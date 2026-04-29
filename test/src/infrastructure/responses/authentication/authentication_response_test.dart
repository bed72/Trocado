import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/authentication/authentication_response.dart';

void main() {
  group('AuthenticationResponse.fromJson', () {
    test('parses access and refresh tokens', () {
      final response = AuthenticationResponse.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
      });

      expect(response.access, 'access-token');
      expect(response.refresh, 'refresh-token');
    });
  });
}
