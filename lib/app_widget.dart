import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/modules/core/core.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trocado',
      theme: Themes.light,
      darkTheme: Themes.dark,
      routerConfig: routerConfig,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: kDebugMode,
      builder: (_, child) => LoadWidget(child: child),
    );
  }
}
