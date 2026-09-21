## ADDED Requirements

### Requirement: Convenção transversal por bounded context
Cada bounded context MUST possuir seus próprios objetos de dados da Application em `Application/Data` quando um contrato exigir agrupamento de entrada ou saída estruturada. Authentication, User e Budget MUST ser avaliados pela mesma convenção, e objetos de dados MUST NOT ser colocados em uma pasta global nem compartilhados entre contextos apenas por coincidência estrutural.

#### Scenario: Contrato composto pertence ao contexto
- **WHEN** um contrato da Application de Authentication, User ou Budget precisa de uma classe de dados
- **THEN** a classe é definida em `Application/Data` do próprio bounded context
- **AND** Infrastructure e Presentation podem depender dela sem inverter a direção arquitetural

#### Scenario: Estruturas coincidentes entre contextos
- **WHEN** dois bounded contexts possuem estruturas com os mesmos campos mas significados ou proprietários diferentes
- **THEN** cada contexto mantém seu próprio contrato
- **AND** nenhuma classe global é criada somente para eliminar duplicação estrutural

### Requirement: Inputs seletivos e coesos
Uma classe de entrada da Application MUST usar o sufixo `Input`, MUST agrupar dados que formem uma unidade conceitual e MUST melhorar a clareza ou evolução do contrato. Mais de três parâmetros relevantes MUST provocar avaliação da assinatura para adoção de um Input, mas a contagem MUST NOT impor um wrapper quando os dados não forem coesos ou quando parâmetros explícitos forem mais claros.

#### Scenario: Operação com quatro parâmetros coesos
- **WHEN** um Use Case recebe mais de três valores relevantes que descrevem uma única intenção
- **THEN** sua assinatura usa um `Input` imutável, salvo razão arquitetural explícita em contrário
- **AND** os chamadores constroem esse Input sem depender de Request ou outro objeto de framework

#### Scenario: Operação simples
- **WHEN** um contrato recebe um ou poucos parâmetros explícitos e inequívocos
- **THEN** ele mantém os parâmetros diretamente na assinatura
- **AND** nenhum Input é criado somente para uniformizar visualmente os métodos

#### Scenario: Muitos dados sem coesão
- **WHEN** uma operação possui muitos parâmetros que não formam uma unidade conceitual
- **THEN** sua responsabilidade é revisada antes de criar um Input
- **AND** o Input não é usado apenas para esconder uma assinatura excessiva

### Requirement: Outputs para saídas estruturadas
Uma classe que represente uma saída estruturada da Application MUST usar o sufixo `Output`; o sufixo `Result` MUST NOT ser usado para esse papel. Contratos públicos da Application que retornem três ou mais valores heterogêneos identificados por nome MUST retornar um Output em vez de array shape, e retornos de dois valores MUST usar Output quando os nomes forem essenciais ou os valores evoluírem como uma unidade.

#### Scenario: Saída com múltiplos campos nomeados
- **WHEN** um Use Case, Port ou Repository precisa retornar três ou mais valores heterogêneos relacionados
- **THEN** o contrato declara um tipo `Output` explícito
- **AND** consumidores acessam propriedades tipadas em vez de chaves convencionais de array

#### Scenario: Par estrutural significativo
- **WHEN** uma operação retorna dois valores cujo significado depende dos nomes ou cuja evolução é conjunta
- **THEN** o contrato pode representá-los em um Output coeso
- **AND** a decisão prioriza clareza sobre a contagem isolada

#### Scenario: Coleção homogênea
- **WHEN** um contrato retorna uma lista de Entities, Value Objects, identificadores ou outro tipo homogêneo
- **THEN** ele pode continuar retornando array com PHPDoc genérico apropriado
- **AND** nenhum Output é criado somente porque a coleção contém vários elementos

### Requirement: Forma imutável e independente de framework
Inputs e Outputs MUST ser `final`, imutáveis, constructor-only, sem setters e fortemente tipados. Eles MUST NOT conter comportamento de domínio, serialização ou formatação HTTP e MUST NOT depender de Laravel, Eloquent, Requests, Responses, Models, facades, container, Infrastructure ou SDKs concretos.

#### Scenario: Construção de classe de dados
- **WHEN** um Input ou Output é instanciado
- **THEN** todos os seus dados são fornecidos na construção e não podem ser alterados posteriormente
- **AND** seus tipos são expressos nativamente sempre que o PHP permitir

#### Scenario: Transformação para HTTP
- **WHEN** um Output precisa ser apresentado como JSON:API
- **THEN** a Response da Presentation realiza a serialização e a formatação
- **AND** o Output permanece sem conhecimento de HTTP ou JSON

#### Scenario: Dados com invariantes de domínio
- **WHEN** um dado exige validação de invariantes, igualdade semântica ou operações próprias do conceito
- **THEN** ele é representado ou reavaliado como Value Object de Domain
- **AND** um Input ou Output não absorve esse comportamento apenas para evitar um tipo de domínio

### Requirement: Retornos naturais de Repository
Repositories MUST preferir Entity, Value Object, scalar ou coleção homogênea quando esses tipos representarem naturalmente a persistência ou consulta. Um Repository MAY usar um objeto específico de `Application/Data` para uma projeção composta legítima, mas MUST NOT retornar um Output de Use Case apenas por coincidência de campos nem expor tipos de ORM ou Infrastructure.

#### Scenario: Consulta de agregado
- **WHEN** um Repository busca um agregado por identificador
- **THEN** ele retorna a Entity correspondente ou ausência tipada
- **AND** nenhum Output intermediário é criado sem informação adicional relevante

#### Scenario: Consulta projetada
- **WHEN** uma consulta legítima combina dados que não formam uma única Entity ou Value Object
- **THEN** o Repository pode retornar um objeto de dados específico da consulta
- **AND** o contrato permanece independente do ORM e não reutiliza por conveniência um Output semanticamente diferente

### Requirement: Uso de Data por Ports
Ports da Application MUST poder receber Inputs e retornar Outputs definidos pela própria Application quando esses objetos representarem o contrato da capacidade. Adapters MUST converter objetos de framework ou SDK para os tipos da Application antes de retorná-los, e um mesmo Output MUST ser reutilizado entre Port e Use Case somente quando ambos representarem exatamente a mesma saída.

#### Scenario: Adapter implementa capacidade com framework
- **WHEN** um Adapter utiliza Laravel, Eloquent, Sanctum ou outro detalhe de Infrastructure para executar um Port
- **THEN** ele converte o resultado técnico para o Output declarado pela Application
- **AND** nenhum objeto concreto do framework escapa pelo Port

#### Scenario: Port e Use Case possuem saídas diferentes
- **WHEN** o Port produz dados técnicos mais amplos ou semanticamente diferentes da saída do Use Case
- **THEN** os contratos usam objetos distintos
- **AND** o Use Case mapeia explicitamente entre eles

### Requirement: Cobertura dos bounded contexts existentes
Authentication, User e Budget MUST ser revisados durante a adoção desta convenção. A revisão MUST migrar os contratos que atendam aos critérios de Input ou Output e MUST preservar parâmetros explícitos e retornos naturais onde uma classe adicional não melhorar o contrato.

#### Scenario: Authentication retorna dados de SignIn
- **WHEN** `SignInPort` autentica credenciais e emite um token
- **THEN** ele retorna `SignInOutput` com identificador do token, identificador do usuário, token em texto puro e expiração fortemente tipados
- **AND** `SignInUseCase` e a Response HTTP consomem o mesmo Output sem acessar array shape

#### Scenario: Entradas atuais de Authentication
- **WHEN** SignIn ou SignUp recebe os parâmetros explícitos atuais
- **THEN** a convenção não exige um Input apenas para substituir duas ou três entradas claras
- **AND** dados sensíveis continuam protegidos contra exposição indevida

#### Scenario: Contratos atuais de User
- **WHEN** os Use Cases e Repositories de User são avaliados
- **THEN** parâmetros explícitos, `UserEntity`, `EmailValueObject`, scalars e listas tipadas são preservados onde representam integralmente o contrato
- **AND** nenhuma classe de dados é criada apenas para garantir que o contexto possua um Input ou Output

#### Scenario: Entradas atuais de Budget
- **WHEN** Create Budget ou Update Budget recebe quatro valores coesos da operação
- **THEN** a entrada é representada respectivamente por `CreateBudgetInput` ou `UpdateBudgetInput`
- **AND** os Use Cases continuam retornando `BudgetEntity` em vez de Outputs redundantes

#### Scenario: Retornos atuais de Budget
- **WHEN** um Use Case ou Repository de Budget retorna uma Entity, lista homogênea, identificador, contagem ou booleano suficiente
- **THEN** o retorno natural é preservado
- **AND** a convenção não alcança array shapes privados do Domain nem arrays exigidos pelas bordas do Laravel

### Requirement: Organização proporcional ao volume
Cada `Application/Data` MUST permanecer organizado pela propriedade sem introduzir hierarquias antecipadas. Subpastas por capacidade ou Use Case MAY ser criadas quando múltiplas classes relacionadas tornarem a pasta plana difícil de navegar, mas divisões genéricas por camada consumidora MUST NOT ser exigidas.

#### Scenario: Poucas classes no contexto
- **WHEN** um bounded context possui poucos Inputs e Outputs
- **THEN** as classes permanecem diretamente em `Application/Data`
- **AND** nenhuma subpasta é criada apenas para separar Input de Output

#### Scenario: Crescimento de uma capacidade
- **WHEN** uma capacidade acumula múltiplos Inputs e Outputs relacionados e a pasta plana perde clareza
- **THEN** as classes podem ser agrupadas por capacidade ou Use Case
- **AND** a reorganização preserva os mesmos limites e dependências da Application
