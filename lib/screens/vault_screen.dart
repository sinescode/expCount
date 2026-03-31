import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/widgets.dart';
import '../widgets/filter_sheet.dart';
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
                      gradient: AppTheme.primaryGrad,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.teal.withOpacity(0.35),
                            blurRadius: 24, spreadRadius: 4),
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

class _VaultContent extends StatefulWidget {
  final AppProvider p;
  const _VaultContent({required this.p});
  @override
  State<_VaultContent> createState() => _VaultContentState();
}

class _VaultContentState extends State<_VaultContent> {
  final Set<String> _selected = {};
  TransactionFilter _filter = const TransactionFilter();
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelect(String id) => setState(() {
    if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
  });

  Future<void> _openVaultFilter(BuildContext context) async {
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(current: _filter, isVault: true),
    );
    if (result != null) setState(() => _filter = result);
  }

  void _deleteSelected() {
    final count = _selected.length;
    final ids = List<String>.from(_selected);
    setState(() => _selected.clear());
    widget.p.deleteTransactions(ids);
    showUndoSnackbar(context, widget.p,
        'Deleted $count hidden entr${count == 1 ? 'y' : 'ies'}');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
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
          title: _selecting
              ? Text('${_selected.length} selected',
                  style: const TextStyle(color: AppTheme.accent,
                      fontWeight: FontWeight.w700))
              : Row(children: [
                  const Icon(Icons.lock_outline, size: 18,
                      color: AppTheme.accentLight),
                  const SizedBox(width: 8),
                  const Text('Secret Vault',
                      style: TextStyle(color: AppTheme.textPrimary)),
                ]),
          actions: _selecting
              ? [
                  TextButton(
                    onPressed: () => setState(
                        () => _selected.addAll(hidden.map((t) => t.id))),
                    child: const Text('All',
                        style: TextStyle(color: AppTheme.accent)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                    onPressed: _deleteSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _selected.clear()),
                  ),
                ]
              : [
                  FilterButton(
                    filter: _filter,
                    onTap: () => _openVaultFilter(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search_outlined,
                        color: AppTheme.textSecondary),
                    onPressed: () => _showVaultSearch(context, p, cur),
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_outlined,
                        color: AppTheme.accentLight),
                    onPressed: () {
                      p.lockVault();
                      Navigator.pop(context);
                    },
                  ),
                ],
        ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppTheme.accent,
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>
                        const AddTransactionScreen(forceHidden: true))),
                icon: const Icon(Icons.add),
                label: const Text('Add Hidden'),
              ),
        body: Column(children: [
          // Vault balance header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline, size: 14,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Hidden Balance',
                      style: TextStyle(color: AppTheme.textSecondary,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Text('$cur${totalHidden.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                        color: totalHidden >= 0 ? AppTheme.green : AppTheme.red,
                        fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.shield_outlined, size: 11,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${hidden.length} encrypted entries',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Active filter bar
          if (_filter.isActive && !_selecting)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ActiveFilterBar(
                filter: _filter,
                onClear: () => setState(() => _filter = const TransactionFilter()),
              ),
            ),
          // Filter summary — totals for the filtered hidden entries
          if (_filter.isActive && !_selecting)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Builder(builder: (ctx) {
                final filtered = p.filterHiddenTransactions(
                  date: _filter.date, from: _filter.from, to: _filter.to,
                  category: _filter.category, type: _filter.type,
                );
                final totalExpense = filtered
                    .where((t) => t.type == TransactionType.expense)
                    .fold(0.0, (s, t) => s + t.amount);
                final totalIncome = filtered
                    .where((t) => t.type == TransactionType.income)
                    .fold(0.0, (s, t) => s + t.amount);
                final net = totalIncome - totalExpense;
                if (filtered.isEmpty) return const SizedBox.shrink();
                return _VaultFilterSummary(
                  currency: cur,
                  totalExpense: totalExpense,
                  totalIncome: totalIncome,
                  net: net,
                  count: filtered.length,
                );
              }),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text(
                _filter.isActive ? 'Filtered Results' : 'Hidden Entries',
                style: TextStyle(color: context.textColor,
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_filter.isActive)
                Builder(builder: (ctx) {
                  final count = p.filterHiddenTransactions(
                    date: _filter.date, from: _filter.from, to: _filter.to,
                    category: _filter.category, type: _filter.type,
                  ).length;
                  return Text('$count found',
                      style: const TextStyle(
                          color: AppTheme.teal, fontSize: 12,
                          fontWeight: FontWeight.w500));
                })
              else if (!_selecting && hidden.isNotEmpty)
                Text('Long-press to select',
                    style: TextStyle(
                        color: context.mutedColor.withOpacity(0.6),
                        fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(builder: (ctx) {
              final list = _filter.isActive
                  ? p.filterHiddenTransactions(
                      date: _filter.date, from: _filter.from, to: _filter.to,
                      category: _filter.category, type: _filter.type,
                    )
                  : hidden;

              if (list.isEmpty) {
                return EmptyState(
                  icon: _filter.isActive
                      ? Icons.filter_alt_off_outlined
                      : Icons.visibility_off_outlined,
                  message: _filter.isActive
                      ? 'No results for this filter'
                      : 'No hidden entries',
                  subtitle: _filter.isActive
                      ? 'Try a different date or category'
                      : 'Tap the button below to add a secret expense',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (listCtx, i) => TransactionTile(
                  transaction: list[i],
                  currency: cur,
                  selectable: _selecting,
                  selected: _selected.contains(list[i].id),
                  onSelect: () => _toggleSelect(list[i].id),
                  onTap: _selecting
                      ? () => _toggleSelect(list[i].id)
                      : () => Navigator.push(listCtx,
                          MaterialPageRoute(builder: (_) =>
                              AddTransactionScreen(existing: list[i]))),
                  onDelete: _selecting
                      ? null
                      : () {
                          p.deleteTransaction(list[i].id);
                          showUndoSnackbar(context, p,
                              'Deleted "${list[i].title}"');
                        },
                ),
              );
            }),
          ),
        ]),
        bottomNavigationBar: _selecting
            ? BulkActionBar(
                selectedCount: _selected.length,
                onDelete: _deleteSelected,
                onCancel: () => setState(() => _selected.clear()),
              )
            : null,
      ),
    );
  }

  void _showVaultSearch(BuildContext context, AppProvider p, String cur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _VaultSearchSheet(provider: p, currency: cur),
    );
  }
}

// ── Vault search sheet ────────────────────────────────────────────────────────
class _VaultSearchSheet extends StatefulWidget {
  final AppProvider provider;
  final String currency;
  const _VaultSearchSheet({required this.provider, required this.currency});
  @override
  State<_VaultSearchSheet> createState() => _VaultSearchSheetState();
}

class _VaultSearchSheetState extends State<_VaultSearchSheet> {
  List<Transaction> _results = [];
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.vaultGrad,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16, right: 16, top: 16),
          child: Column(children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.accentLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.lock_outline, size: 14, color: AppTheme.accentLight),
              const SizedBox(width: 6),
              const Text('Search Secret Vault',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search hidden entries...',
                prefixIcon: const Icon(Icons.search_outlined, size: 18),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppTheme.accentLight.withOpacity(0.5), width: 1.5),
                ),
              ),
              onChanged: (q) => setState(() {
                _results = q.isEmpty
                    ? []
                    : widget.provider.searchHiddenTransactions(q);
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ctrl.text.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.manage_search_outlined, size: 48,
                          color: AppTheme.accentLight.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('Type to search hidden entries',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]))
                  : _results.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_off_outlined, size: 48,
                              color: AppTheme.textSecondary.withOpacity(0.35)),
                          const SizedBox(height: 12),
                          const Text('No hidden entries found',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ]))
                      : ListView.separated(
                          controller: scroll,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final t = _results[i];
                            final isIncome = t.type == TransactionType.income;
                            return GlassCard(
                              gradient: LinearGradient(colors: [
                                AppTheme.pathCardBg(context.isDark),
                                AppTheme.pathCardBg(context.isDark),
                              ]),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        AddTransactionScreen(existing: t)));
                              },
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentLight.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.lock_outline,
                                      size: 16, color: AppTheme.accentLight),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Text(t.title,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(t.category.icon, size: 10,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t.category.label}  ·  '
                                      '${t.dateTime.day}/${t.dateTime.month}/${t.dateTime.year}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                  ]),
                                  if (t.note != null)
                                    Text(t.note!,
                                        style: TextStyle(
                                            color: AppTheme.textSecondary.withOpacity(0.7),
                                            fontSize: 10),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                const SizedBox(width: 8),
                                Text(
                                  '${isIncome ? '+' : '-'}${widget.currency}'
                                  '${t.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: isIncome ? AppTheme.green : AppTheme.red,
                                      fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ]),
                            );
                          },
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Vault filter summary card ─────────────────────────────────────────────────
class _VaultFilterSummary extends StatelessWidget {
  final String currency;
  final double totalExpense, totalIncome, net;
  final int count;

  const _VaultFilterSummary({
    required this.currency,
    required this.totalExpense,
    required this.totalIncome,
    required this.net,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final netPositive = net >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.teal.withOpacity(0.2)),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.teal.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(
                bottom: BorderSide(color: AppTheme.teal.withOpacity(0.15))),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 12, color: AppTheme.teal),
            const SizedBox(width: 6),
            const Text('Vault Filter Summary',
                style: TextStyle(color: AppTheme.teal, fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count entr${count == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(color: AppTheme.teal, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _stat(Icons.arrow_upward_rounded, 'Expense',
                '$currency${fmt.format(totalExpense)}', AppTheme.red),
            _vdivider(),
            _stat(Icons.arrow_downward_rounded, 'Income',
                '$currency${fmt.format(totalIncome)}', AppTheme.green),
            _vdivider(),
            _stat(
              netPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              'Net',
              '${netPositive ? '+' : ''}$currency${fmt.format(net.abs())}',
              netPositive ? AppTheme.green : AppTheme.red,
            ),
          ]),
        ),
        if (totalExpense > 0 || totalIncome > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalIncome > 0
                    ? (totalExpense / totalIncome).clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: AppTheme.green.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(
                    totalExpense > totalIncome ? AppTheme.red : AppTheme.teal),
                minHeight: 5,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) =>
      Expanded(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ]));

  Widget _vdivider() => Container(
      width: 1, height: 36,
      color: AppTheme.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}
