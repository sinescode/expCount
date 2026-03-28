import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

// ── Glass card ────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  const GlassCard({
    super.key, required this.child, this.padding,
    this.gradient, this.onTap, this.radius = 16,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGrad,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.border),
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

// ── Category chip with Icon ───────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final TransactionCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon,
              size: 14,
              color: selected ? AppTheme.accent : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(category.label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
        ],
      ),
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
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
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
      Text(title,
          style: const TextStyle(color: AppTheme.textPrimary,
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
  const EmptyState({super.key, required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 56, color: AppTheme.textSecondary.withOpacity(0.35)),
      const SizedBox(height: 12),
      Text(message,
          style: const TextStyle(color: AppTheme.textSecondary,
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
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Shared confirm-delete dialog ──────────────────────────────────────────────
Future<bool> confirmDelete(
  BuildContext context, {
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

// ── Transaction tile  (swipe-left to reveal delete, tap delete → confirm) ─────
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key, required this.transaction, required this.currency,
    this.onTap, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;

    final card = GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: (isIncome ? AppTheme.green : AppTheme.accent).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(t.category.icon, size: 20,
              color: isIncome ? AppTheme.green : AppTheme.accent),
        ),
        const SizedBox(width: 12),
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
                  child: const Icon(Icons.lock_outline, size: 10, color: AppTheme.accentLight),
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
        AmountText(amount: t.amount, currency: currency, fontSize: 14, isIncome: isIncome),
      ]),
    );

    if (onDelete == null) return card;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(context,
          title: 'Delete transaction?',
          message: '"${t.title}" will be permanently removed.'),
      onDismissed: (_) => onDelete!(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.red.withOpacity(0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_outline, color: AppTheme.red, size: 22),
          const SizedBox(height: 2),
          const Text('Delete', style: TextStyle(color: AppTheme.red, fontSize: 10,
              fontWeight: FontWeight.w600)),
        ]),
      ),
      child: card,
    );
  }
}
