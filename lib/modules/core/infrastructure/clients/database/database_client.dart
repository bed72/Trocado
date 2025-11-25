import 'package:tostore/tostore.dart';
import 'package:flutter/foundation.dart';

import 'package:trocado/modules/core/domain/constant/database_constant.dart';

import 'package:trocado/modules/core/infrastructure/clients/database/schemas/user_schema.dart';

abstract interface class IDatabaseClient {
  ToStore get database;

  Future<void> ensureInitialized();
}

final class DatabaseClient implements IDatabaseClient {
  @override
  ToStore get database => ToStore(
    config: _config,
    schemas: _schemas,
    dbName: DatabaseConstant.databaseName.name,
  );

  @override
  Future<void> ensureInitialized() async {
    await database.initialize();
  }

  DataStoreConfig get _config => DataStoreConfig(
    enableLog: kDebugMode,
    logLevel: LogLevel.debug,
    dbName: DatabaseConstant.databaseName.name,
  );

  List<TableSchema> get _schemas => [userSchema];
}
