## ADDED Requirements

### Requirement: Contexto dedicado com leitura direta e sem escrita em despesas

O sistema MUST manter Insights como contexto dedicado, responsável por análise, elegibilidade, seleção e composição das observações. Insights MUST consultar diretamente os dados de despesas no banco compartilhado somente pela sua Infrastructure, sem consumir classes, Models, Repositories, UseCases ou endpoints de Expense. MUST NOT criar, editar, excluir ou recategorizar despesas. Domain e Application de Insights MUST permanecer independentes do framework e da persistência; a dependência do schema de despesas MUST permanecer na Infrastructure.

#### Scenario: Análise independente do CRUD
- **WHEN** Insights precisa de totais e distribuição de despesas por período
- **THEN** sua Infrastructure consulta o banco e entrega dados tipados ao contexto
- **AND** nenhum componente de Expense é chamado ou importado e nenhum registro é alterado

### Requirement: Consulta pessoal autenticada e isolada por proprietário

O sistema MUST oferecer `GET /api/insights` somente sob autenticação, conta ativa, e-mail verificado e as políticas existentes de throttle autenticado e extensão de sessão. MUST obter o proprietário da identidade autenticada e restringir todas as fontes de cálculo a suas despesas antes de agregações, rankings e comparações. MUST NOT aceitar parâmetros de query no MVP, incluindo proprietário, família, período, limite ou paginação; parâmetros recebidos MUST produzir `422` em JSON:API sem alterar o escopo de acesso.

#### Scenario: Estatísticas da própria conta
- **WHEN** uma conta autenticada consulta insights e outras contas possuem despesas no mesmo período
- **THEN** os candidatos e mensagens consideram exclusivamente registros da conta autenticada
- **AND** despesas de outras contas não participam de totais, denominadores, rankings ou histórico

#### Scenario: Consulta sem autenticação
- **WHEN** `GET /api/insights` é solicitado sem token válido
- **THEN** a API responde `401` em JSON:API sem revelar insights

#### Scenario: Tentativa de escolher o proprietário ou período
- **WHEN** a conta envia `user_id`, `period` ou qualquer outro parâmetro de query
- **THEN** a API responde `422` em JSON:API identificando o parâmetro inválido
- **AND** nenhuma estatística de outro escopo é retornada

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

O sistema MUST resolver uma data civil de referência no timezone configurado da aplicação. Observações do mês atual MUST considerar do primeiro dia à referência, inclusive. Comparações correntes MUST usar somente dias completos do mês atual e o intervalo equivalente do mês anterior, limitando ambos ao número de dias comum quando os meses diferirem em duração. MUST exigir pelo menos sete dias completos comuns. MUST NOT comparar mês parcial com mês completo como períodos equivalentes, projetar fechamento ou substituir silenciosamente o período por meses fechados. Toda mensagem financeira MUST informar um período compatível com o fato apresentado.

#### Scenario: Consulta no dia 12
- **WHEN** a referência é o dia 12 e ambos os meses possuem pelo menos 11 dias
- **THEN** as comparações usam dias 1 a 11 de cada mês
- **AND** as observações descritivas podem incluir registros do dia 12

#### Scenario: Meses de duração diferente
- **WHEN** a referência é 31 de março de 2027 e o mês anterior tem 28 dias
- **THEN** a comparação usa dias 1 a 28 de março e de fevereiro
- **AND** os dias 29 e 30 de março não entram na comparação equivalente

#### Scenario: Início do mês sem intervalo comparável suficiente
- **WHEN** a consulta ocorre no primeiro dia do mês ou antes de completar sete dias comuns
- **THEN** nenhuma comparação corrente é emitida
- **AND** observações descritivas ou onboarding continuam sujeitos à sua elegibilidade própria

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

O sistema MUST gerar `registered_amount_increase` ou `registered_amount_decrease` somente quando cada janela possui a base descritiva mínima, a diferença absoluta alcança pelo menos R$ 50 e a variação relativa alcança pelo menos 20%, além do mínimo de dias completos comuns. MUST usar o total anterior como denominador e não emitir percentual se ele for zero. MUST produzir no máximo uma direção de variação para o mesmo par de períodos e mencionar valores registrados, sem associar redução automaticamente a um comportamento positivo.

#### Scenario: Redução elegível
- **WHEN** períodos equivalentes elegíveis somam R$ 500 anteriormente e R$ 350 atualmente
- **THEN** o candidato indica 30% menos valor registrado no intervalo atual
- **AND** não afirma que a conta economizou R$ 150 ou melhorou seus hábitos

#### Scenario: Diferença absoluta irrelevante
- **WHEN** períodos com base descritiva elegível somam R$ 100 e R$ 125
- **THEN** a variação de 25% não produz comparação porque a diferença é menor que R$ 50

#### Scenario: Período anterior vazio
- **WHEN** o total anterior é zero e existem registros no atual
- **THEN** o sistema não calcula percentual de aumento nem considera o histórico comparável

### Requirement: Liderança recorrente baseada em períodos elegíveis

O sistema MUST gerar `category_lead_streak` somente se a mesma categoria diferente de `other` é líder única no mês atual e nos dois meses anteriores completos. Cada período MUST possuir base descritiva mínima e participação da líder de pelo menos 30%. A mensagem MUST distinguir a liderança corrente parcial dos meses fechados e MUST NOT inferir continuidade a partir de períodos vazios ou empatados.

#### Scenario: Liderança em três períodos
- **WHEN** alimentação lidera de forma única com participação suficiente no mês atual até a referência e nos dois anteriores, todos elegíveis
- **THEN** um candidato pode informar que alimentação segue líder após liderar os dois meses anteriores
- **AND** não trata o mês atual como encerrado

#### Scenario: Mês intermediário sem evidência
- **WHEN** a categoria lidera no mês atual e no anterior, mas o outro mês considerado tem dados insuficientes
- **THEN** o sistema não emite liderança recorrente
- **AND** uma observação corrente de concentração ainda pode ser elegível

### Requirement: Onboarding contextual e tratamento de other

O sistema MUST retornar `first_expense` como única mensagem quando não há despesas históricas até a referência. Quando existem despesas históricas e nenhuma observação financeira é elegível, MUST oferecer no máximo uma mensagem `insufficient_history`, distinguindo poucos registros recentes de histórico sem registros no mês atual. MUST gerar `category_review` somente com base descritiva elegível e pelo menos 50% do valor corrente em `other`. MUST NOT inferir o conteúdo de `other`, chamar todos esses registros de incorretos ou pendentes, nem consultar Identity para personalização ou exclusão de conta.

#### Scenario: Conta sem registros
- **WHEN** a conta não possui despesas históricas até a referência
- **THEN** a resposta contém somente `first_expense`
- **AND** não inventa fatos financeiros para completar a lista

#### Scenario: Histórico antigo sem registros recentes
- **WHEN** existem despesas anteriores à janela de análise, mas nenhuma no mês corrente
- **THEN** a orientação reconhece a ausência de registros recentes
- **AND** não sugere cadastrar a primeira despesa nem celebra economia

#### Scenario: Other predominante
- **WHEN** um mês com base descritiva elegível contém 60% do valor em `other`
- **THEN** a orientação pode convidar a revisar categorias
- **AND** o total financeiro continua incluindo esse valor
- **AND** a mensagem não presume erro, classificação pendente ou comportamento específico

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

O sistema MUST compor mensagens por templates completos de catálogo determinístico, com pelo menos quatro variantes revisadas por conjunto elegível. MUST preencher somente fatos calculados e aprovados pela elegibilidade. Títulos MUST ter no máximo 32 caracteres Unicode e descrições no máximo 110 após interpolação. MUST usar humor leve sobre a situação, sem ofensa, julgamento pessoal ou sarcasmo inadequado a categorias sensíveis. MUST usar uma alternativa curta e completa quando uma variante não couber; MUST NOT truncar números, qualificações ou períodos necessários à veracidade. MUST NOT combinar aleatoriamente título, descrição e piada independentes, chamar IA ou outro serviço externo para gerar textos em runtime.

#### Scenario: Mensagem de alimentação
- **WHEN** a participação calculada de alimentação é 38% e a variante escolhida se refere a esse fato
- **THEN** o texto pode ser "Alimentação levou 38% do valor registrado neste mês. Veio com fome."
- **AND** não acrescenta alegações sobre dieta, renda ou total de gastos fora do aplicativo

#### Scenario: Parâmetros que excedem o orçamento editorial
- **WHEN** uma variante interpolada ultrapassa o limite de título ou descrição
- **THEN** o sistema usa uma alternativa completa compatível com o limite e o mesmo fato
- **AND** não devolve um texto truncado que perca contexto ou significado

### Requirement: Rotação diária estável sem histórico de visualização

O sistema MUST selecionar variantes deterministicamente por conta, chave editorial da observação e dia civil de referência, sem persistir histórico de entrega ou visualização. Para a mesma conta, chave, versão do catálogo e conjunto elegível, MUST manter a variante em consultas no mesmo dia e escolher outra no dia seguinte. Mudanças em números interpolados MUST NOT alterar a variante por si só. Alterações nos fatos MUST recalcular imediatamente os candidatos e valores, sem congelar a resposta por dia. A rotação MUST permitir repetição após o ciclo e MUST NOT prometer novidade na próxima visita espaçada ou estabilidade quando o conjunto elegível mudar.

#### Scenario: Duas consultas no mesmo dia
- **WHEN** a conta consulta duas vezes no mesmo dia, mantendo os mesmos fatos e catálogo
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
- **AND** isso não exige consultar ou gravar um histórico de mensagens vistas

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
