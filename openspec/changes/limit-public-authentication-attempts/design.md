## Context

Identity expõe SignIn e SignUp publicamente sem throttle; as demais rotas usam Sanctum. Laravel 13 oferece limitadores nomeados aplicáveis via middleware de rota e permite escolher um store específico para os contadores. O cache efetivo do ambiente Lerd é `file`, apesar de o valor de fallback em `config/cache.php` ser `database`; o tratamento HTTP existente já adapta `429` ao envelope JSON:API. O Redis já está instalado como serviço Lerd. Esta mudança altera apenas o limite HTTP de Identity e o armazenamento dos seus contadores.

## Goals / Non-Goals

**Goals:**

- Restringir tentativas automatizadas de login e cadastro com limites distintos e previsíveis.
- Preservar o erro JSON:API e o tempo de espera para o cliente sem distinguir usuários existentes de inexistentes.
- Manter Controllers, UseCases, Domain e Application sem lógica de rate limit.

**Non-Goals:**

- Trocar o store geral de cache, implementar bloqueio de conta, CAPTCHA ou limitar rotas autenticadas e SignOut.
- Criar um framework genérico em Core ou adicionar infraestrutura de contadores própria.

## Decisions

### Limitadores nomeados pertencem a Identity

Registrar `authentication.sign-in` e `authentication.sign-up` no `IdentityServiceProvider` usando o rate limiter do Laravel; aplicar `throttle:<nome>` às respectivas rotas em `Identity/Presentation/Routes/api.php`. Não criar classe ou Port apenas para delegar uma chamada ao framework. A política é específica dos endpoints de Identity; Core fica reservado para uma necessidade transversal real. Alternativa rejeitada: middleware/serviço genérico próprio, que duplica Laravel e espalha abstração sem consumidor adicional.

### SignIn tem duas barreiras, SignUp tem uma

Para SignIn: 5/min por IP + e-mail e 30/min por IP, com chaves distintas para impedir colisão entre limites. Canonicalizar o e-mail usado na chave pela mesma intenção do SignIn (espaços externos e caixa), aceitar e-mail ausente/malformado sem erro de chave e usar digest da parte variável para não persistir endereço em texto claro no cache. O limite por IP protege quando o atacante alterna e-mails; não se usa limite por e-mail isolado, pois permitiria a terceiros prejudicar uma conta a partir de IPs diferentes. Para SignUp: 3/h por IP. Contar todas as requisições admitidas, inclusive inválidas e bem-sucedidas: contar só falhas pode permitir abuso ou aumentar a complexidade de resposta. Uma requisição rejeitada pelo throttle não chega ao fluxo de criação/token.

### O limiter usa Redis sem alterar o cache geral

Configurar a chave `limiter` de `config/cache.php` para usar o store `redis`, com `CACHE_LIMITER_STORE=redis` documentado no ambiente. Todas as instâncias devem usar o mesmo Redis; confirmar a resolução de `REDIS_HOST` no Lerd e no ambiente de implantação. Não alterar `CACHE_STORE`: outros usos de cache continuam independentes. Na suíte automatizada, configurar `CACHE_LIMITER_STORE=array` no `phpunit.xml`, antes da inicialização do provider, para isolar contadores sem exigir Redis nos testes; alterar `config('cache.limiter')` durante o teste não substitui o singleton já registrado. Redis já é um serviço declarado no Lerd e o store `redis` já está presente na configuração Laravel; não há nova migration nem package. Reaproveitar o mapeamento existente de `429` em `bootstrap/app.php` e confirmar que `Retry-After` é preservado junto ao Content-Type JSON:API. Alternativa rejeitada: manter o limiter sobre `file` (não compartilhado entre instâncias) ou migrar todo o cache para Redis sem necessidade.

## Risks / Trade-offs

- [IPs compartilhados em NAT podem esgotar a cota de SignUp] → Propor 3/h como valor inicial para a POC e revisar com tráfego real; o limite por IP é deliberadamente comum à rede.
- [Proxies incorretamente configurados podem atribuir o mesmo IP a todos ou aceitar IP forjado] → Verificar resolução de IP e configuração de proxies confiáveis no ambiente de implantação antes da liberação.
- [Redis indisponível impede contagem confiável] → Confirmar o serviço e a conexão antes de servir tráfego; não usar fallback silencioso para `file` que eliminaria a garantia de compartilhamento.
- [Apenas throttle não impede tentativas distribuídas] → A proteção tem escopo de contenção por origem, sem prometer bloquear ataque distribuído.

## Migration Plan

Não há migration de schema nem migração de dados. Configurar o store Redis do limiter e verificar acesso a ele antes de publicar os middlewares de rotas; validar limites, expiração e headers com os fluxos HTTP. Em rollback, remover os middlewares das duas rotas e os registros dos limitadores; os contadores temporários no Redis expiram naturalmente.

## Open Questions

Nenhuma bloqueadora para a spec. Os valores 5/min, 30/min e 3/h são os valores iniciais propostos; podem ser revistos antes da implementação se o uso esperado da POC exigir mais tentativas por IP.
