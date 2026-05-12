import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_delete_request.dart';

void main() {
  group('FcmTokenDeleteRequest', () {
    test('toJson serializes only token', () {
      const request = FcmTokenDeleteRequest(token: 'abc123');

      expect(request.toJson(), {'token': 'abc123'});
    });

    test('toJson does not include platform or any other key', () {
      const request = FcmTokenDeleteRequest(token: 'xyz789');

      final json = request.toJson();
      expect(json.keys, ['token']);
      expect(json.containsKey('platform'), isFalse);
    });
  });
}
