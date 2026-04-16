# Tasks: password-reset-confirm

## infrastructure/

- [ ] `lib/src/infrastructure/clients/http/requests/password_reset_confirm_request.dart` — `PasswordResetConfirmRequest` (uid, token, newPassword → `new_password` no toJson)
- [ ] `lib/src/infrastructure/clients/http/responses/password_reset_confirm_response.dart` — `PasswordResetConfirmResponse` (detail, fromJson)
- [ ] `lib/src/infrastructure/datasources/remote/remote_authentication_data_source.dart` — adicionar `confirmPasswordReset` à interface e implementação; usa `EndpointKey.passwordResetConfirm.path`

## domain/

- [ ] `lib/src/domain/repositories/interface_authentication_repository.dart` — adicionar `confirmPasswordReset` retornando `Either<Failure, void>`

## data/

- [ ] `lib/src/data/repositories/authentication_repository.dart` — implementar `confirmPasswordReset` com `data.either`

## presentation/

- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/validators/password_reset_confirm_form_validator.dart` — compõe `PasswordValidation` + verifica match entre `newPassword` e `confirmPassword`
- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_state.dart` — `PasswordResetConfirmStatus` enum + `PasswordResetConfirmState`
- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_intent.dart` — `NewPasswordChanged`, `ConfirmPasswordChanged`, `SubmitPressed`
- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/notifiers/password_reset_confirm_notifier.dart` — `@riverpod` com `family` (`uid`, `token` no `build`)
- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/password_reset_confirm_screen.dart` — `StatelessWidget` + `Consumer`; recebe `uid` e `token`; `AppBarWidget` + `GoBackWidget`; `ref.listen` para sucesso/falha
- [ ] `lib/src/presentation/screens/authentication/password_reset_confirm/password_reset_confirm_location.dart` — `PasswordResetConfirmLocation` com `uid` e `token` no construtor

## main/

- [ ] `lib/src/main/providers/validators_provider.dart` — adicionar `passwordResetConfirmFormValidatorProvider`
- [ ] `lib/app_route.dart` — adicionar `AppRoutes.passwordResetConfirm` (path `/reset-password`, regex `r'^/reset-password'`) e incluir em `_all`
- [ ] `dart run build_runner build --delete-conflicting-outputs`

## Testes

- [ ] `test/src/infrastructure/responses/password_reset_confirm_response_test.dart` — `fromJson` parseia `detail`
- [ ] `test/src/data/repositories/authentication_repository_test.dart` — grupo `confirmPasswordReset`: Right on success, Left ValidationFailure, NetworkFailure, ServerFailure
- [ ] `test/src/presentation/authentication/password_reset_confirm/validators/password_reset_confirm_form_validator_test.dart` — senha vazia, senha curta, senhas não coincidem, tudo válido
- [ ] `test/src/presentation/authentication/password_reset_confirm/notifiers/password_reset_confirm_notifier_test.dart` — NewPasswordChanged, ConfirmPasswordChanged, SubmitPressed (inválido / válido→success / válido→failure)
