import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import 'widgets.dart';

/// Active filter state — immutable, passed around
class TransactionFilter {
  final DateTime? date;       // exact single day
  final DateTime? from;       // range start
  final DateTime? to;         // range end
  final TransactionCategory? category;
  final TransactionType? type;
  final String? query;

  const TransactionFilter({
    this.date,
    this.from,
    this.to,
    this.category,
    this.type,
    this.query,
  });

  bool get isActive =>
      date != null ||
      from != null ||
      to != null ||
      category != null ||
      type != null ||
      (query != null && query!.isNotEmpty);

  TransactionFilter copyWith({
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TransactionCategory? category,
    TransactionType? type,
    String? query,
    bool clearDate = false,
    bool clearRange = false,
    bool clearCategory = false,
    bool clearType = false,
    bool clearQuery = false,
  }) =>
      TransactionFilter(
        date:     clearDate     ? null : (date     ?? this.date),
        from:     clearRange    ? null : (from     ?? this.from),
        to:       clearRange    ? null : (to       ?? this.to),
        category: clearCategory ? null : (category ?? this.category),
        type:     clearType     ? null : (type     ?? this.type),
        query:    clearQuery    ? null : (query    ?? this.query),
      );

  /// Human-readable summary of active filters
  String get summary {
    final parts = <String>[];
    if (date != null) parts.add(DateFormat('MMM d, y').format(date!));
    if (from != null && to != null) {
      parts.add('${DateFormat('MMM d').format(from!)} – ${DateFormat('MMM d').format(to!)}');
    } else if (from != null) {
      parts.add('From ${DateFormat('MMM d').format(from!)}');
    } else if (to != null) {
      parts.add('Until ${DateFormat('MMM d').format(to!)}');
    }
    if (category != null) parts.add(category!.label);
    if (type != null) parts.add(type == TransactionType.income ? 'Income' : 'Expense');
    return parts.join('  ·  ');
  }
}

/// Filter button shown in app bars
class FilterButton extends StatelessWidget {
  final TransactionFilter filter;
  final VoidCallback onTap;

  const FilterButton({super.key, required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = filter.isActive;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: Icon(
            active ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: active ? AppTheme.teal : context.mutedColor,
          ),
          onPressed: onTap,
        ),
        if (active)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Active filter bar shown below app bar when filters are on
class ActiveFilterBar extends StatelessWidget {
  final TransactionFilter filter;
  final VoidCallback onClear;

  const ActiveFilterBar({super.key, required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.teal.withOpacity(0.08),
      child: Row(children: [
        const Icon(Icons.filter_alt, size: 14, color: AppTheme.teal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            filter.summary,
            style: const TextStyle(
                color: AppTheme.teal, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.close, size: 11, color: AppTheme.teal),
              SizedBox(width: 3),
              Text('Clear', style: TextStyle(
                  color: AppTheme.teal, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// The main filter bottom sheet
class FilterSheet extends StatefulWidget {
  final TransactionFilter current;
  final bool isVault;

  const FilterSheet({super.key, required this.current, this.isVault = false});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? _date;
  late DateTime? _from;
  late DateTime? _to;
  late TransactionCategory? _category;
  late TransactionType? _type;

  // Quick-select date presets
  static const _quickDates = [
    ('Today',      0),
    ('Yesterday',  1),
    ('This week', -7),
  ];

  @override
  void initState() {
    super.initState();
    _date     = widget.current.date;
    _from     = widget.current.from;
    _to       = widget.current.to;
    _category = widget.current.category;
    _type     = widget.current.type;
  }

  bool get _hasDate    => _date != null;
  bool get _hasRange   => _from != null || _to != null;

  void _apply() {
    Navigator.pop(context, TransactionFilter(
      date:     _date,
      from:     _from,
      to:       _to,
      category: _category,
      type:     _type,
    ));
  }

  void _clear() {
    Navigator.pop(context, const TransactionFilter());
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.teal)),
        child: child!,
      ),
    );
    if (d != null) setState(() { _date = d; _from = null; _to = null; });
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.teal)),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to   = range.end;
        _date = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(
                      widget.isVault ? Icons.lock_outline : Icons.filter_alt_outlined,
                      color: AppTheme.teal, size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isVault ? 'Filter Secret Vault' : 'Filter Transactions',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Clear all',
                        style: TextStyle(color: AppTheme.red, fontSize: 13)),
                  ),
                ],
              ),
            ]),
          ),
          Divider(color: context.borderColor, height: 1),

          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [

                // ── Date section ─────────────────────────────────────────
                _sectionLabel(context, Icons.calendar_today_outlined, 'Date'),
                const SizedBox(height: 10),

                // Quick select row
                Row(children: _quickDates.map((q) {
                  final qDate = q.$2 == 0
                      ? now
                      : (q.$2 == 1
                          ? now.subtract(const Duration(days: 1))
                          : null); // "This week" = range
                  final isWeek = q.$2 == -7;
                  final isSelected = isWeek
                      ? (_from != null && _to != null &&
                          _from!.isAfter(now.subtract(const Duration(days: 8))))
                      : (_date != null &&
                          _date!.day == qDate!.day &&
                          _date!.month == qDate.month &&
                          _date!.year == qDate.year);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _QuickChip(
                      label: q.$1,
                      selected: isSelected,
                      onTap: () {
                        if (isWeek) {
                          setState(() {
                            _from = now.subtract(const Duration(days: 6));
                            _to   = now;
                            _date = null;
                          });
                        } else {
                          setState(() {
                            _date = qDate;
                            _from = null;
                            _to   = null;
                          });
                        }
                      },
                    ),
                  );
                }).toList()),

                const SizedBox(height: 12),

                // Exact day or range picker buttons
                Row(children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.event_outlined,
                      label: _hasDate
                          ? DateFormat('MMM d, y').format(_date!)
                          : 'Pick a day',
                      active: _hasDate,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.date_range_outlined,
                      label: _hasRange
                          ? '${DateFormat('MMM d').format(_from ?? now)} – ${DateFormat('MMM d').format(_to ?? now)}'
                          : 'Date range',
                      active: _hasRange,
                      onTap: _pickRange,
                    ),
                  ),
                ]),

                // Clear date row
                if (_hasDate || _hasRange) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() { _date = null; _from = null; _to = null; }),
                      child: const Text('Clear date',
                          style: TextStyle(color: AppTheme.teal, fontSize: 12)),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ── Type section ──────────────────────────────────────────
                _sectionLabel(context, Icons.swap_vert_outlined, 'Transaction Type'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _TypeChip(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Expense',
                    color: AppTheme.red,
                    selected: _type == TransactionType.expense,
                    onTap: () => setState(() =>
                        _type = _type == TransactionType.expense
                            ? null : TransactionType.expense),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _TypeChip(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Income',
                    color: AppTheme.green,
                    selected: _type == TransactionType.income,
                    onTap: () => setState(() =>
                        _type = _type == TransactionType.income
                            ? null : TransactionType.income),
                  )),
                ]),

                const SizedBox(height: 22),

                // ── Category section ──────────────────────────────────────
                _sectionLabel(context, Icons.category_outlined, 'Category'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TransactionCategory.values.map((c) => CategoryChip(
                    category: c,
                    selected: _category == c,
                    onTap: () => setState(() =>
                        _category = _category == c ? null : c),
                  )).toList(),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),

          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: GradientButton(
              label: 'Apply Filter',
              icon: Icons.check,
              onTap: _apply,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String label) =>
      Row(children: [
        Icon(icon, size: 15, color: AppTheme.teal),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ]);
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.teal.withOpacity(0.15) : context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppTheme.teal : context.borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(label,
          style: TextStyle(
              color: selected ? AppTheme.teal : context.mutedColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
    ),
  );
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon, required this.label,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppTheme.teal.withOpacity(0.1) : context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppTheme.teal : context.borderColor,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: active ? AppTheme.teal : context.mutedColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: active ? AppTheme.teal : context.mutedColor,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon, required this.label, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color : context.borderColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        Icon(icon, color: selected ? color : context.mutedColor, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: selected ? color : context.mutedColor,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ]),
    ),
  );
}
