## Why

Os endpoints públicos de cadastro e login podem ser chamados repetidamente sem limite, expondo a API a tentativas automatizadas de credenciais e à criação abusiva de contas. Uma política pequena, localizada em Identity, protege esses fluxos sem introduzir infraestrutura genérica prematuramente.

## What Changes

- Limitar `POST /api/authentication/sign-in` por combinação de IP e e-mail informado e também por IP, inclusive quando o e-mail varia.
- Limitar `POST /api/authentication/sign-up` por IP.
- Responder `429` em JSON:API com orientação de espera quando o limite for excedido; requisições dentro do limite preservam os contratos atuais.
- Usar o Redis já disponível no Lerd somente como armazenamento compartilhado dos contadores do rate limiter, preservando o store geral de cache.
- Manter fora do escopo as rotas autenticadas, `sign-out`, bloqueio permanente de conta, CAPTCHA, troca de banco de dados e uma estratégia de cache de respostas.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `authentication`: acrescenta proteção por taxa às rotas públicas de SignIn e SignUp e define o comportamento de resposta ao esgotar os limites.

## Impact

- Políticas de rate limit registradas no provider de Identity e aplicadas às duas rotas públicas de Authentication.
- O armazenamento dos contadores usa um store Redis dedicado via configuração do limiter, sem nova dependência PHP ou migration; a configuração de cache geral permanece independente.
- Clientes podem receber `429` com `Retry-After` em vez de `200`, `201`, `401`, `409` ou `422` após excederem o limite; não há alteração de formato nas respostas permitidas.
- Nenhuma mudança em Domain, Application, Controllers, UseCases, Sanctum ou API autenticada.
