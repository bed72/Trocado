import 'package:sqflite/sqflite.dart';

import 'package:trocado/modules/core/domain/either.dart';
import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';

import 'package:trocado/modules/core/infrastructure/resources/loggers/logger.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

final class DatabaseDatasource implements IDatabaseDatasource {
  final ILogger _logger;
  final IDatabaseClient _client;

  DatabaseDatasource({required ILogger logger, required IDatabaseClient client})
    : _logger = logger,
      _client = client;

  @override
  Future<void> drop() async {
    await _client.database.close();
    await deleteDatabase(_client.database.path);
  }

  @override
  Future<AllDatabaseDatasource> all(String table) async {
    try {
      final response = await _client.database.query(table);

      return response.isNotEmpty
          ? Right(response)
          : Left('Ops, não encontramos os dados solicitados.');
    } catch (exception) {
      _logger.error(exception.toString());
      return Left('Ops, tivemos um problema ao ler seus dados.');
    }
  }

  @override
  Future<AllDatabaseDatasource> find(String table, String id) async {
    try {
      final response = await _client.database.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );

      return response.isNotEmpty
          ? Right(response)
          : Left('Ops, não encontramos o dado solicitado.');
    } catch (exception) {
      _logger.error(exception.toString());
      return Left('Ops, tivemos um problema ao buscar o dado.');
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    try {
      await _client.database.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (exception) {
      _logger.error(exception.toString());
    }
  }

  @override
  Future<bool> update(String table, Map<String, dynamic> data) async {
    try {
      final id = data['id'];

      final response = await _client.database.update(
        table,
        data,
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return response > 0;
    } catch (exception) {
      _logger.error(exception.toString());
      return false;
    }
  }

  @override
  Future<bool> insert(String table, Map<String, dynamic> data) async {
    try {
      final response = await _client.database.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return response > 0;
    } catch (exception) {
      _logger.error(exception.toString());
      return false;
    }
  }
}
