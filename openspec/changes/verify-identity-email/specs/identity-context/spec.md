## ADDED Requirements

### Requirement: Identity coordena a verificação sem contaminar camadas internas
O sistema MUST manter `Registered`, `VerifyEmail`, `Verified`, `Notifiable`, Auth, Eloquent e Sanctum em Identity Infrastructure/Presentation. A intenção de solicitar verificação pelo SignUp MUST atravessar uma Port de capacidade própria de Identity Application, implementada por Adapter em Infrastructure; o UseCase MUST definir seu escopo transacional usando o `Core` `TransactionPort` já existente. `UserRepository` MUST continuar responsável por persistência e consultas da identidade; `SignOutPort` MUST continuar revogando apenas o token atual no SignOut. A atualização de perfil MUST conservar o e-mail e não requisitar verificação.

#### Scenario: Fronteira de SignUp
- **WHEN** o UseCase registra uma conta e solicita verificação
- **THEN** conhece somente `UserRepository`, `TransactionPort` e uma capacidade de solicitação independente do framework
- **AND** não importa classes de Laravel, Eloquent, notification, model ou SDK

#### Scenario: Escopo transacional da confirmação
- **WHEN** o UseCase confirma um link válido
- **THEN** define a unidade pelo `TransactionPort`, mantendo checagem do endereço e gravação na mesma execução
- **AND** o Adapter obtém o lock, integra os eventos do Laravel após commit e não inicia outra transação

#### Scenario: Fronteira de atualização de perfil
- **WHEN** o UseCase atualiza o nome da conta
- **THEN** preserva o e-mail e seus tokens usando contratos independentes do ORM
- **AND** não requisita notificação, não alarga `SignOutPort` e não expõe método de alteração de endereço no Repository

#### Scenario: Domain não incorpora estado acidental de persistência
- **WHEN** a representação de User é inspecionada
- **THEN** `UserEntity` permanece sem Laravel, password, token e `email_verified_at` nesta mudança
- **AND** `UserStatusEnum` não ganha um estado artificial `verified`
