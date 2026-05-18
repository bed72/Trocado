# Tasks: notification-lifecycle-via-repository

## infrastructure/

- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — adicionar `Stream<void> get onTokenRefreshed` na interface `IRemoteNotificationDataSource`; implementar com `_messagingClient.onTokenRefresh.map((_) {})` em `RemoteNotificationDataSource`

## domain/

- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — adicionar `Stream<void> get onTokenRefreshed`

## data/

- [x] `lib/src/data/repositories/notification_repository.dart` — implementar `Stream<void> get onTokenRefreshed => _dataSource.onTokenRefreshed;`

## main/providers/

- [x] `lib/src/main/providers/notification_lifecycle_provider.dart` — remover import de `clients_provider.dart`; remover `ref.watch(messagingClientProvider)`; trocar listener para `repository.onTokenRefreshed.listen(...)`
- [x] `dart run build_runner build --delete-conflicting-outputs` — regenerar `notification_lifecycle_provider.g.dart` (hash muda porque o corpo do `build()` muda)

## test/

- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` — novo `group('onTokenRefreshed')`: (a) cada emit em `messagingClient.onTokenRefresh` produz um void event no `dataSource.onTokenRefreshed`; (b) listener no `dataSource.onTokenRefreshed` propaga `hasListener == true` no controller upstream
- [x] `test/src/data/repositories/notification_repository_test.dart` — novo `group('onTokenRefreshed')`: cada emit do `dataSource.onTokenRefreshed` é repassado pelo `repository.onTokenRefreshed`
- [x] `test/src/main/providers/notification_lifecycle_provider_test.dart` — reescrever: trocar `MockMessagingClient` por `MockNotificationRepository` como fonte do stream; `StreamController<String>` → `StreamController<void>`; remover override de `messagingClientProvider`; manter os 5 cenários originais (materialização attached, single emit, multi emit, dispose cancela, slow não bloqueia)

## Pré-condições (já satisfeitas)

- `IMessagingClient.onTokenRefresh: Stream<String>` existe e é consumido pelo `RemoteNotificationDataSource`
- `IRemoteNotificationDataSource` já recebe `IMessagingClient` via construtor
- `INotificationRepository` já existe e é injetado via `notificationRepositoryProvider`
- `MockMessagingClient` e `MockNotificationRepository` existem em `test/mocks/mocks.dart`
- `MockRemoteNotificationDataSource` existe em `test/mocks/mocks.dart`
- `notification_lifecycle_provider_test.dart` já cobre os 5 cenários (a fonte do stream é o único delta)
- `notification_repository_test.dart` e `remote_notification_data_source_test.dart` existem com `group(...)` por método

## Verificação

- [x] `flutter analyze` — zero issues (4 warnings pré-existentes em `insights_carousel_loading_widget.dart`, nenhum da refatoração)
- [x] `flutter test` — 660 testes verdes (8 novos cobrindo stream delegation no datasource, repo e notifier)
- [x] `notification_lifecycle_provider.dart` não importa nada de `infrastructure/` nem `main/providers/clients_provider.dart`
- [x] `grep -rn "import.*messaging_client" lib/` retorna apenas `remote_notification_data_source.dart` (consumer real via DI) e `clients_provider.dart` (DI wiring) — `notification_lifecycle_provider.dart` saiu da lista
- [ ] Smoke: app boot autenticado → forçar rotação de token (apagar app data + reabrir) → backend recebe `POST /api/v1/me/fcm-token` com o novo token (mesmo comportamento de antes)
