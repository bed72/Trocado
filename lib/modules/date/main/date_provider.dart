import 'package:trocado/main.dart';

import 'package:trocado/modules/date/presentation/cubits/date_cubit.dart';

void dateProvider() {
  provider.registerLazySingleton<DateCubit>(DateCubit.new);
}
