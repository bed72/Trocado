import 'package:flutter/widgets.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/src/main/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const AppWidget());
}
