import 'package:get_it/get_it.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'package:trocado/app_widget.dart';
import 'package:trocado/app_provider.dart';

final provider = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    ensureInitialized(),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);

  runApp(AppWidget());
}
