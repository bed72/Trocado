import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/src/presentation/observers/state_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(observers: [stateObserver], child: AppWidget()));
}
