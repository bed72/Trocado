import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/forgot_password_screen.dart';

final class ForgotPasswordLocation extends Location {
  @override
  String get path => AppRoutes.forgotPassword.path;

  @override
  LocationBuilder? get builder =>
      (context) => ForgotPasswordScreen(onBack: context.pop);
}
