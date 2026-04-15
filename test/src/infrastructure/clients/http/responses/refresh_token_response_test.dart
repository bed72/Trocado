import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/refresh_token_response.dart';

void main() {
  group('RefreshTokenResponse', () {
    test('fromJson parses access and refresh tokens', () {
      const json = {
        'access': 'new_access_token',
        'refresh': 'new_refresh_token',
      };

      final response = RefreshTokenResponse.fromJson(json);

      expect(response.access, 'new_access_token');
      expect(response.refresh, 'new_refresh_token');
    });
  });
}
