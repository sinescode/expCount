import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

// Bangladesh payment methods
const _paymentMethods = [
  'bKash', 'Nagad', 'Rocket', 'Cash', 'Bank Transfer', 'Card', 'Other'
];

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  final bool forceHidden;
  final TransactionType initialType;

  const AddTransactionScreen({
    super.key, this.existing, this.forceHidden = false,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  bool _isHidden = false;
  bool _isRecurring = false;
  DateTime _dateTime = DateTime.now();
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _isHidden = widget.forceHidden;

    _tab = TabController(
      length: 2, vsync: this,
      initialIndex: _type == TransactionType.income ? 1 : 0,
    );

    if (widget.existing != null) {
      final t = widget.existing!;
      _amountCtrl.text = t.amount.toString();
      _titleCtrl.text = t.title;
      _noteCtrl.text = t.note ?? '';
      _tagCtrl.text = t.tag ?? '';
      _type = t.type;
      _category = t.category;
      _isHidden = t.isHidden;
      _isRecurring = t.isRecurring;
      _dateTime = t.dateTime;
      _paymentMethod = t.paymentMethod;
      _tab.index = t.type == TransactionType.income ? 1 : 0;
    }

    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() {
          _type = _tab.index == 0 ? TransactionType.expense : TransactionType.income;
        });
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final title = _titleCtrl.text.trim().isEmpty ? _category.label : _titleCtrl.text.trim();
    final provider = context.read<AppProvider>();
    final t = Transaction(
      id: widget.existing?.id,
      title: title,
      amount: amount,
      type: _type,
      category: _category,
      dateTime: _dateTime,
      isHidden: _isHidden,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      isRecurring: _isRecurring,
      paymentMethod: _paymentMethod,
    );
    if (widget.existing != null) {
      provider.updateTransaction(t);
    } else {
      provider.addTransaction(t);
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(() => _dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;
    final cur = context.watch<AppProvider>().settings.currency;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          TextButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: AppTheme.accent, size: 18),
            label: const Text('Save',
                style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            gradient: AppTheme.accentGrad,
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward, size: 16), text: 'Expense'),
            Tab(icon: Icon(Icons.arrow_downward, size: 16), text: 'Income'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Amount card
          GlassCard(
            gradient: LinearGradient(colors: [
              isExpense
                  ? AppTheme.expenseCardBg(context.isDark)
                  : AppTheme.incomeCardBg(context.isDark),
              isExpense
                  ? AppTheme.expenseCardBg(context.isDark)
                  : AppTheme.incomeCardBg(context.isDark),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isExpense ? 'Amount Spent' : 'Amount Received',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Text(cur,
                    style: TextStyle(
                        color: isExpense ? AppTheme.red : AppTheme.green,
                        fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        color: isExpense ? AppTheme.red : AppTheme.green,
                        fontSize: 32, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      hintText: '0.00',
                    ),
                  ),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Title (optional)',
              hintText: _category.label,
              prefixIcon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 14),

          const Text('Category',
              style: TextStyle(color: AppTheme.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: TransactionCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  category: c, selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Date/time picker
          GlassCard(
            onTap: _pickDate,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: AppTheme.accent, size: 18),
              const SizedBox(width: 10),
              Text(DateFormat('EEE, MMM d, y  h:mm a').format(_dateTime),
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 14),
            ]),
          ),

          const SizedBox(height: 14),

          // Payment method — Bangladesh specific
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            dropdownColor: AppTheme.card,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
            ),
            items: _paymentMethods.map((m) {
              final icon = _methodIcon(m);
              return DropdownMenuItem(
                value: m,
                child: Row(children: [
                  Icon(icon, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(m),
                ]),
              );
            }).toList(),
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note',
              prefixIcon: Icon(Icons.notes_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _tagCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Tag  (e.g. work, family)',
              prefixIcon: Icon(Icons.label_outline, size: 18),
            ),
          ),

          const SizedBox(height: 14),

          // Toggles
          GlassCard(
            child: Column(children: [
              SwitchListTile(
                title: Row(children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppTheme.accentLight),
                  const SizedBox(width: 8),
                  const Text('Hidden Entry',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
                subtitle: const Text('Encrypted and visible only in vault',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                value: _isHidden,
                onChanged: widget.forceHidden ? null : (v) => setState(() => _isHidden = v),
                activeColor: AppTheme.accent,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(color: AppTheme.border, height: 1),
              SwitchListTile(
                title: Row(children: [
                  const Icon(Icons.repeat, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Recurring',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
                subtitle: const Text('Mark as a recurring transaction',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeColor: AppTheme.accent,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          GradientButton(
            label: widget.existing != null ? 'Update Transaction' : 'Save Transaction',
            icon: Icons.check,
            onTap: _submit,
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'bKash':         return Icons.phone_android;
      case 'Nagad':         return Icons.mobile_friendly;
      case 'Rocket':        return Icons.rocket_launch_outlined;
      case 'Cash':          return Icons.payments_outlined;
      case 'Bank Transfer': return Icons.account_balance_outlined;
      case 'Card':          return Icons.credit_card_outlined;
      default:              return Icons.more_horiz;
    }
  }
}
