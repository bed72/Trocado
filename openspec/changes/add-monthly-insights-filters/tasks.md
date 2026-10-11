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
- [ ] 3.2 Projetar descrição/data/categoria/valor do maior lançamento no mesmo statement, preservando desempate `amount DESC, category ASC, id ASC`; mapear fatos em Data próprio, sem imports de Expense, Model duplicado ou query por cartão.
- [ ] 3.3 Provar em Feature PostgreSQL limites inclusivos, exclusão de meses posteriores, cadastro retroativo, bissexto, somas acima de `PHP_INT_MAX`, desempate e identificação pertencente ao owner correto; conferir um statement e ausência de writes, sem alegar corrida comprovada por execução sequencial.

## 4. Mensagens, onboarding, rotação e identidade

- [ ] 4.1 Implementar catálogo aprovado e nova versão editorial, com conjuntos corrente/encerrado, títulos factuais e contexto de mês/ano no par; remover frases genéricas e atualizar expectativas antigas sem enfraquecer veracidade/limiares.
- [ ] 4.2 Implementar identificação pela descrição utilizável, normalização de whitespace e fallback categoria/data, com percentual obrigatório e valor exato quando couber; tratar marcação como texto, sem truncamento ou logs de descrição.
- [ ] 4.3 Implementar alternativas editoriais dentro de 24/80 após interpolação, preservando magnitude de comparação por percentual ou diferença exata; verificar BRL sem float, percentuais extremos, categorias longas e referência entre anos; falha explícita se não houver alternativa segura.
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
| Maior lançamento: descrição, ausente/longa, marcação, empate e owner | 3.2–3.3, 4.2, 5.4 | Feature PostgreSQL + Unit editorial + HTTP texto literal | Não comprovado |
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
