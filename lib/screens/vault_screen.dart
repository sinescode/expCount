import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'add_transaction.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _pinCtrl = TextEditingController();
  bool _pinError = false;
  bool _obscure = true;

  @override
  void dispose() { _pinCtrl.dispose(); super.dispose(); }

  void _tryUnlock(AppProvider p) {
    if (p.settings.pin == null || p.verifyPin(_pinCtrl.text)) {
      p.unlockVault();
    } else {
      setState(() => _pinError = true);
      _pinCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: p.vaultUnlocked
          ? _VaultContent(p: p)
          : _LockScreen(
              pinCtrl: _pinCtrl,
              pinError: _pinError,
              hasPin: p.settings.pin != null,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onUnlock: () => _tryUnlock(p),
              onSkip: p.settings.pin == null ? () => p.unlockVault() : null,
            ),
    );
  }
}

class _LockScreen extends StatelessWidget {
  final TextEditingController pinCtrl;
  final bool pinError, hasPin, obscure;
  final VoidCallback onUnlock;
  final VoidCallback? onSkip;
  final VoidCallback onToggleObscure;

  const _LockScreen({
    required this.pinCtrl, required this.pinError, required this.hasPin,
    required this.obscure, required this.onUnlock, required this.onToggleObscure,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.vaultGrad),
      child: SafeArea(
        child: Column(children: [
          AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Secret Vault',
                style: TextStyle(color: AppTheme.textPrimary)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGrad,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent.withOpacity(0.4),
                            blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  const Text('Private Vault',
                      style: TextStyle(color: AppTheme.textPrimary,
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Your hidden entries are encrypted here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 32),
                  if (hasPin) ...[
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: obscure,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textPrimary,
                          fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        hintText: '· · · ·',
                        counterText: '',
                        errorText: pinError ? 'Wrong PIN' : null,
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 18, color: AppTheme.textSecondary),
                          onPressed: onToggleObscure,
                        ),
                      ),
                      onSubmitted: (_) => onUnlock(),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Unlock Vault', icon: Icons.lock_open_outlined, onTap: onUnlock),
                  ] else ...[
                    GradientButton(label: 'Enter Vault', icon: Icons.lock_open_outlined,
                        onTap: onSkip ?? onUnlock),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.settings_outlined, size: 14, color: AppTheme.textSecondary),
                      label: const Text('Set a PIN in Settings for protection',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _VaultContent extends StatelessWidget {
  final AppProvider p;
  const _VaultContent({required this.p});

  @override
  Widget build(BuildContext context) {
    final hidden = p.hiddenTransactions;
    final cur = p.settings.currency;
    final totalHidden = hidden.fold(0.0, (s, t) =>
        s + (t.type == TransactionType.expense ? -t.amount : t.amount));

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.vaultGrad),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Row(children: [
            const Icon(Icons.lock_outline, size: 18, color: AppTheme.accentLight),
            const SizedBox(width: 8),
            const Text('Secret Vault',
                style: TextStyle(color: AppTheme.textPrimary)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outlined, color: AppTheme.accentLight),
              onPressed: () {
                p.lockVault();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(forceHidden: true))),
          icon: const Icon(Icons.add),
          label: const Text('Add Hidden'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Vault balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Hidden Balance',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Text('$cur${totalHidden.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                        color: totalHidden >= 0 ? AppTheme.green : AppTheme.red,
                        fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.shield_outlined, size: 11, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${hidden.length} encrypted entries',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hidden Entries',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: hidden.isEmpty
                  ? const EmptyState(
                      icon: Icons.visibility_off_outlined,
                      message: 'No hidden entries',
                      subtitle: 'Tap the button below to add a secret expense')
                  : ListView.separated(
                      itemCount: hidden.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => TransactionTile(
                        transaction: hidden[i],
                        currency: cur,
                        onTap: () => Navigator.push(ctx,
                            MaterialPageRoute(
                                builder: (_) => AddTransactionScreen(existing: hidden[i]))),
                        onDelete: () => p.deleteTransaction(hidden[i].id),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
