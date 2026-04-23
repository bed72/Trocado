import 'package:trocado/src/domain/models/insight/insight_model.dart';
import 'package:trocado/src/domain/models/insight/insights_bundle_model.dart';

InsightsBundleModel insightsBundleMock(List<InsightModel> insights) =>
    InsightsBundleModel(
      insights: insights,
      hasEnoughData: insights.isNotEmpty,
      generatedAt: DateTime.utc(2026, 4, 22, 18, 24, 36),
    );

const dangerBudgetInsightMock = InsightModel(
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

const willOverspendInsightMock = InsightModel(
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

const dailyAverageInsightMock = InsightModel(
  severity: .warning,
  type: .dailyAverage,
  data: {'actual_daily_rate': 208.02, 'ideal_daily_rate': 103.45},
  message:
      'Média diária de R\$208,02. O ideal seria R\$103,45. Matemática triste.',
);

const topCategoryInsightMock = InsightModel(
  severity: .info,
  type: .topCategory,
  data: {'category': 'housing', 'pct': 55.98},
  message: 'Housing representa 56% dos seus gastos este período.',
);
