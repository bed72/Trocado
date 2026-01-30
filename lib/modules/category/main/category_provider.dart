import 'package:trocado/main.dart';

import 'package:trocado/modules/category/presentation/cubits/category_cubit.dart';

void categoryProvider() {
  i.registerLazySingleton<CategoryCubit>(
    CategoryCubit.new,
    dispose: (cubit) => cubit.close(),
  );
}
