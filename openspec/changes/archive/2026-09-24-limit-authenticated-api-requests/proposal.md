## Why

As rotas protegidas por Sanctum ainda não têm limite de uso por conta: um User pode enviar requisições sem cota, inclusive alternando tokens ou IPs. Uma política transversal para a API autenticada complementa os limites públicos de cadastro e login sem misturá-los.

## What Changes

- Aplicar uma cota inicial de 60 requisições por minuto por User autenticado, compartilhada entre rotas de Identity e Expense, tokens e origens de rede do mesmo User.
- Incluir os endpoints protegidos atuais de User e Expense na mesma cota, contando requisições admitidas independentemente do resultado; deixar SignOut livre para permitir a revogação do token mesmo após esgotar a cota.
- Retornar `429` em JSON:API com `Retry-After` após o esgotamento; requisições sem token válido continuam recebendo `401` sem consumir cota de User.
- Usar o store Redis do rate limiter configurado na mudança `limit-public-authentication-attempts`, sem alterar o cache geral.
- Manter as rotas públicas de SignIn e SignUp com limites próprios e não introduzir quotas específicas por endpoint, IP ou token nesta etapa.

## Capabilities

### New Capabilities

- `authenticated-api-rate-limiting`: Define cota compartilhada, identificação da conta, tratamento de requisições não autenticadas e resposta ao esgotamento em rotas protegidas.

### Modified Capabilities

Nenhuma: os contratos de negócio, autenticação e recursos existentes permanecem válidos dentro da cota.

## Impact

- Um limitador HTTP compartilhado e a aplicação dele nas rotas de User e Expense protegidas por Sanctum; SignOut permanece fora da cota, sem mudanças em Domain ou Application.
- Os clientes autenticados passam a poder receber `429` com `Retry-After` quando excederem a cota, sem alteração nas respostas de sucesso dentro dela.
- A implementação depende da disponibilidade do Redis para os contadores e da precedência de `auth:sanctum` sobre o throttle de User; não requer migration nem dependência nova.
- A pendência operacional da primeira mudança (IP/proxy e confirmação do armazenamento compartilhado no ambiente de implantação) continua visível e não é encerrada por esta spec.
