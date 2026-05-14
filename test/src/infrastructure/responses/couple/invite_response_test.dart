import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';

void main() {
  group('InviteResponse.fromJson', () {
    test('parses all fields', () {
      final response = InviteResponse.fromJson({
        'code': 'A3K7FN',
        'qr_data': 'trocado://invite/A3K7FN',
        'expires_at': '2026-03-18T14:30:00Z',
      });

      expect(response.code, 'A3K7FN');
      expect(response.qrData, 'trocado://invite/A3K7FN');
      expect(response.expiresAt, '2026-03-18T14:30:00Z');
    });
  });
}
