import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final now = DateTime.now();

    // Build timeline: combine recent transactions + upcoming reminders
    final items = <_TimelineItem>[];

    for (final t in p.transactions.take(20)) {
      items.add(_TimelineItem(dateTime: t.dateTime, transaction: t));
    }
    for (final r in p.reminders) {
      items.add(_TimelineItem(dateTime: r.dateTime, reminder: r));
    }
    items.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('⏰ Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _showAddReminder(context),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_today,
              message: 'No timeline events',
              subtitle: 'Transactions and reminders appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isReminder = item.reminder != null;
                final isFuture = item.dateTime.isAfter(now);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline spine
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMM d').format(item.dateTime),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              DateFormat('h:mm a').format(item.dateTime),
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isReminder
                                  ? AppTheme.yellow
                                  : (isFuture
                                      ? AppTheme.green
                                      : AppTheme.accent),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (i < items.length - 1)
                            Expanded(
                              child: Container(
                                width: 1,
                                color: AppTheme.border,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: isReminder
                              ? _ReminderCard(reminder: item.reminder!)
                              : _TransactionCard(
                                  transaction: item.transaction!,
                                  currency: p.settings.currency,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddReminder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

class _TimelineItem {
  final DateTime dateTime;
  final Transaction? transaction;
  final Reminder? reminder;

  const _TimelineItem({
    required this.dateTime,
    this.transaction,
    this.reminder,
  });
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String currency;

  const _TransactionCard({
    required this.transaction,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(t.category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(0)}',
            style: TextStyle(
                color: isIncome ? AppTheme.green : AppTheme.red,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isPast = reminder.dateTime.isBefore(DateTime.now());
    return GlassCard(
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(
        colors: [
          AppTheme.yellow.withOpacity(0.1),
          AppTheme.card,
        ],
      ),
      child: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (reminder.note != null)
                  Text(reminder.note!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Past',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 9)),
            )
          else
            IconButton(
              icon: const Icon(Icons.close,
                  size: 14, color: AppTheme.textSecondary),
              onPressed: () =>
                  context.read<AppProvider>().deleteReminder(reminder.id),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
        child: child!,
      ),
    );
    if (d == null) return;
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
    setState(() {
      _dateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    context.read<AppProvider>().addReminder(Reminder(
      title: _titleCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      dateTime: _dateTime,
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
        children: [
          const Text('Add Reminder',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.alarm, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            onTap: _pickDateTime,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppTheme.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(_dateTime),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Set Reminder', icon: Icons.alarm_add, onTap: _submit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
