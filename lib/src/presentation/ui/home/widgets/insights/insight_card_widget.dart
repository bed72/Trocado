import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';

import 'package:trocado/src/presentation/widgets/cards/icon_card_widget.dart';

class InsightCardWidget extends StatelessWidget {
  final InsightModel insight;

  const InsightCardWidget({super.key, required this.insight});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320.0,
    child: IconCardWidget(
      icon: _iconFor(insight.type),
      title: insight.title,
      description: insight.description,
    ),
  );

  IconData _iconFor(InsightTypeEnum type) => switch (type) {
    .willOverspend => Icons.schedule,
    .topCategory => Icons.trending_up,
    .dailyAverage => Icons.show_chart,
    .unknown => Icons.lightbulb_outline,
    .budgetUtilization => Icons.pie_chart_outline,
  };
}
