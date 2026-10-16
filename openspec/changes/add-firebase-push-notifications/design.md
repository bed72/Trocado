## Context

O inventário consultado via Boost informa PHP 8.5, Laravel 13.34.0, Sanctum 4.3.3 e PostgreSQL. O schema contém `users`, `personal_access_tokens`, `jobs` e `failed_jobs`, mas não destinos push nem histórico de notificações. A presença de tabelas de jobs não comprova qual conexão de queue está ativa; configuração e worker serão verificados apenas na implementação autorizada.

As specs de Authentication definem Bearer Sanctum, conta ativa/verificada, SignOut seletivo e expiração individual com teto absoluto de 90 dias. Identity continua sendo a autoridade dessas regras. A integração de e-mail já documenta notifications Laravel assíncronas, Redis e efeitos após commit. A documentação Laravel 13 consultada permite canais customizados; isso não obriga Notifications a importar `UserModel` ou colocar toda a integração no Model de Identity.

Fontes externas consultadas:

- Laravel 13 Notifications, canais customizados e queue: https://laravel.com/docs/13.x/notifications
- Gerenciamento dos registros FCM: https://firebase.google.com/docs/cloud-messaging/manage-tokens
- Cliente Flutter oficial: https://firebase.google.com/docs/cloud-messaging/flutter/client

A documentação Firebase consultada descreve coexistência/transição entre tokens de registro e Firebase Installation IDs. Isso não prova que os SDKs dos clientes nem o pacote PHP escolhido suportem ambos. O identificador de instalação local desta proposta é um UUID gerado pelo cliente; ele **não** é FID, token FCM, ID físico do dispositivo ou Bearer Sanctum.

Todos os valores operacionais abaixo são defaults propostos, sujeitos à revisão indicada em Open Questions. Este documento descreve implementação futura; não registra implementação ou evidência de testes executados.

### Decisões do contrato com o cliente — 2026-10-13

- Plataformas aprovadas pelo usuário: somente Android e iOS; web fora desta entrega.
- Cliente confirmado: Flutter com pacotes oficiais Firebase (`firebase_core` e `firebase_messaging`); versões instaladas ainda não informadas.
- Política aprovada: opção A, vínculo ao PAT. Expiração efetiva interrompe novos envios mesmo antes de pruning; SignOut confirmado remove os registros ainda ligados à sessão revogada, preservando outras sessões. Novo login exige sincronização com sessão válida; cadastro push não estende o login.
- Perfil explicitamente aprovado para a fatia de cadastro: somente token de registro FCM via `getToken()`/`onTokenRefresh`, `registration_kind = token`. FID e token APNs direto não são perfis aceitos. A documentação atual descreve essas APIs Flutter como deprecated; essa decisão fixa o contrato desta fatia, sem comprovar versões instaladas nem autorizar migração para FID. Versões e payload real continuam pendentes para homologação; transporte server-side será decidido na fatia de envio.
- O `installation_id` do contrato permanece UUID local separado do identificador Firebase. No perfil token, o backend recebe token FCM, inclusive no iOS; `getAPNSToken()` não fornece o destino FCM desse perfil.
- O usuário autorizou implementar somente cadastro/atualização/remoção conforme o contrato HTTP abaixo, persistência e verificações focadas. Envio, queue, Firebase server-side e produtores permanecem futuros. O exemplo abaixo é contratual, não evidência de payload real.

## Goals / Non-Goals

**Goals:**

- Persistir múltiplos destinos por conta e um vínculo vigente por instalação.
- Oferecer API idempotente de sincronização e remoção de destino.
- Tratar rotação, logout, expiração, troca de conta e exclusão sem enviar a um novo proprietário a mensagem do anterior.
- Enviar via FCM fora da requisição de negócio e fora de callbacks transacionais sujeitos a retry.
- Isolar falhas por instalação e manter retries e duração da mensagem limitados.
- Preservar Domain/Application puros, segredo server-side e observabilidade sanitizada.

**Non-goals:** histórico no app, leitura, preferências por categoria, campanhas, tópicos públicos/privados, segmentos, anexos, agendamento, Firebase Auth, Firestore, rastreamento de entrega, outbox, transação distribuída, exatamente uma vez, alterações em mensagens de e-mail e gatilhos automáticos de Expense/Insights/Metrics.

## Decisions

### Coordenação UUIDv7 — contrato alvo — 2026-10-14

O STEP 01 de [`standardize-uuid-v7-identifiers`](../archive/2026-10-16-standardize-uuid-v7-identifiers/tasks.md) coordena a política de IDs desta change. A tabela e exemplos abaixo descrevem o **contrato alvo**, ainda não a conversão implementada: PK de registro, owner, sessão/PAT e instalação usam UUIDv7 canônico. Instalação vem do cliente e não é PK de registro; outras versões são rejeitadas, sem alterar bits de um UUID existente. `NotificationPort::lock` recebe owner string v7 e devolve PAT string v7; Port e Adapter de Identity serão convertidos juntos, com revalidação do cadastro nos STEPS 04/06 da change UUID.

Futuro `notification_id` próprio usa UUIDv7 estável em retries/redelivery; `resource_id`, quando identifica recurso próprio, também usa UUIDv7. IDs técnicos FCM/SDK, destino, fingerprint, segredo Bearer e generation conservam seus formatos. Evidências históricas de cadastro com owner/PAT bigint e UUID genérico não comprovam esse contrato novo. Transporte/queue/produtores e homologação do gerador Flutter continuam pendentes.

### Estado comprovado do contrato UUIDv7 — 2026-10-15

Os STEPs 04/06/11/12 de `standardize-uuid-v7-identifiers` concluíram backend, integração e aplicação local do contrato alvo acima. Registro/owner/PAT/instalação exigem v7; repetição/rotação preservam o registro e as provas PostgreSQL/HTTP incluem rollback, corridas e cascades. Evidências históricas continuam identificadas em `tasks.md`.

No STEP 13, inspeção somente leitura do cliente `cordato` encontrou `uuid 4.6.0` transitivo no lockfile, sem uso de gerador v7, persistência de instalação ou cadastro `push-registrations` em `lib/`. `MessagingClient` usa `getToken()`/`onTokenRefresh` e distingue Android/iOS, mas isso não homologa o cadastro. A integração UUIDv7 de instalação e payload real continua pendente no cliente. Não há autorização de edição desse repo nem prova de transporte/recepção Firebase por essa inspeção.

### 1. Ownership e fronteiras

Criar `Notifications` como contexto real, proprietário do registro push e do transporte. Não colocar o cadastro em User nem transformar Core em catálogo de regras de notificações.

Responsabilidades propostas:

| Camada/fronteira | Responsabilidade |
| --- | --- |
| Notifications Domain | Invariantes de plataforma, identificador opaco e mensagem limitada, sem Firebase/Laravel |
| Notifications Application | `CreateNotificationUseCase`, `DeleteNotificationUseCase`; futuros `RequestNotificationUseCase` e `SendNotificationUseCase` |
| Notifications Repository | `NotificationRegistrationRepository`: cadastro/locks/update/delete; lookup de envio e remoção condicional ainda futuros |
| Notifications Ports | `NotificationPort::lock()` define a verificação da sessão requerida pelo cadastro; futuros `NotificationTransportPort` e `NotificationDispatchPort` definem envio/publicação |
| Notifications Infrastructure | `EloquentNotificationRepository`, `NotificationModel`; futuros `FirebaseNotificationTransportAdapter`, `QueueNotificationDispatchAdapter`, job fino e provider |
| Notifications Presentation | `CreateNotificationRequest`, `CreateNotificationController`, `DeleteNotificationController` e `NotificationResponse` JSON:API |
| Core Application | Identidade autenticada e transação pelos contratos existentes; contrato de intenção de envio ainda futuro |
| Identity Infrastructure | `NotificationAdapter` de Identity, implementando a capacidade transversal com a política de sessão e estado próprios de Identity |

`UserPort::id()` continua sendo a fonte do proprietário autenticado. `Notifications\Application\Ports\NotificationPort::lock()` resolve o ID da sessão atual e verifica a correspondência entre conta e sessão, existência, validade efetiva, status ativo e e-mail confirmado. O usuário aprovou que Notifications possua esse contrato, enquanto `NotificationAdapter` e seu binding continuam em Identity. A arquitetura permite a Identity Infrastructure importar somente essa interface de Notifications, sem ampliar a dependência para classes concretas ou outros contratos. Para cadastro, fornece verificação bloqueante da sessão dentro da unidade transacional; para processamento, a revalidação imediatamente antes do envio ainda será implementada. Os métodos recebem instantes explícitos, não parâmetros que alterem a política de Identity.

O binding dessa capacidade fica em Identity, preservando sua autoridade. Notifications não importa classes de Identity, não consulta `users` ou Sanctum diretamente e não duplica os limites 30/15/90 dias. O Adapter pode ler essas tabelas e reutilizar `SessionPolicyValueObject` de seu próprio contexto. Foreign keys não introduzem relacionamentos Eloquent entre contextos.

Uma futura capacidade de intenção em Core, separada do `NotificationPort` de sessão pertencente a Notifications, terá implementação em Notifications que recebe intenção explícita e delega ao UseCase de solicitação. Um produtor futuro depende somente do contrato de Core; seu gatilho e binding no fluxo de negócio exigem definição e autorização próprias. Data de Core descreve a intenção transversal; o mapping para Data de Notifications é explícito, sem reutilizar Outputs por coincidência.

Manter `Input`/`Output` tipados, `final readonly`, constructor-only; introduzir Entity/VO apenas onde existirem invariantes reais. Dependências de UseCases seguem Port → UseCase → Repository e nomes pelo papel. Não criar abstração de ORM, de cliente HTTP ou interface para cada UseCase.

### 2. Uma tabela de destinos, não uma tabela de mensagens

Nome aprovado após revisão de nomenclatura: `notifications`. Migration incremental renomeia `push_registrations` e seus índices/constraints, preservando dados. Essa tabela armazena destinos de instalações, não o histórico do canal database Laravel. As classes existentes passam de `Push` para `Notification`, preservando as simplificações do usuário; `NotificationValueObject` é o nome aprovado para o destino. Endpoints/resource type/eventos técnicos continuam no contrato push existente.

| Coluna | Tipo/constraint propostos | Significado |
| --- | --- | --- |
| `id` | UUIDv7, primary key | ID público opaco, gerado pelo backend |
| `user_id` | UUIDv7, FK `users.id`, cascade | Conta proprietária |
| `session_id` | UUIDv7, FK `personal_access_tokens.id`, cascade | Sessão que confirmou o vínculo |
| `installation_id` | UUIDv7, unique | Identidade local da instalação, gerada pelo cliente |
| `provider` | varchar, valor `fcm` | Provedor desta etapa |
| `platform` | varchar, enum fechado | Somente `android` ou `ios`, conforme aprovação do cliente |
| `registration_kind` | varchar, enum fechado | Somente `token` nesta fatia |
| `registration_identifier` | text, ciphertext | Destino recuperável pelo backend para envio |
| `identifier_fingerprint` | char(64), unique | SHA-256 do provedor/tipo/identificador exatos, separados por NUL |
| `generation` | bigint positivo | Versão do vínculo/destino para controlar jobs obsoletos |
| `last_registered_at` | timestamptz | Última sincronização aceita pelo servidor |
| `created_at` / `updated_at` | timestamptz | Auditoria técnica |

Índice de lookup em `user_id` e índice em `session_id`; a unicidade de fingerprint é do projeto Firebase único configurado nesta etapa. Incluir constraints de valores fechados e geração positiva quando aplicáveis. O raw identifier é cifrado em repouso com capacidade Laravel suportada; o fingerprint SHA-256 não depende de chave auxiliar e não é devolvido nem registrado em logs. Sem limite artificial de 255 caracteres para ciphertext/token. Limite de entrada proposto: 4 KiB em bytes ASCII sem whitespace/controle; conferir compatibilidade com SDKs antes de implementar.

Revisão aprovada pelo usuário: remover HMAC e `PUSH_REGISTRATION_HMAC_KEY`, conservando cifragem pela `APP_KEY` e unicidade por SHA-256. O fingerprint continua sensível; sem HMAC, quem conhece um token pode calcular seu fingerprint. A migration incremental recalcula registros existentes na mesma transação com exclusão de escrita concorrente, preservando ciphertext e metadados. Falha de decifragem ou unicidade aborta integralmente; rollback automático não restaura a chave/valores antigos.

Não aplicar trim, lowercase ou qualquer canonicalização ao destino. Tipos incompatíveis são rejeitados, não convertidos entre token e FID. O envelope aceita apenas o tipo aprovado em configuração; a possibilidade futura de adicionar um tipo não significa suporte implementado a ele.

Alternativas rejeitadas:

- Coluna `firebase_token` em `users`: sobrescreve outros dispositivos e não representa vínculo de sessão.
- Array JSON em `users`: dificulta unicidade, escrita concorrente e limpeza seletiva.
- Firestore como cadastro: acrescenta segundo banco sem necessidade para a capacidade.
- `notifications` do canal database: serve a uma inbox, não resolve cadastro dos destinos.
- Ledger/outbox agora: só justificado se houver requisito de recuperação durável de intenções e garantia eventual.

### 3. Contrato HTTP proposto

`POST /api/push-registrations`, nome `notifications.api.push-registrations.register`. Requer Bearer Sanctum, conta ativa/verificada e a cota autenticada compartilhada existente de 60/min por conta. Não ampliar implicitamente a lista de rotas que estendem sessão: sincronização push não é atividade elegível de extensão nesta proposta.

```json
{
  "data": {
    "type": "push-registrations",
    "attributes": {
      "installation_id": "0199e800-0000-7000-8000-000000000001",
      "platform": "android",
      "registration_kind": "token",
      "registration_identifier": "<identificador obtido pelo SDK FCM aprovado>"
    }
  }
}
```

`token` é o único perfil aprovado para o cadastro desta fatia. Documento fechado: `data.id`, `relationships`, `user_id`, `session_id`, `provider`, timestamps e geração não são entradas editáveis. Campos desconhecidos, ausentes ou inválidos produzem `422` com pointers, sem eco do segredo.

Primeiro cadastro: `201`. Mesma instalação do mesmo proprietário, inclusive atualização: `200`. Mesma requisição repetida não cria registro adicional. Todos os sucessos representam `push-registrations`, com `id`, `installation_id`, `platform`, `provider` e `last_registered_at`; não devolvem destino, fingerprint, sessão nem geração. `Cache-Control: no-store`. Não enviar `Location` para um GET inexistente.

`DELETE /api/push-registrations/{registration}`, nome `notifications.api.push-registrations.delete`: proprietário autenticado, mesma proteção/cota. Registro próprio existente: `204`; já inexistente ou pertencente a outra conta: `404` uniforme em JSON:API. ID malformado também é `404`. Repetição é idempotente quanto ao estado, sem promessa de mesmo status. Não haverá GET/listagem nem endpoint público/interno HTTP de disparo.

Mapeamento: `401` credencial ausente/inválida; `403` conta não apta; `404` remoção fora do ownership; `409` conflito de instalação/destino; `422` documento; `429` cota + `Retry-After`; `5xx` falha operacional sanitizada. Os erros não retornam identidade da conta conflitante nem o identificador informado.

### 4. Idempotência, rotação e disputa

O UseCase delimita com `TransactionPort` a verificação bloqueante da sessão e a escrita do registro. Ordem de lock: sessão, depois registros em ordem determinística quando mais de um for envolvido. Constraints permanecem a última barreira para registros ainda inexistentes; violação conhecida é traduzida em conflito ou releitura idempotente, nunca em sucesso inventado ou `500` por disputa prevista.

- Mesmo owner/instalação/destino/plataforma/sessão: atualizar `last_registered_at`, preservar ID e geração.
- Rotação do destino ou mudança de plataforma/sessão na mesma instalação e mesmo owner: preservar ID, substituir estado e incrementar geração atomicamente.
- Destino já ligado a outra instalação, mesmo do mesmo usuário: `409`. Não fundir destinos silenciosamente; remover o vínculo anterior ou corrigir a identidade local.
- Instalação/destino de outro owner: `409` uniforme. Conhecer um token ou UUID não autoriza transferência.
- Cadastro concorrente com mesmos dados: um `201`, o outro `200`, uma linha.
- Rotações concorrentes diferentes para uma instalação: serializar; o último commit aceito define o destino. O servidor não sabe qual callback do cliente é mais recente. O cliente serializa uploads de rotação e sincroniza novamente ao iniciar/retomar.
- Falha/rollback: preservar integralmente o vínculo anterior; cadastro não publica jobs nem chama Firebase.

### 5. Ciclo de vida de conta, sessão e instalação

O vínculo com `session_id` evita depender de uma requisição DELETE feita pelo cliente antes de SignOut. A FK cascade remove os registros ligados ao PAT excluído pelo SignOut atual e pelo pruning oficial; outras sessões/instalações permanecem. Exclusão de conta remove todos por FK de `user_id`, sem chamada externa na transação.

O cadastro bloqueia e revalida a sessão antes de persistir. Se logout venceu a corrida, não recriar registro. Se cadastro confirmou primeiro, a exclusão posterior da sessão remove o registro. Uma FK prova existência, não ownership: o Adapter precisa provar que a sessão pertence ao `user_id` autenticado.

Sessão vencida ainda persistida não é destino elegível; o processamento reavalia a política efetiva de Identity independentemente de pruning. Conta bloqueada/não verificada também não recebe novos envios. `last_registered_at` não substitui validade de sessão e não a estende.

Troca de conta na mesma instalação: realizar SignOut online/remover vínculo da conta anterior, limpar estado local, autenticar nova conta e cadastrar. Se a instalação continuar vinculada ao outro owner, responder conflito; não implementar transferência baseada somente em UUID/token. Logout offline limpa o estado local, mas não informa o backend imediatamente: a instalação continua vinculada até revogação/expiração. O app deve evitar exibir conteúdo de conta anterior; a mensagem inicial será genérica. Revogação local de permissão requer sincronização de remoção quando houver acesso online.

Defaults: elegível somente se `last_registered_at > now - 60 dias`; no limite exato de 60 dias, descartar envio. Registro stale não é apagado por tempo nem exige Scheduler nesta etapa: um novo cadastro reativa sua frescura se a sessão for válida. Remoção física ocorre por DELETE, cascade ou erro permanente do FCM.

### 6. Solicitação e processamento assíncrono

O contrato interno recebe `user_id` UUIDv7 explícito, `notification_id` UUIDv7 estável para correlação, título/corpo genéricos, destino de navegação estruturado e instantes explícitos `requested_at`/`expires_at`. `resource_id` opcional usa UUIDv7 quando referencia recurso próprio. Não aceita destinatário determinado por payload livre, URL arbitrária, token bruto, IDs de outra conta, valores financeiros ou descrição de despesa na mensagem de tela bloqueada.

Limites propostos: título até 80 caracteres, corpo até 240 e `data` composto apenas de strings permitidas (`notification_id`, `action`, `resource_id` opcional). A serialização final, incluindo overhead e escapes, deve permanecer dentro do limite FCM documentado para envio individual (4 KiB). Action é catálogo fechado a aprovar com o primeiro evento; `resource_id` não é autorização e a tela de destino reconsulta a API autenticada. `expires_at` deve ser futuro e no máximo 1 hora após `requested_at`; reavaliar a expiração no worker e traduzir TTL restante por plataforma.

O futuro `RequestNotificationUseCase` obtém snapshot de destinos elegíveis e solicita um job por registro, com owner, ID, geração esperada, ID da mensagem, conteúdo mínimo e expiração. O token bruto não vai para Redis/failed jobs; ele é recuperado na execução. A futura implementação do contrato de intenção orquestra essa capacidade, não faz transporte inline. A fila será `push-notifications` na conexão Redis aprovada, sem fallback sync.

O produtor deve invocar a capacidade depois de seu commit, usando o mecanismo existente, nunca dentro de callback transacional que possa repetir. Sem destinos: resultado `no_targets`, zero jobs, zero chamada FCM. Resultado da solicitação informa contagens enfileiradas/descartadas e falha parcial de publicação, sem afirmar entrega. Redis indisponível resulta em falha explícita. Se alguns jobs foram publicados, não republicar o lote inteiro automaticamente.

O job fino chamará `SendNotificationUseCase`. Antes de cada tentativa, reler registro por owner/ID, conferir geração e frescura, validar sessão/conta pela futura capacidade de elegibilidade e prazo da mensagem. Ausência, mudança, invalidez ou expiração encerram o job como `skipped`, sem envio. Não redirecionar uma mensagem preparada para o destino novo.

FCM é chamado fora de transação PostgreSQL e sem lock aberto durante rede. Não há garantia de impedir envio já em voo quando logout/rotação/exclusão acontece após a última checagem. Mensagens já aceitas pelo provedor não são recolhidas pelo backend. Essa janela é explícita e não deve ser escondida por teste sequencial.

### 7. Transporte, falhas e retries

O futuro `FirebaseNotificationTransportAdapter` implementará `NotificationTransportPort`, mapeando resultados para tipos próprios (`accepted`, `invalid_registration`, `retryable_failure`, `permanent_failure`). `accepted` significa exclusivamente que FCM aceitou o envio, acompanhado de message ID técnico quando disponível. Nunca escrever `delivered` ou `read` por causa dessa resposta.

Perfil inicial: um projeto Firebase server-side. Preferir HTTP v1 com autenticação OAuth2 suportada ou pacote mantido compatível com PHP/Laravel, após confirmar endpoints/SDKs. Não inventar JWT/OAuth nem usar API legacy/server key. FID só será aceito se SDK cliente, envio server-side e biblioteca escolhida tiverem compatibilidade comprovada; não substituir `token` por `fid` por suposição.

| Falha | Tratamento |
| --- | --- |
| Destino `UNREGISTERED`/equivalente documentado | Remover somente o registro e a geração que originaram a tentativa |
| `INVALID_ARGUMENT` | Classificar pelos detalhes; só invalidar destino se houver prova específica de destino inválido e payload válido |
| Payload inválido, projeto/sender incompatível, permissão/credencial inválida | Falha permanente/configuração, sem apagar destinos válidos e sem retry cego |
| Quota, `429`, indisponibilidade `5xx` | Retry limitado com backoff e `Retry-After` quando presente |
| Timeout/erro de conexão | Retry limitado; aceitação anterior pode ser desconhecida e gerar duplicação |

Remoção pós-erro usa operação compare-and-delete por `id`, `user_id` e `generation`: erro do token antigo não apaga rotação recente. Repetição dessa remoção após exclusão prévia é no-op. Cada job é independente: um destino inválido/falho não interrompe destinos saudáveis nem republica os já aceitos.

Defaults propostos: até 5 tentativas totais por job; atrasos mínimos de 10, 30, 120 e 300 segundos, com jitter e respeito ao mínimo específico recomendado para quota pelo Firebase. `Retry-After` aumenta o atraso; nunca reduz o mínimo. Se próxima tentativa não couber em `expires_at`, terminar sem chamada. Timeout de conexão 3 s, de request 10 s; timeout do job maior que o request e `retry_after` Redis maior que timeout do job. Concluir esses valores com a documentação atual do método de envio escolhido.

Não existe deduplicação durável ou garantia exactly-once: timeout após aceitação e redelivery da queue podem duplicar. `notification_id` permite deduplicação de UX no cliente, quando suportada, mas não impede necessariamente banner gerado pelo sistema. Não retryar o lote inteiro como compensação.

### 8. Configuração, segredos e observabilidade

Credencial via arquivo privado fora do repositório ou mecanismo server-side suportado; só o path/referência entra na configuração. Projeto e método de identificação são explícitos por ambiente. Secret não aparece em fixtures, exemplos, fonte, cliente, resposta ou logs. Não fazer envio FCM real na suíte comum.

Cifrar o destino recuperável pela `APP_KEY`, usar fingerprint SHA-256 estável e restringir acesso ao banco/Redis/failed jobs. Rotação de chave de cifragem deve preservar leitura dos dados vigentes; o fingerprint independe dessa chave. Mudanças no algoritmo/preimage exigem recalcular fingerprints e validar unicidade atomicamente. Não trocar chave e tornar destinos ilegíveis silenciosamente.

Eventos técnicos: `push.registration.created`, `push.registration.updated`, `push.registration.deleted`, `push.requested`, `push.accepted`, `push.skipped`, `push.retry_scheduled`, `push.failed` e `push.registration.invalidated`. Campos permitidos: IDs internos, `notification_id`, plataforma, geração, contagens, tentativa, motivo normalizado, latência, provider message ID e correlação. Nunca incluir token/FID/fingerprint, Bearer, credencial, título/corpo, descrição/valor financeiro, documento HTTP, resposta FCM integral ou exception com request/headers sensíveis.

Eventos de mutação só após commit; falha do logger não muda sucesso de cadastro/remoção. Correlacionar publicação e worker por `notification_id` e ID de origem quando presente, sem herdar Context entre jobs. Não alegar métricas de entrega a partir de métricas de aceitação. Retenção de payloads mínimos da queue segue a política operacional aprovada; retenção de histórico não é criada.

## Risks / Trade-offs

- **Versão Flutter e transporte ainda não comprovados** → cadastro token FCM Android/iOS autorizado e implementado nesta fatia; não ativar transporte antes da comprovação server-side e homologação do cliente, sem anunciar suporte a FID.
- **Vínculo a sessão encerra push quando sessão expira** → opção A aprovada pelo usuário; notificações fora de sessão exigem nova decisão de produto e revisão desta spec.
- **Logout offline** → backend só conhece revogação quando comunicada; payload genérico e higiene local são necessários.
- **Corrida após revalidação** → não manter transação aberta durante FCM; documentar impossibilidade de recolher mensagem em voo.
- **Commit confirmado, Redis indisponível** → registrar intenção não publicada e conservar operação de negócio; não prometer recuperação automática. Outbox requer outra decisão.
- **Publicação parcial** → retorno/diagnóstico com contagens, sem repetir destinos aceitos como lote.
- **Timeout/redelivery** → duplicação possível, ID estável e deduplicação de UX; sem exactly-once.
- **FK ao PAT cria acoplamento de schema** → limitar à referência/cascade; sem imports entre contextos, nem acesso direto de Notifications ao estado de Identity.
- **Callback de rotação atrasado** → uploads serializados pelo cliente e ressincronização; esta etapa não inventa ordem temporal entre requests independentes.
- **Segredo em erros de SDK** → normalizar exceções na borda e comprovar sanitização de logs/failed jobs.

## Migration Plan

1. Resolver as perguntas bloqueadoras e aprovar explicitamente implementação/dependência/perfil cliente.
2. Inspecionar configuração, schema detalhado, rotas e APIs instaladas apenas nas áreas afetadas; verificar lifecycle de PAT e suporte do método FCM escolhido.
3. Criar migration incremental com constraints/índices e cascades, sem modificar tabelas de identidade ou dados existentes. Classificar a nova tabela no cleanup.
4. Publicar schema antes do código que o usa. No Lerd, executar migrations pendentes pelo fluxo permitido antes de verificar HTTP/worker; não usar `migrate:fresh`.
5. Configurar projeto, segredo privado do transporte, cifragem, fingerprint SHA-256, perfil cliente e queue. Reiniciar o worker com o código novo, verificando timeouts/retry_after.
6. Liberar API de cadastro aos clientes aprovados; validar rotação, logout, expiração e múltiplos dispositivos em ambiente de homologação.
7. Fazer smoke test FCM real somente em projeto/instalação de teste consentidos; demonstrar aceitação no servidor e recepção no cliente separadamente. Não enviar para usuários reais como teste.
8. Habilitar o primeiro produtor somente após aprovar evento/texto/navigation e comprovar fronteira after-commit; se o gatilho ampliar escopo, atualizar artefatos antes de implementar.

Rollback operacional: desabilitar produtores, pausar o worker push, remover/desabilitar as novas rotas e implantações, manter os registros cifrados até decisão de schema. Não revogar sessões existentes por rollback. A reversão da migration remove os novos destinos e deve ser explícita; não apagar a tabela automaticamente para reverter código. Jobs remanescentes não podem ser consumidos por código incompatível nem redirecionados a outro projeto Firebase.

## Open Questions

### Bloqueadoras antes de implementar o contrato definitivo

1. **Homologação do perfil cliente:** Android/iOS, Flutter oficial e contrato de cadastro exclusivamente token FCM foram confirmados. Informar versões de `firebase_core`/`firebase_messaging` e exemplo real do documento enviado, com destino redigido; comprovar integração `getToken()`/`onTokenRefresh`, permissão, UUID local e compatibilidade do transporte antes do envio real. Não bloqueia a fatia de cadastro explicitamente autorizada; não há implementação de frontend autorizada nesta mudança.
2. **Política de sessão — resolvida:** opção A aprovada, vínculo ao PAT e suspensão de novos pushes ao expirar/revogar sessão. Não há requisito aprovado de lembretes sem sessão válida.
3. **Integração server-side:** qual projeto Firebase para cada ambiente, método de autenticação e transporte/pacote compatível? Aprovar dependência se necessária e confirmar compatibilidade com o perfil dos clientes.

### Bloqueadoras para ativar disparo de produto

4. **Primeiro gatilho:** qual evento deve disparar push, para quem e em qual instante? Não presumir cadastro de despesa, classificação, insight ou lembrete.
5. **Mensagem/navigation:** aprovar título/corpo genéricos, catálogo de actions/deep links e eventual `resource_id` autorizado. Confirmar tratamento do cliente após troca de conta/logout offline.
6. **Homologação:** disponibilizar instalação de teste e projeto apropriado para validar recepção real e requisitos específicos de iOS/APNs ou web/VAPID/service worker, conforme a plataforma aprovada.

### Não bloqueadoras para esta proposta documental

7. **Inbox/histórico:** fora do escopo proposto. Se requerido, criar capacidade e modelo separados para conteúdo/read_at e política de retenção; isso não substitui os destinos da tabela `notifications`.
8. **Entrega eventual forte:** sem outbox nesta etapa; confirmar se lacuna commit/queue e duplicações são aceitáveis antes de prometer garantia ao produto.
9. **Defaults operacionais:** revisar frescura de 60 dias, validade de 1 hora e retries/timeouts com o perfil FCM escolhido; ajustes de comportamento durável devem atualizar specs/design/tasks.
