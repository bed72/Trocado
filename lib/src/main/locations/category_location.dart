import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/category_screen.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

final class CategoryLocation extends Location {
  @override
  String get path => RoutesConstant.category.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) =>
            CategoryScreen(cubit: context.get<TransactionCubit>()),
      );
}
