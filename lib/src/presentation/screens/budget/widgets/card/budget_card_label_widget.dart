import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class BudgetCardLabelWidget extends StatelessWidget {
  final double percentage;
  final String dailyBudget;

  const BudgetCardLabelWidget({
    super.key,
    required this.percentage,
    required this.dailyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(context.colors);
    final (leading, trailing) = _icons();

    return Container(
      width: .infinity,
      padding: const .only(left: 12.0, top: 4.0, right: 12.0, bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: .circular(10.0),
        color: color.withValues(alpha: 0.10),
      ),
      child: Text.rich(
        TextSpan(
          style: context.typography.bodySmall?.copyWith(color: color),
          children: [
            WidgetSpan(
              alignment: .bottom,
              child: Text(leading, style: context.typography.bodyMedium),
            ),
            const TextSpan(text: '  Pode gastar '),
            TextSpan(
              text: dailyBudget,
              style: const TextStyle(fontWeight: .bold),
            ),
            const TextSpan(text: ' hoje  '),
            WidgetSpan(
              alignment: .bottom,
              child: Text(trailing, style: context.typography.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _icons() => switch (percentage) {
    < 0.3 => ('🎯', '🌟'),
    < 0.7 => ('😊', '👍'),
    < 0.9 => ('⚠️', '🔶'),
    _ => ('🚨', '❌'),
  };

  Color _color(ColorScheme colors) => switch (percentage) {
    < 0.3 => Colors.teal,
    < 0.7 => Colors.green,
    < 0.9 => Colors.amber.shade700,
    _ => colors.error,
  };
}
