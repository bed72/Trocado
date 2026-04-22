import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insights/insight_type.dart';
import 'package:trocado/src/domain/models/insights/insight_severity.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class InsightIconWidget extends StatelessWidget {
  final InsightType type;
  final InsightSeverity severity;

  const InsightIconWidget({
    super.key,
    required this.type,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      alignment: .center,
      decoration: BoxDecoration(
        shape: .circle,
        color: context.colors.primary.withValues(alpha: 0.2),
      ),
      child: Icon(_icon(), size: 20.0, color: context.colors.primary),
    );
  }

  IconData _icon() => switch (type) {
    .willOverspend => Icons.schedule,
    .topCategory => Icons.trending_up,
    .dailyAverage => Icons.show_chart,
    .unknown => Icons.lightbulb_outline,
    .budgetUtilization => Icons.pie_chart_outline,
  };
}
