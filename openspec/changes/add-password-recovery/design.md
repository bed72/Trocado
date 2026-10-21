## Context

Identity é owner de credenciais, autenticação e PATs Sanctum. O código atual possui `PasswordValueObject` (6–32 caracteres, até 72 bytes, maiúscula Unicode e dígito), `PasswordRule` que o reutiliza, `UserModel` autenticável/Notifiable e notificações de verificação enfileiradas. `config/auth.php` já aponta o broker `users` para `password_reset_tokens`, com 60 minutos e throttle de 60 segundos; não foi localizada migration da tabela no código consultado. A existência da tabela no banco de runtime não foi inferida nem consultada nesta etapa documental.

Fontes: `ARCHITECTURE.md`, specs principais `authentication`/`identity-context`/`user`, design arquivado `2026-09-27-verify-identity-email` e inspeção dirigida das classes atuais de Identity e do broker instalado. `.ai/guidelines/` não foi localizada; as orientações correspondentes constam no AGENTS.md. Laravel Boost/Search Docs não estava disponível entre as ferramentas expostas; a implementação deverá consultar a documentação quando acessível e confirmar APIs/versões instaladas antes de codificar.

O `PasswordBroker` instalado valida o token, executa callback e depois o exclui; não estabelece por si só uma unidade transacional com lock da conta. `DatabaseTokenRepository` gera tokens e persiste hashes, mas emissão é delete/insert e a consulta não serializa concorrentes. Seu teste de expiração usa `isPast()`: o contrato explícito desta mudança rejeita também o instante exato de 30 minutos. Não basta chamar o broker de dentro do Controller e assumir uso único concorrente.

## Goals / Non-Goals

**Goals:** dois endpoints públicos seguros, elegibilidade restrita, mensagens genéricas, link configurável, limites compartilhados, uso único concorrente, revogação global atômica e notificações sem rollback por falha de e-mail.

**Non-goals:** qualquer página web/HTML, tela mobile, associação de domínio ao app, redirecionamento, novo provedor de e-mail, histórico de senha, troca de senha autenticada, ativação de conta, alteração de e-mail, MFA, novo sistema de sessões, outbox ou garantia de entrega exatamente uma vez. Criar esta spec não autoriza código, migrations, testes da aplicação ou alterações de runtime.

## Decisions

### 1. Contrato HTTP explícito e somente API

| Operação | Rota e nome | Entrada em data.attributes | Sucesso |
| --- | --- | --- | --- |
| Solicitar | `POST /api/authentication/forgot-password`, `authentication.api.forgot-password` | `email`; tipo `password-recovery-requests` | `202`, JSON:API com somente `meta.message` |
| Redefinir | `POST /api/authentication/reset-password`, `authentication.api.reset-password` | `email`, `token`, `password`, `password_confirmation`; tipo `password-resets` | `204`, sem corpo |

O documento `meta` de solicitação é uma escolha de transporte para cumprir a mensagem aprovada sem inventar recurso persistido ou usar envelope fora de JSON:API. Tipos, atributos e membros aceitos devem ser fechados como nos Requests existentes. Validação usa `422` e pointers; link inválido usa mensagem e pointer uniformes da spec; limites por IP usam `429` e `Retry-After`. Ambos são públicos e independentes das verificações de Bearer/renovação de sessão das rotas protegidas.

Rejeitada a alternativa de criar GET de confirmação na API ou formulário web: a abertura do e-mail não executa mudança de estado e o escopo é somente API. O consumidor implementa a interpretação do destino e a tela.

### 2. Fronteiras de Application e persistência

Introduzir `RequestPasswordRecoveryUseCase` e `ResetPasswordUseCase`, com dependências na ordem Port → UseCase → Repository. O UseCase delimita a unidade via `TransactionPort`; não delega uma transação de negócio oculta ao Controller ou a um callback de notificação. Use `ResetPasswordInput` coeso e `final readonly` para os dados de redefinição; e-mail único da solicitação pode permanecer parâmetro explícito. Dados sensíveis usam `SensitiveParameter` importado onde aplicável e não entram em Entity/Output público.

Usar `PasswordRecoveryRepository`/`EloquentPasswordRecoveryRepository` para operações de estado de recuperação, verificação bloqueante da conta e consumo/persistência; contratos expõem somente tipos próprios, UUIDs, scalars e resultados tipados quando necessários, nunca Model, hasher ou broker. A operação de persistir a redefinição inclui alteração da credencial e exclusão dos PATs do owner na unidade já aberta pelo UseCase. Não adicionar `save` genérico a `UserRepository` nem ampliar SignOut seletivo.

Usar `PasswordRecoveryPort`/`PasswordRecoveryAdapter` para efeitos externos de entrega do link/aviso. O UseCase agenda esses efeitos via `afterCommit`; o adapter resolve notifications e observabilidade sanitizada. Reutilizar `EmailValueObject` e `PasswordValueObject`; nenhum Laravel/SDK em Domain/Application. Bindings somente das fronteiras novas em `IdentityServiceProvider`. Tipos de resultado interno devem distinguir supressão, link inválido, senha igual e sucesso sem expor motivos privados no HTTP.

Essa divisão segue o precedente de verificação por Repository e efeitos por Port. Rejeitados: Application chamando `Password` facade, Controller acessando Eloquent e interfaces para cada UseCase.

### 3. Reutilizar primitivas nativas sem assumir garantias ausentes

Reutilizar geração/verificação/armazenamento de token do componente nativo de recuperação quando compatível, hasher configurado, notifications, queue e limiter Laravel. Confirmar APIs pelo Search Docs/código instalado antes de implementar. Não criar algoritmo criptográfico próprio, alterar vendor ou usar PAT Sanctum como token de recuperação.

O Repository coordena as primitivas nativas dentro da conexão PostgreSQL do fluxo, depois de adquirir lock estável da conta. Caso use broker/repositório nativo, configurar expiração 30 minutos/throttle 60 segundos e garantir que sua conexão seja a mesma de `TransactionPort`. Acrescentar checagem explícita de fronteira temporal para rejeitar `now >= created_at + 30 minutos` antes da validação/consumo; não presumir que o helper nativo rejeita a igualdade. O relógio é resolvido na borda e a política temporal recebe referência explícita ou é avaliada em Infrastructure, nunca via facade em Application.

Não usar o caminho padrão de reset com rotação de `remember_token`: a API não possui esse conceito de sessão e não deve adicionar coluna por conveniência de um exemplo Laravel. O fluxo não autentica nem emite PAT. Comparar senha candidata com hash atual pelo hasher antes de gravar; não comparar hashes entre si e não persistir histórico.

### 4. Unidade atômica, locks e concorrência

Usar a row `users` como âncora de serialização por conta, inclusive quando ainda não existe token de recuperação. Emissão e consumo adquirem lock da mesma conta na conexão de escrita, relendo e-mail atual, status e verificação. A ordem do fluxo é conta → estado de recuperação → PATs afetados, evitando inversões próprias. Revalidar token, expiração e senha atual depois do lock, nunca somente antes da transação.

Na emissão, reavaliar o intervalo sob lock; suprimir sem substituir nem estender token quando ainda não passou 60 segundos. Nova emissão grava hash e data, substituindo o anterior na mesma transação. No consumo, validar e então atualizar hash, excluir todos os PATs do owner e remover token de recuperação antes de commit. Senha igual lança/retorna rejeição sem consumo nem efeitos. Erro transacional reverte todas as escritas; `afterCommit` somente para a tentativa confirmada.

Provar com processos sincronizados emissão/emissão e consumo/consumo; cobrir ordenação emissão/consumo. Revisar a interação estreita com `SessionAdapter`: ele relê PAT com lock e não pode ressuscitá-lo. Não prometer cancelar requests já autenticados em andamento; revogação vale para autenticações subsequentes e extensões não podem recriar PAT. Inspecionar também SignIn concorrente para não deixar PAT emitido com senha antiga validada antes da redefinição e gravado depois da revogação; se necessário, coordenar somente a seção crítica de validação/emissão com o lock da conta, preservando seu contrato público. Isso é integridade da revogação, não um refactor de autenticação.

Retries de transação não podem multiplicar e-mails. Evitar eventos externos dentro do callback e não multiplicar mecanismos de retry. Falhas técnicas não são token inválido e não devem ser mascaradas indiscriminadamente como `422`.

### 5. Cotas e privacidade

Dois limiters públicos independentes: `authentication.forgot-password` e `authentication.reset-password`, cada um com 6 requests/10 minutos por IP no store Redis configurado. Contar tentativas admitidas antes da validação de documento, como nos fluxos atuais; mesma resposta segura `429` com `Retry-After`. Não liberar chamadas quando o Redis falhar nem mudar a cota dos endpoints existentes.

O intervalo por e-mail é 60 segundos desde a última emissão confirmada, global entre IPs e garantido pela persistência sob lock. Durante o intervalo, responder o mesmo `202`, sem informar supressão ou enfileirar outro link. Chaves derivadas usam digest, sem e-mail/token em claro. Canonicalizar conforme Identity; não transformar senha, confirmação ou token. Padronizar corpos e não expor resultados internos do broker (INVALID_USER, RESET_THROTTLED). Uniformidade de resposta não é promessa de duração de rede idêntica; avaliar caminho temporal para evitar diferenças grosseiras sem adicionar sleeps ad hoc como garantia de segurança.

### 6. Destino configurado, sem desenvolvimento web

Adicionar configuração própria de Identity alimentada por `PASSWORD_RESET_URL`, com exemplo sem domínio real/credenciais em `.env.example`. A configuração define uma URL absoluta confiável, HTTPS em produção; somente query não reservada pode existir previamente. Rejeitar fragmento, userinfo e parâmetros `token`/`email` pré-existentes para evitar ambiguidade/duplicação. Anexar query com codificação RFC 3986, sem concatenação ingênua. Não inferir destino de Host, URL do request ou parâmetro do consumidor.

Configuração inválida não pode virar um `500` somente quando uma conta existe, revelando elegibilidade. Validar disponibilidade antes de emitir e registrar falha sanitizada, conservando `202` genérico para documentos válidos; diagnosticar a configuração como requisito operacional para habilitar o fluxo. Não persistir um novo token quando a configuração impede construir o link.

O operador informa o destino tratado pelo app. A escolha de domínio por ambiente é não bloqueante para a spec e bloqueante para operar o envio real. Nenhuma página `/authentication/reset-password` será criada pela API.

### 7. Entrega assíncrona e aviso após commit

Criar notificações próprias de Identity para link e aviso, enfileiradas com recursos já instalados. Solicitar link após commit da emissão e aviso após commit da redefinição. O token bruto existe transitoriamente para compor a entrega; nunca é persistido na tabela de recuperação ou retornado ao cliente. Como o worker precisa do link, proteger o payload de fila que o carrega (cifragem suportada pelo mecanismo instalado ou mecanismo equivalente comprovado), além da redação de logs/failed jobs e controle de acesso operacional. Não alegar que somente hash existe em todo o sistema enquanto uma mensagem enfileirada necessariamente transporta o segredo.

Capturar o destinatário esperado; no worker, reler a identidade e descartar envio se conta removida ou e-mail divergente, sem redirecionar segredo ao novo endereço. Um link obsoleto já enfileirado pode chegar após nova emissão, mas deve falhar no consumo; não regenerar token no worker nem renovar validade. Aviso não contém senha/token e não depende de token ainda existir.

Falha ao enfileirar ou enviar não reverte estado confirmado. Adapter reporta apenas metadados permitidos, sem exception bruta contendo bindings/URL/payload. Depois de emissão, o solicitante mantém `202`; depois de redefinição, `204`. Jobs já enfileirados seguem retries normais; sem job, nova solicitação após 60 segundos recupera o envio do link. Não há garantia de exactly-once nem entrega eventual forte: outbox foi rejeitada por extrapolar a necessidade atual.

### 8. Persistência e evidência

Criar migration incremental reversível de `password_reset_tokens` com e-mail canônico único/PK, hash `token` e `created_at`, compatível com componente nativo. A tabela é técnica vinculada ao endereço, não recurso público: não inventar UUID ou FK numérica. Confirmar schema real via MCP antes de escrever migration; não inferir existência por config. Definir remoção de estado de recuperação no encerramento da conta para não deixar credencial reaproveitável em eventual recadastro do mesmo endereço; integrar somente esse cleanup à transação de exclusão existente e provar isolamento. Não alterar migrations históricas, executar `migrate:fresh` ou migrar no momento da spec.

Adicionar a tabela à classificação de `TestDatabaseCleanup` quando implementar. Provar orquestração em Unit sem bootstrap e banco real/locks/rollback em Feature PostgreSQL pelo launcher. Testes HTTP cobrem contratos, limites e redaction; testes de fila distinguem enfileiramento, execução do job e falha no transporte. Fakes não provam rollback ou concorrência. Usar fixtures explícitas, fakes nativos e recursos exclusivos por cenário, sem apagar cache/fila compartilhados. Manter evidência por cenário em tasks, inclusive falhas e limitações reais.

## Risks / Trade-offs

- **Link contém credencial e e-mail em query** → destino confiável, codificação segura, redaction de URL/logs e payload de fila protegido. O cliente também deve evitar analytics/referrers, mas sua implementação não faz parte da API.
- **Falha entre commit e enqueue** → estado permanece confirmado; registrar falha e permitir nova solicitação. Sem garantia distribuída/outbox.
- **Fila atrasada entrega link já expirado/rotacionado** → prazo começa na emissão, não no envio; somente o token corrente pode ser consumido.
- **Corrida com login/renovação** → lock estável da conta e revisão restrita das seções críticas, provas reais de que PAT revogado não reaparece.
- **Bloqueio da conta durante recuperação** → elegibilidade relida dentro da unidade atômica, sem ativação implícita.
- **Rate limit por IP afeta redes compartilhadas** → conservar a política aprovada de 6/10 minutos por endpoint; não adicionar exceções silenciosas.
- **Hashes custosos em endpoint público** → cotas antes das verificações caras; evitar queries/revalidações repetidas fora da unidade necessária.

## Migration Plan

1. Após autorização de implementação, confirmar versões, documentação disponível, schema PostgreSQL e configuração de fila/limiter sem mudar dados existentes.
2. Implementar migration incremental e configuração; incluir a tabela no lifecycle seguro de testes e na exclusão de conta.
3. Implementar fronteiras, transação/locks, endpoints e notificações com tarefas rastreáveis; executar migrations pendentes no Lerd somente na fase de implementação antes dos fluxos dependentes.
4. Validar testes isolados e suíte focada pelo launcher, incluindo PostgreSQL/Redis/concorrência quando exigidos, e Pint após PHP. Sem testes da aplicação nesta etapa documental.
5. Para habilitar envio real, configurar `PASSWORD_RESET_URL`, conferir mailer/Redis/worker e reiniciar workers após publicação. A API não oferece formulário ou associação de domínio mobile.
6. Rollback de release: desabilitar os novos endpoints/produção de mensagens e impedir entrega de jobs próprios incompatíveis, preservando dados/tabela até revisão operacional. Não restaurar senhas antigas ou PATs revogados. Remoção posterior da tabela invalida links de recuperação em aberto e exige decisão explícita; nenhuma limpeza ampla de Redis/fila/banco.

## Open Questions

- **Bloqueadoras de produto:** nenhuma; as decisões foram aprovadas na conversa.
- **Não bloqueante para a spec, obrigatória para operar:** valor real de `PASSWORD_RESET_URL` por ambiente, fornecido pelo proprietário do app.
- **Verificações técnicas antes de implementar:** Search Docs quando disponível, APIs de cifragem/redaction do payload de notificação, schema real e coordenação de SignIn/renovação. São tarefas de evidência, não autorização para ampliar o escopo.

## Descoberta S01 — 2026-10-21

Descoberta autorizada e concluída sem implementação. Este registro resolve as verificações técnicas acima; não representa prova de comportamento ainda não implementado.

### Ambiente e documentação observados

- MCP Lerd `site action=list`: site `trocado`, diretório principal deste repositório, PHP 8.5; workers existentes já estavam ativos. Nenhum serviço/worker foi iniciado ou reconfigurado.
- `exec action=artisan`, `about --only=environment --json`: PHP **8.5.11**, Laravel **13.38.0**, timezone **UTC**, ambiente local. `composer show --direct --format=json`: Sanctum **4.3.3**, Boost **2.10.0**, Pest **5.2.1**, Pint **1.32.1**, Nightwatch **1.30.2**; `composer show phpunit/phpunit --format=json`: PHPUnit **13.3.4**. Constraints do manifest não foram usadas como versão efetiva.
- Boost não está exposto diretamente no catálogo MCP desta sessão. O comando instalado `boost:execute-tool {tool} {arguments}` aceita classe registrada e JSON em base64 (`vendor/laravel/boost/src/Console/ExecuteToolCommand.php:16–54`). Via MCP Lerd, foi possível executar `Laravel\Boost\Mcp\Tools\SearchDocs` e `DatabaseQuery`, sem instalar/configurar servidor adicional.
- SearchDocs consultou Laravel 13.x sobre broker, hasher, jobs cifrados, limiter e JSON:API. Fontes retornadas: `laravel/docs` branch `13.x`, `passwords.md`, `hashing.md`, `queues.md`, `routing.md` e `eloquent-resources.md`. A consulta específica «Encrypting Queued Notifications» não retornou resultados; suporte de notification cifrada confirmado diretamente em `SendQueuedNotifications.php:102–120` e `Queue.php:176–215`. Resultados genéricos de JSON:API não substituem as regras locais de entrada/erros abaixo.
- `.ai/guidelines/` não existe; arquitetura e orientações inline do AGENTS foram consultadas. Regras de `openspec/changes/**` e busca por password/senha/queue/lock/recovery lidas antes das alterações documentais.

### Banco e configuração efetiva

`DatabaseQuery` executou SELECTs somente de metadados: `current_database()`, `current_schema()`, `version()`, `to_regclass`, `information_schema.columns` e `pg_indexes`. Resultado: **PostgreSQL 16.10**, banco **trocado**, schema **public**, `password_reset_tokens` **ausente**. `users.id` e `personal_access_tokens.id/tokenable_id` são UUID; `users.email` tem índice único. `failed_jobs` existe com `payload` e `exception` text. Não foram consultadas credenciais, usuários ou payloads reais.

`config:show` via Lerd confirmou: conexão padrão `pgsql`; broker `users` com tabela `password_reset_tokens`, expire **60** minutos e throttle **60** segundos; hasher **bcrypt**; queue **redis**, conexão Redis `default`, queue `default`, `retry_after=90`, `block_for=5`, `after_commit=true`; failed jobs **database-uuids**, conexão `pgsql`; limiter **redis**. S02 deve ajustar expire para 30 e criar a tabela incrementalmente. Introspecção somente leitura confirmou que UserModel, PersonalAccessTokenModel e `DB::connection()` resolvem a **mesma instância pgsql**; encrypter está registrado. Revalidar essa identidade se configuração/conexões mudarem antes do apply de código.

### Primitivas, tempo e transação

- `DatabaseTokenRepository.php:19–73,82–133,164–186`: recebe conexão/hasher/tabela/chave, gera token nativo, persiste hash adaptativo e timestamp, permite `getConnection()`, `create`, `exists`, `recentlyCreatedToken` e `delete`. `PasswordBrokerManager.php:85–110` resolve conexão configurada ou padrão e converte minutos em segundos. Reutilizar esse componente em Identity Infrastructure, ligado explicitamente à conexão da unidade; não chamar o fluxo público do broker, que valida/callback/delete sem locks próprios (`PasswordBroker.php:122–146`). Não usar remember token, evento de login ou PAT como recuperação.
- Após lock da conta, reler recuperação e resolver a referência temporal em Infrastructure, nunca antes de aguardar o lock. Comparar explicitamente `reference >= created_at + 1800s` para expiração e `reference < created_at + 60s` para supressão. Igualdade de 60s admite emissão. A checagem nativa `isPast()` não basta no limite inclusivo; preservar o timestamp da emissão, sem recalcular no worker. Usar o mesmo relógio controlável do componente nativo nos testes; não usar `DatePort::today()` (data civil).
- `TransactionAdapter.php:12–19` usa conexão padrão, `afterCommit` e até três tentativas completas. Conta, recuperação, senha e PATs devem usar essa instância; sem segunda conexão/retry de negócio ou efeito externo no callback. `UserModel.php:36–44` já faz cast `hashed`: hasher configurado compara a candidata à senha atual e o cast aceita hash compatível sem rehash duplo (`HasAttributes.php:1506–1521`).
- Entrada segue FormRequest fechado existente (`ResendEmailVerificationRequest.php:16–23`); `Core/Presentation/Http/Exceptions/exceptions.php:31–48` converte chaves em pointers JSON:API. `PasswordValueObject.php:14–39` protege os limites aprovados. `bootstrap/app.php:42–48` já preserva senha/confirmacão, mas **ainda não token**: acrescentar sua exceção de trim em S10. `Limit::perMinutes(10, 6)` existe; `ThrottleRequests.php:154–168` conta antes do próximo handler. `CacheServiceProvider.php:34–37` resolve store de `cache.limiter`, sem fallback local implementado pelo fluxo.

### Proteção da fila e falhas

Adotar notification própria `ShouldQueue` + **`ShouldBeEncrypted`**, com `Queueable`, descarte nativo de Model ausente e `expectedEmail` validado em `shouldSend` sobre Model reidratado. `NotificationSender.php:277–297` transfere middleware da notification para o job; `SendQueuedNotifications.php:114–120` transfere afterCommit/cifragem; `Queue.php:198–214` cifra `data.command` pelo encrypter da aplicação. O envelope conserva nomes técnicos, não deve receber URL/token/contexto sensível. Não basta marcar a notification nem usar `failed()` para sanitizar retroativamente.

`DatabaseUuidFailedJobProvider.php:55–64` persiste payload original **e exception textual**; `Worker.php` reporta exceptions. Decisão para S04: middleware **exclusivo das notifications de recuperação** envolve processamento/transporte, captura Throwable e lança falha genérica sem mensagem/previous original, mantendo retries normais; adapter sanitiza falhas de enqueue antes de reportar. `CallQueuedHandler.php:133–161` oferece esse limite antes do worker. Eventos próprios só carregam metadados permitidos, como ID/evento/classe, nunca mensagem, bindings ou objeto exception. S08 reutiliza o mesmo mecanismo.

O runtime CLI consultado tem `zend.exception_ignore_args=0`: não presumir que SensitiveParameter sozinho saneia traces de bibliotecas. S04 deve provar exception/log/failed job completos em execução real e proteger argumentos no limite próprio; falha dessa prova bloqueia avanço, não autoriza trocar configuração global. Cifragem não protege exception de transporte, templates/debug ou hooks que recebam o objeto antes da serialização. Core já emite metadados de fila permitidos (`CoreServiceProvider.php:57–78`); Nightwatch QuerySensor usa SQL parametrizado sem bindings (`QuerySensor.php:50–73`). S05 deve sanitizar falhas SQL sem previous sensível e S12 revisar captura integrada, sem desligar observabilidade global ou alegar proteção já provada.

### Seções críticas e ordem de locks

- **Ordem comum:** conta `users FOR UPDATE` → estado de recuperação → PATs afetados. Conta é âncora inclusive sem recuperação existente. Locks/escritas ficam dentro da unidade do UseCase, relendo elegibilidade e endereço atual. Não fazer lock de PAT e depois conta.
- **SignIn:** `SignInAdapter.php:52–73` hoje consulta/valida, checa status/verificação, rehash e cria PAT sem unidade/lock. Em S07, coordenar somente esse trecho: transação na conexão do Model, conta relida com lock **antes** da validação efetiva, rehash e emissão. Se reset vence, senha antiga falha na releitura; se login vence, reset posterior remove seu PAT. Preservar provider, respostas e política temporal; nenhuma mudança na Port é exigida por essa coordenação interna do adapter.
- **Renovação:** `SessionAdapter.php:29–47` já faz precheck no writer e depois lock/releitura do PAT, retornando se removido; atualiza Model existente, sem insert/upsert. Não precisa adquirir lock de conta para impedir ressurreição. Se renovação vence, reset aguarda e remove; se reset vence, releitura não encontra PAT. Manter caminho rápido e provar corrida em S07, sem reescrita preventiva.
- **Exclusão:** `DeleteUserUseCase.php:30–37` já delimita transação; `EloquentUserRepository.php:79–90` hoje busca conta sem lock, remove PATs e conta. Em S02, tornar a busca bloqueante e remover recuperação pelo endereço lido sob lock **antes** dos PATs/conta na mesma unidade. Não ampliar UserRepository, não apagar recuperação de outro endereço nem mover transação para Repository. Isso serializa exclusão com emissão/reset/login futuros e impede credencial herdada em recadastro.

**Saída:** S02–S12 continuam dimensionadas como no STEPS; middleware/provas de falha pertencem a S04 e S08, locks de exclusão a S02, coordenação de login/renovação a S07. Nenhuma nova dependência, sessão ou contrato de produto necessário. A existência das APIs foi confirmada; rollback, fronteiras temporais, proteção de payload e corridas ainda dependem das provas previstas nessas sessões. `PASSWORD_RESET_URL` real continua pendência operacional não bloqueante para implementar com destino de teste explícito. S02 aguarda aprovação.

## Fundação S02 — 2026-10-21

S02 posteriormente autorizada e entregue. Migration incremental `2026_10_21_170047_create_password_reset_tokens_table.php` cria o shape nativo (email PK, token hash e created_at nullable compatível com DatabaseTokenRepository), sem ID público ou tabela de senha. O Repository de consumo em S05 ainda deverá rejeitar timestamp ausente/inválido; compatibilidade de schema não comprova elegibilidade ou expiração. `config/auth.php` define 30min/60s; `config/identity.php` lê `PASSWORD_RESET_URL`, sem fallback, com exemplo reservado em `.env.example`.

`Identity/Infrastructure/Adapters/PasswordRecoveryUrlAdapter::baseUrl()` valida configuração sem acessar request, conta ou produzir efeito externo: URL absoluta HTTP/HTTPS, HTTPS obrigatório em produção, sem userinfo/fragmento/query token ou email (inclusive codificações e forma array). Falha lança mensagem técnica genérica sem incluir URL. É classe concreta autowirable, sem novo contrato/binding: S03/S04/S09 integrarão sua validação antes da emissão e a observabilidade sanitizada com `202` uniforme; ainda não há endpoint ou construção de link nesta sessão.

`EloquentUserRepository::delete()` agora adquire lock da conta e remove recuperação por e-mail atual na conexão do Model antes de remover PATs/conta, mantendo a transação definida por DeleteUserUseCase. `TestDatabaseCleanup` classifica a tabela nova. Provas PostgreSQL verificaram ordem SQL, isolamento, recadastro e rollback real após exclusões; não equivalem a corrida sincronizada de recuperação (S06/S07). Provas e gate ampliado do suporte compartilhado constam em TASKS. Migration operacional aplicada somente ao site principal `trocado`; banco/serviços do alvo de carga não foram operados. `PASSWORD_RESET_URL` real não foi definido, `.env` permaneceu intacto. S03 aguarda aprovação.
