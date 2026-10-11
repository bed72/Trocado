## ADDED Requirements

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

O endpoint MUST responder `200` com coleção JSON:API `data` de recursos do tipo `expense-suggestions`, ID opaco em string estável para a mesma conta e chave normalizada e atributo `description`. IDs MUST distinguir contas e chaves e MUST NOT representar uma despesa persistida específica. O atributo `amount` MUST estar presente somente quando a regra de consistência permitir; MUST NOT ser substituído por zero, média ou `null`. A resposta MUST NOT incluir categoria, data sugerida, proprietário, frequência ou timestamps internos. Ausência de histórico ou de correspondências MUST produzir coleção vazia. A rota estática MUST ser resolvida sem ser tratada como um identificador de despesa.

#### Scenario: Sugestão com valor
- **WHEN** uma descrição corresponde ao termo e satisfaz a consistência mensal
- **THEN** seu recurso contém `type: expense-suggestions`, ID string, `description` e `amount` em centavos

#### Scenario: Sugestão somente de descrição
- **WHEN** a descrição corresponde mas não satisfaz a regra de valor
- **THEN** seu recurso contém `description` e omite `amount`
- **AND** nenhum recurso apresenta categoria ou data para preencher o formulário

#### Scenario: Histórico ou busca vazios
- **WHEN** a conta não tem histórico ou nenhuma descrição corresponde ao termo
- **THEN** a API responde `200` com `data: []`

#### Scenario: Identidade estável de sugestão
- **WHEN** a mesma conta pesquisa a mesma chave com termos diferentes ou cadastra nova variante de caixa dessa descrição
- **THEN** o ID da sugestão permanece o mesmo enquanto sua chave normalizada não muda
- **AND** outra conta com a mesma descrição recebe ID distinto

### Requirement: Leitura limitada sem efeitos no ciclo de vida de despesas

A funcionalidade MUST permanecer no contexto Expense, com contrato próprio de Repository na Application e implementação de persistência na Infrastructure, sem expor ORM às camadas internas ou depender concretamente de outro bounded context. O UseCase MUST obter o proprietário por `UserPort` e passar proprietário, termo e período explicitamente à leitura. A busca e os fatos monetários dos candidatos MUST ser obtidos por um único statement de despesas e snapshot PostgreSQL por execução válida, sem N+1, consulta por sugestão ou transferência de lançamentos individuais para a aplicação. O endpoint MUST NOT escrever despesas, criar recursos persistentes, chamar IA, despachar jobs ou acrescentar cache. Os contratos de CRUD, a criação com categoria padrão `other` e o processamento assíncrono de categorização MUST permanecer preservados.

#### Scenario: Quantidade constante de statements de despesas
- **WHEN** a consulta válida retorna zero, uma ou cinco sugestões
- **THEN** a leitura das sugestões executa um único statement de despesas
- **AND** consultas dos middlewares de autenticação ou sessão não são confundidas com N+1 de despesas

#### Scenario: Consulta sem efeitos em despesas ou categorização
- **WHEN** uma conta consulta sugestões com ou sem padrão monetário consistente
- **THEN** despesas e tentativas de classificação permanecem inalteradas
- **AND** nenhuma chamada ao classificador, despacho de job ou escrita de cache de sugestões acontece
- **AND** somente os efeitos já existentes dos middlewares, como extensão de sessão, continuam permitidos

#### Scenario: Cadastro após seleção da sugestão
- **WHEN** o consumidor usa a sugestão para preparar uma criação e escolhe um valor diferente
- **THEN** o endpoint de criação continua validando e persistindo os dados enviados conforme seu contrato atual
- **AND** a sugestão não cria obrigação de valor, periodicidade ou categoria
