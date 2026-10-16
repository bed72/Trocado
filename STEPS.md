# Mapa de implementação — UUIDv7

Change: **`standardize-uuid-v7-identifiers`**.

Este mapa organiza as **108 tarefas em 14 steps** para implementar por pedaços. A numeração dos itens corresponde à da spec, permitindo pedir uma etapa inteira ou uma tarefa específica.

## Fontes de verdade

- [Proposta e decisões](openspec/changes/standardize-uuid-v7-identifiers/proposal.md)
- [Desenho técnico](openspec/changes/standardize-uuid-v7-identifiers/design.md)
- [Requisitos e cenários](openspec/changes/standardize-uuid-v7-identifiers/specs/)
- [Checklist oficial e matriz de evidências](openspec/changes/standardize-uuid-v7-identifiers/tasks.md)
- [Arquitetura do projeto](ARCHITECTURE.md)

`tasks.md` é a fonte oficial de progresso e evidências. Ao concluir uma tarefa, registre lá os comandos/resultados e sincronize o checkbox deste mapa. Se houver divergência, confira a evidência antes de atualizar o status. Todos os itens começam pendentes; criar este arquivo não implementa nenhuma etapa.

## Decisões que guiam todos os steps

1. IDs próprios de entidades, sessões/PATs e recursos da API serão **UUIDv7 canônicos**.
2. Insights, Metrics e sugestões terão **UUIDv7 estáveis**, reutilizados por identidade lógica.
3. O registro de associações fica no **Core** e guarda somente identidade técnica, sem resultados financeiros ou textos.
4. `installation_id` recebido do cliente exige **UUIDv7**.
5. IDs internos de Laravel/SDKs mantêm seus contratos nativos. Valores, datas, contagens, códigos de categoria, segredos e fingerprints não são IDs a converter.
6. Reset foi autorizado somente para o **banco local de desenvolvimento**, no momento da implementação e após conferir o alvo.
7. Bancos de teste continuam pelo launcher seguro, com ownership e migrations incrementais; não usam `migrate:fresh`.

## Como usar este mapa

Exemplos de pedidos:

> Implemente apenas as tarefas 2.1–2.3 do STEPS.md. Faça as provas focadas e registre as evidências antes de marcar os itens.

> Continue pela próxima tarefa pendente do STEP 04, respeitando as dependências. Pare ao concluir a tarefa.

> Revise se o STEP 07 já tem evidências suficientes para liberar Insights, Metrics e sugestões.

Para cada pedaço:

1. Conferir as dependências e ler os requisitos/design correspondentes.
2. Implementar a menor fatia coerente, incluindo os chamadores e provas afetados.
3. Executar verificações adequadas pelo launcher; após PHP, executar Pint.
4. Registrar resultados, falhas, skips e limitações no checklist oficial.
5. Marcar somente o que foi comprovado e sincronizar este mapa.

Alterações de interfaces exigem atualização das implementações na mesma fatia. Não publicar nem tratar como pronta uma API com tipos/schema misturados. Fixtures e doubles necessários a uma prova são atualizados naquele step; o STEP 11 fecha a auditoria transversal, não adia correções que já impedem os testes focados.

## Ordem e dependências

| Step | Área | Depende de | Libera |
| --- | --- | --- | --- |
| 01 | Preparação e inventário | — | Planejamento do apply |
| 02 | UUIDv7 puro em Core | 01 | Validação e fixtures |
| 03 | Schema e cleanup | 02 | Provas PostgreSQL no schema novo |
| 04 | Identity, owner Core e Sanctum | 02–03 | Autenticação e owner UUID |
| 05 | Expense e paginação | 04 | CRUD/classificação/cache UUID |
| 06 | Notifications | 04 | Registro/instalação UUIDv7 |
| 07 | Registro estável de Core | 02–04 | Identidade das projeções |
| 08 | Insights | 05 e 07 | Insights UUIDv7 estáveis |
| 09 | Metrics | 05 e 07 | Resumos UUIDv7 estáveis |
| 10 | Sugestões | 05 e 07 | Sugestões UUIDv7 estáveis |
| 11 | Integração transversal | 04–10 | Build coerente e provas cruzadas |
| 12 | Aplicação local e diagnóstico | 11 | Ambiente local convertido |
| 13 | Documentação, Bruno e cliente | 11–12 para execução real | Contrato consumível |
| 14 | Gates e fechamento | 01–13 | Conclusão com evidências |

As frentes 05, 06 e 07 podem ser organizadas separadamente depois da base 04; 08, 09 e 10 usam a mesma capacidade pronta de Core. A sequência acima é conservadora para evitar validar projeções sobre contratos financeiros ainda em conversão. Documentação da fase 13 pode ser preparada antes da aplicação local; sua execução autenticada depende do ambiente coerente.

## STEP 01 — Preparação e inventário

**Entrega:** escopo autorizado, inventário por papel e fatias/dependências documentadas.

- [x] **1.1** Obter autorização do apply e dos testes da etapa corrente.
- [x] **1.2** Revalidar OpenSpec e reconferir versões/APIs instaladas: UUIDv7, PAT, morph UUID, cursor e bulk insert.
- [x] **1.3** Inventariar PKs, FKs, contratos, rotas, casts, cache, queues e fixtures que pressupõem ID inteiro.
- [x] **1.4** Fechar componentes canônicos de identidade de Insights, Metrics e sugestões, incluindo batch e limite de queries.
- [x] **1.5** Coordenar a spec ativa de Firebase sem antecipar implementação de envio/cliente.
- [x] **1.6** Definir fatias coerentes e impedir publicação de tipos/schema misturados.

**Concluir quando:** cada identificador inventariado tem um destino explícito; valores/segredos/IDs técnicos estão distinguidos dos IDs próprios.

**Concluído em 2026-10-14:** inventário arquivo/campo/destino, APIs instaladas, matriz canônica, dependências e evidências no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-01--preparação-e-inventário--2026-10-14). OpenSpec strict das duas changes e `git diff --check` passaram. Esta etapa comprova a preparação; implementação UUIDv7 e provas PHP começam no STEP 02.

## STEP 02 — Conceito UUIDv7 puro em Core

**Entrega:** validação pura e fixtures determinísticas, sem necessidade de banco.

- [x] **2.1** Implementar `UuidValueObject` e exceção de formato/versão/variante/equivalência.
- [x] **2.2** Provar casos válidos e inválidos, caixa equivalente e ausência somente nos pontos permitidos.
- [x] **2.3** Criar fixture tipada de UUIDv7 para IDs distintos e ordenação controlada.
- [x] **2.4** Definir nomes/tipos dos contratos e Data de identidade Core.
- [x] **2.5** Ajustar permissões arquiteturais específicas e provar pureza/dependências.
- [x] **2.6** Executar Unit Core isolado pelo launcher e registrar resultados.

**Concluir quando:** inteiro, hash, whitespace, nil, variante inválida e outras versões não passam como UUIDv7; Domain não gera IDs nem consulta relógio/framework.

**Concluído em 2026-10-14:** VO/exceção puros, fixture determinística, nomes/tipos dos contratos futuros e permissões específicas documentados. VO isolado (39), fixture (4), Unit Core (251) e arquitetura (30) passaram; gate completo passou com 1.865 testes no padrão, seeds 20261014/20261015 e paralelo de dois processos. Pint aplicado. Comandos, cenários e limites estão no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-02--conceito-uuidv7-puro-em-core--2026-10-14). Integração nullable das Entities e implementação do registro seguem nos steps próprios.

## STEP 03 — Schema UUIDv7 e cleanup seguro

**Entrega:** bootstrap completo do schema novo, validado em PostgreSQL exclusivo de teste.

- [x] **3.1** Converter a PK de `users`, preservando seus demais campos/constraints.
- [x] **3.2** Converter PK e `tokenable_id` de `personal_access_tokens` para UUID.
- [x] **3.3** Converter `expenses.id/user_id`, preservando FK, índices e campos financeiros.
- [x] **3.4** Ajustar criação/rename de `notifications`: registro, owner, sessão e instalação UUIDv7.
- [x] **3.5** Criar `resource_identities` com associação mínima, unique composto e cascade de owner.
- [x] **3.6** Implementar checks de v7/variante/obrigatoriedade e eliminar chave inteira paralela nas tabelas próprias.
- [x] **3.7** Classificar a tabela nova no cleanup e preservar os guards do launcher.
- [x] **3.8** Provar schema, FKs, uniques e checks em banco exclusivo com migrations incrementais.

**Concluir quando:** schema novo aceita apenas identidades próprias válidas e rejeita referências órfãs. O reset do banco local fica no STEP 12.

**Escopo de schema concluído em 2026-10-14:** prova PostgreSQL isolada 171 testes/443 assertions; guard 15/50; isolamento 9/88, incluindo duas invocações; Unit completo 1.089/32.126. Schema + isolamento passaram em duas seeds (20261016/20261017) e cada path em paralelo com dois processos. Pint passou. Evidências e intercorrências no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-03--schema-uuidv7-e-cleanup-seguro--2026-10-14). **Gate global bloqueado:** UserModel ainda inteiro falha ao criar no schema UUID; conversão pertence ao STEP 04. Provas focadas não substituem os gates globais do suporte compartilhado. Banco operacional não foi migrado/resetado; a aplicação completa ainda não está pronta no schema novo.

## STEP 04 — Identity, owner Core e Sanctum

**Entrega:** cadastro, autenticação e sessão com User/PAT UUIDv7, usando os mecanismos nativos.

- [x] **4.1** Converter Entity, Repository, Data e UseCases de User para UUIDv7.
- [x] **4.2** Configurar geração UUIDv7 no `UserModel` e remover pressupostos de inteiro.
- [x] **4.3** Criar/configurar o Model de PAT UUIDv7 pela extensão suportada do Sanctum.
- [x] **4.4** Fazer Bearer com parte ID inválida/legada responder 401 antes de erro SQL UUID.
- [x] **4.5** Converter `UserPort`, adapters/contexto e middleware para owner canônico UUIDv7.
- [x] **4.6** Converter SignIn/Responses/relationships para User/PAT UUIDv7.
- [x] **4.7** Converter sessão e `NotificationAdapter`/contratos afetados, preservando locks e aptidão.
- [x] **4.8** Converter rotas de User e verificação assinada, preservando assinatura/ownership/statuses.
- [x] **4.9** Atualizar fixtures/provas de PAT real, segredo, expiração, extensão, pruning, logout e cascades.
- [x] **4.10** Executar arquivos e suítes focadas de Identity/Core.

**Concluir quando:** UUID de PAT não é confundido com segredo Bearer; sessão mantém o mesmo ID ao estender e principal inválido não vira zero ou 500.

**Escopo Identity/Core concluído em 2026-10-14:** Feature Identity 112 testes/916 assertions; Unit Identity/Core + arquitetura 383/1.584. Arquivos afetados passaram isoladamente. Fatia cruzada com isolamento Redis/duas invocações passou em seeds 20261018/20261019 (505/2.652); Feature Identity em paralelo de dois processos passou (112/916). Pint passou. Evidências, mapa de preservação e intercorrências no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-04--identity-owner-core-e-sanctum--2026-10-14). Gate global continua bloqueado: agora encontra mocks de Expense com owner inteiro, cuja conversão pertence ao STEP 05. A integração completa de Notifications segue no STEP 06 e o banco operacional ainda aguarda STEP 12.

## STEP 05 — Expense, cursor, cache e classificação

**Entrega:** despesas/owners UUIDv7 e paginação coerente com PostgreSQL.

- [x] **5.1** Converter Entity, contratos, UseCases, Data e mappings CRUD/cache.
- [x] **5.2** Configurar UUIDv7 no Model e fornecer IDs válidos em bulk/seed/fixtures.
- [x] **5.3** Converter rotas/controllers/Requests/Responses e preservar ownership/404 uniforme.
- [x] **5.4** Implementar cursor v2: `id` UUIDv7 separado de `amount` inteiro; rejeitar cursor antigo.
- [x] **5.5** Revisar sort/seek/ties UUID, mantendo collation e descrição nullable.
- [x] **5.6** Versionar cache/tags/serialização para owner UUID e cursor v2.
- [x] **5.7** Converter classificação/dispatch/job para Expense UUIDv7, preservando fencing e proteção contra edição.
- [x] **5.8** Atualizar provas Unit, PostgreSQL e HTTP de CRUD/ordenação/paginação/cache/classificação.
- [x] **5.9** Provar worker real e invalidação scoped em fila/Redis exclusivos.
- [x] **5.10** Executar arquivos, suíte e integrações afetadas; registrar planos pertinentes.

**Concluir quando:** next/prev não omitem nem repetem registros estáveis; ID nunca é validado/cast como amount; jobs/cache antigos não são consumidos como novos.

**Escopo Expense concluído em 2026-10-15:** Unit/Feature Expense + arquitetura passaram com 500 testes/3.485 assertions; arquivos alterados passaram isoladamente. Duas seeds com isolamento/Redis/invocações simultâneas passaram (509/3.573 cada); Feature Expense em paralelo de dois processos passou (371/2.721). Worker Redis comprova UUID/fencing, retries, invalidação scoped e edição posterior. Pint e OpenSpec estrito passaram. Planos de 2.400 registros/evidências no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-05--expense-cursor-cache-e-classificação--2026-10-15). Gate global agora bloqueia em owner inteiro de Insights (STEP 08); integração completa e transição do banco operacional seguem pendentes.

**Correção transversal posterior — 2026-10-15:** após diagnóstico completo de 268 problemas, os consumidores obrigatórios de owner/sessão, mocks e inserts UUID foram alinhados conforme seção 1.6 da spec. Core recuperou as provas de rollback/preflight; contratos de Insights/Metrics e owner/sessão de Notifications estão coerentes. Gate completo, seeds 20261022/20261023 e paralelo de dois processos passaram: **2.168 testes/39.859 assertions em cada execução**, sem exclusões/skips. O bloqueio global registrado acima foi superado. Evidências e mapa de preservação estão no [checklist oficial](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#correção-transversal--compatibilidade-da-suíte--2026-10-15). Isso conclui os pré-requisitos de tipos de 6.2/8.1/9.1/10.1, não os respectivos STEPs completos, as identidades estáveis ou o rollout operacional.

## STEP 06 — Notifications e instalação

**Entrega:** registro, owner, sessão e instalação UUIDv7, com o lifecycle atual de cadastro preservado.

- [x] **6.1** Configurar geração/mapping UUIDv7 do registro, sem trocar ID em sincronização/rotação.
- [x] **6.2** Converter owner/sessão/retornos dos contratos e preservar transação/locks/cifragem/fingerprint.
- [x] **6.3** Exigir `installation_id` UUIDv7 no Domain/Request, com pointer correto para outras versões.
- [x] **6.4** Ajustar DELETE/Response/rotas, mantendo auth, cota, não extensão e 204/404.
- [x] **6.5** Atualizar fixtures/doubles/logs, mantendo ID de instalação distinto do ID do registro.
- [x] **6.6** Ajustar prova da migration de fingerprint, conservando rollback e escrita sentinela.
- [x] **6.7** Provar persistência/HTTP e corridas de cadastro, disputa, rotação e logout/cascades.
- [x] **6.8** Executar arquivos/suíte Notifications e integração com Identity.

**Concluir quando:** repetição/rotação mantém UUID; instalação v4 é rejeitada; nenhum envio Firebase foi ativado por essa conversão.

**Escopo Notifications concluído em 2026-10-15:** registro e instalação exigem UUIDv7 canônico, mantendo papéis distintos e ID estável na sincronização/rotação. Domain/HTTP rejeitam outras versões e whitespace; DELETE tem 404 uniforme antes de lookup inválido. Cifragem, fingerprint, rollback pós-escrita, corridas e cascades passaram em PostgreSQL exclusivo. Notifications + Identity + arquitetura: **348 testes/2.293 assertions**; arquivos afetados passaram isoladamente. Gate completo padrão, seeds **20261024/20261025** e paralelo de dois processos passaram: **2.206/40.012** cada, sem skips/exclusões. Pint/OpenSpec estrito passaram. [Evidências e mapa de preservação](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-06--notifications-e-instalação--2026-10-15). Banco operacional segue no STEP 12; envio Firebase e homologação do cliente permanecem pendentes. Próximo: STEP 07.

## STEP 07 — Registro de identidades estáveis no Core

**Entrega:** associação durável `(owner, namespace, versão, identidade lógica) → UUIDv7` resolvida em lote.

- [x] **7.1** Implementar Data de lote/chaves/saída e `ResourceRepository`.
- [x] **7.2** Implementar `ResourceUseCase`, validando e deduplicando chaves sem perder ordem.
- [x] **7.3** Implementar Model/Repository, fingerprint interno não ambíguo e geração somente para ausentes.
- [x] **7.4** Implementar hits em uma leitura, sem UPDATE; lote vazio sem query/alocação.
- [x] **7.5** Implementar insert batch/transação/unique/releitura, devolvendo o UUID vencedor em conflitos.
- [x] **7.6** Implementar retries limitados e falhas sanitizadas, com rollback antes da nova tentativa.
- [x] **7.7** Registrar bindings de fronteira e autowiring, sem Service Locator ou abstração genérica extra.
- [x] **7.8** Provar validação, lote, ordem, argumentos e erros em Unit pura.
- [x] **7.9** Provar hit/miss/misto/unique/owner/cascade/rollback e limites de statements em PostgreSQL.
- [x] **7.10** Provar corridas sincronizadas da mesma identidade e exclusão de owner.
- [x] **7.11** Executar arquivos isolados e registrar contagens/planos/resultados.

**Concluir quando:** duas criações concorrentes retornam o mesmo UUID confirmado; hit não escreve; há até três statements do registro por tentativa, sem query por recurso; não são armazenados resultados/textos.

**Escopo Core concluído em 2026-10-15:** contratos/Data, validação/deduplicação/ordem, Repository/Model e binding implementados. Lotes vazios não consultam nem geram UUID; hits usam um SELECT sem escrita; misses/mistos/conflitos usam até três statements por tentativa. Corrida sincronizada devolve o UUID vencedor; rollback parcial, retries limitados, owner/cascade e falhas sanitizadas comprovados em PostgreSQL exclusivo. Unit nova **33/125**, persistência **15/112**, concorrência **3/9**; Core + arquitetura **535/2.236**. Gate completo padrão, seeds **20261026/20261027** e paralelo de dois processos passaram **2.257/40.302** cada, sem skips/exclusões. Pint e OpenSpec estrito passaram. [Evidências e limites](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-07--registro-estável-core--2026-10-15). Próximo: STEP 08, integração de Insights.

## STEP 08 — Insights com UUIDv7 estável

**Entrega:** Insights usam IDs associados no Core, preservando fatos, seleção, período e rotação.

- [x] **8.1** Converter owner nos contratos, SQL, fatos e escolha de variante.
- [x] **8.2** Preparar chave por tipo/assunto/estado/períodos internos e comparação.
- [x] **8.3** Compor/deduplicar/selecionar tudo antes de resolver IDs em um lote final.
- [x] **8.4** Provar equivalências/chaves e estabilidade frente a valor, descrição, visita e catálogo.
- [x] **8.5** Provar HTTP/PG, novo processo/PAT, onboarding null, owner e desaparecimento/retorno.
- [x] **8.6** Provar falha financeira/editorial/Core sem associação nova, data parcial ou ID fabricado.
- [x] **8.7** Executar arquivos/suíte/arquitetura e distinguir queries financeiras, de identidade e middleware.

**Concluir quando:** histórico mantém UUID em outro dia/processo; onboarding incorpora período interno; avanço do período parcial pode mudar a identidade legitimamente; leitura financeira continua única.

**Escopo Insights concluído em 2026-10-15:** IDs públicos agora usam um lote Core `insights` v1 após seleção/deduplicação/composição completas. Unit comprova componentes exatos, ordem, estados e falhas; HTTP/PostgreSQL comprova equivalências, owner, período null, fatos recalculados, desaparecimento/retorno e processo filho com conexão nova/PAT substituído. Três cartões usam uma leitura financeira e três statements do registro no miss, um no hit sem escrita. Insights + arquitetura passaram **827/32.851**; gate completo padrão **2.267/40.376**; Feature Insights paralelo de dois processos **176/1.960**. Pint e OpenSpec estrito passaram. [Evidências e limites](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-08--insights-com-uuidv7-estável--2026-10-15). Próximo: STEP 09, Metrics.

## STEP 09 — Metrics com UUIDv7 estável

**Entrega:** resumo singular UUIDv7 por owner/período/modo, inclusive total zero.

- [x] **9.1** Converter owner sem mudar cálculo, snapshot, período ou filtros.
- [x] **9.2** Preparar chave canônica e resolver ID depois de reconciliar a projeção.
- [x] **9.3** Substituir hash público por associação Core, sem ID de categoria ou resumo persistido.
- [x] **9.4** Provar chave/modo/default/zero/valores em Unit.
- [x] **9.5** Provar HTTP/PG, processos/PATs novos, isolamento, modos e quantidade de queries.
- [x] **9.6** Provar falhas sem total zero fabricado, resultado parcial ou UUID transitório.
- [x] **9.7** Executar arquivos/suíte e revisar ausência de cache/materialização/queue.

**Concluir quando:** valores atualizam sem trocar UUID; total/category têm identidades distintas; default e intervalo equivalente mantêm ID; categories continuam parcelas do resumo.

**Escopo Metrics concluído em 2026-10-15:** resumo singular usa Core `expense-metrics` v1 por owner e componentes ordenados `start_date → end_date → mode`, após validação/reconciliação, inclusive total zero. Unit preserva cálculo/ordenação e prova chave e falhas; HTTP/PostgreSQL prova equivalências, mutações, isolamento e PAT substituído em processo filho com conexão nova. Para 0/1/18 categorias: uma leitura financeira, três statements do registro no miss e um SELECT no hit sem escrita. Metrics + arquitetura passaram **193/1.794**; gate completo padrão **2.283/40.731**; Feature Metrics paralelo com dois processos **115/1.110**. Pint e OpenSpec estrito passaram. [Evidências e limites](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-09--metrics-com-uuidv7-estável--2026-10-15). Próximo: STEP 10, sugestões.

## STEP 10 — Sugestões com UUIDv7 estável

**Entrega:** identidade por owner/chave normalizada SQL, sem vínculo com uma Expense específica.

- [x] **10.1** Converter owner preservando busca, normalização, janela monetária e limite.
- [x] **10.2** Preparar chave da associação pela chave normalizada SQL, sem raw description persistida.
- [x] **10.3** Resolver lote final e não alocar em resposta vazia.
- [x] **10.4** Provar termos/case equivalentes, valores opcionais, owners/processos diferentes e mudança de assunto.
- [x] **10.5** Provar desaparecimento/retorno e falhas, mantendo uma leitura financeira sem efeitos em despesa/IA/queue.
- [x] **10.6** Executar arquivos/integração e preservar busca literal/limites/privacidade.

**Concluir quando:** termo ou valor não troca UUID; chave normalizada diferente troca; associação antiga não faz sugestão ausente reaparecer.

**Escopo Sugestões concluído em 2026-10-15:** associação Core `expense-suggestions` v1 por owner e `description_key` exata do SQL, em lote final de até cinco sugestões; vazio não consulta/aloca registro. Provas cobrem termos/case/acentos/espaços, valor opcional/janelas, owners/processo filho/PAT novo, assunto distinto, desaparecimento/retorno, lote misto e falhas com rollback sem resposta parcial. Para 0/1/5 sugestões: uma leitura financeira, 0 statements Core no vazio, 3 no miss e 1 no hit sem escrita. Arquivos isolados: **104 testes / 612 assertions**; Expense + Core + arquitetura: **1.026/5.453**. Pint e OpenSpec estrito passaram. [Evidências e limites](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-10--sugestões-com-uuidv7-estável--2026-10-15). Próximo: STEP 11, integração transversal e observabilidade.

## STEP 11 — Integração transversal e observabilidade

**Entrega:** consumidores, suporte e contratos cruzados coerentes em UUIDv7.

- [x] **11.1** Fechar a conversão das fixtures/builders/fakes/stubs/spies compartilhados.
- [x] **11.2** Auditar JSON:API, relationships e bindings de todas as rotas próprias.
- [x] **11.3** Converter correlação própria para UUIDv7 e provar igualdade header/context/log e isolamento entre requests, usando somente `trace_id`, sem `request_id` duplicado.
- [x] **11.4** Revisar allowlists de log e ausência de segredos/chaves/fingerprints do registro.
- [x] **11.5** Provar jornadas de cadastro/login/User/Expense/projeções/instalação/logout/exclusão com PAT real.
- [x] **11.6** Auditar casts, assinaturas, constraints e pressupostos de sequence restantes por papel.
- [x] **11.7** Registrar cenário antigo → cenário UUIDv7, sem retirar provas para acomodar a conversão.
- [x] **11.8** Executar arquitetura e suítes cruzadas pelo launcher.

**Concluir quando:** owner não vira zero/int; não há ID inteiro/hash alternativo nos recursos próprios; o mapa de cenários e as fronteiras continuam íntegros.

**Escopo transversal concluído em 2026-10-15:** `trace_id` UUIDv7 server-owned no atributo/contexto/log e no header `X-Request-Id`, sem campo `request_id`. Provas preservam isolamento HTTP/CLI/worker e IDs nativos de queue; jornada Identity cobre PAT real, despesas/projeções/instalação, logout e cascades. Auditoria de suporte/rotas/JSON:API/casts/schema e allowlists registrada por papel, sem remoção de cenários. Arquivos isolados: **9 testes/434 assertions**; arquitetura **30/504**; gates completos padrão, seeds **2026101511/2026101512** e paralelo **2 processos**: **2.305/41.116** cada. Pint/OpenSpec strict passaram. [Mapa, evidências e limites](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-11--integração-transversal-e-observabilidade--2026-10-15). Próximo: STEP 12.

## STEP 12 — Aplicação local e medição

**Entrega:** ambiente local convertido, com operação e medição documentadas.

- [x] **12.1** Reconferir site/engine/env/DB alvo e autorização de desenvolvimento antes do reset.
- [x] **12.2** Descobrir e pausar workers relevantes, tratando somente filas/cache/prefixos próprios incompatíveis.
- [x] **12.3** Executar o reset local autorizado e conferir schema, constraints e geração finais, sem seed automático.
- [x] **12.4** Restaurar somente workers anteriormente ativos e verificar operação dos novos IDs.
- [x] **12.5** Medir HTTP autenticado, queries financeiras/registro, hit/miss/batch/planos e consultar `optimize_route`.
- [x] **12.6** Validar a estratégia de rollback local documentada e registrar incompatibilidade de IDs/tokens/links/cursors antigos.

**Comando autorizado para o alvo local confirmado:**

```sh
lerd artisan migrate:fresh --no-interaction
```

**Concluir quando:** destino correto e cleanup exclusivo estão comprovados, operação foi restaurada e limitações da captura/medição foram registradas. Esse comando não é usado em produção, base compartilhada ou launcher de testes.

**Aplicação local concluída em 2026-10-15:** usuário reconfirmou descarte das 3 contas/88 despesas demonstrativas/25 PATs no PostgreSQL local `trocado`. Reset sem seed aplicado; collation própria remanescente causou parada inicial, foi conferida/removida sem CASCADE e migrations pendentes concluíram incrementalmente. Schema UUIDv7 nativo/CHECKs/FKs/geração conferidos. Workers restaurados ao estado anterior; worker dedicado consumiu payload UUIDv7. Medição autenticada separa kernel/HTTPS: uma leitura financeira, registro **0/3/1 statements** para vazio/miss/hit, lote cinco sem N+1 observado; dois requests concorrentes obtiveram o mesmo UUID/uma associação. `optimize_route`: **36 amostras, mediana 73 ms, sem rotas sinalizadas**, com limites de escala/captura explícitos. Cleanup deixou tabelas de produto e filas vazias. Launcher focado: **175/546**. [Evidências, incidente da collation e rollback local](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-12--aplicação-local-e-medição--2026-10-15). Próximo: STEP 13.

## STEP 13 — Documentação, Bruno e cliente

**Entrega:** contrato UUIDv7 documentado e exemplos executáveis por consumidores.

- [x] **13.1** Atualizar arquitetura/API existentes e a exceção limitada de estado em Core.
- [x] **13.2** Atualizar Bruno User/Auth/Expense/Notifications com UUIDv7 e variáveis privadas.
- [x] **13.3** Atualizar assertions de Insights/Metrics/sugestões para formato e estabilidade sem mínimo de cartões/texto fixo.
- [x] **13.4** Validar parser/serializer/URL/params/vars e round trips dos arquivos.
- [x] **13.5** Executar casos controlados com fonte elegível/vazia e PAT real; limpar arquivos/tokens/DB de prova.
- [ ] **13.6** Documentar contrato do cliente e confirmar gerador UUIDv7 da instalação antes de alegar homologação.
- [x] **13.7** Atualizar a coordenação com Firebase sem concluir tarefas de envio/plataforma ainda pendentes.

**Concluir quando:** exemplos e assertions refletem a política; resultados e limites estão registrados. Confirmação externa de cliente é identificada como tal, sem editar outro repositório por conveniência.

**Backend/documentação/Bruno comprovados em 2026-10-15:** 28 arquivos passaram no parser/serializer/round trip com preservação semântica de URL/params/vars; CLI Bruno 4.0.0 passou **25 requests/89 checks** em fonte vazia e **25/89** em fonte elegível, com PAT real, estabilidade e cleanup completo. Sem GUI/envio real. **13.6 bloqueado:** inspeção read-only de `cordato`, informado pelo usuário, encontrou `uuid 4.6.0` somente transitivo e nenhum gerador/persistência de instalação UUIDv7 ou cadastro push. [Evidências e limitações](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-13--documentação-bruno-e-fronteira-cliente--2026-10-15).

## STEP 14 — Gates e fechamento

**Entrega:** implementação e contratos comprovados, com evidência por requisito/cenário.

- [x] **14.1** Executar os arquivos PHP afetados isoladamente e suítes focadas/arquitetura após a última edição.
- [x] **14.2** Executar Pint, repetir arquivos que ele alterar e validar OpenSpec estritamente.
- [x] **14.3** Executar gate completo padrão com PostgreSQL/Redis/concorrência e invocações simultâneas existentes.
- [x] **14.4** Executar gate completo com a primeira seed aleatória registrada.
- [x] **14.5** Executar gate completo com uma segunda seed distinta.
- [x] **14.6** Executar paralelo nativo com dois processos ou mais pelo launcher.
- [x] **14.7** Preencher matriz final e revisar claims de UUIDv7, estabilidade, rollback, race, worker e reset.
- [ ] **14.8** Resolver bloqueadores/limitações e conferir autorização específica para archive/publicação.

**Concluir quando:** todos os gates exigidos passaram sem skips/incomplete/risky inesperados, as tarefas têm evidências e limitações externas estão explícitas. Timeout não é aprovação; não arquivar a change Firebase ainda incompleta junto desta.

**Gates backend aprovados em 2026-10-15:** padrão, seeds **2026101513/2026101514** e paralelo com **2 processos**, cada um **2.305 testes/41.116 assertions**, incluindo PostgreSQL/Redis/concorrência/invocações simultâneas. Arquivos focados isolados, arquitetura, Pint e OpenSpec strict passaram. **14.8 pendente:** homologação 13.6 e autorização específica de archive; não houve archive/commit/push/deploy. [Evidências finais](openspec/changes/standardize-uuid-v7-identifiers/tasks.md#step-14--gates-e-estado-de-fechamento--2026-10-15).

## Comandos de verificação para usar durante a implementação

Use o menor arquivo/suíte que prova a tarefa corrente:

```sh
lerd composer test -- <arquivo-ou-suite> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd pint --dirty --format agent
openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive
git diff --check
```

No MCP Lerd, testes usam `exec`/`composer` com `args: ["test", "--", ...]`; Pint usa `vendor_run` após descobrir os binários disponíveis. Se o alias CLI de Pint não estiver disponível, use o binário instalado via Lerd; a opção exigida é `--dirty --format agent`.

Para o STEP 14, registrar duas seeds escolhidas explicitamente:

```sh
lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --order-by=random --random-order-seed=<seed-1> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --order-by=random --random-order-seed=<seed-2> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
lerd composer test -- --parallel --processes=2 --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky
```

Testes Feature não são executados diretamente por Pest/PHPUnit/Artisan sem o preflight. Este mapa organiza a execução; requisitos normativos, limites de escopo e detalhes técnicos permanecem nos artefatos da change.
