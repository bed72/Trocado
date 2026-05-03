import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';
import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_card_label_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/card/budget_progress_bar_painter.dart';

class BudgetCardSuccessWidget extends StatelessWidget {
  final BudgetCardPresentationData data;
  final VoidCallback? onTap;

  const BudgetCardSuccessWidget({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor(
      colors: context.colors,
      percentage: data.percentage,
    );

    final card = Card(
      elevation: 0.0,
      color: color.withValues(alpha: .1),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          spacing: 10.0,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            BudgetCardLabelWidget(
              overspent: data.overspent,
              percentage: data.percentage,
              budget: data.formattedDailyBudget,
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: .stretch,
                children: [
                  Expanded(child: _buildStats(context, color)),
                  _buildPercentage(context, color),
                ],
              ),
            ),
            _buildProgressBar(context, color),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return BounceWidget.withOnPress(onPress: onTap, child: card);
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
              text: data.formattedTotalSpent,
              style: TextStyle(
                fontWeight: .w600,
                color: context.colors.onSurface,
              ),
            ),
            TextSpan(
              text: ' / ${data.formattedValue}',
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
            data.formattedRemaining,
            style: context.typography.titleSmall?.copyWith(
              color: color,
              fontWeight: .bold,
            ),
          ),
          if (data.overspent)
            Flexible(
              child: Text(
                'Estourou em ${data.formattedOverspent}',
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

  Widget _buildPercentage(BuildContext context, Color color) => Column(
    crossAxisAlignment: .end,
    mainAxisAlignment: .spaceBetween,
    children: [
      Column(
        crossAxisAlignment: .end,
        children: [
          Text(
            '${data.formattedPercentage}%',
            style: context.typography.headlineSmall?.copyWith(
              color: color,
              fontWeight: .bold,
            ),
          ),
          Icon(Icons.trending_up_rounded, color: color, size: 18.0),
        ],
      ),
      Text(
        'até ${data.formattedEndDate}',
        style: context.typography.labelSmall?.copyWith(
          color: context.colors.outline,
        ),
      ),
    ],
  );

  Widget _buildProgressBar(BuildContext context, Color color) => SizedBox(
    height: 20.0,
    width: .infinity,
    child: Skeleton.replace(
      replacement: Center(
        child: Container(
          height: 16.0,
          decoration: BoxDecoration(borderRadius: .circular(16.0 / 3)),
        ),
      ),
      child: CustomPaint(
        painter: BudgetProgressBarPainter(
          fillColor: color,
          thumbColor: color,
          percentage: data.percentage.clamp(0.0, 1.0),
          trackColor: color.withValues(alpha: 0.15),
        ),
      ),
    ),
  );

  Color _gaugeColor({
    required double percentage,
    required ColorScheme colors,
  }) => switch (percentage) {
    <= 0.4 => Colors.green,
    <= 0.7 => Color.lerp(
      Colors.green,
      Colors.orange.shade700,
      ((percentage - 0.4) / 0.3).clamp(0.0, 1.0),
    )!,
    _ => Color.lerp(
      Colors.orange.shade700,
      colors.error,
      ((percentage - 0.7) / 0.3).clamp(0.0, 1.0),
    )!,
  };
}
