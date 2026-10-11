## Context

PHP 8.5, Laravel 13.34.0 e PostgreSQL. Insights já recebe uma referência civil explícita, faz uma única leitura analítica de `expenses` e compõe mensagens por catálogo determinístico. O HTTP rejeita qualquer query parameter. A referência atual acumula três papéis: mês analisado, limite de dados e dia da rotação editorial. Simplesmente substituí-la pelo último dia do mês passado congelaria a rotação e continuaria excluindo o último dia nas comparações.

A consulta atual do maior lançamento preserva valor/categoria e desempata por `amount DESC, category ASC, id ASC`; não entrega descrição/data para identificação editorial. As respostas públicas não expõem IDs de despesas. A coleção Bruno tem somente `bruno/Insights/01 - Get Insights.bru`, sem filtros. Há edições preexistentes do usuário em arquivos de Expense/Metrics no Bruno, fora do escopo.

Fonte normativa: `specs/insights/spec.md` desta mudança. As specs principais e a evidência da mudança arquivada continuam válidas para comportamentos não modificados. Em particular, a arquitetura vigente usa `ExpenseAnalysisRepository`, não o Port mencionado no design histórico.

## Goals / Non-Goals

**Goals:** navegar por mês com contrato previsível; preservar o comportamento temporal vigente; analisar meses passados completos; mensagens curtas que identifiquem fatos; cálculo exato e isolamento; adaptação de onboarding, IDs e rotação; Bruno pronto para consumir e verificar o contrato.

**Non-Goals:** implementar slider Flutter, guardar mês preferido, timezone por usuário, filtros por categoria/valor/dia/intervalo livre, paginação, novos tipos/grupos, projeção futura, comparação normalizada por dia para meses fechados, cache, tabelas, migrations, filas, IA, alterações no CRUD de Expense ou refactor genérico dos parsers de query dos outros contextos.

## Decisions

### 1. Parâmetros opcionais como um conjunto mensal

`GET /api/insights` conserva o default. A forma filtrada é `GET /api/insights?filter[year]=2026&filter[month]=9`. Ambos presentes ou ambos ausentes; ano isolado não significa ano inteiro e mês isolado não usa ano inferido. Aceitar strings decimais de 1 a 4 dígitos para ano e de 1 a 2 para mês, incluindo zeros à esquerda; normalizar a representação. Intervalos: ano 1–9999, mês 1–12, mês não futuro e janela representável em Core.

Como a análise usa dois meses antecedentes e Core suporta datas a partir de `0001-01-01`, o primeiro mês aceito é março de 0001. Janeiro/fevereiro de 0001 retornam `422` por janela não representável, nunca erro de banco, underflow ou substituição de período. Isso é limite técnico documentado, não limite comercial de histórico.

Inspecionar a query original com decodificação única para detectar duplicidades que o parser PHP sobrescreve. Rejeitar parâmetros desconhecidos, escalar `filter`, campos extras, arrays de year/month, valores vazios, sinais, whitespace, frações e expoentes. Query é a única fonte dos filtros; corpo em GET não define o mês. Erros usam `source.parameter` com o nome público, por exemplo `filter[month]`. Duplicidades equivalentes também são inválidas. Não extrair parser compartilhado sem necessidade real.

Alternativas rejeitadas: `month=2026-09` (diverge da nomenclatura existente); aceitar qualquer filtro de Expense (altera a semântica analítica); ignorar entradas desconhecidas (esconde erros do consumidor).

### 2. Duas referências explícitas e período validado

Resolver `DatePort::today()` uma vez na borda, no timezone da aplicação. Preparar entrada coesa como `GetInsightsInput` em `Insights/Application/Data`, com data da consulta e período efetivo selecionado. Os nomes finais devem seguir os papéis da arquitetura; a entrada não carrega HTTP nem relógio. Usar `DatePeriodValueObject` de Core e uma política temporal pura de Insights para modo corrente/encerrado e períodos antecedentes, sem nova engine genérica.

Application/Domain também verificam que o período é mensal válido, corresponde ao modo e não ultrapassa o mês da consulta. Não aceitar datas incoerentes de chamadores não HTTP. Atualizar todos os chamadores/argumentos nomeados e projeções afetadas. Controller valida/prepara a entrada, UseCase obtém proprietário por `UserPort`, Repository recebe escopo temporal explícito sem resolver relógio.

| Hoje | Seleção | Descritivo | Comparação do total |
| --- | --- | --- | --- |
| 2026-10-12 | omitida ou 2026/10 | 2026-10-01 a 2026-10-12 | 2026-10-01 a 2026-10-11 vs. 2026-09-01 a 2026-09-11 |
| 2026-10-01 | 2026/10 | somente 2026-10-01 | nenhuma comparação corrente |
| 2026-10-31 | 2026/10 | outubro até dia 31 | outubro/setembro dias 1 a 30 |
| 2026-10-12 | 2026/9 | setembro inteiro | setembro inteiro vs. agosto inteiro |
| 2026-10-12 | 2024/2 | 2024-02-01 a 2024-02-29 | fevereiro inteiro vs. janeiro inteiro |
| 2026-10-12 | 2026/1 | janeiro inteiro | janeiro/2026 inteiro vs. dezembro/2025 inteiro |

O último dia do mês vigente continua sendo dia em andamento, portanto não muda automaticamente para modo encerrado. No mês passado, todos os dias já estão completos: não usar `dia de referência - 1` nem limitar ao menor mês. Comparar totais mensais de durações distintas é decisão de produto, explicitada nos textos/períodos; não é comparação de média diária.

Liderança recorrente: mês selecionado e os dois anteriores; o selecionado é parcial somente se vigente. Limiares permanecem 5 lançamentos, 3 datas, R$ 100, 30%/40%/50%, diferença de R$ 50 e 20%; comparação corrente exige 7 dias completos comuns. Meses completos satisfazem o critério temporal e mantêm as duas bases materiais. Não emitir uma comparação encerrada como fallback do mês corrente.

### 3. Projeção analítica identificável e consistente

Conservar uma leitura PostgreSQL restrita ao proprietário antes de agregar. A janela é o mês selecionado e seus dois antecedentes. História para onboarding continua limitada ao fim efetivo do mês selecionado, dentro do mesmo statement; meses posteriores não entram nos fatos.

Acrescentar `description` e `occurred_on` do maior lançamento na mesma seleção determinística existente. Não buscar detalhes depois por ID, importar ExpenseModel, ler outro proprietário ou consultar uma despesa por cartão. Mapear para projeções próprias tipadas e levar somente os fatos necessários ao candidato/compositor. Valores agregados continuam strings inteiras exatas; converter para BRL sem float na composição.

A descrição é texto de usuário, não instrução nem conteúdo confiável: normalizar whitespace para uma linha; não interpretar HTML/Markdown, executar conteúdo ou registrar a descrição em logs. Uma descrição que não cabe integralmente no par título/descrição é descartada editorialmente em favor de categoria/data. Não cortar com reticências e não substituir por um nome inferido.

Ordem de preferência para concentração de lançamento: descrição utilizável + percentual + valor quando couber; categoria + data + percentual + valor quando couber; alternativa compacta categoria + data + percentual. Valor é informação complementar; identificação, percentual e período correto são obrigatórios. Data torna útil a alternativa mesmo em `other`, sem expor ID. Os dois últimos exemplos não afirmam que todos os gastos do mês estão no app.

### 4. Catálogo informativo com orçamento explícito

Base aprovada em 11/10/2026: título até 24 e descrição até 80 caracteres Unicode, após interpolação e normalização. Não há garantia de linhas físicas em Flutter. Título identifica assunto ou período e participa do contexto; a descrição contém o fato numérico e a referência necessária. Preferir texto menor mesmo quando há orçamento sobrando. Não preencher com piadas, conselho genérico ou adjetivo.

Manter pelo menos quatro variantes completas por conjunto e rotação, sem obrigar humor nem variação artificial no assunto. Usar catálogo versionado cobrindo tipo, modo temporal, identificação regular/fallback e estados de histórico. Revisar todas as variantes, não apenas os exemplos. O usuário aprovou explicitamente a revisão 1 completa e os limites 24/80; a aprovação está registrada no catálogo, sem inferi-la do pedido inicial de criar a spec.

O catálogo completo aprovado está em [editorial-catalog.md](editorial-catalog.md), revisão 1: quatro variantes por conjunto temporal/estado, identificação com/sem valor e alternativas de magnitude por variante. Seu estado de aprovação e a evidência editorial estão registrados no próprio documento. Os exemplos abaixo continuam sendo a direção inicial; a lista de pares para implementação é o catálogo aprovado.

Exemplos de direção editorial, não lista completa aprovada:

| Tipo/modo | Título | Descrição |
| --- | --- | --- |
| Categoria, corrente | Alimentação · out/2026 | 40% do total registrado até dia 12. |
| Categoria, encerrado | Alimentação · set/2026 | 40% do total registrado no mês. |
| Maior lançamento | Maior despesa · set/2026 | Aluguel: R$ 1.200,00 · 54% do total registrado. |
| Lançamento sem descrição | Maior despesa · set/2026 | Moradia · 05/09: 54% do total registrado. |
| Comparação, corrente | Total · out/2026 | +25% nos dias 1–11 vs. 1–11 de set/2026. |
| Comparação, encerrado | Total · set/2026 | +25% no total registrado vs. ago/2026. |
| Liderança, corrente | Alimentação | Líder em ago/set e até dia 12 de out/2026. |
| Liderança, encerrado | Alimentação | Maior categoria de jul a set/2026. |
| Revisão | Outros · set/2026 | 60% do total registrado. Revise as categorias. |
| Histórico insuficiente | Set/2026: poucos dados | Registros insuficientes para uma análise. |
| Histórico vazio | Set/2026: sem registros | Nenhuma despesa registrada no mês. |

Categorias longas podem ficar na descrição quando a combinação com mês/ano exceder 24. A referência pode ficar no título ou na descrição, mas o par deve funcionar fora da dashboard e não depender de cabeçalho Flutter para ser verdadeiro. Em períodos que cruzam anos, informar anos para eliminar ambiguidade.

Nunca omitir um percentual somente porque sua variante ficou longa. Para números extremos, usar outro par completo que preserve magnitude numérica exata (percentual integral ou diferença monetária exata), direção e referência. Alternativas são parte do catálogo e devem ser comprovadas com somas acima de `PHP_INT_MAX`, percentuais acima de 100%, rótulos longos e anos distintos. Se nenhum par for seguro, falhar composição explicitamente; não devolver fato mutilado. A aprovação editorial deve verificar que os limites propostos têm alternativas suficientes para o domínio suportado.

### 5. Histórico selecionado, onboarding e identidade

No vigente, `first_expense` mantém a semântica de nenhuma despesa até hoje. Em mês passado sem fatos elegíveis, retornar no máximo `insufficient_history`, com estado de registros insuficientes ou ausentes naquele mês. Mesmo quando não existe histórico até aquele mês, não convidar a cadastrar “primeira despesa”: a conta pode já ter registros posteriores e o cartão pertence a uma consulta histórica.

`category_review` continua condicionado à base material e a 50% em Outros, com orientação localizada no mês. `period: null` em onboarding permanece; texto menciona mês/ano selecionado. Não criar novo tipo público para esses estados.

IDs continuam derivados da conta, tipo, assunto e períodos efetivos. Onboarding inclui o período interno de análise mesmo que `period` público seja null. Consultas sem filtro e filtro explícito do vigente devem produzir os mesmos IDs. Mês diferente deve distingui-los; dia de visita, variante, descrição, valor e versão editorial não alteram o ID por si sós. Desempate do lançamento conserva o algoritmo atual, sem promessa nova de ID por despesa.

### 6. Rotação depende da visita, contexto depende do mês

A chave editorial usa tipo/assunto, estado histórico, modo corrente/encerrado e mês selecionado, além da versão do catálogo. A data civil da consulta determina a rotação. Não usar o último dia do mês histórico como dia de rotação. Repetir consulta no mesmo dia e mesmo conjunto é estável; visitar no dia seguinte usa outra variante, inclusive no histórico. Despesas retroativas confirmadas recalculam fatos/seleção imediatamente; não congelar números para manter texto.

### 7. Bruno é entregável obrigatório

Atualizar `bruno/Insights/01 - Get Insights.bru` mantendo `{{baseUrl}}`, Bearer `{{accessToken}}` e `Accept: application/vnd.api+json`. Adicionar `~filter[year]` e `~filter[month]` desabilitados juntos e documentação local do contrato. URL e `params:query` precisam concordar; salvar/abrir no Bruno não pode duplicar parâmetros. Não adicionar credenciais em arquivos.

Criar exemplos focados na pasta Insights para mês passado válido, vigente explícito e rejeições (campo isolado, mês inválido/futuro e desconhecido). O exemplo histórico pode usar setembro/2026 com pré-condição de data documentada; os exemplos vigente/futuro devem derivar ambos os campos da mesma referência civil no timezone da aplicação ou exigir preenchimento explícito documentado. Não usar timezone do dispositivo silenciosamente, alterar ambientes globais nem sobrescrever arquivos de Expense/Metrics.

Assertions Bruno verificam status, JSON:API, estrutura, período e limites editoriais, não texto literal diário nem existência obrigatória de um tipo: a seleção depende das despesas da conta. Dados preparados para demonstração são exclusivamente de uma conta controlada de teste, sem seedar contas/despesas reais nesta fase. Execução de casos negativos não acessa leitura analítica após falha de validação.

### 8. Evidências por responsabilidade

- Unit Domain: política de períodos, corrente/encerrado, underflow, bissexto, limiares preservados.
- Unit Application: entrada explícita, owner, passagem dos períodos, onboarding histórico, ID e rotação separados; catálogo e alternativas com parâmetros extremos.
- Feature Infrastructure PostgreSQL: mesmo statement/snapshot, descrição/data do máximo correto, desempate, escopo owner, datas limites, valores exatos e ausência de writes.
- Feature Presentation: parâmetros válidos/ausentes, query original duplicada/malformada, erro `source.parameter`, proteções e resposta/IDs equivalentes.
- Bruno: cenários documentados e requests funcionando no ambiente controlado; não substitui as provas de persistência/isolamento.
- Arquitetura, Pint, suíte focada e observabilidade conforme regras locais durante apply. Uma query não prova por si só performance em escala, nem teste sequencial prova corrida.

## Risks / Trade-offs

- [Textos menores ficam vagos] → exigir identificação, magnitude e referência no par completo; revisão editorial de todos os conjuntos.
- [Meses com 28/31 dias têm totais diferentes por duração] → comparar totais fechados explicitamente, sem chamar períodos de dias equivalentes ou médias.
- [Histórico usa mensagens de presente] → conjuntos temporais distintos e onboarding histórico próprio.
- [Dia de fechamento congela variantes] → data de consulta separada do período financeiro.
- [Descrição longa ou com conteúdo de formatação] → tratar como texto, normalizar whitespace e usar fallback factual sem truncamento.
- [Filtros repetidos passam pelo parser] → inspecionar query original, uma decodificação e whitelist.
- [Mais dados no máximo criam query extra] → incluir tudo na projeção do mesmo statement.
- [Bruno fica obsoleto na virada de mês/ano] → exemplos dinâmicos com referência consistente ou pré-condições explícitas.

## Migration Plan

1. Aprovar catálogo/limites e autorizar apply; consultar Boost para APIs Laravel usadas.
2. Implementar a mudança vertical com testes focados e atualizar documentação existente sobre janela/descrição consumida.
3. Atualizar e executar os requests Bruno de Insights; registrar a conta controlada, data de referência e resultados sem tokens.
4. Executar verificações previstas, Pint e validação estrita; preencher evidências e checkboxes individualmente.
5. Publicar backend antes de habilitar filtros no consumidor. Flutter inicia no vigente e envia o par ao navegar; mudança de janeiro/dezembro é operação de calendário, não soma textual do mês.

Não há migration/backfill nem recurso operacional novo. Rollback restaura contrato anterior e catálogo anterior por release; consumidores com filtros precisam voltar a omiti-los, pois o backend antigo responde `422`. Não há dados analíticos para apagar. A redução dos limites não altera nomes dos atributos nem elimina grupos/tipos.

## Open Questions

### Bloqueantes para implementação, não para criação da spec

- As etapas restantes serão executadas conforme o escopo solicitado pelo usuário. A etapa de filtros/períodos e seus testes focados já foram autorizados; sua entrega não aprova antecipadamente o fechamento das demais tarefas.

### Resolvidas na etapa editorial

- Limites 24/80 e catálogo completo revisão 1 aprovados explicitamente em 11/10/2026. Evidência: resposta “Aprovar catálogo e 24/80”, registrada em `editorial-catalog.md`; task 1.1 concluída.
- Apply da etapa de filtros/períodos autorizado explicitamente pelo pedido “2. Implementar filtros e períodos”, incluindo verificação de calendário e seleção mensal. Implementação/evidências registradas em `tasks.md`.

### Não bloqueantes

- Revisão de layout/acessibilidade Flutter é externa; não afirmar validação visual neste repositório.
- Plano/performance serão medidos na implementação; índices/cache exigem justificativa própria.
