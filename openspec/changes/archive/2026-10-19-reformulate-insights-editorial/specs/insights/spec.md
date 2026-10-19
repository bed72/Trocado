## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Reconhecimento positivo e sarcasmo sem ofensa

Insights MUST ser respeitoso e factual, sem insultar, humilhar, culpabilizar ou inferir saúde, renda, vício, irresponsabilidade ou dificuldade. MUST NOT exigir sarcasmo, cota de elogios/alertas ou recomendação obrigatória. Reconhecimento positivo, quando houver, MUST limitar-se a ação demonstrável, sem converter queda/ausência em economia, disciplina ou patrimônio.

#### Scenario: Ausência não prova economia
- **WHEN** não há lançamentos há três dias ou um total caiu
- **THEN** não afirma “3 dias sem delivery”, “Você guardou dinheiro” ou conquista financeira
- **AND** descreve apenas fatos conhecidos, com acolhimento quando apropriado
