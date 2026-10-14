## MODIFIED Requirements

### Requirement: Domain e Application de Identity permanecem independentes
Domain/Application MUST permanecer livres de Laravel, Illuminate, Eloquent, HTTP, Sanctum, Infrastructure e Presentation. MUST admitir o conceito puro UUIDv7 de Core e suas exceções, sem geração/clock/framework em Domain. UserEntity MUST continuar sem password hash/token/contratos framework; PasswordValueObject MUST proteger somente password transitório. UUIDs dos contratos MUST ser canônicos e não casts inteiros.

#### Scenario: Pureza das camadas internas
- **WHEN** dependências são verificadas
- **THEN** usam PHP, próprio Domain/contratos e dependências puras específicas de Core
- **AND** Auth/Eloquent/Sanctum permanecem nas bordas

#### Scenario: Principal autenticável na borda
- **WHEN** UserModel é inspecionado
- **THEN** integra Laravel/HasApiTokens e geração UUIDv7 dentro de Infrastructure
- **AND** nenhuma responsabilidade framework atravessa a Entity

### Requirement: Ports de Identity possuem responsabilidades separadas
Core Application MUST fornecer TransactionPort e UserPort compartilhados; UserPort MUST retornar somente owner UUIDv7 canônico do guard Sanctum, com erro de autenticação se ausente/inválido. Identity MUST manter SignInPort/SignOutPort para emissão/revogação atuais e capacidade de verificação distinta. Contratos MUST ser independentes do framework, com IDs string UUIDv7 e Adapters nas bordas. Criação/persistência MUST permanecer em UserRepository, não Port de CRUD. Não duplicar o Port de owner nem expor Model/token ao consumidor.

#### Scenario: Coordenação transacional
- **WHEN** o UseCase confirma passos atômicos
- **THEN** define a unidade em TransactionPort::commit
- **AND** Adapter executa transação/retry/propagação

#### Scenario: Registro pertence ao Repository
- **WHEN** SignUp registra conta
- **THEN** usa UserRepository::create na transação
- **AND** não introduz CreatePort/RegistrationAdapter

#### Scenario: Emissão de token
- **WHEN** credenciais válidas são autenticadas
- **THEN** SignInPort valida/emite PAT UUIDv7
- **AND** retorna Output com IDs canônicos sem objetos Sanctum

#### Scenario: Revogação do token atual
- **WHEN** logout autenticado é solicitado
- **THEN** SignOutPort revoga somente token atual identificado por UUIDv7
- **AND** principal/Request/Model não atravessam a Application

#### Scenario: Identificador autenticado para operações de User
- **WHEN** UseCase precisa de ownership
- **THEN** Core UserPort fornece o UUIDv7 do principal
- **AND** guard/UserModel/token não atravessam o contrato

#### Scenario: Sem principal no guard
- **WHEN** o Port não encontra principal UUIDv7 válido no Sanctum
- **THEN** falha como autenticação sem outro guard/Context fallback
