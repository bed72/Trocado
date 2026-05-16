import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';

void main() {
  group('CoupleResponse.fromJson', () {
    test('parses id, createdAt and partner fields', () {
      final response = CoupleResponse.fromJson({
        'id': 1,
        'created_at': '2026-01-12T14:30:00Z',
        'partner': {'id': 2, 'name': 'Marina', 'email': 'partner@trocado.app'},
      });

      expect(response.id, 1);
      expect(response.partner.id, 2);
      expect(response.partner.name, 'Marina');
      expect(response.createdAt, '2026-01-12T14:30:00Z');
      expect(response.partner.email, 'partner@trocado.app');
    });
  });
}
