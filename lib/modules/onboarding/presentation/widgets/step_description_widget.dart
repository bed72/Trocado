import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';

class StepDescriptionWidget extends StatelessWidget {
  final String value;
  final String? highlight;
  final TextStyle? highlightStyle;

  const StepDescriptionWidget({
    super.key,
    required this.value,
    this.highlight,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.typography.bodyLarge?.copyWith(
      height: 1.4,
      fontWeight: .w500,
      color: context.colors.inverseSurface.withValues(alpha: 0.72),
    );

    if (highlight == null || !value.contains(highlight!)) {
      return Text(value, textAlign: .center, style: baseStyle);
    }

    final parts = value.split(highlight!);

    return RichText(
      textAlign: .center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: highlight,
            style:
                highlightStyle ??
                baseStyle?.copyWith(
                  fontWeight: .w600,
                  color: context.colors.inverseSurface,
                ),
          ),
          TextSpan(text: parts.length > 1 ? parts[1] : ''),
        ],
      ),
    );
  }
}
