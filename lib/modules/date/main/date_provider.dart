import 'package:trocado/main.dart';

import 'package:trocado/modules/date/presentation/cubits/date_cubit.dart';

void dateProvider() {
  i.registerLazySingleton<DateCubit>(
    DateCubit.new,
    dispose: (cubit) => cubit.close(),
  );
}
