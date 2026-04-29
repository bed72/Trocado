import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insight_icon_widget.dart';

class InsightCardWidget extends StatelessWidget {
  final InsightModel insight;

  const InsightCardWidget({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320.0,
      child: Card(
        margin: .zero,
        elevation: 0.0,
        clipBehavior: .antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: context.radius.cornerRadius100,
        ),
        child: Padding(
          padding: const .symmetric(vertical: 10.0, horizontal: 16.0),
          child: Row(
            spacing: 10.0,
            crossAxisAlignment: .center,
            children: [
              InsightIconWidget(type: insight.type, severity: insight.severity),
              Expanded(
                child: Column(
                  spacing: 4.0,
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      insight.title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: context.typography.labelMedium?.copyWith(
                        fontWeight: .w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      insight.description,
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
    );
  }
}
