# Design: fcm-token-registration

## Contrato da API

**Endpoint:** `POST /api/v1/me/fcm-token`

**Auth:** `Authorization: Bearer <access>` (já injetado por `AuthenticationInterceptor`).

**Request body:**
```json
{ "token": "fGc8z9k2QlS-eY4...abc123", "platform": "android" }
```

**Response 204:** sem body.

**Response 4xx/5xx (`FailureResponse` padrão):**
```json
{
  "errors": [
    { "field": "token", "message": "Invalid FCM token.", "code": "invalid" }
  ]
}
```

---

## Fluxo de responsabilidades

```
SplashNotifier (authenticated branch)
    → unawaited(notificationRepository.registerToken())

NotificationRepository.registerToken()
    → dataSource.registerToken()
    → data.either((f) => f.toFailure(), (_) {})
    → Either<Failure, void>

RemoteNotificationDataSource.registerToken()
    → messagingClient.getToken()           → String?
    → if null: Right(null) (no-op)
    → messagingClient.platform             → "android" | "ios"
    → IHttpClient.post(Requests(EndpointKey.fcmToken.path,
                                body: FcmTokenRequest(token, platform).toJson()))
    → response.either(FailureResponse.fromJson, (_) {})
    → Either<FailureResponse, void>

IMessagingClient.getToken()
    try FirebaseMessaging.instance.getToken()
    catch _: return null  (swallow-all)
```

A Splash dispara via `unawaited(...)` — não bloqueia navegação. O fluxo inteiro não lança exceptions porque:
- `MessagingClient.getToken()` engole tudo e retorna `null`
- `IHttpClient` já encapsula erros do Dio em `Either<Map, Map>`

Não há `try-catch` na presentation, repository nem datasource. Regra "único try-catch no Client" preservada.

---

## EndpointKey

Adicionar entrada em `lib/src/infrastructure/clients/http/endpoint_key.dart`:

```dart
fcmToken('/api/v1/me/fcm-token'),
```

**Não** entra em `_publicEndpoints` — endpoint protegido, precisa do `Authorization: Bearer` do interceptor.

---

## IMessagingClient — extensão (swallow-all)

`lib/src/infrastructure/clients/messaging/messaging_client.dart`:

```dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class IMessagingClient {
  String get platform;
  Future<String?> getToken();
}

final class MessagingClient implements IMessagingClient {
  @override
  String get platform => Platform.isAndroid ? 'android' : 'ios';

  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
```

- `platform` é getter sync — `dart:io` `Platform.isAndroid` é avaliado por chamada.
- `getToken()` é catch-all: qualquer `FirebaseException`, `MissingPluginException`, `StateError` etc. vira `null`. O cliente é a fronteira — quem chama nunca precisa de `try-catch`.

---

## FcmTokenRequest (infrastructure)

`lib/src/infrastructure/clients/http/requests/fcm_token_request.dart`:

```dart
final class FcmTokenRequest {
  final String token;
  final String platform;

  const FcmTokenRequest({required this.token, required this.platform});

  Map<String, dynamic> toJson() => {'token': token, 'platform': platform};
}
```

---

## IRemoteNotificationDataSource + impl (infrastructure)

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — interface e implementação no mesmo arquivo:

```dart
import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/fcm_token_request.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';
import 'package:trocado/src/infrastructure/clients/messaging/messaging_client.dart';

abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> registerToken();
}

final class RemoteNotificationDataSource
    implements IRemoteNotificationDataSource {
  final IHttpClient _client;
  final IMessagingClient _messagingClient;

  RemoteNotificationDataSource({
    required IHttpClient client,
    required IMessagingClient messagingClient,
  }) : _client = client,
       _messagingClient = messagingClient;

  @override
  Future<Either<FailureResponse, void>> registerToken() async {
    final token = await _messagingClient.getToken();
    if (token == null) return const Right(null);

    final response = await _client.post(
      parameter: Requests(
        EndpointKey.fcmToken.path,
        body: FcmTokenRequest(
          token: token,
          platform: _messagingClient.platform,
        ).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
```

- **DataSource é onde a orquestração vive.** Pega o token via `IMessagingClient`, monta o `FcmTokenRequest`, faz o POST. É o ponto de encontro entre o "data source externo" do Firebase e o data source HTTP.
- **Token `null` → `Right(null)`**: não é falha, é "nada pra registrar agora". Próximo gatilho (próximo app start, `onTokenRefresh` em specs futuras) cobre.

---

## INotificationRepository (domain)

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

abstract interface class INotificationRepository {
  Future<Either<Failure, void>> registerToken();
}
```

Sem params — a orquestração de "qual token, qual plataforma" é detalhe de infraestrutura, não de domínio. Nome é deliberadamente broad — specs futuras vão adicionar `list`, `delete`, `markAsRead` etc.

---

## NotificationRepository (data)

`lib/src/data/repositories/notification_repository.dart`:

```dart
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_notification_data_source.dart';

final class NotificationRepository implements INotificationRepository {
  final IRemoteNotificationDataSource _dataSource;

  NotificationRepository({required IRemoteNotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, void>> registerToken() async {
    final data = await _dataSource.registerToken();

    return data.either((failure) => failure.toFailure(), (_) {});
  }
}
```

Pipeline puro — só mapeia `FailureResponse → Failure` via `FailureResponseExtension.toFailure()`. Não importa `IMessagingClient`.

---

## Providers (main)

`lib/src/main/providers/data_sources.provider.dart` — adicionar:

```dart
@Riverpod()
IRemoteNotificationDataSource remoteNotificationDataSource(Ref ref) =>
    RemoteNotificationDataSource(
      client: ref.watch(httpClientProvider),
      messagingClient: ref.watch(messagingClientProvider),
    );
```

`lib/src/main/providers/repositories_provider.dart` — adicionar:

```dart
@Riverpod()
INotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository(
      dataSource: ref.watch(remoteNotificationDataSourceProvider),
    );
```

`messagingClientProvider` já existe em `clients_provider.dart` e fica como está.

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## SplashNotifier (presentation)

`lib/src/presentation/ui/splash/notifiers/splash_notifier.dart`:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/splash/notifiers/splash_state.dart';

import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'splash_notifier.g.dart';

@riverpod
final class SplashNotifier extends _$SplashNotifier {
  late INotificationRepository _notificationRepository;
  late IAuthenticationRepository _authenticationRepository;

  @override
  Future<SplashStatus> build() async {
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _authenticationRepository = ref.watch(authenticationRepositoryProvider);

    return await _checkSession();
  }

  Future<SplashStatus> _checkSession() async {
    final data = await _authenticationRepository.checkSession();

    return data.fold((_) => .unauthenticated, (_) {
      unawaited(_notificationRepository.registerToken());
      return .authenticated;
    });
  }
}
```

Pontos importantes:
- **Só importa de `domain/`.** Sem `IMessagingClient`, sem `ILoggerClient`, sem `try-catch`. Respeita `presentation → domain` da arquitetura.
- `unawaited(...)` antes do `return .authenticated` — registro roda em paralelo à navegação.
- O `Either` retornado é descartado intencionalmente. Não há feedback ao usuário (transparente), e o `IMessagingClient` swallow-all + `IHttpClient` Either já garantem que nenhuma exception vaza pro zone handler.
- Campos `late` (não `late final`) — Riverpod re-executa `build()` na mesma instância.

---

## Mapping HTTP → Failure

Reusa `FailureResponseExtension.toFailure()` existente. Códigos esperados:

| `FailureItemResponse.code` | Failure |
|---|---|
| `network_error` | `NetworkFailure` |
| `server_error` | `ServerFailure` |
| `not_found` | `NotFoundFailure` |
| outros | `ValidationFailure(message)` |

Como a Splash descarta o `Either`, qualquer falha é silenciosa pro usuário. O `talker_dio_logger` (já em uso via Dio) registra os erros HTTP nos logs de desenvolvimento.

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `fcm_token_request_test.dart` | — | `toJson` mapeia `token` + `platform` |
| `remote_notification_data_source_test.dart` (NOVO) | `IHttpClient`, `IMessagingClient` | • token `null` → `Right(null)`, sem POST<br>• token válido → POST com body correto<br>• erro HTTP → `Left(FailureResponse)` |
| `notification_repository_test.dart` | `IRemoteNotificationDataSource` | mapping de cada `FailureResponse` para `Failure` e propagação de Right |
| `splash_notifier_test.dart` (novo) | `IAuthenticationRepository`, `INotificationRepository` | • `authenticated` → chama `registerToken()`<br>• `unauthenticated` → não chama `registerToken()` |

Sem teste explícito de `MessagingClient` — `getToken()` é wrapper trivial sobre o SDK do Firebase; cobertura efetiva via teste do datasource.
Sem teste de Response (204 sem body — não existe response object).

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| DataSource orquestra fetch+POST | Repository orquestra | DataSource já é o local onde clientes externos se encontram; coloca toda a coordenação de infraestrutura num ponto só, mantém repository mínimo |
| Notifier não importa `IMessagingClient` nem `ILoggerClient` | Notifier orquestra com loggers explícitos | regra `presentation → domain` da arquitetura é dura; tudo que é infra fica abaixo da fronteira |
| `MessagingClient.getToken()` catch-all | rethrow seletivo de `FirebaseException` | regra "único try-catch no Client" — cliente é a fronteira, retornar `null` cobre todos os caminhos sem propagar exceptions |
| Token `null` → `Right(null)` no DataSource | `Left(SomeFailure)` | `null` é estado esperado (iOS sem APNs ainda); registrar como falha geraria ruído sem ação |
| Sem logging explícito | `ILoggerClient.warning` em falhas | `talker_dio_logger` (já configurado no Dio) cobre erros HTTP; falhas silenciosas no FCM client são esperadas |
| `Either<Failure, void>` | `Either<Failure, Unit>` | consistência com `logout`/`requestPasswordReset` no codebase |
| Sem retry/backoff | retry exponencial | gatilho repetido (próximo app start, `onTokenRefresh` em specs futuras) já é o retry natural |
| Splash dispara, mas não é dona | mover lógica pra `App.initState` ou serviço de bootstrap | Splash já tem o sinal de auth e é provider Riverpod testável |
