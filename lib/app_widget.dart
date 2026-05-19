import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/themes/themes.dart';
import 'package:trocado/src/presentation/widgets/load_widget.dart';
import 'package:trocado/src/presentation/extensions/theme_mode_enum_extension.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/theme/theme_notifier.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final themeMode = ref
          .watch(themeProvider)
          .maybeWhen(
            data: (s) => s.mode.themeMode,
            orElse: () => ThemeMode.system,
          );

      return ToastificationWrapper(
        child: MaterialApp.router(
          title: 'Trocado',
          theme: Themes.light,
          themeMode: themeMode,
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
    },
  );
}
