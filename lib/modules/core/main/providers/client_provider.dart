import 'package:trocado/main.dart';

import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';
import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

void clientProvider() {
  provider.registerLazySingleton<IDatabaseClient>(
    () => DatabaseClient(logger: provider.get<ILogger>()),
  );
}
