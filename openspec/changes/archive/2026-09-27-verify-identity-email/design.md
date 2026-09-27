## Context

Identity contém `SignUpUseCase` (transação por `Core\Application\Ports\TransactionPort`), `UserRepository`/`EloquentUserRepository`, `UserModel`, `SignInAdapter` (única emissão em `createToken()`) e `UpdateUserUseCase`. SignUp já não emite token; a persistência define `pending` e o middleware `user.active` protege User e Expense. `UserModel` herda de `Illuminate\Foundation\Auth\User`, que já implementa os métodos do trait `MustVerifyEmail`, mas ainda não implementa o contrato nem usa `Notifiable`. O listener nativo de `Registered` envia `VerifyEmail`, cuja classe padrão não implementa `ShouldQueue`. A rota padrão com `EmailVerificationRequest::fulfill()` requer usuário autenticado, incompatível com `pending` sem token. O `TransactionPort` já fornece `afterCommit()`, e a queue Redis existente tem `after_commit = true`.

## Goals / Non-Goals

**Goals:** confirmar posse do endereço sem ativar conta, enviar assincronamente após persistência confirmada, impedir criação e uso de tokens por e-mail não verificado e travar a edição de e-mail na API, preservando os demais contratos HTTP e limites entre camadas.

**Non-goals:** automatizar ativação, recriar geração/validação criptográfica de links, personalizar Sanctum, implementar mudança ou reverificação de endereço, revogar todos os tokens por edição de perfil, alterar cadastro ou perfil de Expense, criar um processo administrativo de ativação, oferecer garantia de entrega exatamente uma vez, apagar contas existentes via migration ou mudar os documentos de sucesso atuais de SignUp/User.

## Decisions

### 1. Estado e ownership

Adicionar migration reversível `email_verified_at` nullable em `users`. Novas contas permanecem `status = pending` e `email_verified_at = null`. `UserModel` implementa `Illuminate\Contracts\Auth\MustVerifyEmail`, usa `Notifiable`, faz cast datetime do novo campo e reutiliza os métodos herdados; nunca serializa senha/token. `UserEntity` permanece sem o campo: hoje a verificação governa a integração de autenticação, não uma transição de status do Domain. `UserStatusEnum` mantém seus três valores. A alteração de endereço continua pertencendo a Identity. Não editar migrations históricas nem eliminar contas automaticamente.

### 2. Fronteira de envio e commit

Introduzir `Identity\Application\Ports\EmailVerificationPort` com intenção de **solicitar** verificação para um ID persistido; `Identity\Infrastructure\Adapters\EmailVerificationAdapter` resolve `UserModel` e dispara `Registered` somente para cadastros (o listener Laravel chama `sendEmailVerificationNotification`); para reenvio, solicita diretamente `sendEmailVerificationNotification`, evitando disparar falsamente `Registered`. O caso de uso decide quando solicitar, mas conhece apenas a Port e IDs, sem `Registered`, `Notification`, `UserModel` ou Eloquent. Registrar binding no provider de Identity. Não criar Port de criação ou Repository de notificações nem operações não utilizadas.

No SignUp, manter `UserRepository::create` dentro de `TransactionPort::commit`, registrando `TransactionPort::afterCommit` dentro da transação para solicitar verificação com o ID criado. Retry/rollback não devem emitir nem enfileirar mensagens de tentativas abortadas. A fila Redis (`QUEUE_CONNECTION=redis`) com worker consumindo a queue escolhida será exigência operacional. A notificação específica de Identity estende `Illuminate\Auth\Notifications\VerifyEmail`, implementa `ShouldQueue` e usa `Queueable`; `UserModel::sendEmailVerificationNotification` a envia. O método nativo cria `verification.verify` com assinatura temporária, `id` e hash SHA-1 do e-mail (hash de vinculação, não autenticação isolada). A geração ocorre no worker; `after_commit` do Redis é defesa adicional, não substitui a delimitação pelo UseCase. Não enfileirar o listener `Registered` *e* a notification ao mesmo tempo.

O worker envia pelo mailer configurado no ambiente (SMTP/Mailpit no Lerd). Não escrever credenciais no código. A integração com Resend, seu SDK e seus requisitos operacionais ficam para uma mudança futura; a configuração de exemplo pode continuar com mailer seguro para desenvolvimento.

### 3. Confirmação sem login

Criar `GET` público nomeado **`verification.verify`**, com middleware `signed` (URL absoluta, expiração padrão do Laravel de 60 minutos, salvo configuração explícita), ID numérico e hash. O handler HTTP confere a assinatura antes de consultar o usuário. `VerifyEmailUseCase` delimita a transação pelo `TransactionPort`; o Adapter usa lock, valida ID e `hash_equals` contra `sha1` do e-mail **atual** da conta, marca apenas `email_verified_at` quando nulo e agenda o evento `Verified` para depois do commit. Assim, rollback não emite evento e confirmação repetida não o duplica. O Controller é fino e responde JSON:API sem redirecionar ao login nem emitir token; resposta de sucesso: `204 No Content`, inclusive para reuso válido e já verificado. URL expirada/adulterada responde `403` em JSON:API; identidade inexistente ou hash divergente responde `403` uniforme, sem revelar outra conta. O link não constitui login. `EmailVerificationRequest::fulfill()` não é usado: ele consulta `$request->user()` e exigiria token para conta `pending`.

`GET` simples pode ser pré-aberto por scanner de e-mail. A escolha mínima é aceitar esse risco para cumprir clique direto; se houver requisito de confirmação humana explícita, substituir por página intermediária e `POST` será outra decisão de produto. Link válido já utilizado é idempotente; não promete invalidação criptográfica de uso único. O e-mail não pode ser alterado por este fluxo da API; se outro processo o modificar, o hash do link antigo deve falhar e a notification enfileirada não deve enviar para endereço diferente do original.

### 4. Acesso por token e e-mail imutável na API

Em `SignInAdapter`, validar credenciais como hoje; rejeitar conta `active` com e-mail não verificado **antes** de `createToken()` e do rehash de password. Conta `pending`/`blocked` conserva sua rejeição atual independentemente de verificação. Proposta: falha HTTP `403` JSON:API para e-mail não verificado somente após senha correta, sem diferenciar endereço inexistente de senha inválida (`401` atual). Após confirmar e-mail, `pending` continua sem token; só `active` + verificado emite novo token.

Aplicar checagem de verificação também a todas as rotas protegidas de User e Expense, além de manter `auth:sanctum` e `user.active`: isso cobre tokens emitidos anteriormente ou modificações de estado fora da API. Avaliar o middleware nativo `verified` na API (`expectsJson` deve produzir `403`), preservando o envelopamento JSON:API de erros; não usar `verified` como substituto da regra `active`. SignOut não depende de verificação nova, para permitir revogar token antigo.

`PATCH /api/users/{user}` aceita somente `name` como atributo editável. Qualquer `email` enviado, mesmo igual ao atual após canonicalização, deve produzir `422` JSON:API, sem alterar a conta; não ignorar silenciosamente. O `UpdateUserUseCase` aceita apenas o nome e preserva e-mail/status e ownership. `UserRepository::update` persiste apenas `name`. Não expor `updateEmailAndRevokeTokens` nem revogar tokens em alterações de nome. O recurso `UserResponse`, o status de sucesso do PATCH e a identificação por ID permanecem. A imutabilidade diz respeito à API e a seus contratos de Application/Repository; alterações administrativas diretas no banco são uma operação fora deste fluxo e continuam exigindo atenção operacional.

### 5. Reenvio e falhas

Proposta de `POST /api/authentication/email-verification/resend` público, com documento de entrada JSON:API contendo e-mail e resposta uniforme `202 Accepted`, sem revelar se conta existe, já verificou ou foi bloqueada. Para conta existente e não verificada, solicitar a notificação enfileirada; não alterar `status`. Aplicar limite independente dos de SignUp/SignIn por IP e por combinação IP+e-mail canônico (chave com digest), por exemplo 5/h por IP e 2/h por combinação; preservar `429` JSON:API + `Retry-After`, usando o limiter Redis já disponível. O reenvio não deve exigir token, porque `pending` não pode obtê-lo. `202` significa aceite para processamento, não entrega confirmada.

Falhas temporárias no mailer configurado devem ser tratadas pelos retries/registro de falha da queue; worker parado deixa mensagem pendente. Falha ao enfileirar depois do commit não reverte a conta: registrar erro operacional sem afirmar entrega e permitir reenvio. Redis e PostgreSQL não formam transação distribuída; uma exigência futura de entrega eventual forte justificaria outbox, não um efeito externo dentro de callback sujeito a retry. Não enviar mensagem síncrona como fallback. Não tentar enviar se conta foi removida ou se o endereço alvo já mudou enquanto o job aguardava (verificar estado no processamento ou adotar um mecanismo equivalente comprovado por teste).

## Risks / Trade-offs

- **O mailer pode estar indisponível após a resposta de SignUp**: manter estado pending/não verificado; retries/falhas e reenvio recuperam o caminho, sem promessa de entrega garantida.
- **Tokens anteriores com verificação removida fora da API**: verificar e-mail a cada requisição protegida; não inferir que e-mail imutável na API impede alterações administrativas diretas no banco.
- **Notification obsoleta**: `via()` é avaliado no enfileiramento e não é repetido no processamento com canal já definido; verificar a correspondência do endereço em `shouldSend()` no worker com o notifiable recarregado. Usar a opção nativa de descartar jobs cujo User tenha sido excluído; verificar por teste o processamento real do job após mudança externa do endereço.
- **Link pré-aberto por scanners**: explicitar no contrato que assinatura temporária não é nonce de uso único; reavaliar se o produto exigir proteção mais forte.
- **API pública revela e-mail no SignUp existente**: preservar `409` contratado; limitar reenvio e responder uniformemente nele, sem prometer eliminar toda enumeração já existente.
- **Integração Resend adiada**: mailer e fila locais são suficientes para comprovar a mudança sem adicionar dependência específica de produção nesta etapa.

## Migration Plan

Migration incremental nullable, sem backfill destrutivo ou limpeza de usuários/tokens. O proprietário pode limpar contas antigas separadamente antes da liberação, mas a mudança não depende disso. Confirmar mailer local, URL pública, Redis/worker, migrations pendentes e proteção de rotas antes de oferecer o fluxo. Atualizar fixtures que ativam contas manualmente para marcar e-mail verificado antes de SignIn. Clientes que enviavam e-mail no PATCH devem passar somente nome. Reiniciar worker após publicar a notification; verificar testes de PostgreSQL, fluxo HTTP, jobs e arquitetura. Em rollback de código, parar o envio e remover as rotas de confirmação/reenvio; preservar a coluna/dados até um plano explícito de reversão de schema, pois remover a coluna apaga os timestamps.

## Open Questions

Nenhuma bloqueadora para o fluxo local. O reenvio público (5/h por IP e 2/h por IP+e-mail), o `403` após senha correta e o `204` direto por GET assinado são as escolhas desta etapa; o risco de pré-abertura por scanners permanece documentado. Resend será tratado separadamente.
