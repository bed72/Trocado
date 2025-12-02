import 'package:trocado/main.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

void provideResources() {
  provider.registerLazySingleton<ILogger>(Logger.new);
}
