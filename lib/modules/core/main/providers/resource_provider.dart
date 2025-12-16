import 'package:trocado/main.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

void resourceProvider() {
  provider.registerLazySingleton<ILogger>(Logger.new);
}
