import 'package:trocado/modules/core/domain/either.dart';

import 'package:trocado/modules/core/data/datasources/interface_database_datasource.dart';
import 'package:trocado/modules/core/infrastructure/clients/database/database_client.dart';

final class DatabaseDatasource implements IDatabaseDatasource {
  final IDatabaseClient _client;

  DatabaseDatasource({required IDatabaseClient client}) : _client = client;

  @override
  Future<void> drop() async {
    await _client.database.deleteDatabase();
  }

  @override
  Future<AllDatabaseDatasource> all(String table, [String? id]) async {
    final response = id != null
        ? await _client.database.query(table)
        : await _client.database.query(table).where('id', '=', id);

    return response.isSuccess ? Right(response.data) : Left(null);
  }

  @override
  Future<void> delete(String table, [String? id]) async {
    if (id == null) return;

    await _client.database.delete(table).where('id', '=', id);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    await _client.database.upsert(table, data).where('id', '=', data['id']);
  }
}
