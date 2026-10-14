# insights Specification

## Purpose
Definir a consulta pessoal de Insights financeiros sobre despesas registradas, com análise exata e isolada por proprietário, elegibilidade baseada em evidência, mensagens determinísticas com rotação diária e contrato JSON:API, sem escrita em despesas ou estado analítico persistido.
## Requirements
### Requirement: Contexto dedicado com leitura direta e sem escrita em despesas

O sistema MUST manter Insights como contexto dedicado, responsável por análise, elegibilidade, seleção e composição das observações. Insights MUST consultar diretamente os dados de despesas no banco compartilhado somente pela sua Infrastructure, sem consumir classes, Models, Repositories, UseCases ou endpoints de Expense. MUST NOT criar, editar, excluir ou recategorizar despesas. Domain e Application de Insights MUST permanecer independentes do framework e da persistência; a dependência do schema de despesas MUST permanecer na Infrastructure.

#### Scenario: Análise independente do CRUD
- **WHEN** Insights precisa de totais e distribuição de despesas por período
- **THEN** sua Infrastructure consulta o banco e entrega dados tipados ao contexto
- **AND** nenhum componente de Expense é chamado ou importado e nenhum registro é alterado

#### Scenario: Contrato de leitura próprio
- **WHEN** a Application solicita os fatos analíticos
- **THEN** depende de um Repository de leitura próprio de Insights, implementado na Infrastructure e com projeções independentes do ORM
- **AND** a leitura permanece em um statement e não é exposta como Port de capacidade

### Requirement: Consulta pessoal autenticada e isolada por proprietário

O sistema MUST oferecer `GET /api/insights` somente sob autenticação, conta ativa, e-mail verificado e as políticas existentes de throttle autenticado e extensão de sessão. MUST obter o proprietário da identidade autenticada e restringir todas as fontes de cálculo a suas despesas antes de agregações, rankings e comparações. MUST aceitar somente o conjunto opcional `filter[year]` e `filter[month]` para seleção mensal, conforme o requisito de validação mensal. MUST NOT aceitar proprietário, família, período arbitrário, limite, paginação ou outros parâmetros; entradas inválidas MUST produzir `422` JSON:API sem alterar o escopo de acesso nem executar a leitura analítica.

#### Scenario: Estatísticas da própria conta
- **WHEN** uma conta autenticada consulta insights de setembro de 2026 e outras contas possuem despesas nesse mês
- **THEN** os candidatos e mensagens consideram exclusivamente registros da conta autenticada
- **AND** despesas de outras contas não participam de totais, denominadores, rankings, identificação do maior lançamento ou histórico

#### Scenario: Consulta sem autenticação
- **WHEN** `GET /api/insights` é solicitado sem token válido
- **THEN** a API responde `401` em JSON:API sem revelar insights

#### Scenario: Tentativa de escolher o proprietário ou período
- **WHEN** a conta envia `user_id`, `period`, `filter[from]`, `filter[category]` ou outro parâmetro não permitido
- **THEN** a API responde `422` em JSON:API identificando o parâmetro inválido
- **AND** nenhuma leitura analítica é executada

#### Scenario: Conta sem condições de acesso
- **WHEN** uma conta não atende à política existente de atividade ou verificação de e-mail
- **THEN** os middlewares existentes bloqueiam a consulta antes da leitura analítica
- **AND** Insights não oferece um caminho alternativo para acessar despesas

### Requirement: Fatos derivados de registros com cálculo exato

O sistema MUST calcular fatos sobre os valores registrados em centavos de BRL e a data de ocorrência, não sobre a data de cadastro. MUST incluir `other` no total, excluir despesas definitivamente removidas e ignorar datas posteriores à referência. MUST manter somas e decisões monetárias exatas sem overflow ou arredondamento silencioso; percentuais MUST ser arredondados a inteiros por half-up somente para a mensagem, após avaliar os limites com a razão não arredondada. Numerador, denominador e contagens relacionados MUST representar um snapshot consistente. MUST NOT afirmar que os registros cobrem todos os gastos, que ausência de registros comprova economia, que redução comprova melhora de hábitos ou que concentração comprova excesso em relação a renda/orçamento.

#### Scenario: Cadastro retroativo e data futura
- **WHEN** uma conta cadastra hoje uma despesa de um mês anterior e outra despesa com data futura
- **THEN** a primeira participa do período de ocorrência correspondente
- **AND** a despesa futura não participa dos fatos até alcançar a data de referência

#### Scenario: Valor diminuto com grande variação percentual
- **WHEN** o total anterior é R$ 2 e o atual é R$ 10
- **THEN** o sistema não emite comparação de aumento percentual por falta de base monetária suficiente

#### Scenario: Ausência de registros no período atual
- **WHEN** a conta possui histórico anterior, mas nenhum registro no período corrente
- **THEN** o sistema não afirma redução de 100%, economia ou melhoria de hábitos
- **AND** não trata a conta como se nunca tivesse cadastrado despesas

#### Scenario: Soma acima do limite de um inteiro de máquina
- **WHEN** a soma de valores válidos excede o limite de um inteiro nativo
- **THEN** o cálculo preserva o valor exato com representação adequada
- **AND** não publica percentual ou mensagem baseada em overflow ou conversão silenciosa para float

#### Scenario: Alteração concorrente
- **WHEN** uma escrita ocorre durante a leitura analítica
- **THEN** fatos relacionados são calculados a partir de uma versão consistente dos dados confirmados
- **AND** não misturam um numerador anterior à escrita com um denominador posterior

### Requirement: Períodos equivalentes e referência temporal explícita

O sistema MUST resolver uma data civil da consulta no timezone configurado da aplicação, separada do mês selecionado. Sem filtros, MUST selecionar o mês da consulta. Observações do mês vigente MUST considerar do primeiro dia até a data da consulta, inclusive. Observações de meses passados MUST considerar o mês selecionado inteiro, do dia 1 ao seu último dia. MUST NOT selecionar mês futuro. Datas de ocorrência posteriores ao limite efetivo selecionado MUST NOT participar dos fatos, inclusive despesas retroativas cadastradas depois do mês analisado com ocorrência fora dele.

Comparações correntes MUST usar somente dias completos do mês vigente e o intervalo equivalente do mês anterior, limitando ambos ao número de dias comum quando os meses diferirem em duração. MUST exigir pelo menos sete dias completos comuns. MUST NOT comparar mês parcial com mês completo como períodos equivalentes, projetar fechamento ou substituir silenciosamente a comparação corrente por meses fechados. Comparações de um mês passado MUST usar o total desse mês completo contra o total do imediatamente anterior completo, incluindo todos os dias de ambos, mesmo com durações diferentes, e identificar a comparação como total mensal, não média diária ou intervalos de mesma duração. Toda mensagem financeira MUST informar período compatível com o fato.

#### Scenario: Consulta no dia 12
- **WHEN** a data da consulta é 12 de outubro de 2026 e o mês selecionado é outubro de 2026
- **THEN** as comparações usam dias 1 a 11 de outubro e setembro
- **AND** as observações descritivas podem incluir registros do dia 12

#### Scenario: Meses de duração diferente
- **WHEN** a data da consulta é 31 de março de 2027 e o mês selecionado é março de 2027
- **THEN** a comparação usa dias 1 a 28 de março e fevereiro
- **AND** os dias 29 e 30 de março não entram na comparação equivalente

#### Scenario: Início do mês sem intervalo comparável suficiente
- **WHEN** a consulta do mês vigente ocorre no primeiro dia ou antes de completar sete dias comuns
- **THEN** nenhuma comparação corrente é emitida
- **AND** observações descritivas ou onboarding continuam sujeitos à sua elegibilidade própria

#### Scenario: Mês passado completo
- **WHEN** em 12 de outubro de 2026 a conta seleciona setembro de 2026
- **THEN** o período descritivo é 2026-09-01 a 2026-09-30
- **AND** a comparação mensal usa 2026-09-01 a 2026-09-30 contra 2026-08-01 a 2026-08-31
- **AND** despesas de 30 de setembro e 31 de agosto entram nos respectivos totais

#### Scenario: Fevereiro bissexto selecionado
- **WHEN** a conta seleciona fevereiro de 2024 depois de seu encerramento
- **THEN** a análise inclui 2024-02-29 e compara fevereiro inteiro com janeiro inteiro
- **AND** selecionar fevereiro de 2025 encerra o período em 2025-02-28

#### Scenario: Virada de ano
- **WHEN** a conta seleciona janeiro de 2026 depois de seu encerramento
- **THEN** a comparação usa janeiro de 2026 e dezembro de 2025 completos
- **AND** os dois antecedentes da análise são dezembro e novembro de 2025

#### Scenario: Último dia do vigente não é fechamento
- **WHEN** a data da consulta é 31 de outubro de 2026 e outubro está selecionado
- **THEN** observações incluem dia 31 e a comparação corrente usa dias 1 a 30
- **AND** o sistema não troca para comparação de meses encerrados até o mês deixar de ser vigente

#### Scenario: Consulta próxima da mudança de dia no timezone da aplicação
- **WHEN** a consulta ocorre em um instante cujo dia civil no timezone da aplicação difere de UTC
- **THEN** default, validação de mês futuro, período corrente e rotação usam a mesma data civil resolvida uma vez para aquela consulta

### Requirement: Observações de concentração com evidência mínima

O sistema MUST considerar elegível uma base descritiva somente com pelo menos cinco lançamentos em três datas distintas e total de pelo menos R$ 100 no período. `category_concentration` MUST exigir uma líder única diferente de `other` e participação de pelo menos 30% do total. `expense_concentration` MUST exigir que o maior lançamento represente pelo menos 40% do total e produzir no máximo um candidato por período. MUST descrever concentração, sem concluir que o lançamento é atípico ou que uma categoria é excessiva em relação à capacidade financeira da pessoa.

#### Scenario: Categoria dominante elegível
- **WHEN** o mês tem seis lançamentos em quatro datas, total de R$ 500 e alimentação é líder única com R$ 200
- **THEN** um candidato `category_concentration` pode informar a participação de 40% de alimentação

#### Scenario: Empate de categorias
- **WHEN** duas categorias compartilham o maior valor registrado
- **THEN** nenhuma delas é apresentada como líder única ou vencedora

#### Scenario: Volume insuficiente
- **WHEN** todos os registros do período se resumem a dois lançamentos no mesmo dia
- **THEN** o sistema não produz observações de concentração com aparência de padrão estabelecido

#### Scenario: Lançamento concentrado mas não necessariamente atípico
- **WHEN** uma base descritiva elegível contém um lançamento de R$ 400 em um total de R$ 800
- **THEN** o candidato pode informar concentração de 50%
- **AND** não afirma que o gasto é anormal, supérfluo ou incompatível com a renda

### Requirement: Comparações do total com base material nos dois períodos

O sistema MUST gerar `registered_amount_increase` ou `registered_amount_decrease` somente quando cada janela possui a base descritiva mínima de cinco lançamentos em três datas distintas e total de pelo menos R$ 100, a diferença absoluta alcança pelo menos R$ 50 e a variação relativa alcança pelo menos 20%. No modo corrente MUST exigir pelo menos sete dias completos comuns; no modo encerrado MUST comparar os dois meses inteiros, sem excluir seu último dia ou reduzir ambos ao mês mais curto. MUST usar o total anterior como denominador e não emitir percentual se ele for zero. MUST produzir no máximo uma direção de variação para o mesmo par de períodos e mencionar valores registrados, sem associar redução automaticamente a um comportamento positivo.

#### Scenario: Redução elegível
- **WHEN** períodos elegíveis do modo selecionado somam R$ 500 anteriormente e R$ 350 atualmente
- **THEN** o candidato indica 30% menos valor registrado no intervalo atual
- **AND** não afirma que a conta economizou R$ 150 ou melhorou seus hábitos

#### Scenario: Diferença absoluta irrelevante
- **WHEN** períodos com base descritiva elegível somam R$ 100 e R$ 125
- **THEN** a variação de 25% não produz comparação porque a diferença é menor que R$ 50

#### Scenario: Período anterior vazio
- **WHEN** o total anterior é zero e existem registros no selecionado
- **THEN** o sistema não calcula percentual de aumento nem considera o histórico comparável

#### Scenario: Total mensal não é média diária
- **WHEN** agosto tem R$ 400 e setembro tem R$ 500, ambos com base elegível, e setembro é um mês passado selecionado
- **THEN** o candidato indica aumento de 25% no total registrado de setembro contra agosto
- **AND** não ajusta agosto para 30 dias, não exclui seu dia 31 e não apresenta variação de média diária

### Requirement: Liderança recorrente baseada em períodos elegíveis

O sistema MUST gerar `category_lead_streak` somente se a mesma categoria diferente de `other` é líder única no mês selecionado e nos dois imediatamente anteriores completos. Cada período MUST possuir base descritiva mínima e participação da líder de pelo menos 30%. No vigente, MUST distinguir a liderança parcial dos meses fechados; no histórico, MUST descrever três meses encerrados. MUST NOT inferir continuidade a partir de períodos vazios ou empatados nem incluir meses posteriores ao selecionado.

#### Scenario: Liderança em três períodos
- **WHEN** alimentação lidera de forma única com participação suficiente no mês vigente até a consulta e nos dois anteriores, todos elegíveis
- **THEN** um candidato informa a liderança até a data atual e nos dois meses anteriores
- **AND** não trata o mês vigente como encerrado

#### Scenario: Mês intermediário sem evidência
- **WHEN** a categoria lidera no mês selecionado e no anterior, mas o outro mês considerado tem dados insuficientes
- **THEN** o sistema não emite liderança recorrente
- **AND** uma observação de concentração no mês selecionado ainda pode ser elegível

#### Scenario: Liderança histórica
- **WHEN** setembro de 2026 é selecionado em outubro e alimentação lidera de forma elegível em julho, agosto e setembro
- **THEN** o candidato descreve liderança nos três meses encerrados
- **AND** seu período abrange 2026-07-01 a 2026-09-30 e não inclui outubro

### Requirement: Onboarding contextual e tratamento de other

O sistema MUST retornar `first_expense` como única mensagem no mês vigente quando não há despesas históricas até a data da consulta. Quando há histórico e nenhuma observação financeira elegível no vigente, MUST oferecer no máximo uma mensagem `insufficient_history`, distinguindo poucos registros no mês de histórico sem registros no mês. Em mês passado sem observação financeira elegível, MUST usar no máximo `insufficient_history` contextualizado no mês/ano selecionado, distinguindo registros insuficientes e ausência de registros, mesmo quando não existe história até o fim daquele mês. MUST NOT usar `first_expense` numa consulta histórica nem sugerir que a conta inteira não possui registros por causa de um mês vazio.

MUST gerar `category_review` somente com base descritiva elegível e pelo menos 50% do valor selecionado em `other`. MUST NOT inferir o conteúdo de `other`, chamar todos esses registros de incorretos ou pendentes, nem consultar Identity para personalização ou exclusão de conta. Onboarding MUST conservar `period: null` e os tipos/grupos existentes, indicando mês/ano no texto quando necessário ao contexto.

#### Scenario: Conta sem registros
- **WHEN** a conta consulta o vigente e não possui despesas históricas até hoje
- **THEN** a resposta contém somente `first_expense`
- **AND** não inventa fatos financeiros para completar a lista

#### Scenario: Histórico antigo sem registros recentes
- **WHEN** existem despesas anteriores à janela de análise, mas nenhuma no vigente
- **THEN** a orientação reconhece a ausência de registros nesse mês
- **AND** não sugere cadastrar a primeira despesa nem celebra economia

#### Scenario: Other predominante
- **WHEN** o mês selecionado possui base descritiva elegível e 60% do valor em `other`
- **THEN** a orientação informa 60% e convida a revisar categorias no período correto
- **AND** o total financeiro continua incluindo esse valor sem presumir erro ou comportamento específico

#### Scenario: Mês anterior ao primeiro registro
- **WHEN** a conta tem sua primeira despesa em outubro de 2026 e seleciona setembro de 2026
- **THEN** recebe `insufficient_history` informando que setembro de 2026 não tem registros
- **AND** não recebe `first_expense`, não usa fatos de outubro e não é convidada a cadastrar a primeira despesa

#### Scenario: Poucos registros históricos
- **WHEN** setembro de 2026 tem dois lançamentos e é selecionado em outubro
- **THEN** a mensagem informa dados insuficientes em setembro de 2026
- **AND** não afirma que faltam registros em outubro ou que adicionar um único registro garantirá um Insight

### Requirement: Seleção relevante sem preenchimento artificial

O sistema MUST retornar no máximo seis insights, sem mínimo obrigatório, ordenados por prioridade explícita e com desempates determinísticos. MUST priorizar comparação do total, liderança recorrente, concentração por categoria, concentração em um lançamento e orientações, nessa ordem. MUST deduplicar por informação, assunto e período antes de compor mensagens. Liderança recorrente MUST substituir concentração da mesma categoria; concentração em lançamento da categoria já selecionada MUST ser suprimida quando ambos descrevem o mesmo período. MUST NOT duplicar um fato com variantes diferentes, selecionar aleatoriamente candidatos ou acrescentar mensagens irrelevantes apenas para atingir o teto.

#### Scenario: Observações equivalentes de alimentação
- **WHEN** alimentação é elegível para liderança recorrente e concentração corrente
- **THEN** somente a liderança recorrente é selecionada para esse assunto
- **AND** a concentração não reaparece sob outro título

#### Scenario: Maior lançamento na categoria selecionada
- **WHEN** a concentração da categoria é selecionada e o maior lançamento elegível pertence à mesma categoria no mesmo período
- **THEN** o cartão de concentração do lançamento é suprimido por redundância

#### Scenario: Poucos fatos relevantes
- **WHEN** apenas duas observações não redundantes são elegíveis
- **THEN** a API retorna duas mensagens, sem completar artificialmente seis

### Requirement: Catálogo curto com personalidade e fidelidade aos fatos

O sistema MUST compor mensagens por templates completos de catálogo determinístico, com pelo menos quatro variantes revisadas por conjunto elegível. MUST preencher somente fatos calculados e aprovados pela elegibilidade. Títulos MUST ter no máximo 24 caracteres Unicode e descrições no máximo 80 após interpolação. O par MUST priorizar assunto identificado, magnitude numérica e referência temporal; MUST NOT usar piadas, metáforas ou títulos genéricos que não acrescentam informação, como “Um figurante? Claro que não”. MUST manter linguagem neutra sem ofensa, julgamento pessoal ou sarcasmo inadequado a categorias sensíveis.

MUST usar uma alternativa curta e completa quando uma variante não couber; MUST NOT truncar números, qualificações, descrição de despesa ou períodos necessários à veracidade. Uma alternativa de comparação MUST preservar direção, referência e magnitude numérica verdadeira, por percentual integral ou diferença monetária exata; MUST NOT substituir um percentual por apenas “mais” ou “menos” para caber. MUST NOT combinar aleatoriamente título, descrição e piada independentes, chamar IA ou outro serviço externo para gerar textos em runtime. O mês/ano e, em fatos parciais, o limite efetivo MUST estar identificáveis no par de textos sem depender de cabeçalho do cliente. Referências que cruzam anos MUST ser inequívocas.

#### Scenario: Mensagem de alimentação
- **WHEN** a participação calculada de alimentação em setembro de 2026 encerrado é 38%
- **THEN** um par válido identifica Alimentação, set/2026 e 38% do total registrado no mês
- **AND** não acrescenta alegações sobre dieta, renda ou gastos fora do aplicativo

#### Scenario: Parâmetros que excedem o orçamento editorial
- **WHEN** uma variante interpolada ultrapassa o limite de título ou descrição
- **THEN** o sistema usa uma alternativa completa compatível com os limites e o mesmo fato
- **AND** não devolve texto truncado ou sem magnitude/contexto necessário

#### Scenario: Comparação parcial compacta
- **WHEN** outubro de 2026 até dia 12 produz aumento de 25% nos dias completos 1 a 11 contra setembro
- **THEN** o par identifica outubro de 2026, +25% e dias 1 a 11 de ambos os meses
- **AND** não descreve aumento mensal fechado nem inclui o dia 12 na comparação

#### Scenario: Comparação histórica compacta
- **WHEN** setembro de 2026 encerrado produz aumento de 25% contra agosto inteiro
- **THEN** o par identifica setembro, agosto de 2026 e +25% no total registrado
- **AND** não diz “até hoje”, “neste mês” no sentido de outubro ou “mesmos dias”

#### Scenario: Percentual extremo e rótulo longo
- **WHEN** uma comparação tem percentual acima de 100% com muitos dígitos ou uma observação envolve Assinaturas e ano de quatro dígitos
- **THEN** o catálogo produz par completo dentro dos limites sem float, abreviação numérica inexata ou perda de referência
- **AND** uma eventual troca para diferença monetária mantém magnitude exata e direção

#### Scenario: Falha editorial não é onboarding
- **WHEN** nenhum template ou alternativa preserva o fato dentro dos limites
- **THEN** a composição falha explicitamente pelo tratamento existente
- **AND** não mascara a falha como histórico insuficiente nem publica texto cortado

### Requirement: Rotação diária estável sem histórico de visualização

O sistema MUST selecionar variantes deterministicamente por conta, chave editorial da observação e dia civil da consulta, sem persistir histórico de entrega ou visualização. A chave MUST distinguir mês selecionado, modo corrente/encerrado e estado contextual relevante; o dia da rotação MUST NOT ser substituído pelo fim do mês histórico. Para a mesma conta, chave, versão do catálogo e conjunto elegível, MUST manter a variante em consultas no mesmo dia e escolher outra no dia seguinte. Mudanças em números interpolados MUST NOT alterar a variante por si só. Alterações nos fatos MUST recalcular imediatamente candidatos e valores, sem congelar resposta por dia. A rotação MUST permitir repetição após o ciclo e MUST NOT prometer novidade na próxima visita espaçada ou estabilidade quando o conjunto elegível mudar.

#### Scenario: Duas consultas no mesmo dia
- **WHEN** a conta consulta duas vezes o mesmo mês no mesmo dia, mantendo fatos e catálogo
- **THEN** recebe os mesmos candidatos, ordem e variantes de texto

#### Scenario: Dia seguinte com observação ainda válida
- **WHEN** a conta consulta no dia seguinte e a mesma chave editorial continua elegível com o mesmo conjunto e catálogo
- **THEN** o título ou descrição usa outra variante
- **AND** grupo e tipo da observação não mudam por causa da rotação

#### Scenario: Nova despesa durante o dia
- **WHEN** uma nova despesa altera a participação de alimentação de 38% para 42%, mantendo a mesma observação elegível
- **THEN** a próxima consulta atualiza o percentual para 42%
- **AND** a variante não muda apenas pela alteração desse número

#### Scenario: Retorno após um ciclo de variantes
- **WHEN** a conta retorna depois de um ciclo completo do mesmo conjunto
- **THEN** uma variante já utilizada pode reaparecer
- **AND** isso não exige consultar ou gravar histórico de mensagens vistas

#### Scenario: Rotação de mês passado
- **WHEN** a conta consulta setembro de 2026 nos dias 12 e 13 de outubro com os mesmos fatos elegíveis
- **THEN** o contexto financeiro continua setembro completo nas duas respostas
- **AND** a variante muda pelo dia da consulta, sem usar 30 de setembro como dia fixo de rotação

#### Scenario: Atualização retroativa
- **WHEN** uma edição confirmada de despesa de setembro altera o percentual histórico no mesmo dia
- **THEN** a próxima consulta de setembro recalcula fatos, elegibilidade e valores
- **AND** não depende de cache diário ou histórico de visualização

### Requirement: Contrato JSON:API por grupo e tipo

O sistema MUST responder `200` com coleção `data` de recursos JSON:API do tipo externo `insights`, ID derivado em string e atributos `group`, `type`, `title`, `description` e `period`. MUST permitir `observation` com `category_concentration` ou `expense_concentration`; `comparison` com `registered_amount_increase`, `registered_amount_decrease` ou `category_lead_streak`; e `onboarding` com `first_expense`, `insufficient_history` ou `category_review`. Variantes MUST preservar grupo e tipo. IDs MUST distinguir conta, tipo, assunto e períodos analisados, sem depender do texto ou dos números interpolados. MUST NOT exigir registro persistido ou endpoint individual para o ID.

`period` MUST ser `null` em onboarding e conter `from`, `to` e `comparison` nos demais tipos, com datas civis canônicas `Y-m-d`; `comparison` MUST ser o intervalo anterior em comparações do total e `null` nos demais casos. Liderança recorrente MUST expor o intervalo abrangendo os três períodos considerados. MUST NOT retornar cor, ícone, código redundante, julgamento de tom, IDs de despesas ou perfil da conta; Flutter usa `attributes.type` para aparência e MUST poder renderizar o texto com fallback visual neutro para tipos futuros desconhecidos. A coleção MUST NOT exigir paginação.

#### Scenario: Cartão financeiro para Flutter
- **WHEN** a API seleciona uma concentração por categoria
- **THEN** o recurso contém `group` igual a `observation`, `attributes.type` igual a `category_concentration`, texto pronto e período correspondente
- **AND** o Flutter não precisa calcular percentual ou conhecer os limiares da regra

#### Scenario: Comparação com intervalos explícitos
- **WHEN** a referência é 12 de outubro de 2026 e uma comparação do total é selecionada
- **THEN** `period.from` é `2026-10-01`, `period.to` é `2026-10-11` e `period.comparison` contém `2026-09-01` a `2026-09-11`

#### Scenario: Cartão de onboarding
- **WHEN** a API retorna `first_expense`
- **THEN** o recurso possui `group` igual a `onboarding`, `period` igual a `null` e título e descrição completos

#### Scenario: Tipo futuro desconhecido pelo cliente
- **WHEN** o consumidor recebe um tipo que ainda não possui mapeamento visual
- **THEN** pode apresentar título e descrição com ícone e cor neutros
- **AND** não precisa interpretar regras ou rejeitar a coleção inteira

### Requirement: Geração sob demanda sem estado analítico persistido

O sistema MUST gerar Insights sob demanda sem persistir cartões, histórico de visualização ou projeções analíticas, sem cache específico e sem processamento assíncrono. MUST considerar alterações confirmadas nas despesas na próxima leitura, inclusive categoria aplicada em segundo plano, sem reutilizar o cache de páginas de Expense. MUST consultar agregações em lote e intervalos limitados, sem carregar todo o histórico ou fazer uma query por categoria/regra. Uma eventual falha de leitura MUST produzir falha HTTP explícita segundo o tratamento JSON:API existente, não uma lista de estatísticas inventadas ou onboarding que esconda a falha.

#### Scenario: Categoria alterada após o cadastro
- **WHEN** uma classificação confirmada altera a categoria de uma despesa
- **THEN** a próxima consulta de Insights considera a categoria atual e recalcula candidatos
- **AND** não depende de invalidação do cache de páginas de Expense

#### Scenario: Exclusão ou edição confirmada
- **WHEN** a conta exclui uma despesa ou altera seu valor ou data
- **THEN** a próxima leitura reflete os registros confirmados correspondentes
- **AND** não recupera um cartão persistido ou uma lista congelada no começo do dia

#### Scenario: Histórico extenso
- **WHEN** a conta possui despesas em vários anos
- **THEN** a análise financeira consulta a janela limitada de períodos e usa existência histórica somente para distinguir onboarding
- **AND** não percorre a paginação do CRUD nem instancia cada despesa do histórico

#### Scenario: Falha de acesso ao banco
- **WHEN** a leitura analítica falha por indisponibilidade do banco
- **THEN** a API responde com erro JSON:API pelo tratamento existente
- **AND** não afirma que a conta está sem despesas nem retorna percentuais fabricados

### Requirement: Rótulos e análise das categorias expandidas
Insights MUST reconhecer os identificadores `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations` e `travel` com os rótulos editoriais integrais “Financiamentos”, “Investimentos”, “Impostos e taxas”, “Seguros”, “Cuidados pessoais”, “Pets”, “Presentes e doações” e “Viagens”, respectivamente. MUST preservar os rótulos existentes e tratar as novas categorias como elegíveis nas mesmas regras de concentração, liderança e comparação de valores registrados. Investimentos e financiamentos MUST participar dos totais e denominadores conforme o período e proprietário selecionados; MUST NOT inferir consumo, prejuízo, retorno, patrimônio ou capacidade financeira com base nesses registros. Os textos interpolados MUST respeitar os limites editoriais vigentes com alternativas completas, sem truncar rótulo, fatos ou período e sem falhar por ausência de rótulo para categoria válida. As novas categorias MUST NOT alterar os grupos, tipos e envelope JSON:API existentes.

#### Scenario: Concentração de cada nova categoria
- **WHEN** cada uma das oito novas categorias é líder única, tem 40% do total registrado e a base descritiva mínima está atendida
- **THEN** um candidato de concentração pode produzir mensagem com o rótulo integral correspondente e participação factual
- **AND** não ocorre exceção por categoria sem rótulo nem afirmação sobre excesso ou renda

#### Scenario: Investimentos no total e na interpretação
- **WHEN** cinco lançamentos em pelo menos três datas somam `100000` centavos no período, dos quais `60000` são `investments`
- **THEN** a concentração pode informar “Investimentos” com participação de 60% do valor registrado
- **AND** os aportes não são excluídos do denominador nem apresentados como consumo, prejuízo ou rendimento

#### Scenario: Liderança recorrente de nova categoria
- **WHEN** `financing` lidera isoladamente os três períodos analisados com base e participação mínimas atendidas
- **THEN** a liderança recorrente usa o rótulo “Financiamentos” e os períodos corretos conforme o modo de análise
- **AND** preserva a prioridade e deduplicação existentes

#### Scenario: Rótulos longos e alternativas compactas
- **WHEN** “Presentes e doações”, “Cuidados pessoais” ou “Impostos e taxas” são interpolados nas variantes aplicáveis de concentração, liderança ou identificação de lançamento
- **THEN** todos os pares entregues respeitam os limites editoriais vigentes, inclusive 24 caracteres de título e 80 de descrição quando esse contrato estiver vigente
- **AND** alternativas preservam o rótulo integral, magnitude exigida e referência temporal, sem corte ou ampliação dos limites

#### Scenario: Viagem não implica narrativa sobre o usuário
- **WHEN** os lançamentos de `travel` tornam elegível uma observação
- **THEN** a mensagem usa “Viagens” e somente fatos registrados
- **AND** não inventa destino, finalidade pessoal ou capacidade de viajar

### Requirement: Filtros mensais opcionais validados sem ambiguidade

O sistema MUST aceitar `filter[year]` e `filter[month]` somente ambos presentes ou ambos ausentes, exclusivamente na query. MUST validar strings de dígitos decimais, de 1 a 4 posições para ano e 1 a 2 para mês, nos intervalos 1–9999 e 1–12, normalizando zeros à esquerda. MUST rejeitar mês posterior ao vigente e janelas cujos dois antecedentes não sejam representáveis no intervalo civil suportado; o primeiro mês representável é março de 0001. MUST rejeitar valores vazios, sinais, whitespace, frações, expoentes, escalares `filter`, arrays nos valores, chaves extras e parâmetros duplicados, inclusive nomes percent-encoded equivalentes após uma decodificação. MUST NOT aceitar filtros enviados somente no corpo GET, inferir campos faltantes, ignorar parâmetros inválidos ou corrigir silenciosamente mês fora de faixa. MUST responder `422` JSON:API com `source.parameter` identificando o parâmetro público responsável, sem leitura analítica.

#### Scenario: Default e vigente explícito
- **WHEN** hoje é 12 de outubro de 2026 e a conta consulta sem filtros ou com `filter[year]=2026&filter[month]=10`
- **THEN** ambas as consultas selecionam outubro de 2026 até dia 12
- **AND** têm os mesmos fatos, candidatos, IDs e variantes no mesmo dia

#### Scenario: Mês passado válido e normalização
- **WHEN** hoje é outubro de 2026 e a query informa ano 2026 e mês `09`
- **THEN** seleciona setembro de 2026, com a mesma identidade da consulta com mês `9`

#### Scenario: Par incompleto
- **WHEN** a query contém somente `filter[month]=9` ou somente `filter[year]=2026`
- **THEN** a API responde `422` apontando respectivamente `filter[year]` ou `filter[month]`

#### Scenario: Valores e estruturas inválidos
- **WHEN** year/month contém valor vazio, `0`, mês `13`, ano `10000`, sinal, fração, expoente, whitespace ou array, ou `filter` é escalar
- **THEN** a API responde `422` apontando o parâmetro correspondente
- **AND** não transforma a entrada em um mês válido

#### Scenario: Mês futuro
- **WHEN** hoje é 12 de outubro de 2026 e a conta solicita novembro de 2026 ou janeiro de 2027
- **THEN** a API responde `422` apontando `filter[month]`
- **AND** não retorna previsão, onboarding ou mês vigente como substituição

#### Scenario: Duplicidade na query original
- **WHEN** `filter[month]` aparece duas vezes, com valores iguais ou distintos, ou uma ocorrência usa nome percent-encoded equivalente
- **THEN** a API responde `422` para `filter[month]`
- **AND** não usa silenciosamente a primeira ou última ocorrência

#### Scenario: Limite inferior representável
- **WHEN** a conta solicita janeiro ou fevereiro do ano 1
- **THEN** a API responde `422` para `filter[year]` por janela de antecedentes não representável
- **AND** março do ano 1 é aceito temporalmente, com antecedentes fevereiro e janeiro do ano 1

#### Scenario: Corpo GET não seleciona mês
- **WHEN** uma consulta sem query inclui filtros somente no corpo GET
- **THEN** a seleção continua sendo o mês vigente
- **AND** dados do corpo não substituem os parâmetros da query

### Requirement: Maior lançamento identificado por fatos do registro

O sistema MUST identificar a despesa de `expense_concentration` por sua descrição quando ela for não vazia após normalização de whitespace e couber integralmente no par editorial. Caso contrário MUST usar categoria e data de ocorrência como identificação factual, incluindo `other` como Outros sem inferir seu conteúdo. MUST preservar percentual e referência do mês selecionado; MUST acrescentar valor exato em BRL quando a variante comportar essa informação complementar. MUST obter descrição, data, categoria e valor do mesmo lançamento escolhido pelo desempate determinístico existente, no mesmo snapshot dos agregados e restrito ao proprietário. MUST tratar descrição como texto, sem interpretar marcação/instruções nem truncá-la para caber. MUST NOT expor ID da despesa, buscar detalhes por cartão, alterar a elegibilidade de 40% ou inferir que concentração prova gasto excessivo.

#### Scenario: Descrição utilizável
- **WHEN** o maior lançamento elegível tem descrição Aluguel, R$ 1.200 e participação de 54% no mês selecionado
- **THEN** o par identifica Aluguel e 54%, com R$ 1.200,00 se couber na variante
- **AND** não retorna apenas “um lançamento” como identificação

#### Scenario: Descrição ausente ou longa
- **WHEN** a descrição é null, somente whitespace ou não cabe integralmente no texto
- **THEN** a mensagem usa categoria e data do lançamento, percentual e referência corretos
- **AND** não corta a descrição com reticências nem inventa um nome

#### Scenario: Descrição com quebra de linha ou marcação
- **WHEN** a descrição contém quebras de linha, espaços repetidos ou caracteres de marcação
- **THEN** o texto é normalizado para uma linha e permanece texto literal
- **AND** não executa instruções nem interpreta HTML/Markdown

#### Scenario: Empate do maior lançamento
- **WHEN** há lançamentos de mesmo valor máximo
- **THEN** categoria crescente e ID crescente desempatam conforme a regra existente
- **AND** descrição/data exibidas pertencem ao registro escolhido, sem mistura de registros

### Requirement: Identidade e períodos preservados na navegação mensal

O sistema MUST preservar resource type `insights`, atributos, grupos/tipos, `period` e limite de seis itens do contrato existente. IDs MUST continuar distinguindo conta, tipo, assunto e períodos efetivos, incluindo o mês interno analisado em onboarding com `period: null`. MUST NOT depender da presença textual dos filtros, números, descrição, variante, dia de visita ou versão do catálogo por si sós. Comparações históricas MUST expor ambos os meses completos; liderança MUST expor os três períodos corretos. MUST NOT adicionar estado de navegação, IDs de despesas, paginação ou novos grupos/tipos para atender ao slider.

#### Scenario: Período histórico público
- **WHEN** setembro de 2026 selecionado produz comparação do total com agosto
- **THEN** `period.from` é 2026-09-01, `period.to` é 2026-09-30 e `period.comparison` vai de 2026-08-01 a 2026-08-31

#### Scenario: IDs não são texto ou dia de visita
- **WHEN** a mesma observação histórica mantém conta, tipo, assunto e períodos mas seus números ou variante mudam
- **THEN** seu ID permanece o mesmo
- **AND** selecionar outro mês distingue a identidade da observação

#### Scenario: Onboarding de meses distintos
- **WHEN** agosto e setembro produzem `insufficient_history` com `period: null`
- **THEN** o texto contextualiza cada mês e seus IDs são distintos por período interno

### Requirement: Coleção Bruno acompanha o contrato mensal de Insights

A coleção Bruno MUST manter consulta sem filtros e disponibilizar `filter[year]` e `filter[month]` opcionais como par na requisição de Insights, com exemplos/documentação de mês vigente explícito, mês passado e entradas inválidas. MUST preservar base URL de ambiente, Bearer e Accept JSON:API, sem credenciais literais. URL e parâmetros MUST representar a mesma query sem duplicidade acidental. Exemplos dependentes de hoje MUST usar referência civil consistente com o timezone da aplicação ou exigir preenchimento explícito documentado, sem deixar mês futuro como exemplo histórico válido. Assertions MUST validar contrato e limites editoriais sem depender de texto literal de variante diária ou quantidade mínima de cartões. Arquivos de outras capacidades MUST NOT ser alterados por conveniência desta mudança.

#### Scenario: Consulta padrão e filtros habilitados
- **WHEN** o consumidor abre a requisição principal de Insights no Bruno
- **THEN** pode executar sem filtros e habilitar ambos os campos para selecionar um mês
- **AND** salvar/abrir a requisição não duplica os parâmetros na URL

#### Scenario: Exemplos válidos
- **WHEN** os exemplos de vigente e histórico são executados com conta controlada e suas pré-condições documentadas
- **THEN** a API responde `200` JSON:API com estrutura, períodos e limites correspondentes
- **AND** as assertions aceitam qualquer variante válida e seleção elegível

#### Scenario: Exemplos negativos
- **WHEN** os exemplos enviam par incompleto, mês inválido, futuro ou parâmetro desconhecido
- **THEN** as assertions verificam `422`, errors JSON:API e `source.parameter` correspondente
- **AND** nenhum exemplo exige credenciais commitadas ou alteração de dados de produção
