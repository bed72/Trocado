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
Core Application MUST declarar `TransactionPort` para coordenação transacional compartilhada entre contextos; Identity Application MUST declarar `SignInPort` e `SignOutPort` para autenticação com emissão de token e revogação do token atual, respectivamente, e um Port distinto para obter o identificador do principal autenticado em operações da própria conta. Cada Port MUST usar tipos independentes do framework e MUST possuir Adapter em Infrastructure. Criação e demais operações de persistência da identidade MUST pertencer a `UserRepository`, não a uma Port de criação.

#### Scenario: Coordenação transacional
- **WHEN** um UseCase precisa confirmar múltiplos passos atomicamente
- **THEN** ele define a operação completa em `TransactionPort::execute`
- **AND** o Adapter limita-se a transação, retry e propagação do resultado

#### Scenario: Registro pertence ao Repository
- **WHEN** `SignUpUseCase` registra uma nova conta
- **THEN** ele usa `UserRepository::create` dentro de `TransactionPort::execute`
- **AND** `CreatePort` e `RegistrationAdapter` não participam da criação

#### Scenario: Emissão de token
- **WHEN** credenciais válidas são autenticadas
- **THEN** `SignInPort` valida pelo provider e emite o Personal Access Token
- **AND** retorna `SignInOutput` sem expor Model, provider ou objeto Sanctum

#### Scenario: Revogação do token atual
- **WHEN** o logout é solicitado por uma requisição autenticada
- **THEN** `SignOutPort` resolve e revoga somente o token atual
- **AND** Request, principal e token Model não atravessam para a Application

#### Scenario: Identificador autenticado para operações de User
- **WHEN** um UseCase de User necessita conferir ownership
- **THEN** o Port próprio fornece apenas o ID do principal autenticado pelo guard Sanctum
- **AND** Request, guard, UserModel e token não atravessam para a Application

#### Scenario: Sem principal no guard
- **WHEN** o Port de identificação é invocado sem um User autenticado no guard Sanctum
- **THEN** falha como não autenticado sem recorrer a outro guard

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
