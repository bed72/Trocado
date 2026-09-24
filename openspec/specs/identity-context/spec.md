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
Domain e Application de Identity MUST permanecer livres de Laravel, Illuminate, Eloquent, HTTP, Sanctum, Infrastructure e Presentation. `UserEntity` MUST continuar sem password hash, token ou contratos do framework, e `PasswordValueObject` MUST proteger apenas a regra do password em texto durante o uso transitório necessário.

#### Scenario: Pureza das camadas internas
- **WHEN** as dependências de Identity Domain e Application são verificadas
- **THEN** elas usam apenas PHP, o próprio Domain e contratos da própria Application
- **AND** Auth, Eloquent e Sanctum aparecem somente em Infrastructure ou Presentation

#### Scenario: Principal autenticável na borda
- **WHEN** `UserModel` é inspecionado
- **THEN** ele implementa o principal Laravel e usa `HasApiTokens` dentro de Identity Infrastructure
- **AND** nenhuma dessas responsabilidades é exposta por `UserEntity`

### Requirement: Ports de Identity possuem responsabilidades separadas
Identity Application MUST declarar `IdentityWritePort`, `CreatePort`, `SignInPort` e `SignOutPort`. Cada Port MUST representar somente sua capacidade nomeada, MUST usar tipos independentes do framework e MUST possuir Adapter em Infrastructure.

#### Scenario: Coordenação transacional
- **WHEN** um UseCase precisa confirmar múltiplos passos atomicamente
- **THEN** ele define a operação completa em `IdentityWritePort::execute`
- **AND** o Adapter limita-se a transação, retry e propagação do resultado

#### Scenario: Provisionamento de conta
- **WHEN** `SignUpUseCase` registra uma nova conta
- **THEN** `CreatePort` cria o principal autenticável e seu password hash como uma única capacidade
- **AND** a Port não oferece consulta, listagem, atualização ou exclusão de identidade

#### Scenario: Emissão de token
- **WHEN** credenciais válidas são autenticadas
- **THEN** `SignInPort` valida pelo provider e emite o Personal Access Token
- **AND** retorna `SignInOutput` sem expor Model, provider ou objeto Sanctum

#### Scenario: Revogação do token atual
- **WHEN** o logout é solicitado por uma requisição autenticada
- **THEN** `SignOutPort` resolve e revoga somente o token atual
- **AND** Request, principal e token Model não atravessam para a Application

### Requirement: CreatePort é exclusiva para criação autenticável
`CreatePort` MUST ser o único contrato da Application autorizado a criar uma nova linha em `users`. Ela MUST receber a identidade válida e o password transitório, MUST persistir somente o hash e MUST traduzir conflito de e-mail sem expor detalhes do banco.

#### Scenario: Registro bem-sucedido
- **WHEN** SignUp recebe nome, e-mail e password válidos
- **THEN** `CreatePort` persiste exatamente um User com password hash
- **AND** retorna `UserEntity` com identidade e timestamps sem password

#### Scenario: Concorrência de registro
- **WHEN** duas tentativas registram simultaneamente o mesmo e-mail canônico
- **THEN** a constraint única permite no máximo uma conta
- **AND** a tentativa conflitante produz a exceção de Application esperada

#### Scenario: Contrato não vira CRUD
- **WHEN** as operações de `CreatePort` são inspecionadas
- **THEN** não existem métodos de find, list, update, delete ou save genérico
- **AND** essas operações pertencem a `IdentityRepository`

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
