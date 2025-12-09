import 'package:trocado/modules/core/domain/either.dart';

typedef AllDatabaseDatasource = Either<String, List<Map<String, Object?>>>;

abstract interface class IDatabaseDatasource {
  Future<void> drop();
  Future<void> delete(String table, String id);
  Future<AllDatabaseDatasource> all(String table);
  Future<AllDatabaseDatasource> find(String table, String id);
  Future<bool> insert(String table, Map<String, dynamic> data);
  Future<bool> update(String table, Map<String, dynamic> data);
}
