import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/date/presentation/cubits/date_cubit.dart';
import 'package:trocado/modules/date/presentation/screens/date_screen.dart';

final class DateLocation extends Location {
  @override
  String get path => RoutesConstant.date.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) => DateScreen(cubit: context.get<DateCubit>()),
      );
}
