# user Specification

## Purpose
Definir a identidade local de User, suas invariantes, persistência e operações JSON:API, mantendo Domain e Application independentes dos detalhes de framework e autenticação.
## Requirements
### Requirement: Identidade local independente de autenticação
O sistema MUST representar `UserEntity` como uma identidade local composta por identificador persistido, nome e e-mail, sem exigir ou armazenar senha, hash, token ou contrato de autenticação. Domain e Application de User MUST permanecer independentes de Laravel, Eloquent, HTTP, Sanctum e Infrastructure. `UserModel`, por pertencer à Infrastructure, MUST implementar os contratos de autenticação Laravel e Sanctum necessários para representar essa identidade nas bordas.

#### Scenario: Usuário existe sem credenciais
- **WHEN** um User é criado com nome e e-mail válidos pela capability User
- **THEN** sua identidade é persistida sem senha conhecida, token, sessão ou outro dado de autenticação

#### Scenario: Usuário preexistente permanece sem credencial conhecida
- **WHEN** um User anterior a Authentication é migrado
- **THEN** sua identidade permanece válida mesmo sem possuir uma senha conhecida
- **AND** o backfill irrecuperável não concede acesso a terceiros

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de `UserEntity` são verificadas
- **THEN** a entidade não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure, Sanctum ou contratos de autenticação

#### Scenario: Model integra com o framework
- **WHEN** `UserModel` é inspecionado após Authentication
- **THEN** ele implementa `Authenticatable` e usa `HasApiTokens`
- **AND** essa integração não é exposta por `UserEntity` nem pelos contratos de Application

### Requirement: Nome válido
O sistema MUST remover espaços externos do nome antes de criar User e MUST rejeitar um nome que fique vazio após essa normalização ou exceda 255 caracteres.

#### Scenario: Nome com espaços externos
- **WHEN** um User é criado com o nome `  Maria Silva  `
- **THEN** o nome canônico do User é `Maria Silva`

#### Scenario: Nome vazio
- **WHEN** se tenta criar um User com nome vazio ou composto somente por espaços
- **THEN** a criação é rejeitada por uma exceção de Domain
- **AND** nenhum User é persistido

#### Scenario: Nome acima do limite
- **WHEN** se tenta criar ou atualizar um User com nome canônico acima de 255 caracteres
- **THEN** a operação é rejeitada por uma exceção de Domain
- **AND** nenhuma alteração é persistida

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
O sistema MUST permitir listar Users em ordem de identificador e consultar User por identificador e por e-mail canônico por meio de UseCases concretos. Uma identidade inexistente MUST produzir uma falha explícita da Application e MUST NOT expor Model, Builder ou consulta Eloquent.

#### Scenario: Listagem vazia
- **WHEN** nenhum User está persistido
- **THEN** a listagem retorna uma coleção vazia

#### Scenario: Listagem ordenada
- **WHEN** existem múltiplos Users persistidos
- **THEN** a listagem retorna `UserEntity` em ordem crescente de identificador

#### Scenario: Consulta por identificador existente
- **WHEN** um User é consultado por seu identificador persistido
- **THEN** o sistema retorna o `UserEntity` correspondente

#### Scenario: Consulta por e-mail normalizado
- **WHEN** um User com `maria@example.com` é consultado usando ` Maria@Example.COM `
- **THEN** o sistema retorna o mesmo `UserEntity` por meio da forma canônica do e-mail

#### Scenario: Usuário inexistente
- **WHEN** a consulta por identificador ou e-mail não encontra um User
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Atualização parcial de User
O sistema MUST permitir atualizar nome e/ou e-mail de um User existente, MUST preservar atributos omitidos e MUST reaplicar normalização, invariantes e unicidade de e-mail. A operação MUST usar `UserRepository::update` e MUST retornar a entidade persistida atualizada.

#### Scenario: Atualização de nome
- **WHEN** somente um novo nome válido é informado
- **THEN** o nome canônico é atualizado
- **AND** o e-mail existente é preservado

#### Scenario: Atualização de e-mail
- **WHEN** um novo e-mail ainda não utilizado é informado
- **THEN** o e-mail canônico é atualizado
- **AND** o nome existente é preservado

#### Scenario: Manutenção do próprio e-mail
- **WHEN** o User é atualizado com outra representação do seu próprio e-mail canônico
- **THEN** a atualização é permitida
- **AND** nenhum conflito de unicidade é produzido

#### Scenario: E-mail de outro User
- **WHEN** a atualização tenta usar o e-mail canônico de outro User
- **THEN** a atualização é rejeitada como e-mail já utilizado
- **AND** o User permanece inalterado

#### Scenario: Atualização de User inexistente
- **WHEN** se tenta atualizar um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Exclusão de User
O sistema MUST permitir excluir um User por identificador usando `UserRepository::delete`. Uma identidade inexistente MUST produzir a mesma falha explícita de User não encontrado.

#### Scenario: Exclusão bem-sucedida
- **WHEN** um User existente é excluído
- **THEN** seu registro é removido
- **AND** consultas posteriores não o encontram

#### Scenario: Exclusão de User inexistente
- **WHEN** se tenta excluir um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Contrato explícito de Repository
O sistema MUST declarar `UserRepository` na camada Application somente com `create(UserEntity): UserEntity`, `update(UserEntity): ?UserEntity`, `delete(int): bool`, `all(): array`, `findById(int): ?UserEntity` e `findByEmail(EmailValueObject): ?UserEntity`. O contrato MUST usar apenas tipos independentes do ORM, e sua implementação Eloquent MUST permanecer em Infrastructure.

#### Scenario: Fronteira independente do ORM
- **WHEN** o contrato `UserRepository` é verificado
- **THEN** seus parâmetros e retornos não incluem Model, Builder, query, facade ou outro tipo de Infrastructure

#### Scenario: Binding da implementação
- **WHEN** o container resolve `UserRepository`
- **THEN** `UserServiceProvider` fornece `EloquentUserRepository`
- **AND** nenhum Repository base ou genérico é introduzido

### Requirement: CRUD HTTP JSON:API
O sistema MUST expor o CRUD de User em `/api/users` usando Form Requests, Controllers por ação e `UserResponse`. As respostas de recurso MUST usar o tipo `users`, identificador em string, atributos `name`, `email`, `created_at` e `updated_at`, e link `self`.

#### Scenario: Criação HTTP
- **WHEN** `POST /api/users` recebe um documento JSON:API válido
- **THEN** responde `201` com o User criado
- **AND** inclui `Location` para `GET /api/users/{user}`

#### Scenario: Listagem HTTP
- **WHEN** `GET /api/users` é executado
- **THEN** responde `200` com uma coleção JSON:API

#### Scenario: Consulta HTTP
- **WHEN** `GET /api/users/{user}` referencia um User existente
- **THEN** responde `200` com o recurso JSON:API correspondente

#### Scenario: Atualização HTTP
- **WHEN** `PATCH /api/users/{user}` recebe identificador correspondente e ao menos um atributo válido
- **THEN** responde `200` com o recurso atualizado

#### Scenario: Exclusão HTTP
- **WHEN** `DELETE /api/users/{user}` referencia um User existente
- **THEN** responde `204` sem conteúdo

#### Scenario: Erros HTTP
- **WHEN** a API recebe dados inválidos, e-mail duplicado ou identificador inexistente
- **THEN** responde em JSON:API respectivamente com `422`, `409` ou `404`

### Requirement: Persistência mínima de User
O sistema MUST persistir identificador, nome, e-mail canônico, password hash e timestamps na tabela `users`. `UserModel` MUST representar essa persistência e o principal autenticável em Infrastructure sem funcionar como entidade de Domain. Tokens MUST permanecer na tabela oficial do Sanctum.

#### Scenario: Registro persistido
- **WHEN** um User é criado por `SignUp`
- **THEN** a tabela `users` contém nome, e-mail canônico, password hash e timestamps
- **AND** não contém token, remember token ou password em texto puro

#### Scenario: Mapping para o domínio
- **WHEN** `EloquentUserRepository` recupera um registro existente
- **THEN** retorna `UserEntity` sem password hash ou `UserModel`
- **AND** não expõe relações ou tipos do Sanctum fora de Infrastructure

#### Scenario: Serialização segura
- **WHEN** `UserModel` é serializado acidentalmente em uma borda Laravel
- **THEN** o atributo `password` permanece oculto
- **AND** nenhum Personal Access Token é incluído automaticamente

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio do provider do contexto User, tornando visível em desenvolvimento a principal fonte de queries N+1 relacionais. Essa proteção MUST NOT depender exclusivamente da inicialização de outro bounded context.

#### Scenario: Lazy loading em desenvolvimento
- **WHEN** `UserServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

#### Scenario: User sem relações atuais
- **WHEN** o CRUD atual lista ou consulta Users
- **THEN** nenhum relacionamento é carregado sob demanda porque `UserModel` ainda não possui relações

### Requirement: Collection Bruno de User
O sistema MUST fornecer cenários Bruno executáveis para o CRUD completo de User, validações de criação e atualização, conflitos de e-mail, recursos ausentes e cleanup dos registros criados.

#### Scenario: Fluxo CRUD manual
- **WHEN** o diretório CRUD é executado serialmente
- **THEN** o fluxo cria, consulta, atualiza, lista, exclui e confirma a ausência do mesmo User usando uma variável de runtime

#### Scenario: Cenários destrutivos com cleanup
- **WHEN** cenários de validação ou conflito criam Users auxiliares
- **THEN** a collection fornece requests finais de cleanup para removê-los
