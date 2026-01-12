import 'dart:developer';

import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/date/presentation/screens/date_screen.dart';

final class DateLocation extends Location {
  @override
  String get path => RoutesConstant.date.path;

  @override
  LocationPageBuilder get pageBuilder => (_) {
    return BottomSheetPage(
      builder: (_) => DateScreen(
        date: (value) {
          log(value.toString());
        },
      ),
    );
  };
}
