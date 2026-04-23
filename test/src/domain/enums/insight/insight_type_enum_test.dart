import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';

void main() {
  group('InsightTypeEnum.fromString', () {
    test('maps every known API string to matching enum value', () {
      expect(
        InsightTypeEnum.fromString('top_category'),
        InsightTypeEnum.topCategory,
      );
      expect(
        InsightTypeEnum.fromString('daily_average'),
        InsightTypeEnum.dailyAverage,
      );
      expect(
        InsightTypeEnum.fromString('will_overspend'),
        InsightTypeEnum.willOverspend,
      );
      expect(
        InsightTypeEnum.fromString('budget_utilization'),
        InsightTypeEnum.budgetUtilization,
      );
    });

    test('falls back to unknown for unmapped strings', () {
      expect(
        InsightTypeEnum.fromString('topCategory'),
        InsightTypeEnum.unknown,
      );
      expect(InsightTypeEnum.fromString(''), InsightTypeEnum.unknown);
      expect(
        InsightTypeEnum.fromString('TOP_CATEGORY'),
        InsightTypeEnum.unknown,
      );
    });

    test('falls back to unknown on null', () {
      expect(InsightTypeEnum.fromString(null), InsightTypeEnum.unknown);
    });
  });
}
