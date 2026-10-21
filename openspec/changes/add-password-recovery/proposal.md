## Why

Contas que esquecem a senha não possuem um caminho de recuperação na API. Precisamos permitir a redefinição segura para contas ativas com e-mail verificado, preservando a arquitetura de Identity e invalidando todas as sessões anteriores.

## What Changes

- Adicionar `POST /api/authentication/forgot-password`, público, com resposta genérica `202 Accepted`, sem revelar existência ou aptidão da conta.
- Adicionar `POST /api/authentication/reset-password`, público, com sucesso `204 No Content`, sem login automático.
- Emitir link de uso único, válido por 30 minutos; nova emissão admitida invalida o anterior. Usar `PASSWORD_RESET_URL` por ambiente e acrescentar `token` e `email` de forma segura.
- Permitir emissão e consumo somente para conta `active` com e-mail verificado, sem ativar contas ou confirmar endereços implicitamente.
- Aplicar cotas independentes de 6 requisições por IP a cada 10 minutos em cada endpoint; manter intervalo global mínimo de 60 segundos por e-mail entre emissões, com resposta genérica durante esse intervalo.
- Reutilizar integralmente a política atual de senha e exigir confirmação; rejeitar senha igual à atual sem consumir o link.
- Alterar senha, consumir o token e revogar todos os Personal Access Tokens atomicamente; enviar aviso por e-mail depois do commit, sem rollback por falha de envio.
- Acrescentar persistência incremental dos hashes de recuperação, configuração, notificações e evidências automatizadas focadas.
- Não implementar páginas web, aplicativo, App Links/Universal Links, redirecionamento ou login automático. Esta solicitação autoriza somente os artefatos OpenSpec, não a implementação.

## Capabilities

### New Capabilities

- `password-recovery`: solicitação e redefinição de senha pela API, incluindo elegibilidade, link, limites, atomicidade, revogação de sessões e notificações.

### Modified Capabilities

Nenhuma. Os novos endpoints ampliam Identity sem substituir os contratos existentes de cadastro, login, verificação, perfil ou SignOut seletivo.

## Impact

- Contexto `Identity`: Presentation HTTP, UseCases, Ports/Repositories, adapters, notifications e bindings; coordenação transacional existente de Core.
- Composition roots: configuração Laravel, `.env.example`, rate limiters e migration incremental de `password_reset_tokens`.
- PostgreSQL para token de recuperação e unidade atômica; Redis para cotas compartilhadas e entrega assíncrona pelo mailer/fila já existentes, sem nova dependência de produto.
- Testes focados nas camadas proprietárias de Identity, com classificação da nova tabela no cleanup seguro do launcher.
- Consumidor: fornecer o destino em `PASSWORD_RESET_URL`, tratar o link no app e chamar a API. Implementar o consumidor está fora desta entrega.
- Não há breaking change nos endpoints existentes. A revogação global é consequência explícita do sucesso do novo fluxo de recuperação.
