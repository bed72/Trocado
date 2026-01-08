import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:trocado/modules/core/domain/constant/database_constant.dart';

import 'package:trocado/modules/core/infrastructure/clients/schemas/schemas.dart';
import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';

abstract interface class IDatabaseClient {
  Database get database;

  Future<void> ensureInitialized();
}

final class DatabaseClient implements IDatabaseClient {
  final ILogger _logger;

  Database? _instance;

  DatabaseClient({required ILogger logger}) : _logger = logger;

  @override
  Database get database {
    final database = _instance;

    if (database == null) {
      throw Exception('Database not initialized. Call ensureInitialized()');
    }

    return database;
  }

  @override
  Future<void> ensureInitialized() async {
    if (_instance != null) return;

    final path = await _path();

    _instance = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        _logger.debug('[DATABASE] Creating database v$version');

        await _create(database);
      },
    );
  }

  Future<String> _path() async {
    final path = await getDatabasesPath();
    return join(path, DatabaseConstant.databaseName.name);
  }

  Future<void> _create(Database database) async {
    for (final schema in schemas) {
      await database.execute(schema);
    }
  }
}
