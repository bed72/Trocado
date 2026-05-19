import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_active_filter_chip_presentation_data.dart';

class ExpensesActiveFiltersWidget extends StatefulWidget {
  final ValueChanged<ExpenseFilterChipKind> onRemove;
  final List<ExpenseActiveFilterChipPresentationData> chips;

  const ExpensesActiveFiltersWidget({
    super.key,
    required this.chips,
    required this.onRemove,
  });

  @override
  State<ExpensesActiveFiltersWidget> createState() =>
      _ExpensesActiveFiltersWidgetState();
}

class _ExpensesActiveFiltersWidgetState
    extends State<ExpensesActiveFiltersWidget> {
  static const _duration = Duration(milliseconds: 200);

  late GlobalKey<AnimatedListState> _listKey;
  late List<ExpenseActiveFilterChipPresentationData> _items;

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<AnimatedListState>();
    _items = [...widget.chips];
  }

  @override
  void didUpdateWidget(covariant ExpensesActiveFiltersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncItems(widget.chips);
  }

  void _syncItems(List<ExpenseActiveFilterChipPresentationData> next) {
    for (int i = _items.length - 1; i >= 0; i--) {
      final kind = _items[i].kind;
      if (next.any((chip) => chip.kind == kind)) continue;

      final removed = _items.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _animatedChip(
          context,
          removed,
          animation,
          isLast: i == _items.length,
        ),
        duration: _duration,
      );
    }

    for (int i = 0; i < next.length; i++) {
      final newChip = next[i];
      final currentIndex = _items.indexWhere(
        (chip) => chip.kind == newChip.kind,
      );

      if (currentIndex < 0) {
        _items.insert(i, newChip);
        _listKey.currentState?.insertItem(i, duration: _duration);
      } else if (_items[currentIndex] != newChip) {
        setState(() => _items[currentIndex] = newChip);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: _duration,
    alignment: .topCenter,
    child: _items.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 40.0,
            child: AnimatedList(
              key: _listKey,
              scrollDirection: .horizontal,
              initialItemCount: _items.length,
              padding: const .symmetric(horizontal: 16.0),
              itemBuilder: (context, index, animation) => _animatedChip(
                context,
                _items[index],
                animation,
                isLast: index == _items.length - 1,
              ),
            ),
          ),
  );

  Widget _animatedChip(
    BuildContext context,
    ExpenseActiveFilterChipPresentationData data,
    Animation<double> animation, {
    required bool isLast,
  }) => SizeTransition(
    axis: .horizontal,
    sizeFactor: animation,
    child: FadeTransition(
      opacity: animation,
      child: Padding(
        padding: .only(right: isLast ? 0.0 : 8.0),
        child: _chip(context, data),
      ),
    ),
  );

  Widget _chip(
    BuildContext context,
    ExpenseActiveFilterChipPresentationData data,
  ) => InputChip(
    elevation: 0.0,
    labelPadding: const .only(left: 4.0, right: 4.0, bottom: 1.0),
    label: Row(
      spacing: 6.0,
      mainAxisSize: .min,
      children: [
        if (data.icon != null)
          Icon(data.icon, size: 16.0, color: context.colors.onSurfaceVariant),
        Text(data.label),
      ],
    ),
    onDeleted: () => widget.onRemove(data.kind),
    deleteIcon: Container(
      padding: .only(top: 2.0),
      child: Icon(
        Icons.close,
        size: 16.0,
        color: context.colors.onSurfaceVariant,
      ),
    ),
    backgroundColor: context.colors.surfaceContainerHighest,
    shape: RoundedRectangleBorder(
      borderRadius: context.radius.cornerRadius050,
      side: BorderSide(color: Colors.transparent),
    ),
  );
}
