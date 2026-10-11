## 1. Decisões e coordenação antes de implementar

- [x] 1.1 Confirmar com o usuário a política proposta de incluir `investments` nos totais e Insights como saída registrada; atualizar proposal/design/deltas caso a decisão seja diferente.
  - Confirmação explícita em 11/10/2026: “Confirmar proposta”; política, identificadores e critérios de finalidade mantidos.
- [x] 1.2 Confirmar os oito identificadores, rótulos compactos e critérios de finalidade definidos no design, incluindo viagens versus transporte e financiamento versus compra parcelada.
  - Critérios/identificadores confirmados na primeira etapa; oito rótulos e escopo de coordenação confirmados explicitamente por “Confirmar escopo (Recommended)” na etapa Insights.
- [x] 1.3 Coordenar com `add-monthly-insights-filters` a versão efetiva dos templates e a revisão das oito categorias sob limites 24/80, preservando tarefas pendentes e evidências históricas daquela change; obter autorização explícita para implementar.
  - Autorização recebida para catálogo/classificação (2.1–2.3) e verificações focadas. Estado consultado: runtime `v3-monthly-periods`, tarefas editoriais 4.1–4.3 da change mensal pendentes. Revisão/aprovação dos oito rótulos e integração 24/80 continuam pendentes antes da etapa editorial; evidências históricas preservadas.
  - Fechamento da coordenação nesta etapa: usuário confirmou a expansão sobre runtime 32/110, com revisão adicional do catálogo futuro 24/80. Adendo de compatibilidade no catálogo mensal e nota em suas tasks, sem concluir suas tarefas editoriais ou substituir evidências históricas.

## 2. Catálogo e classificação

- [x] 2.1 Adicionar os oito cases ao `ExpenseCategoryEnum`, preservando cases/valores existentes; verificar o catálogo completo contra uma expectativa explícita e independente dos dezoito identificadores.
  - `ExpenseCategoryEnumTest` confere explicitamente nomes dos cases e dezoito valores, sem derivar a expectativa do enum.
- [x] 2.2 Atualizar as instruções do `ExpenseClassificationAgent` com as oito categorias e os desempates documentados; provar que o schema admite exatamente o catálogo expandido e registrar evidência focada das instruções para cada cenário de semântica.
  - `ExpenseClassificationAgentTest` verifica campo obrigatório string e catálogo exato; oito cenários focados cobrem financiamento/parcela, aporte/tributo/tarifa, seguro/saúde, cuidados pessoais, pets, presentes/doações, viagem/transporte e descrição não confiável/fallback. Inspeção das instruções prova o contrato textual, não precisão do modelo.
- [x] 2.3 Verificar, com IA fake e tentativas vigentes, que cada nova categoria pode ser aplicada pelo fluxo assíncrono existente; preservar e executar as provas relevantes de fallback, descrição não confiável, categoria explícita e tentativa atrasada, sem atribuir aos fakes prova de precisão do provedor real.
  - `ExpenseClassificationTest` processa cada nova categoria por `queue:work --once` com fila database exclusiva dos testes e IA fake; cobre escolha manual nas oito categorias antes do worker e durante a resposta fake, além das regressões existentes. Não é prova nova de consumo Redis ou corrida entre processos.

## 3. Expense e consultas

- [x] 3.1 Provar criação e edição HTTP de cada nova categoria, identificador na resposta/persistência e proteção da escolha manual contra classificação pendente.
  - `ExpenseCategoriesHttpTest`: criação explícita das dezoito categorias, resposta/leitura/persistência e ausência de dispatch; edição para cada nova categoria cancela a tentativa anterior sem chamar IA.
- [x] 3.2 Provar filtro individual de cada nova categoria e filtro combinado `travel,investments,food,travel`, com normalização, proprietário, critérios combinados e aplicação antes da paginação.
  - Filtros individuais das dezoito categorias com page size 1 e decoys de outra conta/categoria; filtro combinado com limites inclusivos civis/monetários, duplicação e ordem equivalentes, duas páginas sem decoys.
- [x] 3.3 Provar `422` para valores desconhecidos/semelhantes em criação, edição e filtros, e regressões de `other` e dos dez identificadores existentes; comprovar que a expansão não recategoriza registros históricos.
  - `unknown`, `investment`, `Travel` e `personal-care` rejeitados com pointers JSON:API nas três operações, sem escrita; registros históricos `transport`/viagem e `other`/aporte lidos sem alterações ou dispatch.

## 4. Metrics e Insights

- [x] 4.1 Atualizar expectativas fixas de catálogo em Metrics e provar aceitação e agregação PostgreSQL de cada nova categoria, sem itens ausentes com zero ou rótulos traduzidos na API.
  - Catálogo explícito de dezoito identificadores em Application e Repository, sem expectativa derivada do enum; HTTP/PostgreSQL de cada nova categoria com único item, total `10000` e percentual `100.00`.
- [x] 4.2 Provar total simples/agrupado `100000` para investimentos `60000`, financiamentos `30000` e alimentação `10000`, percentuais exatos, exclusão de outra conta/período e desempate alfabético entre novas categorias com mesmo total.
  - Unit e HTTP/PostgreSQL confirmam `60.00`/`30.00`/`10.00`; ambos os modos excluem outra conta e registros anteriores/posteriores. Empates novos seguem `financing`, `investments`, `travel`, com `33.33` independente por item.
- [x] 4.3 Adicionar os oito rótulos à composição de Insights sem mover rótulos para Core Domain, importar outros contextos ou ampliar allowlists; provar composição para cada nova categoria elegível e liderança recorrente de financiamentos.
  - Mapping em `ComposeInsightMessageUseCase`; Unit com todos os rótulos/tipos afetados e HTTP/PostgreSQL com cada categoria a 40%, além de financiamentos líderes por três meses nos dois modos.
- [x] 4.4 Revisar todos os conjuntos afetados de templates/variantes/alternativas e testar rótulos integrais, modos aplicáveis, períodos, percentuais extremos e limites efetivos, incluindo 24/80 na coordenação com a change mensal; preservar falha explícita para catálogo realmente inconsistente.
  - 144 cenários Unit: 8 categorias × 3 tipos × 2 modos × 3 janelas, quatro variantes/alternativas e participação 100%; regressões de composição cobrem percentuais extremos, Unicode e exceções. Revisão isolada de 2.688 pares mensais aprovados sob 24/80, sem atribuir implementação runtime à outra change.
- [x] 4.5 Provar que investimentos participam da análise com os mesmos denominadores e que mensagens de investimentos/viagens preservam fatos, sem inferências de consumo, prejuízo, retorno, destino ou capacidade financeira; manter grupos/tipos JSON:API e deduplicação.
  - HTTP/PostgreSQL de investimentos `60000` em total `100000` → 60%, nos dois modos, suprimindo lançamento sobreposto; categoria a 40% e liderança mantêm envelope/grupos/períodos, owner e dados intactos. Assertions rejeitam as inferências proibidas.

## 5. Verificação e documentação da entrega

- [x] 5.1 Atualizar documentação/API e exemplos Bruno existentes pertinentes aos novos identificadores, incluindo categorias explícitas e filtro combinado, sem alterar exemplos alheios nem criar documentação genérica desnecessária.
  - README com catálogo/semântica/Insights/deploy/rollback; Bruno Create `travel`, Update `investments`, GetAll conjunto combinado e docs de Metrics. Revisão de arquivos apenas; execução no cliente não declarada.
- [x] 5.2 Executar arquivos afetados isoladamente e suítes focadas de Expense/Metrics/Insights pelo launcher `lerd composer test -- <caminho/opções Pest>`; registrar comandos, resultados e limitações, reutilizando evidências pertinentes de comportamento inalterado.
  - Evidências das três etapas abaixo e gate completo de 1.434 testes; nenhum skip/incomplete/risky.
- [x] 5.3 Executar Laravel Pint `--dirty --format agent` após a última edição PHP e rerodar os checks afetados; revisar fronteiras e executar a prova arquitetural pertinente ao catálogo compartilhado sem ampliar permissões.
  - Pint após a última edição PHP; arquivos e suítes de Insights repetidos. Provas arquiteturais incluídas no gate completo; rótulos permanecem na Application de Insights e nenhuma permissão ampliada.
- [x] 5.4 Verificar fluxos HTTP afetados com captura de queries e `optimize_route` conforme as regras do projeto; registrar evidências e limitações de observabilidade, sem usar tráfego CLI como prova HTTP.
  - Fechada após o usuário informar “já fiz”: eventos `ctx=fpm` confirmam GET de Expense, Metrics agrupado e Insights vigente/mensal. `optimize_route` e timing consultados; evidência final abaixo, sem misturar queries CLI de preflight/migrations.
- [x] 5.5 Registrar confirmação de schema sem migration/backfill e orientação de deploy coordenado com consumidores fechados e workers residentes; documentar rollback compatível que mantenha os novos valores já persistidos.
  - Schema/constraints reconfirmados pelo Boost; todas as migrations locais aplicadas. README e design documentam consumidores, workers e rollback que conserva dezoito valores.
- [x] 5.6 Revisar rastreabilidade, rodar validação OpenSpec estrita e concluir o quality gate adequado antes de declarar implementação concluída; arquivar somente com autorização e evidência suficiente.
  - Revisão de rastreabilidade e gate de código concluídos nesta etapa; fechamento/arquivabilidade bloqueados pela prova operacional 5.4 ainda sem amostras autenticadas de tráfego externo. Não arquivado.

## Rastreabilidade prevista

| Requisito / cenários | Tasks | Evidência futura |
| --- | --- | --- |
| Expense: catálogo fechado, padrão, categorias explícitas e inválidas | 2.1, 3.1, 3.3 | Unit de catálogo/invariantes e Feature HTTP/PostgreSQL |
| Expense: filtros novos, combinados e inválidos | 3.2, 3.3 | HTTP e persistência com proprietário/paginação |
| Expense: semântica, schema e sugestões novas | 2.2, 2.3 | Contrato de schema/instruções e fluxo com IA fake; não prova precisão do modelo real |
| Expense: tentativa atrasada e preservação histórica | 2.3, 3.1, 3.3 | Evidências existentes/focadas de edição e persistência |
| Metrics: cada nova categoria, denominador e desempate | 4.1, 4.2 | Application e PostgreSQL/HTTP pertinentes |
| Insights: rótulos, concentração, investimentos, liderança e viagens | 4.3, 4.5 | Unit editorial/orquestração e integração PostgreSQL/HTTP pertinente |
| Insights: interpolação e limites editoriais | 1.3, 4.4 | Revisão de todos os conjuntos afetados e Unit editorial parametrizada |

Status inicial (histórico): artefatos de planejamento apenas, com todas as tarefas pendentes. Em 11/10/2026, o usuário autorizou a etapa de catálogo/classificação (2.1–2.3) e confirmou a política de investimentos e os identificadores/critérios; a coordenação editorial completa de 1.3 permanece pendente para a etapa de Insights.

## Evidências da etapa de catálogo e classificação — 11/10/2026

Implementação restrita ao enum e às instruções do agente, com schema ainda derivado de `cases()` e conversão defensiva no Adapter existente. Não há alteração de persistência, migration, backfill, job, fila ou dependência. Boost confirmou PHP 8.5, Laravel 13.34.0 e AI SDK 1.0.0; documentação e implementação instalada de schema/fakes consultadas. Schema efetivo: `expenses.category` é `varchar(32)` e as constraints existentes são PK, FK de proprietário e unicidade do token de classificação, sem catálogo SQL. `migrate:status` confirmou todas as migrations locais aplicadas.

Testes executados via MCP Lerd `exec`, action `composer`, args `['test', '--', <caminho>, '--compact']`, equivalentes a `lerd composer test -- <caminho> --compact`. Feature usou preflight, bancos exclusivos por execução e migrations incrementais.

| Caminho / check | Resultado final |
| --- | --- |
| `tests/Unit/Core/Domain/Enums/ExpenseCategoryEnumTest.php` | 1 teste, 1 assertion, passou |
| `tests/Unit/Expense/Infrastructure/Agents/ExpenseClassificationAgentTest.php` | 9 testes, 30 assertions, passou |
| `tests/Unit/Expense/Application/UseCases/ClassifyExpenseUseCaseTest.php` | 3 testes, 14 assertions, passou |
| `tests/Feature/Expense/ExpenseClassificationTest.php` | 50 testes, 324 assertions, passou |
| `tests/Unit/Core/Domain` | 153 testes, 433 assertions, passou após Pint |
| `tests/Unit/Expense` | 73 testes, 253 assertions, passou após Pint |
| `tests/Feature/Expense` | 289 testes, 2.073 assertions, passou após Pint |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | 26 testes, 401 assertions, passou após Pint; nenhuma allowlist ampliada |
| `lerd` vendor_run `pint --dirty --format agent` | Passou após a última edição PHP |
| `openspec validate expand-expense-categories --type change --strict --json --no-interactive` | Passou sem issues |
| `git diff --check` | Passou |

Rastreabilidade desta etapa: catálogo fechado → Unit de Core; schema e cada ambiguidade documentada → Unit do agente; sugestões novas → worker database real com IA fake; fallback/resposta inválida/erro, elegibilidade, categoria explícita, expiração, repetição e alterações posteriores → Feature de classificação e Unit de orquestração. A assertion inicial do schema foi corrigida para não depender da ordem das chaves de objeto JSON (`enum`/`type`); catálogo e obrigatoriedade continuam verificados integralmente.

Limitações e próximos gates: fakes não comprovam precisão do provedor real; não há nova prova de corrida sincronizada ou worker Redis. HTTP externo/captura de queries e `optimize_route`, gate integral/paralelo, Metrics, Insights e Bruno não foram verificados nesta etapa. Tasks 1.2 (aprovação dos rótulos), 1.3 (coordenação editorial completa), 3.*, 4.* e fechamento 5.* continuam pendentes. A composição atual de Insights ainda não possui os oito rótulos: esta entrega parcial não está pronta para deploy coordenado nem arquivamento antes da integração editorial. Preservar os dezoito valores no rollback após sua persistência; atualizar consumidores fechados e workers residentes na entrega coordenada, conforme o design.

## Evidências da etapa Expense e Metrics — 11/10/2026

Autorização: pedido explícito “Proxima step / 2. Expense e Metrics”, abrangendo criação, edição, filtros, expectativas fixas, persistência, totais, percentuais e ordenação. Tasks 3.1–3.3 e 4.1–4.2 concluídas nesta etapa; não implica aprovação editorial nem fechamento da change.

Os consumidores de produto já validam pelo enum compartilhado e agregam as categorias sem exclusões; não foi necessária alteração adicional de produção. Adicionado `ExpenseCategoriesHttpTest` na Presentation e ampliadas as provas existentes de Metrics na Application, HTTP e Repository PostgreSQL. Expectativas explícitas não derivam do enum. Os testes de catálogo de Core e schema do agente foram ajustados para aceitar reordenação da declaração dos cases: preservam os dezoito valores exatos, nomes dos cases, tipo e obrigatoriedade; a ordem de enumeração não é contrato. A ordem do resultado de Metrics continua verificada exatamente.

Todos os testes abaixo usaram `lerd composer test -- <caminho> --compact` via MCP; Feature com preflight, ownership e migrations incrementais em bancos exclusivos. `migrate:status` confirmou ausência de migrations locais pendentes. Search Docs de validação enum/HTTP e rotas de Expense consultados.

| Caminho / check | Resultado final |
| --- | --- |
| `tests/Feature/Expense/Presentation/Http/ExpenseCategoriesHttpTest.php` | 50 testes, 339 assertions, passou |
| `tests/Unit/Metrics/Application/UseCases/GetExpenseMetricsUseCaseTest.php` | 41 testes, 97 assertions, passou |
| `tests/Feature/Metrics/Infrastructure/Repositories/Persistence/EloquentExpenseMetricsRepositoryTest.php` | 15 testes, 52 assertions, passou; catálogo completo agregado em um statement |
| `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php` | 91 testes, 786 assertions, passou |
| `tests/Unit/Core/Domain/Enums/ExpenseCategoryEnumTest.php` | 1 teste, 1 assertion, passou após ajuste de ordem e Pint |
| `tests/Unit/Expense/Infrastructure/Agents/ExpenseClassificationAgentTest.php` | 9 testes, 30 assertions, passou após ajuste de ordem e Pint |
| `tests/Unit/Expense` | 73 testes, 253 assertions, passou após correção da expectativa de ordem |
| `tests/Feature/Expense` | 339 testes, 2.412 assertions, passou |
| `tests/Unit/Metrics` | 41 testes, 97 assertions, passou |
| `tests/Feature/Metrics` | 106 testes, 838 assertions, passou |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | 26 testes, 401 assertions, passou |
| `lerd` vendor_run `pint --dirty --format agent` | Passou após a última edição PHP; arquivos corrigidos repetidos isoladamente e suíte de Expense Unit repetida |
| `openspec validate expand-expense-categories --type change --strict --json --no-interactive` | Passou sem issues |
| `git diff --check` | Passou |

| Cenário | Evidência |
| --- | --- |
| Criação explícita nova e dez categorias anteriores/`other` | HTTP parametrizado das dezoito categorias, persistência/consulta individual, ausência de dispatch/IA |
| Edição para cada nova categoria com tentativa pendente | Resposta e banco preservam escolha manual, token anterior cancelado e job antigo sem prompt |
| Filtro individual e conjunto duplicado `travel,investments,food,travel` | HTTP/PostgreSQL, owner/categoria/data/valor antes de paginação; conjunto normalizado equivalente e navegação de duas páginas |
| Categoria desconhecida/semelhante | `422` e pointers em criação, edição e filtro combinado; ausência de criação e comparação integral do registro após rejeição |
| Histórico genérico com finalidade agora específica | Registros `transport`/viagem e `other`/aporte continuam legíveis sem alteração de campos ou dispatch |
| Oito novas categorias em Metrics | HTTP/PostgreSQL individual com total `10000`, participação `100.00` e item exato sem tradução/categorias vazias |
| Investimentos/financiamentos/alimentação | HTTP em ambos os modos com total `100000` e `60.00`/`30.00`/`10.00`, excluindo outra conta e datas externas; Unit de percentuais independente |
| Empate e catálogo completo | Ordem exata `financing`, `investments`, `travel`, percentuais `33.33`; Application verifica 18 grupos e Repository verifica soma `33500` e ordem numérica/alfabética em um statement |

Observabilidade: dumps já habilitados; `optimize_route(site: trocado)` retornou `samples: 0`, `routes: []`. HTTP in-process dos testes não constitui tráfego externo capturado pelo watcher; task 5.4 permanece pendente sem alegação de N+1/performance medida em tráfego real. Não houve alteração de request handling/queries de produto nesta etapa. Sem migration/backfill ou alteração de registros operacionais; sem gate integral/paralelo ou execução Bruno. Insights, revisão editorial e demais tarefas de fechamento permanecem pendentes.

## Evidências da etapa Insights e fechamento — 11/10/2026

Autorização: “3. Insights e fechamento”, incluindo rótulos, variantes/limites, coordenação, verificações, Pint e registro. O usuário confirmou os oito rótulos e a opção de manter o runtime vigente e revisar o catálogo mensal futuro, preservando suas tarefas pendentes. A mudança de produto desta etapa limita-se ao mapping de categorias em `ComposeInsightMessageUseCase`; sem imports/contratos novos, versão de templates ou alteração de limites. O runtime permanece `v3-monthly-periods`, 32/110. A implementação de 24/80, identificação de maior lançamento e alternativas monetárias pertence a `add-monthly-insights-filters`, conforme confirmação de escopo.

| Caminho / comando | Resultado final após Pint |
| --- | --- |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/ExpandedCategoryMessageTest.php --compact` | 144 testes, 11.424 assertions, passou |
| `lerd composer test -- tests/Feature/Insights/Presentation/Http/ExpandedCategoriesInsightsHttpTest.php --compact` | 20 testes, 250 assertions, passou |
| `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php --compact` | 35 testes, 972 assertions, passou; inclui limites Unicode, percentuais extremos, categoria desconhecida e falha explícita |
| `lerd composer test -- tests/Unit/Insights --compact` | 380 testes, 13.009 assertions, passou |
| `lerd composer test -- tests/Feature/Insights --compact` | 106 testes, 945 assertions, passou |
| `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 1.434 testes, 19.769 assertions, passou em 36.998 ms; inclui todos os contextos, fronteiras arquiteturais e integrações existentes |
| `lerd` vendor_run `pint --dirty --format agent` | Passou após a última edição PHP; arquivos/suítes acima repetidos |
| Revisão editorial isolada Python 3 | 2.688 pares selecionados, máximo 24/80, oito rótulos, dois modos, quatro variantes; janelas `mar/0001`, `jan/2026`, `jan/9999` com antecedentes explícitos |
| `openspec validate expand-expense-categories --type change --strict --json --no-interactive` | Passou sem issues |
| `openspec validate add-monthly-insights-filters --type change --strict --json --no-interactive` | Passou sem issues; pendências editoriais preservadas |
| `git diff --check` | Passou |

Execuções canônicas via MCP Lerd, Feature com preflight, ownership exato e migrations incrementais em bancos exclusivos. Nenhum skip/incomplete/risky, nenhuma mutation de banco operacional, migration nova, backfill ou ampliação de allowlists. Schema efetivo reconfirmado: `category varchar(32)`, constraints PK/FK/token único, sem catálogo fechado SQL; `migrate:status` sem pendências.

### Rastreabilidade final de produto

| Requisito / cenário | Estado e evidência |
| --- | --- |
| Catálogo, categorias explícitas/novas/ inválidas, filtros e histórico | Comprovado pelas etapas anteriores; gate completo repetiu as provas |
| Classificador: semântica, schema, sugestões, manual e tentativa antiga | Comprovado por contrato textual/IA fake/worker de teste; não comprova precisão do provedor real nem nova corrida sincronizada |
| Metrics: oito categorias, denominador, percentuais e empates | Comprovado por Unit/HTTP/PostgreSQL da etapa anterior, repetidos pelo gate completo |
| Insights: concentração das oito categorias a 40% nos dois modos | Comprovado por HTTP/PostgreSQL com outra conta e ocorrência fora do período; campos do envelope, períodos e ausência de escrita verificados |
| Investimentos a 60% do total registrado | Comprovado nos dois modos; concentração do maior lançamento sobreposto suprimida, sem inferência de consumo, retorno, renda ou patrimônio |
| Liderança de financiamentos e deduplicação | Comprovado em três meses elegíveis nos dois modos, grupo comparison e períodos exatos |
| Rótulos integrais, concentração/maior lançamento/liderança, variantes e limites vigentes | Comprovado por 144 cenários, quatro variantes/alternativas, Unicode, participação 100%, anos extremos e virada do ano; regressões da composição preservadas |
| Coordenação com catálogo mensal aprovado 24/80 | Comprovada como revisão editorial isolada e confirmação de escopo; adendo no catálogo/tasks da change mensal. Implementação runtime 24/80 permanece pendente naquela change |
| API/documentação e Bruno | Arquivos pertinentes atualizados e revisados; cliente Bruno/Flutter não executados |
| Observabilidade HTTP externa | Bloqueado: dumps habilitados, `optimize_route(site: trocado)` ainda retornou `samples: 0`, `routes: []`; testes in-process não substituem captura autenticada externa |

### Resultado do quality gate

Código e evidências executáveis do escopo confirmado passaram. Persistem 5.4 e, por consequência, o fechamento global de 5.6: falta captura de tráfego externo autenticado de Expense/Metrics/Insights e inspeção de queries em `optimize_route`. Não há alegação de performance real em escala ou ausência de N+1 medida pelo watcher. Esta change não foi arquivada nem declarada arquivável. O gate completo foi padrão/sequencial; não foi realizado novo gate paralelo/duas seeds nem prova de corrida entre processos. A revisão e aprovação históricas da change mensal permanecem intactas.

## Fechamento operacional e autorização de arquivamento — 11/10/2026

Após solicitar “Arquiva commita tudo e da push”, o usuário confirmou “já fiz” quanto às consultas HTTP reais. As pendências descritas acima são históricas e foram fechadas pela consulta final do MCP Lerd:

- `route_timing(site: trocado)`: 4 amostras de timing, mediana 148,5 ms, `slow: []`.
- `optimize_route(site: trocado)`: 4 amostras, mediana 148,5 ms, `routes: []` (nenhuma rota lenta reportada).
- `dumps_recent(site: trocado, ctx: fpm, kind: query, since: 30m, limit: 25)`: eventos HTTP reais de `GET /api/expenses`, Metrics com `group_by=category` e período de outubro/2026, `GET /api/insights` e Insights com setembro/2026. Fontes de autenticação e sessão confirmam passagem pelo fluxo autenticado; não foram armazenados tokens/bindings sensíveis na evidência.
- Nas amostras consultadas: Expense leu despesas por proprietário em um statement com `LIMIT 21` (1,50 ms); Metrics executou agregação agrupada em um statement (1,72 ms); Insights executou um statement `WITH periods` por consulta analítica (2,46–2,74 ms). Houve também consulta de Expense sem leitura SQL de despesas, compatível com o cache existente. Não foram observadas consultas de despesa por item/cartão nessa amostra.
- `analyze_queries` também devolveu repetições/queries lentas de migrations e do preflight/cleanup de testes via CLI. Elas não foram atribuídas a N+1 de HTTP; a evidência operacional foi restringida aos eventos `ctx=fpm` acima.

Limites: timing de quatro amostras e janela de 25 eventos de query são amostras pequenas/parciais, sem prova de performance em escala ou ausência universal de N+1. O gate completo, Pint, rastreabilidade e validações estritas registrados nesta etapa permanecem aprovados. Com a captura operacional verificada e a autorização explícita de arquivamento, 5.4 e 5.6 estão concluídas. A change mensal mantém suas pendências próprias e não será arquivada por este pedido.

Arquivamento realizado por `openspec archive expand-expense-categories --yes` em `2026-10-11-expand-expense-categories`, com sincronização de Expense, Metrics e Insights. Na revisão das specs sincronizadas, a referência textual antiga a dez categorias no requisito de classificação assíncrona foi atualizada para dezoito, com o requisito completo preservado no delta arquivado; removidas linhas vazias extras geradas no EOF e preenchido o Purpose existente de expense-metrics. Nenhum comportamento de produto adicional foi alterado.
