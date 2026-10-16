## Context

Esta change investiga o resultado de `add-endpoint-load-testing`, sem transformar os testes simples em outro harness. A autorização atual é documental. Nenhum diagnóstico, carga, teste da aplicação ou correção foi executado para elaborar esta spec.

### Evidência histórica — 2026-10-16

Fonte principal: [rodadas 10/20/50/100](../add-endpoint-load-testing/tasks.md#rodadas-adicionais-autorizadas--102050100-concorrentes). São resultados já executados, não novas medições desta investigação.

- Conta Load Test com **60 mil despesas**, 10 mil por mês de maio a outubro/2026, até 16/10, 18 categorias. Massa sintética com descrições contendo `teste`; esse termo pode representar uma busca ampla, não todo o comportamento de autocomplete.
- Alvo: site Lerd `trocado-load-8c7621d49e0af3b61d45a027`, clone independente em `storage/app/private/`, revisão de criação `628c93294ba8d82dc7d87e5cb7599768db543454`, custom-FPM próprio, APP_ENV `load-testing`, PostgreSQL e prefixos Redis próprios. Serviços/VM/host fisicamente compartilhados. Revisão/configuração efetivas devem ser reconferidas no apply, não inferidas do checkout principal.
- Versões registradas: PHP 8.5.11, Laravel 13.34.0, Pest 5.2.1, PHPUnit 13.3.4, Stressless 5.0.2 e k6 2.1.0. Gerador PHP Linux aarch64 executou o k6 AMD64 escolhido pelo plugin; o mecanismo de compatibilidade não foi inventariado. Não chamar essa execução de gerador ARM64 nativo.
- Uma URL/token/conta por rodada; **1 segundo configurado**, processos sequenciais e **61 segundos entre cenários**. Limiter original de **60 requests/minuto por conta**, sem ampliação ou limpeza de contadores. Listagem padrão, métricas/insights padrão e sugestões com `query=teste`; preflight fora das estatísticas.

| Concorrência | Cenário | Requests | RPS | Falhas % | p50 ms | p95 ms |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 10 | Listagem | 41 | 32,63 | 0 | 269,51 | 339,79 |
| 10 | Métricas | 40 | 32,45 | 0 | 269,69 | 340,21 |
| 10 | Insights | 18 | 10,31 | 0 | 702,66 | 997,50 |
| 10 | Sugestões | 17 | 9,72 | 0 | 724,74 | 1042,76 |
| 20 | Listagem | 52 | 35,51 | 0 | 490,35 | 583,40 |
| 20 | Métricas | 53 | 36,50 | 0 | 474,14 | 571,05 |
| 20 | Insights | 27 | 10,63 | 0 | 1290,73 | 1843,26 |
| 20 | Sugestões | 26 | 10,32 | 0 | 1426,76 | 2011,95 |
| 50 | Listagem | 78 | 37,56 | 24,36 | 1081,36 | 1355,34 |
| 50 | Métricas | 81 | 38,80 | 27,16 | 1104,56 | 1277,63 |
| 50 | Insights | 57 | 12,32 | 0 | 2401,92 | 3903,43 |
| 50 | Sugestões | 56 | 12,29 | 0 | 2534,13 | 3984,40 |
| 100 | Listagem | 128 | 42,16 | 53,91 | 1712,81 | 2285,65 |
| 100 | Métricas | 132 | 45,41 | 55,30 | 1523,90 | 2105,68 |
| 100 | Insights | 108 | 20,33 | 45,37 | 4032,40 | 4871,26 |
| 100 | Sugestões | 107 | 18,88 | 42,99 | 4289,13 | 5289,51 |

**16 rodadas, 1021 requests medidos, 10 testes passaram e 6 reprovaram por fração de falhas HTTP.** Uma sonda após cada rodada reprovada confirmou 429/Retry-After: 50/listagem 41s, 50/métricas 49s; 100/listagem 49s, 100/métricas 50s, 100/insights 48s, 100/sugestões 38s. Essas sondas não classificam cada request da rodada. A saúde final `/up` foi 200; isso não mede fila, banco ou margem de recursos.

Referências iniciais adicionais, registradas na conversa anterior, com a mesma massa de 60 mil: são exemplos de rodadas distintas, **não ensaio pareado nem inventário de todas as repetições**.

| Cenário | RPS C=1 | p95 ms C=1 | RPS C=5 | p95 ms C=5 |
| --- | ---: | ---: | ---: | ---: |
| Listagem | 14,36 | 69,25 | 24,81 | 243,82 |
| Métricas | 10,68 | 137,26 | 33,59 | 182,01 |
| Insights | 3,98 | 245,69 | 8,29 | 660,15 |
| Sugestões | 3,99 | 242,59 | 10,65 | 556,29 |

### Fatos, indícios e lacunas

- Entre C=10 e C=20, Insights ganhou aproximadamente **3% de RPS**, com **85% de aumento no p95**; sugestões ganhou aproximadamente **6%**, com **93% de aumento no p95**. Ambas as rodadas tiveram falhas HTTP zero. É um indício a reproduzir, não prova de um gargalo específico.
- Nas rodadas limitadas, p50/p95 e RPS incluem erros. O crescimento de RPS de Insights/Sugestões em C=100 não comprova maior vazão útil.
- 1s é janela de geração; requests em voo terminaram depois. Latência acima de 1s e RPS diferente de requests/1s não são erros de unidade. O tempo do processo Pest inclui overhead/preflight e também não é, sozinho, duração efetiva do k6.
- Faltam repetições comparáveis, distribuição por status dentro da rodada, custo de SQL, CPU, espera no FPM, uso do gerador, inventário de recursos e estado de instrumentação. Não foram provados: N+1, falta de índice, saturação PostgreSQL/FPM, custo da compatibilidade AMD64 ou capacidade de produção.
- 60 mil é o total da conta, não a cardinalidade necessariamente lida por cada consulta. Meses selecionados, janela analítica, termo amplo, cache de páginas e hits/primeira resolução de `resource_identities` precisam ser distinguidos.

## Goals / Non-Goals

**Goals:** explicar a latência e o platô aparente, prioritariamente em Insights/Sugestões, com hipóteses rastreáveis a tráfego real, planos/queries, perfis e observação do runtime. Separar cota, gerador, aplicação e espera de execução. Produzir relatório suficiente para escolher uma próxima correção pequena.

**Non-Goals:** otimizar durante a investigação; criar índices/migrations/cache; refatorar SQL/Domain/Application; mudar a semântica de JSON:API, ownership, períodos, centavos ou agrupamento; trocar gerador; instalar dependências; aumentar pool/recursos/cota; repetir 50/100 automaticamente; criar harness, JS, endpoints públicos de diagnóstico ou SLA. Nada de VPS/produção, CI ou novas campanhas automáticas.

## Decisions

### D1 — Começar pelos sintomas sem cota, preservar falhas históricas

O foco é Insights e sugestões em C=1/10/20. Listagem e métricas são controles de custo HTTP/autenticação/infra, não provas de um custo idêntico: listagem pode usar cache e as projeções têm populações diferentes. C=5 só entra se ajudar a localizar uma transição. C=50/100 fica como evidência histórica com limitações, sem novas execuções por inferência.

Alternativa rejeitada: começar corrigindo o Repository ou ampliando o limiter porque um teste ficou vermelho. O histórico não permite atribuir todas as falhas a 429 nem localizar a causa da latência sem novas evidências.

### D2 — Preflight manual, revisão servida e limites antes de tráfego

No apply, descobrir sites/estado pelo Lerd e conferir a instância dedicada, URL/HTTPS, revisão servida pelo clone, conexão PostgreSQL efetiva, conta/PAT, 60 mil rows/10 mil por mês, categorias, data civil e timezone. Não reconstruir massa ou copiar `.env` do desenvolvimento. A referência de outubro/2026 não torna as consultas padrão de outro mês comparáveis automaticamente: declarar mês/data efetivos e separar qualquer mudança de contexto.

Inventariar servidor e gerador separadamente: OS/arquitetura, versões, configuração selecionada de PHP/OPcache, FPM (modo, children, limites e evidência de fila quando disponível), CPU/memória/limites efetivos, PostgreSQL/Redis, instrumentação, rede e serviços concorrentes. Identificar o que é dedicado versus fisicamente compartilhado. Não inferir configuração servida somente do processo Pest nem assumir que alterações no main chegaram ao clone.

Antes das rodadas, registrar duração, concorrência, quantidade de repetições, orçamento de requests e de tempo total, timeouts por request/processo e prazo/checagens de recuperação compatíveis com o inventário e com o runner existente. Interromper em falha de autenticação/configuração, falta de recuperação, timeout ou limite de recursos. Não liberar mais carga para compensar amostras insuficientes.

### D3 — Protocolo reduzido e controle de validade

1. Fazer uma sonda HTTP por endpoint/variante, confirmar 200/estrutura/conta e distinguir preflight da medição.
2. Medir Insights e sugestões em C=1/10/20; controles listagem/métricas em C=1/20. Pelo menos **três repetições independentes por combinação selecionada**, uma rota/processo por vez. Cada combinação pode ser bloqueada/interrompida com motivo, sem substituí-la silenciosamente por outra.
3. Manter inicialmente 1s, sem instrumentação pesada, reconferindo a janela da conta e aguardando sua renovação (61s foi a estratégia histórica). Incluir preflights/sondas no orçamento da cota. Qualquer 429 ou falha torna aquela repetição inválida para inferir vazão de leituras bem-sucedidas; registrar erro e não apagar/repetir até verde omitindo as falhas.
4. Se duração/amostras impedirem a análise, propor uma rodada **C=1 por até 5s**, somente onde o orçamento conservador observado caiba na cota. Stressless não expõe teto rígido de requests por rodada: uma estimativa não garante ausência de 429. Caso a proteção continue impedindo a observação, registrar Blocked/Inconclusive e obter decisão específica; não remover middleware ou elevar cota nesta change.
5. Registrar p50/p95 por repetição e sua faixa de variação, RPS, requests, fração de falhas, duração configurada, tempo do processo separado e fonte de cada medida. Três repetições não tornam automaticamente o p95 estável. Não fazer média de percentis como percentil global nem chamar um burst de 1s de regime estacionário.

O preflight existente aquece a rota; preservar essa condição na referência e não alegar cache frio. Registrar página/critério, termo de sugestões e cardinalidade correspondente. Não invalidar cache/associações por request. Insuficiência de amostras é um resultado visível, não autorização para ampliar o escopo.

### D4 — Diagnóstico dirigido por tráfego real

Fluxo preferido, conferindo as capacidades existentes no apply: `route_timing` para localizar rotas → registrar estado da captura/SPX → habilitar captura de queries e profiler somente na janela diagnóstica → atingir as rotas selecionadas → `optimize_route`/`analyze_queries` e perfil para correlacionar rota, queries e CPU. Filtrar pelo site/branch, intervalo e amostras frescas para não atribuir tráfego antigo ou do desenvolvimento à investigação.

Só então localizar os callers no **checkout efetivamente servido**, usando arquivo/linha dos achados. Não inspecionar controllers para adivinhar N+1. Ausência de alerta, captura vazia ou profiler indisponível não prova ausência de gargalo; declarar a lacuna. `route_timing` é sintoma agregado, não evidência causal isolada.

Capturas/perfis são diagnósticos separados da referência sem instrumentação pesada. Registrar/restaurar estados anteriores, inclusive quando o toggle é global e afeta outro site. Se o alcance não puder ser isolado/coordenado, bloquear essa parte em vez de interferir em sessões de diagnóstico alheias. Não desligar uma instrumentação preexistente do usuário ao terminar.

### D5 — SQL e PostgreSQL: provar o custo, não escolher um índice por antecipação

Para os SELECTs capturados: número de chamadas por request, tempo, fingerprints sem bindings, cardinalidades esperadas/observadas, planos, scans, sort/agregação/window functions, buffers e spills quando disponíveis. Inspecionar schema/índices/estatísticas atuais por leitura antes de sugerir DDL. Em sugestões, distinguir busca/normalização/agrupamento histórico e janela de valores; em Insights, distinguir seleção/agregação/fatos de composição posterior.

`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` executa a consulta: usar apenas SELECTs de leitura no banco dedicado, parâmetros privados, prazo de statement limitado e preferencialmente transação read-only. Não executar ANALYZE de INSERT/UPDATE/DELETE/DDL; não criar índices, rodar manutenção de estatísticas ou desabilitar scans para obter um plano melhor. Identificar aquecimento de buffers pelo próprio diagnóstico.

Verificar também esperas/locks observados em autenticação/PAT e registro Core, quando presentes no tráfego. Hits de `resource_identities` são contratualmente leituras; não presumir que cada GET insere/atualiza. Provar contagem/espera real antes de atribuir contenção ao registro, token ou Redis.

### D6 — PHP, FPM e gerador são hipóteses distintas

Correlacionar por request/rodada o tempo HTTP com o que existe de tempo de aplicação/SQL, CPU do perfil, atividade/espera de workers e consumo do gerador/host. Não subtrair p95 agregados de populações diferentes para fabricar tempo de fila. Ausência de fila visível não elimina espera sem observação adequada.

Usar métricas/logs locais já disponíveis, sem publicar status/debug endpoints. Distinguir CPU PHP (composição editorial, aritmética, serialização, autenticação etc.), espera de execução no FPM e custo do PostgreSQL/Redis. O fato de todas as rotas crescerem não identifica sozinho qual recurso é compartilhado.

O k6 AMD64 funciona, mas sua CPU/compatibilidade e contenção com o alvo precisam ser observadas. Se o gerador saturar, o resultado não comprova saturação do alvo. Se for necessária uma comparação com gerador nativo/externo ou alteração de recursos para discriminar a hipótese, apresentar proposta para decisão, não instalar/trocar runtime por conta própria. Não reintroduzir o spike JS/Node descartado.

### D7 — Registro de hipóteses e nível de evidência

Todas começam **Unproven**. Um achado correlacionado dá suporte, mas confirmação causal exige evidência do mecanismo e comparação controlada suficiente para excluir alternativas relevantes. Quando isso depender de intervenção fora do escopo, manter Partially proven/Inconclusive e propor a intervenção.

| Hipótese | Evidência procurada | O que não basta |
| --- | --- | --- |
| H1 — SQL de Insights domina | SELECTs/planos/tempo/buffers compatíveis com o tempo do mesmo request | Repository parecer complexo ou haver scan |
| H2 — Busca/agregação de sugestões domina | Plano e cardinalidades para `query=teste`, normalização/grupos/sort/janela | Termo amplo e 60 mil rows, isoladamente |
| H3 — CPU PHP domina | Perfil com funções/hotspots e uso de CPU coerentes com wall time | Nome de UseCase/compositor ou quantidade de classes |
| H4 — Fila/limites do FPM | Workers/queue/max-children/tempos observados na mesma janela | p95 crescer com concorrência |
| H5 — Esperas em DB/PAT/Core/Redis | Locks/waits/queries reais e seu escopo por request | Presumir escrita/lock em todo GET |
| H6 — Gerador/VM compartilhada limita | CPU/memória/arquitetura/limites e contenção observados | Binário AMD64 ou máquina local por si só |
| H7 — Instrumentação distorce | Estados e comparação de referência versus captura equivalente | Assumir Xdebug/profiler desligados |
| H8 — Amostragem/workload distorce | Repetições/contagens, duração/tail, dados/termo/cache/contexto civil | Um único p95 de burst ou extrapolação para 5s |

Classificar achados como Proven, Partially proven, Unproven ou Blocked; declarar hipótese apoiada/refutada/inconclusiva, confiança e alternativas. Um caso ausente ou uma ferramenta sem recurso não é pass/skip verde.

### D8 — Entrega é diagnóstico, correção é outra decisão

Relatório final nos artefatos desta change: resumo por rota, inventário sanitizado, rodadas individuais (incluindo inválidas), matriz de hipóteses/evidências, links/callers, limitações e propostas priorizadas. Para cada proposta: owner/camada, mecanismo esperado, evidência, impacto estimado sem promessa, risco para contratos, experimento de validação e autorização necessária.

Preservar Domain/Application puros e as permissões existentes entre contextos. Índice/cache/refactor/pool/limiter não é aplicado nesta investigação. Não alterar testes/esperados para encobrir falha, definir SLA arbitrário ou declarar melhorias que não foram implementadas/medidas. Uma investigação pode encerrar honestamente com causas ainda inconclusivas e próximos experimentos bloqueados.

## Risks / Trade-offs

- [429 mistura populações] → usar repetições sem erros para custo de negócio e separar as limitadas.
- [Poucas amostras/cauda após 1s] → repetir, registrar variação e declarar insuficiência; duração maior só com orçamento da cota.
- [Clone desatualizado ou mês/contexto diferentes] → identificar revisão/DB/consulta realmente servidos e separar séries não equivalentes.
- [Captura global altera outro site] → inventário, janela coordenada, restauração do estado anterior ou bloqueio parcial.
- [EXPLAIN executa SQL pesado] → SELECT dedicado/read-only com timeout e sem DDL/manutenção.
- [Gen/target compartilham VM] → observar ambos e não extrapolar para VPS/usuários humanos.
- [Diagnóstico vira projeto de tooling] → comandos existentes e relatório manual; nenhuma suíte/harness ou dependência nova.
- [Raw captures contêm dados sensíveis] → mantê-los privados, extrair somente campos permitidos e não publicar tokens, SQL bindings, descrições/valores financeiros ou dumps de configuração.

## Migration Plan

Não há migration/deploy. Após autorização de apply: conferir contexto/limites → referência reduzida → capturas diagnósticas separadas → planos/CPU/esperas → síntese e propostas → restaurar instrumentação, encerrar somente processos próprios e verificar saúde/ausência de resíduos próprios. Não apagar massa, PATs ou recursos preexistentes para encerrar a investigação. Nenhum archive/commit/push é inferido do apply.

## Open Questions

- **Bloqueante para execução:** autorização explícita do apply; o pedido atual é só a spec.
- **A resolver no preflight:** revisão/configuração efetivas do clone, recursos/limits, alcance e disponibilidade das ferramentas, validade do PAT, referência civil e orçamento finito das rodadas. Ausência não bloqueia a elaboração, mas bloqueia as provas afetadas.
- **Condicionais:** se a cota impedir duração útil ou a hipótese exigir mudar recursos/gerador/índices, pedir decisão específica. Não presumir essa autorização da carga histórica.
- **Posteriores:** SLA, capacidade de produção e plano de otimização não são critérios desta investigação.

## Traceability

| Requisito | Decisões | Evidência futura |
| --- | --- | --- |
| INV-01 | Context/D1 | Histórico íntegro, unidades/populações e classificação das rodadas |
| INV-02 | D2 | Preflight/inventário sanitizados do alvo, dados e gerador |
| INV-03 | D3 | Rodadas/repetições/budget e rejeição de resultados contaminados |
| INV-04 | D4/D5 | Tráfego → callers/queries → planos SELECT, com lacunas explícitas |
| INV-05 | D6 | Observação correlacionada de CPU/FPM/DB/gerador |
| INV-06 | D4/Migration Plan | Estados de instrumentação, recuperação e restauração |
| INV-07 | D7 | Matriz de hipóteses com evidências/alternativas/limitações |
| INV-08 | D8 | Relatório, propostas priorizadas e decisão de próximas intervenções |

## Diagnóstico focal executado — 2026-10-16

### Escopo e inventário observado

Autorização posterior: “Pode fazer essa investigacao aqui — Insights e sugestões merecem investigação prioritária.” Esta seção registra execução focal real, não a conclusão da matriz completa D3. Nenhuma correção foi aplicada.

- Alvo descoberto com Lerd `site list`/`diag which`: custom-FPM dedicado do clone histórico, revisão Git `628c93294ba8d82dc7d87e5cb7599768db543454`. Seu status contém `.lerd.yaml` modificado e os arquivos locais de provisionamento, preservados. O checkout principal também já tinha alterações de tooling/documentação, preservadas.
- `exec artisan tinker --execute=...` no clone confirmou `APP_ENV=load-testing`, `current_database()` exatamente `trocado_load_8c7621d49e0af3b61d45a027`, UTC/data 2026-10-16, uma conta, um PAT não expirado e 60.000 despesas, 10.000 em cada mês de maio a outubro, 18 categorias. O Bearer existente autenticou as sondas. Configuração privada continua no `/tmp` do PHP compartilhado; não está no `/tmp` do custom-FPM. Nenhuma credencial foi copiada/impressa.
- PHP 8.5.11/aarch64; container enxerga 5 CPUs e teto de memória da VM de aproximadamente 3,02 GB (compartilhado, não alocação exclusiva). `podman inspect` não mostrou quota CPU/memória própria do custom-FPM. PostgreSQL, Redis e outros serviços continuam compartilhando a VM. `podman stats --no-stream` foi inventário pontual em repouso, não monitoramento de saturação sob carga.
- `podman exec <custom-FPM> php-fpm -tt`: pool dynamic, `pm.max_children=5`, `start_servers=2`, spare 1–3; sem status/slowlog configurados. A leitura CLI de ini mostrou OPcache habilitado, memory_limit 128M, SPX disponível e bridge como auto-prepend; isso não substitui inventário completo de valores efetivos da SAPI FPM. Não foram alterados pool, ini ou endpoints de status.
- PostgreSQL: `work_mem=4 MB`, shared_buffers=128 MB, max_connections=100, jit=on; planos obtidos não contêm seção JIT. Estatísticas estimavam 60.000 rows, sem dead tuples e com autoanalyze recente. Índices incluem PK, `(user_id, occurred_on)` e `(user_id, occurred_on, id)`; não se pode afirmar ausência de índice de proprietário/período.
- Dumps e profiler já estavam globalmente habilitados, com assinante ativo. Nenhum toggle/clear foi aplicado. SPX efetivamente produziu perfis HTTP nesta janela. Portanto todas as latências abaixo são diagnósticas/instrumentadas. Medição limpa e comparação de overhead permanecem Blocked por necessidade de coordenação dos estados globais preexistentes.

### Leituras HTTP e correlação fresca

Uma sonda inicial de Insights retornou 200 em 379,56 ms. Depois foram feitas três leituras sequenciais de cada rota, com Bearer existente, connect timeout 3s/timeout 10s, sem k6, entre 18:35:40–18:35:42 UTC:

| Rota | Repetição | HTTP ms | Query principal capturada ms | rid |
| --- | ---: | ---: | ---: | --- |
| Insights | 1 | 380,92 | 185,34 | `6c00f36d949e27fecf312e4c` |
| Insights | 2 | 250,61 | 169,52 | `74904fdeec1b8f806e7bc217` |
| Insights | 3 | 234,25 | 160,16 | `3d781f0f2e5c15f610804af6` |
| Sugestões `teste` | 1 | 323,10 | 245,54 | `613fc259b3410fb14a4692a8` |
| Sugestões `teste` | 2 | 310,52 | 207,06 | `f6e81915490b1e512185c551` |
| Sugestões `teste` | 3 | 292,83 | 202,06 | `5c68166cdd0011a7e407d525` |

Todas retornaram 200; Insights retornou um item e sugestões cinco. As medidas do cliente incluem transporte/overhead; não foram transformadas em p95, RPS ou tempo de fila. `dumps_recent` retornou também registros antigos apesar de `since`: a seleção foi conferida localmente por timestamp, ctx fpm, rota e rid. `analyze_queries` também inclui histórico e ordenação por custo; seus primeiros itens não foram assumidos como os requests atuais.

Os eventos recuperados contêm 4–6 queries por rid, com captura incompleta em alguns requests; não se declara essa faixa como contagem exata de todos os statements. Em cada um dos seis requests há uma consulta principal do Repository, sem multiplicação por item observada. Hits do registro Core foram SELECTs de aproximadamente 0,94–2,12 ms; releitura da sessão 0,24–0,54 ms; lookup de PAT 5,90–10,45 ms nos eventos recuperados. Há UPDATE de autenticação em parte das capturas: não atribuir isso a Core nem presumir custo zero de autenticação. Não houve prova de locks/esperas do banco ou Redis sob concorrência.

### Planos SQL e mecanismo encontrado

Após os callers aparecerem nas capturas, foram lidos no checkout servido:

- `app/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepository.php:133`.
- `app/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepository.php:19`.

Os mesmos Repositories foram invocados no clone para obter SQL/bindings em memória por QueryExecuted; nunca publicados. As duas queries foram explicadas com `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` na mesma transação read-only, com `SET LOCAL statement_timeout='5s'` e rollback em finally. Parâmetros: referência vigente 2026-10-16 e, para os valores de sugestões, julho–setembro/2026. Nenhum DDL, ANALYZE de manutenção, configuração de otimização ou plano alternativo foi aplicado.

**Insights:** a leitura do Repository levou 190,48 ms nesta execução CLI; o plano instrumentado levou 381,689 ms, planning 0,226 ms. São execuções diferentes; EXPLAIN acrescenta overhead e não substitui o tempo HTTP.

- Seq scan leu 60.000 rows e conservou 30.000 da janela agosto–16/outubro, aproximadamente 9,982 ms nesse nó. Os buffers base foram hits, sem shared reads.
- O join dos cinco períodos com as 30.000 despesas produziu 44.380 linhas e eliminou 105.620 combinações pelo filtro. A materialização é reutilizada para totais, categorias e maior lançamento.
- Há escrita/leitura temporária nos CTEs e sort `external merge` em disco para maior lançamento, com 4.096 KiB de sort space. No nó raiz, 1.400 temp blocks lidos e 1.282 escritos. Não somar contadores inclusivos dos pais/filhos.
- Isso demonstra custo de expansão/materialização/agregação/ordenação neste plano. O scan inicial não domina o custo observado; um índice novo por hábito não é uma correção sustentada por esta evidência.

**Sugestões:** leitura do Repository 189,94 ms; EXPLAIN 364,385 ms, planning 0,138 ms.

- Para `teste`, o filtro aceitou as 60.000 rows: normalização com regexp/lower, ordenação por descrição normalizada/data/id e WindowAgg processam todo esse conjunto.
- O sort anterior à janela usou `external merge`, 5.984 KiB em disco; raiz com 748 temp blocks lidos e 750 escritos, sem shared reads.
- O agregado produziu 900 grupos e só então a ordenação final/LIMIT selecionou cinco. `LIMIT 5` limita a saída, não o trabalho anterior.
- A janela financeira restringe os agregados de valor, não toda a busca histórica. Restringir silenciosamente o histórico ou aplicar LIMIT antes de escolher corretamente os grupos mudaria o contrato.

### Perfis HTTP e FPM

Os seis perfis HTTP SPX da janela foram associados por host/URI/timestamp. Os eventos foram reduzidos em memória usando pilha entrada/saída, com validação de zero frames abertos/zero saídas incompatíveis; tempos dos eventos convertidos de ns para ms. Não se usou o nome `wall_time_ms` do metadata bruto para inferir unidades. IDs privados de captura para rastreabilidade: `20261016_183540` PID74/180904821; `183541` PID73/1941719893, PID72/122380465, PID74/820798753; `183542` PID72/1923064278, PID73/536091009.

- Insights: wall do perfil 192,53–289,52 ms; closure de SELECT 163,10–189,92 ms exclusivos. Geração de candidatos 0,82–1,98 ms inclusivos; composição da mensagem 0,07–0,36 ms inclusivos. Autoload do primeiro request teve 43,38 ms exclusivos versus 0,57–0,66 ms nos outros. Não há evidência de composição editorial dominando esses requests.
- Sugestões: wall 246,50–283,10 ms; SELECT 206,07–249,89 ms exclusivos. O UseCase levou 206,91–253,86 ms inclusivos, majoritariamente tempo transitivo da consulta. Isso não prova CPU PHP elevada.
- Os perfis disponíveis medem wall/memória, não CPU de processo separada. Tempo dentro de SELECT inclui espera no banco. Não chamar esse wall time de tempo exclusivo de CPU do PostgreSQL ou PHP.
- Duas sondas adicionais com cookies SPX de escopo do request retornaram 200: Insights 1.132,65 ms e sugestões 303,42 ms. O outlier de Insights teve perfil wall 908 ms, SELECT 589,4 ms exclusivos, autoload 149,6 ms e bridge 33,7 ms. Foi preservado, não substituído pela melhor rodada. `optimize_route` correlacionou esse perfil, sinalizando p95 991 ms/5 amostras de Insights; esse agregado instrumentado não é benchmark limpo nem regressão de produto demonstrada.
- `profiler_report` CLI dos dois Repositories também executou com sucesso, mas inclui bootstrap do Artisan/Tinker e autoload frio; não foi usado como perfil equivalente do request HTTP.
- Logs FPM históricos registram seis ocorrências de `server reached pm.max_children setting (5)` entre 18:04:11 e 18:10:48 UTC. Limite e atingimento são comprovados; a contribuição causal para cada p95 antigo permanece parcial, sem medição contemporânea de listen queue/tempo em fila. Nenhum warning/error novo foi retornado para a janela diagnóstica.

### H1–H8: resultado por hipótese

| Hipótese | Insights | Sugestões | Evidência / confiança / limitação |
| --- | --- | --- | --- |
| H1 — SQL de Insights domina | Proven neste recorte instrumentado | Não aplicável | Query 160–185 ms e maior hotspot de wall no SELECT; plano explica materialização/sort. Alta para os requests observados, não para capacidade sustentada. |
| H2 — SQL de sugestões domina | Não aplicável | Proven neste recorte instrumentado | Query 202–245 ms; 60 mil linhas, 900 grupos e sort em disco antes de LIMIT 5. Alta neste termo/massa, sem generalizar para todo autocomplete. |
| H3 — CPU PHP/composição domina | Não apoiada neste recorte; Partially proven | Não apoiada neste recorte; Partially proven | Composição sub-ms e wall do SELECT dominante. CPU separada indisponível; autoload/bridge participam de outliers. Não há motivo medido para refatorar Domain/Application. |
| H4 — Pool limita concorrência | Partially proven | Partially proven | max_children=5 e warnings históricos; contribuição de fila para cada rodada não medida. Confiança média no mecanismo, sem atribuir todo platô ao pool. |
| H5 — PAT/Core/Redis/locks domina | Unproven sob concorrência | Unproven sob concorrência | Eventos individuais pequenos frente ao SQL principal; não houve monitoramento de locks/waits concorrentes. Core hit somente SELECT nos eventos recuperados. |
| H6 — Gerador/VM limita | Unproven | Unproven | Custo reproduzido sem k6, logo k6 não é necessário para a lentidão individual. Não exclui interferência do k6 AMD64/VM nas cargas históricas. |
| H7 — Instrumentação distorce | Partially proven / comparação limpa Blocked | Partially proven / comparação limpa Blocked | SPX realmente ativo; bridge mede 3,66–5,78 ms nos seis perfis e 33,7 ms no outlier. Efeito total exige comparação coordenada, sem desligar estado do usuário. |
| H8 — Amostragem/workload distorce | Partially proven | Partially proven | Bursts antigos pequenos/com erros; termo atual casa com 60 mil rows. Generalização para regime sustentado/termos seletivos continua sem prova. |

### Próximas propostas priorizadas — ainda não aplicadas

1. **Insights Infrastructure: experimentar outra forma da consulta analítica**, reduzindo expansão/materialização e sort de linhas largas, preservando snapshot único, datas civis, somas exatas, desempates e maior descrição da mesma seleção. Evidência: plano e perfis acima. Validar equivalência funcional PostgreSQL e comparar planos/latência em massa igual. Risco: alterar semântica dos períodos sobrepostos ou do máximo. Benefício potencial concentrado no componente hoje dominante, sem estimativa percentual garantida. Exige autorização de correção própria.
2. **Expense Infrastructure: experimentar seleção de candidatos/grupos antes do trabalho detalhado dos valores**, evitando normalizar/ordenar repetidamente todo o histórico quando houver estratégia equivalente. Definir por prova se expressão/indexação materializada ou outra SQL ajuda; substring arbitrária/normalização não ganha automaticamente de um B-tree convencional. Preservar ranking global, grafia recente, substring/prefixo e três meses representados. Validar resultados com termos amplos/seletivos e plano antes/depois. Risco: top cinco incorreto ou janela financeira usada como corte indevido do histórico. Exige decisão de implementação/DDL se necessário.
3. **Ambiente: comparação controlada do pool e da instrumentação**, separada das correções SQL. Recursos compartilhados e `work_mem` por operação tornam aumento cego de workers/memória arriscado. Medir fila, CPU/memória e latência com mesma carga antes/depois de qualquer alteração autorizada; ampliar children pode apenas deslocar contenção ao PostgreSQL. Não há justificativa para escolher agora um novo tamanho de pool.

### Rastreabilidade e encerramento focal

| Requisito/cenários | Evidência desta etapa | Estado restante |
| --- | --- | --- |
| INV-01: histórico/erros/unidades | Histórico preservado; medições novas rotuladas como individuais instrumentadas | Sem nova matriz de capacidade ou SLA |
| INV-02: alvo/credencial/data/recursos | Descoberta Lerd, Git, DB exato, massa e HTTP 200; inventário sanitizado acima | Inventário completo SAPI/gerador e interferência concorrente parcial |
| INV-03: repetições/cota/limites | Seis leituras sequenciais + sonda inicial + duas sondas SPX; timeouts finitos, sem 429 | Matriz C=1/10/20 e controles não executada; referência limpa Blocked |
| INV-04: query/plano/captura ausente | Tráfego fresco → dois callers → SELECTs explicados read-only/5s | Captura contém lacunas; nenhum alerta vazio usado como prova |
| INV-05: PHP/FPM/DB/gerador | Perfis HTTP wall + planos + pool/logs; sem k6 no diagnóstico | CPU/fila/waits concorrentes e capacidade sustentada Unproven |
| INV-06: instrumentação/relatório | Nenhum toggle/clear global; cookies de profiling locais ao request; sem scripts/arquivos de execução próprios | Capturas persistem no armazenamento privado preexistente do Lerd e no output privado do agente, sujeitos à retenção dessas ferramentas; não copiar bruto ao Git |
| INV-07: parcial/refutação/fora do escopo | Matriz H1–H8 com alternativas e alcance acima | Intervenções causais adicionais exigem decisão |
| INV-08: relatório/propostas/inconclusivo | Diagnóstico e propostas aqui, sem corrigir produto | Change inteira não concluída/arquivável; não há melhoria implementada ou capacidade VPS provada |

Saúde final `/up` retornou 200, configuração privada preservada, dumps/SPX continuam habilitados como no início. Sem processos persistentes próprios, migrations, dependências, novo harness, testes funcionais, limpeza de contadores, alterações de quota/pool/SQL ou deploy. O warning agregado de Insights é explicado pelos requests diagnósticos instrumentados e permanece registrado; não foi removido para produzir estado verde.
