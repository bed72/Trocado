import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class SelectorWidget extends StatelessWidget {
  final int selected;
  final List<String> options;
  final ValueChanged<int> onSelected;

  const SelectorWidget({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final value = options[selected];

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        selected: {value},
        onSelectionChanged: (values) =>
            onSelected(options.indexOf(values.first)),
        segments: options
            .map(
              (label) => ButtonSegment<String>(
                value: label,
                label: Text(
                  label,
                  style: context.typography.labelMedium?.copyWith(
                    fontWeight: .w600,
                  ),
                ),
              ),
            )
            .toList(),
        style: ButtonStyle(
          // alignment: .center,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: .circular(10.0)),
          ),
        ),
      ),
    );
  }
}
