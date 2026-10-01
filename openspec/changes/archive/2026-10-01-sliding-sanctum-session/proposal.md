## Why

Um app de finanças pode ser aberto apenas a cada semana ou quinzena; os atuais 120 minutos de validade obrigam o usuário a digitar as credenciais novamente a cada visita. Queremos preservar o mesmo token opaco Sanctum durante uma sessão ativa, sem criar um token por acesso nem introduzir refresh token.

## What Changes

- **BREAKING:** substituir a expiração fixa de 120 minutos por uma janela de validade de 30 dias desde a emissão ou última extensão efetiva, com renovação do `expires_at` do mesmo token quando faltarem 15 dias ou menos, limitada a 90 dias desde sua emissão.
- Aplicar a extensão somente após requisições autenticadas e bem-sucedidas às rotas protegidas de User e Expense; logout, erros, acessos negados e rotas públicas não estendem a sessão.
- Manter a geração, hash, autenticação, revogação e limpeza de tokens com Sanctum; não emitir outro token nem devolver o segredo original na renovação.
- Preservar logins independentes e revogação seletiva; a mudança evita tokens adicionais por atividade, sem prometer apenas um login/dispositivo por conta.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `authentication`: alterar a política de expiração, estabelecer renovação por atividade e limite absoluto de sessão, e explicitar os efeitos sobre SignIn, SignOut e respostas protegidas.

## Impact

- Identity: política de emissão e extensão do token Sanctum, configuração de expiração e integração nas rotas protegidas de Identity e Expense.
- API: formato do Bearer e contrato JSON:API de SignIn permanecem; seu `expires_at` passa a ser a expiração inicial, não uma promessa de validade imutável. Sem acesso na metade final da janela de validade, o token vence; após 90 dias absolutos, a API responde `401` e exige novo SignIn.
- Armazenamento: reaproveita `personal_access_tokens.expires_at`, `created_at` e o pruning agendado. Sem migration, dependência nova, cookie, JWT ou tabela de refresh.
