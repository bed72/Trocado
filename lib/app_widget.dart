import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/modules/core/core.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.get<ThemeStore>();

    return Observer(
      builder: (_) => MaterialApp.router(
        title: 'Trocado',
        theme: Themes.light,
        darkTheme: Themes.dark,
        themeMode: store.theme,
        routerConfig: routerConfig,
        debugShowCheckedModeBanner: kDebugMode,
        builder: (_, child) => LoadWidget(child: child),
      ),
    );
  }
}
