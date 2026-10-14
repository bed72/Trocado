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
- [x] 4.4 Adequar onboarding histórico para `insufficient_history` com mês/ano e registros ausentes/insuficientes; manter `first_expense` somente no vigente sem histórico e `category_review` com base/50% em Outros.
- [x] 4.5 Separar rotação por dia da consulta da chave por mês/modo/estado selecionado; provar estabilidade diária, mudança no dia seguinte no histórico, ciclo de repetição e atualização retroativa sem congelar valores.
- [x] 4.6 Preservar IDs por owner/tipo/assunto/períodos, inclusive onboarding com período público null; provar equivalência default/filtro explícito/zeros à esquerda e estabilidade frente a números/descrição/variante, distinguindo meses selecionados.

## 5. Expor filtros e preservar JSON:API

- [x] 5.1 Implementar whitelist e validação do par year/month exclusivamente na query, com detecção de duplicidade na query original, decodificação única, rejeição de estruturas/sinais/vazios/frações/expoentes/whitespace e limites civil/futuro.
- [x] 5.2 Resolver uma única data civil por consulta via DatePort e preparar a entrada no Controller fino; manter middleware, owner pelo UserPort e Response first-party, sem mudança em grupos/tipos/paginação.
- [x] 5.3 Verificar HTTP de default, vigente explícito e histórico; par incompleto, desconhecidos, futuro no mesmo/próximo ano, lower bound, zeros, GET body, duplicidade e nomes codificados, com `422` e `source.parameter` público, sem chamar Repository nas rejeições.
- [x] 5.4 Verificar proteções, isolamento, erro de leitura/composição explícito e contrato dos períodos históricos/comparações/liderança/onboarding; garantir que texto de despesa é string serializada e nenhum ID de despesa é exposto.

## 6. Atualizar e verificar a coleção Bruno

- [x] 6.1 Atualizar `bruno/Insights/01 - Get Insights.bru` com `~filter[year]` e `~filter[month]` desabilitados juntos, mantendo consulta sem filtros, baseUrl/accessToken e Accept; documentar habilitação do par e regras de período/validação.
  - Request revisada com exemplo 2026/9 desabilitado, URL sem query duplicada e documentação em `docs`. `git diff --check` passou. Na entrega 6.1, leitura/salvamento e execução ainda estavam pendentes; os round trips nativos de 6.2 e a execução CLI de 6.5 completaram essas evidências, sem alegar interação visual com a GUI.
- [x] 6.2 Adicionar exemplos de vigente explícito e mês passado completo em `bruno/Insights/`, com seq/nome consistentes e referência civil/condições de data documentadas; verificar URL e `params:query` sem duplicidades ao salvar/abrir.
- [x] 6.3 Adicionar exemplos negativos de ano/mês isolados, mês inválido, mês futuro e chave desconhecida, com assertions de `422` JSON:API e `source.parameter`; futuro deve continuar futuro após virada de mês/ano ou exigir preenchimento explícito documentado.
- [x] 6.4 Adicionar assertions de sucesso para estrutura, tipos/grupos, períodos e limites Unicode sem fixar variante diária ou mínimo de cartões; manter contas/tokens em ambiente privado e não alterar outros folders/ambientes por conveniência.
- [x] 6.5 Executar os exemplos de Insights em ambiente controlado e registrar data/timezone, pré-condições, resultados e limitações sem credenciais; confirmar default/vigente equivalentes e comparação histórica somente quando a conta tem fatos elegíveis.

## 7. Documentar e reunir evidências de conclusão

- [x] 7.1 Atualizar documentação existente de arquitetura/API relevante para janela mensal, duas referências temporais e descrição/data consumidas da tabela, preservando dependências de contexto; não alterar evidência histórica nem marcar revisão Flutter como concluída.
- [x] 7.2 Executar arquivos de testes afetados isoladamente e suítes focadas de Insights pelo launcher `lerd composer test -- <caminho/opções>`; executar fronteiras arquiteturais quando estrutura/contratos mudarem. Não usar Feature direto por Pest/PHPUnit/Artisan nem banco real do usuário.
- [x] 7.3 Executar Pint `--dirty --format agent` após alterações PHP, repetir verificações afetadas se a formatação alterar código e validar OpenSpec estritamente; executar gate mais amplo somente quando o escopo/riscos e regras de fechamento exigirem.
- [x] 7.4 Capturar tráfego das consultas afetadas em Lerd e executar `optimize_route`, documentando queries/planos e ausência de N+1 observado; não afirmar performance em escala sem medição. Se houver migrations pendentes, aplicar incrementalmente antes de fluxos dependentes, nunca `migrate:fresh`.
- [x] 7.5 Preencher a matriz de evidências por requisito/cenário abaixo com comandos/resultados/skips/limitações e revisar task truthfulness; manter pendências editoriais/Flutter ou bloqueios explícitos. Arquivar somente após autorização e evidências suficientes.

## Matriz de rastreabilidade final

Esta matriz reúne o resultado das etapas e do gate final. Evidências históricas abaixo permanecem datadas e não foram reescritas como se verificações posteriores já existissem. A conclusão de 7.4 usa a medição HTTP/PostgreSQL controlada, com a limitação de correlação do Lerd explicitamente aceita pelo usuário; detalhes no fechamento.

| Requisito / cenários | Tarefas | Evidência mínima planejada | Estado |
| --- | --- | --- | --- |
| Consulta autenticada/owner, parâmetros desconhecidos e proteções | 3.3, 5.3–5.4 | Feature HTTP + PostgreSQL com contas distintas e descrição de máximo | Comprovado: Repository/validação das etapas anteriores e fechamento HTTP 5.4 abaixo |
| Filtros: default, explícito, zeros, par incompleto, inválidos, futuro, duplicidade/codificação, lower bound, corpo | 2.1–2.2, 5.1–5.3 | Unit de invariantes temporais + HTTP com query original | Comprovado nesta etapa; arquivos e comandos abaixo |
| Períodos: dia 12, dias insuficientes, último dia vigente, 28/31 dias, fechado, bissexto, ano e timezone | 2.2–2.3, 3.3, 5.2–5.4 | Unit de calendário + PostgreSQL inclusivo + HTTP relógio controlado | Comprovado nas etapas temporais/Repository e HTTP; 5.4 confirma identificação do máximo no último dia e períodos completos públicos |
| Comparações: bases, redução, diferença irrelevante, zero, total mensal vs. média | 2.3, 3.3 | Unit de regras + Feature de agregação e períodos | Comprovado para regras/períodos e mensagens nas etapas editoriais/HTTP, inclusive extremos e falha explícita |
| Liderança: vigente parcial, histórico fechado, intermediário insuficiente | 2.4, 5.4 | Unit + HTTP período de três meses | Comprovado: Unit de regras, HTTP vigente e histórico; 5.4 reforça isolamento histórico com outra conta nos três meses |
| Onboarding: vigente sem história, antigo, Outros, antes do primeiro registro, histórico insuficiente | 4.4, 5.4 | Unit + HTTP com estados explícitos | Comprovado nas fatias 4.4/5.4, incluindo isolamento de histórico de outra conta e período público null |
| Catálogo: categoria, parcial, encerrado, extremos, fallback e falha | 1.1, 4.1–4.3 | Revisão editorial + Unit com dimensões explícitas Unicode/números/períodos | Comprovado para os requisitos observáveis: catálogo aprovado, quatro variantes/conjunto, magnitudes, identificação e falha; limite de branch monetário preservado no fechamento |
| Runtime editorial, fatia 4.1–4.3 | 4.1–4.3 | Unit: catálogo/variantes 24/80, BRL, identificação/fallback, extremos e referências entre anos; Feature: texto literal e fallback em vigente/encerrado | Comprovado para cenários listados abaixo; último estágio monetário tem prova de catálogo/formatador, sem seleção positiva reproduzida |
| Maior lançamento: descrição, ausente/longa, marcação, empate e owner | 3.2–3.3, 4.2, 5.4 | Feature PostgreSQL + Unit editorial + HTTP texto literal | Comprovado: desempate/projeção em Repository, composição Unit e HTTP vigente/encerrado com texto literal, null, whitespace e descrição longa; owner histórico reforçado em 5.4 |
| Projeção do maior lançamento, fatia 3.2 | 3.2 | Feature PostgreSQL: dados do mesmo registro, desempate categoria/ID, owner, null/vazio, um statement sem writes | Comprovado na borda Repository; identificação editorial/HTTP complementadas em 4.1–4.3 e 5.4 |
| Provas PostgreSQL da projeção mensal, fatia 3.3 | 3.3 | Feature PostgreSQL: limites, mês posterior, retroativo, bissexto/ano, somas exatas, desempate, owner e leitura única sem writes | Comprovado; cenários/execuções abaixo. Não comprova corrida ou comportamento editorial/HTTP futuro |
| Rotação: mesmo dia, dia seguinte, ciclo, números, mês histórico e retroativo | 4.5 | Unit/HTTP com datas da consulta distintas e fatos controlados | Comprovado na fatia 4.5: chave mensal/modo/estado, ciclo, viradas civis e recálculo de valores/elegibilidade; evidências abaixo |
| Identidade/JSON:API: períodos históricos, IDs estáveis e onboarding por mês | 4.6, 5.4 | Unit IDs + HTTP envelope/períodos | Comprovado nas fatias 4.6/5.4: normalização, período interno de onboarding e envelope público estrito, sem IDs de despesas ou coleção parcial em falhas |
| Bruno: default/par, exemplos válidos/negativos, estrutura/textos/URL | 6.1–6.5 | Coleção revisada e execução com conta controlada | Comprovado: parsing/round trips, assertions de erro/sucesso no QuickJS e execução real da CLI contra HTTP/PostgreSQL isolados, com contas elegível e vazia; evidências 6.4–6.5 abaixo |
| Fronteiras, documentação, formatação e observabilidade | 7.1–7.5 | Arquitetura + Pint + validação estrita + captura Lerd | Fronteiras/documentação/Pint/gates comprovados; seis requests HTTP reais e EXPLAIN em PostgreSQL exclusivo, com uma leitura analítica por request. optimize_route consultado; ausência de correlação com a rota temporária aceita explicitamente pelo usuário, sem alegar captura Nginx ou performance em escala |

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

## Evidências da etapa 4.4 — onboarding histórico — 14/10/2026

Autorização explícita: “Vamos seguir com a implementacao, Próxima tarefa: 4.4 — concluir as regras e provas de onboarding histórico, incluindo insufficient_history, first_expense e revisão de Outros.” Escopo desta etapa: 4.4 e suas verificações focadas.

As regras necessárias já estavam implementadas em `GenerateInsightCandidatesUseCase`, `InsightCandidateValueObject` e no catálogo `v4-monthly-editorial` pelas etapas anteriores. A revisão confirmou o contrato; esta fatia completa a evidência sem exigir alteração de produto ou do catálogo aprovado.

| Cenário / regra | Evidência |
| --- | --- |
| Vigente sem histórico até a consulta: somente `first_expense`; despesa futura não muda o estado | `MonthlyOnboardingHttpTest`: conta sem registros e conta com registro apenas em 13/10, consulta em 12/10; um recurso onboarding e `period: null` |
| Histórico antigo fora da janela, com mês selecionado vazio | HTTP no vigente e encerrado com despesa em janeiro; `insufficient_history` reconhece ausência no mês, sem primeira despesa ou economia |
| Histórico sem nenhum registro ou anterior à primeira despesa | Unit de regras com `hasHistoricalExpenses: false`; HTTP de setembro vazio e primeira despesa em outubro; somente `insufficient_history` contextualizado em set/2026 |
| Dois registros no histórico, incluindo o último dia | Unit de regras e HTTP com 01/09 e 30/09, além de registro posterior em outubro; estado de registros insuficientes, sem linguagem de outubro ou promessa de Insight por um registro adicional |
| Revisão exige 5 despesas, 3 datas e R$ 100, com participação exata de Outros ≥ 50% | Unit e HTTP em ambos os modos: 50% e 60% elegíveis; 49,99% rejeitado apesar do arredondamento para 50%; quatro despesas, duas datas e R$ 99,99 rejeitados separadamente |
| Revisão preserva Outros no denominador e usa somente o mês selecionado | Unit verifica numerador/denominador exatos; HTTP informa 50%/60% e ignora despesa posterior de R$ 9.999,99 em Outros |
| Revisão pode coexistir com orientação, mas observação financeira suprime `insufficient_history` | Unit e HTTP nos dois modos: revisão + uma orientação quando não há observação; maior despesa de 50% + revisão de 60%, sem orientação insuficiente |
| Todas as quatro variantes históricas respeitam estado, mês/ano e neutralidade | `ComposeInsightMessageUseCaseTest`: três conjuntos de onboarding históricos, set/2026, 24/80 Unicode; sem primeira despesa, mês vigente, alegação de erro/classificação pendente, economia ou garantia |
| `first_expense` é proibido como candidato histórico; onboarding conserva período público null | Provas existentes de Domain e geração, incluídas na suíte focada; HTTP novo confirma grupo/tipo/JSON:API e período null |

Verificações finais executadas por MCP Lerd `exec`, action `composer`, com launcher guardado e `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Comando / caminho | Resultado após Pint |
| --- | --- |
| `lerd` vendor_run `pint --dirty --format agent` | Passou |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/GenerateInsightCandidatesRulesTest.php ...` | 55 testes / 113 assertions, passou isoladamente |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php ...` | 66 testes / 2.280 assertions, passou isoladamente |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyOnboardingHttpTest.php ...` | 22 testes / 208 assertions, passou isoladamente em PostgreSQL exclusivo |
| `lerd composer test -- tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php ...` | 762 testes / 31.836 assertions, passou |

Sem skips/incomplete/risky inesperados. Feature usou preflight e migrations incrementais em bancos exclusivos do launcher; sem migration nova ou alterações no banco operacional. Fronteiras arquiteturais passaram, incluindo a independência de Insights em relação a Identity. Nenhuma mudança em request handling/queries de produção nesta fatia; não foi produzida nova medição de tráfego real ou desempenho. Validação OpenSpec estrita e `git diff --check` passaram.

Task 4.4 concluída. Rotação/IDs (4.5–4.6), fechamento geral de 5.4, Bruno e fechamento 6–7 continuam pendentes. Gate completo/paralelo, execução Bruno e revisão Flutter não fazem parte desta evidência; a change não está arquivável.

## Evidências da etapa 4.5 — rotação por dia da consulta — 14/10/2026

Autorização explícita: “Pode seguir para a 4.5”. A separação temporal já estava implementada em `GetInsightsUseCase`, `ComposeInsightMessageUseCase` e `SelectInsightMessageVariantUseCase`: a data civil da consulta determina a variante, enquanto versão/tipo/assunto/estado/modo/mês selecionado determinam a chave editorial. Esta etapa completa as provas, sem alterar produto, catálogo ou schema.

| Requisito / cenário | Evidência |
| --- | --- |
| Chave distingue mês selecionado, modo e estado, separadamente da visita | `ComposeInsightMessageUseCaseTest`: cinco chaves explícitas (vigente com/sem registros, setembro encerrado com/sem registros, agosto encerrado), verificadas para oito contas com o seletor de variantes; referências editoriais seguem o mês selecionado |
| Consultas no mesmo dia preservam candidatos, ordem e variantes | `GetInsightsUseCaseTest`: duas execuções iguais com leitura em cada chamada; `MonthlyRotationHttpTest`: respostas completas idênticas ao meio-dia e às 20h, com observação e revisão de Outros ordenadas |
| Histórico muda a variante no dia seguinte, preservando períodos completos e tipos/grupos | Unit integrada: setembro completo, antecedentes agosto/julho e seis leituras explícitas; HTTP: setembro consultado de 12 a 16/10, máximo de 50% e Outros de 60%, sem congelar rotação em 30/09 |
| Ciclo permite repetição e funciona nas viradas de calendário | Seletor Unit: quatro variantes atravessando fevereiro bissexto e dezembro/janeiro, além de ciclos existentes de quatro/seis e referência anterior ao epoch; Unit integrada/HTTP: quatro variantes distintas e repetição no quinto dia |
| Visita cruza mês sem trocar contexto financeiro | HTTP consulta setembro de 30/10 a 03/11; períodos/textos continuam setembro, com ciclo completo e repetição |
| Rotação usa dia civil configurado, não meia-noite UTC | HTTP com `America/Sao_Paulo`: 02:30 e 02:59:59 UTC mantêm a variante; 03:00 UTC muda a variante, preservando onboarding histórico e contexto de setembro |
| Números mudam sem trocar a variante no mesmo dia | Unit atual reforçada com igualdade do texto após substituir 60% por 62%; Unit histórica prova nova leitura e a mesma substituição, mantendo contexto de setembro |
| Nova despesa/edição retroativa recalculam valores e elegibilidade | HTTP PostgreSQL: registro de R$ 6,90 no vigente e edição de R$ 18,00 para R$ 24,90 em setembro levam Alimentação de 38% para 42% arredondados, mantendo a variante e período; redistribuição posterior remove a concentração e produz `insufficient_history` na mesma data |

O fixture de projeção local a `GetInsightsUseCaseTest` passou a aceitar modo e mês explícitos para esses cenários; nenhum suporte compartilhado ou contrato de produto mudou. As provas de recálculo são sequenciais, sem alegação de concorrência ou de execução do CRUD HTTP de Expense.

Verificações pelo MCP Lerd `exec`, action `composer`, launcher guardado e `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Comando / caminho | Resultado |
| --- | --- |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/SelectInsightMessageVariantUseCaseTest.php ...` | 15 testes / 129 assertions, passou isoladamente |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php ...` | 71 testes / 2.360 assertions, passou isoladamente |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php ...` | 13 testes / 96 assertions, passou isoladamente antes e após Pint |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyRotationHttpTest.php ...` | 5 testes / 205 assertions, passou isoladamente em PostgreSQL exclusivo |
| `lerd` vendor_run `pint --dirty --format agent` | Passou; ajustou posição de chave no fixture local de `GetInsightsUseCaseTest` |
| `lerd composer test -- tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php ...` | Após Pint: 776 testes / 32.219 assertions, passou |

Sem skips/incomplete/risky inesperados. Feature usou bancos exclusivos com preflight/migrations incrementais, sem tocar o banco operacional. Validação OpenSpec estrita e `git diff --check` passaram. Sem alteração de request handling/query de produção ou medição nova de tráfego real nesta fatia.

Task 4.5 concluída. 4.6 (IDs), fechamento geral de 5.4, Bruno e fechamento 6–7 permanecem pendentes. Esta evidência não inclui gate integral/paralelo, execução Bruno, layout Flutter ou aprovação de archive.

## Evidências da etapa 4.6 — identidade dos Insights — 14/10/2026

Autorização explícita: “Pode implementar a 4.6”. A derivação em `GetInsightsUseCase::derivedId()` já usa conta, tipo, categoria/estado e limites dos períodos de análise/comparação. Esta etapa completa as provas desse contrato, preservando o algoritmo e os IDs existentes.

| Regra / cenário | Evidência |
| --- | --- |
| Conta, assunto e mês selecionado distinguem IDs | Unit de `GetInsightsUseCaseTest` com contas 42/43, Alimentação/Saúde e agosto/setembro encerrados; HTTP com duas contas de teste e mesmos fatos/tipos em agosto/setembro |
| Tipo também participa da identidade | Unit compara aumento/redução com mesmo owner e períodos completos de setembro/agosto; HTTP/Unit comprovam IDs diferentes de concentração de despesa e revisão no mesmo mês |
| Período efetivo não se confunde com dia editorial | Unit histórica conserva ID entre visitas de 12 a 16/10; Unit corrente diferencia limites efetivos 12/10 e 13/10. A data da visita não altera o ID por si só; a mudança do período parcial altera |
| Números, descrição e variante não definem o ID | Unit histórica conserva ID com 60%→62%, concentração de despesa com Aluguel/50%→Mensalidade/55% e rotação diária; HTTP altera lançamento para R$ 55,00/Mensalidade, atualiza máximo para 52% e Outros para 62%, conserva ambos os IDs e depois muda as variantes no dia seguinte |
| Onboarding incorpora período interno apesar de `period: null` | Unit e HTTP distinguem agosto/setembro para `insufficient_history`, sozinho e com `category_review`, conservando período público null e grupo onboarding |
| Estado contextual distingue assunto de onboarding | HTTP passa de mês vazio para um registro insuficiente em setembro: mesmo tipo/mês/período público null, mas ID distinto para o novo estado |
| Default/filtro explícito/codificação/ordem/zeros não alteram identidade | HTTP com fatos financeiros e onboarding verifica igualdade integral dos recursos: default/vigente explícito/nomes codificados em ordem invertida, mês 9/09 e ano 26/0026; prova existente de `first_expense` default/explícito incluída na suíte |
| Resource type e ID opaco string permanecem | HTTP novo verifica `insights` e string hexadecimal de 64 caracteres; nenhuma despesa individual ou estado de navegação foi acrescentado |

Os testes anteriores de rotação e distinção de IDs em `GetInsightsUseCaseTest` passaram a usar projeções históricas coerentes com o mês solicitado; o limite parcial antes coberto foi preservado em cenário próprio com as duas datas efetivas corretas. Sem remoção de cenários ou enfraquecimento de assertions. Independência da versão editorial foi conferida pela revisão da derivação, que não recebe nem inclui versão/textos; não houve simulação runtime de troca da versão do catálogo.

Verificações finais pelo MCP Lerd `exec`, action `composer`, com launcher e `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Comando / caminho | Resultado após Pint |
| --- | --- |
| `lerd` vendor_run `pint --dirty --format agent` | Passou |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php ...` | 18 testes / 155 assertions, passou isoladamente |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyIdentityHttpTest.php ...` | 5 testes / 162 assertions, passou isoladamente em PostgreSQL exclusivo |
| `lerd composer test -- tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php ...` | 786 testes / 32.440 assertions, passou |

A primeira execução HTTP encontrou colisão do e-mail default de `IdentityFixture` ao preparar duas contas no mesmo cenário. O Arrange foi corrigido com e-mails explícitos e distintos; a execução isolada e a suíte acima passaram após a correção. Sem skips/incomplete/risky inesperados no resultado final.

Feature usou bancos exclusivos com preflight e migrations incrementais. Sem mudança de produto/schema ou acesso ao banco operacional; nenhuma nova medição de tráfego real foi produzida. Validação OpenSpec estrita e `git diff --check` passaram.

Task 4.6 concluída. Fechamento geral de 5.4, Bruno e fechamento 6–7 permanecem pendentes. Gate integral/paralelo, execução Bruno, revisão Flutter e aprovação de archive não estão incluídos nesta fatia.

## Evidências da etapa 5.4 — proteções e contrato HTTP mensal — 14/10/2026

Autorização explícita: “Pode seguir”, em resposta à proposta de executar 5.4. Escopo: completar provas HTTP de proteção, isolamento, períodos, serialização e falhas. Sem alteração de produto ou suporte compartilhado.

| Regra / cenário | Evidência |
| --- | --- |
| Middleware mensal preserva proteção de acesso | `route:list --path=api/insights --except-vendor -vv` confirmou Sanctum, contexto autenticado, throttle, conta ativa, e-mail verificado e extensão; `InsightsApiTest` cobre default, vigente explícito e encerrado |
| Token ausente/inválido/expirado/revogado não permite leitura | HTTP `401` JSON:API, sem `data`, com Repository configurado para nunca executar; expiração/revogação usam PATs reais preparados explicitamente |
| Conta pending/blocked/unverified não permite leitura | HTTP `403` JSON:API nas três formas de consulta, com fixtures de status/verificação explícitos e nenhuma execução analítica |
| Throttle permanece antes da leitura; sessão estende somente em sucesso | Cota isolada por execução/cenário, `200` seguido de `429`/Retry-After e exatamente uma chamada analítica; em janela de extensão, `422` mantém expiração e `200` estende, nos três modos |
| Falha de leitura não produz onboarding nem estende sessão | Exceção sentinela de Repository comprovada por identidade com `Exceptions::fake`; resposta exata `500`/errors JSON:API, sem dados ou detalhe interno, expiração preservada e handler restaurado em finally |
| Falha de composição não devolve coleção parcial | `MonthlyCompositionFailureHttpTest` fornece projeção inconsistente com o catálogo (categoria sem rótulo), sem gravá-la no banco; a comparação de +50% é comprovadamente componível antes da categoria que falha. HTTP vigente explícito/encerrado retorna somente erro `500`, reporta `InsightMessageCompositionException` específica e não estende sessão |
| Comparação, máximo e revisão usam somente fatos históricos do owner | `MonthlyContractHttpTest`: duas contas, julho–outubro, maior registro/descrição privados de outra conta e fato posterior do próprio owner. Setembro produz +120% vs. agosto, máximo em 30/09 de 55% e revisão de 55%, com um statement analítico e despesas intactas |
| Histórico de outra conta não afeta onboarding | Owner apenas com despesa futura, outra conta com histórico antigo/recente: vigente retorna somente `first_expense`; setembro retorna somente `insufficient_history` |
| Liderança histórica preserva três meses e isolamento | `MonthlyInsightsFiltersHttpTest` reforçado com outra conta em todos os meses; comparação setembro/agosto de +25% e liderança própria de julho a setembro permanecem, sem outubro e com comparison null na liderança |
| Envelope e períodos públicos preservados | Contrato estrito de `data`, resource type `insights`, ID opaco string, atributos permitidos e períodos setembro/agosto completos; concentração usa setembro completo/comparison null e onboarding period null. Sem relationships, paginação ou campo de ID de despesa |
| Descrição é string literal e fallback factual completo | HTTP em vigente/encerrado: marcação `<b>` e placeholder `{month}` são preservados como texto, whitespace é normalizado; null, whitespace-only e descrição de 64 caracteres fora do orçamento usam categoria/data, sem truncamento. Limites Unicode 24/80 e owner do texto são verificados |
| Onboarding, rotação e identidade mantêm provas anteriores | Suíte focada inclui os cenários 4.4–4.6 de estados históricos, period null, atualização retroativa, variantes e IDs |

Verificações finais pelo MCP Lerd `exec`, action `composer`, launcher guardado e `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Comando / caminho | Resultado |
| --- | --- |
| `lerd composer test -- tests/Feature/Insights/InsightsApiTest.php ...` | Após Pint e cenários adicionais: 54 testes / 361 assertions, passou isoladamente |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php ...` | 41 testes / 255 assertions, passou isoladamente |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyCompositionFailureHttpTest.php ...` | 2 testes / 30 assertions, passou isoladamente |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/MonthlyContractHttpTest.php ...` | 2 testes / 77 assertions, passou isoladamente |
| `lerd` vendor_run `pint --dirty --format agent` | Passou; ajustou imports/whitespace em `InsightsApiTest`; execução final passou sem mudanças |
| `lerd composer test -- tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php ...` | Após Pint: 816 testes / 32.707 assertions, passou |

A primeira execução do contrato histórico falhou por exigir ordem de chaves de objetos JSON no período. A assertion foi corrigida para verificar os valores individuais e o conjunto exato de chaves, sem impor ordem de propriedades; nenhuma expectativa de datas/envelope foi removida. Resultado final sem skips/incomplete/risky inesperados. Fakes/handlers e query logs dos testes novos são restaurados em finally; Feature usou bancos exclusivos com preflight/migrations incrementais.

Documentação Laravel 13 de `Exceptions::fake`/assertions foi consultada via Boost, com conferência do fake instalado. Validação OpenSpec estrita e `git diff --check` passaram. Sem migrations novas, mudança de request handling/queries de produção, acesso ao banco operacional ou nova medição de tráfego real. A falha editorial foi provocada na fronteira simulada do Repository; não demonstra uma categoria inválida persistida no PostgreSQL nem indisponibilidade real do banco.

Task 5.4 concluída. Próximas tarefas pendentes: 6.2–6.5 (Bruno) e 7.1–7.5 (fechamento). Gate integral/paralelo, execução Bruno, revisão Flutter e aprovação de archive permanecem fora desta evidência.

## Evidências da etapa 6.2 — exemplos Bruno mensais — 14/10/2026

Autorização explícita: “Pode seguir para 6.2”. Criados em `bruno/Insights/`:

- `02 - Get Current Month Insights.bru`, name `Get Current Month Insights`, seq 2: par ativo 2026/10, com preenchimento explícito documentado. Antes de executar, o consumidor deve conferir ano/mês da mesma data civil no timezone configurado da aplicação e atualizar ambos na virada. Não deriva datas do timezone do dispositivo. Documenta equivalência com o default, limite parcial e efeito de um par que passe a ser histórico/futuro.
- `03 - Get Closed Month Insights.bru`, name `Get Closed Month Insights`, seq 3: par ativo 2026/9, com pré-condição de referência civil ≥ 2026-10-01 para representar setembro encerrado. Documenta limites setembro/agosto, liderança julho–setembro, onboarding period null e ausência de comparação/quantidade mínima obrigatória.

Ambos conservam `{{baseUrl}}`, Bearer `{{accessToken}}`, Accept JSON:API e body none. URL e `params:query` representam o mesmo par, sem ocorrência duplicada por campo; a documentação orienta edição na aba Params e sincronização ao editar o arquivo diretamente. `01 - Get Insights.bru` permanece com os dois filtros desabilitados. Nenhum ambiente, credencial, folder externo a Insights, código PHP ou teste da aplicação foi alterado nesta etapa.

Validação local sem rede usando o Bruno instalado (`bru --version`: 4.0.0), parser/serializer `@usebruno/lang` 0.38.0 e preparação nativa de requests:

- Script temporário de validação executado por `node` no diretório de trabalho: três arquivos analisados, com nomes/seq únicos, método/body/auth/Accept e placeholders preservados.
- Para cada arquivo, três ciclos `bruToJsonV2 → jsonToBruV2 → bruToJsonV2` conservaram URL, parâmetros e documentação. A URL decodificada contém exatamente os filtros ativos e seus valores: zero filtros ativos no default, dois em cada exemplo novo, uma ocorrência por campo.
- `prepare-request` nativo conserva a mesma URL e não acrescenta cópias dos parâmetros; Bearer e Accept permanecem corretos. Nenhuma requisição HTTP foi enviada.
- `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` e `git diff --check` passaram.

Os ciclos de leitura/salvamento foram comprovados com os componentes nativos instalados, sem interação visual com a GUI. Execução autenticada dos exemplos em ambiente controlado pertence à 6.5; assertions de sucesso e exemplos negativos pertencem à 6.4/6.3. Não há evidência nova de respostas HTTP, visualização Flutter ou performance nesta fatia. Task 6.2 concluída; 6.3–6.5 e 7.1–7.5 continuam pendentes.

## Evidências da etapa 6.3 — exemplos negativos Bruno — 14/10/2026

Autorização explícita: “pode implementar a 6.3”. Adicionados cinco arquivos standalone em `bruno/Insights/`, com nomes e seq 4–8 consistentes:

| Arquivo | Query / condição | source.parameter esperado |
| --- | --- | --- |
| `04 - Reject Year Only Insights.bru` | `filter[year]=2026`, sem mês | `filter[month]` |
| `05 - Reject Month Only Insights.bru` | `filter[month]=9`, sem ano | `filter[year]` |
| `06 - Reject Invalid Month Insights.bru` | par completo 2026/13 | `filter[month]` |
| `07 - Reject Future Month Insights.bru` | par completo pré-preenchido 2026/11; preenchimento explícito obrigatório antes de cada execução para o mês seguinte à referência civil da aplicação | `filter[month]` |
| `08 - Reject Unknown Insights Parameter.bru` | `unknown=1`, independente de ano/mês fixos | `unknown` |

Cada arquivo tem dois testes Bruno/Chai: status HTTP 422, Content-Type JSON:API, objeto de resposta sem `data`, `errors` não vazio com status string `422`, e presença do parâmetro público esperado em `source.parameter`. Não fixa texto de erro, quantidade de erros ou posição do erro relevante. Os testes não aceitam 200, 401, 403 ou 429 como alternativa ao resultado esperado.

O futuro documenta a referência no timezone da aplicação, atualização conjunta do par em cada execução e dezembro→janeiro do próximo ano, sem usar relógio/timezone do dispositivo. Se o exemplo ficar vigente/histórico, as assertions falham; não transforma a resposta em sucesso permitido. Todos conservam `{{baseUrl}}`, `{{accessToken}}`, Bearer, Accept e body none; exigem conta ativa/verificada nas pré-condições. URL e params representam as mesmas chaves/valores, sem duplicação.

Verificações locais, sem rede:

- Documentação oficial de testes Chai e `res.getStatus/getHeader/getBody` consultada; APIs conferidas no Bruno 4.0.0 instalado.
- Parser/serializer nativo `@usebruno/lang` 0.38.0: cinco arquivos novos, três ciclos de leitura/salvamento por arquivo, com preservação de queries, testes e documentação. Preparação nativa de requests preservou URL, Bearer e Accept.
- `TestRuntime` nativo no sandbox QuickJS: 75 respostas sintéticas / 150 execuções dos testes dos arquivos. Aceitou 15 respostas válidas (erro padrão, media type com charset e múltiplos erros com o relevante ao final) e rejeitou 60 respostas inválidas: sucesso, 401/403/429, media type errado, errors vazio/ausente, data junto de errors, status numérico, source errado/ausente e pointer no lugar de parameter. Nenhum teste skipped.
- A primeira invocação do harness temporário estava sem callback de console exigido pelo runtime QuickJS; o harness foi corrigido e a validação completa passou, sem mudança nos scripts dos requests.
- Repetida a validação nativa dos três exemplos 01–03: default continua sem filtros ativos, pares válidos consistentes e sem duplicação nos ciclos de salvamento.
- `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` e `git diff --check` passaram.

As respostas são sintéticas e comprovam as assertions, não execução autenticada contra a API. Não foram alterados PHP, testes da aplicação, ambientes ou folders externos a Insights; nenhum token/credencial literal foi adicionado. A execução controlada dos exemplos e sua rejeição efetiva pelo backend permanecem na 6.5; as provas HTTP prévias de validação/ausência de leitura analítica continuam registradas em 5.3/5.4. Task 6.3 concluída; 6.4–6.5 e 7.1–7.5 seguem pendentes.

## Evidências das etapas 6.4–6.5 — assertions de sucesso e execução controlada — 14/10/2026

Autorização explícita: “Pode implementar as demais tarefas da fase 6”. Concluídas 6.4 e 6.5; a autorização não inclui o fechamento/arquivo da fase 7.

### Assertions de sucesso — 6.4

`01 - Get Insights`, `02 - Get Current Month Insights` e `03 - Get Closed Month Insights` agora têm dois testes Bruno standalone por arquivo:

- HTTP 200/Content-Type JSON:API, `data` array sem mínimo obrigatório e até seis itens, IDs string não vazios/únicos, resource type `insights`, atributos permitidos e combinação de grupos/tipos válida.
- Título/descrição são strings não vazias dentro de 24/80 pontos de código Unicode, medidos por `Array.from`, sem fixar texto ou variante diária.
- Períodos civis previstos pelo mês solicitado: concentração no período selecionado, comparação vigente por dias completos comuns, comparação histórica por ambos os meses completos, liderança abrangendo os dois antecedentes e onboarding `period: null`; `first_expense` é rejeitado no histórico.
- Variável local `insightsQueryDate`, com exemplo `2026-10-14` e instrução de atualização pela data civil da aplicação em `app.timezone`. Não é enviada à API nem escreve ambiente global. As assertions usam `bru.getRequestVar`, confirmado no runtime instalado; não calculam a referência pelo relógio do dispositivo.

Validação nativa QuickJS dos três arquivos: **81 respostas sintéticas / 162 execuções dos testes**, aceitando 35 respostas válidas e rejeitando 46 inválidas. Inclui coleção vazia, seis itens, todos os tipos permitidos em cada modo, limites exatos com emoji e caracteres combinantes, excedentes Unicode, sétimo cartão, ID duplicado/não string, tipo/grupo incorreto, campo extra de despesa e períodos inválidos. Nenhum skip. A primeira validação detectou o uso incorreto de `getVar` para variável local; os scripts foram corrigidos para `getRequestVar` e a matriz completa passou. Parsing/round trips e preparação nativa dos oito requests também passaram após a mudança; default segue sem filtros ativos.

### Execução autenticada real — 6.5

Executada a CLI **Bruno 4.0.0** contra servidor PHP HTTP temporário em loopback, usando o bootstrap, Kernel HTTP, rotas, middlewares, Repository PostgreSQL e composição reais da aplicação. Referência civil congelada em **2026-10-14, timezone UTC**; exemplos vigente 2026/10, histórico 2026/9 e futuro 2026/11 satisfazem as pré-condições nessa referência.

O harness Pest temporário foi executado **pelo launcher** `lerd composer test -- tests/Feature/Insights/Presentation/Http/BrunoCollectionExecutionTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. O preflight criou banco exclusivo, aplicou migrations incrementais e registrou ownership. O servidor relia `TestDatabaseGuard` em cada request, conferindo configuração, banco efetivo e marcador exato antes do processamento. Nenhum banco operacional foi acessado.

Preparação explícita no banco exclusivo:

- Conta ativa/verificada com cinco despesas em cada um de julho, agosto, setembro e outubro. Julho/agosto: R$ 400 registrados por mês; setembro: R$ 500, incluindo 30/09; outubro: R$ 500 até 12/10. As ocorrências em cinco datas e categoria Alimentação sustentam as bases e a liderança.
- Outra conta ativa/verificada, sem despesas, para provar o consumo de onboarding pelos mesmos exemplos de sucesso.
- PATs reais válidos, guardados somente em arquivo de ambiente temporário com permissão 0600, em diretório privado 0700. Tokens não aparecem nos comandos/evidência ou arquivos da coleção. Relatórios omitiram headers e bodies.

| Execução CLI / exemplo | Resultado |
| --- | --- |
| Conta com base elegível: 01 default | 200, dois testes Bruno passaram |
| Conta com base elegível: 02 vigente explícito | 200, dois testes passaram |
| Conta com base elegível: 03 histórico completo | 200, dois testes passaram |
| Conta com base elegível: 04 ano isolado | 422, dois testes passaram; `source.parameter: filter[month]` |
| Conta com base elegível: 05 mês isolado | 422, dois testes passaram; `source.parameter: filter[year]` |
| Conta com base elegível: 06 mês 13 | 422, dois testes passaram; `source.parameter: filter[month]` |
| Conta com base elegível: 07 mês futuro 2026/11 | 422, dois testes passaram; `source.parameter: filter[month]` |
| Conta com base elegível: 08 unknown | 422, dois testes passaram; `source.parameter: unknown` |
| Conta vazia: 01/02/03 | 200/200/200, seis testes Bruno passaram |

Total: **11 requisições Bruno e 22 testes Bruno aprovados**, sem requests skipped. Os relatórios JSON nativos conferiram a quantidade de requests/testes e todos os status, além do exit code da CLI. Chamadas HTTP complementares confirmaram igualdade integral de `data` entre default/vigente explícito nas duas contas; na conta elegível, setembro/agosto retornou **+25%**, com limites 01–30/09 e 01–31/08; na conta vazia, vigente retornou `first_expense` e histórico somente `insufficient_history`/period null, sem comparação.

Resultado final do harness após Pint: **1 cenário / 31 assertions, passou**, com os 22 testes CLI também aprovados. `pint --dirty --format agent`, `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` e `git diff --check` passaram. O harness foi removido após a execução manual para não introduzir dependência da instalação global de Bruno na suíte padrão. Servidor, arquivo privado de token, relatórios e logs foram removidos em finally; o launcher limpou somente o banco de sua execução.

Limitações: servidor HTTP temporário com data congelada, não a rota Nginx operacional nem a GUI; não prova performance em escala, homologação Flutter ou execução do deploy. A comparação exige a fixture elegível registrada acima, não é garantida para qualquer conta. Nenhum ambiente Bruno/global, folder externo a Insights ou código de produto foi alterado; não houve migration nova ou dados demonstrativos no banco real.

**Fase 6 concluída.** Tarefas 7.1–7.5 permanecem pendentes; gate de fechamento e aprovação de archive não foram antecipados.

## Fechamento da fase 7 — 14/10/2026

Autorização: “Pode finalizar”. README e ARCHITECTURE receberam a documentação final de onboarding, identidade/rotação e consumo Bruno, preservando a janela mensal e os campos/schema consumidos já documentados. Não se alteraram fronteiras, dependências, schema, produto ou a evidência histórica das etapas anteriores. Revisão visual/acessibilidade Flutter permanece externa e não foi marcada como executada.

### Gate final de código — 7.2/7.3

Todos os comandos usam o launcher `lerd composer test -- <caminho/opções> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Os onze arquivos PHP alterados/adicionados foram repetidos isoladamente após Pint:

| Arquivo | Testes / assertions |
| --- | --- |
| Unit `ComposeInsightMessageUseCaseTest.php` | 71 / 2.360 |
| Unit `GenerateInsightCandidatesRulesTest.php` | 55 / 113 |
| Unit `GetInsightsUseCaseTest.php` | 18 / 155 |
| Unit `SelectInsightMessageVariantUseCaseTest.php` | 15 / 129 |
| Feature `InsightsApiTest.php` | 54 / 361 |
| Feature `MonthlyInsightsFiltersHttpTest.php` | 41 / 255 |
| Feature `MonthlyCompositionFailureHttpTest.php` | 2 / 30 |
| Feature `MonthlyContractHttpTest.php` | 2 / 77 |
| Feature `MonthlyIdentityHttpTest.php` | 5 / 162 |
| Feature `MonthlyOnboardingHttpTest.php` | 22 / 208 |
| Feature `MonthlyRotationHttpTest.php` | 5 / 205 |

| Gate | Resultado |
| --- | --- |
| Insights Unit + Feature + `ContextBoundariesTest` | **816 / 32.707**, passou |
| `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | **1.819 / 38.546**, passou, 56,548 s; inclui Redis/concorrência e isolamento de invocações existentes |
| `lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | **1.819 / 38.546**, passou, 44,229 s |
| `lerd` vendor_run `pint --dirty --format agent` | Passou |
| OpenSpec estrito + `git diff --check` | Passaram |

As primeiras invocações do gate completo/paralelo via MCP atingiram timeout de transporte e não contam como aprovação. Confirmada ausência de processos remanescentes, ambos foram repetidos pelo CLI com prazo maior, sempre pelo mesmo launcher/preflight seguro, produzindo os resultados explícitos acima. Não houve skips/incomplete/risky inesperados nos resultados finais. Não houve mudança de suporte compartilhado nem fechamento da reorganização de testes nesta fatia; seeds aleatórias adicionais não foram executadas.

### Medição controlada e limitação aceita — 7.4

Dumps Lerd já estavam habilitados; configuração e ring existentes não foram modificados/limpos. `migrate:status --no-interaction` confirmou todas as migrations aplicadas, sem schema novo ou migration pendente.

Um harness temporário, pelo launcher e com `TestDatabaseGuard` no servidor de cada request, preparou **4.800 despesas em PostgreSQL exclusivo**: duas contas, 600 ocorrências por mês em julho/agosto/setembro/outubro por conta. Foi executado `ANALYZE expenses` somente nesse banco. Seis GETs autenticados reais — duas consultas default, duas vigentes explícitas e duas históricas — retornaram 200 e cada request executou **exatamente um statement analítico**. Referência civil 2026-10-14/UTC, token real válido, nenhum dado ou sessão operacional alterado.

| Consulta | Kernel HTTP (ms, duas execuções) | Statement analítico (ms) |
| --- | --- | --- |
| Default | 106,91 / 16,74 | 6,29 / 6,21 |
| Vigente explícito | 17,72 / 16,73 | 6,18 / 6,15 |
| Histórico setembro | 18,50 / 19,67 | 7,74 / 7,90 |

Os tempos Kernel não incluem bootstrap inicial; a primeira consulta ainda tem aquecimento. Não são percentis de produção ou promessa de performance. Query logs do HTTP real demonstram ausência de multiplicação/per-card/N+1 **na leitura analítica** para essa fixture.

`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` com SQL/bindings capturados mostrou uso de `expenses_user_id_occurred_on_index` por Bitmap Index/Heap Scan no escopo financeiro: 1.506 linhas elegíveis no vigente e 1.800 no histórico, sem misturar outro owner. As cinco janelas reutilizam a CTE materializada; loops internos do plano não são queries por cartão. Planning/execution: vigente **0,749/12,826 ms**, histórico **0,204/17,274 ms**. A checagem `EXISTS` de histórico teve Seq Scan encerrada na primeira ocorrência nessa fixture; não se extrapola para distribuição ou volumes maiores.

`route_timing`, `analyze_queries` e `optimize_route` foram consultados. O watcher tinha tráfego de outras rotas, mas **não correlacionou as requisições do servidor temporário de Insights**; `optimize_route` retornou `routes: []`. Amostras gerais e achados de preflight/rotas de User/Expense não foram apresentados como evidência de Insights. Não se afirma ausência global de N+1 ou captura autenticada via Nginx.

Decisão explícita do usuário para fechar 7.4: **“Fechar com limitação (Recomendado)”**, escolhida após esclarecer a alternativa de captura operacional. Essa aceitação é limitada à medição HTTP/PostgreSQL controlada e à ausência de correlação no Lerd; não equivale a prova daquilo que o watcher não capturou.

Harness de medição: **1 cenário / 16 assertions, passou**. A primeira tentativa de seed falhou por timestamps ausentes; a fixture foi corrigida com datas explícitas, sem alterar schema/constraints, e as execuções posteriores passaram. Servidor, router privado, métricas/logs e banco exclusivo foram removidos; harness PHP retirado da suíte após a operação. Nenhuma configuração do site, extensão, serviço ou worker foi alterada.

### Revisão final de evidência — 7.5

Todos os requisitos observáveis da mudança têm evidência de Domain/Application, PostgreSQL/HTTP ou Bruno na matriz final. Fronteiras e task truthfulness revisadas; nenhum teste verde foi usado para atribuir prova de corrida, produção, GUI ou Flutter.

O último fallback monetário continua sem seleção positiva de branch, conforme registro editorial original. Isso não bloqueia a preservação observável de magnitude: em comparação elegível, o denominador anterior é pelo menos 10.000 centavos, logo o percentual inteiro é no máximo o arredondamento da diferença/100. A diferença em BRL tem moeda, centavos e separadores e é mais longa que o percentual compacto; as alternativas usam o mesmo contexto/sinal. Não foi fabricado um ratio inválido para forçar esse branch. Catálogo/formatador monetários, percentuais regular/compacto e falha quando nenhum par cabe estão comprovados; não se alega cobertura positiva inexistente.

**Todas as 30 tarefas concluídas**, com a limitação operacional de 7.4 explicitamente aceita. A mudança está concluída para o escopo deste backend/coleção. Archive, commit, push, deploy e revisão Flutter não foram executados nesta etapa; archive exige autorização específica e não é inferido dos gates verdes.

## Autorização de arquivamento e publicação — 14/10/2026

Pedido explícito posterior ao fechamento: “Arquiva a spec commita tudo e da push”. A primeira tentativa do CLI recusou a sincronização porque cinco títulos de cenários preexistentes haviam sido renomeados no delta MODIFIED. Foram restaurados os títulos originais, preservando integralmente o conteúdo mensal atualizado e os cenários novos, sem alterar regras de produto, implementação ou evidência histórica. O arquivamento é realizado pelo CLI nativo, com sincronização das specs principais e validação habilitadas; os resultados de commit/push são informados após sua execução.

Arquivamento nativo concluído em `2026-10-14-add-monthly-insights-filters`: quatro requisitos adicionados, sete modificados e nenhum removido/renomeado. Spec principal `insights` sincronizada; validação estrita global passou para 17 itens (uma change ativa e 16 specs), sem falhas, e `openspec doctor` retornou healthy/sem findings. Avisos INFO de extensão dos textos normativos não representam falhas. Removida somente uma linha em branco excedente no EOF gerada pelo serializer para satisfazer `git diff --check`.
