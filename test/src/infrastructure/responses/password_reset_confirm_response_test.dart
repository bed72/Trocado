import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/password_reset_confirm_response.dart';

void main() {
  group('PasswordResetConfirmResponse.fromJson', () {
    test('parses detail field', () {
      final json = {'detail': 'Password has been reset successfully.'};

      final response = PasswordResetConfirmResponse.fromJson(json);

      expect(response.detail, 'Password has been reset successfully.');
    });
  });
}
