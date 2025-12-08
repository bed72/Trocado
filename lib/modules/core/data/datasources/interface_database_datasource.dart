import 'package:trocado/modules/core/domain/either.dart';

typedef AllDatabaseDatasource = Either<Null, List<Map<String, dynamic>>>;

abstract interface class IDatabaseDatasource {
  Future<void> drop();
  Future<void> delete(String table, [String? id]);
  Future<bool> upsert(String table, Map<String, dynamic> data);
  Future<AllDatabaseDatasource> all(String table, [String? id]);
}
