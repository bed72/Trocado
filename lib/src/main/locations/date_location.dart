import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/domain/constants/routes_constant.dart';

import 'package:trocado/src/presentation/screens/date_screen.dart';
import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

final class DateLocation extends Location {
  @override
  String get path => RoutesConstant.date.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) => DateScreen(cubit: context.get<TransactionCubit>()),
      );
}
