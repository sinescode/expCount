import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/vault_crypto.dart';

enum SaveStatus { idle, saving, saved, failed }

// Holds one pending-undo item so it can be restored within 5 seconds
class _UndoEntry {
  final String type; // 'transaction' | 'debt' | 'reminder'
  final dynamic item;
  final int index;
  _UndoEntry(this.type, this.item, this.index);
}

class AppProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Debt>        _debts        = [];
  List<Reminder>    _reminders    = [];
  AppSettings       _settings     = const AppSettings();
  SaveStatus        _saveStatus   = SaveStatus.idle;
  bool              _vaultUnlocked = false;
  bool              _isLoading    = true;

  // Pending undo stack (max 1 entry; each delete overwrites)
  _UndoEntry? _pendingUndo;
  Timer?      _undoTimer;

  static const _dataPath = '/storage/emulated/0/expcount/mydata.json';
  VaultCrypto _crypto = VaultCrypto();

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Transaction> get transactions        => _transactions;
  List<Transaction> get publicTransactions  => _transactions.where((t) => !t.isHidden).toList();
  List<Transaction> get hiddenTransactions  => _transactions.where((t) => t.isHidden).toList();
  List<Debt>        get debts               => _debts;
  List<Debt>        get publicDebts         => _debts.where((d) => !d.isHidden).toList();
  List<Debt>        get hiddenDebts         => _debts.where((d) => d.isHidden).toList();
  List<Reminder>    get reminders           => _reminders;
  AppSettings       get settings            => _settings;
  SaveStatus        get saveStatus          => _saveStatus;
  bool              get vaultUnlocked       => _vaultUnlocked;
  bool              get isLoading           => _isLoading;
  bool              get hasPendingUndo      => _pendingUndo != null;

  // ── Balances ──────────────────────────────────────────────────────────────
  double get totalBalance => _transactions.fold(0.0,
      (s, t) => s + (t.type == TransactionType.income ? t.amount : -t.amount));

  double get publicBalance => publicTransactions.fold(0.0,
      (s, t) => s + (t.type == TransactionType.income ? t.amount : -t.amount));

  double get todaySpent {
    final now = DateTime.now();
    return _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.dateTime.year == now.year &&
        t.dateTime.month == now.month &&
        t.dateTime.day == now.day).fold(0.0, (s, t) => s + t.amount);
  }

  double get monthSpent {
    final now = DateTime.now();
    return _transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.dateTime.year == now.year &&
        t.dateTime.month == now.month).fold(0.0, (s, t) => s + t.amount);
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
        .toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // ── Vault ─────────────────────────────────────────────────────────────────
  void unlockVault()   { _vaultUnlocked = true;  notifyListeners(); }
  void lockVault()     { _vaultUnlocked = false; notifyListeners(); }
  bool verifyPin(String pin) => _settings.pin == pin;

  // ── Undo system ───────────────────────────────────────────────────────────
  void _armUndo(String type, dynamic item, int index) {
    _undoTimer?.cancel();
    _pendingUndo = _UndoEntry(type, item, index);
    notifyListeners();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      _pendingUndo = null;
      notifyListeners();
    });
  }

  void undo() {
    final entry = _pendingUndo;
    if (entry == null) return;
    _undoTimer?.cancel();
    _pendingUndo = null;

    switch (entry.type) {
      case 'transaction':
        final t = entry.item as Transaction;
        final idx = entry.index.clamp(0, _transactions.length);
        _transactions.insert(idx, t);
      case 'transactions':
        final items = (entry.item as List).cast<Transaction>();
        for (final t in items.reversed) {
          _transactions.insert(0, t);
        }
      case 'debt':
        final d = entry.item as Debt;
        final idx = entry.index.clamp(0, _debts.length);
        _debts.insert(idx, d);
      case 'debts':
        final items = (entry.item as List).cast<Debt>();
        for (final d in items.reversed) {
          _debts.insert(0, d);
        }
      case 'reminder':
        final r = entry.item as Reminder;
        final idx = entry.index.clamp(0, _reminders.length);
        _reminders.insert(idx, r);
      case 'reminders':
        final items = (entry.item as List).cast<Reminder>();
        _reminders.addAll(items);
        _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
    _save();
  }

  // ── CRUD: Transactions ────────────────────────────────────────────────────
  void addTransaction(Transaction t) {
    _transactions.insert(0, t);
    _save();
  }

  void updateTransaction(Transaction t) {
    final idx = _transactions.indexWhere((x) => x.id == t.id);
    if (idx >= 0) { _transactions[idx] = t; _save(); }
  }

  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    _armUndo('transaction', _transactions[idx], idx);
    _transactions.removeAt(idx);
    _save();
  }

  /// Delete multiple transactions at once — single undo restores all
  void deleteTransactions(List<String> ids) {
    final removed = <Transaction>[];
    for (final id in ids) {
      final t = _transactions.firstWhere((x) => x.id == id, orElse: () => throw StateError(''));
      removed.add(t);
    }
    _transactions.removeWhere((t) => ids.contains(t.id));
    _armUndo('transactions', removed, 0);
    _save();
  }

  // ── CRUD: Debts ───────────────────────────────────────────────────────────
  void addDebt(Debt d) {
    _debts.insert(0, d);
    _save();
  }

  void updateDebt(Debt d) {
    final idx = _debts.indexWhere((x) => x.id == d.id);
    if (idx >= 0) { _debts[idx] = d; _save(); }
  }

  void deleteDebt(String id) {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    _armUndo('debt', _debts[idx], idx);
    _debts.removeAt(idx);
    _save();
  }

  void deleteDebts(List<String> ids) {
    final removed = _debts.where((d) => ids.contains(d.id)).toList();
    _debts.removeWhere((d) => ids.contains(d.id));
    _armUndo('debts', removed, 0);
    _save();
  }

  void markDebtSettled(String id) {
    final idx = _debts.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      _debts[idx] = _debts[idx].copyWith(
          status: DebtStatus.settled, paidAmount: _debts[idx].totalAmount);
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
        status: newPaid >= d.totalAmount ? DebtStatus.settled : DebtStatus.partiallyPaid,
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
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    _armUndo('reminder', _reminders[idx], idx);
    _reminders.removeAt(idx);
    _save();
  }

  void deleteReminders(List<String> ids) {
    final removed = _reminders.where((r) => ids.contains(r.id)).toList();
    _reminders.removeWhere((r) => ids.contains(r.id));
    _armUndo('reminders', removed, 0);
    _save();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  void updateSettings(AppSettings s) {
    final pinChanged = s.pin != _settings.pin;
    _settings = s;
    if (pinChanged) _crypto = VaultCrypto(pin: s.pin);
    _save();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final file = File(_dataPath);
      if (await file.exists()) {
        _applyJson(await file.readAsString());
      } else {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('expcount_data');
        if (raw != null) _applyJson(raw);
      }
    } catch (e) { debugPrint('Load error: $e'); }
    _crypto = VaultCrypto(pin: _settings.pin);
    _isLoading = false;
    notifyListeners();
  }

  void _applyJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['settings'] != null) _settings = AppSettings.fromJson(j['settings']);
    final crypto = VaultCrypto(pin: _settings.pin);
    _transactions = ((j['transactions'] as List?) ?? [])
        .map((e) => Transaction.fromJson(e, crypto: crypto)).toList();
    _debts = ((j['debts'] as List?) ?? [])
        .map((e) => Debt.fromJson(e, crypto: crypto)).toList();
    _reminders = ((j['reminders'] as List?) ?? [])
        .map((e) => Reminder.fromJson(e)).toList();
  }

  Future<void> _save() async {
    _saveStatus = SaveStatus.saving;
    notifyListeners();
    try {
      final data = _buildJson();
      final file = File(_dataPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(data, flush: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('expcount_data', data);
      _saveStatus = SaveStatus.saved;
    } catch (e) {
      debugPrint('Save error: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('expcount_data', _buildJson());
        _saveStatus = SaveStatus.saved;
      } catch (_) { _saveStatus = SaveStatus.failed; }
    }
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _saveStatus = SaveStatus.idle;
    notifyListeners();
  }

  String _buildJson() => const JsonEncoder.withIndent('  ').convert({
    'transactions': _transactions.map((t) => t.isHidden ? t.toSecureJson(_crypto) : t.toJson()).toList(),
    'debts': _debts.map((d) => d.isHidden ? d.toSecureJson(_crypto) : d.toJson()).toList(),
    'reminders': _reminders.map((r) => r.toJson()).toList(),
    'settings': _settings.toJson(),
    'exportedAt': DateTime.now().toIso8601String(),
    '_note': 'Hidden entries are AES-256 encrypted.',
  });

  String exportJson() => _buildJson();

  Future<bool> importJson(String raw) async {
    try { _applyJson(raw); await _save(); return true; }
    catch (_) { return false; }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
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
          .where((t) => t.type == TransactionType.expense &&
              t.dateTime.year == day.year &&
              t.dateTime.month == day.month &&
              t.dateTime.day == day.day)
          .fold(0.0, (s, t) => s + t.amount);
      return MapEntry(day, spent);
    });
  }


  // ── Filter helpers ────────────────────────────────────────────────────────

  /// Filter public transactions by date and/or category/type
  List<Transaction> filterTransactions({
    DateTime? date,          // exact day
    DateTime? from,          // range start
    DateTime? to,            // range end (inclusive)
    TransactionCategory? category,
    TransactionType? type,
    String? query,
  }) {
    return publicTransactions.where((t) {
      if (date != null) {
        if (t.dateTime.year != date.year ||
            t.dateTime.month != date.month ||
            t.dateTime.day != date.day) return false;
      }
      if (from != null && t.dateTime.isBefore(
              DateTime(from.year, from.month, from.day))) return false;
      if (to != null && t.dateTime.isAfter(
              DateTime(to.year, to.month, to.day, 23, 59, 59))) return false;
      if (category != null && t.category != category) return false;
      if (type != null && t.type != type) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!t.title.toLowerCase().contains(q) &&
            !(t.note?.toLowerCase().contains(q) ?? false) &&
            !(t.tag?.toLowerCase().contains(q) ?? false) &&
            !t.category.label.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Same filter for hidden (vault) transactions — vault must be unlocked
  List<Transaction> filterHiddenTransactions({
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TransactionCategory? category,
    TransactionType? type,
    String? query,
  }) {
    if (!_vaultUnlocked) return [];
    return hiddenTransactions.where((t) {
      if (date != null) {
        if (t.dateTime.year != date.year ||
            t.dateTime.month != date.month ||
            t.dateTime.day != date.day) return false;
      }
      if (from != null && t.dateTime.isBefore(
              DateTime(from.year, from.month, from.day))) return false;
      if (to != null && t.dateTime.isAfter(
              DateTime(to.year, to.month, to.day, 23, 59, 59))) return false;
      if (category != null && t.category != category) return false;
      if (type != null && t.type != type) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!t.title.toLowerCase().contains(q) &&
            !(t.note?.toLowerCase().contains(q) ?? false) &&
            !(t.tag?.toLowerCase().contains(q) ?? false) &&
            !t.category.label.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Public-only search — hidden entries never appear here
  List<Transaction> searchTransactions(String query) {
    final q = query.toLowerCase();
    return publicTransactions.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        (t.tag?.toLowerCase().contains(q) ?? false) ||
        t.category.label.toLowerCase().contains(q)).toList();
  }

  /// Vault-only search — only hidden entries, only when vault is unlocked
  List<Transaction> searchHiddenTransactions(String query) {
    if (!_vaultUnlocked) return [];
    final q = query.toLowerCase();
    return hiddenTransactions.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false) ||
        (t.tag?.toLowerCase().contains(q) ?? false) ||
        t.category.label.toLowerCase().contains(q)).toList();
  }
}
