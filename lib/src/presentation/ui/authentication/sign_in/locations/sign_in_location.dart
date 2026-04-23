import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/ui/home/locations/home_location.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/screens/sign_in_screen.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/locations/sign_up_location.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/locations/forgot_password_location.dart';

final class SignInLocation extends Location {
  @override
  String get path => AppRoutes.signIn.path;

  @override
  LocationBuilder? get builder =>
      (context) => SignInScreen(
        onSignUp: () => context.navigate(SignUpLocation()),
        onSuccess: () =>
            context.navigate(HomeLocation(), root: true, replace: true),
        onForgotPassword: () => context.navigate(ForgotPasswordLocation()),
      );
}
