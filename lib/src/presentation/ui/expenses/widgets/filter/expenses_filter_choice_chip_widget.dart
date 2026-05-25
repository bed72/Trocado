import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class ExpensesFilterChoiceChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ExpensesFilterChoiceChipWidget({
    super.key,
    required this.onTap,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        fontWeight: isSelected ? .w600 : null,
        color: isSelected
            ? context.colors.primary
            : context.colors.onSurfaceVariant,
      ),
    ),
    selected: isSelected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    materialTapTargetSize: .shrinkWrap,
    labelPadding: const .symmetric(horizontal: 4.0),
    backgroundColor: context.colors.surfaceContainerHighest,
    selectedColor: context.colors.primary.withValues(alpha: 0.15),
    shape: RoundedRectangleBorder(
      borderRadius: context.radius.cornerRadius050,
      side: BorderSide(
        color: isSelected ? context.colors.primary : Colors.transparent,
      ),
    ),
  );
}
