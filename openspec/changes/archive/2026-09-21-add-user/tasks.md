## 1. Domain de User

- [x] 1.1 Criar testes unitários para normalização, validação e igualdade de `EmailValueObject`, incluindo espaços externos, caixa e e-mails inválidos.
- [x] 1.2 Implementar `EmailValueObject` imutável em PHP puro e a exceção de Domain para e-mail inválido.
- [x] 1.3 Criar testes unitários para `UserEntity`, cobrindo nome aparado, nome vazio, ausência de credenciais e preservação de identidade e timestamps.
- [x] 1.4 Implementar `UserEntity` e a exceção de Domain para nome inválido, sem dependências de Laravel, Eloquent, HTTP, Infrastructure ou autenticação.

## 2. Application e contratos

- [x] 2.1 Definir `UserRepository` somente com `create`, `findById` e `findByEmail`, usando `UserEntity`, `EmailValueObject` e tipos primitivos independentes do ORM.
- [x] 2.2 Criar as exceções de Application para e-mail já utilizado e User não encontrado, sem importar exceções de banco ou Infrastructure.
- [x] 2.3 Criar testes unitários de `CreateUserUseCase` para sucesso, normalização, nome/e-mail inválido, duplicidade antecipada e uso exclusivo de `UserRepository::create`.
- [x] 2.4 Implementar `CreateUserUseCase` concreto com `UserRepository` injetado como `$repository`, sem interface de UseCase ou Service Locator.
- [x] 2.5 Criar testes unitários das consultas por identificador e e-mail, cobrindo resultado existente, normalização de e-mail e User não encontrado.
- [x] 2.6 Implementar `GetUserUseCase` e `GetUserByEmailUseCase` concretos sobre `UserRepository`.

## 3. Persistência Laravel

- [x] 3.1 Consultar Laravel Boost/Search Docs para as APIs da versão instalada usadas por migrations, Eloquent e tratamento de violações de unicidade.
- [x] 3.2 Criar a migration de `users` com `id`, `name`, `email` único e timestamps, sem senha, token, sessão ou verificação de e-mail.
- [x] 3.3 Criar testes de integração para criação, mapping, consultas por identificador/e-mail, forma canônica persistida e retorno de identidade e timestamps.
- [x] 3.4 Implementar `UserModel` como Model Eloquent comum e `EloquentUserRepository` com mapping simples para `UserEntity`.
- [x] 3.5 Traduzir a violação concorrente da unicidade de e-mail para a exceção de Application e testar que nenhuma exceção do banco vaza da fronteira.
- [x] 3.6 Criar `UserServiceProvider`, registrar o binding `UserRepository -> EloquentUserRepository` e adicionar o provider ao composition root.
- [x] 3.7 Criar teste do binding e ajustar os testes arquiteturais para cobrir as fronteiras do contexto `User`, sem criar Repository base, factory, seeder ou camada `Presentation` vazia.

## 4. Verificação

- [x] 4.1 Manter rastreabilidade entre cada cenário de `specs/user/spec.md` e ao menos um teste automatizado no nível mais baixo adequado.
- [x] 4.2 Executar separadamente os testes de Domain, Application, persistência, provider e arquitetura do contexto `User`.
- [x] 4.3 Executar a suíte completa para confirmar que a introdução de User não altera Budget ou suas recorrências.
- [x] 4.4 Executar `vendor/bin/pint --dirty --format agent` e repetir os testes afetados após a formatação.

## 5. CRUD de User

- [x] 5.1 Ampliar `UserRepository` e `EloquentUserRepository` com `all`, `update` e `delete`, preservando tipos independentes do ORM e traduzindo unicidade também na atualização.
- [x] 5.2 Criar `GetAllUsersUseCase`, `UpdateUserUseCase` e `DeleteUserUseCase` com testes unitários para sucesso, preservação de atributos, normalização, duplicidade e User inexistente.
- [x] 5.3 Criar `UserResponse`, Form Requests e Controllers por ação para create, list, get, update e delete.
- [x] 5.4 Registrar as rotas de `/api/users` e os erros de User no composition root com respostas JSON:API `201`, `200`, `204`, `404`, `409` e `422`.
- [x] 5.5 Criar testes de API para payloads válidos e inválidos, listagem, consulta, atualização parcial, unicidade e exclusão.
- [x] 5.6 Atualizar testes de persistência, contrato e arquitetura para a camada Presentation e as novas operações.
- [x] 5.7 Executar testes direcionados, suíte completa e `vendor/bin/pint --dirty --format agent`.

## 6. Operação e documentação

- [x] 6.1 Substituir códigos HTTP mágicos nas Controllers pelas constantes semânticas declaradas em `Symfony\Component\HttpFoundation\Response`.
- [x] 6.2 Habilitar e testar a prevenção de lazy loading no `UserServiceProvider` fora de produção.
- [x] 6.3 Criar a collection Bruno de User com CRUD, validações, conflitos, not-found e cleanup.
- [x] 6.4 Documentar detalhadamente o bounded context User no Obsidian e conectá-lo aos índices e documentos de API/operação.
