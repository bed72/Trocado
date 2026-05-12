# Tasks: fcm-token-on-refresh

## infrastructure/

- [x] `lib/src/infrastructure/clients/messaging/messaging_client.dart` — adicionar `Stream<String> get onTokenRefresh` à `IMessagingClient` (interface) e implementação que retorna `FirebaseMessaging.instance.onTokenRefresh` direto

## main/providers/

- [x] `lib/src/main/providers/notification_lifecycle_provider.dart` (NOVO) — classe `NotificationLifecycle extends _$NotificationLifecycle` com `@Riverpod(keepAlive: true)`, `build()` retorna `void`, `ref.watch(messagingClientProvider)` + `ref.watch(notificationRepositoryProvider)`, `messaging.onTokenRefresh.listen((_) => unawaited(repository.registerToken()))`, `ref.onDispose(subscription.cancel)`
- [x] `dart run build_runner build --delete-conflicting-outputs`

## main entry

- [x] `lib/main.dart` — adicionar `container.read(notificationLifecycleProvider)` após `await container.read(appCheckClientProvider).activate()` e antes de `runApp(...)`; importar o provider

## test/

- [x] `test/src/main/providers/notification_lifecycle_provider_test.dart` (NOVO) — usar `StreamController<String>.broadcast()`, mockar `onTokenRefresh` retornando `controller.stream`; cobrir os 5 cenários da spec: provider materializa e listener attached; dispose cancela; single emit → 1 call; múltiplos emits → N calls; slow `registerToken` não bloqueia próximo emit
- [x] Verificar que `MockMessagingClient` em `test/mocks/mocks.dart` ainda cobre o novo getter via `Mock` (mocktail auto-stubs sem when, mas precisamos do when explícito pra retornar o stream)

## Pré-condições (já satisfeitas)

- `IMessagingClient` existe com `platform` e `getToken()` (Spec 1)
- `INotificationRepository.registerToken()` existe (Spec 1)
- `messagingClientProvider` e `notificationRepositoryProvider` existem
- `MockMessagingClient` e `MockNotificationRepository` existem em `test/mocks/mocks.dart`
- Backend confirmou contrato idempotente do `POST /api/v1/me/fcm-token`

## Verificação

- [x] `flutter analyze` — zero issues
- [x] `flutter test` — verde
- [x] Sem alteração em testes existentes da Splash, SignIn, SignUp
