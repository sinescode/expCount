import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import 'dashboard.dart';
import 'analytics_screen.dart';
import 'planner_screen.dart';
import 'settings_screen.dart';
import 'add_transaction.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    PlannerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.bar_chart_rounded, 'Analytics'),
                _fabButton(),
                _navItem(2, Icons.calendar_today_rounded, 'Planner'),
                _navItem(3, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final selected = _index == idx;
    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: selected ? AppTheme.accent : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _fabButton() => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
    child: Container(
      width: 54, height: 54,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGrad,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 26),
    ),
  );
}
