## Checklist atual — carga simples com Pest

Decisão explícita do usuário: “Também to achando. Só queria teste de carga”. Este checklist substitui o backlog de 51 tarefas. Não há equivalência entre a entrega pequena e os cenários avançados retirados.

- [x] 1.1 Usar Pest/Stressless público em PHP e comprovar execução local, retirando adaptação k6/JS/Node e lifecycle de campanha. [LOAD-01]
- [x] 1.2 Implementar quatro leituras fixas, configuração privada mínima, preflight HTTP/JSON:API e relatório das métricas suportadas. [LOAD-03–06]
- [x] 1.3 Verificar seleção/descoberta funcional, limites, configuração privada e sanitização com testes focados. [LOAD-02–05]
- [x] 1.4 Executar sondas autenticadas pequenas e registrar sucessos/falhas reais, sem ampliar limiter ou alegar benchmark representativo. [LOAD-04–06]
- [x] 1.5 Atualizar documentação, rastreabilidade e inventário do alvo; executar Pint e validar OpenSpec/diff. [LOAD-01–06; ORG-01; ISO-08]

## Histórico — backlog anterior substituído

Os estados abaixo são os da versão anterior, não tarefas ativas da entrega simplificada. “Pendente” não foi convertido em implementação concluída: a obrigação avançada foi retirada por decisão de escopo. As evidências históricas completas seguem após a tabela. Os requisitos LOAD antigos citados nos registros históricos pertencem à versão anterior; use os requisitos atuais para a aceitação atual.

| ID anterior | Estado anterior | Trabalho e destino na revisão |
| --- | --- | --- |
| 1.1 | Concluída | Autorização do apply local; histórico preservado. |
| 1.2 | Concluída | Instalação Stressless estável/lockfile; mantida. |
| 1.3 | Parcial | Topologia dedicada; alvo criado, inventário abaixo, sem lifecycle automatizado. |
| 1.4 | Concluída no spike | Runtime/download/TLS nativo; spike retirado e substituído pela prova do plugin oficial. |
| 1.5 | Concluída no spike | Tokens/cursor/status/p99; capacidades fora do novo escopo, não reivindicadas. |
| 1.6 | Concluída | Adaptação autorizada e depois abandonada pela simplificação explícita. |
| 2.1 | Concluída | Entrada manual; mantida com seleção simplificada. |
| 2.2 | Concluída | Organização por contexto/Presentation/Http; mantida. |
| 2.3 | Concluída | Descoberta funcional sem Load; reverificada no escopo novo. |
| 2.4 | Concluída | Manifesto/fases/estados; retirados, permanece configuração privada mínima. |
| 3.1 | Pendente | Provisionamento automatizado/readiness; substituído por preparação manual do alvo. |
| 3.2 | Pendente | Preflight CLI/DB/HTTP/revisão integrado; reduzido a preflight HTTP e confirmação manual do alvo. |
| 3.3 | Pendente | Ownership/lease/migrations por campanha; fora do escopo. |
| 3.4 | Pendente | Negativas de manifesto/DB/cleanup; fora do escopo sem acesso DB pelo runner. |
| 3.5 | Pendente | Campanhas simultâneas/lease; fora do escopo. |
| 4.1 | Pendente | Dataset versionado/seed/distribuição; preparação manual. |
| 4.2 | Pendente | 20 contas/PATs/200 mil despesas; obrigação retirada. |
| 4.3 | Pendente | Contagens/reuso/recusa de dataset divergente; fora do escopo. |
| 4.4 | Pendente | Token só no gerador/isolation A/B; preflight simples não é prova equivalente. |
| 4.5 | Pendente | Registro de credenciais de campanha; substituído por arquivo privado sem lifecycle de PAT. |
| 5.1 | Pendente | Ampliação de cota de capacidade; retirada, produto conserva default. |
| 5.2 | Pendente | Namespaces/configuração por perfil; não implementados no runner. |
| 5.3 | Pendente | Cenário 60/61 entre rotas/tokens/contas; testes funcionais conservados, sem suíte de proteção Load. |
| 5.4 | Pendente | Negativas de perfil/Redis; retirada sem alteração no limiter. |
| 5.5 | Pendente | Inventário/limites/recovery de campanha; reduzido a concorrência/duração/prazo fixos. |
| 5.6 | Pendente | Escada 1/5/10/20 entre 20 contas; substituída por uma rodada manual e um token. |
| 5.7 | Pendente | Recuperação automática e requests em voo; fora do escopo. |
| 6.1 | Pendente | Matriz de páginas/filtros/sorts/cursores; reduzida a GET padrão. |
| 6.2 | Pendente | Métricas total/agrupado/meses/registro; reduzida a GET padrão. |
| 6.3 | Pendente | Insights mensal/onboarding/registro; reduzida a GET padrão. |
| 6.4 | Pendente | Sugestões frequente/raro/vazio; reduzida à query fixa teste. |
| 6.5 | Pendente | Estados de cache/registro controlados; fora do escopo, estado existente declarado. |
| 6.6 | Pendente | Taxonomia e checks de negócio por resposta sob carga; só preflight e fração HTTP nesta versão. |
| 7.1 | Pendente | p99/status/concorrência observada; relatório reduzido às métricas públicas suportadas. |
| 7.2 | Pendente | Agregação entre geradores; retirada, um processo por rodada. |
| 7.3 | Pendente | Relatório de campanha/inventário/retention; resumo simples no terminal. |
| 7.4 | Pendente | Sanitização completa do motor/processos/temporários; reduzida a campos permitidos e redação do token na saída. |
| 7.5 | Pendente | Cleanup de filhos/DB/Redis/PAT e restauração; sem lifecycle de recursos no runner. |
| 7.6 | Pendente | Cleanup em falha/SIGKILL/recovery por manifesto; retirada. |
| 8.1 | Pendente | Sondas dos quatro endpoints; executadas no novo escopo apenas para provar o tooling. |
| 8.2 | Pendente | Três repetições por combinação/variabilidade; fora do escopo. |
| 8.3 | Pendente | Diagnóstico integrado Lerd queries/CPU; fora do escopo. |
| 8.4 | Pendente | Referências e aprovação de thresholds por ambiente; limiar opcional do operador. |
| 8.5 | Pendente | Regressão equivalente/referência preservada; não oferecida nesta versão. |
| 8.6 | Pendente | Investigação/correções de capacidade; fora do escopo. |
| 9.1 | Pendente | Documentação operacional extensa; substituída por instruções simples e arquitetura Load. |
| 9.2 | Pendente | VPS/gerador externo/referências próprias; fora da versão local. |
| 9.3 | Pendente | Gates completos de suporte compartilhado; não declarados pelo gate focado atual. |
| 9.4 | Pendente | Pint/OpenSpec/diff; aplicados à revisão atual. |
| 9.5 | Pendente | Matriz dos antigos 46 cenários; substituída pela matriz dos requisitos atuais, sem alegar equivalência. |
| 9.6 | Pendente | Thresholds/fechamento/arquivo; não se arquiva nem publica por inferência. |

## Dependências e estado da elaboração — histórico anterior

- Fase 1 precede recursos/medições de produto. Limitações do motor bloqueiam cenários dependentes; não autorizam substituição silenciosa da ferramenta.
- Fases 2–5 estabelecem separação, ownership e correção antes da carga. Fases 6–7 produzem cenários e evidências verificáveis. Fase 8 depende de todas as checagens aplicáveis e da autorização de execução.
- O usuário aprovou a dependência dev na elaboração e autorizou iniciar o apply local pelo STEP 01 em 2026-10-16. A autorização cobre o spike e sondas locais controladas desta etapa; etapas posteriores e operações remotas não são inferidas deste pedido.
- Estado inicial de todos os cenários de produto/tooling: **Unproven**. Consultas documentais ao upstream não comprovam resolução de Composer, execução de k6, isolamento Lerd ou capacidade dos endpoints.
- Homologação VPS tem parâmetros e operação documentados nesta entrega, mas não execução presumida. Não se arquiva como medição remota concluída; qualquer requisito adicional de prova remota exige revisão explícita de escopo.

## Validação documental — 2026-10-16

- Change criada pelo CLI OpenSpec 1.6.0; `doctor --json` indicou root saudável. Proposal, design, quatro delta specs e tasks seguem as instruções retornadas pelo CLI.
- `openspec validate add-endpoint-load-testing --type change --strict --json --no-interactive`: válido, sem issues. `status` indica os quatro artefatos de planejamento completos, não implementação concluída.
- Catálogo conferido: uma capacidade nova e três modificadas, correspondentes aos quatro arquivos de specs; 17 requisitos e 46 cenários. Blocos MODIFIED preservam todos os cenários anteriores dos requisitos alterados.
- Checklist: 51 tarefas de implementação pendentes; rastreabilidade por requisito e matriz em design. Nenhuma tarefa foi marcada com base em consulta documental.
- Whitespace dos sete arquivos Markdown novos conferido individualmente com `git diff --no-index --check /dev/null <arquivo>`.
- Não foram instalados plugin/k6, executados testes da aplicação/carga, provisionados recursos, preparados usuários/dados, alteradas main specs ou operado ambiente remoto. As alterações preexistentes fora desta pasta foram preservadas.

## Apply — STEP 01 — 2026-10-16

### 1.1 — Proven

- Autorização explícita: “Vamos comecar a implementar a spec de stress test pela step STEP 01 — Autorizar apply e comprovar o motor”.
- Reconsultados proposal, design, quatro delta specs, tasks, SPEC e ARCHITECTURE; `openspec status`/`instructions apply` resolveram a change local com 51 tarefas. Validação estrita passou sem issues antes do apply.
- Boost confirmou PHP 8.5, Laravel 13.34.0, Pest 5.2.1 e PHPUnit 13.3.4; documentação Pest 5 de stress testing consultada via Search Docs. Composer declara PHP `^8.3`, Pest `^5.0`, estabilidade stable; requisito PHP será preservado.
- Estado preexistente: README e ExpenseSeeder modificados, STEPS removido, SPEC e esta change não rastreados. Não são resultados deste spike.

### 1.2 — Proven

- `lerd composer show pestphp/pest-plugin-stressless --all --format=json`: release estável v5.0.2 disponível, commit `d1df49be234a00b8c6d49e79fde85f536849560d`, MIT; PHP `^8.4`, ext-curl/ext-zip, Pest `^5.0.3` e pest-plugin `^5.0.0`.
- `lerd composer require --dev 'pestphp/pest-plugin-stressless:^5.0' --dry-run --no-interaction --no-scripts`, seguido da mesma instalação sem `--dry-run`: **1 install, 0 updates, 0 removals**, v5.0.2 registrada em require-dev e lockfile. Scripts de publicação/boot Laravel não foram executados.
- `lerd composer check-platform-reqs`: sucesso, PHP **8.5.11**, curl **8.5.11**, zip **1.22.8**, Phar disponível. `lerd composer validate --strict --no-interaction`: válido. Requisito raiz PHP `^8.3`, Pest 5.2.1 e PHPUnit 13.3.4 preservados.
- Composer apontou duas classes enum preexistentes fora de PSR-4 em `UserAdapterTest.php`; não impediu instalação/autoload e não foi corrigido neste escopo.

### 1.3 — Partially proven: topologia proposta, prontidão não comprovada

- Lerd `site list` encontrou somente o site de desenvolvimento. `diag which` confirmou PHP 8.5 e document root do checkout atual; `diag status` indicou DNS `.test` saudável, nginx/FPM ativos, mkcert 1.4.4 e **watcher parado**. Não foi realizado reparo global.
- Mecanismo suportado consultado em `.ai/lerd.md`: site com checkout próprio e custom-FPM (`Containerfile.lerd` baseado em `lerd-php85-fpm:local`, seção `container` sem porta), cadastrado com `site link`. Isso permite FPM próprio, além da separação de diretórios. `lerd link --help` confirmou o registro pelo diretório.
- Proposta para o STEP 03: checkout dedicado da revisão medida, sem symlinks de `.env`, `bootstrap/cache` ou `storage`; configuração/compilados/logs próprios, sem workers de fila/schedule/classificação; PostgreSQL exclusivo com ownership por campanha e Redis com prefixos exclusivos de campanha/perfil em todas as conexões relevantes. Control plane, gerador e alvo serão identificados separadamente. Serviços PostgreSQL/Redis e VM/host podem compartilhar recursos físicos: não alegar isolamento de CPU/memória.
- Ainda falta verificar o site custom-FPM efetivamente registrado, a revisão (incluindo alterações locais relevantes), a configuração servida e o isolamento HTTP/recursos. Nenhum site/checkout/container/banco/namespace foi provisionado. O watcher parado precisa de prontidão resolvida antes de depender do provisionamento automático. A tarefa permanece aberta.

### 1.4 — Blocked: seletor de arquitetura antes do download/sonda

- Diagnóstico sem bootstrap: `lerd php -r 'require "vendor/autoload.php"; print json_encode(["php" => PHP_VERSION, "os" => PHP_OS_FAMILY, "machine" => php_uname("m"), "k6_version" => Pest\Stressless\K6::K6_VERSION, "k6_exists" => Pest\Stressless\K6::exists()], JSON_PRETTY_PRINT).PHP_EOL;'` retornou PHP **8.5.11**, **Linux**, **aarch64**, k6 esperado **v2.1.0**, binário ausente.
- `vendor/pestphp/pest-plugin-stressless/src/K6.php:142` usa `str_contains(php_uname('m'), 'arm') ? 'arm64' : 'amd64'`. A expressão foi reproduzida no runtime com `lerd php -r`: `aarch64` seleciona **amd64**, incompatível com a arquitetura nativa ARM64. Não foi testada emulação; não se declara uma falha executada do binário. Download automático não foi acionado.
- Release [k6 v2.1.0](https://api.github.com/repos/grafana/k6/releases/tags/v2.1.0), estável, commit `83a87a41e2c56eedbadbab4001dc11fe78d95942`: arquivo nativo Linux ARM64 `k6-v2.1.0-linux-arm64.tar.gz`, **27.357.876 bytes (~26,1 MiB)**, SHA-256 `191fa8d89512a4e5083f3fabcb4c3828af9f5b9eee016de8443f6473c029ffb5`. O seletor atual escolheria Linux AMD64, **29.777.351 bytes (~28,4 MiB)**. Tamanhos/hashes são metadados upstream, não download/verificação local.
- [Licença k6 da tag v2.1.0](https://raw.githubusercontent.com/grafana/k6/v2.1.0/LICENSE.md): AGPL v3, distinta da licença MIT do plugin.
- Execução de k6, DNS do alvo sintético e confiança CA/HTTPS **não comprovados**. Nenhuma sonda HTTP/carga foi iniciada. Resolver arquitetura por mecanismo aprovado antes de baixar/executar; não renomear binário ARM como AMD nem corrigir vendor.

### 1.5 — Blocked: matriz da API instalada (não é prova de execução)

Fonte imutável: plugin v5.0.2/commit acima; arquivos locais `src/Factory.php`, `src/Run.php`, `src/Result.php`, `src/Session.php` e `bin/run.js`.

| Capacidade | Evidência e estado |
| --- | --- |
| URL/token fixos | API `stress(url)->headers(...)->get()` disponível; `run.js` repete os mesmos valores. Inspecionada, execução Unproven. |
| Múltiplos tokens/URLs numa rodada | Blocked: Factory recebe uma URL e um mapa fixo de headers; não expõe callback/script de seleção por iteração/VU. |
| Cursores dinâmicos | Blocked: `run.js` não captura resposta nem segue links/cursor. Repetição da primeira página não atende o requisito. |
| Concorrência total | `concurrently(C)` configura `vus=C` em um único k6; execução/concorrência observada Unproven pelo bloqueio de runtime. Não foram criados subprocessos por conta. |
| Status/checks/correção | Blocked: script não define checks nem classificação própria de statuses/JSON:API/owner; fração de falhas HTTP não substitui esses contratos. |
| p50/p95 | Summary tipado contém `med` e `p(95)`; presença/valores/unidades na execução Unproven. |
| p99 | Blocked na configuração exposta: não existe opção da Factory para `summaryTrendStats`; possível configuração nativa do k6 por ambiente exige prova, não foi descartada nem considerada aprovada. |
| Exportação/agregação | `toArray()` entrega summary; Run apaga summary/progress após sucesso. Não expõe amostras para agregar múltiplos processos nem prova percentis globais. Blocked para o contrato completo; nenhuma média de percentis foi calculada. |
| Segredos/temporários | Session grava em `vendor/.../bin`, sem diretório privado/permissions próprios; erros do k6 podem incluir dados do alvo. O harness futuro deve comprovar sanitização/lifecycle e não tratar dump bruto como relatório. |

### 1.6 — Blocked: decisão do usuário pendente

- Proposta para decisão, **não aplicada**: autorizar adaptação explícita **Pest + k6 nativo ARM64**, com binário versionado/verificado fora de vendor, scripts k6 próprios e integração por processo público. Manter Pest como runner/assertions; a API Stressless de URL fixa não seria apresentada como motor dos cenários compostos. Atualizar D1/contratos afetados antes de implementar a adaptação.
- A adaptação deverá provar primeiro alvo sintético mínimo, CA/DNS, dois tokens/URLs, cursor retornado pelo alvo, statuses/checks, concorrência total, p50/p95/p99 e exportação válida, com prazos/volume limitados. Os cenários de produto dependentes continuam bloqueados.
- Alternativa: aguardar uma release compatível que atenda arquitetura e capacidades necessárias. Nenhuma atualização de branch dev, fork, patch de vendor ou redução de contrato foi aplicada.

### Verificações desta rodada

- `lerd composer test -- --list-tests --compact`: descoberta funcional concluída com o plugin instalado; nenhuma execução de teste/campanha solicitada. Isso comprova carregamento/descoberta, não comportamento do motor ou aceitação funcional completa.
- Lerd `vendor_run pest --version`: Pest **5.2.1**. Composer validate/platform passaram. Sem mudanças PHP próprias, sem Pint sobre o ExpenseSeeder preexistente.
- Após atualizar os artefatos, OpenSpec strict passou sem issues e `instructions apply` confirmou **2 completas / 49 pendentes**. Whitespace de composer.json/lock e dos quatro Markdown alterados conferido com `git diff --check` e `git diff --no-index --check /dev/null <arquivo>`; sem erros.
- Estado: **2/51 tarefas concluídas**, STEP 01 **Blocked**, demais etapas pendentes. Migrations, massa, PATs e carga de produto não foram executados.

## Apply — STEP 02 — 2026-10-16

- Autorização: “Pode seguir para o step dois”. Autoriza a entrada/organização independente do motor; não resolve a decisão 1.6. Execução de produto permanece Blocked.

### 2.1–2.2 — Proven (entrada e organização; não medição)

- `composer test:load` chama `tests/load.php`; `phpunit.load.xml` descobre exclusivamente Load, sem bootstrap Laravel, env funcional ou cache de resultados. `--list` lista catálogo e `--list-tests` usa a descoberta Pest sem executar callbacks. Seleções usam `--scenario=<id>`, `--endpoint=<path>` e `--objective=capacity|regression`; execução exige cenário e objetivo explícitos, sem pass-through arbitrário de flags Pest.
- Quatro arquivos Load nos contextos Expense/Metrics/Insights sob Presentation/Http, com cenários de entrada deliberadamente bloqueados pelo `LoadEngineGate`, sem skip e sem código HTTP/k6. Implementação do comportamento pertence ao STEP 06. Suporte exclusivo de carga em `tests/Support/Core/Load`, sem mudanças em app, tests/run.php, tests/Pest.php ou phpunit.xml.
- `lerd composer test:load -- --list`: quatro entradas Blocked; `--list-tests --scenario=monthly-insights`: somente o cenário selecionado. `lerd composer validate --strict --no-interaction`: válido.
- `lerd composer test -- tests/Unit/Core/Support/Load/LoadCommandTest.php --compact`: **12 testes / 51 assertions**, passou. Prova seleção, descoberta dedicada, opções inválidas/duplicadas, ausência de eco de segredo sentinela e exit 2/Blocked antes de carregar config/criar manifesto/acionar motor. Revalidação pós-Pint registrada ao fechar a etapa.

### 2.3 — Proven para seleção local e configuração de CI

- O teste `keeps Load outside functional discovery without relying on a skip` executa o launcher funcional padrão com `--list-tests`, driver SQLite/nome operacional e host inválido herdados. A descoberta Unit/Feature passa sem entrar no preflight; não lista Tests\Load nem nomes dos cenários Load. `phpunit.xml`, launcher e associação Feature não foram alterados. Não há skip para esconder Load.
- `lerd composer test -- tests/Unit/Core/Support/Database/TestExecutionCommandTest.php --compact`: **11 testes / 26 assertions**, passou (Unit puro e descoberta Feature, inclusive negativas antes de provisionamento).
- `lerd composer test -- tests/Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php --compact`: **3 testes / 20 assertions**, passou pelo launcher, com migrations incrementais em banco exclusivo. Prova caminho Feature funcional, não prova HTTP de carga.
- CI `.github/workflows/ci.yml` inspecionado: continua chamando `composer test -- --compact` e `composer test -- --parallel --processes=2 ...`, ambos pelo launcher e XML funcional, sem `test:load`. Nenhuma mudança no workflow. Execução no GitHub não foi realizada; a seleção foi provada localmente, não se declara job remoto aprovado.

### 2.4 — Proven para contratos e persistência do manifesto planejado

- `LoadConfiguration` valida URL-base sem credenciais/query/fragment/caminho de endpoint, dataset técnico, perfil e limites explícitos. Leitura limitada a arquivo regular privado, até 64 KiB, por caminho canônico fora do checkout. Campos desconhecidos (incluindo credenciais) e valores inválidos falham sem eco do conteúdo/encadeamento sensível. Contrato e canal reservado `TROCADO_LOAD_CONFIG` documentados em D4; comando bloqueado ainda não consome configuração.
- `LoadManifest` planeja runId/owner independentes e escreve JSON 0600 em diretório externo 0700, sem sobrescrever o mesmo run. Contém seleção, configuração e fase/estado iniciais, com lease/targetVerification null e resources vazio: **não é autorização de recursos ou readiness**. Fases/estados tipados e seus significados definidos em D4; orquestração, credenciais/PATs e ownership efetivo pertencem aos STEPs 03–07.
- `lerd composer test -- tests/Unit/Core/Support/Load/LoadConfigurationTest.php --compact`: **17 testes / 28 assertions**, passou isoladamente antes/depois do Pint (arquivo privado/permissões, URL com segredo, campos/limites inválidos e JSON malformado sem divulgação).
- `lerd composer test -- tests/Unit/Core/Support/Load/LoadManifestTest.php --compact`: **1 teste / 51 assertions**, passou isoladamente antes/depois do Pint (dois manifestos distintos, conteúdo, permissões, recusa de sobrescrita e preservação do primeiro). Temporários de cada teste removidos em finally; não há banco/Redis/servidor nesse teste.

### Gate local do STEP 02

- `lerd composer test -- tests/Unit/Core/Support/Load --compact`: **30 testes / 130 assertions**, passou após Pint. Os três arquivos também passaram isoladamente após Pint; LoadCommand manteve **12 testes / 51 assertions**.
- `lerd composer test -- tests/Unit/Architecture/ContextBoundariesTest.php --compact`: **30 testes / 504 assertions**, passou; nenhuma permissão de app foi ampliada.
- `lerd` vendor_run `pint --dirty --format agent`: passou. `lerd composer test:load -- --list-tests`: quatro entradas Load descobertas sem execução. Composer validate passou.
- Pint também passou com todos os caminhos PHP novos explícitos (incluindo arquivos ainda não rastreados). `lerd composer test:load -- --scenario=expense-pages --objective=capacity` retornou **exit 2 / Blocked**, conforme esperado, sem setup/carga. OpenSpec strict passou sem issues após as atualizações e `git diff --check` passou.
- Este suporte é novo e exclusivo de Load; nenhum suporte compartilhado por cenários funcionais existentes foi alterado. Gate funcional completo com duas seeds/paralelo/duas invocações não foi executado nesta etapa e não é declarado aprovado.
- STEP 02 conclui entrada/organização e contratos iniciais; **6/51 tarefas concluídas**. STEP 01 continua Blocked em 1.3–1.6, sem decisão implícita de adaptação. Nenhum k6/download/sonda HTTP/servidor-alvo/massa/conta/PAT foi iniciado pelo comando Load.

## Continuação — autorização STEP 03 e decisão 1.6

- Pedido explícito: “Segue para o step 3”. Diante da dependência do gate do motor, o usuário selecionou **“Autorizar adaptação (Recommended)”** para Pest + k6 nativo ARM64, fora de vendor, com sondas sintéticas antes do alvo do STEP 03. Tamanho de download (~26,1 MiB) informado antes da decisão.
- **1.6 — Proven:** decisão obtida; não equivale a motor executado/comprovado. D1 e LOAD-02 atualizados antes da adaptação. Evidências históricas de bloqueio acima são preservadas.

### 1.4–1.5 — Proven no alvo sintético da adaptação

- Entrada exclusivamente opt-in: `lerd php tests/probe-load-engine.php --run`. Pest 5 executa `tests/Load/Core/Presentation/Http/EngineProbeLoadTest.php` pelo XML Load; sem opt-in a sonda recusa antes do download. Nenhuma alteração de vendor/API interna Stressless.
- Download oficial k6 v2.1.0 Linux ARM64: tamanho **27.357.876 bytes** e SHA-256 `191fa8d89512a4e5083f3fabcb4c3828af9f5b9eee016de8443f6473c029ffb5` verificados antes de extrair/executar; `k6 version` exige v2.1.0 e linux/arm64. PHP 8.5.11/Linux aarch64, Node v24.18.1, OpenSSL 3.5.8. CA e certificado sintéticos efêmeros com SAN localhost; resolução/HTTPS no loopback do runtime, não ainda DNS/CA do futuro domínio Lerd de produto.
- Rodada positiva: **1 teste / 16 assertions**, passou; **2 VUs**, pico **2** no servidor, **0** ativos ao final; **24 requests** emitidos (23 chegam ao servidor, 1 falha de transporte controlada), **16 amostras válidas**, checks **1,0**. Credenciais A/B distintas, 8 páginas por owner e 4 avanços de cursor por owner, URLs obtidas da resposta.
- Classes separadas com counters/thresholds: exatamente uma ocorrência de **401, 403, 422, 429 (Retry-After), 500, invalid-body, timeout, transport**. Percentis do único Trend global `valid_duration`, sem média de percentis: exemplo p50 **42,834 ms**, p95 **46,594 ms**, p99 **46,615 ms**. Dezesseis amostras apenas comprovam a API/exportação; não calibram desempenho.
- Check sentinela deliberadamente errado: **exit 99**. CA ausente: **exit 99**, `unknown authority` confirmado sem publicar stderr bruto. Processo deliberadamente lento: timeout de 0,5s, encerrado em ~0,626s, filho parado. Entradas, credenciais/certificados/chaves, binário/archive e raw summaries são privados e removidos em finally; só evidência allowlisted é impressa.
- Descoberta inicial importante: misturar falhas/timeout com novas iterações produziu pico servidor **3** para 2 VUs; duas execuções reprovaram essa assertion. O spike foi corrigido separando a prova concorrente de páginas válidas das falhas sequenciais em teardown. Não se aumentou o esperado para ocultar requests remanescentes; provas de recuperação/requests em voo do produto seguem exigidas em 5.7.
- Limites do spike: alvo sintético, um processo de k6, duas identidades fictícias. Não comprova Sanctum/ownership do Trocado, agregação entre múltiplos geradores, perfil de produto ou capacidade VPS. Um processo por rodada é a topologia aprovada; se múltiplos geradores forem introduzidos, nova prova de agregação será necessária.

## Revisão atual — somente carga com Pest/Stressless

### Decisão e retirada de complexidade

- O usuário questionou JS/adaptação e confirmou “Também to achando. Só queria teste de carga”. A primeira versão passa a ser teste simples PHP/Stressless, um token/URL por execução, métricas públicas e preflight, com preparação manual do alvo.
- Foram retirados `NativeK6Runtime`, `LoadEngineProbe`, os dois scripts JS/Node, a entrada/cenário do spike e o lifecycle de manifesto/fases/estados/gate permanente. Nenhum desses arquivos é dependência da versão atual. Os temporários do spike foram removidos pelo seu finally; o k6 oficial instalado em vendor é gerenciado pelo plugin, não um patch.
- `LoadManifestTest` e sua fixture foram retirados com o comportamento fora de escopo, sem alegar equivalência de cobertura. `LoadCommandTest` mantém seleção/descoberta/recusa/segredos, substituindo a assertion do gate permanente pela recusa de configuração ausente. `LoadConfigurationTest` preserva arquivo privado externo/URL sem segredo/JSON inválido e passa a provar limites simples, opt-in, confirmação e redação do token. Validações antigas de dataset/perfis/manifestos não são exigidas nem declaradas cobertas nesta revisão.

### Prova do plugin oficial e preparação manual

- Primeira execução `lerd` vendor_run `pest stress <alvo>/up --duration=1 --concurrency=1`: download do k6 AMD64, seguido de falta de memória PHP 128 MiB durante PharData. Não foi falha comprovada de arquitetura.
- `lerd php -d memory_limit=512M vendor/bin/pest stress <alvo>/up --duration=1 --concurrency=1`: **14 requests, 13,52 RPS, 100% de sucesso**, HTTPS e concorrência 1. Portanto o executável AMD64 selecionado pelo plugin **funciona neste Lerd ARM64**; a análise inicial de bloqueio por arquitetura era insuficiente. Não se afirma execução nativa ou equivalência com gerador externo.
- Alvo criado durante o STEP 03 autorizado: clone Git independente `storage/app/private/trocado-load-8c7621d49e0af3b61d45a027`, revisão `628c93294ba8d82dc7d87e5cb7599768db543454`, vendor próprio instalado pelo lockfile sem scripts. `.lerd.local.yaml`/Containerfile próprios; Lerd site link criou domínio `trocado-load-8c7621d49e0af3b61d45a027.test`, custom-FPM e certificado, sem iniciar workers do alvo. O watcher global estava parado, mas esse provisionamento síncrono ficou servindo.
- Antes da criação, PostgreSQL listado só continha `lerd`, `trocado` e `trocado_testing`. Lerd criou **`trocado_load_8c7621d49e0af3b61d45a027`** e **`trocado_load_8c7621d49e0af3b61d45a027_testing`**; o segundo é auxiliar do Lerd e não foi usado. Serviços PostgreSQL/Redis/VM são preexistentes e compartilhados fisicamente; site/FPM/checkout/config/bancos são novos. Não remover serviços preexistentes como parte desse trabalho.
- `lerd env setup` configurou .env e aplicou overrides do alvo. Prova CLI read-only antes das migrations: **APP_ENV=load-testing**, `current_database()` exatamente o banco dedicado, Redis prefix `trocado-load:8c7621d49e0af3b61d45a027:` e cache prefix exclusivo. O sufixo legado `capacity` do prefixo não amplia cota. Mail array, fila sync, sessão array e Nightwatch desligado no alvo; configurações/cache compilado/logs/storage são do clone.
- Plano de setup conferido; `lerd setup --step "php artisan storage:link" --step "php artisan migrate" --skip-open` executado no clone. Migrations incrementais, sem fresh, seed pessoal, frontend build ou workers.
- Preparação manual mínima depois de conferir novamente ambiente/banco exatos e ausência de contas: **uma conta ativa/verificada, zero despesas**, senha aleatória não exposta e PAT real com validade de uma hora. Configuração 0600 em **`/tmp/trocado-load-8c7621d49e0af3b61d45a027.json` no runtime PHP compartilhado do Lerd**; nenhum token foi impresso. Conta/config/PAT foram preservados para uso manual; expiração e dados não são gerenciados pelo runner. Isto não é dataset de benchmark nem execução do seeder demonstrativo.

### Sondas reais do comando simplificado

Comando: `lerd composer test:load -- --scenario=<id> --config=/tmp/trocado-load-8c7621d49e0af3b61d45a027.json`, sempre **1 concorrente / 1 segundo**, sequencialmente, contra a conta sem despesas. Cada linha tem **1 teste / 2 assertions**. O preflight autenticado está fora das métricas.

| Cenário | Requests | Fração de falhas | p50 ms | p95 ms | Resultado |
| --- | ---: | ---: | ---: | ---: | --- |
| expense-pages | 16 | 0 | 60,39 | 71,70 | Passou |
| expense-metrics | 15 | 0 | 63,46 | 67,25 | Passou |
| monthly-insights | 14 | 0 | 67,13 | 82,72 | Passou |
| expense-suggestions, sequência na mesma janela | 15 | 0,2667 | 64,10 | 74,43 | **Reprovou**, como deveria |
| expense-suggestions, após renovação da janela | 15 | 0 | 65,78 | 76,55 | Passou |

- A falha foi preservada: probe do mesmo alvo/conta confirmou **HTTP 429 com Retry-After=21**. Não houve flush de contadores, remoção de middleware, ampliação de cota ou relaxamento da assertion. O relatório agregado não identifica cada status individualmente; a sonda separada confirma o limiter como condição observada, não taxonomia por request.
- Credencial inválida enviada ao preflight: recusada com o diagnóstico esperado antes de chamar Stressless. Sonda adicional com p95 sentinela **0,001 ms**: **exit 1**, assertion de latência reprovou; a cópia privada da configuração foi removida explicitamente após a sonda. Esse limite artificial não foi mantido na configuração normal nem adotado como SLA.
- Esses números comprovam ferramenta/integração HTTP, não consultas sobre massa representativa, capacidade de usuários, cache frio ou regressão calibrada. Nenhuma prova de VPS/produção foi executada.

### Matriz e verificações atuais

| Requisito | Evidência atual |
| --- | --- |
| LOAD-01 | Quatro arquivos PHP chamam `LoadHttpScenario`, que usa apenas `stress()` público; as quatro leituras tiveram sondas reais. |
| LOAD-02 / ORG-01 / ISO-08 | LoadCommandTest verifica seleção, descoberta dedicada e ausência de Load na descoberta funcional; XML/launcher/CI funcional preservados. |
| LOAD-03 | LoadConfigurationTest verifica arquivo externo/privado, confirmação, URL local sem segredos, JSON/campos inválidos; alvo conferido e preparado manualmente. |
| LOAD-04 | Preflight real 200 nas quatro leituras e Bearer inválido recusado antes do motor; validação de corpo em cada resposta sob carga não é oferecida. |
| LOAD-05 | Limites positivos/max na configuração, um processo selecionado, deadline finito; reprovação real sob cota e 429/Retry-After observado sem mudar produto. |
| LOAD-06 | Resumos das sondas, falha HTTP e p95 sentinela reprovando; p50/p95/RPS/fração extraídos do plugin sem p99/status inventados. Token redigido no encaminhamento de stdout/stderr e testado com sentinela. |

- Após Pint, arquivos isolados pelo launcher: **LoadCommandTest 12 testes/56 assertions** e **LoadConfigurationTest 16 testes/36 assertions**, passaram. Pasta Load Support: **28 testes/92 assertions** na rodada anterior; arquivos depois do formatter mantiveram esses totais.
- Arquitetura: **30 testes/504 assertions**, passou. Launcher funcional TestExecutionCommandTest: **11 testes/26 assertions**, passou, incluindo Unit sem DB e descoberta Feature. O suporte alterado é exclusivo de Load; não foi modificado suporte compartilhado de cenários funcionais existentes. Não se declara gate completo/duas seeds/paralelo funcional executado nesta revisão.
- `pint --dirty --format agent` passou, incluindo execução explícita do novo LoadHttpScenario. Composer validate strict, OpenSpec strict e `git diff --check` passaram. `test:load -- --list-tests` descobriu somente as quatro entradas sem HTTP. Não houve commit, push ou archive.
- Há uma edição do usuário em `bruno/Expense/01 - CRUD/02 - GetAll Expense.bru` surgida durante o trabalho; não foi alterada para esta entrega.
