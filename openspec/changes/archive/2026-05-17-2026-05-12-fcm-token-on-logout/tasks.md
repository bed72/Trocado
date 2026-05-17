# Tasks: fcm-token-on-logout

## domain/

- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — adicionar `Future<Either<Failure, void>> revokeToken();` (sem params)

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/requests/fcm_token_delete_request.dart` (NOVO) — `FcmTokenDeleteRequest({required String token})` com `toJson() => {'token': token}`
- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — adicionar `revokeToken()` à `IRemoteNotificationDataSource` (interface) e impl: pega token via `_messagingClient.getToken()`, se null → `Right(null)`, senão `_httpClient.delete(Requests(EndpointKey.fcmToken.path, body: FcmTokenDeleteRequest(token: token).toJson()))`, `response.either(FailureResponse.fromJson, (_) {})`

## data/

- [x] `lib/src/data/repositories/notification_repository.dart` — adicionar `revokeToken()` que faz forward para datasource + mapping `FailureResponse → Failure` (mesmo padrão de `registerToken`)
- [x] `lib/src/data/repositories/authentication_repository.dart` — adicionar `import 'dart:async';`, importar `INotificationRepository`, novo campo `late final INotificationRepository _notificationRepository`, parâmetro `notificationRepository` no construtor, e como **primeira linha** do `logout()` chamar `unawaited(_notificationRepository.revokeToken())`

## main/providers/

- [x] `lib/src/main/providers/repositories_provider.dart` — `authenticationRepository` provider passa `notificationRepository: ref.watch(notificationRepositoryProvider)` ao construtor
- [x] `dart run build_runner build --delete-conflicting-outputs`

## test/

- [x] `test/src/infrastructure/clients/http/requests/fcm_token_delete_request_test.dart` (NOVO) — `toJson` retorna `{'token': 'abc'}` apenas, sem outras chaves
- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` (ESTENDER) — group `revokeToken`: token válido → DELETE com path + body certos; token null → sem HTTP, `Right(null)`; erro HTTP → `Left(FailureResponse)`
- [x] `test/src/data/repositories/notification_repository_test.dart` (ESTENDER) — group `revokeToken`: mapping de cada `FailureResponse.code` (network/server/notFound/validation/desconhecido) + propagação de `Right(null)`
- [x] `test/src/data/repositories/authentication_repository_test.dart` (ESTENDER) — adicionar `MockNotificationRepository` no setup, passar ao construtor; novo group `revokeToken on logout`: success → `revokeToken` 1x; refresh null → `revokeToken` 1x; signOut error → `revokeToken` 1x; slow `revokeToken` não bloqueia retorno

## Pré-condições (já satisfeitas)

- `IHttpClient.delete({required Requests parameter})` existe e passa `parameter.body` como `data` pro Dio (verificado)
- `EndpointKey.fcmToken('/api/v1/me/fcm-token')` existe (Spec 1)
- `IMessagingClient.getToken()` existe (Spec 1)
- `INotificationRepository`, `NotificationRepository`, `RemoteNotificationDataSource` existem (Spec 1)
- `MockNotificationRepository`, `MockMessagingClient`, `MockHttpClient` existem em `test/mocks/mocks.dart` (Spec 1)
- Backend confirmou DELETE idempotente `204` (curl ground truth, 2026-05-12)

## Verificação

- [x] `flutter analyze` — zero issues
- [x] `flutter test` — verde
- [x] Sem alteração em testes existentes de Splash, SignIn, SignUp, notification_lifecycle
- [x] Provider wiring funciona (smoke: `flutter run` arranca sem erro de injeção)
