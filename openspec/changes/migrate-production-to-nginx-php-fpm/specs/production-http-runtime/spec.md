## ADDED Requirements

### Requirement: R1 Entrega HTTP por serviços de uma mesma release
O runtime de produção MUST atender pela cadeia Traefik → Nginx → PHP-FPM, com TLS terminado no Traefik e arquivos públicos/código PHP pertencentes à mesma release imutável. Nginx MUST ser o único destino HTTP do Traefik. Os processos PHP MUST preservar acesso ao PostgreSQL/Redis pela rede Dokploy existente, sem exigir uma rede externa adicional. O listener FastCGI MUST aceitar conexões somente pela interface da rede dedicada entre Nginx e FPM e MUST NOT ser publicado no host ou na internet. O build do par MUST usar o mesmo checkout, sem exigir uma variável manual de revisão. Nginx MUST NOT receber segredos de aplicação ou acesso a arquivos privados para servir assets.

#### Scenario: Asset e rota dinâmica da mesma release
- **WHEN** uma release é iniciada e recebe requisições para um asset existente e uma rota Laravel
- **THEN** Nginx serve o asset da mesma revisão executada por PHP-FPM
- **AND** a rota dinâmica é processada por FPM, não por Apache

#### Scenario: Isolamento de FastCGI e segredos
- **WHEN** as redes, portas e arquivos da release são inspecionados
- **THEN** FastCGI só é acessível pela rede dedicada entre Nginx e FPM, sem porta publicada
- **AND** o serviço Nginx não contém credenciais, fontes internas ou storage privado

#### Scenario: Build pelo Dokploy sem configuração adicional de revisão ou rede
- **WHEN** Dokploy obtém o repositório e constrói a composição com os hosts de banco/Redis já configurados
- **THEN** os dois targets são construídos do mesmo checkout sem variável manual de revisão
- **AND** PHP conserva acesso aos serviços pela rede existente sem exigir nova rede externa
- **AND** FastCGI continua restrito à interface dedicada, mesmo com o container PHP conectado à rede Dokploy

### Requirement: R2 Front controller e arquivos protegidos
O servidor HTTP MUST servir exclusivamente a árvore pública autorizada, sem listagem de diretórios, e MUST limitar execução PHP ao front controller esperado. Arquivos ocultos, configuração privada e outros caminhos PHP MUST NOT ser executados ou entregues como fonte. Roteamento, query strings e normalização de barra final MUST preservar os comportamentos existentes da aplicação, sem alterar URLs assinadas indevidamente.

#### Scenario: Arquivo interno ou PHP arbitrário solicitado
- **WHEN** uma requisição tenta obter `.env`, conteúdo de `.git`, código fora de public ou um arquivo PHP distinto do front controller
- **THEN** o acesso é rejeitado sem entregar conteúdo privado ou código fonte
- **AND** o bloqueio não é convertido em uma resposta de sucesso pelo fallback

#### Scenario: Rota Laravel com query string
- **WHEN** uma rota pública ou autenticada recebe filtros, query string ou barra final
- **THEN** roteamento e redirecionamento preservam o comportamento anterior e os parâmetros necessários
- **AND** respostas da aplicação mantêm status, media type e envelope existentes

### Requirement: R3 Confiança de proxy e compatibilidade autenticada
A cadeia HTTP/FastCGI MUST preservar credenciais, host e esquema externos necessários a autenticação e URLs assinadas, com política explícita de proxies confiáveis coerente com a origem efetivamente observada no PHP. A migração MUST NOT substituir HTTPS externo por HTTP interno, aceitar headers forwarded forjados de clientes como autoridade ou ampliar implicitamente a confiança para todos os proxies. Auth, ownership e rate limiting MUST permanecer sob as regras existentes.

#### Scenario: Bearer válido e inválido
- **WHEN** uma leitura protegida é feita com um PAT válido e depois sem credencial válida
- **THEN** a primeira conserva a autorização e o contrato da operação
- **AND** a segunda conserva a rejeição de autenticação sem cache ou bypass pelo servidor

#### Scenario: URL HTTPS assinada
- **WHEN** uma URL válida assinada para o host HTTPS público atravessa Traefik e Nginx
- **THEN** Laravel recebe os elementos necessários para validar a assinatura sem transformação indevida
- **AND** não gera redirecionamentos para o esquema HTTP interno

#### Scenario: Forwarded forjado na entrada pública
- **WHEN** um cliente envia headers forwarded com host, esquema ou endereço falsos
- **THEN** os valores não substituem indevidamente a origem externa validada pela cadeia confiável
- **AND** o diagnóstico registra a política efetiva sem expor credenciais

### Requirement: R4 Divulgação mínima e headers preservados
O runtime MUST ocultar versões Nginx/PHP e MUST NOT emitir `X-Powered-By`, stack traces ou versões Laravel nas respostas de produção. O nome Nginx sem versão é permitido; módulos extras apenas para removê-lo MUST NOT ser introduzidos. HSTS existente MUST ser preservado sem duplicação na resposta HTTPS externa, e headers de aplicação, incluindo correlação, MUST atravessar a nova cadeia.

#### Scenario: Respostas de sucesso e erro
- **WHEN** são inspecionadas respostas HTTPS de sucesso, erro da aplicação e erro gerado por Nginx
- **THEN** não revelam versões de runtime, `X-Powered-By` ou detalhes internos de debug
- **AND** preservam HSTS aplicável com o valor existente e sem duplicação
- **AND** respostas originadas na aplicação conservam os headers de correlação existentes

### Requirement: R5 Compressão negociada sem cache HTTP compartilhado
O runtime MUST oferecer gzip no Nginx para tipos textuais e JSON/JSON:API elegíveis, negociar `Accept-Encoding`, emitir `Vary: Accept-Encoding` nas variantes aplicáveis e evitar dupla compressão. MUST NOT adicionar Brotli, CDN, `fastcgi_cache`, `proxy_cache` ou políticas novas de cache HTTP nesta migração. Os caches de aplicação existentes e headers de cache da API MUST permanecer independentes e preservados.

#### Scenario: Resposta elegível aceita gzip
- **WHEN** um cliente aceita gzip e solicita uma resposta textual ou JSON elegível acima do limiar configurado
- **THEN** recebe conteúdo comprimido uma única vez, decodificável para o mesmo documento
- **AND** a resposta informa a variação por `Accept-Encoding`

#### Scenario: Cliente não aceita gzip
- **WHEN** um cliente solicita a mesma resposta sem aceitar gzip
- **THEN** recebe a representação sem codificação gzip, com status e conteúdo equivalentes

#### Scenario: Respostas privadas não são reutilizadas pelo servidor
- **WHEN** duas contas consultam uma rota protegida
- **THEN** cada requisição atravessa autenticação e autorização existentes
- **AND** Nginx não armazena nem reutiliza a resposta privada de uma conta para outra

### Requirement: R6 Inicialização e otimizações PHP preservadas
O runtime PHP MUST preservar versão/extensões compatíveis, autoload otimizado sem dev, configuração de produção e OPcache com código imutável. Cada container PHP pertinente MUST preparar os caches existentes de configuração, rotas e eventos após receber seu ambiente e antes de atender ou trabalhar; falha MUST impedir seu startup normal. MUST NOT introduzir limpeza global de cache, precompilação concorrente de views ou compartilhamento de bootstrap/cache entre containers.

#### Scenario: FPM inicia com ambiente e caches corretos
- **WHEN** um container FPM de produção inicia com configuração válida
- **THEN** dispõe das variáveis e extensões necessárias e prepara os caches antes do atendimento
- **AND** OPcache carrega código da release sem exigir edição no container ativo

#### Scenario: Preparação de cache falha
- **WHEN** a preparação de um cache obrigatório falha
- **THEN** o container não inicia normalmente como servidor saudável
- **AND** a falha é diagnosticável sem imprimir segredos

### Requirement: R7 Lifecycle e saúde fim a fim
A implantação MUST preservar a barreira de migrations bem-sucedidas, filas existentes, scheduler, Nightwatch e volumes persistentes, sem duplicar consumidores por acidente. O healthcheck HTTP MUST atravessar Nginx e FPM pelo endpoint de boot existente; uma resposta estática ou porta aberta MUST NOT substituir essa prova. Saúde HTTP MUST NOT ser apresentada como prova suficiente de banco, Redis ou workers.

#### Scenario: Upstream PHP indisponível
- **WHEN** FPM está indisponível e o healthcheck consulta o serviço HTTP
- **THEN** o healthcheck falha em vez de indicar saúde apenas porque Nginx está ativo

#### Scenario: Falha de migration ou início dos auxiliares
- **WHEN** migration falha ou a release é iniciada com sucesso
- **THEN** uma migration falha impede os processos dependentes de iniciar normalmente
- **AND** no caso de sucesso os serviços auxiliares mantêm comandos, filas, ambiente e storage existentes

### Requirement: R8 Orçamento de recursos e evidência de desempenho
O pool FPM MUST ter configuração explícita, limites finitos e justificativa baseada no orçamento compartilhado e em medições, considerando PostgreSQL, Redis, workers, sistema e demais serviços. Valores provisórios MUST ser identificados como tais. A comparação com Apache MUST registrar ambiente, revisão, perfil, caches, erros e métricas efetivamente disponíveis sob condições equivalentes; ausência de evidência MUST produzir conclusão limitada ou inconclusiva, nunca promessa de ganho. MUST NOT ampliar limiter ou guards do runner local para medir produção.

#### Scenario: Dimensionamento em VPS compartilhada
- **WHEN** os parâmetros de produção do pool são definidos
- **THEN** a justificativa registra consumo medido dos processos, reserva para os demais serviços e restrição de CPU
- **AND** o teto de filhos não é escolhido apenas pelo total de RAM ou número de vCPUs

#### Scenario: Comparação sem amostras suficientes ou contaminada
- **WHEN** as amostras antes/depois são insuficientes, não equivalentes ou incluem respostas limitadas
- **THEN** o relatório explicita as limitações e separa 429 de sucesso de negócio
- **AND** não conclui aumento de capacidade nem contorna o limiter ou a restrição local do runner

### Requirement: R9 Publicação deliberada e reversível
A mudança MUST prever validação de imagens/configurações e verificações HTTP reais antes de publicação autorizada, sem exigir homologação permanente. Antes do rollout MUST existir uma release Apache recuperável com imagens e configuração identificadas. Após publicação MUST haver smoke checks controlados e critérios explícitos de interrupção/rollback. Reversão MUST restaurar o conjunto HTTP e processos compatíveis sem apagar dados, volumes, banco ou Redis; testes em produção MUST NOT executar operações destrutivas ou carga de saturação implicitamente.

#### Scenario: Falha crítica após rollout autorizado
- **WHEN** a nova release apresenta exposição de arquivos, quebra de autenticação/assinatura, falha persistente de saúde, OOM ou novos 5xx recorrentes
- **THEN** o operador interrompe a publicação ou reverte para o conjunto Apache conhecido
- **AND** preserva dados e credenciais e verifica HTTP e serviços auxiliares após a reversão

#### Scenario: Verificação de código sem acesso operacional
- **WHEN** builds e configurações foram validados mas não houve publicação ou medição autorizada na VPS
- **THEN** a evidência registra somente o que foi executado
- **AND** tarefas de produção e comparação não são marcadas como concluídas
