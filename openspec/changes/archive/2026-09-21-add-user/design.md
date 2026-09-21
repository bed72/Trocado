## Context

A aplicação possui apenas o bounded context `Budget` e não tem tabela, entidade, contrato ou API de usuário. Budgets são globais hoje, mas Budget e a futura Expense precisarão referenciar um proprietário estável antes que autenticação determine quem está executando uma requisição.

O desenho segue `ARCHITECTURE.md` e `.ai/guidelines/`: Domain permanece PHP puro, Application contém UseCases concretos e contratos independentes do ORM, Infrastructure usa Laravel/Eloquent e registra bindings, e Presentation expõe o CRUD HTTP com Form Requests, Controllers e Responses JSON:API. Os sufixos `Entity`, `ValueObject`, `UseCase`, `Repository`, `Model`, `Request`, `Controller`, `Response`, `Exception` e `ServiceProvider` identificam os papéis das classes.

## Goals / Non-Goals

**Goals:**

- Criar uma identidade local de User independente de autenticação.
- Proteger no Domain as invariantes de nome e e-mail.
- Criar, listar, consultar, atualizar e excluir usuários por casos de uso concretos.
- Expor essas operações por endpoints JSON:API consistentes com a API de Budget.
- Garantir unicidade do e-mail normalizado inclusive sob concorrência.
- Definir um contrato explícito de persistência com operações de CRUD, sem recorrer a `save` ou Repository genérico.
- Manter tipos Laravel e Eloquent restritos à Infrastructure.

**Non-Goals:**

- Implementar registro público, login, logout, senha, hashing, token, sessão, middleware, autorização, verificação de e-mail ou recuperação de acesso.
- Fazer `UserEntity` implementar `Authenticatable` ou qualquer contrato Laravel.
- Alterar Budget, recorrência ou implementar Expense.
- Criar abstrações base/genéricas.
- Proteger as rotas com autenticação ou autorização antes que essas capabilities sejam especificadas.

## Decisions

### User será um bounded context próprio

As classes serão organizadas sob `app/User/{Domain,Application,Infrastructure,Presentation}`. A estrutura respeitará `Presentation -> Application -> Domain` e `Infrastructure -> Application/Domain`; Presentation conterá somente os adaptadores HTTP exigidos pelo CRUD.

Alternativa rejeitada: criar `App\Models\User` como modelo global e deixar os outros contextos dependerem dele. Isso exporia Eloquent como identidade de negócio e contrariaria as fronteiras definidas em `ARCHITECTURE.md`.

### A entidade não conterá credenciais

`UserEntity` representará somente `id` opcional durante a criação, nome, `EmailValueObject` e timestamps opcionais de persistência. O nome será aparado e não poderá ficar vazio. O e-mail será validado, aparado e convertido para uma forma canônica em minúsculas pelo Value Object.

Senha, hash, token e estado de sessão não farão parte da entidade nem da tabela `users` nesta mudança. Uma capability futura de autenticação dependerá da identidade de User, e não o contrário.

Alternativa rejeitada: adicionar agora `password`, `remember_token` e `email_verified_at` por convenção do Laravel. Esses campos antecipariam decisões de autenticação que ainda não foram especificadas.

### O Repository terá operações explícitas

O contrato em `Application/Repositories/UserRepository.php` será:

```php
interface UserRepository
{
    public function create(UserEntity $user): UserEntity;

    public function update(UserEntity $user): ?UserEntity;

    public function delete(int $id): bool;

    /** @return list<UserEntity> */
    public function all(): array;

    public function findById(int $id): ?UserEntity;

    public function findByEmail(EmailValueObject $email): ?UserEntity;
}
```

`create` aceitará somente uma entidade ainda sem identidade persistida; `update` aceitará uma entidade persistida e retornará `null` quando a identidade não for encontrada; `delete` informará se removeu uma identidade; `all` retornará usuários em ordem de identificador. Não haverá `save`, Repository genérico, Builder, Model ou query Eloquent no contrato. O mapping simples permanecerá em `EloquentUserRepository`, como orienta `.ai/guidelines/infrastructure.md`.

Alternativa rejeitada: usar `save` para criação e atualização. Operações explícitas mantêm semânticas e falhas distintas visíveis no contrato.

### UseCases concretos exporão a capability

`CreateUserUseCase`, `GetAllUsersUseCase`, `GetUserUseCase`, `GetUserByEmailUseCase`, `UpdateUserUseCase` e `DeleteUserUseCase` serão classes concretas com `UserRepository` injetado como `$repository`, seguindo `.ai/guidelines/application.md`. Nenhuma interface será criada para os UseCases e nenhum Service Locator será usado.

Os casos de criação e atualização farão uma verificação antecipada por e-mail para produzir uma falha compreensível. A atualização parcial preservará atributos omitidos, reconstruirá `UserEntity` para reaplicar invariantes e permitirá manter o próprio e-mail canônico. A restrição única no banco continuará sendo a garantia definitiva contra escritas concorrentes. Duplicidade e usuário ausente serão representados por exceções explícitas de Application, sem vazar `QueryException` ou detalhes do banco.

### A persistência reforçará a identidade canônica

A tabela `users` conterá `id`, `name`, `email`, `created_at` e `updated_at`, com índice único em `email`. `UserModel` estenderá o Model Eloquent comum, não `Authenticatable`. `EloquentUserRepository` fará o mapping para `UserEntity` e traduzirá uma violação da unicidade de e-mail para a exceção definida pela Application.

`UserServiceProvider` registrará apenas o binding arquiteturalmente relevante `UserRepository -> EloquentUserRepository`, conforme `ARCHITECTURE.md` e `.ai/guidelines/infrastructure.md`.

### O CRUD será exposto como JSON:API

Presentation seguirá `HTTP -> Form Request -> Controller -> UseCase -> Response -> HTTP`. As rotas serão `POST /api/users`, `GET /api/users`, `GET /api/users/{user}`, `PATCH /api/users/{user}` e `DELETE /api/users/{user}`. `UserResponse` estenderá o recurso JSON:API first-party do Laravel; criação retornará `201` e `Location`, exclusão retornará `204`, ausências retornarão `404`, e-mail duplicado retornará `409` e entradas inválidas retornarão `422`.

As rotas permanecerão sem autenticação nesta POC, assim como as rotas atuais de Budget. Isso disponibiliza o CRUD solicitado sem introduzir password, sessão, token ou autorização implicitamente; uma capability posterior deverá proteger essas operações antes de uso fora do ambiente previsto para a POC.

### Desenvolvimento detectará lazy loading e a collection Bruno cobrirá a API

`UserServiceProvider` chamará `Model::preventLazyLoading(! $this->app->isProduction())`. A proteção é global no Eloquent, mas será declarada pelo contexto para que sua operação em desenvolvimento não dependa acidentalmente do provider de Budget. Hoje `UserModel` não possui relações; a configuração prepara o contexto para falhar cedo quando relações futuras forem acessadas sem eager loading.

Essa proteção cobre N+1 causado por lazy loading. Loops que executem consultas explícitas continuam dependendo da captura e análise de queries do ambiente Lerd.

A pasta `bruno/User` espelhará a organização operacional existente: fluxo CRUD serial, validações de create/update, conflitos de unicidade, not-found e cleanup. IDs criados serão guardados em variáveis de runtime, e o ambiente Local fornecerá apenas `baseUrl` e um ID reservado para ausência.

## Risks / Trade-offs

- [O CRUD de User ficará acessível sem autenticação nesta POC] -> A ausência de proteção será explícita e limitada ao escopo atual; autenticação e autorização terão spec própria antes de exposição real.
- [Normalizar e-mail para minúsculas elimina distinções teóricas no local-part] -> A aplicação adotará identidade de e-mail case-insensitive de forma explícita e consistente entre Domain e banco.
- [A verificação prévia de duplicidade sofre race condition] -> O índice único será a garantia final em criação e atualização, e o Repository traduzirá o conflito concorrente para a mesma exceção da Application.
- [Atualizações concorrentes usam last-write-wins] -> O CRUD não introduzirá versionamento otimista nesta POC; uma capability que exigir detecção de edição concorrente deverá especificar versão, ETag ou outra política explícita.
- [Prevenir lazy loading não detecta todo N+1] -> O provider cobre relações Eloquent; queries explícitas repetidas devem ser observadas com `analyze_queries` e `optimize_route` no Lerd.
- [Credenciais precisarão de persistência própria no futuro] -> Essa separação preserva User como identidade e permite definir o mecanismo de autenticação sem migrar dados antecipados ou acoplar o Domain ao Laravel.

## Migration Plan

1. Criar a migration de `users` com e-mail único e sem colunas de autenticação.
2. Implementar Domain e Application sem dependências de framework.
3. Implementar Model, Repository e Service Provider em Infrastructure e registrar o provider no composition root.
4. Registrar as rotas e o tratamento de erros JSON:API no composition root.
5. Executar os testes de Domain, Application, persistência, API, bindings e fronteiras arquiteturais.
6. Em rollback, remover rotas, provider e tabela somente depois de confirmar que nenhuma capability posterior referencia usuários persistidos.

## Open Questions

Nenhuma decisão permanece aberta nesta capability. Autenticação, propriedade de Budget e propriedade de Expense serão especificadas separadamente.
