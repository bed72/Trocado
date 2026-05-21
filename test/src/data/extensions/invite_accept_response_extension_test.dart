import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/extensions/invite_accept_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart';

void main() {
  group('InviteAcceptResponseExtension.toModel', () {
    test('maps couple_id and partner fields to InviteAcceptModel', () {
      const response = InviteAcceptResponse(
        coupleId: 1,
        partner: UserResponse(
          id: 2,
          name: 'Marina',
          email: 'partner@trocado.app',
        ),
      );

      final model = response.toModel();

      expect(model.coupleId, 1);
      expect(model.partner.id, 2);
      expect(model.partner.name, 'Marina');
      expect(model.partner.email, 'partner@trocado.app');
    });
  });
}
