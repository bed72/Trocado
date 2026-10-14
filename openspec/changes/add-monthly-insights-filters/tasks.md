## 1. Aprovação e preparação do apply

- [x] 1.1 Preparar o catálogo editorial completo para revisão, com quatro variantes por conjunto temporal/estado e fallbacks de identificação e magnitude; confirmar limites propostos de 24/80 com o usuário e registrar aprovação real, sem converter exemplos do design em aprovação presumida.
  - Evidência editorial: [catálogo revisão 1](editorial-catalog.md), aprovado explicitamente em 11/10/2026 por “Aprovar catálogo e 24/80”. Contagem isolada dos 72 templates de descrição e oito formas de título realizada; validação OpenSpec estrita passou sem issues. Não é evidência de execução da aplicação.
- [x] 1.2 Obter autorização explícita da etapa corrente de implementação/apply, incluindo seus testes focados; revalidar OpenSpec estritamente após eventuais ajustes de produto. Criação da spec não autoriza executar testes da aplicação.
  - Autorização: pedido do usuário “2. Implementar filtros e períodos”, incluindo verificação de fevereiro, bissexto e virada de ano. Escopo limitado à entrega desta etapa; tarefas posteriores continuam pendentes.
- [x] 1.3 No apply, consultar versões/documentação Boost e instruções Lerd, confirmar campos consumidos no schema e comandos disponíveis; localizar testes irmãos de Insights e preservar trabalho preexistente, especialmente Bruno de Expense/Metrics.
  - PHP 8.5/Laravel 13.34.0 confirmados pelo Boost; Search Docs de Form Request/validação, schema de expenses, rota/middlewares, timezone UTC, instruções Lerd e vendor bins consultados. Migrations locais já aplicadas. Alterações preexistentes Bruno preservadas.

## 2. Modelar seleção e referências temporais

- [x] 2.1 Introduzir entrada coesa e tipada de Application para data da consulta e seleção mensal efetiva, mantendo relógio/timezone na borda e dependências puras de Core; atualizar chamadores/argumentos nomeados. Evidência: default/vigente explícito e inputs inválidos fora de HTTP.
- [x] 2.2 Implementar política de períodos corrente/encerrado e antecedentes, incluindo limite março/0001, calendário bissexto e virada de ano; vigente mantém dia da consulta, encerrado inclui último dia. Evidência: cenários temporais e limite inferior.
- [x] 2.3 Ajustar a geração de comparações para dias completos equivalentes no vigente e totais de meses completos no histórico; preservar todas as bases/limiares e ausência de comparação corrente com menos de sete dias. Evidência: corrente dia 12/primeiro/último dia, 28/31 dias e comparação setembro/agosto de R$ 500/R$ 400.
- [x] 2.4 Ajustar liderança recorrente para mês selecionado e dois antecedentes, sem incluir meses posteriores ou tratar vigente como fechado. Evidência: três períodos elegíveis, empate e mês intermediário insuficiente.

## 3. Evoluir a projeção PostgreSQL

- [x] 3.1 Passar períodos explícitos ao `ExpenseAnalysisRepository` e atualizar a implementação para agregar somente a janela selecionada com proprietário antes de qualquer cálculo; história até o limite efetivo no mesmo statement.
- [x] 3.2 Projetar descrição/data/categoria/valor do maior lançamento no mesmo statement, preservando desempate `amount DESC, category ASC, id ASC`; mapear fatos em Data próprio, sem imports de Expense, Model duplicado ou query por cartão.
  - Implementação e verificações focadas autorizadas pelo pedido “Vamos implementar o 3.2”. Evidência registrada abaixo; 3.3 e etapas editoriais permanecem pendentes.
- [x] 3.3 Provar em Feature PostgreSQL limites inclusivos, exclusão de meses posteriores, cadastro retroativo, bissexto, somas acima de `PHP_INT_MAX`, desempate e identificação pertencente ao owner correto; conferir um statement e ausência de writes, sem alegar corrida comprovada por execução sequencial.
  - Etapa autorizada por “Podemos seguir para a proxima”, após conclusão de 3.2. Matriz por dimensão e resultados registrados abaixo; prova restrita à projeção PostgreSQL, sem alegação de concorrência ou conclusão editorial/HTTP.

## 4. Mensagens, onboarding, rotação e identidade

- [x] 4.1 Implementar catálogo aprovado e nova versão editorial, com conjuntos corrente/encerrado, títulos factuais e contexto de mês/ano no par; remover frases genéricas e atualizar expectativas antigas sem enfraquecer veracidade/limiares.
  - Execução conjunta de 4.1–4.3 autorizada explicitamente pelo usuário; runtime `v4-monthly-editorial` e evidências abaixo.
- [x] 4.2 Implementar identificação pela descrição utilizável, normalização de whitespace e fallback categoria/data, com percentual obrigatório e valor exato quando couber; tratar marcação como texto, sem truncamento ou logs de descrição.
  - Descrição/data propagadas da projeção ao candidato; Domain exige ocorrência no período, e composição preserva texto literal e a prioridade identificação → valor complementar.
- [x] 4.3 Implementar alternativas editoriais dentro de 24/80 após interpolação, preservando magnitude de comparação por percentual ou diferença exata; verificar BRL sem float, percentuais extremos, categorias longas e referência entre anos; falha explícita se não houver alternativa segura.
  - Alternativas da mesma variante implementadas; limites, BRL, percentual compacto e falha explícita comprovados. Formas monetárias verificadas como catálogo, sem alegar um caso de seleção positiva desse último estágio em runtime; limite detalhado abaixo.
- [ ] 4.4 Adequar onboarding histórico para `insufficient_history` com mês/ano e registros ausentes/insuficientes; manter `first_expense` somente no vigente sem histórico e `category_review` com base/50% em Outros.
- [ ] 4.5 Separar rotação por dia da consulta da chave por mês/modo/estado selecionado; provar estabilidade diária, mudança no dia seguinte no histórico, ciclo de repetição e atualização retroativa sem congelar valores.
- [ ] 4.6 Preservar IDs por owner/tipo/assunto/períodos, inclusive onboarding com período público null; provar equivalência default/filtro explícito/zeros à esquerda e estabilidade frente a números/descrição/variante, distinguindo meses selecionados.

## 5. Expor filtros e preservar JSON:API

- [x] 5.1 Implementar whitelist e validação do par year/month exclusivamente na query, com detecção de duplicidade na query original, decodificação única, rejeição de estruturas/sinais/vazios/frações/expoentes/whitespace e limites civil/futuro.
- [x] 5.2 Resolver uma única data civil por consulta via DatePort e preparar a entrada no Controller fino; manter middleware, owner pelo UserPort e Response first-party, sem mudança em grupos/tipos/paginação.
- [x] 5.3 Verificar HTTP de default, vigente explícito e histórico; par incompleto, desconhecidos, futuro no mesmo/próximo ano, lower bound, zeros, GET body, duplicidade e nomes codificados, com `422` e `source.parameter` público, sem chamar Repository nas rejeições.
- [ ] 5.4 Verificar proteções, isolamento, erro de leitura/composição explícito e contrato dos períodos históricos/comparações/liderança/onboarding; garantir que texto de despesa é string serializada e nenhum ID de despesa é exposto.

## 6. Atualizar e verificar a coleção Bruno

- [x] 6.1 Atualizar `bruno/Insights/01 - Get Insights.bru` com `~filter[year]` e `~filter[month]` desabilitados juntos, mantendo consulta sem filtros, baseUrl/accessToken e Accept; documentar habilitação do par e regras de período/validação.
  - Request revisada com exemplo 2026/9 desabilitado, URL sem query duplicada e documentação em `docs`. `git diff --check` passou. Abertura/salvamento no cliente e execução continuam pendentes em 6.2/6.5.
- [ ] 6.2 Adicionar exemplos de vigente explícito e mês passado completo em `bruno/Insights/`, com seq/nome consistentes e referência civil/condições de data documentadas; verificar URL e `params:query` sem duplicidades ao salvar/abrir.
- [ ] 6.3 Adicionar exemplos negativos de ano/mês isolados, mês inválido, mês futuro e chave desconhecida, com assertions de `422` JSON:API e `source.parameter`; futuro deve continuar futuro após virada de mês/ano ou exigir preenchimento explícito documentado.
- [ ] 6.4 Adicionar assertions de sucesso para estrutura, tipos/grupos, períodos e limites Unicode sem fixar variante diária ou mínimo de cartões; manter contas/tokens em ambiente privado e não alterar outros folders/ambientes por conveniência.
- [ ] 6.5 Executar os exemplos de Insights em ambiente controlado e registrar data/timezone, pré-condições, resultados e limitações sem credenciais; confirmar default/vigente equivalentes e comparação histórica somente quando a conta tem fatos elegíveis.

## 7. Documentar e reunir evidências de conclusão

- [ ] 7.1 Atualizar documentação existente de arquitetura/API relevante para janela mensal, duas referências temporais e descrição/data consumidas da tabela, preservando dependências de contexto; não alterar evidência histórica nem marcar revisão Flutter como concluída.
- [ ] 7.2 Executar arquivos de testes afetados isoladamente e suítes focadas de Insights pelo launcher `lerd composer test -- <caminho/opções>`; executar fronteiras arquiteturais quando estrutura/contratos mudarem. Não usar Feature direto por Pest/PHPUnit/Artisan nem banco real do usuário.
- [ ] 7.3 Executar Pint `--dirty --format agent` após alterações PHP, repetir verificações afetadas se a formatação alterar código e validar OpenSpec estritamente; executar gate mais amplo somente quando o escopo/riscos e regras de fechamento exigirem.
- [ ] 7.4 Capturar tráfego das consultas afetadas em Lerd e executar `optimize_route`, documentando queries/planos e ausência de N+1 observado; não afirmar performance em escala sem medição. Se houver migrations pendentes, aplicar incrementalmente antes de fluxos dependentes, nunca `migrate:fresh`.
- [ ] 7.5 Preencher a matriz de evidências por requisito/cenário abaixo com comandos/resultados/skips/limitações e revisar task truthfulness; manter pendências editoriais/Flutter ou bloqueios explícitos. Arquivar somente após autorização e evidências suficientes.

## Matriz de rastreabilidade planejada

Esta matriz reúne evidências por etapa. A task 1.1 tem aprovação editorial registrada; a etapa de filtros/períodos possui as execuções abaixo. Células parciais e tarefas posteriores continuam pendentes; nenhuma evidência histórica anterior foi substituída.

| Requisito / cenários | Tarefas | Evidência mínima planejada | Estado |
| --- | --- | --- | --- |
| Consulta autenticada/owner, parâmetros desconhecidos e proteções | 3.3, 5.3–5.4 | Feature HTTP + PostgreSQL com contas distintas e descrição de máximo | Não comprovado |
| Filtros: default, explícito, zeros, par incompleto, inválidos, futuro, duplicidade/codificação, lower bound, corpo | 2.1–2.2, 5.1–5.3 | Unit de invariantes temporais + HTTP com query original | Comprovado nesta etapa; arquivos e comandos abaixo |
| Períodos: dia 12, dias insuficientes, último dia vigente, 28/31 dias, fechado, bissexto, ano e timezone | 2.2–2.3, 3.3, 5.2–5.4 | Unit de calendário + PostgreSQL inclusivo + HTTP relógio controlado | Regras e limites comprovados; projeção de descrição/data ainda pendente em 3.3/5.4 |
| Comparações: bases, redução, diferença irrelevante, zero, total mensal vs. média | 2.3, 3.3 | Unit de regras + Feature de agregação e períodos | Comprovado para regras/períodos; catálogo completo/extremos editoriais pendentes |
| Liderança: vigente parcial, histórico fechado, intermediário insuficiente | 2.4, 5.4 | Unit + HTTP período de três meses | Regra existente preservada e seleção histórica comprovada; fechamento de 5.4 pendente |
| Onboarding: vigente sem história, antigo, Outros, antes do primeiro registro, histórico insuficiente | 4.4, 5.4 | Unit + HTTP com estados explícitos | Não comprovado |
| Catálogo: categoria, parcial, encerrado, extremos, fallback e falha | 1.1, 4.1–4.3 | Revisão editorial + Unit com dimensões explícitas Unicode/números/períodos | Editorial aprovado; runtime não comprovado |
| Runtime editorial, fatia 4.1–4.3 | 4.1–4.3 | Unit: catálogo/variantes 24/80, BRL, identificação/fallback, extremos e referências entre anos; Feature: texto literal e fallback em vigente/encerrado | Comprovado para cenários listados abaixo; último estágio monetário tem prova de catálogo/formatador, sem seleção positiva reproduzida |
| Maior lançamento: descrição, ausente/longa, marcação, empate e owner | 3.2–3.3, 4.2, 5.4 | Feature PostgreSQL + Unit editorial + HTTP texto literal | Não comprovado |
| Projeção do maior lançamento, fatia 3.2 | 3.2 | Feature PostgreSQL: dados do mesmo registro, desempate categoria/ID, owner, null/vazio, um statement sem writes | Comprovado na borda Repository; identificação editorial e HTTP continuam não comprovados |
| Provas PostgreSQL da projeção mensal, fatia 3.3 | 3.3 | Feature PostgreSQL: limites, mês posterior, retroativo, bissexto/ano, somas exatas, desempate, owner e leitura única sem writes | Comprovado; cenários/execuções abaixo. Não comprova corrida ou comportamento editorial/HTTP futuro |
| Rotação: mesmo dia, dia seguinte, ciclo, números, mês histórico e retroativo | 4.5 | Unit/HTTP com datas da consulta distintas e fatos controlados | Não comprovado |
| Identidade/JSON:API: períodos históricos, IDs estáveis e onboarding por mês | 4.6, 5.4 | Unit IDs + HTTP envelope/períodos | Não comprovado |
| Bruno: default/par, exemplos válidos/negativos, estrutura/textos/URL | 6.1–6.5 | Coleção revisada e execução com conta controlada | Não comprovado |
| Fronteiras, documentação, formatação e observabilidade | 7.1–7.5 | Arquitetura + Pint + validação estrita + captura Lerd | Não comprovado |

## Evidências da etapa 2 — filtros e períodos

Implementação: `GetInsightsInput`, `InsightAnalysisPeriodValueObject` e `InsightPeriodModeEnum`; Repository recebe períodos explícitos, mantendo um statement PostgreSQL; Request usa query original e Controller resolve a data uma vez. Há onboarding histórico e templates encerrados com mês/ano para não descrever o histórico como mês vigente. A migração editorial completa de 4.1–4.3 **não** está concluída: o vigente conserva o catálogo anterior e maior lançamento ainda aguarda descrição/data e alternativas aprovadas. A versão transitória é `v3-monthly-periods`; a aprovação do catálogo revisão 1 permanece válida e não foi alterada por esta etapa.

Todos os comandos de teste abaixo foram executados por MCP Lerd `exec`, action `composer`, args `['test', '--', <caminho>, '--compact']` (equivalente a `lerd composer test -- <caminho> --compact`). Feature usou bancos exclusivos com preflight e migrations incrementais; não utilizou o banco operacional.

| Caminho / comando | Resultado final |
| --- | --- |
| `tests/Unit/Insights/Domain/ValueObjects/InsightAnalysisPeriodValueObjectTest.php` | 24 testes, 141 assertions, passou; calendário, limites civil, primeiro/último dia, bissexto/centúrias e antecedentes |
| `tests/Unit/Insights/Domain/ValueObjects/InsightCandidateValueObjectTest.php` | 40 testes, 147 assertions, passou; comparações fechadas consecutivas, durações distintas e primeira despesa histórica rejeitada |
| `tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php` | 11 testes, 42 assertions, passou; owner/argumentos explícitos, entradas inválidas antes da leitura e IDs preservados |
| `tests/Unit/Insights/Application/UseCases/GenerateInsightCandidatesUseCaseTest.php` | 11 testes, 33 assertions, passou; aumento 25%, redução 30%, diferença irrelevante, denominador zero e base material |
| `tests/Feature/Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php` | 41 testes, 254 assertions, passou; query original, rejeições sem Repository, equivalências, body, timezone, calendário e comparação/liderança históricas |
| `tests/Feature/Insights/InsightsApiTest.php` | 24 testes, 174 assertions, passou; contrato/proteções regressivos preservados; parâmetros desconhecidos agora identificados pelo nome público completo |
| `tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php` | 21 testes, 267 assertions, passou; owner, primeiro/último dia, meses posteriores excluídos, história limitada, snapshot de um statement e ausência de writes |
| `tests/Unit/Insights` | 236 testes, 1.585 assertions, passou após Pint; inclui as regras existentes de limiares, empate e mês intermediário insuficiente |
| `tests/Feature/Insights` | 86 testes, 695 assertions, passou após Pint |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | 26 testes, 401 assertions, passou após Pint; sem ampliar allowlists |
| `lerd` vendor_run `pint --dirty --format agent` | Executado; ajustes de estilo/imports aplicados e testes afetados repetidos |
| `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` | Passou sem issues |
| `git diff --check` | Passou |

Limitações: não houve revisão visual Flutter, execução Bruno, gate integral/paralelo ou prova nova de corrida. `migrate:status` confirmou todas as migrations locais aplicadas, sem migration nova nesta etapa. Dumps Lerd já habilitados; `optimize_route` retornou `samples: 0` e nenhuma rota. As requisições HTTP dos testes não produziram amostras de tráfego externo no watcher; 7.4 continua pendente e não há alegação de performance em escala ou ausência de N+1 medida em tráfego real.

## Coordenação com expand-expense-categories — 11/10/2026

O catálogo vigente de composição recebeu os oito rótulos aprovados na etapa de expansão. O adendo de `editorial-catalog.md` revisa quatro variantes dos conjuntos afetados e a ordem de identificação/valor sob 24/80 para esses rótulos. O usuário confirmou que esta coordenação não implementa o catálogo mensal: runtime `v3-monthly-periods` e limites 32/110 permanecem até o apply editorial desta change. Tasks 3.2–3.3, 4.*, Bruno/Flutter e fechamento permanecem pendentes, assim como suas evidências históricas. A implementação futura deve incluir todos os dezoito rótulos na matriz de composição/identificação, preservando as alternativas e a falha explícita; não reutilizar a contagem isolada como prova de runtime.

## Evidências da tarefa 3.2 — 14/10/2026

Autorização explícita: “Vamos implementar o 3.2”. Escopo: projeção analítica e verificações focadas dessa alteração, sem concluir a matriz completa de 3.3 nem as etapas editoriais.

- `ExpensePeriodAnalysisOutput` acrescenta `largestExpenseDescription` e `largestExpenseOccurredOn`, nullable, na projeção própria de Insights. A descrição original permanece literal; normalização e fallback pertencem à etapa editorial futura. Data ausente em período vazio é null; data presente é string civil canônica `Y-m-d`.
- `EloquentExpenseAnalysisRepository` seleciona descrição/data na CTE `largest`, junto de categoria/valor, preservando `amount DESC, category ASC, id ASC`. O mapping ocorre na mesma leitura, sem ID público, query adicional, Model duplicado ou imports de Expense.
- Assertions dos cenários existentes do Repository foram estendidas para provar texto literal com marcação/whitespace, isolamento contra outro owner e ocorrência futura, dados do mesmo registro no desempate categoria/ID (data não desempata), período vazio, descrição null com ocorrência presente e datas finais de meses históricos, incluindo fevereiro bissexto. As assertions existentes de leitura única, ausência de writes e somas acima de `PHP_INT_MAX` continuam passando. Não é prova de corrida concorrente nem de composição/serialização editorial.

Comandos executados pelo launcher seguro via MCP Lerd, com bancos exclusivos e migrations incrementais:

| Comando | Resultado |
| --- | --- |
| `lerd composer test -- tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 21 testes / 291 assertions, passou |
| `lerd` vendor_run `pint --dirty --format agent` | Passou sem ajustes |
| `lerd composer test -- tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 516 testes / 14.438 assertions, passou após Pint |
| `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` | Passou sem issues |
| `git diff --check` | Passou |

Boost confirmou PHP 8.5/Laravel 13.34.0 e schema `expenses.description` nullable e `occurred_on` date. `migrate:status` confirmou todas as migrations locais aplicadas; esta tarefa não cria migration. Dumps Lerd já habilitados; GET real sem credencial respondeu 401 JSON:API. `optimize_route` retornou `samples: 0`, sem rotas; não há evidência de desempenho autenticado ou ausência de N+1 em tráfego real. Task 7.4 continua pendente. Gate integral/paralelo, catálogo, Bruno e revisão Flutter não foram executados nesta fatia.

## Evidências da tarefa 3.3 — 14/10/2026

Autorização: “Podemos seguir para a proxima”, na sequência da entrega de 3.2. Esta etapa complementa as provas PostgreSQL; não altera código de produto. Arquivo proprietário: `tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php`.

| Dimensão exigida | Cenário/evidência no arquivo | Estado |
| --- | --- | --- |
| Limites inclusivos do vigente | `aggregates only the owner occurrence periods in one read without writes`: despesas nos dias 1 e 12 incluídas; dia 13 excluído; comparação termina no dia 11 | Proven |
| Limites inclusivos históricos e exclusão posterior | `reads inclusive complete historical months and excludes later occurrence and other owners in one statement`: primeiro/último dia somam 30000 e duas datas; despesa maior no primeiro dia do mês seguinte excluída; dados do máximo e dos períodos anteriores conferidos | Proven |
| Bissexto, meses de durações distintas e virada de ano | Mesmo cenário com datasets nomeados para setembro/2026, fevereiro/2024, fevereiro/2025 e janeiro/2026; último dia correto e comparação inclui 31 de agosto/janeiro/dezembro quando aplicável | Proven |
| Cadastro retroativo e releitura | `reads newly registered backdated expenses by occurrence rather than registration date without writes`: primeira leitura sem história até setembro; inserts ocorridos em 01/09 e 30/09, criados em 12/10; próxima leitura soma 50000, passa a ter história e identifica o máximo de 01/09 com descrição null/data presente | Proven |
| Somas acima de `PHP_INT_MAX` e desempate | `preserves totals above machine integer limits and breaks largest expense ties deterministically`: total 27670116110564327421, categoria 18446744073709551614; categoria crescente vence apesar do ID maior, depois ID crescente vence apesar da data posterior; descrição/data pertencem ao vencedor | Proven |
| Identificação owner-scoped | Cenários vigente e histórico incluem despesa maior de outra conta com descrição distinta; valor/categoria/descrição/data retornados continuam do owner consultado | Proven |
| Um statement e nenhuma escrita | Query log dos cenários vigente, histórico e retroativo contém somente um statement iniciado por `WITH periods`; snapshot integral de `expenses` antes/depois é idêntico. Query log restaurado em finally | Proven |

Nenhum cenário anterior foi removido. O cenário histórico foi reforçado com descrições distintas dos máximos, identificação nos períodos descritivos/comparativos, exclusão do dia imediatamente seguinte e datasets nomeados. Um cenário novo cobre cadastro retroativo/releitura e descrição null de um máximo existente. Leitura única demonstra o limite de statement da projeção; inserção e releitura sequenciais não demonstram corrida concorrente.

Todos os testes passaram via launcher Lerd em bancos exclusivos com migrations incrementais, sem skips/incomplete/risky:

| Comando | Resultado |
| --- | --- |
| `lerd composer test -- tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 22 testes / 368 assertions, passou isoladamente após a edição inicial e novamente após ajuste dos datasets/Pint |
| `lerd` vendor_run `pint --dirty --format agent` | Passou sem ajustes |
| `lerd composer test -- tests/Feature/Insights --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 107 testes / 1.046 assertions, passou após Pint |
| `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` | Passou sem issues |
| `git diff --check` | Passou |

Limitações: sem nova alteração de schema, rota ou código de produto; gate integral/paralelo e tráfego autenticado real não executados nesta etapa. Tasks 4.*, 5.4, Bruno e fechamento continuam pendentes; 7.4 mantém a limitação operacional registrada em 3.2. A comprovação da projeção não comprova normalização editorial, fallback, novos limites ou serialização dos textos futuros.

## Evidências das tarefas 4.1–4.3 — 14/10/2026

Autorização explícita: após esclarecer a dependência entre catálogo, identificação e alternativas, o usuário respondeu “Pode seguir” à pergunta que abrangia 4.1–4.3 e testes focados. Essa autorização não antecipa 4.4–4.6 ou fechamento.

Implementação:

- `GetInsightMessageTemplatesUseCase::Version = v4-monthly-editorial`: pares da revisão 1, nos modos Current/Closed e estados existentes, com quatro variantes em cada conjunto. Rótulos integrais dos dezoito identificadores preservados. Títulos genéricos/piadas removidos.
- `ExpensePeriodSummaryValueObject` e `InsightCandidateValueObject` conservam descrição/ocorrência do máximo. Período vazio rejeita identificação; período com registros exige ocorrência dentro de seus limites; outros tipos de candidato rejeitam identificação de despesa. A Application propaga os fatos originais, sem normalizar ou inventar texto no mapping.
- `ComposeInsightMessageUseCase` conta caracteres Unicode após interpolação e aplica 24/80. Identificação tenta descrição normalizada integral com/sem valor, depois categoria/data com/sem valor. Placeholders são validados no template antes da interpolação: HTML/Markdown e texto de usuário como `{month}` permanecem literais.
- O numerador da razão continua sendo o valor exato do máximo ou a diferença absoluta da comparação. BRL usa padding, separação de centavos e agrupamento por string, sem float. Templates de comparação conservam sinal, magnitude e ambos os períodos, tentando percentual regular, compacto e descrição monetária da mesma variante. Ausência de alternativa segura gera `InsightMessageCompositionException`, sem truncamento ou onboarding.
- README e ARCHITECTURE atualizados somente nas descrições pertinentes a projeção/catálogo; alterações preexistentes de Notifications preservadas. Rotas, schema, bindings e dependências não mudaram nesta etapa.

### Matriz de provas da fatia

| Dimensão / cenário | Arquivo e prova | Estado |
| --- | --- | --- |
| Todos os conjuntos temporais/estados com quatro variantes completas | `ComposeInsightMessageUseCaseTest`: enum de modos, todos os tipos aplicáveis, conjuntos de histórico, regular/compacta/monetária e contexto no par; `Version` explícita | Proven para catálogo e interpolação das dimensões exercitadas |
| Rótulos longos, anos 0001/9999, referência entre anos | `ExpandedCategoryMessageTest`: 17 categorias elegíveis × 3 tipos × 2 modos × 3 janelas civis = 306 cenários; quatro variantes/pares e limites 24/80. Outros coberto separadamente em concentração de despesa/revisão | Proven |
| Descrição utilizável/normalização e marcação literal | `ComposeInsightMessageUseCaseTest`: espaços ASCII/Unicode, quebras de linha, `<b>` e `{month}` literais, percentual e valor; `InsightsApiTest`: JSON decodificado em vigente/encerrado | Proven |
| Descrição null/whitespace/longa e fallback | Unit: ausência, whitespace Unicode e descrição de 64 caracteres; identificação categoria/data integral, percentual e valor quando cabe. HTTP: descrição ausente e fallback Outros/data nos dois modos | Proven |
| Identificação tem prioridade sobre valor | Unit: descrição de 41 caracteres Unicode cabe sem valor em todas as quatro variantes, não é trocada por categoria/data para incluir BRL; número de bytes supera 80 enquanto caracteres respeitam limite | Proven |
| Valor complementar opcional e categoria longa | Unit: valor de 100 dígitos não cabe, mas categoria/data/100% continuam integrais com Presentes e doações, sem truncamento | Proven |
| BRL exato | Unit: 1, 100, 123456 e 9223372036854775808 centavos → 0,01; 1,00; 1.234,56; 92.233.720.368.547.758,08, sem float | Proven |
| Percentual regular/compacto da mesma variante | Unit: 30 dígitos preservados quando uma regular não cabe; mesma variante escolhida antes do fallback, mantendo sinal e comparação atual/encerrada | Proven |
| Diferença e referências entre anos | `GenerateInsightCandidatesUseCaseTest`: numerador da razão = diferença 10000/15000; Unit de composição: aumento/redução, janeiro/2026 contra dezembro/2025, totais fechados ou dias 1–11 explícitos | Proven |
| Formas monetárias finais aprovadas | Unit: todos os oito textos monetários Current/Closed, diferença acima de PHP_INT_MAX, pares completos dentro de 24/80 e texto esperado independente; formatador exato comprovado por composição de despesa | Partially proven: catálogo/formatador comprovados, seleção positiva desse último estágio não reproduzida |
| Falha explícita se nenhum par cabe | Unit: comparação com magnitude de 100 dígitos e concentração artificial com percentual impossível de acomodar falham com exceção, sem remover magnitude/fabricar onboarding | Proven |
| Propagação e invariantes dos fatos | `GenerateInsightCandidatesUseCaseTest`: descrição original, ocorrência, categoria e numerador/denominador; Unit Domain: ocorrência ausente/alheia ao período, identificação em tipo errado/período vazio rejeitadas | Proven |
| Texto HTTP/IDs não expostos | `InsightsApiTest`: real Bearer, máximo e registros menores PostgreSQL, vigente/encerrado, marcação/placeholder literal ou fallback; allowlist de atributos sem ID de despesa e períodos corretos | Proven para esses quatro cenários; 5.4 completa permanece pendente |

Limite monetário: com valores inteiros em centavos e denominador positivo, a diferença em BRL frequentemente é maior que o percentual compacto. Os cenários válidos exercitados selecionaram percentual regular/compacto ou falha explícita; não foi criado ratio inconsistente/mocking para forçar uma seleção monetária positiva. A ordem de alternativas está implementada, mas a evidência do último estágio é limitada conforme a matriz, sem alegar cobertura de branch que não ocorreu.

### Rastreabilidade das expectativas editoriais antigas

Todos os cenários anteriores de composição continuam com responsabilidades equivalentes ou contrato atualizado, sem inferir equivalência por contagem:

| Cenário anterior | Destino / mudança autorizada |
| --- | --- |
| Conjuntos compactos e quatro variantes | Mesmo arquivo, cobertura Current/Closed, título factual e contexto no par; orçamento 24/80 |
| Variantes por título único | Rotação verificada pelo par título/descrição: títulos aprovados podem ser iguais nas quatro variantes |
| Liderança das seis contas explícitas | Mantidas as mesmas contas e quatro visitas; textos literais aprovados substituem piadas |
| Mudança numérica/limite do dia | Mantidos percentual atualizado e variante estável no mesmo dia/mês |
| Percentual ilimitado com alternativa que omitia magnitude | Substituído por falha explícita quando não há magnitude completa segura, conforme contrato aprovado; teste de percentual compacto extremo acrescentado |
| Unicode vs. bytes | Teste de descrição integral com 41 letras acentuadas, sem valor, preserva prova de contagem Unicode e prioridade editorial |
| Histórico existente, rótulo desconhecido e falha de orçamento | Mantidas provas de estados distintos/sem primeira despesa, categoria desconhecida e exceção explícita |
| Rótulos neutros, mês/conjunto e ciclo | Mantidos rótulos integrais no par e repetição de quatro variantes; catálogo agora coloca categoria no título |
| HTTP/Repository exigiam categoria na descrição ou único template por título | Categoria factual no título e aceitação das quatro descrições válidas, sem fixar variante diária; isolamento, query única, schema e períodos preservados |

### Execuções

Todos os comandos de teste abaixo foram executados pelo launcher `lerd composer test -- <caminho/opções> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Feature usa bancos exclusivos, manifesto/preflight e migrations incrementais; Unit não provisiona banco.

| Caminho isolado | Resultado final após Pint |
| --- | --- |
| `tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php` | 63 testes / 2193 assertions, passou |
| `tests/Unit/Insights/Application/UseCases/ExpandedCategoryMessageTest.php` | 306 / 27132, passou |
| `tests/Unit/Insights/Application/UseCases/GenerateInsightCandidatesUseCaseTest.php` | 12 / 40, passou |
| `tests/Unit/Insights/Application/UseCases/GenerateInsightCandidatesRulesTest.php` | 39 / 62, passou |
| `tests/Unit/Insights/Application/UseCases/SelectInsightCandidatesUseCaseTest.php` | 18 / 27, passou |
| `tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php` | 11 / 42, passou |
| `tests/Unit/Insights/Domain/ValueObjects/InsightCandidateValueObjectTest.php` | 44 / 151, passou |
| `tests/Unit/Insights/Domain/ValueObjects/ExpensePeriodSummaryValueObjectTest.php` | 32 / 63, passou |
| `tests/Feature/Insights/InsightsApiTest.php` | 28 / 202, passou |
| `tests/Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php` | 22 / 368, passou |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | 30 / 462, passou |

`lerd` vendor_run `pint --dirty --format agent` passou; suites focadas `tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php` passaram com **721 testes / 31490 assertions**, sem skips/incomplete/risky, após Pint. Fronteiras permanecem explícitas, sem ampliar allowlists.

`openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` passou sem issues; `git diff --check` passou. `lerd artisan migrate:status --no-interaction` confirmou todas as migrations locais aplicadas, sem pendentes.

Intercorrências registradas: primeiras execuções encontraram fixture de comparação com setembro/31 inválido, descrição de 43 caracteres que não cabia em todas as variantes, expectativa incorreta de seleção monetária e expectations antigas de título/categoria na descrição; foram corrigidas com dimensões explícitas e contrato aprovado. Uma assertion case-sensitive de “mês” também foi corrigida para aceitar “Mês”. Essas execuções falhas não contam como aprovação; os resultados finais acima são os repetidos após os ajustes.

Observabilidade Lerd: `optimize_route` retornou `samples: 0`, sem rotas; não há prova nova de desempenho autenticado/N+1 em tráfego real. Sem migration nova nesta etapa. Gate integral/paralelo, Bruno e Flutter não executados; tarefas 4.4–4.6, 5.4 e 6–7 seguem pendentes. A fatia não torna a change arquivável.

### Refinamento autorizado do compositor e calendário civil — 14/10/2026

Pedido do usuário: remover `elseif` em `ComposeInsightMessageUseCase`, ajustar hints de interpolação e isolar o cálculo repetido de mês anterior. Não é uma nova regra global nem autorização para refactor de instantes/sessões de Identity/Notifications.

- Os dois `elseif` do compositor foram substituídos por condições independentes; as invariantes existentes distinguem candidatos de comparação, concentração de despesa e liderança.
- Identificação categoria/data, BRL e rótulo mês/ano usam interpolação de strings com componentes explícitos. O compositor deixou de construir `DateTimeImmutable`/`DateTimeZone` para calcular antecedentes.
- `DatePeriodValueObject::previousMonth()` centraliza o calendário civil em Core: ancora no mês do início do período, retorna mês anterior completo e rejeita underflow de janeiro/0001. `isPreviousMonthOf()` retorna false quando o outro período começa no primeiro mês suportado. Política mensal de Insights e compositor reutilizam a operação; período de liderança usa o mês de seu endpoint final antes de derivar o predecessor.
- Provas novas em `DatePeriodValueObjectTest`: março/31 com fevereiro comum/bissexto, janeiro/dezembro, janela parcial, intervalo abrangendo vários meses (âncora no início), limites 0001/9999, underflow e timezone do processo. Sem mudança de schema, dependências ou contrato HTTP.

Verificações após Pint, sempre pelo launcher e com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Comando / caminho | Resultado |
| --- | --- |
| `lerd` vendor_run `pint --dirty --format agent` | Passou |
| `lerd composer test -- tests/Unit/Core/Domain/ValueObjects/DatePeriodValueObjectTest.php ...` | 41 testes / 115 assertions, passou isoladamente |
| `lerd composer test -- tests/Unit/Insights/Domain/ValueObjects/InsightAnalysisPeriodValueObjectTest.php ...` | 24 / 141, passou isoladamente |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php ...` | 63 / 2193, passou isoladamente |
| `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | Gate completo padrão: 1724 testes / 37329 assertions, passou; inclui arquitetura e consumidores Core/Expense/Insights/Metrics, Redis e concorrência existentes |

O gate completo padrão amplia a evidência após a extração em Core; não substitui as pendências de produto/Bruno/operação, a limitação da alternativa monetária registrada acima ou aprovação de archive. Seeds adicionais e execução paralela não executadas neste refinamento.

`openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` e `git diff --check` passaram após o registro documental.
