## ADDED Requirements

### Requirement: SignUp solicita verificação após confirmação da conta
O sistema MUST persistir novas contas com `status = pending` e `email_verified_at = null`, MUST solicitar verificação do endereço somente depois do commit de `UserRepository::create` e MUST NOT autenticar ou emitir token no SignUp. O sucesso HTTP MUST preservar `201`, tipo `sign-ups`, relacionamento `users` e header `Location` existentes; aceitação da solicitação MUST NOT afirmar que o e-mail foi entregue.

#### Scenario: Cadastro válido
- **WHEN** o SignUp recebe nome, e-mail canônico, senha e confirmação válidos
- **THEN** a conta é persistida com `pending` e e-mail não verificado
- **AND** responde `201` com o documento JSON:API `sign-ups` e `Location` atuais
- **AND** nenhum Personal Access Token é criado
- **AND** uma única verificação é solicitada após o commit

#### Scenario: Rollback ou conflito de unicidade
- **WHEN** o cadastro é rejeitado ou a transação de criação é revertida, inclusive numa tentativa repetida pelo banco
- **THEN** nenhum e-mail referente à tentativa abortada é enfileirado
- **AND** os contratos existentes de validação e conflito permanecem

### Requirement: E-mail de verificação é assíncrono e usa os mecanismos nativos
O sistema MUST enfileirar no Redis uma notification Laravel implementando `ShouldQueue`, com URL temporária assinada produzida pela infraestrutura nativa `VerifyEmail`, usando o mailer configurado no ambiente. MUST NOT executar transporte de e-mail na requisição HTTP, introduzir serviço externo em Domain/Application ou enviar mensagem síncrona como fallback. O processamento MUST usar o endereço ainda pertencente ao usuário para o qual a solicitação foi criada.

#### Scenario: Worker entrega a verificação
- **WHEN** um cadastro confirmado solicita verificação e o worker consome o job
- **THEN** a notification é enviada pelo mailer configurado, sem envio durante o request de SignUp
- **AND** o link contém rota `verification.verify`, ID, hash do endereço de destino, assinatura e prazo

#### Scenario: Worker parado ou envio falha
- **WHEN** o worker não está disponível ou o mailer configurado falha após o cadastro
- **THEN** a conta continua `pending` e não verificada
- **AND** o job aguarda processamento ou segue retries e registro de falhas da queue
- **AND** não há emissão de token nem fallback síncrono

#### Scenario: Endereço mudou ou conta foi excluída antes do processamento
- **WHEN** a notificação antiga é processada depois que o e-mail foi alterado ou a conta foi removida
- **THEN** não envia um link antigo para o novo endereço nem trata o endereço novo como já confirmado

### Requirement: Link público confirma somente a posse do e-mail
O sistema MUST aceitar confirmação sem login através de `GET` público `verification.verify` com assinatura temporária válida, identificador existente e hash do e-mail canônico atual. MUST marcar apenas `email_verified_at` em operação atômica e emitir `Verified` somente após commit; MUST NOT modificar `status`, conceder sessão ou emitir token. O tratamento de sucesso MUST ser idempotente e retornar `204` sem conteúdo; erros da API MUST seguir JSON:API.

#### Scenario: Conta pendente confirma o endereço
- **WHEN** a conta `pending` acessa seu link válido antes de expirar, sem Bearer token
- **THEN** `email_verified_at` recebe um timestamp e o evento Laravel `Verified` é emitido uma vez
- **AND** `status` continua `pending`, a resposta é `204` e nenhum token é criado

#### Scenario: Conta bloqueada confirma o endereço
- **WHEN** a conta `blocked` acessa um link válido
- **THEN** somente o e-mail é confirmado
- **AND** ela continua `blocked` e sem acesso à aplicação

#### Scenario: Link válido repetido
- **WHEN** um link já utilizado para o mesmo e-mail, ainda válido, é acessado novamente
- **THEN** responde `204` sem atualizar o timestamp nem emitir novamente `Verified`
- **AND** nenhuma ativação ocorre

#### Scenario: Confirmação revertida
- **WHEN** a transação que marcou o e-mail verificado sofre rollback
- **THEN** `email_verified_at` permanece nulo
- **AND** o evento `Verified` não é emitido

#### Scenario: Assinatura ou prazo inválido
- **WHEN** a URL foi adulterada ou seu prazo expirou
- **THEN** responde `403` em JSON:API
- **AND** não altera conta, verificação ou tokens

#### Scenario: Conta inexistente ou hash não corresponde ao endereço atual
- **WHEN** o link identifica conta inexistente ou foi emitido para e-mail diferente do atual
- **THEN** responde `403` uniforme em JSON:API
- **AND** não confirma nenhum endereço

### Requirement: SignIn e rotas protegidas exigem e-mail confirmado e conta ativa
O sistema MUST verificar e-mail e `status = active` após validar credenciais e antes de chamar Sanctum `createToken()`. MUST rejeitar token Bearer existente de usuário cujo e-mail não está verificado nas rotas protegidas de User e Expense, sem remover as verificações atuais de status e ownership. SignOut MUST continuar disponível ao titular de token anteriormente emitido independentemente da nova condição de e-mail verificado, sujeito aos demais requisitos atuais de SignOut.

#### Scenario: E-mail confirmado e conta ainda pendente
- **WHEN** o e-mail foi confirmado, mas `status = pending`
- **THEN** SignIn conserva o `403` de conta pendente
- **AND** não cria Personal Access Token nem autoriza recursos protegidos

#### Scenario: Conta ativa sem e-mail confirmado
- **WHEN** credenciais corretas pertencem a conta `active` com `email_verified_at = null`
- **THEN** SignIn responde `403` JSON:API de e-mail não confirmado
- **AND** nenhum Personal Access Token é criado

#### Scenario: Credenciais inválidas
- **WHEN** e-mail inexiste, é inválido ou a senha está incorreta
- **THEN** permanece o mesmo `401` genérico atual
- **AND** não informa se o e-mail foi verificado

#### Scenario: Conta apta
- **WHEN** credenciais corretas pertencem a conta `active` com e-mail confirmado
- **THEN** SignIn emite token opaco Sanctum com o contrato `access-tokens` atual

#### Scenario: Token previamente emitido com endereço não confirmado
- **WHEN** um token ainda persistido é usado nas rotas de User ou Expense por conta agora não verificada
- **THEN** a requisição é rejeitada em JSON:API sem ler nem alterar recursos protegidos
- **AND** Sanctum permanece responsável pela autenticação do Bearer token

### Requirement: Reenvio público não revela contas
O sistema SHOULD disponibilizar `POST /api/authentication/email-verification/resend` para e-mail informado em documento JSON:API, sem requerer token. Requisições admitidas MUST responder `202 Accepted` uniformemente para conta inexistente, já verificada e não verificada; somente conta existente não verificada pode gerar nova notificação, mantendo seu status. O endpoint MUST possuir limites separados dos de SignIn/SignUp, armazenados no limiter compartilhado Redis: inicialmente 5 por hora por IP e 2 por hora por combinação IP/e-mail canônico, com chave sem endereço em claro. Exceder um limite MUST responder `429` JSON:API com `Retry-After`.

#### Scenario: Recuperação de e-mail perdido
- **WHEN** endereço pertence a conta ainda não verificada e a cota permite
- **THEN** responde `202`, enfileira uma notificação e não altera status nem token

#### Scenario: Endereço desconhecido ou já confirmado
- **WHEN** o endereço não pertence a conta ou já está confirmado
- **THEN** responde o mesmo `202`, sem indicar existência ou status
- **AND** nenhuma notificação adicional é enfileirada

#### Scenario: Abuso e cotas independentes
- **WHEN** o mesmo IP excede 5 tentativas por hora ou a combinação IP/e-mail excede 2
- **THEN** responde `429` com `Retry-After` e não enfileira mensagem
- **AND** as cotas de SignUp e SignIn não são consumidas pelo reenvio
