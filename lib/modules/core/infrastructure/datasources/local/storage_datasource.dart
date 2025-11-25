import 'package:trocado/modules/core/data/datasources/interface_storage_datasource.dart';
import 'package:trocado/modules/core/infrastructure/clients/storage/storage_client.dart';

final class StorageDatasource implements IStorageDatasource {
  final IStorageClient _client;

  StorageDatasource({required IStorageClient client}) : _client = client;

  @override
  Future<void> delete(String key) async {
    _client.delete(key);
  }

  @override
  Future<String?> get(String key) async => _client.get(key);

  @override
  Future<void> save(String key, String value) async {
    _client.save(key, value);
  }
}
