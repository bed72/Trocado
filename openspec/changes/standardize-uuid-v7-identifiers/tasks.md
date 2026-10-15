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

- [x] 2.1 Implementar UuidValueObject/exceção em Core Domain para forma v7/variante/canonicalização de caixa/equivalência, sem framework/clock/generator. [UID-02; D2]
  - `UuidValueObjectTest.php` isolado pelo launcher: 39 testes/46 assertions aprovados; `fromString/value/equals`, exceção sem eco da entrada. Evidência final do STEP 02 abaixo.
- [x] 2.2 Provar UUID válido, uppercase equivalente, v1/v4/v6/v8, nil, variante inválida, hash, inteiro/string numérica, espaços e ausência explícita; builders negativos não devem reparar entrada. [UID-02]
  - O mesmo arquivo prova as quatro variantes RFC, limites de bits, equivalência simétrica, diferenças, malformações e rejeição de `null`/não strings. Aceitação de `null` nas entidades pré-create será integrada nos STEPs 04/05/06; o VO não representa ausência.
- [x] 2.3 Introduzir fixture UUIDv7 determinística tipada em Tests\Support\Core para IDs distintos e ordering, sem BaseBuilder/catálogo de mocks ou esperado calculado pelo gerador de produção. [UID-03; D10]
  - `UuidFixtureTest.php` isolado pelo launcher: 4 testes/13 assertions aprovados; índices explícitos, extremos e rejeição fora de 48 bits. Nenhum consumidor existente foi convertido pela fixture nova.
- [x] 2.4 Definir nomes e tipos dos contratos/Inputs/Outputs de identidade Core; string canônica para IDs presentes e null somente nos pontos legítimos antes de persistir. [UID-05; RID-01]
  - Design D2, subseção STEP 02: quatro Data, Repository e UseCase definidos, lista ordenada, IDs obrigatórios e pontos nullable existentes conferidos no código. Implementação desses contratos é 7.1/7.2; UserPort/ContextPort são 4.5.
- [x] 2.5 Atualizar permissões arquiteturais específicas para conceito/capacidade Core e provar ausência de imports Core→contextos, Domain→framework e Application→ORM. [D2; identidade-context]
  - ARCHITECTURE e allowlist permitem somente VO/exceção novos, sem liberar diretórios. Capacidade futura tem permissões específicas definidas para STEP 07. Arquivo arquitetural isolado aprovado: 30 testes/462 assertions após Pint.
- [x] 2.6 Executar o arquivo Unit Core isolado pelo launcher e registrar resultado antes de avançar para a conversão ampla. [UID-02]
  - Após Pint, VO isolado 39/46, fixture isolada 4/13 e Unit Core 251/717 (testes/assertions), todos aprovados com fail-on-skipped/incomplete/risky. Comandos e limites na seção STEP 02 abaixo.

## 3. Bootstrap schema UUIDv7 e cleanup seguro

- [x] 3.1 Atualizar bootstrap de users para PK uuid/geração legítima v7 e preservar campos, email unique, password/status/verificação/avatar e timestamps. [UID-04; user]
  - Bootstrap UUID nativo sem sequence/default, CHECK v7 e campos preservados comprovados no STEP 03. Geração PHP do Model pertence a 4.2, não foi antecipada.
- [x] 3.2 Atualizar bootstrap de personal_access_tokens para PK UUID e tokenable_id UUID/morph type atual, preservando hash/abilities/expiry/indexes. [UID-04; authentication]
- [x] 3.3 Atualizar expenses.id/user_id para UUID com FK/cascade/indexes e preservar catálogo/centavos/datas/nullable description/fencing. [UID-04; expense]
- [x] 3.4 Atualizar criação/rename de notifications para registro/owner/sessão/instalação v7, preservando constraints de token/fingerprint/geração e cascades. [UID-04/07]
- [x] 3.5 Criar migration resource_identities com PK/owner UUID, namespace, identity_version, fingerprint e created_at; unique composto, FK cascade e nenhuma coluna de fatos/segredos/last_access. [RID-01–03/05]
- [x] 3.6 Implementar/verificar checks de versão/variante/campos obrigatórios e inexistência de sequences/ID inteiro alternativo em tabelas próprias. [UID-04]
- [x] 3.7 Classificar resource_identities em TestDatabaseCleanup e preservar guards inicial/efetivo e ownership exato antes de migration/fixture/cleanup/drop; não mudar PKs técnicas Laravel. [RID-07; UID-08]
  - Guard Unit, recusa real de cleanup e isolamento com duas invocações comprovados. Gate global bloqueado pela conversão de Models ainda pendente; não há aprovação global deste suporte compartilhado.
- [x] 3.8 Provar schema/FKs/uniques/checks em PostgreSQL exclusivo do launcher com fixtures explícitas e migrations incrementais; não resetar o banco operacional nesta fase de prova. [UID-04; RID-01]
  - `UuidSchemaTest.php` isolado: 171 testes/443 assertions, passando sem warnings/skips/incomplete/risky. Evidência e limites abaixo.

## 4. Identity, Core owner e Sanctum

- [x] 4.1 Converter UserEntity/Repository/Data/UseCases de criação/leitura/update/delete para IDs v7 e validar fora de HTTP, sem password/token no Domain. [user; UID-02/05]
- [x] 4.2 Configurar UserModel com geração UUIDv7 e remover casts/comentários/relações que pressupõem inteiro; conservar a separação de Expense Model. [user; UID-03]
- [x] 4.3 Implementar Model próprio de PAT UUIDv7 em Identity e registrá-lo via Sanctum::usePersonalAccessTokenModel; sem vendor changes ou credencial nova. [authentication; D6]
- [x] 4.4 Proteger lookup de parte ID malformada/legada para 401 antes de SQL UUID, preservando resolução oficial/hash/segredo Sanctum e inputs suportados pelo pacote. [authentication: Bearer]
- [x] 4.5 Converter Core UserPort/UserAdapter/ContextPort/ContextAdapter e consumidor do middleware para owner canônico v7; atualizar assinaturas e implementações em uma fatia coerente, sem fallback de Context/guard ou cast numérico. [UID-05]
  - Contratos/implementações e stub string; middleware existente continua passando o owner explicitamente. Consumers de negócio ainda inteiros pertencem aos STEPs 05–10; build global não está liberado.
- [x] 4.6 Converter SignInOutput/Adapters/Ports e Responses: User/PAT/relationship UUIDv7, token uma vez/no-store e UUID preservado em extensão. [authentication]
- [x] 4.7 Converter SessionAdapter e NotificationAdapter owner/sessão/retorno para UUIDv7, preservando locks/aptidão/owner/validade; não ampliar dependência cross-context. [UID-05/07]
  - SessionAdapter opera o PAT string configurado, sem mudança de política. NotificationPort/Adapter convertidos juntos; registro completo e seus mocks/Entities/Repository são STEP 06.
- [x] 4.8 Converter rotas/controllers/Requests User e verificação assinada para UUIDv7, mantendo checagem da assinatura antes de canonicalização e 404/401/403/422 existentes. [user; authentication]
- [x] 4.9 Atualizar testes/fixtures/doubles Identity e provar PAT real v7, segredo, owner, expiração, extensão/pruning/logout, link assinado, cascades e invocação fora de HTTP. [UID-04–06; D6]
- [x] 4.10 Executar arquivos Identity/Core afetados isoladamente e suites focadas; registrar falhas/limitações sem enfraquecer temporalidade/ownership para acomodar tipo. [D10]
  - Arquivos isolados, Feature Identity 112/916, Unit Identity/Core + arquitetura 383/1584, duas seeds focadas 505/2652 e paralelo Feature 112/916 aprovados. Gate global continua bloqueado em Expense; detalhes abaixo.

## 5. Expense, cache, classificação e cursor

- [x] 5.1 Converter ExpenseEntity, Repository/UseCases/Data e mapping CRUD/cache para ID/owner strings v7; remover casts integer somente desses campos. [expense; UID-05]
- [x] 5.2 Configurar geração v7 de ExpenseModel e revisar bulk/seed/fixtures para fornecer IDs válidos onde hooks não executam. [UID-03/04]
- [x] 5.3 Converter rotas/controllers/Requests e relações JSON:API de Expense para IDs v7 e preservar erro uniforme de owner/ID inválido antes de lookup. [UID-06; expense]
- [x] 5.4 Implementar cursor v2 com posição ID UUIDv7 e amount int separados; rejeitar v1/legacy numéricos e campos/direção/critério incompatíveis. [expense: paginação; D7]
- [x] 5.5 Revisar seek/ordenação SQL UUID em ASC/DESC e ties, mantendo ICU/null/descrição original; não usar ordem de geração como esperado. [expense-querying]
- [x] 5.6 Versionar chaves/serialização/tags de CachedExpenseRepository por owner UUID/cursor v2, conservando TTL/invalidação após commit e isolamento. [EXP-UID]
- [x] 5.7 Converter dispatch/Queue/UseCase/Repository de classificação para expenseId UUIDv7 e preservar fencing string, prazo, fallback e proteção contra edição posterior. [EXP-UID]
- [x] 5.8 Atualizar provas Unit e PostgreSQL/HTTP de CRUD/sort/cursor/cache/classificação, com next/prev e empates explicitamente ordenados por UUIDs de fixture. [expense; D7]
- [x] 5.9 Provar worker real em fila exclusiva/Redis e invalidação scoped após commit, sem FLUSHALL/FLUSHDB ou consumo de fila operacional. [EXP-UID; D10]
- [x] 5.10 Executar arquivos Expense afetados isoladamente e suite focada/Redis/concorrência pertinente; registrar planos de filtros/indexes sem extrapolar escala. [D10]

## 6. Notifications e contrato de instalação

- [x] 6.1 Configurar registro UUIDv7 no Model/Repository e canonicalizar mapping, preservando ID em sincronização/rotação. [UID-03/07]
- [x] 6.2 Converter tipos de owner/session em Entity/Repository/UseCases/Ports e validação Domain, mantendo unidade transacional/locks/fingerprint/cifragens. [UID-05/07]
- [x] 6.3 Exigir installation_id UUIDv7 no VO/Request, normalizar somente caixa válida e rejeitar outras versões com pointer sem eco de destino. [UID-02/07]
- [x] 6.4 Ajustar DELETE/Response/rotas para registro v7 e confirmar 204/404 uniforme/auth/cota/não extensão/nenhum GET ou envio HTTP novo. [UID-06/07]
- [x] 6.5 Atualizar fixtures/doubles Unit e registro de observabilidade para IDs reais v7 e instalação distinta; sem usar installation_id como PK por conveniência. [UID-07]
- [x] 6.6 Ajustar prova de migration fingerprint para ordering v7 explícito, preservando rollback sentinela/escrita anterior/ciphertext/lifecycle; não remover a prova porque os dados antigos serão descartados. [UID-04; D9]
- [x] 6.7 Provar PostgreSQL/HTTP e corridas sincronizadas de idempotência/rotações/disputa/logout/cascades com IDs v7, mantendo testes de segredos e geração. [UID-07]
- [x] 6.8 Executar arquivos/suite Notifications e integração com Identity isoladamente; atualizar evidência da fatia de cadastro sem marcar envio/cliente aprovado. [D8/D10]

## 7. Registro transversal de Core

- [x] 7.1 Implementar Data mínimo tipado de lote/chaves/saída e contrato ResourceRepository, sem Models/Builders/Outputs financeiros. [RID-01/02]
- [x] 7.2 Implementar ResourceUseCase concreto com validação owner/namespace/versão, deduplicação e manutenção da ordem, sem framework. [RID-02/04]
- [x] 7.3 Implementar Model e Repository Eloquent de associação, digest interno não ambíguo e geração v7 somente para chaves ausentes. [RID-01–03]
- [x] 7.4 Implementar leitura de hits em lote sem UPDATE/timestamp e saída vazia sem query/alocação. [RID-04]
- [x] 7.5 Implementar insert batch sob transação curta/ordem técnica, unique conflict e releitura com snapshot novo; sem publicar UUID candidato perdedor. [RID-03; D5]
- [x] 7.6 Implementar retries limitados de race/deadlock/serialization com rollback antes da nova tentativa e falha sanitizada após esgotamento. [RID-03/06]
- [x] 7.7 Registrar binding do Repository Core e autowiring do UseCase, sem bindings redundantes, helpers globais, Interfaces de UseCases ou Service Locator. [RID-01; D2]
- [x] 7.8 Provar Unit de validação/chaves/lote/ordem/erros com doubles próprios e contagem/argumentos explícitos, sem bootstrap. [RID-01–04/06]
- [x] 7.9 Provar PostgreSQL hit/miss/misto/unique/UUID/owner/cascade/rollback e limite de statements, incluindo ausência de writes em hits. [RID-01–05]
- [x] 7.10 Provar corrida sincronizada de criação da mesma associação e exclusão de owner, com conexões novas/barreiras/timeouts/diagnóstico/cleanup. [RID-03/05]
- [x] 7.11 Executar arquivos Core isolados e registrar pré-condições/query plans/contagens; nenhum teste fake pode provar rollback ou race PostgreSQL. [D10]
  - Evidência final do STEP 07 abaixo: Unit 33/125; Repository PG 15/112; corridas 3/9; arquitetura 30/504; Core + arquitetura 535/2.236. Gate padrão, duas seeds e paralelo aprovados.

## 8. UUIDv7 estável de Insights

- [x] 8.1 Converter owner nos contratos/fonte SQL/fatos/edição de variante para v7, sem modificar janela, bases ou matemática. [UID-05; insights]
- [x] 8.2 Preparar chave lógica tipada por owner/tipo/categoria/estado/from/to/comparison, com namespace/version constantes e períodos internos de onboarding. [RID-02; insights]
- [x] 8.3 Compor/selecionar/deduplicar todos os recursos antes de resolver IDs em um único lote, substituir hash público pelo UUID Core e manter ordem/limite. [RID-04/06]
- [x] 8.4 Provar Unit de chaves/default/zeros/periodos/estado e estabilidade frente a valor/descrição/variante/dia/catálogo, com novo ID só por mudança lógica. [insights: identidade]
- [x] 8.5 Provar HTTP/PG associação estável em visitas/processos/PATs novos, batch, ownership, onboarding null, desaparecimento/retorno e limites editoriais preservados. [RID-03–05; insights]
- [x] 8.6 Provar fonte/composição/registro falhando sem associação nova, data parcial, UUID aleatório ou onboarding fabricado; manter uma leitura financeira. [RID-06; insights]
- [x] 8.7 Executar arquivos/suite Insights e arquitetura isolados, com resultados por cenário e distinção entre queries de fatos/identidade/middleware. [D10]

## 9. UUIDv7 estável de Metrics

- [x] 9.1 Converter owner no Repository/UseCase/mapping Metrics para v7, mantendo parâmetros/default/total/percentuais exatos e snapshot. [UID-05; expense-metrics]
- [x] 9.2 Preparar chave por owner/start/end/mode normalizados, independente de URL/trim/valores, e resolver UUID depois de reconciliar projeção. [RID-02/06]
- [x] 9.3 Substituir hash público por associação Core para objeto singular, inclusive zero total; não criar IDs de categoria ou persistir resumo. [expense-metrics]
- [x] 9.4 Provar Unit de chave/modo/default equivalente/zero/valores, ordenação e fake de registro sem ORM. [expense-metrics: identidade]
- [x] 9.5 Provar HTTP/PG estabilidade entre processos/PATs/mudanças financeiras, owners/modos distintos, registry zero e batches/queries constantes. [RID-02–05]
- [x] 9.6 Provar falha de fonte/projeção antes de associação e falha Core com erro explícito sem total zero/resultado parcial/IDs transitórios. [RID-06]
- [x] 9.7 Executar arquivos/suite Metrics isolados e revisar que associação não adicionou cache, resumos, filas ou query por categoria. [expense-metrics; D10]

## 10. UUIDv7 estável de sugestões

- [x] 10.1 Converter owner no contrato/fonte de sugestões para v7 e conservar agrupamento/normalização SQL/padrão de valor/janela/limite. [UID-05; expense-suggestions]
- [x] 10.2 Preparar chave de Core pela mesma chave normalizada SQL, independente de termo/valor/janela, sem persistir raw description. [RID-02]
- [x] 10.3 Resolver lote final após validação/preparação, substituir hash por UUID e omitir associação em data vazio; sem identificar Expense row específica. [RID-04/06]
- [x] 10.4 Provar Unit/HTTP de termo diferente/case equivalente/valor opcional/owner diferente/novo processo e descrição normalizada diferente, com UUIDs corretos. [expense-suggestions]
- [x] 10.5 Provar desaparecimento/retorno com mesmo UUID, fonte/registro falhando e uma leitura financeira sem writes de despesa/IA/queue/cache. [RID-05/06; expense-suggestions]
- [x] 10.6 Executar arquivos de sugestões isolados e integração com Expense/registro Core; não enfraquecer busca literal/limites ou interpolar descrição em logs. [D10]

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

## Matriz requisito/cenário → trabalho → evidência corrente

| Requisito / cenários | Tasks principais | Prova mínima | Estado corrente |
| --- | --- | --- | --- |
| UID-01 política/exclusões e todos os recursos próprios | 1.3, 3.*, 11.2/11.6 | Inventário por papel + schema/HTTP + arquitetura | Não implementado/comprovado |
| UID-02 canônico/v7/variante/negativos/null | 2.1–2.3, 4.1, 6.3 | Unit pura + HTTP antes de lookup + PG checks | VO puro STEP 02 e integração User/PAT/Expense/Notifications STEPs 04–06 comprovados; registro Core/projeções/rollout pendentes |
| UID-03 geração padrão/imutabilidade | 3.*, 4.2–4.3, 5.2, 6.1, 7.3 | Model/PG create-update + formato + callback/clock fora de Domain | User/PAT/Expense/Notifications comprovados nos STEPs 04–06, inclusive repetição/rotação/corridas de cadastro; associações Core pendentes |
| UID-04 PK/FK/morph/cascades | 3.1–3.8, 4.9, 6.7 | PostgreSQL tipos/constraints/owner/session/encerramento | Schema STEP 03 e lifecycle User/PAT/Expense/Notifications STEPs 04–06 comprovados em bancos exclusivos; integração da capacidade Core e rollout pendentes |
| UID-05 contratos/guard/sem cast | 2.4–2.5, 4.5/4.7, 5.1, 8.1/9.1/10.1, 11.6 | Unit argumentos + arquitetura + autenticação real | Owner/sessão dos consumidores atuais comprovados no gate transversal de 2026-10-15, sem casts numéricos nas fronteiras corrigidas. Auditoria final de papéis/novas capacidades e rollout ainda pendentes |
| UID-06 rotas inválidas/owner/auth | 4.8–4.9, 5.3/5.8, 6.4/6.7 | HTTP 200/201/204 e 401/403/404/422/429 | User/Auth STEP 04, Expense STEP 05 e Notifications STEP 06 comprovados; proteções/IDs/404 uniforme e rejeição antes de lookup inválido preservados; rollout pendente |
| UID-07 instalação/registro/cliente | 1.5, 6.*, 13.2/13.6/13.7 | Unit/HTTP/PG + homologação externa registrada | Backend Proven no STEP 06: v7/caixa/versões/ID distinto/imutável/HTTP/PG/races/rollback. Homologação externa Flutter/Bruno/envio e rollout operacional pendentes |
| UID-08 reset autorizado/negativo/lifecycle | 3.7, 12.* | Alvo/estado/cleanup/checks registrados + guard/testes de recusa | Parcial: guard e cleanup do launcher comprovados no STEP 03; reset operacional não executado |
| RID-01 mínimo/sem fatos/fronteiras | 3.5, 7.1/7.3/7.7, 13.1 | Schema allowlist + Unit + arquitetura | Capacidade Core e schema mínimo Proven no STEP 07; integração das projeções/documentação geral pendente |
| RID-02 chave/namespace/owner/ambiguidade | 1.4, 7.2/7.8, 8.2/9.2/10.2 | Unit independente por consumidor + PG isolado | Core genérico Proven no STEP 07; Insights Proven no STEP 08 para chave exata, nulls, owner/estado/períodos/equivalências. Metrics/sugestões pendentes |
| RID-03 race/ID perdedor/rollback | 7.5–7.6/7.9–7.10 | Duas conexões sincronizadas + escrita sentinela/rollback PG | Proven no STEP 07: UUID vencedor em processo novo, rollback parcial e retries 3; SQLSTATEs reais induzidos para recuperação/esgotamento |
| RID-04 vazio/hit/misto/ordem/queries | 7.2/7.4/7.9, 8.3/9.3/10.3, 12.5 | Unit batch + query logs PG de 0/1/5/6 recursos | Core Proven no STEP 07: 0/1/3 statements e ordem/repetições; Insights STEP 08: lote HTTP de três cartões, uma leitura financeira e 3/1 statements de registro miss/hit, sem escrita em hit. Metrics/sugestões/medição operacional pendentes |
| RID-05 reinício/PAT/reaparecimento/cascade | 7.9–7.10, 8.5/9.5/10.5 | HTTP/PG processos novos + owner delete + recursos ausentes | Core Proven no STEP 07 para processo/dia/PAT/cascade/owner concorrente; Insights STEP 08 comprova HTTP em processo filho/conexão nova/PAT novo após desaparecimento/retorno. Reboot do servidor, Metrics/sugestões e rollout pendentes |
| RID-06 erro/composição/fonte/sem fallback | 7.6, 8.6/9.6/10.5 | Exceção sentinela Unit/HTTP + zero writes + erro sem data/log sensível | Core Proven no STEP 07; Insights STEP 08 comprova falhas de fonte/precisão/composição antes de associação e rollback após INSERT com erro JSON:API sem data. Metrics/sugestões pendentes |
| RID-07 sem endpoint/autoridade/cleanup | 3.7, 7.9, 11.5 | HTTP/owner + lifecycle exact runId/token | Core e cleanup/ownership Proven nos STEPs 03/07; nenhuma rota adicionada. Integração HTTP das projeções pendente |
| User/Core UUID ownership e Entity pura | 2.*, 4.1/4.5/4.8/4.9 | Unit + HTTP + fronteiras | Proven para Identity/Core no STEP 04; consumidores e ambiente operacional ainda em conversão |
| Sanctum/segredo/expiração/extensão/link | 4.2–4.4/4.6–4.9 | PAT real + PG locks + assinatura/tempo/owner | Proven no schema exclusivo do STEP 04, incluindo corrida sincronizada de extensão; rollout operacional pendente |
| Expense sort/cursor v2/cache/worker | 5.* | Unit + PG/HTTP next-prev + Redis/worker exclusivo | Proven no STEP 05 em schema/Redis/filas exclusivos; transição operacional de caches/jobs/banco ainda no STEP 12 |
| Notifications registro/instalação/rotação/remoção | 6.* | Unit + HTTP/PG + rollback/races + Identity | Proven no STEP 06 em bancos exclusivos; v4/whitespace rejeitados, ID preservado e DELETE uniforme. Envio/cliente/rollout operacional pendentes |
| Insights períodos/estados/rotação/UUID | 8.* | Unit + HTTP/PG + Core batch | Proven no STEP 08: UUID associado, chaves tipadas, fatos/editorial preservados, equivalências/estados/períodos/owner, processo/PAT/retorno, falhas e queries separadas. Operação local permanece no STEP 12 |
| Metrics singular/zero/default/grouped/UUID | 9.* | Unit + HTTP/PG + Core batch | Não implementado/comprovado |
| Sugestões norm/valor/owner/UUID | 10.* | Unit + HTTP/PG normalização SQL/associação | Proven no STEP 10: chave SQL exata, UUIDv7 batch, owner/termos/case/valor/janela/processo/PAT/retorno, falhas e limites de queries; medição operacional no STEP 12 |
| Observabilidade próprio UUID/native SDK | 11.3–11.4 | JSON/header/context + ausência de segredos/fingerprint | Não implementado/comprovado |
| Cliente/Bruno/documentação | 13.* | Parser/CLI controlados + homologação externa distinta | Não implementado/comprovado |
| Gates transversais | 14.* | Padrão + duas seeds + paralelo + Redis/concorrência | Evidências históricas dos STEPs 06/07 preservadas abaixo. Após STEP 08: padrão 2.267/40.376 e Feature Insights paralelo 176/1.960. Seeds/gate paralelo completo não repetidos nesta fatia; repetir gates finais após implementação restante, sem concluir 14.* |

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

## STEP 02 — Conceito UUIDv7 puro em Core — 2026-10-14

### Autorização, implementação e contratos

Pedido: “Seguindo a implementacao da spec, vamos para o step: ## STEP 02 — Conceito UUIDv7 puro em Core”. Autoriza a fatia 2.1–2.6 e suas provas, incluindo os gates exigidos para suporte transversal novo. `git status --short` estava limpo antes das alterações. Boost confirmou PHP 8.5, Laravel 13.34.0, Pest 5.2.1, PHPUnit 13.3.4 e Pint 1.32.1; site Lerd descoberto como `trocado`. As skills locais SDD, arquitetura e quality gate foram lidas nesta execução; Boost Search Docs consultado para datasets/arquitetura Pest 5.

- `app/Core/Domain/ValueObjects/UuidValueObject.php`: `final readonly`, constructor privado, `fromString/value/equals`, validação integral com âncoras `\A`/`\z`, versão 7 e variante 8/9/a/b; canonicaliza somente caixa, sem trim/clock/geração/framework.
- `app/Core/Domain/Exceptions/InvalidUuidException.php`: exceção de Domain sem detalhes da entrada. String inválida lança essa exceção; não string/ausência é `TypeError` na chamada estrita. Ausência não vira VO vazio e não foi adicionada factory nullable.
- `tests/Support/Core/Fixtures/UuidFixture.php`: índice explícito 0–0xFFFFFFFFFFFF em prefixo v7 fixo, sem gerador de produção. Esperados literais independentes, ordem lexical controlada e entradas negativas não reparadas. Não representa geração de produto nem prova de ordem global de cadastro.
- `design.md` D2 fecha nomes/tipos dos quatro Data, Repository e UseCase futuros, owner/saída obrigatórios e os únicos IDs de Entity nullable existentes (User/Expense). NotificationRegistrationEntity mantém ID obrigatório. Definição documental não marca 7.1/7.2 nem 4.5 como implementados.
- `ARCHITECTURE.md` e `ContextBoundariesTest.php` permitem especificamente o VO/exceção; não liberam diretórios, ORM ou dependência Core→consumidores. A capacidade futura permanece restrita às permissões nominadas do design para implementação no STEP 07.

### Cenário → evidência

| Cenário / requisito desta fatia | Evidência | Estado |
| --- | --- | --- |
| UUIDv7 textual, quatro prefixos de variante RFC, extremos válidos | Dataset literal de `UuidValueObjectTest.php` | Proven |
| Caixa equivalente, igualdade reflexiva/simétrica e IDs distintos | `compares identity by canonical value...` | Proven |
| v1/v4/v6/v8/nil/max UUID/variantes inválidas/hash/número/whitespace/NUL/forma inválida | Datasets negativos sem builder/normalização intermediários | Proven |
| Ausência e tipos inválidos não viram identidade presente | Dataset integer/float/bool/null/array → TypeError | Proven no VO; integração nullable das Entities permanece nos STEPs 04/05/06 |
| Mensagem de formato não ecoa entrada rejeitada | Assertion de exceção literal | Proven |
| Fixture distinta, repetível, ordenada, limites e índice inválido | `UuidFixtureTest.php`, esperado literal | Proven |
| Pureza de Domain/Application e isolamento de Core | Arquivo arquitetural isolado e gate completo | Proven para o código corrente |
| Contratos/Data/nullable de Core definidos | Design D2 e inspeção dos contratos/Entities existentes | Definição concluída; implementação do registro e conversão de consumidores pendentes |
| Geração/persistência/HTTP/associação UUIDv7 | Nenhuma implementação dessas etapas nesta fatia | Unproven, STEPs 03–14 |

### Comandos e resultados

Todos os comandos Pest abaixo passaram pelo launcher `lerd composer test --`, com os flags `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` no final. Nenhuma execução registrou falha, skip, incomplete ou risky. Durações são as reportadas pelo runner, sem o tempo externo de provisionamento.

| Argumentos antes dos flags comuns | Testes / assertions | Duração |
| --- | --- | --- |
| `tests/Unit/Core/Domain/ValueObjects/UuidValueObjectTest.php` (isolado, após Pint) | 39 / 46 | 27 ms |
| `tests/Unit/Core/Support/UuidFixtureTest.php` (isolado, após Pint) | 4 / 13 | 24 ms |
| `tests/Unit/Architecture/ContextBoundariesTest.php` (isolado, após Pint) | 30 / 462 | 4.746 ms |
| `tests/Unit/Core` (após Pint) | 251 / 717 | 2.074 ms |
| nenhum (gate completo padrão) | 1.865 / 38.749 | 41.147 ms |
| `--order-by=random --random-order-seed=20261014` | 1.865 / 38.749 | 40.836 ms |
| `--order-by=random --random-order-seed=20261015` | 1.865 / 38.749 | 41.620 ms |
| `--parallel --processes=2` | 1.865 / 38.749 | 26.410 ms |

O gate completo incluiu os grupos existentes Redis/concorrência e a prova de duas invocações simultâneas, sem exclusões. Feature foi provisionado pelo launcher com migrations incrementais em bancos exclusivos; Unit puro não provisionou banco. Os testes completos comprovam regressão do código corrente, não a futura conversão UUIDv7 do schema/consumidores.

`lerd exec`/`vendor_run` Pint `--dirty --format agent` executou e corrigiu somente a caixa dos literais hexadecimais nos dois arquivos de fixture/prova; os arquivos afetados foram reexecutados isoladamente depois. A segunda execução de Pint passou sem alterações. `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive` passou sem issues após o registro de evidências; `git diff --check` também passou.

**Resultado:** tarefas 2.1–2.6 concluídas e sincronizadas com `STEPS.md`. Próxima etapa: STEP 03, schema e cleanup seguro. Reset operacional, homologação, archive e gate final da conversão permanecem nas etapas próprias.

## STEP 03 — Schema UUIDv7 e cleanup seguro — 2026-10-14

### Escopo e implementação

Pedido: “Seguindo a implementacao da spec, vamos para o step: 3”. Autoriza 3.1–3.8 e suas provas PostgreSQL pelo launcher. O checkout começou limpo. Boost reconfirmou PHP 8.5/Laravel 13.34.0/PG, APIs de migrations e schema/constraints operacionais; Lerd descobriu o site `trocado`. Skills arquitetura/quality gate consultadas. A skill SDD local não estava disponível na árvore; o fluxo foi conferido por `openspec status`/`instructions apply` e artefatos existentes.

- Migrations de bootstrap de User/PAT/Expense agora criam PKs UUID sem sequence/default e referências UUID. `uuidMorphs` preserva type/índice composto do PAT; não cria FK/cascade polimórfico inexistente. Campos/uniques/status/datas/avatar/centavos/nullable/fencing continuam nas migrations existentes.
- Criação de `push_registrations` usa owner/PAT UUID e quatro CHECKs v7; rename para `notifications` renomeia também esses CHECKs nos dois sentidos. A prova de `down/up` preserva a row e os checks. Migration de fingerprint permanece intacta; sua prova com ordering UUIDv7 será convertida em 6.6.
- `2026_10_14_203520_create_resource_identities_table.php`, gerada via Artisan, cria somente `id`, `user_id`, `namespace`, `identity_version`, `logical_fingerprint`, `created_at` (`timestampTz(6)` obrigatório). Unique `(user_id, namespace, identity_version, logical_fingerprint)` e FK owner cascade. Namespace técnico lowercase alfanumérico iniciado por letra, com segmentos separados por hífen, até 64 caracteres; versão smallint positiva e digest hex lowercase de 64 caracteres. Não há TTL, last_access, updated_at, payload ou fatos financeiros.
- CHECKs em todas as 11 colunas UUID próprias validam versão 7 e variante RFC (`8/9/a/b`) na representação canônica do PostgreSQL. NOT NULL protege obrigatoriedade. Banco canonicaliza caixa; validação textual/whitespace antes do SQL continua no VO/consumidores, não é atribuída ao tipo UUID PostgreSQL.
- `TestDatabaseCleanup::TABLES` classifica `resource_identities` antes de `users`; guard/preflight/manifesto/ownership/cleanup de bancos e sequências técnicas não foram alterados.
- `UuidSchemaFixture` prepara rows tipadas explícitas por papel para provas de schema, sem usar Model/gerador de produto. `ExecutionIsolationProbe` usa UUIDs coincidentes entre execuções (`at(1500)` User, `at(1501)` associação), mantém sentinelas técnicas Redis/cache/limiter/queue e passa a verificar também a associação. Não converte UserModel/contratos de negócio antecipadamente.

### Cenário → evidência

| Requisito / cenário de schema e lifecycle | Evidência atual | Estado |
| --- | --- | --- |
| UID-04 schema novo completo, 11 colunas nativas UUID/NOT NULL, PKs sem sequence/default/ID inteiro paralelo | `UuidSchemaTest`: catálogo PostgreSQL, PK e inventário de colunas de identidade | Proven |
| UID-04 versão/variante em cada PK/owner/PAT/instalação | Dataset por coluna × v1/v4/v6/v8/nil/variantes 0/7/c/f; SQLSTATE 23514 e nenhuma row inválida | Proven |
| UUID obrigatório/null, quatro prefixos RFC e caixa uppercase | Datasets NOT NULL/aceitação canônica | Proven no schema; HTTP/Domain dos consumidores continuam pendentes |
| UID-04 FK órfã Expense owner, Notifications owner/session, Core owner | SQLSTATE 23503 por FK real | Proven |
| PKs/email/hash PAT/fencing/instalação/fingerprint/logical key únicos | Datasets SQLSTATE 23505 e uma row | Proven |
| RID-01 schema mínimo/sem fatos e obrigatoriedade/forma de namespace/versão/digest/instante | Allowlist literal de seis colunas + datasets negativos | Proven |
| RID-02 escopos owner/namespace/versão/fingerprint distintos | Duas rows com somente a dimensão indicada distinta | Proven para unique; construção da chave tipada ainda no STEP 07 |
| UID-04 campos/índices existentes preservados | Valores literais User/PAT/Expense/Notifications e índices catalogados | Proven para persistência de schema; fluxos Application/HTTP ainda pendentes |
| UID-04/RID-05 remoção de conta e outra associação preservada | Delete SQL User: cascades Expense/Notifications/Core, outra User/Core preservados | Proven para FKs; remoção de PAT na unidade Identity é 4.9 |
| UID-04 sessão removida, outro dispositivo preservado, associação Core retida | Delete SQL PAT: cascade seletivo Notifications; Core/User intactos | Proven para schema; SignOut/pruning HTTP pendentes |
| Rename incremental em ambos os sentidos | Down/up isolado da migration com row/CHECKs preservados e restauração em finally | Proven |
| UID-01/04 IDs técnicos nativos | Tipos int8/int4 jobs/failed_jobs/migrations e sequências não resetadas | Proven |
| RID-07/UID-08 cleanup sob ownership exato, recusa antes de DML e migrations preservadas | Cleanup real + recusa com config divergente + `TestDatabaseGuardTest` (inclui divergência efetiva/owner) | Proven |
| RID-07 isolamento de duas invocações/processos e cleanup independente | Probes com mesmas User/associação/keys; barreira e inspeção de recursos/DBs no teste existente | Proven; não é corrida do resolver Core |
| Geração PHP legítima/lookup de Bearer/HTTP/registry resolver/races de associação | STEPs 04–11 ainda pendentes | Unproven nesta fatia |
| Gate global da aplicação no schema novo | Tentativa parada na primeira falha de UserModel sem UUID | Blocked até conversão dos Models/fixtures/consumidores; não é aprovação global |

### Comandos, resultados e limites

Todos os comandos abaixo usam `lerd composer test --`. Flags comuns da evidência final: `--compact --fail-on-warning --fail-on-skipped --fail-on-incomplete --fail-on-risky`. As execuções aprovadas não registraram warnings/skips/incomplete/risky. Feature provisionado/migrado incrementalmente em bancos exclusivos com manifesto/runId/ownership; Unit não provisionou banco.

| Argumentos antes dos flags comuns | Resultado testes/assertions |
| --- | --- |
| `tests/Feature/Core/Infrastructure/Database/UuidSchemaTest.php` isolado | Passou: 171 / 443 |
| `tests/Unit/Core/Support/Database/TestDatabaseGuardTest.php` isolado (sem `--fail-on-warning`, sem warnings reportados) | Passou: 15 / 50 |
| `tests/Feature/Core/Infrastructure/Isolation` (inclui Redis/concorrência/duas invocações) | Passou: 9 / 88 |
| `tests/Feature/Core/Infrastructure/Isolation/Probes/FirstProcessTest.php` isolado | Passou: 1 / 10 |
| `tests/Feature/Core/Infrastructure/Isolation/Probes/SecondProcessTest.php` isolado | Passou: 1 / 10 |
| `tests/Feature/Core/Infrastructure/Isolation/SimultaneousInvocationsTest.php` isolado | Passou: 1 / 35 |
| `tests/Unit` (inclui arquitetura) | Passou: 1.089 / 32.126 |
| `tests/Feature/Core/Infrastructure/Database/UuidSchemaTest.php tests/Feature/Core/Infrastructure/Isolation --order-by=random --random-order-seed=20261016` | Passou: 180 / 531 |
| mesmos dois paths, `--order-by=random --random-order-seed=20261017` | Passou: 180 / 531 |
| `tests/Feature/Core/Infrastructure/Database/UuidSchemaTest.php --parallel --processes=2` | Passou: 171 / 443 |
| `tests/Feature/Core/Infrastructure/Isolation --parallel --processes=2` | Passou: 9 / 88 |
| sem path, `--stop-on-defect` (tentativa global limitada à primeira falha) | Falhou: 1.095 executados, 1.094 passando, 1 erro; gate global **não aprovado** |

Falha global: `tests/Feature/Core/Infrastructure/Adapters/ObservabilityAdapterTest.php`, criação via `IdentityFixture`/`UserModel` ainda inteiro tenta persistir User sem ID; PostgreSQL recusa com 23502. A correção de UserModel/PAT/fixtures está no STEP 04 e dos demais consumidores nos steps respectivos. Não se enfraqueceu NOT NULL/CHECK nem se introduziu fallback SQL, union temporária ou geração falsa para passar. Gates completos padrão/seeds/paralelo exigidos pelo suporte transversal permanecem bloqueados e deverão ser repetidos após a conversão coerente; os resultados focados acima não os substituem.

Intercorrências preservadas: primeira prova do schema encontrou quatro erros de preparação duplicada de PAT e um esperado com nome incorreto do índice de cursor; fixture foi ajustada e esperado alinhado ao índice histórico `expenses_owner_cursor_index`. Uma execução seguinte passou as assertions mas registrou warning de import global sem alias; alias explícito corrigiu e execução final com `--fail-on-warning` passou. Primeira suíte de isolamento encontrou o probe inteiro antigo; foi convertido para inserts UUID explícitos, mantendo a prova e ampliando-a à associação. Uma tentativa de paralelo com dois paths foi recusada pelo ParaTest (aceita só um path), sem testes; paths executados individualmente em paralelo passaram. Nenhuma tentativa falha é contabilizada como aprovação.

Mapa de preservação: os cenários antigos de `FirstProcessTest`/`SecondProcessTest` e `SimultaneousInvocationsTest` conservam paths/barreiras/sentinelas/cleanup; `User id=1500` virou fixture v7 explícita e ganhou associação Core coincidente entre runs. Nenhum teste antigo foi removido/consolidado. O arquivo novo comprova schema e não substitui as provas de cifragem/rollback/concorrência de registro, que serão atualizadas no STEP 06.

Pint `--dirty --format agent` passou após a última edição PHP. Migrations rodaram somente pelo preflight incremental do launcher. **Não houve `migrate`/`migrate:fresh` no banco operacional**, pois suas migrations de bootstrap já aplicadas ainda produzem bigint e a nova FK UUID requer a recriação coordenada do STEP 12. Boost reconfirmou ao final `current_database() = trocado`, `users.id = bigint`, `resource_identities` ausente. Não houve request sobre schema operacional convertido nem alegação de desempenho/geração de Models. Workers/configuração/filas operacionais não foram alterados. `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive` passou (`valid = true`, sem issues) e `git diff --check` passou no fechamento desta fatia.

**Resultado de escopo:** 3.1–3.8 implementados e comprovados para schema/cleanup exclusivo, sincronizados com `STEPS.md`. Próxima etapa: STEP 04. Build completo, gate global do suporte compartilhado, reset operacional e archive continuam bloqueados/pendentes nas etapas próprias.

## STEP 04 — Identity, owner Core e Sanctum — 2026-10-14

### Autorização, implementação e fronteiras

Pedido: “Entao vamos para o Step 4”. Autoriza 4.1–4.10 e as provas dessa fatia. Checkout iniciou limpo, com STEP 03 integrado. Boost reconfirmou PHP 8.5/Laravel 13.34.0/Sanctum 4.3.3/Pest 5.2.1; Search Docs e Sanctum instalado consultados para HasUuids, custom PAT, lookup e constraints de rota. Skills arquitetura/quality gate e regras locais consultadas; fluxo OpenSpec conferido por status/instructions apply.

- `UserEntity` usa `?string` explícita: null somente pré-create, presente validado/canonicalizado pelo VO puro. Get/Update/Delete/Verify validam o alvo antes de owner/Repository/transação; contratos, SignUp retorno, SignInOutput, Repositories e adapters transportam strings v7 sem casts numéricos. Mapping preserva campos/status/password fora de Domain.
- `UserModel` e `PersonalAccessTokenModel` usam `HasUuids` nativo do Laravel 13. PAT estende o Model oficial, declara a tabela por atributo e é registrado por `Sanctum::usePersonalAccessTokenModel`; segredo/hash/abilities/expiry/owner morph permanecem oficiais. Nenhum vendor, dependência, gerador global ou protocolo novo.
- `PersonalAccessTokenModel::findToken` valida/canonicaliza somente a parte ID quando há `|`, retornando null sem SQL se inválida; depois delega ao pai, preservando hash_equals e o caminho oficial sem pipe (lookup pelo hash do segredo). UUID sozinho não autentica. Parâmetro é SensitiveParameter.
- Core `UserPort::id(): string` e `UserAdapter` obtêm/validam somente guard Sanctum e traduzem ausência/tipo/formato inválido para AuthenticationException. `ContextPort`/`ContextAdapter` transportam owner canônico; middleware existente continua passagem explícita, sem fallback Context/web. Stub tipado alterado em conjunto.
- `NotificationPort::lock(string, DateTimeImmutable): string` e `NotificationAdapter` foram convertidos juntos, com binding proprietário em Identity e sem ampliar imports. Provas diretas relêem PAT sob lock e conta após snapshot do guard, verificando owner/morph/expiry/idade/status/e-mail e não extensão. `SessionAdapter` já usa chave opaca; o custom PAT agora lhe fornece strings v7, mantendo política e transação existentes.
- Rotas User/verificação restringem versão/variante e permitem caixa equivalente; Controllers recebem string. `UpdateUserRequest` valida data.id v7/equivalência com rota, com pointer seguro. `TrimStrings` preserva data.id. Signed middleware valida a URL original antes do UseCase canonicalizar; URL uppercase assinada confirma, alterar só a caixa sem reassinar resulta em 403.
- Responses existentes já serializam IDs string; agora recebem User/PAT v7 canônicos. SignIn continua único ponto de entrega do segredo/no-store/no-cache. Architecture foi alinhada ao contrato owner e extensão Sanctum atuais; sem allowlists novas.

### Cenário → evidência atual

| Cenário / requisito da fatia | Evidência | Estado |
| --- | --- | --- |
| Entity presente v7, uppercase canônico, null pré-create, IDs presentes inválidos rejeitados | UserEntityTest; VO Core existente | Proven |
| Ownership fora de HTTP/canonicalização antes de Repository e transação | Get/Update/Delete/Verify Unit preservados + UuidIdentityUseCasesTest | Proven |
| User/PAT geração v7 nativa/string/não incremental e mapping sem credencial | EloquentUserRepositoryTest + PersonalAccessTokenModelTest + SignUp/SignIn HTTP | Proven |
| Bearer v7, owner/morph, segredo/hash oficial, caminho sem pipe e UUID sem segredo recusado | PersonalAccessTokenModelTest + SignInHttpTest | Proven |
| Prefixos numérico/v1/v4/v6/v8/nil/variante/whitespace/malformado: null antes de query e HTTP 401 sem lookup PAT | Dataset PAT, query log explicitamente vazio na chamada direta e sem query PAT no HTTP | Proven |
| User GET/PATCH uppercase, corpo v7 e UUID preservado | UuidUserHttpTest | Proven |
| Rota não v7 → 404 sem query User; body inválido/número/whitespace/UUID divergente → 422 pointer | Datasets UuidUserHttpTest e request data.id fora de trim | Proven |
| GET/PATCH/DELETE alheio e inexistente idênticos, nenhuma alteração de outra conta | UuidUserHttpTest + Unit ownership | Proven |
| Encerramento real da User: todos PATs + Expense/Notifications/Core removidos, outra conta íntegra | DELETE HTTP com Bearer real, rows dependentes UUID explícitas e assertions por owner | Proven para lifecycle; não substitui fluxos de criação Expense/Notifications |
| Extensão inicial/quinzenal/semanal, fronteira 15 dias/teto 90, UUID/hash/segredo imutáveis | SlidingSanctumSessionTest | Proven |
| Releitura de PAT sob extensão/revogação/expiração concorrentes | Três corridas existentes, filho com conexão nova/go/awaitLock/done e timeout/cleanup | Proven; não é corrida de cadastro Notifications |
| Logout seletivo e pruning UUID removem somente destinos da sessão, preservando outra sessão | SlidingSanctumSessionTest ampliado com rows Notifications explícitas | Proven para cascade; registro push é STEP 06 |
| Conta pending/blocked, verificação/política temporal e falhas de infraestrutura/credencial sanitizadas | SignInHttpTest, EmailVerificationTest, SignUp HTTP/RateLimit | Proven |
| URL original antes de canonicalização; verificação idempotente/rollback/eventos após commit | EmailVerificationTest + EloquentEmailVerificationRepositoryTest + Verify Unit | Proven |
| Transporte de verificação real/Redis/retry e callbacks de tentativas revertidas | Cenários existentes EmailVerificationTest executados na suíte e isoladamente | Proven; envio Firebase continua pendente |
| Owner Core exclusivamente Sanctum, ausência/formato inválido → auth; Context scoped/string/log seguro | UserAdapterTest + RequestCorrelationTest | Proven para owner; UUIDv7 de trace/request é STEP 11 |
| Pureza/fronteiras/binding proprietário | ContextBoundariesTest, 30/462 | Proven sem ampliar allowlist |
| Integração UUID de Expense/Notifications/projeções e gate global | STEPs 05–11 pendentes; gate para em Expense Unit com owner int | Blocked global; aprovação focada não libera build completo |

### Provas isoladas após Pint

Todos os comandos Pest usam `lerd composer test -- <path> --compact --fail-on-warning --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Paths abaixo relativos a tests/. Todos os resultados listados passaram sem warnings/skips/incomplete/risky.

| Path | Testes/assertions |
| --- | --- |
| Unit/Identity/Domain/Entities/UserEntityTest.php | 10/14 |
| Unit/Identity/Application/Repositories/UserRepositoryTest.php | 1/16 |
| Unit/Identity/Application/Ports/IdentityPortsTest.php (após coordenação de edição) | 1/10 |
| Unit/Identity/Application/UseCases/GetUserUseCaseTest.php | 3/9 |
| Unit/Identity/Application/UseCases/GetUserByEmailUseCaseTest.php | 2/6 |
| Unit/Identity/Application/UseCases/UpdateUserUseCaseTest.php | 6/23 |
| Unit/Identity/Application/UseCases/DeleteUserUseCaseTest.php | 3/17 |
| Unit/Identity/Application/UseCases/SignUpUseCaseTest.php (repetido após ajuste de argumento nomeado) | 3/31 |
| Unit/Identity/Application/UseCases/SignInUseCaseTest.php | 1/4 |
| Unit/Identity/Application/UseCases/SignOutUseCaseTest.php | 1/1 |
| Unit/Identity/Application/UseCases/VerifyEmailUseCaseTest.php | 4/31 |
| Unit/Identity/Application/UseCases/UuidIdentityUseCasesTest.php | 24/168 |
| Unit/Core/Infrastructure/Adapters/UserAdapterTest.php | 16/64 |
| Unit/Core/Support/TransactionPortFakeTest.php | 6/41 |
| Unit/Architecture/ContextBoundariesTest.php | 30/462 |
| Feature/Core/Presentation/Http/Middleware/RequestCorrelationTest.php | 1/64 |
| Feature/Identity/Infrastructure/Adapters/NotificationAdapterTest.php | 8/11 |
| Feature/Identity/Infrastructure/Repositories/Persistence/PersonalAccessTokenModelTest.php | 12/106 |
| Feature/Identity/Infrastructure/Repositories/Persistence/EloquentUserRepositoryTest.php | 3/12 |
| Feature/Identity/Infrastructure/Repositories/Persistence/EloquentEmailVerificationRepositoryTest.php | 3/17 |
| Feature/Identity/Infrastructure/Fixtures/IdentityFixtureTest.php | 8/56 |
| Feature/Identity/Presentation/Http/SignInHttpTest.php | 11/115 |
| Feature/Identity/Presentation/Http/UuidUserHttpTest.php | 15/75 |
| Feature/Identity/Presentation/Http/SignUpHttpTest.php (após argumento nomeado) | 17/115 |
| Feature/Identity/EmailVerificationTest.php (repetido após argumento nomeado) | 20/145 |
| Feature/Identity/SlidingSanctumSessionTest.php | 13/153 |

### Suítes, seeds, paralelo e bloqueio global

Mesmo launcher e flags comuns acima; Feature sempre sob preflight incremental/manifesto/ownership exclusivo. Unit puro não provisiona banco. Nenhuma migration operacional, seed, reset ou fila operacional foi executada.

| Seleção/argumentos antes dos flags comuns | Resultado |
| --- | --- |
| `tests/Unit/Identity tests/Unit/Core tests/Unit/Architecture/ContextBoundariesTest.php` | Passou: 383/1.584 |
| `tests/Feature/Identity` (invocação individual final) | Passou: 112/916 |
| `tests/Unit/Identity tests/Unit/Core tests/Unit/Architecture/ContextBoundariesTest.php tests/Feature/Identity tests/Feature/Core/Presentation/Http/Middleware/RequestCorrelationTest.php tests/Feature/Core/Infrastructure/Isolation --order-by=random --random-order-seed=20261018` | Passou: 505/2.652 |
| mesma seleção, `--order-by=random --random-order-seed=20261019` | Passou: 505/2.652 |
| `tests/Feature/Identity --parallel --processes=2` | Passou: 112/916 |
| sem path, `--stop-on-defect` | Falhou: 290 executados, 289 passando, 1 erro; gate global não aprovado |

Gate global parou em `tests/Unit/Expense/Application/UseCases/DeleteExpenseUseCaseTest.php:14`: mock de UserPort ainda retorna int, mas o contrato agora exige string. Expense/fixtures/mocks/cursor são STEP 05, Notifications STEP 06 e demais owners/projeções STEPs 08–11. Não se introduziu union/fallback/ID inteiro, nem se enfraqueceu o contrato ou converteu produto de outra fatia para fazer o gate passar. Gates globais exigidos por suporte compartilhado permanecem pendentes e serão repetidos no build coerente.

Intercorrências registradas, sem contabilizar tentativas falhas: primeira Feature Identity encontrou esperado antigo `getKey() + 1` em link inexistente, convertido para UUID determinístico. Durante as primeiras duas seeds/paralelo houve edição concorrente do usuário reordenando EmailVerificationPort e renomeando `EmailVerificationAdapter::requestForRegistration` para `$id`; isso gerou uma falha de ordem no teste de contrato por seed e falhas/erros de argumento nomeado no paralelo. A edição atual foi preservada; interface e chamada `id:` alinhadas, esperado do contrato atualizado e ambas seeds/paralelo passaram na execução final. Uma chamada agrupada de Feature Identity deu timeout MCP, sem aprovação; repetição individual final passou 112/916. Pint corrigiu imports/formatação em oito arquivos; provas afetadas foram reexecutadas.

### Mapa de preservação, operação e fechamento

- Todos os cenários anteriores de Entity/Repositories/Get/GetByEmail/Update/Delete/SignUp/SignIn/SignOut/Verify permanecem nos mesmos arquivos; IDs de exemplo 5/7/10/20/42 foram substituídos por UUIDs determinísticos por papel, callbacks/expectativas string e reflexões dos contratos foram alinhadas. Nenhum cenário foi removido ou consolidado.
- SlidingSanctumSession preserva os 13 cenários/política/barreiras de concorrência. Requests de sucesso usados apenas para provar atividade de sessão passaram de expenses.index para users.get, que usa a mesma extensão; prova integrada de Expense será retomada no STEP 05. Recusas de auth/conta/rate-limit que precedem o UseCase Expense continuam nos endpoints originais. Logout/pruning ganharam assertions de cascade UUID, não perderam garantias.
- EmailVerification preserva callbacks/retries/rollback/eventos/mail worker real/links/status/edição; IDs ausentes deixaram aritmética e nova prova distingue caixa original assinada de URL adulterada. IdentityFixture continua criação explícita via Model, agora com geração v7; IdentityHttpJourney retorna string e não ativa/verifica silenciosamente.
- RequestCorrelation preserva scope, igualdade header/context/log, novo request, evento CLI limpo e ausência de segredos; owner numérico forçado virou UUID real. Metadado sintético expense_id desse probe e geração trace/request permanecem para STEP 11; não é prova de identidade Expense v7.
- `route:list --path=users --json` confirmou apenas GET/PATCH/DELETE e mesmos middlewares; `--path=email-verification --json` confirmou signed na rota pública. `dumps_status` já estava enabled; GET real sem Bearer numa rota User v7 respondeu 401 JSON:API. `optimize_route(site=trocado)` retornou sem amostras/rotas, portanto não comprova desempenho/N+1 autenticado. Captura não foi alterada. Boost reconfirmou database operacional `trocado` com `users.id = bigint`; rollout/reset continua STEP 12 e não foi antecipado.
- Pint `--dirty --format agent` passou após a última edição PHP. `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive` passou (`valid = true`, sem issues) e `git diff --check` passou no fechamento desta seção. Nenhum commit/push/archive foi solicitado ou executado.

**Resultado de escopo:** 4.1–4.10 implementados/comprovados para Identity/Core no schema novo exclusivo e sincronizados com STEPS.md. Próximo STEP 05. Aprovação global do suporte compartilhado, integração de registro Notifications, demais consumers e ambiente operacional continuam pendentes; esta fatia não torna a change arquivável.

## STEP 05 — Expense, cursor, cache e classificação — 2026-10-15

### Autorização e escopo

Pedidos: “Vamos seguir com a implementacao da spec, no step ## STEP 05 — Expense, cursor, cache e classificação” e “Implementa”. Foram implementadas e verificadas 5.1–5.10. O checkout começou com alterações de STEP 04 em andamento; foram preservadas. Durante a execução essas alterações anteriores deixaram o diff, sem operação de stage/commit desta execução. Alterações desta fatia pertencem a Expense, seu suporte de testes, ARCHITECTURE/STEPS e este checklist.

Boost confirmou PHP 8.5/Laravel 13.34.0/PG/Pest 5.2.1; documentação de HasUuids/cursor e trait instalado conferidos. Skills de arquitetura/quality gate, skill SDD local por leitura direta, guidelines e regras de changes foram consultadas; fluxo por OpenSpec status/instructions apply/validação estrita. Site Lerd `trocado` descoberto antes das operações.

### Implementação

- `ExpenseEntity` usa ID nullable string somente antes de persistir, owner obrigatório string e validação/canonicalização pelo VO puro. Amount continua inteiro positivo, com datas/descrição/categoria preservadas. Get/Update/Delete/Classify validam UUID antes de chamar Repository; criação exige ID retornado persistido antes de dispatch/eventos.
- Contratos CRUD/classificação, `ApplyExpenseClassificationInput`, Eloquent/decorators/Models/controllers deixam de coerçar IDs para inteiros. `ExpenseModel` usa HasUuids nativo v7; o seeder usa firstOrCreate e já executa os hooks. O único bulk da fatia de planos passa IDs v7 explicitamente. Fixtures de Expense retornam UUID strings.
- Rotas restringem v7/variante aceitando caixa; UseCases canonicalizam antes do lookup owner-scoped. Response já retornava string e não precisou mudar. O documento PATCH continua aceitando somente os atributos já suportados, sem introduzir ID editável.
- Cursor v2 separa ID textual v7 de amount int positivo. V1/shape legado são recusados mesmo em default/ano/mês/dia; `legacyCursorAllowed` foi removido dos Data/Request/fixtures. Critérios normalizados, tipos/campos/direção e vínculo da query continuam validados antes de cache/persistência.
- SQL conserva UUID DESC final e aliases/ICU `und-u-ks-level1`/COALESCE somente para sort. Provas alfabéticas/combinadas inserem UUIDs determinísticos em ordem inversa à esperada de empate; next/prev não usam ordem incidental do gerador como oráculo.
- Páginas/chaves/tags passam para `expense:pages:v3` com owner UUID, TTL 60 e serialização de UUID string; invalidação após commit, rollback/savepoint e isolamento por conta permanecem. Cursor público é v2, namespace interno de cache é v3 porque a versão anterior já era v2.
- Dispatch/job/Classify transportam UUID; fencing não foi convertido em identidade. Tentativas/prazo/fallback/erro/retries/edição posterior conservam as regras anteriores. Worker Redis real verifica payload desserializado UUID/fencing, releases/backoff/falha final e cache scoped; outra prova consome um job real após edição manual sem chamar IA nem sobrescrevê-la.
- Para manter a fatia de Expense coerente com UserPort string, owner de `ExpenseSuggestionsRepository`/Eloquent e respectivos doubles/fixtures também passou para UUID. O algoritmo financeiro, normalização SQL e hash público atual não mudaram: associação estável Core e conclusão de 10.* continuam pendentes.

### Rastreabilidade e preservação de cenários

| Requisito/cenários | Evidência | Estado |
| --- | --- | --- |
| UID-02/05: IDs presentes/owner canônicos, ausência legítima, UUID inválido fora de HTTP, centavos intactos | ExpenseEntityTest; Get/Update/Delete/Classify UseCase tests | Proven |
| Persistência/CRUD UUID, 201/200/204, uppercase e identidade preservada | UuidExpenseHttpTest; ExpenseOwnershipTest; ExpenseCategoriesHttpTest | Proven |
| ID numérico/hash/nil/v4/v6/v8/variante → 404 antes do negócio; ausente/excluído/alheio iguais | UuidExpenseHttpTest, mocks nunca chamados, GET/PATCH/DELETE | Proven |
| V2: posição ID UUID separada de amount, v1/legacy recusados, shape/direção/query incompatíveis | ExpenseQueryCursorAdapterTest; ExpenseSortCursorHttpTest; GetAllExpenseUseCaseTest | Proven |
| Sort simples/composto, ICU/case/acento/Unicode/null, next/prev/ties/owner | ExpenseSortCursorHttpTest; GetAllExpenseHttpTest; ExpenseQueryHttpTest | Proven |
| Cache por dimensão/owner, TTL, namespace anterior excluído, invalidação após commit/rollback | Três arquivos de Cache + ComposableExpenseCacheTest (array/Redis) | Proven |
| Classificação/fencing/prazo/fallback, edição antes/durante resposta, exclusão e categorias | ExpenseClassificationTest; ClassifyExpenseUseCaseTest; ExpenseCategoriesHttpTest | Proven |
| Payload UUID/fencing e lifecycle de worker Redis, retry/falha, cache scoped e edição posterior | ExpenseClassificationRetryTest (4 cenários) | Proven |
| Uma query limitada, sem OFFSET, índices/ICU/schema UUID | ExpenseQueryPersistenceTest; UuidSchemaTest cruzado | Proven no volume medido |
| Fronteiras/observabilidade/cascade e integração Identity | ContextBoundariesTest; ExpenseMutationObservabilityTest; suítes Identity/Core | Proven na fatia |
| Reset/descartar payloads operacionais incompatíveis/optimize_route local | STEP 12 | Blocked até schema/consumidores coerentes |

Os arquivos existentes mantêm seus cenários na mesma localização. Conversões de IDs/mocks preservam argumentos, falhas e campos financeiros. Em ExpenseEntityTest, o antigo owner zero passa a casos inválidos de UUID em ambos os papéis; amount/data/categoria/descrição continuam com seus negativos. Em ExpenseSortCursorHttpTest, a antiga aceitação de cursor legado vira recusa nas mesmas nove consultas por exigência explícita da spec; versões/field types continuam negativos. Nos dois testes de Cache, páginas com cursor antes legado usam fixture v2 válida para conservar as provas de dimensões/invalidação; recusa do legado permanece provada no adapter/HTTP. Cenários de retry/fencing/cache/observabilidade continuam nos arquivos originais, com UUID em vez de casts. Nenhum cenário foi removido por contagem ou por incompatibilidade do schema.

### Arquivos executados isoladamente

Todos passaram após Pint pelo launcher `lerd composer test -- <arquivo> --compact --fail-on-warning --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Paths abaixo relativos a tests/; Unit puro não provisionou banco. Feature usou preflight/migrations incrementais/manifesto/runId e filas/Redis exclusivos, com cleanup existente.

| Arquivo | Testes / assertions |
| --- | --- |
| Unit/Expense/Application/UseCases/ClassifyExpenseUseCaseTest.php | 5 / 20 |
| Unit/Expense/Application/UseCases/DeleteExpenseUseCaseTest.php | 3 / 12 |
| Unit/Expense/Application/UseCases/GetAllExpenseUseCaseTest.php | 3 / 18 |
| Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php | 25 / 134 |
| Unit/Expense/Application/UseCases/UpdateExpenseUseCaseTest.php | 3 / 15 |
| Unit/Expense/Domain/Entities/ExpenseEntityTest.php | 21 / 28 |
| Unit/Expense/Infrastructure/Adapters/ExpenseQueryCursorAdapterTest.php | 27 / 35 |
| Unit/Expense/Application/UseCases/GetExpenseUseCaseTest.php | 3 / 12 |
| Feature/Expense/ExpenseClassificationTest.php | 50 / 324 |
| Feature/Expense/ExpenseOwnershipTest.php | 7 / 31 |
| Feature/Expense/Infrastructure/Queues/ExpenseClassificationRetryTest.php | 4 / 170 |
| Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseCategorizationRepositoryTest.php | 4 / 5 |
| Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseRepositoryTest.php | 18 / 48 |
| Feature/Expense/Infrastructure/Repositories/Cache/ComposableExpenseCacheTest.php | 11 / 51 |
| Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php | 26 / 91 |
| Feature/Expense/Infrastructure/Repositories/Persistence/ExpenseQueryPersistenceTest.php | 2 / 81 |
| Feature/Expense/Journeys/ExpenseMutationObservabilityTest.php | 2 / 80 |
| Feature/Expense/Presentation/Http/ExpenseQueryHttpTest.php | 53 / 217 |
| Feature/Expense/Presentation/Http/ExpenseSortCursorHttpTest.php | 49 / 744 |
| Feature/Expense/Presentation/Http/GetAllExpenseHttpTest.php | 35 / 215 |
| Feature/Expense/Presentation/Http/UuidExpenseHttpTest.php | 28 / 130 |

### Suítes, isolamento e planos

Mesmo launcher/flags estritos acima, sem exclusão de grupos nas evidências finais:

| Seleção/opções adicionais | Resultado |
| --- | --- |
| tests/Unit/Expense tests/Feature/Expense tests/Unit/Architecture/ContextBoundariesTest.php | Passou: 500 / 3.485, 24.098 ms |
| mesmos paths + tests/Feature/Core/Infrastructure/Isolation --order-by=random --random-order-seed=20261020 | Passou: 509 / 3.573, 24.111 ms |
| mesma seleção --order-by=random --random-order-seed=20261021 | Passou: 509 / 3.573, 24.172 ms |
| tests/Feature/Expense --parallel --processes=2 | Passou: 371 / 2.721, 9.437 ms |
| tests/Feature/Identity tests/Unit/Core tests/Feature/Core/Infrastructure/Database/UuidSchemaTest.php | Passou: 539 / 2.096, 12.038 ms |
| sem path, --stop-on-defect | Falhou: 927 executados, 926 passando, 1 erro; gate global não aprovado |

As seeds incluem os grupos Redis/worker/isolamento e a prova de duas invocações simultâneas existente. O gate global agora para em `tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php:75`, cujo mock ainda devolve owner inteiro. Essa conversão pertence ao STEP 08; o contrato não recebeu union/fallback e o contexto Insights não foi alterado. Gates globais/seeds/paralelo finais de 14.* continuam pendentes até o build coerente.

Planos PG exclusivos, 2.400 despesas de dois owners, ANALYZE e EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON), uma leitura limitada a 21 rows para página de 20: default Index Scan ~0,037 ms; filtros combinados Index Scan ~0,048 ms; descrição/amount Sort ~0,294 ms (execução da suíte final). Planejamento ~0,031/0,040/0,055 ms. O sort ICU continua válido com nullable/alias; não se alega escalabilidade para outras cardinalidades nem ausência global de N+1 a partir desses planos.

Pint `--dirty --format agent` passou, corrigindo somente imports/formatação nos arquivos da fatia; todos os arquivos afetados foram repetidos depois. OpenSpec estrito e `git diff --check` passaram.

### Intercorrências e limite operacional

- A primeira tentativa de Unit incluiu sugestões ainda com owner int; a primeira Feature parou na mesma incompatibilidade de Repository de sugestões. Foram alinhados somente o owner/fixtures/doubles de Expense; suíte final completa do contexto passou. Um `--exclude-group=suggestions` inicial não excluiu esses testes, que não têm esse grupo; nenhuma evidência final usa essa exclusão.
- Uma assertion nova de Location encontrou que o CreateExpenseController atual retorna 201 sem esse header, comportamento anterior à fatia UUID. A assertion exploratória foi retirada; não houve mudança do contrato/implementação de criação por esse achado fora do escopo. Correção desse header exige decisão própria, e a evidência acima não comprova Location.
- A primeira tentativa agrupada do gate global teve timeout MCP, sem resultado aproveitado. Após confirmar ausência de processos de teste no container, o mesmo comando via CLI Lerd retornou o bloqueio Insights acima. Timeout não conta como aprovação.
- MCP de schema confirma que o banco operacional continua com IDs bigint anteriores; migrate:status mostra `create_resource_identities_table` pendente. Aplicar essa FK UUID isoladamente sobre users bigint seria incompatível. Nenhuma migration/reset/seed/operação de workers operacionais foi executada; a transição coerente e a medição HTTP/optimize_route pertencem ao STEP 12. Testes HTTP/PG/worker desta entrega usam somente bancos/filas/Redis exclusivos do launcher, já migrados incrementalmente.

**Resultado de escopo:** 5.1–5.10 implementados e comprovados no schema novo exclusivo, sincronizados com STEPS.md. Próximo STEP 06. Registro estável Core/projeções, gates globais, transição operacional e archive continuam pendentes.

## Correção transversal — compatibilidade da suíte — 2026-10-15

### Autorização e diagnóstico completo

Após questionar a quantidade de testes quebrados, o usuário solicitou executar/verificar a suíte inteira e autorizou expressamente a correção: “Corrige por favor”. O escopo é recuperar a compatibilidade dos consumidores obrigatórios e das provas com schema/UserPort/PAT UUID, conforme seção 1.6; não implementar o registro estável Core ou toda a semântica pendente de Notifications/projeções. A justificativa anterior de simplesmente adiar as quebras de tipo para os STEPs proprietários não satisfazia essa exigência. Evidências históricas de bloqueio acima foram preservadas, mas são superadas pelo resultado desta seção.

Diagnóstico pelo launcher sem stop-on-defect: **2.167 testes, 1.899 passando, 66 falhas e 202 erros, 37.443 assertions, 55.169 ms**. Distribuição dos 268 problemas: Insights 122, Metrics 110, Notifications 32 e Core 4; Expense sem falha nessa execução. As causas incluem mocks UserPort devolvendo int, Repositories recebendo int com owner string, inserts sem UUID, casts de UUID para int e chamadas ao Model base de PAT em vez do Model próprio configurado.

### Correções e limites

- Insights: owner string em Repository/SQL/UseCase/composição/SelectInsightMessageVariantInput; rotação valida/canonicaliza UUID antes do hash interno. Fórmula de rotação, dias civis, catálogo, seleção, fatos/períodos, precisão monetária e hash público atual foram preservados.
- Metrics: contrato/implementação recebem owner string, mantendo a consulta única/snapshot, agrupamento, períodos/default e matemática exata. Sem nova persistência/cache ou alteração do hash público.
- Notifications: contrato/Repository/Entity usam owner/sessão string; Entity canonicaliza os dois papéis e sincronização não incrementa geração por caixa diferente. Foram removidos casts numéricos do Model. Registro é emitido por Str::uuid7() para satisfazer o schema v7 já adotado. Model próprio de PAT é usado explicitamente nos testes consumidores, preservando segredo real, revogação e disputas. Nenhuma alteração de transporte Firebase.
- Fixtures de instalação válidas passam de v4 a v7 para construir o schema atual. Isso não conclui a validação HTTP/Domain contra todas as outras versões de instalação/registro: 6.1/6.3/6.4 e a revisão completa da fatia continuam pendentes.
- Query Builder/insertGetId recebem ID UUIDv7 explícito porque não executam hooks de Model. Helpers retornam string; UUID não é convertido em int. Identificadores sem papel na expectativa usam geração v7; empates e ordenação sensíveis usam UuidFixture explícita, independente da ordem de inserts.
- Core: testes de transação/preflight voltam a demonstrar uma escrita válida antes da sentinela/retry/migration incremental. Nenhuma alteração de TransactionAdapter, guard, ownership ou cleanup. Tentativas de retry usam UUIDs distintos explícitos e verificam que a escrita abortada não persistiu.
- Nenhuma migration, dependência, configuração de ambiente ou worker operacional foi alterado. O banco operacional anterior permanece para STEP 12; todas as verificações usaram bancos/filas/Redis exclusivos do launcher.

### Mapa cenário antigo → prova corrigida

| Arquivos/cenários preservados | Conversão e evidência |
| --- | --- |
| Core TransactionAdapterTest e TestDatabasePreflightTest | Mesmos cenários de commit/rollback/retry/callbacks e preservação após migrations incrementais. Inserts UUID explícitos, sentinela exata e escrita anterior comprovadas; nenhum guard ou assertion transacional relaxado |
| Insights GetInsightsUseCaseTest; Metrics GetExpenseMetricsUseCaseTest | Mesmos mocks/expectativas de quantidade/argumentos/erros; owner fixture v7 no lugar de int, identidade pública ainda hash. Orquestração e falhas não viram retorno fabricado |
| Insights ComposeInsightMessageUseCaseTest; ExpandedCategoryMessageTest; SelectInsightMessageVariantUseCaseTest | Mesmas dimensões/catálogos/variantes, limites 24/80 e precisão. Índices numéricos de datasets identificam UuidFixture, não IDs de produto. Casos antigos de owner 0/-1 passam às strings inválidas equivalentes; há mais um negativo v4, sem reparar entrada. Caixa equivalente ganha prova no mesmo cenário de ciclo |
| Insights EloquentExpenseAnalysisRepositoryTest | Mesmos agregados/snapshot/owner/limites civis e falhas. Empate do máximo usa UUIDs explícitos e inserção inversa, preservando vencedor esperado. Casos de contas geradas após exclusões verificam identidade distinta, sem pressupor sequência/ordem global de geração UUID |
| Insights InsightsApiTest e Monthly{CompositionFailure,Contract,Identity,InsightsFilters,Onboarding,Rotation}HttpTest | Mesmas requisições/contratos/filtros/precisão/rotação/privacidade e falhas editoriais; inserts válidos e owner string. PAT próprio conserva a prova de não extensão em erro |
| Metrics EloquentExpenseMetricsRepositoryTest e ExpenseMetricsHttpTest | Mesmos totais/grupos/rounding/zero/default/ownership, erros e leitura única, sem alterar esperado financeiro |
| Notifications CreateNotificationUseCaseTest e NotificationRegistrationEntityTest | Mesmas checagens de escopo transacional, lock antes de Repository, retry limitado, metadata após commit e geração. Owner/sessão v7 e caixa equivalente sem geração extra |
| Notifications EloquentNotificationRepositoryTest, NotificationRegistrationConcurrencyTest e NotificationRegistrationHttpTest | Cifragem/fingerprint, unicidade, rollback pós-escrita, cascades, rotação, sessão real e concorrência sincronizada preservados; testes usam Model PAT próprio e UUID desconhecido explícito para ownership inválido |
| NotificationRegistrationFixture e NotificationFingerprintMigrationTest | Constantes válidas v7 em ordem explícita; prova existente de recalcular fingerprint e reverter escrita anterior ao ciphertext inválido passou no gate completo. Nenhuma assertion de rollback/ciphertext foi removida |

Os cenários permanecem nos mesmos arquivos. Não foram removidos testes, introduzidos skips ou enfraquecidas assertions para obter verde. A contagem total aumentou em um pelo negativo v4 de rotação; a equivalência decorre do mapa e das provas, não da contagem.

### Arquivos isolados após Pint

Comando para cada arquivo: `lerd composer test -- <arquivo> --compact --fail-on-warning --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Todos passaram. Paths abaixo relativos a tests/.

| Arquivo | Testes / assertions |
| --- | --- |
| Feature/Core/Infrastructure/Adapters/TransactionAdapterTest.php | 4 / 29 |
| Feature/Core/Infrastructure/Database/TestDatabasePreflightTest.php | 3 / 20 |
| Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php | 71 / 2.360 |
| Unit/Insights/Application/UseCases/ExpandedCategoryMessageTest.php | 306 / 27.132 |
| Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php | 18 / 155 |
| Unit/Insights/Application/UseCases/SelectInsightMessageVariantUseCaseTest.php | 16 / 157 |
| Unit/Metrics/Application/UseCases/GetExpenseMetricsUseCaseTest.php | 41 / 97 |
| Unit/Notifications/Application/UseCases/CreateNotificationUseCaseTest.php | 3 / 33 |
| Unit/Notifications/Domain/Entities/NotificationRegistrationEntityTest.php | 4 / 17 |
| Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php | 22 / 368 |
| Feature/Insights/InsightsApiTest.php | 54 / 361 |
| Feature/Insights/Presentation/Http/MonthlyCompositionFailureHttpTest.php | 2 / 30 |
| Feature/Insights/Presentation/Http/MonthlyContractHttpTest.php | 2 / 77 |
| Feature/Insights/Presentation/Http/MonthlyIdentityHttpTest.php | 5 / 162 |
| Feature/Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php | 41 / 255 |
| Feature/Insights/Presentation/Http/MonthlyOnboardingHttpTest.php | 22 / 208 |
| Feature/Insights/Presentation/Http/MonthlyRotationHttpTest.php | 5 / 205 |
| Feature/Metrics/Infrastructure/Repositories/Persistence/EloquentExpenseMetricsRepositoryTest.php | 15 / 52 |
| Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php | 91 / 786 |
| Feature/Notifications/Infrastructure/Repositories/Persistence/EloquentNotificationRepositoryTest.php | 16 / 64 |
| Feature/Notifications/Infrastructure/Repositories/Persistence/NotificationRegistrationConcurrencyTest.php | 6 / 27 |
| Feature/Notifications/Presentation/Http/NotificationRegistrationHttpTest.php | 31 / 215 |

### Gate global restaurado

Todos os comandos abaixo usam `lerd composer test --`, com `--compact --fail-on-warning --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Nenhuma exclusão, stop-on-defect ou skip. PHPUnit/Pest executaram pelo launcher com preflight/manifesto/ownership, migrations incrementais e cleanup exclusivos. Grupos Redis/worker/concorrência e duas invocações simultâneas estão incluídos.

| Opções adicionais | Resultado final |
| --- | --- |
| nenhuma: suíte completa padrão | **2.168 / 39.859**, 58.535 ms |
| --order-by=random --random-order-seed=20261022 | **2.168 / 39.859**, 70.359 ms |
| --order-by=random --random-order-seed=20261023 | **2.168 / 39.859**, 70.058 ms |
| --parallel --processes=2 | **2.168 / 39.859**, 42.498 ms |

Pint `--dirty --format agent` executado antes dessas provas, com repetição de todos os arquivos afetados; `git diff --check` passou. As primeiras suítes focadas também passaram: Notifications/Metrics + Core transação/preflight 225/1.361; Insights + arquitetura 817/32.706. A evidência final acima inclui os refinamentos posteriores de canonicalização.

**Resultado:** os 268 problemas do diagnóstico completo foram corrigidos e a suíte do build atual está verde. Foram sincronizados os pré-requisitos de compatibilidade 6.2/8.1/9.1/10.1, sem declarar completos os STEPs 06/08/09/10. Associação estável Core/projeções, regras v7 restantes de Notifications, rollout/medição operacional, cliente e archive continuam pendentes. Gates 14.* deverão ser repetidos depois dessas implementações; verde atual não comprova requisitos ainda ausentes.

## STEP 06 — Notifications e instalação — 2026-10-15

### Escopo autorizado e implementação

O pedido “Vamos continuar a implementacao ## STEP 06 — Notifications e instalação” autoriza a fatia 6.1–6.8 e suas provas. Owner/sessão já convertidos na correção transversal foram preservados e reverificados com Identity. Não houve alteração de dependência, migration, credencial, configuração de ambiente ou worker operacional.

- `NotificationModel` usa `HasUuids` nativo (reconferido no Laravel 13.34.0: `newUniqueId()` chama `Str::uuid7()`); Repository conserva sua geração legítima v7 antes de construir a Entity. Mapping valida/canonicaliza a PK obrigatória pelo VO puro de Core. Registro/owner/sessão/instalação são strings v7; destino FCM e generation conservam seus tipos/bytes.
- `NotificationValueObject` exige instalação v7 pelo conceito de Core e preserva a exceção específica do campo. Request reutiliza a mesma validação e aponta `/data/attributes/installation_id`. A exceção específica ao `TrimStrings` em `bootstrap/app.php` impede que whitespace vire instalação válida antes da validação.
- DELETE tem constraint v7/variante/case-insensitive na rota e valida/canonicaliza no UseCase mesmo fora de HTTP, antes de locks/Repository. O Repository também valida IDs antes de SQL. O renderer no composition root conserva o mesmo 404 de registro para falha na rota e registro ausente/alheio. Response continua com somente ID/instalação/plataforma/provider/última sincronização, sem destino ou Location fictício.
- Fixtures distinguem `Installation`/`OtherInstallation` de `Registration`/`OtherRegistration`. Ordenação técnica de rollback da migration usa as PKs explícitas `…0201`/`…0202`, sem depender do clock/ordem de geração ou reutilizar instalação como registro.
- POST/DELETE mantêm PAT real, conta apta, cota compartilhada e ausência de extensão/novo token. As provas de não extensão agora usam PAT dentro da janela de extensão (10 dias restantes). Logs do UseCase continuam limitados à allowlist existente; as provas de argumentos/metadados após commit verificam owner/registro v7, distintos da instalação. Inspeção integral de logs JSON/transporte é trabalho futuro da change Firebase.

### Matriz de cenários e mapa de preservação

Todos os cenários antigos permanecem nos mesmos arquivos, sem remoção, consolidação, skips ou exclusões. Paths abaixo relativos a `tests/`.

| Arquivo/cenários | Alteração e evidência atual |
| --- | --- |
| Unit/Notifications/Domain/ValueObjects/NotificationValueObjectTest.php | Preserva bytes FCM, limites 1–4096, plataforma/tipo e canonicalização. Acrescenta rejeição v1/v4/v6/v8/nil/variante/número textual/hash/whitespace/compacto fora de HTTP |
| Unit/Notifications/Domain/Entities/NotificationRegistrationEntityTest.php | Preserva repetição sem incremento e mudanças de destino/plataforma/sessão com incremento. Registro fixture próprio é canonicalizado; ID permanece nas transições; negativos de PK v4/variante/whitespace/número são rejeitados |
| Unit/Notifications/Application/UseCases/CreateNotificationUseCaseTest.php | Mesmos argumentos, lock antes de acesso, transação/retry limitado e eventos após commit; registro fixture passa a papel próprio, distinto da instalação |
| Unit/Notifications/Application/UseCases/DeleteNotificationUseCaseTest.php (novo) | Prova canonicalização antes de delete owner-scoped, lock/Repository dentro da unidade, callback somente após commit e recusa inválida sem lock/query/callback; não alega rollback real a partir de fake |
| Feature/Notifications/Presentation/Http/NotificationRegistrationHttpTest.php | Preserva todos os contratos anteriores e amplia v7 canônico/distinto, caixa equivalente sem nova row/geração, outras versões e whitespace com pointer/sem eco, DELETE maiúsculo, outra instalação preservada, 404 uniforme, zero lookup Notifications para rota inválida, cota em POST/DELETE e não extensão dentro da janela |
| Feature/Notifications/Infrastructure/Repositories/Persistence/EloquentNotificationRepositoryTest.php | Preserva cifragem exata/fingerprint/Hidden/mapping, rollback com sentinela após escrita observada e callbacks descartados, cascades e revalidação do guard. Acrescenta formato v7/papéis separados/mapping completo/PK string não incremental/checks v4 e metadados v7 após commit |
| Feature/Notifications/Infrastructure/Database/NotificationFingerprintMigrationTest.php | Mesmos dois cenários: só fingerprint muda; ciphertext/metadados permanecem; decifragem posterior falha e reverte escrita anterior. PKs de registro ordenadas explicitamente e primeiro UPDATE/ID observados no query log; sentinela e erro sanitizado preservados |
| Feature/Notifications/Infrastructure/Repositories/Persistence/NotificationRegistrationConcurrencyTest.php | Mesmas conexões novas/barreiras/awaitLock/timeouts/cleanup: mesma sessão, nova sessão do owner, outra conta, rotações, logout primeiro/cadastro primeiro. Acrescenta igualdade do ID retornado pelo filho e vencedor confirmado, v7 distinto da instalação e fingerprint coerente com rotação final |
| Support/Notifications/Fixtures/NotificationRegistrationFixture.php | Instalações v7 existentes preservadas; duas constantes novas de registro independentes. Nenhuma reparação de entrada inválida ou gerador de produção usado como esperado |

**Proven no backend:** UID-02/03/05/06/07 relativos ao cadastro/remoção de Notifications e UID-04 relativos às suas constraints/cascades. Registro v7 permanece igual em repetição, rotação, nova sessão e corrida idempotente; instalação v4 é rejeitada antes de persistir; outras contas não ganham acesso conhecendo um UUID. Sem envio Firebase implementado/ativado.

### Verificação isolada e integração

Cada arquivo abaixo foi executado isoladamente com `lerd composer test -- <arquivo> --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`, após Pint/finalização das suas edições. O VO foi repetido isoladamente após a última remoção de linha em branco. Sem skips/incomplete/risky inesperados.

| Arquivo | Testes / assertions |
| --- | --- |
| Unit/Notifications/Domain/ValueObjects/NotificationValueObjectTest.php | 20 / 22 |
| Unit/Notifications/Domain/Entities/NotificationRegistrationEntityTest.php | 8 / 22 |
| Unit/Notifications/Application/UseCases/CreateNotificationUseCaseTest.php | 3 / 33 |
| Unit/Notifications/Application/UseCases/DeleteNotificationUseCaseTest.php | 5 / 38 |
| Feature/Notifications/Infrastructure/Database/NotificationFingerprintMigrationTest.php | 2 / 13 |
| Feature/Notifications/Infrastructure/Repositories/Persistence/EloquentNotificationRepositoryTest.php | 18 / 80 |
| Feature/Notifications/Infrastructure/Repositories/Persistence/NotificationRegistrationConcurrencyTest.php | 6 / 35 |
| Feature/Notifications/Presentation/Http/NotificationRegistrationHttpTest.php | 47 / 289 |

Integração: `lerd composer test -- tests/Unit/Notifications tests/Feature/Notifications tests/Unit/Identity tests/Feature/Identity tests/Unit/Architecture/ContextBoundariesTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` → **348 testes / 2.293 assertions**, passando (12.087 ms). Inclui Adapter de sessão, PAT real, SignOut/pruning/encerramento/cascades e boundaries, sem ampliar permissões de contexto.

### Gates transversais finais

Todos os comandos usam `lerd composer test --` e `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`, sem exclusões. Incluem PostgreSQL/Redis/worker/concorrência e as duas invocações simultâneas existentes; manifesto/ownership e cleanup exclusivos, migrations incrementais pelo launcher, sem migrate:fresh.

| Opções adicionais | Resultado |
| --- | --- |
| nenhuma: gate completo padrão | **2.206 testes / 40.012 assertions**, 49.639 ms |
| --order-by=random --random-order-seed=20261024 | **2.206 / 40.012**, 50.087 ms |
| --order-by=random --random-order-seed=20261025 | **2.206 / 40.012**, 49.109 ms |
| --parallel --processes=2 | **2.206 / 40.012**, 30.985 ms |

Pint `--dirty --format agent` via MCP vendor_run passou após a última edição PHP. OpenSpec estrito passou e `git diff --check` passou. Nenhuma contagem substitui a rastreabilidade de cenários acima. Tasks 14.* continuam pendentes para o fechamento do build futuro completo.

Intercorrências corrigidas: a primeira Unit nova usou incorretamente o nome do campo como texto esperado da exceção (15 falhas de assertion; o campo é propriedade tipada, a mensagem é genérica); corrigido o teste sem alterar esse contrato. A primeira HTTP ampliada encontrou três falhas reais da fatia: whitespace de instalação era aparado pelo middleware (dois datasets) e 404 de rota diferia do 404 owner-scoped. Foram corrigidos no composition root e o arquivo passou integralmente. Essas tentativas não contam como aprovação.

### Ambiente, coordenação e limites

Boost confirmou PHP 8.5/Laravel 13.34.0/Sanctum 4.3.3/PostgreSQL; docs e código instalado de HasUuids foram consultados. `route:list --path=api/push --json` confirmou somente POST/DELETE, com Sanctum/atividade/verificação/throttle e sem `session.extend`. Captura Lerd já estava ligada, sem alteração de estado; POST real sem credencial respondeu **401 JSON:API**. `optimize_route` retornou **0 amostras**, sem evidência de desempenho autenticado.

Boost/schema e `migrate:status` confirmaram que o banco operacional ainda tem owner/PAT bigint e a migration Core está pendente, dependente do bootstrap UUID. Não foi aplicada sobre esse schema incompatível nem usado reset antecipado: a transição consentida continua no STEP 12. As provas deste passo construíram schema UUID por migrations incrementais em bancos novos/exclusivos do launcher. Desempenho autenticado, rollout, Bruno/gerador Flutter e recepção real Firebase continuam pendentes; não se afirma homologação ou archive da change de envio.

**Resultado de escopo:** 6.1–6.8 implementados/comprovados, checklist sincronizado com STEPS.md e evidência da change Firebase atualizada. Próximo STEP 07: registro estável Core. Sem implementação antecipada de projeções/envio/cliente.

## STEP 07 — Registro estável Core — 2026-10-15

### Autorização, implementação e decisões locais

O usuário solicitou continuar a implementação do STEP 07 de `STEPS.md`, incluindo suas provas Unit/PostgreSQL e concorrência. O working tree inicial estava limpo. PHP 8.5, Laravel 13.34.0 e PostgreSQL foram reconferidos por MCP; Lerd descobriu `trocado`. Boost Search Docs e código instalado reconfirmaram transações, `Str::uuid7()` e `PostgresGrammar::compileInsertOrIgnore()` (`ON CONFLICT DO NOTHING`). As skills architecture/quality-gate foram carregadas e `trocado-sdd` foi consultada por leitura local; OpenSpec 1.6.0 e doctor saudável reconfirmados.

- Quatro Data imutáveis constructor-only e `ResourceRepository::resolve(string, array): array` conforme D2; nenhum Output financeiro, Model ou Builder na Application.
- UseCase valida owner mesmo no lote vazio, lista e itens, namespace de até 64 bytes pelo regex técnico, versão 1–32767 (smallint), nomes não vazios/string e valores somente string/int/bool/null. Componentes vazios são um mapa válido; a ordem fornecida é significativa. Falha em qualquer item impede a abertura da transação.
- Deduplicação exata por `serialize([namespace, version, components])`, que preserva tipos, nomes, ordem, limites de strings e bytes inclusive NUL/não UTF-8. Repository usa SHA-256 de `serialize(components)` e escopa namespace/versão/owner separadamente. Não há concatenação ambígua ou normalização de assunto/descrição de consumidor em Core.
- O UseCase define toda a unidade por `TransactionPort`, valida/reconcilia o retorno dentro dela e recompõe a ordem/repetições originais. Repository faz leitura em lote pela conexão de escrita, gera somente os ausentes, ordena inserts por tupla técnica e relê em statement separado. Não usa UPDATE, CTE de snapshot único, cache ou fallback de UUID.
- Ausência após releitura/colisão de PK, `23505`, `40001` e `40P01` provocam falha retryable própria, sem previous SQL. A exceção de Repository chega ao Port sem a mensagem nativa que dispararia seu retry interno; o UseCase repete até três unidades completas depois do rollback. Outros erros e esgotamento produzem `ResourcePersistenceException` fixa, sem SQL/bindings/descrição/previous. Entradas sensíveis do UseCase/Repository estão anotadas com `SensitiveParameter`.
- Binding apenas de Repository no CoreServiceProvider, autowiring de UseCase, Model string/não incremental com HasUuids e sem updated_at. A permissão de Application de Expense/Insights/Metrics adiciona somente o UseCase e os quatro Data, preservando Repository interno, Domain puro e ausência de Core → consumidores.

### Mapa requisito/cenário → prova

Todos os caminhos abaixo são relativos a `tests/`; os três arquivos de resolução são novos, sem substituir/remover cenários antigos. `ContextBoundariesTest.php` preserva os testes existentes e acrescenta somente as cinco permissões nominadas de D2. A contagem arquitetural cresceu pelas assertions de contratos Data novos, não por equivalência presumida de cenários.

| Requisito/cenário | Evidência | Estado no escopo Core |
| --- | --- | --- |
| RID-01 Data puros, Repository, binding, Model e row mínima | Unit/Application, arquivo PG de Repository e ContextBoundariesTest | Proven |
| RID-02 namespace/versão/owner inválidos; item posterior inválido | `Unit/Core/Application/UseCases/ResourceUseCaseTest.php` | Proven antes de Port/Repository |
| RID-02 diferenças de nomes/tipos/null/vazio/ordem/bytes/concatenações/namespace/versão/owner | Mesmo Unit + `Feature/Core/Infrastructure/Repositories/Persistence/EloquentResourceRepositoryTest.php` | Proven em contratos e rows distintas PG |
| RID-03 primeiro insert simultâneo / UUID perdedor | `Feature/Core/Infrastructure/Repositories/Persistence/ResourceConcurrencyTest.php` | Proven: fork antes da transação, conexões novas, barreira go, espera Lock observada em pg_stat_activity, filho gera candidato distinto, faz três statements e recebe UUID persistido pelo pai |
| RID-03 lote com escrita parcial e colisão de PK | Repository PG, sucesso na segunda tentativa e esgotamento na terceira | Proven: outra row inserida na tentativa é desfeita; hit preexistente preservado, nenhum retorno parcial |
| RID-03/06 falha após INSERT / recuperação / esgotamento | Repository PG, listener observa row escrita e provoca RAISE PostgreSQL com 40001/40P01/23514 | Proven rollback real e classificação dos SQLSTATEs; não é alegada uma formação real de ciclo de deadlock |
| RID-04 zero/hit/miss/misto/dedup/ordem | Unit + query logs PG, lotes de 1/5/6 e vazio | Proven: 0 no vazio; 1 SELECT no hit; 3 nos miss/mistos; nenhuma geração no hit/vazio, nenhum UPDATE/timestamp alterado |
| RID-04 plano do lookup de seis chaves | EXPLAIN FORMAT JSON no arquivo PG, enable_seqscan off local à transação | Proven elegibilidade de `resource_identities_logical_key_unique` com owner; não prova a escolha natural do planner ou latência em escala |
| RID-05 retenção sem token/dia/conexão/instância | Repository PG, PAT excluído e relógio avançado, lote vazio entre duas resoluções e reconexão | Proven registro durável; jornadas HTTP dos consumidores continuam pendentes |
| RID-05 processo novo e owner concorrente / outro owner | Concurrency PG, primeiro insert e exclusão nos dois sentidos | Proven vencedor confirmado, cascade e nenhum órfão/recriação; row de outra conta preservada |
| RID-06 argumentos/escopo/retries/retorno inválido/falha permanente/commit | Unit com PHPUnit e TransactionPortFake | Proven orquestração, sem usar fake como prova de rollback PG |
| RID-06 exceção sanitizada | Unit e falhas PostgreSQL, mensagem fixa e previous null | Proven contrato de exceção; integração HTTP/observabilidade das projeções segue os STEPs próprios |
| RID-07 isolamento/cleanup | Gate completo inclui provas existentes do launcher e invocações simultâneas | Proven no lifecycle exclusivo, sem nova rota ou autoridade concedida pelo ID |

As assertions executadas no filho da prova concorrente são verificadas pelo protocolo `done/error` e não são agregadas à contagem de assertions do runner pai.

### Comandos e resultados finais

Todos usam `lerd composer test --` com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`; Feature provisionado pelo launcher com migrations incrementais, manifesto/runId e ownership exatos. Nenhuma exclusão ou skip. Arquivos isolados passaram após suas últimas edições/Pint:

| Seleção | Testes / assertions | Duração reportada |
| --- | --- | --- |
| `tests/Unit/Core/Application/UseCases/ResourceUseCaseTest.php` | **33 / 125** | 39 ms |
| `tests/Feature/Core/Infrastructure/Repositories/Persistence/EloquentResourceRepositoryTest.php` | **15 / 112** | 665 ms |
| `tests/Feature/Core/Infrastructure/Repositories/Persistence/ResourceConcurrencyTest.php` | **3 / 9** | 413 ms |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | **30 / 504** | 4.635 ms |
| `tests/Unit/Core tests/Feature/Core tests/Unit/Architecture/ContextBoundariesTest.php` | **535 / 2.236** | 18.659 ms |
| Completo padrão | **2.257 / 40.302** | 50.887 ms |
| Completo `--order-by=random --random-order-seed=20261026` | **2.257 / 40.302** | 50.361 ms |
| Completo `--order-by=random --random-order-seed=20261027` | **2.257 / 40.302** | 49.891 ms |
| Completo `--parallel --processes=2` | **2.257 / 40.302** | 31.510 ms |

Gates completos incluem Redis/worker/concorrência e as duas invocações simultâneas existentes. `lerd` vendor_run Pint `--dirty --format agent` passou; `git diff --check` passou; `openspec status`/`instructions apply` consultados e `openspec validate standardize-uuid-v7-identifiers --type change --strict --json --no-interactive` aprovado.

### Intercorrências corrigidas e limites

- A primeira prova concorrente usou dois UUIDs esperados na ordem de entrada, apesar de a geração ocorrer em ordem técnica; a expectativa foi corrigida para uma identidade disputada, suficiente para provar UUID perdedor/vencedor. Lotes de cinco/seis e ordem inversa permanecem provados separadamente.
- A primeira arquitetura recusou o helper global `now` em Core Infrastructure. A implementação passou a importar `Illuminate\Support\Carbon`, sem ampliar a allowlist para esse helper.
- Duas chamadas MCP concorrentes de Core/Unit expiraram enquanto o gate completo executava. Timeout não foi tratado como aprovação: ambas as seleções foram executadas novamente, individualmente, com os resultados da tabela. Gates completos seguintes foram executados individualmente.
- MCP de schema confirmou que o banco operacional ainda tem users/expenses/PAT bigint e não tem resource_identities. Migrations de bootstrap UUID já existentes são aplicadas pelo launcher em bancos novos exclusivos; não houve alteração de migration, reset ou exercício de rota operacional. Aplicação operacional/planos de tráfego/N+1 continuam no STEP 12.
- Esta prova libera a capacidade Core para implementação de Insights/Metrics/sugestões nos STEPs 08–10. Não declara as jornadas HTTP dessas projeções, a aplicação local ou a change inteira concluídas/arquiváveis.

**Resultado de escopo:** 7.1–7.11 implementados/comprovados; STEPS.md e matriz sincronizados. Próximo: STEP 08 — Insights com UUIDv7 estável.

### Renomeação posterior para Resource em Core — 2026-10-15

Por pedido explícito do usuário, confirmado como manutenção em Core, a capacidade passa a usar `ResourceUseCase`, `ResourceRepository`, `EloquentResourceRepository` e `ResourceModel`. Os Data de lote são `ResourceInput`/`ResourceOutput`; os individuais, `ResourceKeyInput`/`ResourceKeyOutput`. Exceções: `InvalidResourceException`, `ResourceRaceException` e `ResourcePersistenceException`. Arquivos/imports/binding/allowlist, design, arquitetura e checklist foram alinhados. Schema `resource_identities`, campos, fingerprint e comportamento permanecem os mesmos.

Os três arquivos de teste foram renomeados preservando todos os cenários/assertions; os paths da evidência acima foram atualizados para seus destinos atuais, conservando as contagens/durações históricas. Chamadas de `ResourceKeyInput` passaram a argumentos nomeados para preservar a reordenação de construtor encontrada durante a edição. A primeira execução Unit apresentou DatasetMissing causado pelo TypeError durante a construção do dataset, e a primeira Feature expôs a incompatibilidade posicional; ambas foram corrigidas antes da aprovação.

Verificações posteriores à renomeação/Pint, pelo launcher e com os mesmos flags estritos da tabela anterior:

- `tests/Unit/Core/Application/UseCases/ResourceUseCaseTest.php`: **33/125**, 40 ms.
- `tests/Feature/Core/Infrastructure/Repositories/Persistence/EloquentResourceRepositoryTest.php`: **15/112**, 786 ms.
- `tests/Feature/Core/Infrastructure/Repositories/Persistence/ResourceConcurrencyTest.php`: **3/9**, 440 ms.
- `tests/Unit/Architecture/ContextBoundariesTest.php`: **30/504**, 5.692 ms.
- `tests/Unit/Core tests/Feature/Core tests/Unit/Architecture/ContextBoundariesTest.php`: **535/2.236**, 21.587 ms.

Pint `--dirty --format agent`, OpenSpec estrito e `git diff --check` aprovados; busca pelos identificadores PHP antigos sem ocorrências. Gates completos anteriores permanecem evidência histórica da implementação, sem atribuir nova execução global à renomeação.

## STEP 08 — Insights com UUIDv7 estável — 2026-10-15

### Autorização, implementação e fronteiras

Pedido: “Vamos continuar a implementacao ## STEP 08”. Autoriza a integração Insights e suas provas 8.2–8.7; 8.1 já estava concluído. Checkout iniciou limpo. Boost reconfirmou PHP 8.5/Laravel 13.34.0/PostgreSQL/Pest 5.2.1; documentação de container/testing consultada. Site Lerd `trocado` descoberto antes das operações. Skills architecture/quality-gate e SDD local consultadas; fluxo OpenSpec por instructions apply/status e validação estrita.

`GetInsightsUseCase` passa a depender especificamente de `ResourceUseCase`, mantendo `Port → UseCases → Repository`. A seleção/deduplicação existente continua antes da composição. Todos os textos e chaves são preparados antes da única chamada ao Core; só então os Outputs recebem os UUIDs confirmados, na ordem final. Namespace `insights` e versão de identidade `1` são constantes independentes do catálogo editorial.

Componentes na ordem contratual: `type`, `subject`, `history_state`, `analysis_from`, `analysis_to`, `comparison_from`, `comparison_to`. Opcionais ausentes são null tipados; owner é escopo separado do lote. Onboarding usa o período interno e conserva período público null. Não entram valor, descrição, maior Expense, modo editorial, dia de visita ou versão de catálogo. SQL financeiro, regras, limites, composição, rotação e catálogo não foram alterados; não há novo Model/Repository/binding/migration em Insights.

### Rastreabilidade de cenários e evidência

| Cenário anterior → destino atual | Evidência e classificação |
| --- | --- |
| GetInsightsUseCaseTest: obtenção de owner, fatos tipados, valores, variantes, períodos, tipos, assuntos, onboarding e falhas → mesmo arquivo | **Proven**: 18 casos anteriores preservados; hash esperado substituído por UUID fornecido pelo stub do Repository Core. Core real orquestra a resolução com TransactionPortFake, sem alegar rollback de banco |
| Chave contratual, nulls, estado, comparação e ordem → novos casos no mesmo Unit | **Proven**: componentes esperados escritos independentemente; um único lote para comparação/observação, retorno do Repository invertido reconciliado; estados current_expenses/no_current_expenses conservam período interno. Chave exata exclui dados e versão editorial; não houve troca artificial do catálogo |
| Fonte/precisão/composição/registro falham → novos casos Unit e MonthlyCompositionFailureHttpTest | **Proven**: Repository Core nunca chamado antes de validação/composição bem-sucedidas; HTTP falhando no segundo cartão, após comparação componível, deixa zero associações e não publica data parcial/onboarding |
| MonthlyIdentityHttpTest: default/URL/zeros, valores/descrição/visita/owner/mês, onboarding null e estados → mesmo arquivo | **Proven** em HTTP/PostgreSQL com PAT real: associações estáveis nas equivalências e distintas por mudança lógica. Nenhuma prova de período ou precisão removida |
| Desaparecimento/retorno + PAT novo/processo novo → novo cenário MonthlyIdentityHttpTest | **Proven**: mudança de categorias remove IDs da seleção; restaurá-las reutiliza os IDs em processo filho PHP real com conexão PostgreSQL nova e guard limpo, no dia seguinte/PAT substituído. Rows anteriores ficam idênticas e PAT removido responde 401. Processo por fork; não simula reboot integral do servidor |
| InsightsApiTest/MonthlyContractHttpTest: JSON:API, privacidade, períodos, limites 24/80 e snapshot → mesmos arquivos | **Proven**: assertions de hash passam a versão/variante/canonicalização UUIDv7; demais assertions preservadas. Três cartões, uma leitura financeira por chamada, registro miss de três statements e hit de um SELECT; rows/timestamps de hits intactos. Queries de users/PAT são classificadas separadamente como middleware |
| Fonte indisponível/registro falha após escrita → StableIdentityFailureHttpTest | **Proven**: exceção sentinela da fonte reportada sem acesso ao registro; SQLSTATE 23514 real induzido após observar INSERT confirmado dentro da transação, rollback para zero rows, erro sanitizado sem previous, JSON:API 500 sem data/fallback e transactionLevel zero |
| Pureza e permissões específicas Core → ContextBoundariesTest | **Proven**: arquivo isolado e suíte focada sem ampliar allowlist ou importar Core Infrastructure/Repository em produto Insights |

Não há cenário antigo eliminado ou consolidado. O seletor continua limitado a seis e deduplica antes do lote; os contratos de lote vazio e seis chaves são comprovados na capacidade Core do STEP 07, não por fabricar seis cartões ou uma seleção vazia na geração atual (que oferece orientação quando faltam fatos).

### Comandos e resultados finais

Todos os comandos abaixo usam `lerd composer test --` e terminam com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Feature usa bancos exclusivos do launcher, migrations incrementais e cleanup registrado; nenhum reset do banco operacional.

| Argumentos de seleção | Testes / assertions | Duração |
| --- | --- | --- |
| `tests/Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php` | **25 / 185** | 56 ms |
| `tests/Feature/Insights/InsightsApiTest.php` | **54 / 361** | 2.079 ms |
| `tests/Feature/Insights/Presentation/Http/MonthlyContractHttpTest.php` | **2 / 88** | 361 ms |
| `tests/Feature/Insights/Presentation/Http/MonthlyIdentityHttpTest.php` | **6 / 169** | 584 ms |
| `tests/Feature/Insights/Presentation/Http/MonthlyCompositionFailureHttpTest.php` | **2 / 32** | 298 ms |
| `tests/Feature/Insights/Presentation/Http/StableIdentityFailureHttpTest.php` | **2 / 24** | 300 ms |
| `tests/Unit/Architecture/ContextBoundariesTest.php` | **30 / 504** | 4.838 ms |
| `tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php` | **827 / 32.851** | 11.533 ms |
| nenhuma (gate completo padrão) | **2.267 / 40.376** | 51.290 ms |
| `tests/Feature/Insights --parallel --processes=2` | **176 / 1.960** | 4.648 ms |

Pint `--dirty --format agent` executado antes das verificações finais; corrigiu somente imports dos dois testes. Todos os arquivos de teste alterados passaram isoladamente após o formatter. Gate completo inclui as provas Redis/concorrência/duas invocações simultâneas existentes; não houve exclusões/skips/incomplete/risky. As duas seeds e o paralelo completo históricos do STEP 07 não foram reexecutados nesta fatia; 14.* continua pendente para o fechamento da change.

A primeira tentativa de Feature Insights paralela pelo MCP retornou timeout sem evidência aproveitada. Após confirmar ausência de processos de teste restantes no container, o comando idêntico pela CLI Lerd passou com o resultado da tabela. Timeout não conta como aprovação.

### Observabilidade e limites operacionais

Captura Lerd já estava habilitada, sem alteração de configuração. Requisição local sem credencial a `/api/insights` retornou 401 JSON:API; `optimize_route` devolveu zero amostras. As contagens autenticadas acima são provas HTTP/PostgreSQL do launcher, não medição operacional nem evidência de ausência global de N+1. Rollout, reset e medição autenticada local permanecem no STEP 12. Não há nova migration nesta fatia.

**Resultado de escopo:** 8.1–8.7 completos e comprovados; próximo STEP 09 — Metrics com UUIDv7 estável. Nenhuma declaração de conclusão/arquivo da change inteira ou homologação Bruno/Flutter.

### Correção após relato de teste quebrando — 2026-10-15

A nova execução completa reproduziu **3 falhas e 4 erros** em `GetInsightsUseCaseTest` (2.260 passando de 2.267). No estado encontrado, `GetInsightsUseCase` consultava o owner antes de validar o período e emitia os componentes da chave em ordem diferente da matriz. Foi restaurada a validação antes de `UserPort::id()` e a ordem contratual `type → subject → history_state → analysis_from → analysis_to → comparison_from → comparison_to`. A ordem é parte do fingerprint Core, portanto a correção preserva a identidade em vez de alterar os esperados dos testes. As demais reorganizações encontradas no arquivo foram preservadas.

Após Pint `--dirty --format agent`, o arquivo Unit isolado passou **25/185**, 56 ms. O comando `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` passou **2.267/40.376**, 53.122 ms, sem skips/exclusões. As evidências anteriores permanecem históricas; esta execução confirma novamente o estado corrigido.

## STEP 09 — Metrics com UUIDv7 estável — 2026-10-15

O usuário autorizou continuar a implementação pelo STEP 09. PHP 8.5, Laravel 13.34.0 e PostgreSQL reconfirmados por MCP; documentação de JSON:API consultada via Boost. `route:list --path=api/metrics --except-vendor --no-interaction` confirmou o GET singular existente. Nenhuma nova migration; o schema operacional ainda usa bigint e a transição permanece no STEP 12. As provas abaixo aplicam migrations incrementalmente somente nos bancos exclusivos do launcher.

### Implementação e rastreabilidade

`GetExpenseMetricsUseCase` canonicaliza owner antes da fonte, injeta `UserPort → ResourceUseCase → ExpenseMetricsRepository` e mantém uma chamada a `summarize()`. Valida total, categorias, soma, ordenação e percentuais antes de resolver um lote de uma chave Core. Namespace `expense-metrics`, versão 1, componentes em ordem **start_date → end_date → mode**; owner é escopo separado. Valores, categorias e URL não entram na chave. O ID do Output é somente o UUID confirmado por Core, inclusive no zero. SQL financeiro, período, filtros, Response, provider e cálculos permanecem os existentes.

| Contrato / cenário anterior → evidência atual | Destino e resultado |
| --- | --- |
| Hash público opaco → UUID confirmado, chave exata, owner canônico, zero e soma acima de inteiro nativo | `tests/Unit/Metrics/Application/UseCases/GetExpenseMetricsUseCaseTest.php`: registro simulado sem bootstrap/ORM; resposta usa UUID explícito da fixture; namespace/versão/nomes/tipos/ordem dos componentes são verificados. |
| Default/intervalo equivalente, owner/start/end/modo diferentes, estabilidade frente a valores/ordem | Mesmo arquivo Unit: preserva os cenários anteriores, agora com Core real e persistência simulada, sem replicar o digest de produção para calcular esperado. |
| Precisão, catálogo, duplicatas, grupos inconsistentes, categorias inesperadas e falha de fonte/owner | Cenários Unit anteriores agora exigem **zero chamadas** ao registro. Falhas do registro, lote incompleto e hash em lugar de UUID falham explicitamente, sem Output alternativo. |
| Resumo singular e filtros/proteções anteriores | `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php`: IDs dos dois modos são v7 canônicos e distintos; filtros inválidos e contas bloqueadas não criam associações. Preservadas as provas de catálogo, totais enormes, percentuais, timezone, leap years e isolamento. |
| Zero → criação → edição/recategorização → mudança de ocorrência → retorno → exclusão | `tests/Feature/Metrics/Presentation/StableMetricsIdentityHttpTest.php`: HTTP real/PG nos dois modos, mesmo UUID e fatos atuais; default equivale ao explícito com ordem/trim aceitos. Categorias continuam somente parcelas sem ID/relationship. |
| Nova sessão/processo e isolamento de identidades | Mesmo arquivo: revoga PAT anterior, emite substituto, executa Kernel HTTP em processo filho com conexão PostgreSQL nova e relê UUID/fatos; token antigo recebe 401. Outra conta, outro modo e outro período têm UUIDs distintos. Row original do registro permanece idêntica. É processo por fork, não reinício frio do servidor. |
| Query constante para 0/1/18 categorias | Mesmo arquivo: uma leitura financeira; miss usa SELECT/INSERT/SELECT do registro, hit usa um SELECT. Rows de despesas e registro hit permanecem idênticas; Queue fake exige nenhum dispatch. Queries de autenticação/middleware/controle são classificadas separadamente, sem prometer um statement total do endpoint. |
| Falha financeira, precisão, reconciliação e falha SQL após INSERT do registro | Mesmo arquivo: JSON:API 500 exato sem `data`; fonte inválida não toca o registro. Listener comprova primeira escrita, provoca SQLSTATE 23514 e verifica rollback real para zero rows/transaction level zero e exceção Core sanitizada sem previous. Não é prova de corrida nova; concorrência Core existente foi exercitada no gate completo. |

Não foram introduzidos cache, tabela de resumo, materialização, queue/job, IDs por categoria, escrita de despesas ou imports de Infrastructure na Application. As permissões específicas de Core já existentes bastam; arquitetura não foi ampliada.

### Execuções finais

Todos os comandos Pest usam `lerd composer test --` e terminam com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`. Arquivos modificados foram executados isoladamente após a última edição/Pint. Nenhum skip/incomplete/risky ou exclusão nas execuções aprovadas.

| Seleção após `test --` (antes dos flags comuns) | Testes / assertions | Duração Pest |
| --- | --- | --- |
| `tests/Unit/Metrics/Application/UseCases/GetExpenseMetricsUseCaseTest.php` | 48 / 180 | 59 ms |
| `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php` | 91 / 859 | 3.240 ms |
| `tests/Feature/Metrics/Presentation/StableMetricsIdentityHttpTest.php` | 9 / 199 | 763 ms |
| `tests/Unit/Metrics tests/Feature/Metrics tests/Unit/Architecture/ContextBoundariesTest.php` | 193 / 1.794 | 8.974 ms |
| sem seleção — gate completo padrão, incluindo Core/Redis/concorrência/duas invocações simultâneas | 2.283 / 40.731 | 52.713 ms |
| `tests/Feature/Metrics --parallel --processes=2` | 115 / 1.110 | 4.127 ms |

Pint `--dirty --format agent` passou (ordem de imports Unit corrigida), `git diff --check` passou e OpenSpec estrito passou. Durante desenvolvimento, o Unit detectou assinatura posicional incorreta no esperado de `ResourceKeyInput` e ordem incorreta de componentes no código intermediário; ambos corrigidos, preservando a matriz canônica em vez de flexibilizar o teste. A primeira chamada paralela via MCP retornou timeout enquanto o gate completo executava; não conta como aprovação. A invocação paralela repetida sozinha é a evidência da tabela. Seeds globais e gate paralelo global finais continuam nas tarefas 14.x.

### Limites operacionais e resultado

Captura Lerd já estava habilitada; não houve mudança de configuração. GET local sem credencial em `/api/metrics/expenses` retornou 401 JSON:API. `optimize_route` retornou zero amostras: as contagens autenticadas acima são evidência HTTP/PostgreSQL do launcher, não medição operacional nem comprovação global de ausência de N+1. Reset e medição autenticada local permanecem no STEP 12. Não houve homologação Bruno/Flutter, archive ou publicação.

**Resultado de escopo:** 9.1–9.7 completos e comprovados; próximo STEP 10 — sugestões com UUIDv7 estável. A change inteira continua pendente nas fatias seguintes.

## STEP 10 — Sugestões com UUIDv7 estável — 2026-10-15

10.2/10.3: `GetExpenseSuggestionsUseCase` reutiliza exatamente a chave SQL em `expense-suggestions` v1, componente `description_key:string`, com owner canônico separado. Prepara todo o lote antes de resolver Core, mantém ordem/valor opcional e retorna vazio sem consultar o registro. Primeira verificação Unit isolada pelo launcher com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **35 testes / 180 assertions**, incluindo chave exata, lote, retorno reverso do Repository, vazio e falhas sem alocação.

10.4/10.5: arquivos isolados pelo mesmo launcher/flags: Unit **36/183**, HTTP existente **32/195**, HTTP de identidade estável **9/140**, Repository PostgreSQL **27/94**. Provas incluem processo filho com conexão nova/PAT substituído; termos/case/acentos/espaços; amount presente/alterado/omitido; janela distinta; outra conta; assunto distinto; desaparecimento/retorno; lote misto com quatro inserts e hit intacto; 0/1/5 recursos com uma leitura financeira e 0/3/1 statements Core vazio/miss/hit; fonte e segundo candidato inválido sem registro; falha SQL após insert comprovado com rollback, 500 JSON:API sem data/causa SQL; despesas/IA/queue preservados e nenhuma operação de cache no UseCase direto.

### Mapa de cenários e evidências finais

| Origem / contrato preservado | Destino / incremento UUIDv7 | Evidência |
| --- | --- | --- |
| Unit de janela, matemática inteira/amount opcional, ordem e falha de owner | Mesmo arquivo `GetExpenseSuggestionsUseCaseTest.php`; fake tipado exclusivo de sugestões em `Tests\\Support\\Expense\\Fakes`, sem Laravel/PG; expectativa independente da chave em mock Core | 36 testes / 183 assertions |
| Unit de hash estável por owner/chave | Mesmos cenários usam UUIDs de fixture associados; novos cenários provam namespace/v1/`description_key` exata, lote único, retorno reverso, vazio, owner inválido, projeção inválida no segundo item e falha/incompletude Core | Incluído nos 36/183; não remove cenário monetário anterior |
| HTTP de proteções, buscas/entrada, owner, amount, criação e ausência de efeitos IA/queue | Mesmo `GetExpenseSuggestionsHttpTest.php`; assertion de hash substituída por forma v7/variante, demais cenários preservados | 32 testes / 195 assertions |
| Repository SQL de normalização, busca literal `%`/`_`/barra/aspas, acentos, espaços, ranking/limite, ties, meses e precisão | Mesmo `EloquentExpenseSuggestionsRepositoryTest.php`; construtores passam capacidade Core e novo cenário observa ausência de cache no UseCase direto | 27 testes / 94 assertions; fonte SQL não foi alterada |
| Estabilidade persistida e falhas | Novo `StableSuggestionIdentityHttpTest.php`: fatos recalculados, PAT substituído/processo filho/conexão nova, descrição/assunto, desaparecimento/retorno, row intacta no hit, batch misto, schema mínimo sem descrição, statements 0/1/5, falha SQL após insert/rollback e 500 sem data | 9 testes / 140 assertions |

### 10.6 Verificação e limites

- Os quatro arquivos acima passaram isoladamente **após Pint**, pelo launcher, com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: total **104 testes / 612 assertions**. Após extrair o fake tipado exclusivo desse Unit, Pint e esse arquivo passaram novamente (**36/183**).
- Integração: `lerd composer test -- tests/Unit/Expense tests/Feature/Expense tests/Unit/Core tests/Feature/Core tests/Unit/Architecture/ContextBoundariesTest.php --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **1.026 testes / 5.453 assertions**, sem skips/incomplete/risky. Inclui provas existentes de concorrência/rollback Core e cache/classificação/worker Expense; não atribui essas provas ao fake de sugestões.
- `lerd` vendor `pint --dirty --format agent`: passou. `git diff --check` e validação OpenSpec estrita passaram.
- Boost schema confirmou que o banco operacional ainda tem IDs bigint e não tem `resource_identities`; a conversão operacional permanece no STEP 12. As provas desta fatia usaram bancos exclusivos do launcher, com migrations incrementais. Não houve reset operacional.
- Captura Lerd já estava habilitada e permaneceu assim. `optimize_route(site=trocado)` retornou `samples: 0`, sem rotas: não há medição de tráfego operacional nem claim de desempenho de produção. Contagens financeiras/registro vêm dos requests HTTP reais do kernel nos testes PostgreSQL. Processo filho prova troca de processo/conexão/PAT; não equivale a reboot completo do servidor.
- Gate completo, duas seeds, paralelo global e homologação externa permanecem nas etapas próprias; o suporte transversal existente não foi alterado, e o fake novo é exclusivo do Unit de sugestões.

**Resultado de escopo:** 10.1–10.6 completos e comprovados; próximo STEP 11 — integração transversal e observabilidade. A change inteira continua pendente nas fatias seguintes.

### Revalidação após relato de teste quebrando — 2026-10-15

A execução completa reproduziu **4 falhas**, com 2.279 de 2.283 testes passando: no estado encontrado, os componentes Metrics estavam em ordem `mode → end_date → start_date`. Foi restaurada a ordem contratual **start_date → end_date → mode**, com comentário sobre sua participação no fingerprint persistido v1, sem alterar os esperados nem o contrato Core. Após Pint `--dirty --format agent`, o Unit isolado passou **48/180**, 59 ms; o gate completo padrão pelo launcher, com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`, passou **2.283/40.731**, 53.602 ms. Essa execução também inclui o ajuste posterior de tipagem/preparação explícita de `ExpenseMetricsHttpTest.php`; a restauração do relógio permanece no `FeatureTestCase::tearDown()`.
