import 'package:uuid/uuid.dart';
import '../utils/vault_crypto.dart';

const _uuid = Uuid();

enum TransactionType { expense, income }
enum TransactionCategory {
  food, transport, rent, health, shopping, entertainment,
  education, utilities, savings, work, travel, other
}
enum DebtStatus { pending, partiallyPaid, settled, overdue }
enum DebtType { iOwe, theyOwe }

extension TransactionCategoryExt on TransactionCategory {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get emoji {
    const map = {
      TransactionCategory.food: '🍔',
      TransactionCategory.transport: '🚗',
      TransactionCategory.rent: '🏠',
      TransactionCategory.health: '💊',
      TransactionCategory.shopping: '🛍️',
      TransactionCategory.entertainment: '🎬',
      TransactionCategory.education: '📚',
      TransactionCategory.utilities: '💡',
      TransactionCategory.savings: '💰',
      TransactionCategory.work: '💼',
      TransactionCategory.travel: '✈️',
      TransactionCategory.other: '📦',
    };
    return map[this] ?? '📦';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction
// ─────────────────────────────────────────────────────────────────────────────

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime dateTime;
  final bool isHidden;
  final String? note;
  final String? tag;
  final bool isRecurring;
  final String? paymentMethod;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.dateTime,
    this.isHidden = false,
    this.note,
    this.tag,
    this.isRecurring = false,
    this.paymentMethod,
  }) : id = id ?? _uuid.v4();

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? dateTime,
    bool? isHidden,
    String? note,
    String? tag,
    bool? isRecurring,
    String? paymentMethod,
  }) =>
      Transaction(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        dateTime: dateTime ?? this.dateTime,
        isHidden: isHidden ?? this.isHidden,
        note: note ?? this.note,
        tag: tag ?? this.tag,
        isRecurring: isRecurring ?? this.isRecurring,
        paymentMethod: paymentMethod ?? this.paymentMethod,
      );

  // ── Plain JSON (public transactions) ───────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category.name,
        'dateTime': dateTime.toIso8601String(),
        'isHidden': isHidden,
        'note': note,
        'tag': tag,
        'isRecurring': isRecurring,
        'paymentMethod': paymentMethod,
        '_encrypted': false,
      };

  // ── Encrypted JSON (hidden transactions) ──────────────────────────────────
  // Plain fields  : id, amount, isHidden, isRecurring          (analytics needs these)
  // Encrypted fields: title, type, category, dateTime, note, tag, paymentMethod
  Map<String, dynamic> toSecureJson(VaultCrypto crypto) => {
        'id': id,
        'amount': amount,           // plain — so totals still work
        'isHidden': true,
        'isRecurring': isRecurring,
        '_encrypted': true,
        // Everything below is AES-256 encrypted
        'title': crypto.encrypt(title),
        'type': crypto.encrypt(type.name),
        'category': crypto.encrypt(category.name),
        'dateTime': crypto.encrypt(dateTime.toIso8601String()),
        'note': note != null ? crypto.encrypt(note!) : null,
        'tag': tag != null ? crypto.encrypt(tag!) : null,
        'paymentMethod': paymentMethod != null ? crypto.encrypt(paymentMethod!) : null,
      };

  factory Transaction.fromJson(Map<String, dynamic> j, {VaultCrypto? crypto}) {
    final isEncrypted = j['_encrypted'] == true;

    String decryptField(String key, String fallback) {
      final v = j[key] as String?;
      if (v == null) return fallback;
      if (isEncrypted && crypto != null) return crypto.decrypt(v);
      return v;
    }

    String? decryptOptional(String key) {
      final v = j[key] as String?;
      if (v == null) return null;
      if (isEncrypted && crypto != null) return crypto.decrypt(v);
      return v;
    }

    final typeStr = decryptField('type', 'expense');
    final categoryStr = decryptField('category', 'other');
    final dateTimeStr = decryptField('dateTime', DateTime.now().toIso8601String());

    return Transaction(
      id: j['id'],
      title: decryptField('title', '🔒 Hidden'),
      amount: (j['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => TransactionCategory.other,
      ),
      dateTime: DateTime.tryParse(dateTimeStr) ?? DateTime.now(),
      isHidden: j['isHidden'] ?? false,
      note: decryptOptional('note'),
      tag: decryptOptional('tag'),
      isRecurring: j['isRecurring'] ?? false,
      paymentMethod: decryptOptional('paymentMethod'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debt
// ─────────────────────────────────────────────────────────────────────────────

class Debt {
  final String id;
  final String personName;
  final double totalAmount;
  final double paidAmount;
  final DebtType type;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? note;
  final bool isHidden;

  Debt({
    String? id,
    required this.personName,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.type,
    this.status = DebtStatus.pending,
    required this.createdAt,
    this.dueDate,
    this.note,
    this.isHidden = false,
  }) : id = id ?? _uuid.v4();

  double get remaining => totalAmount - paidAmount;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != DebtStatus.settled;

  Debt copyWith({
    String? personName,
    double? totalAmount,
    double? paidAmount,
    DebtType? type,
    DebtStatus? status,
    DateTime? dueDate,
    String? note,
    bool? isHidden,
  }) =>
      Debt(
        id: id,
        personName: personName ?? this.personName,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt,
        dueDate: dueDate ?? this.dueDate,
        note: note ?? this.note,
        isHidden: isHidden ?? this.isHidden,
      );

  // ── Plain JSON ─────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'note': note,
        'isHidden': isHidden,
        '_encrypted': false,
      };

  // ── Encrypted JSON ─────────────────────────────────────────────────────────
  // Plain fields  : id, totalAmount, paidAmount, type, status, createdAt, dueDate
  // Encrypted fields: personName, note
  Map<String, dynamic> toSecureJson(VaultCrypto crypto) => {
        'id': id,
        'totalAmount': totalAmount,     // plain
        'paidAmount': paidAmount,       // plain
        'type': type.name,              // plain (iOwe / theyOwe)
        'status': status.name,          // plain
        'createdAt': createdAt.toIso8601String(), // plain
        'dueDate': dueDate?.toIso8601String(),    // plain
        'isHidden': true,
        '_encrypted': true,
        // Encrypted
        'personName': crypto.encrypt(personName),
        'note': note != null ? crypto.encrypt(note!) : null,
      };

  factory Debt.fromJson(Map<String, dynamic> j, {VaultCrypto? crypto}) {
    final isEncrypted = j['_encrypted'] == true;

    String decryptField(String key, String fallback) {
      final v = j[key] as String?;
      if (v == null) return fallback;
      if (isEncrypted && crypto != null) return crypto.decrypt(v);
      return v;
    }

    String? decryptOptional(String key) {
      final v = j[key] as String?;
      if (v == null) return null;
      if (isEncrypted && crypto != null) return crypto.decrypt(v);
      return v;
    }

    return Debt(
      id: j['id'],
      personName: decryptField('personName', '🔒 Hidden'),
      totalAmount: (j['totalAmount'] as num).toDouble(),
      paidAmount: (j['paidAmount'] as num).toDouble(),
      type: DebtType.values.firstWhere((e) => e.name == j['type']),
      status: DebtStatus.values.firstWhere((e) => e.name == j['status']),
      createdAt: DateTime.parse(j['createdAt']),
      dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
      note: decryptOptional('note'),
      isHidden: j['isHidden'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder (not encrypted — reminders are always visible)
// ─────────────────────────────────────────────────────────────────────────────

class Reminder {
  final String id;
  final String title;
  final String? note;
  final DateTime dateTime;
  final bool isActive;
  final String? linkedDebtId;

  Reminder({
    String? id,
    required this.title,
    this.note,
    required this.dateTime,
    this.isActive = true,
    this.linkedDebtId,
  }) : id = id ?? _uuid.v4();

  Reminder copyWith({bool? isActive}) => Reminder(
        id: id,
        title: title,
        note: note,
        dateTime: dateTime,
        isActive: isActive ?? this.isActive,
        linkedDebtId: linkedDebtId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dateTime': dateTime.toIso8601String(),
        'isActive': isActive,
        'linkedDebtId': linkedDebtId,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        title: j['title'],
        note: j['note'],
        dateTime: DateTime.parse(j['dateTime']),
        isActive: j['isActive'] ?? true,
        linkedDebtId: j['linkedDebtId'],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  final String currency;
  final bool darkMode;
  final bool appLockEnabled;
  final String? pin;
  final bool biometricEnabled;
  final double? monthlyBudget;
  final double? dailyBudget;

  const AppSettings({
    this.currency = '₹',
    this.darkMode = true,
    this.appLockEnabled = false,
    this.pin,
    this.biometricEnabled = false,
    this.monthlyBudget,
    this.dailyBudget,
  });

  AppSettings copyWith({
    String? currency,
    bool? darkMode,
    bool? appLockEnabled,
    String? pin,
    bool? biometricEnabled,
    double? monthlyBudget,
    double? dailyBudget,
  }) =>
      AppSettings(
        currency: currency ?? this.currency,
        darkMode: darkMode ?? this.darkMode,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        pin: pin ?? this.pin,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        dailyBudget: dailyBudget ?? this.dailyBudget,
      );

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'darkMode': darkMode,
        'appLockEnabled': appLockEnabled,
        'pin': pin,
        'biometricEnabled': biometricEnabled,
        'monthlyBudget': monthlyBudget,
        'dailyBudget': dailyBudget,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        currency: j['currency'] ?? '₹',
        darkMode: j['darkMode'] ?? true,
        appLockEnabled: j['appLockEnabled'] ?? false,
        pin: j['pin'],
        biometricEnabled: j['biometricEnabled'] ?? false,
        monthlyBudget: (j['monthlyBudget'] as num?)?.toDouble(),
        dailyBudget: (j['dailyBudget'] as num?)?.toDouble(),
      );
}
