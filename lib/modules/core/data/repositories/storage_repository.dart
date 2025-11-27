import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class StorageRepository implements IStorageRepository {
  final IStorageDatasource _datasource;

  StorageRepository({required IStorageDatasource datasource})
    : _datasource = datasource;

  @override
  Future<void> delete({required String key}) async {
    _datasource.delete(key);
  }

  @override
  Future<String?> get({required String key}) async => _datasource.get(key);

  @override
  Future<void> save({required String key, required String value}) async {
    _datasource.save(key, value);
  }
}
