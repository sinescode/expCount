import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final s = p.settings;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('⚙️ Settings & Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export section
          const SectionHeader(title: '📦 Data Management'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(
              children: [
                _tile(
                  '📤 Export JSON',
                  'Share your data as JSON file',
                  Icons.upload_file,
                  AppTheme.green,
                  () => _exportJson(context, p),
                ),
                const Divider(color: AppTheme.border, height: 1),
                _tile(
                  '📋 Copy JSON',
                  'Copy raw JSON to clipboard',
                  Icons.copy,
                  AppTheme.accent,
                  () {
                    Clipboard.setData(ClipboardData(text: p.exportJson()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON copied to clipboard')),
                    );
                  },
                ),
                const Divider(color: AppTheme.border, height: 1),
                _tile(
                  '📥 Import JSON',
                  'Restore data from JSON file',
                  Icons.download,
                  AppTheme.orange,
                  () => _importJson(context, p),
                ),
                const Divider(color: AppTheme.border, height: 1),
                _tile(
                  '🔄 Force Save',
                  'Manually save to /expcount/mydata.json',
                  Icons.save,
                  AppTheme.yellow,
                  () async {
                    // Trigger re-save by making a no-op update
                    p.updateSettings(p.settings);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Force save triggered')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // File path info
          GlassCard(
            gradient: const LinearGradient(
                colors: [Color(0xFF0A2010), Color(0xFF0D1A0D)]),
            child: Row(
              children: [
                const Icon(Icons.folder, color: AppTheme.green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-save location',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      const Text(
                        '/storage/emulated/0/expcount/mydata.json',
                        style: TextStyle(
                            color: AppTheme.green,
                            fontSize: 11,
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-syncs on every change',
                        style: TextStyle(
                            color: AppTheme.green.withOpacity(0.6),
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // General settings
          const SectionHeader(title: '🎨 General'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(
              children: [
                // Currency
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_exchange,
                          color: AppTheme.accent, size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Currency',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                      DropdownButton<String>(
                        value: s.currency,
                        dropdownColor: AppTheme.card,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        underline: const SizedBox.shrink(),
                        items: ['₹', '\$', '€', '£', '¥', '₩']
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            p.updateSettings(s.copyWith(currency: v));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security
          const SectionHeader(title: '🔐 Security'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('App Lock',
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14)),
                  subtitle: const Text('Lock app on open',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  value: s.appLockEnabled,
                  onChanged: (v) =>
                      p.updateSettings(s.copyWith(appLockEnabled: v)),
                  activeColor: AppTheme.accent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const Divider(color: AppTheme.border, height: 1),
                _tile(
                  '🔑 Set Vault PIN',
                  s.pin != null ? 'PIN is set (tap to change)' : 'Protect hidden vault',
                  Icons.pin,
                  AppTheme.accentLight,
                  () => _showSetPin(context, p, s),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Budget
          const SectionHeader(title: '🎯 Budget Goals'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _budgetField(
                  context, p, s,
                  '📅 Monthly Budget',
                  s.monthlyBudget,
                  true,
                ),
                const SizedBox(height: 10),
                _budgetField(
                  context, p, s,
                  '🌞 Daily Budget',
                  s.dailyBudget,
                  false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats
          const SectionHeader(title: '📊 Data Stats'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(
              children: [
                _statRow('Total Transactions', '${p.transactions.length}'),
                _statRow('Hidden Entries', '${p.hiddenTransactions.length}'),
                _statRow('Debts Tracked', '${p.debts.length}'),
                _statRow('Reminders', '${p.reminders.length}'),
                _statRow('Settled Debts',
                    '${p.debts.where((d) => d.status == DebtStatus.settled).length}'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger zone
          const SectionHeader(title: '⚠️ Danger Zone'),
          const SizedBox(height: 10),

          GlassCard(
            child: _tile(
              '🗑️ Clear All Data',
              'This cannot be undone',
              Icons.delete_forever,
              AppTheme.red,
              () => _confirmClear(context, p),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _tile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textSecondary, size: 16),
      );

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _budgetField(BuildContext context, AppProvider p, AppSettings s,
      String label, double? current, bool isMonthly) {
    final ctrl =
        TextEditingController(text: current?.toStringAsFixed(0) ?? '');
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14)),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefix: Text(s.currency,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onSubmitted: (v) {
              final amt = double.tryParse(v);
              if (isMonthly) {
                p.updateSettings(s.copyWith(monthlyBudget: amt));
              } else {
                p.updateSettings(s.copyWith(dailyBudget: amt));
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportJson(BuildContext context, AppProvider p) async {
    try {
      final json = p.exportJson();
      final dir = await getTemporaryDirectory();
      final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/expcount_$ts.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)],
          text: 'ExpCount Data Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importJson(BuildContext context, AppProvider p) async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;
      final content = await File(path).readAsString();
      final success = await p.importJson(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  success ? '✅ Import successful' : '❌ Import failed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  void _showSetPin(BuildContext context, AppProvider p, AppSettings s) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Set Vault PIN',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: '4–6 digit PIN',
            counterText: '',
          ),
        ),
        actions: [
          if (s.pin != null)
            TextButton(
              onPressed: () {
                p.updateSettings(s.copyWith(pin: null));
                Navigator.pop(context);
              },
              child: const Text('Remove PIN',
                  style: TextStyle(color: AppTheme.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.length >= 4) {
                p.updateSettings(s.copyWith(pin: ctrl.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN set successfully')),
                );
              }
            },
            child: const Text('Set',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Clear All Data?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'This will permanently delete all transactions, debts, and reminders.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              p.importJson('{"transactions":[],"debts":[],"reminders":[]}');
              Navigator.pop(context);
            },
            child: const Text('Delete All',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
