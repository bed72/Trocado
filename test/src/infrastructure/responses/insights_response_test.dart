import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/insight/insights_response.dart';

import 'package:trocado/src/data/extensions/insights_response_extension.dart';

const _json = {
  'insights': [
    {
      'severity': 'danger',
      'type': 'budget_utilization',
      'title': 'Estourou o budget',
      'description': 'Usou 146% do orçamento.',
      'data': {
        'period_pct': 72.41,
        'budget_pct': 145.61,
        'budget_value': 3000,
        'total_spent': 4368.37,
      },
    },
    {
      'severity': 'warning',
      'type': 'will_overspend',
      'title': 'Vai estourar',
      'description': 'No ritmo atual, estoura em 0 dias.',
      'data': {
        'daily_rate': 208.02,
        'budget_value': 3000,
        'total_spent': 4368.37,
        'days_until_overspend': 0,
      },
    },
    {
      'severity': 'warning',
      'type': 'daily_average',
      'title': 'Média diária alta',
      'description': 'Média diária de R\$208.02.',
      'data': {'actual_daily_rate': 208.02, 'ideal_daily_rate': 103.45},
    },
    {
      'severity': 'info',
      'type': 'top_category',
      'title': 'Categoria em destaque',
      'data': {'category': 'housing', 'pct': 55.98},
      'description': 'Housing representa 56% dos gastos.',
    },
  ],
  'has_enough_data': false,
  'generated_at': '2026-04-22T18:24:36.544845+00:00',
};

void main() {
  group('InsightsResponse.fromJson', () {
    test('parses all top-level fields correctly', () {
      final response = InsightsResponse.fromJson(_json);

      expect(response.insights, hasLength(4));
      expect(response.hasEnoughData, isFalse);
      expect(response.generatedAt, '2026-04-22T18:24:36.544845+00:00');
    });

    test('parses each insight item', () {
      final response = InsightsResponse.fromJson(_json);

      expect(response.insights[0].severity, 'danger');
      expect(response.insights[0].data['budget_pct'], 145.61);
      expect(response.insights[0].type, 'budget_utilization');
      expect(response.insights[0].title, 'Estourou o budget');
      expect(response.insights[0].description, 'Usou 146% do orçamento.');
    });

    test('accepts unknown type and severity without throwing', () {
      final json = <String, dynamic>{
        'insights': [
          <String, dynamic>{
            'title': 'titulo',
            'description': 'desc',
            'severity': 'critical',
            'type': 'something_new',
            'data': <String, dynamic>{},
          },
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      expect(() => InsightsResponse.fromJson(json), returnsNormally);
    });

    test('defaults data to empty map when missing', () {
      final json = {
        'insights': [
          {
            'type': 'top_category',
            'severity': 'info',
            'title': 'titulo',
            'description': 'desc',
          },
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      final response = InsightsResponse.fromJson(json);

      expect(response.insights.first.data, isEmpty);
    });

    test('defaults title and description to empty when missing', () {
      final json = {
        'insights': [
          {
            'type': 'top_category',
            'severity': 'info',
            'data': <String, dynamic>{},
          },
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      final response = InsightsResponse.fromJson(json);

      expect(response.insights.first.title, '');
      expect(response.insights.first.description, '');
    });
  });

  group('InsightsResponseExtension.toModel', () {
    test('maps all known type and severity values', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.insights[3].type, InsightTypeEnum.topCategory);
      expect(bundle.insights[2].type, InsightTypeEnum.dailyAverage);
      expect(bundle.insights[3].severity, InsightSeverityEnum.info);
      expect(bundle.insights[1].type, InsightTypeEnum.willOverspend);
      expect(bundle.insights[0].severity, InsightSeverityEnum.danger);
      expect(bundle.insights[1].severity, InsightSeverityEnum.warning);
      expect(bundle.insights[0].type, InsightTypeEnum.budgetUtilization);
    });

    test('falls back to unknown for unrecognized type and severity', () {
      final json = <String, dynamic>{
        'insights': [
          <String, dynamic>{
            'title': 'titulo',
            'description': 'desc',
            'severity': 'critical',
            'type': 'something_new',
            'data': <String, dynamic>{},
          },
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      final bundle = InsightsResponse.fromJson(json).toModel();

      expect(bundle.insights.first.type, InsightTypeEnum.unknown);
      expect(bundle.insights.first.severity, InsightSeverityEnum.unknown);
    });

    test('preserves data map as-is', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.insights[3].data['category'], 'housing');
      expect(bundle.insights[3].data['pct'], 55.98);
    });

    test('maps title and description to model', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.insights[0].title, 'Estourou o budget');
      expect(bundle.insights[0].description, 'Usou 146% do orçamento.');
    });

    test('converts generatedAt ISO string to DateTime', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.generatedAt.year, 2026);
      expect(bundle.generatedAt.month, 4);
      expect(bundle.generatedAt.day, 22);
    });

    test('preserves hasEnoughData flag', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.hasEnoughData, isFalse);
    });
  });
}
