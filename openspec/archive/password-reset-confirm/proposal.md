# Proposal: password-reset-confirm

## Intenção

Implementar a tela de confirmação de redefinição de senha — segunda etapa do fluxo "Esqueci minha senha". O usuário recebe um e-mail com um deep link contendo `uid` e `token`, abre o app, preenche a nova senha e confirma. O app envia as credenciais ao backend e, em caso de sucesso, redireciona para o sign-in.

## Motivação

Completar o fluxo iniciado pela feature `forgot-password-request`. Sem essa tela, o usuário recebe o e-mail mas não consegue efetuar a troca de senha dentro do app.

## Camadas afetadas

- **infrastructure** — `PasswordResetConfirmRequest`, `PasswordResetConfirmResponse`, método `confirmPasswordReset` no datasource remoto de autenticação
- **domain** — método `confirmPasswordReset` em `IAuthenticationRepository` retornando `Either<Failure, void>`
- **data** — implementação do repositório usando `data.either`
- **presentation** — validator, State, Intent, Notifier (`family`), Screen, Location

## Comportamento esperado

- A tela é acessível **somente via deep link**: `/reset-password?uid=<uid>&token=<token>`
- Não aparece em nenhum fluxo de navegação interno do app
- Campos: **Nova senha** e **Confirmar senha**
- Validação: ambos os campos são obrigatórios, mínimo 8 caracteres, senhas devem coincidir
- **Sucesso**: toast `.success` com título "Senha redefinida" + navega para `SignInLocation` (root, replace)
- **Falha**: toast `.failure` com título "Opps" e `failure.message`

## Fora do escopo

- Configuração de deep link no Android (`AndroidManifest.xml` — `intent-filter`) e iOS (`Info.plist` — URL schemes / Associated Domains) — deve ser tratada em spec separada, pois envolve configuração nativa e testes de integração específicos por plataforma
- Invalidação/expiração do token (tratada pelo backend como `ValidationFailure`)
- Autenticação automática após redefinição
