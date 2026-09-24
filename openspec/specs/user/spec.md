# user Specification

## Purpose
Definir o recurso User dentro do bounded context Identity, suas invariantes, persistência e operações JSON:API preservadas, mantendo Domain e Application independentes dos detalhes de framework e autenticação.
## Requirements
### Requirement: Identidade local independente de autenticação
O sistema MUST representar `UserEntity` dentro de Identity Domain como uma identidade local composta por identificador persistido, `NameValueObject` e e-mail, sem armazenar password, hash ou token. Domain e Application de Identity MUST permanecer independentes de Laravel, Eloquent, HTTP, Sanctum e Infrastructure. `UserModel`, por pertencer a Identity Infrastructure, MUST implementar os contratos de autenticação Laravel e Sanctum necessários nas bordas.

#### Scenario: Entidade criada com credencial fora do Domain
- **WHEN** SignUp registra nome, e-mail e password válidos
- **THEN** `UserEntity` representa somente a identidade criada
- **AND** password hash e tokens permanecem fora da Entity

#### Scenario: Usuário preexistente permanece sem credencial conhecida
- **WHEN** um User anterior a Authentication é migrado
- **THEN** sua identidade permanece válida mesmo sem possuir uma senha conhecida
- **AND** o backfill irrecuperável não concede acesso a terceiros

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de `UserEntity` são verificadas
- **THEN** a entidade não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure, Sanctum ou contratos de autenticação

#### Scenario: Model integra com o framework
- **WHEN** `UserModel` de Identity Infrastructure é inspecionado
- **THEN** ele implementa `Authenticatable` e usa `HasApiTokens`
- **AND** essa integração não é exposta por `UserEntity` nem pelos contratos de Application

### Requirement: Nome válido
O sistema MUST representar o nome por `NameValueObject`, MUST remover whitespace externo, MUST reduzir whitespace repetido a um único espaço e MUST aceitar somente letras Unicode separadas por espaços. O nome canônico MUST conter entre 2 e 12 letras, inclusive, sem contar os espaços. `UserEntity` MUST carregar o `NameValueObject`, e a validação HTTP de SignUp e atualização MUST aplicar as mesmas regras do Domain.

#### Scenario: Whitespace é normalizado
- **WHEN** SignUp ou atualização recebe o nome `  Maria   Silva  `
- **THEN** o nome canônico é `Maria Silva`
- **AND** `UserEntity` carrega esse valor como `NameValueObject`

#### Scenario: Somente letras Unicode separadas por espaços
- **WHEN** o nome canônico contém dígito, pontuação, símbolo ou separador diferente de espaço
- **THEN** o Domain rejeita o nome
- **AND** nenhuma identidade é criada ou alterada

#### Scenario: Limites inclusivos contam somente letras
- **WHEN** o nome canônico contém 2 ou 12 letras, inclusive com espaços internos
- **THEN** o nome é aceito
- **AND** os espaços não são incluídos na contagem

#### Scenario: Nome fora do limite de letras
- **WHEN** o nome canônico contém menos de 2 ou mais de 12 letras
- **THEN** o Domain rejeita o nome
- **AND** nenhuma identidade é criada ou alterada

#### Scenario: Validação HTTP espelha o Domain
- **WHEN** SignUp ou atualização recebe um nome que o `NameValueObject` rejeitaria
- **THEN** a API responde `422` com pointer para `/data/attributes/name`
- **AND** o UseCase não persiste a entrada inválida

### Requirement: E-mail válido e canônico
O sistema MUST representar o e-mail por `EmailValueObject`, MUST remover espaços externos, MUST convertê-lo para minúsculas e MUST rejeitar valores que não sejam endereços de e-mail válidos. A mesma forma canônica MUST ser usada na criação, consulta e persistência.

#### Scenario: Normalização de e-mail
- **WHEN** um User é criado com o e-mail `  Maria.Silva@Example.COM  `
- **THEN** seu e-mail canônico é `maria.silva@example.com`

#### Scenario: E-mail inválido
- **WHEN** se tenta criar um User com um valor que não representa um endereço de e-mail válido
- **THEN** a criação é rejeitada por uma exceção de Domain
- **AND** nenhum User é persistido

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
O sistema MUST permitir atualizar nome e/ou e-mail de um User existente, MUST preservar atributos omitidos e MUST reaplicar normalização, invariantes e unicidade de e-mail. A operação MUST usar `IdentityRepository::update` e MUST retornar a entidade persistida atualizada.

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
O sistema MUST excluir uma conta existente dentro de `IdentityWritePort`, MUST remover todos os seus Personal Access Tokens antes de remover `users` por `IdentityRepository::delete` e MUST reverter ambos diante de falha. A exclusão definitiva do User MUST remover também todas as suas despesas, inclusive as que possuírem `deleted_at` preenchido, na mesma transação. Uma identidade inexistente MUST produzir a mesma falha explícita de User não encontrado.

#### Scenario: Exclusão bem-sucedida
- **WHEN** uma conta existente com múltiplos tokens é excluída
- **THEN** todos os tokens dessa identidade e seu registro `users` são removidos
- **AND** consultas e autenticação posteriores não a encontram

#### Scenario: Exclusão com despesas
- **WHEN** uma conta com despesas ativas e logicamente excluídas é removida
- **THEN** todas as despesas dessa conta são removidas definitivamente na mesma transação
- **AND** não restam despesas órfãs

#### Scenario: Falha durante exclusão
- **WHEN** a remoção da identidade falha depois da tentativa de remover tokens
- **THEN** a transação restaura os tokens e mantém o User
- **AND** mantém também todas as suas despesas

#### Scenario: Exclusão de User inexistente
- **WHEN** se tenta excluir um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Contrato explícito de Repository
O sistema MUST declarar `IdentityRepository` na camada Application somente com `update(UserEntity): ?UserEntity`, `delete(int): bool`, `all(): array`, `findById(int): ?UserEntity` e `findByEmail(EmailValueObject): ?UserEntity`. O contrato MUST usar apenas tipos independentes do ORM, MUST NOT criar contas e sua implementação Eloquent MUST permanecer em Infrastructure.

#### Scenario: Fronteira independente do ORM
- **WHEN** o contrato `IdentityRepository` é verificado
- **THEN** seus parâmetros e retornos não incluem Model, Builder, query, facade ou outro tipo de Infrastructure
- **AND** ele não possui `create`, `save` ou operação de registro

#### Scenario: Binding da implementação
- **WHEN** o container resolve `IdentityRepository`
- **THEN** `IdentityServiceProvider` fornece `EloquentIdentityRepository`
- **AND** nenhum Repository base ou genérico é introduzido

### Requirement: CRUD HTTP JSON:API
O sistema MUST expor listagem, consulta, atualização e exclusão de User em `/api/users` usando Form Requests, Controllers por ação e `UserResponse`. As respostas de recurso MUST usar o tipo `users`, identificador em string, atributos `name`, `email`, `created_at` e `updated_at`, e link `self`. A API MUST NOT expor criação por `POST /api/users`.

#### Scenario: Criação HTTP removida
- **WHEN** `POST /api/users` é executado
- **THEN** responde `405` em JSON:API
- **AND** orienta implicitamente o consumidor a usar o recurso de SignUp sem criar User

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
O sistema MUST persistir identificador, nome, e-mail canônico, password hash e timestamps na tabela `users`. `UserModel` de Identity Infrastructure MUST representar essa persistência e o principal autenticável sem funcionar como entidade de Domain. Tokens MUST permanecer na tabela oficial do Sanctum, e novas contas MUST NOT receber password aleatório de fallback.

#### Scenario: Registro persistido
- **WHEN** um User é criado por SignUp e `CreatePort`
- **THEN** a tabela `users` contém nome, e-mail canônico, password hash e timestamps
- **AND** não contém token, remember token ou password em texto puro

#### Scenario: Ausência de fallback
- **WHEN** código tenta criar `UserModel` sem password fora de `CreatePort`
- **THEN** a persistência rejeita a operação
- **AND** nenhum callback inventa uma credencial silenciosamente

#### Scenario: Mapping para o domínio
- **WHEN** `EloquentIdentityRepository` recupera um registro existente
- **THEN** retorna `UserEntity` sem password hash ou `UserModel`
- **AND** não expõe relações ou tipos do Sanctum fora de Infrastructure

#### Scenario: Serialização segura
- **WHEN** `UserModel` é serializado acidentalmente em uma borda Laravel
- **THEN** o atributo `password` permanece oculto
- **AND** nenhum Personal Access Token é incluído automaticamente

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio de `IdentityServiceProvider`, tornando visível em desenvolvimento a principal fonte de queries N+1 relacionais. `UserModel` MUST declarar `expenses()` como relação `HasMany` pelo campo `expenses.user_id`; a exclusão lógica de Expense MUST ser respeitada pela relação. Consultas de múltiplos Users que acessem despesas MUST carregar a relação antecipadamente.

#### Scenario: Lazy loading em desenvolvimento
- **WHEN** `IdentityServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

#### Scenario: Despesas de múltiplos Users carregadas em lote
- **WHEN** múltiplos Users são consultados com `expenses` carregado antecipadamente
- **THEN** cada User possui somente suas despesas ativas
- **AND** a quantidade de queries da leitura não aumenta por User

#### Scenario: Lazy loading de despesas bloqueado
- **WHEN** a relação `expenses` é acessada sem eager loading em uma coleção de Users fora de produção
- **THEN** a proteção do Eloquent sinaliza o acesso indevido

### Requirement: Collection Bruno de User
O sistema MUST fornecer cenários Bruno executáveis para consulta, atualização e exclusão de User, validações, conflitos de e-mail, recursos ausentes e cleanup. Qualquer User necessário ao setup MUST ser criado por SignUp, e a collection MUST NOT chamar `POST /api/users`.

#### Scenario: Fluxo manual sem criação direta
- **WHEN** o diretório CRUD é executado serialmente
- **THEN** o setup cria a conta por SignUp e salva seu identificador em runtime
- **AND** o fluxo consulta, atualiza, lista, exclui e confirma a ausência do mesmo User

#### Scenario: Cenários destrutivos com cleanup
- **WHEN** um cenário cria ou altera uma identidade temporária
- **THEN** a pasta documenta a ordem e o cleanup autenticado
- **AND** não persiste password ou token em arquivo versionado
