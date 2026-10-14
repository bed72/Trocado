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

- [ ] **4.1** Converter Entity, Repository, Data e UseCases de User para UUIDv7.
- [ ] **4.2** Configurar geração UUIDv7 no `UserModel` e remover pressupostos de inteiro.
- [ ] **4.3** Criar/configurar o Model de PAT UUIDv7 pela extensão suportada do Sanctum.
- [ ] **4.4** Fazer Bearer com parte ID inválida/legada responder 401 antes de erro SQL UUID.
- [ ] **4.5** Converter `UserPort`, adapters/contexto e middleware para owner canônico UUIDv7.
- [ ] **4.6** Converter SignIn/Responses/relationships para User/PAT UUIDv7.
- [ ] **4.7** Converter sessão e `NotificationAdapter`/contratos afetados, preservando locks e aptidão.
- [ ] **4.8** Converter rotas de User e verificação assinada, preservando assinatura/ownership/statuses.
- [ ] **4.9** Atualizar fixtures/provas de PAT real, segredo, expiração, extensão, pruning, logout e cascades.
- [ ] **4.10** Executar arquivos e suítes focadas de Identity/Core.

**Concluir quando:** UUID de PAT não é confundido com segredo Bearer; sessão mantém o mesmo ID ao estender e principal inválido não vira zero ou 500.

## STEP 05 — Expense, cursor, cache e classificação

**Entrega:** despesas/owners UUIDv7 e paginação coerente com PostgreSQL.

- [ ] **5.1** Converter Entity, contratos, UseCases, Data e mappings CRUD/cache.
- [ ] **5.2** Configurar UUIDv7 no Model e fornecer IDs válidos em bulk/seed/fixtures.
- [ ] **5.3** Converter rotas/controllers/Requests/Responses e preservar ownership/404 uniforme.
- [ ] **5.4** Implementar cursor v2: `id` UUIDv7 separado de `amount` inteiro; rejeitar cursor antigo.
- [ ] **5.5** Revisar sort/seek/ties UUID, mantendo collation e descrição nullable.
- [ ] **5.6** Versionar cache/tags/serialização para owner UUID e cursor v2.
- [ ] **5.7** Converter classificação/dispatch/job para Expense UUIDv7, preservando fencing e proteção contra edição.
- [ ] **5.8** Atualizar provas Unit, PostgreSQL e HTTP de CRUD/ordenação/paginação/cache/classificação.
- [ ] **5.9** Provar worker real e invalidação scoped em fila/Redis exclusivos.
- [ ] **5.10** Executar arquivos, suíte e integrações afetadas; registrar planos pertinentes.

**Concluir quando:** next/prev não omitem nem repetem registros estáveis; ID nunca é validado/cast como amount; jobs/cache antigos não são consumidos como novos.

## STEP 06 — Notifications e instalação

**Entrega:** registro, owner, sessão e instalação UUIDv7, com o lifecycle atual de cadastro preservado.

- [ ] **6.1** Configurar geração/mapping UUIDv7 do registro, sem trocar ID em sincronização/rotação.
- [ ] **6.2** Converter owner/sessão/retornos dos contratos e preservar transação/locks/cifragem/fingerprint.
- [ ] **6.3** Exigir `installation_id` UUIDv7 no Domain/Request, com pointer correto para outras versões.
- [ ] **6.4** Ajustar DELETE/Response/rotas, mantendo auth, cota, não extensão e 204/404.
- [ ] **6.5** Atualizar fixtures/doubles/logs, mantendo ID de instalação distinto do ID do registro.
- [ ] **6.6** Ajustar prova da migration de fingerprint, conservando rollback e escrita sentinela.
- [ ] **6.7** Provar persistência/HTTP e corridas de cadastro, disputa, rotação e logout/cascades.
- [ ] **6.8** Executar arquivos/suíte Notifications e integração com Identity.

**Concluir quando:** repetição/rotação mantém UUID; instalação v4 é rejeitada; nenhum envio Firebase foi ativado por essa conversão.

## STEP 07 — Registro de identidades estáveis no Core

**Entrega:** associação durável `(owner, namespace, versão, identidade lógica) → UUIDv7` resolvida em lote.

- [ ] **7.1** Implementar Data de lote/chaves/saída e `ResourceIdentityRepository`.
- [ ] **7.2** Implementar `ResolveResourceIdentitiesUseCase`, validando e deduplicando chaves sem perder ordem.
- [ ] **7.3** Implementar Model/Repository, fingerprint interno não ambíguo e geração somente para ausentes.
- [ ] **7.4** Implementar hits em uma leitura, sem UPDATE; lote vazio sem query/alocação.
- [ ] **7.5** Implementar insert batch/transação/unique/releitura, devolvendo o UUID vencedor em conflitos.
- [ ] **7.6** Implementar retries limitados e falhas sanitizadas, com rollback antes da nova tentativa.
- [ ] **7.7** Registrar bindings de fronteira e autowiring, sem Service Locator ou abstração genérica extra.
- [ ] **7.8** Provar validação, lote, ordem, argumentos e erros em Unit pura.
- [ ] **7.9** Provar hit/miss/misto/unique/owner/cascade/rollback e limites de statements em PostgreSQL.
- [ ] **7.10** Provar corridas sincronizadas da mesma identidade e exclusão de owner.
- [ ] **7.11** Executar arquivos isolados e registrar contagens/planos/resultados.

**Concluir quando:** duas criações concorrentes retornam o mesmo UUID confirmado; hit não escreve; há até três statements do registro por tentativa, sem query por recurso; não são armazenados resultados/textos.

## STEP 08 — Insights com UUIDv7 estável

**Entrega:** Insights usam IDs associados no Core, preservando fatos, seleção, período e rotação.

- [ ] **8.1** Converter owner nos contratos, SQL, fatos e escolha de variante.
- [ ] **8.2** Preparar chave por tipo/assunto/estado/períodos internos e comparação.
- [ ] **8.3** Compor/deduplicar/selecionar tudo antes de resolver IDs em um lote final.
- [ ] **8.4** Provar equivalências/chaves e estabilidade frente a valor, descrição, visita e catálogo.
- [ ] **8.5** Provar HTTP/PG, novo processo/PAT, onboarding null, owner e desaparecimento/retorno.
- [ ] **8.6** Provar falha financeira/editorial/Core sem associação nova, data parcial ou ID fabricado.
- [ ] **8.7** Executar arquivos/suíte/arquitetura e distinguir queries financeiras, de identidade e middleware.

**Concluir quando:** histórico mantém UUID em outro dia/processo; onboarding incorpora período interno; avanço do período parcial pode mudar a identidade legitimamente; leitura financeira continua única.

## STEP 09 — Metrics com UUIDv7 estável

**Entrega:** resumo singular UUIDv7 por owner/período/modo, inclusive total zero.

- [ ] **9.1** Converter owner sem mudar cálculo, snapshot, período ou filtros.
- [ ] **9.2** Preparar chave canônica e resolver ID depois de reconciliar a projeção.
- [ ] **9.3** Substituir hash público por associação Core, sem ID de categoria ou resumo persistido.
- [ ] **9.4** Provar chave/modo/default/zero/valores em Unit.
- [ ] **9.5** Provar HTTP/PG, processos/PATs novos, isolamento, modos e quantidade de queries.
- [ ] **9.6** Provar falhas sem total zero fabricado, resultado parcial ou UUID transitório.
- [ ] **9.7** Executar arquivos/suíte e revisar ausência de cache/materialização/queue.

**Concluir quando:** valores atualizam sem trocar UUID; total/category têm identidades distintas; default e intervalo equivalente mantêm ID; categories continuam parcelas do resumo.

## STEP 10 — Sugestões com UUIDv7 estável

**Entrega:** identidade por owner/chave normalizada SQL, sem vínculo com uma Expense específica.

- [ ] **10.1** Converter owner preservando busca, normalização, janela monetária e limite.
- [ ] **10.2** Preparar chave da associação pela chave normalizada SQL, sem raw description persistida.
- [ ] **10.3** Resolver lote final e não alocar em resposta vazia.
- [ ] **10.4** Provar termos/case equivalentes, valores opcionais, owners/processos diferentes e mudança de assunto.
- [ ] **10.5** Provar desaparecimento/retorno e falhas, mantendo uma leitura financeira sem efeitos em despesa/IA/queue.
- [ ] **10.6** Executar arquivos/integração e preservar busca literal/limites/privacidade.

**Concluir quando:** termo ou valor não troca UUID; chave normalizada diferente troca; associação antiga não faz sugestão ausente reaparecer.

## STEP 11 — Integração transversal e observabilidade

**Entrega:** consumidores, suporte e contratos cruzados coerentes em UUIDv7.

- [ ] **11.1** Fechar a conversão das fixtures/builders/fakes/stubs/spies compartilhados.
- [ ] **11.2** Auditar JSON:API, relationships e bindings de todas as rotas próprias.
- [ ] **11.3** Converter correlação própria para UUIDv7 e provar igualdade header/context/log e isolamento entre requests.
- [ ] **11.4** Revisar allowlists de log e ausência de segredos/chaves/fingerprints do registro.
- [ ] **11.5** Provar jornadas de cadastro/login/User/Expense/projeções/instalação/logout/exclusão com PAT real.
- [ ] **11.6** Auditar casts, assinaturas, constraints e pressupostos de sequence restantes por papel.
- [ ] **11.7** Registrar cenário antigo → cenário UUIDv7, sem retirar provas para acomodar a conversão.
- [ ] **11.8** Executar arquitetura e suítes cruzadas pelo launcher.

**Concluir quando:** owner não vira zero/int; não há ID inteiro/hash alternativo nos recursos próprios; o mapa de cenários e as fronteiras continuam íntegros.

## STEP 12 — Aplicação local e medição

**Entrega:** ambiente local convertido, com operação e medição documentadas.

- [ ] **12.1** Reconferir site/engine/env/DB alvo e autorização de desenvolvimento antes do reset.
- [ ] **12.2** Descobrir e pausar workers relevantes, tratando somente filas/cache/prefixos próprios incompatíveis.
- [ ] **12.3** Executar o reset local autorizado e conferir schema, constraints e geração finais, sem seed automático.
- [ ] **12.4** Restaurar somente workers anteriormente ativos e verificar operação dos novos IDs.
- [ ] **12.5** Medir HTTP autenticado, queries financeiras/registro, hit/miss/batch/planos e consultar `optimize_route`.
- [ ] **12.6** Validar a estratégia de rollback local documentada e registrar incompatibilidade de IDs/tokens/links/cursors antigos.

**Comando autorizado para o alvo local confirmado:**

```sh
lerd artisan migrate:fresh --no-interaction
```

**Concluir quando:** destino correto e cleanup exclusivo estão comprovados, operação foi restaurada e limitações da captura/medição foram registradas. Esse comando não é usado em produção, base compartilhada ou launcher de testes.

## STEP 13 — Documentação, Bruno e cliente

**Entrega:** contrato UUIDv7 documentado e exemplos executáveis por consumidores.

- [ ] **13.1** Atualizar arquitetura/API existentes e a exceção limitada de estado em Core.
- [ ] **13.2** Atualizar Bruno User/Auth/Expense/Notifications com UUIDv7 e variáveis privadas.
- [ ] **13.3** Atualizar assertions de Insights/Metrics/sugestões para formato e estabilidade sem mínimo de cartões/texto fixo.
- [ ] **13.4** Validar parser/serializer/URL/params/vars e round trips dos arquivos.
- [ ] **13.5** Executar casos controlados com fonte elegível/vazia e PAT real; limpar arquivos/tokens/DB de prova.
- [ ] **13.6** Documentar contrato do cliente e confirmar gerador UUIDv7 da instalação antes de alegar homologação.
- [ ] **13.7** Atualizar a coordenação com Firebase sem concluir tarefas de envio/plataforma ainda pendentes.

**Concluir quando:** exemplos e assertions refletem a política; resultados e limites estão registrados. Confirmação externa de cliente é identificada como tal, sem editar outro repositório por conveniência.

## STEP 14 — Gates e fechamento

**Entrega:** implementação e contratos comprovados, com evidência por requisito/cenário.

- [ ] **14.1** Executar os arquivos PHP afetados isoladamente e suítes focadas/arquitetura após a última edição.
- [ ] **14.2** Executar Pint, repetir arquivos que ele alterar e validar OpenSpec estritamente.
- [ ] **14.3** Executar gate completo padrão com PostgreSQL/Redis/concorrência e invocações simultâneas existentes.
- [ ] **14.4** Executar gate completo com a primeira seed aleatória registrada.
- [ ] **14.5** Executar gate completo com uma segunda seed distinta.
- [ ] **14.6** Executar paralelo nativo com dois processos ou mais pelo launcher.
- [ ] **14.7** Preencher matriz final e revisar claims de UUIDv7, estabilidade, rollback, race, worker e reset.
- [ ] **14.8** Resolver bloqueadores/limitações e conferir autorização específica para archive/publicação.

**Concluir quando:** todos os gates exigidos passaram sem skips/incomplete/risky inesperados, as tarefas têm evidências e limitações externas estão explícitas. Timeout não é aprovação; não arquivar a change Firebase ainda incompleta junto desta.

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
