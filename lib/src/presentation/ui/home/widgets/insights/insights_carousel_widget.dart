import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/cards/inline_failure_card_widget.dart';

import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_empty_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_loading_widget.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_success_widget.dart';

class InsightsCarouselWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final AsyncValue<InsightsBundleModel> state;

  const InsightsCarouselWidget({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Padding(
        padding: const .symmetric(horizontal: 20.0),
        child: Text(
          'Insights',
          style: context.typography.titleMedium?.copyWith(
            fontWeight: .w600,
            color: context.colors.onSurface,
          ),
        ),
      ),
      _content(),
    ],
  );

  Widget _content() {
    if (state.isLoading) return const InsightsCarouselLoadingWidget();

    return switch (state) {
      AsyncValue(:final value?) when value.insights.isEmpty =>
        const InsightsCarouselEmptyWidget(),
      AsyncValue(:final value?) => InsightsCarouselSuccessWidget(bundle: value),
      AsyncError() => Padding(
        padding: const .symmetric(horizontal: 16.0),
        child: InlineFailureCardWidget(
          onRetry: onRetry,
          message: 'Não foi possível carregar os insights.',
        ),
      ),
      _ => const InsightsCarouselLoadingWidget(),
    };
  }
}
