import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/locations/home_location.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/sign_up_screen.dart';

final class SignUpLocation extends Location {
  @override
  String get path => AppRoutes.signUp.path;

  @override
  LocationBuilder? get builder =>
      (context) => SignUpScreen(
        onSignIn: context.pop,
        onSuccess: () =>
            context.navigate(HomeLocation(), root: true, replace: true),
      );
}
