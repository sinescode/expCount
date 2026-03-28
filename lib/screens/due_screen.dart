import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class DueScreen extends StatelessWidget {
  const DueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final theyOwe = p.debts.where((d) => d.type == DebtType.theyOwe).toList();
    final iOwe = p.debts.where((d) => d.type == DebtType.iOwe).toList();
    final cur = p.settings.currency;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Due & Owe'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddDebt(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: '📥 They Owe Me'),
              Tab(text: '📤 I Owe'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DebtList(debts: theyOwe, currency: cur, type: DebtType.theyOwe),
            _DebtList(debts: iOwe, currency: cur, type: DebtType.iOwe),
          ],
        ),
      ),
    );
  }

  void _showAddDebt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddDebtSheet(),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final String currency;
  final DebtType type;

  const _DebtList({
    required this.debts,
    required this.currency,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return EmptyState(
        icon: type == DebtType.theyOwe
            ? Icons.call_received
            : Icons.call_made,
        message: type == DebtType.theyOwe
            ? 'Nobody owes you'
            : 'You owe nobody',
        subtitle: 'Tap + to track a debt',
      );
    }

    final fmt = NumberFormat('#,##0.00');
    final p = context.read<AppProvider>();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final d = debts[i];
        final progress = d.totalAmount > 0 ? d.paidAmount / d.totalAmount : 0.0;
        final color = type == DebtType.theyOwe ? AppTheme.green : AppTheme.red;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        d.personName.isNotEmpty
                            ? d.personName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.personName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        if (d.note != null)
                          Text(d.note!,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency${fmt.format(d.remaining)}',
                        style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'of $currency${fmt.format(d.totalAmount)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  DebtStatusBadge(
                      status: d.status, isOverdue: d.isOverdue),
                  if (d.dueDate != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Due ${DateFormat('MMM d').format(d.dueDate!)}',
                      style: TextStyle(
                          color: d.isOverdue
                              ? AppTheme.red
                              : AppTheme.textSecondary,
                          fontSize: 11),
                    ),
                  ],
                  const Spacer(),
                  // Action buttons
                  if (d.status != DebtStatus.settled) ...[
                    TextButton(
                      onPressed: () =>
                          _showPartialPayment(ctx, p, d),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Partial',
                          style: TextStyle(
                              color: AppTheme.orange, fontSize: 11)),
                    ),
                    TextButton(
                      onPressed: () => p.markDebtSettled(d.id),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(60, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Settle',
                          style: TextStyle(
                              color: AppTheme.green, fontSize: 11)),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.textSecondary),
                    onPressed: () => p.deleteDebt(d.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPartialPayment(BuildContext ctx, AppProvider p, Debt d) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Record Payment',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
              hintText: 'Amount paid'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt > 0) {
                p.recordPartialPayment(d.id, amt);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Add debt bottom sheet ─────────────────────────────────────────────────────
class _AddDebtSheet extends StatefulWidget {
  const _AddDebtSheet();

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DebtType _type = DebtType.theyOwe;
  DateTime? _dueDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;
    context.read<AppProvider>().addDebt(Debt(
      personName: name,
      totalAmount: amount,
      type: _type,
      createdAt: DateTime.now(),
      dueDate: _dueDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Add Debt / Due',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = DebtType.theyOwe),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == DebtType.theyOwe
                          ? AppTheme.green.withOpacity(0.2)
                          : AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _type == DebtType.theyOwe
                              ? AppTheme.green
                              : AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Text('📥', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('They Owe Me',
                            style: TextStyle(
                                color: _type == DebtType.theyOwe
                                    ? AppTheme.green
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = DebtType.iOwe),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == DebtType.iOwe
                          ? AppTheme.red.withOpacity(0.2)
                          : AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _type == DebtType.iOwe
                              ? AppTheme.red
                              : AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Text('📤', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('I Owe',
                            style: TextStyle(
                                color: _type == DebtType.iOwe
                                    ? AppTheme.red
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Person Name',
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.currency_rupee, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note (e.g. Lunch split)',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accent)),
                  child: child!,
                ),
              );
              if (d != null) setState(() => _dueDate = d);
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppTheme.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  _dueDate == null
                      ? 'Set due date (optional)'
                      : 'Due: ${DateFormat('MMM d, y').format(_dueDate!)}',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Add', icon: Icons.check, onTap: _submit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
