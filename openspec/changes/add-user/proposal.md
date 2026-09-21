## Why

Budgets e futuras Expenses precisam pertencer a uma identidade estável, mas a aplicação ainda não representa usuários. Essa identidade deve existir independentemente do mecanismo de autenticação para que os contextos financeiros dependam apenas do proprietário dos dados, sem conhecer senhas, tokens, sessões ou detalhes do Laravel.

## What Changes

- Introduzir o bounded context `User` conforme as fronteiras e convenções de `ARCHITECTURE.md` e `.ai/guidelines/`.
- Representar um usuário por identidade, nome e e-mail normalizado, sem incorporar credenciais ou contratos de autenticação à entidade de domínio.
- Disponibilizar um caso de uso concreto para criar usuários e consultas por identificador e e-mail.
- Definir o contrato mínimo `UserRepository` com `create`, `findById` e `findByEmail`, usando apenas tipos de Domain/Application e sem expor Eloquent.
- Persistir usuários com unicidade de e-mail garantida pelo banco e traduzir conflitos para uma falha explícita da aplicação.
- Adicionar cobertura automatizada das invariantes, do caso de uso, do contrato de persistência e da restrição de unicidade.
- Manter autenticação, senha, token, sessão, middleware e autorização fora desta mudança.

## Capabilities

### New Capabilities

- `user`: Define a identidade local, a criação e a consulta de usuários, incluindo normalização e unicidade de e-mail e independência em relação à autenticação.

### Modified Capabilities

Nenhuma capability existente.

## Impact

- Um novo bounded context será criado em `app/User/{Domain,Application,Infrastructure}` seguindo `Presentation -> Application -> Domain` e `Infrastructure -> Application/Domain`; nenhuma camada vazia será criada.
- A persistência receberá uma tabela `users`, um `UserModel`, um `EloquentUserRepository` e o binding `UserRepository -> EloquentUserRepository` em `UserServiceProvider`.
- O contrato de Repository usará `create`, conforme decidido para esta capability, e não um método genérico `save`.
- Nenhuma dependência nova será adicionada e nenhum mecanismo de autenticação do Laravel será configurado nesta mudança.
- Budget e Expense não serão alterados agora; mudanças de propriedade e escopo terão specs próprias depois que a identidade de User estiver disponível.
