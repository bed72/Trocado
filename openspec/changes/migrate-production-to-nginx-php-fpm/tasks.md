## 1. Baseline e preparação da implementação

O usuário autorizou iniciar somente o grupo 1 em 2026-10-24. Escrever/validar a spec não autoriza operação na VPS ou publicação. Tarefas operacionais exigem acesso e autorização próprios; ausência deles mantém os itens pendentes. Docker não deve ser instalado neste ambiente.

- [x] 1.1 Registrar baseline versionado de Dockerfile, Compose, Apache, PHP e entrypoint e mapear sua equivalência com R1–R7, preservando os contratos existentes sem implementar melhorias de negócio.
- [ ] 1.2 Selecionar versões fixas de Nginx e PHP-FPM compatíveis com o PHP/extensões atuais; definir identificação da release comum e comprovar que o build consegue produzir o par de imagens sem dependências Composer/npm novas (R1, R6).
- [x] 1.3 Inventariar assets e eventual uso de storage público, definindo os arquivos mínimos acessíveis ao Nginx e mantendo storage privado e segredos fora de sua imagem/ambiente (R1, R2).

Evidências do grupo 1 (2026-10-24): seção **Evidência do step 1 — baseline e preparação** em `design.md`. Baseline `d481def3260bb8f6acf20973de4874a6c32575ed`, blobs Git e diff dos arquivos de deploy/manifests sem alterações, mapa estático R1–R7; inventário versionado e local de public/Vite/filesystems, sem ler storage privado. Definida allowlist pública e ausência inicial de mount storage no Nginx; uso real na VPS ainda exige confirmação antes de publicar. Nenhum runtime foi modificado.

**1.2 parcial, não concluída:** selecionados PHP-FPM 8.5.12-bookworm e Nginx 1.30.6-trixie com digests de índice consultados no Docker Hub; definida revisão Git comum/labels/tags/digests pareados. Build não executado: Docker ausente e instalação proibida pelo usuário; Podman não foi usado para build/pull/run. O Dockerfile atual continua Apache, sem targets do novo par. A comprovação deve acompanhar 2.1 em ambiente de build acordado, sem instalar Docker ou acionar publicação implicitamente. Não confundir consulta de registry com build compatível; nenhuma dependência Composer/npm alterada.

Pendência preexistente para 2.4/4.6: README descreve workflow manual Dokploy ausente do checkout, que contém somente `ci.yml`. Sem autorização/execução de grupo 2, testes da aplicação, Pint, migrations, operação remota, commit ou deploy nesta etapa.

Verificação de saída: `openspec validate migrate-production-to-nginx-php-fpm --type change --strict --json --no-interactive` aprovado sem issues; `openspec list --json` confirma **2/29** tarefas concluídas. `git diff --check` sem saída, limitado aos arquivos rastreados (a change permanece não rastreada); diff explícito dos arquivos de runtime/manifests continua vazio. Validação documental não comprova build nem cenários HTTP.

## 2. Imagens PHP e composição dos serviços

- [ ] 2.1 Adaptar o build multi-stage para runtime FPM e imagem Nginx com arquivos públicos da mesma revisão, preservando extensões, assets, autoload sem dev e ausência de ferramentas de build no runtime (R1, R6).
- [ ] 2.2 Adaptar o entrypoint para FPM e validar ambiente efetivo, caches por container, OPcache e falha explícita de preparação, sem limpar cache global ou views compartilhadas (R6).
- [ ] 2.3 Alterar Compose para `web` Nginx e serviço FPM separado, com rede FastCGI dedicada e sem publicação de portas FPM; manter acesso PHP aos serviços necessários e barreira de migration (R1, R7).
- [ ] 2.4 Preservar comandos/filas/usuários dos workers, scheduler, Nightwatch e volumes, verificando que a nova topologia não duplica consumidores nem exige schema novo (R7).
- [ ] 2.5 Implementar configuração explícita do pool FPM com limites finitos e overrides documentados; identificar valores provisórios e método de dimensionamento por medição/orçamento compartilhado (R8).

## 3. Configuração HTTP e segurança

- [ ] 3.1 Configurar document root público, front controller único, bloqueios de arquivos ocultos/PHP arbitrário, autoindex desativado, assets e compatibilidade de rewrite/barra final/query (R2).
- [ ] 3.2 Configurar FastCGI e passagem de host, credenciais e forwarded sem substituir HTTPS externo; documentar a relação entre `REMOTE_ADDR`, Traefik e proxies confiáveis antes de habilitar a cadeia (R3).
- [ ] 3.3 Preservar HSTS e headers da aplicação, ocultar versões e `X-Powered-By`, manter produção sem debug e configurar logs novos sem credenciais/query strings sensíveis (R4).
- [ ] 3.4 Configurar gzip negociado no Nginx para os tipos atuais, com limiar/exceções e `Vary`, sem Brotli, cache HTTP novo ou dupla compressão (R5).
- [ ] 3.5 Adaptar healthcheck para `/up` via Nginx/FPM, com timeouts finitos e falha quando o upstream não atende, sem apresentar esse check como prova de banco/Redis/workers (R7).

## 4. Verificação antes de publicação

- [ ] 4.1 Validar Compose, build das duas imagens, sintaxe Nginx e FPM e inicialização em ambiente privado isolado; registrar revisões/comandos/resultados sem segredos (R1, R6, R9).
- [ ] 4.2 Exercitar HTTP real dos containers: asset da release, front controller, query/barra final, bloqueios de arquivos e PHP arbitrário; comprovar saúde por `/up` e falha com upstream indisponível (R1, R2, R7).
- [ ] 4.3 Verificar HTTP real de auth válida/inválida, status/envelope JSON:API, headers de correlação, HTTPS/assinatura e forwarded forjado na cadeia representativa, sem mudar regras de aplicação (R3, R4).
- [ ] 4.4 Verificar headers de sucesso/erro, gzip aceito/recusado e ausência de cache compartilhado entre contas; confirmar que Nginx não recebeu segredos ou storage privado (R1, R4, R5).
- [ ] 4.5 Verificar startup fail-fast/cache por container, variáveis/extensões no FPM e continuidade dos serviços auxiliares; executar somente verificações funcionais existentes pertinentes pelo launcher guardado, sem bancos de produção (R6, R7).
- [ ] 4.6 Atualizar README de produção com arquitetura, builds/release pareada, parâmetros FPM, redes, proxies, gzip, healthcheck, limites e rollout/rollback. Remover orientações Apache tornadas obsoletas somente após registrar a referência de reversão (R1–R9).

## 5. Pré-requisitos operacionais de publicação

- [ ] 5.1 Com autorização de acesso, inventariar na VPS redes/roteamento Dokploy, normalização forwarded, compressão e HSTS do Traefik, verificando que a configuração externa não duplica ou contradiz a nova cadeia (R3–R5).
- [ ] 5.2 Medir consumo compartilhado e processos FPM representativos; registrar reserva, teto de conexões e parâmetros justificados para os 2 vCPUs/8 GB, sem atribuir toda a RAM ao PHP (R8).
- [ ] 5.3 Registrar baseline Apache disponível de latência, erros, CPU/memória e perfil/caches/revisão, com observabilidade equivalente e sem carga de saturação ou execução do runner local na VPS; declarar insuficiências de amostra (R8).
- [ ] 5.4 Guardar imagem Apache anterior por identificação imutável, revisão e configuração Compose/Traefik recuperáveis; conferir compatibilidade de dados e documentar passos/gatilhos de rollback sem apagar volumes ou duplicar auxiliares (R9).
- [ ] 5.5 Confirmar janela e autorização de deploy, digests pareados, pool e proxies efetivos, ausência de mudanças de schema/negócio combinadas e conclusão dos checks anteriores; impedir publicação com rollback indisponível (R1, R8, R9).

## 6. Publicação autorizada e evidências finais

- [ ] 6.1 Publicar pelo fluxo manual Dokploy o par da mesma release, preservando ordem de startup e execução única dos auxiliares; registrar revisão/digests e resultado real, não apenas aceite da solicitação (R1, R7, R9).
- [ ] 6.2 Executar smoke checks pequenos e não destrutivos de saúde, assets, leitura/auth, headers, compressão e logs; verificar recursos e serviços auxiliares. Validar cadeia HTTPS/assinatura sem efeitos externos não consentidos (R2–R9).
- [ ] 6.3 Conferir prontidão do rollback e seus gatilhos após rollout; se acionado, restaurar conjunto Apache conhecido e registrar verificação de HTTP/auxiliares e preservação dos dados. Não apresentar roteiro não executado como reversão comprovada (R9).
- [ ] 6.4 Registrar comparação antes/depois com condições/métricas disponíveis, resultados, 429 separados e limitações; marcar conclusão inconclusiva quando necessário, sem promessa de ganho ou alteração de limiter/runner (R8).
- [ ] 6.5 Consolidar matriz R1–R9 e respectivos cenários com evidência real, pendências e bloqueios; executar validação OpenSpec estrita desta mudança. Não concluir/arquivar enquanto verificações operacionais necessárias estiverem pendentes (R9).
