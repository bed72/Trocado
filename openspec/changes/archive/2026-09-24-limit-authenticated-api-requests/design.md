## Context

Identity e Expense têm rotas protegidas por `auth:sanctum`, sem limite de uso autenticado. A mudança ativa `limit-public-authentication-attempts` registra limites próprios em Identity e configura o store Redis exclusivo do rate limiter, sem alterar o cache geral. A nova cota cobre operações HTTP de dois bounded contexts, não regras de negócio de um deles. A configuração atual do Laravel deve ser conferida quanto à ordem efetiva de middleware: a execução de autenticação antes do limitador é parte do contrato, não uma suposição baseada apenas na ordem escrita nas rotas.

## Goals / Non-Goals

**Goals:**

- Uma cota inicial simples, compartilhada por User entre endpoints autenticados de Identity e Expense, preservando SignOut livre para revogação.
- Preservar `401` para não autenticados e JSON:API/`Retry-After` para `429` autenticado.
- Reutilizar Redis e o throttle nativo do Laravel, sem afetar as cotas públicas.

**Non-Goals:**

- Alterar quotas de SignIn/SignUp, introduzir política por token, IP, papel ou endpoint, autorizar acesso de negócio ou adicionar cache de respostas.
- Criar abstração de rate limit na Domain/Application, infraestrutura própria de contador ou suporte genérico especulativo.

## Decisions

### Política HTTP compartilhada pertence a Core Infrastructure

Registrar um limitador nomeado, por exemplo `api.authenticated`, em um `AuthenticatedApiRateLimitServiceProvider` de `Core/Infrastructure/Providers`, ligado no composition root `bootstrap/providers.php`. O callback usa o identificador autenticado pelo guard do Laravel com prefixo de chave próprio; não importa `UserModel` de Identity nem depende do token atual. Assim a capacidade HTTP transversal fica em Core Infrastructure, e os contextos aplicam o mesmo nome de limitador nos endpoints protegidos de User e Expense. SignOut fica apenas sob `auth:sanctum`, sem throttle autenticado, para permitir revogar um token mesmo após esgotar a cota. SignIn e SignUp permanecem com limitadores separados. Alternativa rejeitada: duplicar políticas entre providers de Identity e Expense ou envolver RateLimiter em Port de Application sem UseCase consumidor.

### Auth precisa executar antes do throttle compartilhado

Configurar as rotas para que o guard Sanctum seja resolvido antes da política baseada em User e verificar a ordem real de execução sob Laravel 13 (incluindo a prioridade global de middleware). Se a ordenação automática inverter essa precedência, ajustar o composition root com a menor configuração de prioridade necessária e provar com requisições sem token, token inválido e token válido. Não inventar chave por IP para visitantes anônimos: esses devem receber `401` sem consumir a cota autenticada.

### Uma janela e uma chave por identidade

Definir inicialmente 60 requisições por minuto por identificador autenticado, com prefixo que não colida com SignIn ou SignUp. Contar requisições admitidas independentemente do status posterior (inclusive 4xx), sem alterar o resultado das operações que ficaram dentro do limite. O resultado `429` segue o tratamento JSON:API existente em `bootstrap/app.php` e conserva `Retry-After`; o endpoint não executa o fluxo bloqueado. Limitar por token permitiria contornar a cota emitindo outros tokens; limitar por IP penalizaria Users diferentes na mesma rede. Não adicionar multiplicidade de janelas até existir requisito ou tráfego que a justifique.

### Redis é a dependência operacional de ambos os limites

Usar o store `cache.limiter` definido na mudança pública, configurado para Redis em execução normal e `array` na suíte automatizada. Uma falha de Redis não pode desabilitar o limite silenciosamente. Sem nova migration ou dependência de pacote. Antes da implantação, conferir o storage Redis compartilhado e a ordem real dos middlewares no ambiente-alvo; a pendência 2.4 da mudança pública não é automaticamente resolvida por esta spec.

## Risks / Trade-offs

- [O middleware de throttle pode ser ordenado antes da autenticação pelo framework] → Verificar a execução real e, se necessário, ajustar prioridade em `bootstrap/app.php` antes de afirmar `401` sem consumo de cota.
- [Uma cota agregada pode penalizar uso intenso e legítimo] → Começar em 60/min, monitorar respostas `429` e rever o valor com dados; operações de leitura e escrita compartilham o orçamento por simplicidade.
- [SignOut não participa da cota agregada] → Manter somente a exigência de `auth:sanctum` nesse endpoint; aceitar a exceção para garantir que um token ainda possa ser revogado após esgotar a cota.
- [Redis indisponível afeta endpoints limitados] → Verificar a conectividade e não cair silenciosamente para `file` ou `array` fora dos testes.

## Migration Plan

Não há schema ou dados a migrar. Primeiro verificar que a mudança pública fornece Redis como store do limiter; depois registrar a política compartilhada e anexá-la somente às rotas autenticadas, verificando autenticação antes de throttle e contratos de erro. Em rollback, remover os middlewares autenticados e o provider de Core; os contadores expiram no Redis sem limpeza manual.

## Open Questions

Nenhuma questão bloqueadora. A cota inicial de 60/min por User e a exclusão de SignOut foram escolhidas para esta versão da spec; ajustes posteriores exigem revisão dos artefatos antes do apply.
