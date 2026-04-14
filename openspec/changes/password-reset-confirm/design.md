# Design: password-reset-confirm

## Regra de dependência

```
infrastructure ← data ← domain
presentation   ← domain
main           → tudo
```

Nenhuma camada viola esta ordem.

---

## infrastructure/

### `PasswordResetConfirmRequest`
`lib/src/infrastructure/clients/http/requests/password_reset_confirm_request.dart`

```dart
final class PasswordResetConfirmRequest {
  final String uid;
  final String token;
  final String newPassword;

  const PasswordResetConfirmRequest({
    required this.uid,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'token': token,
    'new_password': newPassword,
  };
}
```

### `PasswordResetConfirmResponse`
`lib/src/infrastructure/clients/http/responses/password_reset_confirm_response.dart`

Mesmo padrão do `PasswordResetResponse` — campo `detail`, `fromJson` apenas.

```dart
final class PasswordResetConfirmResponse {
  final String detail;
  const PasswordResetConfirmResponse({required this.detail});
  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) =>
      PasswordResetConfirmResponse(detail: json['detail'] as String);
}
```

### Datasource — `IRemoteAuthenticationDataSource`
`lib/src/infrastructure/datasources/remote/remote_authentication_data_source.dart`

Adicionar à interface e implementação:

```dart
Future<Either<FailureResponse, PasswordResetConfirmResponse>> confirmPasswordReset({
  required String uid,
  required String token,
  required String newPassword,
});
```

Implementação cria `PasswordResetConfirmRequest` internamente e usa `EndpointKey.passwordResetConfirm.path`.

---

## domain/

### `IAuthenticationRepository`
`lib/src/domain/repositories/interface_authentication_repository.dart`

```dart
Future<Either<Failure, void>> confirmPasswordReset({
  required String uid,
  required String token,
  required String newPassword,
});
```

Retorna `Either<Failure, void>` — sem modelo de domínio, igual ao `requestPasswordReset`.

---

## data/

### `AuthenticationRepository`
`lib/src/data/repositories/authentication_repository.dart`

Sem operação async entre Left e Right → usar `data.either`:

```dart
@override
Future<Either<Failure, void>> confirmPasswordReset({
  required String uid,
  required String token,
  required String newPassword,
}) async {
  final data = await _authenticationDataSource.confirmPasswordReset(
    uid: uid,
    token: token,
    newPassword: newPassword,
  );
  return data.either((failure) => failure.toFailure(), (_) {});
}
```

Sem extension `toModel()` — `void` não precisa de mapeamento.

---

## presentation/

### `PasswordResetConfirmFormValidator`
`lib/src/presentation/screens/authentication/password_reset_confirm/validators/`

Compõe `PasswordValidation` para `newPassword`. Verifica internamente se `confirmPassword == newPassword` — sem classe `Validation` nova.

### State / Intent

`PasswordResetConfirmStatus`: `initial`, `loading`, `success`, `failure`

`PasswordResetConfirmState`:
- `newPassword: String`
- `confirmPassword: String`
- `message: String`
- `status: PasswordResetConfirmStatus`
- `newPasswordFailure: String?`
- `confirmPasswordFailure: String?`

`PasswordResetConfirmIntent`:
- `NewPasswordChanged(String value)`
- `ConfirmPasswordChanged(String value)`
- `SubmitPressed()`

### Notifier — `family`

`uid` e `token` vêm do deep link e são passados ao notifier via `family` do Riverpod:

```dart
@riverpod
class PasswordResetConfirmNotifier extends _$PasswordResetConfirmNotifier {
  late PasswordResetConfirmFormValidator _validator;
  late IAuthenticationRepository _repository;

  @override
  PasswordResetConfirmState build({required String uid, required String token}) {
    _validator = ref.watch(passwordResetConfirmFormValidatorProvider);
    _repository = ref.watch(authenticationRepositoryProvider);
    return const PasswordResetConfirmState();
  }
}
```

Provider gerado: `passwordResetConfirmProvider((uid: uid, token: token))`.

### Screen

`PasswordResetConfirmScreen` recebe `uid` e `token` via construtor — repassados ao provider family.

- `AppBarWidget(title: 'Criar nova senha', leading: GoBackWidget())`
- Campo "Nova senha" (obscureText)
- Campo "Confirmar senha" (obscureText, inputAction: `.done`)
- Botão "Redefinir senha"
- `ref.listen` → sucesso: toast + `context.navigate(SignInLocation(), root: true, replace: true)`

### Location

`PasswordResetConfirmLocation` recebe `uid` e `token` como parâmetros do construtor — populados pelo router ao processar o deep link.

---

## main/

- `validators_provider.dart` — `passwordResetConfirmFormValidatorProvider`
- `app_route.dart` — `AppRoutes.passwordResetConfirm` com path `/reset-password` e regex `r'^/reset-password'`

---

## Decisões

| Decisão | Motivo |
|---|---|
| `Either<Failure, void>` | Sem dado de domínio relevante no sucesso |
| Notifier `family` (uid + token) | Parâmetros chegam do deep link, não de estado global; family é o mecanismo Riverpod para providers parametrizados |
| Deep link nativo fora do escopo | Requer configuração em `AndroidManifest.xml` e `Info.plist` — ciclo de vida separado da feature |
| Sem nova classe `Validation` para match | A comparação `confirmPassword == newPassword` é responsabilidade do `FormValidator`, não de uma `Validation` genérica reutilizável |
