import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

// ── Undo snackbar ─────────────────────────────────────────────────────────────
/// Call after any delete to show the 5-second undo snackbar.
void showUndoSnackbar(BuildContext context, AppProvider provider, String label) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 5),
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      behavior: SnackBarBehavior.floating,
      content: Row(children: [
        const Icon(Icons.delete_outline, color: AppTheme.red, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ),
      ]),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: AppTheme.accent,
        onPressed: () => provider.undo(),
      ),
    ),
  );
}

// ── Confirm-delete dialog ─────────────────────────────────────────────────────
Future<bool> confirmDelete(BuildContext context, {
  String title = 'Delete this entry?',
  String message = 'This cannot be undone.',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      ]),
      content: Text(message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            backgroundColor: AppTheme.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete',
              style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result == true;
}

// ── Glass card ────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final bool selected;

  const GlassCard({
    super.key, required this.child, this.padding,
    this.gradient, this.onTap, this.onLongPress,
    this.radius = 16, this.selected = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    onLongPress: onLongPress,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGrad,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected ? AppTheme.accent : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppTheme.accent.withOpacity(0.2), blurRadius: 8)]
            : null,
      ),
      child: child,
    ),
  );
}

// ── Amount display ────────────────────────────────────────────────────────────
class AmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final double fontSize;
  final bool isIncome;
  final bool neutral;

  const AmountText({
    super.key, required this.amount, this.currency = '৳',
    this.fontSize = 20, this.isIncome = false, this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = neutral ? AppTheme.textPrimary
        : (isIncome ? AppTheme.green : AppTheme.red);
    final sign = neutral ? '' : (isIncome ? '+' : '-');
    return Text(
      '$sign$currency${NumberFormat('#,##0.00').format(amount)}',
      style: TextStyle(color: color, fontSize: fontSize,
          fontWeight: FontWeight.w700, letterSpacing: -0.5),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final TransactionCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category,
      this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.accent.withOpacity(0.2) : AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppTheme.accent : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(category.icon, size: 14,
            color: selected ? AppTheme.accent : AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(category.label,
            style: TextStyle(
              color: selected ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ]),
    ),
  );
}

// ── Save status indicator ─────────────────────────────────────────────────────
class SaveStatusIndicator extends StatelessWidget {
  final SaveStatus status;
  const SaveStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SaveStatus.idle) return const SizedBox.shrink();
    final (icon, color, label) = switch (status) {
      SaveStatus.saving => (Icons.sync, AppTheme.yellow, 'Saving...'),
      SaveStatus.saved  => (Icons.cloud_done_outlined, AppTheme.green, 'Saved'),
      SaveStatus.failed => (Icons.cloud_off_outlined, AppTheme.red, 'Failed'),
      SaveStatus.idle   => (Icons.check, AppTheme.green, ''),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11,
            fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Debt status badge ─────────────────────────────────────────────────────────
class DebtStatusBadge extends StatelessWidget {
  final DebtStatus status;
  final bool isOverdue;
  const DebtStatusBadge({super.key, required this.status, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = isOverdue ? ('OVERDUE', AppTheme.red)
        : switch (status) {
            DebtStatus.pending       => ('PENDING', AppTheme.orange),
            DebtStatus.partiallyPaid => ('PARTIAL', AppTheme.yellow),
            DebtStatus.settled       => ('SETTLED', AppTheme.green),
            DebtStatus.overdue       => ('OVERDUE', AppTheme.red),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(color: AppTheme.textPrimary,
          fontSize: 16, fontWeight: FontWeight.w700)),
      if (trailing != null) trailing!,
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  const EmptyState({super.key, required this.icon,
      required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 56, color: AppTheme.textSecondary.withOpacity(0.35)),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 15, fontWeight: FontWeight.w500)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    ]),
  );
}

// ── Gradient button ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient? gradient;
  const GradientButton({super.key, required this.label, required this.onTap,
      this.icon, this.gradient});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.accentGrad,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(color: Colors.white,
            fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Multi-select bulk delete bar ──────────────────────────────────────────────
/// Place at the bottom of a screen when in multi-select mode.
class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Cancel
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          // Count badge
          Expanded(
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: const TextStyle(color: AppTheme.accent,
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          // Delete button
          TextButton.icon(
            onPressed: selectedCount > 0 ? onDelete : null,
            icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 18),
            label: const Text('Delete',
                style: TextStyle(color: AppTheme.red,
                    fontSize: 14, fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Transaction tile (swipe-to-delete + multi-select aware) ───────────────────
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelect;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
    this.onDelete,
    this.selectable = false,
    this.selected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;

    final card = GlassCard(
      selected: selected,
      onTap: selectable ? onSelect : onTap,
      onLongPress: selectable ? null : onSelect, // long-press enters select mode
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        // Checkbox (shown in select mode) or category icon
        if (selectable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24, height: 24,
            margin: const EdgeInsets.only(right: 10),
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
          )
        else
          Container(
            width: 42, height: 42,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: (isIncome ? AppTheme.green : AppTheme.accent).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(t.category.icon, size: 20,
                color: isIncome ? AppTheme.green : AppTheme.accent),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(t.title,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (t.isHidden)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.lock_outline, size: 10,
                      color: AppTheme.accentLight),
                ),
            ]),
            const SizedBox(height: 2),
            Text('${t.category.label}  ·  ${DateFormat('MMM d, h:mm a').format(t.dateTime)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            if (t.tag != null)
              Text('#${t.tag}',
                  style: const TextStyle(color: AppTheme.accentLight, fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 8),
        AmountText(amount: t.amount, currency: currency,
            fontSize: 14, isIncome: isIncome),
      ]),
    );

    if (onDelete == null || selectable) return card;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true, // undo replaces confirm dialog
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.red.withOpacity(0.3)),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_outline, color: AppTheme.red, size: 22),
          SizedBox(height: 2),
          Text('Delete', style: TextStyle(color: AppTheme.red, fontSize: 10,
              fontWeight: FontWeight.w600)),
        ]),
      ),
      child: card,
    );
  }
}
