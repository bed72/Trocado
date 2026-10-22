# password-recovery Specification

## Purpose

Definir a recuperação de senha de contas aptas pela API de Identity, com respostas públicas seguras, tokens temporários de uso único, revogação atômica das sessões e entrega assíncrona protegida, sem implementar interfaces de cliente ou login automático.

## Requirements
### Requirement: Recuperação pertence a Identity e não implementa interfaces de cliente

O sistema MUST oferecer recuperação de senha somente pela API pública de Identity, mantendo Domain/Application independentes de Laravel, Eloquent, HTTP e Sanctum. MUST manter senha/hash/token fora de UserEntity e das respostas. MUST NOT implementar páginas web, telas do aplicativo, associação de App Links/Universal Links, redirecionamento, ativação de conta, confirmação de e-mail ou login automático nesta capacidade.

#### Scenario: Consumidor conclui recuperação
- **WHEN** um aplicativo recebe o link e chama a API com uma nova senha
- **THEN** a API processa a recuperação sem servir formulário HTML ou redirecionar o consumidor
- **AND** nenhuma conta, verificação de endereço ou sessão é criada implicitamente

### Requirement: Solicitação pública possui contrato uniforme

O sistema MUST expor `POST /api/authentication/forgot-password`, nome `authentication.api.forgot-password`, sem Bearer obrigatório. MUST aceitar documento JSON:API fechado com `data.type = password-recovery-requests` e somente `email` em `data.attributes`, obrigatório, string, válido e com até 255 caracteres. MUST canonicalizar o e-mail conforme Identity antes de lookup e limites por endereço. Para documento válido e dentro da cota por IP, MUST retornar `202 Accepted`, media type JSON:API e `meta.message = Se a conta estiver apta, enviaremos as instruções de recuperação.`, sem `data` ou indicação de existência, status, verificação, emissão ou entrega. Documento inválido MUST retornar `422` JSON:API com pointers pertinentes, sem emitir token ou notificação.

#### Scenario: Conta apta solicita recuperação
- **WHEN** a solicitação contém e-mail de conta ativa e verificada e os limites permitem emissão
- **THEN** responde `202` com a mensagem genérica em `meta.message`
- **AND** solicita o envio de um link sem retornar token no documento

#### Scenario: Conta inexistente ou inapta
- **WHEN** o endereço não existe ou pertence a conta pending, blocked ou sem e-mail verificado
- **THEN** responde com o mesmo status, media type e corpo de uma solicitação apta
- **AND** não emite token nem solicita e-mail

#### Scenario: Documento inválido ou atributos extras
- **WHEN** falta e-mail, o formato é inválido, o resource type diverge ou há atributo desconhecido
- **THEN** responde `422` JSON:API com pointer pertinente
- **AND** não emite token nem solicita envio

### Requirement: Elegibilidade é verificada na emissão e no consumo

O sistema MUST emitir e consumir tokens somente para conta existente com `status = active` e e-mail verificado. MUST revalidar a elegibilidade e a correspondência com o e-mail atual sob coordenação concorrente antes da emissão e antes de qualquer escrita de redefinição. MUST NOT alterar status ou `email_verified_at`. Falha de elegibilidade no consumo MUST usar a mesma resposta pública de link inválido.

#### Scenario: Estado muda após emissão
- **WHEN** um link foi emitido para conta apta, mas antes da redefinição ela fica pending, blocked ou não verificada
- **THEN** a redefinição responde com o `422` uniforme de link inválido
- **AND** não altera senha, tokens de acesso, status ou verificação

#### Scenario: Conta removida ou endereço alterado
- **WHEN** o consumo usa link de conta removida ou cujo e-mail atual diverge do endereço vinculado
- **THEN** responde com o mesmo `422` de link inválido
- **AND** não aplica a recuperação a outra identidade

### Requirement: Link é configurável e não executa alteração por abertura

O sistema MUST ler a URL-base de uma configuração Laravel alimentada por `PASSWORD_RESET_URL` por ambiente, sem `env()` nas classes de fluxo. MUST acrescentar `token` e `email` por codificação de query segura, preservando eventual query não reservada. MUST usar destino fixo confiável configurado pelo operador, HTTPS em produção, sem aceitar URL de retorno do request ou derivar o destino do header Host. MUST rejeitar configuração ausente ou inválida operacionalmente sem gerar link falso, usar URL da API como fallback ou expor erro de configuração associado à existência de uma conta. Abertura do link MUST NOT consumir token, alterar senha ou emitir sessão.

#### Scenario: URL configurada
- **WHEN** uma emissão é admitida e há destino HTTPS válido em `PASSWORD_RESET_URL`
- **THEN** o e-mail contém o destino configurado com `token` e e-mail canônico codificados
- **AND** não exige uma página web fornecida por esta API

#### Scenario: Tentativa de substituir destino
- **WHEN** um request fornece Host diferente ou atributo de redirecionamento
- **THEN** o Host não modifica o destino e atributo extra é rejeitado pela validação

#### Scenario: Configuração inválida
- **WHEN** a URL está ausente, malformada ou possui parâmetros reservados token/email previamente definidos
- **THEN** o sistema registra falha operacional sanitizada e não solicita envio de link inválido
- **AND** uma solicitação válida conserva o `202` genérico independentemente da existência da conta

#### Scenario: Scanner abre o link
- **WHEN** o destino do e-mail é pré-aberto por um scanner ou navegador
- **THEN** nenhuma alteração na API ocorre sem o POST explícito de redefinição

### Requirement: Token temporário tem armazenamento seguro e rotação serializada

O sistema MUST gerar token criptograficamente seguro, persistir somente seu hash no armazenamento de recuperação e vinculá-lo ao e-mail canônico da conta. MUST manter no máximo um token corrente por endereço e validade de 30 minutos contados da emissão confirmada. O token MUST ser rejeitado a partir de `created_at + 30 minutos`, inclusive. Uma nova emissão admitida MUST invalidar o token anterior atomicamente, inclusive entre processos concorrentes. MUST NOT renovar prazo ou invalidar o link por solicitação suprimida pelo intervalo de 60 segundos, erro de validação ou mera abertura do link.

#### Scenario: Prazo e limite exato
- **WHEN** um token é apresentado antes de completar 30 minutos e as demais condições são válidas
- **THEN** ele pode ser consumido
- **AND** no instante exato de 30 minutos ou depois responde com o `422` uniforme de link inválido

#### Scenario: Reemissão admitida
- **WHEN** a conta solicita novo link após o intervalo mínimo
- **THEN** somente o novo token permanece válido
- **AND** o link anterior responde com o `422` uniforme de link inválido

#### Scenario: Emissões simultâneas
- **WHEN** dois processos tentam emitir token para o mesmo e-mail ao mesmo tempo
- **THEN** somente uma emissão é admitida na janela de 60 segundos
- **AND** ambas as solicitações válidas recebem o mesmo `202` genérico e existe somente um token corrente

### Requirement: Limites de recuperação são compartilhados e independentes

O sistema MUST limitar cada um dos dois endpoints a 6 requisições por IP a cada 10 minutos, com contadores independentes entre endpoints e em relação a SignIn, SignUp e reenvio de verificação. Requisições admitidas MUST contar independentemente do resultado, inclusive documento inválido e sucesso. MUST usar o limiter Redis compartilhado configurado, sem fallback silencioso local. A sétima requisição do endpoint na janela MUST retornar `429` JSON:API com `Retry-After` antes de efeitos de recuperação. A emissão MUST também respeitar intervalo mínimo de 60 segundos por e-mail canônico, global entre IPs; durante esse intervalo MUST conservar `202` e não emitir, substituir ou reenviar token. Chaves de limite MUST NOT armazenar e-mail ou token em claro.

#### Scenario: Cota por IP esgotada
- **WHEN** um IP envia seis requests a forgot-password ou seis a reset-password na janela de dez minutos
- **THEN** o sétimo request daquele endpoint responde `429` com `Retry-After`
- **AND** não emite token, envia e-mail, altera senha ou revoga sessão

#### Scenario: Cotas independentes
- **WHEN** um IP esgota forgot-password
- **THEN** reset-password e as cotas de outros fluxos de Authentication não são consumidos por essas tentativas
- **AND** outro IP mantém sua própria cota

#### Scenario: Intervalo por e-mail entre origens distintas
- **WHEN** dois IPs solicitam o mesmo endereço canônico com menos de 60 segundos desde a emissão anterior
- **THEN** a nova solicitação válida recebe `202` genérico e não envia outra mensagem
- **AND** o token anterior e seu prazo permanecem inalterados

#### Scenario: Reabertura e canonicalização
- **WHEN** passam 60 segundos da emissão e uma solicitação válida usa variação equivalente de caixa ou espaços externos do e-mail
- **THEN** a mesma identidade canônica pode receber nova emissão se a cota por IP permitir

#### Scenario: Instâncias e indisponibilidade
- **WHEN** duas instâncias recebem requests para a mesma cota por IP
- **THEN** aplicam o contador combinado Redis
- **AND** indisponibilidade do limiter não libera tentativas por substituição silenciosa por contador local

### Requirement: Redefinição pública valida documento e política existente

O sistema MUST expor `POST /api/authentication/reset-password`, nome `authentication.api.reset-password`, sem Bearer obrigatório. MUST aceitar documento JSON:API fechado com `data.type = password-resets` e somente `email`, `token`, `password` e `password_confirmation` em `data.attributes`, todos obrigatórios e strings; e-mail MUST ter formato válido e até 255 caracteres. MUST exigir confirmação idêntica e reutilizar integralmente a política atual de senha de Identity: de 6 a 32 caracteres, até 72 bytes, ao menos uma letra Unicode maiúscula e um dígito de 0 a 9. MUST preservar exatamente senha, confirmação e token, sem trim ou transformação. Erros de documento, política ou confirmação MUST responder `422` JSON:API com pointers pertinentes, sem consumir o token.

#### Scenario: Senha e confirmação válidas
- **WHEN** conta e token são aptos e senha nova satisfaz a política com confirmação idêntica
- **THEN** a API pode concluir a redefinição e responde `204 No Content`
- **AND** não retorna documento, token de acesso ou redirecionamento

#### Scenario: Senha inválida ou confirmação divergente
- **WHEN** a senha viola qualquer limite atual ou a confirmação diverge
- **THEN** responde `422` com pointer para o atributo pertinente
- **AND** o mesmo token continua utilizável dentro de seu prazo para uma tentativa válida

#### Scenario: Segredo preservado
- **WHEN** a nova senha contém espaços válidos ou caracteres multibyte
- **THEN** valida e persiste o valor exato, respeitando limites independentes de caracteres e bytes

### Requirement: Senha atual não pode ser reutilizada

O sistema MUST comparar a senha candidata ao hash atual pelo hasher configurado, somente após validar token e elegibilidade, sobre o estado persistido protegido contra concorrência. MUST rejeitar senha igual à atual com `422` JSON:API e pointer `/data/attributes/password`, sem consumir o link, alterar o hash, revogar sessões ou enviar aviso. MUST NOT criar histórico nem impedir reutilização de senhas anteriores que não sejam a atual.

#### Scenario: Senha igual à atual
- **WHEN** um token válido é usado com a mesma senha que autentica a conta atualmente
- **THEN** responde `422` indicando que a nova senha deve ser diferente da atual
- **AND** senha, token de recuperação e sessões permanecem inalterados

#### Scenario: Outra senha após rejeição
- **WHEN** o consumidor repete com senha diferente e token ainda válido
- **THEN** a rejeição anterior não impede concluir a recuperação

### Requirement: Falhas de link usam resposta pública única

O sistema MUST responder `422`, media type JSON:API, com mesmo título, status e detalhe público para token incorreto, expirado, consumido, substituído, e-mail sem token correspondente e conta inexistente ou inelegível. O detalhe MUST ser `Este link é inválido ou expirou. Solicite uma nova recuperação de senha.` e o pointer MUST ser `/data/attributes/token`. MUST NOT distinguir publicamente essas causas nem executar efeitos de recuperação. Erros estruturais de documento permanecem separados conforme suas regras de validação.

#### Scenario: Credencial de recuperação inválida
- **WHEN** um documento estruturalmente válido apresenta qualquer uma das causas de falha de link
- **THEN** recebe a mesma resposta JSON:API `422` e pointer de token
- **AND** nenhum segredo ou informação de aptidão da conta é exposto

### Requirement: Consumo e revogação global são atômicos e de uso único

O sistema MUST alterar o hash da senha, consumir o token de recuperação e excluir todos os Personal Access Tokens da conta na mesma transação PostgreSQL delimitada pelo UseCase, após revalidar token, elegibilidade e senha atual sob locks. MUST NOT revogar tokens de outra conta, emitir nova sessão ou modificar outros dados de perfil. MUST serializar emissão e consumo por conta; duas requisições simultâneas com o mesmo token MUST produzir no máximo um sucesso. Em rollback, MUST preservar senha anterior, token utilizável dentro do prazo e sessões anteriores. Revogação MUST impedir que a extensão de sessão recrie ou reviva um PAT removido.

#### Scenario: Recuperação bem-sucedida
- **WHEN** uma conta possui vários PATs e conclui uma recuperação válida
- **THEN** o hash autentica somente a nova senha e o token de recuperação é consumido
- **AND** todos os PATs da conta são removidos, os de outra conta são preservados e a API responde `204`
- **AND** o consumidor precisa realizar novo SignIn explicitamente

#### Scenario: Mesmo token em concorrência
- **WHEN** dois processos sincronizados tentam redefinir a senha com o mesmo token
- **THEN** somente um confirma a alteração e recebe `204`
- **AND** o outro recebe o `422` uniforme de link inválido, sem substituir a senha vencedora

#### Scenario: Falha durante a transação
- **WHEN** uma falha é provocada após uma escrita de senha ou revogação e antes do commit
- **THEN** rollback restaura senha, token de recuperação e PATs anteriores
- **AND** nenhum aviso de sucesso da tentativa abortada é solicitado

#### Scenario: Renovação de sessão concorrente
- **WHEN** uma extensão de sessão disputa um PAT que a recuperação remove
- **THEN** a extensão não recria nem restaura esse PAT após o commit de recuperação

### Requirement: E-mails são assíncronos e efeitos de envio não revertem a recuperação

O sistema MUST solicitar entrega do link e do aviso de alteração após seus respectivos commits, usando mailer e fila Redis existentes, sem transporte síncrono no request e sem nova integração externa. O aviso de alteração MUST NOT conter senha ou token e MUST ser solicitado somente por redefinição confirmada. Falhas de enfileiramento ou transporte MUST NOT desfazer senha, consumo ou revogação já confirmados; MUST ser registradas de forma sanitizada e usar retries/falhas normais da fila quando o job tiver sido enfileirado. MUST NOT afirmar entrega garantida ou exatamente uma vez. Falha de envio do link MUST conservar o `202` genérico; nova solicitação após o intervalo permite recuperação operacional. Jobs MUST NOT redirecionar segredos para um endereço novo se o destinatário mudou ou a conta foi excluída.

#### Scenario: Envio do link falha
- **WHEN** o enfileiramento falha depois da emissão ou o worker encontra falha de transporte
- **THEN** a solicitação mantém o `202` genérico sem fallback síncrono
- **AND** registra falha sanitizada e permite nova emissão após o intervalo de 60 segundos

#### Scenario: Aviso falha após redefinição
- **WHEN** a recuperação confirma e o enfileiramento ou transporte do aviso falha
- **THEN** a senha nova continua vigente, o token permanece consumido e todas as sessões antigas continuam revogadas
- **AND** a API mantém `204`, sem rollback

#### Scenario: Job antigo com endereço diferente ou conta removida
- **WHEN** a fila processa uma notificação cujo destinatário não corresponde mais à conta original
- **THEN** não envia o link ou aviso a um endereço substituto

### Requirement: Observabilidade e armazenamento não expõem credenciais de recuperação

O sistema MUST NOT registrar senha, confirmação, hash, token bruto, URL completa de recuperação ou payload do request em logs, métricas, exceptions públicas ou eventos de observabilidade próprios. MUST redigir esses campos também nas falhas operacionais, erros SQL e falhas de fila, e proteger o payload de entrega que necessariamente transporta o link para o worker. A tabela de recuperação MUST armazenar somente e-mail canônico, hash do token e data de emissão; MUST NOT armazenar senha ou token bruto. A configuração de exemplo MUST NOT conter credenciais reais.

#### Scenario: Inspeção de persistência e falha operacional
- **WHEN** uma emissão é persistida e uma falha de envio ou SQL é capturada
- **THEN** o armazenamento de recuperação contém hash em vez do token bruto
- **AND** campos públicos e observabilidade própria não contêm os segredos nem a URL completa
