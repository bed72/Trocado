## ADDED Requirements

### Requirement: Identidade local independente de autenticação
O sistema MUST representar User como uma identidade local composta por identificador persistido, nome e e-mail, sem exigir ou armazenar senha, hash, token, sessão ou contrato de autenticação. A entidade de User MUST permanecer independente de Laravel, Eloquent, HTTP e Infrastructure, conforme `ARCHITECTURE.md` e `.ai/guidelines/domain.md`.

#### Scenario: Usuário existe sem credenciais
- **WHEN** um User é criado com nome e e-mail válidos
- **THEN** sua identidade é persistida sem senha, token, sessão ou outro dado de autenticação

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de `UserEntity` são verificadas
- **THEN** a entidade não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure ou contratos de autenticação

### Requirement: Nome válido
O sistema MUST remover espaços externos do nome antes de criar User e MUST rejeitar um nome que fique vazio após essa normalização.

#### Scenario: Nome com espaços externos
- **WHEN** um User é criado com o nome `  Maria Silva  `
- **THEN** o nome canônico do User é `Maria Silva`

#### Scenario: Nome vazio
- **WHEN** se tenta criar um User com nome vazio ou composto somente por espaços
- **THEN** a criação é rejeitada por uma exceção de Domain
- **AND** nenhum User é persistido

### Requirement: E-mail válido e canônico
O sistema MUST representar o e-mail por `EmailValueObject`, MUST remover espaços externos, MUST convertê-lo para minúsculas e MUST rejeitar valores que não sejam endereços de e-mail válidos. A mesma forma canônica MUST ser usada na criação, consulta e persistência.

#### Scenario: Normalização de e-mail
- **WHEN** um User é criado com o e-mail `  Maria.Silva@Example.COM  `
- **THEN** seu e-mail canônico é `maria.silva@example.com`

#### Scenario: E-mail inválido
- **WHEN** se tenta criar um User com um valor que não representa um endereço de e-mail válido
- **THEN** a criação é rejeitada por uma exceção de Domain
- **AND** nenhum User é persistido

### Requirement: Criação de User
O sistema MUST disponibilizar um `CreateUserUseCase` concreto que receba nome e e-mail explícitos, aplique as invariantes de Domain e persista o novo agregado por `UserRepository::create`. A operação MUST retornar o `UserEntity` com identificador e timestamps atribuídos pela persistência.

#### Scenario: Criação bem-sucedida
- **WHEN** `CreateUserUseCase` recebe um nome válido e um e-mail ainda não utilizado
- **THEN** exatamente um User é persistido pelo método `create`
- **AND** a entidade retornada possui identificador, nome e e-mail canônicos e timestamps de criação e atualização

#### Scenario: Criação não usa atualização genérica
- **WHEN** o caso de uso persiste um novo User
- **THEN** ele usa a operação explícita `UserRepository::create`
- **AND** o contrato não exige um método genérico `save`

### Requirement: Unicidade de e-mail
O sistema MUST impedir que dois Users possuam o mesmo e-mail canônico. A Application MUST apresentar uma falha explícita de e-mail já utilizado, e a persistência MUST manter uma restrição única como garantia definitiva inclusive para tentativas concorrentes.

#### Scenario: E-mail canônico duplicado
- **WHEN** existe um User com `maria@example.com` e se tenta criar outro com ` MARIA@EXAMPLE.COM `
- **THEN** a criação é rejeitada como e-mail já utilizado
- **AND** nenhum User adicional é persistido

#### Scenario: Criações concorrentes com o mesmo e-mail
- **WHEN** duas criações concorrentes tentam persistir o mesmo e-mail canônico
- **THEN** no máximo um User é persistido com esse e-mail
- **AND** a tentativa conflitante produz a mesma falha explícita de e-mail já utilizado, sem vazar uma exceção do banco

### Requirement: Consulta de User
O sistema MUST permitir consultar User por identificador e por e-mail canônico por meio de UseCases concretos. Uma identidade inexistente MUST produzir uma falha explícita da Application e MUST NOT expor Model, Builder ou consulta Eloquent.

#### Scenario: Consulta por identificador existente
- **WHEN** um User é consultado por seu identificador persistido
- **THEN** o sistema retorna o `UserEntity` correspondente

#### Scenario: Consulta por e-mail normalizado
- **WHEN** um User com `maria@example.com` é consultado usando ` Maria@Example.COM `
- **THEN** o sistema retorna o mesmo `UserEntity` por meio da forma canônica do e-mail

#### Scenario: Usuário inexistente
- **WHEN** a consulta por identificador ou e-mail não encontra um User
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Contrato mínimo de Repository
O sistema MUST declarar `UserRepository` na camada Application somente com `create(UserEntity): UserEntity`, `findById(int): ?UserEntity` e `findByEmail(EmailValueObject): ?UserEntity`. O contrato MUST usar apenas tipos independentes do ORM, e sua implementação Eloquent MUST permanecer em Infrastructure.

#### Scenario: Fronteira independente do ORM
- **WHEN** o contrato `UserRepository` é verificado
- **THEN** seus parâmetros e retornos não incluem Model, Builder, query, facade ou outro tipo de Infrastructure

#### Scenario: Binding da implementação
- **WHEN** o container resolve `UserRepository`
- **THEN** `UserServiceProvider` fornece `EloquentUserRepository`
- **AND** nenhum Repository base ou genérico é introduzido

### Requirement: Persistência mínima de User
O sistema MUST persistir somente identificador, nome, e-mail canônico e timestamps na tabela `users`. `UserModel` MUST representar a persistência em Infrastructure sem funcionar como entidade de Domain nem implementar autenticação nesta capability.

#### Scenario: Registro persistido
- **WHEN** um User é criado com sucesso
- **THEN** a tabela `users` contém seu nome, e-mail canônico e timestamps
- **AND** o registro não contém campos de senha, token, sessão ou verificação de e-mail

#### Scenario: Mapping para o domínio
- **WHEN** `EloquentUserRepository` recupera um registro existente
- **THEN** ele retorna um `UserEntity` sem expor `UserModel` fora de Infrastructure
