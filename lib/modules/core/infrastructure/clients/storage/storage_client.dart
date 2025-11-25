import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class IStorageClient {
  Future<String?> get(String key);
  Future<void> delete(String key);
  Future<void> save(String key, String value);
}

final class StorageClient implements IStorageClient {
  final FlutterSecureStorage _storage;

  StorageClient({required FlutterSecureStorage storage}) : _storage = storage;

  @override
  Future<String?> get(String key) async => _storage.read(key: key);

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> save(String key, String value) async {
    await delete(key);
    await _storage.write(key: key, value: value);
  }
}
