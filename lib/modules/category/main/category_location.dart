import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/cubits/category_cubit.dart';
import 'package:trocado/modules/category/presentation/screens/category_screen.dart';

final class CategoryLocation extends Location {
  final TransactionTypeData type;

  const CategoryLocation({required this.type});

  @override
  String get path => RoutesConstant.category.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) =>
            CategoryScreen(type: type, cubit: context.get<CategoryCubit>()),
      );
}
