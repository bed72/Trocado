import 'dart:ui';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/presentation/observers/state_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(observers: [stateObserver]);
  await container.read(firebaseClientProvider).initialize();

  final crashClient = container.read(crashClientProvider);

  FlutterError.onError = crashClient.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashClient.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };

  unawaited(_logFcmToken(container));

  runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
}

// TODO: Migrate to SplashScreen
Future<void> _logFcmToken(ProviderContainer container) async {
  final logger = container.read(loggerClientProvider);

  try {
    final token = await container.read(messagingClientProvider).getToken();
    logger.information('FCM token: ${token ?? '(null)'}');
  } catch (error, stackTrace) {
    logger.error(
      'Failed to retrieve FCM token',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
