import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/health/health_response.dart';

void main() {
  group('HealthResponse.fromJson', () {
    test('parses all fields', () {
      final response = HealthResponse.fromJson({
        'status': 'ok',
        'version': 1,
        'components': {
          'db': 'ok',
          'cache': 'ok',
          'worker': {'status': 'ok', 'heartbeat_age_seconds': 5.94},
          'queue': {'depth': 0, 'warning': false},
        },
      });

      expect(response.version, 1);
      expect(response.status, 'ok');
    });
  });
}
