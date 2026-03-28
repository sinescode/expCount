import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'add_transaction.dart';
import 'vault_screen.dart';
import 'due_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cur = p.settings.currency;
    final fmt = NumberFormat('#,##0.00');

    if (p.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.card,
        onRefresh: () async => p.load(),
        child: CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.bg,
            title: Row(children: [
              const Icon(Icons.account_balance_wallet, color: AppTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text('ExpCount',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              SaveStatusIndicator(status: p.saveStatus),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.search_outlined, color: AppTheme.textSecondary),
                onPressed: () => _showSearch(context, p),
              ),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _BalanceCard(balance: p.totalBalance, todaySpent: p.todaySpent,
                    monthSpent: p.monthSpent, currency: cur, fmt: fmt, settings: p.settings),

                const SizedBox(height: 14),
                const _QuickActions(),
                const SizedBox(height: 20),

                // Due/Owe summary
                if (p.debts.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Due & Owe',
                    trailing: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DueScreen())),
                      child: const Text('See all',
                          style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: GlassCard(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0A2010), Color(0xFF0D1A0D)]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.call_received, size: 13, color: AppTheme.green),
                            const SizedBox(width: 4),
                            const Text('You receive',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ]),
                          const SizedBox(height: 4),
                          Text('$cur${fmt.format(p.totalOwed)}',
                              style: const TextStyle(color: AppTheme.green,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassCard(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2A0A10), Color(0xFF1A0D0D)]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.call_made, size: 13, color: AppTheme.red),
                            const SizedBox(width: 4),
                            const Text('You owe',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                            if (p.overdueDebts.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                    color: AppTheme.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text('${p.overdueDebts.length} overdue',
                                    style: const TextStyle(color: AppTheme.red,
                                        fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text('$cur${fmt.format(p.totalOwing)}',
                              style: const TextStyle(color: AppTheme.red,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // Weekly chart
                if (p.transactions.isNotEmpty) ...[
                  const SectionHeader(title: 'This Week'),
                  const SizedBox(height: 12),
                  _WeekChart(data: p.last7DaysSpending, currency: cur),
                  const SizedBox(height: 20),
                ],

                // Recent transactions
                SectionHeader(
                  title: 'Recent',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('All',
                        style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                if (p.publicTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(icon: Icons.receipt_long_outlined,
                        message: 'No transactions yet',
                        subtitle: 'Tap + to add your first entry'),
                  )
                else
                  ...p.publicTransactions.take(8).map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(
                      transaction: t, currency: cur,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: t))),
                      onDelete: () => context.read<AppProvider>().deleteTransaction(t.id),
                    ),
                  )),

                // Upcoming reminders
                if (p.upcomingReminders.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Reminders'),
                  const SizedBox(height: 8),
                  ...p.upcomingReminders.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: AppTheme.yellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.alarm_outlined, size: 18, color: AppTheme.yellow),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.title,
                              style: const TextStyle(color: AppTheme.textPrimary,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(DateFormat('MMM d, h:mm a').format(r.dateTime),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: AppTheme.textSecondary),
                          onPressed: () => context.read<AppProvider>().deleteReminder(r.id),
                        ),
                      ]),
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showSearch(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SearchSheet(provider: p),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance, todaySpent, monthSpent;
  final String currency;
  final NumberFormat fmt;
  final AppSettings settings;

  const _BalanceCard({required this.balance, required this.todaySpent,
      required this.monthSpent, required this.currency,
      required this.fmt, required this.settings});

  @override
  Widget build(BuildContext context) {
    final budgetUsage = settings.monthlyBudget != null && settings.monthlyBudget! > 0
        ? (monthSpent / settings.monthlyBudget!).clamp(0.0, 1.0)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppTheme.accentGrad, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        Text('$currency${fmt.format(balance)}',
            style: const TextStyle(color: Colors.white, fontSize: 34,
                fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 16),
        Row(children: [
          _stat(Icons.today_outlined, 'Today', '$currency${fmt.format(todaySpent)}', AppTheme.red),
          const SizedBox(width: 24),
          _stat(Icons.calendar_month_outlined, 'Month', '$currency${fmt.format(monthSpent)}', AppTheme.orange),
        ]),
        if (budgetUsage != null) ...[
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Budget: ${(budgetUsage * 100).toStringAsFixed(0)}% used',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text('$currency${fmt.format(settings.monthlyBudget! - monthSpent)} left',
                style: TextStyle(
                    color: budgetUsage > 0.8 ? AppTheme.red : Colors.white70, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budgetUsage,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(budgetUsage > 0.8 ? AppTheme.red : Colors.white),
              minHeight: 5,
            ),
          ),
        ],
      ]),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 11, color: Colors.white54),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
    ],
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.arrow_upward_rounded, 'Expense', AppTheme.red,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()))),
      (Icons.arrow_downward_rounded, 'Income', AppTheme.green,
          () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(initialType: TransactionType.income)))),
      (Icons.lock_outline, 'Hidden', AppTheme.accentLight,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()))),
      (Icons.handshake_outlined, 'Debt', AppTheme.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DueScreen()))),
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GlassCard(
            onTap: a.$4,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: a.$3.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(a.$1, size: 18, color: a.$3),
              ),
              const SizedBox(height: 6),
              Text(a.$2, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      )).toList(),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  final String currency;
  const _WeekChart({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 140,
        child: BarChart(BarChartData(
          maxY: maxVal > 0 ? maxVal * 1.2 : 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('E').format(data[idx].key),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: data.asMap().entries.map((e) {
            final isToday = e.value.key.day == DateTime.now().day &&
                e.value.key.month == DateTime.now().month;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.value,
                gradient: isToday ? AppTheme.accentGrad
                    : LinearGradient(
                        colors: [AppTheme.accent.withOpacity(0.5), AppTheme.accent.withOpacity(0.25)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter),
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ]);
          }).toList(),
        )),
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final AppProvider provider;
  const _SearchSheet({required this.provider});
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  List<Transaction> _results = [];
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16),
        child: Column(children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl, autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search_outlined, size: 18)),
            onChanged: (q) => setState(() => _results = widget.provider.searchTransactions(q)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _results.isEmpty && _ctrl.text.isNotEmpty
                ? const EmptyState(icon: Icons.search_off_outlined, message: 'No results found')
                : ListView.separated(
                    controller: scroll,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => TransactionTile(
                      transaction: _results[i],
                      currency: widget.provider.settings.currency,
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
