import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/locations/sign_in_location.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/screens/forgot_password_success_screen.dart';

final class ForgotPasswordSuccessLocation extends Location {
  final String email;

  const ForgotPasswordSuccessLocation({required this.email});

  @override
  String get path => AppRoutes.forgotPasswordSuccess.path;

  @override
  LocationBuilder? get builder =>
      (context) => ForgotPasswordSuccessScreen(
        email: email,
        onBackToSignIn: () =>
            context.popUntil((location) => location is SignInLocation),
      );
}
