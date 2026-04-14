import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/authentication/password_reset_confirm/password_reset_confirm_screen.dart';

final class PasswordResetConfirmLocation extends Location {
  final String uid;
  final String token;

  const PasswordResetConfirmLocation({required this.uid, required this.token});

  @override
  String get path => AppRoutes.passwordResetConfirm.path;

  @override
  LocationBuilder? get builder =>
      (context) => PasswordResetConfirmScreen(
        uid: uid,
        token: token,
        onSuccess: () => context.navigate(
          SignInLocation(),
          root: true,
          replace: true,
        ),
      );
}
