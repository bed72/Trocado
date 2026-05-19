import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_widget.dart';

import 'package:trocado/src/presentation/observers/state_observer.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/notification_lifecycle_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    observers: kDebugMode ? [stateObserver] : const [],
  );
  await container.read(firebaseClientProvider).initialize();
  await container.read(appCheckClientProvider).initialize();

  container.read(notificationLifecycleProvider);

  final client = container.read(crashClientProvider);

  FlutterError.onError = client.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    client.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };

  runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
}
