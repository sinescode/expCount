import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  bool _showHidden = false;   // toggle to reveal hidden entries on the planner

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final now = DateTime.now();
    final cur = p.settings.currency;

    // Build timeline items
    // All public transactions
    final items = <_TimelineItem>[];
    for (final t in p.publicTransactions.take(30)) {
      items.add(_TimelineItem(dateTime: t.dateTime, transaction: t));
    }

    // Hidden transactions — shown only when vault is unlocked AND _showHidden is true
    if (_showHidden && p.vaultUnlocked) {
      for (final t in p.hiddenTransactions.take(20)) {
        items.add(_TimelineItem(dateTime: t.dateTime, transaction: t, isHiddenEntry: true));
      }
    }

    // Reminders
    for (final r in p.reminders) {
      items.add(_TimelineItem(dateTime: r.dateTime, reminder: r));
    }

    items.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          // Hidden toggle — only show the button if vault is unlocked
          if (p.vaultUnlocked)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _showHidden = !_showHidden),
                icon: Icon(
                  _showHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 16,
                  color: _showHidden ? AppTheme.accent : AppTheme.textSecondary,
                ),
                label: Text(
                  _showHidden ? 'Hide secret' : 'Show secret',
                  style: TextStyle(
                      color: _showHidden ? AppTheme.accent : AppTheme.textSecondary,
                      fontSize: 12),
                ),
              ),
            )
          else if (p.hiddenTransactions.isNotEmpty)
            IconButton(
              tooltip: 'Unlock vault to see hidden entries',
              icon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 18),
              onPressed: () => Navigator.pushNamed(context, '/vault'),
            ),
          IconButton(
            icon: const Icon(Icons.add_alarm_outlined),
            onPressed: () => _showAddReminder(context),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_today_outlined,
              message: 'No timeline events',
              subtitle: 'Transactions and reminders appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isReminder = item.reminder != null;
                final isFuture = item.dateTime.isAfter(now);

                // Date separator
                final showDate = i == 0 ||
                    !_sameDay(items[i - 1].dateTime, item.dateTime);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate) _DateSeparator(date: item.dateTime),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time column
                          SizedBox(
                            width: 54,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                DateFormat('h:mm a').format(item.dateTime),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Spine dot + line
                          Column(children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: item.isHiddenEntry
                                    ? AppTheme.accentLight
                                    : isReminder
                                        ? AppTheme.yellow
                                        : isFuture ? AppTheme.green : AppTheme.accent,
                                shape: BoxShape.circle,
                                border: item.isHiddenEntry
                                    ? Border.all(color: AppTheme.accentLight, width: 2)
                                    : null,
                              ),
                            ),
                            if (i < items.length - 1)
                              Expanded(
                                child: Container(
                                    width: 1, color: AppTheme.border),
                              ),
                          ]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: isReminder
                                  ? _ReminderCard(reminder: item.reminder!)
                                  : _TransactionCard(
                                      transaction: item.transaction!,
                                      currency: cur,
                                      isHidden: item.isHiddenEntry,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.only(left: 64, top: 12, bottom: 4),
      child: Text(label,
          style: TextStyle(
              color: isToday ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

class _TimelineItem {
  final DateTime dateTime;
  final Transaction? transaction;
  final Reminder? reminder;
  final bool isHiddenEntry;

  const _TimelineItem({
    required this.dateTime,
    this.transaction,
    this.reminder,
    this.isHiddenEntry = false,
  });
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final bool isHidden;

  const _TransactionCard({
    required this.transaction, required this.currency, this.isHidden = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    return GlassCard(
      gradient: isHidden
          ? LinearGradient(colors: [
              AppTheme.accentLight.withOpacity(0.08),
              AppTheme.card,
            ])
          : null,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: (isHidden ? AppTheme.accentLight
                    : isIncome ? AppTheme.green : AppTheme.accent)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isHidden ? Icons.lock_outline : t.category.icon,
            size: 16,
            color: isHidden ? AppTheme.accentLight
                : isIncome ? AppTheme.green : AppTheme.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(t.title,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (isHidden) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_outline, size: 8, color: AppTheme.accentLight),
                    const SizedBox(width: 2),
                    const Text('secret', style: TextStyle(
                        color: AppTheme.accentLight, fontSize: 8, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
            if (!isHidden)
              Text(t.category.label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          '${isIncome ? '+' : '-'}$currency${t.amount.toStringAsFixed(0)}',
          style: TextStyle(
              color: isIncome ? AppTheme.green : AppTheme.red,
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ]),
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
      gradient: LinearGradient(colors: [
        AppTheme.yellow.withOpacity(0.08), AppTheme.card,
      ]),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppTheme.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.alarm_outlined, size: 16, color: AppTheme.yellow),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.title,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            if (reminder.note != null)
              Text(reminder.note!,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
        if (isPast)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Past',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
          )
        else
          IconButton(
            icon: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
            onPressed: () async {
              final ok = await confirmDelete(context,
                  title: 'Remove reminder?',
                  message: '"${reminder.title}" will be removed.');
              if (ok && context.mounted) {
                context.read<AppProvider>().deleteReminder(reminder.id);
              }
            },
            constraints: const BoxConstraints(), padding: EdgeInsets.zero,
          ),
      ]),
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
  void dispose() { _titleCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

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
          left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Add Reminder',
            style: TextStyle(color: AppTheme.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.alarm_outlined, size: 18)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes_outlined, size: 18)),
        ),
        const SizedBox(height: 10),
        GlassCard(
          onTap: _pickDateTime,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Text(DateFormat('EEE, MMM d  ·  h:mm a').format(_dateTime),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 16),
        GradientButton(label: 'Set Reminder', icon: Icons.alarm_add_outlined, onTap: _submit),
        const SizedBox(height: 20),
      ]),
    );
  }
}
