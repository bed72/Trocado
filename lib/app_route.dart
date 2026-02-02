import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/main/locations/splash_location.dart';

import 'package:trocado/src/presentation/observers/logger_navigation_observer.dart';

final routerConfig = DuckRouter(
  initialLocation: SplashLocation(),
  navigatorObserverBuilder: (_) => [LoggerNavigatorObserver()],
  onDeepLink: (uri, _) {
    // adb shell am start -a android.intent.action.VIEW -d "trocado://app/settings"

    return [];
  },
);
