# expense-suggestions Specification

## Purpose
Definir sugestões transitórias de despesas para autocomplete autenticado, com descrições únicas e ordenadas do histórico do proprietário e valor opcional exato quando todos os registros dos três meses civis anteriores forem consistentes, sem efeitos no ciclo de vida das despesas.
## Requirements
### Requirement: Consulta autenticada e isolada por proprietário

O sistema MUST disponibilizar `GET /api/expenses/suggestions`, com rota nomeada `expenses.suggestions`, no mesmo grupo de middlewares das demais rotas de Expense: autenticação Sanctum, contexto autenticado, conta ativa, e-mail verificado, rate limiting autenticado e extensão de sessão. O proprietário MUST ser obtido da identidade autenticada e aplicado no banco antes da busca, deduplicação, ordenação e agregação de valores. Dados de outras contas MUST NOT influenciar descrições, frequência, recência ou valores sugeridos. O endpoint MUST rejeitar a presença de `user_id` no cliente com `422` JSON:API.

#### Scenario: Histórico exclusivo da conta
- **WHEN** duas contas possuem despesas e uma delas consulta sugestões com token válido
- **THEN** somente seu próprio histórico produz sugestões e critérios de ordenação
- **AND** os registros da outra conta não alteram o valor sugerido nem preenchem meses ausentes

#### Scenario: Autenticação ausente ou inválida
- **WHEN** a consulta não possui Bearer token válido, incluindo token expirado ou revogado
- **THEN** a API responde `401` em JSON:API sem revelar sugestões

#### Scenario: Conta sem acesso permitido
- **WHEN** a conta autenticada está inativa ou não possui e-mail verificado
- **THEN** a consulta é recusada pelas mesmas proteções das demais rotas de Expense
- **AND** nenhum histórico é exposto

#### Scenario: Proprietário informado pelo cliente
- **WHEN** uma conta envia `user_id` na consulta, inclusive vazio ou com seu próprio identificador
- **THEN** a API responde `422` JSON:API identificando o parâmetro inválido
- **AND** não consulta sugestões com um proprietário escolhido pelo cliente

### Requirement: Entrada textual limitada e busca parcial literal

O parâmetro de query string `query` MUST ser obrigatório, escalar textual, não vazio após remoção dos espaços nas extremidades e limitado a 64 caracteres Unicode antes dessa remoção. O sistema MUST rejeitar ausência, valor vazio, somente espaços, estrutura de array ou comprimento excessivo com `422` JSON:API e erro associado ao parâmetro. O termo MUST ser tratado como texto literal, com bindings no banco, inclusive `%`, `_`, barra invertida e aspas; MUST NOT ser interpretado como wildcard ou SQL. A busca MUST localizar o termo em qualquer posição da descrição normalizada, sem diferenciar caixa. A V1 MUST preservar diferenças de acentuação e espaços internos e MUST NOT aplicar busca aproximada.

#### Scenario: Busca parcial sem diferença de caixa
- **WHEN** o histórico contém `Internet` e `Plano de Internet` e a conta consulta `query=iNt`
- **THEN** ambas as descrições são elegíveis para sugestões

#### Scenario: Termo com espaços externos
- **WHEN** a conta consulta `query= Int ` dentro do limite de comprimento
- **THEN** a busca usa `Int` como termo

#### Scenario: Entrada inválida
- **WHEN** `query` está ausente, vazio, contém somente espaços, tem mais de 64 caracteres ou é enviado como `query[]`
- **THEN** a API responde `422` JSON:API com erro associado ao parâmetro `query`
- **AND** nenhuma leitura de sugestões é executada

#### Scenario: Caracteres especiais literais
- **WHEN** a conta pesquisa um termo contendo `%`, `_`, barra invertida ou aspas
- **THEN** apenas descrições contendo literalmente o termo são elegíveis
- **AND** o termo não amplia a busca nem altera a estrutura da consulta

#### Scenario: Acentos e espaços internos preservados
- **WHEN** o histórico contém `Café` e `Plano  Internet`
- **THEN** `query=Cafe` não corresponde a `Café`
- **AND** `query=Plano Internet` não corresponde a `Plano  Internet`

### Requirement: Descrições normalizadas e únicas

O sistema MUST agrupar descrições pela mesma chave normalizada usada na busca e na análise de valor: remoção de espaços nas extremidades e conversão para caixa uniforme, sem alterar espaços internos, pontuação ou acentos. Descrições nulas, vazias ou somente com espaços MUST NOT produzir sugestões. Cada chave MUST aparecer uma única vez. A descrição exibida MUST ser a descrição sem espaços externos do registro com maior `created_at` do grupo; em empate, MUST usar o maior `id`. A consulta MUST NOT modificar descrições persistidas.

#### Scenario: Duplicação e variações de caixa ou espaços externos
- **WHEN** a conta possui registros `Internet`, `internet` e ` Internet `
- **THEN** recebe uma única sugestão para esse grupo
- **AND** a análise de valor considera os registros de todas essas variantes

#### Scenario: Grafia do último registro
- **WHEN** registros da mesma chave possuem grafias diferentes e timestamps de cadastro distintos
- **THEN** a sugestão usa a grafia do registro mais recentemente cadastrado, sem espaços externos

#### Scenario: Empate no timestamp de cadastro
- **WHEN** dois registros da mesma chave têm o mesmo `created_at`
- **THEN** a grafia exibida vem do registro com maior `id`

#### Scenario: Descrições não utilizáveis
- **WHEN** o histórico contém apenas descrições nulas, vazias ou somente com espaços
- **THEN** a API responde `200` com `data: []`

### Requirement: Ordenação determinística e limite fixo

O sistema MUST retornar no máximo cinco sugestões, sem paginação ou contagem total. MUST ordenar primeiro os grupos cuja descrição normalizada começa com o termo normalizado, depois por maior `created_at` do grupo decrescente, quantidade de registros do grupo decrescente e chave normalizada crescente como desempate final em ordenação determinística. Frequência e recência MUST considerar o histórico da conta, independentemente da janela de três meses usada para valores. A recência MUST representar cadastro (`created_at`), não ocorrência (`occurred_on`) nem atualização (`updated_at`). O limite MUST ser aplicado no banco após agrupamento e ordenação, sem carregar todo o histórico na aplicação.

#### Scenario: Prefixo precede correspondência interna
- **WHEN** `Internet` é mais antigo que `Plano de Internet` e a conta pesquisa `Int`
- **THEN** `Internet` aparece antes de `Plano de Internet`

#### Scenario: Recência precede frequência
- **WHEN** dois grupos têm a mesma prioridade de prefixo e o grupo menos frequente foi cadastrado mais recentemente
- **THEN** o grupo mais recente aparece primeiro

#### Scenario: Frequência e desempate final
- **WHEN** grupos têm a mesma prioridade de prefixo e a mesma última data de cadastro
- **THEN** o mais frequente aparece primeiro
- **AND** grupos também empatados em frequência seguem chave normalizada crescente

#### Scenario: Cadastro retroativo
- **WHEN** uma descrição acaba de ser cadastrada com `occurred_on` antigo
- **THEN** sua recência considera o timestamp do novo cadastro

#### Scenario: Mais de cinco descrições elegíveis
- **WHEN** existem pelo menos seis grupos que correspondem ao termo
- **THEN** são retornados apenas os cinco primeiros na ordenação definida
- **AND** não existem sugestões duplicadas ocupando o limite

### Requirement: Janela de três meses civis anteriores

O sistema MUST resolver a data corrente no timezone configurado da aplicação e usar os três meses civis completos imediatamente anteriores ao mês dessa referência para analisar valores. MUST usar `occurred_on` para atribuir cada despesa ao seu mês e MUST excluir o mês corrente e datas anteriores à janela da análise de valor. A referência temporal MUST ser explícita ao entrar na Application, sem dependência de relógio ou framework nessa camada. Registros fora da janela MUST continuar elegíveis para sugerir descrição e participar da ordenação histórica.

#### Scenario: Consulta em outubro
- **WHEN** a data corrente da aplicação é `2026-10-11`
- **THEN** a análise de valor usa despesas de `2026-07-01` até `2026-09-30`, inclusive
- **AND** despesas de junho ou outubro não influenciam o valor sugerido

#### Scenario: Virada de ano
- **WHEN** a referência é `2027-01-31`
- **THEN** a análise usa outubro, novembro e dezembro de 2026 completos
- **AND** o dia 31 não causa deslocamento indevido dos meses

#### Scenario: Fuso configurado
- **WHEN** o instante corrente pertence a meses distintos em UTC e no timezone da aplicação
- **THEN** a janela é calculada pelo mês civil da aplicação

#### Scenario: Descrição com histórico antigo
- **WHEN** uma descrição corresponde ao termo mas tem registros apenas fora da janela
- **THEN** ela pode ser retornada segundo a ordenação e o limite
- **AND** não recebe valor sugerido

### Requirement: Valor sugerido somente com consistência integral

Para cada chave normalizada, o sistema MUST sugerir `amount` somente se houver pelo menos um registro em cada um dos três meses da janela e todos os valores de todos os registros dessa chave na janela forem iguais. O valor MUST manter a representação existente de inteiro positivo em centavos de BRL, sem média, soma mensal, arredondamento ou conversão para ponto flutuante. Múltiplos registros no mesmo mês MUST ser aceitos quando todos têm o mesmo valor e os outros dois meses estão presentes. Qualquer divergência, inclusive dentro de um único mês, ou mês ausente MUST impedir a sugestão de valor sem remover a descrição dos candidatos. A seleção MUST NOT escolher somente o último registro de cada mês ou ignorar valores divergentes.

#### Scenario: Mesmo valor nos três meses
- **WHEN** `Internet` tem `amount=14000` em julho, agosto e setembro e a consulta acontece em outubro
- **THEN** sua sugestão contém `amount=14000`

#### Scenario: Valores diferentes entre meses
- **WHEN** `Mercado` tem valores `10000`, `12000` e `10000` nos três meses anteriores
- **THEN** a sugestão contém a descrição sem o atributo `amount`

#### Scenario: Três registros no mesmo mês
- **WHEN** uma descrição tem três registros de `14000` em setembro e nenhum em julho ou agosto
- **THEN** a sugestão não contém `amount`

#### Scenario: Mês ausente apesar de outros meses consistentes
- **WHEN** existem valores iguais em julho e setembro, mas nenhum registro em agosto
- **THEN** a sugestão não contém `amount`

#### Scenario: Múltiplos registros consistentes
- **WHEN** cada um dos três meses está representado e todos os registros da descrição na janela têm `amount=14000`, inclusive dois no mesmo mês
- **THEN** a sugestão contém `amount=14000`

#### Scenario: Divergência dentro de um mês
- **WHEN** julho e agosto têm `14000` e setembro tem registros de `14000` e `15000`
- **THEN** a sugestão não contém `amount`, independentemente da ordem dos registros

#### Scenario: Normalização compartilhada pela regra monetária
- **WHEN** julho contém `Internet`, agosto contém `internet` e setembro contém ` Internet `, todos com `14000`
- **THEN** os três registros compõem o mesmo padrão e produzem uma única sugestão com `amount=14000`

#### Scenario: Valor inteiro exato
- **WHEN** o valor consistente tem centavos não inteiros em reais, como `14001`, ou é um inteiro grande válido no contrato existente de Expense
- **THEN** a sugestão devolve exatamente o inteiro persistido, sem arredondamento ou perda de precisão

### Requirement: Resposta JSON:API de sugestões transitórias
O endpoint MUST responder 200/data coleção expense-suggestions com ID UUIDv7 canônico estável para o mesmo owner UUID e chave normalizada, obtido pelo registro de Core. MUST distinguir owners/chaves sem identificar despesa específica ou publicar o fingerprint. description MUST manter apresentação atual; amount MUST existir somente pela consistência financeira, sem zero/média/null substituto. MUST NOT adicionar categoria/data/owner/frequência/timestamps. Histórico/busca sem matches MUST produzir data vazio e não resolver associações. Rota estática MUST continuar não sendo ID de despesa.

#### Scenario: Sugestão com valor
- **WHEN** descrição satisfaz busca e consistência
- **THEN** retorna type expense-suggestions, UUIDv7, description e amount exato

#### Scenario: Sugestão somente de descrição
- **WHEN** descrição corresponde sem base de valor
- **THEN** retorna UUIDv7/description e omite amount
- **AND** não preenche categoria/data

#### Scenario: Histórico ou busca vazios
- **WHEN** não há histórico/matches
- **THEN** 200/data vazio, sem alocação de identidade

#### Scenario: Identidade estável de sugestão
- **WHEN** owner pesquisa a mesma chave com termos diferentes ou cria variante de caixa
- **THEN** conserva UUIDv7 enquanto a chave normalizada não muda, inclusive após reinício
- **AND** outro owner recebe outro UUID

### Requirement: Leitura limitada sem efeitos no ciclo de vida de despesas
A funcionalidade MUST permanecer em Expense, com Repository financeiro próprio e uma leitura PostgreSQL de busca/fatos monetários por execução válida, sem ORM nas camadas internas, N+1, query por sugestão ou transferência de lançamentos individuais. UserPort MUST fornecer owner UUIDv7 explícito. MUST permitir somente associação auxiliar de identidade em Core por lote final, além dos efeitos atuais dos middlewares; não persistir sugestões/descriptions/valores, escrever despesas, chamar IA, despachar jobs ou cachear resultados. CRUD/default other/classificação MUST permanecer preservados. O registro MUST ser invocado depois de validar projeção e preparar a resposta, sem alias para o hash antigo.

#### Scenario: Quantidade constante de statements de despesas
- **WHEN** consulta válida retorna zero, uma ou cinco sugestões
- **THEN** usa um statement financeiro
- **AND** auth e resolução batch de IDs Core são classificados separadamente, não por sugestão

#### Scenario: Consulta sem efeitos em despesas ou categorização
- **WHEN** há/ausenta padrão de valor
- **THEN** despesas/tentativas ficam intactas
- **AND** não chama classificador, queue ou cache de sugestões
- **AND** somente middleware e associação mínima de identidade final são efeitos permitidos

#### Scenario: Cadastro após seleção da sugestão
- **WHEN** cliente usa sugestão e escolhe outro valor no create
- **THEN** Expense valida/persiste o documento atual com novo ID de despesa UUIDv7
- **AND** o UUID de sugestão não é ID de despesa nem obriga valor/categoria/periodicidade

#### Scenario: Associação existente sem candidatos
- **WHEN** há associação antiga mas a descrição não corresponde mais à busca/histórico
- **THEN** ela não faz uma sugestão reaparecer na resposta

#### Scenario: Falha do registro
- **WHEN** fonte financeira é válida mas Core não resolve os IDs
- **THEN** há falha JSON:API explícita sem dados parciais ou UUID transitório
