import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';

import 'package:trocado/src/presentation/ui/home/widgets/insights/insight_card_widget.dart';

class InsightsCarouselLoadingWidget extends StatelessWidget {
  const InsightsCarouselLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: SizedBox(
        height: 78.0,
        child: ListView.separated(
          itemCount: 3,
          scrollDirection: .horizontal,
          padding: .symmetric(horizontal: 16.0),
          separatorBuilder: (_, _) => const SizedBox(width: 8.0),
          itemBuilder: (_, _) => const InsightCardWidget(insight: _placeholder),
        ),
      ),
    );
  }
}

const _placeholder = InsightModel(
  data: {},
  severity: .info,
  type: .budgetUtilization,
  title: 'Carregando insight',
  description: 'Carregando insight para o skeleton.',
);
