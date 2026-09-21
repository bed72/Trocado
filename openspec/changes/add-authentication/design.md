## Context

O projeto usa Laravel 13, JSON:API e bounded contexts. User já mantém identificador, nome e e-mail canônico, mas seu Model ainda não participa do sistema de autenticação do framework. A versão anterior deste desenho propunha tabela, guard, principal, geração de token, digest, expiração e resolução próprios, apesar de Laravel Sanctum já fornecer essas capacidades para APIs simples e autenticação híbrida web/API.

Sanctum 4.3 é compatível com Illuminate 13 e é o pacote recomendado pelo Laravel para aplicações que combinam interface first-party e API por token. Ele resolve dois casos deliberadamente diferentes: Personal Access Tokens para clientes Bearer e sessão Laravel para navegadores first-party. Esta mudança passa a aceitar essa separação em vez de forçar o mesmo segredo nos dois transportes.

## Goals / Non-Goals

**Goals:**

- Usar Sanctum e autenticação nativa do Laravel como implementação padrão.
- Evitar guard, principal, tabela de sessão, token generator, token digest e repository de sessão próprios.
- Implementar `SignUp`, `SignIn` e `SignOut` para API e web com os mecanismos recomendados para cada transporte.
- Manter `UserEntity` e Application de User livres de Laravel, ainda que `UserModel` se torne o principal autenticável na Infrastructure.
- Preservar senha somente como hash adaptativo e token Sanctum somente como digest SHA-256 persistido pelo pacote.
- Produzir erros públicos genéricos para credenciais inválidas e limitar tentativas de `SignIn`.
- Manter autorização de negócio fora de Authentication.

**Non-Goals:**

- Criar guard, token format, token model, sessão server-side ou middleware de resolução próprios.
- Fazer o cookie web carregar um Personal Access Token.
- Implementar password reset, alteração de senha, verificação de e-mail, MFA, OAuth/OIDC ou login social.
- Implementar abilities/scopes de negócio, roles, permissions ou policies de ownership.
- Listar tokens, nomear dispositivos ou revogar outras sessões.
- Proteger genericamente os CRUDs atuais de User e Budget.

## Decisions

### Sanctum será a fonte de verdade para autenticação HTTP

A implementação instalará `laravel/sanctum:^4.3` e seguirá a instalação oficial para Laravel 13. Rotas protegidas usarão `auth:sanctum`; não haverá `Auth::extend`, `Auth::viaRequest`, guard próprio ou principal paralelo.

Para API, Sanctum emitirá Personal Access Tokens com `createToken`, persistirá somente o hash SHA-256 em `personal_access_tokens`, resolverá Bearer tokens e disponibilizará `currentAccessToken()` para revogação. O token puro será retornado uma única vez pelo `SignIn`.

Para web first-party, será usado o guard `web`, sessão Laravel, cookie de sessão criptografado e assinado, regeneração de session ID após `SignIn`, CSRF e invalidação da sessão no `SignOut`. `auth:sanctum` reconhecerá a sessão first-party antes de procurar um Bearer token, conforme o fluxo oficial do pacote.

Alternativa rejeitada: transportar um Personal Access Token em cookie próprio. Isso recriaria resolução de credencial, conflito entre transportes e lifecycle de cookie que Sanctum já evita ao recomendar sessão web first-party.

### `UserModel` será o principal do framework

`UserModel`, localizado em User Infrastructure, passará a estender `Illuminate\Foundation\Auth\User` e usar `Laravel\Sanctum\HasApiTokens`. Ele será configurado como model do provider Eloquent. Não será criado `AuthenticationPrincipal`.

`UserEntity` continuará representando somente identificador, nome e e-mail e não implementará `Authenticatable`, `HasApiTokens` ou qualquer contrato Laravel. O Repository continuará mapeando apenas o estado de domínio; password e tokens serão ocultados da serialização.

Essa decisão modifica a capability User de forma explícita. A independência exigida passa a se aplicar à Entity e às camadas Domain/Application, não ao Model de Infrastructure, cujo papel já é integrar o contexto ao framework.

Alternativa rejeitada: principal mínimo paralelo a User. Isso exigiria provider, guard e resolução próprios e impediria o uso direto do fluxo suportado pelo Sanctum.

### Password hash ficará em `users`

A tabela `users` receberá a coluna `password`, usada pelo provider Eloquent padrão. Ela armazenará somente hash produzido pelo hasher configurado do Laravel. Nenhuma tabela `authentication_credentials` será criada.

Users preexistentes receberão, na migration, um hash aleatório irrecuperável para satisfazer o contrato não nulo sem lhes conceder uma senha conhecida. Eles continuarão sem conseguir autenticar até existir uma capability futura de definição/reset de senha. `SignUp` não poderá reivindicar e-mail já existente.

`UserEntity` não carregará password. A integração necessária para criar User e hash de maneira atômica ficará na borda de Infrastructure de Authentication, com a menor extensão possível dos contratos atuais e sem expor hash em respostas.

Alternativa rejeitada: tabela própria de credenciais. Embora preserve separação física, ela exigiria UserProvider ou verificação de senha customizada e duplicaria comportamento já esperado pelo provider Eloquent.

### Senha seguirá a política da capability

`SignUp` aceitará senha entre 8 caracteres e 72 bytes, preservando o valor exato. O Request confirmará `password_confirmation`; a regra de domínio ou aplicação protegerá os mesmos limites fora do HTTP. Os caminhos aninhados de password serão excluídos de trim e conversão de string vazia quando necessário para não alterar o segredo recebido.

O hash será criado pelo hasher Laravel. Um `SignIn` bem-sucedido poderá aplicar `needsRehash` usando a integração nativa antes de concluir a autenticação.

### API usará Personal Access Tokens

`POST /api/authentication/sign-in` validará credenciais sem criar sessão web e emitirá um Personal Access Token Sanctum sem abilities de negócio. A resposta JSON:API representará `access-tokens`, incluirá o identificador público do registro, `token`, `token_type: Bearer` e `expires_at`, e enviará `Cache-Control: no-store` e `Pragma: no-cache`.

A expiração padrão será 120 minutos, configurada em `config/sanctum.php` e gravada em `expires_at` na emissão. O comando oficial `sanctum:prune-expired` será agendado para remover tokens expirados após a margem operacional definida.

`DELETE /api/authentication/sign-out`, protegido por `auth:sanctum`, removerá somente `currentAccessToken()`. Outros tokens do mesmo User permanecerão válidos.

### Web usará sessão Laravel

Os endpoints web permanecerão no grupo `web`. `SignIn` autenticará com o guard `web`, regenerará a sessão e redirecionará sem token no corpo, URL ou flash data. `SignOut` executará logout, invalidará a sessão, regenerará o token CSRF e redirecionará como visitante.

Os atributos de cookie, duração e domínio virão de `config/session.php`. Em produção, o cookie será `Secure`, `HttpOnly` e `SameSite=Lax`. Não haverá cookie de Authentication separado.

Para um SPA first-party futuro, `statefulApi()` e `/sanctum/csrf-cookie` poderão ser habilitados conforme a documentação oficial. Esta mudança cobre Blade/web first-party e não exige criar um SPA.

### SignUp continuará atômico

`SignUp` criará identidade e password hash em uma transação única. Como ambos residem em `users`, não haverá uma segunda tabela de credencial nem risco de identidade persistida sem hash. A constraint única de `users.email` continuará como barreira final para concorrência.

O fluxo não emitirá token nem iniciará sessão implicitamente. O User criado fará `SignIn` separadamente.

### Falhas e rate limiting não enumerarão Users

E-mail inválido, User inexistente, password irrecuperável e senha incorreta produzirão o mesmo `401`, título e detalhe na API. O Request de `SignIn` validará estrutura e tipo, mas não transformará formato de e-mail inválido em um `422` distinguível.

Um limiter nomeado limitará cinco tentativas por minuto pela combinação de IP e SHA-256 de `lowercase(trim(email))`. API e web compartilharão a mesma definição. O backend de rate limiting não receberá o e-mail em claro na chave.

### API seguirá JSON:API

As rotas de API serão:

- `POST /api/authentication/sign-up`, nome `authentication.api.sign-up`.
- `POST /api/authentication/sign-in`, nome `authentication.api.sign-in`.
- `DELETE /api/authentication/sign-out`, nome `authentication.api.sign-out`.

`SignUp` responderá `201` com recurso `sign-ups`, relacionamento `user` e `Location` para o User criado. `SignIn` responderá `200` com recurso `access-tokens`. `SignOut` responderá `204`.

As rotas web equivalentes usarão os nomes `authentication.web.sign-up`, `authentication.web.sign-in` e `authentication.web.sign-out`, com redirects convencionais e proteção CSRF.

Validation errors preservarão `source.pointer`. E-mail já utilizado responderá `409`; entrada inválida, `422`; credenciais ou token inválidos, `401`; throttling, `429`.

### Authentication não concederá autorização

Sanctum comprovará o principal e, quando aplicável, o token. Isso não autoriza operações de User ou Budget. Rotas atuais continuarão públicas até specs próprias definirem ownership e policies.

## Risks / Trade-offs

- [User Infrastructure passa a depender de Sanctum e Auth] -> Manter `UserEntity`, Domain e Application livres do framework e testar essa fronteira.
- [API e web não compartilham a mesma credencial] -> Aceitar a separação recomendada pelo Sanctum; ambos convergem em `auth:sanctum` para rotas protegidas.
- [Password hash passa a residir em `users`] -> Ocultar no Model, não mapear para Entity e impedir serialização/logs.
- [Users preexistentes não conhecem a senha aleatória de backfill] -> Mantê-los não autenticáveis e criar definição/reset de senha somente em capability futura.
- [Token Bearer roubado vale até expiração ou revogação] -> HTTPS, expiração de 120 minutos, resposta `no-store`, hash persistido pelo Sanctum e revogação imediata.
- [Sessão web depende da configuração do driver] -> Usar configuração Laravel e validar cookie, CSRF, regeneração e invalidação em feature tests.
- [Rate limiting por IP e digest não bloqueia ataques distribuídos] -> Cobrir abuso básico agora e evoluir somente com observabilidade.

## Migration Plan

1. Instalar Sanctum com o fluxo oficial de Laravel 13 e revisar os artefatos publicados.
2. Adicionar `password` a `users`, fazer backfill irrecuperável para registros existentes e publicar a migration de `personal_access_tokens`.
3. Tornar `UserModel` autenticável/tokenable, ocultar password e configurar o provider Eloquent.
4. Implementar `SignUp`, `SignIn` e `SignOut` usando Auth, sessão e Sanctum, sem infraestrutura paralela.
5. Configurar expiração, pruning, rate limiting, JSON:API e rotas web/API.
6. Executar migrations no Lerd antes dos testes de fluxo.
7. Validar Domain/Application, integração Sanctum, API, web, provider, arquitetura e coleção Bruno.

No rollback, remover primeiro rotas e uso do guard Sanctum, depois tokens e coluna `password`, e por fim a dependência. A remoção da coluna descarta hashes; portanto rollback após uso real exige janela de manutenção e decisão explícita sobre perda de credenciais.

## Open Questions

Nenhuma questão bloqueadora. Password reset, definição de senha para Users preexistentes, abilities e autorização de negócio permanecem em mudanças futuras.
