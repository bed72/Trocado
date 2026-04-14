# Design: forgot-password-request

## Contrato da API

**Endpoint:** `POST /api/v1/auth/password/request`
(`EndpointKey.passwordResetRequest` — já existe no enum)

**Request body:**
```json
{ "email": "jane@trocado.app" }
```

**Response 200:**
```json
{ "detail": "If this email is registered, a reset link has been sent." }
```

**Response 4xx:**
```json
{
  "errors": [
    { "field": "string", "message": "string", "code": "string" }
  ]
}
```

---

## Fluxo de responsabilidades

```
IHttpClient.post('/api/v1/auth/password/request', body: PasswordResetRequest.toJson())
    → Either<Map, Map>

RemoteAuthenticationDataSource.requestPasswordReset
    → response.either(FailureResponse.fromJson, PasswordResetResponse.fromJson)
    → Either<FailureResponse, PasswordResetResponse>

AuthenticationRepository.requestPasswordReset
    → data.either((failure) => failure.toFailure(), (_) {})
    → Either<Failure, void>

ForgotPasswordNotifier.dispatch(SubmitPressed)
    → valida com ForgotPasswordFormValidator
    → chama repository.requestPasswordReset
    → status.success → toast 'Verifique seu email'
    → status.failure → toast 'Opps' + failure.message
```

---

## Regra de dependência

```
core/         ← todos (Either)
domain/       ← data/, presentation/
infrastructure/ ← apenas core/
data/         ← domain/ + infrastructure/
presentation/ ← domain/ + core/
main/         → tudo
```

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| `Either<Failure, void>` no repositório | `Either<Failure, String>` (detail) | `detail` não é usado pela UI; void evita model/extension desnecessários |
| Sem `PasswordResetModel` | criar model com `detail` | não há dado de domínio relevante a retornar |
| Sem extension | `PasswordResetResponseExtension.toModel()` | retorno void não precisa de mapping |
| Toast success inline na screen | `onSuccess` callback na Location | tela permanece aberta após sucesso (sem navegação) |
| `data.either(...)` sem early return | early return pattern | sem operação async entre Left e Right |

---

## PasswordResetRequest (infrastructure)

```dart
final class PasswordResetRequest {
  final String email;
  const PasswordResetRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}
```

---

## PasswordResetResponse (infrastructure)

```dart
final class PasswordResetResponse {
  final String detail;
  const PasswordResetResponse({required this.detail});
  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) =>
      PasswordResetResponse(detail: json['detail'] as String);
}
```

---

## IRemoteAuthenticationDataSource (adição)

```dart
Future<Either<FailureResponse, PasswordResetResponse>> requestPasswordReset({
  required String email,
});
// implementação: cria PasswordResetRequest internamente
```

---

## IAuthenticationRepository (adição)

```dart
Future<Either<Failure, void>> requestPasswordReset({required String email});
```

---

## AuthenticationRepository (adição)

```dart
@override
Future<Either<Failure, void>> requestPasswordReset({required String email}) async {
  final data = await _authenticationDataSource.requestPasswordReset(email: email);
  return data.either((failure) => failure.toFailure(), (_) {});
}
```

---

## ForgotPasswordState

```dart
enum ForgotPasswordStatus { initial, loading, success, failure }

final class ForgotPasswordState extends Equatable {
  final String email;
  final String message;
  final ForgotPasswordStatus status;
  final String? emailFailure;
  // copyWith com clearEmailFailure
}
```

---

## ForgotPasswordIntent

```dart
sealed class ForgotPasswordIntent { const ForgotPasswordIntent(); }
final class EmailChanged extends ForgotPasswordIntent { final String value; ... }
final class SubmitPressed extends ForgotPasswordIntent { const SubmitPressed(); }
```

---

## ForgotPasswordNotifier

```dart
@riverpod
final class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  late ForgotPasswordFormValidator _validator;
  late IAuthenticationRepository _repository;

  @override
  ForgotPasswordState build() {
    _validator = ref.watch(forgotPasswordFormValidatorProvider);
    _repository = ref.watch(authenticationRepositoryProvider);
    return const ForgotPasswordState();
  }

  void dispatch(ForgotPasswordIntent intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(email: value, clearEmailFailure: true),
    SubmitPressed()            => _submit(),
  };
}
```

---

## ForgotPasswordScreen

- `StatelessWidget` + `Consumer` interno
- Parâmetro: `onBack: VoidCallback`
- `ref.listen`: `.success` → toast `.success` title `'Verifique seu email'`
- `ref.listen`: `.failure` → toast `.failure` title `'Opps'` description `state.message`
- Layout: botão voltar (top-left) → título → subtítulo → campo e-mail → Spacer → botão 'Enviar'
- Sem `onSuccess` callback — tela permanece aberta após sucesso

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `password_reset_response_test.dart` | — | `fromJson` parseia `detail` |
| `authentication_repository_test.dart` (grupo `requestPasswordReset`) | `IHttpClient` | Right on success, Left por tipo de erro |
| `forgot_password_notifier_test.dart` | `IAuthenticationRepository` | dispatch de todos os intents |
| `forgot_password_form_validator_test.dart` | — | validação de e-mail isolada |
