## Context

O `Dockerfile` usa `php:8.5.12-apache-bookworm`; o Compose inicia `migrate`, `web`, `queue`, `expense-classification`, `scheduler` e `nightwatch-agent`. O README registra Apache prefork atrás do Traefik, que termina TLS. PostgreSQL, Redis e outros serviços disputam a mesma VPS de 2 vCPUs e 8 GB, conforme confirmação do operador. O Lerd local usa Nginx + PHP-FPM, mas isso não garante equivalência de versões, recursos ou configuração com produção.

Já existem build multi-stage, assets Vite, autoload otimizado sem dependências de desenvolvimento, `php.ini-production`, OPcache de 128 MiB sem revalidação de timestamps e caches de configuração/rotas/eventos preparados no startup. Apache usa rewrite no VirtualHost, gzip, HSTS e ocultação de versões. O volume `app-storage` é compartilhado pelos processos PHP; `bootstrap/cache` não é compartilhado.

As specs permanentes não contêm uma capability de deploy HTTP. A change arquivada de PostgreSQL preserva fronteiras de persistência e não define produção; as changes ativas de investigação de performance e de carga são referências de limites, não autorização para mudar consultas ou executar carga na VPS. O runner Load existente aceita somente alvo local dedicado.

Referência consultada: documentação Laravel 13 via Boost, tópicos deployment/Nginx, trusted proxies e caches de configuração/rotas. Configuração Nginx sugerida pelo framework é ponto de partida, não substitui revisão da cadeia Traefik/FastCGI nem das regras atuais.

## Goals / Non-Goals

**Goals:** separar atendimento HTTP de execução PHP; preservar contratos e segurança atuais; explicitar pool e orçamento compartilhado; validar o runtime real; documentar rollout e rollback; medir sem prometer melhoria.

**Non-Goals:** Octane/FrankenPHP, Brotli, módulos extras para ocultar o nome Nginx, CDN, balanceamento adicional, réplicas, cache de respostas HTTP, novos caches de negócio, mudanças em queries/schema/limiter, nova plataforma de carga, homologação permanente ou garantia de zero downtime. Não criar classes, contextos, dependências Composer/npm ou testes de negócio por causa da troca de servidor.

## Decisions

### D1 — Dois serviços, uma release

Manter `web` como serviço HTTP para minimizar mudanças de roteamento no Dokploy; ele passa a executar Nginx e encaminha FastCGI a um serviço PHP-FPM interno. Os dois são construídos a partir da mesma revisão e dos mesmos stages de assets/dependências, com versões de imagens explicitamente fixadas e compatíveis. Preservar PHP 8.5.12 e extensões atuais, salvo incompatibilidade comprovada e decisão explícita. A versão Nginx suportada e o digest das imagens serão registrados no apply.

Nginx recebe apenas os arquivos públicos necessários, não `.env`, `vendor`, fontes da aplicação ou configuração secreta. FPM recebe a aplicação completa no mesmo caminho lógico, para resolver `SCRIPT_FILENAME` sem divergência. Os assets não são copiados entre containers em startup nem montados a partir de um checkout mutável; as imagens são imutáveis e publicadas como par da mesma release.

Não criar rota pública para `storage/app/private` nem publicar todo `app-storage` no Nginx. Se houver arquivos públicos dinâmicos efetivamente usados, inventariar o contrato antes do apply e permitir somente o subdiretório público necessário, read-only no Nginx; a mera existência do volume não autoriza exposição.

Alternativas descartadas: Nginx diante do Apache mantém a estrutura prefork e adiciona camada redundante; dois processos principais no mesmo container exigem supervisão desnecessária; imagens construídas de revisões independentes podem servir assets e PHP incompatíveis.

### D2 — Rede e confiança de proxies

Traefik permanece na entrada, encaminhando HTTP a `web:80`. Somente Nginx precisa participar da rede de entrada `dokploy-network`; criar uma rede FastCGI dedicada entre Nginx e FPM, sem publicar porta FPM no host ou conectá-lo à rede de entrada. FPM continua nas redes necessárias para PostgreSQL, Redis e Nightwatch; isolar FastCGI não deve cortar essas conexões.

Detalhamento do grupo 2: declarar uma rede externa de dados por `APP_SERVICES_NETWORK`, distinta de `dokploy-network`, para PHP, PostgreSQL e Redis; manter `default` para Nightwatch. O Compose deve exigir o nome, sem assumir que a rede já existe ou que os hosts DB/Redis já são resolvíveis nela. A criação/conexão operacional dessa rede e confirmação de seus aliases pertencem a 5.1 e exigem autorização própria. FPM escuta somente em `fpm-fastcgi:9000`, alias exclusivo da rede FastCGI; não em todas as interfaces do container multi-homed. Nginx usa DNS interno Docker para renovar a resolução após troca do container. Não adicionar IP fixo ou confiar em isolamento baseado apenas em `expose`.

Preservar `Host`, URI/query original, `Authorization`, cookies, `X-XSRF-TOKEN` e os headers encaminhados necessários. Nginx não deve substituir o esquema externo HTTPS pelo HTTP interno nem reescrever o host/porta usados na assinatura. Preservar a origem Traefik em `REMOTE_ADDR` ao encaminhar FastCGI e confirmar a semântica efetiva no runtime. Se a implementação optar por real-IP ou outra reescrita, revisar conjuntamente `REMOTE_ADDR`, cadeia forwarded e `TRUSTED_PROXIES`, em vez de confiar em `*` para fazer funcionar.

O README atual orienta confiar no IP interno Traefik. A cadeia adiciona Nginx, portanto a implementação precisa comprovar qual endereço Laravel observa, qual proxy valida e quais headers Traefik normaliza. Requisições externas com forwarded forjado não devem controlar esquema, host ou IP de cliente. Essa verificação é de borda; qualquer necessidade de alterar política de aplicação além da adaptação de configuração deve ser apresentada antes de ampliar escopo.

Alternativa descartada: publicar FPM ou confiar globalmente em headers encaminhados. O healthcheck local não exige tornar a aplicação pública fora do Traefik.

### D3 — Front controller e superfície pública mínima

Document root é exclusivamente `public/`, autoindex desativado e execução FastCGI limitada ao `index.php` esperado. Bloquear outros caminhos PHP e arquivos ocultos, inclusive `.env` e `.git`; não criar handler genérico de execução `*.php`. Bloqueios de arquivo não devem cair no fallback Laravel e retornar sucesso. Arquivos estáticos inexistentes não devem ser apresentados como arquivos existentes.

Preservar roteamento Laravel, comportamento atual de barra final e query string, respostas JSON:API, código de status e headers da aplicação. Revisar precedência das locations para impedir que arquivos PHP sejam servidos como texto ou que bloqueios sejam contornados por path info/encoding. Não copiar cegamente diretivas Apache nem alterar a normalização de URLs assinadas.

Usar `server_tokens off`, manter `expose_php=Off` e esconder defensivamente `X-Powered-By` no FastCGI. `APP_DEBUG=false` permanece obrigatório em produção; respostas não expõem stack trace nem versão Laravel. A identificação textual `nginx` é aceita. Não adicionar módulo `headers-more`, WAF ou novas políticas de segurança desconectadas do objetivo.

HSTS preserva o valor atual (`max-age=15552000`) e deve ser emitido uma única vez na resposta externa, inclusive erros aplicáveis. Manter sua responsabilidade no Nginx salvo configuração equivalente já existente no Traefik, que deverá ser inventariada para evitar duplicação. Headers da aplicação, incluindo correlação, não são descartados.

### D4 — Gzip no Nginx, sem cache novo

Nginx será a camada de compressão para as respostas desta aplicação, cobrindo os tipos textuais atuais e `application/json`/`application/vnd.api+json`, com nível moderado, negociação correta e `Vary: Accept-Encoding`. Inventariar middleware Traefik e evitar dupla compressão; respeitar respostas já codificadas e clientes que não aceitam gzip. Documentar limiar de tamanho e demais exceções, sem exigir compressão de respostas minúsculas ou formatos já comprimidos.

Não habilitar `fastcgi_cache`, `proxy_cache` ou cache HTTP compartilhado de rotas autenticadas. Não alterar headers de cache de API nem políticas de cache existentes dos assets nesta primeira equivalência. OPcache, Redis e cache owner-scoped do Repository continuam independentes da camada HTTP. Brotli e políticas de cache/CDN ficam para escopo próprio.

### D5 — Startup PHP, serviços auxiliares e healthcheck

Reutilizar build multi-stage e runtime enxuto, preservando extensões `pdo_pgsql`, `pcntl`, Redis e OPcache, `php.ini-production`, autoload sem dev e permissões de escrita em storage/bootstrap/cache. O Nginx não precisa receber credenciais PHP, banco, Redis ou IA. Workers continuam sem executar servidor web.

Adaptar a seleção do entrypoint para FPM: em produção preparar config/route/event caches depois da injeção do ambiente, por container PHP que depende deles. FPM só entra em atendimento se a preparação terminar com sucesso. Manter `bootstrap/cache` local a cada container, sem `cache:clear` global, sem precompilar/limpar views concorrentes no storage compartilhado e sem alterar o comportamento de comandos administrativos avulsos. Verificar a política `clear_env` do FPM e a disponibilidade efetiva das variáveis necessárias, sem imprimi-las em logs ou endpoints de diagnóstico.

Preservar `migrate` como barreira bem-sucedida antes de FPM e processos auxiliares; não executar migrations por request. Esta mudança não cria migration. Preservar filas, flags e usuário dos workers, scheduler, Nightwatch e o volume existente. Revalidar o workflow de deploy apenas nos pontos afetados pela publicação das duas imagens, sem mudar seu acionamento manual.

O healthcheck de `web` deve executar `GET /up` através de Nginx e FPM, não somente testar a configuração Nginx ou uma página estática. FPM indisponível deve produzir falha de saúde, não falso sucesso. `/up` comprova o caminho HTTP e o boot; PostgreSQL, Redis e workers exigem verificações próprias. Configurações Nginx/FPM passam por seus validadores antes de publicação.

### D6 — Pool limitado pelo orçamento compartilhado

Usar pool `dynamic` com parâmetros explícitos e configuráveis. Antes de fixar o teto, registrar consumo de PostgreSQL/Redis, Traefik/Dokploy, workers/scheduler/Nightwatch, outros projetos e reserva do sistema. Medir memória dos filhos FPM aquecidos em endpoints representativos e distinguir RSS/PSS e memória compartilhada para não apresentar precisão inexistente.

Estimar um teto de memória como `floor(orçamento disponível para filhos / consumo conservador por filho)` e confrontá-lo com CPU, latência, fila e conexões PostgreSQL. Não usar esse cálculo como licença para ocupar toda a RAM nem igualar `pm.max_children` ao número de vCPUs automaticamente. Registrar também `start_servers`, spares, `max_requests` e timeouts efetivos; valores iniciais são conservadores e provisórios, com justificativa e evidências. Status do pool, se usado para diagnóstico, fica interno.

Sem acesso às medições da VPS, o código pode ser preparado com valores provisórios documentados, mas dimensionamento de produção e comparação ficam pendentes. Não declarar tuning validado com base em memória livre local ou resposta isolada de `/up`.

### D7 — Verificação proporcional, evidência e autorização

No apply de código autorizado: validar imagens/configurações e exercitar a topologia dos containers com ambiente privado isolado, sem usar os bancos de produção para testes automatizados. Reusar a suíte funcional existente pelo launcher guardado para regressões pertinentes; não construir um novo harness ou ampliar Load. Verificar HTTP real, porque testes Laravel sem Nginx/FPM não comprovam as regras de servidor.

A matriz de evidência deve cobrir os requisitos R1–R9 da delta spec: assets/build de mesma revisão; healthcheck real e falha do upstream; auth válida/inválida; resposta JSON:API; barra final/query; HTTPS/assinatura e headers forjados; arquivos bloqueados; headers em sucesso/erro; gzip aceito/recusado; ausência de cache HTTP; caches/startup; serviços auxiliares e recursos. Registrar comando, resultado, ambiente e limitação sem tokens, URLs assinadas ou dados pessoais. Não criar cenários de negócio fora do escopo.

Sem homologação permanente, o operador aceita uma janela controlada em produção e possível indisponibilidade curta. Publicação continua sendo ação deliberada posterior, não consequência da escrita da spec ou do apply de código. Smoke checks de produção são pequenos, não destrutivos e sem disparar e-mails/IA ou consumir filas de teste na fila real. Se precisar comprovar fluxo com efeitos, obter consentimento específico e usar recursos de teste identificados, sem apagar dados reais.

Para a comparação, usar Apache e Nginx/FPM com o mesmo código de negócio, massa, rotas, autenticação, estado de cache, observabilidade e perfil de requisições; registrar revisão e diferenças inevitáveis. Medir latência p50/p95, volume/taxa, erros/status, CPU/memória e espera/saturação quando disponíveis. O limiter permanece ativo; 429 é reportado separadamente e não representa capacidade de negócio. Não executar `composer test:load` contra VPS nem alterar seus guards. Em produção, usar telemetria existente e sondas limitadas autorizadas; quando não houver amostras/carga equivalentes suficientes, registrar comparação inconclusiva, sem alegar throughput máximo ou ganho. Benchmark de saturação exige escopo próprio.

### D8 — Rollback é da release completa

Antes do rollout, registrar imagem Apache anterior por tag imutável/digest, revisão, Compose/configuração compatível e configuração de roteamento Dokploy. Não depender de tag `local` sobrescrita nem somente de rebuild futuro. O alvo de reversão deve ter o mesmo contrato de dados da release migrada; não combinar esta publicação com mudanças de schema ou negócio.

Falha persistente de `/up`, auth/assinatura quebrada, exposição de dados/arquivos, OOM ou 5xx novos recorrentes são gatilhos de interrupção/reversão; lentidão nova reproduzível exige interromper expansão e investigar/reverter, sem esconder a regressão com ajustes simultâneos de SQL/limiter. O procedimento restaura imagem Apache, Compose e apontamento Traefik do conjunto conhecido, sem manter dois schedulers/grupos de workers consumindo em paralelo por acidente. Preserva volumes, banco, Redis, `APP_KEY` e credenciais. Não usa `down -v`, drop, flush ou restore de banco como rollback HTTP.

## Risks / Trade-offs

- [Nenhum ganho mensurável] → Migração não prova que o servidor era gargalo; comparar com limitações explícitas e não vender equivalência local como otimização comprovada.
- [Mais serviços e imagens] → Build comum, releases pareadas, configuração validada e rollback completo; a separação tem custo operacional deliberado.
- [2 vCPUs compartilhadas saturam] → Pool conservador, reserva para banco/Redis/workers e gzip moderado, sem multiplicar processos sem medição.
- [Variáveis somem no FPM ou cache fica obsoleto] → Verificar ambiente efetivo, startup fail-fast e recriação de containers por release; não alterar PHP no container vivo.
- [HTTPS, IP ou assinatura incorretos] → Comprovar a cadeia real Traefik/Nginx/FastCGI, incluindo forwarded forjado, antes de aceitar smoke checks.
- [Sem homologação] → Validar containers antes, registrar baseline/rollback antes da janela e manter verificações pequenas em produção; não prometer zero downtime.
- [Logs de borda expõem assinatura/token] → Não registrar headers Authorization/cookies nem query strings sensíveis nos novos logs; revisar também a captura Traefik existente e sanitizar evidências.

## Migration Plan

1. Após autorização de implementação, preparar imagens/configurações/Compose e documentação, sem publicar. Registrar baseline estático Apache e inventário dos recursos/roteamento que dependem de acesso operacional.
2. Validar build, sintaxe, inicialização e matriz HTTP na topologia dos containers com dados privados isolados. Executar apenas verificações pertinentes e preservar os guards existentes.
3. Antes de publicação autorizada, obter baseline operacional disponível, orçamento compartilhado, versões/digests e release Apache recuperável. Resolver pré-requisitos pendentes; ausência de rollback utilizável bloqueia publicação.
4. Publicar o par Nginx/FPM pelo fluxo manual Dokploy, preservar execução única dos auxiliares e conferir `/up`, erros, headers, auth/leitura e consumo. Não executar carga de saturação.
5. Reverter o conjunto se surgir qualquer falha crítica descrita em D8. Conferir HTTP e auxiliares após reversão e registrar a causa sem remover dados.
6. Registrar evidências antes/depois, medições inconclusivas e limitações. Tarefas de produção permanecem abertas enquanto não executadas; validação estática não as substitui.

## Open Questions

Não há decisões funcionais bloqueantes para escrever ou implementar a mudança. O operador confirmou VPS compartilhada, ocultação de versões sem módulos extras e ausência de homologação permanente.

**Pré-requisitos bloqueantes para publicar, a verificar no apply:** recursos efetivamente disponíveis e valores provisórios justificados do pool; versão/digest Nginx selecionados; configuração real de compressão/HSTS/forwarded do Traefik; origem observada pelo Laravel e proxies confiáveis; necessidade real de servir storage público; imagem/revisão Apache recuperável e janela autorizada. Esses fatos não foram inferidos como verificados a partir do repositório.

**Não bloqueante:** ganho de latência/vazão ainda desconhecido. Amostragem insuficiente impede concluir a comparação, não autoriza inventar um resultado ou ampliar o runner local.

## Evidência do step 1 — baseline e preparação (2026-10-24)

### Escopo e referência recuperável

Autorização limitada ao grupo 1 de `tasks.md`. Nenhuma alteração em Dockerfile, Compose, configuração de runtime, dependências ou aplicação; sem operação na VPS, build, pull, publicação ou instalação de ferramentas. O usuário explicitou que não há Docker e que não deve ser instalado. A consulta inicial identificou Podman disponível (`linux/arm64`), mas ele não foi usado como substituto para construir ou iniciar containers. A comprovação de build de 1.2 continua pendente.

Baseline de código: commit **`d481def3260bb8f6acf20973de4874a6c32575ed`**. `git diff --exit-code HEAD -- Dockerfile docker-compose.yml deploy .dockerignore package.json package-lock.json composer.json composer.lock vite.config.js public resources config/filesystems.php .github/workflows/ci.yml` terminou com código 0. A change já estava não rastreada no início; não foi descartada, adicionada ao staging ou commitada. Os guias locais antigos `STEPS.md`/`STEPS.ms` tratam de outras changes e não foram alterados.

`git ls-tree -r HEAD -- Dockerfile docker-compose.yml deploy .dockerignore` registrou os objetos abaixo. Recuperação de conteúdo: `git show d481def3260bb8f6acf20973de4874a6c32575ed:<caminho>`. Isto identifica **configuração versionada**, não uma imagem Apache de produção recuperável; 5.4 continua obrigatória.

| Arquivo | Blob Git do baseline |
| --- | --- |
| `Dockerfile` | `88984df7daffb70b73bfdd2ca53f5592ed4d22ae` |
| `docker-compose.yml` | `0ba50ae58d7f8931c67660872f806819eb41bfbb` |
| `deploy/apache.conf` | `15206b56dd844ad37ed4c432a60c6a9ffc0cc198` |
| `deploy/apache-global.conf` | `24a22c96f962133a75bf43cf337721fc5af0d9d7` |
| `deploy/php.ini` | `53059d2e2efed5a37d55b38084dc6d2bb08dffaf` |
| `deploy/entrypoint.sh` | `2b8c40e22a7d6c957b251ae3546958de8e7907b5` |
| `.dockerignore` | `cbebaea1e28b97fc60a20ddbadb061568eaa7361` |

### Mapa de equivalência R1–R7

| Requisito | Contrato observado nos arquivos | Equivalência a implementar/verificar, não comprovada nesta etapa |
| --- | --- | --- |
| R1 | Stages `assets`, `php-base`, `dependencies`, `runtime`; assets copiados do build Node para `/var/www/html/public/build`; uma imagem `trocado-app:local` para processos PHP. Todos exceto Nightwatch participam hoje de `dokploy-network` e `default`. Sem `ports` publicados pelo Compose. | Par Nginx/FPM de revisão comum; somente `web` na entrada, rede FastCGI dedicada, sem fontes/segredos no Nginx. A tag `local` atual não é identificação imutável. |
| R2 | DocumentRoot `/var/www/html/public`, `AllowOverride None`, `Options FollowSymLinks`; rewrite 301 de barra final quando não é diretório, fallback de não arquivo/não diretório para `index.php`. `.htaccess` não é lido. | Preservar query e redirecionamento; restringir FastCGI a `index.php`, bloquear PHP arbitrário/ocultos e desligar autoindex explicitamente. O VirtualHost atual não prova esses bloqueios novos; não alegar equivalência de segurança por inspeção. |
| R3 | Rewrite transporta `Authorization` e `X-XSRF-Token`; README orienta IP interno Traefik como proxy confiável e TLS externo. | Preservar também cookies/Host/forwarded e conferir `REMOTE_ADDR`, HTTPS e assinatura reais. IP/política efetivos não foram consultados na VPS. |
| R4 | `ServerTokens Prod`, `ServerSignature Off`; HSTS `max-age=15552000` com `always`; `expose_php=Off`, `display_errors=Off`. Logs Apache em stdout/stderr, access log `combined`. | `server_tokens off`, ocultar `X-Powered-By`, manter headers da aplicação e um HSTS externo. Não copiar `combined` cegamente: ele pode incluir query sensível. Não se comprovou `APP_DEBUG` efetivo nem política Traefik. |
| R5 | DEFLATE para `text/html`, `text/plain`, `text/css`, `text/javascript`, `application/javascript`, `application/json`, `application/vnd.api+json`, `application/xml`, `image/svg+xml`; sem política adicional de cache HTTP no VirtualHost. | Gzip negociado com `Vary`, limiar/exceções explícitos, mesmos tipos e sem cache HTTP novo. Compressão externa permanece desconhecida. |
| R6 | Base `php:8.5.12-apache-bookworm`; instala `pdo_pgsql`, `pcntl`, Redis PECL 6.3.0; build exige `dom`, `pdo_pgsql`, `pcntl`, `redis`, `Zend OPcache`. Composer `--no-dev`, autoload otimizado; Node/Composer/git/unzip não copiados dos stages de build para runtime. `php.ini-production`, realpath 4096K/600s; OPcache 128 MiB, strings 16 MiB, 20000 arquivos, timestamps off, CLI off, JIT disable. | Preservar na base FPM e comprovar extensões/dependências instaladas; validar `clear_env`. `set -eu` prepara config/route/event cache somente em produção para Apache e comandos residentes/migrate; comandos avulsos não preparam. Adaptar seletor para FPM sem cache global/views. |
| R7 | `migrate`: `php artisan migrate --force`, sem restart; dependentes aguardam sucesso. `queue`: Redis/default; `expense-classification`: Redis/fila homônima; ambos `--tries=3 --timeout=60 --sleep=1`. Scheduler: `schedule:work`. Nightwatch: `nightwatch:agent --listen-on=0.0.0.0:2407`, só `default`; ingest `nightwatch-agent:2407`. Auxiliares usam `www-data`. | Preservar uma instância de cada e seus comandos, ambiente e `app-storage:/var/www/html/storage`; `bootstrap/cache` continua local. `/up` declarado em `bootstrap/app.php`; healthcheck atual usa curl, intervalo 30s, timeout 5s, retries 3, start 30s. Novo check deve atravessar FPM e falhar sem upstream; não prova banco/Redis/workers. |

Divergência preexistente a resolver em 2.4/4.6 antes de qualquer publicação: README descreve a Action manual **Deploy to Dokploy**, mas o checkout e a árvore Git contêm somente `.github/workflows/ci.yml`. Esse workflow executa verificações e assets, não solicita deploy nem constrói o par de imagens. Não foi criado workflow nesta etapa nem inferido o estado remoto do Dokploy.

### Seleção de imagens e identidade comum (1.2 parcial)

Consultas HTTPS somente leitura à API pública Docker Hub (`/v2/repositories/library/<imagem>/tags/<tag>`) retornaram HTTP 200 em 2026-10-24. Seleção para o próximo step:

| Papel | Referência fixa selecionada (digest do índice multiarch) |
| --- | --- |
| PHP-FPM | `php:8.5.12-fpm-bookworm@sha256:d3db5340c7ecfb1e3a26af5d3d9de8b4e160cdd75692a830b5cb74b0b85db2cf` |
| Nginx | `nginx:1.30.6-trixie@sha256:a7675fcee220f59b4a99f7098c06a0d5d999c2c0ee37c0211efb780536e5cb20` |

PHP mantém patch e distribuição do baseline; Redis permanece 6.3.0. Nginx 1.30.6 corresponde ao digest de `stable` observado na consulta, sem Perl/OTel/módulos extras. Nginx e FPM são processos em imagens separadas comunicando FastCGI: não precisam compartilhar a distribuição Linux. Os índices consultados incluem `linux/amd64` e `linux/arm64`; arquitetura efetiva da VPS ainda precisa de confirmação. Existência no registry não comprova build, segurança integral da imagem ou compatibilidade da aplicação.

Para referência apenas, a tag da **base** Apache atual resolve para `php:8.5.12-apache-bookworm@sha256:5e4418695f9b13b75edefaff547125bf6be267e865931731bdd5946461505736`. Não é o digest da aplicação publicada nem substitui o rollback de 5.4.

Contrato definido para 2.1/2.3: usar `RELEASE_REVISION` com o SHA Git completo do checkout limpo (**40 caracteres hexadecimais**) como argumento de build comum e label `org.opencontainers.image.revision` em ambas as imagens. Tags locais/remotas distintas por papel e revisão (`trocado-php:<sha>` e `trocado-nginx:<sha>`); registrar os dois digests resultantes no manifesto operacional da publicação. Construir os dois targets do mesmo Dockerfile/contexto/revisão, compartilhando o stage de assets; FPM também recebe o manifest Vite da mesma compilação. Nenhuma imagem se identifica por `latest`/`local` na publicação. Builds de prova de um checkout modificado devem declarar essa condição e não se apresentar como release imutável de HEAD.

O build atual só produz o runtime Apache; não há ainda targets Nginx/FPM. **Não houve build nem instalação**. A prova exigida em 1.2 deve ocorrer quando os targets forem implementados em 2.1, em ambiente de build já disponível e explicitamente acordado, sem instalar Docker neste ambiente ou acionar deploy/CI remoto implicitamente. Manter 1.2 aberta até obter essa evidência; nenhuma dependência Composer/npm foi adicionada ou atualizada.

### Inventário público e exclusões (1.3)

- Arquivos rastreados em `public/`: `index.php` (front controller, somente no FPM), `.htaccess` (Apache, desnecessário no Nginx), `favicon.ico` (arquivo vazio no baseline; preservar sem inventar asset), `robots.txt` (`User-agent: *`, `Disallow:` vazio).
- `vite.config.js` compila `resources/css/app.css` e `resources/js/app.js`, com Instrument Sans 400/500/600 pelo plugin de fontes já declarado. Saída necessária: `public/build/manifest.json` e os arquivos gerados em `public/build/assets/` (CSS, JS, WOFF/WOFF2). Copiar do stage `assets`, não do build local. O manifest local foi apenas inventariado e não comprova os hashes da próxima release.
- `welcome.blade.php` referencia `@fonts`/`@vite`, mas o bootstrap não registra `routes/web.php`; não criar rota de boas-vindas nesta migração. Templates de e-mail permanecem no FPM, não são assets públicos do Nginx.
- `public/storage` local é symlink para `storage/app/public`; a existência foi conferida só por metadados, sem ler arquivos privados. `.dockerignore` exclui `public/storage`, `storage/app`, `public/build`, `public/hot` e `public/fonts-manifest.dev.json`; os dois últimos são artefatos de desenvolvimento, proibidos na imagem pública.
- `config/filesystems.php` declara disco local privado em `storage/app/private`, disco público em `storage/app/public` e link público `/storage`. As buscas por `Storage`, `Filesystem`, `UploadedFile`, `storage` em `app/` e por storage/upload/download em `routes/` não encontraram consumo; configuração disponível não é prova de uso. Não foi observado uso de upload público no código atual nem mecanismo de criação desse link no Dockerfile/entrypoint de produção.
- Allowlist inicial do Nginx: **`favicon.ico`, `robots.txt` e `build/` gerado**, em `/var/www/html/public`; nenhum `index.php` fonte, `.htaccess`, `hot`, manifest dev, link storage, fontes internas, `vendor`, `.env` ou `storage` completo. O caminho FastCGI aponta ao `index.php` existente somente no FPM. Não montar `app-storage` nem carregar `env_file: .env` no Nginx. Configuração não secreta do servidor é independente dessa allowlist.
- Decisão: **sem mount de storage público inicialmente**. A verificação operacional de uso real de `/storage` permanece pré-requisito de publicação; se houver consumo externo não visível no repositório, inventariar antes de ativar somente o subdiretório público read-only. Nunca inferir permissão sobre o storage privado.

### Resultado e próximo checkpoint

1.1 e 1.3 possuem evidência estática suficiente para suas entregas de inventário. 1.2 permanece parcial por falta de build do par. R1–R7 estão mapeados, **não comprovados no novo runtime**; cenários HTTP, startup, segurança e lifecycle continuam sem execução. R8/R9 operacionais permanecem pendentes. Sem testes da aplicação ou Pint: nenhum PHP foi alterado e esta entrega só registra preparação. Próxima ação, mediante autorização: grupo 2, carregando estas referências e preservando 1.2 aberta até a prova de build. Sem commit, archive ou deploy automático.

## Handoff do grupo 2 — código preparado, validação runtime pendente (2026-10-24)

Após nova autorização do usuário, a spec/baseline foi commitada em `db385ca`; implementação subsequente permanece no working tree. Não instalar Docker continua sendo restrição vigente. Não foi usado Podman para build/pull/run nem executada operação remota.

### Implementação e decisões confirmadas por inspeção

- `Dockerfile`: preservados stages de assets/dependências e passos/extensões existentes; base PHP agora FPM fixada no digest de 1.2. `runtime` recebe a aplicação/manifest Vite; `web`, base Nginx fixada, só recebe allowlist pública. Ambos exigem `RELEASE_REVISION` SHA completo e label comum. Não adicionadas dependências Composer/npm; `deploy/php.ini` intacto. Ainda sem prova de build, plataforma ou inventário final das imagens.
- `deploy/entrypoint.sh`: seleciona `php-fpm`, valida os seis inteiros positivos e ordenação do pool, chama `php-fpm -t`, recusa debug em produção e exige proxy explícito sem wildcard para FPM. Preserva seleção dos comandos residentes/migrate e avulsos; cache config/route/event individual. Falha exibe somente nome do cache, sem repassar a exceção que poderia conter credenciais. Não muda cache global/views. Ambiente/caches/OPcache reais ainda não observados no container.
- `deploy/php-fpm.conf`: override após as configurações da imagem oficial, `clear_env=no`, usuário/grupo `www-data`, extensão `.php`, listener em `fpm-fastcgi:9000`. Referência do código PHP 8.5 `sapi/fpm/fpm/fpm_sockets.c` confirma resolução por `getaddrinfo` para hostname de bind; o bind efetivo exige prova runtime. Pool dinâmico provisório: máximo 4, início 2, spare mínimo 1/máximo 2, reciclagem 500, timeout 60s inclusive após finalização FastCGI e backlog 128. Overrides/método de orçamento no README; nenhum status público ou dimensionamento VPS validado.
- Compose: adiciona somente `fpm`; preserva migration e auxiliares/filas/usuários/volumes/barreiras. Nginx sem credenciais/volume de aplicação. Rede externa de dados obrigatória e distinta da entrada, descrita em D2; `fastcgi` interna tem só web/FPM e o alias de bind exclusivo. Conectividade DB/Redis e isolamento não inferidos do YAML.
- `deploy/nginx.conf` é preparação antecipada do grupo 3 necessária à imagem HTTP: root público, exact front controller, bloqueios de ocultos/PHP, redirect relativo de barra final com args, FastCGI com Host/auth/headers e `REMOTE_ADDR` do peer sem real-IP, timeouts finitos, ocultação PHP/versões e HSTS de responsabilidade Nginx. Não sobrescreve forwarded com `$scheme` interno. A confiança depende do Traefik normalizar entrada e do proxy PHP corresponder à origem real; não foi comprovada por configuração apenas.
- Gzip nível 4 e limiar 1024, tipos atuais e `Vary`, sem cache HTTP novo. Omitido URI/query/credenciais de access logs Nginx/FPM. O error log por request Nginx é desativado para não capturar queries assinadas (formato não redigível); há custo explícito de perder detalhe de falhas upstream. Diagnóstico usa access status/tempo e logs PHP/aplicação. Logs Traefik e headers externos continuam pendentes. Healthcheck `/up` limitado a conexão 2s/total 4s, sem alegar prova da falha de upstream.
- README ganhou seção de preparação com impedimento de rollout, parâmetros/redes e limites. Orientações históricas Apache e referências de recuperação mantidas; 4.6 só termina com documentação operacional/evidências posteriores. Workflow manual descrito no README segue ausente do checkout; não criado automaticamente.

### Fontes e evidência

Boost/Search Docs Laravel 13 consultado para deployment/Nginx e caches config/route/event: o projeto mantém comandos granulares, não `optimize`/`optimize:clear`, para evitar views/cache compartilhado. Documentação PHP FPM e Dockerfiles oficiais PHP 8.5-bookworm/Nginx stable Debian consultados somente por HTTPS, sem baixar imagens. Confirmados suporte à expansão de ambiente no pool, `clear_env`, timeout/access format e presença de curl na base Nginx consultada. Documentação Nginx confirma `resolve` em upstream sem módulo pago desde 1.27.3. Essas fontes apoiam a configuração, mas não substituem validadores das imagens fixadas.

Checks executados: sintaxe POSIX shell; parse PyYAML/inspeções com assertions de auxiliares, redes, revisões e allowlist; inspeção cruzada das seis variáveis/defaults/overrides/documentação; **60 cenários do entrypoint com binários simulados**, todos aprovados e cleanup temporário concluído. Não se executaram PHP/Artisan reais, Nginx/FPM, requests, build, migrations ou testes de aplicação. Não há mudança PHP que exija Pint. Comandos/resultados/limites em `tasks.md`.

Tarefas 2.4/2.5 concluídas no nível estrutural/configuração solicitado; 1.2/2.1/2.2/2.3 continuam parciais e 3.1–3.5 abertas. Nenhum cenário HTTP novo é classificado como comprovado; publicação/rollback/recursos continuam bloqueados pelos grupos 4–6. Próxima ação: acordar ambiente de build/validação sem instalação Docker (eventual uso do Podman existente exige alinhamento), concluir provas pendentes e revisar grupo 3, sem acionar deploy como teste.
