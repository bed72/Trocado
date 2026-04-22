import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insights/insight_model.dart';
import 'package:trocado/src/domain/models/insights/insight_type.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/insights/insight_icon_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/insights/insight_detail_sheet_widget.dart';

class InsightCardWidget extends StatelessWidget {
  final InsightModel insight;

  const InsightCardWidget({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.0,
      child: Card(
        elevation: 0.0,
        clipBehavior: .antiAlias,
        color: context.colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: context.radius.cornerRadius100,
        ),
        child: GestureDetector(
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const .all(12.0),
            child: Row(
              spacing: 12.0,
              crossAxisAlignment: .center,
              children: [
                InsightIconWidget(
                  type: insight.type,
                  severity: insight.severity,
                ),
                Expanded(
                  child: Column(
                    spacing: 4.0,
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        titleFor(insight.type),
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: context.typography.labelMedium?.copyWith(
                          fontWeight: .w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                      Text(
                        insight.message,
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: context.typography.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) => bottomSheetScaffoldWidget<void>(
    context: context,
    autoResize: true,
    title: titleFor(insight.type),
    child: InsightDetailSheetWidget(insight: insight),
  );
}

String titleFor(InsightType type) => switch (type) {
  .dailyAverage => 'Média diária',
  .willOverspend => 'Projeção de gasto',
  .topCategory => 'Categoria em destaque',
  .budgetUtilization => 'Uso do orçamento',
  .unknown => 'Insight',
};
