import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/me_response.dart';

void main() {
  group('MeResponse.fromJson', () {
    test('parses all fields including nullable avatar', () {
      final response = MeResponse.fromJson({
        'id': 1,
        'name': 'Jane Doe',
        'email': 'jane@trocado.app',
        'avatar': 'https://example.com/avatar.jpg',
      });

      expect(response.id, 1);
      expect(response.name, 'Jane Doe');
      expect(response.email, 'jane@trocado.app');
      expect(response.avatar, 'https://example.com/avatar.jpg');
    });

    test('parses null avatar', () {
      final response = MeResponse.fromJson({
        'id': 1,
        'avatar': null,
        'name': 'Jane Doe',
        'email': 'jane@trocado.app',
      });

      expect(response.avatar, isNull);
    });
  });
}
