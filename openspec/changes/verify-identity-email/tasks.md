## 1. Persistência e fronteiras

- [x] 1.1 Criar migration incremental e reversível para `users.email_verified_at` nullable, sem apagar/backfill de contas; verificar schema aplicado antes de fluxos dependentes da coluna.
- [x] 1.2 Adaptar `UserModel` ao contrato nativo `MustVerifyEmail`, `Notifiable` e cast de timestamp; manter senha/token ocultos e `UserEntity` independente.
- [x] 1.3 Introduzir `EmailVerificationPort` e Adapter próprios de Identity; registrar binding e usar `Registered` somente no cadastro, sem duplicar o listener oficial.
- [x] 1.4 Fazer SignUp solicitar uma única notificação depois do commit usando `TransactionPort::afterCommit`; preservar o contrato `201`, `Location`, `sign-ups` e ausência de token.

## 2. Queue, mailer e confirmação

- [x] 2.1 Enfileirar notification que aproveite `VerifyEmail` nativa, implementando `ShouldQueue` e processamento pelo Redis; assegurar que job obsoleto não mande link antigo ao endereço novo.
- [x] 2.2 Confirmar transporte SMTP/Mailpit local, Redis e worker efetivos; adiar integração e dependência Resend para outra mudança, sem credenciais versionadas.
- [x] 2.3 Adicionar rota pública assinada `verification.verify` e handler fino que confira ID/hash atual, confirme e-mail, emita `Verified` uma vez e responda `204`, `403` seguro para links inválidos, sem mudar status ou token.
- [x] 2.4 Decidir e implementar, se aprovado, reenvio público uniforme `202`, com documento JSON:API e throttle Redis independente (`429` + `Retry-After`).

## 3. SignIn, acesso e alteração de User

- [x] 3.1 Bloquear emissão de token para conta `active` não verificada em `SignInAdapter` sem alterar Sanctum, sem revelar existência para credenciais inválidas e sem alterar erro de `pending`/`blocked`.
- [x] 3.2 Proteger rotas autenticadas de User/Expense contra e-mail não verificado, preservando status, ownership e SignOut; verificar resposta JSON:API.
- [x] 3.3 Impedir e-mail no PATCH com `422` JSON:API, inclusive se for o mesmo endereço; preservar e-mail, verificação e tokens sem reenvio; manter ownership e remover capacidade de alteração de e-mail do Repository.
- [x] 3.4 Garantir que edição só de nome preserve verificação, tokens e resposta HTTP; entradas inválidas não alteram a conta.

## 4. Testes e verificação da futura implementação

- [ ] 4.1 Testes de SignUp e Repository: pending/null, hash de password, `201`/`Location`/relacionamento, nenhum token, um envio pós-commit, nenhum no rollback/retry/conflito. Rollback e conflito estão cobertos; falta demonstrar retry real.
- [ ] 4.2 Testes da notification/queue: `ShouldQueue`, Redis/worker, assinatura e expiração, transporte local isolado, falha/retry e supressão de envio obsoleto após alteração externa/exclusão. Job simulado e expiração cobertos; faltam falha/retry e consumo pelo worker real.
- [x] 4.3 Testes HTTP de confirmação: pending/blocked mantêm status; link válido e repetido; ID/hash errados, URL adulterada/expirada; evento `Verified` uma vez após commit; rollback sem evento; nenhum token; respostas JSON:API.
- [x] 4.4 Testes de SignIn e rotas protegidas: credencial errada preserva `401`, active/null recebe falha sem token, verified/pending continua proibido, verified/active recebe token; token antigo sem verificação é negado em User e Expense.
- [x] 4.5 Testes de PATCH: e-mail diferente ou equivalente recebe `422` e preserva User/verificação/tokens; edição só de nome mantém tokens; terceiro recebe `404`; Repository não persiste e-mail em update.
- [x] 4.6 Reenvio aprovado: testar resposta genérica, destinatário elegível, throttles isolados, `429`/`Retry-After`, nenhuma enumeração ou disparo para conta já verificada.
- [x] 4.7 Atualizar helpers/fixtures e testes arquiteturais, conferir migrations pendentes no Lerd antes de fluxos dependentes do schema, executar verificações focadas de Identity e Expense, Pint nos PHP alterados, revisar diff e validar OpenSpec strict; deixar desmarcado o que não tiver evidência.
