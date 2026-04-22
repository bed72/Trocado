import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class BudgetCardLabelWidget extends StatelessWidget {
  final String budget;
  final bool overspent;
  final double percentage;

  const BudgetCardLabelWidget({
    super.key,
    required this.budget,
    required this.percentage,
    this.overspent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = overspent ? context.colors.error : _color(context.colors);
    final (leading, trailing) = _icons();

    return Container(
      width: .infinity,
      padding: const .all(8.0),
      decoration: BoxDecoration(
        borderRadius: .circular(10.0),
        color: color.withValues(alpha: 0.10),
      ),
      child: Row(
        spacing: 8.0,
        crossAxisAlignment: .center,
        children: [
          Text(leading, style: context.typography.bodyMedium),
          Expanded(child: _buildMessage(context, color)),
          Text(trailing, style: context.typography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, Color color) => overspent
      ? Text(
          'Não podemos gastar mais...',
          style: context.typography.bodySmall?.copyWith(
            color: color,
            fontWeight: .bold,
          ),
        )
      : Text.rich(
          TextSpan(
            style: context.typography.bodySmall?.copyWith(color: color),
            children: [
              const TextSpan(text: 'Pode gastar '),
              TextSpan(
                text: budget,
                style: const TextStyle(fontWeight: .bold),
              ),
              const TextSpan(text: ' hoje'),
            ],
          ),
        );

  (String, String) _icons() => switch (percentage) {
    <= 0.4 => ('👀​', '🟢'),
    <= 0.8 => ('👀​', '🟡'),
    _ => ('👀​', '🔴'),
  };

  Color _color(ColorScheme colors) => switch (percentage) {
    <= 0.4 => Colors.green,
    <= 0.8 => Color.lerp(Colors.green, Colors.amber, (percentage - 0.4) / 0.4)!,
    _ => Color.lerp(Colors.amber, colors.error, (percentage - 0.9) / 0.6)!,
  };
}
