import 'package:trocado/main.dart';

import 'package:trocado/modules/category/presentation/cubits/category_cubit.dart';

void categoryProvider() {
  provider.registerLazySingleton<CategoryCubit>(CategoryCubit.new);
}
