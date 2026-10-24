## Why

A produção usa Apache prefork com PHP, enquanto o desenvolvimento usa Nginx + PHP-FPM. Queremos aproximar os modelos de execução e administrar explicitamente os processos PHP na VPS compartilhada de 2 vCPUs e 8 GB, preservando segurança e otimizações antes de considerar Octane, sem presumir que Apache seja o gargalo ou prometer ganho de desempenho.

## What Changes

- Substituir o atendimento Apache por Nginx + PHP-FPM atrás do Traefik, com releases coerentes entre arquivos públicos e código PHP.
- Preservar o build pelo Dokploy a partir do mesmo checkout e o acesso aos serviços pela rede existente, sem exigir variável manual de revisão ou uma nova rede externa de dados. FPM compartilha a rede Dokploy para banco/Redis, mas seu listener fica restrito à interface FastCGI dedicada e sem porta publicada.
- Preservar autenticação, HTTPS externo, links assinados, query strings, contratos JSON:API, limites de requisição e headers de segurança existentes.
- Restringir execução ao front controller, impedir exposição de arquivos internos e FastCGI, ocultar versões e remover `X-Powered-By`, sem módulos adicionais apenas para remover o nome Nginx.
- Manter gzip, OPcache, autoload otimizado, caches Laravel e isolamento dos processos de migration, filas, scheduler e Nightwatch.
- Definir orçamento do pool PHP-FPM a partir de medições e do consumo dos demais serviços da mesma VPS, incluindo PostgreSQL e Redis.
- Prever validação dos containers antes da publicação, smoke checks controlados em produção e rollback documentado para a release Apache. Homologação permanente e deploy sem interrupção não são requisitos.
- Registrar comparação antes/depois sob condições equivalentes, sem ampliar o runner de carga local para produção nem alterar limiter para obter números melhores.

Não fazem parte desta mudança: Octane, Brotli, CDN, réplicas adicionais, cache HTTP compartilhado de respostas, mudanças de negócio, schema ou políticas atuais de cache de aplicação. A escrita desta spec não autoriza implementação, benchmark ou deploy.

## Capabilities

### New Capabilities

- `production-http-runtime`: contrato operacional de entrega HTTP via Nginx + PHP-FPM, incluindo isolamento, compatibilidade, otimizações, dimensionamento, verificação e reversão.

### Modified Capabilities

Nenhuma. Os contratos existentes de autenticação, erros, consultas, observabilidade e rate limiting permanecem inalterados. O cache de páginas de Expense continua sendo cache de dados da aplicação, não cache de respostas no servidor HTTP.

## Impact

- No futuro apply: `Dockerfile`, `docker-compose.yml`, `deploy/`, documentação de produção no `README.md` e configuração do serviço Compose no Dokploy; imagens Nginx e PHP-FPM substituem a imagem Apache no caminho HTTP.
- PHP mantém versão e extensões compatíveis com a release atual; não há nova dependência Composer/npm nem mudança nos bounded contexts. A capability é de infraestrutura de deploy, não um novo contexto em `app/`.
- **BREAKING operacional:** o serviço HTTP deixa de executar PHP diretamente; o deploy deve publicar conjuntamente as imagens/configurações Nginx e FPM. Configuração Apache não é reutilizável no novo runtime. A interface pública da API não muda.
- Traefik continua terminando TLS. PostgreSQL, Redis, volumes persistentes e credenciais permanecem existentes. Nenhuma recriação de dados é necessária.
- A publicação e qualquer medição em produção exigem autorização operacional própria; esta entrega altera apenas os artefatos da mudança.
