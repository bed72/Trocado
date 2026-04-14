import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/password_reset_confirm_location.dart';

final class DeepLinkHandler {
  const DeepLinkHandler();

  List<Location> call(Uri uri) => switch (uri.path) {
    '/reset-password' => _passwordResetConfirm(uri),
    _                 => [],
  };

  List<Location> _passwordResetConfirm(Uri uri) {
    final uid   = uri.queryParameters['uid']   ?? '';
    final token = uri.queryParameters['token'] ?? '';
    if (uid.isEmpty || token.isEmpty) return [];
    return [PasswordResetConfirmLocation(uid: uid, token: token)];
  }
}
