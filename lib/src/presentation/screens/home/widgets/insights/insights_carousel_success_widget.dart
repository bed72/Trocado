import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

import 'package:trocado/src/presentation/screens/home/widgets/insights/insight_card_widget.dart';

class InsightsCarouselSuccessWidget extends StatelessWidget {
  final InsightsBundleModel bundle;

  const InsightsCarouselSuccessWidget({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.0,
      child: ListView.separated(
        scrollDirection: .horizontal,
        itemCount: bundle.insights.length,
        padding: .symmetric(horizontal: 16.0),
        separatorBuilder: (_, index) => const SizedBox(width: 8.0),
        itemBuilder: (_, index) =>
            InsightCardWidget(insight: bundle.insights[index]),
      ),
    );
  }
}
