import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/sign_in_response.dart';

void main() {
  group('SignInResponse.fromJson', () {
    test('parses access and refresh tokens', () {
      final response = SignInResponse.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
      });

      expect(response.access, 'access-token');
      expect(response.refresh, 'refresh-token');
    });
  });
}
