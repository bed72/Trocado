import 'package:duck_router/duck_router.dart';
import 'package:flutter/services.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/exit/presentation/exit_screen.dart';

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
