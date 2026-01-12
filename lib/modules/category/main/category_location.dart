import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/screens/category_screen.dart';

final class CategoryLocation extends Location {
  final TransactionTypeState type;

  const CategoryLocation({required this.type});

  @override
  String get path => RoutesConstant.category.path;

  @override
  LocationPageBuilder get pageBuilder => (_) {
    return BottomSheetPage(
      builder: (_) => CategoryScreen(type: type, onSelected: (value) {}),
    );
  };
}
