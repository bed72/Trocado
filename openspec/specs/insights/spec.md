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

O sistema MUST calcular fatos sobre valores registrados em centavos BRL e data de ocorrência, não cadastro. MUST incluir other, excluir despesas removidas e ignorar datas futuras. Somas, razões e limiares MUST permanecer exatos, sem overflow ou float; fatos relacionados MUST vir de snapshot consistente. Valores publicados MUST derivar desses fatos e ser formatados integralmente em BRL, omitindo somente centavos iguais a zero. MUST NOT publicar percentuais, proporções disfarçadas ou inferir que os registros representam todos os gastos, renda, saldo, economia ou melhoria de hábitos.

#### Scenario: Cadastro retroativo e data futura
- **WHEN** a conta cadastra hoje uma despesa de mês anterior e outra com data futura
- **THEN** a primeira participa do período de ocorrência e a segunda não entra antes da referência

#### Scenario: Valor diminuto com grande variação percentual
- **WHEN** o total anterior é R$ 2 e o atual R$ 10
- **THEN** não emite comparação por falta de base material
- **AND** não substitui a observação inelegível por percentual ou dinheiro de variação fabricado

#### Scenario: Ausência de registros no período atual
- **WHEN** existe histórico anterior mas nenhum registro no vigente
- **THEN** não afirma redução, economia ou melhoria de hábitos
- **AND** não trata a conta como se nunca tivesse registrado despesas

#### Scenario: Soma acima do limite de um inteiro de máquina
- **WHEN** a soma de registros válidos excede o inteiro nativo
- **THEN** conserva o valor exato com representação adequada e formatação BRL por strings
- **AND** não publica montante baseado em overflow, float ou arredondamento silencioso

#### Scenario: Alteração concorrente
- **WHEN** uma escrita ocorre durante a leitura analítica
- **THEN** os fatos relacionados representam uma versão consistente dos dados confirmados no mesmo statement
- **AND** não misturam numerador anterior à escrita com denominador posterior

#### Scenario: Data e proprietário preservados
- **WHEN** há lançamentos retroativos, futuros e de outras contas
- **THEN** somente ocorrências elegíveis do proprietário entram no valor publicado
- **AND** snapshot, precisão e descarte de removidos permanecem inalterados

#### Scenario: Valor exato com centavos e acima do inteiro nativo
- **WHEN** os fatos contêm 35000, 35001 ou 9223372036854775808 centavos
- **THEN** a formatação produz respectivamente R$ 350, R$ 350,01 e R$ 92.233.720.368.547.758,08
- **AND** não usa float, arredondamento, sufixo mil/mi ou percentual

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

O sistema MUST exigir base descritiva de cinco lançamentos em três datas distintas e total mínimo de R$ 100. Categoria MUST exigir líder única diferente de other e participação exata mínima de 30%; lançamento MUST exigir participação mínima de 40%, produzindo no máximo um candidato. Mensagem MUST publicar o valor real da categoria ou do lançamento e interpretar o destaque nos registros. MUST NOT inferir excesso, gasto anormal ou incompatibilidade com renda/orçamento.

#### Scenario: Categoria dominante elegível
- **WHEN** o mês tem seis lançamentos em quatro datas, total de R$ 500 e Alimentação é líder única com R$ 200
- **THEN** o candidato identifica Alimentação e R$ 200 como categoria líder nos registros
- **AND** não publica 40% nem infere dieta, renda ou frequência de compras

#### Scenario: Empate de categorias
- **WHEN** duas categorias compartilham o maior valor registrado
- **THEN** nenhuma delas é apresentada como líder única ou vencedora

#### Scenario: Volume insuficiente
- **WHEN** todos os registros se resumem a dois lançamentos no mesmo dia
- **THEN** não produz concentração com aparência de padrão estabelecido

#### Scenario: Lançamento concentrado mas não necessariamente atípico
- **WHEN** uma base elegível contém um lançamento de R$ 400 em um total de R$ 800
- **THEN** pode identificar R$ 400 como maior lançamento
- **AND** não afirma anormalidade, supérfluo, incompatibilidade com renda ou participação percentual

#### Scenario: Categoria líder com valor real
- **WHEN** Alimentação lidera com R$ 200 num total elegível de R$ 500
- **THEN** o card identifica Alimentação e R$ 200 com a condição de categoria líder
- **AND** não substitui a informação por percentual, metáfora ou datas sem interpretação

#### Scenario: Empate ou base insuficiente
- **WHEN** não existe líder única ou a base descritiva é insuficiente
- **THEN** nenhuma categoria é apresentada como vencedora

### Requirement: Comparações do total com base material nos dois períodos

O sistema MUST gerar aumento ou redução somente quando ambas as janelas têm a base descritiva mínima, diferença absoluta de ao menos R$ 50 e variação exata de ao menos 20%, usando total anterior positivo como denominador. Vigente MUST exigir sete dias completos comuns; histórico MUST comparar meses completos, incluindo seus últimos dias sem equiparar duração ou média diária. MUST emitir somente uma direção por par e publicar **diferença monetária absoluta** com a direção correta. MUST NOT apresentar redução como economia/virtude ou aumento como descontrole. Intervalos exatos MUST permanecer em period; texto vigente MUST identificar comparação com o mesmo intervalo do antecedente, sem exigir repetir datas/dias/anos no par.

#### Scenario: Redução elegível
- **WHEN** janelas elegíveis somam R$ 500 anteriormente e R$ 350 no selecionado
- **THEN** informa R$ 150 a menos nos registros da janela selecionada
- **AND** não publica 30% nem afirma economia ou melhoria de hábitos

#### Scenario: Diferença absoluta irrelevante
- **WHEN** períodos com base elegível somam R$ 100 e R$ 125
- **THEN** a variação não produz comparação porque a diferença é menor que R$ 50

#### Scenario: Período anterior vazio
- **WHEN** o total anterior é zero e existem registros no selecionado
- **THEN** não calcula variação relativa nem considera o histórico comparável

#### Scenario: Total mensal não é média diária
- **WHEN** agosto registra R$ 400 e setembro R$ 500 com bases elegíveis, e setembro é selecionado depois do encerramento
- **THEN** informa R$ 100 a mais em setembro contra agosto completo
- **AND** não reduz agosto para 30 dias, não exclui seu dia 31 nem apresenta média diária

#### Scenario: Aumento material
- **WHEN** outubro parcial registra R$ 350 a mais que a janela equivalente de setembro
- **THEN** um par válido é “Total registrado subiu” e “R$ 350 a mais que no mesmo intervalo de setembro.”
- **AND** period conserva os dias completos exatos dos dois meses

#### Scenario: Redução e histórico
- **WHEN** setembro encerrado registra R$ 150 a menos que agosto inteiro
- **THEN** o texto informa R$ 150 a menos em setembro contra agosto, sem falar em mesmos dias
- **AND** não afirma que o usuário economizou ou merece elogio por essa redução

#### Scenario: Variação sem base material
- **WHEN** o anterior é zero ou a diferença absoluta/relativa não atinge os limiares existentes
- **THEN** não produz comparação nem dinheiro de variação fabricado

### Requirement: Liderança recorrente baseada em períodos elegíveis

O sistema MUST exigir a mesma líder única diferente de other no selecionado e nos dois antecedentes completos, com base descritiva e participação mínima de 30% em cada período. MUST publicar o valor dessa categoria **somente no mês selecionado** e interpretar a liderança pelo terceiro mês. O span de três períodos MUST permanecer em period, incluindo limite parcial no vigente. MUST NOT somar três meses e apresentar o resultado como montante do selecionado, inferir continuidade a partir de empate/vazio ou projetar fechamento.

#### Scenario: Liderança em três períodos
- **WHEN** Alimentação lidera isoladamente o vigente e os dois antecedentes completos, todos elegíveis
- **THEN** informa o valor de Alimentação no selecionado e a liderança pelo terceiro mês
- **AND** period inclui o limite vigente parcial, sem projetar fechamento

#### Scenario: Mês intermediário sem evidência
- **WHEN** a líder do selecionado e do anterior tem base insuficiente no outro antecedente
- **THEN** não emite liderança recorrente
- **AND** concentração no selecionado ainda pode ser elegível

#### Scenario: Liderança histórica
- **WHEN** setembro é selecionado em outubro e a mesma categoria lidera julho, agosto e setembro elegíveis
- **THEN** publica seu valor de setembro e a recorrência comprovada
- **AND** period abrange julho a setembro completos, sem incluir outubro

#### Scenario: Moradia por três meses
- **WHEN** Moradia lidera nos três períodos e soma R$ 1.800 no outubro selecionado
- **THEN** um par válido é “Moradia” e “R$ 1.800 em outubro; lidera pelo terceiro mês.”
- **AND** o valor não é a soma de agosto, setembro e outubro

#### Scenario: Antecedente inválido
- **WHEN** um dos antecedentes é vazio, empatado ou não elegível
- **THEN** não produz liderança recorrente
- **AND** concentração mensal ainda pode ser elegível

### Requirement: Onboarding contextual e tratamento de other

O sistema MUST retornar first_expense como única mensagem somente no vigente sem histórico até a referência. Com histórico e sem observação financeira elegível, MUST oferecer no máximo um insufficient_history, distinguindo existência de registros selecionados e mês vazio. Histórico MUST usar insufficient_history contextualizado por mês/ano, mesmo antes do primeiro registro, nunca first_expense. Mensagens MUST ser claras e acolhedoras, sem preencher espaço com elogios, culpa ou interpretações de economia. MUST NOT fabricar montante onde não há observação elegível. Todos conservam period null.

Category_review MUST exigir base elegível e participação exata de other de ao menos 50%; MUST publicar o valor registrado em Outros e permitir orientação concreta de revisão, sem afirmar que tudo está errado/pendente ou inferir seu conteúdo. MUST NOT consultar Identity para personalização/exclusão.

#### Scenario: Conta sem registros
- **WHEN** a conta consulta o vigente e não possui despesas históricas até hoje
- **THEN** retorna somente first_expense com convite ao primeiro registro
- **AND** não inventa fatos financeiros para completar a lista

#### Scenario: Histórico antigo sem registros recentes
- **WHEN** há despesas anteriores à janela analítica, mas nenhuma no vigente
- **THEN** informa ausência de registros no mês selecionado sem julgamento
- **AND** não sugere primeira despesa nem celebra economia

#### Scenario: Other predominante
- **WHEN** Outros contém R$ 300 de um total elegível de R$ 500 no selecionado
- **THEN** informa R$ 300 em Outros e permite orientar revisão das categorias
- **AND** o total continua incluindo esse valor, sem publicar 60% ou presumir erro

#### Scenario: Mês anterior ao primeiro registro
- **WHEN** a primeira despesa da conta ocorre em outubro de 2026 e a seleção é setembro de 2026
- **THEN** retorna insufficient_history identificando setembro de 2026 sem registros
- **AND** não usa fatos de outubro nem convida a cadastrar a primeira despesa

#### Scenario: Poucos registros históricos
- **WHEN** setembro de 2026 contém dois lançamentos e é consultado em outubro
- **THEN** informa base insuficiente em setembro de 2026
- **AND** não aponta falta de registros de outubro nem promete Insight com mais um lançamento

#### Scenario: Primeiro registro e mês vazio
- **WHEN** não existe histórico no vigente ou o selecionado está vazio com contexto histórico
- **THEN** o primeiro caso convida ao primeiro registro e o segundo informa ausência naquele mês
- **AND** nenhum celebra economia ou inventa dinheiro para preencher o card

#### Scenario: Base insuficiente
- **WHEN** existem registros mas não sustentam observação financeira
- **THEN** informa base insuficiente no mês, sem prometer que mais um registro garantirá Insight
- **AND** não afirma necessariamente que há poucos lançamentos quando falha outro critério de base

#### Scenario: Outros com valor
- **WHEN** Outros soma R$ 300 numa base elegível e atinge o limiar existente
- **THEN** o texto informa R$ 300 em Outros e pode sugerir revisar categorias
- **AND** não publica participação nem presume erro de classificação

### Requirement: Seleção relevante sem preenchimento artificial

O sistema MUST retornar no máximo seis, sem mínimo, por prioridade e desempates explícitos: comparação do total, liderança, categoria, lançamento e orientações. MUST deduplicar informação/assunto/período antes de compor e conferir unicidade textual final, ignorando caixa, espaços redundantes, pontuação e emoji decorativo. Liderança MUST substituir concentração da categoria e lançamento sobrepostos; concentração de categoria MUST suprimir lançamento da mesma categoria/período. MUST preservar fatos realmente distintos, manter maior prioridade em colisão e resolver somente o lote final de UUIDs, sem reposição artificial. MUST permitir reaparecimento em outra consulta sem histórico de visualização.

#### Scenario: Observações equivalentes de alimentação
- **WHEN** Alimentação é elegível para liderança recorrente e concentração no selecionado
- **THEN** conserva somente a liderança recorrente para esse assunto
- **AND** não reapresenta a concentração com outra redação

#### Scenario: Maior lançamento na categoria selecionada
- **WHEN** a categoria selecionada e o maior lançamento elegível têm o mesmo assunto e período
- **THEN** suprime o card do lançamento por redundância

#### Scenario: Poucos fatos relevantes
- **WHEN** somente duas observações não redundantes são elegíveis
- **THEN** retorna duas mensagens sem completar artificialmente seis

#### Scenario: Sobreposição e fatos distintos
- **WHEN** alimentação gera liderança e concentração, enquanto outro fato monetário distinto é elegível
- **THEN** conserva apenas liderança para alimentação e não remove o fato distinto

#### Scenario: Colisão e reaparecimento
- **WHEN** dois pares diferem apenas cosmeticamente
- **THEN** conserva o primeiro priorizado antes de resolver UUIDs
- **AND** pode mostrá-lo novamente em outra consulta

### Requirement: Catálogo curto com personalidade e fidelidade aos fatos

O sistema MUST usar catálogo determinístico em português, com quatro variantes completas por conjunto. MUST priorizar valor real e interpretação direta, sem frases decorativas de palco/pódio, sarcasmo obrigatório, elogio genérico ou mero relatório de datas. Card MUST ter até 80 grafemas estendidos após normalização de linha única em title + espaço + description; título MUST ter até 24. MUST contar acentos compostos, emojis, espaços e pontuação corretamente, sem truncamento.

Mensagens financeiras MUST conter montante BRL integral calculado e interpretação compatível; percentuais/proporções MUST NOT aparecer. Referência temporal natural MUST ser suficiente no texto, enquanto period fornece dias/anos/intervalos exatos. Alternativas compactas MUST poder apoiar o contexto temporal financeiro no period estruturado, sem repetir datas; onboarding histórico MUST conservar mês/ano no texto porque seu period é null. MUST preservar valor, assunto e direção/condição ao compactar, sem trocar variante por tamanho do montante. MUST falhar explicitamente se nenhuma alternativa completa válida couber, sem parcial ou onboarding fabricado. MUST NOT usar IA, serviço externo ou combinar fragmentos independentes.

#### Scenario: Mensagem de alimentação
- **WHEN** Alimentação concentra R$ 200 no setembro de 2026 selecionado
- **THEN** o par identifica Alimentação, R$ 200 e seu destaque com referência natural
- **AND** period conserva as datas/ano exatos, sem exigir participação, dieta ou alegações sobre gastos externos

#### Scenario: Parâmetros que excedem o orçamento editorial
- **WHEN** uma variante interpolada excede o título de 24 ou o par de 80 grafemas
- **THEN** usa alternativa completa da mesma variante ou falha explicitamente
- **AND** não corta identificação/dinheiro, muda variante por tamanho ou remove a interpretação

#### Scenario: Comparação parcial compacta
- **WHEN** outubro de 2026 até dia 12 tem R$ 350 a mais nos dias completos 1 a 11 contra setembro
- **THEN** o texto informa R$ 350 a mais que no mesmo intervalo de setembro
- **AND** period identifica os dias 1 a 11 de ambos sem incluir dia 12 ou sugerir fechamento

#### Scenario: Comparação histórica compacta
- **WHEN** setembro de 2026 encerrado registra R$ 100 a mais que agosto inteiro
- **THEN** interpreta R$ 100 a mais em setembro contra agosto, com as datas exatas em period
- **AND** não diz até hoje, neste mês no sentido de outubro ou mesmos dias

#### Scenario: Percentual extremo e rótulo longo
- **WHEN** uma comparação interna excede 100% ou uma observação usa rótulo longo como Presentes e doações
- **THEN** mantém rótulo e montante real integral em uma alternativa dentro de 80/24 quando representável
- **AND** não publica percentual, usa float ou abrevia dinheiro; se nenhuma alternativa integral couber, falha explicitamente

#### Scenario: Falha editorial não é onboarding
- **WHEN** nenhuma alternativa preserva identificação, dinheiro e significado dentro dos limites
- **THEN** falha explicitamente pelo tratamento existente
- **AND** não fabrica histórico insuficiente ou publica coleção parcial/truncada

#### Scenario: Limites e Unicode
- **WHEN** pares têm 80/81 grafemas incluindo separador, acento combinante ou emoji composto
- **THEN** aceita 80, e 81 exige alternativa completa ou falha explícita
- **AND** título acima de 24 também não é aceito

#### Scenario: Montante que não cabe
- **WHEN** o montante integral excede até a alternativa mínima disponível
- **THEN** falha explicitamente
- **AND** não arredonda, abrevia, remove o valor ou troca por piada e datas

### Requirement: Rotação diária estável sem histórico de visualização

O sistema MUST escolher variantes deterministicamente por conta, versão, chave editorial e dia civil de consulta, distinguindo tipo/assunto/estado/mês/modo. Mesma consulta no mesmo dia MUST ser estável; dia seguinte MUST usar outra variante para a mesma chave/conjunto. Mudanças apenas no montante MUST atualizar o valor imediatamente sem trocar variante ou UUID por si sós. Histórico MUST girar pelo dia da consulta, não fim do mês. Ciclo MUST permitir repetição; MUST NOT congelar respostas, persistir visualizações ou prometer ineditismo permanente.

#### Scenario: Duas consultas no mesmo dia
- **WHEN** a conta repete a seleção no mesmo dia com fatos e catálogo inalterados
- **THEN** recebe os mesmos candidatos, ordem e variantes sem redundância interna

#### Scenario: Dia seguinte com observação ainda válida
- **WHEN** consulta no dia seguinte com a mesma chave editorial e conjunto elegível
- **THEN** título ou descrição usa outra variante
- **AND** tipo e grupo não mudam pela rotação

#### Scenario: Nova despesa durante o dia
- **WHEN** o valor da mesma categoria elegível aumenta de R$ 300 para R$ 330 no mesmo dia
- **THEN** a consulta seguinte atualiza o montante na mesma variante
- **AND** UUID permanece se tipo, assunto e períodos efetivos não mudarem

#### Scenario: Retorno após um ciclo de variantes
- **WHEN** a conta retorna depois de um ciclo do mesmo conjunto
- **THEN** uma variante já utilizada pode reaparecer
- **AND** não consulta nem grava histórico de mensagens vistas

#### Scenario: Rotação de mês passado
- **WHEN** setembro de 2026 é consultado nos dias 12 e 13 de outubro com fatos elegíveis inalterados
- **THEN** conserva o contexto financeiro de setembro completo
- **AND** muda a variante pelo dia da consulta, sem fixar rotação em 30 de setembro

#### Scenario: Atualização retroativa
- **WHEN** uma edição confirmada altera fatos históricos no mesmo dia
- **THEN** a consulta seguinte recalcula elegibilidade e montantes pertinentes
- **AND** não depende de cache diário ou histórico de visualização

#### Scenario: Valor muda no mesmo dia
- **WHEN** a mesma categoria elegível passa de R$ 300 para R$ 330 sem mudar a identidade lógica
- **THEN** atualiza o valor na mesma variante e conserva UUID
- **AND** reavalia elegibilidade sem cache diário

#### Scenario: Rotação histórica e ciclo
- **WHEN** o mesmo mês histórico é consultado em dias consecutivos ou após um ciclo
- **THEN** muda a variante no próximo dia e admite repetição ao completar o ciclo
- **AND** period e montante continuam derivados do selecionado

### Requirement: Contrato JSON:API por grupo e tipo
O sistema MUST responder 200/data coleção insights com ID string UUIDv7 canônico estável e attributes group/type/title/description/period. MUST manter observation(category_concentration/expense_concentration), comparison(registered_amount_increase/decrease/category_lead_streak) e onboarding(first_expense/insufficient_history/category_review). Variantes MUST manter grupo/tipo. IDs MUST distinguir owner/tipo/assunto/estado/períodos por associação mínima de Core, sem texto/números/versão editorial e sem expor fingerprint/hash alternativo. MUST NOT persistir cartão/resultado ou criar endpoint individual pelo UUID.

period MUST ser null em onboarding e from/to/comparison nos financeiros com Y-m-d; comparação anterior MUST ser explícita no total e null nos demais; liderança MUST cobrir três períodos. MUST NOT devolver cor/ícone/código redundante/julgamento/ID de despesa/perfil. Flutter MUST usar attributes.type e admitir fallback visual neutro para tipo desconhecido. Sem paginação; associação estável não altera texto/data recalculados.

#### Scenario: Cartão financeiro para Flutter
- **WHEN** seleciona concentração de categoria
- **THEN** recurso UUIDv7 tem observation/category_concentration/texto/período corretos
- **AND** cliente não calcula razão/limiares

#### Scenario: Comparação com intervalos explícitos
- **WHEN** referência é 12/10/2026 e o total corrente é comparado
- **THEN** from 2026-10-01/to 2026-10-11 e comparison 2026-09-01 a 2026-09-11, com UUIDv7

#### Scenario: Cartão de onboarding
- **WHEN** retorna first_expense
- **THEN** UUIDv7, group onboarding, period null e par completo

#### Scenario: Tipo futuro desconhecido pelo cliente
- **WHEN** cliente recebe tipo sem mapeamento visual
- **THEN** renderiza título/descrição com aparência neutra
- **AND** não rejeita coleção nem deriva regras do UUID

### Requirement: Geração sob demanda sem estado analítico persistido
Insights MUST recalcular fatos/candidatos/textos sob demanda, sem persistir cartão, visualização, resultado financeiro, cache próprio ou processamento assíncrono. MUST permitir somente associação técnica de identidade em Core, resolvida em lote após validar/selecionar/deduplicar/compor todos os recursos. Agregação financeira MUST permanecer limitada/em lote/snapshot consistente, sem query por regra/categoria ou reutilização de páginas Expense. Falha de leitura/precisão/composição/registro MUST produzir falha HTTP JSON:API explícita, sem lista parcial, onboarding fabricado, hash ou UUID transitório de fallback.

#### Scenario: Categoria alterada após o cadastro
- **WHEN** classificação confirmada muda categoria
- **THEN** a próxima consulta recalcula candidatos
- **AND** não depende de cache Expense; identidade é reutilizada só se a chave lógica continuar igual

#### Scenario: Exclusão ou edição confirmada
- **WHEN** despesa é removida ou valor/data muda
- **THEN** a resposta usa fatos confirmados atuais
- **AND** não recupera cartão/conteúdo congelado do registro

#### Scenario: Histórico extenso
- **WHEN** há vários anos de despesas
- **THEN** fonte financeira usa janela limitada/existência histórica
- **AND** não pagina CRUD ou instancia cada despesa

#### Scenario: Falha de acesso ao banco
- **WHEN** leitura financeira falha
- **THEN** responde erro JSON:API
- **AND** não aloca ID nem inventa ausência/percentual

#### Scenario: Falha de associação
- **WHEN** textos finais válidos não conseguem UUIDs confirmados no Core
- **THEN** resposta falha sem data parcial/ID aleatório

### Requirement: Rótulos e análise das categorias expandidas

Insights MUST conservar os rótulos integrais existentes e reconhecer financing/Financiamentos, investments/Investimentos, taxes/Impostos e taxas, insurance/Seguros, personal_care/Cuidados pessoais, pets/Pets, gifts_and_donations/Presentes e doações e travel/Viagens. MUST aplicar as mesmas regras e incluir investimentos/financiamentos em totais/denominadores. MUST publicar valores reais sem inferir consumo, prejuízo, retorno, patrimônio, luxo, dificuldade ou capacidade financeira. MUST respeitar 80/24 com alternativas completas e sem truncar rótulos/dinheiro; grupos/tipos/envelope MUST permanecer.

#### Scenario: Concentração de cada nova categoria
- **WHEN** cada categoria expandida é líder única, concentra R$ 400 num total elegível de R$ 1.000
- **THEN** compõe seu rótulo integral, R$ 400 e a interpretação de liderança
- **AND** não publica 40% ou infere excesso/renda

#### Scenario: Investimentos no total e na interpretação
- **WHEN** cinco registros em três datas somam R$ 1.000 e Investimentos contém R$ 600
- **THEN** informa Investimentos e R$ 600 como categoria líder
- **AND** mantém aportes no denominador sem tratá-los como consumo, perda, retorno ou riqueza

#### Scenario: Liderança recorrente de nova categoria
- **WHEN** Financiamentos lidera isoladamente os três períodos com bases e participações elegíveis
- **THEN** usa o rótulo integral e o valor somente do mês selecionado, com recorrência comprovada
- **AND** conserva prioridade e deduplicação, sem inferir endividamento problemático

#### Scenario: Rótulos longos e alternativas compactas
- **WHEN** Presentes e doações, Cuidados pessoais ou Impostos e taxas entram nas variantes aplicáveis
- **THEN** o par publicado preserva o rótulo e montante integral em 80/24 grafemas
- **AND** pode apoiar o contexto financeiro em period sem corte, arredondamento ou retirada do dinheiro

#### Scenario: Viagem não implica narrativa sobre o usuário
- **WHEN** Viagens torna uma observação elegível
- **THEN** usa o rótulo e o montante registrado com interpretação factual
- **AND** não inventa destino, finalidade pessoal ou capacidade de viajar

#### Scenario: Categoria longa e investimento
- **WHEN** categoria expandida ou longa é elegível, inclusive Investimentos
- **THEN** compõe rótulo integral, montante exato e interpretação válida nos limites
- **AND** não inventa retorno, riqueza, destino de viagem ou renda

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

O sistema MUST identificar maior lançamento por descrição integral não vazia, reconhecida segura e que caiba; caso contrário MUST usar categoria/data de ocorrência, incluindo Outros. MUST publicar valor real do mesmo lançamento, nunca total da categoria ou do mês por engano. Descrição/data/categoria/valor MUST vir da mesma seleção determinística por amount DESC, category ASC, id ASC, no snapshot e owner existentes. MUST tratar conteúdo do usuário literalmente, sem interpretar marcação/instruções, reproduzir quantificação/ofensa fornecida pelo usuário ou incluir texto em logs. MUST NOT truncar, expor ID, buscar detalhes por card, mudar threshold de 40% ou inferir excesso. Alternativas MUST conservar identificação, valor e condição de maior lançamento.

#### Scenario: Descrição utilizável
- **WHEN** o maior lançamento elegível tem descrição segura Aluguel e valor de R$ 1.200
- **THEN** identifica Aluguel e R$ 1.200 como maior lançamento no selecionado
- **AND** não retorna apenas uma identificação genérica nem publica sua participação percentual

#### Scenario: Descrição ausente ou longa
- **WHEN** a descrição é null, somente whitespace ou não cabe integralmente no par
- **THEN** usa categoria/data do mesmo lançamento e seu valor integral como maior registro
- **AND** não corta a descrição com reticências nem inventa nome

#### Scenario: Descrição com quebra de linha ou marcação
- **WHEN** uma identificação reconhecida segura contém whitespace, marcação ou literal semelhante a placeholder
- **THEN** normaliza para uma linha e conserva o conteúdo literal quando cabe
- **AND** não interpreta HTML/Markdown/instruções ou confunde dinheiro de usuário com fato calculado

#### Scenario: Empate do maior lançamento
- **WHEN** existem lançamentos de mesmo valor máximo
- **THEN** categoria crescente e ID crescente desempatam conforme a regra existente
- **AND** identificação, ocorrência e valor pertencem ao mesmo registro escolhido

#### Scenario: Descrição segura e alternativa
- **WHEN** Aluguel é identificação segura e o maior lançamento vale R$ 1.200
- **THEN** o card identifica Aluguel e R$ 1.200 como maior lançamento
- **AND** ausência, descrição longa, conteúdo ofensivo/percentual/dinheiro do usuário ou falta de espaço usam categoria/data do mesmo registro

#### Scenario: Empate e texto literal
- **WHEN** dois máximos empatam ou descrição segura contém whitespace/marcação
- **THEN** preserva desempate existente, normaliza linha e não interpreta o texto

### Requirement: Identidade e períodos preservados na navegação mensal
O sistema MUST manter type/attributes/grupos/tipos/period/limite seis. UUIDv7 associado MUST distinguir owner/tipo/assunto/estado/from/to internos e comparação, incluindo onboarding com period null. MUST NOT depender de forma da URL/números/descrição/variante/dia de visita/versão editorial por si só; UUID MUST permanecer após reinício, sessão e desaparecimento temporário da mesma identidade. Comparações/liderança MUST manter períodos atuais. MUST NOT adicionar estado de navegação, ID de despesa, novos tipos/paginação. Fonte/eligibilidade continua autorizando seleção, nunca existência da associação.

#### Scenario: Período histórico público
- **WHEN** setembro selecionado compara agosto
- **THEN** from/to setembro 01–30 e comparison agosto 01–31, com UUIDv7 estável

#### Scenario: IDs não são texto ou dia de visita
- **WHEN** owner/tipo/assunto/estado/períodos históricos não mudam, mas números/variante mudam
- **THEN** UUIDv7 permanece, inclusive em outro processo
- **AND** outro mês distingue identidade

#### Scenario: Onboarding de meses distintos
- **WHEN** agosto/setembro retornam insufficient_history period null
- **THEN** cada período interno resolve UUIDv7 distinto e texto contextual

#### Scenario: Vigente avança limite efetivo
- **WHEN** a mesma conta consulta o vigente em outro dia e o período interno cresce
- **THEN** a chave/UUID da observação pode mudar pelo período, não apenas pela rotação

#### Scenario: Default e zeros normalizados
- **WHEN** default/seleção explícita/zeros à esquerda representam os mesmos períodos
- **THEN** mesmos UUIDv7 e fatos no mesmo dia

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

### Requirement: Reconhecimento positivo e sarcasmo sem ofensa

Insights MUST ser respeitoso e factual, sem insultar, humilhar, culpabilizar ou inferir saúde, renda, vício, irresponsabilidade ou dificuldade. MUST NOT exigir sarcasmo, cota de elogios/alertas ou recomendação obrigatória. Reconhecimento positivo, quando houver, MUST limitar-se a ação demonstrável, sem converter queda/ausência em economia, disciplina ou patrimônio.

#### Scenario: Ausência não prova economia
- **WHEN** não há lançamentos há três dias ou um total caiu
- **THEN** não afirma “3 dias sem delivery”, “Você guardou dinheiro” ou conquista financeira
- **AND** descreve apenas fatos conhecidos, com acolhimento quando apropriado
