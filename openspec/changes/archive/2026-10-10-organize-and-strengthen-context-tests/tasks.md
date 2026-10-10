## 0. Atualizar a spec antes dos próximos pedaços

- [x] 0.1 Alinhar proposal, design, BEH-17 e tarefas à entrega arquivada de Metrics, distinguindo diagnóstico original, última execução documentada e pendências aceitas; validar os artefatos estritamente, sem executar a aplicação.

## Decisão de encerramento — 2026-10-10

Após a atualização de ARCHITECTURE.md, README.md e AGENTS.md com o padrão de testes, o usuário solicitou explicitamente arquivar esta change, commitar todas as alterações e enviar ao remoto. O arquivamento registra essa decisão de encerramento com as pendências documentadas; não declara implementação integral nem converte evidência parcial/ausente em prova.

As tarefas desmarcadas e a matriz P/PP/U abaixo permanecem preservadas, incluindo lacunas de inventário, reorganização e contratos comportamentais. Os últimos gates registrados passaram com 811 testes e 5.096 assertions em ordem padrão, duas seeds e paralelo com dois processos; não houve nova execução da aplicação na rodada de documentação/arquivamento. A sincronização das specs consolida o padrão normativo, sem afirmar que todos os testes existentes já o atendem.

As conclusões anteriores sobre ausência de autorização para arquivar são evidências históricas das respectivas etapas e ficam superadas por este pedido explícito. O encerramento não marca 11.7/11.10 como concluídas, pois seus critérios integrais de evidência continuam não atendidos.

## 1. Autorizar e estabelecer a baseline de implementação

- [x] 1.1 Confirmar o escopo do próximo pedaço autorizado de apply para testes/configuração/scripts de suporte; correção de produção descoberta por teste exige decisão posterior. Usuário autorizou guard, preflight, migrations incrementais e execução isolada, com testes desse suporte.
- [x] 1.2 Reconsultar versões/commands/docs Laravel/Pest/PHPUnit, instruções de arquitetura, conexão/schema e permissões de provisionamento pelo ambiente Lerd; confirmar ordem dos hooks parallel antes de escrever bootstrap. [ISO-01/04]
- [ ] 1.3 Inventariar todos os arquivos/cenários existentes e recursos persistentes usados; registrar cenário, objetivo, camada, contexto, dependências e destino planejado na matriz de migração. [ORG-01/07]
- [ ] 1.4 Inventariar os cenários entregues de Metrics Domain/Application, Adapter PostgreSQL e HTTP/composição à luz da spec consolidada e do arquivo de 2026-10-10; registrar destinos e limitações aceitas sem reimplementar produto ou alterar o histórico. [BEH-17]
- [ ] 1.5 Revisar divergências históricas já identificadas contra arquitetura atual e registrar o contrato adotado para cada prova; perguntar uma dúvida por vez se surgir divergência funcional sem decisão inequívoca. [BEH-18]

## 2. Preparar execução e guard seguro de teste

- [x] 2.1 Definir runId compartilhado pelo entrypoint e filhos, base PostgreSQL exclusiva e registro exato de destinos autorizados, com encaminhamento de argumentos do runner nativo. [ISO-01/04]
- [x] 2.2 Implementar validação inicial de driver/URL/config e validação read-only do banco efetivo antes de migrations, fixtures, cleanup ou drop, preservando recusa de banco operacional. [ISO-01]
- [x] 2.3 Adicionar testes negativos do guard para driver SQLite, banco operacional, DB_URL conflitante, nome parecido não autorizado e conexão efetiva divergente, usando doubles/destinos seguros; comprovar que a ação destrutiva não é chamada. [ISO-01]
- [x] 2.4 Implementar provisionamento idempotente somente de bancos autorizados e preparação incremental de migrations existentes, com diagnóstico de pré-requisito ausente; não usar migrate:fresh. [ISO-02]
- [x] 2.5 Definir comandos canônicos para Unit, arquitetura, Feature por contexto, integrações e paralelo; garantir que execução avulsa também usa preflight ou falha antes de dados parciais. Comandos e pré-requisitos completos em README; integração/paralelo comprovados com 10.5/10.9. [ISO-02/08]
- [x] 2.6 Executar as primeiras verificações Feature somente após guard/schema seguros; registrar baseline atual sem confundir os resultados históricos desta spec com nova execução. [ISO-09]

## 3. Corrigir a falha editorial conhecida antes da reorganização ampla

- [x] 3.1 Reconferir a dependência editorial de IDs no estado atual e, se ainda presente, substituir a assertion de frase incidental em ExpenseAnalysisAdapterTest por prova do significado/contrato que aceite todas as variantes válidas, preservando catálogo de produção. Se já corrigida, registrar a evidência sem refactor redundante. [BEH-13]
- [x] 3.2 Acrescentar dataset de IDs positivos explícitos que alcance todas as variantes relevantes e manter assertions focadas do catálogo/composição independentes de sequência PostgreSQL. [BEH-13]
- [x] 3.3 Executar o cenário editorial sozinho, o arquivo e os testes focados de composição; verificar diferentes estados de sequência sem resetá-la para forçar uma mensagem. Registrar o resultado. [ISO-06/09]

## 4. Estabelecer Support e mover cenários por responsabilidade

- [x] 4.1 Criar somente a estrutura Support necessária, autoloadável por Tests, e retirar helpers de negócio globais de Pest.php. Confirmar que descoberta de Unit não conecta serviços. [ORG-03/08]
- [x] 4.2 Extrair stub autenticado de Core e spy de observabilidade quando reutilização justificar; manter argumentos/expectativas específicas visíveis nos testes. [ORG-03/04]
- [x] 4.3 Implementar fake observável de TransactionPort com escopo ativo, registro/ordem de callbacks, confirmação e descarte por tentativa abortada; provar seus limites sem simular rollback de banco. [BEH-01/02]
- [x] 4.4 Separar fixtures de contas pending/unverified, active/verified e blocked, tokens reais e helpers de jornada HTTP; remover fake/ativação/verificação ocultos do helper de cadastro. [ORG-05]
- [ ] 4.5 Extrair o Repository double substancial do cache de Expense e migrar mocks de contratos próprios de Mockery para PHPUnit/spy, sem remover a dependência do framework. [ORG-03/04]
- [ ] 4.6 Consolidar builders de candidatos/resumos/projeções de Insights em Support, mantendo dados negativos possíveis e cálculos esperados independentes do SUT. [ORG-06]
- [ ] 4.7 Extrair fixtures de Metrics e eliminar helper que recebe e devolve os mesmos mocks em tupla; construir UseCase explicitamente e manter expectativas por cenário. [ORG-05/06]
- [ ] 4.8 Dividir EmailVerificationTest por cadastro/link/reenvio/perfil/Repository/notification/worker e SlidingSanctumSessionTest por HTTP/adapter/concorrência/pruning, registrando cada destino. [ORG-01/02/07]
- [ ] 4.9 Dividir ExpenseClassificationTest por HTTP/provider/queue/categorização/cache/jornada e ExpenseOwnershipTest por transporte/persistência; mover Insights Feature para camadas correspondentes. [ORG-01/02/07]
- [ ] 4.10 Localizar observabilidade transversal em Core e intenção de eventos em Identity/Expense; avaliar destinos das provas reflexivas de contratos sem exigir ordem incidental de Reflection. [ORG-01/02, BEH-16/18]
- [ ] 4.11 Consolidar casos sobrepostos de Core e mover invariantes de Domain hoje em testes de Application de Insights; comprovar por matriz a preservação dos casos relevantes. [ORG-07, BEH-15]
- [ ] 4.12 Executar cada arquivo movido/alterado isoladamente antes de marcar sua migração concluída e registrar a correspondência antiga/nova, inclusive duplicações justificadamente consolidadas. [ORG-02/07]

## 5. Fortalecer provas de Core e callbacks

- [x] 5.1 Cobrir UserAdapter id inteiro e status string/BackedEnum, principal ausente/status inválido e uso exclusivo de Sanctum, sem bootstrap desnecessário. [BEH-15]
- [x] 5.2 Verificar presença e execução pós-commit de eventos/solicitação de e-mail em SignUp e ausência em falha, incluindo chamada de Repository dentro da unidade observada. [BEH-01/02]
- [ ] 5.3 Verificar eventos/argumentos de atualização/exclusão de Expense, exclusão de User e classificação efetiva, e ausência em resultados recusados. [BEH-02]
- [x] 5.4 Provar TransactionAdapter real para commit/resultado/falha, afterCommit externo, retry e descarte de callbacks abortados com PostgreSQL, preservando cenários já existentes úteis. [BEH-01/02]
- [ ] 5.5 Substituir catches permissivos nos cenários de rollback por exceção sentinela com verificação de causa e escrita anterior; repetir os testes afetados. [BEH-01]
- [x] 5.6 Cobrir formatter/adapter/correlação de requests e worker/CLI com assertions estruturais de JSON e campos sensíveis; incluir ID/timestamp com dígitos coincidentes com amount. [BEH-16] Concluída após correção do contexto HTTP herdado na hidratação do worker e gate padrão verde; evidência abaixo.
- [x] 5.7 Tornar falha de destino de log determinística com recurso controlado, comprovando preservação da escrita confirmada sem depender de caminho absoluto incidental. [BEH-16]

## 6. Fechar lacunas de Identity

- [x] 6.1 Cobrir cadastro HTTP completo: pending/unverified, canonicalização, hash, ausência de token/segredos, Location e type/ID/relacionamento. [BEH-03]
- [x] 6.2 Cobrir confirmação divergente, senha nos limites e inválida por caracteres/bytes, nome/e-mail inválidos, type/atributos extras, pointers e ausência de persistência/notification. [BEH-03]
- [x] 6.3 Cobrir preservação de senha com espaços usando hash e login real, sem normalização implícita da fixture. [BEH-03/04]
- [x] 6.4 Cobrir login real com e-mail equivalente, dois tokens distintos, resposta segura e erros uniformes para credenciais inválidas/usuário ausente/hash não autenticável, sem emissão indevida. [BEH-04]
- [x] 6.5 Preservar e completar recusa pending/blocked/unverified, Bearer real e SignOut após remoção da verificação, além de revogação seletiva. [BEH-04]
- [ ] 6.6 Cobrir mapping de EloquentUserRepository, ausentes e atualização somente de nome com status/e-mail/verificação/tokens preservados. [BEH-06]
- [ ] 6.7 Cobrir GET/PATCH/DELETE próprio/alheio/ausente/sem principal nos níveis apropriados e GET/POST públicos de users com 404 JSON:API. [BEH-05]
- [ ] 6.8 Cobrir exclusão real com dois tokens/duas despesas e dados de terceiro preservados; provar falha sentinela após remoção de tokens com rollback integral. [BEH-05]
- [ ] 6.9 Cobrir conflito sequencial e constraint atingida após precheck com corrida de duas conexões/processos sincronizados, exatamente uma conta e ausência de efeitos da tentativa perdida. [BEH-06, ISO-07]
- [ ] 6.10 Preservar verificação assinada, idempotência, rollback/evento, reenvio uniforme e notification/worker com retry, mudança de endereço e exclusão de principal, nos novos destinos. [ORG-07, BEH-04]
- [ ] 6.11 Preservar política temporal/limites e prova concorrente de extensão/revogação/expiração da sessão, distinguindo adapter, HTTP e pruning. [ORG-07, ISO-07]

## 7. Fechar lacunas de rate limiting

- [ ] 7.1 Cobrir SignIn 5/minuto IP/e-mail canônico, 30/minuto IP, e-mails alternados e IP independente, com 429/Retry-After e ausência de token. [BEH-07]
- [ ] 7.2 Preservar SignUp padrão 3/hora e override; completar contagem de sucesso/erro/conflito admitidos e independência de SignIn/reenvio. [BEH-07]
- [ ] 7.3 Preservar/completar reenvio 2/hora combinação e 5/hora IP, equivalência canônica e respostas sem enumeração. [BEH-07]
- [ ] 7.4 Cobrir 60/minuto por User com alternância de tokens/IPs/rotas Identity/Expense, erros admitidos e conta distinta não bloqueada; provar que endpoint recusado não executa ação. [BEH-07]
- [ ] 7.5 Cobrir SignOut após cota autenticada esgotada e reabertura de janelas com relógio controlado, sem sleeps longos. [BEH-07]
- [ ] 7.6 Provar contador Redis compartilhado por clientes/processos e cache geral independente no namespace de teste, além de falha controlada sem fallback local, sem parar serviço operacional. [BEH-07, ISO-05]

## 8. Fechar lacunas de Expense

- [ ] 8.1 Cobrir GetExpenseUseCase/GetAllExpenseUseCase com IDs/proprietário/parâmetros explícitos e falhas de identidade, sem declarar prova de SQL a partir de mocks. [BEH-08/09]
- [ ] 8.2 Cobrir GET individual próprio/atual, alheio/ausente/excluído, sem token e ID não numérico, com contrato JSON:API e bypass do cache de páginas. [BEH-08]
- [ ] 8.3 Criar paginação PostgreSQL com sete registros/datas repetidas e size 2, validando sequência completa next/prev e links nas bordas. [BEH-09]
- [ ] 8.4 Cobrir default 20 com mais de vinte registros, limites 1/100, conta vazia, preservação de size e cursor reapresentado por outra conta sem vazamento. [BEH-09]
- [ ] 8.5 Cobrir matriz de page.size/page.cursor inválidos, estrutura/direção/ID/data/limite de tamanho e user_id proibido, com 422 e ausência de leitura/fallback. [BEH-09]
- [ ] 8.6 Cobrir criação/edição HTTP com valores/categorias/data/descrição válidos e inválidos, limite Unicode 64, timezone/default/nulidade e PATCH omissão versus null. [BEH-10]
- [ ] 8.7 Provar mapping/ownership/FK/cascade no Repository real, inclusive tradução de proprietário ausente, sem relações Eloquent entre contextos. [BEH-10]
- [ ] 8.8 Cobrir round-trip integral de cache, ambos os cursores/timestamps, miss/hit, chave por conta/size/cursor e passagem direta de getById. [BEH-11]
- [ ] 8.9 Cobrir TTL t0/antes/depois de 60 segundos com relógio controlado e reload após expiração, sem usar waits reais. [BEH-11]
- [ ] 8.10 Cobrir invalidação de todas as páginas por create/update/delete/classificação confirmados e preservação de terceiro/ausente/recusado/begin/find/cancel. [BEH-11]
- [ ] 8.11 Preservar e fortalecer rollback externo/savepoint com dados reais e callbacks descartados; distinguir o double de cache da prova de persistência revertida. [BEH-01/11]
- [ ] 8.12 Provar cache/invalidação Redis entre clientes independentes no namespace exclusivo de teste. [BEH-11, ISO-05]
- [ ] 8.13 Preservar classificação pós-commit, ausência de provider no HTTP, falhas/sync/expiração/repetição/edição/exclusão; declarar corretamente handle/failed manual versus worker real. [BEH-12]
- [ ] 8.14 Provar escrita condicional real frente a categoria/descrição/token alterados por outro processo depois da leitura e cancelamento antigo sem apagar tentativa nova. [BEH-12, ISO-07]
- [ ] 8.15 Executar worker real com payload serializado/fila exclusiva/bindings atuais e IA fake; verificar destino efetivo e ausência de consumo por worker local. [BEH-12, ISO-05]

## 9. Preservar e fortalecer Insights Metrics e arquitetura

- [ ] 9.1 Preservar projeção Insights owner/occurred_on, histórico/futuro, meses curtos/bissextos, precisão e desempates sem escrita, removendo dependência incidental do nome da CTE no monitor de leitura. [BEH-14]
- [ ] 9.2 Preservar thresholds exatos, comparação material, seleção sem redundância/limite seis e onboarding; atualizar datasets/builders sem perda de casos negativos. [BEH-14, ORG-06/07]
- [ ] 9.3 Preservar catálogo/composição completo, Unicode, labels, alternativas/falhas, ciclo/estabilidade diária e identidade por conta/assunto/período com esperados independentes. [BEH-13]
- [ ] 9.4 Preservar HTTP Insights incluindo query rejeitada, ausência de análise em bloqueios, media type/envelope, referência timezone, sessão/throttle e falha sem onboarding fabricado. [BEH-14]
- [ ] 9.5 Preservar Metrics Domain/Application: enum, encaminhamento único, null versus vazio, catálogo/ordem, grandes valores, reconciliação/percentuais/IDs e falhas de identidade/leitura/projeção. [BEH-17]
- [ ] 9.6 Verificar arquitetura atual, Data imutáveis/pureza e permissões pontuais de Core, avaliando reflexão por propósito; não ampliar allowlists para acomodar testes. [BEH-18]
- [ ] 9.7 Atualizar referências correntes afetadas se caminhos de Metrics mudarem, registrando o mapa a partir dos caminhos históricos sem editar evidências/checklists de archive/2026-10-10-add-expense-metrics. [BEH-17, ORG-07]
- [ ] 9.8 Preservar Metrics Adapter PostgreSQL: proprietário/período/occurred_on, categorias/ordenação numérica, limites/grandes somas, reconciliação por statement único, leitura sem escrita e atualização após commits sem cache; não declarar corrida durante leitura. [BEH-17]
- [ ] 9.9 Preservar Metrics HTTP/composição: query textual original/duplicatas/encoding, 422 sem leitura, default/timezone/períodos, identidade, singularidade/omissões/precisão JSON:API, bloqueios/erros seguros e binding; classificar cada prova no destino adequado. [BEH-17, ORG-01/02]

## 10. Completar isolamento e paralelismo obrigatório

- [x] 10.1 Substituir limpeza restrita a três tabelas por política explícita de todos os recursos usados, respeitando FKs/migrations/metadata e suportando commits reais; incluir jobs/failed_jobs quando necessários. [ISO-03]
- [x] 10.2 Registrar cleanup de filas/chaves/cache por cenário/execução/processo em finally/teardown, com IDs/namespaces únicos e sem FLUSHALL/FLUSHDB. [ISO-05]
- [x] 10.3 Isolar caminhos temporários de logs e restaurar relógio/timezone, guards, listeners/fakes/bindings, canais e query logs, com provas de execução reordenada. [ISO-06]
- [x] 10.4 Implementar protocolo reutilizável estreito de concorrência se necessário, com conexão nova no filho, sinais, erro explícito, timeout, rollback, sockets fechados e espera/encerramento limitado. [ISO-07]
- [x] 10.5 Configurar parallel testing nativo para dois ou mais processos, com bancos exclusivos e guard do destino efetivo antes da preparação/limpeza. [ISO-04]
- [x] 10.6 Provar isolamento entre processos com fixtures de e-mail/IDs coincidentes, recurso sentinela por banco/namespace e limpeza que não atinge o outro destino. [ISO-04/05]
- [x] 10.7 Provar duas invocações concorrentes com tokens de processo iguais e runIds diferentes, verificando bancos/Redis/filas/logs exclusivos e conclusão independente. [ISO-04]
- [x] 10.8 Provocar falha controlada após criação de job/chave/processo e verificar cleanup completo, zero transações abertas e ausência de filhos/recursos abandonados. [ISO-03/05/07]
- [x] 10.9 Documentar seleção de grupos e pré-requisitos em orientação existente, com comando canônico que inclui Redis/concorrência no gate; skip local não conta como prova. [ISO-02/08]

## 11. Executar o gate e registrar evidências reais

- [x] 11.1 Executar arquivos afetados isolados e suítes focadas Unit/Feature de Core, Identity, Expense, Insights e Metrics implementado; registrar comandos, resultados e skips. [ISO-09] Reconfirmado no passo 7, com 37 arquivos avulsos e os cinco contextos; resultados abaixo.
- [x] 11.2 Executar arquitetura e verificar preservação da matriz de app, autoload de Support e ausência de bootstrap de serviços nos unitários puros. [ORG-08, BEH-18] Arquitetura inalterada, 26/311; launcher 11/26 inclui subprocessos com destinos deliberadamente inválidos.
- [x] 11.3 Executar Laravel Pint via tooling Lerd com `--dirty --format agent` após a última mudança PHP e repetir testes afetados pelo formatter. [ISO-09]
- [x] 11.4 Executar suíte completa na ordem padrão e em duas seeds aleatórias registradas, incluindo 20261009 e outra seed distinta, com todos os grupos obrigatórios. [ISO-09]
- [x] 11.5 Executar gate completo com pelo menos dois processos e o cenário de duas invocações simultâneas; registrar número de processos, grupos e identidade segura dos recursos. [ISO-04/09]
- [x] 11.6 Confirmar bootstrap de banco vazio/pending migration e falhas seguras do guard no nível apropriado, sem recriar banco operacional ou usar migrate:fresh. [ISO-01/02] Preflight 3/20, guard 15/50 e launcher 11/26 reconfirmados isoladamente no passo 7.
- [ ] 11.7 Finalizar o mapa de cenários antigos e a matriz abaixo com cenário/dataset, caminho, comando, resultado e limitação; justificar consolidações sem meta fixa de quantidade. [ORG-07, BEH-18] Parcial: matriz de todos os Scenarios revisada no passo 7; inventário/migrações ainda abertos em 1.3–1.5 e 4.5–4.12 impedem concluir o mapa final.
- [x] 11.8 Investigar qualquer falha aleatória/paralela/isolada e manter requisito/tarefa pendente se blocked; perguntar antes de corrigir produção, sem alterar contrato para fazer teste passar. [ISO-09] Nenhuma falha de teste nas execuções do passo 7; lacunas de evidência permanecem abertas, sem relaxamento de assertions.
- [x] 11.9 Validar esta mudança OpenSpec estritamente e revisar consistência de todos os artefatos; aplicar o quality gate de código somente no apply autorizado, sem confundir artefatos completos com entrega implementada. [ISO-09] Validação estrita passou; avaliação final distingue gate executável verde de aceite integral bloqueado pelas tarefas pendentes.
- [ ] 11.10 Apresentar evidências finais, limitações e alterações de comandos; sincronizar/arquivar somente mediante solicitação, com todos os cenários obrigatórios comprovados e sem skips inesperados. Relatório do passo 7 apresentado; condição de todos os cenários comprovados ainda não atendida.

## Matriz de rastreabilidade planejada

### Evidência da etapa 0.1 — 2026-10-10

- Fonte: decisão de encerramento e evidências por camada em `archive/2026-10-10-add-expense-metrics/tasks.md`, contrato consolidado `expense-metrics` e arquitetura atual. Paths dos três arquivos de Metrics confirmados para planejar destinos.
- Baseline documental: 725 testes/4.588 assertions na última execução registrada; 627/3.450 e falhas aleatórias/isoladas preservados como diagnóstico anterior. Nenhuma execução da aplicação nesta etapa.
- Proposal, design, BEH-17 e tarefas incluem Metrics Infrastructure/HTTP já entregues e distinguem as limitações históricas aceitas. Tarefas 9.8/9.9 tornam explícita a preservação dessas provas.
- `openspec validate organize-and-strengthen-context-tests --type change --strict --json --no-interactive`: passou, sem issues. `git diff --check`: passou.
- Somente 0.1 concluída; inventário completo, refactor e verificações da aplicação aguardam os próximos pedaços.

### Evidência da etapa 2 — execução segura sequencial, 2026-10-10

- Ambiente: PHP 8.5, Laravel 13.34.0, Pest 5.2.1 e PHPUnit 13.3.4. Lerd e binaries descobertos; schema consultado pelo Boost. Consulta read-only de `pg_roles` confirmou `postgres` com permissão de criação de bancos. `migrate:status --no-interaction` não encontrou migrations operacionais pendentes; nenhuma migration operacional foi executada.
- APIs conferidas por Boost e código instalado: `TestCase::createApplication`, `RunsInParallel`, `TestDatabases` e handler paralelo de Pest. O runner Laravel resolve `Tests\CreatesApplication` antes de `callSetUpProcessCallbacks`; recriação/drop nativos não devem acontecer antes de guard/ownership. A resolução paralela foi bloqueada temporariamente até 10.5.
- Implementação: `tests/Support/Core/Database/{TestDatabaseRun,TestDatabaseGuard,TestDatabasePreflight}.php`, `tests/run.php`, guards em `TestCase`/`FeatureTestCase` e bloqueio paralelo em `tests/CreatesApplication.php`. Manifesto privado e comentário PostgreSQL autorizam o nome exato; preparação/cleanup nunca usam wildcard. Composer, README e CI existente usam o launcher; o workflow remoto não foi executado nesta etapa.
- `lerd composer test -- tests/Unit/Core/Support/Database --compact`: **22 testes, 68 assertions, passando**, após Pint, **779 ms**. `TestDatabaseGuardTest.php` cobre configuração/driver/URL/nome/schema/routing, destino efetivo/ownership divergentes, identidade inválida e ação destrutiva não alcançada. `TestExecutionCommandTest.php` exercita recusas do launcher, Unit sem serviços e descoberta Feature sem provisionamento/migrations.
- `lerd composer test -- tests/Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php --compact`: **3 testes, 20 assertions, passando**, após Pint, **1.075 ms**. Banco inicialmente vazio; primeira migration aplicada sozinha; fixture persistida antes das restantes; schema completo e reaplicação sem perda da fixture nem nova linha de migrations. Reuso/ownership e recusa de migrate/drop em destino divergente comprovados. O reuser não remove banco criado por outro preparador.
- Arquivo isolado de produto: `lerd composer test -- tests/Feature/Metrics/Infrastructure/Adapters/ExpenseMetricsAdapterTest.php --compact`: **15 testes, 52 assertions, passando**, **503 ms**, com banco/schema preparados pelo launcher.
- Baseline focada após Pint: `lerd composer test -- tests/Feature/Metrics tests/Unit/Metrics tests/Unit/Architecture --compact`: **161 testes, 1.539 assertions, passando**, **7.870 ms**, sem skips reportados. É uma baseline focada, não nova execução completa nem gate aleatório/paralelo.
- Recusa esperada: `vendor_run pest tests/Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php --compact` retornou erro de preflight ausente, **zero assertions**, antes de app/cleanup/fixtures. `vendor_run pest <mesmo arquivo> --parallel --processes=2 --compact` foi recusado na resolução da aplicação, antes dos hooks de banco; isso não comprova paralelismo.
- `vendor_run pint --dirty --format agent`: passou (ajuste de estilo no guard), seguido das verificações acima. `lerd composer validate --no-check-publish`: passou. `git diff --check`: passou. `openspec validate organize-and-strengthen-context-tests --type change --strict --json --no-interactive`: passou, sem issues.
- Consulta read-only após as verificações não encontrou bancos `trocado_testing_<runId>` remanescentes. Essa observação confirma cleanup normal das execuções realizadas, não cleanup sob encerramento abrupto ou recursos Redis/filas/logs.
- Limites: 2.5 permanece parcial; 10.x e o gate completo permanecem pendentes. Não houve reclassificação de testes de negócio, alteração de código de produto ou claim de isolamento completo entre recursos externos.

### Evidência da etapa 3 — reconfirmação editorial de Insights, 2026-10-10

- Reprodução anterior ao ajuste: `lerd composer test -- tests/Feature/Insights/ExpenseAnalysisAdapterTest.php --filter="generates candidates from the real analytical projection" --compact` falhou isoladamente: **1 teste, 7 assertions**, **209 ms**, na assertion de `dois meses anteriores`. O catálogo aprovado contém esse trecho em somente uma das quatro variantes de liderança recorrente.
- Correção de 3.1: o mesmo cenário conserva projeção SQL, candidatos e seleção, e verifica grupo Comparison, categoria food, período completo, ausência de ratio/comparisonPeriod e par título/descrição válido no catálogo. Não exige uma frase incidental. Dataset: contas explícitas 1/2/3/4/15/1500 e contas geradas após zero/sete/trinta e uma contas removidas, sem reset/restart/setval de sequência.
- Prova inicial de 3.1: o comando isolado acima passou com **9 testes, 165 assertions**, **458 ms**.
- Prova de 3.2: `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php --filter="preserves all approved recurring leadership messages" --compact` passou com **6 testes, 198 assertions**, **24 ms**. Cada ID positivo explícito percorre quatro datas fixas, visita todas as quatro variantes e mantém estabilidade diária/limites Unicode/placeholders. O esperado é o conjunto literal dos pares aprovados, não uma cópia do hash nem resultado calculado pelo catálogo sob teste.
- Após `vendor_run pint --dirty --format agent` (somente ordem de imports ajustada no arquivo Feature), o cenário isolado repetido passou com **9 testes, 165 assertions**, **425 ms**; o arquivo inteiro (`lerd composer test -- tests/Feature/Insights/ExpenseAnalysisAdapterTest.php --compact`) passou com **16 testes, 223 assertions**, **625 ms**.
- Composição e rotação focadas: `lerd composer test -- tests/Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php tests/Unit/Insights/Application/UseCases/SelectInsightMessageVariantUseCaseTest.php --compact`: **48 testes, 1.057 assertions, passando**, **41 ms**. Preserva os casos existentes de catálogo completo, ciclo/estabilidade, Unicode, labels e fallback/falha explícitos, além da nova regressão.
- Reordenação do arquivo Feature: `lerd composer test -- tests/Feature/Insights/ExpenseAnalysisAdapterTest.php --order-by=random --random-order-seed=20261009 --compact`: **16 testes, 223 assertions, passando**, **585 ms**. Mesmo comando com seed **20261010**: **16 testes, 223 assertions, passando**, **581 ms**. Os casos com sequência naturalmente avançada permanecem válidos em ambas as ordens; nenhuma sequência é resetada para selecionar uma mensagem.
- Contexto afetado: `lerd composer test -- tests/Unit/Insights tests/Feature/Insights --compact`: **238 testes, 1.895 assertions, passando**, **1.640 ms**, sem skips reportados.
- Rastreabilidade: o cenário original `ExpenseAnalysisAdapterTest::generates candidates from the real analytical projection` permanece no mesmo arquivo, desdobrado em nove datasets nomeados, conservando a projeção/candidatos/seleção e substituindo somente o oráculo editorial inválido. A nova prova `ComposeInsightMessageUseCaseTest::preserves all approved recurring leadership messages across explicit positive accounts` tem seis datasets e percorre quatro variantes por conta.
- `git diff --exit-code -- app/Insights`: passou; catálogo e código de produto preservados. As seeds acima comprovam o arquivo afetado, não o gate aleatório/paralelo completo de 11.x. Tarefas 3.1–3.3 concluídas; reorganização de Insights em 4.x/9.x permanece pendente.
- Validação OpenSpec estrita e `git diff --check`: passaram. Consulta read-only após as execuções não encontrou bancos temporários remanescentes.

### Evidência da etapa 4 — suporte compartilhado de Core e Identity, 2026-10-10

- Escopo autorizado: 4.1–4.4, incluindo migração dos sete arquivos que chamavam os helpers globais e verificações do suporte. Não inclui reorganização de arquivos por camada, extração de builders de Insights/Metrics ou migração completa de Mockery, que continuam nas tarefas seguintes.
- `tests/Pest.php` conserva somente `pest()->extend(FeatureTestCase::class)->in('Feature')`. Não há definições/chamadas restantes de `signUpIdentityByApi`/`signInIdentityByApi` em `tests/`.
- Suporte puro: `tests/Support/Core/Stubs/UserPortStub.php`, `Spies/ObservabilityPortSpy.php` e `Fakes/TransactionPortFake.php`. Stub retorna identidade/status explícitos sem Models; spy registra argumentos sem filtrar efeitos; fake observa escopo, resultados/falhas, ordem/registro/liberação de callbacks e descarte da tentativa abortada. Não reverte Repository em memória, não repete operações e recusa nested/savepoints simulados. Falha de callback não reclassifica uma operação confirmada como rollback.
- Reutilização real: `SignUpUseCaseTest`, `DeleteUserUseCaseTest` e `UpdateUserUseCaseTest`. Expectativas de Repository e EmailVerificationPort ficam nos cenários; `never` de TransactionPort continua como mock local quando esse é o oráculo. Cadastro/exclusão observam Repository dentro da unidade e efeitos somente após liberação explícita; callbacks e metadados não ficam escondidos em uma factory de mocks.
- Suporte Feature: `tests/Support/Identity/Fixtures/IdentityFixture.php` exige status e timestamp de verificação (ou null), não cria tokens automaticamente e oferece token Sanctum real com expiração explícita. `Helpers/IdentityHttpJourney.php` executa cadastro, link assinado de confirmação e login HTTP sem escolher fakes ou ativar/verificar contas por escrita oculta. O teste/setup escolhe `Notification::fake()`; login esquece guards antes de resolver as credenciais.

#### Mapa de migração do suporte e preservação de cenários

| Origem/chamadores | Destino/preparação explícita | Evidência isolada |
| --- | --- | --- |
| `Pest.php::signUpIdentityByApi` em Expense ownership/classificação e Insights/Metrics HTTP | `IdentityFixture::create(status: Active, verifiedAt: ...)` e `IdentityFixture::token(..., expiresAt: ...)`; nenhuma dependência incidental de cadastro/login. | Arquivos abaixo preservam todos os cenários/datasets de produto. |
| `Pest.php::signUpIdentityByApi` em sessão e perfil/verificação de Identity | Fixture explícita de conta apta; `IdentityHttpJourney::signIn` mantém provider/hasher/emissão reais onde são o alvo. | `SlidingSanctumSessionTest.php` e `EmailVerificationTest.php`. |
| Jornada de eventos de `ExpenseObservabilityTest.php` | Cadastro e confirmação HTTP por `IdentityHttpJourney`; fake de notification e ativação são operações visíveis no próprio cenário. Os demais cenários usam fixture + login real para os eventos pertinentes. | Mesmo arquivo, sem remover suas assertions de eventos. |
| Callback pass-through e mocks sem expectativa de Core nos três UseCases de Identity | Fake de transação, spy de observabilidade e stub de identidade; quotas/argumentos de mocks específicos preservados junto aos cenários. | Arquivos Unit existentes permanecem no mesmo destino, com oráculos de escopo/efeitos fortalecidos. |

Todos os arquivos Feature migrados foram executados individualmente com `lerd composer test -- <arquivo> --compact`, antes de Pint; Pint não alterou esses arquivos nesta etapa. Resultados:

| Arquivo | Testes / assertions | Duração |
| --- | --- | --- |
| `tests/Feature/Expense/ExpenseOwnershipTest.php` | 5 / 25, passando | 429 ms |
| `tests/Feature/Expense/ExpenseObservabilityTest.php` | 3 / 68, passando | 433 ms |
| `tests/Feature/Expense/ExpenseClassificationTest.php` | 26 / 156, passando | 1.137 ms |
| `tests/Feature/Identity/SlidingSanctumSessionTest.php` | 13 / 166, passando | 1.016 ms |
| `tests/Feature/Identity/EmailVerificationTest.php` | 22 / 158, passando | 942 ms |
| `tests/Feature/Insights/InsightsApiTest.php` | 24 / 174, passando | 942 ms |
| `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php` | 81 / 754, passando | 2.379 ms |

- Novas provas: `tests/Unit/Core/Support/TransactionPortFakeTest.php` comprova callbacks ordenados, aborto/descarte, efeitos confirmados preservados diante de aborto posterior, falha externa sem rollback/replay, execução externa imediata, recusa de liberação precoce/nesting e doubles sem framework. `TestExecutionCommandTest.php` acrescenta execução de Core doubles/Identity Application em subprocessos com driver/URL/host deliberadamente inválidos e sem manifesto: unitários passam sem tocar serviços. A descoberta continua sem fixtures globais.
- `IdentityFixtureTest.php` cobre todos os três statuses com e sem verificação, preservação exata da senha, ausência de tokens/notifications automáticos, fake escolhido pelo chamador, Bearer real e jornada de cadastro/confirmação que permanece pending até ativação explícita. A primeira prova de expiração detectou comparação de microssegundos com coluna PostgreSQL de precisão em segundos; o cenário foi corrigido com relógio e expiração fixos, sem normalização no produto/fixture.
- Após Pint: `lerd composer test -- tests/Unit/Core/Support tests/Unit/Identity/Application/UseCases --compact`: **48 testes, 193 assertions, passando**, **1.408 ms**, incluindo os subprocessos sem serviços. `lerd composer test -- tests/Feature/Identity/Infrastructure/Fixtures/IdentityFixtureTest.php --compact`: **8 testes, 55 assertions, passando**, **452 ms**.
- `vendor_run pint --dirty --format agent`: passou. Após o formatter, `lerd composer test -- --compact`: **780 testes, 4.594 assertions, todos passando**, **14.253 ms**, incluindo arquitetura, os sete arquivos migrados, callbacks PostgreSQL, Redis/worker e concorrência de sessão existentes; nenhum skip reportado. É uma execução completa padrão, não conclusão do gate aleatório/paralelo de 11.x.
- Contagens de assertions HTTP de preparação diminuíram porque cadastro/login deixaram de ser pré-requisitos incidentais dos demais contextos. Os cenários/datasets de produto permanecem; as jornadas/contratos próprios de Identity continuam sendo exercitados diretamente. Não usar essa variação como percentual de cobertura.
- `git diff --exit-code -- app`: passou. Nenhum código de produto, catálogo, binding ou allowlist arquitetural foi alterado. Tarefas 4.1–4.4 concluídas; demais tarefas de suporte/reorganização e o isolamento externo completo permanecem pendentes.
- Validação OpenSpec estrita e `git diff --check`: passaram. A consulta read-only final não encontrou bancos temporários remanescentes.

Cada linha cobre **todos os cenários do requisito identificado**. No apply, desdobrar em uma linha por Scenario/dataset com caminho final e comando efetivo, preservando esta correspondência. A tabela abaixo é o mapa planejado; as seções das etapas 2/3/4 registram provas já executadas de execução segura, regressão editorial e suporte compartilhado, sem concluir os requisitos que dependem da reorganização restante e do gate paralelo/completo. Resultados da revisão e do encerramento de Metrics são históricos e não marcam tarefas de teste como concluídas. A tarefa 0.1 é documental e tem validação própria.

| Requisito | Tarefas | Evidência preferida |
| --- | --- | --- |
| ORG-01 | 1.3–1.4, 4.8–4.10, 9.9 | Inventário/destinos e execução por caminho/contexto. |
| ORG-02 | 4.8–4.10, 4.12, 9.9 | Arquivos coesos e execução independente. |
| ORG-03 | 4.1–4.5 | Classes Support tipadas/autoloadáveis, doubles fora dos cenários substanciais. |
| ORG-04 | 4.2, 4.5, 5.2–5.3 | Expectativas locais e fakes nativos preservados. |
| ORG-05 | 4.4, 4.7, 6.1 | Fixtures explícitas e jornadas reais sem mutação oculta. |
| ORG-06 | 4.6–4.7, 9.2, 9.5 | Builders válidos/negativos e esperados independentes. |
| ORG-07 | 1.3–1.4, 4.8–4.12, 9.7, 11.7 | Mapa de cada cenário antigo/destino/consolidação. |
| ORG-08 | 4.1, 11.2 | Autoload/discovery Unit sem serviços e arquitetura atual. |
| BEH-01 | 4.3, 5.2, 5.4–5.5, 8.11 | Ordem/escopo observados e rollback real com sentinela. |
| BEH-02 | 4.3, 5.2–5.4 | Unit de callbacks/intenção e Feature do mecanismo real. |
| BEH-03 | 6.1–6.3 | HTTP JSON:API, persistência/hash e ausência de efeitos inválidos. |
| BEH-04 | 6.3–6.5, 6.10–6.11 | Provider/Sanctum reais, falhas equivalentes e sessão/logout. |
| BEH-05 | 6.7–6.8 | Ownership Unit/HTTP e exclusão/rollback PostgreSQL. |
| BEH-06 | 6.6, 6.9 | Mapping/constraint e corrida sincronizada após precheck. |
| BEH-07 | 7.1–7.6 | Limites/janelas HTTP e Redis compartilhado com falha controlada. |
| BEH-08 | 8.1–8.2 | UseCase e GET individual real sem cache de página. |
| BEH-09 | 8.1, 8.3–8.5 | Cursores reais next/prev, ordem/isolamento e matriz 422. |
| BEH-10 | 8.6–8.7 | HTTP/defaults/PATCH e FK/mapping/cascade reais. |
| BEH-11 | 8.8–8.12 | Cache array/TTL/rollback e Redis entre clientes. |
| BEH-12 | 8.13–8.15 | Jornadas e persistência/worker/corrida reais com IA fake. |
| BEH-13 | 3.1–3.3, 9.3 | Variantes completas, integração independente de ID incidental. |
| BEH-14 | 9.1–9.4 | Unit de regras/seleção e integração analítica/HTTP. |
| BEH-15 | 4.11, 5.1 | Unit de Core completo e status/id do principal. |
| BEH-16 | 4.10, 5.6–5.7 | Assertions estruturais JSON, contexto/restauração e log com falha controlada. |
| BEH-17 | 1.4, 4.7, 9.5, 9.7–9.9 | Domain/Application, Adapter PostgreSQL e HTTP/composição entregues preservados; limitações históricas explícitas, sem claims de corrida não executada. |
| BEH-18 | 1.5, 4.10, 9.6, 11.2, 11.7 | Arquitetura/revisão e classificação honesta da evidência. |
| ISO-01 | 2.1–2.3, 10.5, 11.6 | Guards antes de alteração e testes negativos sem tocar produto. |
| ISO-02 | 2.4–2.5, 10.9, 11.6 | Bootstrap incremental/avulso/empty/pending em banco autorizado. |
| ISO-03 | 10.1, 10.8 | Cleanup de todas as tabelas/recursos usados em sucesso/falha. |
| ISO-04 | 2.1, 10.5–10.7, 11.5 | Bancos exclusivos, dois processos e duas invocações simultâneas. |
| ISO-05 | 7.6, 8.12, 8.15, 10.2, 10.6, 10.8 | Redis/cache/queue names exclusivos e cleanup scoped. |
| ISO-06 | 3.3, 10.3, 11.4 | Restauração de globals e seeds registradas. |
| ISO-07 | 6.9, 6.11, 8.14, 10.4, 10.8 | Protocolos, bloqueio observado, timeout e cleanup de filhos. |
| ISO-08 | 2.5, 10.9, 11.1 | Seletores/grupos documentados e gate incluindo integrações. |
| ISO-09 | 2.6, 11.1–11.10 | Arquivos isolados, padrão/duas seeds/paralelo, Pint e evidências. |
| PostgreSQL: Testes de persistência isolados | 2.1–2.5, 10.5–10.7, 11.6 | Destino efetivo, guard, migrations e isolamento por execução/processo. |

## Critérios de conclusão da fase de especificação

- Proposal possui uma delta spec para cada capability declarada.
- Requisitos são normativos e todos têm cenários concretos WHEN/THEN.
- Design incorpora paralelismo obrigatório e distingue prova de mock, mecanismo real e corrida ativa.
- A delta PostgreSQL inclui o requisito completo e preserva proteção operacional existente.
- A atualização documental 0.1 só é concluída após validação; tarefas de testes/configuração/scripts permanecem pendentes até os próximos pedaços autorizados e verificados.
- `openspec validate organize-and-strengthen-context-tests --type change --strict --json --no-interactive` passa.
- Nenhum código/teste/configuração de execução da aplicação foi alterado ou executado por esta fase de spec.

## Critérios de conclusão da implementação futura

- Cada cenário antigo tem destino/evidência ou consolidação justificada sem perda relevante.
- Cada Scenario desta mudança tem evidência no nível adequado, comando e resultado; grupos gerados por datasets permanecem identificáveis.
- Arquivos afetados executam sozinhos; Unit puro não depende de serviços; todos os contextos e arquitetura passam.
- Suíte completa padrão, duas seeds e paralelo com pelo menos dois processos passam, incluindo integrações Redis/concorrência obrigatórias.
- Duas invocações simultâneas não interferem, e falha controlada não deixa recursos que alterem a próxima execução.
- Guard interrompe destinos inválidos antes de alteração; schema é preparado incrementalmente e somente em destinos autorizados.
- Não há skips/incomplete/risky inesperados nos cenários obrigatórios nem relaxamento de assertions para ocultar falha.
- Pint, referências/documentação existente e validação OpenSpec concluídos após as últimas mudanças.
- Nenhuma funcionalidade de produto foi implementada sem autorização; Metrics entregue está preservado e suas limitações históricas, divergências e bloqueios permanecem explícitos.
- Relatório não afirma coverage percentual, escala ou concorrência não medida e distingue esta entrega das evidências históricas.

## Evidência da migração por contexto — Core e início de Identity, 2026-10-10

O usuário autorizou o passo «Migrar por contexto», em rodadas Core/Identity/Expense/Insights/Metrics. Esta seção registra somente o trabalho executado; as tarefas detalhadas 5.x não equivalem à conclusão dos cinco contextos.

### Rodada Core

- PHP 8.5, Laravel 13.34.0, Pest 5.2.1 e PHPUnit 13.3.4 reconfirmados; tooling Lerd descoberto. Docs de transações/HTTP/hashing e código instalado conferidos. Launcher/preflight preservados; schema preparado incrementalmente nos bancos autorizados, sem migration de produto.
- UserAdapter conserva id inteiro e rejeição de null/string; acrescenta status string/enum string e rejeição de principal ausente, status null/int/bool/array/enum int. Exige exatamente uma resolução de Sanctum em cada caso. GenericUser inicialmente sem chave causou warning do double; substituído por status null explícito, sem mascarar warning.
- TransactionAdapter tem prova PostgreSQL de escrita dentro da unidade, resultado, ordem dos callbacks depois do commit, sentinela após escrita demonstrada, rollback, callback externo imediato e liberação nested no commit externo. Retry é **falha de concorrência injetada**, não deadlock natural entre processos; comprova rollback da primeira escrita e descarte do callback abortado. A mensagem injetada usa `deadlock detected`, reconhecida pelo detector instalado; uma mensagem arbitrária inicialmente não provocou retry e foi corrigida no teste.
- ObservabilityLogFixture usa arquivo temporário exclusivo, leitura JSON e descarte de canais no teardown. A falha controlada tenta abrir um filho desse arquivo regular existente, sem depender de pasta absoluta ou permissão de root. Assertions estruturais permitem IDs 1500 e timestamp com 001500 enquanto verificam ausência de campos/valores sensíveis.

### Mapa dos cenários movidos/consolidados

Paths abaixo relativos a `tests/`; cenários não listados mantêm seus destinos/assertions. Toda execução isolada usa `lerd composer test -- <destino> --compact`.

| Origem / cenário ou dataset | Destino e preservação | Prova isolada |
| --- | --- | --- |
| `Unit/Core/Domain/ValueObjects/AmountArithmeticTest::keeps sums differences and comparisons exact above native integer limits` | `AmountValueObjectTest`, mesmo cenário, acrescenta imutabilidade. | 30 testes / 49 assertions, 25 ms. |
| Mesmo arquivo, `rejects noncanonical noninteger or negative amounts`, oito entradas | União em `AmountValueObjectTest::rejects malformed or noncanonical monetary values`; casos duplicados consolidados e 1.5/01/espaços externos/literal barra-n preservados além de newline real/NUL. | Mesmo arquivo isolado. |
| Mesmo arquivo, `evaluates thresholds before rounding and rounds only on request` | `AmountShareTest`, mesmas assertions. | 7 / 10, 20 ms. |
| Mesmo arquivo, `rounds half up without overflowing large percentages`, cinco entradas | `AmountShareTest`, todos os datasets preservados, inclusive percentual acima de inteiro nativo. | Mesmo arquivo isolado. |
| Mesmo arquivo, `rejects zero denominators` | `AmountShareTest`, preserva API Amount::shareOf; Ratio::fromAmounts/fromShare continuam em seus próprios arquivos. | Mesmo arquivo isolado. |
| `DatePeriodValueObjectTest::rejects impossible and noncanonical dates at either endpoint`, 12 datas × dois endpoints | União no parser de `DatePeriodCalendarTest`, que exerce ambos os endpoints e monthContaining para cada data. Datas exclusivas preservadas: tomorrow, padding, timestamp/whitespace de 2026-10-12. | Arquivo final: 50 / 227, 30 ms. |
| `DatePeriodValueObjectTest::rejects an end date before the start` | `DatePeriodCalendarTest::rejects an inverted interval instead of swapping endpoints`, mesma regra/exceção/mensagem. | Mesmo arquivo isolado. |
| `DatePeriodCalendarTest::compares periods by both endpoints` | `DatePeriodValueObjectTest::compares periods by both endpoints rather than their duration`, mantendo igualdade, diferenças de início/fim, simetria/reflexividade e igual duração em outro mês. | 31 / 67, 24 ms. |
| Outros cenários dos seis arquivos Core Domain | Mesmo destino/assertions: precisão/half-up, razão versus participação, limites civis/inclusividade, timezone/DST, duração, mês completo/anterior. Nenhum cenário Ratio removido. | Suíte Core abaixo. |
| `Feature/Expense/ExpenseObservabilityTest::writes correlated events for confirmed mutations and queue outcomes`, parcela de eventos de negócio | `Feature/Expense/Journeys/ExpenseMutationObservabilityTest::wires confirmed identity and expense mutations to correlated business events`; cadastro/confirmação/login/mutações/logout reais preservados, assertions estruturais. | 2 / 71, 382 ms. |
| Mesmo cenário, parcelas queue outcomes e outside.http | `Feature/Core/Infrastructure/Providers/QueueObservabilityTest` e `Feature/Core/Presentation/Http/Middleware/RequestCorrelationTest`; metadados/erro preservados, recusa de processed para failed/released acrescentada; dois requests autenticados, público e emissão CLI posterior sem contexto residual. | 3 / 53, 252 ms; 1 / 55, 240 ms. |
| `ExpenseObservabilityTest::does not emit on rollback or invalid input` | `ExpenseMutationObservabilityTest`, mesmo cenário, agora prova escrita anterior, identidade da sentinela, rollback/evento ausente/zero transações. | Arquivo isolado acima. |
| `ExpenseObservabilityTest::keeps a confirmed creation successful when the log destination fails` | `Feature/Core/Infrastructure/Adapters/ObservabilityAdapterTest`, destino controlado, 201 e valores persistidos. | 1 / 4, 260 ms. |
| Nova prova pura de formatter | `Unit/Core/Infrastructure/Adapters/Observability/ObservabilityJsonFormatterTest`, JSON exato/newline/ID 1500/timestamp 001500/campos sensíveis ausentes. | 1 / 7, 20 ms. |
| `Feature/Identity/EmailVerificationTest::requires both active status and a verified email before issuing a token` | `Feature/Identity/Presentation/Http/SignInHttpTest`, mesmo nome; estado explícito e autenticação real preservados. | Arquivo executado, resultado parcial abaixo. |
| `EmailVerificationTest::rejects an existing token on protected routes after verification is cleared` | `SignInHttpTest::rejects an existing token on protected routes after verification is cleared but allows selective sign-out`; duas rotas recusadas preservadas; logout e outro token sobrevivente acrescentados. | Arquivo executado, resultado parcial abaixo. |

### Gate executado e bloqueio

- Todos os arquivos Core novos/alterados e a jornada movida foram executados isoladamente. UserAdapterTest final: **11 / 44**, **32 ms**, sem warnings. TransactionAdapterTest final: **4 / 29**, **262 ms**. TestExecutionCommandTest final: **11 / 26**, **1.955 ms**; novos subprocessos Core Domain/Infrastructure passam com driver/URL/host inválidos, sem bootstrap de serviços.
- `vendor_run pint --dirty --format agent` passou após a última alteração PHP. Depois de Pint: `lerd composer test -- tests/Unit/Core tests/Feature/Core tests/Feature/Expense/Journeys/ExpenseMutationObservabilityTest.php tests/Unit/Architecture --compact`: **236 testes / 1.143 assertions, passando**, **7.705 ms**, sem skips/warnings reportados.
- Depois de Pint: `lerd composer test -- tests/Feature/Identity/EmailVerificationTest.php --compact`: **20 / 145, passando**, **915 ms**. Somente os dois cenários de login foram retirados; restante da divisão 4.8 continua pendente.
- `lerd composer test -- tests/Feature/Identity/Presentation/Http/SignInHttpTest.php --compact`: **10 cenários, 9 passando, 1 falhando, 102 assertions**, **545 ms**, sem skips. Passam canonicalização, dois tokens reais/resposta segura, conta ausente/e-mail inválido/senha incorreta/hash adaptativo de senha desconhecida, pending/blocked e perda de verificação/logout. Dataset **unusable hash** recebe **500 em vez de 401**, sem emissão de tokens. Falha também reproduzida na primeira execução do arquivo, antes do controle adicional de hash adaptativo.
- **Bloqueio BEH-04 / 6.4:** hash persistido `not-an-authenticatable-hash` é rejeitado por BcryptHasher::check com RuntimeException; `SignInAdapter.php:74` converte em erro operacional. Docs Laravel 13/código instalado confirmam verificação de algoritmo. BEH-04 exige erro uniforme também para hash não autenticável de fixture. Menor correção proposta: reconhecer hash persistido inválido na fronteira de validação de credenciais e responder InvalidCredentialsException, conservando falhas reais de provider/banco/emissão como operacionais. Requer decisão do usuário antes de editar produção; expectativa 401 não foi relaxada ou removida.
- `git diff --exit-code -- app` passou. Consulta read-only final não encontrou bancos temporários remanescentes.
- Somente 5.1/5.4/5.6/5.7 concluídas. 4.10/4.11/4.12 permanecem parciais por incluírem contextos/destinos ainda não migrados; 5.2/5.3 são provas dos contextos emissores; 5.5 inclui outros rollbacks. 6.4 continua bloqueada. Outras rodadas, inventário completo, duas seeds e paralelismo/gate integral continuam pendentes. A migração dos cinco contextos e a mudança não estão concluídas/arquiváveis.

### Continuação após decisão de autenticação e nova divergência de contexto

Esta subseção é o estado posterior à evidência acima: o usuário **autorizou a correção mínima de autenticação**, preservando falhas operacionais. A decisão de contexto de worker abaixo ainda está pendente.

- `SignInAdapter` agora rejeita um password persistido sem algoritmo de hash reconhecido antes de pedir validação ao provider. Mantém hasher/provider reais e verificação de algoritmo; não desabilita HASH_VERIFY nem transforma o catch geral em 401. Prova HTTP adicional injeta falha na consulta do provider e conserva 500 sanitizado/zero tokens. Hash adaptativo de senha desconhecida permanece um controle distinto de hash malformado.
- `EmailVerificationTest::creates an unverified pending account and requests one queued verification` foi movido para `Feature/Identity/Presentation/Http/SignUpHttpTest`, com canonicalização/name/hash/segredos/type/ID/relationship/Location fortalecidos. Acrescentados 12 datasets nomeados de transporte inválido, três de limites inclusivos e jornada de senha com espaços: hash exato e login trimmed 401 versus original 200. Não cria token/notification nos documentos recusados.
- `SignUpUseCaseTest` conserva a prova de callbacks registrada na etapa 4 e acrescenta falha sentinela do Repository dentro da unidade observada, sem callbacks/eventos/e-mail. Não declara rollback de persistência a partir desse fake.
- Após a última alteração PHP e Pint (`--dirty --format agent`), arquivos isolados:
  - `lerd composer test -- tests/Feature/Identity/Presentation/Http/SignUpHttpTest.php --compact`: **17 / 115, passando**, **675 ms**.
  - `lerd composer test -- tests/Feature/Identity/Presentation/Http/SignInHttpTest.php --compact`: **11 / 115, passando**, **579 ms**.
  - `lerd composer test -- tests/Unit/Identity/Application/UseCases/SignUpUseCaseTest.php --compact`: **3 / 31, passando**, **32 ms**.
  - `lerd composer test -- tests/Feature/Identity/EmailVerificationTest.php --compact`: **19 / 136, passando**, **872 ms**. As demais responsabilidades desse arquivo ainda aguardam divisão.
- Novo cenário em `Feature/Core/Infrastructure/Providers/QueueObservabilityTest::does not hydrate HTTP request fields into events emitted by a real serialized worker job`: HTTP enfileira `Tests\Support\Core\Fixtures\ObservabilityWorkerProbe` em fila database exclusiva; inspeciona payload serializado/classe, consome pelo worker real, comprova zero jobs/failed_jobs e observa evento do job e evento processed. Cleanup por fila em finally também executa com assertion reprovada. A primeira tentativa do teste mostrou que push direto exige argumento queue explícito; corrigido no próprio teste, e a fila efetiva é observada no banco.
- **Nova divergência BEH-16:** com fila efetiva/consumo demonstrados, o teste falha porque o evento do worker contém `request_id` HTTP da origem. A hidratação também transporta os demais campos HTTP capturados. Docs Laravel 13 confirmam que Context é desidratado junto ao payload e hidratado no worker; isso é causalidade nativa, não simplesmente contexto residual de dois requests no mesmo processo. A prova anterior de eventos despachados diretamente não exercitava esse mecanismo. É necessária decisão entre preservar a correlação causal e ajustar o contrato da spec, ou remover campos HTTP durante a hidratação mantendo somente metadados autorizados. Não alterar esse mecanismo nem a expectativa sem decisão.
- Arquivo de fila após Pint: `lerd composer test -- tests/Feature/Core/Infrastructure/Providers/QueueObservabilityTest.php --compact`: **4 testes, 3 passando/1 falhando, 61 assertions**, **355 ms**. Reprodução isolada com `--filter=serialized`: **1 falha / 8 assertions**, **291 ms**.
- Gate completo padrão após Pint: `lerd composer test -- --compact`: **801 testes, 800 passando/1 falhando, 4.987 assertions**, **15.001 ms**, sem skips/warnings reportados. A única falha é a nova prova de Context hidratado no worker. Os demais testes existentes dos cinco contextos/arquitetura passam, mas isso não conclui sua reorganização ou as seeds/paralelismo.
- Verificação operacional da correção de SignIn: rota reconferida via Artisan; URL resolvida via Boost; request com e-mail deliberadamente inválido respondeu 401 JSON:API com erro uniforme. Dumps já estavam habilitados e `optimize_route(site: trocado)` retornou zero amostras/rotas; não há evidência de performance autenticada nem de regressão N+1 a partir dessa captura.
- Estado atualizado: 5.2 e 6.1–6.5 comprovadas. **5.6 reaberta** pela prova real de worker. A conclusão anterior de 5.6 era limitada aos eventos diretos e deve ser lida como evidência parcial, não conclusão atual. Core/Identity e o passo dos cinco contextos continuam incompletos; rodadas restantes e gate aleatório/paralelo aguardam continuação.

### Correção dos testes quebrados — contexto do worker, 2026-10-10

- Após o pedido do usuário para corrigir os testes quebrados, a correção seguiu o contrato existente de BEH-16: retirar contexto HTTP herdado do worker, mantendo as assertions de ausência. A spec comportamental não foi relaxada.
- Reprodução antes da correção: `lerd composer test -- tests/Feature/Core/Infrastructure/Providers/QueueObservabilityTest.php --compact`: **4 testes, 3 passando/1 falhando, 61 assertions**, **359 ms**; falha por `request_id` presente no evento do worker.
- `CoreServiceProvider` registra `Context::hydrated` usando a API oficial Laravel 13 e o Repository fornecido pelo callback. Retira apenas `request_id`, `trace_id`, `http_method`, `path`, `ip`, `route` e `user_id` herdados da request. Preserva outros metadados e o mecanismo nativo de fila; IDs de negócio podem continuar sendo emitidos explicitamente pelo job/UseCase.
- A mesma regressão agora usa uma request autenticada com token real, observa evento HTTP após o enqueue e compara seus campos ao header/principal. Worker real consome o payload serializado em fila database exclusiva, preserva `expense_id`, metadado independente `probe_batch` e nome efetivo da fila, sem herdar os sete campos HTTP. Cleanup de jobs/failed_jobs segue em finally. Nenhum cenário removido ou marcado como skip.
- Arquivo isolado depois da correção: `lerd composer test -- tests/Feature/Core/Infrastructure/Providers/QueueObservabilityTest.php --compact`: **4 / 92, passando**, **435 ms**.
- `vendor_run pint --dirty --format agent`: passou. Após Pint, `lerd composer test -- --compact`: **801 testes / 5.018 assertions, todos passando**, **15.093 ms**, sem skips/warnings reportados. Inclui arquitetura, correlação HTTP/CLI, workers existentes de classificação/notification e todos os contextos.
- O bloqueio de BEH-16 está resolvido e 5.6 volta a concluída. Esta execução corrige a falha atual, mas não conclui reorganizações pendentes nem os gates de seeds/paralelismo da mudança.

## Evidência do passo 6 solicitado — isolamento e paralelismo, 2026-10-10

O passo «Completar isolamento e paralelismo» corresponde a **10.1–10.9** neste checklist, e não à seção 6 de contratos de Identity. Escopo: suporte/configuração/testes e orientação existente; nenhuma nova alteração de produção, migration ou dependência. Identidade da etapa 2 foi estendida, preservando manifesto privado e ownership exato.

### Implementação e rastreabilidade

| Requisito/tarefa | Cenário / destino | Evidência |
| --- | --- | --- |
| ISO-01/02/04, 10.5 | `TestDatabaseRun` registra tokens 1..N; `tests/run.php` provisiona/migra incrementalmente base e bancos nativos antes do runner. `TestCase` valida configuração inicial e efetiva após seleção do token; `CreatesApplication` recusa falta de manifesto. | Unit de guard/launcher/identidade; preflight vazio/pending/reuso no gate; todas as execuções Feature avulsas e paralelas abaixo. |
| ISO-03, 10.1/10.8 | `TestDatabaseCleanup` mantém lista explícita de failed_jobs/jobs/tokens/despesas/contas, com ordem FK, metadata/sequências preservadas e recusa de tabela desconhecida. `FailureCleanupTest` aborta após jobs Redis/database, failed job e transação aberta. | Sentinelas demonstradas antes da falha, depois jobs/failed_jobs vazios, migrations preservadas e zero transações. Commits/afterCommit reais continuam no gate. |
| ISO-05, 10.2/10.6 | `TestResources` cria namespace por run/token/cenário e filas/log exclusivos, faz SCAN/DEL restrito e fecha clientes default/cache mesmo após purge de fork. `RedisSharingTest` usa dois processos intencionalmente no mesmo namespace. | Cache alterado pelo filho é visto pelo pai; contador Redis incrementado pelos dois clientes chega a 2. Probes repetem ID 1500/e-mail e valores lógicos de chaves sem interferência. |
| ISO-06, 10.3 | `StateRestorationTest` altera relógio/timezone/binding/listener/query log e verifica aplicação posterior limpa; `ObservabilityLogFixture` inclui run/token e restaura stream. Feature teardown restaura globals e destrói app/fakes/guards/canais. | Arquivo avulso; gate completo em duas seeds; testes anteriores de alternância de token e observabilidade preservados. |
| ISO-07, 10.4 | `ConcurrentDatabaseProcess`; `SlidingSanctumSessionTest::revalidates...`, datasets extend/revoke/expire, usa conexão nova e barreira, observando Lock em pg_stat_activity. | Arquivo avulso e gate paralelo. Oráculo de readiness/lock passa a ser erro explícito do protocolo, mantendo checagens de token persistido. |
| ISO-07, 10.8 | `ChildReadinessFailureTest` recusa manifesto no filho antes de ready; `FailureCleanupTest` recebe erro do filho depois de go e também encerra filho que não conclui. | Falhas sentinelas recebidas, fechamento/reap limitado e waitpid confirma ausência de filho pendente. |
| ISO-04/05, 10.6/10.7 | `Probes/FirstProcessTest`, `Probes/SecondProcessTest` e `SimultaneousInvocationsTest`: duas invocações nativas × tokens 1/2, quatro bancos/namespaces/filas/logs; barreira segura mantém recursos vivos. | Liberar uma invocação remove só seus bancos/chaves/fila/logs. A outra segue ativa com sentinelas/logs/fila preservados, conclui e também limpa seus recursos. 35 assertions no orquestrador e oito por probe. |
| ISO-08, 2.5/10.9 | README documenta caminhos por contexto, grupos integration/redis/concurrency/worker/parallel-isolation e gate sem exclusões; CI inclui redis/posix e gate nativo de dois processos. | Comandos de desenvolvimento e aceitação executados localmente; workflow remoto não foi executado. |

Testes comuns conservam cache/limiter array, mail array e AI fake. Filas Redis de notification e classificação database usam configurações exclusivas; workers locais `queue` e `expense-classification` permaneceram ativos. Não houve FLUSHALL/FLUSHDB, parada de serviços ou migrate:fresh.

### Verificações isoladas após formatação

Todos os comandos abaixo usam `lerd composer test -- <arquivo> --compact`; paths relativos a `tests/`.

| Arquivo | Testes / assertions | Duração |
| --- | --- | --- |
| `Feature/Core/Infrastructure/Isolation/SimultaneousInvocationsTest.php` | 1 / 35, passou | 4.016 ms |
| `Feature/Core/Infrastructure/Isolation/FailureCleanupTest.php` | 2 / 16, passou | 1.412 ms |
| `Feature/Core/Infrastructure/Isolation/ChildReadinessFailureTest.php` | 1 / 3, passou | 245 ms |
| `Feature/Core/Infrastructure/Isolation/RedisSharingTest.php` | 1 / 3, passou | 313 ms |
| `Feature/Core/Infrastructure/Isolation/Probes/FirstProcessTest.php` | 1 / 8, passou | 238 ms |
| `Feature/Core/Infrastructure/Isolation/Probes/SecondProcessTest.php` | 1 / 8, passou | 329 ms |
| `Feature/Core/Infrastructure/Isolation/StateRestorationTest.php` | 2 / 11, passou | 250 ms |
| `Feature/Identity/SlidingSanctumSessionTest.php` | 13 / 151, passou | 1.315 ms |
| `Feature/Identity/EmailVerificationTest.php` | 19 / 136, passou | 1.252 ms |
| `Feature/Expense/ExpenseClassificationTest.php` | 26 / 156, passou | 1.588 ms |
| `Unit/Core/Support/Database/ParallelIdentityTest.php` | 1 / 9, passou | 21 ms |
| `Unit/Core/Support/Database/TestExecutionCommandTest.php` | 11 / 26, passou | 2.310 ms |

Suporte de banco focado: `lerd composer test -- tests/Unit/Core/Support/Database --compact`: **27 / 85**, **1.986 ms**, passou. Isolamento focado antes do último ajuste de diretórios nativos: **9 / 84**, **5.340 ms**, passou. As verificações finais avulsas e integrais abaixo incluem o ajuste.

Revisão final reforçou os finally de timezone (mesmo se teardown do framework lançar erro) e do orquestrador (encerramento limitado e limpeza dos arquivos mesmo se wait falhar). Pint passou novamente; os arquivos SimultaneousInvocations/StateRestoration foram repetidos isoladamente com os resultados finais da tabela. Os quatro gates integrais abaixo foram repetidos após esse último PHP edit; os demais resultados avulsos são anteriores a esse reforço compartilhado, também coberto pelos gates finais.

### Gate integral final

Após o último PHP edit, `vendor_run pint --dirty --format agent` passou; não houve alteração posterior de PHP. Em todos os comandos da tabela, **811 testes / 5.096 assertions passaram**, incluindo arquitetura, todos os cinco contextos e grupos Redis/worker/concorrência/isolamento. Sem skips/incomplete/risky; as flags explicitam que esses estados reprovam o gate.

| Comando | Duração | RunId |
| --- | --- | --- |
| `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 23.247 ms | `14d2f5d3265fa85a115919c6` |
| `lerd composer test -- --compact --order-by=random --random-order-seed=20261009 --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 23.330 ms | `6439186fbde5142a29ef5814` |
| Mesmo comando aleatório, seed `20261010` | 22.966 ms | `0907425ffc542ee947eda1e4` |
| `lerd composer test -- --compact --parallel --processes=2 --fail-on-skipped --fail-on-incomplete --fail-on-risky` | 15.932 ms | `024bdc72be7f75d713988b14` |

### Falhas encontradas, correções e limites

- Primeiro gate paralelo antes dos novos cenários: **801 / 5.003**, passou. Não é a evidência final da etapa.
- Primeira rodada do suporte detectou representação string dos contadores Redis (normalizada apenas nas assertions numéricas) e cleanup incompleto após purge pré-fork; teardown passou a reconectar os destinos default/cache do namespace para removê-los. A falha controlada foi repetida e passou.
- Tentativa de executar os quatro gates completos simultaneamente encontrou `filesize(): stat failed` no protocolo ParaTest e dois timeouts MCP, não aprovações. Em seguida, um gate paralelo detectou `mkdir(): File exists` nos hooks de views por token do Laravel. Código instalado confirmou paths compartilhados entre invocações. O launcher passou a isolar diretórios de protocolo ParaTest, cache PHPUnit e views por runId; o gate completo paralelo e as duas seeds foram repetidos e passaram como registrado acima. Não houve aumento de timeout ou exclusão de cenários.
- Tentativas encerradas externamente deixaram sete bancos dos IDs exatos `6dbbb9c35f8dfb4a9821981f`, `95af46dc79c8e3d8efb12da9` e `8726e5a139d5a2519127e968` (bases/tokens). Foram recuperados pontualmente nesta sessão, com confirmação efetiva/ownership pelo guard antes do drop, sem sweep de nomes semelhantes. Consulta read-only posterior encontrou zero bancos `trocado_testing_<runId>` remanescentes.
- O suporte comprova sucesso/falha controlada/reap de filhos e duas invocações simultâneas de dois processos; não é teste de carga, nem recuperação automática sob SIGKILL do launcher. Timeout MCP e encerramento externo continuam limitações operacionais explícitas. CI remoto não executado. Inventário/reorganizações e requisitos BEH pendentes da mudança continuam abertos; esta entrega não torna a mudança inteira arquivável.
- Verificações finais: `composer validate --no-check-publish`, OpenSpec estrito e `git diff --check` passaram. Consulta read-only não encontrou bancos exclusivos remanescentes; lista de processos do container mostrou somente FPM/MCP/scheduler/workers locais, sem runner/filho de teste pendente.

## Evidência do passo 7 solicitado — gate final, 2026-10-10

O passo «Executar o gate final» corresponde a **11.1–11.10**, não à seção 7 de rate limiting. O usuário autorizou a execução e o registro do gate. Esta rodada não acrescentou cenários, migrations, dependências ou correções de produto. As alterações anteriores do checkout foram preservadas. **Gate executável aprovado; aceite integral/arquivamento ainda impedido por organização, inventário e provas comportamentais pendentes.**

### Ambiente e comandos efetivos

- Boost reconfirmou PHP **8.5**, Laravel **13.34.0**, Pest **5.2.1**, PHPUnit **13.3.4**, ParaTest **7.25.0** e Pint **1.32.1**. Docs de parallel testing e CLI Pest consultadas. Lerd descoberto pelo MCP; `vendor_bins` confirmou ferramentas.
- Nesta seção, `F` significa exatamente `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Todos os arquivos e conjuntos abaixo foram executados pelo **MCP Lerd exec/composer** com argumentos equivalentes a `lerd composer test -- <seleção> F`. Cada linha registra uma invocação independente; nenhum resultado é inferido apenas da suíte completa.
- Uma tentativa de agrupar comandos pelo shell host foi recusada com `command not found: lerd`, antes de executar qualquer teste. Todas as verificações foram então realizadas pelo MCP; não há gate aprovado a partir daquela tentativa.
- `vendor_run pint --dirty --format agent` passou antes das verificações. Nenhum PHP foi editado depois. `composer validate --no-check-publish` passou. `migrate:status --no-interaction` mostrou todas as migrations operacionais aplicadas; nenhum migrate operacional foi necessário. Os bancos do launcher receberam migrations incrementais.
- `--list-groups` identificou `arch` (21), `concurrency` (8), `integration` (12), `parallel-isolation` (3), `redis` (6), `worker` (2) e `default` (778). Grupos se sobrepõem; não somar essas contagens. Os quatro gates completos não usam exclusão de grupos. O teste de worker serializado de Core também participa, embora não tenha tag `worker`.
- `worker list` confirmou `queue`, `expense-classification`, `schedule` e `vite` locais ativos após o gate. As provas usam filas exclusivas, IA fake e mail array; nenhuma parada de serviço, `FLUSHALL`, `FLUSHDB` ou `migrate:fresh`.

### Arquivos afetados executados isoladamente

Paths relativos a `tests/`. Comando de **cada** linha: `lerd composer test -- tests/<path> F`. Resultado de todas as linhas: **passou**, sem skips/incomplete/risky reportados.

| Path | Testes / assertions | Duração (ms) |
| --- | --- | --- |
| `Unit/Core/Domain/ValueObjects/AmountValueObjectTest.php` | 30 / 49 | 28 |
| `Unit/Core/Domain/ValueObjects/AmountShareTest.php` | 7 / 10 | 25 |
| `Unit/Core/Domain/ValueObjects/DatePeriodCalendarTest.php` | 50 / 227 | 33 |
| `Unit/Core/Domain/ValueObjects/DatePeriodValueObjectTest.php` | 31 / 67 | 25 |
| `Unit/Core/Infrastructure/Adapters/UserAdapterTest.php` | 11 / 44 | 35 |
| `Unit/Core/Infrastructure/Adapters/Observability/ObservabilityJsonFormatterTest.php` | 1 / 7 | 22 |
| `Unit/Core/Support/TransactionPortFakeTest.php` | 6 / 41 | 22 |
| `Unit/Core/Support/Database/TestDatabaseGuardTest.php` | 15 / 50 | 24 |
| `Unit/Core/Support/Database/ParallelIdentityTest.php` | 1 / 9 | 21 |
| `Unit/Core/Support/Database/TestExecutionCommandTest.php` | 11 / 26 | 2.219 |
| `Unit/Identity/Application/UseCases/SignUpUseCaseTest.php` | 3 / 31 | 38 |
| `Unit/Identity/Application/UseCases/DeleteUserUseCaseTest.php` | 3 / 17 | 38 |
| `Unit/Identity/Application/UseCases/UpdateUserUseCaseTest.php` | 6 / 23 | 33 |
| `Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php` | 35 / 972 | 40 |
| `Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php` | 3 / 20 | 2.560 |
| `Feature/Core/Infrastructure/Adapters/TransactionAdapterTest.php` | 4 / 29 | 891 |
| `Feature/Core/Infrastructure/Adapters/ObservabilityAdapterTest.php` | 1 / 4 | 293 |
| `Feature/Core/Infrastructure/Providers/QueueObservabilityTest.php` | 4 / 92 | 457 |
| `Feature/Core/Presentation/Http/Middleware/RequestCorrelationTest.php` | 1 / 55 | 309 |
| `Feature/Core/Infrastructure/Isolation/StateRestorationTest.php` | 2 / 11 | 251 |
| `Feature/Core/Infrastructure/Isolation/FailureCleanupTest.php` | 2 / 16 | 1.351 |
| `Feature/Core/Infrastructure/Isolation/ChildReadinessFailureTest.php` | 1 / 3 | 216 |
| `Feature/Core/Infrastructure/Isolation/RedisSharingTest.php` | 1 / 3 | 234 |
| `Feature/Core/Infrastructure/Isolation/Probes/FirstProcessTest.php` | 1 / 8 | 222 |
| `Feature/Core/Infrastructure/Isolation/Probes/SecondProcessTest.php` | 1 / 8 | 226 |
| `Feature/Core/Infrastructure/Isolation/SimultaneousInvocationsTest.php` | 1 / 35 | 3.830 |
| `Feature/Identity/Presentation/Http/SignUpHttpTest.php` | 17 / 115 | 776 |
| `Feature/Identity/Presentation/Http/SignInHttpTest.php` | 11 / 115 | 639 |
| `Feature/Identity/Infrastructure/Fixtures/IdentityFixtureTest.php` | 8 / 55 | 526 |
| `Feature/Identity/EmailVerificationTest.php` | 19 / 136 | 1.095 |
| `Feature/Identity/SlidingSanctumSessionTest.php` | 13 / 151 | 1.160 |
| `Feature/Expense/ExpenseOwnershipTest.php` | 5 / 25 | 456 |
| `Feature/Expense/ExpenseClassificationTest.php` | 26 / 156 | 1.283 |
| `Feature/Expense/Journeys/ExpenseMutationObservabilityTest.php` | 2 / 71 | 449 |
| `Feature/Insights/ExpenseAnalysisAdapterTest.php` | 16 / 223 | 713 |
| `Feature/Insights/InsightsApiTest.php` | 24 / 174 | 1.157 |
| `Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php` | 81 / 754 | 2.965 |

### Contextos e arquitetura

Comando por linha: `lerd composer test -- <seleção> F`. Resultado: **passou**, sem skips/incomplete/risky reportados. Somados, os cinco contextos e arquitetura identificam os 811 testes/5.096 assertions do gate atual, sem tratar contagem como equivalência funcional.

| Seleção | Testes / assertions | Duração (ms) | RunId |
| --- | --- | --- | --- |
| `tests/Unit/Core tests/Feature/Core` | 219 / 893 | 9.299 | `da6f665bdf5de9675a5a7e17` |
| `tests/Unit/Identity tests/Feature/Identity` | 119 / 846 | 3.452 | `53566ea6f344800fc7fdef5d` |
| `tests/Unit/Expense tests/Feature/Expense` | 74 / 342 | 2.374 | `038af9d98f7021265d783cce` |
| `tests/Unit/Insights tests/Feature/Insights` | 238 / 1.806 | 1.828 | `a0d32ad3f5386728fc631e8a` |
| `tests/Unit/Metrics tests/Feature/Metrics` | 135 / 898 | 3.630 | `f5e46f440f1cc971d30dd386` |
| `tests/Unit/Architecture` | 26 / 311 | 4.940 | Sem preflight/banco |

`git diff --exit-code -- tests/Unit/Architecture composer.lock database/migrations` passou: nenhuma allowlist, dependência ou migration alterada no checkout da mudança. `Pest.php` apenas associa FeatureTestCase a Feature. Os 11 cenários/datasets de `TestExecutionCommandTest` passaram isoladamente: drivers/hosts/URLs deliberadamente inválidos não impedem Core Domain/adapters/doubles e Identity Application puros, nem discovery Feature; não há preflight nesses subprocessos. O autoload de Support é exercitado pelos testes avulsos de fake/stub/spy/fixtures. Isso não afirma indisponibilidade real de todos os serviços da máquina.

### Suíte completa, seeds e paralelo

Comando por linha: `lerd composer test -- <opções>`. **811 testes / 5.096 assertions passaram em cada execução**, sem skips/incomplete/risky reportados. Gates executados um após o outro; somente o cenário próprio de invocações simultâneas lança intencionalmente duas execuções.

| Opções | Duração (ms) | RunId |
| --- | --- | --- |
| `F` | 22.904 | `668206f2e9fe1de51f7f9ae1` |
| `F --order-by=random --random-order-seed=20261009` | 23.246 | `00021895bf41009dea2bf7fb` |
| `F --order-by=random --random-order-seed=20261010` | 23.611 | `d4630221efe1732b33a42541` |
| `F --parallel --processes=2` | 17.013 | `834a55ef898771cdba7396c1` |

O paralelo usa base `trocado_testing_834a55ef898771cdba7396c1` e destinos nativos registrados `_test_1`/`_test_2`, sem autorizar nomes semelhantes. `SimultaneousInvocationsTest::isolates two native parallel invocations with the same local tokens and independent cleanup` passou avulso e nos quatro gates: **duas invocações × dois processos**, quatro bancos/namespaces/filas/logs distintos, tokens locais 1/2 repetidos, fixture ID 1500/e-mail coincidentes e limpeza da primeira preservando a segunda. O teste verifica os runIds dinâmicos internamente; seus segredos/manifestos não foram registrados neste documento.

Consulta Boost read-only final de `pg_database`, com `datname ~ '^trocado_testing_[0-9a-f]{24}(_test_[0-9]+)?$'`, retornou **zero linhas** após o paralelo. É uma observação de resíduos, não autorização de cleanup por regex. Falha controlada/reap de filhos/cleanup Redis/filas/logs são comprovados pelos cenários próprios; não se extrapola essa evidência para SIGKILL.

### Matriz revisada por Scenario e nível de evidência

Estados: **P** = Proven, cenário pertinente executado; **PP** = Partially proven, prova relacionada passa mas falta cláusula/camada; **U** = Unproven, não há prova do cenário exato. Não houve cenário executável bloqueado por serviço nesta rodada. Paths abaixo relativos a `tests/`; os nomes de cenários são os das delta specs. `F` e os resultados estão nas tabelas acima. Para destinos fora da tabela avulsa, o comando efetivo é a seleção Unit/Feature do contexto na tabela de contextos, também incluída nos quatro gates integrais.

#### Organização

| Requisito / Scenario | Estado | Destino/evidência e limitação |
| --- | --- | --- |
| ORG-01 — Localizar um teste de Repository | PP | Cache em `Feature/Expense/Infrastructure/Repositories/Cache`; persistência Identity ainda misturada em `Feature/Identity/EmailVerificationTest.php`. 4.8/4.9 pendentes. |
| ORG-01 — Localizar contrato HTTP | PP | SignUp/SignIn em `Feature/Identity/Presentation/Http`; Insights e parte de Expense/Identity ainda em arquivos amplos; Metrics ainda em `Presentation/`, sem subpasta Http. |
| ORG-01 — Unidade de adapter sem bootstrap | P | `Unit/Core/Infrastructure/Adapters/UserAdapterTest.php`; subprocesso sem preflight em TestExecutionCommandTest. |
| ORG-02 — Dividir a verificação de e-mail | PP | Três cenários antigos movidos para SignUp/SignIn; link/reenvio/notification/worker/perfil/Repository continuam juntos em EmailVerificationTest. |
| ORG-02 — Dividir classificação de despesa | U | ExpenseClassificationTest ainda mistura provider/HTTP/queue/cache. Executá-lo sozinho não prova a divisão. |
| ORG-03 — Repository double do cache | U | `Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseRepositoryTest.php::cachedRepositoryFixture` ainda contém classe anônima substancial/IDs fixos. 4.5 pendente. |
| ORG-03 — Capacidade autenticada compartilhada | P | `Support/Core/Stubs/UserPortStub.php`, chamado nos UseCases Identity; fake/spy puros comprovados por `Unit/Core/Support/TransactionPortFakeTest.php`. |
| ORG-03 — Double pontual pequeno | P | Expectativas de Repository/EmailVerificationPort locais em SignUpUseCaseTest; ausência de quota escondida no Support. |
| ORG-04 — Cache de categorização | U | `CachedExpenseCategorizationRepositoryTest.php` mantém Mockery em contratos próprios; Metrics HTTP também mantém mocks próprios Mockery. |
| ORG-04 — Falha de integração simulada | P | Fakes nativos de IA/Queue/Notification preservados em ExpenseClassificationTest e EmailVerificationTest; gate do contexto passa. |
| ORG-05 — Conta apta para testar Expense | P | IdentityFixture com Active/verifiedAt/token explícitos em ExpenseOwnershipTest e ExpenseClassificationTest, ambos avulsos. |
| ORG-05 — Jornada de cadastro real | P | `IdentityFixtureTest::keeps the HTTP registration and verification journey pending until activation is explicitly arranged` e ExpenseMutationObservabilityTest. |
| ORG-06 — Candidatos de Insights | U | Builders/funções semelhantes continuam em arquivos Unit de Insights; 4.6 pendente. |
| ORG-06 — Projeção inválida de Metrics | PP | `Unit/Metrics/Application/UseCases/GetExpenseMetricsUseCaseTest.php` aceita projeções inválidas nos datasets, mas fixture/tupla de mocks permanece no arquivo; 4.7 pendente. |
| ORG-07 — Dois testes de formato monetário | P | União de datasets AmountArithmetic/AmountValueObject registrada na rodada Core; AmountValueObject avulso 30/49, sem parser duplicado. |
| ORG-07 — Redução legítima da contagem | PP | Mapa Core detalha casos removidos/consolidados (Amount/calendário) e destinos; inventário de todos os cenários/contextos não concluído em 1.3/11.7. |
| ORG-08 — Executar unitários puros | P | TestExecutionCommandTest, datasets sem serviços; arquitetura 26/311 sem preflight. |
| ORG-08 — Helper integra contextos | P | IdentityFixture somente em tests/Support; fronteiras de `app/` passam, allowlists inalteradas. |

#### Comportamento

| Requisito / Scenario | Estado | Destino/evidência e limitação |
| --- | --- | --- |
| BEH-01 — Criação dentro da unidade transacional | P | `Unit/Identity/Application/UseCases/SignUpUseCaseTest.php` observa isActive dentro da criação e liberação posterior dos callbacks; 3/31 avulso. |
| BEH-01 — Rollback provocado | PP | TransactionAdapterTest e ExpenseMutationObservabilityTest provam escrita/sentinela/rollback PostgreSQL; catches permissivos continuam em cache e ExpenseClassificationTest. 5.5 pendente. |
| BEH-02 — Registro confirmado | P | SignUpUseCaseTest observa ID, pedido de verificação/evento e ausência antes de releaseAfterCommit. |
| BEH-02 — Tentativa abortada | P | SignUpUseCaseTest verifica sentinela do Repository, callbacks descartados e nenhum efeito; TransactionAdapterTest comprova mecanismo real/retry injetado. |
| BEH-02 — Mutações e classificação | PP | DeleteUserUseCaseTest cobre evento/ID e recusa; jornada comprova wiring HTTP. Unit de Expense ainda não observa todos os callbacks/eventos; 5.3 pendente. |
| BEH-03 — Confirmação divergente | P | `SignUpHttpTest::rejects a named invalid registration document without persistence or verification`, dataset de confirmação; 17/115 avulso inclui todos os datasets do arquivo. |
| BEH-03 — Senha preservada | P | `SignUpHttpTest::preserves password spaces through registration hashing and real login`, hash/login trimmed 401 e original 200. |
| BEH-03 — Limites e transporte inválidos | P | SignUpHttpTest: 12 datasets inválidos e três limites inclusivos, sem escrita/token/notification, pointers verificados. |
| BEH-04 — E-mail equivalente no login | P | `SignInHttpTest::issues distinct real tokens for canonical equivalent logins with safe JSON API responses`; provider/hasher/Sanctum reais. |
| BEH-04 — Falhas genéricas | P | `SignInHttpTest::returns the same safe credential error without issuing tokens`, invalid email/missing identity/wrong password/unknown adaptive password/unusable hash. |
| BEH-04 — Dois logins e resposta segura | P | Mesmo cenário de tokens distintos, hashes/expiração/relacionamentos/no-store/Pragma; 11/115 avulso. |
| BEH-04 — E-mail deixa de estar verificado | P | SignInHttpTest verifica bloqueios e selective sign-out preservando o segundo token. |
| BEH-05 — Exclusão completa | U | Não há HTTP DELETE de User com dois tokens/duas despesas/terceiro preservado; fake de DeleteUser e cascade isolado não substituem 6.8. |
| BEH-05 — Falha após remover tokens | U | Não há sentinela nesse ponto da exclusão real de User; 6.8 pendente. |
| BEH-05 — Conta alheia e ausente | PP | Get/Update/DeleteUser unitários interrompem Repository; EmailVerificationTest cobre PATCH alheio. Matriz HTTP GET/PATCH/DELETE/ausente/sem principal de 6.7 incompleta. |
| BEH-05 — Caminhos públicos inexistentes | U | Prova HTTP dedicada de GET/POST `/api/users` 404 sem efeitos ainda não foi entregue em 6.7. |
| BEH-06 — Colisão após precheck | U | Conflict/retry sequenciais em EmailVerificationTest não são duas criações concorrentes que ultrapassam precheck; 6.9 pendente. |
| BEH-06 — Perfil preservado | PP | EmailVerificationTest cobre persistência de nome/e-mail e HTTP verificação/tokens, mas não mapping completo/status/timestamps/ausentes e normalização no retorno Entity; 6.6 pendente. |
| BEH-07 — Login repetido canônico | U | Não há dataset HTTP 5/minuto/canonicalização/outro IP/zero token da sexta tentativa; 7.1 pendente. |
| BEH-07 — Troca de e-mail não contorna IP | U | Não há prova HTTP 30/minuto por IP com e-mails distintos; 7.1/7.2 pendentes. |
| BEH-07 — Cota autenticada compartilhada | U | Throttle substituído por 1/minuto em Insights prova aplicação da policy, não 60/minuto entre tokens/IPs/rotas/erros/logout; 7.4/7.5 pendentes. |
| BEH-07 — Janela expira | U | Não há prova completa das janelas de limiter com relógio controlado; 7.5 pendente. |
| BEH-07 — Redis compartilhado e indisponibilidade | PP | RedisSharingTest comprova consumo por dois processos/cache compartilhado, mas não falha injetada sem fallback local; 7.6 pendente. |
| BEH-08 — Consulta própria e atual | U | Não há GET individual Expense atualizado/bypass de página e UseCase focado; 8.1/8.2 pendentes. |
| BEH-08 — Alvo inacessível | U | Não há matriz GET individual alheio/ausente/excluído/sem token/ID não numérico; DELETE/PATCH ownership não a substitui. |
| BEH-09 — Datas iguais em várias páginas | U | ExpenseOwnershipTest usa uma página; não navega sete registros size 2 por next/prev; 8.3 pendente. |
| BEH-09 — Cursor de outra conta | U | Não há replay de cursor emitido para A por B; double de cache não comprova SQL; 8.4 pendente. |
| BEH-09 — Conta vazia e limites | U | Não há prova HTTP default 20 com mais de vinte registros e limites 1/100; 8.4 pendente. |
| BEH-09 — Cursor ou tamanho inválido | U | Matriz completa de 422 sem leitura/fallback de 8.5 não entregue. |
| BEH-09 — Proprietário fornecido pelo cliente | U | user_id é recusado na criação, não há a prova exigida na listagem/cursor válido de 8.5. |
| BEH-10 — Default na virada civil | U | Sem HTTP de criação omitindo occurred_on em instante UTC/app divergente; 8.6 pendente. |
| BEH-10 — Atualização parcial | PP | ExpenseOwnershipTest comprova null explícito e data preservada; ExpenseClassificationTest comprova edição de categoria/descrição. Matriz omissão versus null/campos não informados incompleta em 8.6. |
| BEH-10 — Invariantes no transporte e Repository | PP | ExpenseEntity Unit, entrada inválida de ExpenseClassificationTest e FK/cascade de ExpenseOwnershipTest passam; falta matriz HTTP 64 Unicode/catálogo e tradução de proprietário ausente em 8.6/8.7. |
| BEH-11 — TTL antes e depois do limite | U | CachedExpenseRepositoryTest não avança relógio para t0/antes/depois de 60s; 8.8/8.9 pendentes. |
| BEH-11 — Escrita confirmada em múltiplas páginas | PP | Cache miss/hit/chave/invalidação e classificação por páginas passam; matriz create/update/delete em todos os tamanhos/cursores ainda incompleta em 8.10. |
| BEH-11 — Rollback e savepoint | PP | Cache usa inner Repository double com catches permissivos; prova de callbacks não prova dados reais revertidos; 8.11 pendente. |
| BEH-11 — Leitura individual e categoria recusada | PP | CachedExpenseCategorizationRepositoryTest prova begin/find/cancel/rejected sem invalidação; duas chamadas reais/observadas getById e round-trip completo faltam em 8.8. |
| BEH-11 — Invalidação entre clientes Redis | U | RedisSharingTest prova store genérico, não invalidação de CachedExpenseRepository entre clientes; 8.12 pendente. |
| BEH-12 — Resposta tardia diante de edição | PP | ExpenseClassificationTest preserva interleavings determinísticos, inclusive edição durante provider; não usa segundo processo após leitura para category/description/token; 8.14 pendente. |
| BEH-12 — Falha de tentativa antiga | U | Prova específica token antigo/nova tentativa com condição SQL não entregue em 8.14. |
| BEH-12 — Worker real | PP | ExpenseClassificationTest consome fila database exclusiva com worker/IA fake; prova entregue passa. Revisão completa de bindings/payload/destinos/retries e divisão por responsabilidade de 8.13/8.15 ainda aberta. |
| BEH-13 — Liderança recorrente com contas diferentes | P | ExpenseAnalysisAdapterTest: IDs 1/2/3/4/15/1500 e sequência avançada após 0/7/31 contas; nove datasets preservados. Composição: seis contas × quatro datas/variantes. Ambos avulsos e duas seeds integrais. |
| BEH-13 — Catálogo completo | P | ComposeInsightMessageUseCaseTest e SelectInsightMessageVariantUseCaseTest preservam catálogo/Unicode/fallback/falha/ciclos/labels; suíte Insights e gates. Extração de builders é pendência separada. |
| BEH-13 — Números mudam no mesmo dia | P | GetInsightsUseCaseTest, ComposeInsightMessageUseCaseTest (39%/42%) e InsightsApiTest (60%/64%) mantêm ID/título e mudam percentual. |
| BEH-14 — Uma leitura analítica íntegra | PP | ExpenseAnalysisAdapterTest e InsightsApiTest provam owner/período/uma leitura/sem escrita, mas ainda exigem `WITH periods`; 9.1 pendente. |
| BEH-14 — Thresholds e seleção | P | GenerateInsightCandidatesRulesTest e SelectInsightCandidatesUseCaseTest, todos os datasets atuais na suíte Insights; razões exatas/limite seis/sem redundância preservados. |
| BEH-14 — Query recusada e falha operacional | P | InsightsApiTest observa never analyze em 422/401/403, aplica throttle e mantém 500 sem onboarding; não prova cota real 60/minuto, tratada em BEH-07. |
| BEH-15 — Status do principal | P | UserAdapterTest: status textual/string-backed enum e tipos/principal inválidos, somente Sanctum; 11/44. |
| BEH-15 — Razão versus participação | P | RatioValueObjectTest/RatioPercentageTest/AmountShareTest na suíte Core; share limitada e razão acima de 100%, denominador zero inválido. |
| BEH-15 — Aritmética e calendário extremos | P | Seis arquivos Core Domain preservam precisão, operandos, half-up, extremos civis/timezone/DST; mapa da rodada Core e avulsos atuais. |
| BEH-16 — IDs coincidem com valor sensível numérico | P | ObservabilityJsonFormatterTest/Jornada: JSON estrutural aceita ID 1500/timestamp, remove campos sensíveis; 1/7 e 2/71. |
| BEH-16 — Requests e execução fora de HTTP | P | RequestCorrelationTest 1/55 e QueueObservabilityTest 4/92; inclui job serializado/worker real sem campos HTTP herdados, metadados autorizados preservados. |
| BEH-16 — Destino de log indisponível | P | ObservabilityAdapterTest usa filho de arquivo regular temporário e mantém 201/escrita; 1/4. |
| BEH-17 — Totais e percentuais exatos | P | GetExpenseMetricsUseCaseTest: large totals; datasets simple distribution, 99.99 percent, 100.01 percent, minimum positive share, minimum amount; suíte Metrics 135/898. |
| BEH-17 — Projeção inconsistente | P | Mesmo arquivo: dez projeções malformadas e cinco montantes × total/category; construção negativa não reparada. Extração de fixture continua em ORG-06. |
| BEH-17 — Leitura PostgreSQL entregue | P | ExpenseMetricsAdapterTest: dois modos, quinze datasets/cenários atuais, statement único/owner/civil/large sums/sem escrita e atualização entre consultas; suíte Metrics. Não é corrida durante leitura. |
| BEH-17 — Contrato HTTP entregue | P | ExpenseMetricsHttpTest 81/754: query original/duplicatas/encoding, default/timezone/leap, singular/omissões/precisão/bloqueios/erro; preservado no caminho atual. Movimentação ainda em ORG-01. |
| BEH-17 — Coordenação com histórico de Metrics | PP | Nenhum path de Metrics ou histórico arquivado foi movido/editado; preservação/limitações registradas. Inventário/migração final e referências dependem de 1.4/4.7/9.7. |
| BEH-18 — Nova organização de suporte | P | ContextBoundariesTest 26/311, allowlist compartilhada permanece exata; Support não libera novos imports de app. |
| BEH-18 — Prova sequencial de idempotência | P | Repetição/manual handle classificada como idempotência, retry injetado como injetado, interleaving como interleaving; somente sessão/isolamento têm a prova processual correspondente. |

#### Isolamento e PostgreSQL

| Requisito / Scenario | Estado | Destino/evidência e limitação |
| --- | --- | --- |
| ISO-01 — Configuração operacional acidental | P | TestDatabaseGuardTest, datasets operacional/URL/read/write/effective mismatch; TestExecutionCommandTest recusa antes de provisionar; preflight recusa migrate/drop divergentes. |
| ISO-01 — Nome parecido mas não autorizado | P | Guard e launcher, datasets similar unauthorized database/similar name; ação destrutiva não atingida. |
| ISO-01 — Banco resolvido pelo processo paralelo | P | ParallelIdentityTest, probes e gate de dois processos; seleção/guard do destino efetivo antes de fixtures. |
| ISO-02 — Banco vazio de teste | P | `TestDatabasePreflightTest::prepares an empty database and applies pending migrations without losing existing rows`; banco inicialmente sem users. |
| ISO-02 — Migration pendente | P | Mesmo cenário aplica primeira migration, insere fixture, aplica restantes, preserva linha e reaplica sem nova migration; 3/20 avulso. |
| ISO-02 — Arquivo isolado | P | 37 arquivos avulsos; discovery sem migrate e execução sem manifesto recusada em TestExecutionCommandTest. |
| ISO-03 — Worker falha antes de consumir job | P | FailureCleanupTest demonstra jobs/failed_jobs/Redis/log presentes, falha sentinela, finally remove apenas recursos exclusivos. |
| ISO-03 — Testes de afterCommit | P | TransactionAdapterTest usa commits externos/rollback reais sem wrapper; cleanup/failure confirma zero transações; não equivale a completar BEH-11. |
| ISO-04 — Dois processos executam Feature | P | Probes First/Second e gate `--parallel --processes=2`; ID 1500/e-mail iguais em bancos diferentes. |
| ISO-04 — Duas invocações simultâneas | P | SimultaneousInvocationsTest 1/35 avulso; quatro destinos distintos e cleanup independente com barreira. |
| ISO-04 — Recursos suficientes indisponíveis | PP | Launcher/guard falham explicitamente e não têm fallback; não se retirou permissão/serviço PostgreSQL real nesta rodada para reproduzir indisponibilidade de provisionamento. |
| ISO-05 — Worker local ativo | P | Workers locais ativos; EmailVerificationTest worker Redis/retry mail e ExpenseClassificationTest worker database em filas exclusivas, gates verdes. |
| ISO-05 — Cache e limiter em paralelo | P | Probes e RedisSharingTest comprovam namespaces isolados/compartilhamento intencional com clientes independentes; não prova falha de limiter de BEH-07. |
| ISO-05 — Interrupção de cenário Redis | P | FailureCleanupTest 2/16; sentinela e fila removidas, Redis não é limpo globalmente. |
| ISO-06 — Troca de token no mesmo processo | P | SignInHttpTest/IdentityFixtureTest e HTTP dos demais contextos usam Bearer/forgetGuards; avulsos e seeds passam. |
| ISO-06 — Relógio e listener modificados | P | StateRestorationTest 2/11 e FeatureTestCase teardown; aplicação seguinte limpa e dois gates aleatórios verdes. |
| ISO-07 — Processo aguarda lock | P | SlidingSanctumSessionTest, datasets extend/revoke/expire; protocolo observa Lock PostgreSQL antes da liberação; avulso 13/151. |
| ISO-07 — Processo falha antes da barreira | P | ChildReadinessFailureTest 1/3; manifesto recusado antes de ready; FailureCleanupTest verifica erro pós-go/encerramento limitado/reap. |
| ISO-08 — Desenvolvimento de regra pura | P | Seleção Unit sem preflight e subprocessos de TestExecutionCommandTest com driver/host/URL inválidos; README documenta o comando. |
| ISO-08 — Gate completo | P | Quatro gates sem exclusões; grupos Redis/concurrency/worker/parallel-isolation incluídos; flags reprovam skip/incomplete/risky. |
| ISO-09 — Teste editorial selecionado sozinho | P | Prova isolada da etapa 3 (9 datasets), arquivo avulso atual (16/223), duas seeds integrais e sequência avançada no próprio dataset; sem reset de sequência. |
| ISO-09 — Regressão descoberta no gate | P | Nenhuma regressão executável nesta rodada; falhas históricas preservadas, lacunas PP/U não convertidas em conclusão; 11.7/11.10 abertas. |
| PostgreSQL — Execução da suíte | P | Guard/preflight e todos os conjuntos Feature; dados operacionais não são destinos autorizados. |
| PostgreSQL — Configuração de testes incorreta | P | Guard 15/50, launcher 11/26 e preflight 3/20; driver/URL/config/effective/ownership inválidos impedem alteração. |
| PostgreSQL — Processos paralelos | P | Gate nativo de dois processos e probes de isolamento, destinos exatos autorizados. |
| PostgreSQL — Execuções simultâneas | P | Duas invocações × dois tokens; limpeza de uma preserva fixtures/cache/fila/log da outra. |
| PostgreSQL — Bootstrap incremental seguro | P | Banco vazio/pending/reuso com ownership; fixture prévia preservada, nada de migrate:fresh. |

### Mapa de preservação e decisão final do gate

- **Movidos/consolidados nesta mudança:** a tabela da rodada Core identifica cada cenário removido de AmountArithmeticTest, a união dos datasets de datas, todos os três cenários de ExpenseObservabilityTest e os dois cenários de login retirados de EmailVerificationTest. A continuação de Identity identifica o cadastro movido para SignUpHttpTest. Nenhum cenário adicional foi removido/consolidado neste passo 7; os 37 destinos avulsos acima reconfirmam as provas afetadas.
- **Mantidos nos caminhos atuais:** Expense ownership/classificação/cache; Identity verificação/sessão/rate limit; Insights Domain/Application/Adapter/HTTP; Metrics Domain/Application/Adapter/HTTP. Execução de seus contextos confirma os casos existentes, não a entrega dos casos novos faltantes. Os arquivos ainda amplos e os helpers locais não foram tratados como migração concluída.
- **Blocker de aceite integral:** 11.7 permanece parcial enquanto faltarem inventário/migrações (1.3–1.5, 4.5–4.12), callbacks/rollback restantes (5.3/5.5), Identity mapping/ownership/concorrência (6.6–6.11), rate limiting (7.x), Expense GET/paginação/validação/cache/concorrência (8.x) e preservação/reorganização restante (9.x). As linhas PP/U especificam por que o teste verde relacionado não basta. Não foi necessária nova decisão de produto nesta rodada.
- **Pass:** 11.1/11.2/11.6/11.8/11.9 agora concluídas; 11.3–11.5 reconfirmadas. OpenSpec estrito e `git diff --check` passaram. Artefatos de planejamento estão completos, mas tarefas de implementação restantes continuam abertas. 11.10 tem relatório, porém sua condição de todos os cenários comprovados não foi satisfeita.
- **Limitações:** CI remoto não executado; nenhuma alegação de coverage percentual/carga/escala, deadlock natural, colisão de e-mail ou corrida de classificação ainda não exercitados. Cleanup de SIGKILL permanece fora da recuperação automática. Em Metrics, travessia de mês durante request, escrita durante leitura, cota/extensão de sessão específica e medição autenticada continuam limitações históricas aceitas. O Purpose `TBD` da main spec expense-metrics é drift documental pré-existente, sem mudança no contrato; não foi corrigido nem usado como evidência comportamental.
- **Comando de aceite preservado:** launcher `lerd composer test --`, com `F` e opções da tabela; não houve nova alteração de comandos/README/CI neste passo. Não sincronizar nem arquivar por esta execução: não há solicitação para isso e a mudança inteira ainda não atende os critérios de conclusão.
