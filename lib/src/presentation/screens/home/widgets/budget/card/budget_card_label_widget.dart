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
      padding: const .symmetric(vertical: 8.0, horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: .circular(10.0),
        color: color.withValues(alpha: 0.10),
      ),
      child: Row(
        spacing: 8.0,
        crossAxisAlignment: .center,
        children: [
          Text(leading, style: context.typography.bodyMedium),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: context.typography.bodySmall?.copyWith(color: color),
                children: [
                  const TextSpan(text: 'Pode gastar '),
                  TextSpan(
                    text: dailyBudget,
                    style: const TextStyle(fontWeight: .bold),
                  ),
                  const TextSpan(text: ' hoje'),
                ],
              ),
            ),
          ),
          Text(trailing, style: context.typography.bodyMedium),
        ],
      ),
    );
  }

  (String, String) _icons() => switch (percentage) {
    <= 0.4 => ('👀​', '🟢'),
    <= 0.8 => ('👀​', '🟡'),
    _ => ('👀​', '🔴'),
  };

  Color _color(ColorScheme colors) => switch (percentage) {
    <= 0.4 => Colors.green,
    <= 0.8 => Color.lerp(Colors.green, Colors.amber, (percentage - 0.4) / 0.4)!,
    _ => Color.lerp(Colors.amber, colors.error, (percentage - 0.8) / 0.2)!,
  };
}
