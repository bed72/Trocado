## Context

PHP 8.5, Laravel 13.34.0, Sanctum 4.3.3, PostgreSQL. Versões e documentação Boost consultadas na elaboração; APIs instaladas devem ser reconferidas no apply. `HasUuids` gera UUIDv7 no Laravel instalado e Sanctum suporta Model de PAT próprio por `usePersonalAccessTokenModel`.

O schema atual usa bigint em User/Expense/PAT e FKs; Notifications usa UUIDv4 em seu registro e UUID de instalação de versões diversas. IDs públicos de Insights/Metrics/sugestões são SHA-256 determinísticos. Core exige `UserPort::id(): int`. Rotas, cursores, dispatch de classificação, cache, DTOs, casts e testes pressupõem inteiros; a auditoria inicial encontrou 51 arquivos de aplicação com esses pressupostos, sem tratar essa contagem como inventário completo ou prova de equivalência.

Esta change é exclusivamente de especificação enquanto não houver novo apply autorizado. Não muda schema, configuração, arquivos de produto, dependências ou testes nesta etapa.

### Início autorizado da preparação — 2026-10-14

O pedido posterior autoriza executar o STEP 01 de `STEPS.md`. O [inventário e as evidências em tasks.md](tasks.md#step-01--preparação-e-inventário--2026-10-14) reconferem APIs, schema, casts, consumidores e fatias. O estado de elaboração descrito acima é histórico; geração, persistência e comportamento UUIDv7 ainda dependem das etapas seguintes.

## Goals / Non-Goals

**Goals:** uma política UUIDv7 para todas as entidades/identificadores públicos próprios; IDs estáveis para projeções; owner/session UUID sem perda de autorização; validação pura; geração suportada em Infrastructure; consumo Core explícito; concorrência e resolução em lote; transição limpa local sem legado.

**Non-Goals:** alterar semântica financeira, moeda, filtros civis, categorias, políticas temporais de sessão, estratégia de hashing de senhas/segredos, bytes FCM, SDKs internos, tabelas técnicas Laravel, frontend Flutter neste repositório, transporte/envio push, migração de produção ou compatibilidade com IDs antigos. Associação de identidade não é cache nem materialização de resultados.

## Decisions

### D1 — Escopo, formato e representações

| Identificador | Destino |
| --- | --- |
| User / `users.id` / IDs de `users` e `sign-ups` | UUIDv7; SignUp conserva o ID da própria User |
| PAT / `personal_access_tokens.id` / `access-tokens.id` | UUIDv7; `tokenable_id` também UUID de User |
| Expense / `expenses.id` e `user_id` | UUIDv7 |
| Notifications / registro `id`, `user_id`, `session_id` | UUIDv7 |
| `installation_id` | UUIDv7 obrigatório, gerado pelo cliente |
| Insights / Metrics / sugestões | UUIDv7 gerado uma vez e recuperado por associação estável de Core |
| Registro auxiliar de Core: `resource_identities.id`, `user_id` | UUIDv7 |
| `request_id` / `trace_id` próprios | O mesmo UUIDv7 novo por request; header/log conservam igualdade |
| IDs de mensagem de push futuros controlados pelo projeto | UUIDv7 no contrato; a geração não ativa a fatia de envio |
| `jobs.id`, `failed_jobs.id/uuid`, `migrations.id`, payload UUID de queue e IDs de SDKs | Contratos internos nativos, fora da conversão |
| Bearer/FCM, password hash, assinatura, fingerprints, token de fencing de classificação | Não são IDs de entidade/recurso; continuam em seus formatos de segurança |
| categoria/type/action, centavos, datas, contagens, generation e versões | Continuam códigos/valores próprios; não são UUIDs |

UUIDv7 canônico significa string textual de 36 caracteres, com hífens, versão 7, variante RFC 9562 e letras minúsculas. Entradas UUID textuais estruturalmente válidas podem normalizar somente caixa; não fazer trim, completar, remover hífens ou converter inteiro/hash/UUIDv4 para v7. Corpo JSON com número não é UUID. `null` antes da persistência é permitido somente nos pontos já explícitos de entidade não persistida, nunca em ID de resposta/owner/FK obrigatória.

Alternativas rejeitadas: manter mistura por contexto; trocar somente Notifications; alterar bits de hash para aparentar UUIDv7; gerar novo UUID por consulta. A escolha final do usuário é ID estável, substituindo a resposta inicial de UUID novo.

### D2 — Fronteiras e geração

- Core Domain fornece `UuidValueObject` e sua exceção para formato, versão, normalização/equivalência, sem Laravel, banco ou relógio. IDs presentes dos contratos são strings canônicas; não criar interfaces de Entities/VOs nem converter todos os scalars do projeto para objetos.
- Domain valida IDs presentes também para chamadores fora de HTTP; Application valida antes de chamar Repository/capacidade. Model/DTO não pode transformar UUID em int, zero ou float.
- Geração usa `HasUuids`/`Str::uuid7()` em Infrastructure/Presentation onde apropriado. UUIDv7 nasce no momento de emissão, não no mês financeiro analisado. Não sobrescrever globalmente o gerador UUID do Laravel para atingir IDs de dependências.
- Models autogeráveis são não incrementais/string; bulk inserts/upserts devem fornecer UUIDs v7 porque não se assume execução de hooks Eloquent.
- Repositories conservam seu papel. Core terá `ResolveResourceIdentitiesUseCase` concreto, `ResourceIdentityRepository`, implementação Eloquent e Data tipado próprio (`Input`/`Output`). Registro de associação é persistência real, não um wrapper de uma chamada chamado Port.
- Consumers conhecem somente o UseCase/Data públicos específicos de Core e o conceito puro UUID. Propor no apply as permissões explícitas em ARCHITECTURE/ContextBoundariesTest; não liberar diretórios inteiros nem importar Models/Infrastructure de Core.
- Core não importa contextos consumidores nem enum financeiro; namespace é um rótulo técnico genérico. Políticas de composição de chave ficam em cada consumidor.

Há mudança arquitetural explícita: a proibição de persistir IDs auxiliares de projeções passa a permitir apenas esse registro mínimo, sem transformar o contexto analítico em dono de Expense ou de User.

#### Definição de contratos — STEP 02 — 2026-10-14

O pedido posterior autoriza a implementação e as provas do STEP 02. O conceito puro usa `UuidValueObject::fromString(string): self`, `value(): string` e `equals(self): bool`; strings inválidas lançam `InvalidUuidException`, tipos não string (incluindo `null`) são rejeitados pela assinatura estrita. Não há factory nullable nem geração no Domain. A fixture `Tests\Support\Core\Fixtures\UuidFixture::at(int): string` é determinística, com índice explícito de 48 bits e prefixo fixo v7; serve somente aos testes, sem relógio, estado global ou esperado obtido do gerador de produção.

Nomes/tipos fechados para implementação no STEP 07 (não são classes implementadas pelo STEP 02):

| Contrato / Data de Core Application | Assinatura / campos |
| --- | --- |
| `Data\ResourceIdentityInput` | `namespace: string`, `identityVersion: int`, `components: array<string, string\|int\|bool\|null>`; mapa ordenado de componentes tipados, namespace técnico e versão positiva |
| `Data\ResolveResourceIdentitiesInput` | `userId: string`, `identities: list<ResourceIdentityInput>`; um owner canônico obrigatório por lote |
| `Data\ResourceIdentityOutput` | `identity: ResourceIdentityInput`, `id: string`; projeção de associação do Repository, UUID confirmado obrigatório |
| `Data\ResolveResourceIdentitiesOutput` | `identities: list<ResourceIdentityOutput>`; correspondência na ordem original, inclusive repetições da mesma chave |
| `Repositories\ResourceIdentityRepository` | `resolve(string $userId, array $identities): array` com `list<ResourceIdentityInput>` → `list<ResourceIdentityOutput>`; lote deduplicado, sem tipos ORM, UUID candidato ou Output de UseCase reaproveitado |
| `UseCases\ResolveResourceIdentitiesUseCase` | `execute(ResolveResourceIdentitiesInput $input): ResolveResourceIdentitiesOutput`; valida owner/chaves antes do Repository, deduplica e recompõe a ordem |

Os Data serão `final readonly`, constructor-only, sem comportamento, validação, geração, digest ou framework. O UseCase valida/canonicaliza `userId` e valida componentes/namespace/versão antes da capacidade de persistência. O UseCase define a unidade curta da resolução concorrente por `TransactionPort`; o Repository executa o mecanismo de lookup/insert/releitura, sem colocar leituras/composição financeiras na transação. A representação do digest deve preservar nomes, tipos, ordem fixa e `null`, sem conversão para string vazia; arrays aninhados, floats e objetos não fazem parte do contrato. Componentes são transitórios e não entram em logs nem nas rows do registro.

IDs presentes de owner/FK/sessão/saída usam `string` canônica, nunca `?string` ou `int|string`. Somente os pontos existentes de entidade sem persistência (`UserEntity::$id` e `ExpenseEntity::$id`) terão `?string`; nesses pontos `null` continua ausência e valor presente passa pelo VO. `NotificationRegistrationEntity::$id` já é obrigatório e permanece `string`, passando a exigir v7. Essa integração é dos STEPs 04/05/06. `UserPort::id(): string` e `ContextPort::identifyUser(string $userId): void` serão convertidos junto aos adapters/consumidores no STEP 04, sem antecipar assinaturas incompatíveis agora.

A permissão implementada neste step cobre somente `UuidValueObject`/`InvalidUuidException` específicos. No STEP 07 a Application de Expense, Insights e Metrics poderá consumir somente o UseCase e os quatro Data acima, sem liberar `Core\Application` inteiro nem o Repository interno aos consumidores. Core continua sem imports de contextos consumidores; namespace/componentes não introduzem enum financeiro em Core.

### D3 — Registro transversal mínimo

Tabela proposta `resource_identities`, owner Core:

| Campo | Papel |
| --- | --- |
| `id uuid PK` | UUIDv7 público associado ao recurso |
| `user_id uuid NOT NULL` | FK `users.id`, cascade no encerramento de conta |
| `namespace varchar(64) NOT NULL` | Nome técnico lowercase iniciado por letra, segmentos alfanuméricos separados por hífen (`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`); máximo 64 caracteres |
| `identity_version smallint NOT NULL` | Versão positiva da semântica da chave, não versão editorial |
| `logical_fingerprint char(64) NOT NULL` | Digest interno para lookup; não ID público, payload, credencial ou descrição |
| `created_at` | Momento técnico da primeira associação |

Unique `(user_id, namespace, identity_version, logical_fingerprint)`; PK única em `id`; checks UUIDv7/namespace/versão/digest. Nenhum campo de valor, percentual, categoria financeira, período explícito, descrição, token, título/corpo, visualização ou último acesso. FK não implica import/relação Eloquent com Identity. O digest usa uma representação não ambígua dos componentes tipados; hash é permitido internamente, mas nunca substitui/é apresentado como o UUID público.

Retenção sem TTL enquanto a conta existir: um recurso que desaparece da resposta e volta com a mesma identidade lógica reutiliza o UUID. Excluir conta remove as associações por cascade; SignOut/pruning/expiração de PAT não as removem. Não retornar recursos somente porque a associação existe. Não há endpoint de consulta/listagem desse registro nem exclusão manual pública.

### D4 — Chaves lógicas, estabilidade e mudanças

| Namespace | Componentes da chave lógica, além do owner UUID |
| --- | --- |
| `insights` v1 | tipo, categoria/assunto ou vazio, estado de onboarding ou vazio, from/to internos de análise e from/to de comparação ou vazios |
| `expense-metrics` v1 | start_date/end_date efetivos e modo total/category |
| `expense-suggestions` v1 | chave de descrição normalizada já produzida pela leitura SQL |

Representação canônica inclui nomes/tipos/limites inequívocos, sem concatenação ambígua. Para sugestão, conservar exatamente a semântica atual de normalização SQL; não normalizar descrição outra vez com um algoritmo PHP diferente. Namespace e versão da identidade são constantes de semântica, não do catálogo de mensagens.

Fechamento no STEP 01: componentes opcionais sem assunto/estado/comparação são `null` explícitos, distintos de string vazia; usar ordem fixa e codificação tipada não ambígua. Owner é escopo separado. A matriz detalhada de nomes/tipos, equivalências e limites de lote está em `tasks.md`, seção 1.4. Esses componentes permanecem transitórios; somente seu fingerprint técnico entra no registro.

Não entram na identidade: valor, percentual, contagens, descrição exibida de despesa, título, variante/dia de visita, versão editorial, ordem textual/zeros à esquerda dos filtros ou tamanho de página. Para sugestão, o termo de busca/janela monetária não altera a chave normalizada. Mudança do texto normalizado que define o assunto da sugestão é mudança legítima de identidade.

Vigente de Insights muda de ID se seu limite efetivo interno mudar; histórico do mesmo período mantém ID em outro dia. Onboarding tem período interno apesar do `period: null` público. Troca do maior lançamento não troca por si só o ID de uma concentração de despesa se tipo/assunto/períodos forem iguais, preservando a identidade de observação atual.

### D5 — Resolução em lote e concorrência

1. Autenticar, validar entrada/owner e consultar os fatos financeiros por seu Repository.
2. Validar projeções, gerar/deduplicar/selecionar candidatos e compor todos os textos/outputs relevantes antes de criar associações. Zero recursos: lote vazio, zero statements do registro; Metrics zero total ainda é um recurso e precisa de UUID.
3. Preparar o lote de identidades finais: até seis Insights, cinco sugestões ou um resumo Metrics. Deduplicar chaves iguais e manter a ordem de saída.
4. Resolver todas as chaves por owner em uma leitura do registro. Se todas existem, retornar sem atualizar rows/timestamps.
5. Para ausentes, gerar UUIDv7 e inserir em lote sob unidade curta definida por `TransactionPort`. Unique de chave resolve disputa; perder o insert não autoriza trocar o UUID vencedor.
6. Fazer releitura em lote com snapshot novo quando houver conflito para ver o vencedor confirmado. Não usar CTE de snapshot único `DO NOTHING` assumindo visibilidade de row inserida por outra transação; não usar update fictício do ID/timestamp em cada GET.
7. Reconciliar chave → UUID e devolver lote completo em ordem. Sem resposta parcial, UUID aleatório de fallback ou suposição de retorno na ordem do SQL.

Ordem de locks/inserts pela tupla técnica canônica. Até três tentativas limitadas para race/deadlock/serialization; rollback da tentativa completa antes de retry. Nenhuma query por cartão/chave ou chamada de rede dentro da transação.

Teto por tentativa para um lote não vazio: até três statements do registro (SELECT em lote, INSERT em lote de ausentes, releitura em lote se necessária); hit completo usa um. Controles transacionais/autenticação e query de guard de teste não são contados como leitura financeira. Cada Repository financeiro conserva seu statement/snapshot; o novo estado não pode introduzir N+1 de despesas.

Concorrência com encerramento de conta: FK/locks impedem rows órfãs e recriação de owner apagado; falha de associação não produz resposta fabricada. A identidade não confere acesso nem muda regras de revogação/ownership.

### D6 — Identity, PAT e HTTP

- `users.id` e `personal_access_tokens.id` UUID; associação polimórfica tem `tokenable_id` UUID e tipo atual de `UserModel`. Model de PAT próprio em Identity estende o do Sanctum e é registrado pela API suportada; sem modificar vendor nem implementar outro protocolo de credenciais.
- `SignInOutput`, todos os Ports/Repositories de User/sessão e NotificationAdapter deixam de exigir inteiros. `UserPort` valida e devolve UUIDv7 canônico do guard, com 401 para principal inválido/ausente.
- A parte ID de Bearer emitido por Sanctum será UUIDv7, mas o token completo permanece segredo do pacote (`id|segredo`), hash SHA-256 e validação oficial. Prefixo legado/malformado deve falhar em 401 antes de comparação inválida com coluna UUID, nunca 22P02/500.
- Preservar SignUp pending/unverified, login de conta apta, validade/expiração/limite absoluto, extensão in-place, locks, revogação, pruning e logout por token atual. Account/PAT/registry cascades são provadas em PostgreSQL.
- Rotas de entidade passam a UUIDv7, com normalização de caixa antes da comparação de ownership, sem coerção numérica. Não reescrever URL antes da verificação de assinatura.
- Verificação de e-mail usa User UUID no link; SHA-1 de e-mail e assinatura continuam mecanismos nativos. Links numéricos antigos são descartáveis e não ganham alias.
- HTTP mantém resource types, atributos e statuses. ID numérico/malformado/versão errada em rota de entidade apta → 404 uniforme; UUID desconhecido/alheio → mesma política de inexistente. Documentos editáveis com ID inválido seguem 422/pointer; Bearer inválido → 401; query/cursor → 422 no contrato atual.

### D7 — Expense, cache, cursor e classificação

`expenses.id/user_id` UUID. Repository continua filtrando owner antes da query. Retirar todos os casts numéricos e separar validação de `id` UUID e `amount` inteiro no cursor.

Cursor v2 contém posição com ID string UUIDv7; rejeitar v1 numérico e shape legado mesmo em filtros antigos. Canonicalização da query, ordem de campos, direção e collation permanecem. Desempate UUID ASC/DESC usa a mesma comparação PostgreSQL da seleção e do seek; não supor que UUIDv7 prova ordem global de cadastro em clocks/processos concorrentes. Recência explícita continua por `created_at`/datas já definidas.

Versionar namespace de páginas/cache de Expense, preservar invalidação após commit e owner UUID nas tags. Invalidar cursores/cache antigos por versão, sem cache de associação de identidade. Jobs próprios de classificação carregam Expense UUIDv7; fencing token, segredo e política de overwrite permanecem. Não consumir payloads numéricos antigos após a transição; limpar somente filas/prefixos deste site, com workers pausados e estado operacional restaurado.

### D8 — Notifications e cliente

Registro, owner e sessão UUIDv7; geração não altera instalação/token/semântica de rotação. `installation_id` recebido deve ser UUIDv7; formato de outras versões → 422 em `/data/attributes/installation_id`, sem eco FCM. Entity/UseCases validam mesmo fora de HTTP. DELETE owner-scoped aceita apenas ID de registro v7, com 204/404 atuais.

Antes de avançar a fatia de push/cliente, coordenar o design/specs/tasks da change ativa `add-firebase-push-notifications`: UUIDv7 do registro e instalação, `NotificationPort::lock` owner/retorno string, UUIDv7 de `notification_id` próprio futuro e UUIDv7 de `resource_id` quando referencia recurso do projeto. Não arquivar, reabrir tasks históricas ou marcar transporte/cliente como implementados por causa desta change.

Flutter precisa gerar UUIDv7 de instalação, mantê-lo na instalação, atualizar filtros de IDs e não converter IDs para números. Versão de biblioteca/generator do cliente será comprovada na homologação; esta spec não autoriza alterar outro repositório ou ativar envio real.

### D9 — Reset, rollout e rollback

Decisão explícita: recriação somente do banco local de desenvolvimento na implementação futura. Atualizar migrations de bootstrap dos quatro recursos e adicionar registro Core; não manter duas famílias de schema nem backfill inteiro→UUID/UUIDv4→v7. Ajustar migrations de rename/fingerprint conforme necessário para construir o novo schema do zero; preservar testes de rollback/constraint, não aproveitar o reset para removê-los.

Durante apply, reconfirmar pelo MCP o site/engine/DB alvo e que não é produção, compartilhado ou DB de testes. Somente então executar o comando autorizado `lerd artisan migrate:fresh --no-interaction` nesse banco. Sem `--seed` automático. Permissão não se estende a outra base, produção, FLUSHALL/FLUSHDB, destruição do lifecycle de testes ou um reset futuro arbitrário.

Tokens, links assinados, cursores e dados demonstrativos antigos deixam de valer. Pausar workers relevantes, remover somente payloads/chaves próprios incompatíveis, recriar schema, verificar geração/constraints e restaurar workers previamente ativos. Testes continuam `lerd composer test -- ...` com preflight/ownership e migrations incrementais em DBs exclusivos; nunca `migrate:fresh` no launcher.

Rollback antes de adoção: reverter a release e recriar novamente apenas o desenvolvimento consentido. Não prometer preservação de IDs/associações ou rollback de produção. Se surgirem dados reais/produção no alvo, interromper reset e obter nova estratégia; a declaração original de ausência de usuários não substitui verificação do ambiente.

### D10 — Provas e critério de conclusão

- Unit Core/Domain: UUIDv7 canônico, caixa, null somente autorizado, rejeição v1/v4/v6/v8/inteiro/hash/nil/variante inválida; sem geração/clock framework em Domain.
- Unit Application: owner UUID explícito, chave lógica por consumidor, batch e falha sem efeito/fallback; resolver depois da validação/composição.
- PostgreSQL Core: unique de associação, PK/owner v7, isolamento, corrida sincronizada em conexões novas, rollback, cascades, reutilização sem UPDATE, limites de query por lote e owner apagado.
- Identity/Sanctum HTTP/PG: PAT real v7, lookup malformado 401 sem erro SQL, criação, sessão, verificação assinada, pruning e logout; contratos puros e sem enumeração.
- Expense HTTP/PG/worker: CRUD/owner UUID, sort/seek/next/prev em empates, cursor antigo rejeitado, índices/plano, cache scoped e classificação sem sobrescrever edição posterior.
- Notifications: instalação v7, registro v7, rotação/UUID estável, idempotência, conflitos, cifragem, corridas e cascades; sem ativar transport.
- Projeções: UUIDv7 estável através de reinício, dia/variante/valor, equivalências e concorrência; fonte financeira recalculada; zero recursos não aloca; falha Core/financeira/composição não produz dados parciais ou IDs fake.
- Fixtures/doubles substantial shared em classes tipadas; fixtures determinísticas distintas não dependem do gerador de produção para calcular esperado. Clock/timezone, listeners, guards e namespaces restaurados.
- Suporte transversal novo exige gate padrão completo, duas seeds registradas, paralelo com ≥2 processos e integrações Redis/concorrência/duas invocações simultâneas. Bruno controlado, Pint e validação OpenSpec completam a evidência; schema reset/desempenho/homologação não se presume de testes verdes.

## Risks / Trade-offs

- [GET passa a alocar identidade técnica] → exceção limitada e explícita de persistência; nunca gravar/cachear fatos; resolver depois de compor e em lote.
- [Associações crescem sem TTL] → retenção necessária à estabilidade, índice/owner cascade e medição de cardinalidade; não purgar IDs por rotina de frescura.
- [Corrida devolve UUID perdedor] → unique técnico, transação curta, releitura com snapshot novo e teste sincronizado, sem CTE invisível/fallback.
- [Registro auxiliares vaza descrições] → somente fingerprint interno; sem raw keys/payloads em rows, respostas, logs ou exceções.
- [UUIDv7 tratado como autorização ou data financeira] → ownership continua obrigatório; timestamp do UUID é emissão e não escolhe ocorrência/período.
- [Cast silencioso mantém int/zero] → inventário por papel, contratos tipados e testes de UUID não convertidos; valores financeiros continuam seus tipos.
- [Reset em DB errado/payload antigo] → reconfirmação do destino, pausa/limpeza exclusiva e lifecycle de teste intacto.
- [Mudança isolada quebra Sanctum/cliente] → release coordenada de schema/model/PAT/rotas/DTOs/Bruno e instalação; sem dual ID nem edição de vendor.

## Migration Plan

1. Aprovar artefatos e autorização específica do apply; inventariar IDs e dependências usando ferramentas disponíveis.
2. Converter bootstrap schema, validação Core e contratos compartilhados como uma fatia coerente; não publicar build parcialmente convertido.
3. Converter Identity/PAT e provar autenticação/owner; converter Expense/Notifications, cursor/cache/queue, read Repositories e fixtures.
4. Implementar registro Core com concorrência/cascade e integrar as três projeções após composição, em batch.
5. Atualizar specs coordenadas, documentação/Bruno e contratos de cliente; aplicar reset local consentido somente no alvo verificado.
6. Executar arquivos isolados, contextos, arquitetura e gates transversais; medir statement/plano do caminho financeiro e do registro sem extrapolar escala.
7. Registrar evidência por cenário, limitações e decisão de release. Archive/commit/push/deploy exigem seus pedidos próprios.

## Open Questions

### Resolvidas com o usuário

- Estabilidade: **Manter IDs estáveis**, resposta final da primeira pergunta repetida.
- Escopo: **Projeto e API**, sem mudar contratos internos Laravel/SDKs.
- Instalação: **Exigir UUIDv7**.
- Local: **Recriar banco local**, somente no futuro apply.
- Associação: **Registro transversal no Core**.

### Verificações de implementação / integração

- Detalhes do Model de PAT, `findToken`, bulk SQL/retry e constraints UUIDv7 serão conferidos no código instalado antes de usar APIs; não presumir que trait genérico valida somente v7.
- Identificar alvos/prefixos/queues e estado dos workers no momento de aplicar reset, sem operar nesta etapa.
- Compatibilidade do gerador UUIDv7/instalação no cliente requer evidência externa antes de alegar integração pronta; não bloqueia escrever esta spec nem autoriza frontend.
- Não há decisão de produto bloqueante em aberto para a proposta. Toda evidência de implementação permanece futura e tasks ficam pendentes.
