import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/sign_in_location.dart';

import 'package:trocado/src/presentation/screens/splash_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class SplashLocation extends Location {
  @override
  String get path => AppRoutes.splash.path;

  @override
  LocationBuilder? get builder =>
      (context) => SplashScreen(
        navigateTo: () =>
            context.navigate(SignInLocation(), root: true, replace: true),
      );
}
