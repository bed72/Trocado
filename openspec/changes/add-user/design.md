## Context

A aplicação possui apenas o bounded context `Budget` e não tem tabela, entidade ou contrato de usuário. Budgets são globais hoje, mas Budget e a futura Expense precisarão referenciar um proprietário estável antes que autenticação determine quem está executando uma requisição.

O desenho segue `ARCHITECTURE.md` e `.ai/guidelines/`: Domain permanece PHP puro, Application contém UseCases concretos e contratos independentes do ORM, Infrastructure usa Laravel/Eloquent e registra bindings, e Presentation só será criada quando existir uma entrada HTTP real. Os sufixos `Entity`, `ValueObject`, `UseCase`, `Repository`, `Model`, `Exception` e `ServiceProvider` identificam os papéis das classes.

## Goals / Non-Goals

**Goals:**

- Criar uma identidade local de User independente de autenticação.
- Proteger no Domain as invariantes de nome e e-mail.
- Criar e consultar usuários por casos de uso concretos.
- Garantir unicidade do e-mail normalizado inclusive sob concorrência.
- Definir um contrato mínimo de persistência com `create`, conforme a decisão do projeto.
- Manter tipos Laravel e Eloquent restritos à Infrastructure.

**Non-Goals:**

- Implementar registro público, login, logout, senha, hashing, token, sessão, middleware, autorização, verificação de e-mail ou recuperação de acesso.
- Fazer `UserEntity` implementar `Authenticatable` ou qualquer contrato Laravel.
- Adicionar listagem, atualização ou exclusão de usuários.
- Alterar Budget, recorrência ou implementar Expense.
- Criar uma camada `Presentation` vazia ou abstrações base/genéricas.

## Decisions

### User será um bounded context próprio

As classes serão organizadas sob `app/User/{Domain,Application,Infrastructure}`. A estrutura respeitará `Infrastructure -> Application -> Domain`; não será criada `Presentation` até uma capability HTTP exigir Controllers, Requests ou Responses.

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

    public function findById(int $id): ?UserEntity;

    public function findByEmail(EmailValueObject $email): ?UserEntity;
}
```

`create` aceitará somente uma entidade ainda sem identidade persistida e retornará a entidade persistida. Não haverá `save`, CRUD genérico, Builder, Model ou query Eloquent no contrato. O mapping simples permanecerá em `EloquentUserRepository`, como orienta `.ai/guidelines/infrastructure.md`.

Alternativa rejeitada: usar `save` para criação e futuras atualizações. Não existe requisito de atualização nesta capability, e um método mais amplo esconderia operações com semânticas e invariantes diferentes.

### UseCases concretos exporão a capability

`CreateUserUseCase`, `GetUserUseCase` e `GetUserByEmailUseCase` serão classes concretas com `UserRepository` injetado como `$repository`, seguindo `.ai/guidelines/application.md`. Nenhuma interface será criada para os UseCases e nenhum Service Locator será usado.

O caso de criação fará uma verificação antecipada por e-mail para produzir uma falha compreensível. A restrição única no banco continuará sendo a garantia definitiva contra duas criações concorrentes. Duplicidade e usuário ausente serão representados por exceções explícitas de Application, sem vazar `QueryException` ou detalhes do banco.

### A persistência reforçará a identidade canônica

A tabela `users` conterá `id`, `name`, `email`, `created_at` e `updated_at`, com índice único em `email`. `UserModel` estenderá o Model Eloquent comum, não `Authenticatable`. `EloquentUserRepository` fará o mapping para `UserEntity` e traduzirá uma violação da unicidade de e-mail para a exceção definida pela Application.

`UserServiceProvider` registrará apenas o binding arquiteturalmente relevante `UserRepository -> EloquentUserRepository`, conforme `ARCHITECTURE.md` e `.ai/guidelines/infrastructure.md`.

### Não haverá API nesta mudança

Sem autenticação ou um ator autorizado para administrar usuários, um endpoint público de criação equivaleria a decidir prematuramente o fluxo de registro. A capability será exercida inicialmente pelos UseCases e seus testes; uma spec posterior de autenticação definirá o adaptador HTTP apropriado.

## Risks / Trade-offs

- [A capability não terá entrada HTTP própria] -> Os UseCases formam uma fronteira reutilizável e serão chamados pela futura capability de autenticação; não será criada uma rota insegura apenas para completar camadas.
- [Normalizar e-mail para minúsculas elimina distinções teóricas no local-part] -> A aplicação adotará identidade de e-mail case-insensitive de forma explícita e consistente entre Domain e banco.
- [A verificação prévia de duplicidade sofre race condition] -> O índice único será a garantia final e o Repository traduzirá o conflito concorrente para a mesma exceção da Application.
- [Credenciais precisarão de persistência própria no futuro] -> Essa separação preserva User como identidade e permite definir o mecanismo de autenticação sem migrar dados antecipados ou acoplar o Domain ao Laravel.

## Migration Plan

1. Criar a migration de `users` com e-mail único e sem colunas de autenticação.
2. Implementar Domain e Application sem dependências de framework.
3. Implementar Model, Repository e Service Provider em Infrastructure e registrar o provider no composition root.
4. Executar os testes de Domain, Application, persistência, bindings e fronteiras arquiteturais.
5. Em rollback, remover o provider e a tabela somente depois de confirmar que nenhuma capability posterior referencia usuários persistidos.

## Open Questions

Nenhuma decisão permanece aberta nesta capability. Autenticação, propriedade de Budget e propriedade de Expense serão especificadas separadamente.
