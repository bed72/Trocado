import 'package:trocado/src/infrastructure/clients/storage/storage_key.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';

abstract interface class ILocalTokenDataSource {
  Future<void> clear();
  Future<({String? access, String? refresh})> get();
  Future<void> save({required String access, required String refresh});
}

final class LocalTokenDataSource implements ILocalTokenDataSource {
  final IStorageClient _client;

  LocalTokenDataSource({required this._client});

  @override
  Future<void> clear() => _client.clear();

  @override
  Future<void> save({required String access, required String refresh}) async {
    await Future.wait([
      _client.write(key: StorageKey.accessToken.value, value: access),
      _client.write(key: StorageKey.refreshToken.value, value: refresh),
    ]);
  }

  @override
  Future<({String? access, String? refresh})> get() async {
    final access = await _client.read(key: StorageKey.accessToken.value);
    final refresh = await _client.read(key: StorageKey.refreshToken.value);

    return (access: access, refresh: refresh);
  }
}
