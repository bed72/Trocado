import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/home/preview/mocks/insight_mock.dart';
import 'package:trocado/src/presentation/ui/home/widgets/insights/insights_carousel_widget.dart';

Widget _carousel(AsyncValue<InsightsBundleModel> state) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const .symmetric(vertical: 16.0),
      child: InsightsCarouselWidget(state: state, onRetry: () {}),
    ),
  ),
);

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() => _carousel(const AsyncLoading());

@TrocadoPreview(group: 'Estados', name: 'Empty')
Widget previewEmpty() => _carousel(AsyncData(insightsBundleMock(const [])));

@TrocadoPreview(group: 'Estados', name: 'Failure')
Widget previewFailure() =>
    _carousel(AsyncError('Falha ao carregar', StackTrace.empty));

@TrocadoPreview(group: 'Conteúdo', name: '1 insight (danger)')
Widget previewSuccessSingle() =>
    _carousel(AsyncData(insightsBundleMock(const [dangerBudgetInsightMock])));

@TrocadoPreview(group: 'Conteúdo', name: 'Todos os tipos')
Widget previewSuccessAll() => _carousel(
  AsyncData(
    insightsBundleMock(const [
      dangerBudgetInsightMock,
      willOverspendInsightMock,
      dailyAverageInsightMock,
      topCategoryInsightMock,
    ]),
  ),
);

@TrocadoPreview(group: 'Conteúdo', name: 'Só info')
Widget previewSuccessInfo() =>
    _carousel(AsyncData(insightsBundleMock(const [topCategoryInsightMock])));
