import 'dart:math';

import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_label_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_progress_bar_painter.dart';

class BudgetCardSuccessWidget extends StatelessWidget {
  final ActiveBudgetModel model;
  final String Function(double) format;

  const BudgetCardSuccessWidget({
    super.key,
    required this.model,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final budget = format(_dailyBudget() / 100);
    final percentage = model.value > 0 ? model.totalSpent / model.value : 0.0;
    final color = _gaugeColor(percentage: percentage, colors: context.colors);

    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 10.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            BudgetCardLabelWidget(
              budget: budget,
              percentage: percentage,
              overspent: model.remaining < 0,
            ),
            Row(
              crossAxisAlignment: .start,
              children: [
                Expanded(child: _buildStats(context, color)),
                _buildPercentage(context, color, percentage),
              ],
            ),
            _buildProgressBar(context, color, percentage),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Color color) => Column(
    spacing: 4.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Gasto no período',
        style: context.typography.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
      RichText(
        text: TextSpan(
          style: context.typography.bodyMedium,
          children: [
            TextSpan(
              text: format(model.totalSpent / 100),
              style: TextStyle(
                fontWeight: .w600,
                color: context.colors.onSurface,
              ),
            ),
            TextSpan(
              text: ' / ${format(model.value / 100)}',
              style: TextStyle(color: context.colors.outline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 2.0),
      Text(
        'Disponível',
        style: context.typography.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
      Row(
        spacing: 6.0,
        textBaseline: .alphabetic,
        crossAxisAlignment: .baseline,
        children: [
          Text(
            format(max(0, model.remaining) / 100),
            style: context.typography.titleSmall?.copyWith(
              color: color,
              fontWeight: .bold,
            ),
          ),
          if (model.remaining < 0)
            Flexible(
              child: Text(
                'Estourou em ${format(model.remaining.abs() / 100)}',
                overflow: .ellipsis,
                style: context.typography.labelSmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _buildPercentage(
    BuildContext context,
    Color color,
    double percentage,
  ) => Column(
    crossAxisAlignment: .end,
    children: [
      Text(
        '${(percentage * 100).clamp(0, 100).toStringAsFixed(0)}%',
        style: context.typography.headlineSmall?.copyWith(
          color: color,
          fontWeight: .bold,
        ),
      ),
      Icon(Icons.trending_up_rounded, color: color, size: 18.0),
    ],
  );

  Widget _buildProgressBar(
    BuildContext context,
    Color color,
    double percentage,
  ) => SizedBox(
    height: 20.0,
    width: .infinity,
    child: CustomPaint(
      painter: BudgetProgressBarPainter(
        fillColor: color,
        thumbColor: color,
        percentage: percentage.clamp(0.0, 1.0),
        trackColor: color.withValues(alpha: 0.15),
      ),
    ),
  );

  int _dailyBudget() {
    final daysRemaining =
        DateTime.fromMillisecondsSinceEpoch(
          model.endDate,
        ).difference(.now()).inDays +
        1;
    return (model.remaining / max(1, daysRemaining)).round();
  }

  Color _gaugeColor({
    required double percentage,
    required ColorScheme colors,
  }) => switch (percentage) {
    <= 0.4 => Colors.green,
    <= 0.6 => Color.lerp(Colors.green, Colors.amber, .9)!,
    _ => Color.lerp(Colors.amber, colors.error, (percentage - 0.9) / 0.6)!,
  };
}
