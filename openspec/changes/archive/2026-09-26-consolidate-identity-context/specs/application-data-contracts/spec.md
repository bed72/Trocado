## MODIFIED Requirements

### Requirement: Convenção transversal por bounded context
Cada bounded context MUST possuir seus próprios objetos de dados da Application em `Application/Data` quando um contrato exigir agrupamento de entrada ou saída estruturada. Identity e Expense MUST ser avaliados pela mesma convenção, e objetos de dados MUST NOT ser colocados em uma pasta global nem compartilhados entre contextos apenas por coincidência estrutural.

#### Scenario: Contrato composto pertence ao contexto
- **WHEN** um contrato da Application de Identity ou Expense precisa de uma classe de dados
- **THEN** a classe é definida em `Application/Data` do próprio bounded context
- **AND** Infrastructure e Presentation podem depender dela sem inverter a direção arquitetural

#### Scenario: Estruturas coincidentes entre contextos
- **WHEN** dois bounded contexts possuem estruturas com os mesmos campos mas significados ou proprietários diferentes
- **THEN** cada contexto mantém seu próprio contrato
- **AND** nenhuma classe global é criada somente para eliminar duplicação estrutural

### Requirement: Cobertura dos bounded contexts existentes
Identity e Expense MUST seguir esta convenção. Contratos que atendam aos critérios de Input ou Output MUST usar esses tipos, preservando parâmetros explícitos e retornos naturais onde uma classe adicional não melhorar o contrato.

#### Scenario: Identity retorna dados de SignIn
- **WHEN** `SignInPort` autentica credenciais e emite um token
- **THEN** ele retorna `SignInOutput` com identificador do token, identificador do User, token em texto puro e expiração fortemente tipados
- **AND** `SignInUseCase` e a Response HTTP consomem o mesmo Output sem acessar array shape

#### Scenario: Entradas atuais de Identity
- **WHEN** Registration, SignIn ou SignUp recebe os parâmetros explícitos atuais
- **THEN** a convenção não exige um Input apenas para substituir duas ou três entradas claras
- **AND** dados sensíveis continuam protegidos contra exposição indevida

#### Scenario: Contratos de identidade
- **WHEN** os UseCases, Ports e `IdentityRepository` são avaliados
- **THEN** parâmetros explícitos, `UserEntity`, `NameValueObject`, `EmailValueObject`, scalars e listas tipadas são preservados onde representam integralmente o contrato
- **AND** nenhuma classe de dados é criada apenas para garantir que o contexto possua um Input ou Output

#### Scenario: Entrada de criação de despesa
- **WHEN** Create Expense recebe dados coesos da operação
- **THEN** a entrada é representada por `CreateExpenseInput`
- **AND** o Use Case continua retornando `ExpenseEntity` em vez de um Output redundante
