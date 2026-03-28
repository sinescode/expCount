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

// Bangladesh + common currencies — no Indian Rupee
const _currencies = ['৳', '\$', '€', '£', '¥', '﷼'];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final s = p.settings;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Settings & Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data management
          const SectionHeader(title: 'Data Management'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(children: [
              _tile(context, 'Export JSON', 'Share data as a JSON file',
                  Icons.upload_file_outlined, AppTheme.green,
                  () => _exportJson(context, p)),
              const Divider(color: AppTheme.border, height: 1),
              _tile(context, 'Copy JSON', 'Copy raw JSON to clipboard',
                  Icons.copy_outlined, AppTheme.accent, () {
                Clipboard.setData(ClipboardData(text: p.exportJson()));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON copied to clipboard')));
              }),
              const Divider(color: AppTheme.border, height: 1),
              _tile(context, 'Import JSON', 'Restore data from JSON file',
                  Icons.download_outlined, AppTheme.orange,
                  () => _importJson(context, p)),
              const Divider(color: AppTheme.border, height: 1),
              _tile(context, 'Force Save', 'Manually sync to storage',
                  Icons.save_outlined, AppTheme.yellow,
                  () => p.updateSettings(p.settings)),
            ]),
          ),

          const SizedBox(height: 8),

          // Auto-save path info
          GlassCard(
            gradient: const LinearGradient(colors: [Color(0xFF0A2010), Color(0xFF0D1A0D)]),
            child: Row(children: [
              const Icon(Icons.folder_outlined, color: AppTheme.green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Auto-save path',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  const Text('/storage/emulated/0/expcount/mydata.json',
                      style: TextStyle(color: AppTheme.green, fontSize: 11,
                          fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Text('Syncs on every change  ·  Hidden entries are AES-256 encrypted',
                      style: TextStyle(color: AppTheme.green.withOpacity(0.6), fontSize: 9)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // General
          const SectionHeader(title: 'General'),
          const SizedBox(height: 10),

          GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                const Icon(Icons.attach_money_outlined, color: AppTheme.accent, size: 18),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Currency', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    Text('Default: ৳ (Bangladeshi Taka)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
                ),
                DropdownButton<String>(
                  value: s.currency,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  underline: const SizedBox.shrink(),
                  items: _currencies.map((c) => DropdownMenuItem(
                    value: c, child: Text(c, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) p.updateSettings(s.copyWith(currency: v));
                  },
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // Security
          const SectionHeader(title: 'Security'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(children: [
              SwitchListTile(
                title: Row(children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  const Text('App Lock',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                ]),
                subtitle: const Text('Lock app on open',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                value: s.appLockEnabled,
                onChanged: (v) => p.updateSettings(s.copyWith(appLockEnabled: v)),
                activeColor: AppTheme.accent,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(color: AppTheme.border, height: 1),
              _tile(context, 'Set Vault PIN',
                  s.pin != null ? 'PIN is set — tap to change' : 'Protect hidden vault with PIN',
                  Icons.pin_outlined, AppTheme.accentLight,
                  () => _showSetPin(context, p, s)),
            ]),
          ),

          const SizedBox(height: 24),

          // Budget
          const SectionHeader(title: 'Budget Goals'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(children: [
              _budgetRow(context, p, s, 'Monthly Budget', s.monthlyBudget, true),
              const SizedBox(height: 10),
              _budgetRow(context, p, s, 'Daily Budget', s.dailyBudget, false),
            ]),
          ),

          const SizedBox(height: 24),

          // Stats
          const SectionHeader(title: 'Data Stats'),
          const SizedBox(height: 10),

          GlassCard(
            child: Column(children: [
              _statRow('Total Transactions', '${p.transactions.length}'),
              _statRow('Hidden Entries', '${p.hiddenTransactions.length}'),
              _statRow('Debts Tracked', '${p.debts.length}'),
              _statRow('Reminders', '${p.reminders.length}'),
              _statRow('Settled Debts',
                  '${p.debts.where((d) => d.status == DebtStatus.settled).length}'),
            ]),
          ),

          const SizedBox(height: 24),

          const SectionHeader(title: 'Danger Zone'),
          const SizedBox(height: 10),

          GlassCard(
            child: _tile(context, 'Clear All Data', 'This cannot be undone',
                Icons.delete_forever_outlined, AppTheme.red,
                () => _confirmClear(context, p)),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) =>
      ListTile(
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(color: AppTheme.textPrimary,
                fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 16),
      );

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary,
          fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _budgetRow(BuildContext context, AppProvider p, AppSettings s,
      String label, double? current, bool isMonthly) {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(0) ?? '');
    return Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
      SizedBox(
        width: 130,
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            prefix: Text(s.currency,
                style: const TextStyle(color: AppTheme.textSecondary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    ]);
  }

  Future<void> _exportJson(BuildContext context, AppProvider p) async {
    try {
      final json = p.exportJson();
      final dir = await getTemporaryDirectory();
      final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/expcount_$ts.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'ExpCount Data Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success ? 'Import successful' : 'Import failed')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import error: $e')));
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
          decoration: const InputDecoration(hintText: '4–6 digit PIN', counterText: ''),
        ),
        actions: [
          if (s.pin != null)
            TextButton(
              onPressed: () {
                p.updateSettings(s.copyWith(pin: null));
                Navigator.pop(context);
              },
              child: const Text('Remove PIN', style: TextStyle(color: AppTheme.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              if (ctrl.text.length >= 4) {
                p.updateSettings(s.copyWith(pin: ctrl.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN set successfully')));
              }
            },
            child: const Text('Set', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final canDelete = ctrl.text.trim() == 'DELETE';
          return AlertDialog(
            backgroundColor: AppTheme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 22),
              const SizedBox(width: 8),
              const Text('Clear All Data?',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'This permanently deletes ALL transactions, debts, and reminders. There is no undo.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Type  DELETE  to confirm:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: AppTheme.red,
                    fontWeight: FontWeight.w700, letterSpacing: 2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.4), letterSpacing: 2),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.red, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: canDelete ? () {
                  p.importJson('{"transactions":[],"debts":[],"reminders":[]}');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All data cleared.')));
                } : null,
                style: TextButton.styleFrom(
                  backgroundColor:
                      canDelete ? AppTheme.red.withOpacity(0.15) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Delete All',
                    style: TextStyle(
                        color: canDelete
                            ? AppTheme.red
                            : AppTheme.textSecondary.withOpacity(0.4),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }
}
