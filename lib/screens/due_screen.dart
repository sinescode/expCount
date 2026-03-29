import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class DueScreen extends StatefulWidget {
  const DueScreen({super.key});
  @override
  State<DueScreen> createState() => _DueScreenState();
}

class _DueScreenState extends State<DueScreen> {
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelect(String id) => setState(() {
    if (_selected.contains(id)) _selected.remove(id);
    else _selected.add(id);
  });

  void _cancelSelect() => setState(() => _selected.clear());

  void _deleteSelected(AppProvider p) {
    final count = _selected.length;
    final ids = List<String>.from(_selected);
    setState(() => _selected.clear());
    p.deleteDebts(ids);
    showUndoSnackbar(context, p, 'Deleted $count debt${count == 1 ? '' : 's'}');
  }

  @override
  Widget build(BuildContext context) {
    final p   = context.watch<AppProvider>();
    final cur = p.settings.currency;

    final theyOwe = p.debts.where((d) => d.type == DebtType.theyOwe).toList();
    final iOwe    = p.debts.where((d) => d.type == DebtType.iOwe).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: _selecting
              ? Text('${_selected.length} selected',
                  style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w700))
              : const Text('Due & Owe'),
          actions: _selecting
              ? [
                  TextButton(
                    onPressed: () {
                      final all = [...theyOwe, ...iOwe].map((d) => d.id);
                      setState(() => _selected.addAll(all));
                    },
                    child: const Text('All',
                        style: TextStyle(color: AppTheme.accent)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                    onPressed: () => _deleteSelected(p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.textSecondary),
                    onPressed: _cancelSelect,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.add_outlined),
                    onPressed: () => _openSheet(context, null),
                  ),
                ],
          bottom: _selecting
              ? null
              : const TabBar(
                  indicatorColor: AppTheme.accent,
                  labelColor: AppTheme.accent,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: [
                    Tab(icon: Icon(Icons.call_received_outlined, size: 16),
                        text: 'They Owe Me'),
                    Tab(icon: Icon(Icons.call_made_outlined, size: 16),
                        text: 'I Owe'),
                  ],
                ),
        ),
        body: _selecting
            ? _buildSelectableList([...theyOwe, ...iOwe], cur, p)
            : TabBarView(children: [
                _DebtList(debts: theyOwe, currency: cur, type: DebtType.theyOwe,
                    onEdit: (d) => _openSheet(context, d),
                    onDelete: (d) {
                      p.deleteDebt(d.id);
                      showUndoSnackbar(context, p, 'Deleted "${d.personName}"');
                    },
                    onLongPress: (d) => _toggleSelect(d.id)),
                _DebtList(debts: iOwe, currency: cur, type: DebtType.iOwe,
                    onEdit: (d) => _openSheet(context, d),
                    onDelete: (d) {
                      p.deleteDebt(d.id);
                      showUndoSnackbar(context, p, 'Deleted "${d.personName}"');
                    },
                    onLongPress: (d) => _toggleSelect(d.id)),
              ]),
        bottomNavigationBar: _selecting
            ? BulkActionBar(
                selectedCount: _selected.length,
                onDelete: () => _deleteSelected(p),
                onCancel: _cancelSelect,
              )
            : null,
      ),
    );
  }

  Widget _buildSelectableList(
      List<Debt> all, String cur, AppProvider p) {
    final fmt = NumberFormat('#,##0.00');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final d = _buildDebtCard(ctx, all[i], cur, fmt, p,
            selectable: true,
            selected: _selected.contains(all[i].id),
            onTap: () => _toggleSelect(all[i].id));
        return d;
      },
    );
  }

  Widget _buildDebtCard(
    BuildContext ctx,
    Debt d,
    String cur,
    NumberFormat fmt,
    AppProvider p, {
    bool selectable = false,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final color = d.type == DebtType.theyOwe ? AppTheme.green : AppTheme.red;
    final progress = d.totalAmount > 0 ? d.paidAmount / d.totalAmount : 0.0;

    return GlassCard(
      selected: selected,
      onTap: onTap,
      child: Row(children: [
        if (selectable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24, height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: selected ? AppTheme.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? AppTheme.accent : AppTheme.textSecondary,
                  width: 1.5),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    d.personName.isNotEmpty ? d.personName[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.personName,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (d.note != null)
                  Text(d.note!, style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$cur${fmt.format(d.remaining)}',
                    style: TextStyle(color: color, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text('of $cur${fmt.format(d.totalAmount)}',
                    style: const TextStyle(color: AppTheme.textSecondary,
                        fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
            ),
            const SizedBox(height: 6),
            Row(children: [
              DebtStatusBadge(status: d.status, isOverdue: d.isOverdue),
              if (d.dueDate != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.calendar_today_outlined, size: 10,
                    color: d.isOverdue ? AppTheme.red : AppTheme.textSecondary),
                const SizedBox(width: 2),
                Text('Due ${DateFormat('MMM d').format(d.dueDate!)}',
                    style: TextStyle(
                        color: d.isOverdue ? AppTheme.red : AppTheme.textSecondary,
                        fontSize: 11)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  void _openSheet(BuildContext context, Debt? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DebtSheet(existing: existing),
    );
  }
}

// ── Debt list (single tab) ────────────────────────────────────────────────────
class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final String currency;
  final DebtType type;
  final void Function(Debt) onEdit;
  final void Function(Debt) onDelete;
  final void Function(Debt) onLongPress;

  const _DebtList({
    required this.debts, required this.currency, required this.type,
    required this.onEdit, required this.onDelete, required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return EmptyState(
        icon: type == DebtType.theyOwe
            ? Icons.call_received_outlined : Icons.call_made_outlined,
        message: type == DebtType.theyOwe ? 'Nobody owes you' : 'You owe nobody',
        subtitle: 'Tap + to add · Long-press to select',
      );
    }

    final fmt = NumberFormat('#,##0.00');
    final p   = context.read<AppProvider>();
    final color = type == DebtType.theyOwe ? AppTheme.green : AppTheme.red;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final d = debts[i];
        final progress = d.totalAmount > 0 ? d.paidAmount / d.totalAmount : 0.0;

        return Dismissible(
          key: ValueKey(d.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async => true,
          onDismissed: (_) => onDelete(d),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.red.withOpacity(0.3)),
            ),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_outline, color: AppTheme.red, size: 22),
              SizedBox(height: 2),
              Text('Delete', style: TextStyle(color: AppTheme.red,
                  fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
          child: GlassCard(
            onTap: () => onEdit(d),
            onLongPress: () => onLongPress(d),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      d.personName.isNotEmpty
                          ? d.personName[0].toUpperCase() : '?',
                      style: TextStyle(color: color, fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.personName,
                      style: const TextStyle(color: AppTheme.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (d.note != null)
                    Text(d.note!, style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$currency${fmt.format(d.remaining)}',
                      style: TextStyle(color: color, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('of $currency${fmt.format(d.totalAmount)}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10)),
                  const SizedBox(height: 2),
                  Icon(Icons.edit_outlined, size: 12,
                      color: AppTheme.textSecondary.withOpacity(0.5)),
                ]),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
              ),
              const SizedBox(height: 8),
              Row(children: [
                DebtStatusBadge(status: d.status, isOverdue: d.isOverdue),
                if (d.dueDate != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.calendar_today_outlined, size: 10,
                      color: d.isOverdue ? AppTheme.red : AppTheme.textSecondary),
                  const SizedBox(width: 2),
                  Text('Due ${DateFormat('MMM d').format(d.dueDate!)}',
                      style: TextStyle(
                          color: d.isOverdue ? AppTheme.red : AppTheme.textSecondary,
                          fontSize: 11)),
                ],
                const Spacer(),
                if (d.status != DebtStatus.settled) ...[
                  _actionBtn('Partial', AppTheme.orange,
                      () => _showPartialPayment(ctx, p, d, currency)),
                  _actionBtn('Settle', AppTheme.green,
                      () => p.markDebtSettled(d.id)),
                ],
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(50, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      );

  void _showPartialPayment(
      BuildContext ctx, AppProvider p, Debt d, String currency) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.payments_outlined, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          const Text('Record Payment',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        ]),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Amount paid',
            prefixText: '$currency ',
            prefixStyle: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt > 0) {
                p.recordPartialPayment(d.id, amt);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: AppTheme.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit debt sheet ─────────────────────────────────────────────────────
class _DebtSheet extends StatefulWidget {
  final Debt? existing;
  const _DebtSheet({this.existing});
  @override
  State<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends State<_DebtSheet> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DebtType  _type   = DebtType.theyOwe;
  DateTime? _dueDate;
  bool get _isEdit  => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _nameCtrl.text   = d.personName;
      _amountCtrl.text = d.totalAmount.toString();
      _noteCtrl.text   = d.note ?? '';
      _type            = d.type;
      _dueDate         = d.dueDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _amountCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name   = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid name and amount')));
      return;
    }
    final p = context.read<AppProvider>();
    if (_isEdit) {
      p.updateDebt(widget.existing!.copyWith(
        personName: name, totalAmount: amount, type: _type, dueDate: _dueDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    } else {
      p.addDebt(Debt(
        personName: name, totalAmount: amount, type: _type,
        createdAt: DateTime.now(), dueDate: _dueDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    }
    Navigator.pop(context);
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate ?? DateTime.now().add(const Duration(days: 7));
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_isEdit ? 'Edit Debt' : 'Add Debt / Due',
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (_isEdit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Editing',
                    style: TextStyle(color: AppTheme.accent,
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _typeBtn(DebtType.theyOwe, Icons.call_received_outlined,
                'They Owe Me', AppTheme.green),
            const SizedBox(width: 10),
            _typeBtn(DebtType.iOwe, Icons.call_made_outlined,
                'I Owe', AppTheme.red),
          ]),
          const SizedBox(height: 14),
          TextField(controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person_outline, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(labelText: 'Total Amount',
                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                  prefixText: '${context.watch<AppProvider>().settings.currency} ',
                  prefixStyle: const TextStyle(color: AppTheme.textSecondary))),
          const SizedBox(height: 10),
          TextField(controller: _noteCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Note  (e.g. Lunch split, Room rent)',
                  prefixIcon: Icon(Icons.notes_outlined, size: 18))),
          const SizedBox(height: 10),
          GlassCard(
            onTap: _pickDueDate,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppTheme.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _dueDate == null
                    ? 'Set due date (optional)'
                    : 'Due: ${DateFormat('EEE, MMM d, y').format(_dueDate!)}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              )),
              if (_dueDate != null)
                GestureDetector(
                  onTap: () => setState(() => _dueDate = null),
                  child: const Icon(Icons.close, size: 16,
                      color: AppTheme.textSecondary),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: _isEdit ? 'Save Changes' : 'Add Debt',
            icon: _isEdit ? Icons.check : Icons.add,
            onTap: _submit,
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _typeBtn(DebtType t, IconData icon, String label, Color color) {
    final sel = _type == t;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _type = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.2) : AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? color : AppTheme.border),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? color : AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              color: sel ? color : AppTheme.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }
}
