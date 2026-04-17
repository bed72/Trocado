import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

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
    final dailyBudget = _dailyBudget(model);
    final percentage = model.value > 0 ? model.totalSpent / model.value : 0.0;
    final color = _gaugeColor(percentage: percentage, colors: context.colors);

    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 16.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            _buildDailyBudgetLabel(
              context: context,
              color: color,
              dailyBudget: dailyBudget,
            ),
            Row(
              spacing: 16.0,
              children: [
                _buildGauge(
                  context: context,
                  color: color,
                  percentage: percentage,
                ),
                Expanded(
                  child: _buildStats(context: context, model: model),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  RichText _buildDailyBudgetLabel({
    required BuildContext context,
    required Color color,
    required int dailyBudget,
  }) => RichText(
    text: TextSpan(
      style: context.typography.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
      children: [
        const TextSpan(text: 'Pode gastar '),
        TextSpan(
          text: format(dailyBudget / 100),
          style: TextStyle(color: color, fontWeight: .bold),
        ),
        const TextSpan(text: ' hoje'),
      ],
    ),
  );

  SizedBox _buildGauge({
    required BuildContext context,
    required Color color,
    required double percentage,
  }) {
    const size = 110.0;
    final label = '${(percentage * 100).clamp(0, 100).toStringAsFixed(0)}%';

    return SizedBox(
      width: size,
      height: size / 2 + 16.0,
      child: Stack(
        alignment: .bottomCenter,
        children: [
          ClipRect(
            child: Align(
              heightFactor: 0.5,
              alignment: .topCenter,
              child: SizedBox(
                width: size,
                height: size,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    startDegreeOffset: 180,
                    sections: [
                      PieChartSectionData(
                        color: color,
                        radius: size / 2,
                        showTitle: false,
                        value: percentage.clamp(0.0, 1.0) * 100,
                      ),
                      PieChartSectionData(
                        radius: size / 2,
                        showTitle: false,
                        value: (1 - percentage.clamp(0.0, 1.0)) * 100,
                        color: context.colors.surfaceContainerHighest,
                      ),
                      PieChartSectionData(
                        value: 100,
                        radius: size / 2,
                        showTitle: false,
                        color: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: context.typography.labelLarge?.copyWith(
              fontWeight: .bold,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Column _buildStats({
    required BuildContext context,
    required ActiveBudgetModel model,
  }) => Column(
    spacing: 6.0,
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
      const SizedBox(height: 4.0),
      Text(
        'Disponível',
        style: context.typography.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
      Text(
        format(model.remaining / 100),
        style: context.typography.titleMedium?.copyWith(
          fontWeight: .bold,
          color: context.colors.primary,
        ),
      ),
    ],
  );

  int _dailyBudget(ActiveBudgetModel model) {
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
    < 0.7 => Colors.green,
    < 0.9 => Colors.amber,
    _ => colors.error,
  };
}
