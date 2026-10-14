## 1. Autorizar apply e consolidar inventário

- [ ] 1.1 Obter autorização explícita da etapa de implementação e testes; escrever/validar esta spec não autoriza apply, reset, PHPUnit/Pest, emissão de tokens ou operação de workers.
- [ ] 1.2 Revalidar estritamente a change e reconferir PHP/Laravel/Sanctum/PG, documentação e código instalado de HasUuids, PAT/custom findToken, uuidMorphs, cursor e bulk inserts. [UID-03–06; D2/D6]
- [ ] 1.3 Inventariar PKs/FKs/IDs de Domain, Application, HTTP, SQL, cache, queue e fixtures por papel, inclusive todos os casts int/getKey; registrar arquivo/campo/destino sem converter amount/datas/contadores. [UID-01/05]
- [ ] 1.4 Registrar matriz de namespaces/componentes canônicos de Insights/Metrics/sugestões e confirmar limites de batch/queries antes do registro Core. [RID-01–04; D4/D5]
- [ ] 1.5 Coordenar a change ativa de Firebase: revisar design/specs/tasks para registro/instalação/owner/sessão v7 sem marcar envio, cliente ou trabalhos históricos como concluídos novamente. [UID-07; D8]
- [ ] 1.6 Definir fatias coerentes/dependências e impedir publicação de build com esquema/contratos misturados; não criar union int|string temporária como compatibilidade pública. [UID-04–06; D9]

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

## Estado desta proposta

Somente a criação/revisão/validação dos artefatos foi autorizada. Nenhuma task de implementação acima está concluída; não foram executados testes da aplicação, migrations/reset, queue, seed ou smoke test. As cinco decisões do usuário constam em proposal/design e são pré-condições do futuro apply, não seu início implícito.

## Validação desta elaboração

- `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive`: passou sem issues.
- `openspec status`: proposal, design, specs e tasks completos como **artefatos de planejamento**, não implementação.
- Revisão documental adicional: 11 capacidades declaradas correspondem aos 11 arquivos de specs; 42 requisitos e 162 cenários; 26 blocos MODIFIED conservam todas as âncoras de cenários da spec principal, evitando perda na futura sincronização.
- Checklist: 108 tasks únicas em 14 fases, todas pendentes; matriz de evidências inicial sem resultados de implementação presumidos.
- Formatação documental/EOF e `git diff --check` passaram. `git status` mostra somente a nova pasta desta change; código, schema, specs principais e outra change ativa permanecem sem alterações nesta elaboração.
