import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/presentation/observers/state_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(observers: [stateObserver]);
  await container.read(firebaseClientProvider).initialize();

  runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
}
