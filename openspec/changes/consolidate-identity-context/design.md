## Context

O projeto possui `User` para identidade local e CRUD e `Authentication` para credencial e tokens. Os dois contextos compartilham `users`, `UserModel`, e-mail e criação de registro. `CreateUserUseCase` persiste uma identidade sem credencial conhecida e o callback de `UserModel` inventa um password aleatório; `SignUpUseCase` persiste a mesma identidade com password informado. Authentication Infrastructure importa Domain e Infrastructure de User, e o teste arquitetural libera todo `App\User` para acomodar essa integração.

A consolidação ocorre antes de ownership e PostgreSQL para que essas evoluções dependam de uma identidade com owner e lifecycle únicos. A mudança deve preservar Laravel 13, Sanctum, JSON:API, a tabela `users` e os contratos externos restantes.

## Goals / Non-Goals

**Goals:**

- Tornar `Identity` o único bounded context responsável por identidade, registro, credencial, autenticação, tokens e encerramento da conta.
- Fazer `SignUp` ser o único cadastro público e remover identidades ativas sem credencial conhecida.
- Preservar Domain e Application livres de Laravel, Eloquent, HTTP e Sanctum.
- Manter Ports separados e nomeados `IdentityWritePort`, `CreatePort`, `SignInPort` e `SignOutPort`.
- Remover dependências cross-context e sua allowlist ampla.
- Preservar tabela, IDs, resource types e endpoints não removidos.
- Revogar tokens quando a conta for excluída.

**Non-Goals:**

- Implementar ownership, policies, roles, permissions ou PostgreSQL RLS.
- Implementar convite administrativo, ativação, reset ou alteração de password, verificação de e-mail ou MFA.
- Alterar a política de password, expiração de token ou semântica de SignIn e SignOut.
- Renomear a tabela `users`, resource types JSON:API ou URLs de Authentication.
- Introduzir interfaces para UseCases, Repository genérico ou abstração própria sobre o Sanctum.
- Manter compatibilidade com `POST /api/users`.

## Decisions

### Identity será o único owner do lifecycle

As classes de `app/User` e `app/Authentication` serão migradas para `app/Identity`. `UserEntity` continuará representando nome, e-mail e identidade sem password ou token, carregando o nome como `NameValueObject`. `PasswordValueObject` continuará protegendo a política de password. `UserModel` continuará sendo o principal autenticável do provider Eloquent e tokenable do Sanctum, agora dentro da Infrastructure do mesmo contexto.

A unificação é de ownership e dependências, não uma fusão de todas as responsabilidades em uma classe. UseCases de perfil, registro e acesso continuam separados.

Alternativa rejeitada: manter dois contextos e introduzir um contrato cross-context. Isso preservaria dois owners sobre a mesma linha e exigiria decidir em qual lado vivem criação, exclusão e mudanças futuras de e-mail e credencial.

### Nome será canônico no Domain e validado igualmente no HTTP

`NameValueObject` removerá espaços externos, reduzirá whitespace repetido a um único espaço e aceitará somente letras Unicode separadas por espaços. O valor canônico deverá conter de 2 a 12 letras, inclusive, sem contar os espaços. `UserEntity` carregará esse Value Object, e os Form Requests de SignUp e atualização aplicarão as mesmas regras para rejeitar na borda o que o Domain rejeitaria.

### SignUp será a única criação pública

`POST /api/users` e `CreateUserController` serão removidos. `POST /api/authentication/sign-up` continuará criando o recurso `sign-ups`, relacionando o novo `users` e apontando `Location` para `GET /api/users/{user}`.

O fallback de password aleatório em `UserModel::booted` será removido. Toda criação nova de conta deverá passar por `SignUpUseCase` e `CreatePort` com password válido. Registros preexistentes permanecem válidos; esta mudança não redefine o backfill histórico nem cria um fluxo de reivindicação.

Alternativa rejeitada: manter `POST /api/users` durante transição. Não há consumidor externo identificado que justifique compatibilidade, e o endpoint manteria account squatting e o lifecycle duplicado.

### As quatro Ports terão capacidades distintas

`IdentityWritePort` implementará coordenação transacional e retry. O UseCase definirá toda a operação atômica dentro de `execute`; o Adapter não escolherá quais passos pertencem à unidade.

`CreatePort` provisionará exclusivamente um novo principal autenticável e sua credencial na tabela `users`. Seu contrato receberá tipos independentes do framework, protegerá o password com `SensitiveParameter`, retornará `UserEntity` persistida e traduzirá conflito de unicidade para exceção da Application.

`CreatePort` é uma exceção deliberada à preferência por Repository porque a operação combina criação do principal Laravel, password hash do provider e persistência obrigatoriamente conjunta. Ela não poderá consultar, atualizar, listar ou excluir identidades e não substituirá `IdentityRepository` como CRUD genérico.

`SignInPort` validará credenciais pelo provider Laravel, aplicará rehash quando necessário e emitirá Personal Access Token Sanctum, retornando `SignInOutput`.

`SignOutPort` resolverá e revogará somente o Personal Access Token usado na requisição atual. Ela não excluirá todos os tokens nem receberá Model ou Request na assinatura.

Alternativa rejeitada: uma única `AccessTokenPort`. Ports separados mantêm intenções, contratos sensíveis e testes isolados sem criar interfaces de UseCase.

### IdentityRepository cuidará do estado ordinário da identidade

`IdentityRepository` substituirá `UserRepository` para consulta por ID/e-mail, listagem, atualização e exclusão. Ele não criará contas; a criação pertence exclusivamente a `CreatePort`.

Na exclusão, o Repository removerá todos os tokens pertencentes ao principal antes de remover `users`, dentro de `IdentityWritePort`. O contrato continuará retornando somente tipos de Domain e scalars, sem expor Eloquent ou Sanctum.

Alternativa rejeitada: manter `UserRepository::create`. Dois contratos capazes de criar a mesma identidade reintroduziriam a ambiguidade que esta mudança remove.

### URLs e recursos permanecerão orientados ao consumidor

O nome interno do contexto não altera os recursos externos. Permanecem `users`, `sign-ups` e `access-tokens`, assim como GET/PATCH/DELETE de `/api/users` e os três endpoints `/api/authentication/*`. Apenas `POST /api/users` será removido e deverá responder `405` porque o prefixo continuará possuindo outras rotas.

Controllers, Requests e Responses serão movidos para `App\Identity\Presentation`, mantendo nomes orientados à ação e ao recurso.

### A migração será estrutural, não de dados

Namespaces, providers, bindings e testes serão movidos sem renomear tabelas ou colunas. `IdentityServiceProvider` substituirá `UserServiceProvider` e `AuthenticationServiceProvider`, registrará o Repository, as quatro Ports e a política de lazy loading. `bootstrap/app.php` carregará as rotas Identity e manterá as traduções JSON:API.

Como o Sanctum persiste o morph type do principal em `personal_access_tokens.tokenable_type`, `IdentityServiceProvider` manterá o discriminador já armazenado apontando para o novo `UserModel`. Assim tokens emitidos antes da consolidação continuam resolvíveis e revogáveis sem migration de dados, embora o namespace antigo deixe de existir como dependência de código.

O teste arquitetural deixará de permitir `Authentication Infrastructure -> App\User`; `Identity` e `Expense` são os contextos existentes.

## Matriz de rastreabilidade

| Comportamento | Evidência executável | Estado |
| --- | --- | --- |
| Identity concentra o lifecycle sem dependências dos contextos removidos | `tests/Unit/Architecture/ContextBoundariesTest.php` e `tests/Feature/Identity/Infrastructure/Providers/IdentityServiceProviderTest.php` | Comprovado |
| Nome canônico usa `NameValueObject`, letras Unicode, whitespace normalizado e limites de 2 a 12 letras | `tests/Unit/Identity/Domain/ValueObjects/NameValueObjectTest.php`, `tests/Feature/Identity/Presentation/Http/SignUpApiTest.php` e `tests/Feature/Identity/Presentation/Http/UpdateUserApiTest.php` | Comprovado |
| Ports e Repository expõem responsabilidades separadas e independentes de Laravel | `tests/Unit/Identity/Application/Ports/IdentityPortsTest.php`, `tests/Unit/Identity/Application/Repositories/IdentityRepositoryTest.php` e teste arquitetural | Comprovado |
| SignUp provisiona principal e credencial atomicamente, traduz conflito e não emite token | `tests/Unit/Identity/Application/UseCases/SignUpUseCaseTest.php`, `tests/Feature/Identity/Infrastructure/Adapters/IdentityWriteAdapterTest.php`, `tests/Feature/Identity/Infrastructure/Adapters/RegistrationAdapterTest.php` e `tests/Feature/Identity/Presentation/Http/SignUpApiTest.php` | Comprovado em SQLite; concorrência real em PostgreSQL bloqueada pela tarefa 3.8 |
| SignIn e SignOut preservam emissão, expiração e revogação seletiva | `tests/Unit/Identity/Application/UseCases/SignInUseCaseTest.php`, `tests/Unit/Identity/Application/UseCases/SignOutUseCaseTest.php`, `tests/Feature/Identity/Infrastructure/Adapters/SignOutAdapterTest.php` e `tests/Feature/Identity/Presentation/Http/SignInAndSignOutApiTest.php` | Comprovado |
| Consulta, listagem e atualização de User preservam mapping e contratos JSON:API | `tests/Feature/Identity/Infrastructure/Persistence/Repositories/EloquentIdentityRepositoryTest.php` e testes HTTP de GET/PATCH em `tests/Feature/Identity/Presentation/Http` | Comprovado |
| Exclusão remove todos os tokens e a identidade na mesma unidade atômica | `tests/Unit/Identity/Application/UseCases/DeleteUserUseCaseTest.php`, `tests/Feature/Identity/Infrastructure/Persistence/Repositories/EloquentIdentityRepositoryTest.php` e `tests/Feature/Identity/Presentation/Http/DeleteUserApiTest.php` | Comprovado para sucesso e rollback sequenciais; corrida com emissão concorrente não exercitada |
| `POST /api/users` não existe e as demais rotas preservam nomes e middleware | `tests/Feature/Identity/Presentation/Http/CreateUserApiTest.php` e `tests/Feature/Identity/Presentation/Routes/AuthenticationRoutesTest.php` | Comprovado |
| Respostas não expõem password, hash ou token indevido | `tests/Feature/Identity/Security/SecretExposureTest.php` e testes HTTP de Identity | Comprovado |

## Risks / Trade-offs

- [Mudança breaking remove `POST /api/users`] -> Atualizar README e consumidores identificados; responder `405` e orientar criação por SignUp.
- [Mudança ampla de namespaces produz imports órfãos] -> Migrar verticalmente, buscar referências antigas e executar teste arquitetural e suíte completa.
- [CreatePort persiste parte central da conta] -> Restringir o contrato somente ao provisionamento principal+credencial e impedir operações CRUD adicionais.
- [Exclusão de conta passa a remover tokens] -> Testar múltiplos tokens e rollback conjunto quando a exclusão falhar.
- [Registros históricos podem ter password irrecuperável] -> Preservar dados e comportamento; ativação/reset permanece em mudança própria.
- [Contexto Identity fica maior] -> Manter UseCases, Ports, Adapters e Presentation separados por papel, sem classes base ou Services genéricos.
- [Renomear UserRepository pode gerar churn sem benefício comportamental] -> Fazer a mudança uma única vez junto da consolidação e preservar suas operações naturais.

## Migration Plan

1. Criar `app/Identity` e mover Domain e Application de User e Authentication, ajustando namespaces e introduzindo `NameValueObject` para o nome canônico.
2. Introduzir `IdentityRepository`, `IdentityWritePort`, `CreatePort`, `SignInPort` e `SignOutPort` com bindings em `IdentityServiceProvider`.
3. Migrar os Adapters, o `UserModel`, Repository Eloquent, Controllers, Requests, Responses e rotas para Identity.
4. Fazer `SignUpUseCase` delimitar a transação e registrar por `CreatePort`; remover o callback de password aleatório.
5. Remover `CreateUserUseCase`, `CreateUserRequest`, `CreateUserController` e `POST /api/users`.
6. Tornar `DeleteUserUseCase` transacional e remover todos os tokens da identidade antes do registro `users`.
7. Atualizar composition roots, exception mapping, testes arquiteturais, providers e paths de testes.
8. Atualizar OpenSpec, README, ARCHITECTURE e Obsidian.
9. Executar migrations pendentes, suítes por camada, suíte completa, Pint e validação OpenSpec strict.
10. Remover os diretórios vazios `app/User`, `app/Authentication` e seus equivalentes em testes.

Rollback antes de deploy restaura namespaces, providers e `POST /api/users`. Após clientes migrarem para a API nova, rollback do endpoint removido não exige transformação de dados, mas volta a permitir criação sem lifecycle; por isso só deve ocorrer para restaurar serviço enquanto a falha é corrigida.

## Open Questions

Nenhuma questão bloqueadora. Convite administrativo, ativação de contas históricas, ownership, RLS e autorização permanecem em mudanças próprias.
