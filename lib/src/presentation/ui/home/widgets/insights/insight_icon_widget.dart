import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class InsightIconWidget extends StatelessWidget {
  final InsightTypeEnum type;
  final InsightSeverityEnum severity;

  const InsightIconWidget({
    super.key,
    required this.type,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) => BackgroundIconWidget(
    icon: _icon(),
    iconSize: 20.0,
    color: context.colors.primary,
  );

  IconData _icon() => switch (type) {
    .willOverspend => Icons.schedule,
    .topCategory => Icons.trending_up,
    .dailyAverage => Icons.show_chart,
    .unknown => Icons.lightbulb_outline,
    .budgetUtilization => Icons.pie_chart_outline,
  };
}
