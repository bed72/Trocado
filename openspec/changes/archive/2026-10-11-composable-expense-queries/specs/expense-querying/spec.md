## ADDED Requirements

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
`sort` MUST aceitar de um a três campos distintos entre `occurred_on`, `amount` e `description`, separados por vírgula e aplicados na ordem informada. Prefixo `-` MUST significar decrescente; ausência do prefixo MUST significar crescente. ID decrescente MUST ser acrescentado como desempate final. Campo desconhecido, duplicado, vazio ou estrutura inválida MUST produzir `422`. Sem `sort`, MUST preservar `occurred_on DESC, id DESC`. Ordenação por descrição MUST preservar o contrato opcional/nullable, ignorar maiúsculas/minúsculas e acentos com collation explícita ICU `und-u-ks-level1`, não determinística, e preservar o texto original. Null MUST ser representado como string vazia somente na chave interna de ordenação/cursor, sem reescrita na persistência ou resposta; esse grupo MUST preceder os textos em ordem crescente e sucedê-los em decrescente. Descrições equivalentes MUST empatar nesse critério, incluindo formas Unicode canonicamente equivalentes; critérios seguintes e ID decrescente MUST resolver o empate, sem desempate intermediário por bytes ou grafia original. Ordenação e comparações de posição do cursor MUST usar a mesma collation, sem depender da collation padrão do banco.

#### Scenario: Data e valor com prioridade
- **WHEN** o cliente envia `sort=-occurred_on,amount`
- **THEN** a consulta ordena pela ocorrência mais recente, depois menor valor e finalmente ID decrescente

#### Scenario: Ordenações simples nos dois sentidos
- **WHEN** o cliente seleciona data crescente/decrescente ou valor crescente/decrescente
- **THEN** recebe respectivamente mais antigas/mais recentes ou menor/maior valor primeiro, com ID decrescente nos empates

#### Scenario: Descrição alfabética e desempate
- **WHEN** o cliente seleciona `description` ou `-description` e as descrições são `Aluguel` e `Mercado`
- **THEN** recebe respectivamente Aluguel antes de Mercado ou Mercado antes de Aluguel
- **AND** descrições equivalentes pela política aprovada são desempatadas pelos próximos critérios e pelo ID

#### Scenario: Maiúsculas e acentos equivalentes nas duas direções
- **WHEN** despesas têm descrições `Água` (ID 11), `agua` (ID 12), `ÁGUA` (ID 13), `Aluguel` (ID 14) e `Mercado` (ID 15), e o cliente usa `sort=description`
- **THEN** recebe os IDs 13, 12, 11, 14, 15
- **AND** com `sort=-description` recebe os IDs 15, 14, 13, 12, 11, conservando ID decrescente dentro do grupo equivalente
- **AND** cada recurso mantém sua descrição original

#### Scenario: Cedilha e acentos não criam grupos distintos
- **WHEN** despesas têm descrições `Açaí` (ID 21), `acai` (ID 22), `ACAI` (ID 23) e `Banana` (ID 24)
- **THEN** `sort=description` retorna os IDs 23, 22, 21, 24 e `sort=-description` retorna os IDs 24, 23, 22, 21

#### Scenario: Próximo critério precede ID no empate alfabético
- **WHEN** despesas têm `Água` com amount 2000 e ID 31, `agua` com amount 1000 e ID 32, e `ÁGUA` com amount 1000 e ID 33
- **THEN** `sort=description,amount` e `sort=-description,amount` retornam os IDs 33, 32, 31
- **AND** `sort=description,-amount` retorna os IDs 31, 33, 32

#### Scenario: Representações Unicode equivalentes
- **WHEN** duas descrições diferem somente por `Á` pré-composto (U+00C1) ou A seguido de acento combinante (U+0041 U+0301)
- **THEN** empatam no critério description e são resolvidas pelos critérios seguintes e ID decrescente
- **AND** o texto não é normalizado ou reescrito na persistência ou resposta pela ordenação

#### Scenario: Cursor atravessa empate alfabético
- **WHEN** a consulta do cenário de maiúsculas e acentos equivalentes usa page[size]=2, em qualquer direção de description, e segue next até o fim e prev de volta em dados estáveis
- **THEN** percorre exatamente a ordem esperada daquela direção sem omitir ou repetir IDs entre páginas
- **AND** voltar à primeira página devolve os mesmos IDs e descrições originais

#### Scenario: Descrições nullable conservam dados e paginação
- **WHEN** despesas têm description null (ID 41), string vazia (ID 42) e `Água` (ID 43)
- **THEN** `sort=description` retorna os IDs 42, 41, 43 e `sort=-description` retorna os IDs 43, 42, 41
- **AND** com page[size]=1 a navegação next/prev mantém essa ordem sem omissões ou repetições
- **AND** as descrições na persistência e resposta continuam respectivamente null, string vazia e `Água`

#### Scenario: Ordenação inválida
- **WHEN** o cliente envia `sort=amount,-amount`, `sort=user_id`, `sort=amount,` ou array em sort
- **THEN** a API responde `422`, sem aplicar ordenação parcial

### Requirement: Query Builder nativo confinado à Infrastructure
O sistema MUST compor filtros e ordenações com o Query Builder nativo do Laravel por meio de Eloquent em Expense Infrastructure, sem dependência adicional. Domain e Application MUST NOT depender de Request, Eloquent, Query Builder ou Service Locator. `GetAllExpenseInput` MUST ser final readonly, constructor-only, tipado e próprio da Application de Expense. O UseCase MUST obter o proprietário por UserPort e passá-lo com a entrada ao ExpenseRepository. O Repository Eloquent MUST iniciar uma query restrita ao proprietário e aplicar critérios explícitos validados com comparações inclusivas, categoria por conjunto e ordenação de colunas permitidas. MUST NOT construir Request interna, descobrir a requisição atual por container ou aceitar campos arbitrários do cliente como SQL.

#### Scenario: Consulta com critérios explícitos
- **WHEN** o UseCase recebe critérios de consulta válidos
- **THEN** consulta o Repository com o proprietário autenticado e uma entrada independente de framework
- **AND** Infrastructure aplica os critérios com Query Builder nativo sem construir ou consultar uma Request

#### Scenario: Parâmetros não ampliam capacidade
- **WHEN** o cliente tenta usar filtros ou ordenações fora da allowlist ou selecionar proprietário
- **THEN** recebe erro de validação e a query não amplia o escopo da conta
