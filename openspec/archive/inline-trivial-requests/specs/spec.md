# Spec: inline-trivial-requests

## Context

O projeto possui 6 classes `Request` em `lib/src/infrastructure/clients/http/requests/`. O datasource `RemoteAuthenticationDataSource` já usa duas convenções inconsistentes:

- `logout`, `verifyToken`, `refreshToken` — body inline como `{'key': value}` literal
- `signIn`, `signUp`, `passwordReset`, `passwordResetConfirm` — classes `Request` dedicadas com `toJson()`

Dentre as classes dedicadas, duas são triviais (≤ 2 campos) e apresentam ~8 linhas de código para gerar um `Map` de 1–2 chaves — mesmo volume e padrão dos bodies já inlinados em `logout`/`verifyToken`/`refreshToken`.

Esta spec elimina essa inconsistência removendo `SignInRequest` (2 campos) e `PasswordResetRequest` (1 campo). Requests com ≥ 3 campos permanecem como classes dedicadas — a type-safety do construtor nomeado paga o próprio peso quando há mais campos.

## Scope

**Dentro do escopo:**
- Remoção de `SignInRequest` e `PasswordResetRequest`.
- Ajuste de `RemoteAuthenticationDataSource` para construir os bodies inline.
- Ajuste de testes que possam referenciar essas classes.

**Fora do escopo:**
- Qualquer alteração em `SignUpRequest`, `PasswordResetConfirmRequest`, `BudgetRequest`, `ExpenseRequest` (todos ≥ 3 campos).
- Alteração da interface `IRemoteAuthenticationDataSource` — continua recebendo tipos primitivos de domínio (`String email`, `String password`).
- Alteração nas responses ou nos repositórios.

---

## Requirements

### Requirement: Threshold trivial

The system SHALL adotar o threshold: uma classe `Request` é **trivial** se possui ≤ 2 campos. Classes triviais SHALL ser inlinadas na implementação concreta do datasource; classes com ≥ 3 campos SHALL permanecer como arquivo dedicado.

#### Scenario: Requests remanescentes
Given a refatoração concluída
When `ls lib/src/infrastructure/clients/http/requests/` é executado
Then existem 4 arquivos: `sign_up_request.dart`, `password_reset_confirm_request.dart`, `budget_request.dart`, `expense_request.dart`

---

### Requirement: Remoção de `SignInRequest`

The system SHALL delete o arquivo `lib/src/infrastructure/clients/http/requests/sign_in_request.dart`.

The system SHALL update `RemoteAuthenticationDataSource.signIn` para construir o body inline:

```dart
@override
Future<Either<FailureResponse, SignInResponse>> signIn({
  required String email,
  required String password,
}) async {
  final response = await _client.post(
    parameter: Requests(
      EndpointKey.signIn.path,
      body: {'email': email, 'password': password},
    ),
  );

  return response.either(FailureResponse.fromJson, SignInResponse.fromJson);
}
```

The system SHALL remove o `import 'package:trocado/src/infrastructure/clients/http/requests/sign_in_request.dart';` de `remote_authentication_data_source.dart`.

The system SHALL keep a interface `IRemoteAuthenticationDataSource.signIn` idêntica — continua recebendo `String email` e `String password`.

#### Scenario: Nenhuma referência remanescente
Given a refatoração concluída
When `grep -rn "SignInRequest" lib/ test/` é executado
Then zero resultados

#### Scenario: Contrato da interface preservado
Given `interface_authentication_repository.dart` e `IRemoteAuthenticationDataSource`
When inspecionados
Then nenhuma assinatura de método muda

---

### Requirement: Remoção de `PasswordResetRequest`

The system SHALL delete o arquivo `lib/src/infrastructure/clients/http/requests/password_reset_request.dart`.

The system SHALL update `RemoteAuthenticationDataSource.requestPasswordReset` para construir o body inline:

```dart
@override
Future<Either<FailureResponse, PasswordResetResponse>> requestPasswordReset({
  required String email,
}) async {
  final response = await _client.post(
    parameter: Requests(
      EndpointKey.passwordResetRequest.path,
      body: {'email': email},
    ),
  );

  return response.either(
    FailureResponse.fromJson,
    PasswordResetResponse.fromJson,
  );
}
```

The system SHALL remove o `import 'package:trocado/src/infrastructure/clients/http/requests/password_reset_request.dart';` de `remote_authentication_data_source.dart`.

#### Scenario: Nenhuma referência remanescente
Given a refatoração concluída
When `grep -rn "PasswordResetRequest" lib/ test/` é executado
Then zero resultados (exceto `PasswordResetConfirmRequest`, que permanece)

---

### Requirement: Requests não-triviais preservados

The system SHALL NOT modify:
- `lib/src/infrastructure/clients/http/requests/sign_up_request.dart`
- `lib/src/infrastructure/clients/http/requests/password_reset_confirm_request.dart`
- `lib/src/infrastructure/clients/http/requests/budget_request.dart`
- `lib/src/infrastructure/clients/http/requests/expense_request.dart`

The system SHALL NOT modify os métodos `signUp`, `confirmPasswordReset` (no `RemoteAuthenticationDataSource`) e os métodos de `RemoteBudgetDataSource`/`RemoteExpenseDataSource` que consomem essas classes.

#### Scenario: Diff mínimo
Given a refatoração concluída
When `git diff --stat lib/src/infrastructure/clients/http/requests/` é inspecionado
Then apenas os dois arquivos triviais aparecem como removidos; nenhum outro é modificado

---

### Requirement: Testes atualizados

The system SHALL remove qualquer referência a `SignInRequest` ou `PasswordResetRequest` em `test/`.

The system SHALL keep os testes de `AuthenticationRepository` (`test/src/data/repositories/authentication_repository_test.dart`) passando — o mock de `IHttpClient` captura o body final (já independente da existência da classe `Request`).

#### Scenario: Suite passa
Given a refatoração concluída
When `flutter test` é executado
Then zero falhas e zero erros de compilação

#### Scenario: Assertions sobre body continuam válidas
Given testes que verificam o body enviado ao `IHttpClient` para `signIn` e `requestPasswordReset`
When inspecionados
Then as assertions comparam o `Map<String, dynamic>` esperado diretamente (sem depender das classes removidas)

---

## Files

### Delete

- `lib/src/infrastructure/clients/http/requests/sign_in_request.dart`
- `lib/src/infrastructure/clients/http/requests/password_reset_request.dart`

### Modify

| Arquivo | Mudança |
|---|---|
| `lib/src/infrastructure/datasources/remote/remote_authentication_data_source.dart` | Inline de bodies em `signIn` e `requestPasswordReset`; remover 2 imports |
| `test/src/data/repositories/authentication_repository_test.dart` | Remover referência às classes se existir; comparar body como `Map` |

### Unchanged

- `interface_authentication_repository.dart` (domain) — contratos inalterados
- `sign_up_request.dart`, `password_reset_confirm_request.dart`, `budget_request.dart`, `expense_request.dart`
- Todos os Notifiers, screens e validators

---

## Out of scope

- Inlining de requests ≥ 3 campos.
- Padronização de todos os requests restantes (manter a regra de threshold).
- Mudança na interface do datasource ou do repositório.
- Migração para `freezed` ou outros geradores de código para os requests remanescentes.
