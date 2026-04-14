# Tasks: forgot-password-request

## infrastructure/

- [ ] `lib/src/infrastructure/clients/http/requests/password_reset_request.dart` — `PasswordResetRequest` (email, toJson)
- [ ] `lib/src/infrastructure/clients/http/responses/password_reset_response.dart` — `PasswordResetResponse` (detail, fromJson)
- [ ] `lib/src/infrastructure/datasources/remote/remote_authentication_data_source.dart` — adicionar `requestPasswordReset` à interface e implementação

## domain/

- [ ] `lib/src/domain/repositories/interface_authentication_repository.dart` — adicionar `requestPasswordReset` retornando `Either<Failure, void>`

## data/

- [ ] `lib/src/data/repositories/authentication_repository.dart` — implementar `requestPasswordReset` com `data.either`

## presentation/

- [ ] `lib/src/presentation/screens/authentication/forgot_password/validators/forgot_password_form_validator.dart` — compõe `EmailValidation`
- [ ] `lib/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_state.dart` — `ForgotPasswordStatus` + `ForgotPasswordState`
- [ ] `lib/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_intent.dart` — `EmailChanged` + `SubmitPressed`
- [ ] `lib/src/presentation/screens/authentication/forgot_password/notifiers/forgot_password_notifier.dart` — `@riverpod`, `_validator` + `_repository` via `ref.watch`
- [ ] `lib/src/presentation/screens/authentication/forgot_password/forgot_password_screen.dart` — `StatelessWidget` + `Consumer`, `onBack` callback
- [ ] `lib/src/presentation/screens/authentication/forgot_password/forgot_password_location.dart` — `ForgotPasswordLocation`, `onBack: context.pop`
- [ ] `lib/src/presentation/screens/authentication/sign_in/sign_in_screen.dart` — adicionar `onForgotPassword: VoidCallback`, wire no botão
- [ ] `lib/src/presentation/screens/authentication/sign_in/sign_in_location.dart` — passar `onForgotPassword: () => context.navigate(ForgotPasswordLocation())`

## main/

- [ ] `lib/src/main/providers/validators_provider.dart` — adicionar `forgotPasswordFormValidatorProvider`
- [ ] `lib/app_route.dart` — adicionar rota `forgotPassword` (`/forgot-password`)
- [ ] `dart run build_runner build --delete-conflicting-outputs`

## Testes

- [ ] `test/src/infrastructure/responses/password_reset_response_test.dart` — `fromJson` parseia `detail`
- [ ] `test/src/data/repositories/authentication_repository_test.dart` — grupo `requestPasswordReset` (Right on success, Left ValidationFailure, NetworkFailure, ServerFailure)
- [ ] `test/src/presentation/authentication/forgot_password/validators/forgot_password_form_validator_test.dart` — e-mail vazio, inválido, válido
- [ ] `test/src/presentation/authentication/forgot_password/notifiers/forgot_password_notifier_test.dart` — EmailChanged, SubmitPressed (vazio / inválido / válido→success / válido→failure)
