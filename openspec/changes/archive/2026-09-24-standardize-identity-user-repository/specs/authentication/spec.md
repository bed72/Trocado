## MODIFIED Requirements

### Requirement: SignUp cria conta atomicamente
O sistema MUST criar nome, e-mail canônico e password hash na unidade definida por `Core` `TransactionPort`, MUST persistir o principal por `UserRepository::create`, MUST preservar a unicidade de e-mail e MUST NOT autenticar ou emitir token implicitamente.

#### Scenario: SignUp bem-sucedido
- **WHEN** nome, e-mail disponível e password confirmado são válidos
- **THEN** `SignUpUseCase` executa `UserRepository::create` dentro de `TransactionPort`
- **AND** um único registro `users` é persistido com password hash
- **AND** nenhum Personal Access Token é criado

#### Scenario: E-mail já utilizado
- **WHEN** o e-mail canônico já pertence a um User
- **THEN** responde `409` sem alterar aquele User
- **AND** não cria password ou token adicional

#### Scenario: Concorrência no mesmo e-mail
- **WHEN** dois `SignUp` concorrentes usam o mesmo e-mail canônico
- **THEN** a constraint única permite somente uma conta
- **AND** `UserRepository` traduz a tentativa conflitante para o mesmo `409`

### Requirement: Naming e cobertura
O sistema MUST usar `UserRepository` para persistência de User, `SignInPort` e `SignOutPort` para autenticação e `Core` `TransactionPort` para coordenação transacional, MUST usar a terminologia `AccessToken` para o recurso emitido pelo Sanctum e MUST cobrir os fluxos críticos automatizados.

#### Scenario: Cobertura automatizada
- **WHEN** a suíte focada é executada
- **THEN** cobre registro atômico pelo Repository, falhas genéricas, token Sanctum, expiração, SignOut seletivo e ausência de outro caminho público de criação
