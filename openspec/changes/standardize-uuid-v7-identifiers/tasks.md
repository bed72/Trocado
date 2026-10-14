## 1. Autorizar apply e consolidar inventário

- [x] 1.1 Obter autorização explícita da etapa de implementação e testes; escrever/validar esta spec não autoriza apply, reset, PHPUnit/Pest, emissão de tokens ou operação de workers.
  - Pedido de 2026-10-14: começar a implementação pelo STEP 01 do `STEPS.md`. Autoriza a preparação/inventário e suas verificações; as etapas seguintes continuam pendentes. Evidência detalhada abaixo.
- [x] 1.2 Revalidar estritamente a change e reconferir PHP/Laravel/Sanctum/PG, documentação e código instalado de HasUuids, PAT/custom findToken, uuidMorphs, cursor e bulk inserts. [UID-03–06; D2/D6]
  - OpenSpec strict passou; Boost e código instalado reconferidos em 2026-10-14. Matriz de APIs e limites abaixo; inspeção não é prova de implementação UUIDv7.
- [x] 1.3 Inventariar PKs/FKs/IDs de Domain, Application, HTTP, SQL, cache, queue e fixtures por papel, inclusive todos os casts int/getKey; registrar arquivo/campo/destino sem converter amount/datas/contadores. [UID-01/05]
  - Inventário por schema/contexto/papel e auditoria de casts/getKey registrados na seção 1.3 abaixo; inclui bulk, cursor, trim HTTP e exclusões técnicas/financeiras.
- [x] 1.4 Registrar matriz de namespaces/componentes canônicos de Insights/Metrics/sugestões e confirmar limites de batch/queries antes do registro Core. [RID-01–04; D4/D5]
  - Matriz fechada na seção 1.4: componentes tipados/null explícito e lotes 6/1/5; orçamento 0/1/até 3 statements por tentativa, até 3 tentativas. Medição futura permanece pendente.
- [x] 1.5 Coordenar a change ativa de Firebase: revisar design/specs/tasks para registro/instalação/owner/sessão v7 sem marcar envio, cliente ou trabalhos históricos como concluídos novamente. [UID-07; D8]
  - Design/specs/tasks Firebase alinhados ao contrato alvo; OpenSpec strict passou nas duas changes. Checkboxes e evidência histórica Firebase preservados, cenários v7 ainda Unproven.
- [x] 1.6 Definir fatias coerentes/dependências e impedir publicação de build com esquema/contratos misturados; não criar union int|string temporária como compatibilidade pública. [UID-04–06; D9]
  - Seção 1.6 fecha ordem/dependências, atualizações simultâneas de contratos/implementações/doubles e condição de integração anterior ao reset/publicação.

## 2. Conceito UUIDv7 puro e prova Unit inicial

- [ ] 2.1 Implementar UuidValueObject/exceção em Core Domain para forma v7/variante/canonicalização de caixa/equivalência, sem framework/clock/generator. [UID-02; D2]
- [ ] 2.2 Provar UUID válido, uppercase equivalente, v1/v4/v6/v8, nil, variante inválida, hash, inteiro/string numérica, espaços e ausência explícita; builders negativos não devem reparar entrada. [UID-02]
- [ ] 2.3 Introduzir fixture UUIDv7 determinística tipada em Tests\Support\Core para IDs distintos e ordering, sem BaseBuilder/catálogo de mocks ou esperado calculado pelo gerador de produção. [UID-03; D10]
- [ ] 2.4 Definir nomes e tipos dos contratos/Inputs/Outputs de identidade Core; string canônica para IDs presentes e null somente nos pontos legítimos antes de persistir. [UID-05; RID-01]
- [ ] 2.5 Atualizar permissões arquiteturais específicas para conceito/capacidade Core e provar ausência de imports Core→contextos, Domain→framework e Application→ORM. [D2; identidade-context]
- [ ] 2.6 Executar o arquivo Unit Core isolado pelo launcher e registrar resultado antes de avançar para a conversão ampla. [UID-02]

## 3. Bootstrap schema UUIDv7 e cleanup seguro

- [ ] 3.1 Atualizar bootstrap de users para PK uuid/geração legítima v7 e preservar campos, email unique, password/status/verificação/avatar e timestamps. [UID-04; user]
- [ ] 3.2 Atualizar bootstrap de personal_access_tokens para PK UUID e tokenable_id UUID/morph type atual, preservando hash/abilities/expiry/indexes. [UID-04; authentication]
- [ ] 3.3 Atualizar expenses.id/user_id para UUID com FK/cascade/indexes e preservar catálogo/centavos/datas/nullable description/fencing. [UID-04; expense]
- [ ] 3.4 Atualizar criação/rename de notifications para registro/owner/sessão/instalação v7, preservando constraints de token/fingerprint/geração e cascades. [UID-04/07]
- [ ] 3.5 Criar migration resource_identities com PK/owner UUID, namespace, identity_version, fingerprint e created_at; unique composto, FK cascade e nenhuma coluna de fatos/segredos/last_access. [RID-01–03/05]
- [ ] 3.6 Implementar/verificar checks de versão/variante/campos obrigatórios e inexistência de sequences/ID inteiro alternativo em tabelas próprias. [UID-04]
- [ ] 3.7 Classificar resource_identities em TestDatabaseCleanup e preservar guards inicial/efetivo e ownership exato antes de migration/fixture/cleanup/drop; não mudar PKs técnicas Laravel. [RID-07; UID-08]
- [ ] 3.8 Provar schema/FKs/uniques/checks em PostgreSQL exclusivo do launcher com fixtures explícitas e migrations incrementais; não resetar o banco operacional nesta fase de prova. [UID-04; RID-01]

## 4. Identity, Core owner e Sanctum

- [ ] 4.1 Converter UserEntity/Repository/Data/UseCases de criação/leitura/update/delete para IDs v7 e validar fora de HTTP, sem password/token no Domain. [user; UID-02/05]
- [ ] 4.2 Configurar UserModel com geração UUIDv7 e remover casts/comentários/relações que pressupõem inteiro; conservar a separação de Expense Model. [user; UID-03]
- [ ] 4.3 Implementar Model próprio de PAT UUIDv7 em Identity e registrá-lo via Sanctum::usePersonalAccessTokenModel; sem vendor changes ou credencial nova. [authentication; D6]
- [ ] 4.4 Proteger lookup de parte ID malformada/legada para 401 antes de SQL UUID, preservando resolução oficial/hash/segredo Sanctum e inputs suportados pelo pacote. [authentication: Bearer]
- [ ] 4.5 Converter Core UserPort/UserAdapter/ContextPort/ContextAdapter e consumidor do middleware para owner canônico v7; atualizar assinaturas e implementações em uma fatia coerente, sem fallback de Context/guard ou cast numérico. [UID-05]
- [ ] 4.6 Converter SignInOutput/Adapters/Ports e Responses: User/PAT/relationship UUIDv7, token uma vez/no-store e UUID preservado em extensão. [authentication]
- [ ] 4.7 Converter SessionAdapter e NotificationAdapter owner/sessão/retorno para UUIDv7, preservando locks/aptidão/owner/validade; não ampliar dependência cross-context. [UID-05/07]
- [ ] 4.8 Converter rotas/controllers/Requests User e verificação assinada para UUIDv7, mantendo checagem da assinatura antes de canonicalização e 404/401/403/422 existentes. [user; authentication]
- [ ] 4.9 Atualizar testes/fixtures/doubles Identity e provar PAT real v7, segredo, owner, expiração, extensão/pruning/logout, link assinado, cascades e invocação fora de HTTP. [UID-04–06; D6]
- [ ] 4.10 Executar arquivos Identity/Core afetados isoladamente e suites focadas; registrar falhas/limitações sem enfraquecer temporalidade/ownership para acomodar tipo. [D10]

## 5. Expense, cache, classificação e cursor

- [ ] 5.1 Converter ExpenseEntity, Repository/UseCases/Data e mapping CRUD/cache para ID/owner strings v7; remover casts integer somente desses campos. [expense; UID-05]
- [ ] 5.2 Configurar geração v7 de ExpenseModel e revisar bulk/seed/fixtures para fornecer IDs válidos onde hooks não executam. [UID-03/04]
- [ ] 5.3 Converter rotas/controllers/Requests e relações JSON:API de Expense para IDs v7 e preservar erro uniforme de owner/ID inválido antes de lookup. [UID-06; expense]
- [ ] 5.4 Implementar cursor v2 com posição ID UUIDv7 e amount int separados; rejeitar v1/legacy numéricos e campos/direção/critério incompatíveis. [expense: paginação; D7]
- [ ] 5.5 Revisar seek/ordenação SQL UUID em ASC/DESC e ties, mantendo ICU/null/descrição original; não usar ordem de geração como esperado. [expense-querying]
- [ ] 5.6 Versionar chaves/serialização/tags de CachedExpenseRepository por owner UUID/cursor v2, conservando TTL/invalidação após commit e isolamento. [EXP-UID]
- [ ] 5.7 Converter dispatch/Queue/UseCase/Repository de classificação para expenseId UUIDv7 e preservar fencing string, prazo, fallback e proteção contra edição posterior. [EXP-UID]
- [ ] 5.8 Atualizar provas Unit e PostgreSQL/HTTP de CRUD/sort/cursor/cache/classificação, com next/prev e empates explicitamente ordenados por UUIDs de fixture. [expense; D7]
- [ ] 5.9 Provar worker real em fila exclusiva/Redis e invalidação scoped após commit, sem FLUSHALL/FLUSHDB ou consumo de fila operacional. [EXP-UID; D10]
- [ ] 5.10 Executar arquivos Expense afetados isoladamente e suite focada/Redis/concorrência pertinente; registrar planos de filtros/indexes sem extrapolar escala. [D10]

## 6. Notifications e contrato de instalação

- [ ] 6.1 Configurar registro UUIDv7 no Model/Repository e canonicalizar mapping, preservando ID em sincronização/rotação. [UID-03/07]
- [ ] 6.2 Converter tipos de owner/session em Entity/Repository/UseCases/Ports e validação Domain, mantendo unidade transacional/locks/fingerprint/cifragens. [UID-05/07]
- [ ] 6.3 Exigir installation_id UUIDv7 no VO/Request, normalizar somente caixa válida e rejeitar outras versões com pointer sem eco de destino. [UID-02/07]
- [ ] 6.4 Ajustar DELETE/Response/rotas para registro v7 e confirmar 204/404 uniforme/auth/cota/não extensão/nenhum GET ou envio HTTP novo. [UID-06/07]
- [ ] 6.5 Atualizar fixtures/doubles Unit e registro de observabilidade para IDs reais v7 e instalação distinta; sem usar installation_id como PK por conveniência. [UID-07]
- [ ] 6.6 Ajustar prova de migration fingerprint para ordering v7 explícito, preservando rollback sentinela/escrita anterior/ciphertext/lifecycle; não remover a prova porque os dados antigos serão descartados. [UID-04; D9]
- [ ] 6.7 Provar PostgreSQL/HTTP e corridas sincronizadas de idempotência/rotações/disputa/logout/cascades com IDs v7, mantendo testes de segredos e geração. [UID-07]
- [ ] 6.8 Executar arquivos/suite Notifications e integração com Identity isoladamente; atualizar evidência da fatia de cadastro sem marcar envio/cliente aprovado. [D8/D10]

## 7. Registro transversal de Core

- [ ] 7.1 Implementar Data mínimo tipado de lote/chaves/saída e contrato ResourceIdentityRepository, sem Models/Builders/Outputs financeiros. [RID-01/02]
- [ ] 7.2 Implementar ResolveResourceIdentitiesUseCase concreto com validação owner/namespace/versão, deduplicação e manutenção da ordem, sem framework. [RID-02/04]
- [ ] 7.3 Implementar Model e Repository Eloquent de associação, digest interno não ambíguo e geração v7 somente para chaves ausentes. [RID-01–03]
- [ ] 7.4 Implementar leitura de hits em lote sem UPDATE/timestamp e saída vazia sem query/alocação. [RID-04]
- [ ] 7.5 Implementar insert batch sob transação curta/ordem técnica, unique conflict e releitura com snapshot novo; sem publicar UUID candidato perdedor. [RID-03; D5]
- [ ] 7.6 Implementar retries limitados de race/deadlock/serialization com rollback antes da nova tentativa e falha sanitizada após esgotamento. [RID-03/06]
- [ ] 7.7 Registrar binding do Repository Core e autowiring do UseCase, sem bindings redundantes, helpers globais, Interfaces de UseCases ou Service Locator. [RID-01; D2]
- [ ] 7.8 Provar Unit de validação/chaves/lote/ordem/erros com doubles próprios e contagem/argumentos explícitos, sem bootstrap. [RID-01–04/06]
- [ ] 7.9 Provar PostgreSQL hit/miss/misto/unique/UUID/owner/cascade/rollback e limite de statements, incluindo ausência de writes em hits. [RID-01–05]
- [ ] 7.10 Provar corrida sincronizada de criação da mesma associação e exclusão de owner, com conexões novas/barreiras/timeouts/diagnóstico/cleanup. [RID-03/05]
- [ ] 7.11 Executar arquivos Core isolados e registrar pré-condições/query plans/contagens; nenhum teste fake pode provar rollback ou race PostgreSQL. [D10]

## 8. UUIDv7 estável de Insights

- [ ] 8.1 Converter owner nos contratos/fonte SQL/fatos/edição de variante para v7, sem modificar janela, bases ou matemática. [UID-05; insights]
- [ ] 8.2 Preparar chave lógica tipada por owner/tipo/categoria/estado/from/to/comparison, com namespace/version constantes e períodos internos de onboarding. [RID-02; insights]
- [ ] 8.3 Compor/selecionar/deduplicar todos os recursos antes de resolver IDs em um único lote, substituir hash público pelo UUID Core e manter ordem/limite. [RID-04/06]
- [ ] 8.4 Provar Unit de chaves/default/zeros/periodos/estado e estabilidade frente a valor/descrição/variante/dia/catálogo, com novo ID só por mudança lógica. [insights: identidade]
- [ ] 8.5 Provar HTTP/PG associação estável em visitas/processos/PATs novos, batch, ownership, onboarding null, desaparecimento/retorno e limites editoriais preservados. [RID-03–05; insights]
- [ ] 8.6 Provar fonte/composição/registro falhando sem associação nova, data parcial, UUID aleatório ou onboarding fabricado; manter uma leitura financeira. [RID-06; insights]
- [ ] 8.7 Executar arquivos/suite Insights e arquitetura isolados, com resultados por cenário e distinção entre queries de fatos/identidade/middleware. [D10]

## 9. UUIDv7 estável de Metrics

- [ ] 9.1 Converter owner no Repository/UseCase/mapping Metrics para v7, mantendo parâmetros/default/total/percentuais exatos e snapshot. [UID-05; expense-metrics]
- [ ] 9.2 Preparar chave por owner/start/end/mode normalizados, independente de URL/trim/valores, e resolver UUID depois de reconciliar projeção. [RID-02/06]
- [ ] 9.3 Substituir hash público por associação Core para objeto singular, inclusive zero total; não criar IDs de categoria ou persistir resumo. [expense-metrics]
- [ ] 9.4 Provar Unit de chave/modo/default equivalente/zero/valores, ordenação e fake de registro sem ORM. [expense-metrics: identidade]
- [ ] 9.5 Provar HTTP/PG estabilidade entre processos/PATs/mudanças financeiras, owners/modos distintos, registry zero e batches/queries constantes. [RID-02–05]
- [ ] 9.6 Provar falha de fonte/projeção antes de associação e falha Core com erro explícito sem total zero/resultado parcial/IDs transitórios. [RID-06]
- [ ] 9.7 Executar arquivos/suite Metrics isolados e revisar que associação não adicionou cache, resumos, filas ou query por categoria. [expense-metrics; D10]

## 10. UUIDv7 estável de sugestões

- [ ] 10.1 Converter owner no contrato/fonte de sugestões para v7 e conservar agrupamento/normalização SQL/padrão de valor/janela/limite. [UID-05; expense-suggestions]
- [ ] 10.2 Preparar chave de Core pela mesma chave normalizada SQL, independente de termo/valor/janela, sem persistir raw description. [RID-02]
- [ ] 10.3 Resolver lote final após validação/preparação, substituir hash por UUID e omitir associação em data vazio; sem identificar Expense row específica. [RID-04/06]
- [ ] 10.4 Provar Unit/HTTP de termo diferente/case equivalente/valor opcional/owner diferente/novo processo e descrição normalizada diferente, com UUIDs corretos. [expense-suggestions]
- [ ] 10.5 Provar desaparecimento/retorno com mesmo UUID, fonte/registro falhando e uma leitura financeira sem writes de despesa/IA/queue/cache. [RID-05/06; expense-suggestions]
- [ ] 10.6 Executar arquivos de sugestões isolados e integração com Expense/registro Core; não enfraquecer busca literal/limites ou interpolar descrição em logs. [D10]

## 11. Integração transversal, suporte e rastreabilidade

- [ ] 11.1 Converter todos os fixtures/builders/fakes/stubs/spies compartilhados de owner/entidade/PAT para v7 tipado, preservando entradas inválidas explícitas e normalização fora do gerador de esperado. [UID-05; D10]
- [ ] 11.2 Revisar JSON:API/data/relationships e bindings de todas as rotas próprias para v7, mantendo statuses/proteções e sem ID inteiro/hash paralelo. [UID-01/06]
- [ ] 11.3 Converter correlação própria para Str::uuid7 e provar igualdade header/context/log, novos requests e não herança nos workers; SDK/job IDs permanecem nativos. [structured-observability]
- [ ] 11.4 Atualizar allowlists específicas de atributos de log, sem emitir logical keys/fingerprint ou descrição/valor/segredo para diagnosticar registro. [RID-06; structured-observability]
- [ ] 11.5 Provar viagens integradas de cadastro/login/User/Expense/projeções/instalação/SignOut/exclusão com PAT real e FK/lifecycle UUID, mantendo responsabilidade de cada contexto. [UID-04–07; RID-05/07]
- [ ] 11.6 Auditar por papel os casts/assinaturas/route constraints/PKs e pressupostos de sequence restantes; excluir conscientemente valores/infra conforme UID-01, não usar contagem como equivalência. [UID-01/05]
- [ ] 11.7 Registrar mapa cenário antigo → cenário UUIDv7 em todos os arquivos alterados/consolidados, preservando campos sensíveis/rollback/races e corrigindo esperado sem fixar variante/UUID gerado incidentalmente. [D10]
- [ ] 11.8 Executar arquitetura e suites cruzadas de Core/Identity/Expense/Notifications/Insights/Metrics pelo launcher; inconsistências de código fora do escopo pedem decisão, não relaxamento de allowlist/contrato. [D10]

## 12. Aplicação local consentida e diagnóstico

- [ ] 12.1 Reconferir por MCP o site/engine/env/DB alvo, ausência de produção/compartilhamento e autorização local; registrar referência sem credenciais antes de reset. [UID-08; D9]
- [ ] 12.2 Descobrir estado/filas/prefixos e pausar workers relevantes, descartando somente payloads próprios incompatíveis e versionando cache sem FLUSHALL/FLUSHDB. [UID-08; EXP-UID]
- [ ] 12.3 Executar `lerd artisan migrate:fresh --no-interaction` somente no banco local de desenvolvimento confirmado, sem seed automático; conferir schema/constraints/model generation finais. [UID-04/08]
- [ ] 12.4 Restaurar somente workers que estavam ativos e confirmar operação com novos IDs; não mudar arquitetura de worker ou iniciar envio Firebase. [D9]
- [ ] 12.5 Medir requests UUID autenticados controlados: fontes financeiras uma leitura, registry hit/miss/batch/planos, concorrência e ausência de N+1 observado; consultar optimize_route e registrar limites/restaurar captura alterada. [RID-04; D10]
- [ ] 12.6 Validar caminho de rollback de desenvolvimento documentado sem executar destruição extra ou prometer preservação/rollback de produção; registrar incompatibilidade de tokens/links/cursors anteriores. [UID-08; D9]

## 13. Documentação, Bruno e fronteira de cliente

- [ ] 13.1 Atualizar ARCHITECTURE/README existentes para formato/owner/PAT, conceito/capacidade Core e exceção mínima de estado; manter proibições financeiras/DDL/ORM e limites de cada contexto. [UID-01; RID-01]
- [ ] 13.2 Atualizar exemplos Bruno User/Auth/Expense/Notifications para UUIDv7 sem credenciais, instalação v7 e armazenamento privado de variáveis; sem parseInt/gerador falso. [UID-01/06/07]
- [ ] 13.3 Atualizar assertions Bruno Insights/Metrics/sugestões para versão/variante/canonicalização e estabilidade nas equivalências, sem exigir mínimo de candidatos ou texto diário literal. [RID-02/05]
- [ ] 13.4 Validar parser/serializer/URL/params/vars e ida/volta dos arquivos Bruno por ferramenta instalada; não alegar abertura GUI se só houve parsing. [D10]
- [ ] 13.5 Executar coleção/casos relevantes em contas/DB controlados, com fonte elegível e vazia, PAT real v7 e protocolo de limpeza privada; registrar referência/status/limitações sem segredos. [UID-06; RID-06]
- [ ] 13.6 Documentar contrato de installation_id UUIDv7/IDs string para o cliente e obter confirmação de generator/versão no repositório cliente antes de declarar homologação; não editar outro repo por conveniência. [UID-07; D8]
- [ ] 13.7 Atualizar coordenação/documentação da change Firebase com referências a esta política e evidência da fatia de cadastro, preservando tasks de envio/plataforma ainda pendentes. [D8]

## 14. Gates e fechamento

- [ ] 14.1 Executar todos os arquivos PHP afetados isoladamente após última edição e suites focadas/arquitetura pelo launcher, com --fail-on-skipped --fail-on-incomplete --fail-on-risky. [D10]
- [ ] 14.2 Executar Pint `--dirty --format agent` e repetir arquivos alterados pelo formatter; validar OpenSpec estritamente, sem marcar falha/timeout como aprovação. [D10]
- [ ] 14.3 Executar gate completo padrão com PostgreSQL/Redis/concorrência e duas invocações simultâneas existentes, sem exclusões para passar. [D10]
- [ ] 14.4 Executar gate completo com ordem aleatória/seed registrada 1 e registrar comando/resultado; não transformar seeds em valores esperados do produto. [D10]
- [ ] 14.5 Executar gate completo com seed registrada 2 diferente, registrando resultados/skips/limitações. [D10]
- [ ] 14.6 Executar paralelo nativo `--parallel --processes=2` ou mais pelo launcher e conferir isolamento/cleanup, sem recriação/drop flags fora do lifecycle. [D10]
- [ ] 14.7 Preencher a matriz abaixo e revisar ausência de claims falsas: UUIDv7 real, identidade estável persistida, rollback/race/worker reais, ausência de fatos armazenados e escopo do reset. [Todos]
- [ ] 14.8 Resolver bloqueadores/limitações externas, reconfirmar spec/design/código e autorização específica de archive/publicação; preservar evidência histórica, sem arquivar a change de Firebase ainda incompleta. [Todos]

## Dependências e execução por fatia

- Fase 1 antes do apply. Fase 2 é Unit pura; geração/persistência ainda não são provadas.
- Fase 3 antes de qualquer fluxo com schema novo, nos bancos exclusivos de prova; conversão de interfaces/implementações deve ocorrer de forma coerente com fases 4–6 e nunca ser publicada parcialmente.
- Fase 7 depende de schema/conceito/owner UUID; fases 8–10 dependem da capacidade Core comprovada e de fonte financeira owner UUID.
- Fase 11 fecha suporte transversal/consumidores; fase 12 aplica somente o reset local consentido no alvo reconfirmado. Fases 13–14 fecham artefatos/consumo/evidência.
- Aplicar uma task pendente por vez, verificar antes de marcar e registrar comandos/resultados. Proposta de spec e decisões resolvidas não são evidência de implementação.

## Matriz requisito/cenário → trabalho → evidência futura

| Requisito / cenários | Tasks principais | Prova mínima | Estado inicial |
| --- | --- | --- | --- |
| UID-01 política/exclusões e todos os recursos próprios | 1.3, 3.*, 11.2/11.6 | Inventário por papel + schema/HTTP + arquitetura | Não implementado/comprovado |
| UID-02 canônico/v7/variante/negativos/null | 2.1–2.3, 4.1, 6.3 | Unit pura + HTTP antes de lookup + PG checks | Não implementado/comprovado |
| UID-03 geração padrão/imutabilidade | 3.*, 4.2–4.3, 5.2, 6.1, 7.3 | Model/PG create-update + formato + callback/clock fora de Domain | Não implementado/comprovado |
| UID-04 PK/FK/morph/cascades | 3.1–3.8, 4.9, 6.7 | PostgreSQL tipos/constraints/owner/session/encerramento | Não implementado/comprovado |
| UID-05 contratos/guard/sem cast | 2.4–2.5, 4.5/4.7, 5.1, 8.1/9.1/10.1, 11.6 | Unit argumentos + arquitetura + autenticação real | Não implementado/comprovado |
| UID-06 rotas inválidas/owner/auth | 4.8–4.9, 5.3/5.8, 6.4/6.7 | HTTP 200/201/204 e 401/403/404/422/429 | Não implementado/comprovado |
| UID-07 instalação/registro/cliente | 1.5, 6.*, 13.2/13.6/13.7 | Unit/HTTP/PG + homologação externa registrada | Não implementado/comprovado |
| UID-08 reset autorizado/negativo/lifecycle | 3.7, 12.* | Alvo/estado/cleanup/checks registrados + guard/testes de recusa | Não executado/comprovado |
| RID-01 mínimo/sem fatos/fronteiras | 3.5, 7.1/7.3/7.7, 13.1 | Schema allowlist + Unit + arquitetura | Não implementado/comprovado |
| RID-02 chave/namespace/owner/ambiguidade | 1.4, 7.2/7.8, 8.2/9.2/10.2 | Unit independente por consumidor + PG isolado | Não implementado/comprovado |
| RID-03 race/ID perdedor/rollback | 7.5–7.6/7.9–7.10 | Duas conexões sincronizadas + escrita sentinela/rollback PG | Não implementado/comprovado |
| RID-04 vazio/hit/misto/ordem/queries | 7.2/7.4/7.9, 8.3/9.3/10.3, 12.5 | Unit batch + query logs PG de 0/1/5/6 recursos | Não implementado/comprovado |
| RID-05 reinício/PAT/reaparecimento/cascade | 7.9–7.10, 8.5/9.5/10.5 | HTTP/PG processos novos + owner delete + recursos ausentes | Não implementado/comprovado |
| RID-06 erro/composição/fonte/sem fallback | 7.6, 8.6/9.6/10.5 | Exceção sentinela Unit/HTTP + zero writes + erro sem data/log sensível | Não implementado/comprovado |
| RID-07 sem endpoint/autoridade/cleanup | 3.7, 7.9, 11.5 | HTTP/owner + lifecycle exact runId/token | Não implementado/comprovado |
| User/Core UUID ownership e Entity pura | 2.*, 4.1/4.5/4.8/4.9 | Unit + HTTP + fronteiras | Não implementado/comprovado |
| Sanctum/segredo/expiração/extensão/link | 4.2–4.4/4.6–4.9 | PAT real + PG locks + assinatura/tempo/owner | Não implementado/comprovado |
| Expense sort/cursor v2/cache/worker | 5.* | Unit + PG/HTTP next-prev + Redis/worker exclusivo | Não implementado/comprovado |
| Insights períodos/estados/rotação/UUID | 8.* | Unit + HTTP/PG + Core batch | Não implementado/comprovado |
| Metrics singular/zero/default/grouped/UUID | 9.* | Unit + HTTP/PG + Core batch | Não implementado/comprovado |
| Sugestões norm/valor/owner/UUID | 10.* | Unit + HTTP/PG normalização SQL/associação | Não implementado/comprovado |
| Observabilidade próprio UUID/native SDK | 11.3–11.4 | JSON/header/context + ausência de segredos/fingerprint | Não implementado/comprovado |
| Cliente/Bruno/documentação | 13.* | Parser/CLI controlados + homologação externa distinta | Não implementado/comprovado |
| Gates transversais | 14.* | Padrão + duas seeds + paralelo + Redis/concorrência | Não executado/comprovado |

## Estado histórico da elaboração da proposta

Somente a criação/revisão/validação dos artefatos foi autorizada. Nenhuma task de implementação acima está concluída; não foram executados testes da aplicação, migrations/reset, queue, seed ou smoke test. As cinco decisões do usuário constam em proposal/design e são pré-condições do futuro apply, não seu início implícito.

## Validação histórica desta elaboração

- `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive`: passou sem issues.
- `openspec status`: proposal, design, specs e tasks completos como **artefatos de planejamento**, não implementação.
- Revisão documental adicional: 11 capacidades declaradas correspondem aos 11 arquivos de specs; 42 requisitos e 162 cenários; 26 blocos MODIFIED conservam todas as âncoras de cenários da spec principal, evitando perda na futura sincronização.
- Checklist: 108 tasks únicas em 14 fases, todas pendentes; matriz de evidências inicial sem resultados de implementação presumidos.
- Formatação documental/EOF e `git diff --check` passaram. `git status` mostra somente a nova pasta desta change; código, schema, specs principais e outra change ativa permanecem sem alterações nesta elaboração.

## STEP 01 — Preparação e inventário — 2026-10-14

### 1.1 Autorização e escopo corrente

O pedido de implementação pelo STEP 01 autoriza tarefas 1.1–1.6 e verificações pertinentes a essa entrega. A entrega é o inventário e a coordenação do apply. Nenhuma prova de comportamento UUIDv7 é atribuída à inspeção. Os testes PHP/Pest das etapas 02–14 permanecem nos respectivos passos; esta etapa não exige executar a aplicação em schema convertido. Reset local continua condicionado à reconferência do alvo no STEP 12; descoberta de site/schema não satisfaz essa reconferência futura.

`git status --short` estava limpo no início. A skill local `trocado-sdd` citada em AGENTS.md não está disponível nesta árvore; o fluxo foi conferido por `openspec status`, `openspec instructions apply`, pelas skills disponíveis de arquitetura/quality gate e pelos artefatos da change.

### 1.2 Ambiente e APIs reconferidos

- Boost `application-info`: PHP **8.5**, Laravel **13.34.0**, Sanctum **4.3.3**, Ramsey UUID **4.9.4**, Pest **5.2.1**, PHPUnit **13.3.4**, Pint **1.32.1**.
- Lerd `site list`: site `trocado`, path deste checkout, PHP 8.5. Consulta read-only `SELECT current_database(), current_setting('server_version')`: database **trocado**, PostgreSQL **16.10**. Esta leitura identifica o ambiente observado, sem afirmar ausência de dados reais/compartilhamento para autorizar reset.
- Boost Search Docs consultado para UUID/HasUuids, Sanctum/custom PAT, uuidMorphs/foreignUuid e cursor pagination. Conferência no vendor instalado resolve os detalhes abaixo.

| API / arquivo instalado (paths relativos a `vendor/`) | Resultado e consequência para o apply |
| --- | --- |
| `laravel/framework/src/Illuminate/Database/Eloquent/Concerns/HasUuids.php:16–29` | `newUniqueId()` chama `Str::uuid7()`. `isValidUniqueId()` chama `Str::isUuid()` sem versão: **não** protege v7 sozinho. |
| `laravel/framework/src/Illuminate/Database/Eloquent/Concerns/HasUniqueStringIds.php:29–92` | Habilita IDs únicos; chave em `uniqueIds()` tem tipo string e não incremental. Validação de route binding não protege todo lookup direto. |
| `laravel/framework/src/Illuminate/Support/Str.php:675–707` | Sem versão, `isUuid()` verifica forma hex/hífens; existe argumento de versão. Domain terá validação pura própria de forma/v7/variante, sem chamar Laravel nem permitir trim. |
| `laravel/sanctum/src/Sanctum.php::usePersonalAccessTokenModel` e `HasApiTokens.php::createToken` | Extensão suportada para PAT próprio em Identity; manter emissão `id\|segredo`, SHA-256 e morph type de User. |
| `laravel/sanctum/src/Guard.php:100–112` e `PersonalAccessToken.php:58–69` | Guard restringe prefixo numérico somente para key type int. Com string, `findToken()` pode consultar ID inválido: validar prefixo v7 antes de delegar ao lookup/hash oficial. Preservar o caminho suportado de token sem `\|`, que busca pelo hash; não inventar outra credencial. |
| `laravel/framework/src/Illuminate/Database/Schema/Blueprint.php::uuidMorphs/foreignUuid` | `uuidMorphs('tokenable')` cria type string, ID UUID e índice composto; **não cria FK polimórfica nem CHECK v7**. `foreignUuid` deve receber a constraint/cascade necessária. |
| `laravel/framework/src/Illuminate/Database/Concerns/BuildsQueries.php:464–551` | Cursor usa parâmetros da ordenação em igualdade/seek `>`/`<`, invertendo direção para anterior. Aceita posição textual; exigir ID único UUID e expressão de descrição não nula/alias no SELECT. |
| `laravel/framework/src/Illuminate/Database/Eloquent/Builder.php:521–573,1326–1344,1478–1492` | `insert/insertOrIgnore` simples não enriquecem IDs como create. **Há APIs específicas**: `fillAndInsert*` chama `setUniqueIds`, e Eloquent `upsert` adiciona unique IDs/timestamps. Não generalizar que todo bulk gera ou que nenhum gera; fornecer UUIDs explícitos nas fixtures/raw inserts e no lote do registro. |
| `laravel/framework/src/Illuminate/Database/Query/Grammars/PostgresGrammar.php:392–413` | `insertOrIgnore` compila `ON CONFLICT DO NOTHING`; variante returning permite alvo composto. Não usar upsert que atualiza hits/ID/timestamp; reconciliar o lote com releitura, sem publicar UUID perdedor. |

PostgreSQL 16.10 não deve ser tratado como gerador SQL nativo de UUIDv7; geração ficará na borda PHP. Provas de CHECKs, visibilidade concorrente e limits de statements pertencem aos STEPS 03/07, não à descoberta da API.

### 1.3 Inventário por papel e destino

Todos os paths abaixo são relativos ao repositório. Em tabelas agrupadas, os arquivos indicados compartilham o campo/papel e destino explícitos; números/digests técnicos não são convertidos por coincidência lexical.

#### Schema, PKs, FKs e índices

| Fonte / campo atual | Destino e tarefa |
| --- | --- |
| `database/migrations/2026_09_21_000000_create_users_table.php`: `users.id` bigint/sequence | PK UUIDv7 com CHECK versão/variante; preservar email unique/status check/campos. 3.1/3.6. |
| `database/migrations/2026_09_21_175106_create_personal_access_tokens_table.php`: `id`, `tokenable_id` bigint | PK v7 + morph UUID de User, type atual e índice `tokenable_type/tokenable_id`; hash token unique e datas permanecem. Sem presumir FK inexistente: exclusão de PAT continua pela unidade Identity. 3.2/4.3/4.9. |
| `database/migrations/2026_09_24_000000_create_expenses_table.php`: `id/user_id` bigint | PK/FK v7, FK `users(id)` cascade; amount bigint continua centavos. 3.3. |
| `database/migrations/2026_09_24_000001_add_cursor_index_to_expenses_table.php`: `(user_id,occurred_on,id)` | Preservar índice e referência UUID para owner/desempate; não usar sequence como recência. 3.3/5.5. |
| `database/migrations/2026_10_13_212150_create_push_registrations_table.php`: `id/installation_id` UUID, `user_id/session_id` bigint | Todos v7, PK registro independente da instalação; instalação unique, fingerprints unique, FKs owner/PAT cascade e índices conservados. 3.4/6.*. |
| `database/migrations/2026_10_13_222940_rename_push_registrations_to_notifications.php` | Conservar rename e nomes de constraints/índices; coordenar novos CHECKs v7 na cadeia de bootstrap. 3.4/3.6. |
| `database/migrations/2026_10_13_224125_recalculate_notification_fingerprints.php`: `chunkById`, `where(id)` | ID string v7 e ordenação explícita nas provas; fingerprint SHA-256/ciphertext/metadados e rollback sentinela preservados. 6.6. |
| Nova `resource_identities` (ainda ausente no schema) | `id/user_id` v7, FK owner cascade; namespace, versão, fingerprint, created_at somente. Unique composto de D3, sem chave inteira paralela/sequence. 3.5/7.*. |
| `2026_09_25_160000_create_jobs_table.php`, `2026_09_25_160001_create_failed_jobs_table.php`, tabela `migrations` | PKs/UUIDs internos nativos. attempts/batch/instantes técnicos não são identidades próprias. Excluídos da conversão. |

Boost schema summary confirmou esses tipos atuais. Consulta `pg_constraint` confirmou as duas FKs cascade de Notifications, FK cascade Expense→User, uniques de email/token/instalação/fingerprint/fencing e CHECKs de status/valores de Notifications. PAT **não possui FK para User** no schema atual; não prometer cascade polimórfico implícito. Nenhuma tabela própria atual tem CHECK v7. Os demais campos/migrations de password/status/email_verified_at/avatar/updated_at/classification/collation mantêm seus papéis atuais.

#### Contratos, geração, HTTP e mappings de aplicação

| Arquivo(s), relativo(s) a `app/` | Campo / destino |
| --- | --- |
| `Core/Application/Ports/UserPort.php`, `Core/Infrastructure/Adapters/UserAdapter.php` | `id(): int`, `is_int($id)` → owner string v7 canônico validado do guard Sanctum, falha auth sem fallback. 4.5. |
| `Core/Application/Ports/ContextPort.php`, `Core/Infrastructure/Adapters/ContextAdapter.php`, `Core/Presentation/Http/Middleware/AuthenticatedRequestMiddleware.php` | `identifyUser(int)`/`user_id` → mesmo owner string; Context não vira fonte auth. 4.5. |
| `Core/Presentation/Http/Middleware/TraceRequestMiddleware.php`, `Core/Infrastructure/Adapters/ContextAdapter.php`, `Core/Infrastructure/Adapters/Observability/{ObservabilityAdapter,ObservabilityJsonFormatter}.php`, `Core/Infrastructure/Providers/CoreServiceProvider.php` | `Str::uuid()` → uuid7 próprio por request, igualdade request_id/trace_id/header; conservar limpeza de Context para workers e allowlists. Cota `api:authenticated:user:` concatena owner sem cast e deve receber a mesma string canônica. 4.5/11.3–11.4. |
| `Identity/Domain/Entities/UserEntity.php` | `?int $id` → `?string` v7 validada; null só entidade não persistida. 4.1. |
| `Identity/Application/Repositories/{UserRepository,EmailVerificationRepository}.php`, `Identity/Application/Ports/EmailVerificationPort.php` | `$id/$userId` → string v7, update recebe Entity coerente; preservam booleanos/outputs. 4.1. |
| `Identity/Application/UseCases/{SignUp,GetUser,UpdateUser,DeleteUser,VerifyEmail}UseCase.php` | Entradas ID e retorno inteiro de SignUp → User UUIDv7; SignUpResponse usa a mesma User, sem ID extra de cadastro. 4.1/4.6. |
| `Identity/Application/Data/Output/SignInOutput.php` | `id/userId` inteiros → PAT UUID/User UUID; `token` permanece segredo sensível. 4.6. |
| `Identity/Infrastructure/Repositories/Persistence/{EloquentUserRepository,EloquentEmailVerificationRepository}.php`, `Models/UserModel.php` | ID/owner string; UserModel geração v7, key string não incremental, mapping remove cast e docblock inteiro. 4.1–4.2. |
| `Identity/Infrastructure/Adapters/{SignIn,SignOut,Session,EmailVerification,Notification}Adapter.php` | User/PAT/owner string em emissão, locks, verificação, revogação e logs. `NotificationAdapter::lock` e Port consumidor retornam PAT string na mesma fatia; Session preserva ID no update. 4.3–4.7. |
| `Identity/Infrastructure/Providers/IdentityServiceProvider.php`, novo Model PAT em `Identity/Infrastructure/Repositories/Persistence/Models/` | Registrar custom PAT pela API Sanctum e preservar callback temporal/binding de NotificationPort em Identity. 4.3/4.7. |
| `Identity/Presentation/Routes/api.php`, `Http/Controllers/{GetUser,UpdateUser,DeleteUser,VerifyEmail}Controller.php` | `whereNumber`, parâmetros int → UUIDv7 validado; assinatura de URL original verificada antes de canonicalizar, hash de e-mail permanece SHA-1. 4.8. |
| `Identity/Presentation/Http/Responses/{User,SignUp,AccessToken}Response.php` | data.id/relationship/self → strings v7, segredo somente na emissão e no-store. 4.6. |
| `Expense/Domain/Entities/ExpenseEntity.php` | `?int id/int userId` → `?string id/string userId` v7; amount/category/date não mudam. 5.1. |
| `Expense/Application/Repositories/{ExpenseRepository,ExpenseCategorizationRepository,ExpenseSuggestionsRepository}.php`, `Ports/ExpenseClassificationDispatchPort.php` | ID/owner/expenseId → string v7; token de fencing permanece string de segurança. Owner de sugestões deve acompanhar a base mesmo antes da associação do STEP 10. 5.1/5.7/10.1. |
| `Expense/Application/UseCases/{CreateExpense,GetExpense,GetAllExpense,UpdateExpense,DeleteExpense,ClassifyExpense}UseCase.php`, `Data/ApplyExpenseClassificationInput.php` | ID/owner/expenseId e callbacks pós-commit → v7; saída de create não pode virar `(int)` no dispatch/cancel. 5.1/5.7. |
| `Expense/Infrastructure/Repositories/Persistence/{EloquentExpenseRepository,EloquentExpenseCategorizationRepository}.php`, `Models/ExpenseModel.php` | PK/owner mappings e casts v7; amount integer preservado; índice, tie-break e seek UUID com collation atual. 5.1–5.5. |
| `Expense/Infrastructure/Adapters/ExpenseQueryCursorAdapter.php`, `Application/Data/{ExpenseCursorOutput,GetAllExpenseInput}.php` | Envelope v1 e legado → v2; posição `id` string v7 separada de `amount` int; rejeitar shapes antigos. Union de valores heterogêneos do mapa não é compatibilidade int/string para ID. 5.4. |
| `Expense/Infrastructure/Repositories/Cache/{CachedExpenseRepository,CachedExpenseCategorizationRepository}.php` | Assinaturas/mapping/tags UUID; namespace atual `expense:pages:v2` → nova versão de cache, não confundir versão do cache com versão do cursor. Manter TTL 60/invalidação após commit. 5.6. |
| `Expense/Infrastructure/Adapters/ExpenseClassificationDispatchAdapter.php`, `Infrastructure/Queues/ClassifyExpenseQueue.php` | Payload `$expenseId` int → string v7; job UUID nativo/fencing/signal/attempts permanecem. 5.7. |
| `Expense/Presentation/Routes/api.php`, `Http/Controllers/{GetExpense,UpdateExpense,DeleteExpense}Controller.php`, `Http/Responses/ExpenseResponse.php` | `whereNumber`/`int $expense` → v7/404 uniforme; Response ID v7. Requests continuam rejeitando ID server-owned e validando amount inteiro. 5.3. |
| `Notifications/Domain/Entities/NotificationRegistrationEntity.php`, `Domain/ValueObjects/NotificationValueObject.php` | Registro v7; owner/session string v7; instalação v7 com canonicalização só de caixa. generation int e destino exato não mudam. 6.1–6.3. |
| `Notifications/Application/Repositories/NotificationRegistrationRepository.php`, `Application/Ports/NotificationPort.php`, `Application/UseCases/{CreateNotification,DeleteNotification}UseCase.php` | Owner/session/retorno lock v7 com Adapter de Identity compatível; IDs validados também fora de HTTP. 4.7/6.2. |
| `Notifications/Infrastructure/Repositories/Persistence/EloquentNotificationRepository.php`, `Models/NotificationModel.php` | `Str::uuid()` → v7; retirar casts integer owner/session, conservar generation int; mapping ID string canônico. 6.1–6.2. |
| `Notifications/Presentation/Routes/api.php`, `Http/Requests/CreateNotificationRequest.php`, `Http/Controllers/DeleteNotificationController.php`, `Http/Responses/NotificationResponse.php` | UUID genérico → v7: installation pointer 422, DELETE registro 404; resposta mínima e POST/DELETE sem extensão. 6.3–6.4. |
| `Insights/Application/Repositories/ExpenseAnalysisRepository.php`, `Data/SelectInsightMessageVariantInput.php`, `UseCases/{GetInsights,ComposeInsightMessage,SelectInsightMessageVariant}UseCase.php`, `Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepository.php` | Owner int → v7; hash **público** `derivedId` → associação Core; hash editorial interno permanece. SQL desempata Expense UUID, sem alterar fatos/contagens/períodos. 8.1–8.3. |
| `Insights/Application/Data/InsightOutput.php`, `Presentation/Http/Responses/InsightResponse.php` | `id` já string → UUIDv7 confirmado, sem alterar tipos/editorial. 8.3. |
| `Metrics/Application/Repositories/ExpenseMetricsRepository.php`, `UseCases/GetExpenseMetricsUseCase.php`, `Infrastructure/Repositories/Persistence/EloquentExpenseMetricsRepository.php` | Owner int → v7; hash público → UUID Core singular depois da reconciliação, inclusive zero. 9.1–9.3. |
| `Metrics/Application/Data/ExpenseMetricsOutput.php`, `Presentation/Http/Responses/ExpenseMetricsResponse.php` | ID string → v7; categorias permanecem parcelas sem ID. 9.3. |
| `Expense/Application/UseCases/GetExpenseSuggestionsUseCase.php`, `Data/{ExpenseSuggestionHistoryOutput,ExpenseSuggestionOutput}.php`, `Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepository.php`, `Presentation/Http/Responses/ExpenseSuggestionResponse.php` | Owner UUID; key SQL normalizada → associação Core; id string hash público → v7. Nenhum vínculo de identidade com row Expense individual. 10.1–10.3. |
| `bootstrap/app.php` | `TrimStrings` deve preservar bytes de installation_id/IDs editáveis antes da validação para não aceitar UUID com whitespace por trim global; erros/auth/pointers continuam na borda. 4.8/6.3/11.2. |
| `database/seeders/{UserSeeder,ExpenseSeeder,DatabaseSeeder}.php` | Create/firstOrCreate usam geração do Model; owner UUID, valores/datas próprios conservados. Não executar seed nesta preparação/reset automático. 5.2/11.6. |

**Casts/getKey auditados em `app/`:** remover os quatro `(int) $model->getKey()` de `EloquentExpenseRepository` (linhas 38/91/130/160), os dois de `SignInAdapter` (85/87), o de `EloquentUserRepository` (123), o de `EmailVerificationAdapter` (55), o de owner e retorno PAT de `NotificationAdapter` (37/63) e os três casts `$expense->id` de `CreateExpenseUseCase` (56/63/65). Os lookups `getKey()` de `SessionAdapter`/`NotificationAdapter` passam a consumir a chave string do custom PAT; o cast string em `EloquentNotificationRepository:94` é mapping de registro e deve manter validação canônica. Linhas referem-se ao checkout inspecionado, não ao resultado futuro.

**Exclusões explícitas:** casts de datas, page size, amount/filter.amount_min/max, contagens financeiras, percentuais, sort comparators e generation permanecem. SHA-256 de cache/cursor/query, hash editorial, SHA-1 do link, password hash, Sanctum token hash/segredo, FCM exato, fingerprint de destino, digest lógico Core e fencing de classificação não se tornam UUIDs. IDs de jobs/failed_jobs, backend PID e runId/token privados do launcher preservam seu contrato técnico.

#### Fixtures, provas e consumidores

| Fonte | Pressuposto / destino e responsável |
| --- | --- |
| `tests/Support/Core/Stubs/UserPortStub.php` | Constructor/retorno int → owner UUID explícito; mocks consumidores na mesma fatia. 4.5/11.1. |
| `tests/Support/Identity/Fixtures/IdentityFixture.php`, `Helpers/IdentityHttpJourney.php` | Model/PAT real v7; `signUp(): int` e cast relationship → string. Link assinado mantém hash e datas/status explícitos. 4.9. |
| `tests/Support/Expense/Fixtures/{ExpenseQueryHistoryFixture,ExpenseSuggestionHistoryFixture}.php` | Argumento owner e retorno/getKey int → UUID; amount permanece int. 5.8/10.6. |
| `tests/Support/Expense/Fixtures/{ExpenseQueryFixture,ExpenseCursorFixture}.php` | Legacy cursor `id=5` vira cenário negativo; positivos v2 com ID v7 ordenado deterministicamente; não reparar inputs inválidos. 5.4/5.8. |
| `tests/Support/Notifications/Fixtures/NotificationRegistrationFixture.php` | Duas instalações atuais v4 → fixtures v7 distintas de IDs de registro; preservar casos v4 negativos. 6.5. |
| Nova fixture tipada de UUID em `tests/Support/Core/` | Exemplos distintos/determinísticos com ordenação declarada; esperado não depende de gerador de produção. 2.3. |
| `tests/Support/Core/Database/TestDatabaseCleanup.php` | Classificar `resource_identities` antes de users, sem alterar guard/preflight/ownership ou sequences técnicas. 3.7. |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | Permissões exatas para VO/exceção UUID e Data/UseCase Core nos consumidores; preservar exceção restrita de NotificationPort e pureza. 2.5/7.7/11.8. |
| `tests/Unit/{Identity,Expense,Notifications,Insights,Metrics,Core}/` | IDs literais/mocks/argumentos inteiros, hashes esperados e instalação v4 → fixtures/contratos v7 por papel no step proprietário; contagens/centavos/datas preservados. 2/4/5/6/7/8/9/10. |
| `tests/Feature/Identity/{SlidingSanctumSessionTest,EmailVerificationTest}.php`, `Presentation/Http/SignInHttpTest.php`, `Infrastructure/Repositories/Persistence/EloquentEmailVerificationRepositoryTest.php` | Casts owner/getKey, links, PAT/pruning/locks → UUID real; sem simular o Bearer nos cenários que o provam. 4.9. |
| `tests/Feature/Expense/{ExpenseOwnershipTest,ExpenseClassificationTest}.php`, `Journeys/ExpenseMutationObservabilityTest.php`, `Infrastructure/Repositories/Persistence/ExpenseQueryPersistenceTest.php` | Casts owner/expense, raw bulk sem ID, ordenação e logs → v7; raw inserts fornecem ID. Provas de worker/Redis e empates seguem 5.8–5.10/11.3. |
| `tests/Feature/Notifications/Presentation/Http/NotificationRegistrationHttpTest.php`, `Infrastructure/Repositories/Persistence/{EloquentNotificationRepositoryTest,NotificationRegistrationConcurrencyTest}.php` | Casts owner/PAT; `tokenable_id + 1` para owner alheio → outro UUID explícito; IDs de instalação/registro separados, corridas mantidas. 6.7. |
| `tests/Feature/Notifications/Infrastructure/Database/NotificationFingerprintMigrationTest.php` | Prova de primeira escrita/rollback mantida com UUIDs cuja ordenação é explícita. 6.6. |
| `tests/Feature/Insights/InsightsApiTest.php`, `Presentation/Http/Monthly*Test.php`, `Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php` | Casts owners/mocks, raw inserts users/expenses e hashes públicos → UUIDs explícitos nos inserts/batches e estabilidade Core; variante não depende da sequence. 8.4–8.7. |
| `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php` e demais provas de persistência Metrics | Owner int/raw inserts sem PK → v7 explícito e registry; total/amount esperados independentes. 9.4–9.7. |
| `tests/Feature/Core/Infrastructure/Isolation/{RedisSharingTest,FailureCleanupTest}.php`, `tests/Support/Core/Fixtures/{TestResources,ConcurrentDatabaseProcess,ExecutionIsolationProbe,ObservabilityWorkerProbe}.php` | Quotas/contagens, failed_jobs UUID técnico, backend PID e manifesto continuam técnicos. Probes que registrarem User/Expense usam o novo tipo nas respectivas fatias. 11.1/11.6. |
| `bruno/{Authentication,User,Expense,Notifications,Insights,Metrics}/`, environments, `README.md`, `ARCHITECTURE.md` | Contratos/examples/assertions de ID numérico/hash/instalação v4 → strings v7; parser, execuções privadas e homologação somente no STEP 13. |

A auditoria inicial de 51 arquivos não é usada como critério de fechamento. Este inventário inclui também pontos já string (hash/v4), geração, bulk, trim global e chamadas sem cast. Cada fatia reverifica chamadores/argumentos nomeados e registra cenários antigos→novos; a auditoria transversal final é 11.6, não uma permissão para deixar um contrato alterado sem implementação/double correspondente.

### 1.4 Matriz canônica fechada e orçamento de queries

Owner canônico é escopo separado da chave. Envelope técnico: namespace constante + `identity_version=1` + lista ordenada de componentes com nome/tipo/valor. Usar codificação não ambígua (por exemplo, lista JSON de tuplas nome/tipo/valor, com strings UTF-8 e null explícito), sem concatenação simples. Ausência não se confunde com string vazia; componentes opcionais sem assunto/período usam null explícito. Fingerprint SHA-256 deriva desse envelope na borda de persistência; não armazenar chave/raw description nem publicá-lo. Tipagem concreta dos Data fica em 2.4/7.1.

| Namespace v1 | Componentes em ordem fixa (owner fora da chave) | Equivalências / mudanças legítimas | Lote final |
| --- | --- | --- | --- |
| `insights` | `type:string`, `subject:string|null` (category do candidato), `history_state:string|null`, `analysis_from:date`, `analysis_to:date`, `comparison_from:date|null`, `comparison_to:date|null` | Usar períodos internos inclusive onboarding; tipo/assunto/estado/período diferente distingue ID. Valor/maior Expense/descrição/variante/catálogo não entram. Histórico mantém ID em outro dia; vigente pode mudar pelo fim efetivo, não pelo dia de rotação isolado. | Até 6, somente após todos os textos compostos e seleção/deduplicação. |
| `expense-metrics` | `start_date:date`, `end_date:date`, `mode:string` (`total`/`category`) | Default e intervalo equivalente compartilham ID; modo diferente distingue. Total zero ainda é recurso; valores/categorias calculados não entram e categorias não recebem IDs. | 1, depois de validar/reconciliar inclusive categorias. |
| `expense-suggestions` | `description_key:string` | Reutilizar **exatamente** `$projection->key` da query: trim externo via `regexp_replace`, depois `lower(description) COLLATE "C"`; sem algoritmo PHP adicional nem colapsar espaços internos/acentos. Query/termo/janela monetária/amount opcional não entram. Key diferente distingue; representação exibida pode mudar com mesma key. | Até 5, depois de preparar/validar todas as sugestões; vazio não aloca. |

- Cada fonte financeira conserva **um statement/snapshot** por execução; o registro não consulta despesas, não fornece elegibilidade e não congela resultado.
- Lote vazio: **0 statements** do registro. Hit completo: **1 SELECT**, zero INSERT/UPDATE e sem last_access/updated_at.
- Miss/misto/disputa: **até 3 statements por tentativa** (SELECT batch, INSERT batch de ausentes, SELECT batch de reconciliação), **até 3 tentativas**; rollback completo antes de retry. Releitura de vencedor usa snapshot novo, sem CTE invisível e sem upsert de hits.
- Lote mantém ordem/correspondência e deduplica chaves; nenhuma query por cartão/sugestão/categoria. Autenticação, controle transacional e guard do launcher são classificados separadamente.
- Retenção até exclusão do owner; PAT/SignOut/pruning não apagam associações. Falha de fonte/composição/reconciliação precede resolução; falha Core aborta output inteiro sem fallback.
- Orçamento **definido**, ainda **não medido/provado**. Unit, logs SQL PostgreSQL para lotes 0/1/5/6, corridas sincronizadas e rollback real ficam em 7.8–7.11 e integrações 8–10/12.5.

### 1.5 Coordenação com Firebase

`add-firebase-push-notifications/design.md` e as duas delta specs passam a explicitar o contrato alvo coordenado: registro/owner/PAT/instalação UUIDv7, `NotificationPort::lock(string owner): string PAT`, futura mensagem `notification_id` v7 e `resource_id` próprio v7. O exemplo de instalação foi ajustado para v7 textual legítimo, não conversão de bits de um ID v4 existente.

O contrato de cadastro token FCM Android/iOS, destino exato, cifra/fingerprint/generation, conflito e cascades continua sendo a fonte do lifecycle. As evidências/checks históricos de 2026-10-13 registram o schema anterior e não provam v7; a revalidação está nas tarefas 4.7/6.* desta change. Tasks Firebase não são reabertas nem consideradas implementadas novamente. Homologação do gerador Flutter e envio/cliente/queue/produtores permanecem futuros.

### 1.6 Fatias e condição de integração

Ordem de execução confirmada com `STEPS.md`: **01 → 02 → 03 → 04 → 05/06/07 → 08/09/10 → 11 → 12 → 13 → 14**; 08/09/10 dependem de 05+07. Contratos e implementações são alterados juntos, incluindo mocks/fixtures necessários à prova do passo. Não criar union `int|string` para preservar ID legado.

| Fatia | Unidade coerente / evidência antes de liberar dependentes |
| --- | --- |
| 02 | VO/exceção/fixture determinística, contratos Data previstos e permissão arquitetural específica; Unit pura isolada. |
| 03 | Bootstrap users/PAT/expenses/notifications + registro e cleanup; PostgreSQL exclusivo com migrations incrementais, fixtures UUID explícitas, sem depender dos Models operacionais ainda inteiros. |
| 04 | User/PAT/guard/Core owner/Context/links/Responses; **alterar `NotificationPort` e Adapter juntos** e atualizar consumidores obrigatórios de owner (contratos, implementações e doubles dos contextos) para não deixar quebra de tipos; semantics/geração próprias continuam no step proprietário. |
| 05/06/07 | Expense completo com cursor/cache/queue; Notifications completo com instalação; registro Core com batches/races e binding. Steps organizáveis após owner/schema, integrados antes de qualquer publicação. |
| 08/09/10 | Integração das projeções com associação após fatos/composição e prova de chaves/batch/estabilidade/falhas. |
| 11/12 | Fechar suporte/consumidores/JSON:API/correlação; somente build integrado segue para reset local, pausa/cleanup exclusivo/restauração e medição. |
| 13/14 | Consumidores e documentação final, evidência externa distinta, gates e autorização própria de publicação/archive. |

Os STEPS 03–10 são trabalho intermediário de uma única transição incompatível: não executar/publicar HTTP operacional com schema UUID e contratos antigos, nem o inverso. Aplicação no banco operacional aguarda STEP 12; testes usam schema novo em bancos exclusivos e suítes focadas coerentes. Pendências de consumidores ficam visíveis; completar um passo não equivale a release pronta. Nenhuma compatibilidade pública int/string, alias de ID, migração de produção ou gerador global alterado faz parte da fatia.

### Verificação da entrega e rastreabilidade do STEP 01

| Task | Evidência da preparação | Estado |
| --- | --- | --- |
| 1.1 | Pedido explícito do usuário + escopo corrente registrado | Proven para STEP 01 |
| 1.2 | Boost versões/docs, vendor, PG read-only, `openspec status/instructions apply` e validação strict | Proven para reconferência, não geração/HTTP |
| 1.3 | Schema summary/pg_constraint, `route:list`, buscas por contexto de int/casts/getKey/hash/UUID/cursor/cache/queues e fixtures, matrizes arquivo/campo/destino | Proven como inventário do checkout |
| 1.4 | Matrizes D4/D5 reconferidas contra UseCases/fontes SQL e limites; composição tipada sem ambiguidade documentada | Proven como decisão; batch/races/performance Unproven |
| 1.5 | Diff de design/two delta specs/tasks Firebase; checkboxes históricos intactos; strict valid | Proven como coordenação documental |
| 1.6 | Dependências e unidades coerentes alinhadas a STEPS.md; consumidor obrigatório não adiado para auditoria final | Proven como plano de integração |

Comandos/checks executados nesta etapa:

- `openspec status --change standardize-uuid-v7-identifiers --json`: artefatos completos; isso não representa produto pronto.
- `openspec instructions apply --change standardize-uuid-v7-identifiers --json`: inicialmente ready, **0/108**; após a preparação, **6/108**, com STEPS 02–14 pendentes.
- `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive`: **valid=true**, sem issues.
- `openspec validate add-firebase-push-notifications --type change --strict --json --no-interactive`: **valid=true**, sem issues.
- Lerd exec Artisan `route:list --path=api --except-vendor --json`: **18 rotas** inspecionadas, incluindo link assinado e proteções; POST/DELETE push sem session.extend, sem GET/disparo novo.
- Boost schema/query e vendor: inspeção read-only; não são prova de geração v7/constraints novas/rollback/races.
- `git diff --check`: passou. Diff restrito a STEPS e artefatos das duas changes. Nenhum PHP alterado; Pint/testes da aplicação não foram necessários à entrega documental deste STEP. Não houve migration/reset, seed, emissão de token ou operação de workers.

**Resultado:** STEP 01 concluído; a matriz geral acima preserva os requisitos de produto como não implementados/comprovados. Próxima entrega é STEP 02 (VO UUIDv7 puro + fixture + Unit focada). Nenhum gate de produto, homologação do cliente ou archive foi aprovado por essa preparação.
