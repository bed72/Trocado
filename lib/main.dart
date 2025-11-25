import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/modules/core/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: providers, child: AppWidget()));
}
