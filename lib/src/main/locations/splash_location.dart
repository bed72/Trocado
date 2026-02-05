import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/locations/home_location.dart';

import 'package:trocado/src/presentation/screens/splash_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class SplashLocation extends Location {
  @override
  String get path => RoutesConstant.splash.path;

  @override
  LocationBuilder? get builder =>
      (context) => SplashScreen(
        navigateTo: () =>
            context.navigate(HomeLocation(), root: true, replace: true),
      );
}
