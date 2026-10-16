## Context

Decisões do usuário: medir regressão e capacidade; começar com as quatro leituras; usar alvo dedicado no Lerd; 20 contas com 10 mil despesas cada; dois perfis de limiter; calibrar antes de aprovar limites; execução manual separada; Pest Stressless/k6 autorizado como dependência dev futura; aquecimento e níveis 1/5/10/20 de 30 segundos. Acrescentou reutilização futura em homologação VPS e separação entre alvo e gerador.

O projeto usa PHP 8.5, Pest 5 e PHPUnit 13. `composer.json` não declara Stressless. `phpunit.xml` descobre apenas Unit/Feature; `tests/Pest.php` associa FeatureTestCase a Feature. O launcher funcional prepara PostgreSQL exclusivo para o processo de teste, sem configurar automaticamente outro servidor HTTP. A cota autenticada atual é 60/minuto por proprietário. Listagem usa cache Redis; projeções podem gravar associações técnicas no Core mesmo em GET.

A edição pré-existente de `ExpenseSeeder` e `README.md` pertence ao pedido anterior de dados demonstrativos. Não é autorização para usá-los no banco operacional como massa de carga.

### Evidência documental do motor — 2026-10-16

Boost/Search Docs de Pest 5 consultado em `stress testing`. Código upstream consultado somente por leitura, sem instalar ou executar:

- [composer.json, linha 5.x](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/composer.json): declara PHP `^8.4`, Pest `^5.0.3`, plugin Pest `^5.0.0`, curl e zip. A linha 4.x exige Pest 4 e não é a escolha para o projeto. Branch upstream não comprova release estável disponível/resolvida.
- [Factory.php](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/src/Factory.php): uma URL, headers fixos, método/payload, duração e concorrência por execução; `run()` produz um Result. Não há seleção dinâmica de token/cursor na superfície examinada.
- [bin/run.js](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/bin/run.js): repete requests com URL e headers fixos; não define checks de JSON:API/status nem tags próprias para os cenários pretendidos.
- [Run.php](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/src/Run.php): inicia subprocesso k6 e lê summary; não comprova por si só isolamento HTTP/DB, prazos de campanha ou métricas por status.
- [Result.php](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/src/Result.php): expõe `toArray()`, mas estatísticas documentadas no tipo incluem med/p90/p95, não garantia de p99 ou distribuição de statuses.
- [K6.php](https://github.com/pestphp/pest-plugin-stressless/blob/5.x/src/K6.php): faz download automático, seleciona SO/arquitetura e executa binário local ao runtime PHP. Compatibilidade com o runtime real do Lerd, rede e CA precisa ser provada; PHP funcionar num container não prova que o binário escolhido funcionará nele.

Essas são evidências para desenhar o spike, não APIs instaladas nem provas executáveis. Fontes por branch são mutáveis; no apply registrar release/commit e versões resolvidas. Não se promete suporte inexistente ao agrupar vários tokens, seguir cursores, produzir p99 ou decompor 429/5xx.

## Goals / Non-Goals

**Goals:**

- LOAD-01–13: medir HTTP real de leituras com isolamento, dados/controladores de carga conhecidos, relatórios e critérios honestos.
- Tornar reproduzíveis regressões dentro do mesmo ambiente e investigar saturação com limites explícitos.
- Reutilizar cenários em homologação sem equiparar latência/capacidade local e remota.

**Non-Goals:**

- Implementar durante a elaboração desta spec; executar carga, criar bancos/contas ou provisionar VPS agora.
- Fixar SLA arbitrário, prometer número de usuários simultâneos do produto ou estimar capacidade de produção pelo Lerd.
- Carga de escrita, exclusão de contas, login/cadastro sob carga, filas/IA/FCM reais, CI automático ou execução em produção nesta primeira versão.
- Refatorar queries/caches/UseCases para obter verde; correções de produto descobertas exigem decisão e escopo próprios.
- Alterar o launcher/guards funcionais para acomodar um servidor externo ou incluir Load como skip padrão.

## Decisions

### D1 — Gate técnico do motor antes do provisionamento e da carga

Instalar a versão dev compatível somente após autorização de apply. Primeiro confirmar resolução estável com Pest 5, binário/arquitetura/runtime, HTTPS/CA e saída pública do plugin. A prova inicial deve usar alvo sintético controlado e volume mínimo, sem tratar a sonda como benchmark do produto.

Depois provar múltiplos tokens, rotação de URLs/cursor, classificação por status, p99 e exportação sanitizada. A API upstream examinada é insuficiente para presumir todos esses recursos. Preferir API suportada da versão instalada; se faltar capacidade, parar o cenário dependente e obter decisão para atualização compatível ou adaptação explícita Pest+k6, com artefatos atualizados. Não usar APIs internas para contornar silenciosamente a limitação, alterar vendor, fazer fork, reduzir tudo a um token ou adotar outra ferramenta por conta própria.

**Alternativa rejeitada:** escrever vinte chamadas sequenciais a `stress()` e apresentá-las como vinte contas concorrentes. Outra alternativa inadequada é iniciar vinte processos com `concurrently(20)`, multiplicando a carga declarada. Subprocessos independentes só são aceitáveis se o spike comprovar coordenação, concorrência total e agregação válida.

### D2 — Organização e comando opt-in

Propor `tests/Load/<Contexto>/Presentation/Http/`, com Expense (listagem/sugestões), Metrics e Insights como owners de cenários. Core possui somente coordenação transversal e cenários de isolamento/limiter. Suporte tipado reutilizável fica em `tests/Support/Core/Load/` e, quando específico, no contexto consumidor, sem classes em `app/` para coordenar carga.

Uma configuração Pest/PHPUnit separada e entrada proposta `lerd composer test:load -- <opções>` selecionam Load explicitamente. O nome final e flags devem ser conferidos/implementados, não presumidos como disponíveis. `composer test`, seus guards e a descoberta Unit/Feature permanecem intactos. Checagens do harness ficam em Unit/Feature conforme suas dependências e podem entrar no gate funcional; a campanha de carga não entra nele.

**Contrato entregue no STEP 02:** `composer test:load -- --list` lista o catálogo sem ler configuração; `--list-tests` usa `phpunit.load.xml` para descoberta Pest. Seleção por `--scenario=<id>`, `--endpoint=<path>` e `--objective=capacity|regression`; iniciar exige cenário e objetivo explícitos. Não há pass-through de opções Pest, credenciais ou URL por argumento. Cada arquivo Load é uma entrada bloqueada, não um cenário de desempenho já implementado: `LoadEngineGate` recusa execução até decisão/provas do STEP 01 e implementação dos STEPs 03–06. `--list` informa Blocked; saída 0 significa descoberta válida, não regressão aprovada. Execução bloqueada usa exit 2, seleção inválida usa exit 1.

A nova raiz de testes é uma exceção pequena e explícita, coberta pelo delta ORG-01 e futura atualização de ARCHITECTURE/README. Não mover testes antigos nem criar hierarquia de produto para esse tooling.

### D3 — Separar control plane, servidor e gerador

O control plane prepara/valida o alvo via Lerd/CLI; o gerador só executa HTTP com tokens e configurações privadas. O servidor dedicado precisa servir a mesma revisão da aplicação com configuração própria e defaults relevantes conhecidos. Não apontar duas entradas nginx para o mesmo checkout/config cache compartilhado e chamar isso de ambiente isolado: o mecanismo deve separar o estado de configuração de cada processo servidor, cache compilado, logs e workers, além da URL.

Na implementação, descobrir os mecanismos suportados pelo Lerd. Usar checkout/runtime dedicados ou alternativa suportada que comprove separação efetiva; não usar `git worktree add` manual, não reescrever `.env` do desenvolvimento, não ligar outro site com banco/cache do site atual e não declarar prontidão pela presença de vendor/node_modules. Conferir também containers compartilhados: banco separado não garante CPU/memória isoladas.

Antes de uma campanha, o operador define limites de request, aquecimento, recuperação, duração total, recursos e interrupção. Alvo desconhecido/produção é recusado. A primeira entrega valida localmente. Remoto permanece parametrizado/documentado; provisionar ou medir uma VPS exige autorização própria e acesso/configuração definidos. Gerador fora da VPS é a topologia preferida; se compartilha recursos, registrar a interferência, não afirmar capacidade isolada.

### D4 — Manifesto de campanha, lease e confirmação do alvo

Manifesto privado com runId, datasetId, revisão, lease, URL exata, identidade da instância/configuração, PostgreSQL efetivo, prefixos Redis separados, logs/temporários e processos próprios. Validar conexão com `current_database()` e ownership antes de qualquer escrita/cleanup. Confirmar no control plane a configuração efetiva do servidor e realizar preflight HTTP com credencial exclusiva criada no banco-alvo, verificando proprietário e resposta esperados. Não criar endpoint público de diagnóstico nem expor dados de configuração por HTTP para isso.

Se não é possível vincular a URL/instância aos recursos autorizados, bloquear a campanha. Lease impede duas campanhas de alterar/limpar o mesmo alvo; uma alternativa é instância própria por campanha. Mudança de configuração/revisão/identidade invalida a lease e exige novo preflight. Control plane remoto deve fornecer confirmação equivalente; acesso HTTP isolado não autoriza drop de banco por nome.

O manifesto distingue recurso criado pelo run de instância preexistente apenas emprestada. Namespaces incluem campanha e perfil; temporários privados fora do repositório. Não incluir credenciais no relatório sanitizado, argumentos do shell ou URLs. A autorização não usa `testing` no nome, regex ampla ou domínio `.test` como prova suficiente.

**Contrato inicial do STEP 02 (sem provisionamento):** `LoadConfiguration::fromFile()` valida JSON v1 em arquivo privado regular (sem permissões de grupo/outros, até 64 KiB), por caminho absoluto canônico fora do checkout. `TROCADO_LOAD_CONFIG` é o canal reservado para esse caminho; enquanto o motor está bloqueado, o comando não lê o arquivo nem cria manifesto. Campos permitidos: `version`, `targetUrl` (base HTTP/HTTPS sem user/password/query/fragment ou caminho de endpoint), `datasetId` técnico, `profile` (`capacity`/`protection`) e `limits`. Não é prova de ambiente autorizado: URL sintaticamente válida continua dependendo do preflight/lease do STEP 03. Tokens e credenciais não fazem parte desse arquivo; seu registro privado será implementado nos STEPs 03–04.

`limits` exige explicitamente `concurrency` (lista sem duplicação de níveis dentre 1/5/10/20), `durationSeconds` (30 no perfil inicial), `warmupSeconds`, `requestTimeoutSeconds`, `processTimeoutSeconds`, `recoveryTimeoutSeconds`, `campaignTimeoutSeconds` e `maxRequests`, todos os valores escalares inteiros positivos. Request termina antes do prazo de processo, processo permite a janela medida, campanha tem prazo maior que o processo. Esses campos delimitam o contrato de configuração, não aprovam dimensionamento operacional: orçamento agregado, recursos e recuperação serão definidos/comprovados em 5.5–5.7. Números das fixtures são exclusivamente entradas de testes, não perfil aprovado.

`LoadManifest::plan()` cria identidade aleatória própria sem I/O; `write()` aloca diretório externo 0700 e JSON 0600 exclusivamente, sem sobrescrever manifesto anterior. Registra versão, runId, owner privado, seleção/objetivo, URL, dataset/perfil/limites e estado inicial. `targetVerification`/`lease` são null e `resources` é vazio até o STEP 03; esse documento planejado não autoriza escrita em banco/Redis, não certifica readiness e não é um relatório público. Credenciais e evidências de alvo/revisão serão vinculadas somente após o preflight efetivo.

Fases definidas: `preflight → preparation → warmup → measurement → recovery` (por nível), encerrando em `cleanup → finished`; erro/interrupção também exige cleanup quando houver recursos registrados. Estados: `Pending`, `Running`, `Blocked` (pré-requisito ausente), `Failed` (falha de contrato ou limite aprovado), `Inconclusive` (medição insuficiente), `Calibration` (medição sem threshold aprovado), `Passed` (regressão equivalente com limites aprovados) e `Aborted`. A orquestração dessas transições pertence às etapas futuras; os enums não comprovam lifecycle/cleanup externo.

### D5 — Massa própria, versionada e criada fora da janela medida

Usar esquema PostgreSQL existente e migrations incrementais sobre banco exclusivo autorizado. Criar 20 contas aptas com senha aleatória não exibida e PATs reais fora do request medido; sem enviar e-mail, usar o login em loop ou credenciais pessoais. Massa total 200 mil, 10 mil por conta, UUIDv7 gerados nas bordas e inserts em lotes com campos explícitos.

Definir versão/seed da massa, data civil/timezone do servidor, distribuição entre mês atual e cinco anteriores, categorias, descrições recorrentes/variadas, empates de sort e períodos/termos vazios de controle. Não copiar valores esperados do algoritmo de produção; validar contagens, ownership, limites e estrutura independentemente. Registrar hash/versão da configuração da massa, não seus valores financeiros. Se a data do servidor atravessa a referência civil durante a campanha, interromper/repreparar de forma explícita, sem misturar meses.

Preparação pode reusar o mesmo dataset da campanha apenas após confirmar contagens e identidade. Estado divergente falha ou requer preparação explícita em banco próprio; nunca completar silenciosamente contas pessoais. Cleanup de campanha considera também associações em `resource_identities`, tokens e outros estados existentes; sem tabela de produto nova ou `migrate:fresh`.

### D6 — Catálogo por endpoint e estado

| Owner / endpoint | Variações mínimas | Estado que deve ser separado |
| --- | --- | --- |
| Expense / GET expenses | páginas 20/100; critérios combinados; sort monetário/alfabético; empates; next/prev com cursor real | página fria/quente, critérios e proprietário |
| Metrics / GET metrics/expenses | total/por categoria; mês elegível/vazio | associação Core ausente/hit; não inventar cache de resultados |
| Insights / GET insights | vigente/encerrado; massa elegível/onboarding válido | associação ausente/hit; seleção editorial não exige texto literal único |
| Expense / GET expenses/suggestions | termo frequente/raro/sem resultado, variações válidas do contrato | associação ausente/hit; limites e agrupamento mantidos |

Parâmetros exatos vêm dos Requests/specs/rotas atuais no apply. Gerar cursores usando a resposta do servidor, sem montar cursor fictício nem fixar só primeira página. A URL e os tokens precisam variar de modo rastreável, não por aleatoriedade sem seed.

Frio significa estado ausente comprovado antes do lote, não todos os requests do lote sendo misses: sob concorrência a primeira consulta pode aquecer as seguintes. Identificar primeira requisição/coorte fria e regime subsequente; separar números quando necessário. Não invalidar cache por request sem declarar outro cenário que inclua o custo artificial. Limpar somente tags/chaves/associações da campanha, fora da medição. Cenário de mesma conta e cenário entre contas não são resultados intercambiáveis.

### D7 — Carga, limiter e recuperação

Modelo inicial fechado, níveis independentes de 30s com concorrência total 1/5/10/20. No cenário entre contas, distribuir até C unidades concorrentes por contas do pool de 20; variação de contas ao longo das iterações tem regra explícita. No cenário de mesma conta, usar o proprietário selecionado e registrar disputa. Não interpretar número de VUs como RPS ou usuários humanos.

Preparação e warm-up fora da janela; antes de escalar confirmar que o gerador anterior encerrou e usar probes de recuperação com prazo finito. Requests pendentes além do prazo ou limites de recurso/saúde violados param a campanha. Regressão avalia perfil aprovado fixo; stress progressivo busca sintomas e registra onde parou. A escolha conservadora inicial não autoriza aumentar níveis ilimitadamente.

Perfil de capacidade: cota positiva ampliada, registrada e efetiva no servidor dedicado. Qualquer 429 marca rodada como limitada pelo limiter. Perfil da proteção: 60/minuto, com nova janela/namespace próprio, duas credenciais da mesma conta para provar compartilhamento e outra conta para independência. O control plane confirma o perfil antes da carga e restaura ao final; não remover middleware, aceitar header do cliente para bypass ou alterar a cota de produção. SignIn público e SignOut preservam os contratos existentes.

### D8 — Métricas e aprovação posterior

Medir p50/p95/p99, total/RPS, duração efetiva, VUs, status codes, erros de transporte, timeout e 429. Diferenciar fração de erros de erros/segundo; não confiar em um nome `rate()` sem verificar unidade. Checks de status/JSON:API/ownership são obrigatórios: latência de um 401/429 não prova velocidade da operação de negócio. Separar população de respostas válidas da população total; registrar insuficiência de amostras.

Percentis globais precisam de amostras/histograma compatível ou agregação suportada do motor. `Result::toArray()` não torna estatisticamente válida a média de percentis nem cria um p99 que não existe. Se a superfície suportada não fornece os dados, registrar Blocked no spike e pedir decisão de desenho, sem preencher zero.

Calibração: pelo menos três repetições por combinação candidata a referência, relatório de variabilidade, proposta de limites por ambiente/endpoint/cenário/estado/perfil. Não aplicar limites universais arbitrários. Calibração pode terminar como tecnicamente válida sem thresholds aprovados, mas isso não é aprovação de regressão; ativação de thresholds exige aprovação explícita posterior e é rastreada separadamente nas tarefas. Infra/credenciais/checks inválidos sempre reprovam. Referências não são sobrescritas após falha de desempenho; mudanças de revisão/massa/configuração identificam equivalência ou nova calibração.

### D9 — Diagnóstico, relatórios e operação

Resumo legível e JSON sanitizado por run/rodada: versões/revisão, dataset/seed/data/timezone, endpoint e filtros por nomes técnicos não sensíveis, perfil/cache/registro, concorrência, duração, métricas, thresholds e classificação do resultado. Inventariar recursos efetivos, PHP-FPM/OPcache e configurações selecionadas de PostgreSQL/Redis sem dump de segredos. Registrar geração de carga local/externa, rede, eventual contenção Podman/host/VPS e presença de debugger/profiler/captura.

Campanha de referência com instrumentação pesada desligada; diagnóstico separado pode usar Lerd route timing, captura de queries e profiler para correlacionar gargalos reais. Não atribuir causalidade a query/CPU sem evidência. Se o gerador satura, resultado é inconclusivo para capacidade do alvo. Não há comparabilidade automática entre Lerd e VPS.

Relatórios sanitizados podem ser retidos localmente por política explícita; raw k6/temporários potencialmente sensíveis não são publicados/commitados. Remover credenciais ao fim e preservar somente evidência permitida. Timeout, ferramenta sem recurso, execução abortada e load não executado são estados visíveis, não skips/verde.

### D10 — Cleanup, rollback e implantação

`finally`/teardown encerra filhos próprios e limpa recursos por manifesto depois de revalidar ownership. Associações gravadas pelos GETs precisam de cleanup no servidor; transação no Pest não as reverte. Expiração/cascades de tokens/contas e limpeza de Redis devem usar nomes exatos e recursos exclusivos. Restaurar perfil/instrumentação alterados e não destruir site preexistente emprestado.

SIGKILL pode impedir cleanup: conservar manifesto privado suficiente para diagnóstico/recovery explícito, sem claim de recuperação automática. Rollback da ferramenta significa interromper campanha, restaurar configuração dedicada e remover somente o que criou; não reverter migrations de produto, apagar dados de desenvolvimento ou modificar outra change. Nenhum deploy/VPS está autorizado por esta proposta.

## Risks / Trade-offs

- [Stressless não atende cenários compostos] → gate técnico obrigatório; bloquear capacidades dependentes e obter decisão antes de adaptação/fallback.
- [URL distinta ainda usa configuração/banco do desenvolvimento] → comprovar instância/configuração, control plane, token exclusivo, banco efetivo e lease antes de preparar/medir.
- [GET grava estado técnico] → manifesto inclui associações Core e cenário separa primeira resolução de hit; cleanup no servidor.
- [Carga mede 429 ou cache aquecido sem perceber] → perfis/estados explícitos, status e população de medição separados.
- [Gerador concorre com alvo ou VPS de produção] → identificar topologia/limites e preferir gerador externo; não executar produção nem presumir isolamento físico.
- [Primeira referência instável] → três repetições, variabilidade/amostras registradas e aprovação posterior de limites, sem comparar ambientes distintos.
- [Alterar testes para esconder gargalo] → preservar cenário/referência; correção de produto exige novo escopo, não relaxamento silencioso de assertions.

## Migration Plan

1. Obter autorização de apply. Conferir versão estável/instalável, executar spike de compatibilidade e decidir limitações antes de provisionar alvo/massa.
2. Implementar entrada opt-in, isolamento/manifesto/leases e recusa de alvos divergentes, sem mudar launcher funcional.
3. Provisionar e comprovar alvo Lerd dedicado, massa e tokens; confirmar perfis do limiter e cleanup.
4. Implementar catálogo/checks/relatórios e executar sondas mínimas antes da campanha progressiva.
5. Executar calibração local com limites de execução definidos; apresentar referências e proposta de thresholds.
6. Após aprovação dos thresholds, ativar regressão e comprovar reprovação controlada. Atualizar arquitetura/README e evidências; não arquivar com tarefas/decisões bloqueantes pendentes.
7. Preparar documentação/configuração para homologação VPS. Prova remota depende de autorização própria; primeira entrega local não declara VPS homologada.

## Open Questions

**Resolvidas pelo usuário:** objetivos, endpoints, isolamento dedicado, 20 × 10 mil, dois perfis, calibração inicial, manual/separado, dependência dev futura, níveis de carga conservadores e reutilização local/VPS.

**Bloqueantes para cenários dependentes no apply:** release compatível realmente disponível e capacidades suportadas para múltiplos tokens/cursor/status/p99; mecanismo Lerd que isola configuração e runtime do alvo. A versão upstream lida não resolve essas provas. Não bloqueiam a elaboração documental; impedem marcar a implementação/medição como pronta antes do spike.

**Decisões posteriores de operação/calibração:** timeouts e critérios de interrupção/recovery dimensionados pelo inventário, limites de regressão aprovados após referência; autorização, topologia e credenciais da homologação VPS. Produção segue fora do escopo.

## Traceability

| Contrato | Decisão | Evidência futura mínima |
| --- | --- | --- |
| LOAD-01 / ORG-01 / ISO-08 | D2 | descoberta funcional sem Load; comando Load isolado; teste avulso |
| LOAD-02 | D1 | resolução de versões, sonda do binário, tokens/cursor/status/p99 e limitações |
| LOAD-03–04 | D3–4 | recusa de URL/config/DB divergentes, lease/ownership, dois runs e topologia registrada |
| LOAD-05–06 | D5 | contagens/UUID/estado/datas e PAT real contra servidor com teste de isolamento A/B |
| LOAD-07 | D6 | matriz por endpoint/estado; cursores reais; correção e dados vazios |
| LOAD-08 | D7 | concorrência total observada, prazos e interrupção/recovery controlados |
| LOAD-09 / cota / contadores | D7 | capacidade com cota efetiva; 60/61 com dois tokens, outra conta e Redis próprio |
| LOAD-10–11 | D8 | métricas verificadas, distribuição/status, três repetições e limites aprovados/reprovação controlada |
| LOAD-12 | D9 | JSON sanitizado, segredo sentinela ausente, referência/diagnóstico e ambientes separados |
| LOAD-13 | D10 | falha/interrupção com cleanup exato, filhos encerrados e recovery por manifesto |

Estado na elaboração: todos os cenários de implementação **Unproven**; leituras documentais não são prova de execução. O apply local do STEP 01 foi autorizado em 2026-10-16: instalação compatível v5.0.2 comprovada, mas runtime/capacidades compostas **Blocked**, com decisão de adaptação pendente. Evidências e matriz da API instalada em `tasks.md`; D1 não foi substituída por uma adaptação ainda não aprovada.

Na continuação autorizada pelo STEP 02, entrada/descoberta, isolamento da seleção funcional e contratos de configuração/manifesto planejado foram comprovados. Isso não altera o estado Blocked do motor nem comprova cenários de desempenho ou ownership de recursos externos. Estado corrente: 6/51 tarefas concluídas; matriz e comandos em `tasks.md`.
