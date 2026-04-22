import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/insights/insight_type.dart';
import 'package:trocado/src/domain/models/insights/insight_severity.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/insights_response.dart';

import 'package:trocado/src/data/extensions/insights_response_extension.dart';

const _json = {
  'insights': [
    {
      'severity': 'danger',
      'type': 'budget_utilization',
      'message': 'Usou 146% do orçamento.',
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
      'message': 'No ritmo atual, estoura em 0 dias.',
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
      'message': 'Média diária de R\$208.02.',
      'data': {'actual_daily_rate': 208.02, 'ideal_daily_rate': 103.45},
    },
    {
      'severity': 'info',
      'type': 'top_category',
      'data': {'category': 'housing', 'pct': 55.98},
      'message': 'Housing representa 56% dos gastos.',
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
      expect(response.insights[0].message, 'Usou 146% do orçamento.');
    });

    test('accepts unknown type and severity without throwing', () {
      final json = <String, dynamic>{
        'insights': [
          <String, dynamic>{
            'message': 'msg',
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
          {'type': 'top_category', 'severity': 'info', 'message': 'msg'},
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      final response = InsightsResponse.fromJson(json);

      expect(response.insights.first.data, isEmpty);
    });
  });

  group('InsightsResponseExtension.toModel', () {
    test('maps all known type and severity values', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.insights[3].type, InsightType.topCategory);
      expect(bundle.insights[2].type, InsightType.dailyAverage);
      expect(bundle.insights[3].severity, InsightSeverity.info);
      expect(bundle.insights[1].type, InsightType.willOverspend);
      expect(bundle.insights[0].severity, InsightSeverity.danger);
      expect(bundle.insights[1].severity, InsightSeverity.warning);
      expect(bundle.insights[0].type, InsightType.budgetUtilization);
    });

    test('falls back to unknown for unrecognized type and severity', () {
      final json = <String, dynamic>{
        'insights': [
          <String, dynamic>{
            'message': 'msg',
            'severity': 'critical',
            'type': 'something_new',
            'data': <String, dynamic>{},
          },
        ],
        'has_enough_data': true,
        'generated_at': '2026-04-22T00:00:00Z',
      };

      final bundle = InsightsResponse.fromJson(json).toModel();

      expect(bundle.insights.first.type, InsightType.unknown);
      expect(bundle.insights.first.severity, InsightSeverity.unknown);
    });

    test('preserves data map as-is', () {
      final bundle = InsightsResponse.fromJson(_json).toModel();

      expect(bundle.insights[3].data['category'], 'housing');
      expect(bundle.insights[3].data['pct'], 55.98);
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
