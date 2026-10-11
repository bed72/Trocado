## 1. Contratos e caso de uso de Expense

- [x] 1.1 Criar `ExpenseSuggestionsRepository` e `ExpenseSuggestionHistoryOutput` tipado para chave, descrição representativa e fatos mensais agregados, sem ORM e sem alterar contratos de CRUD/categorização (requisito: Leitura limitada sem efeitos no ciclo de vida de despesas).
- [x] 1.2 Criar `ExpenseSuggestionOutput` e `GetExpenseSuggestionsUseCase`, com `UserPort` antes do Repository, proprietário explícito e janela dos três meses civis anteriores derivada da referência usando o período de Core (requisitos: Consulta autenticada e isolada por proprietário; Janela de três meses civis anteriores).
- [x] 1.3 Implementar a política pura de três meses representados e igualdade integral de mínimo/máximo, mantendo centavos inteiros, e gerar identidade opaca estável por conta/chave sem acrescentar Entity persistente ou Domain Service (requisitos: Valor sugerido somente com consistência integral; Resposta JSON:API de sugestões transitórias).
- [x] 1.4 Criar e executar isoladamente `tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php`, cobrindo argumentos/chamada única, coleção vazia, janela em outubro/virada de ano, valores iguais/diferentes, mês ausente, múltiplos registros consistentes/divergentes, exatidão monetária e identidade estável; registrar evidência pelo launcher.

### Evidências da etapa 1 — 2026-10-11

- `lerd composer test -- tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php --compact`: 25 testes aprovados, 134 assertions.
- Pint pelo MCP Lerd (`vendor_run`, `bin: pint`, `args: ["--dirty", "--format", "agent"]`): aprovado.
- Após Pint, `lerd composer test -- tests/Unit/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 74 testes aprovados, 540 assertions.
- `openspec validate add-expense-suggestions --type change --strict --json --no-interactive`: aprovado, sem issues.
- Orquestração: proprietário lido uma vez, termo preservado, período explícito e uma chamada ao Repository; coleção vazia e falha de identidade sem leitura.
- Calendário: outubro, virada de ano em 31 de janeiro, fim de mês e fevereiro bissexto; referência civil inválida não consulta histórico.
- Política monetária: três meses e extremos iguais positivos, mês ausente, registros concentrados no mesmo mês, extremos divergentes, histórico fora da janela e extremos ausentes. Exatidão comprovada para `14001`, `9007199254740993`, divergência de um centavo acima da precisão de double e `PHP_INT_MAX`.
- Identidade: estabilidade com alteração de termo, referência, grafia e valor; distinção por proprietário e chave. Ordem e grafia da projeção preservadas.
- Limite da evidência: Unit usa fatos agregados tipados; a inclusão de todos os lançamentos, inclusive múltiplos registros consistentes/divergentes no mesmo mês, depende da prova PostgreSQL nas tarefas 2.4–2.5. Autenticação HTTP, isolamento real no banco, normalização, ranking SQL, statement único e transporte JSON:API permanecem pendentes nas etapas 2–3. Não há fluxo manual novo ou migration nesta etapa.

## 2. Leitura PostgreSQL de sugestões

- [x] 2.1 Implementar `EloquentExpenseSuggestionsRepository` reutilizando `ExpenseModel`, com filtro por conta em todas as leituras, normalização única, exclusão de descrições inutilizáveis e busca literal com bindings (requisitos: Consulta autenticada e isolada por proprietário; Entrada textual limitada e busca parcial literal; Descrições normalizadas e únicas).
- [x] 2.2 Completar o statement único com grafia por `(created_at, id)`, ranking prefixo/recência/frequência/chave, limite de cinco após agrupamento e fatos monetários da janela sem descartar divergências (requisitos: Ordenação determinística e limite fixo; Janela de três meses civis anteriores; Valor sugerido somente com consistência integral; Leitura limitada sem efeitos no ciclo de vida de despesas).
- [x] 2.3 Registrar o binding do novo Repository no `ExpenseServiceProvider`, sem alterar os decorators atuais ou acrescentar cache, e comprovar sua resolução pelo fluxo de consulta.
- [x] 2.4 Criar e executar isoladamente `tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php`, cobrindo isolamento de ranking/valor, substring/prefixo, caixa, whitespace externo, acentos/espaços internos preservados, caracteres LIKE literais e grafia com empate de timestamp.
- [x] 2.5 Completar e executar o mesmo arquivo com recência antes de frequência, desempate determinístico, cadastro retroativo, cinco resultados, vazio, limites inclusivos da janela, histórico antigo, mesmo mês sem recorrência, mês ausente e todos os casos de consistência; comprovar um statement de despesas para zero/um/cinco sugestões e restaurar query logs.

### Evidências da etapa 2 — 2026-10-11

- `lerd composer test -- tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php --compact`: primeira execução com 24 testes/84 assertions; após completar cenários de frequência histórica e isolamento, 26 testes aprovados/91 assertions. Ambas pelo launcher com migrations incrementais nos bancos exclusivos de execução.
- Pint pelo MCP Lerd (`vendor_run`, `bin: pint`, `args: ["--dirty", "--format", "agent"]`): aprovado.
- Após Pint, `lerd composer test -- tests/Unit/Expense tests/Feature/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 151 testes aprovados, 919 assertions.
- Normalização PostgreSQL: `regexp_replace` com `^[[:space:]]+|[[:space:]]+$` e flag `g` remove whitespace externo (espaço, tabulação e quebras de linha comprovados); `lower()` unifica caixa. A chave é compartilhada por busca, agrupamento e fatos monetários; acentos e espaços internos permanecem significativos. Chave usa collation `C` para agrupamento/desempate determinísticos, após conversão de caixa.
- Busca literal usa `strpos` com bindings, sem LIKE: `%`, `_`, barra invertida, aspas e texto com formato de SQL comprovados como literais.
- Provas de isolamento: descrição/grafia/recência/frequência de terceiros não alteram resultados; meses de outra conta não preenchem lacunas; valores de terceiros não invalidam padrão completo do proprietário.
- Ranking/limite: prefixo antes de substring; cadastro antes de frequência; frequência histórica inclusive fora da janela; desempate pela chave; cadastro retroativo e `updated_at` irrelevante; cinco grupos únicos após agregação, sem limitar registros monetários nem esconder divergência anterior.
- Fatos monetários e UseCase: limites inclusivos, exclusão de junho/outubro, histórico antigo sem valor, mês ausente, três registros no mesmo mês, múltiplos registros consistentes e divergências em ambas as ordens. `14001`, `9007199254740993` e `PHP_INT_MAX` preservados exatamente.
- Quantidade constante: zero/um/cinco grupos executam exatamente um statement, com bindings explícitos; estado de despesas preservado e query log vazio/estado de logging restaurados em finally. Binding comprovado por resolução do Repository e execução do UseCase pelo container.
- Limites: não há rota de sugestões nesta etapa; contrato HTTP e captura `optimize_route` dependem da etapa 3. `EXPLAIN`/tempo com histórico representativo continuam pendentes em 4.3; statement único não é alegação de performance medida. Nenhuma migration nova.

## 3. Contrato HTTP JSON:API

- [x] 3.1 Criar `GetExpenseSuggestionsRequest` com `query` obrigatório escalar textual de até 64 caracteres, trim externo, rejeição de vazio/array e de presença de `user_id`, lendo query string e preservando erros JSON:API associados aos parâmetros (requisitos: Entrada textual limitada e busca parcial literal; Consulta autenticada e isolada por proprietário).
- [x] 3.2 Criar `GetExpenseSuggestionsController`, resolvendo referência civil no timezone configurado, e `ExpenseSuggestionResponse` com recurso `expense-suggestions`, ID string, descrição e omissão real de `amount` ausente; confirmar a API first-party instalada pelo Boost antes de implementar (requisitos: Janela de três meses civis anteriores; Resposta JSON:API de sugestões transitórias).
- [x] 3.3 Adicionar a rota estática nomeada `expenses.suggestions` no grupo protegido existente e verificar sua resolução e middlewares sem alterar endpoints atuais.
- [x] 3.4 Criar e executar isoladamente `tests/Feature/Expense/Presentation/Http/GetExpenseSuggestionsHttpTest.php`, cobrindo Bearer válido/ausente/inválido/expirado/revogado, conta inativa/não verificada, isolamento, query inválida e `user_id` presente inclusive vazio; usar fixtures explícitas e tokens reais nos cenários de autenticação.
- [x] 3.5 Completar e executar o mesmo arquivo com coleção vazia, tipo/IDs/atributos JSON:API, omissão de valor/categoria/data, IDs estáveis entre buscas/variantes e distintos entre contas, referência no timezone configurado e ausência de mudanças em despesas/tentativas, chamadas de IA ou jobs; restaurar relógio/timezone e manter fakes explícitos.

### Evidências da etapa 3 — 2026-10-11

- Boost/Search Docs consultado para Form Requests e recursos JSON:API first-party; API de `JsonApiResource` instalada conferida. Response usa `toId`, `toType`, `toAttributes` e coleção oficial; `amount` é omitido do array quando ausente.
- `lerd composer test -- tests/Feature/Expense/Presentation/Http/GetExpenseSuggestionsHttpTest.php --compact`: 28 testes/181 assertions após corrigir a expectativa do action invokable e usar tokens de classificação únicos na fixture; com cenários adicionais de histórico/busca vazios, 30 testes aprovados/185 assertions.
- Pint pelo MCP Lerd (`vendor_run`, `bin: pint`, `args: ["--dirty", "--format", "agent"]`): aprovado.
- Após Pint, `lerd composer test -- tests/Unit/Expense tests/Feature/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 181 testes aprovados, 1104 assertions, pelo launcher com migrations incrementais em banco exclusivo.
- `lerd artisan route:list --name=expenses.suggestions -vv --no-interaction`: rota estática GET/HEAD confirmada com autenticação Sanctum, contexto autenticado, throttle autenticado, bindings, conta ativa, verificação de e-mail e extensão de sessão. Teste compara middlewares com `expenses.index` e confirma resolução do Controller.
- Autenticação: Bearer real válido, expirado e revogado; ausência e token inválido retornam `401` JSON:API sem leitura. Conta bloqueada, pendente ou não verificada retorna `403` sem leitura.
- Validação: query original decodificada uma vez, sem confiar nos valores já alterados por trim/conversão de strings vazias dos middlewares. Ausência, vazio, whitespace, arrays/estruturas, duplicação e 65 caracteres rejeitados; comprimento antes do trim comprovado. Presença de `user_id`, inclusive vazio, sem valor, próprio/terceiro e array, rejeitada. Erros usam `source.parameter`; corpo GET não fornece o termo. 64 caracteres Unicode aceitos e whitespace externo removido sem comprimir espaços internos.
- Transporte: tipo `expense-suggestions`, ID string opaco, atributos permitidos exatos, centavos inteiros e omissão real de valor sem consistência; nenhum atributo de categoria/data/proprietário/frequência/timestamp nem paginação. Vazio por ausência de histórico ou correspondência; isolamento real entre contas; IDs estáveis entre termos e nova grafia e distintos entre contas.
- Referência temporal: fronteira UTC de novembro ainda em outubro em `America/Sao_Paulo` produz janela de julho a setembro. Relógio/timezone restaurados após os cenários.
- Efeitos: despesas e campos de tentativa de classificação comparados integralmente antes/depois em padrões consistentes e divergentes; tabelas de jobs preservadas. Ports de classificação/despacho não chamados; Queue/Bus fakes sem despachos e agente fake nunca solicitado.
- `lerd artisan migrate:status --no-interaction`: nenhuma migration pendente no ambiente local; nenhuma migration nova necessária. GET real sem Bearer confirmou `401` JSON:API.
- Diagnóstico Lerd: captura já estava habilitada, sem alteração de configuração. `optimize_route` retornou `samples: 0`/rotas vazias; request real foi apenas não autenticado e não comprova performance da consulta. Captura autenticada e `EXPLAIN` com histórico representativo permanecem pendentes em 4.3–4.4.

## 4. Verificação e rastreabilidade da implementação

### Centralização de data civil solicitada após a etapa 3 — 2026-10-11

- Criados `Core\Application\Ports\DatePort::today()` e `Core\Infrastructure\Adapters\DateAdapter`, com binding no `CoreServiceProvider`. O Adapter lê relógio e timezone configurado a cada chamada e retorna `Y-m-d`.
- Controllers de criação de Expense, sugestões, Metrics e Insights consomem o Port; UseCases continuam com referências explícitas. Criação consulta o Port somente no fallback de `occurred_on`. A permissão arquitetural é específica para `DatePort` na Presentation dos três contextos, documentada em `ARCHITECTURE.md`; o design foi ajustado à decisão posterior do usuário.
- `lerd composer test -- tests/Feature/Core/Infrastructure/Adapters/DateAdapterTest.php --compact`: 5 testes/11 assertions aprovados. Prova binding, timezone independente do padrão PHP, fronteiras de mês/ano, dia bissexto e atualização do relógio/configuração sem cache.
- `lerd composer test -- tests/Feature/Expense/ExpenseOwnershipTest.php --compact`: 7 testes/31 assertions aprovados. Cenários novos comprovam chamada única ao Port para data omitida e ausência de chamada quando a ocorrência é explícita.
- Pint `--dirty --format agent`: aprovado. Após Pint, `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: 918 testes/5627 assertions aprovados, 24802 ms.
- `lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: 918 testes/5627 assertions aprovados, 17264 ms. Inclui os fluxos HTTP afetados e fronteiras; não substitui as medições operacionais pendentes abaixo.
- OpenSpec estrito aprovado; busca em controllers não encontrou mais obtenção direta de data atual por Carbon/Date ou leitura de `app.timezone`.

- [x] 4.1 Executar arquivos novos pelo launcher `lerd composer test -- <caminho> --compact`, suítes Unit/Feature focadas de Expense e `tests/Unit/Architecture/ContextBoundariesTest.php`; registrar comandos, resultados e bloqueios sem tratar skips inesperados como aprovação.
- [x] 4.2 Executar Pint `--dirty --format agent` pela ferramenta Lerd após as últimas edições PHP e repetir as verificações afetadas pelo formatter, preservando mudanças externas à feature.
- [x] 4.3 No ambiente de implementação, conferir migrations pendentes antes do fluxo manual e aplicar incrementalmente se necessário; inspecionar `EXPLAIN` e tempo da consulta com histórico representativo e registrar observações sem acrescentar índices ou dependências sem decisão.
- [x] 4.4 Capturar a rota afetada pelos diagnósticos Lerd e consultar `optimize_route` para verificar N+1/slow queries, preservando autenticação e recursos de captura; registrar limites da medição e restaurar configurações de diagnóstico alteradas.
- [x] 4.5 Mapear todos os cenários da spec para evidências, revisar fronteiras e preservação de criação/categorização, validar `add-expense-suggestions` estritamente e atualizar checkboxes somente com trabalho comprovado; manter a mudança não arquivada até autorização e gate aplicável.

### Evidências finais — 2026-10-11

- Arquivos novos isolados pelo launcher (`lerd composer test -- <caminho> --compact`): `GetExpenseSuggestionsUseCaseTest.php`, 25 testes/134 assertions; `EloquentExpenseSuggestionsRepositoryTest.php`, 26 testes/91 assertions; `GetExpenseSuggestionsHttpTest.php`, inicialmente 30 testes/185 assertions, depois 31 testes/193 assertions com a prova integrada de cadastro por valor diferente da sugestão, finalmente 32 testes/195 assertions (1513 ms) com histórico composto somente por descrições não utilizáveis. As duas lacunas de cenário foram fechadas somente em testes, sem correção de produto.
- Pint `--dirty --format agent` executado após a última edição PHP: aprovado. Após Pint, `lerd composer test -- tests/Unit/Expense tests/Feature/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 185 testes/1120 assertions aprovados, 8801 ms. A execução anterior com 184 testes/1118 assertions e os resultados de etapas e centralização permanecem históricos.
- Migrations operacionais: `lerd artisan migrate:status --no-interaction` mostrou todas aplicadas; não houve necessidade de migrate nem alteração de schema.
- `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` da consulta equivalente ao statement do Repository, com proprietário 13, termo `[Demo]` e janela inclusiva `2026-07-01`–`2026-09-30`: histórico local existente de 88 despesas, 16 descrições e seis meses (`2026-05-01`–`2026-10-08`). Planning Time 1,529 ms; Execution Time 0,920 ms; 5 linhas finais. Plano: Seq Scan com proprietário e texto no filtro → Sort/WindowAgg para grafia → Incremental Sort/GroupAggregate para 16 grupos → top-N heapsort → Limit. Leitura das 88 linhas em um loop; sort principal 33 kB e top-N 26 kB; zero temp reads/writes. Índices existentes por proprietário/ocorrência preservados. Seq Scan nessa tabela pequena não fundamenta um índice novo.
- Limite do EXPLAIN: uma execução sobre histórico demonstrativo pequeno, representativo das formas funcionais, não de grande volume ou concorrência de produção. Não há promessa de escalabilidade, SLA ou teste de carga.
- Captura HTTP real autorizada pelo usuário: token temporário na conta demonstrativa existente, usado apenas em GET e revogado em finally (1 token removido, 0 restante com seu nome único). Nenhum usuário/despesa criado; fingerprints de todas as despesas e quantidade de jobs iguais antes/depois. Token não foi exposto nem gravado no repositório. Efeitos normais de autenticação/limiter/sessão permanecem permitidos.
- Nove requests `200`, três por termo: `no-match-expense-suggestions` → 0 itens, HTTP 168,952/71,590/73,996 ms (mediana 73,996); `Internet` → 1 item, 70,372/72,352/69,647 ms (mediana 70,372); `[Demo]` → 5 itens, 71,613/71,327/72,291 ms (mediana 71,613). IDs estáveis nas repetições. Tempos incluem HTTP local e captura/profiler já habilitados; a primeira amostra é fria, não prova latência de produção.
- Lerd `route_timing`/`optimize_route`: 9 amostras, mediana interna 65 ms, nenhuma rota lenta e `routes: []`. `analyze_queries` com `slow_ms: 10` e `min_repeat: 2`: zero slow findings; alertas de fingerprint investigados por request e SQL. O fingerprint `select * from ? where ?.? = ? limit ?` reúne tabelas diferentes (`personal_access_tokens` e `users`); atualizações/lock do token pertencem aos middlewares, não a leituras por candidato. Não foi identificado N+1 de sugestões.
- Eventos FPM por rid: oito das nove requests retiveram um statement `WITH normalized` de despesas cada, inclusive resultados 0/1/5; tempos 2,410–2,870 ms. Uma request teve captura parcial (somente duas consultas de autenticação retidas), sem alegação de completude do buffer. A prova executável de cardinalidade constante para 0/1/5 está no teste PostgreSQL, sem depender desse buffer.
- Preservação de diagnóstico: dumps e profiler já estavam habilitados e permaneceram habilitados; não foi limpo o buffer compartilhado nem alterada configuração. O indicador inicial de watcher inativo não bloqueou a coleta; após as requests, timing e consultas foram disponibilizados. Nenhuma ação de reparo global foi aplicada.

#### Gate completo após a última edição PHP e Pint

Todos os comandos usam `lerd composer test --`, launcher e bancos exclusivos por execução/processo, com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`.

| Modo/opções adicionais | Testes | Assertions | Duração | Resultado |
| --- | ---: | ---: | ---: | --- |
| Ordem padrão | 920 | 5637 | 25448 ms | Aprovado |
| `--order-by=random --random-order-seed=20261009` | 920 | 5637 | 24505 ms | Aprovado |
| `--order-by=random --random-order-seed=20261010` | 920 | 5637 | 24125 ms | Aprovado |
| `--parallel --processes=2` | 920 | 5637 | 17312 ms | Aprovado |

- A primeira chamada MCP do paralelo expirou sem resultado; não foi contada como sucesso. Antes de repetir isoladamente, processos de host/container foram inspecionados e não havia launcher/Pest em execução. A repetição acima produziu resultado aprovado. Os gates completos incluem os cenários Redis, concorrência e duas invocações simultâneas previstos pelo launcher; não houve skip/incomplete/risky inesperado aprovado por omissão de flags.
- Revisão de arquitetura: contratos/Outputs/UseCase independentes de ORM; Repository específico, owner explícito antes da leitura; um statement sem linhas individuais na Application; binding direto sem decorator de cache; Controller fino, referência civil via DatePort e Response oficial; permissões específicas de Core mantidas. CRUD, decorators e contratos de categorização não foram ampliados por sugestões. Ausência de cache de sugestões também conferida no fluxo Controller → UseCase → Repository e binding; não se afirma ausência de cache do limiter, que é efeito permitido dos middlewares.

#### Matriz de rastreabilidade por Scenario

`P` = comprovado no nível indicado. Evidências de regra/query/transporte são compostas por responsabilidade; não se alega que cada variante monetária tenha um teste HTTP duplicado.

- **U:** `tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php`.
- **R:** `tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php`.
- **H:** `tests/Feature/Expense/Presentation/Http/GetExpenseSuggestionsHttpTest.php`.
- **A:** `tests/Unit/Architecture/ContextBoundariesTest.php`.
- **D:** `tests/Feature/Core/Infrastructure/Adapters/DateAdapterTest.php`.
- **C:** suítes existentes de Expense (ownership, classification, repositories de cache e observabilidade), incluídas nos gates acima.
- **L:** EXPLAIN e captura autenticada registrados nesta seção; limites de amostragem mantidos.

| Requirement / Scenario | Evidência específica | Estado |
| --- | --- | --- |
| Consulta autenticada / Histórico exclusivo da conta | R `isolates descriptions...` e `does not let foreign values...`; H `exposes only the owner...`; U owner lido uma vez | P |
| Consulta autenticada / Autenticação ausente ou inválida | H `rejects absent invalid expired or revoked Bearer tokens...`, quatro variantes e Repository nunca chamado | P |
| Consulta autenticada / Conta sem acesso permitido | H `rejects inactive and unverified accounts...`, blocked/pending/unverified | P |
| Consulta autenticada / Proprietário informado pelo cliente | H query inválida, datasets empty/bare/own/foreign/array owner, `source.parameter` e ausência de leitura | P |
| Entrada textual / Busca parcial sem diferença de caixa | R normalização e `uses created_at... keeps substring matches`; H duas descrições por termo `Int` | P |
| Entrada textual / Termo com espaços externos | R termo com tabulação/espaço/quebra; H `accepts 64 Unicode characters and trims only external whitespace` | P |
| Entrada textual / Entrada inválida | H `rejects invalid query strings...`: ausência/vazio/whitespace/65 Unicode/antes de trim/array/nested/duplicado; GET body rejeitado | P |
| Entrada textual / Caracteres especiais literais | R `searches special characters literally...`: percent/underscore/backslash/quote/SQL-shaped, bindings | P |
| Entrada textual / Acentos e espaços internos preservados | R `preserves accents and internal spaces...`; H termo com espaços internos mantidos | P |
| Descrições / Duplicação e variações de caixa ou espaços externos | R `normalizes case and external whitespace consistently...`: uma chave e três meses agregados de variantes | P |
| Descrições / Grafia do último registro | R mesmo teste com timestamps distintos; H ID estável e nova variante posterior | P |
| Descrições / Empate no timestamp de cadastro | R mesmo teste com duas grafias no mesmo timestamp e maior ID vencedor | P |
| Descrições / Descrições não utilizáveis | H coleção vazia, dataset `unusable descriptions only` com null/vazio/tabulação/quebras; R exclusão de descrições inutilizáveis | P |
| Ordenação / Prefixo precede correspondência interna | R `ranks prefix before substring...` e `uses created_at... keeps substring matches` | P |
| Ordenação / Recência precede frequência | R ranking, grupo mais recente com um registro antes de grupo mais frequente antigo | P |
| Ordenação / Frequência e desempate final | R ranking e `counts historical frequency...`, grupos empatados em timestamp e chave crescente | P |
| Ordenação / Cadastro retroativo | R `uses created_at rather than occurrence or update time...`, ocorrência antiga e updated_at irrelevante | P |
| Ordenação / Mais de cinco descrições elegíveis | R ranking/limite após grupos, frequência histórica e divergência além de cinco registros; L resposta com cinco grupos | P |
| Janela / Consulta em outubro | U dataset October com período exato; R limites inclusivos e divergências de junho/outubro excluídas | P |
| Janela / Virada de ano | U dataset `year boundary on the 31st`, outubro–dezembro de 2026 sem overflow | P |
| Janela / Fuso configurado | H fronteira UTC novembro/São Paulo outubro; D timezone independente do padrão PHP, virada de ano e dia bissexto | P |
| Janela / Descrição com histórico antigo | R dataset `old history only`; H registro antigo elegível sem amount; U projeção vazia da janela | P |
| Valor / Mesmo valor nos três meses | U extrema iguais; R registros consistentes; H sugestão com 14000 e cadastro independente | P |
| Valor / Valores diferentes entre meses | R dataset `different months`; U min/max diferentes; H sem efeitos, variante inconsistent, amount omitido | P |
| Valor / Três registros no mesmo mês | R dataset `three records in one month`; U representedMonths=1; omissão HTTP de Output sem amount comprovada em H | P |
| Valor / Mês ausente apesar de outros meses consistentes | R `missing month` e isolamento que impede meses de terceiros preencherem lacunas; U representedMonths=2; H sem amount | P |
| Valor / Múltiplos registros consistentes | R dataset `multiple consistent records` em três meses e duplicata mensal; U extrema iguais | P |
| Valor / Divergência dentro de um mês | R datasets earlier/later divergent record e divergência antiga além de cinco registros; U min/max diferentes | P |
| Valor / Normalização compartilhada pela regra monetária | R normalização com três grafias em meses distintos e extrema iguais; UseCase preserva chave sem reagrupar | P |
| Valor / Valor inteiro exato | R 14001, 9007199254740993, PHP_INT_MAX; U também diferença de um centavo acima da precisão de double; H amount=14001 | P |
| JSON:API / Sugestão com valor | H `exposes only the owner...`, `type`, ID string e atributos exatos; GET consistente sem efeitos | P |
| JSON:API / Sugestão somente de descrição | H atributos exatos com apenas description e `assertJsonMissingPath(amount)` para divergência; sem categoria/data/proprietário | P |
| JSON:API / Histórico ou busca vazios | H datasets no history/no matches com `assertExactJson(data: [])`; rota estática confirmada | P |
| JSON:API / Identidade estável de sugestão | H `keeps ids stable across terms and new spelling variants...`; U também separação por chave/data/valor; L repetição de IDs | P |
| Leitura limitada / Quantidade constante de statements de despesas | R query log: exatamente um statement para 0/1/5; L 9 requests, 8 traces de despesas retidos, sem confundir tabelas de autenticação | P |
| Leitura limitada / Consulta sem efeitos em despesas ou categorização | H estado integral de despesas/tentativas e jobs, Ports nunca chamados, Queue/Bus/AI sem efeitos; R sem mutação; L fingerprints preservados; revisão de código/binding sem cache de sugestões | P |
| Leitura limitada / Cadastro após seleção da sugestão | H `allows the consumer to create an expense with a value different...`: sugestão 14000 → POST 15000 persistido, categoria inicial other; C preservação dos demais contratos | P |

Todos os 37 Scenarios estão mapeados. A suíte completa e A comprovam fronteiras e regressões dos contextos afetados; medições locais não constituem benchmark de escala ou concorrência de produção. `openspec validate add-expense-suggestions --type change --strict --json --no-interactive` aprovado, sem issues; `git diff --check` aprovado. Consulta final confirmou zero tokens temporários `expense-suggestions-gate-*`. As 19 tarefas estão concluídas com evidência; ao concluir o gate, a mudança aguardava autorização para arquivo.

### Arquivamento autorizado — 2026-10-11

Após solicitação explícita do usuário, `openspec archive add-expense-suggestions --yes --json` arquivou a mudança em `2026-10-11-add-expense-suggestions` e consolidou os oito Requirements em `openspec/specs/expense-suggestions/spec.md`, cujo Purpose foi preenchido com a finalidade durável da capacidade. Evidências e resultados históricos foram preservados.
