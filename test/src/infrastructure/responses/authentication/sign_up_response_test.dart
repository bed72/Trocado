import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/authentication/sign_up_response.dart';

void main() {
  group('SignUpResponse.fromJson', () {
    test('parses access, refresh and full user object', () {
      final json = {
        'access': 'access-token',
        'refresh': 'refresh-token',
        'user': {
          'id': 42,
          'name': 'jane',
          'email': 'jane@trocado.app',
          'avatar': 'https://example.com/avatar.png',
        },
      };

      final response = SignUpResponse.fromJson(json);

      expect(response.user.id, 42);
      expect(response.user.name, 'jane');
      expect(response.access, 'access-token');
      expect(response.refresh, 'refresh-token');
      expect(response.user.email, 'jane@trocado.app');
      expect(response.user.avatar, 'https://example.com/avatar.png');
    });

    test('accepts null avatar in user', () {
      final json = {
        'access': 'access-token',
        'refresh': 'refresh-token',
        'user': {
          'id': 42,
          'name': 'jane',
          'avatar': null,
          'email': 'jane@trocado.app',
        },
      };

      final response = SignUpResponse.fromJson(json);

      expect(response.user.avatar, isNull);
    });
  });
}
