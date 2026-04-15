import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/screens/splash/splash_screen.dart';

final class SplashLocation extends Location {
  @override
  String get path => AppRoutes.splash.path;

  @override
  LocationBuilder? get builder =>
      (_) => const SplashScreen();
}
