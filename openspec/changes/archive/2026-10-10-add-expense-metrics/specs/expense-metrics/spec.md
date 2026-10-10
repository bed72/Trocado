# Expense Metrics

## Purpose

Definir a consulta pessoal de valores de despesas por data de ocorrência, com total geral e distribuição por categoria para cards e gráficos customizáveis, precisão monetária e percentual, validação estrita de query, isolamento por conta, snapshot consistente e contrato JSON:API. Metrics apresenta fatos quantitativos; não interpreta hábitos, não escreve em despesas e não pressupõe que os registros cobrem todos os gastos reais da pessoa.

## Vocabulário e contrato de entrada

As duas formas abaixo são modos da mesma rota:

```http
GET /api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31
GET /api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category
```

| Termo | Significado |
| --- | --- |
| Despesa considerada | Registro existente da conta autenticada cujo `occurred_on` pertence ao intervalo efetivo. |
| Período efetivo | Par de datas civis inclusivas informado pelo cliente ou resolvido como o mês corrente inteiro. |
| Total geral | Soma exata, em centavos, de todas as despesas consideradas, incluindo `other`. |
| Total de categoria | Soma exata das despesas consideradas que têm o mesmo identificador de categoria. |
| Percentual | Participação do total da categoria no total geral, em unidades de porcentagem, com duas casas decimais. |
| Sem agrupamento | Ausência de `group_by`; resposta somente com período e total geral. |
| Agrupado | `group_by=category`; resposta com período, total geral e categorias. |
| Mês corrente | Mês da data civil de referência obtida no timezone configurado da aplicação. |

| Parâmetro | Tipo após decodificação da query | Ausência | Valores aceitos |
| --- | --- | --- | --- |
| `start_date` | Um único texto | Somente se `end_date` também estiver ausente | Data real canônica `YYYY-MM-DD`, após remover espaços externos. |
| `end_date` | Um único texto | Somente se `start_date` também estiver ausente | Data real canônica `YYYY-MM-DD` maior ou igual à inicial, após remover espaços externos. |
| `group_by` | Um único texto | Sem agrupamento | Somente `category`, após remover espaços externos. |

Nenhum outro parâmetro faz parte deste contrato. Os requisitos e cenários abaixo são normativos; exemplos de respostas com IDs ilustrativos não fixam o algoritmo do identificador.

## ADDED Requirements

### Requirement: Contexto Metrics dedicado a fatos quantitativos

O sistema MUST manter `Metrics` como bounded context responsável pela consulta de totais, agrupamentos e percentuais de despesas para consumidores que constroem cards e gráficos. MUST manter a interpretação financeira e mensagens analíticas em Insights. Metrics MUST NOT importar classes de negócio, Models, Repositories, UseCases ou Responses de Expense, Identity ou Insights. Sua Infrastructure MUST realizar a integração de leitura pelo schema compartilhado de despesas, sem criar um segundo Model Eloquent de despesa ou escrever nas tabelas consultadas. Domain MUST permanecer puro e Application MUST permanecer independente de Laravel, HTTP, ORM e implementações de Infrastructure.

#### Scenario: Consulta quantitativa independente de Insights
- **WHEN** uma conta consulta total geral ou totais por categoria
- **THEN** Metrics entrega fatos quantitativos próprios
- **AND** não chama a geração, elegibilidade, seleção ou composição de mensagens de Insights
- **AND** não precisa de quantidade mínima de lançamentos para devolver os totais existentes

#### Scenario: Integração somente de leitura
- **WHEN** Metrics calcula os valores sobre despesas existentes
- **THEN** a integração ocorre somente na Infrastructure pela leitura do schema
- **AND** nenhum registro de despesa, identidade ou configuração é criado, alterado ou excluído pela operação analítica

#### Scenario: Conceitos puros compartilhados sem duplicação
- **WHEN** Metrics e Insights precisam de centavos, períodos civis ou razões exatas
- **THEN** reutilizam os Value Objects normalizados de Core Domain
- **AND** Core não depende dos contextos consumidores nem incorpora regras editoriais ou de persistência

#### Scenario: Catálogo de categorias compartilhado
- **WHEN** Expense ou Metrics precisa reconhecer um identificador de categoria
- **THEN** reutiliza `Core\Domain\Enums\ExpenseCategoryEnum`, sem duplicar o catálogo ou importar o contexto consumidor
- **AND** os cases e identificadores persistidos permanecem iguais aos do catálogo existente
- **AND** Expense continua responsável pela categorização das despesas e Metrics apenas valida os identificadores da projeção
- **AND** as participações de Metrics são limitadas a 100%, enquanto razões de variação de Insights podem exceder esse valor

### Requirement: Uma rota GET com dois modos de consulta

O sistema MUST disponibilizar `GET /api/metrics/expenses`. A ausência de `group_by` MUST selecionar o total geral; `group_by=category` MUST selecionar total geral e distribuição por categoria. Ambos os modos MUST compartilhar as regras de período, validação, autorização, precisão e erros. O contrato MUST usar filtros na query da URL; MUST NOT exigir corpo de requisição ou o verbo HTTP `QUERY`.

#### Scenario: Consulta somente do total
- **WHEN** a conta solicita `GET /api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31`
- **THEN** a API retorna um resumo do total de outubro de 2026
- **AND** não inclui o atributo `categories`

#### Scenario: Consulta com agrupamento
- **WHEN** a conta solicita a mesma URL com `group_by=category`
- **THEN** a API retorna o resumo do total e a distribuição por categoria para o mesmo intervalo
- **AND** não exige uma segunda requisição para obter o total geral

### Requirement: Acesso autenticado e proteções existentes da API

O sistema MUST exigir autenticação válida e conta ativa nos dois modos. MUST seguir o grupo de proteções já existente para consultas analíticas autenticadas, incluindo verificação de e-mail, throttle autenticado compartilhado e extensão de sessão, sem criar políticas de acesso alternativas ou alterar suas configurações. Requisições bloqueadas pelas proteções MUST NOT executar a leitura de métricas. Os erros de acesso MUST seguir os status e documentos JSON:API existentes.

#### Scenario: Token ausente ou inválido
- **WHEN** a rota é solicitada sem autenticação válida
- **THEN** a resposta é `401` em JSON:API
- **AND** nenhuma métrica é revelada nem consulta analítica é executada

#### Scenario: Conta bloqueada ou pendente
- **WHEN** uma conta autenticada não atende à política de conta ativa
- **THEN** o middleware existente responde `403` no padrão JSON:API
- **AND** o cálculo não é executado

#### Scenario: E-mail não verificado
- **WHEN** uma conta autenticada ativa não atende à política existente de e-mail verificado
- **THEN** a consulta é bloqueada pela proteção existente
- **AND** Metrics não fornece um caminho para contornar a mesma restrição aplicada a Insights

#### Scenario: Cota autenticada esgotada
- **WHEN** a conta excede a cota compartilhada aplicável à API autenticada
- **THEN** a resposta segue o `429` JSON:API e os headers de espera existentes
- **AND** o endpoint não calcula os totais

### Requirement: Isolamento obrigatório pela conta autenticada

O sistema MUST obter o proprietário pela capacidade de identidade autenticada de Core e fornecer seu identificador explicitamente à leitura analítica. Todas as fontes que alimentam somas, categorias, percentuais ou IDs MUST considerar somente essa conta. O filtro de proprietário MUST ser aplicado antes de qualquer agregação. O sistema MUST NOT aceitar `user_id`, identificador de outra pessoa ou escopo familiar como filtro. Dados de terceiros MUST NOT participar do denominador dos percentuais, mesmo quando sua categoria ou período coincidirem.

#### Scenario: Despesas coincidentes de duas contas
- **WHEN** a conta A tem `food` de `6000` e `transport` de `4000` no período e a conta B tem `food` de `90000` no mesmo período
- **THEN** A recebe total geral `"10000"`, `food` de `"6000"` com `"60.00"` e `transport` de `"4000"` com `"40.00"`
- **AND** nenhum valor ou percentual de B afeta essa resposta

#### Scenario: Tentativa de selecionar outra conta
- **WHEN** A envia `user_id` na query, inclusive com seu próprio ID
- **THEN** a requisição recebe `422` indicando `source.parameter: "user_id"`
- **AND** o parâmetro não é usado para definir o proprietário

#### Scenario: Conta vazia diante de despesas de terceiros
- **WHEN** A não tem despesas no período e B possui despesas nele
- **THEN** A recebe total `"0"` e, no modo agrupado, `categories: []`
- **AND** a existência das despesas de B não altera o resultado

### Requirement: Período padrão como mês corrente inteiro

Quando `start_date` e `end_date` estiverem ambos ausentes, o sistema MUST resolver o primeiro e o último dia do mês corrente inteiro. MUST incluir o último dia mesmo quando ele é posterior à data atual e considerar despesas futuras já registradas dentro desse mês. O sistema MUST aplicar o mesmo período padrão com e sem `group_by=category`. MUST NOT substituir silenciosamente esse período por mês até hoje, mês anterior, últimos trinta dias ou janela de Insights.

#### Scenario: Consulta no meio de outubro sem datas
- **WHEN** a referência civil é `2026-10-09` e nenhuma data foi enviada
- **THEN** o período efetivo é `2026-10-01` a `2026-10-31`
- **AND** uma despesa existente com `occurred_on=2026-10-25` participa do total

#### Scenario: Agrupamento com período padrão
- **WHEN** a referência civil é `2026-10-09` e a query contém somente `group_by=category`
- **THEN** total e categorias usam `2026-10-01` a `2026-10-31`
- **AND** a resposta informa essas duas datas efetivas

#### Scenario: Fevereiro em ano bissexto
- **WHEN** o mês corrente é fevereiro de 2028 e as datas estão ausentes
- **THEN** o intervalo efetivo é `2028-02-01` a `2028-02-29`

#### Scenario: Fevereiro em ano não bissexto
- **WHEN** o mês corrente é fevereiro de 2027 e as datas estão ausentes
- **THEN** o intervalo efetivo é `2027-02-01` a `2027-02-28`

### Requirement: Referência do mês pelo timezone da aplicação

O sistema MUST resolver a referência civil do período padrão no timezone configurado da aplicação, uma única vez por requisição. MUST NOT usar timezone do navegador, dispositivo, query ou perfil individual. Datas explícitas e `occurred_on` MUST continuar sendo datas civis sem conversão de timezone. A resolução do período, a resposta e a identidade do recurso MUST usar a mesma referência, inclusive quando a execução atravessar a virada do mês.

#### Scenario: Instante com meses diferentes entre UTC e timezone configurado
- **WHEN** um mesmo instante corresponde a `2026-11-01` em UTC, mas ainda a `2026-10-31` no timezone configurado da aplicação
- **THEN** uma consulta sem datas usa outubro inteiro
- **AND** o mês do dispositivo do cliente não modifica esse intervalo

#### Scenario: Requisição atravessa a virada do mês
- **WHEN** a referência padrão é resolvida em outubro e a resposta termina após a virada para novembro
- **THEN** a consulta, as datas retornadas e o ID permanecem associados ao intervalo de outubro resolvido no início

### Requirement: Datas opcionais somente como par completo

O sistema MUST aceitar exatamente dois estados de presença: ambas as datas ausentes, usando o período padrão; ou ambas presentes e válidas, usando o período explícito. Apenas uma data presente MUST resultar em `422`, identificando o parâmetro complementar necessário. MUST NOT completar limites implicitamente, consultar intervalo aberto ou tratar ausência de um limite como consulta histórica ilimitada. Ausência MUST ser distinguida de presença com valor vazio ou nulo após normalização.

#### Scenario: Somente data inicial
- **WHEN** a query contém `start_date=2026-10-01` e não contém `end_date`
- **THEN** a resposta é `422` indicando `end_date`
- **AND** nenhum último dia de mês é aplicado implicitamente

#### Scenario: Somente data final
- **WHEN** a query contém `end_date=2026-10-31` e não contém `start_date`
- **THEN** a resposta é `422` indicando `start_date`
- **AND** nenhum primeiro dia de mês é aplicado implicitamente

#### Scenario: Par completo com agrupamento
- **WHEN** ambas as datas são válidas e `group_by=category` está presente
- **THEN** os dois limites explícitos são usados para o total geral e todos os itens agrupados

### Requirement: Datas reais em formato civil estrito

Cada data informada MUST representar uma data civil real no formato exato `YYYY-MM-DD`, após remoção de espaços externos. O sistema MUST validar simultaneamente o formato e a existência da data no calendário, sem correção automática. MUST rejeitar formatos locais, datas relativas, timestamps, horários, timezone e componentes sem preenchimento canônico. Uma data inválida MUST produzir `422` associado ao respectivo parâmetro, não erro de banco, normalização para outra data ou retorno zero.

#### Scenario: Formato canônico válido
- **WHEN** as datas são `2026-10-01` e `2026-10-31`
- **THEN** a validação de formato e calendário as aceita

#### Scenario: Formato brasileiro
- **WHEN** `start_date=01/10/2026`
- **THEN** a resposta é `422` indicando `start_date`

#### Scenario: Dia inexistente
- **WHEN** `end_date=2026-02-30`
- **THEN** a resposta é `422` indicando `end_date`
- **AND** o valor não é convertido para março

#### Scenario: Dia bissexto válido e inválido
- **WHEN** o cliente informa `2028-02-29` ou `2027-02-29`
- **THEN** o primeiro é uma data válida e o segundo é rejeitado com `422` no parâmetro correspondente

#### Scenario: Horário ou timezone incorporado
- **WHEN** uma data contém `2026-10-01T00:00:00Z`, `2026-10-01 12:00:00` ou um sufixo de timezone
- **THEN** o parâmetro é rejeitado com `422`

#### Scenario: Data relativa ou não canônica
- **WHEN** uma data contém `today`, `next month`, `2026-1-1` ou `2026-10-1`
- **THEN** o parâmetro é rejeitado com `422`

### Requirement: Limites inclusivos e ordem não invertida

O sistema MUST exigir `start_date <= end_date`. Quando a inicial for posterior à final, MUST responder `422` indicando `end_date`, sem inverter o intervalo automaticamente. Os dois limites MUST ser inclusivos na comparação com `occurred_on`. Datas iguais MUST ser válidas e representar somente aquele dia. MUST NOT aplicar filtros por horários artificiais que excluam parte de uma data civil.

#### Scenario: Despesas nos limites e fora deles
- **WHEN** o intervalo é `2026-10-01` a `2026-10-31` e existem despesas em `2026-09-30`, `2026-10-01`, `2026-10-31` e `2026-11-01`
- **THEN** apenas as despesas de `2026-10-01` e `2026-10-31` participam da soma

#### Scenario: Consulta de um único dia
- **WHEN** ambas as datas são `2026-10-09`
- **THEN** a consulta é válida e inclui todas as despesas da conta com `occurred_on=2026-10-09`
- **AND** exclui despesas do dia anterior e seguinte

#### Scenario: Intervalo invertido
- **WHEN** `start_date=2026-10-31` e `end_date=2026-10-01`
- **THEN** a API responde `422` indicando `end_date`
- **AND** não executa a leitura analítica nem inverte os valores

### Requirement: Intervalos explícitos futuros e sem limite arbitrário de duração

O sistema MUST aceitar intervalos explícitos passados, futuros, multimensais e multianuais que atendam às regras de data e ordem. MUST NOT impor teto de dias, meses ou anos, restringir ao mês corrente ou truncar o intervalo sem decisão posterior de produto. Datas futuras MUST considerar registros já existentes; o sistema MUST NOT projetar ou inventar despesas para preenchê-las. Ausência de teto de duração não dispensa validação de datas reais representáveis pelo contrato civil canônico.

#### Scenario: Intervalo inteiramente futuro
- **WHEN** a referência atual é outubro de 2026, o intervalo solicitado é `2027-01-01` a `2027-01-31` e existe uma despesa da conta em `2027-01-10`
- **THEN** essa despesa participa dos totais de janeiro de 2027

#### Scenario: Intervalo futuro sem registros
- **WHEN** o intervalo futuro é válido e não contém despesas existentes
- **THEN** a resposta é `200` com total `"0"`
- **AND** nenhum valor previsto é acrescentado

#### Scenario: Histórico de vários anos
- **WHEN** o cliente informa `2020-01-01` a `2026-12-31`
- **THEN** todo o intervalo válido é considerado
- **AND** a consulta não é rejeitada por ultrapassar doze meses nem limitada ao ano corrente

### Requirement: Normalização limitada a espaços externos dos valores

O sistema MUST remover espaços externos dos valores textuais antes da validação, aceitando os mesmos valores que seriam válidos sem esses espaços. MUST NOT remover espaços internos, alterar capitalização, converter formatos de data ou corrigir nomes de parâmetros para fazê-los válidos. Valores vazios ou compostos somente por espaços MUST continuar presentes e inválidos. A normalização MUST NOT transformar filtros enviados em filtros ausentes.

#### Scenario: Datas e agrupamento com espaços externos
- **WHEN** a query contém `start_date=%202026-10-01%20`, `end_date=%202026-10-31%20` e `group_by=%20category%20`
- **THEN** os valores normalizados são `2026-10-01`, `2026-10-31` e `category`
- **AND** a consulta usa o período e agrupamento explícitos

#### Scenario: Espaços internos
- **WHEN** uma data contém `2026- 10-01` ou o agrupamento contém `cate gory`
- **THEN** o parâmetro correspondente recebe `422`

#### Scenario: Valor somente com espaços
- **WHEN** `group_by=%20%20` ou uma data é composta somente por espaços
- **THEN** o parâmetro enviado recebe `422`
- **AND** não é tratado como ausente

### Requirement: Valores vazios são erros e não ativam defaults

O sistema MUST responder `422` quando qualquer um dos parâmetros permitidos estiver presente com valor vazio, inclusive após trim ou transformação de vazio em `null` por middleware. MUST NOT aplicar mês corrente a datas vazias nem interpretar `group_by=` como ausência de agrupamento. Parâmetros sem valor explícito, como `?start_date`, MUST seguir a mesma regra de vazio.

#### Scenario: Ambas as datas vazias
- **WHEN** a query contém `start_date=&end_date=`
- **THEN** a API responde `422` com erros para as datas enviadas
- **AND** não usa o mês corrente

#### Scenario: Uma data vazia e a outra válida
- **WHEN** `start_date=` e `end_date=2026-10-31`
- **THEN** a API responde `422` indicando `start_date`

#### Scenario: Agrupamento vazio
- **WHEN** a query contém `group_by=`
- **THEN** a API responde `422` indicando `group_by`
- **AND** não retorna implicitamente o modo sem agrupamento

### Requirement: Agrupamento fechado em category

O sistema MUST aceitar somente `category` como valor explícito de `group_by`. Valor ausente MUST selecionar a consulta sem agrupamento. Qualquer outro valor, inclusive outra capitalização, lista textual ou opção não implementada, MUST resultar em `422` indicando `group_by`. MUST NOT ignorar silenciosamente agrupamentos inválidos ou selecionar um agrupamento diferente.

#### Scenario: Agrupamento suportado
- **WHEN** `group_by=category`
- **THEN** a resposta contém total geral e categorias

#### Scenario: Agrupamento desconhecido
- **WHEN** `group_by=month`, `group_by=day`, `group_by=user`, `group_by=none` ou `group_by=Category`
- **THEN** a resposta é `422` indicando `group_by`

#### Scenario: Lista textual de agrupamentos
- **WHEN** `group_by=category,month`
- **THEN** a resposta é `422`
- **AND** a string não é interpretada como múltiplos agrupamentos

### Requirement: Allowlist estrita de nomes de parâmetros

O sistema MUST aceitar somente os nomes exatos `start_date`, `end_date` e `group_by`. Qualquer parâmetro adicional MUST produzir `422` com `source.parameter` correspondente, mesmo quando seus valores seriam inofensivos, vazios ou iguais ao contexto atual. MUST NOT aceitar aliases, parâmetros de paginação, moeda, timezone, proprietário, categoria individual ou opções visuais de gráfico nesta versão. A validação MUST detectar nomes desconhecidos antes que normalizações do parser possam convertê-los em nomes permitidos.

#### Scenario: Parâmetro desconhecido acompanhado de filtros válidos
- **WHEN** a query válida contém também `foo=bar`
- **THEN** a resposta é `422` indicando `foo`
- **AND** nenhum resumo parcial é devolvido

#### Scenario: Parâmetros fora do escopo
- **WHEN** a query contém `user_id`, `currency`, `timezone`, `category`, `page[size]`, `limit` ou `chart_type`
- **THEN** a resposta é `422` identificando o parâmetro não suportado

#### Scenario: Alias ou nome com capitalização diferente
- **WHEN** o cliente envia `from`, `to`, `Start_date`, `group.by` ou `start.date`
- **THEN** esses nomes são rejeitados
- **AND** não são interpretados como os parâmetros permitidos por conversão de pontos ou capitalização

### Requirement: Valores únicos e escalares sem arrays ou objetos

Cada parâmetro permitido MUST conter um único valor textual. O sistema MUST rejeitar arrays, mapas ou estruturas aninhadas com `422` associado ao filtro raiz. MUST NOT extrair o primeiro item, converter arrays em strings, aceitar bracket notation como outra sintaxe ou usar um objeto para definir o período. Valores textuais que contenham JSON MUST ser validados como texto comum e não decodificados em estruturas de filtros.

#### Scenario: Agrupamento como array
- **WHEN** a query contém `group_by[]=category`
- **THEN** a resposta é `422` indicando `group_by`
- **AND** não executa a consulta agrupada

#### Scenario: Data como array ou mapa
- **WHEN** a query contém `start_date[]=2026-10-01` ou `end_date[value]=2026-10-31`
- **THEN** a resposta é `422` indicando `start_date` ou `end_date`, respectivamente

#### Scenario: JSON textual não é um filtro composto
- **WHEN** o valor de `group_by` é o texto `{"value":"category"}`
- **THEN** a resposta é `422` indicando `group_by`

### Requirement: Parâmetros repetidos são rejeitados antes de perder multiplicidade

O sistema MUST rejeitar com `422` qualquer repetição do mesmo parâmetro na query original, inclusive valores iguais ou nomes que se tornam iguais após decodificação URL. A verificação MUST preservar informação suficiente para detectar a repetição antes que o parser selecione somente o primeiro ou último valor. MUST NOT escolher silenciosamente uma ocorrência, aceitar repetição por igualdade de valor ou permitir que um valor escalar sobrescreva estrutura inválida.

#### Scenario: Datas repetidas com valores diferentes
- **WHEN** a query contém `start_date=2026-10-01&start_date=2026-11-01&end_date=2026-11-30`
- **THEN** a resposta é `422` indicando `start_date`
- **AND** nenhuma das duas datas iniciais é escolhida

#### Scenario: Agrupamento repetido com o mesmo valor
- **WHEN** a query contém `group_by=category&group_by=category`
- **THEN** a resposta é `422` indicando `group_by`

#### Scenario: Nome repetido com encoding equivalente
- **WHEN** a query contém `start_date=2026-10-01&start%5Fdate=2026-10-01&end_date=2026-10-31`
- **THEN** a resposta é `422` indicando `start_date`
- **AND** a codificação do nome não permite contornar a unicidade

#### Scenario: Estrutura inválida sobrescrita por escalar
- **WHEN** a query contém `group_by[]=category&group_by=category`
- **THEN** a resposta é `422` indicando `group_by`
- **AND** a última ocorrência escalar não torna a consulta válida

### Requirement: Validação independente de despesas existentes

O sistema MUST validar os filtros antes de executar a leitura analítica e independentemente de existir alguma despesa da conta. Uma consulta inválida MUST resultar em `422`, nunca em `200` com zero ou lista vazia. O sistema MUST NOT consultar despesas para decidir se o contrato de filtros será aplicado. Proteções de autenticação e acesso existentes MUST continuar precedendo a exposição de resultados da operação.

#### Scenario: Conta vazia com intervalo invertido
- **WHEN** a conta não possui despesas e envia um intervalo invertido
- **THEN** recebe `422` indicando `end_date`
- **AND** o endpoint não executa a leitura agregada

#### Scenario: Conta vazia com agrupamento desconhecido
- **WHEN** a conta não possui despesas e envia `group_by=month`
- **THEN** recebe `422` indicando `group_by`
- **AND** não recebe resposta vazia de sucesso

### Requirement: Cálculo por occurred_on e estado atual dos registros

O sistema MUST somar somente registros existentes da conta cujo `occurred_on` esteja no intervalo inclusivo. MUST NOT usar `created_at`, `updated_at`, data de cadastro, pagamento ou vencimento para definir participação no período. MUST considerar o valor e a categoria atuais de cada registro no snapshot consultado, incluindo `other`, sem duplicar lançamentos nem excluir categorias sem regra explícita. Registros definitivamente removidos MUST NOT participar.

#### Scenario: Cadastro retroativo
- **WHEN** uma despesa cadastrada em novembro tem `occurred_on=2026-10-15`
- **THEN** ela participa de uma consulta de outubro
- **AND** não participa de novembro apenas por ter sido cadastrada nele

#### Scenario: Cadastro antigo com ocorrência futura
- **WHEN** uma despesa cadastrada em setembro tem `occurred_on=2026-10-25`
- **THEN** participa de outubro, inclusive em uma consulta feita antes do dia 25
- **AND** não participa de setembro pela data de cadastro

#### Scenario: Despesa excluída definitivamente
- **WHEN** uma despesa foi removida antes do snapshot da consulta
- **THEN** não participa do total nem de qualquer categoria

### Requirement: Total geral exato em centavos sem campo de moeda

O sistema MUST representar `total_amount` como uma string inteira decimal canônica de centavos de BRL, sem sinal positivo, separador de milhar, ponto decimal monetário ou zeros à esquerda. MUST preservar somas exatas, inclusive acima de `PHP_INT_MAX` e da precisão inteira segura de JavaScript. MUST NOT converter totais para float ou inteiro nativo quando isso causar perda de precisão, overflow ou truncamento. Zero MUST ser `"0"`. BRL MUST ser implícito no contrato; o sistema MUST NOT retornar `currency` nesta capacidade.

#### Scenario: Total monetário comum
- **WHEN** despesas consideradas somam R$ 1.234,56
- **THEN** `total_amount` é `"123456"`
- **AND** não existe campo `currency`

#### Scenario: Centavos de pequeno valor
- **WHEN** o total é de um centavo
- **THEN** `total_amount` é `"1"`, não `1`, `"0.01"` ou `"001"`

#### Scenario: Soma acima do inteiro nativo de 64 bits
- **WHEN** três despesas válidas consideradas têm `amount=4000000000000000000` cada
- **THEN** o total é exatamente `"12000000000000000000"`
- **AND** permanece uma string decimal sem notação científica ou conversão para float

### Requirement: Categorias somente com despesas e identificadores estáveis

No modo agrupado, o sistema MUST retornar um item por categoria que tenha pelo menos uma despesa considerada no período. MUST NOT adicionar categorias sem registros, duplicar categorias ou retornar rótulos traduzidos. Cada item MUST conter `category`, `total_amount` e `percentage`. `category` MUST usar o identificador persistido do catálogo compartilhado `Core\Domain\Enums\ExpenseCategoryEnum`: `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions` ou `other`. `other` MUST participar normalmente, sem ser ocultada, renomeada ou tratada como registro inválido. O total de cada categoria MUST seguir a mesma representação monetária exata do total geral.

#### Scenario: Categoria presente e categoria sem despesas
- **WHEN** o período contém duas despesas `food` e nenhuma `health`
- **THEN** `categories` contém um único item `food` com a soma das duas despesas
- **AND** não contém um item `health` com zero

#### Scenario: Other participa normalmente
- **WHEN** as únicas despesas consideradas pertencem a `other`
- **THEN** o total geral inclui todos esses valores
- **AND** o agrupamento contém `category: "other"` com participação `"100.00"`

#### Scenario: Identificador sem tradução
- **WHEN** a categoria considerada é `food`
- **THEN** o item usa `category: "food"`
- **AND** não inclui campo adicional de nome traduzido, cor ou ícone

### Requirement: Ordenação determinística por total e categoria

O sistema MUST ordenar `categories` pelo total monetário exato decrescente. Em empate de total, MUST ordenar pelo identificador de categoria em ordem alfabética crescente. MUST NOT comparar strings monetárias lexicograficamente, ordenar por percentual arredondado, ordem dos registros, rótulo traduzido ou ordem incidental do banco. A ordenação MUST permanecer determinística enquanto os fatos permanecerem iguais.

#### Scenario: Totais com quantidades diferentes de dígitos
- **WHEN** `food` soma `"10000"` e `health` soma `"900"`
- **THEN** `food` aparece antes de `health`
- **AND** o comprimento ou comparação lexical das strings não inverte a ordem numérica

#### Scenario: Empate exato
- **WHEN** `transport`, `food` e `health` somam `"5000"` cada
- **THEN** a ordem é `food`, `health`, `transport`

#### Scenario: Percentuais arredondados iguais com totais distintos
- **WHEN** duas categorias têm o mesmo percentual exibido, mas totais exatos diferentes
- **THEN** a de maior total exato aparece primeiro

### Requirement: Percentuais calculados no backend com razão exata

No modo agrupado, o sistema MUST calcular cada percentual como `total da categoria / total geral * 100`, usando os totais exatos do mesmo snapshot. MUST retornar `percentage` como string decimal com ponto e exatamente duas casas, em unidades de porcentagem: `"60.00"` significa 60%, não uma fração de 0,60. O sistema MUST aplicar half-up somente ao resultado final com duas casas e MUST NOT arredondar o numerador, denominador ou razão intermediária com float. Percentuais MUST permanecer entre `"0.00"` e `"100.00"`; uma categoria presente com participação muito pequena MUST continuar na lista mesmo se arredondar para `"0.00"`.

#### Scenario: Distribuição simples
- **WHEN** o total geral é `"100000"`, `food` soma `"60000"`, `transport` soma `"30000"` e `other` soma `"10000"`
- **THEN** os percentuais são respectivamente `"60.00"`, `"30.00"` e `"10.00"`

#### Scenario: Half-up na terceira casa decimal
- **WHEN** uma categoria soma `"16665"` em um total geral de `"100000"`
- **THEN** sua razão percentual de 16,665% é apresentada como `"16.67"`

#### Scenario: Uma única categoria
- **WHEN** somente uma categoria possui despesas consideradas
- **THEN** seu percentual é `"100.00"`

#### Scenario: Participação pequena que arredonda para zero
- **WHEN** uma categoria soma `"1"` em total geral de `"1000000"`
- **THEN** a categoria permanece com seu total `"1"` e `percentage: "0.00"`

#### Scenario: Numeradores acima do inteiro nativo
- **WHEN** totais de categoria e total geral excedem o inteiro nativo ou sua multiplicação por cem causaria overflow
- **THEN** a razão e o arredondamento permanecem exatos
- **AND** o resultado não depende de perda de precisão por float

### Requirement: Percentuais independentes sem correção artificial para cem

O sistema MUST arredondar o percentual de cada categoria independentemente. MUST NOT aumentar ou diminuir uma categoria para forçar a soma dos percentuais exibidos a 100%. A soma monetária MUST permanecer exatamente igual ao total geral, mas a soma de percentuais arredondados não tem essa garantia. O consumidor MUST poder usar os totais exatos para proporções e `percentage` para exibição.

#### Scenario: Três participações iguais
- **WHEN** existem três categorias com o mesmo total positivo
- **THEN** cada item apresenta `"33.33"`
- **AND** a soma exibida é 99,99%, sem atribuir `"33.34"` a uma categoria escolhida

#### Scenario: Soma exibida acima de cem
- **WHEN** o total é `"100000"` e quatro categorias somam `"16665"`, `"16665"`, `"16670"` e `"50000"`
- **THEN** os percentuais são `"16.67"`, `"16.67"`, `"16.67"` e `"50.00"`, cuja soma é 100,01%
- **AND** o sistema preserva os resultados individuais em vez de corrigi-los

### Requirement: Mesmo snapshot para total geral e categorias

O sistema MUST calcular total geral, totais por categoria e denominador dos percentuais sobre a mesma versão consistente de registros confirmados. No modo agrupado, a soma exata dos totais de todos os itens MUST ser igual a `total_amount`. Sob escrita concorrente, a leitura MUST observar um snapshot válido anterior ou posterior à confirmação pertinente; MUST NOT misturar total de uma versão com categorias de outra. O sistema MUST NOT bloquear escritas por locks de despesas apenas para realizar a consulta analítica.

#### Scenario: Reconciliação monetária
- **WHEN** uma consulta agrupada retorna qualquer conjunto de categorias
- **THEN** a soma exata de seus `total_amount` corresponde ao total geral retornado
- **AND** cada percentual usa esse mesmo total geral como denominador

#### Scenario: Criação concorrente
- **WHEN** uma nova despesa é confirmada enquanto a consulta agrupada está em execução
- **THEN** a resposta contém um snapshot consistente que inclui ou exclui a nova despesa
- **AND** não acrescenta seu valor somente ao total geral ou somente à categoria

#### Scenario: Recategorização concorrente
- **WHEN** uma despesa muda de categoria durante a consulta
- **THEN** seu valor aparece em exatamente uma categoria no snapshot retornado
- **AND** não é duplicado, perdido ou somado em categorias de instantes incompatíveis

### Requirement: Período vazio é sucesso com total zero

Uma consulta válida sem despesas consideradas MUST retornar HTTP `200`, um recurso de resumo e `total_amount: "0"`. MUST informar o período efetivo. No modo agrupado, MUST retornar `categories: []`; sem agrupamento, MUST omitir `categories`. MUST NOT retornar `404`, `204`, `data: null`, coleção de resumos vazia, categorias artificiais com zero ou percentual de divisão por zero. Ausência de despesas MUST NOT ocultar falhas da leitura.

#### Scenario: Consulta vazia sem agrupamento
- **WHEN** o período é válido, não contém despesas da conta e `group_by` está ausente
- **THEN** a resposta é `200` com recurso, datas efetivas e total `"0"`
- **AND** `categories` não existe nos atributos

#### Scenario: Consulta vazia agrupada
- **WHEN** o período é válido, não contém despesas da conta e `group_by=category`
- **THEN** a resposta é `200` com total `"0"` e `categories: []`
- **AND** não existe percentual `NaN`, infinito, nulo ou calculado com denominador zero

### Requirement: Resumo singular em JSON:API com período efetivo

O sistema MUST responder sucesso com HTTP `200` e `Content-Type: application/vnd.api+json`. `data` MUST ser um único objeto de recurso, não coleção, com `type: "expense-metrics"`, `id` string e `attributes` contendo `start_date`, `end_date` e `total_amount`. As datas MUST ser os limites efetivamente usados, canônicos e não nulos, inclusive quando os filtros estiverem ausentes. No modo agrupado, `attributes.categories` MUST conter a lista de objetos de categoria; esses objetos MUST ser parcelas do resumo, não recursos independentes ou relationships. Sem agrupamento, `categories` MUST estar ausente, não `null` nem `[]`.

#### Scenario: Total explícito em JSON:API
- **WHEN** a consulta explícita de outubro soma `"123456"` e não pede agrupamento
- **THEN** `data.type` é `expense-metrics` e `data.attributes` contém `start_date: "2026-10-01"`, `end_date: "2026-10-31"` e `total_amount: "123456"`
- **AND** não contém `categories` nem `currency`

#### Scenario: Resumo agrupado não é coleção de recursos
- **WHEN** a consulta pede `group_by=category`
- **THEN** `data` continua um único objeto `expense-metrics`
- **AND** os itens ficam em `data.attributes.categories`, com `category`, `total_amount` e `percentage`
- **AND** não são colocados em `included` ou em uma segunda coleção paginada

#### Scenario: Default exposto ao consumidor
- **WHEN** as datas estão ausentes e o período padrão resolvido é outubro de 2026
- **THEN** a resposta informa `start_date: "2026-10-01"` e `end_date: "2026-10-31"`
- **AND** o cliente não precisa inferir o período pelo seu próprio relógio

### Requirement: Identidade opaca e determinística do resumo

O sistema MUST derivar `id` deterministicamente da conta autenticada, período efetivo e modo de agrupamento. MUST distinguir consultas de contas, períodos ou modos diferentes. MUST NOT expor o ID bruto da conta na composição pública, depender da ordem dos parâmetros da URL, dos espaços externos, de valores calculados ou de um registro persistido. A mesma consulta efetiva MUST manter o ID quando novas despesas alterarem seus valores. Um intervalo padrão e o mesmo intervalo explícito MUST identificar o mesmo resumo quando conta e modo coincidirem. O identificador MUST NOT servir como credencial ou exigir endpoint individual de consulta.

#### Scenario: Mesma consulta repetida
- **WHEN** a mesma conta consulta duas vezes o mesmo período e agrupamento
- **THEN** o `id` é igual

#### Scenario: Valores alterados mantendo o período
- **WHEN** uma despesa confirmada altera o total do mesmo período para a mesma conta e modo
- **THEN** os valores retornados mudam e o `id` permanece igual

#### Scenario: Default e intervalo explícito equivalente
- **WHEN** uma conta consulta sem datas e depois informa exatamente as datas do mês padrão, com o mesmo agrupamento
- **THEN** ambos os recursos têm o mesmo `id`

#### Scenario: Ordem e espaços equivalentes
- **WHEN** as requisições mudam apenas a ordem dos filtros ou espaços externos aceitos nos valores
- **THEN** seus IDs são iguais para a mesma conta, período e modo efetivos

#### Scenario: Conta ou modo diferente
- **WHEN** duas contas consultam o mesmo período, ou uma conta alterna entre total simples e agrupado
- **THEN** os IDs distinguem esses resumos
- **AND** não revelam o ID bruto das contas

### Requirement: Erros de query no padrão JSON:API de Insights

Filtros inválidos MUST retornar HTTP `422` e `Content-Type: application/vnd.api+json`, com documento `errors` contendo objetos com `title: "Parâmetro inválido"`, `detail` explicativo, `status: "422"` e `source.parameter` identificando o parâmetro de query. MUST NOT usar `source.pointer` para esses erros nem retornar o envelope Laravel `message`/`errors` de campos sem conversão para JSON:API. O documento de erro MUST NOT conter um resumo de sucesso em `data`. O formato MUST seguir o tratamento de query existente em Insights sem alterar globalmente a validação de documentos JSON:API de outros endpoints.

#### Scenario: Ordem inválida com erro completo
- **WHEN** o cliente envia a data final anterior à inicial
- **THEN** o erro contém `title: "Parâmetro inválido"`, `status: "422"`, detalhe sobre a ordem e `source.parameter: "end_date"`
- **AND** a resposta HTTP tem status `422` e media type JSON:API

#### Scenario: Parâmetro estrutural inválido
- **WHEN** `group_by` chega como array
- **THEN** o erro identifica o filtro raiz `group_by` por `source.parameter`
- **AND** não usa um JSON pointer como `/group_by/0`

#### Scenario: Mais de um filtro inválido
- **WHEN** datas vazias e um parâmetro desconhecido são detectados na mesma requisição autorizada
- **THEN** os erros reportados identificam os parâmetros correspondentes dentro de `errors`
- **AND** a resposta não mistura um resultado parcial em `data`

### Requirement: Leitura sob demanda sem cache ou estado analítico persistido

O sistema MUST consultar o banco a cada requisição válida de métricas, sem cache próprio, reutilização das páginas de Expense, tabela de resumos, materialização persistida, fila, job ou chamada externa. MUST considerar as alterações confirmadas antes do início do snapshot da nova leitura. MUST NOT congelar valores por dia, mês ou identidade do recurso. A estabilidade do ID MUST NOT ser interpretada como imutabilidade do conteúdo.

#### Scenario: Criação entre duas consultas
- **WHEN** a primeira consulta retorna `"10000"` e uma despesa de `2500` da conta é confirmada no mesmo período antes da segunda leitura
- **THEN** a segunda retorna `"12500"`
- **AND** não aguarda TTL nem invalidação de cache de páginas

#### Scenario: Edição de valor ou ocorrência
- **WHEN** uma despesa muda de valor ou é movida para fora do intervalo antes da nova leitura
- **THEN** o novo resumo reflete o valor e a participação atuais

#### Scenario: Categoria atualizada
- **WHEN** a categoria de uma despesa muda de `other` para `food` antes da nova leitura
- **THEN** a distribuição e os percentuais refletem a categoria atual
- **AND** o total geral não muda apenas por essa recategorização

#### Scenario: Exclusão confirmada
- **WHEN** uma despesa é excluída definitivamente antes da nova leitura
- **THEN** seu valor deixa de participar do resumo
- **AND** uma categoria sem outros registros desaparece da lista

### Requirement: Agregações em lote sem carregar despesas individuais

O sistema MUST executar somas e agrupamento no banco, restritos à conta e intervalo, e retornar somente a projeção necessária. MUST NOT percorrer páginas de Expense, carregar todas as despesas para somar na Application, fazer uma query por categoria ou consultar identidades para montar o resumo. A quantidade de statements analíticos MUST NOT crescer com o número de despesas ou categorias. O modo agrupado MUST obter seus fatos relacionados em uma leitura de snapshot consistente.

#### Scenario: Histórico extenso
- **WHEN** a conta solicita um intervalo de vários anos com muitas despesas
- **THEN** o banco agrega os registros elegíveis e a aplicação recebe o resumo
- **AND** não instancia uma Entity ou Model por despesa nem percorre cursores do CRUD

#### Scenario: Várias categorias
- **WHEN** o período contém todas as categorias permitidas
- **THEN** a leitura analítica agrega as categorias em lote
- **AND** não executa uma consulta adicional por categoria

### Requirement: Falhas operacionais não são resultado vazio

Quando a leitura analítica falhar, o sistema MUST responder com falha HTTP explícita e documento JSON:API conforme o tratamento existente. MUST NOT converter indisponibilidade do banco, erro SQL ou perda de precisão detectada em total zero, lista vazia ou percentuais inventados. O documento de erro MUST NOT expor SQL, credenciais ou dados de terceiros.

#### Scenario: Banco indisponível
- **WHEN** a consulta de um período válido falha por indisponibilidade do banco
- **THEN** a API retorna erro HTTP pelo tratamento existente
- **AND** não responde `200` com `total_amount: "0"`

#### Scenario: Falha de projeção exata
- **WHEN** a leitura não consegue produzir uma representação monetária íntegra
- **THEN** o endpoint falha explicitamente
- **AND** não entrega um total truncado ou aproximado

### Requirement: Dados para gráficos sem acoplamento visual ou paginação

O sistema MUST entregar fatos reutilizáveis pelo front e MUST NOT retornar configurações de biblioteca gráfica, tipo de gráfico, cores, ícones, rótulos traduzidos de categoria ou mensagens interpretativas. O resumo e sua lista de categorias MUST ser completos para o período e não paginados. O total MUST representar apenas despesas registradas no aplicativo, sem alegar cobertura de gastos externos, previsão financeira, orçamento ou economia.

#### Scenario: Mesmo resumo usado em card e gráfico
- **WHEN** o front recebe um resumo agrupado
- **THEN** pode usar `total_amount` em um card e categorias/percentuais em pizza ou barras
- **AND** escolhe apresentação e formatação sem pedir um tipo de gráfico ao backend

#### Scenario: Todas as categorias do período em uma resposta
- **WHEN** o período contém despesas em todas as categorias permitidas
- **THEN** todos os grupos presentes são retornados na mesma lista ordenada
- **AND** não existe próximo cursor ou requisito de buscar outra página para fechar o total

## Exemplos completos de resposta

Os identificadores abaixo são opacos e ilustrativos. Datas e valores demonstram o contrato; não representam dados reais do ambiente.

### Total geral explícito

```http
GET /api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31
```

```json
{
  "data": {
    "type": "expense-metrics",
    "id": "b70126d1fb8c55df5c0b4902833ceda0",
    "attributes": {
      "start_date": "2026-10-01",
      "end_date": "2026-10-31",
      "total_amount": "100000"
    }
  }
}
```

### Total e categorias

```http
GET /api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category
```

```json
{
  "data": {
    "type": "expense-metrics",
    "id": "2ac7ccefe27e36036b6a5e081a62794f",
    "attributes": {
      "start_date": "2026-10-01",
      "end_date": "2026-10-31",
      "total_amount": "100000",
      "categories": [
        { "category": "food", "total_amount": "60000", "percentage": "60.00" },
        { "category": "transport", "total_amount": "30000", "percentage": "30.00" },
        { "category": "other", "total_amount": "10000", "percentage": "10.00" }
      ]
    }
  }
}
```

### Período vazio agrupado

```json
{
  "data": {
    "type": "expense-metrics",
    "id": "2ac7ccefe27e36036b6a5e081a62794f",
    "attributes": {
      "start_date": "2026-10-01",
      "end_date": "2026-10-31",
      "total_amount": "0",
      "categories": []
    }
  }
}
```

### Erro de validação de query

```json
{
  "errors": [
    {
      "title": "Parâmetro inválido",
      "detail": "A data final deve ser igual ou posterior à data inicial.",
      "status": "422",
      "source": { "parameter": "end_date" }
    }
  ]
}
```

Todas as respostas acima usam `Content-Type: application/vnd.api+json`. Sucesso usa HTTP `200`; o exemplo de erro usa HTTP `422`. Textos de detalhe são exemplos da regra, não um catálogo novo de mensagens para outros endpoints.
