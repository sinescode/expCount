import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/vault_crypto.dart';

enum SaveStatus { idle, saving, saved, failed }

class AppProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Debt> _debts = [];
  List<Reminder> _reminders = [];
  AppSettings _settings = const AppSettings();
  SaveStatus _saveStatus = SaveStatus.idle;
  bool _vaultUnlocked = false;
  bool _isLoading = true;

  static const _dataPath = '/storage/emulated/0/expcount/mydata.json';

  // Active crypto instance — rebuilt whenever PIN changes
  VaultCrypto _crypto = VaultCrypto();

  List<Transaction> get transactions => _transactions;
  List<Transaction> get publicTransactions =>
      _transactions.where((t) => !t.isHidden).toList();
  List<Transaction> get hiddenTransactions =>
      _transactions.where((t) => t.isHidden).toList();
  List<Debt> get debts => _debts;
  List<Debt> get publicDebts => _debts.where((d) => !d.isHidden).toList();
  List<Debt> get hiddenDebts => _debts.where((d) => d.isHidden).toList();
  List<Reminder> get reminders => _reminders;
  AppSettings get settings => _settings;
  SaveStatus get saveStatus => _saveStatus;
  bool get vaultUnlocked => _vaultUnlocked;
  bool get isLoading => _isLoading;

  // ── Balance calculations ──────────────────────────────────────────────────

  double get totalBalance {
    double b = 0;
    for (final t in _transactions) {
      b += t.type == TransactionType.income ? t.amount : -t.amount;
    }
    return b;
  }

  double get publicBalance {
    double b = 0;
    for (final t in publicTransactions) {
      b += t.type == TransactionType.income ? t.amount : -t.amount;
    }
    return b;
  }

  double get todaySpent {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get monthSpent {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get totalOwed => _debts
      .where((d) => d.type == DebtType.theyOwe && d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  double get totalOwing => _debts
      .where((d) => d.type == DebtType.iOwe && d.status != DebtStatus.settled)
      .fold(0.0, (s, d) => s + d.remaining);

  List<Debt> get overdueDebts => _debts.where((d) => d.isOverdue).toList();

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    return _reminders
        .where((r) => r.isActive && r.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // ── Vault ─────────────────────────────────────────────────────────────────

  void unlockVault() {
    _vaultUnlocked = true;
    notifyListeners();
  }

  void lockVault() {
    _vaultUnlocked = false;
    notifyListeners();
  }

  bool verifyPin(String pin) => _settings.pin == pin;

  // ── CRUD: Transactions ────────────────────────────────────────────────────

  void addTransaction(Transaction t) {
    _transactions.insert(0, t);
    _save();
  }

  void updateTransaction(Transaction t) {
    final idx = _transactions.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      _transactions[idx] = t;
      _save();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _save();
  }

  // ── CRUD: Debts ───────────────────────────────────────────────────────────

  void addDebt(Debt d) {
    _debts.insert(0, d);
    _save();
  }

  void updateDebt(Debt d) {
    final idx = _debts.indexWhere((x) => x.id == d.id);
    if (idx >= 0) {
      _debts[idx] = d;
      _save();
    }
  }

  void deleteDebt(String id) {
    _debts.removeWhere((d) => d.id == id);
    _save();
  }

  void markDebtSettled(String id) {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _debts[idx] = _debts[idx].copyWith(
        status: DebtStatus.settled,
        paidAmount: _debts[idx].totalAmount,
      );
      _save();
    }
  }

  void recordPartialPayment(String id, double amount) {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final d = _debts[idx];
      final newPaid = d.paidAmount + amount;
      _debts[idx] = d.copyWith(
        paidAmount: newPaid,
        status: newPaid >= d.totalAmount
            ? DebtStatus.settled
            : DebtStatus.partiallyPaid,
      );
      _save();
    }
  }

  // ── CRUD: Reminders ───────────────────────────────────────────────────────

  void addReminder(Reminder r) {
    _reminders.add(r);
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _save();
  }

  void toggleReminder(String id) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _reminders[idx] = _reminders[idx].copyWith(isActive: !_reminders[idx].isActive);
      _save();
    }
  }

  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _save();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void updateSettings(AppSettings s) {
    final pinChanged = s.pin != _settings.pin;
    _settings = s;
    if (pinChanged) {
      // Rebuild crypto with new PIN, then re-save so existing hidden entries
      // are re-encrypted under the new key.
      _crypto = VaultCrypto(pin: s.pin);
    }
    _save();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final file = File(_dataPath);
      if (await file.exists()) {
        final raw = await file.readAsString();
        _applyJson(raw);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('expcount_data');
        if (raw != null) _applyJson(raw);
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
    // Build crypto after settings are loaded (PIN is now known)
    _crypto = VaultCrypto(pin: _settings.pin);
    _isLoading = false;
    notifyListeners();
  }

  void _applyJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;

    // Settings must be parsed first so PIN is available for crypto
    if (j['settings'] != null) {
      _settings = AppSettings.fromJson(j['settings']);
    }
    final crypto = VaultCrypto(pin: _settings.pin);

    _transactions = ((j['transactions'] as List?) ?? [])
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>, crypto: crypto))
        .toList();

    _debts = ((j['debts'] as List?) ?? [])
        .map((e) => Debt.fromJson(e as Map<String, dynamic>, crypto: crypto))
        .toList();

    _reminders = ((j['reminders'] as List?) ?? [])
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    _saveStatus = SaveStatus.saving;
    notifyListeners();
    try {
      final data = _buildJson();
      final file = File(_dataPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(data, flush: true);
      // Fallback mirror in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('expcount_data', data);
      _saveStatus = SaveStatus.saved;
    } catch (e) {
      debugPrint('Save error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('expcount_data', _buildJson());
        _saveStatus = SaveStatus.saved;
      } catch (_) {
        _saveStatus = SaveStatus.failed;
      }
    }
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _saveStatus = SaveStatus.idle;
    notifyListeners();
  }

  /// Builds the JSON string.
  /// Hidden entries are serialized with AES-256 encryption on all sensitive fields.
  /// Public entries are plain JSON.
  String _buildJson() {
    final txList = _transactions.map((t) {
      if (t.isHidden) return t.toSecureJson(_crypto);
      return t.toJson();
    }).toList();

    final debtList = _debts.map((d) {
      if (d.isHidden) return d.toSecureJson(_crypto);
      return d.toJson();
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'transactions': txList,
      'debts': debtList,
      'reminders': _reminders.map((r) => r.toJson()).toList(),
      'settings': _settings.toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
      '_note': 'Hidden entries are AES-256 encrypted. Amount fields are always plain.',
    });
  }

  String exportJson() => _buildJson();

  Future<bool> importJson(String raw) async {
    try {
      _applyJson(raw);
      await _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Analytics helpers ─────────────────────────────────────────────────────

  Map<TransactionCategory, double> get categorySpending {
    final map = <TransactionCategory, double>{};
    for (final t in _transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<MapEntry<DateTime, double>> get last7DaysSpending {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final spent = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.dateTime.year == day.year &&
              t.dateTime.month == day.month &&
              t.dateTime.day == day.day)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(day, spent);
    });
  }

  List<Transaction> searchTransactions(String query) {
    final q = query.toLowerCase();
    return _transactions.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        (t.tag?.toLowerCase().contains(q) ?? false) ||
        t.category.label.toLowerCase().contains(q)).toList();
  }
}
