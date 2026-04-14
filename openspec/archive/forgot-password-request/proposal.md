# Proposal: forgot-password-request

## Intenção

Implementar a feature de recuperação de senha. O usuário informa o e-mail e a API envia um link de redefinição. Em caso de sucesso, exibe um toast de confirmação. Em caso de falha, exibe um toast de erro com a mensagem da API.

## Motivação

O botão "Esqueci minha senha" na `SignInScreen` está atualmente sem ação (`onTap: () {}`). Esta feature completa o fluxo de autenticação do app.

## Camadas afetadas

- `infrastructure/clients/http/requests/` — `PasswordResetRequest` (email)
- `infrastructure/clients/http/responses/` — `PasswordResetResponse` (detail)
- `infrastructure/datasources/remote/` — `IRemoteAuthenticationDataSource` + `RemoteAuthenticationDataSource` (novo método `requestPasswordReset`)
- `domain/repositories/` — `IAuthenticationRepository` (novo método `requestPasswordReset`)
- `data/repositories/` — `AuthenticationRepository` (implementação do novo método)
- `presentation/screens/authentication/forgot_password/` — State, Intent, Notifier, FormValidator, Screen, Location
- `main/providers/` — `validators_provider.dart` (novo provider), `app_route.dart` (nova rota)
- `presentation/screens/sign_in/` — `SignInScreen` e `SignInLocation` (wire `onForgotPassword`)

## Fora do escopo

- Tela de redefinição de senha (inserir nova senha com token)
- Validação do token de reset
- Reenvio automático do e-mail
