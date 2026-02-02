import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SelectorWidget extends StatelessWidget {
  final int selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const SelectorWidget({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = options[selected];

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        selected: {selectedValue},
        onSelectionChanged: (values) {
          onSelected(values.first);
        },
        segments: options
            .map(
              (label) => ButtonSegment<String>(
                value: label,
                label: Text(
                  label,
                  style: context.typography.labelMedium?.copyWith(
                    height: 1,
                    fontWeight: .w600,
                  ),
                ),
              ),
            )
            .toList(),
        style: ButtonStyle(
          padding: .all(.zero),
          minimumSize: .all(.zero),
          shape: .all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
        ),
      ),
    );
  }
}
