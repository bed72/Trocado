import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/extensions/couple_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/couple_response.dart';

void main() {
  group('CoupleResponseExtension.toModel', () {
    test('maps id, partner and converts createdAt to milliseconds', () {
      final response = CoupleResponse(
        id: 7,
        createdAt: '2026-01-12T14:30:00Z',
        partner: const UserResponse(
          id: 2,
          name: 'Marina',
          email: 'marina@trocado.app',
        ),
      );

      final model = response.toModel();

      expect(model.id, 7);
      expect(model.partner.id, 2);
      expect(model.partner.name, 'Marina');
      expect(model.partner.email, 'marina@trocado.app');
      expect(
        model.createdAt,
        DateTime.parse('2026-01-12T14:30:00Z').millisecondsSinceEpoch,
      );
    });
  });
}
