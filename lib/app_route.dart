import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/splash/splash.dart';

final routerConfig = DuckRouter(
  initialLocation: SplashLocation(),
  onDeepLink: (uri, _) {
    // adb shell am start -a android.intent.action.VIEW -d "trocado://app/settings"

    return [];
  },
  navigatorObserverBuilder: (_) => [LoggerNavigatorObserver()],
);
