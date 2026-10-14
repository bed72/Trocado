## 1. Decisões e autorização antes da implementação

- [x] 1.1 Obter autorização explícita de implementação; este checklist é trabalho futuro e não autoriza código, dependência ou execução de testes por causa da criação da spec.
  - Autorização recebida para a fatia de cadastro (migration, persistência, POST/DELETE e verificações focadas); não autoriza transporte, queue ou produtores.
- [ ] 1.2 Resolver plataformas/SDKs e comprovar o perfil de registro aceito pelo cliente e transporte (token/FID); ajustar catálogo de plataformas, `registration_kind` e limites nos artefatos antes de codificar.
  - Decisão parcial em 2026-10-13: somente Android/iOS, Flutter com pacotes oficiais Firebase. Catálogo ajustado; versões, método/perfil token/FID, compatibilidade server-side e limites permanecem pendentes de comprovação.
  - Perfil de cadastro confirmado explicitamente pelo usuário: somente token FCM, `registration_kind = token`, `getToken()`/`onTokenRefresh`; limite proposto de 4096 bytes preservado. Versões/payload real e compatibilidade do transporte futuro ainda não comprovados.
- [x] 1.3 Aprovar vínculo do destino ao PAT, suspensão após expiração e fluxo de logout/troca de conta; se push sem sessão for necessário, revisar proposta/design/specs antes de implementar.
  - Usuário escolheu explicitamente opção A em 2026-10-13. POST/DELETE autorizados na fatia de cadastro. Cascades e revalidação no cadastro comprovadas; revalidação no envio continua futura.
- [ ] 1.4 Escolher projeto Firebase por ambiente, método de autenticação e transporte compatível; obter aprovação de nova dependência se necessária, sem assumir suporte de pacote não instalado.
- [ ] 1.5 Confirmar defaults de frescura, validade, retries/timeouts e tolerância à lacuna commit/Redis/FCM; revisar artefatos se a garantia desejada exigir outbox/ledger.
- [ ] 1.6 Registrar decisões resolvidas e executar validação OpenSpec strict novamente, deixando perguntas de ativação e tarefas futuras explicitamente pendentes.
  - Decisões registradas em design/proposal/spec de registro; POST/DELETE autorizados. Exemplo real do cliente e decisões de transporte/ativação permanecem pendentes; exemplo do design é somente contratual.

## 2. Fronteiras e contratos tipados

- [ ] 2.1 Definir o contexto Notifications e seus Inputs/Outputs/VOs mínimos, com invariantes independentes de framework, sem interfaces para UseCases ou abstrações antecipadas. [Registro: fronteiras; Envio: queue/transporte nas bordas]
  - Fatia de registro concluída com VO/Entity/Input/Output; tipos de envio permanecem futuros.
- [ ] 2.2 Definir `NotificationRegistrationRepository` para cadastro, snapshot, consulta por owner/ID e remoção condicional por geração, sem expor ORM ou reutilizar Outputs de UseCases como projeções do Repository. [Registro: ownership, rotação e atomicidade]
  - Cadastro/locks/remoção owner-scoped implementados; snapshot e compare-and-delete de envio permanecem futuros.
- [ ] 2.3 Definir `Notifications\Application\Ports\NotificationPort` e implementar `NotificationAdapter` de Identity para sessão atual, correspondência owner/sessão, verificação bloqueante e elegibilidade temporal, reutilizando a política existente de Identity. [Registro: autoridade de Identity; Envio: revalidação]
  - `lock` implementado e comprovado; capacidade de revalidação de destinatário no worker ainda não criada. Nomes simplificados pelo usuário foram preservados.
  - Ownership revisado pelo usuário: Port pertence ao consumidor Notifications; Adapter/binding pertencem a Identity. Exceção arquitetural restrita somente a essa interface, sem import de Identity por Notifications.
- [ ] 2.4 Definir contrato transversal de intenção de notificação em Core, sua entrada mínima e implementação em Notifications com mapping explícito; não ligar produtor de negócio ainda. A capacidade não é o atual `NotificationPort` de sessão. [Envio: solicitação interna]
- [ ] 2.5 Definir `NotificationTransportPort`, resultados tipados e `NotificationDispatchPort`, distinguindo no_targets, publicação total/parcial, aceitação, descarte e falhas. [Envio: fanout, classificação e aceitação]
- [ ] 2.6 Registrar bindings nas bordas proprietárias e ajustar verificações arquiteturais com permissões específicas para contratos Core, sem allowlist ampla entre contextos. [Registro: fronteiras; Envio: queue/transporte nas bordas]
  - Bindings e permissões exatas da fatia de registro comprovados por `ContextBoundariesTest`; bindings de envio futuros.

## 3. Schema e persistência PostgreSQL

- [x] 3.1 Confirmar schema detalhado das tabelas relacionadas e criar migrations incrementais de criação e renomeação para `notifications` com UUID público/instalação, owner/PAT, plataforma/provedor/tipo, ciphertext, fingerprint SHA-256, geração e timestamps de instante. [Registro: modelo separado]
- [x] 3.2 Implementar constraints de unicidade, valores fechados/geração positiva, índices e cascades de conta/sessão, sem backfill ou alteração de migrations históricas. [Registro: atomicidade e lifecycle]
- [x] 3.3 Implementar cifragem do destino e fingerprint SHA-256 exato sem chave auxiliar; recalcular registros anteriores atomicamente, preservar bytes, evitar truncamento e documentar rotação de cifragem sem tornar dados ilegíveis. [Registro: destino sensível]
- [x] 3.4 Implementar `EloquentNotificationRepository` e `NotificationModel` na organização de persistência do contexto, sem relacionamentos/imports Eloquent de Identity. [Registro: fronteiras]
- [x] 3.5 Implementar cadastro/rotação atômicos com ordem de locks, releitura idempotente/tradução de conflitos e rollback integral. [Registro: sincronização, conflitos e corrida]
- [ ] 3.6 Implementar seleção por proprietário/frescura e compare-and-delete por owner/ID/geração para invalidação, sem apagar geração nova ou outros dispositivos. [Registro: frescura; Envio: invalidação condicional]
- [x] 3.7 Classificar a tabela mutável no cleanup seguro e aplicar migrations pendentes pelo Lerd antes de verificar fluxos do novo schema, sem `migrate:fresh`. [Registro: evidência PostgreSQL]

## 4. Application e contrato HTTP de registro

- [x] 4.1 Implementar UseCases de cadastro/remoção com `UserPort`, aptidão/sessão pela capacidade transversal e unidade `TransactionPort`; resolver instante na borda, sem clock/config/ORM em Application. [Registro: cadastro autenticado e atomicidade]
- [x] 4.2 Implementar Request JSON:API fechado com UUID, catálogo aprovado, tipo compatível e destino exato; rejeitar membros server-owned e gerar pointers seguros. [Registro: documento fechado]
- [x] 4.3 Implementar Controllers finos, `NotificationResponse`, `201`/`200`, atributos públicos mínimos e `no-store`; não criar Location para GET inexistente. [Registro: resposta mínima]
- [x] 4.4 Registrar POST/DELETE com Sanctum, conta ativa/verificada, cota compartilhada existente e nomes de rota previstos; não ativar extensão de sessão por sincronização push. [Registro: autenticação e cota]
- [x] 4.5 Implementar remoção owner-scoped `204` e `404` uniforme para ausente/alheio/malformado, preservando sessões e outras instalações. [Registro: remoção]
- [x] 4.6 Mapear falhas de validação/conflito/infraestrutura para JSON:API sanitizado e conferir ausência de GET global ou HTTP de disparo. [Registro: conflito/segredos; Envio: capacidade interna]

## 5. Solicitação, queue e worker

- [ ] 5.1 Implementar validação da intenção: UUID, texto genérico aprovado, catálogo fechado, strings permitidas, limite serializado de 4 KiB e prazo de até uma hora. [Envio: mensagem e expiração]
- [ ] 5.2 Implementar solicitação com snapshot owner-scoped, elegibilidade, no_targets e fanout de um job por registro/geração, sem token/credencial no payload. [Envio: fanout]
- [ ] 5.3 Implementar `QueueNotificationDispatchAdapter` em Redis/fila push, com resultado de publicação total/parcial e ausência de fallback síncrono/republicação do lote inteiro. [Envio: commit/publicação e fanout]
- [ ] 5.4 Implementar job fino e `SendNotificationUseCase` com releitura e revalidação de geração, owner, frescura, sessão/conta e prazo antes de cada tentativa. [Envio: revalidação]
- [ ] 5.5 Implementar descarte de jobs removidos/obsoletos/expirados e TTL por tempo restante, preservando notification_id em retries/redelivery. [Envio: expiração e duplicação]
- [ ] 5.6 Configurar timeout de request/job/retry_after, número máximo de tentativas, jitter, backoff, quota e Retry-After com limites de expiração; comprovar que rede não executa sob transação/lock. [Envio: retry e bordas]

## 6. Transporte Firebase e observabilidade

- [ ] 6.1 Implementar `FirebaseNotificationTransportAdapter` com método e autenticação aprovados, projeto por ambiente e compatibilidade explícita do tipo/plataforma; normalizar exceções na borda. [Envio: transporte server-side]
- [ ] 6.2 Mapear accepted/message ID, UNREGISTERED, INVALID_ARGUMENT discriminado, projeto/permissão/payload permanente, quota/5xx e falhas de rede. [Envio: aceitação, invalidação e retry]
- [ ] 6.3 Aplicar invalidação atômica apenas à geração enviada; não apagar destino por payload ambíguo, timeout, indisponibilidade ou projeto incompatível. [Envio: invalidação condicional]
- [ ] 6.4 Configurar credencial privada fora do repositório e fornecer apenas referências/examples sem segredos; verificar cifragem/fingerprint e isolamento de projeto por ambiente. [Registro: segredo; Envio: configuração]
- [ ] 6.5 Implementar eventos estruturados por allowlist, correlação request/notification_id e mutações após commit, com falha de logger não destrutiva. [Envio: diagnóstico]
- [ ] 6.6 Sanitizar logs/failed jobs de exceções com request/headers/resposta brutos; verificar ausência de token/FID/fingerprint, Bearer, credencial, conteúdo financeiro e mensagem fora do payload mínimo da queue. [Envio: diagnóstico]

## 7. Evidência futura por responsabilidade

- [ ] 7.1 Criar Unit puro de Domain/Application para destinos exatos, catálogos, limites, expiração/frescura, orquestração transacional, geração e resultados/no_targets, sem bootstrap/PG/Redis. [Registro: documento/frescura; Envio: intenção]
  - Registro coberto por 16 Unit puros; frescura/intenção/no_targets futuros.
- [x] 7.2 Criar HTTP Feature de POST `201`/`200`, DELETE `204`/`404`, Bearer real, aptidão, não extensão, conflito, documento fechado/pointers, resposta sem segredo e cota compartilhada/Retry-After. [Registro: contrato HTTP]
- [x] 7.3 Criar Infrastructure Feature PostgreSQL para unicidade/cifragens/mapping, rotação/rollback sentinela, cascades de sessão/conta e independência de instalações. [Registro: persistência e lifecycle]
- [x] 7.4 Provar corridas sincronizadas em conexões/processos novos: cadastro igual, disputa entre contas, rotações e cadastro versus logout; usar barreiras, timeout limitado, diagnóstico e cleanup exclusivo. [Registro: atomicidade concorrente]
- [ ] 7.5 Criar Application/Infrastructure de fanout, publicação parcial/Redis indisponível, descartar removido/rotacionado/inelegível/expirado, payload sem destino e TTL restante. [Envio: publicação, fanout e revalidação]
- [ ] 7.6 Provar after-commit/rollback com commit real, sem transação externa que impeça callbacks, preservando estado de negócio quando queue falha. [Envio: fronteira de publicação]
- [ ] 7.7 Criar Adapter Feature com transporte HTTP/SDK simulado para aceitação, invalidez, INVALID_ARGUMENT ambíguo, falha de configuração, quota/Retry-After, 5xx/timeout e sanitização; não chamar Firebase real. [Envio: transporte e falhas]
- [ ] 7.8 Provar compare-and-delete sob rotação concorrente enquanto resposta antiga está em voo, com transporte controlado e banco real, sem alegar corrida a partir de teste sequencial. [Envio: invalidação condicional]
- [ ] 7.9 Provar consumo real de worker em fila Redis exclusiva, retry só do destino falho, máximo de tentativas/expiração e correlação isolada entre jobs; chamada manual de handle não substitui essa evidência. [Envio: worker e retry]
- [ ] 7.10 Criar verificações de bindings/arquitetura e observabilidade JSON decodificada, incluindo falha do logger após commit e segredos ausentes em logs/failed jobs. [Registro: fronteiras; Envio: diagnóstico]
  - Arquitetura e metadados de registro após commit/falha de logger comprovados; logs JSON integrais e failed jobs de envio permanecem futuros.
- [ ] 7.11 Executar arquivos afetados isoladamente e suítes focadas pelo launcher `lerd composer test -- ...`, registrando comandos, resultados, skips/limitações e evidência por cenário; usar recursos exclusivos e cleanup sem FLUSHALL/FLUSHDB.
  - Verificações da fatia de registro concluídas conforme evidência abaixo; tarefas de envio pendentes.
- [ ] 7.12 Executar Pint `--dirty --format agent` após mudanças PHP e verificações adequadas às fronteiras compartilhadas; marcar somente tarefas realmente comprovadas.
  - Pint e gate completo executados para esta fatia; nova execução será necessária após futuras mudanças PHP.

## 8. Ativação, documentação e fechamento

- [ ] 8.1 Aprovar primeiro evento/caller, texto/navigation e dados permitidos; atualizar artefatos antes de qualquer integração que amplie escopo. Sem essa decisão, manter produtores de produto desligados.
- [ ] 8.2 Com a aprovação do gatilho, conectar a intenção via contrato Core somente após commit e acrescentar cenários/evidência específicos do evento aprovado, sem imports entre contextos.
- [ ] 8.3 Atualizar documentação existente de API/arquitetura/operação para instalação local, perfil SDK, rotação, conflito, logout offline, queue, segredos e limites de garantia, sem documentar suporte não comprovado.
  - README e ARCHITECTURE atualizados para cadastro, cifragem e fingerprint SHA-256; queue/envio futuros.
- [ ] 8.4 Obter projeto/instalação de teste consentidos e validar smoke test real para as plataformas aprovadas, distinguindo aceitação FCM, recepção foreground/background e action com ownership atual.
- [ ] 8.5 Verificar operação Lerd nas áreas afetadas: migrations pendentes, worker/timeouts, logs sanitizados e diagnóstico de queries/rotas alteradas, com evidência focada sem credenciais.
- [ ] 8.6 Validar rollback operacional (produtores/worker/rotas), preservação dos dados cifrados e incompatibilidade de jobs antigos; não executar drop ou rollback destrutivo sem autorização.
- [ ] 8.7 Revisar matriz requisito/cenário → evidência, resolver bloqueadoras, registrar lacunas externas/duplicação/publicação e validar OpenSpec strict. Não declarar implementado/arquivável enquanto decisões ou tarefas exigidas estiverem pendentes.

## 9. Rastreabilidade e estado documental

Cada item acima referencia a responsabilidade normativa nas duas delta specs. Na implementação, a matriz deve registrar todos os cenários individualmente, com arquivo/comando/resultado e classificação Proven, Partially proven, Unproven ou Blocked. Cenários de concorrência exigem corrida sincronizada; cenário de worker exige consumo real; recepção FCM exige homologação externa.

Estado inicial histórico: **todos os cenários de produto estavam Unproven** na criação documental. A fatia de cadastro autorizada foi implementada e verificada em 2026-10-13 conforme a matriz abaixo. Envio, elegibilidade no worker, homologação externa e tarefas futuras continuam pendentes; a mudança completa ainda não é candidata a archive.

### Evidência da fatia de cadastro — 2026-10-13

Arquivos de evidência (aliases somente para esta matriz):

- **HTTP**: `tests/Feature/Notifications/Presentation/Http/NotificationRegistrationHttpTest.php` — 31 testes; anteriormente `PushRegistrationHttpTest.php`.
- **PG**: `tests/Feature/Notifications/Infrastructure/Repositories/Persistence/EloquentNotificationRepositoryTest.php` — 16 testes; anteriormente `EloquentPushRegistrationRepositoryTest.php`.
- **Race**: `tests/Feature/Notifications/Infrastructure/Repositories/Persistence/NotificationRegistrationConcurrencyTest.php` — 6 testes, conexões novas, ready/go/done e espera de lock PostgreSQL observada; anteriormente `PushRegistrationConcurrencyTest.php`.
- **VO**: `tests/Unit/Notifications/Domain/ValueObjects/NotificationValueObjectTest.php` — 9 testes puros; anteriormente `PushDestinationValueObjectTest.php`.
- **Entity**: `tests/Unit/Notifications/Domain/Entities/NotificationRegistrationEntityTest.php` — 4 testes puros; anteriormente `PushRegistrationEntityTest.php`.
- **UseCase**: `tests/Unit/Notifications/Application/UseCases/CreateNotificationUseCaseTest.php` — 3 testes puros; o fake observa escopo e callbacks, sem alegar rollback real. Anteriormente `RegisterPushRegistrationUseCaseTest.php` e depois `CreatePushUseCaseTest.php`.
- **Arch**: `tests/Unit/Architecture/ContextBoundariesTest.php` — 30 testes no arquivo/suíte arquitetural.

Cada arquivo acima passou isoladamente pelo launcher `lerd composer test -- <arquivo> --compact`. Unit/Notifications também passou como suíte. HTTP foi repetido após ajuste de preservação de ciphertext; PG e HTTP passaram novamente no gate após Pint. Nenhum envio Firebase foi executado.

| Cenário de push-registration | Estado | Evidência/limite |
| --- | --- | --- |
| Dois dispositivos da mesma conta | Proven | HTTP: coexistência, sincronização e rotação com duas linhas |
| Identidade local não autentica | Proven | HTTP: Bearer ausente/inválido/expirado/revogado |
| Conta apta | Proven | HTTP: criação, sessão associada, sem emissão/extensão |
| Conta não apta | Proven | HTTP + PG: bloqueada/pendente/não verificada e releitura da conta |
| Cota compartilhada | Proven | HTTP: cota consumida em User, outro PAT/IP recebe 429/Retry-After |
| Tentativa de definir proprietário | Proven | HTTP: dataset fechado de membros server-owned e pointers |
| Destino inválido | Proven | VO + HTTP: controles, whitespace, Unicode, tipo e tamanho |
| Tipo sem suporte | Proven | VO + HTTP: fid rejeitado |
| Plataforma web fora desta entrega | Proven | HTTP: web rejeitado com pointer |
| Primeiro cadastro | Proven | HTTP: 201; PG: geração positiva/UUID |
| Cadastro repetido | Proven | HTTP + Entity: mesmo ID, uma linha por instalação, geração e ciphertext preservados |
| Token renovado | Proven | HTTP + Entity: destino novo e geração incrementada, sem acumular antigo |
| Novo login na mesma conta | Proven | HTTP: rebind ao PAT novo e SignOut anterior preserva registro |
| Troca de conta sem revogar vínculo anterior | Proven | HTTP: conflito sem tomada da instalação/destino |
| Destino duplicado na mesma conta | Proven | HTTP: conflito entre UUIDs |
| Troca de conta após logout confirmado | Partially proven | Remoção por SignOut e rejeição de takeover comprovadas; jornada completa de nova conta no mesmo UUID ainda não exercitada |
| Duas primeiras sincronizações iguais | Proven | Race: 201/200 e uma linha; mesma sessão e nova sessão do mesmo owner |
| Duas contas disputam destino disponível | Proven | Race: segunda conta bloqueada pela unicidade, recebe 409 |
| Rotação concorrente | Proven | Race: último commit aceito, token/plataforma/sessão coerentes e geração 3 |
| Cadastro disputa com SignOut | Proven | Race: ambas as ordens, sem recriação após revogação |
| Falha após escrita dentro da unidade | Proven | PG: sentinel após escrita observada e comparação integral do estado anterior; callbacks não emitidos |
| Remoção de instalação própria | Proven | HTTP: 204, registro removido e PAT preservado; query owner-scoped |
| Registro alheio ou ausente | Proven | HTTP: 404 idêntico para alheio/ausente/malformado/repetido |
| SignOut seletivo | Proven | HTTP: duas sessões, vínculo reatribuído preservado e antigo removido |
| Conta removida | Proven | PG: cascade de user remove registros |
| Sessão expirada ainda no banco | Partially proven | HTTP + PG: POST 401, inclusive após snapshot do guard; elegibilidade no envio ainda futura |
| Limite de frescura | Unproven | Seleção/envio não implementados nesta fatia |
| Ressincronização válida | Partially proven | Sincronização renova referência; seleção de destinos stale ainda futura |
| Cadastro responde sem segredo | Proven | HTTP: allowlist pública, no-store, sem Location/destino |
| Conversão de fingerprints existentes | Proven | NotificationFingerprintMigrationTest: SHA-256, ciphertext/metadados preservados e sincronização idempotente |
| Falha durante conversão | Proven | NotificationFingerprintMigrationTest: primeira escrita observada no query log e rollback integral após segunda decifragem falhar |
| Inspeção de persistência e diagnóstico | Partially proven | PG: ciphertext/fingerprint/Hidden; metadados afterCommit permitidos. Inspeção integral de logs JSON ainda futura |
| Inspeção de dependências | Proven | Arch + revisão de bindings proprietários, sem imports de Identity em Notifications |

Todos os cenários de `firebase-push-delivery` permanecem **Unproven** nesta fatia: não há solicitação/transporte/worker/TTL/retries/invalidação ou recepção externa implementados. A prova de eventos de registro após commit não comprova publicação after-commit de push. Os limites acima não impedem os quatro critérios de conclusão de cadastro, mas impedem declarar a mudança completa implementada/arquivável.

Verificações transversais executadas:

- `lerd artisan migrate --no-interaction`: migration `2026_10_13_212150_create_push_registrations_table` aplicada incrementalmente; Boost confirmou uniques, índices, CHECK e duas FKs cascade.
- `lerd artisan route:list --path=push-registrations -v`: somente POST/DELETE com Sanctum, conta ativa/verificada e throttle compartilhado; sem `session.extend`.
- `lerd pint --dirty --format agent` (MCP vendor_run): ajustes somente de imports não utilizados nos dois arquivos Feature.
- Após a revisão final de `SensitiveParameter` nas bordas de persistência, Pint passou sem ajustes e PG foi repetido isoladamente: **16 testes / 55 assertions, passando**.
- `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **1507 testes / 20180 assertions, passando**.
- `lerd composer test -- --order-by=random --random-order-seed=20261009 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **1507 / 20180, passando**.
- `lerd composer test -- --order-by=random --random-order-seed=20261010 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **1507 / 20180, passando**.
- `lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **1507 / 20180, passando**. Gate inclui Redis/concorrência e teste existente de invocações simultâneas.
- Tentativas MCP agrupadas da segunda seed/paralelo tiveram timeout e não foram contabilizadas como aprovação. Após confirmar ausência de processo ativo, ambas foram executadas individualmente com resultados acima.
- Request real no Lerd: POST sem credencial respondeu 401 JSON:API. `dumps_toggle` já ativo; `optimize_route` retornou sem rotas lentas, com somente uma amostra não autenticada. Não é evidência de desempenho do cadastro autenticado em produção; HTTP/PG/Race usam bancos exclusivos de teste.
- Histórico da primeira fatia: chave HMAC aleatória configurada somente no `.env` local ignorado pelo Git; exemplo sem segredo. Em revisão posterior autorizada pelo usuário, HMAC/configuração/env foram removidos em favor de SHA-256; cifragem pela APP_KEY permanece. Nenhuma nova dependência foi instalada.
- `openspec validate add-firebase-push-notifications --type change --strict --json --no-interactive`: **valid = true**, sem issues. `git diff --check`: sem problemas. A alteração pré-existente de `SignInOutput` foi preservada.

### Revisões posteriores autorizadas: nomes, tabela, Bruno, fingerprint e ownership

- Classes/arquivos de produto usam `Notification`, preservando as simplificações do usuário. Nomes explícitos aprovados: `CreateNotificationController`, `CreateNotificationRequest` e `NotificationValueObject`. Imports, bindings, rotas e testes atualizados; expectativas `lock`/`update`/`delete` e argumentos nomeados acompanham as assinaturas atuais. Não há referências `Push` nas classes de produto.
- Os seis arquivos de testes anteriores foram renomeados um a um para os destinos listados acima, sem remover/consolidar cenários. `NotificationRegistrationFixture` substitui `PushRegistrationFixture`. Os resultados isolados são: VO 9/11 assertions, Entity 4/15, UseCase 3/33, HTTP 31/215, PG 16/64, Race 6/27 e Arch 30/456. São verificações dos cenários preservados, não equivalência inferida apenas das contagens.
- `rename_push_registrations_to_notifications` aplicada no Lerd: tabela, uniques, CHECK, índices e FKs renomeados incrementalmente. Boost confirmou schema `notifications` e cascades. Migration histórica de criação foi preservada.
- `bruno/Notifications/01 - Create Notification.bru` e `02 - Delete Notification.bru` adicionados seguindo as requisições existentes. POST captura ID em 201/200; variáveis de instalação/plataforma/ID e `notificationToken` secreto definidos nos environments. Endpoints, resource type e eventos técnicos mantêm o contrato push existente. Não houve execução dessas requisições contra produção nem exposição de token real.
- Usuário autorizou eliminar HMAC: removidos `config/notifications.php`, chave de `.env`/`.env.example` e dependência de config do Repository. Fingerprint usa `SHA-256(provider + NUL + kind + NUL + identifier)`; cifragem pela APP_KEY permanece. Banco operacional tinha zero registros na inspeção pré-migration; migration incremental também contempla ambientes com registros existentes.
- `2026_10_13_224125_recalculate_notification_fingerprints` aplicada no Lerd. `tests/Feature/Notifications/Infrastructure/Database/NotificationFingerprintMigrationTest.php` passou isoladamente com **2 testes / 12 assertions**: preservação de ciphertext/metadados, deduplicação após conversão e rollback após escrita anterior observada. Reversão para valores antigos exige restauração explícita; não há chave auxiliar no runtime atual.
- Usuário aprovou `NotificationPort` em `Notifications/Application/Ports`, implementado por `NotificationAdapter` em Identity. Binding fica em Identity; permissão arquitetural limitada a `App\Notifications\Application\Ports\NotificationPort`. A regra anterior de contrato específico em Core foi revisada explicitamente; Notifications continua sem imports de Identity/Sanctum.
- Pint `--dirty --format agent` executado; arquivos alterados pelo formatter foram reverificados. OpenSpec strict passou sem issues; `git diff --check` sem problemas.
- Gate final pelo launcher, sempre com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: padrão **1509 testes / 20201 assertions**, seed **20261009: 1509/20201**, seed **20261010: 1509/20201**, paralelo **--parallel --processes=2: 1509/20201**, todos passando. Inclui grupos Redis/concorrência e invocações simultâneas existentes.
- Registro de intercorrências: durante renomeações simultâneas do usuário, um gate encontrou cinco falhas de expectativas/permissões antigas; foram alinhadas a `NotificationPort::lock()` e o gate final acima passou. Uma tentativa de seed anterior foi abortada e não conta como evidência. Resultados históricos anteriores foram preservados, não substituídos por aprovação fictícia.
- Envio Firebase, queue push, homologação do SDK/payload real e demais tarefas futuras continuam pendentes; essas revisões não tornam a mudança completa arquivável.
- Checagem HTTP final no Lerd: POST sem credencial respondeu 401 JSON:API. `optimize_route` retornou sem amostras disponíveis; não comprova desempenho autenticado em produção. As provas de cadastro/persistência/concorrência acima continuam provenientes dos bancos exclusivos do launcher.
