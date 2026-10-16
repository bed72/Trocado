## Context

Autorização da primeira entrega: “vamos fazer esses ajustes”. Evidências anteriores em `investigate-read-endpoint-performance/design.md`. VPS informada: 2 vCPUs, 8 GB RAM, NVMe 100 GB; ambiente de medição local é diferente e compartilhado. A primeira implementação ficou nos dois Repositories. Pedido posterior autorizou investigar profundamente os candidatos adicionais e planejar steps nesta spec; o incremento atual é documental/diagnóstico, sem implementar esses próximos steps. Preservar edições preexistentes.

## Goals / Non-Goals

**Goals:** reduzir CPU/ordenação/temporários por leitura, provar resultados equivalentes com PostgreSQL/massa dedicada e priorizar próximas intervenções usando evidência por workload e runtime.

**Non-Goals do incremento atual:** deploy/tuning, DDL/extensões, alteração de cache/sessão/produto, nova carga sustentada, testes da aplicação ou mudanças Domain/Application/HTTP. Os steps prospectivos descrevem os experimentos e possíveis alterações de índice/runtime, mas não constituem execução ou aprovação antecipada dessas intervenções. SLA/capacidade continuam fora das conclusões locais.

## Decisions

1. **Insights:** pré-agregar fatos por data/categoria antes de expandir para os períodos. Contar datas distintas e somar contagens/somas sobre essa projeção compacta; preservar numeric/string exata. Consultar maior lançamento via LATERAL top-1 por período no mesmo statement/snapshot, com os desempates existentes. Assim descrições não atravessam materialização/ordenação global de dezenas de milhares de linhas. Alternativa rejeitada: aumentar memória ou indexar sem reduzir o trabalho observado.
2. **Sugestões:** materializar descrições normalizadas uma vez, agrupar/rankear todo o histórico e escolher cinco chaves antes de selecionar grafia e agregar valores dessas chaves. Seleção detalhada permanece em SQL num único statement, com ownership antes de normalização, sem query PHP por sugestão. Não limitar lançamentos antes do ranking histórico. Alternativa rejeitada: cortar histórico pela janela financeira ou mudar normalização para um trim não equivalente.
   - Antes de materializar, filtrar substring sobre texto original em caixa uniforme com o termo já sem whitespace externo: uma correspondência de termo assim normalizado não depende do whitespace externo removido da descrição. Prefixo/ranking/grafia continuam calculados sobre descrição normalizada. Isso evita materializar todo o histórico em buscas seletivas/sem matches. A primeira tentativa que materializava todas as descrições teve regressão medida e foi substituída.
3. **Verificação:** executar arquivos existentes dos dois Repositories isoladamente e suítes dos contextos pelo launcher, incluindo cenários de datas, empates, valores grandes e IDs. Comparar original/novo no mesmo banco dedicado, mesma referência, SELECT read-only com timeout 5s e saídas privadas comparadas em memória; registrar mediana/faixa por query sem fabricar percentis de carga. Medir HTTP após aplicar somente os dois arquivos ao clone, identificando essa revisão como base + patch. Não substituir .env/massa/vendor nem executar migrations sem pendências relacionadas.
4. **Instrumentação:** manter estados preexistentes. Comparações instrumentadas são equivalentes quanto ao estado declarado; sem desligar diagnóstico global de outro usuário. Até 30 sondas HTTP autenticadas, timeout 10s/connect 3s, sem bursts/k6 e sem limpar cotas. Encerrar em erro/timeout; `/up` final. Resultados locais não garantem a mesma latência na VPS.

## Risks / Trade-offs

- [Pré-agregação perde máximo/desempate] → máximo selecionado na fonte original com `amount DESC, category ASC, id ASC`.
- [Somar contagens distintas por categoria duplica datas] → COUNT DISTINCT da data na projeção diária de cada período.
- [Top cinco antecipa limite indevido] → ranking usa todos os grupos, frequência/recência históricas; grafia e valores usam todos os lançamentos das chaves escolhidas.
- [CTEs/planos mudam com cardinalidade] → comparar planos e tempos, não assumir melhoria só pela reescrita. Rollback da implementação se piorar.
- [Snapshot/ownership] → uma leitura financeira por Repository e filtros por proprietário antes de agregação.

## Migration Plan

Primeira entrega sem migration; rollback pelos dois arquivos. Clone de carga recebeu cópia exata desses arquivos após testes, com revisão/patch registrados. Para steps prospectivos com DDL: definir migration incremental, privilégios/extensões, estratégia operacional de criação/rollback e impacto em escrita antes de aplicar. Nenhuma migration/alteração operacional é criada neste incremento. A VPS não foi acessada/reconfigurada.

## Open Questions

Primeira entrega sem bloqueantes remanescentes. Para novos steps: inventário da instância realmente publicada na VPS e disponibilidade de staging equivalente são bloqueantes da prova de runtime; escolha de índice/extensão e política de last_used_at dependem dos gates abaixo. Não bloqueiam a elaboração documental. Capacidade sustentada permanece posterior a uma carga sem contaminação de limiter/gerador.

## Resultado e rastreabilidade — 2026-10-16

Implementação entregue somente nos dois Repositories. Evidência detalhada de comandos, versões, rodadas intermediárias/final, falha de teste corrigida sem mudar assertions, hashes do clone e limitações em `tasks.md`.

| Requisito/cenário | Evidência | Estado |
| --- | --- | --- |
| EFF-01 períodos/categorias/data/máximo | Repository Insights: 22 testes/368 assertions; suíte Feature Insights 176/1960; comparação completa original/novo com 60 mil despesas | Proven nos cenários executados |
| EFF-01 vazio/valores grandes | Testes existentes de história vazia/futura, somas acima de PHP_INT_MAX, desempates e meses encerrados, sem alterações de esperados | Proven |
| EFF-02 mais de cinco grupos/grafia/valores | Repository sugestões 27/94; suíte Feature Expense final 381/2876, incluindo ranking, ownership, empates, representação e IDs estáveis | Proven |
| EFF-02 antigo/literal | Cenários existentes de histórico antigo, caracteres especiais, whitespace, acentos e valores divergentes; equivalência completa na massa para buscas ampla, seletiva e vazia | Proven |
| EFF-03 comparação | Três repetições intercaladas por query/versão, SELECT read-only/timeout 5s, planos e capturas HTTP finais confirmados | Proven local/instrumentado |

### Ganhos finais observados

- **Insights SQL:** mediana 157,44 → 13,53 ms (~91,4% menos); projeção por período 44.380 → 972 linhas, sem temporários no plano novo. HTTP mediano 237,68 → 83,62 ms (~64,8% menos).
- **Sugestões SQL:** busca ampla 175,72 → 125,75 ms (~28,4% menos); seletiva 60,55 → 31,71 ms (~47,6% menos); vazia 35,79 → 11,66 ms (~67,4% menos). Detalhe dos cinco grupos limitado a 340 linhas na massa ampla, preservando ranking histórico global. Normalização/materialização ampla continua com temporários (603/603 blocos): não é custo constante nem busca indexada.
- **Sugestões HTTP:** mediana 248,64 → 199,00 ms (~20% menos). Não usar o tempo mais favorável dos protótipos como resultado entregue.

A primeira tentativa de sugestões regrediu em buscas vazias; foi corrigida com filtro antes da materialização e revalidada. O pool de cinco workers não foi alterado. Menor custo por request deve reduzir ocupação, mas multiplicador de vazão/usuários e dimensionamento na VPS de 2 vCPUs/8 GB permanecem **Unproven**, pois não houve carga sustentada ou medição nessa máquina. Alguns testes/diagnósticos locais executaram enquanto outros processos da VM estavam ativos; não houve isolamento físico do host. Sem deploy, índices, cache, migração ou promessa de SLA.

## Investigação ampliada — 2026-10-16, 19:04–19:10 UTC

### Protocolo, alvo e fontes

Pedido: “Pode fazer uma investigacao pesada nesses pontos que acabou de encontrar e incrementar nessa spec, como steps de melhorias”. Foram usados Lerd `site list`, `diag status/route_timing/optimize_route/dumps_recent`, `worker list`, Artisan/Tinker, planos PostgreSQL e perfis SPX existentes. Sem testes funcionais ou implementação adicional. As ferramentas de captura também retornaram histórico: foram filtrados ctx FPM, timestamp, host/URI e rid; registros antigos não foram tratados como prova nova.

Alvo reconfirmado: `load-testing`, PostgreSQL dedicado exato, uma conta/PAT válido, 60.000 despesas, 900 descrições normalizadas, data 2026-10-16/UTC. Base Git mais os dois arquivos otimizados, como na entrega anterior. PostgreSQL local **16.10**, cache/limiter Redis com prefixo dedicado. `pg_trgm` disponível no servidor, mas **não instalado** no banco. Não instalado durante a investigação.

Contagem operacional: **60 chamadas de medição** (42 páginas por persistência, nove sugestões, seis Metrics, três cache), **19 EXPLAIN SELECTs**, uma sonda autenticada inicial + seis sondas autenticadas de listagem. As seis tiveram pausa de 1,05s fora da janela cronometrada para observar tracking em segundos distintos; não são carga concorrente nem regime estacionário. SELECTs/EXPLAIN em transação read-only, timeout 5s, sem publicar bindings/linhas financeiras/cursores. As chamadas pelo cache somente preencheram uma chave legítima do owner dedicado, TTL normal de 60s, sem flush/expiração forçada. Instrumentação global preexistente preservada.

### A1 — Sugestões: custo residual confirmado, índice ainda é hipótese

| Busca | Query ms, três execuções | Mediana ms | Linhas correspondentes | Grupos históricos | Temporários read/write |
| --- | --- | ---: | ---: | ---: | --- |
| Ampla `teste` | 129,59 / 123,22 / 123,97 | 123,97 | 60.000 | 900 | 603 / 603 |
| Seletiva `1` | 31,35 / 32,03 / 31,55 | 31,55 | 16.800 | 252 | 0 / 0 |
| Sem matches | 12,42 / 12,20 / 12,19 | 12,20 | 0 | 0 | 0 / 0 |

Todos os planos começam por scan de 60 mil rows do owner; o filtro elimina respectivamente 0/43.200/60.000. O limite final segue cinco e o detalhe das buscas com resultados segue 340 rows. EXPLAIN instrumentado: 220,631 / 64,588 / 11,533 ms; não intercambiar com a tabela de queries normais. A regressão de materializar buscas vazias continua resolvida.

**Mecanismo confirmado:** custo proporcional ao histórico para filtrar; em termos amplos também normalizar/materializar/agrupar muitos registros. **Não confirmado:** ganho de um novo índice/coluna. Não foi criado índice hipotético ou real.

Índices atuais de expenses: PK, `(user_id, occurred_on)`, `(user_id, occurred_on, id)` e unicidade de classification_token. Não há índice da expressão textual buscada. A [documentação PostgreSQL 16 de pg_trgm](https://www.postgresql.org/docs/16/pgtrgm.html#PGTRGM-INDEX) informa suporte a LIKE/ILIKE/regex/equality, **não ao predicado `strpos(...) > 0` atual**. Criar GIN sem adaptar a expressão/predicado não demonstra benefício. Um experimento futuro deve comparar expressão/coluna normalizada e um predicado indexável equivalente, com escaping explícito de `%`, `_` e barra invertida, sem fuzzy search ou remoção de acentos. Termos de um/dois caracteres ou sem trigramas extraíveis podem degenerar para full-index scan; termo que casa com todo o histórico também pode continuar favorecendo seq scan.

**Gate:** medir termos amplos, seletivos de pelo menos três caracteres, curtos, vazios de resultado e caracteres especiais; a massa atual só confirmou seletividade para um caractere, não prova benefício de trigramas. Medir custo de escrita/tamanho do índice antes de escolhê-lo. Uma coluna gerada/expressão indexada é candidata; tabela de resumos financeiros/históricos não foi aprovada e alteraria muito mais a consistência.

### A2 — Listagem: padrão eficiente, alternativas escaneiam histórico

Foram invocados diretamente `EloquentExpenseRepository::getAll` e o cursor real, sem o decorator de cache. Sete combinações, páginas 1/2, três execuções por página; next cursor real da página anterior, nunca fabricado/impresso. Size 20. A página 2 não representa página profunda; esse caso permanece pendente.

| Critério | Mediana p1/p2 ms | Plano / trabalho observado |
| --- | --- | --- |
| Default data DESC/id DESC | 0,23 / 0,24 | Index Scan `expenses_owner_cursor_index`, 21 rows; p2 elimina 20 pelo filtro |
| Valor ASC/id DESC | 5,94 / 6,20 | Seq Scan 60.000/59.980 rows + top-N em memória |
| Valor DESC/id DESC | 6,33 / 6,41 | Seq Scan 60.000/59.980 + top-N |
| Descrição ASC/id DESC | 10,42 / 13,78 | Seq Scan 60.000/59.980 + top-N com collation ICU |
| Descrição DESC/id DESC | 10,10 / 12,88 | Seq Scan 60.000/59.980 + top-N com collation ICU |
| Data DESC/valor ASC/id DESC | 0,35 / 0,38 | Index Scan + incremental sort, 626/606 rows |
| Período/categorias/faixa de valor + valor ASC | 0,83 / 0,82 | Bitmap no índice owner/data: 10.000 rows candidatas, 471/451 aceitas |

Nenhum plano de listagem usou temporários. EXPLAIN dos sorts por valor ~30–32 ms, por descrição ~36–41 ms, com instrumentação; não são latências de query normais. **O default não precisa ser “consertado” com mais índices/cache.** Há oportunidade condicional nos sorts alternativos, proporcional à frequência de uso e crescimento da conta.

Índice candidato precisa reproduzir expressão `COALESCE(description, '') COLLATE "expense_description_ci_ai"`, direções e UUID DESC. Reverter um índice `(owner, amount ASC, id DESC)` também reverte a direção de id; não presumir que uma definição resolve os dois sentidos mantendo desempate. Não criar todas as permutações dos três campos. Medir uso real e escolher a menor cobertura útil. Os dois índices owner/data têm prefixo compartilhado, mas um apareceu no incremental sort: não remover o menor por aparência de redundância sem comparar planos e custo de escrita.

**Gate:** workload de páginas frias, quentes e profundas com repetições/owner seletivo. Avaliar índices com testes de cursor v2, direção reversa, empates/Unicode/null, sem trocar ordenação ICU pela chave binária de sugestões.

### A3 — Cache: hit funciona; stampede é risco estrutural sem corrida demonstrada

Provider efetivo injeta `CachedExpenseRepository`. Size 19/descrição foi uma chave ainda ausente no cache dedicado, verificada antes da chamada:

| Leitura | Estado anterior | Tempo do Repository | SELECTs financeiros |
| --- | --- | ---: | ---: |
| 1 | Miss | 29,07 ms | 1, SQL 18,10 ms |
| 2 | Hit | 0,51 ms | 0 |
| 3 | Hit | 0,46 ms | 0 |

O SQL cold de 18,10 ms é uma chamada/condição diferente dos ensaios de persistência e não foi usado para “melhorar” a mediana anterior. Esses dados confirmam benefício do cache, não uma corrida. No código instalado, `Illuminate\Cache\Repository::rememberWithWarmth()` faz get → callback → put, sem single-flight. O projeto usa TTL 60s, chaves por owner/critérios/cursor e invalidação de tag após commit de CRUD/classificação. A política aceita staleness limitada; não reinterpretar como cache transacional forte.

**Gate:** reproduzir dois misses simultâneos e contar consultas duplicadas em fixtures/keys exclusivas; não esvaziar cache operacional. O default custa ~0,23 ms de SQL: um lock Redis pode custar mais do que a recomputação evitada. Coordenar apenas onde houver benefício, com lock por página/namespace, espera/TTL limitados e double-check após adquirir; tratar invalidação concorrente sem ampliar staleness. Não serializar todas as páginas/owners nem mudar TTL/jitter silenciosamente. Adicionar lock para todo miss **não é recomendação aprovada**.

### A4 — Identity: dois pontos de serialização; nenhum gargalo concorrente provado

`SessionAdapter.php:29–53` relê PAT com lock antes da avaliação de política. O token dedicado está válido e fora da janela de renovação (>15 dias), mas os seis requests atuais ainda executaram esse SELECT FOR UPDATE. Não houve escrita de expires_at nesses requests.

Sanctum **4.3.3** tem `config('sanctum.last_used_at', true)` em `SanctumServiceProvider.php:108–113`. O projeto não configura a opção; o Guard tenta salvar last_used_at após autenticar. Em Eloquent, tentativa de save não significa UPDATE em toda chamada: timestamp não dirty no mesmo segundo pode eliminar a escrita. As sondas espaçadas em segundos distintos capturaram UPDATE em seis/seis, sem converter isso em regra para qualquer cadência.

Rids da janela 19:07:03–19:07:09 UTC: `750bfbf30e3ee7bcfb869644`, `282f03d927129743edc314ce`, `94c14f5e1db2cafa8e1b172c`, `163a6bd9e6af1cbb0406f3e7`, `fb298658669d2c7bd10eca43`, `8af640aad35f891f40a0ec7d`. Capturadas 4–5 queries por request; primeira consulta financeira somente no primeiro default, demais hits sem consulta de despesas.

- SELECT de extensão com lock: **0,28–0,32 ms**.
- UPDATE last_used_at: **0,91–1,12 ms**.
- Método de extensão inteiro no SPX: **1,40–1,91 ms**, incluindo transação/queries, não apenas lock.
- Lookup inicial de PAT: **6,76–7,88 ms**, mas perfil do mesmo request mostra criação da conexão PDO **5,00–5,70 ms**. Não atribuir todo esse primeiro SELECT à busca por token ou criar outro índice: PK/hash já têm índices.

O caminho tem trabalho evitável potencialmente, mas os números sequenciais não sustentam “Identity domina a latência”. Contenção com mesmo token/conta e comparação com tokens distintos continuam Unproven: existe apenas um PAT no alvo, nenhum novo foi criado e não houve campanha concorrente. Locks também protegem atualização legítima; não removê-los por leitura de código.

**Gate:** aprovar política de last_used_at após inventariar consumidores/auditoria; usar opção oficial quando a decisão for desligar tracking, sem vendor patch ou throttle próprio antecipado. Para extensão, avaliar fast path ou leitura inicial sem lock com rechecagem bloqueante quando houver elegibilidade. Uma instância Eloquent antiga não é prova de persistência atual: definir/tratar o caso de expires_at encurtado/alterado depois da autenticação, além de extensão/revogação/expiração concorrentes. Preservar 30 dias, fronteira inclusiva de 15, máximo 90, token/issued_at imutáveis, respostas rejeitadas sem extensão e Notifications independente da otimização da extensão. Reutilizar e ampliar pontualmente `SlidingSanctumSessionTest` e sua corrida sincronizada, somente no apply do step.

### A5 — Runtime: diferença de SAPI muda o plano operacional

**Local efetivo:** `php-fpm -i` confirmou FPM/FastCGI, OPcache On/128 MB, validate_timestamps On/revalidate_freq 2, memory_limit 128M, Xdebug sem modo, SPX HTTP On e bridge em auto_prepend. Pool dynamic/max_children 5 como inventariado anteriormente. Config/routes/events **não cacheados** no clone, debug false/Nightwatch false. O clone mantém dependências dev; perfis incluem autoload do plugin Laravel de Pest.

**Arquivos de entrega:** `Dockerfile:11` usa `php:8.5-apache-bookworm`, instala dependências com `--no-dev --optimize-autoloader`; `deploy/php.ini` só contém expose_php Off; configurações Apache tratam vhost/headers/logs, sem dimensionamento MPM explícito nesses arquivos. Dockerfile não chama optimize; o workflow versionado atual é somente CI. Configuração/hook externo do Dokploy e imagem realmente publicada não foram consultados. Portanto:

- Não se sabe se a VPS está servindo exatamente essa imagem; inventariar SAPI/MPM/módulos/ini efetivos primeiro.
- Não transportar `pm.max_children=5` para Apache; medir MaxRequestWorkers/MPM se Apache, pool se FPM. Não propor migração de servidor como pré-requisito.
- Não afirmar que OPcache da VPS está desligado pela ausência de uma linha no Dockerfile (PHP 8.5/base podem fornecê-lo). Verificar extensão/status efetivos e configuração.
- Caches de config/routes/events devem ser gerados após injeção do ambiente real, sem congelar segredos/defaults incorretos no build. Registrar comandos/hooks existentes antes de adicionar outros.

Os seis perfis HTTP existentes, com pilha validada sem frames abertos/incompatíveis, mostram wall interno **34,97–92,10 ms**; autoload exclusivo **0,54–43,06 ms**, bridge send **3,53–4,25 ms** e PDO acima. Capturas SPX: `190703` PID74/2081920043, `190704` PID73/338129607, `190705` PID72/951549576, `190706` PID74/1816857566, `190708` PID73/1414602132, `190709` PID72/1867281562. São wall/memória, não CPU separada; autoload elevado não prova OPcache miss ou saturação. HTTP cliente: default **150,72/122,10/119,13 ms**, descrição **158,73/114,49/161,92 ms**. Não subtrair esses agregados do SPX para fabricar fila/rede.

A VM local enxerga 5 CPUs/~3,02 GB compartilhados, não os 2/8 da VPS. Stats instantâneos de containers e workers do main ativos comprovam compartilhamento, não consumo de pico sob carga. Falta RSS/PSS por worker, CPU sustentada, swap/IO, fila de execução, conexões e orçamento de PostgreSQL/Redis/queue. Pool/MaxRequestWorkers não pode ser calculado dividindo 8 GB por memory_limit: este não é RSS medido nem memória exclusiva do PHP.

**Gate:** referência production-like coordenada sem dependências dev/instrumentação pesada, mesma revisão/massa/queries; staging equivalente se disponível. Sem expor phpinfo/status público, cache clear global, dependência nova ou carga de produção por inferência. Diagnóstico de conexão PDO é candidato posterior, não autorização para persistência de conexões/novo pooler.

### A6 — Contextos de controle e prioridades

Metrics na massa atual, mês de 10 mil despesas: total **1,02/0,73/0,72 ms**, agrupado **1,68/1,30/1,36 ms**, 18 categorias, bitmap owner/data e sem temporários; EXPLAIN 4,407/5,210 ms. Não há evidência para refatorar essa SQL agora. Core mantém resolução em lote/índice composto e hits baratos nas capturas anteriores. Notifications tem índices de instalação/fingerprint e locks com finalidade de integridade; não houve tráfego de cadastro/perfil novo para concluir desempenho. Esses contextos ficam em observação, não recebem refactors preventivos.

| Ordem | Step futuro | Motivo | Estado da prova / decisão |
| --- | --- | --- | --- |
| 4 | Referência e runtime reais | Evitar otimizar para FPM local um deploy Apache/devtools diferentes | Divergência comprovada nos arquivos; VPS efetiva Blocked sem inventário/acesso |
| 5 | Sugestões indexáveis/normalização | Maior custo SQL residual confirmado | Custo Proven; índice/DDL e ganho Unproven, experimento obrigatório |
| 6 | Sessão/tracking | Trabalho por rota e dois pontos de escrita/lock no mesmo PAT | Mecanismo Proven; ganho concorrente Unproven e política pendente |
| 7 | Índices seletivos da listagem | Valor/descrição examinam histórico a cada página fria | Planos Proven; frequência/benefício líquido e páginas profundas pendentes |
| 8 | Single-flight condicional | Evitar recomputações simultâneas onde custarem mais que coordenação | Ausência de coordenação Proven por código; stampede/benefício Unproven |
| 9 | Aceitação e dimensionamento | Comparar ganho útil sem erros/cotas e com recurso representativo | Somente após steps aprovados; sem SLA de VPS antecipado |

## Contratos e critérios dos próximos steps

- **Step 4:** inventário sanitizado da instância publicada e deploy hooks; baseline equivalente e estado de instrumentação coordenado. Critério: SAPI/config/revisão/recursos identificados, tempos comparáveis e plano de rollback antes de tuning. Se acesso/staging não existir, reportar Blocked sem substituir por localhost. Não exige operar a VPS neste pedido.
- **Step 5:** escolher uma estratégia mínima após experimentos isolados de SQL/expressão/índice. Critério: outputs/IDs/ranking idênticos para ampla/seletiva/curta/especial/vazia, benefício medido sem regressão relevante nas outras dimensões e impacto em escrita/tamanho explicitado. DDL somente depois da decisão, migration incremental/rollback e compatibilidade PG da entrega/CI; não definir “criar GIN” como tarefa incondicional.
- **Step 6:** separar decisão sobre tracking da otimização da extensão. Critério: mesmo contrato de autenticação/renovação e corridas reais PostgreSQL, redução de roundtrips/locks onde não há renovação, sem stale token autorizado ou perda da revalidação quando há escrita. Provar mesmo PAT versus sessões distintas sem confundir a cota por conta. Não trocar por cache de autenticação.
- **Step 7:** selecionar índices pelas consultas usadas, não por cada combinação permitida. Critério: plano/latência p1/próxima/profunda e ambos os sentidos, sem mudança de ordenação/seek/cursor, ownership ou custo de escrita ignorado. Aceitar explicitamente “não criar índice” quando ganho não justificar manutenção.
- **Step 8:** primeiro provar duplicação cara com chaves exclusivas/fixture; só implementar coordenação se superar o overhead Redis. Critério: hit não serializado, espera limitada/double-check, owners/páginas independentes, TTL 60s/invalidação após commit preservados e staleness não ampliada. Falhas/timeout do lock e corrida com invalidação devem ser cenários explícitos. Mudanças de TTL/stale-while-revalidate precisam de decisão distinta.
- **Step 9:** gate por alteração e workload representativo, status e vazão útil separados de 429, referência/instrumentação e gerador registrados. Segurança/contratos e testes não podem ser enfraquecidos para throughput. Tuning de Apache/FPM/DB/queue exige budget CPU/memória/conexões medido e rollback; não multiplicar usuários por um ganho isolado de SQL.

## STEP 4 — início de execução e bloqueio de acesso — 2026-10-16

Autorizado iniciar pela primeira etapa pendente. Inspeção estática na revisão local `05c4d4420f0a2828aca4884da0e48c1120d60a89`, preservando os artefatos previamente modificados. Esta revisão **não** identifica a imagem publicada. Não houve conexão à VPS, requisições HTTP, carga, build ou alteração operacional.

### Inventário verificável no repositório — parcial para 4.1

| Fonte | Fato observado | Limite da evidência |
| --- | --- | --- |
| `Dockerfile` | PHP 8.5/Apache Bookworm; pdo_pgsql/pcntl/Redis; Composer `--no-dev --optimize-autoloader`; assets Node 22 | Não comprova digest, módulos/MPM, extensão OPcache nem configuração efetiva da instância |
| `deploy/php.ini` e configurações Apache | `expose_php=Off`, headers/vhost/logs; sem tuning explícito de OPcache/MPM nesses arquivos | Defaults e overrides externos permanecem desconhecidos |
| `docker-compose.yml` | `migrate` precede web, duas filas, scheduler e agente Nightwatch; ambiente por `.env`; storage compartilhado; healthcheck web em `/up` | Não prova serviços ativos, recursos consumidos, limites externos ou sucesso das migrations |
| `Dockerfile` e Compose | Não há geração explícita de caches Laravel nesses dois arquivos | Hooks Dokploy e caches reais não inspecionados; não adicionar cache no build por inferência |
| `.github/workflows/ci.yml` e README | Workflow encontrado somente de CI; README descreve também Action manual de deploy que não foi encontrada nos workflows locais | Divergência documental registrada; não criar workflow nem inferir como o deploy atual ocorre |

A descoberta de recursos MCP retornou somente informações locais do Laravel Boost, sem recurso de inventário da VPS. Nenhum alvo remoto/acesso Dokploy/SSH foi fornecido nesta execução. Não procurar credenciais privadas nem presumir que integrações Hostinger de hospedagem web administram essa VPS.

### Baseline coordenada — protocolo proposto, captura bloqueada em 4.2

Antes da medição, identificar alvo dedicado/staging, revisão e digest realmente servidos, versão PostgreSQL, massa/cardinalidades e ambiente efetivo. Registrar hooks, caches, instrumentação e processos concorrentes por serviço. Coletar configuração da SAPI web, não usar `php --ini`/OPcache CLI como prova do Apache/FPM. Inventariar MPM/MaxRequestWorkers ou pool FPM conforme a SAPI efetiva; medir CPU, RSS/PSS por processo, swap/IO e conexões de banco durante a mesma janela.

Coordenar janela e orçamento de requests antes de executar: gerador separado e validado, endpoints representativos já suportados pelo runner existente, termos amplos/seletivos/vazios e páginas com critérios declarados. Separar primeira leitura, aquecimento e medições warm, mantendo revisão, massa, credenciais de teste e instrumentação equivalentes entre original/candidato. Cold de aplicação/cache não significa cache de disco do banco frio: não limpar cache global nem reiniciar serviços para simular esse estado. Registrar respostas úteis, 429, erros e latências individuais; obter percentis das amostras, nunca de médias de percentis. Sem carga na produção por inferência deste protocolo.

### Decisão operacional — 4.3 bloqueada pelas anteriores

Nenhuma configuração numérica ou mudança de bootstrap é aprovada sem o inventário/baseline. Se estes justificarem caches/OPcache, propor patch mínimo e sequência após injeção do ambiente real; somente então obter aprovação operacional. Antes de aplicar, registrar imagem/configuração anterior e procedimento de restauração. Smoke checks devem abranger `/up`, autenticação, leituras representativas, banco/Redis e saúde dos workers, sem publicar diagnósticos ou segredos. Uma configuração cacheada por serviço não deve ser presumida compartilhada com os outros containers.

| Requisito/cenário | Evidência desta execução | Estado |
| --- | --- | --- |
| EFF-08: Apache de entrega versus FPM local | Dockerfile/Compose/configurações inspecionados; nenhuma transferência de limites entre SAPIs | Parcial; runtime publicado Blocked |
| EFF-08: referência equivalente indisponível | Sem alvo/acesso remoto ou staging identificado; localhost não usado como substituto | Blocked; nenhuma conclusão de capacidade |
| EFF-03/08: comparação e recursos medidos | Protocolo acima, sem campanha executada | Blocked |

Menor desbloqueio: identificar a instância e disponibilizar acesso somente leitura autorizado ou inventário sanitizado coletado pelo operador, seguido da escolha de staging/janela e orçamento de medição. Manter 4.1–4.3 pendentes; não avançar para o STEP 5 nem declarar o STEP 4 concluído.

## STEP 5 — decisão de execução local independente

Após esclarecer que a etapa operacional não impede otimizações locais, o usuário autorizou continuar (“Só executa”) e informou que não pode disponibilizar conexão/Dokploy. STEP 4 permanece adiado/Blocked; este pedido autoriza o experimento/implementação local do STEP 5, não tuning ou carga na VPS.

Experimentos em transação no banco dedicado com cópia temporária das 60 mil despesas compararam `strpos`, LIKE literal com escape `!`, GIN da expressão lower/C e inlining com índice B-tree da chave normalizada. Todos os objetos experimentais/extensão foram revertidos por rollback. GIN acelerou termos ausentes, mas regrediu na ampla; inlining sem materialização piorou termos seletivos/ausentes. Não aplicar esses candidatos em produto.

Alternativa escolhida para implementação/verificação: agrupar primeiro descrições **brutas idênticas por collation C**, conservando contagem e maior created_at, normalizar cada grafia distinta e reconciliar os grupos normalizados antes do ranking/limite. Selecionar então todos os lançamentos das grafias pertencentes às cinco chaves finais para desempate por id e fatos monetários. A normalização/caixa continua na collation original da coluna, não na C usada exclusivamente para igualdade binária. `MIN(description)` conserva a collation original depois do agrupamento por igualdade C, sem escolher outra grafia, pois os membros desse grupo são idênticos. Uma CTE owned NOT MATERIALIZED permite as duas leituras internas no mesmo statement/snapshot com um único binding do proprietário. Não adicionar projeção persistida, cache, extensão ou migration.

Na primeira prova read-only, ampla ~123 → 23 ms, curta seletiva ~32 → 18 ms e ausente ~12 → 12 ms, saídas completas iguais e sem temporários. São amostras locais preliminares; verificar revisão final, variantes Unicode/especiais, termos seletivos de pelo menos três caracteres, IDs e HTTP antes de concluir. A dispensa de DDL evita armazenamento/manutenção de índice sem ganho líquido demonstrado; busca indexada não será declarada implementada.

### Estratégia final e trade-offs

A forma incondicional foi rejeitada após prova com 60 mil descrições únicas e busca muito seletiva. A forma final amostra **até 2048 descrições do owner**, sem ordenar ou transferir registros para PHP. Compacta somente se pelo menos **256** correspondem ao termo e o número de grafias brutas distintas entre as correspondências é no máximo metade delas. Esses números são orçamento/heurística de execução, não comprimento mínimo de busca ou limite de histórico. A amostra pode não representar o restante do histórico: isso pode afetar o ganho, nunca a correção, pois os dois caminhos sempre processam todo o histórico elegível no mesmo snapshot.

Dois substatements LATERAL mutuamente exclusivos preservam projeções estreitas próprias: o caminho direto conserva a normalização por lançamento da revisão anterior; o compacto normaliza grafias distintas. A condição de estratégia deve impedir a leitura financeira do caminho inativo (conferida por Actual Loops=0 em EXPLAIN). O ranking/fatos finais compartilham a mesma construção SQL, e a ordenação externa recompõe explicitamente a ordem após UNION ALL. Não carregar campos nullable de ambos os caminhos em uma CTE larga: esse protótipo regrediu e foi descartado.

Na revisão final, a busca ampla repetitiva caiu **124,641 → 30,010 ms**, mas buscas seletivas/ausentes/especiais pagaram aproximadamente **1–3 ms** pela seleção de estratégia. A cópia com 60 mil grafias únicas ficou **127,822 → 129,961 ms**, em vez dos ~265 ms do protótipo rejeitado. Esse custo é explícito: a entrega prioriza eliminar ~95 ms na ampla recorrente sem duplicar a latência da alta cardinalidade; não promete ganho em todo termo nem um limiar/SLA de produção. Se o workload real for predominantemente seletivo ou tiver amostra não representativa, reavaliar a escolha; rollback é restaurar somente o Repository anterior. Não há rollback de schema ou extensão.

Sem novos imports, contratos ou bindings; uma leitura financeira/statement e quatro bindings na ordem original. Testes preservam validação HTTP, ownership, ranking/frequência, grafia, valores e IDs. A assertion do prefixo SQL em StableSuggestionIdentityHttpTest muda para a CTE owned, conservando a exigência de um statement financeiro e os limites do registro. O cenário de estabilidade começa com 300 lançamentos repetidos (caminho compacto) e termina com um lançamento (direto), inclusive em processo filho, mantendo o mesmo ID lógico.

## STEP 6 — tracking conservado e renovação condicional

Autorização: “Próxima step”, limitada a 6.1–6.3. Inventário de `last_used_at`: nenhuma leitura/regra de negócio em app, configuração local sem override, campo nullable na migration e fixtures/schema tests. Sanctum 4.3.3 configura o Guard pela opção oficial `sanctum.last_used_at` (default true) e faz save durante autenticação, independentemente do middleware de extensão. Save no mesmo segundo pode não gerar UPDATE. Não é possível inferir ausência de consumidores externos/auditoria: **manter tracking habilitado**, explicitando true na configuração; não introduzir throttle, vendor patch, cache de autenticação ou flag pessoal para desabilitá-lo.

### Algoritmo e pontos de decisão

1. Resolver o PAT atual do guard somente para identificar o registro; não decidir elegibilidade pelas datas do Model autenticado.
2. Reler o PAT na conexão de escrita, sem lock. Avaliar a política pura com datas dessa leitura e relógio explícito. Ausência, datas inválidas, expiração/teto ou nenhuma extensão possível terminam sem transação de renovação.
3. Havendo possibilidade, abrir a transação existente, reler o PAT com FOR UPDATE e recalcular a política com estado/relógio atuais antes de salvar somente expires_at. Expiração, remoção ou extensão concorrente não podem ser sobrescritas; encurtamento válido antes desse lock é avaliado pelas datas bloqueadas.

A leitura fresca é o ponto de decisão para **não renovar**, não uma promessa de validade futura nem uma nova autorização. Mudança ainda não confirmada em outra transação pode ser invisível nessa leitura PostgreSQL; uma alteração posterior a esse snapshot é observada na próxima invocação/autenticação. Não aguardar toda escrita concorrente quando nenhuma renovação foi observada é a redução deliberada de coordenação. A política de autenticação continua no guard; requests já autenticados não passam a ter revogação retroativa da resposta. Antes de qualquer extensão, revalidação bloqueante continua obrigatória.

Usar a conexão de escrita para a leitura fresca evita decidir pelo atraso de eventual réplica. Não usar refresh do Model em memória nem Eloquent cached attributes como prova de persistência. Centralizar a preparação de datas/cálculo numa rotina privada do Adapter, sem duplicar constantes/limites do Domain ou criar nova fronteira.

### Custos e verificação planejada

Sem renovação: uma leitura PostgreSQL continua necessária, mas remover FOR UPDATE e os roundtrips BEGIN/COMMIT de renovação. Com renovação possível: aceitar uma leitura adicional, seguida da transação/lock já existentes. Medir separadamente queries, eventos transacionais, espera observada e tempo; não afirmar redução de SELECTs em todas as chamadas.

Manter tracking significa que autenticação com o mesmo PAT ainda pode esperar pelo UPDATE last_used_at, antes de chegar ao Adapter. Comparar same-PAT e sessões distintas com processos sincronizados, tanto no Adapter isolado quanto em HTTP, mantendo a cota por conta e statuses 200. Provar cadência no mesmo segundo/segundo seguinte, datas antigas em memória, encurtamento antes da leitura fresca e extensão/revogação/expiração/encurtamento enquanto a releitura bloqueante espera. Notifications mantém seu próprio lock de integridade e não será alterado.

Sem migration/DDL/cache/cota ou alteração da política 30/15/90. Rollback: restaurar o SessionAdapter anterior; tracking continua habilitado em ambas as versões e não há backfill, token novo ou mudança do segredo. Complementar o delta authentication porque sua redação anterior exigia lock em toda invocação, mesmo sem escrita; não sincronizar a main spec nem arquivar esta change neste step.
