## Why

A aplicação já possui identidades locais, mas ainda não autentica requisições de API. Em vez de manter guard, tokens e revogação próprios, a implementação deve adotar Laravel Sanctum como base suportada e mantida pelo ecossistema.

## What Changes

- Adicionar `laravel/sanctum` como dependência de produção compatível com Laravel 13.
- Introduzir Authentication como capability responsável por `SignUp`, `SignIn` e `SignOut`, sem reimplementar guard, geração, hash, persistência, expiração ou resolução de tokens.
- Usar Personal Access Tokens do Sanctum para clientes de API via `Authorization: Bearer`.
- Tornar `UserModel` o principal autenticável do Laravel e habilitá-lo com `HasApiTokens`, mantendo `UserEntity` livre de framework e credenciais.
- Adicionar password hash à persistência de User sem expor senha ou hash em Entity, Repository público, resposta ou log.
- Manter credenciais inválidas indistinguíveis na resposta pública.
- Expor endpoints JSON:API de `SignUp`, `SignIn` e `SignOut`.
- Cobrir integração Sanctum por Bearer token, expiração, revogação e fronteiras arquiteturais.
- Manter autenticação web ou SPA stateful, sessão, cookies, CSRF, rate limiting, password reset, verificação de e-mail, MFA, login externo, gestão de dispositivos, refresh tokens, abilities de negócio e autorização fora desta mudança.

## Capabilities

### New Capabilities

- `authentication`: Define criação de conta, autenticação por senha, emissão de tokens Sanctum para API e revogação do Bearer token atual.

### Modified Capabilities

- `user`: Permite que `UserModel` seja o principal autenticável do Laravel e tokenable do Sanctum, e que a tabela `users` armazene password hash, preservando `UserEntity` como identidade pura.

## Impact

- `composer.json` e `composer.lock` receberão `laravel/sanctum` 4.x compatível com Laravel 13.
- A migration oficial de `personal_access_tokens`, o guard `sanctum` e a configuração publicada serão usados no lugar de infraestrutura própria de tokens.
- A tabela `users` receberá apenas a coluna de password hash necessária ao provider nativo; tokens continuarão na tabela do Sanctum.
- `UserModel` passará a estender `Authenticatable` e usar `HasApiTokens`; `UserEntity` continuará sem password, token ou dependências Laravel.
- Authentication poderá integrar-se a User nas bordas de Infrastructure, com dependência declarada no allowlist arquitetural.
- As rotas de User não receberão autorização genérica nesta mudança.
