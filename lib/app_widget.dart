import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/themes/themes.dart';
import 'package:trocado/src/presentation/widgets/load_widget.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Trocado',
        themeMode: .system,
        theme: Themes.light,
        darkTheme: Themes.dark,
        routerConfig: routerConfig,
        debugShowCheckedModeBanner: kDebugMode,
        supportedLocales: const [Locale('pt', 'BR')],
        builder: (_, child) => LoadWidget(child: child),
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
