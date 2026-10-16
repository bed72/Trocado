## 1. Autorizar apply e comprovar o motor

- [x] 1.1 Obter autorização explícita de implementação e sondas/carga local; reconferir artefatos, versões e decisões sem interpretar a criação da spec como apply. [LOAD-01–02]
- [x] 1.2 Resolver release estável compatível de Stressless/Pest 5 e requisitos PHP/extensões; registrar versões/commit consultado e confirmar instalação dev/lockfile sem rebaixar Pest ou elevar requisito PHP sem decisão. [LOAD-02; D1]
- [ ] 1.3 Conferir a topologia Lerd suportada para servidor dedicado com configuração/cache compilado/logs/DB/Redis separados; registrar a escolha antes de provisionar. [LOAD-03–04; D3]
- [ ] 1.4 Conferir runtime do gerador, download/tamanho/licença do k6, arquitetura/SO, execução, DNS e CA/HTTPS com sonda mínima controlada; não incluir setup/download na medição. [LOAD-02–03]
- [ ] 1.5 Provar no motor APIs suportadas para múltiplos tokens/URLs, cursores dinâmicos, concorrência total, status/checks, p50/p95/p99 e exportação/agregação; registrar cada capacidade suportada ou Blocked. [LOAD-02/06–10]
- [ ] 1.6 Se houver limitação, obter decisão explícita de adaptação/versão antes de alterar design ou implementar cenários dependentes; não modificar vendor nem declarar cobertura reduzida como equivalente. [LOAD-02; D1]

## 2. Entrada manual e organização

- [x] 2.1 Criar entrada opt-in `test:load` e configuração dedicada, confirmando opções e seleção avulsa de cenário/endpoint/objetivo, sem executar carga durante descoberta. [LOAD-01; ORG-01; ISO-08]
- [x] 2.2 Organizar cenários Load por contexto/Presentation/Http e suporte tipado por responsabilidade em Tests Support; manter tooling fora de app e preservar Unit/Feature existentes. [ORG-01; D2]
- [x] 2.3 Provar que `composer test`, listagem, Unit/Feature e CI padrão não descobrem/iniciam/provisionam Load e não ganham skips para escondê-lo. [LOAD-01; ISO-08]
- [x] 2.4 Definir manifesto privado, fases de campanha, estados de resultado e configuração de URL/perfil/dataset/limites, sem segredos em argumentos ou relatórios. [LOAD-03–04/12]

## 3. Alvo dedicado e ownership

- [ ] 3.1 Provisionar somente o alvo Lerd autorizado pela ferramenta suportada, registrando recursos criados versus preexistentes e prontidão efetiva. [LOAD-03–04; D3]
- [ ] 3.2 Implementar preflight de URL/instância/configuração/revisão, PostgreSQL efetivo por `current_database()` e confirmação HTTP com credencial exclusiva do banco-alvo; recusar produção/alvo desconhecido. [LOAD-03–04/06]
- [ ] 3.3 Implementar ownership exato e lease por campanha, com nomes/namespace/processos/temporários próprios e migração incremental somente no banco autorizado. [LOAD-04]
- [ ] 3.4 Provar negativas de URL/config/DB divergentes, nome parecido, manifesto ausente/alterado e tentativa de usar o banco operacional, antes de qualquer escrita/cleanup/carga. [LOAD-03–04]
- [ ] 3.5 Provar duas invocações simultâneas: recursos distintos ou segunda lease recusada, sem interferência de preparação, medição e cleanup. [LOAD-04]

## 4. Massa e credenciais próprias

- [ ] 4.1 Definir versão/seed da massa, referência civil/timezone, distribuição de meses/categorias/descrições/empates e controles vazios por endpoint; registrar critérios independentemente dos algoritmos de produção. [LOAD-05/07]
- [ ] 4.2 Preparar 20 contas ativas/verificadas, PATs reais e 200 mil despesas (10 mil por owner), UUIDv7/inserts em lotes e sem seed pessoal, login em loop, e-mail ou IA reais. [LOAD-05–06]
- [ ] 4.3 Provar contagens, UUIDs, ownership, datas/distribuição, reuso consistente e recusa de dataset divergente ou referência civil alterada, sem duplicação. [LOAD-05]
- [ ] 4.4 Provar token só no gerador rejeitado, PATs válidos no servidor, troca A/B com dados distinguíveis e nenhuma resposta alheia, preservando middleware/autorização. [LOAD-06]
- [ ] 4.5 Registrar e proteger credenciais/temporários por campanha; provar que exports e diagnósticos não carregam tokens, senhas, Authorization/Cookie ou fatos financeiros. [LOAD-12]

## 5. Perfis de cota e carga

- [ ] 5.1 Implementar configuração mínima da cota positiva ampliada exclusivamente no alvo dedicado não produtivo, com default 60 preservado, sem bypass por header nem remoção de middleware. [LOAD-09; cota]
- [ ] 5.2 Implementar namespaces Redis próprios por perfil e confirmação/restauração da configuração efetiva no servidor, sem contadores herdados ou fallback local. [LOAD-09; contadores]
- [ ] 5.3 Provar cota original compartilhada entre rotas/dois tokens, 60 admitidas/61ª 429 JSON:API com Retry-After, outra conta independente e renovação da janela. [LOAD-09; cota]
- [ ] 5.4 Provar recusa de ampliação fora do alvo autorizado, manutenção de 60 em desenvolvimento/produção sem perfil e falha explícita se Redis indisponível. [cota; contadores]
- [ ] 5.5 Definir antes da campanha timeouts por request/processo, aquecimento, prazo/checagem de recuperação, limite total e critérios de interrupção conforme recursos inventariados. [LOAD-08; D7]
- [ ] 5.6 Implementar níveis 1/5/10/20 por 30s, distribuição entre contas e cenário da mesma conta; comprovar concorrência total sem multiplicação por subprocessos. [LOAD-08]
- [ ] 5.7 Provar encerramento limitado do gerador, recuperação entre níveis e parada por alvo não recuperado, timeout ou limites de recursos, sem escalada ilimitada. [LOAD-08/13]

## 6. Catálogo de cenários e correção

- [ ] 6.1 Implementar listagem: páginas 20/100, filtros combinados, sort monetário/alfabético/empates, navegação next/prev com cursores reais e preflight JSON:API. [LOAD-06–07]
- [ ] 6.2 Implementar métricas: total/agrupado por categoria, mês elegível/vazio, primeira resolução/hit Core e checks coerentes de população. [LOAD-06–07]
- [ ] 6.3 Implementar insights: vigente/encerrado, resultado elegível/onboarding válido, primeira resolução/hit e assertions que não exijam uma variante editorial incidental. [LOAD-06–07]
- [ ] 6.4 Implementar sugestões: termo frequente/raro/sem resultado e variações válidas, com agrupamento/limites e primeira resolução/hit identificados. [LOAD-06–07]
- [ ] 6.5 Provar preparação de cache frio/quente e registro ausente/hit fora da medição; distinguir primeira coorte e regime já aquecido sem limpeza artificial por request. [LOAD-07]
- [ ] 6.6 Provar que 401/403/422, 429, 5xx, timeout e corpo inválido são classificados e não viram sucesso de negócio por responderem rápido. [LOAD-06/09–10]

## 7. Métricas, relatórios e cleanup

- [ ] 7.1 Implementar coleta p50/p95/p99, total/RPS, duração efetiva, concorrência observada/configurada, statuses e falhas com unidades/populações explícitas, conforme capacidades provadas do motor. [LOAD-10]
- [ ] 7.2 Provar agregação de amostras/estatísticas e estratos sem média de percentis; métrica indisponível/amostragem insuficiente/gerador saturado deve resultar inconclusivo ou Blocked. [LOAD-02/10]
- [ ] 7.3 Implementar relatório legível e JSON sanitizado com revisão, dataset/perfil, alvo/gerador, recursos/versões/config selecionada, cota/cache/registro e instrumentação; definir retenção. [LOAD-12]
- [ ] 7.4 Provar sanitização por campos permitidos e segredos sentinela, incluindo erro do motor, processos, URLs e temporários; não exportar dumps brutos nem descrições/valores financeiros. [LOAD-12]
- [ ] 7.5 Implementar finally/teardown: encerrar filhos próprios, revalidar ownership, revogar tokens, limpar banco/associações/Redis/temporários registrados e restaurar perfil/instrumentação. [LOAD-13]
- [ ] 7.6 Provar cleanup após erro/assertion/interrupção tratável, preservação de recurso preexistente/relatórios e recusa de remover recursos de outro run; documentar recovery por manifesto para SIGKILL. [LOAD-04/13]

## 8. Calibração e regressão

- [ ] 8.1 Validar sondas mínimas dos quatro endpoints no alvo dedicado antes de aumentar carga; registrar correção e prontidão, sem chamar sonda de benchmark completo. [LOAD-01/06]
- [ ] 8.2 Executar campanha local conservadora com ao menos três repetições por combinação candidata à referência, separando estados e níveis; registrar amostras/variabilidade e todas as falhas/interrupções. [LOAD-07–11]
- [ ] 8.3 Executar diagnóstico separado dos gargalos observados por tráfego real/Lerd, correlacionando queries/CPU e distinguindo rodadas instrumentadas das referências sem instrumentação pesada. [LOAD-12]
- [ ] 8.4 Apresentar referência e proposta de thresholds por ambiente/endpoint/cenário/perfil/estado; obter aprovação explícita antes de limites bloqueantes. [LOAD-11]
- [ ] 8.5 Ativar limites aprovados e provar reprovação controlada, referência preservada, recusa de comparação não equivalente e estado de calibração sem aprovação fictícia. [LOAD-10–11]
- [ ] 8.6 Registrar achados de capacidade e restrições do gerador/ambiente; correções de produto descobertas fora deste escopo devem obter decisão antes de alterar código ou esperado. [LOAD-08/10–12]

## 9. Documentação e fechamento

- [ ] 9.1 Atualizar ARCHITECTURE/README existentes para Load opt-in, comando, massa, ownership, relatórios, perfis e execução local/remota; manter Unit/Feature e launcher funcional íntegros. [ORG-01; ISO-08; D2]
- [ ] 9.2 Documentar parâmetros/topologia de homologação VPS, gerador externo preferido, referências distintas e recusa de produção; deixar execução/provisionamento remoto condicionado a autorização própria, sem alegar medição VPS nesta entrega local. [LOAD-03/11–12]
- [ ] 9.3 Executar verificações do harness isoladas e suítes funcionais afetadas/arquitetura pelo launcher; se suporte compartilhado mudar, executar os gates completos padrão, duas seeds e paralelo com pelo menos dois processos sem excluir integrações existentes. [ISO-08; arquitetura de testes]
- [ ] 9.4 Executar Pint após mudanças PHP e reverificar arquivos alterados; validar OpenSpec estritamente e conferir diff/ausência de segredos/resíduos próprios. [LOAD-12–13]
- [ ] 9.5 Preencher matriz por requisito/cenário com evidência, comando/versões/ambiente/resultados e estados Proven/Partially proven/Unproven/Blocked, incluindo limitações do plugin e operações remotas não exercitadas. [LOAD-01–13; deltas]
- [ ] 9.6 Resolver bloqueios técnicos e aprovação de thresholds antes de declarar implementação concluída/arquivável; archive, commit, push e operações VPS exigem autorização própria. [LOAD-02/03/11]

## Dependências e estado da elaboração

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
