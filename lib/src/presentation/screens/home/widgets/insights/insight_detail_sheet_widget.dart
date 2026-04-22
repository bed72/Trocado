import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/home/widgets/insights/insight_icon_widget.dart';

class InsightDetailSheetWidget extends StatelessWidget {
  final InsightModel insight;

  const InsightDetailSheetWidget({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12.0,
      crossAxisAlignment: .start,
      children: [
        InsightIconWidget(type: insight.type, severity: insight.severity),
        Expanded(
          child: Text(
            insight.message,
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
