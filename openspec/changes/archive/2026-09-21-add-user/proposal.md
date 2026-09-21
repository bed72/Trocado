## Why

Budgets e futuras Expenses precisam pertencer a uma identidade estável, mas a aplicação ainda não representa usuários. Essa identidade deve existir independentemente do mecanismo de autenticação para que os contextos financeiros dependam apenas do proprietário dos dados, sem conhecer senhas, tokens, sessões ou detalhes do Laravel.

## What Changes

- Introduzir o bounded context `User` conforme as fronteiras e convenções de `ARCHITECTURE.md` e `.ai/guidelines/`.
- Representar um usuário por identidade, nome e e-mail normalizado, sem incorporar credenciais ou contratos de autenticação à entidade de domínio.
- Disponibilizar casos de uso concretos para criar, listar, consultar, atualizar e excluir usuários, além da consulta por e-mail canônico.
- Definir o contrato explícito `UserRepository` com `create`, `update`, `delete`, `all`, `findById` e `findByEmail`, usando apenas tipos de Domain/Application e sem expor Eloquent.
- Expor o CRUD de User por uma API JSON:API em `POST /api/users`, `GET /api/users`, `GET /api/users/{user}`, `PATCH /api/users/{user}` e `DELETE /api/users/{user}`.
- Persistir usuários com unicidade de e-mail garantida pelo banco em criação e atualização, traduzindo conflitos para uma falha explícita da aplicação.
- Adicionar cobertura automatizada das invariantes, dos casos de uso, do contrato de persistência, da restrição de unicidade e da API.
- Tornar explícita em desenvolvimento a prevenção de lazy loading que revela a principal fonte de queries N+1 em Eloquent.
- Adicionar uma collection Bruno completa para CRUD, validações, conflitos, not-found e cleanup de User.
- Manter autenticação, senha, token, sessão, middleware e autorização fora desta mudança.

## Capabilities

### New Capabilities

- `user`: Define a identidade local, a criação e a consulta de usuários, incluindo normalização e unicidade de e-mail e independência em relação à autenticação.

### Modified Capabilities

Nenhuma capability existente.

## Impact

- Um novo bounded context será criado em `app/User/{Domain,Application,Infrastructure,Presentation}` seguindo `Presentation -> Application -> Domain` e `Infrastructure -> Application/Domain`.
- A persistência receberá uma tabela `users`, um `UserModel`, um `EloquentUserRepository` e o binding `UserRepository -> EloquentUserRepository` em `UserServiceProvider`.
- O contrato de Repository usará operações explícitas de CRUD e não um método genérico `save`.
- O composition root registrará as rotas e os erros de User no mesmo formato JSON:API adotado pelo contexto Budget.
- `UserServiceProvider` habilitará a proteção de lazy loading fora de produção, e `bruno/User` documentará os cenários manuais executáveis.
- Nenhuma dependência nova será adicionada e nenhum mecanismo de autenticação do Laravel será configurado nesta mudança.
- Budget e Expense não serão alterados agora; mudanças de propriedade e escopo terão specs próprias depois que a identidade de User estiver disponível.
