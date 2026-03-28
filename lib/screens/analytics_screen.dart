import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cur = p.settings.currency;
    final fmt = NumberFormat('#,##0.00');
    final catSpend = p.categorySpending;
    final sortedCats = catSpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: const Icon(Icons.bar_chart_rounded, color: AppTheme.accent),
        leadingWidth: 48,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _SummaryCard(icon: Icons.arrow_upward_rounded, label: 'This Month',
                value: '$cur${fmt.format(p.monthSpent)}', color: AppTheme.red),
            const SizedBox(width: 10),
            _SummaryCard(icon: Icons.today_outlined, label: 'Today',
                value: '$cur${fmt.format(p.todaySpent)}', color: AppTheme.orange),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _SummaryCard(icon: Icons.call_received_outlined, label: 'To Receive',
                value: '$cur${fmt.format(p.totalOwed)}', color: AppTheme.green),
            const SizedBox(width: 10),
            _SummaryCard(icon: Icons.call_made_outlined, label: 'To Pay',
                value: '$cur${fmt.format(p.totalOwing)}', color: AppTheme.red),
          ]),

          const SizedBox(height: 24),
          const SectionHeader(title: '7-Day Spending'),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(height: 180, child: _LineChart(data: p.last7DaysSpending)),
          ),

          const SizedBox(height: 24),
          if (sortedCats.isNotEmpty) ...[
            const SectionHeader(title: 'By Category'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: sortedCats.map((entry) {
                  final pct = sortedCats.first.value > 0
                      ? entry.value / sortedCats.first.value : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          Icon(entry.key.icon, size: 14, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          Text(entry.key.label,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                        ]),
                        Text('$cur${fmt.format(entry.value)}',
                            style: const TextStyle(color: AppTheme.textPrimary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppTheme.border,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                          minHeight: 6,
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const SectionHeader(title: 'Spending by Time'),
          const SizedBox(height: 12),
          _TimeHeatmap(transactions: p.transactions),

          const SizedBox(height: 24),
          const SectionHeader(title: 'Hidden vs Public'),
          const SizedBox(height: 12),
          _HiddenVsPublic(
            publicCount: p.publicTransactions.length,
            hiddenCount: p.hiddenTransactions.length,
            publicAmount: p.publicTransactions
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (s, t) => s + t.amount),
            hiddenAmount: p.hiddenTransactions
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (s, t) => s + t.amount),
            currency: cur,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _SummaryCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _LineChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const _LineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
    final maxY = data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);

    return LineChart(LineChartData(
      maxY: maxY > 0 ? maxY * 1.2 : 100,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppTheme.border, strokeWidth: 1)),
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
              return Text(DateFormat('E').format(data[idx].key),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10));
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: AppTheme.accentGrad,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            colors: [AppTheme.accent.withOpacity(0.3), AppTheme.accent.withOpacity(0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          )),
        ),
      ],
    ));
  }
}

class _TimeHeatmap extends StatelessWidget {
  final List<Transaction> transactions;
  const _TimeHeatmap({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense);
    int morning = 0, afternoon = 0, evening = 0, night = 0;
    double mAmt = 0, aAmt = 0, eAmt = 0, nAmt = 0;
    for (final t in expenses) {
      final h = t.dateTime.hour;
      if (h >= 5 && h < 12)       { morning++;   mAmt += t.amount; }
      else if (h >= 12 && h < 17) { afternoon++; aAmt += t.amount; }
      else if (h >= 17 && h < 21) { evening++;   eAmt += t.amount; }
      else                         { night++;     nAmt += t.amount; }
    }
    final total = mAmt + aAmt + eAmt + nAmt;
    return GlassCard(
      child: Column(children: [
        _row(Icons.wb_twilight_outlined, 'Morning',   '5am–12pm',  morning,   mAmt, total),
        const Divider(color: AppTheme.border, height: 16),
        _row(Icons.wb_sunny_outlined,    'Afternoon', '12pm–5pm',  afternoon, aAmt, total),
        const Divider(color: AppTheme.border, height: 16),
        _row(Icons.wb_cloudy_outlined,   'Evening',   '5pm–9pm',   evening,   eAmt, total),
        const Divider(color: AppTheme.border, height: 16),
        _row(Icons.nightlight_outlined,  'Night',     '9pm–5am',   night,     nAmt, total),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String sub, int count, double amount, double total) {
    final pct = total > 0 ? amount / total : 0.0;
    return Row(children: [
      SizedBox(width: 120, child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textPrimary,
              fontSize: 12, fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ])),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$count txn', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent), minHeight: 5)),
      ])),
    ]);
  }
}

class _HiddenVsPublic extends StatelessWidget {
  final int publicCount, hiddenCount;
  final double publicAmount, hiddenAmount;
  final String currency;
  const _HiddenVsPublic({required this.publicCount, required this.hiddenCount,
      required this.publicAmount, required this.hiddenAmount, required this.currency});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final total = publicAmount + hiddenAmount;
    final hiddenPct = total > 0 ? hiddenAmount / total : 0.0;
    return GlassCard(child: Column(children: [
      Row(children: [
        Expanded(child: _stat(Icons.public_outlined, 'Public',
            publicCount, publicAmount, AppTheme.accent, fmt)),
        Container(width: 1, height: 50, color: AppTheme.border),
        Expanded(child: _stat(Icons.lock_outline, 'Hidden',
            hiddenCount, hiddenAmount, AppTheme.accentLight, fmt)),
      ]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Hidden share', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text('${(hiddenPct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: AppTheme.accentLight,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: hiddenPct,
            backgroundColor: AppTheme.accent.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(AppTheme.accentLight), minHeight: 6)),
    ]));
  }

  Widget _stat(IconData icon, String label, int count, double amount, Color color, NumberFormat fmt) =>
      Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text('$count entries', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text('$currency${fmt.format(amount)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ]);
}
