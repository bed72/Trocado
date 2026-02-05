import 'package:flutter/services.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/screens/exit_screen.dart';
import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class ExitLocation extends Location {
  const ExitLocation();

  @override
  String get path => RoutesConstant.exit.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => BottomSheetPage(
        builder: (_) =>
            ExitScreen(onCancel: context.pop, onExit: SystemNavigator.pop),
      );
}
