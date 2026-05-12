# Tasks: fcm-token-registration

## domain/

- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — `INotificationRepository.registerToken() → Future<Either<Failure, void>>` (sem params)

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar entrada `fcmToken('/api/v1/me/fcm-token')` (não pública)
- [x] `lib/src/infrastructure/clients/messaging/messaging_client.dart` — adicionar `String get platform` em `IMessagingClient` + impl em `MessagingClient`; `getToken()` catch-all swallow
- [x] `lib/src/infrastructure/clients/http/requests/fcm_token_request.dart` — `FcmTokenRequest(token, platform)` com `toJson`
- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — `IRemoteNotificationDataSource.registerToken()` (sem params) + `RemoteNotificationDataSource` que injeta `IHttpClient` + `IMessagingClient`; orquestra fetch token + platform + POST; token `null` → `Right(null)`

## data/

- [x] `lib/src/data/repositories/notification_repository.dart` — `NotificationRepository.registerToken()` (sem params), só forward + mapping de `FailureResponse → Failure`

## main/providers/

- [x] `lib/src/main/providers/data_sources.provider.dart` — provider `remoteNotificationDataSource` injetando `httpClient` + `messagingClient`
- [x] `lib/src/main/providers/repositories_provider.dart` — provider `notificationRepository`
- [x] `dart run build_runner build --delete-conflicting-outputs`

## presentation/

- [x] `lib/src/presentation/ui/splash/notifiers/splash_notifier.dart` — dependências apenas de domain (`INotificationRepository`, `IAuthenticationRepository`); no ramo `authenticated`, disparar `unawaited(_notificationRepository.registerToken())`; sem try-catch, sem logger, sem IMessagingClient

## test/

- [x] `test/mocks/mocks.dart` — `MockMessagingClient`, `MockNotificationRepository`, `MockRemoteNotificationDataSource`
- [x] `test/src/infrastructure/clients/http/requests/fcm_token_request_test.dart` — `toJson` cobre os dois campos
- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` (NOVO) — mock em `IHttpClient` + `IMessagingClient`: token null → no-op, token válido → POST com body certo, erro HTTP → `Left(FailureResponse)`
- [x] `test/src/data/repositories/notification_repository_test.dart` — mock em `IRemoteNotificationDataSource`, cobre mapping de cada `FailureResponse` para `Failure`
- [x] `test/src/presentation/providers/splash_notifier_test.dart` (novo) — 2 cenários: authenticated chama `registerToken()`, unauthenticated não chama

## Pré-condição (já satisfeita)

- `firebase_messaging ^16.2.1` já está no `pubspec.yaml`.
- `firebaseClient.initialize()` já roda em `main.dart`.
- `AuthenticationInterceptor` já injeta `Authorization: Bearer` em endpoints não-públicos.

## Verificação

- [x] `flutter analyze` — zero issues
- [x] `flutter test` — 513/513 verde
