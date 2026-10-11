## Context

Laravel 13, PostgreSQL, paginação por cursor e cache de páginas por proprietário são o baseline. A composição usará o Query Builder nativo por meio de Eloquent, sem pacote adicional. A criação da spec autorizava somente artefatos; em 2026-10-11, o usuário autorizou iniciar apply pela etapa 1 (tarefas 1.1–1.3), limitada ao fechamento do contrato, revisão do baseline e conferência das APIs. Implementação PHP, migration, limpeza e testes da aplicação pertencem às etapas seguintes.

**Revisão de escopo em 2026-10-11:** após iniciar a etapa de descrição obrigatória, o usuário cancelou esse trabalho e pediu manter descrição nullable. A implementação, migration, classes de cleanup/invalidação e testes específicos foram revertidos; o banco local não foi migrado nem limpo. A spec ativa conserva criação/edição/Domain e dados existentes, limitando-se às consultas combináveis. Evidências do trabalho revertido são históricas e não comprovam a implementação ativa.

### Alterações locais preexistentes

O checkout contém alterações não commitadas em seis arquivos de produção de Expense (contrato `ExpenseRepository`, `GetAllExpenseUseCase`, Repositories de cache/persistência, Controller e Request de listagem), no teste `CachedExpenseRepositoryTest.php` e dois testes novos não rastreados (`GetAllExpenseHttpTest.php` e `GetAllExpenseUseCaseTest.php`). Esses arquivos implementam os filtros opcionais de ano/mês/dia e são baseline incremental, não trabalho novo concluído por esta spec.

Também há alterações preexistentes em `bruno/Expense/02 - Get Expense Suggestions.bru` e `bruno/Metrics/01 - Get Expense Metrics.bru`; não pertencem automaticamente a esta mudança. Na revisão da etapa 1 esses arquivos foram preservados integralmente. Qualquer agrupamento de commits depende de pedido específico do usuário; a autorização de apply não autoriza commit.

Evidência histórica da etapa anterior, conforme a conversa: 150 Feature de Expense em paralelo com dois processos, 50 Unit de Expense e 26 verificações de arquitetura passaram. São evidências do baseline, não dos novos filtros, ordenações ou descrição obrigatória. Todas as tarefas de implementação desta mudança começam pendentes.

### Revisão do baseline — tarefa 1.2, 2026-10-11

Referência Git: `HEAD 9c33dc42f9102c68a9f94d53ea53142f3ff768fd` **mais os diffs locais**, identificados por `git status --short` e revisados com `git diff -- app/Expense tests/Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseRepositoryTest.php` e `git diff -- bruno`. Os dois testes não rastreados foram lidos integralmente. HEAD isolado não inclui os filtros civis locais.

| Arquivo / área | Baseline local inspecionado | Continuidade no novo escopo |
| --- | --- | --- |
| `ExpenseRepository.php`, `GetAllExpenseUseCase.php` | Parâmetro opcional `DatePeriodValueObject $period`; UserPort fornece proprietário explicitamente | Substituir parâmetros coesos por GetAllExpenseInput na tarefa 2.1, atualizando argumentos nomeados/doubles |
| `GetAllExpenseRequest.php` | Allowlist year/month/day, dependências civis, checkdate, conversão para ano/mês/dia inclusivos; page[size] 1–100/padrão 20; cursor canônico restrito a occurred_on/id/direção | Preservar civil; acrescentar novos critérios e validação de cursor sem perder rejeição de campos/tipos arbitrários |
| `EloquentExpenseRepository.php` | user_id antes de whereBetween(occurred_on); occurred_on DESC/id DESC; cursorPaginate e mapping de página | Manter escopo/ordem padrão, usar limites independentes para intervalos abertos e allowlist para sort |
| `CachedExpenseRepository.php` | Namespace v1, chave por proprietário/tamanho/cursor com limites civis quando presentes; TTL 60; tag de conta e DB::afterCommit para CRUD | Versionar namespace e identidade por todos os critérios; preservar invalidação após confirmação |
| `GetAllExpenseController.php` | Repassa período; next/prev preservam filter e page[size]; Response mantém JSON:API | Ampliar links para os novos filtros e sort sem armazenar links no cache |
| Bruno Suggestions | Termo de exemplo mudou de Int para Mer | Alteração preexistente preservada |
| Bruno Metrics | Ativa group_by=category e período 2026-10-01 a 2026-10-31 | Alteração preexistente preservada |

### Mapa de cenários existentes

Os caminhos abaixo são relativos a `tests/`. O mapa descreve assertions inspecionadas, **não execução nesta etapa**.

| Arquivo | Cenários existentes aproveitáveis | Limite da evidência |
| --- | --- | --- |
| `Unit/Expense/Application/UseCases/GetAllExpenseUseCaseTest.php` (não rastreado) | Com/sem período; proprietário 20, tamanho 6, cursor e retorno repassados ao contrato | Orquestração pura; não prova SQL/cache/HTTP |
| `Feature/Expense/Presentation/Http/GetAllExpenseHttpTest.php` (não rastreado) | Sem filtro, ano/mês/dia, bissexto, período vazio, extremos civis; ocorrência distinta de cadastro; isolamento de contas; filtros incompletos/formatos/limites/estrutura/chave desconhecida e pointers JSON:API | Não cobre novos intervalos abertos, categorias, valores, sorts nem fingerprint de cursor |
| Mesmo HTTP | next/prev com ano/mês/dia e empates por ID; page[size]=6 no mês; padrão 20 atravessando anos; edição muda páginas do período antigo/novo e sem filtro | Preservar esses objetivos e as fixtures com descrição opcional/nullable |
| `Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseRepositoryTest.php` (diff local) | Períodos equivalentes compartilham página; sem filtro/ano/mês/dia são distintos; limites encaminhados; CRUD invalida variantes da conta sem invalidar outra | Double observa chamadas; não prova seleção PostgreSQL ou Redis real/rollback no novo escopo |

As contagens históricas 150 Feature/50 Unit/26 arquitetura são apenas o relato já existente da etapa anterior, sem logs reobtidos na revisão da etapa 1. Novas assertions alfabéticas e novos filtros continuam sem prova executável. Os gaps de consulta (cursor sem vínculo ao período, namespace v1 e critérios limitados) estão cobertos pelas tarefas pendentes, não tratados como implementação concluída. Descrição anulável é o contrato preservado após o cancelamento, não um gap a corrigir.

## Goals / Non-Goals

**Goals:** consulta combinável no endpoint atual, cursor determinístico e cache coerente, preservando fronteiras, descrição nullable e o comportamento sem parâmetros.

**Non-Goals:** descrição obrigatória, cleanup, NOT NULL/CHECK de descrição, infraestrutura de invalidação de cleanup, DSL RQL arbitrária, `include`/seleção de campos, busca textual, endpoints genéricos, novos contextos/relations, alterações no mecanismo de classificação, exposição de `user_id`, migração para offset, refactor de toda a suíte ou publicação em produção nesta etapa.

## Decisions

### 1. Contrato HTTP explícito e filtros normalizados

`filter[year/month/day]` conserva a regra mês exige ano e dia exige ambos. `filter[from/to]` recebe datas canônicas `Y-m-d`, limites inclusivos e independentes; presença de qualquer limite junto com qualquer componente civil é erro. `filter[category]` recebe identificadores do catálogo separados por vírgula; itens vazios e desconhecidos são rejeitados, duplicatas válidas são normalizadas. `filter[amount_min/max]` recebe inteiros em centavos de `0` a `9223372036854775807`; cada limite é opcional e mínimo não pode superar máximo. Zero é um limite válido de consulta, sem mudar a invariante de valor positivo da despesa.

`sort` é uma lista não vazia separada por vírgulas, de até três campos distintos entre `occurred_on`, `amount`, `description`; `-` significa decrescente. Campo duplicado, ainda que com direção diferente, desconhecido, token vazio ou estrutura array gera `422`. ID não é configurável pelo cliente e é acrescentado decrescente. Ausência de sort equivale a `-occurred_on,-id`; ausência de filtros não preenche mês ou data atuais. A sintaxe é um contrato próprio da API, sem linguagem de consulta arbitrária.

### 2. Application tipada e Query Builder nativo na Infrastructure

`GetAllExpenseInput` em `Expense/Application/Data` é `final readonly`, constructor-only, contendo tamanho, cursor, limites civis normalizados, categorias, valores e ordenações, sem Request, ORM, SDK ou formatação HTTP. Componentes ano/mês/dia são convertidos para limites civis usando os conceitos existentes de Core na borda; intervalos abertos não são transformados em VOs que exigem ambos os limites. O UseCase recebe a entrada e obtém o proprietário por `UserPort`; `ExpenseRepository::getAll()` recebe proprietário e entrada, retornando o `ExpensePageOutput` existente.

`EloquentExpenseRepository` inicia `ExpenseModel::query()->where('user_id', $userId)` e aplica critérios explícitos da entrada: `where` com `>=`/`<=` para cada limite independente de data/valor, `whereIn` para categorias e `orderBy` para cada ordenação efetiva, seguido de `orderByDesc('id')`. Limites opcionais são testados por `!== null`, preservando zero como valor válido. Uma allowlist/mapeamento explícito traduz os campos públicos de sort para colunas conhecidas; nunca usar identificadores SQL arbitrários do cliente. A consulta termina em `cursorPaginate`, mantendo o mapping Model/Entity no Repository. Não construir Request interna, ler a Request atual, usar `app()` para descobrir filtros, criar interfaces sem fronteira real, parser RQL ou framework genérico de filtros.

Alternativa considerada: Spatie Laravel Query Builder, inicialmente escolhido e depois substituído pelo usuário pela abordagem nativa. O conjunto delimitado de filtros e três campos de sort cabe em composição explícita no Repository, sem dependência nem adaptação HTTP. Isso reduz etapas na aplicação, mas não implica ganho de performance comprovado: custo do PostgreSQL depende do SQL, planos e índices e deve ser medido. Confirmar APIs na versão Laravel instalada; não alterar Composer por esta mudança.

### Conferência de APIs — tarefa 1.3, 2026-10-11

Boost/application-info confirmou PHP 8.5 e `laravel/framework 13.34.0`; a conexão consultada é PostgreSQL 16.10/UTF8. Boost/Search Docs foi consultado primeiro para queries, ordenação, cursor pagination e validação; código instalado foi conferido para as particularidades de aliases/expressões e decodificação. Nenhuma dependência foi adicionada e Composer permaneceu intacto.

| API / fonte instalada | Conferência e consequência |
| --- | --- |
| `Query/Builder.php::whereIn()` (1479), `whereBetween()` (1667) | Categorias por conjunto com bindings; BETWEEN recebe dois limites e conserva o baseline fechado. Para limites independentes, usar where >=/<=; testar !== null antes de aplicar, inclusive zero |
| `Query/Builder.php::orderBy()` (3038), `orderByDesc()` (3072) | Chamadas sucessivas preservam prioridade; asc/desc aceitos; coluna deve vir de allowlist fixa, pois identificadores não são bindings |
| `Query/Builder.php::selectRaw()` (356), `orderByRaw()` (3182) | selectRaw acrescenta Expression e aceita bindings; a expressão de ordenação por cursor deve ser fixa e sem parâmetros. orderByRaw registra sql/type, sem column/direction, e é excluído da lista de critérios do paginator |
| `Eloquent/Builder.php::cursorPaginate()` (1218), `ensureOrderForCursorPagination()` (1231) | Assinatura instalada conserva perPage/columns/cursorName/cursor; Cursor explícito é aceito. Navegação prev inverte as direções; garantir critério único composto com ID e ausência de valores nulos |
| `Database/Concerns/BuildsQueries.php::paginateUsingCursor()` (464), `getOriginalColumnNameForCursorPagination()` (561) | Recupera expressão de alias selecionado e constrói comparações lexicográficas por = e >/<. Na versão instalada, a expressão só vira Expression nesses predicados se contiver parênteses; com descrição nullable, a chave interna será `(COALESCE(description, '') COLLATE "expense_description_ci_ai") as description_sort` |
| `Pagination/AbstractCursorPaginator.php::nextCursor()` (177), `previousCursor()` (158), `getParametersForItem()` (211) | Extrai valores dos campos efetivamente ordenados, incluindo alias; devolve null quando não há página correspondente. Conservar next/prev, não implementar paginação offset ou ordenação em PHP |
| `Pagination/Cursor.php::fromEncoded()` (116), `encode()` (105) | Base64 URL-safe de JSON com `_pointsToNextItems`; decodificação nativa não valida tipos, allowlist ou vínculo aos filtros/sort. Validação canônica/tipada e fingerprint pertencem ao contrato novo antes de consultar cache/banco |

Fontes versionadas: documentação Laravel 13 de [queries](https://github.com/laravel/docs/blob/13.x/queries.md), [pagination](https://github.com/laravel/docs/blob/13.x/pagination.md) e [validation](https://github.com/laravel/docs/blob/13.x/validation.md), consultadas via Boost; documentação PostgreSQL 16, [collations ICU não determinísticas e customização](https://www.postgresql.org/docs/16/collation.html#ICU-CUSTOM-COLLATIONS). Os caminhos da tabela são relativos a `vendor/laravel/framework/src/Illuminate/` e as linhas registram esta versão instalada. A conferência prova disponibilidade/contrato das APIs, não execução da futura query ou performance.

### 3. Ordenação efetiva, cursor e compatibilidade

A lista de sort conserva a prioridade do cliente; adicionar `id DESC` garante unicidade. Descrição permanece opcional/nullable; somente a chave interna de ordenação precisa ser não nula para o cursor Laravel. Em 2026-10-11, o usuário escolheu **ignorar maiúsculas/minúsculas e acentos**: `Água`, `agua` e `ÁGUA` são equivalentes, assim como `Açaí` e `acai`. Equivalência não insere desempate pelo texto original: os próximos campos de sort e, por fim, `id DESC` resolvem o empate nas duas direções. A descrição armazenada e devolvida permanece original, inclusive null.

A implementação usará uma collation própria `expense_description_ci_ai`, criada por migration incremental com `provider = icu`, `locale = 'und-u-ks-level1'` e `deterministic = false`. Isso define comparação Unicode de nível primário, independente da collation padrão do banco, e evita desempate implícito por bytes. ICU é capacidade do PostgreSQL, sem extensão `unaccent` ou dependência Composer. O ambiente local PostgreSQL 16.10/UTF8 possui collations ICU, confirmado por consulta read-only em 2026-10-11; a criação e prova da collation ainda pertencem à tarefa 2.5. Um ambiente sem ICU deve falhar explicitamente na migration, sem fallback que altere o contrato.

No Repository, selecionar `expenses.*` e a expressão fixa **parentesizada** `(COALESCE(description, '') COLLATE "expense_description_ci_ai") as description_sort`, usando `selectRaw` sem parâmetros na expressão, e ordenar pelo alias interno via `orderBy('description_sort', 'asc'/'desc')`. Null equivale à string vazia somente na chave interna: esse grupo fica antes dos textos em ordem crescente e depois em decrescente; os próximos critérios e ID resolvem os empates. O alias não é campo público de sort nem atributo JSON:API e não altera a descrição persistida ou sua resposta. Laravel 13.34.0 recupera a expressão do alias para os predicados de cursor; os parênteses fazem o paginator tratá-la como Expression, conservando a collation também em `=`, `<` e `>`. Apenas `orderByRaw('description COLLATE ...')` não atende ao cursor nativo. O cursor usa o valor selecionado do alias; não precisa transliterar o texto em PHP. SQL, comparações do cursor e eventual índice por expressão devem usar a mesma collation.

Formas Unicode canonicamente equivalentes (por exemplo, `Água` com U+00C1 ou A + U+0301) também empatam. Não se aplica trim, lowercase, remoção de acentos ou reescrita da descrição para implementar a ordenação; demais caracteres seguem a collation ICU escolhida, sem habilitar ordenação numérica natural ou descarte adicional de pontuação. Provas PostgreSQL devem cobrir equivalência, prioridade e navegação nas duas direções antes de considerar a ordenação implementada.

Cursor permanece opaco e não é autorização. Novos cursores devem carregar posição com campos/tipos da ordenação efetiva e metadados suficientes para detectar consulta/ordenação incompatível; fingerprint inclui critérios normalizados e prioridade/direção de sort, não tamanho ou proprietário. Campos arbitrários de cursor não podem se tornar identificadores SQL. Validar antes da leitura/cache e conservar o avanço/retorno do paginator Laravel.

A implementação usa `ExpenseQueryCursorPort` como fronteira da capacidade de identidade/codec opaco e `ExpenseQueryCursorAdapter` para fingerprint, codificação e validação canônica/tipada. O UseCase valida por essa capacidade antes de acessar o Repository; os Repositories também validam antes de seu acesso direto. O codec devolve `ExpenseCursorOutput` com posição por campos públicos e direção; somente Infrastructure traduz description para o alias SQL. Não há Request, paginator Laravel ou serialização HTTP na Application. O payload novo é Base64 URL-safe de JSON com versão 1, fingerprint, posição e direção; tamanho máximo 4096, campos/tipos exatos e representação canônica. Fingerprint não é assinatura/autorização: o PostgreSQL continua restrito ao proprietário autenticado. Cache e cursor compartilham a mesma identidade de consulta, sem ordenar prioridades de sort.

Preservar a aceitação de cursores legados com `occurred_on`, `id` e direção de navegação para consultas do contrato anterior (sem novos filtros/ordenações, inclusive ano/mês/dia). Eles não comprovam vínculo ao período original; continuam obrigatoriamente restritos ao proprietário/período da requisição. Cursores legados são rejeitados para novas combinações. Novos cursores incompatíveis são `422`, inclusive quando as colunas de sort coincidem mas seus sentidos ou os filtros mudam. Mudar os critérios exige reiniciar sem cursor.

Índices não serão multiplicados para toda permutação. Preservar o índice atual, medir planos das consultas-alvo e adicionar índices somente com evidência. Toda ordenação e seleção de página ocorre no PostgreSQL, sem ordenar/carregar toda a coleção em PHP.

### 4. Cache normalizado e links

Versionar a chave de páginas para o contrato novo de consultas e cursores. Chave distingue proprietário, limites, conjunto de categorias deduplicado/ordenado, valores, lista de sort com prioridade preservada, tamanho e cursor. Não persistir Request, resposta HTTP ou links no cache; TTL de 60 segundos e política afterCommit permanecem. Criação, edição, exclusão e classificação confirmadas invalidam todas as variantes da conta. Ordenar categorias não autoriza ordenar a lista de sort.

Controller gera `next`/`prev` com todos os filtros e sort aceitos, tamanho e cursor; ausência de página continua nula e `data` permanece JSON:API. Normalização dos links não muda o significado da consulta.

### 5. Descrição nullable preservada

A decisão atual do usuário é manter o contrato existente: descrição opcional de até 64 caracteres, null permitido na criação e edição, sem novas invariantes, constraints, limpeza ou alterações em consumidores/fixtures/seeders. A antiga proposta de obrigatoriedade e cleanup foi cancelada, e sua implementação revertida. Não há Repository, Port, UseCase, comando ou ledger de invalidação de cleanup nesta mudança. A ordenação por descrição lida com null somente na projeção interna da consulta, sem alterar o valor persistido.

## Risks / Trade-offs

- [Múltiplas ordenações ampliam custo e formato do cursor] → Allowlist de campos, validação tipada e testes de empates/retorno; medir planos antes de expandir índices.
- [Composição manual omite critério ou trata zero como ausente] → Entrada tipada, testes por `!== null`, allowlist explícita de ordenação e cenários isolados/combinados de filtros, incluindo zero.
- [Descrição nullable e cursor] → Projetar COALESCE somente na chave interna, mantendo null na Entity/Response, e provar paginação entre descrições nulas e textos sem omissões.
- [Collation ICU e cursor por expressão] → Criar collation explícita por migration e selecionar expressão parentesizada com alias; provar os mesmos comparadores na ida/volta. Atualizações de ICU podem alterar regras: rever provas, índices dependentes e versão de cursor/cache se a semântica mudar.

## Migration Plan

1. Etapa 1 autorizada em 2026-10-11: conferir baseline/diff, registrar a decisão alfabética e confirmar APIs do Query Builder na versão Laravel instalada, sem adicionar dependências.
2. Implementar entrada, query, validação, cursor e cache versionado, atualizando apenas consumidores e testes afetados pelas consultas.
3. Provar ordenação/cursor e criação da collation em PostgreSQL de teste pelo launcher; descrição conserva sua nulabilidade.
4. Aplicar migration de collation local apenas na etapa 7, antes dos fluxos dependentes dela. Em 2026-10-11 o usuário confirmou explicitamente manter essa aplicação adiada. Nenhuma limpeza de dados ou constraint de descrição faz parte deste plano.

## Open Questions

Nenhuma decisão bloqueante de contrato permanece na etapa 1. A política alfabética foi respondida pelo usuário e registrada na decisão 3 e nos cenários de expense-querying. Criação da collation, código e provas executáveis continuam pendentes nas tarefas de implementação.

## Evidence Plan

| Contrato | Evidência planejada |
| --- | --- |
| Propagação de proprietário e critérios | Application Unit com mocks PHPUnit |
| Datas/categorias/valores combinados e zero | Feature PostgreSQL/HTTP com entradas e limites explícitos |
| Ordenações, empates e cursores compatíveis/legados | Feature PostgreSQL/HTTP, ida/volta e casos negativos |
| Cache por critérios e invalidação | Feature de cache + Redis real isolado |
| Fronteiras e regressão do contrato anterior | Arquitetura e suítes afetadas pelo launcher |

Na etapa 1, a evidência é a decisão explícita do usuário, inspeção dos diffs/código instalado, documentação versionada, consulta read-only de capacidade ICU e validação OpenSpec. Testes da aplicação e provas do novo comportamento permanecem pendentes; fechamento do contrato não torna a mudança pronta para archive.

## Evidência da implementação ativa — 2026-10-11

Esta seção registra a implementação de consultas após o cancelamento da descrição obrigatória. Não reaproveita aprovação do código revertido. Os comandos de teste usam o launcher guardado (`lerd composer test -- ...`); cada Feature provisionou somente bancos exclusivos de teste e aplicou incrementalmente a migration de collation neles. O banco operacional permanece sem essa migration, por decisão do usuário.

### Rastreabilidade de requisitos e cenários

| Requisito/cenários | Evidência executável | Estado |
| --- | --- | --- |
| Entrada imutável, proprietário e propagação de todos os critérios; cursor recusado antes do Repository | `tests/Unit/Expense/Application/UseCases/GetAllExpenseUseCaseTest.php` (3 testes) e arquitetura | Proven |
| Sem filtros, ano/mês/dia, bissextos, extremos civis, período vazio, ocorrência vs cadastro, page[size]=6/padrão 20 | `tests/Feature/Expense/Presentation/Http/GetAllExpenseHttpTest.php` (35) | Proven |
| Categorias OU, critérios E, limites independentes/inclusivos, zero, valor máximo e casos negativos de transporte | `tests/Feature/Expense/Presentation/Http/ExpenseQueryHttpTest.php` (53) | Proven |
| Ordenações simples/compostas nas duas direções, prioridade, acentos/cedilha/maiúsculas, Unicode canônico, nullable, desempate ID e ida/volta | `tests/Feature/Expense/Presentation/Http/ExpenseSortCursorHttpTest.php` (49, incluindo cursor) | Proven |
| Fingerprint incompatível, critérios equivalentes, mudança de tamanho, proprietário, cursores legados e campos/tipos arbitrários | Mesmo HTTP de cursor; `tests/Unit/Expense/Infrastructure/Adapters/ExpenseQueryCursorAdapterTest.php` (13) | Proven |
| Links mantêm filtros/sort/tamanho e campos internos não vazam na resposta | HTTP de listagem e sort/cursor | Proven |
| Identidade canônica, isolamento de todas as dimensões, namespace antigo e TTL | `tests/Feature/Expense/Infrastructure/Repositories/Cache/ComposableExpenseCacheTest.php` (11); `CachedExpenseRepositoryTest.php` (18) | Proven |
| CRUD/classificação invalidam variantes somente após commit; rollback e outra conta preservados; Redis real isolado | Mesmo cache composable, com Redis real e transações PostgreSQL; `CachedExpenseCategorizationRepositoryTest.php` (4) | Proven |
| Query Builder nativo, uma consulta limitada por página, collation ICU explícita, description ainda nullable, índices atuais preservados | `tests/Feature/Expense/Infrastructure/Repositories/Persistence/ExpenseQueryPersistenceTest.php` (2) | Proven |
| Fronteiras de contexto/camada, Data constructor-only e independência da Application | `tests/Unit/Architecture/ContextBoundariesTest.php` (26) | Proven |
| Migration/diagnóstico HTTP no banco local | Adiados explicitamente para tarefas 7.1–7.2 | Pending operacional |

Arquivos afetados foram executados isoladamente com `--compact`. Depois passaram `tests/Unit/Expense` (64 testes, 223 assertions) e `tests/Feature/Expense` (265 testes, 1905 assertions). Arquivos do baseline preservam seus objetivos: os cenários civis/cache existentes foram adaptados para GetAllExpenseInput; testes de descrição nullable/classificação não foram substituídos. Suggestions/Bruno e Metrics/Bruno preexistentes foram preservados. README, ARCHITECTURE e a request Bruno de listagem foram atualizados para o novo contrato.

### Gate completo e condições de execução

| Comando após `lerd composer test --` | Resultado | Duração Pest |
| --- | --- | --- |
| `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 1090/1090, 7033 assertions | 32.528 s |
| `--order-by=random --random-order-seed=20261011 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 1090/1090, 7033 assertions | 37.820 s |
| `--order-by=random --random-order-seed=20261012 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 1090/1090, 7033 assertions | 37.767 s |
| `--parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 1090/1090, 7033 assertions | 22.649 s |

As duas seeds da tabela foram lançadas simultaneamente pelo terminal e usaram bancos distintos `trocado_testing_7a67a32bd2f0b3fc27c043cb` e `trocado_testing_32e8172386763483e1171cc7`, removidos pelo lifecycle do launcher; o paralelo usou run `51b7b45a6489b01a55a8a98c` e dois processos. Redis e concorrência existentes participaram do gate; não houve skips/incomplete/risky inesperados.

Limitações históricas registradas: duas chamadas ampliadas via MCP atingiram timeout; foram repetidas pelo terminal com limite maior. Com a captura de dumps do Lerd ligada, seed 20261012 falhou em `StateRestorationTest.php:27` (listener preexistente), também reproduzido sozinho pelo filtro `starts with clean`. Desligar temporariamente a captura fez o mesmo teste passar. As duas seeds simultâneas e o último paralelo acima foram executados com essa captura desligada; depois seu estado original enabled=true foi restaurado. Nenhum teste de isolamento foi enfraquecido nem código de produção alterado para contornar esse comportamento de instrumentação. O gate padrão e um paralelo anterior também passaram com a captura ligada, mas não substituem essa ressalva de ordem/instrumentação.

Pint `--dirty --format agent` passou após as últimas mudanças PHP. Também foi executado explicitamente sobre os caminhos PHP afetados e arquivos novos não rastreados, com `--format agent`, seguido das verificações afetadas e gate completo. Nenhum commit ou archive foi feito.

### Consultas e planos PostgreSQL

`ExpenseQueryPersistenceTest.php` usou 2400 despesas (1200 por conta), ANALYZE e EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) sobre o SQL/bindings realmente emitidos pelo Repository. Cada leitura executou um statement, sem OFFSET, Limit de 21 registros para página de 20 e filtro de proprietário. Na execução isolada final: padrão Index Scan, 0.044 ms de execução; filtros combinados Index Scan, 0.047 ms; alfabética Sort, 0.298 ms. Esses valores descrevem somente esse dataset de teste e não são promessa de latência de produção.

Os índices owner/occurred_on/id existentes foram preservados. As medições não justificam multiplicar índices por permutação de filtros/sorts nesta POC. O diagnóstico HTTP local com captura real fica para 7.2, depois de aplicar a collation em 7.1; não foi declarado concluído a partir dos testes ou planos.

### Aplicação local posterior autorizada

Em 2026-10-11, após informar que já havia validado os fluxos, o usuário autorizou aplicar as migrations. `lerd artisan migrate --no-interaction` aplicou somente a migration pendente `2026_10_11_204139_create_expense_description_sort_collation` (15.20 ms, batch 3). `migrate:status` confirmou ausência de pendências. Consultas read-only verificaram provider ICU, locale und-u-ks-level1 e deterministic=false; description permaneceu nullable e a contagem de despesas permaneceu 88 antes/depois. Assim, a antiga pendência de aplicação local descrita nas seções históricas está resolvida. A validação manual foi relatada pelo usuário; não foi registrada captura/revisão HTTP de queries e tempos para considerar 7.2 comprovada.

### Fechamento operacional para arquivamento

Após autorização explícita de arquivar/commitar/push, foi revisada a captura FPM real do `GET /api/expenses` combinado usado no Bruno: from=2026-09-01, to=2026-09-30, category=food,transport, amount_min=1000, amount_max=30000, sort=-occurred_on,amount e page[size]=6. O SQL observado contém user_id, limites inclusivos, category IN, occurred_on DESC/amount ASC/id DESC e LIMIT 7; houve uma leitura de despesas em 2.53 ms. As cinco queries capturadas para esse request incluem também autenticação e extensão da sessão, sem leitura de despesas por item. Nenhum binding de credencial ou dado sensível foi incluído nesta evidência.

`route_timing` e `optimize_route` mostraram duas amostras locais, mediana 236.5 ms e nenhuma rota lenta. A análise agregada de queries continha também tráfego CLI/preflight de testes e não foi tomada como prova de N+1 HTTP. Essa janela pequena não prova latência de produção nem cada permutação de filtros/sorts; a validação manual informada pelo usuário e os testes automatizados de filtros/ordenações/cursor/nullable sustentam os cenários funcionais. A pendência 7.2 está concluída com essas fontes identificadas e limitações registradas.
