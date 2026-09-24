## MODIFIED Requirements

### Requirement: Ports de Identity possuem responsabilidades separadas
Core Application MUST declarar `TransactionPort` para coordenação transacional compartilhada entre contextos; Identity Application MUST declarar `SignInPort` e `SignOutPort` para autenticação com emissão de token e revogação do token atual, respectivamente. Cada Port MUST usar tipos independentes do framework e MUST possuir Adapter em Infrastructure. Criação e demais operações de persistência da identidade MUST pertencer a `UserRepository`, não a uma Port de criação.

#### Scenario: Coordenação transacional
- **WHEN** um UseCase precisa confirmar passos relacionados atomicamente
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

## REMOVED Requirements

### Requirement: CreatePort é exclusiva para criação autenticável
**Reason**: A criação persiste o mesmo agregado já consultado, atualizado e excluído pelo Repository; concentrá-la em `UserRepository` remove a exceção e o mapping duplicado.
**Migration**: Substituir `CreatePort`/`RegistrationAdapter` por `UserRepository::create`/`EloquentUserRepository`, usando `Core` `TransactionPort` em SignUp e mantendo os contratos externos atuais.
