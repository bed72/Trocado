import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/screens/forgot_password_screen.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/locations/forgot_password_success_location.dart';

final class ForgotPasswordLocation extends Location {
  @override
  String get path => AppRoutes.forgotPassword.path;

  @override
  LocationBuilder? get builder =>
      (context) => ForgotPasswordScreen(
        onSuccess: (email) => context.navigate(
          ForgotPasswordSuccessLocation(email: email),
          replace: true,
        ),
      );
}
