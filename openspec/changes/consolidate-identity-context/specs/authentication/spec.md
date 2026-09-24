## MODIFIED Requirements

### Requirement: Authentication respeita as fronteiras do projeto
O sistema MUST manter regras de password e orquestração nas camadas adequadas de Identity, MUST manter Domain e Application livres de Laravel e MUST limitar integrações com Auth, Eloquent e Sanctum a Identity Infrastructure ou Presentation.

#### Scenario: Fronteiras arquiteturais
- **WHEN** as dependências de Identity são verificadas
- **THEN** Domain utiliza somente tipos próprios e PHP
- **AND** Application utiliza somente seu Domain e contratos próprios
- **AND** Auth, Eloquent e Sanctum aparecem somente nas bordas permitidas

#### Scenario: Sem abstração do pacote
- **WHEN** a integração Sanctum é inspecionada
- **THEN** não existe wrapper que apenas renomeia uma única chamada de `createToken`, `currentAccessToken` ou `auth:sanctum`
- **AND** `SignInPort` e `SignOutPort` existem para preservar fronteiras reais de Application

### Requirement: UserModel é o principal autenticável
O sistema MUST usar `UserModel` de Identity Infrastructure como principal autenticável resolvido pelo Sanctum, MUST habilitá-lo com `HasApiTokens` e MUST manter `UserEntity` sem framework, password ou token.

#### Scenario: Principal resolvido pelo Sanctum
- **WHEN** uma requisição protegida é autenticada por Bearer token
- **THEN** `$request->user()` retorna o `UserModel` correspondente
- **AND** Sanctum disponibiliza o token atual

#### Scenario: Domain permanece puro
- **WHEN** `UserEntity` é inspecionada
- **THEN** ela não implementa `Authenticatable` nem usa `HasApiTokens`
- **AND** contém somente o estado de identidade definido por Identity

### Requirement: SignUp cria conta atomicamente
O sistema MUST criar nome, e-mail canônico e password hash na unidade definida por `IdentityWritePort`, MUST provisionar o principal por `CreatePort`, MUST preservar a unicidade de e-mail e MUST NOT autenticar ou emitir token implicitamente.

#### Scenario: SignUp bem-sucedido
- **WHEN** nome, e-mail disponível e password confirmado são válidos
- **THEN** `SignUpUseCase` executa `CreatePort` dentro de `IdentityWritePort`
- **AND** um único registro `users` é persistido com password hash
- **AND** nenhum Personal Access Token é criado

#### Scenario: E-mail já utilizado
- **WHEN** o e-mail canônico já pertence a um User
- **THEN** responde `409` sem alterar aquele User
- **AND** não cria password ou token adicional

#### Scenario: Concorrência no mesmo e-mail
- **WHEN** dois `SignUp` concorrentes usam o mesmo e-mail canônico
- **THEN** a constraint única permite somente uma conta
- **AND** `CreatePort` traduz a tentativa conflitante para o mesmo `409`

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio de `IdentityServiceProvider`, sem depender da inicialização de outro bounded context.

#### Scenario: Provider de Identity em desenvolvimento
- **WHEN** `IdentityServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

### Requirement: Naming e cobertura
O sistema MUST usar `CreatePort`, `SignInPort`, `SignOutPort` e `IdentityWritePort` para as capacidades próprias, MUST usar a terminologia `AccessToken` para o recurso emitido pelo Sanctum e MUST cobrir os fluxos críticos automatizados.

#### Scenario: Cobertura automatizada
- **WHEN** a suíte focada é executada
- **THEN** cobre registro atômico, falhas genéricas, token Sanctum, expiração, SignOut seletivo e remoção do caminho alternativo de criação
