## Context

O projeto usa Laravel 13, JSON:API e bounded contexts. User já mantém identificador, nome e e-mail canônico, mas seu Model ainda não participa do sistema de autenticação do framework. A versão anterior deste desenho propunha tabela, guard, principal, geração de token, digest, expiração e resolução próprios, apesar de Laravel Sanctum já fornecer essas capacidades para APIs simples.

Sanctum 4.3 é compatível com Illuminate 13 e pode ser usado exclusivamente para autenticação por API token. Esta mudança cobre apenas Personal Access Tokens enviados por `Authorization: Bearer`; autenticação web ou SPA stateful não faz parte do escopo.

## Goals / Non-Goals

**Goals:**

- Usar Sanctum e autenticação nativa do Laravel como implementação padrão.
- Evitar guard, principal, token generator, token digest e repository de token próprios.
- Implementar `SignUp`, `SignIn` e `SignOut` para API com Personal Access Tokens.
- Manter `UserEntity` e Application de User livres de Laravel, ainda que `UserModel` se torne o principal autenticável na Infrastructure.
- Preservar senha somente como hash adaptativo e token Sanctum somente como digest SHA-256 persistido pelo pacote.
- Produzir erros públicos genéricos para credenciais inválidas.
- Impedir lazy loading do Eloquent fora de produção a partir do provider de Authentication.
- Manter autorização de negócio fora de Authentication.

**Non-Goals:**

- Criar guard, token format, token model ou middleware de resolução próprios.
- Implementar autenticação web ou SPA stateful, sessão, cookies ou proteção CSRF.
- Implementar rate limiting de `SignIn`.
- Implementar password reset, alteração de senha, verificação de e-mail, MFA, OAuth/OIDC ou login social.
- Implementar abilities/scopes de negócio, roles, permissions ou policies de ownership.
- Listar tokens, nomear dispositivos ou revogar outros tokens.
- Proteger genericamente o CRUD de User.

## Decisions

### Sanctum será a fonte de verdade para autenticação HTTP

A implementação instalará `laravel/sanctum:^4.3` e seguirá a instalação oficial para Laravel 13. Rotas protegidas usarão `auth:sanctum`; não haverá `Auth::extend`, `Auth::viaRequest`, guard próprio ou principal paralelo.

Para API, Sanctum emitirá Personal Access Tokens com `createToken`, persistirá somente o hash SHA-256 em `personal_access_tokens`, resolverá Bearer tokens e disponibilizará `currentAccessToken()` para revogação. O token puro será retornado uma única vez pelo `SignIn`.

O middleware `statefulApi()` não será habilitado por esta mudança e nenhum endpoint de Authentication usará sessão ou cookie. Suporte web ou SPA stateful exigirá uma mudança própria.

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

`SignUp` aceitará senha entre 6 e 12 caracteres, com ao menos uma letra maiúscula e um número, preservando o valor exato. O Request confirmará `password_confirmation`; a regra de Domain protegerá os mesmos requisitos fora do HTTP. Os caminhos aninhados de password serão excluídos de trim quando necessário para não alterar o segredo recebido.

O hash será criado pelo hasher Laravel. Um `SignIn` bem-sucedido poderá aplicar `needsRehash` usando a integração nativa antes de concluir a autenticação.

### API usará Personal Access Tokens

`POST /api/authentication/sign-in` validará credenciais e emitirá um Personal Access Token Sanctum sem abilities de negócio. A resposta JSON:API representará `access-tokens`, incluirá o identificador público do registro, `token`, `token_type: Bearer` e `expires_at`, e enviará `Cache-Control: no-store` e `Pragma: no-cache`.

A expiração padrão será 120 minutos, configurada em `config/sanctum.php` e gravada em `expires_at` na emissão. O comando oficial `sanctum:prune-expired` será agendado para remover tokens expirados após a margem operacional definida.

`DELETE /api/authentication/sign-out`, protegido por `auth:sanctum`, removerá somente `currentAccessToken()`. Outros tokens do mesmo User permanecerão válidos.

A Presentation não acessará `$request->user()?->currentAccessToken()` nem excluirá diretamente o Model do Sanctum. `SignOutController` chamará `SignOutUseCase`, que delegará a revogação atual por `SignOutPort`; somente `SignOutAdapter`, em Infrastructure, resolverá o principal autenticado, obterá `currentAccessToken()` e o excluirá. Essa fronteira torna explícita a intenção de revogação e mantém Request, guard, Eloquent e Sanctum fora da Application, sem introduzir Entity, Repository ou Model de token próprios.

Alternativa rejeitada: manter a chamada recomendada pelo Sanctum diretamente no Controller. Embora funcional, ela combina resolução implícita do principal com persistência em Presentation e expõe essa camada ao Model do pacote.

### SignUp continuará atômico

`SignUp` criará identidade e password hash em uma transação única. Como ambos residem em `users`, não haverá uma segunda tabela de credencial nem risco de identidade persistida sem hash. A constraint única de `users.email` continuará como barreira final para concorrência.

O fluxo não emitirá token implicitamente. O User criado fará `SignIn` separadamente.

### Falhas não enumerarão Users

E-mail inválido, User inexistente, password irrecuperável e senha incorreta produzirão o mesmo `401`, título e detalhe na API. O Request de `SignIn` validará estrutura e tipo, mas não transformará formato de e-mail inválido em um `422` distinguível.

### API seguirá JSON:API

As rotas de API serão:

- `POST /api/authentication/sign-up`, nome `authentication.api.sign-up`.
- `POST /api/authentication/sign-in`, nome `authentication.api.sign-in`.
- `DELETE /api/authentication/sign-out`, nome `authentication.api.sign-out`.

`SignUp` responderá `201` com recurso `sign-ups`, relacionamento `user` e `Location` para o User criado. `SignIn` responderá `200` com recurso `access-tokens`. `SignOut` responderá `204`.

Validation errors preservarão `source.pointer`. E-mail já utilizado responderá `409`; entrada inválida, `422`; credenciais ou token inválidos, `401`.

### Authentication não concederá autorização

Sanctum comprovará o principal e, quando aplicável, o token. Isso não autoriza operações de User. Rotas atuais continuarão públicas até specs próprias definirem ownership e policies.

## Risks / Trade-offs

- [User Infrastructure passa a depender de Sanctum e Auth] -> Manter `UserEntity`, Domain e Application livres do framework e testar essa fronteira.
- [Password hash passa a residir em `users`] -> Ocultar no Model, não mapear para Entity e impedir serialização/logs.
- [Users preexistentes não conhecem a senha aleatória de backfill] -> Mantê-los não autenticáveis e criar definição/reset de senha somente em capability futura.
- [Token Bearer roubado vale até expiração ou revogação] -> HTTPS, expiração de 120 minutos, resposta `no-store`, hash persistido pelo Sanctum e revogação imediata.

## Migration Plan

1. Instalar Sanctum com o fluxo oficial de Laravel 13 e revisar os artefatos publicados.
2. Adicionar `password` a `users`, fazer backfill irrecuperável para registros existentes e publicar a migration de `personal_access_tokens`.
3. Tornar `UserModel` autenticável/tokenable, ocultar password e configurar o provider Eloquent.
4. Remover configuração de ambiente adicionada exclusivamente para sessão web ou SPA stateful e não habilitar `statefulApi()`.
5. Implementar `SignUp`, `SignIn` e `SignOut` usando Auth e Sanctum, sem infraestrutura paralela.
6. Configurar expiração, pruning, JSON:API e rotas de API.
7. Executar migrations no Lerd antes dos testes de fluxo.
8. Validar Domain/Application, integração Sanctum por Bearer token, provider e arquitetura.

No rollback, remover primeiro rotas e uso do guard Sanctum, depois tokens e coluna `password`, e por fim a dependência. A remoção da coluna descarta hashes; portanto rollback após uso real exige janela de manutenção e decisão explícita sobre perda de credenciais.

## Open Questions

Nenhuma questão bloqueadora. Autenticação web ou SPA stateful, rate limiting, password reset, definição de senha para Users preexistentes, abilities e autorização de negócio permanecem em mudanças futuras.
