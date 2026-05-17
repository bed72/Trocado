# Design: fcm-token-on-logout

## Contrato da API

**Endpoint:** `DELETE /api/v1/me/fcm-token`

**Auth:** `Authorization: Bearer <access>` (injetado por `AuthenticationInterceptor`).

**Request body:**
```json
{ "token": "fGc8z9k2QlS-eY4...abc123" }
```

**Response 204:** sem body. Sempre — incluindo casos de token desconhecido, já revogado, ou pertencente a outro user.

**Response 4xx/5xx (erro de rede ou backend caído):**
```json
{ "errors": [{ "field": "...", "message": "...", "code": "..." }] }
```

Em condições normais backend não retorna 4xx aqui — comportamento idempotente garante 204. 4xx/5xx só aparece em falhas reais de transporte.

---

## Fluxo de responsabilidades

```
LogoutNotifier (ou onde quer que rode logout, presentation)
    → IAuthenticationRepository.logout()

AuthenticationRepository.logout()
    → unawaited(notificationRepository.revokeToken())   // NOVO — fire-and-forget
    → tokens = tokenDataSource.get()
    → if refresh == null: clear + Right(null)
    → authenticationDataSource.logout(refresh)
    → tokenDataSource.clear()
    → Right(null)

NotificationRepository.revokeToken()
    → dataSource.revokeToken()
    → data.either((f) => f.toFailure(), (_) {})
    → Either<Failure, void>

RemoteNotificationDataSource.revokeToken()
    → messagingClient.getToken() → String?
    → if null: Right(null) (no-op)
    → IHttpClient.delete(Requests(EndpointKey.fcmToken.path,
                                  body: FcmTokenDeleteRequest(token).toJson()))
    → response.either(FailureResponse.fromJson, (_) {})
    → Either<FailureResponse, void>
```

A revogação roda em paralelo ao resto do `logout()`. O `Either` retornado é ignorado (notifier de logout só consome o retorno do `AuthenticationRepository.logout()`, que é independente).

---

## FcmTokenDeleteRequest (infrastructure)

`lib/src/infrastructure/clients/http/requests/fcm_token_delete_request.dart`:

```dart
final class FcmTokenDeleteRequest {
  final String token;

  const FcmTokenDeleteRequest({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}
```

---

## INotificationRepository (domain) — extensão

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';

abstract interface class INotificationRepository {
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> revokeToken();
}
```

Sem params — orquestração de "qual token" fica em infrastructure (DataSource).

---

## IRemoteNotificationDataSource + impl (infrastructure) — extensão

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart`:

```dart
abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> revokeToken();
}

final class RemoteNotificationDataSource implements IRemoteNotificationDataSource {
  // ... existing fields + constructor unchanged ...

  @override
  Future<Either<FailureResponse, void>> revokeToken() async {
    final token = await _messagingClient.getToken();
    if (token == null) return const Right(null);

    final response = await _httpClient.delete(
      parameter: Requests(
        EndpointKey.fcmToken.path,
        body: FcmTokenDeleteRequest(token: token).toJson(),
      ),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
```

- Mesmo padrão de `registerToken()` da Spec 1 — buscar token, no-op se null, postar.
- `EndpointKey.fcmToken.path` já existe (mesmo path usado pelo POST).

---

## NotificationRepository (data) — extensão

`lib/src/data/repositories/notification_repository.dart`:

```dart
@override
Future<Either<Failure, void>> revokeToken() async {
  final data = await _dataSource.revokeToken();
  return data.either((failure) => failure.toFailure(), (_) {});
}
```

Pipeline puro — mapeia `FailureResponse → Failure`. Mesma forma de `registerToken()`.

---

## AuthenticationRepository (data) — extensão

`lib/src/data/repositories/authentication_repository.dart`:

```dart
import 'dart:async';

// ... existing imports ...
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

final class AuthenticationRepository implements IAuthenticationRepository {
  final ILocalTokenDataSource _tokenDataSource;
  final INotificationRepository _notificationRepository;        // NOVO
  final IRemoteAuthenticationDataSource _authenticationDataSource;

  AuthenticationRepository({
    required ILocalTokenDataSource tokenDataSource,
    required INotificationRepository notificationRepository,    // NOVO
    required IRemoteAuthenticationDataSource authenticationDataSource,
  }) : _tokenDataSource = tokenDataSource,
       _notificationRepository = notificationRepository,        // NOVO
       _authenticationDataSource = authenticationDataSource;

  @override
  Future<Either<Failure, void>> logout() async {
    unawaited(_notificationRepository.revokeToken());           // NOVO

    final tokens = await _tokenDataSource.get();

    if (tokens.refresh == null) {
      await _tokenDataSource.clear();
      return const Right(null);
    }

    final data = await _authenticationDataSource.logout(
      refresh: tokens.refresh!,
    );

    if (data.isLeft) return Left(data.left.toFailure());

    await _tokenDataSource.clear();
    return const Right(null);
  }

  // ... outros métodos inalterados ...
}
```

Pontos importantes:
- `unawaited(...)` é a **primeira** linha do `logout()`. Garante Bearer válido quando o DELETE sair.
- Roda mesmo no branch "refresh == null" — não custa nada e cobre o cenário "session local corrompida, mas token FCM ainda registrado".
- Falha do `revokeToken()` é descartada — `logout()` continua e retorna conforme o fluxo de `signOut` server-side.

---

## Provider wiring (main)

`lib/src/main/providers/repositories_provider.dart`:

```dart
@Riverpod()
IAuthenticationRepository authenticationRepository(Ref ref) =>
    AuthenticationRepository(
      tokenDataSource: ref.watch(localTokenDataSourceProvider),
      notificationRepository: ref.watch(notificationRepositoryProvider),    // NOVO
      authenticationDataSource: ref.watch(remoteAuthenticationDataSourceProvider),
    );
```

Build runner regenera o `.g.dart` do provider.

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `fcm_token_delete_request_test.dart` (NOVO) | — | `toJson` retorna `{'token': 'abc'}` |
| `remote_notification_data_source_test.dart` (ESTENDER) | `IHttpClient`, `IMessagingClient` | • token válido → DELETE com body `{token}` no path certo<br>• token null → no-op, `Right(null)`, sem HTTP<br>• erro HTTP → `Left(FailureResponse)` |
| `notification_repository_test.dart` (ESTENDER) | `IRemoteNotificationDataSource` | • datasource `Right(null)` → repo `Right(null)`<br>• cada `FailureResponse.code` → `Failure` correspondente (network/server/notFound/validation) |
| `authentication_repository_test.dart` (ESTENDER) | adicionar `INotificationRepository` no setup | • logout success → `revokeToken()` chamado uma vez<br>• logout com refresh null → `revokeToken()` ainda chamado uma vez<br>• logout com signOut error → `revokeToken()` ainda chamado uma vez<br>• `revokeToken()` lento não bloqueia retorno do logout |

Sem teste explícito de `MessagingClient` (mesma justificativa da Spec 1).

---

## Mapping HTTP → Failure

Reusa `FailureResponseExtension.toFailure()` existente. Em condições reais o backend não retorna 4xx — qualquer Left vem de erro de rede. Mapeamento típico:

| `FailureItemResponse.code` | Failure |
|---|---|
| `network_error` / `connection_error` / `timeout` | `NetworkFailure` |
| `server_error` | `ServerFailure` |
| outros | `ValidationFailure(message)` |

Como `revokeToken()` é fire-and-forget no logout, qualquer falha é silenciosa pro usuário. `talker_dio_logger` cobre nos logs.

---

## Ordem no logout — por que primeira linha

```dart
unawaited(_notificationRepository.revokeToken());  // (1) DELETE FCM
final tokens = await _tokenDataSource.get();        // (2)
// ...
final data = await _authenticationDataSource.logout(refresh);  // (3) signOut server
```

`unawaited` em (1) significa que o DELETE é "scheduled" mas não awaited. Dio enfileira a request. Em paralelo, (2) e (3) rodam.

Sequência de network:
- Microtask A: dispara DELETE — interceptor injeta `Authorization: Bearer <access>` (ainda válido).
- Microtask B: signOut HTTP — interceptor injeta o mesmo Bearer.
- Ambos chegam no backend; ordem de chegada é não-determinística mas backend trata cada um independente.
- Após (3) completar, `tokenDataSource.clear()` apaga o local. DELETE pode ainda estar in-flight; já tinha sido emitido com Bearer válido, então segue.

Se invertêssemos a ordem (revogar **depois** do signOut), o Bearer já estaria invalidado pelo backend e o DELETE bateria com 401. Backend ainda responderia 204 (idempotente), mas é caminho ruidoso. Por isso revoga primeiro.

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Plug no `AuthenticationRepository.logout()` | Plug no LogoutNotifier (presentation) | Mantém presentation transparente; "logout = limpar tudo" coeso; reaproveita em qualquer caller que chame `logout()` |
| `revokeToken()` sem params | `revokeToken(token)` | Mantém simetria com `registerToken()`; cliente não precisa importar `IMessagingClient` |
| `FcmTokenDeleteRequest` separado | Reusar `FcmTokenRequest` ignorando platform | Backend ignora extras, mas DTO próprio mantém serialização precisa e evita "campos opcionais" no request |
| `unawaited(...)` em vez de `await` | `await _notificationRepository.revokeToken()` | DELETE adiciona round-trip; falha não é crítica (backend tem 90d cleanup) |
| Primeira linha do `logout()` | Última linha (depois de `signOut` server) | Bearer ainda válido na primeira posição; depois do signOut viraria 401 ruidoso |
| Revoga mesmo se `refresh == null` | Skip se local corrompido | Token FCM pode estar registrado server-side mesmo com session local corrompida; revoga assim mesmo |
| Sem teste de `MessagingClient.getToken()` | Teste do wrapper | Wrapper trivial (Spec 1 já estabeleceu) |
