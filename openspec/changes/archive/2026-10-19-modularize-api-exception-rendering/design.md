## Context

O composition root atual mistura configuração Laravel, mapeamentos de três contextos e serialização JSON:API. O Laravel 13 já oferece `render`, `respond`, `dontReport` e `shouldRenderJsonWhen`; não é necessário substituir seu exception handler. A documentação foi consultada via Boost, e o código instalado de `Handler::renderViaCallbacks` confirma que o primeiro retorno não nulo vence. Por isso, o segundo registro de `EmailAlreadyUsedException` não define o comportamento efetivo.

Referências: `ARCHITECTURE.md`, guidelines de arquitetura/Presentation/JSON:API, `authentication` (Erros seguem JSON:API), `expense-metrics` (erros próprios de query), mudança arquivada `2026-09-26-limit-public-authentication-attempts` (preservação de Retry-After) e mudança ativa `add-firebase-push-notifications/specs/push-registration/spec.md`. Não se altera o escopo dessas mudanças.

## Goals / Non-Goals

**Goals:** bootstrap declarativo, construção única do documento de erro, tradução pertencente ao contexto e compatibilidade observável demonstrável.

**Non-Goals:** novas exceções de negócio, uniformização editorial de mensagens existentes, nova política de reporte, novo negociador de conteúdo, alteração de rotas/middlewares/DI de UseCases, tratamento de sucesso ou substituição de respostas próprias de Insights/Metrics. Não criar interfaces, hierarquias Base, dispatcher próprio ou dependências.

## Decisions

### 1. Usar composição explícita sobre os hooks nativos

Proposta mínima: arquivos `app/<Contexto>/Presentation/Http/Exceptions/exceptions.php` retornando closures tipadas que recebem `Illuminate\Foundation\Configuration\Exceptions`. `bootstrap/app.php` carrega e invoca explicitamente os registros de Identity, Expense, Notifications e Core dentro de `withExceptions`. Os arquivos têm `strict_types`, imports explícitos e não são descobertos automaticamente. Não criam classes com sufixos novos nem dependem de Service Locator.

Os registros contêm callbacks nativos por tipo; não um `match` global sobre Throwable. O bootstrap permanece composition root e não guarda mensagens, seleção de campos ou regras de registro push. Routing e middleware permanecem como estão: mover essas configurações não faz parte desta mudança.

Alternativas rejeitadas: mover o bloco inteiro para um arquivo global (mantém acoplamento e repetição); criar uma Strategy por exceção ou Chain of Responsibility própria (o framework já despacha por tipo); reintroduzir um Handler customizado ou registrar por providers sem necessidade (aumenta a superfície e torna ordem menos evidente).

### 2. Uma Response compartilhada exclusivamente de transporte

`App\Core\Presentation\Http\Responses\JsonErrorResponse` concentra envelope `errors`, media type, status textual e construção de um ou vários erros. Estende `JsonResponse`, sem simular recursos `data` via `JsonApiResource`. Os chamadores fornecem títulos, detalhes e origens; a Response não inspeciona exceções ou conhece contextos consumidores. O nome inicial `JsonApiErrorResponse` foi simplificado por solicitação do usuário durante a implementação; as evidências históricas abaixo conservam os nomes usados em cada etapa.

Para normalização final, a montagem do documento é reutilizada sem descartar status e headers da resposta original. Não criar DTO de Application ou Value Object de Domain para representar HTTP.

O compartilhamento usa permissão explícita e restrita para esta classe de Core nas verificações de fronteira e documentação arquitetural. Não libera namespaces inteiros nem imports entre contextos de negócio. A atualização pontual foi implementada após autorização do usuário.

### 3. Ownership e precedência

| Owner | Responsabilidade |
| --- | --- |
| Identity Presentation | Credenciais, aptidão/status da conta, e-mail, senha, nome, avatar e usuário ausente |
| Expense Presentation | Despesa/owner ausentes, despesa inválida e cursor inválido |
| Notifications Presentation | Conflito, registro ausente/inválido e 404 específico do DELETE de push registrations |
| Core Presentation | Validação Laravel, 404 genérico, fallback HTTP e decisão transversal de JSON |

Registrar o callback específico de `NotFoundHttpException` de Notifications antes do genérico de Core. Fora do método/caminho já tratados ele retorna null, permitindo o fallback. Não criar exceção de negócio em Core para descobrir sua mensagem: Notifications pode reutilizar seu próprio contrato atual.

Preservar os registros tipados existentes inclusive seu alcance atual: os renderers de negócio hoje não possuem guard `api/*`, e a refatoração não deve introduzir um silenciosamente. O guard de validação/404/fallback continua restrito a `api/*`; `shouldRenderJsonWhen` continua `api/* || expectsJson()`. Não confundir seleção de JSON com aplicação obrigatória de JSON:API fora da API.

### 4. Baseline explícito e duplicação resolvida

Antes de mover os registros, caracterizar o comportamento efetivo e registrar a evidência na tarefa correspondente:

- Identity: `InvalidCredentialsException` → 401; `UnverifiedEmailException` e `InactiveUserException` → 403; `EmailAlreadyUsedException` → 409 com pointer de e-mail; `UserNotFoundException` → 404; `InvalidPasswordException`, `InvalidEmailException`, `InvalidNameException`, `InvalidAvatarException` → 422, mantendo a presença ou ausência atual de pointers. Preservar os três ramos de status de conta, sem trocar textos como `User não encontrado`.
- Expense: duas exceções de ausência → 404; despesa inválida e cursor → 422, preservando `/page/cursor` exatamente, sem corrigi-lo para `source.parameter` nesta refatoração.
- Notifications: conflito → 409, ausência → 404, inválido → 422 com pointer derivado do campo; DELETE malformado/alheio/ausente mantém o mesmo 404.
- Validação: cada mensagem gera um erro, na ordem fornecida, com pointer derivado do campo por substituição de pontos por barras.
- Fallback: preservar todos os ramos atuais (400, 401, 403, 404, 405, 406, 408, 409, 410, 413, 415, 419, 422, 429, 500, 502, 503, 504) e defaults de demais 4xx/5xx, com títulos e detalhes atuais. Respostas já JSON:API não são reescritas.
- Reporte: manter somente as exclusões explícitas atuais (três exceções de Notifications, cursor inválido, conta inativa, senha inválida, e-mail usado, credenciais inválidas e e-mail não confirmado), além do comportamento padrão Laravel. Não expandir `dontReport` para todo erro de negócio.

Remover somente o segundo registro de e-mail usado; conservar status 409, título `E-mail já utilizado`, detalhe da exceção e `/data/attributes/email`. Nenhum cenário espera executar o callback morto.

### 5. Segurança e compatibilidade da resposta final

O fallback continua emitindo mensagens públicas sanitizadas, nunca `getMessage()` de falhas desconhecidas. Preservar headers como `Retry-After`, `Allow`, autenticação e cache quando presentes; atualizar Content-Type e remover Content-Length obsoleto ao substituir o corpo. A normalização pelo hook `respond` trata respostas do exception handler, não passa a interceptar toda resposta HTTP da aplicação.

Não mudar reporting, trace/request correlation, tradução de erros próprios de query (`source.parameter`) ou o caminho de sucesso. Mensagens de exceções já expostas são preservadas, não generalizadas para qualquer Throwable.

## Risks / Trade-offs

- [Mover código sem reduzir repetição] → Response compartilhada e revisão do bootstrap sem regras de erro embutidas.
- [Ordem altera o 404 específico] → Registros explícitos, callback específico antes do genérico e cenários de precedência.
- [Trocar resposta perde headers ou reescreve JSON:API próprio] → Provas de Retry-After/Allow e preservação de documento/header já normalizado.
- [Melhoria incidental quebra contrato] → Não corrigir textos, pointers ou alcance não API; divergência exige decisão separada.
- [Mudanças paralelas em Notifications] → Reconciliar a baseline com a fatia efetivamente implementada antes do apply, sem assumir tarefas pendentes de envio.

## Migration Plan

Sem migration de schema, dados, configuração de ambiente ou serviços; atomicidade e concorrência de negócio não são alteradas. Após autorização de apply: caracterizar, extrair construção, mover registros e verificar contratos e fronteiras. Publicação é exclusivamente de código. Rollback consiste em reverter somente o diff desta mudança, preservando trabalho paralelo; não exige restauração de banco ou limpeza de Redis.

## Open Questions

Nenhuma decisão de produto bloqueadora identificada. A forma final da API da Response é detalhe local, desde que cumpra os requisitos. Qualquer divergência entre baseline e contrato vigente que demande mudar produto bloqueia essa parte do apply até decisão do usuário; não legitima enfraquecer assertions.

## Baseline verificada — Step 1 (2026-10-19)

Inventário reconciliado com `bootstrap/app.php` antes de qualquer extração, Laravel 13.34.0 / PHP 8.5. Nenhuma divergência de produto identificada. Cada linha abaixo tem expectativa literal de título, detalhe, status e origem no dataset `tests/Feature/<Owner>/Presentation/Http/ExceptionRenderingHttpTest.php`; os detalhes recebidos das exceções de Domain usam mensagens sentinela explícitas. O documento completo é comparado, incluindo ausência de `data` e de membros opcionais não previstos.

| Owner / exceção ou ramo | HTTP | Título | Origem | Reportável |
| --- | --- | --- | --- | --- |
| Identity / InvalidCredentials | 401 | Credenciais inválidas | ausente | não |
| Identity / UnverifiedEmail | 403 | E-mail não confirmado | ausente | não |
| Identity / InactiveUser Pending | 403 | Conta pendente | ausente | não |
| Identity / InactiveUser Blocked | 403 | Conta bloqueada | ausente | não |
| Identity / InactiveUser Active | 403 | Acesso negado | ausente | não |
| Identity / EmailAlreadyUsed | 409 | E-mail já utilizado | pointer `/data/attributes/email` | não |
| Identity / InvalidPassword | 422 | Dados inválidos | pointer `/data/attributes/password` | não |
| Identity / UserNotFound | 404 | User não encontrado | ausente | sim |
| Identity / InvalidEmail | 422 | Dados inválidos | ausente | sim |
| Identity / InvalidAvatar | 422 | Dados inválidos | pointer `/data/attributes/avatar` | sim |
| Identity / InvalidName | 422 | Dados inválidos | ausente | sim |
| Expense / InvalidExpenseCursor | 422 | Cursor inválido | pointer `/page/cursor` | não |
| Expense / ExpenseOwnerNotFound | 404 | User não encontrado | ausente | sim |
| Expense / ExpenseNotFound | 404 | Despesa não encontrada | ausente | sim |
| Expense / InvalidExpense | 422 | Dados inválidos | ausente | sim |
| Notifications / NotificationRegistrationConflict | 409 | Conflito de registro push | ausente | não |
| Notifications / NotificationRegistrationNotFound | 404 | Registro push não encontrado | ausente | não |
| Notifications / InvalidNotificationRegistration | 422 | Registro push inválido | pointer `/data/attributes/{field}` | não |

Todos os renderers da tabela são exercitados por HTTP dentro e fora de `api/*`, com `Accept: text/html`, sem novo guard. Detalhes de conta são os três literais do match atual, não a mensagem genérica da exceção. As demais traduções conservam `getMessage()`. Para Notifications, há provas explícitas de `field=installation_id` e `field=registration_identifier`; não se pressupõe envio FCM ou funcionalidades ainda pendentes da change paralela.

Ordem efetiva: três renderers de Notifications → cursor → credenciais → e-mail não confirmado → conta → primeiro e-mail usado → senha → usuário ausente → owner ausente → despesa ausente → despesa inválida → segundo e-mail usado (inalcançável) → e-mail inválido → avatar → nome → NotFoundHttpException → ValidationException → respond. `Handler::renderViaCallbacks` instalado retorna o primeiro callback não nulo. O duplicado permanece intocado neste step; o teste de conflito fixa a resposta do primeiro callback, com pointer.

O 404 atual ainda é um único callback com guard `api/*` e seleção por `DELETE && api/push-registrations/*`. Validação e normalização final também têm guard `api/*`; a última preserva Content-Type iniciado por `application/vnd.api+json`. `shouldRenderJsonWhen` permanece `api/* || expectsJson()`. `dontReport` contém exatamente as nove classes não reportáveis da tabela (os três ramos de conta são uma classe), além das exclusões nativas Laravel. As verificações `shouldReport` usam o handler real, sem fake que force silenciamento; Core também observa a chamada de reporte de uma falha inesperada e a ausência de chamada para HTTP/validação ignorados pelo framework.

### Mapa de cenários e lacunas preenchidas

| Requisito | Evidência existente / lacuna | Evidência da baseline |
| --- | --- | --- |
| ERR-01, ERR-02 | SignInHttpTest já compara credenciais exatamente; status Pending/Blocked e verificação tinham provas parciais. SignUpHttpTest/UuidUserHttpTest cobrem transporte e ownership, não todos os renderers de Domain. | Identity/ExceptionRenderingHttpTest fixa 11 traduções/ramos × dois caminhos, inclusive Active e conflito com pointer. |
| ERR-01, ERR-02 | ExpenseSortCursorHttpTest prova rejeição antes da leitura e `/page/cursor`, sem todos os textos e ausências. | Expense/ExceptionRenderingHttpTest fixa quatro traduções × dois caminhos. |
| ERR-02, ERR-05 | NotificationRegistrationHttpTest já prova conflito, validação, exclusão alheia/ausente/malformada uniforme e rejeição antes de lookup; igualdade entre respostas não fixava o texto esperado. | Notifications/ExceptionRenderingHttpTest fixa traduções e campos × dois caminhos. A jornada existente agora também compara exatamente o 404 alheio que serve de referência aos ausentes/malformados. |
| ERR-03 | Não havia prova focada da multiplicidade/ordem da tradução global. | Core/ExceptionRenderingHttpTest fornece duas mensagens de senha e uma de e-mail, comparando lista ordenada e pointers. |
| ERR-04 | Havia Retry-After no quota de Notifications e falha operacional sanitizada em SignInHttpTest, mas não catálogo completo/defaults e remoção de Content-Length. | Core/ExceptionRenderingHttpTest fixa 18 códigos catalogados + 418/507, 429 com Retry-After=37, Allow/WWW-Authenticate/cache, remoção de Content-Length, 405 real e 500 inesperado mesmo com debug ativo. |
| ERR-05 | MonthlyInsightsFiltersHttpTest e ExpenseMetricsHttpTest já verificam erros próprios de query com parameter, sem provar isoladamente o hook final para documento pronto. | Core/ExceptionRenderingHttpTest entrega documento pronto através de renderer temporário ao hook real, comparando bytes, parâmetros, code/meta, status e headers. Cobre também 404 específico antes do controller, genérico e outro método. |
| ERR-06 | Faltavam provas explícitas do alcance não API e da seleção de reporte. | Datasets dos três owners verificam escopo e shouldReport; Core prova HTML/JSON para 404, redirect/JSON para validação, reporte inesperado e exclusões nativas. |

As rotas, callbacks de teste e configuração debug são locais à aplicação recriada por cenário; nenhum endpoint de produto, binding global, listener persistente ou suporte compartilhado foi acrescentado. Na primeira execução, um teste de headers usava HttpResponseException lançado diretamente na rota: `Illuminate\Routing\Route::run` o intercepta antes do handler e o teste falhou (31/32 em Core). O arranjo foi corrigido para um renderer temporário de HttpException, garantindo passagem real por `respond`, também no teste de documento pronto. Não houve correção de produto nem relaxamento do contrato.

### Execuções isoladas e limites

Cada linha foi executada por `lerd composer test -- <arquivo> --compact`, via MCP `exec/composer`, com preflight e migrations incrementais em banco exclusivo da execução. Não foi migrado nem alterado o banco operacional. Resultados finais:

| Arquivo sob `tests/Feature/` | Testes | Assertions |
| --- | ---: | ---: |
| Core/Presentation/Http/ExceptionRenderingHttpTest.php | 32 | 146 |
| Identity/Presentation/Http/ExceptionRenderingHttpTest.php | 22 | 110 |
| Expense/Presentation/Http/ExceptionRenderingHttpTest.php | 8 | 40 |
| Notifications/Presentation/Http/ExceptionRenderingHttpTest.php | 8 | 40 |
| Notifications/Presentation/Http/NotificationRegistrationHttpTest.php | 47 | 292 |
| Identity/Presentation/Http/SignInHttpTest.php | 11 | 115 |
| Identity/Presentation/Http/SignUpHttpTest.php | 17 | 115 |
| Identity/Presentation/Http/UuidUserHttpTest.php | 15 | 75 |
| Expense/Presentation/Http/ExpenseSortCursorHttpTest.php | 49 | 744 |
| Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php | 41 | 255 |
| Metrics/Presentation/ExpenseMetricsHttpTest.php | 91 | 859 |

Total de cenários distintos nessas execuções finais: 341 testes / 2791 assertions, todos aprovados, sem skips reportados. Pint `--dirty --format agent` passou; os quatro arquivos novos foram novamente executados isoladamente após Pint. OpenSpec validado estritamente. Não foi executado gate completo/paralelo nativo: nenhum suporte compartilhado ou código de produção foi alterado. A matriz prova somente a baseline; ownership/composição futuros, remoção do callback morto e integração pós-extração continuam pendentes nos Steps 2–4. Não há alegação de change concluída ou arquivável.

## Construção compartilhada verificada — Step 2 (2026-10-19)

`Core\Presentation\Http\Responses\JsonApiErrorResponse` estende o `Illuminate\Http\JsonResponse` instalado. O construtor recebe lista de erros e status HTTP; usa `document()` para adicionar status textual a cada erro, preservando a ordem, os textos e os membros opcionais recebidos, sem acrescentar `data`. `document()` também expõe o mesmo envelope como array, sem container ou efeitos sobre uma resposta existente, para reutilização futura pelo hook final. A classe não escolhe mensagens, não inspeciona exceções, não conhece consumidores e não registra bindings.

A permissão em `ContextBoundariesTest.php` foi acrescentada somente para a classe exata, exclusivamente na Presentation de Identity, Expense e Notifications. Domain, Application, Infrastructure, Insights e Metrics não receberam novas permissões. `ARCHITECTURE.md` documenta esse limite; não há liberação de namespace nem dependência entre contextos de negócio.

Evidência ERR-01/ERR-03/ERR-04: `tests/Unit/Core/Presentation/Http/Responses/JsonApiErrorResponseTest.php` prova um erro em dez status, lista ordenada de quatro erros, múltiplas mensagens para um campo, pointers intactos (inclusive `/page/cursor`), parameter, membros id/code/links/meta, Unicode, ausência de membros implícitos, status textual, media type e igualdade entre `document()` e o construtor sem mutar a entrada. Executa sem bootstrap Laravel/PostgreSQL/Redis: 13 testes / 45 assertions.

Evidência ERR-02: `tests/Unit/Architecture/ContextBoundariesTest.php` passou com 30 testes / 504 assertions. Revisão do diff confirma permissão restrita e ausência de alterações no bootstrap, renderers, rotas, middleware, providers e suporte compartilhado.

Comandos via MCP Lerd, com cada arquivo executado isoladamente pelo launcher:

- `lerd composer test -- tests/Unit/Core/Presentation/Http/Responses/JsonApiErrorResponseTest.php --compact`
- `lerd composer test -- tests/Unit/Architecture/ContextBoundariesTest.php --compact`
- `lerd composer test -- tests/Feature/<Core|Identity|Expense|Notifications>/Presentation/Http/ExceptionRenderingHttpTest.php --compact` (quatro invocações; respectivamente 32/146, 22/110, 8/40 e 8/40 testes/assertions).
- Pint `--dirty --format agent`, também com seleção explícita dos três arquivos PHP desta etapa; todos os seis arquivos de testes acima repetidos após a última formatação.

Resultado final desta etapa: 113 testes / 885 assertions aprovados, sem skips reportados. Feature usou o preflight com migrations incrementais em bancos exclusivos; os dois arquivos Unit não provisionaram banco. A baseline HTTP conserva seu comportamento porque a Response ainda não foi conectada aos renderers. A extração e o consumo de `document()` no hook final continuam em 3.1–3.4; preservação pós-integração permanece no Step 4. Não houve mudança de suporte compartilhado, execução da suíte completa/paralelo nativo, commit ou arquivamento.

## Extração integrada verificada — Step 3 (2026-10-19)

Os quatro arquivos `app/<Identity|Expense|Notifications|Core>/Presentation/Http/exceptions.php` retornam closures tipadas que registram os hooks nativos. `withExceptions` agora contém somente quatro cargas/invocações explícitas, em ordem Identity → Expense → Notifications → Core. O bootstrap não importa mais exceções de negócio nem contém mensagens, montagem de erros, seleção de campos ou a particularidade de push. Foi acrescentado `strict_types`; os blocos completos `withRouting` e `withMiddleware` foram comparados textualmente com HEAD e permanecem idênticos.

Identity usa a Response compartilhada, conserva os três ramos de conta, todos os textos/pointers e as cinco exclusões de reporte. Há somente um renderer de EmailAlreadyUsedException, com o pointer do primeiro registro efetivo; somente o segundo registro morto foi removido. Expense conserva os quatro mapeamentos e a exclusão de cursor, inclusive seu pointer `/page/cursor`. Os renderers tipados desses contextos e de Notifications continuam sem guard de API.

Notifications conserva as três exclusões de reporte e os três mapeamentos. Seu callback de NotFoundHttpException retorna null fora de `DELETE && api/push-registrations/*`; no caso específico, preserva o título e o detalhe da exceção própria. O registro ocorre antes do 404 genérico de Core. Nenhum import de Notifications permanece no bootstrap ou em Core.

Core conserva `api/* || expectsJson()`, os guards de API da validação/404/normalização e o catálogo/defaults integral. Validação monta uma entrada por mensagem, preservando ordem e pointers. O fallback usa `JsonApiErrorResponse::document()` ao substituir somente o corpo da mesma Response, mantendo status/headers, ajustando Content-Type e removendo Content-Length obsoleto. Documento já JSON:API permanece intocado. Não há dispatcher próprio, novos providers, exceções, interfaces, endpoints, migrations ou suporte de teste.

### Verificações incrementais e finais

- Após extrair Identity: `lerd composer test -- tests/Feature/Identity/Presentation/Http/ExceptionRenderingHttpTest.php --compact` (22 / 110) e fronteiras (30 / 504), ambos aprovados antes de marcar 3.1.
- Após extrair Expense/Notifications: suas caracterizações (8 / 40 cada), `NotificationRegistrationHttpTest.php` (47 / 292) e caracterização de Core (32 / 146), todos aprovados antes de marcar 3.2. Isso inclui o 404 alheio/ausente/malformado e o fallback fora do caso específico.
- Após extrair Core: sua caracterização (32 / 146), fronteiras (30 / 504), filtros de Insights (41 / 255) e Metrics HTTP (91 / 859), todos aprovados antes de marcar 3.3. Isso inclui catálogo, validação múltipla, reporte, guards, documento pronto, headers e erros próprios com parameter.
- Após Pint `--dirty --format agent`: os mesmos 11 arquivos HTTP listados na tabela do Step 1 foram executados novamente, cada um isoladamente pelo launcher, com os mesmos resultados (341 / 2791). Response Unit (13 / 45) e fronteiras (30 / 504) também foram repetidos isoladamente. Total distinto nesta rodada final: **384 testes / 3340 assertions**, todos aprovados, sem skips reportados.

Os comandos de teste são `lerd composer test -- <arquivo> --compact`, via MCP `exec/composer`. Feature continua usando preflight e bancos exclusivos com migrations incrementais; nenhuma migration ou escrita manual no banco operacional foi necessária. Não houve mudança nos testes ou no suporte nesta etapa.

Smoke HTTP local adicional: GET de uma rota API inexistente, com `Accept: text/html`, respondeu 404 JSON:API com `Recurso não encontrado`, detalhe esperado e `X-Request-Id`. A captura de dumps já estava habilitada e foi preservada; `optimize_route(site=trocado)` não tinha amostras (`samples=0`, `routes=[]`), portanto não comprova desempenho nem ausência de N+1. Não foram criados usuários/tokens nem exercitados fluxos mutáveis manualmente.

Sem divergência de produto identificada. O gate consolidado do Step 4 (suítes HTTP focadas e revisão final de rastreabilidade) permanece pendente, assim como a aprovação para prosseguir. Não foram executados suíte completa ou paralelo nativo; não houve alteração de suporte compartilhado. Sem commit ou arquivamento nesta etapa.

### Ajuste posterior solicitado: diretório Exceptions

Após edição manual de Notifications, os registros de Core, Expense e Identity foram movidos, sem alteração de conteúdo, para `Presentation/Http/Exceptions/exceptions.php`. Os quatro caminhos no bootstrap foram atualizados. As referências anteriores desta seção de evidências descrevem os caminhos e o estado históricos do Step 3, não uma nova aprovação do estado corrente.

Pint passou. As quatro caracterizações HTTP foram repetidas isoladamente pelo launcher: Expense 8/8, Identity 22/22, Notifications 8/8; Core 28/32, com quatro falhas. Core já continha duas assinaturas `?JsonApiErrorResponse` apesar de importar/instanciar `JsonErrorResponse`, causando TypeError em validação/404. A ordem do bootstrap também já havia sido alterada para Core → Expense → Identity → Notifications, contrariando a precedência documentada do 404 específico. A padronização de pastas preservou essas edições; sua correção requer autorização separada. As evidências verdes anteriores não aprovam esse estado posterior, e o Step 4 permanece bloqueado por essas divergências.

### Correção autorizada das falhas posteriores

Após o pedido de corrigir os testes, os dois retornos de Core foram alinhados a `?JsonErrorResponse` e a composição foi restaurada para Identity → Expense → Notifications → Core. A permissão arquitetural e a referência em `ARCHITECTURE.md` foram alinhadas ao nome atual `JsonErrorResponse`, preservando o compartilhamento da classe exata. Nenhuma assertion foi removida ou relaxada.

Pint passou nos três arquivos PHP envolvidos. Pelo launcher, foram repetidos isoladamente os quatro arquivos de caracterização HTTP, `NotificationRegistrationHttpTest.php`, `ContextBoundariesTest.php` e `JsonApiErrorResponseTest.php` (este último já usa a classe renomeada): **160 testes / 1177 assertions aprovados**, sem skips reportados. Core voltou a 32/32 e a jornada de Notifications aprovou seus 47 cenários, incluindo o 404 uniforme. GET local da rota API de smoke inexistente voltou a responder 404 JSON:API, inclusive com Accept HTML. `optimize_route` continua sem amostras; não é evidência de performance.

As duas divergências registradas acima estão resolvidas. A autorização desta correção não executa nem conclui automaticamente o gate consolidado do Step 4; nenhum commit ou arquivamento realizado.

## Gate final — Step 4 (2026-10-19)

Executado após a autorização explícita de arquivamento, commit e push. O estado final usa `JsonErrorResponse` e `Presentation/Http/Exceptions/exceptions.php`; os nomes/caminhos antigos nas seções anteriores são evidência histórica. As duas falhas posteriores de tipos/precedência foram resolvidas antes deste gate, sem relaxar assertions.

### Execução

Pint `--dirty --format agent` passou antes das execuções finais. O launcher `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` aprovou **2445 testes / 41741 assertions**, sem skips/incomplete/risky. Preflight: `trocado_testing_c86314da7b78b76c4ae083aa`; somente bancos exclusivos de teste e migrations incrementais.

Os sete arquivos da correção final já haviam sido aprovados isoladamente (160 / 1177, tabela/descrição acima). Além da suíte completa, cada caminho abaixo foi executado em sua própria invocação pelo launcher, com `--compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`:

| Caminho sob `tests/Feature/` | Testes | Assertions |
| --- | ---: | ---: |
| Core/Presentation/Http | 33 | 240 |
| Identity/Presentation/Http | 65 | 415 |
| Expense/Presentation/Http | 264 | 2020 |
| Notifications/Presentation/Http | 55 | 332 |
| Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php | 41 | 255 |
| Metrics/Presentation/ExpenseMetricsHttpTest.php | 91 | 859 |

Suítes focadas: **549 testes / 4121 assertions**, todos aprovados. Esses resultados se sobrepõem à suíte completa e não devem ser somados como cenários distintos.

### Rastreabilidade final

| Requisito / cenários | Evidência aprovada | Estado |
| --- | --- | --- |
| ERR-01: conflito e pointers de senha/avatar/cursor | Identity e Expense ExceptionRenderingHttpTest; Unit da Response | Proven |
| ERR-02: traduções, três ramos de conta, campo Notifications e fronteiras | Caracterizações dos três contextos; NotificationRegistrationHttpTest; ContextBoundariesTest; revisão dos quatro registros e composição | Proven |
| ERR-03: duas mensagens de senha + uma de e-mail, ordem e pointers | Core ExceptionRenderingHttpTest: `keeps every validation message...` | Proven |
| ERR-04: 429/Retry-After, 405/Allow, catálogo/defaults, Content-Length e sanitização | Core ExceptionRenderingHttpTest: testes de headers, rejeição real de método, catálogo de 20 códigos e falha inesperada com debug; quota de Notifications | Proven |
| ERR-05: 404 push uniforme, outro 404 e documento pronto | NotificationRegistrationHttpTest; Core ExceptionRenderingHttpTest: especialização, documento preservado byte a byte com headers; filtros reais Insights/Metrics com parameter | Proven |
| ERR-06: não API HTML/JSON/redirect, negócio fora da API e reporte | Core ExceptionRenderingHttpTest e datasets API/não API dos três contextos; shouldReport real e callback de reporte inesperado | Proven |

Revisão: bootstrap declarativo, Core sem import de consumidores, Response sem escolha de mensagens/inspeção de exceções, permissão exata em Presentation, Domain/Application intocados. O diff também contém reorganizações manuais prévias na ordem de rotas/aliases/argumentos de middleware e ajustes de Bruno, além da exclusão de documentação HTML, incluídos no commit por solicitação de “tudo”; não são apresentados como parte da extração nem revertidos. O ambiente Bruno mantém segredos declarados em `vars:secret` sem valores versionados e IDs locais vazios; apenas whitespace final foi removido. Não foram disparados requests Bruno mutáveis durante este gate.

Nenhum bloqueio ou cenário sem evidência identificado para ERR-01–ERR-06. Não houve mudança de suporte compartilhado, schema, dependências ou rotinas de negócio; o gate ampliado de reorganização de suporte não se aplica. Não foi executado paralelo nativo/duas seeds adicionais; a suíte completa padrão e as suítes focadas passaram. Smoke local e optimize_route continuam com os limites já registrados, sem alegação de performance. Validação estrita e arquivamento nativo OpenSpec encerram esta etapa; outras changes ativas permanecem fora do escopo.
