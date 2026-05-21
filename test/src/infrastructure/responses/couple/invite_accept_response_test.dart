import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart';

void main() {
  group('InviteAcceptResponse.fromJson', () {
    test('parses all fields', () {
      final response = InviteAcceptResponse.fromJson({
        'couple_id': 1,
        'partner': {'id': 2, 'name': 'Jane Doe', 'email': 'jane@trocado.app'},
      });

      expect(response.coupleId, 1);
      expect(response.partner.id, 2);
      expect(response.partner.name, 'Jane Doe');
      expect(response.partner.email, 'jane@trocado.app');
    });
  });
}
