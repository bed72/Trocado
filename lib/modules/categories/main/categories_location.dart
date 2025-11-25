import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/categories/presentation/screens/categories_screen.dart';

final class CategoriesLocation extends Location {
  @override
  String get path => RoutesConstant.categories.path;

  @override
  LocationBuilder? get builder =>
      (_) => CategoriesScreen();
}
