# Design: storage-client

## Decisão de abstração

O nome `IStorageClient` (não `ISecureStorageClient`) esconde o detalhe de implementação.
Consumidores dependem da interface; podem ser testados com `MockStorageClient`.

## Interface + Implementação

```dart
// lib/src/infrastructure/clients/storage/storage_client.dart

abstract interface class IStorageClient {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> clear();
}

final class StorageClient implements IStorageClient {
  final FlutterSecureStorage _storage;

  StorageClient({required FlutterSecureStorage storage}) : _storage = storage;

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) =>
      _storage.read(key: key);

  @override
  Future<void> delete({required String key}) =>
      _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
```

## Configuração iOS

`flutter_secure_storage` usa o Keychain no iOS. Requer:

1. `ios/Runner/Info.plist` — adicionar `CFBundleIdentifier` se ausente (normalmente já existe)
2. Xcode → Signing & Capabilities → adicionar **Keychain Sharing** capability
3. `ios/Runner.xcodeproj/project.pbxproj` — a capability é adicionada automaticamente pelo Xcode

Sem essa configuração, leituras do Keychain retornam `null` silenciosamente no iOS.

## Registro em injection.dart

```dart
sl.registerLazySingleton<IStorageClient>(
  () => StorageClient(storage: const FlutterSecureStorage()),
);
```

## Testes

Não há testes unitários do `StorageClient` — é um thin wrapper sobre `flutter_secure_storage`
(mesmo padrão do `LoggerClient`).

`MockStorageClient` adicionado em `test/mocks/mocks.dart` para uso pelos consumidores.

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| `flutter_secure_storage` | DataStore + CryptographyClient manual | Lib já encapsula Keychain (iOS) e EncryptedSharedPreferences (Android) |
| `IStorageClient` (sem "Secure") | `ISecureStorageClient` | Detalhe de implementação não deve vazar na interface |
| Sem datasource | `ILocalStorageDataSource` por cima | Client já é simples o suficiente; camada extra sem valor |
| `FlutterSecureStorage` injetada via construtor | criada internamente | Permite substituição em testes |
