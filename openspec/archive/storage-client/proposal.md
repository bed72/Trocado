# Proposal: storage-client

## Intenção

Implementar o client de armazenamento local seguro do app, expondo uma interface genérica
`IStorageClient` sem revelar que o armazenamento é criptografado.

## Motivação

Necessário para persistir tokens JWT (access/refresh) após o sign-in. O `AuthenticationRepository`
e futuros consumidores dependem deste client para ler/escrever credenciais locais.

## Camadas afetadas

- `infrastructure/clients/storage/` — `IStorageClient` + `StorageClient` (backed by `flutter_secure_storage`)
- `main/injection.dart` — registro do `StorageClient`
- `test/mocks/mocks.dart` — `MockStorageClient`

## Configuração de plataforma

- **iOS**: requer `KeychainSharingCapability` e configuração do `Info.plist` para uso do Keychain
- **Android**: `flutter_secure_storage` usa `EncryptedSharedPreferences` — sem configuração adicional

## Fora do escopo

- Datasource de storage
- Persistência de tokens (uso do client por outros datasources)
- Refresh automático de token
