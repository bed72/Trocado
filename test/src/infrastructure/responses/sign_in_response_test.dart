import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/models/authentication_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/sign_in_response.dart';

void main() {
  group('SignInResponse.fromJson', () {
    test('parses access and refresh tokens', () {
      final SignInResponse response = SignInResponse.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
      });

      expect(response.access, 'access-token');
      expect(response.refresh, 'refresh-token');
    });
  });

  group('SignInResponse.toModel', () {
    test('maps to AuthenticationModel with same values', () {
      const SignInResponse response = SignInResponse(
        access: 'access-token',
        refresh: 'refresh-token',
      );

      final AuthenticationModel model = response.toModel();

      expect(model.access, 'access-token');
      expect(model.refresh, 'refresh-token');
    });
  });
}
