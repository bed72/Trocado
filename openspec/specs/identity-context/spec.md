# identity-context Specification

## Purpose
Definir Identity como o único owner do lifecycle da conta, preservando as fronteiras internas, as capacidades separadas de Infrastructure e os contratos externos que não foram removidos.
## Requirements
### Requirement: Identity possui o lifecycle completo da conta
O sistema MUST organizar identidade local, registro, credencial, autenticação, access tokens e encerramento da conta no bounded context `Identity`. Após a migração, `User` e `Authentication` MUST NOT permanecer como bounded contexts separados nem manter dependências cruzadas.

#### Scenario: Estrutura consolidada
- **WHEN** a estrutura de `app` é inspecionada
- **THEN** as classes de identidade e autenticação pertencem a `app/Identity/{Domain,Application,Infrastructure,Presentation}`
- **AND** não existem diretórios de contexto `app/User` ou `app/Authentication`

#### Scenario: Um único owner da tabela users
- **WHEN** um fluxo cria, consulta, altera, autentica ou exclui uma conta
- **THEN** o fluxo atravessa contratos pertencentes a Identity
- **AND** nenhum outro contexto escreve diretamente na tabela `users`

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

### Requirement: Identity não depende de allowlist cross-context
O teste arquitetural MUST reconhecer Identity e Expense como os bounded contexts existentes e MUST NOT conceder a Identity acesso especial a outro contexto para autenticar ou persistir Users.

#### Scenario: Dependências após consolidação
- **WHEN** o teste de fronteiras é executado
- **THEN** Identity segue a matriz normal `Presentation -> Application -> Domain` e `Infrastructure -> Application/Domain`
- **AND** não existe allowlist equivalente a `Authentication Infrastructure -> App\User`

### Requirement: Contrato externo é preservado salvo criação direta de User
Identity MUST preservar os resource types `users`, `sign-ups` e `access-tokens`, os endpoints de Authentication e os endpoints GET, PATCH e DELETE de User. `POST /api/users` MUST ser removido e SignUp MUST ser o único cadastro público.

#### Scenario: Endpoint removido
- **WHEN** um cliente envia `POST /api/users`
- **THEN** a API responde `405` em JSON:API
- **AND** nenhuma identidade é criada

#### Scenario: Endpoints preservados
- **WHEN** um consumidor usa SignUp, SignIn, SignOut, GET, PATCH ou DELETE existentes
- **THEN** método, URL, route name, resource type e semântica de sucesso permanecem os mesmos
- **AND** somente os namespaces internos mudam

### Requirement: Identity coordena a verificação sem contaminar camadas internas
O sistema MUST manter `Registered`, `VerifyEmail`, `Verified`, `Notifiable`, Auth, Eloquent e Sanctum em Identity Infrastructure/Presentation. A intenção de solicitar verificação pelo SignUp MUST atravessar uma Port de capacidade própria de Identity Application, implementada por Adapter em Infrastructure; o UseCase MUST definir seu escopo transacional usando o `Core` `TransactionPort` já existente. `UserRepository` MUST continuar responsável por persistência e consultas da identidade; `SignOutPort` MUST continuar revogando apenas o token atual no SignOut. A atualização de perfil MUST conservar o e-mail e não requisitar verificação.

#### Scenario: Fronteira de SignUp
- **WHEN** o UseCase registra uma conta e solicita verificação
- **THEN** conhece somente `UserRepository`, `TransactionPort` e uma capacidade de solicitação independente do framework
- **AND** não importa classes de Laravel, Eloquent, notification, model ou SDK

#### Scenario: Escopo transacional da confirmação
- **WHEN** o UseCase confirma um link válido
- **THEN** define a unidade pelo `TransactionPort`, mantendo checagem do endereço e gravação na mesma execução
- **AND** o Repository obtém o lock e persiste a confirmação sem enviar notificações nem publicar eventos
- **AND** o UseCase agenda a publicação de `Verified` pelo mesmo Port de efeitos externos que solicita os envios, após commit somente para nova confirmação; confirmação anterior permanece idempotente

#### Scenario: Fronteira de atualização de perfil
- **WHEN** o UseCase atualiza o nome da conta
- **THEN** preserva o e-mail e seus tokens usando contratos independentes do ORM
- **AND** não requisita notificação, não alarga `SignOutPort` e não expõe método de alteração de endereço no Repository

#### Scenario: Domain não incorpora estado acidental de persistência
- **WHEN** a representação de User é inspecionada
- **THEN** `UserEntity` permanece sem Laravel, password, token e `email_verified_at` nesta mudança
- **AND** `UserStatusEnum` não ganha um estado artificial `verified`
