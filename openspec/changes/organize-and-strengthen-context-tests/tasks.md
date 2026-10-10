## 1. Autorizar e estabelecer a baseline de implementação

- [ ] 1.1 Obter autorização explícita de apply para testes/configuração/scripts de suporte; confirmar que correção de produção descoberta por teste exige decisão posterior. Não marcar por causa da autorização para criar esta spec.
- [ ] 1.2 Reconsultar versões/commands/docs Laravel/Pest/PHPUnit, instruções de arquitetura, conexão/schema e permissões de provisionamento pelo ambiente Lerd; confirmar ordem dos hooks parallel antes de escrever bootstrap. [ISO-01/04]
- [ ] 1.3 Inventariar todos os arquivos/cenários existentes e recursos persistentes usados; registrar cenário, objetivo, camada, contexto, dependências e destino planejado na matriz de migração. [ORG-01/07]
- [ ] 1.4 Reconferir o estágio de add-expense-metrics e alterações prévias do usuário; delimitar somente testes existentes e referências correntes afetadas, sem iniciar Adapter/HTTP de Metrics. [BEH-17]
- [ ] 1.5 Revisar divergências históricas já identificadas contra arquitetura atual e registrar o contrato adotado para cada prova; perguntar uma dúvida por vez se surgir divergência funcional sem decisão inequívoca. [BEH-18]

## 2. Preparar execução e guard seguro de teste

- [ ] 2.1 Definir runId compartilhado pelo entrypoint e filhos, base PostgreSQL exclusiva e registro exato de destinos autorizados, com encaminhamento de argumentos do runner nativo. [ISO-01/04]
- [ ] 2.2 Implementar validação inicial de driver/URL/config e validação read-only do banco efetivo antes de migrations, fixtures, cleanup ou drop, preservando recusa de banco operacional. [ISO-01]
- [ ] 2.3 Adicionar testes negativos do guard para driver SQLite, banco operacional, DB_URL conflitante, nome parecido não autorizado e conexão efetiva divergente, usando doubles/destinos seguros; comprovar que a ação destrutiva não é chamada. [ISO-01]
- [ ] 2.4 Implementar provisionamento idempotente somente de bancos autorizados e preparação incremental de migrations existentes, com diagnóstico de pré-requisito ausente; não usar migrate:fresh. [ISO-02]
- [ ] 2.5 Definir comandos canônicos para Unit, arquitetura, Feature por contexto, integrações e paralelo; garantir que execução avulsa também usa preflight ou falha antes de dados parciais. [ISO-02/08]
- [ ] 2.6 Executar as primeiras verificações Feature somente após guard/schema seguros; registrar baseline atual sem confundir os resultados históricos desta spec com nova execução. [ISO-09]

## 3. Corrigir a falha editorial conhecida antes da reorganização ampla

- [ ] 3.1 Substituir a assertion de frase incidental em ExpenseAnalysisAdapterTest por prova do significado/contrato que aceite todas as variantes válidas, preservando catálogo de produção. [BEH-13]
- [ ] 3.2 Acrescentar dataset de IDs positivos explícitos que alcance todas as variantes relevantes e manter assertions focadas do catálogo/composição independentes de sequência PostgreSQL. [BEH-13]
- [ ] 3.3 Executar o cenário editorial sozinho, o arquivo e os testes focados de composição; verificar diferentes estados de sequência sem resetá-la para forçar uma mensagem. Registrar o resultado. [ISO-06/09]

## 4. Estabelecer Support e mover cenários por responsabilidade

- [ ] 4.1 Criar somente a estrutura Support necessária, autoloadável por Tests, e retirar helpers de negócio globais de Pest.php. Confirmar que descoberta de Unit não conecta serviços. [ORG-03/08]
- [ ] 4.2 Extrair stub autenticado de Core e spy de observabilidade quando reutilização justificar; manter argumentos/expectativas específicas visíveis nos testes. [ORG-03/04]
- [ ] 4.3 Implementar fake observável de TransactionPort com escopo ativo, registro/ordem de callbacks, confirmação e descarte por tentativa abortada; provar seus limites sem simular rollback de banco. [BEH-01/02]
- [ ] 4.4 Separar fixtures de contas pending/unverified, active/verified e blocked, tokens reais e helpers de jornada HTTP; remover fake/ativação/verificação ocultos do helper de cadastro. [ORG-05]
- [ ] 4.5 Extrair o Repository double substancial do cache de Expense e migrar mocks de contratos próprios de Mockery para PHPUnit/spy, sem remover a dependência do framework. [ORG-03/04]
- [ ] 4.6 Consolidar builders de candidatos/resumos/projeções de Insights em Support, mantendo dados negativos possíveis e cálculos esperados independentes do SUT. [ORG-06]
- [ ] 4.7 Extrair fixtures de Metrics e eliminar helper que recebe e devolve os mesmos mocks em tupla; construir UseCase explicitamente e manter expectativas por cenário. [ORG-05/06]
- [ ] 4.8 Dividir EmailVerificationTest por cadastro/link/reenvio/perfil/Repository/notification/worker e SlidingSanctumSessionTest por HTTP/adapter/concorrência/pruning, registrando cada destino. [ORG-01/02/07]
- [ ] 4.9 Dividir ExpenseClassificationTest por HTTP/provider/queue/categorização/cache/jornada e ExpenseOwnershipTest por transporte/persistência; mover Insights Feature para camadas correspondentes. [ORG-01/02/07]
- [ ] 4.10 Localizar observabilidade transversal em Core e intenção de eventos em Identity/Expense; avaliar destinos das provas reflexivas de contratos sem exigir ordem incidental de Reflection. [ORG-01/02, BEH-16/18]
- [ ] 4.11 Consolidar casos sobrepostos de Core e mover invariantes de Domain hoje em testes de Application de Insights; comprovar por matriz a preservação dos casos relevantes. [ORG-07, BEH-15]
- [ ] 4.12 Executar cada arquivo movido/alterado isoladamente antes de marcar sua migração concluída e registrar a correspondência antiga/nova, inclusive duplicações justificadamente consolidadas. [ORG-02/07]

## 5. Fortalecer provas de Core e callbacks

- [ ] 5.1 Cobrir UserAdapter id inteiro e status string/BackedEnum, principal ausente/status inválido e uso exclusivo de Sanctum, sem bootstrap desnecessário. [BEH-15]
- [ ] 5.2 Verificar presença e execução pós-commit de eventos/solicitação de e-mail em SignUp e ausência em falha, incluindo chamada de Repository dentro da unidade observada. [BEH-01/02]
- [ ] 5.3 Verificar eventos/argumentos de atualização/exclusão de Expense, exclusão de User e classificação efetiva, e ausência em resultados recusados. [BEH-02]
- [ ] 5.4 Provar TransactionAdapter real para commit/resultado/falha, afterCommit externo, retry e descarte de callbacks abortados com PostgreSQL, preservando cenários já existentes úteis. [BEH-01/02]
- [ ] 5.5 Substituir catches permissivos nos cenários de rollback por exceção sentinela com verificação de causa e escrita anterior; repetir os testes afetados. [BEH-01]
- [ ] 5.6 Cobrir formatter/adapter/correlação de requests e worker/CLI com assertions estruturais de JSON e campos sensíveis; incluir ID/timestamp com dígitos coincidentes com amount. [BEH-16]
- [ ] 5.7 Tornar falha de destino de log determinística com recurso controlado, comprovando preservação da escrita confirmada sem depender de caminho absoluto incidental. [BEH-16]

## 6. Fechar lacunas de Identity

- [ ] 6.1 Cobrir cadastro HTTP completo: pending/unverified, canonicalização, hash, ausência de token/segredos, Location e type/ID/relacionamento. [BEH-03]
- [ ] 6.2 Cobrir confirmação divergente, senha nos limites e inválida por caracteres/bytes, nome/e-mail inválidos, type/atributos extras, pointers e ausência de persistência/notification. [BEH-03]
- [ ] 6.3 Cobrir preservação de senha com espaços usando hash e login real, sem normalização implícita da fixture. [BEH-03/04]
- [ ] 6.4 Cobrir login real com e-mail equivalente, dois tokens distintos, resposta segura e erros uniformes para credenciais inválidas/usuário ausente/hash não autenticável, sem emissão indevida. [BEH-04]
- [ ] 6.5 Preservar e completar recusa pending/blocked/unverified, Bearer real e SignOut após remoção da verificação, além de revogação seletiva. [BEH-04]
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
- [ ] 9.5 Preservar Metrics Application: encaminhamento único, null versus vazio, catálogo/ordem, grandes valores, reconciliação/percentuais/IDs e falhas de identidade/leitura/projeção. [BEH-17]
- [ ] 9.6 Verificar arquitetura atual, Data imutáveis/pureza e permissões pontuais de Core, avaliando reflexão por propósito; não ampliar allowlists para acomodar testes. [BEH-18]
- [ ] 9.7 Atualizar referências correntes afetadas em add-expense-metrics se caminhos mudarem, sem editar sua evidência histórica/checklists como se a implementação futura estivesse feita. [BEH-17]

## 10. Completar isolamento e paralelismo obrigatório

- [ ] 10.1 Substituir limpeza restrita a três tabelas por política explícita de todos os recursos usados, respeitando FKs/migrations/metadata e suportando commits reais; incluir jobs/failed_jobs quando necessários. [ISO-03]
- [ ] 10.2 Registrar cleanup de filas/chaves/cache por cenário/execução/processo em finally/teardown, com IDs/namespaces únicos e sem FLUSHALL/FLUSHDB. [ISO-05]
- [ ] 10.3 Isolar caminhos temporários de logs e restaurar relógio/timezone, guards, listeners/fakes/bindings, canais e query logs, com provas de execução reordenada. [ISO-06]
- [ ] 10.4 Implementar protocolo reutilizável estreito de concorrência se necessário, com conexão nova no filho, sinais, erro explícito, timeout, rollback, sockets fechados e espera/encerramento limitado. [ISO-07]
- [ ] 10.5 Configurar parallel testing nativo para dois ou mais processos, com bancos exclusivos e guard do destino efetivo antes da preparação/limpeza. [ISO-04]
- [ ] 10.6 Provar isolamento entre processos com fixtures de e-mail/IDs coincidentes, recurso sentinela por banco/namespace e limpeza que não atinge o outro destino. [ISO-04/05]
- [ ] 10.7 Provar duas invocações concorrentes com tokens de processo iguais e runIds diferentes, verificando bancos/Redis/filas/logs exclusivos e conclusão independente. [ISO-04]
- [ ] 10.8 Provocar falha controlada após criação de job/chave/processo e verificar cleanup completo, zero transações abertas e ausência de filhos/recursos abandonados. [ISO-03/05/07]
- [ ] 10.9 Documentar seleção de grupos e pré-requisitos em orientação existente, com comando canônico que inclui Redis/concorrência no gate; skip local não conta como prova. [ISO-02/08]

## 11. Executar o gate e registrar evidências reais

- [ ] 11.1 Executar arquivos afetados isolados e suítes focadas Unit/Feature de Core, Identity, Expense, Insights e Metrics implementado; registrar comandos, resultados e skips. [ISO-09]
- [ ] 11.2 Executar arquitetura e verificar preservação da matriz de app, autoload de Support e ausência de bootstrap de serviços nos unitários puros. [ORG-08, BEH-18]
- [ ] 11.3 Executar Laravel Pint via tooling Lerd com `--dirty --format agent` após a última mudança PHP e repetir testes afetados pelo formatter. [ISO-09]
- [ ] 11.4 Executar suíte completa na ordem padrão e em duas seeds aleatórias registradas, incluindo 20261009 e outra seed distinta, com todos os grupos obrigatórios. [ISO-09]
- [ ] 11.5 Executar gate completo com pelo menos dois processos e o cenário de duas invocações simultâneas; registrar número de processos, grupos e identidade segura dos recursos. [ISO-04/09]
- [ ] 11.6 Confirmar bootstrap de banco vazio/pending migration e falhas seguras do guard no nível apropriado, sem recriar banco operacional ou usar migrate:fresh. [ISO-01/02]
- [ ] 11.7 Finalizar o mapa de cenários antigos e a matriz abaixo com cenário/dataset, caminho, comando, resultado e limitação; justificar consolidações sem meta fixa de quantidade. [ORG-07, BEH-18]
- [ ] 11.8 Investigar qualquer falha aleatória/paralela/isolada e manter requisito/tarefa pendente se blocked; perguntar antes de corrigir produção, sem alterar contrato para fazer teste passar. [ISO-09]
- [ ] 11.9 Validar esta mudança OpenSpec estritamente e revisar consistência de todos os artefatos; aplicar o quality gate de código somente no apply autorizado, sem confundir artefatos completos com entrega implementada. [ISO-09]
- [ ] 11.10 Apresentar evidências finais, limitações e alterações de comandos; sincronizar/arquivar somente mediante solicitação, com todos os cenários obrigatórios comprovados e sem skips inesperados.

## Matriz de rastreabilidade planejada

Cada linha cobre **todos os cenários do requisito identificado**. No apply, desdobrar em uma linha por Scenario/dataset com caminho final e comando efetivo, preservando esta correspondência. Estado inicial: **Planejado, não executado por esta mudança** para todas as linhas. Resultados da revisão são históricos e não marcam tarefas como concluídas.

| Requisito | Tarefas | Evidência preferida |
| --- | --- | --- |
| ORG-01 | 1.3, 4.8–4.10 | Inventário/destinos e execução por caminho/contexto. |
| ORG-02 | 4.8–4.10, 4.12 | Arquivos coesos e execução independente. |
| ORG-03 | 4.1–4.5 | Classes Support tipadas/autoloadáveis, doubles fora dos cenários substanciais. |
| ORG-04 | 4.2, 4.5, 5.2–5.3 | Expectativas locais e fakes nativos preservados. |
| ORG-05 | 4.4, 4.7, 6.1 | Fixtures explícitas e jornadas reais sem mutação oculta. |
| ORG-06 | 4.6–4.7, 9.2, 9.5 | Builders válidos/negativos e esperados independentes. |
| ORG-07 | 1.3, 4.8–4.12, 11.7 | Mapa de cada cenário antigo/destino/consolidação. |
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
| BEH-17 | 1.4, 4.7, 9.5, 9.7 | Application de Metrics preservada, sem claims de SQL/HTTP futuros. |
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
- Todas as tarefas de implementação permanecem pendentes.
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
- Nenhuma tarefa de produto/Metrics futuro foi implementada sem autorização; divergências e bloqueios permanecem explícitos.
- Relatório não afirma coverage percentual, escala ou concorrência não medida e distingue esta entrega das evidências históricas.
