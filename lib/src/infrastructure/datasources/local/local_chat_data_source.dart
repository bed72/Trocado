import 'package:trocado/src/infrastructure/clients/storage/storage_key.dart';
import 'package:trocado/src/infrastructure/clients/storage/storage_client.dart';

abstract interface class ILocalChatDataSource {
  Future<String?> getSessionId();
  Future<void> saveSessionId({required String sessionId});
}

final class LocalChatDataSource implements ILocalChatDataSource {
  final IStorageClient _client;

  LocalChatDataSource({required IStorageClient client}) : _client = client;

  @override
  Future<String?> getSessionId() =>
      _client.read(key: StorageKey.chatSessionId.value);

  @override
  Future<void> saveSessionId({required String sessionId}) =>
      _client.write(key: StorageKey.chatSessionId.value, value: sessionId);
}
