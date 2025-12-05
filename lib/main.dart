import 'package:get_it/get_it.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/modules/core/core.dart';

final provider = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SolidartConfig.devToolsEnabled = true;
  SolidartConfig.assertSignalBuilderWithoutDependencies = false;

  await Future.wait([
    ensureInitialized(),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);

  runApp(AppWidget());
}
