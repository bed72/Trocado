import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';

void main() {
  group('InsightSeverityEnum.fromString', () {
    test('maps every known API string to matching enum value', () {
      expect(InsightSeverityEnum.fromString('info'), InsightSeverityEnum.info);
      expect(
        InsightSeverityEnum.fromString('danger'),
        InsightSeverityEnum.danger,
      );
      expect(
        InsightSeverityEnum.fromString('warning'),
        InsightSeverityEnum.warning,
      );
    });

    test('falls back to unknown for unmapped strings', () {
      expect(
        InsightSeverityEnum.fromString('critical'),
        InsightSeverityEnum.unknown,
      );
      expect(InsightSeverityEnum.fromString(''), InsightSeverityEnum.unknown);
      expect(
        InsightSeverityEnum.fromString('INFO'),
        InsightSeverityEnum.unknown,
      );
    });

    test('falls back to unknown on null', () {
      expect(InsightSeverityEnum.fromString(null), InsightSeverityEnum.unknown);
    });
  });
}
