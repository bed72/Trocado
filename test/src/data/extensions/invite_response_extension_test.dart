import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/data/extensions/invite_response_extension.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';

void main() {
  group('InviteResponseExtension.toModel', () {
    test('maps code and qrData and converts expiresAt to milliseconds', () {
      final response = InviteResponse(
        code: 'A3K7FN',
        qrData: 'trocado://invite/A3K7FN',
        expiresAt: '2026-03-18T14:30:00Z',
      );

      final model = response.toModel();

      expect(model.code, 'A3K7FN');
      expect(model.qrData, 'trocado://invite/A3K7FN');
      expect(
        model.expiresAt,
        DateTime.parse('2026-03-18T14:30:00Z').millisecondsSinceEpoch,
      );
    });
  });
}
