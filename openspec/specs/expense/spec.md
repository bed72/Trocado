# expense Specification

## Purpose
Definir a criação de despesas independentes de Budget, pertencentes ao User autenticado, com invariantes de valor, data e categoria, persistência com exclusão lógica e relacionamento Eloquent protegido contra N+1.
## Requirements
### Requirement: Despesa pertence a uma identidade existente
O sistema MUST permitir criar Expense somente para o User autenticado e existente em Identity. `user_id` MUST ser definido pela identidade autenticada, MUST NOT ser escolhido pelo cliente e MUST NOT exigir Budget.

#### Scenario: Criação sem Budget
- **WHEN** um User autenticado sem Budget cria uma despesa válida
- **THEN** a despesa é vinculada ao seu identificador e persistida

#### Scenario: Tentativa de atribuição a terceiro
- **WHEN** um cliente autenticado envia `user_id` de outra pessoa na criação
- **THEN** a requisição é rejeitada como inválida
- **AND** nenhuma despesa é criada para qualquer User

#### Scenario: Identidade não autenticada ou inexistente
- **WHEN** uma criação é solicitada sem autenticação ou o User vinculado não existe mais
- **THEN** nenhuma despesa é criada
- **AND** a API responde respectivamente `401` ou uma falha explícita de identidade inexistente

### Requirement: Dados e invariantes da despesa
O sistema MUST representar `amount` como inteiro positivo em centavos de BRL, `occurred_on` como data civil sem horário, `description` como texto opcional de até 64 caracteres e `category` como um dos valores permitidos. O limite de 32 caracteres da categoria e o limite de descrição MUST ser protegidos em código, inclusive fora do transporte HTTP. Ao omitir `occurred_on`, o sistema MUST usar a data corrente no fuso configurado para a aplicação; ao omitir `description`, MUST persistir `null`.

#### Scenario: Campos mínimos
- **WHEN** um User cria uma despesa com `amount` igual a `1250` e sem data nem descrição
- **THEN** ela representa R$ 12,50, recebe a data corrente e mantém descrição nula

#### Scenario: Data informada
- **WHEN** uma despesa é criada com `occurred_on` igual a `2026-09-20`
- **THEN** o valor persistido é essa data, sem componente de horário

#### Scenario: Valor inválido
- **WHEN** `amount` é zero, negativo, fracionário ou não é um inteiro
- **THEN** a criação é rejeitada sem persistência

#### Scenario: Descrição longa
- **WHEN** a descrição excede 64 caracteres
- **THEN** a criação é rejeitada sem persistência

### Requirement: Categorias fechadas e categoria padrão
O sistema MUST aceitar somente `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions` e `other` como categorias de Expense. MUST definir `other` como categoria padrão quando o cliente omitir `category` e MUST rejeitar valores fora da lista.

#### Scenario: Categoria omitida
- **WHEN** uma despesa é criada sem categoria informada
- **THEN** a categoria persistida é `other`

#### Scenario: Categoria válida informada
- **WHEN** uma despesa é criada com `category` igual a `transport`
- **THEN** a categoria persistida é `transport`

#### Scenario: Categoria desconhecida
- **WHEN** uma despesa é criada com `category` fora da lista permitida
- **THEN** a criação é rejeitada sem persistência

### Requirement: Persistência e ciclo de vida inicial
O sistema MUST persistir despesas em `expenses` com `id` como chave primária, `user_id` obrigatório como chave estrangeira para `users`, `amount` inteiro em centavos, `occurred_on` como data, `category` obrigatória, `description` anulável, `created_at` preenchido na criação e `deleted_at` inicialmente nulo. MUST manter um índice composto em (`user_id`, `occurred_on`) e preparar exclusão lógica individual por `deleted_at`, sem exigir edição ou exclusão individual nesta mudança.

#### Scenario: Despesa persistida
- **WHEN** uma despesa válida é criada
- **THEN** recebe identificador único, timestamp de criação e `deleted_at` nulo
- **AND** a referência ao User e os campos do gasto são persistidos

#### Scenario: Consulta eficiente por proprietário e período
- **WHEN** a estrutura de persistência de Expense é criada
- **THEN** existe índice composto por `user_id` e `occurred_on`

### Requirement: Relacionamento Eloquent e prevenção de N+1
`ExpenseModel` MUST declarar `user()` como relação `BelongsTo` pelo campo `user_id`. A proteção contra lazy loading MUST permanecer ativa fora de produção. Consultas de múltiplas despesas que acessem seus Users MUST carregar a relação antecipadamente, sem uma query por despesa. O relacionamento entre Models MUST NOT introduzir dependências cross-context em Domain ou Application.

#### Scenario: Users de múltiplas despesas carregados em lote
- **WHEN** várias despesas são consultadas com a relação `user` antecipadamente carregada
- **THEN** cada despesa referencia o User correto
- **AND** a quantidade de queries da leitura não aumenta por despesa

#### Scenario: Lazy loading de User bloqueado
- **WHEN** a relação `user` é acessada sem eager loading em uma coleção de despesas fora de produção
- **THEN** a proteção do Eloquent sinaliza o acesso indevido

### Requirement: Criação HTTP JSON:API
O sistema MUST disponibilizar `POST /api/expenses` autenticado com documento JSON:API do tipo `expenses` e atributos de entrada `amount`, `occurred_on` opcional, `category` opcional e `description` opcional. MUST responder `201` com o recurso criado, identificador em string e atributos `amount`, `occurred_on`, `category`, `description` e `created_at`. Dados inválidos MUST produzir erro JSON:API `422` sem criar uma despesa.

#### Scenario: Criação autenticada
- **WHEN** `POST /api/expenses` recebe um documento válido e autenticação de User existente
- **THEN** responde `201` com a despesa pertencente a esse User
- **AND** a resposta contém a categoria informada ou `other` quando omitida

#### Scenario: Validação HTTP
- **WHEN** a requisição contém valor não positivo, data inválida, categoria desconhecida ou descrição longa
- **THEN** responde `422` em JSON:API
- **AND** nenhuma despesa é criada
