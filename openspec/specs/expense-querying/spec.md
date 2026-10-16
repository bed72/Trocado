# expense-querying Specification

## Purpose
Definir filtros combináveis e ordenações determinísticas da listagem de despesas próprias, com normalização civil/monetária, política alfabética explícita e Query Builder nativo confinado à Infrastructure, preservando descrição nullable.
## Requirements
### Requirement: Filtros opcionais combináveis sobre despesas próprias
`GET /api/expenses` MUST aceitar filtros opcionais em `filter` para `year`, `month`, `day`, `from`, `to`, `category`, `amount_min` e `amount_max`. Filtros distintos MUST combinar por E; categorias selecionadas MUST combinar por OU. Todos MUST ser aplicados no PostgreSQL junto ao proprietário autenticado antes da paginação. Sem filtros, MUST manter a listagem atual sem inferir período corrente. Campos desconhecidos dentro de `filter`, estruturas inválidas ou valores vazios enviados MUST produzir `422` JSON:API identificando o campo.

#### Scenario: Consulta sem filtros
- **WHEN** a conta consulta a listagem sem `filter`
- **THEN** suas despesas de todos os períodos são elegíveis, na ordem padrão e paginadas com tamanho padrão 20
- **AND** nenhum ano, mês ou dia atual é preenchido automaticamente

#### Scenario: Categoria valor e período combinados
- **WHEN** a conta informa `from=2026-09-01`, `to=2026-09-30`, `category=food,transport`, `amount_min=1000` e `amount_max=30000`
- **THEN** somente suas despesas de setembro, de alimentação ou transporte e com valor de 1000 a 30000 centavos são elegíveis
- **AND** datas e valores nos limites são incluídos

#### Scenario: Filtro inválido
- **WHEN** o cliente envia filtro desconhecido, vazio ou em estrutura incompatível
- **THEN** recebe `422` em JSON:API e o filtro não é silenciosamente ignorado

### Requirement: Períodos civis e intervalos de datas independentes
`year` MUST aceitar inteiro de 1 a 9999; `month` MUST aceitar inteiro de 1 a 12 e exigir ano; `day` MUST exigir mês e ano e formar uma data civil existente. `from` e `to` MUST aceitar datas válidas canônicas `Y-m-d`, ser independentes e inclusivos e exigir `from <= to` quando ambos presentes. A presença de qualquer limite de intervalo junto com qualquer componente ano/mês/dia MUST ser rejeitada com `422`. Todos os filtros temporais MUST usar `occurred_on`, nunca `created_at`.

#### Scenario: Ano mês e dia opcionais
- **WHEN** o cliente envia apenas ano, ano e mês ou ano mês e dia válidos
- **THEN** a consulta cobre respectivamente o ano completo, o mês completo ou o dia específico

#### Scenario: Somente início ou fim
- **WHEN** o cliente envia apenas `from=2026-09-01` ou apenas `to=2026-09-30`
- **THEN** a consulta aceita respectivamente despesas daquela data em diante ou até aquela data, inclusive

#### Scenario: Combinação incompleta conflitante ou inválida
- **WHEN** o cliente envia mês sem ano, dia sem mês/ano, `2026-02-29`, intervalo invertido ou mistura intervalo e componentes civis
- **THEN** a API responde `422` identificando o critério inválido

#### Scenario: Ocorrência diferente de cadastro
- **WHEN** uma despesa ocorrida em setembro foi cadastrada em outubro e o cliente filtra setembro
- **THEN** ela é elegível pelo período de ocorrência

### Requirement: Categorias múltiplas e valores em centavos
`filter[category]` MUST aceitar uma ou mais categorias do catálogo separadas por vírgula e normalizar duplicatas sem mudar o conjunto. Tokens vazios ou categorias desconhecidas MUST ser rejeitados. `amount_min` e `amount_max` MUST aceitar somente inteiros de 0 a 9223372036854775807 em centavos, ser opcionais independentes e inclusivos e rejeitar mínimo maior que máximo. A faixa de consulta MUST NOT alterar a invariante de amount positivo das despesas.

#### Scenario: Múltiplas categorias
- **WHEN** o cliente informa `food,transport,food`
- **THEN** despesas de food ou transport são elegíveis e a duplicata não muda o resultado

#### Scenario: Categoria inválida
- **WHEN** o cliente envia `food,,transport`, lista vazia ou categoria fora do catálogo
- **THEN** a API responde `422` sem omitir silenciosamente o item inválido

#### Scenario: Limites de valor independentes
- **WHEN** o cliente envia somente mínimo 1000 ou somente máximo 30000
- **THEN** são elegíveis respectivamente valores maiores ou iguais a 1000 ou menores ou iguais a 30000 centavos

#### Scenario: Zero e intervalo vazio
- **WHEN** o cliente informa mínimo zero ou máximo zero
- **THEN** mínimo zero não é ignorado e permite despesas positivas; máximo zero retorna coleção vazia

#### Scenario: Faixa de valor inválida
- **WHEN** há valor negativo, fracionário, acima do limite ou mínimo maior que máximo
- **THEN** a API responde `422` identificando o filtro inválido

### Requirement: Múltiplas ordenações explícitas e determinísticas
sort MUST aceitar um a três campos distintos occurred_on/amount/description, na prioridade informada; prefixo - decrescente, sem prefixo crescente, id UUIDv7 DESC sempre como desempate final. Default MUST ser occurred_on DESC/id DESC. Critério desconhecido/duplicado/vazio/estrutura inválida MUST produzir 422. Comparação UUID do sort e seek MUST ser a mesma PostgreSQL; não presumir ordem de criação/inteiro a partir do UUID. Description MUST manter nullable/texto original e equivalência de caixa/acentos/canonical Unicode por ICU und-u-ks-level1 não determinística. COALESCE vazio MUST valer somente na chave interna, precedendo texto ASC e sucedendo DESC. Próximos critérios/UUID MUST resolver empates sem critério intermediário por bytes/grafia. Cursor MUST usar a mesma collation.

Nos cenários abaixo U11...U43 são rótulos de fixtures UUIDv7 canônicas distintas, não IDs numéricos enviados à API; dentro de cada grupo, a ordem PostgreSQL de UUID é a ordem crescente dos sufixos indicados. Isso mantém exemplos legíveis sem vincular ordenação a uma sequence.

#### Scenario: Data e valor com prioridade
- **WHEN** sort=-occurred_on,amount
- **THEN** ordena ocorrência mais recente, menor valor e UUID DESC

#### Scenario: Ordenações simples nos dois sentidos
- **WHEN** data/valor é ordenado ASC ou DESC
- **THEN** mantém direção e UUID DESC nos empates

#### Scenario: Descrição alfabética e desempate
- **WHEN** descrições são Aluguel e Mercado com description/-description
- **THEN** ordena respectivamente Aluguel/Mercado ou Mercado/Aluguel
- **AND** política equivalente usa próximos critérios/UUID

#### Scenario: Maiúsculas e acentos equivalentes nas duas direções
- **WHEN** Água U11, agua U12, ÁGUA U13, Aluguel U14 e Mercado U15 são ordenadas por description
- **THEN** a ordem é U13,U12,U11,U14,U15
- **AND** -description produz U15,U14,U13,U12,U11
- **AND** os textos originais são preservados

#### Scenario: Cedilha e acentos não criam grupos distintos
- **WHEN** Açaí U21, acai U22, ACAI U23 e Banana U24 são ordenados
- **THEN** description produz U23,U22,U21,U24 e -description U24,U23,U22,U21

#### Scenario: Próximo critério precede ID no empate alfabético
- **WHEN** Água amount 2000/U31, agua 1000/U32 e ÁGUA 1000/U33 usam description,amount ou -description,amount
- **THEN** a ordem é U33,U32,U31
- **AND** description,-amount produz U31,U33,U32

#### Scenario: Representações Unicode equivalentes
- **WHEN** texto difere somente por Á pré-composto ou A+acento combinante
- **THEN** description empata e próximos critérios/UUID DESC resolvem
- **AND** texto não é reescrito

#### Scenario: Cursor atravessa empate alfabético
- **WHEN** o cenário de equivalência usa size 2 e next/prev v2 nas duas direções
- **THEN** percorre a ordem UUID esperada sem omissão/repetição
- **AND** volta à primeira página com os mesmos UUIDs/textos

#### Scenario: Descrições nullable conservam dados e paginação
- **WHEN** há null U41, vazio U42 e Água U43
- **THEN** description produz U42,U41,U43 e -description U43,U42,U41
- **AND** size 1/next/prev conserva ordem sem perdas
- **AND** dados permanecem null/vazio/Água

#### Scenario: Ordenação inválida
- **WHEN** a consulta envia `sort=amount,-amount`, `sort=user_id`, `sort=amount,` ou array
- **THEN** 422 sem ordenação parcial

### Requirement: Query Builder nativo confinado à Infrastructure
O sistema MUST compor filtros e ordenações com o Query Builder nativo do Laravel por meio de Eloquent em Expense Infrastructure, sem dependência adicional. Domain e Application MUST NOT depender de Request, Eloquent, Query Builder ou Service Locator. `GetAllExpenseInput` MUST ser final readonly, constructor-only, tipado e próprio da Application de Expense. O UseCase MUST obter o proprietário por UserPort e passá-lo com a entrada ao ExpenseRepository. O Repository Eloquent MUST iniciar uma query restrita ao proprietário e aplicar critérios explícitos validados com comparações inclusivas, categoria por conjunto e ordenação de colunas permitidas. MUST NOT construir Request interna, descobrir a requisição atual por container ou aceitar campos arbitrários do cliente como SQL.

#### Scenario: Consulta com critérios explícitos
- **WHEN** o UseCase recebe critérios de consulta válidos
- **THEN** consulta o Repository com o proprietário autenticado e uma entrada independente de framework
- **AND** Infrastructure aplica os critérios com Query Builder nativo sem construir ou consultar uma Request

#### Scenario: Parâmetros não ampliam capacidade
- **WHEN** o cliente tenta usar filtros ou ordenações fora da allowlist ou selecionar proprietário
- **THEN** recebe erro de validação e a query não amplia o escopo da conta
