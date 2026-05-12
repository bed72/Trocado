import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_request.dart';

void main() {
  group('FcmTokenRequest', () {
    test('toJson serializes token and platform', () {
      const request = FcmTokenRequest(token: 'abc123', platform: 'android');

      expect(request.toJson(), {'token': 'abc123', 'platform': 'android'});
    });

    test('toJson keeps platform value as-is for ios', () {
      const request = FcmTokenRequest(token: 'xyz789', platform: 'ios');

      expect(request.toJson(), {'token': 'xyz789', 'platform': 'ios'});
    });
  });
}
