import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

import 'package:trocado/src/presentation/widgets/preview/material_preview_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/insights/insights_carousel_widget.dart';

InsightsBundleModel _bundle(List<InsightModel> insights) => InsightsBundleModel(
  insights: insights,
  hasEnoughData: insights.isNotEmpty,
  generatedAt: DateTime.utc(2026, 4, 22, 18, 24, 36),
);

const _danger = InsightModel(
  severity: .danger,
  type: .budgetUtilization,
  message: 'Que bom que budgets são só sugestões mesmo, né? Você usou 146%.',
  data: {
    'period_pct': 72.41,
    'budget_value': 3000,
    'budget_pct': 145.61,
    'total_spent': 4368.37,
  },
);

const _warning = InsightModel(
  severity: .warning,
  type: .willOverspend,
  message: 'No ritmo atual, estoura o budget em 0 dias.',
  data: {
    'budget_value': 3000,
    'daily_rate': 208.02,
    'total_spent': 4368.37,
    'days_until_overspend': 0,
  },
);

const _dailyAverage = InsightModel(
  severity: .warning,
  type: .dailyAverage,
  data: {'actual_daily_rate': 208.02, 'ideal_daily_rate': 103.45},
  message:
      'Média diária de R\$208,02. O ideal seria R\$103,45. Matemática triste.',
);

const _info = InsightModel(
  severity: .info,
  type: .topCategory,
  data: {'category': 'housing', 'pct': 55.98},
  message: 'Housing representa 56% dos seus gastos este período.',
);

Widget _carousel(AsyncValue<InsightsBundleModel> state) =>
    MaterialPreviewWidget(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const .symmetric(vertical: 16.0),
            child: InsightsCarouselWidget(state: state, onRetry: () {}),
          ),
        ),
      ),
    );

@Preview(name: 'Loading')
Widget previewLoading() => _carousel(const AsyncLoading());

@Preview(name: 'Empty')
Widget previewEmpty() => _carousel(AsyncData(_bundle(const [])));

@Preview(name: 'Failure')
Widget previewFailure() => _carousel(AsyncError('Falha ao carregar', .empty));

@Preview(name: 'Success — 1 insight (danger)')
Widget previewSuccessSingle() => _carousel(AsyncData(_bundle(const [_danger])));

@Preview(name: 'Success — todos os tipos')
Widget previewSuccessAll() => _carousel(
  AsyncData(_bundle(const [_danger, _warning, _dailyAverage, _info])),
);

@Preview(name: 'Success — só info')
Widget previewSuccessInfo() => _carousel(AsyncData(_bundle(const [_info])));
