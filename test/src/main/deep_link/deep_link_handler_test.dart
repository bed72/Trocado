import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/main/deep_link/deep_link_handler.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/password_reset_confirm_location.dart';

void main() {
  const handler = DeepLinkHandler();

  group('DeepLinkHandler', () {
    group('/reset-password', () {
      test('returns [SignInLocation, PasswordResetConfirmLocation] with uid and token', () {
        final uri = Uri.parse(
          'trocado://app/reset-password?uid=Mw&token=bm7gkj-1a2b3c4d',
        );

        final locations = handler(uri);

        expect(locations, hasLength(2));
        expect(locations.first, isA<SignInLocation>());
        expect(locations.last, isA<PasswordResetConfirmLocation>());

        final location = locations.last as PasswordResetConfirmLocation;
        expect(location.uid, 'Mw');
        expect(location.token, 'bm7gkj-1a2b3c4d');
      });

      test('returns empty list when uid is missing', () {
        final uri = Uri.parse('trocado://app/reset-password?token=bm7gkj');

        expect(handler(uri), isEmpty);
      });

      test('returns empty list when token is missing', () {
        final uri = Uri.parse('trocado://app/reset-password?uid=Mw');

        expect(handler(uri), isEmpty);
      });

      test('returns empty list when uid is empty', () {
        final uri = Uri.parse('trocado://app/reset-password?uid=&token=bm7gkj');

        expect(handler(uri), isEmpty);
      });

      test('returns empty list when token is empty', () {
        final uri = Uri.parse('trocado://app/reset-password?uid=Mw&token=');

        expect(handler(uri), isEmpty);
      });
    });

    test('returns empty list for unknown path', () {
      final uri = Uri.parse('trocado://app/unknown-route');

      expect(handler(uri), isEmpty);
    });
  });
}
