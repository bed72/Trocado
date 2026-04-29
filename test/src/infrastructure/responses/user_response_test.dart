import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

void main() {
  group('UserResponse.fromJson', () {
    test('parses all fields', () {
      final response = UserResponse.fromJson({
        'id': 1,
        'name': 'Jane Doe',
        'email': 'jane@trocado.app',
      });

      expect(response.id, 1);
      expect(response.name, 'Jane Doe');
      expect(response.email, 'jane@trocado.app');
    });
  });
}
