import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/password_reset_response.dart';

void main() {
  group('PasswordResetResponse.fromJson', () {
    test('parses detail field', () {
      final json = {
        'detail': 'If this email is registered, a reset link has been sent.',
      };

      final response = PasswordResetResponse.fromJson(json);

      expect(
        response.detail,
        'If this email is registered, a reset link has been sent.',
      );
    });
  });
}
