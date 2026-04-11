# Design: sign-in-datasource

## Contrato da API

**Endpoint:** `POST /auth/token/`

**Request body:**
```json
{ "email": "jane@trocado.app", "password": "password123" }
```

**Response 200:**
```json
{ "access": "eyJhbGci...", "refresh": "eyJhbGci..." }
```

**Response 400/401:**
```json
{
  "errors": [
    { "field": "non_field_errors", "message": "No active account found with the given credentials.", "code": "no_active_account" }
  ]
}
```

---

## Fluxo de responsabilidades

```
IHttpClient.post('/auth/token/', body: signInRequest.toJson())
    → Either<Map, Map>

RemoteAuthenticationDataSource
    → either.either(FailureResponse.fromJson, SignInResponse.fromJson)
    → Either<FailureResponse, SignInResponse>

AuthenticationRepository
    → either.either(_toFailure, (r) => r.toModel())
    → Either<Failure, AuthenticationModel>
```

---

## Regra de dependência

```
domain/   ← conhece: nada externo
data/     ← conhece: domain/ + interface IRemoteAuthenticationDataSource
infra/    ← conhece: suas próprias interfaces + IHttpClient
```

---

## AuthenticationModel (domain)

```dart
final class AuthenticationModel extends Equatable {
  final String access;
  final String refresh;

  const AuthenticationModel({required this.access, required this.refresh});

  @override
  List<Object?> get props => [access, refresh];

  AuthenticationModel copyWith({String? access, String? refresh}) =>
      AuthenticationModel(
        access: access ?? this.access,
        refresh: refresh ?? this.refresh,
      );
}
```

---

## SignInRequest (infrastructure)

```dart
final class SignInRequest {
  final String email;
  final String password;

  const SignInRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
```

---

## SignInResponse (infrastructure)

```dart
final class SignInResponse {
  final String access;
  final String refresh;

  const SignInResponse({required this.access, required this.refresh});

  factory SignInResponse.fromJson(Map<String, dynamic> json) =>
      SignInResponse(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
      );

  AuthenticationModel toModel() =>
      AuthenticationModel(access: access, refresh: refresh);
}
```

---

## IRemoteAuthenticationDataSource + RemoteAuthenticationDataSource (infrastructure)

```dart
abstract interface class IRemoteAuthenticationDataSource {
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required SignInRequest request,
  });
}

final class RemoteAuthenticationDataSource implements IRemoteAuthenticationDataSource {
  final IHttpClient _client;

  RemoteAuthenticationDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required SignInRequest parameter,
  }) async {
    final response = await _client.post(
      parameter: Requests(Endpoints.signIn.path, body: parameter.toJson()),
    );
    return response.either(FailureResponse.fromJson, SignInResponse.fromJson);
  }
}
```

---

## AuthenticationRepository (data)

```dart
final class AuthenticationRepository implements IAuthenticationRepository {
  final IRemoteAuthenticationDataSource _dataSource;

  AuthenticationRepository({required IRemoteAuthenticationDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, AuthenticationModel>> signIn({
    required String email,
    required String password,
  }) async {
    final Either<FailureResponse, SignInResponse> either = await _dataSource.signIn(
      request: SignInRequest(email: email, password: password),
    );
    return either.either(_toFailure, (r) => r.toModel());
  }

  Failure _toFailure(FailureResponse response) {
    final FailureItemResponse item = response.errors.first;
    return switch (item.code) {
      'network_error'    => const NetworkFailure(),
      'no_active_account' => ValidationFailure(item.message),
      _                  => ValidationFailure(item.message),
    };
  }
}
```

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `sign_in_response_test.dart` | — | `fromJson` e `toModel()` |
| `authentication_repository_test.dart` | `IHttpClient` | repo + datasource juntos |

Não há testes de datasource separados.

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| `toModel()` em `SignInResponse` | mapper separado | response simples, sem conversão de tipos |
| `_toFailure` no repositório | mapeamento no datasource | repositório é quem conhece o domínio |
| Sem try-catch no repositório | try-catch por camada | único try-catch fica no `DioHttpClient` |
