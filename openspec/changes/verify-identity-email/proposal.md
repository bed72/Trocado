## Why

SignUp cria contas `pending` sem token, mas não confirma a posse do endereço de e-mail. SignIn já exige `active`, porém emite token sem conferir se o e-mail é verificado. Queremos confirmar o endereço sem confundir essa confirmação com a ativação manual da conta e sem introduzir Laravel nas camadas internas de Identity.

## What Changes

- Persistir `users.email_verified_at` nullable; contas novas começam sem verificação e continuam `pending` depois de confirmar o e-mail.
- Solicitar, depois do commit do cadastro, uma notificação Laravel de verificação enfileirada em Redis e entregue pelo mailer configurado; conservar `201`, `sign-ups`, relacionamento `user` e `Location`, sem token.
- Aceitar link temporário assinado sem exigir login; conferir assinatura, identificador e hash do e-mail atual; marcar somente o e-mail como verificado, sem ativar a conta nem emitir token.
- Exigir e-mail verificado **e** conta `active` antes da emissão de token no SignIn e nas rotas protegidas; preservar autenticação, ownership e recursos JSON:API existentes.
- Impedir alteração do e-mail pela API de User nesta etapa: `PATCH /api/users/{user}` aceita somente nome e rejeita qualquer tentativa de editar e-mail com `422`, preservando verificação e tokens.
- Propor reenvio público de verificação com resposta uniforme e limites independentes para recuperação de mensagem perdida/falha.
- Cobrir por testes as invariantes, a fronteira arquitetural, a fila/commit, o link, SignIn, o reenvio e a revogação.

## Capabilities

### New Capabilities

Nenhuma; o lifecycle de verificação pertence a Identity.

### Modified Capabilities

- `authentication`: verificação por e-mail, envio assíncrono, confirmação pública assinada, reenvio e impedimento de emissão/uso de tokens antes de e-mail verificado e ativação.
- `user`: persistência do estado de verificação e restrição da atualização de User ao nome, sem editar o e-mail.
- `identity-context`: fronteira Application/Infrastructure para solicitar o envio e uso da integração nativa Laravel sem contaminar Domain.

## Impact

- Identity Application, Infrastructure e Presentation; migration incremental em `users`; binding em `IdentityServiceProvider`; rotas novas de verificação e reenvio; PATCH de User limitado ao nome; adaptação dos testes de Identity e dos helpers de conta autenticada.
- Nenhum novo contexto, guard ou formato de token; Sanctum continua responsável pelos Personal Access Tokens. Expense somente continua protegida por autenticação e pelos middlewares compartilhados de conta elegível.
- Redis deve processar a queue de verificação; o transporte de e-mail do ambiente deve estar configurado. A integração com Resend fica para outra mudança.
- Contas existentes são descartáveis **por decisão operacional do proprietário**, não por migration destrutiva desta mudança. A aplicação ainda deve funcionar corretamente quando um registro existente tiver `email_verified_at = null`.
