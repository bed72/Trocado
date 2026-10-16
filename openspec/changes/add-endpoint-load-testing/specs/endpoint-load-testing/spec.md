## ADDED Requirements

### Requirement: LOAD-01 Carga HTTP manual com objetivos separados

O sistema MUST oferecer execução manual explícita de regressão e investigação de capacidade para `GET /api/expenses`, `GET /api/metrics/expenses`, `GET /api/insights` e `GET /api/expenses/suggestions`. MUST usar HTTP real contra servidor identificado e MUST NOT incluir carga automaticamente na suíte funcional ou CI. Escritas de negócio, login por iteração, envio externo e produção MUST permanecer fora do catálogo inicial; preparação, preflight, aquecimento e cleanup MUST ser fases distintas da medição.

#### Scenario: Seleção manual de endpoint
- **WHEN** o operador seleciona um dos quatro endpoints e um cenário válido
- **THEN** somente o cenário selecionado é medido por HTTP real com identificação de objetivo e alvo
- **AND** resultados de preparação/aquecimento não compõem as latências da fase medida

#### Scenario: Execução funcional comum
- **WHEN** o launcher executa a suíte Unit, Feature ou o gate funcional completo
- **THEN** nenhum gerador de carga é iniciado e nenhum alvo de carga é provisionado

### Requirement: LOAD-02 Motor compatível e capacidades comprovadas

O harness MUST usar Pest com Stressless/k6 em versões compatíveis, registrando versões efetivamente instaladas de PHP, Pest, plugin e binário. Antes da carga, MUST comprovar autenticação real, concorrência total, múltiplas contas, classificação de respostas, percentis e cenários dinâmicos necessários. Recurso ausente MUST bloquear o cenário com diagnóstico. MUST NOT inventar APIs, alterar vendor, reduzir silenciosamente a massa para um token ou substituir/adaptar o motor fora da API suportada sem decisão explícita e atualização do design.

#### Scenario: Plugin ou binário incompatível
- **WHEN** a versão disponível conflita com Pest/PHP ou o k6 não executa no runtime escolhido
- **THEN** a execução termina como bloqueada antes de preparar dados ou iniciar carga
- **AND** não rebaixa dependências nem modifica vendor como fallback

#### Scenario: Capacidade não exposta pelo plugin
- **WHEN** não há mecanismo suportado comprovado para vários tokens, status detalhado, cursor ou p99
- **THEN** os cenários dependentes ficam bloqueados e a limitação exige decisão técnica explícita
- **AND** o relatório não declara tais cenários cobertos por repetir uma URL com um único token

### Requirement: LOAD-03 Alvo dedicado e referências por ambiente

A primeira etapa MUST usar alvo HTTP dedicado no Lerd, separado do desenvolvimento, com URL configurável, PostgreSQL e recursos próprios. O preflight MUST identificar separadamente servidor-alvo e gerador e MUST NOT presumir que a conexão de banco do Pest configure o servidor HTTP. Os cenários MUST ser reutilizáveis em homologação de VPS mediante autorização específica, registrando equivalência/diferenças de imagem, configuração e limites. Referências e thresholds MUST ser distintos por ambiente; produção MUST ser recusada na primeira entrega.

#### Scenario: Pest e servidor apontam para bancos diferentes
- **WHEN** o banco/identidade efetivos do servidor não coincidem com o manifesto autorizado do alvo
- **THEN** a campanha é recusada antes da carga e de qualquer limpeza no servidor

#### Scenario: Homologação remota
- **WHEN** os cenários são autorizados para uma homologação na VPS
- **THEN** usam a URL declarada e referência própria, com gerador preferencialmente fora da VPS-alvo
- **AND** gerador compartilhado, recursos compartilhados com produção e latência de rede são identificados como interferências, sem alegar isolamento físico inexistente

#### Scenario: Alvo produtivo
- **WHEN** a configuração identifica produção ou não permite comprovar o ambiente não produtivo
- **THEN** a execução é recusada, sem assumir que um domínio de homologação garante recursos isolados

### Requirement: LOAD-04 Ownership exato e lifecycle externo ao Pest

Antes de migrations, fixtures, troca de perfil, limpeza de cache/identidades ou remoção de recursos, o harness MUST validar ownership exato de campanha/dataset e destino PostgreSQL efetivo, com identificadores de execução e manifesto privado. O manifesto MUST vincular URL, instância/configuração do servidor, banco, namespace Redis, tokens de teste e processos provisionados. Campanhas simultâneas MUST usar recursos distintos ou recusar uma segunda lease sobre o mesmo alvo. MUST NOT usar liberação por substring, `migrate:fresh`, `FLUSHALL`, `FLUSHDB`, banco operacional ou cleanup presumido por rollback do processo Pest.

#### Scenario: Recurso com nome parecido
- **WHEN** banco, prefixo ou processo não corresponde exatamente ao registro de ownership da campanha
- **THEN** nenhuma escrita, invalidação ou remoção é autorizada nesse recurso

#### Scenario: Duas campanhas simultâneas
- **WHEN** duas invocações tentam preparar ou medir a mesma instância dedicada
- **THEN** recebem instâncias/recursos distintos ou a segunda é recusada antes de interferir na primeira
- **AND** um encerramento não limpa os recursos da outra campanha

### Requirement: LOAD-05 Massa reproduzível de vinte proprietários

A campanha padrão MUST preparar exclusivamente no alvo autorizado 20 contas distintas, ativas e verificadas, com PAT real por conta e exatamente 10 mil despesas por conta. UUIDv7, categorias, valores em centavos e datas MUST respeitar os contratos existentes. Distribuição de meses/categorias/descrições/empates e critérios de dados vazios MUST ser explícitos e versionados; referência civil e timezone MUST ser registrados. A massa MUST distinguir consulta da mesma conta de consultas entre contas e MUST NOT executar seeds pessoais ou criar dados por request medido. Reexecução da preparação do mesmo dataset MUST verificar/reusar a massa consistente ou falhar, sem duplicá-la.

#### Scenario: Preparação padrão
- **WHEN** uma campanha nova prepara a massa inicial
- **THEN** existem 20 proprietários e 200 mil despesas no banco exclusivo, com 10 mil por proprietário
- **AND** os dados permitem meses atuais/encerrados, filtros, ordenação com empates e resultados vazios controlados

#### Scenario: Dataset divergente ou referência mudou
- **WHEN** contagens, distribuição/versionamento ou data civil efetiva do alvo divergem do manifesto
- **THEN** a medição é recusada ou um dataset novo é preparado explicitamente fora da fase medida
- **AND** não se compara a rodada como equivalente à referência anterior

### Requirement: LOAD-06 Autenticação e correção antes de desempenho

Os cenários MUST usar Bearer tokens reais das contas da campanha, preservando Sanctum, status, verificação de e-mail, autorização e filtro de proprietário. Preflight e checagens do cenário MUST confirmar status e estrutura JSON:API esperados, ausência de dados alheios e coerência mínima de resultados, sem registrar conteúdo financeiro. Falhas 401/403/422, respostas rápidas inválidas e erros de transporte MUST NOT contar como leituras de negócio bem-sucedidas. Tokens MUST existir no banco servido pelo alvo e não apenas no banco do gerador.

#### Scenario: Token só existe no banco do Pest
- **WHEN** o servidor não autentica a credencial da campanha
- **THEN** o preflight falha antes da medição e não apresenta a resposta rápida 401 como ganho de desempenho

#### Scenario: Proprietários distintos
- **WHEN** o cenário alterna contas A e B com dados distinguíveis
- **THEN** cada credencial recebe apenas os recursos/fatos do próprio proprietário
- **AND** a checagem não depende de UUID ser credencial nem de login executado durante cada iteração

### Requirement: LOAD-07 Catálogo de leituras com estados controlados

O catálogo MUST medir separadamente listagem de despesas, métricas, insights e sugestões, com parâmetros válidos dos contratos atuais. Listagem MUST cobrir páginas 20/100, filtros combinados, ordenação monetária/alfabética, empates e navegação por cursores reais. Métricas MUST separar total/agrupamento por categoria e mês com dados/vazio. Insights MUST separar vigente/encerrado e resultado elegível/onboarding conforme os dados. Sugestões MUST separar termo frequente/raro/sem resultado. Cache de listagem frio/quente e registro Core primeira resolução/hit MUST ser dimensões explícitas independentes; limpeza MUST limitar-se aos recursos próprios fora da fase medida.

#### Scenario: Listagem paginada
- **WHEN** o cenário mede navegação após a primeira página
- **THEN** usa cursores retornados pelo alvo, preserva filtros/sort e verifica progressão sem repetir a primeira página como se fosse navegação

#### Scenario: Projeção com identidade ainda ausente
- **WHEN** métricas, insights ou sugestões resolvem uma chave lógica pela primeira vez
- **THEN** a rodada é identificada como primeira resolução e distingue sua associação técnica dos hits posteriores
- **AND** primeira resolução e hit não são misturados num único número apresentado como cache frio

#### Scenario: Cache de páginas aquecido
- **WHEN** o cenário mede cache quente da listagem
- **THEN** o aquecimento dos critérios e proprietários escolhidos ocorre antes da janela medida
- **AND** o resultado identifica cache quente e não é apresentado como desempenho de consultas sempre frias

### Requirement: LOAD-08 Perfis limitados e recuperação observável

O perfil inicial MUST separar aquecimento de rodadas medidas de 30 segundos com concorrência total 1, 5, 10 e 20, com distribuição declarada entre contas e cenário específico de mesma conta. O número declarado MUST ser a concorrência total do cenário, não ser multiplicado silenciosamente por processos/tokens. Entre níveis, MUST verificar encerramento do gerador, requests em voo e recuperação observável com prazo limitado. Duração, timeout por request, limite total de campanha e critérios de interrupção MUST ser explícitos antes de executar; alterações criam outro perfil. MUST NOT escalar indefinidamente nem confundir concorrência com vazão.

#### Scenario: Vinte contas em concorrência vinte
- **WHEN** o perfil entre contas mede o nível 20
- **THEN** no máximo 20 unidades concorrentes configuradas compõem o cenário total, distribuídas conforme o manifesto
- **AND** não são iniciadas 20 execuções com concorrência 20 cada

#### Scenario: Alvo não recupera entre níveis
- **WHEN** o gerador encerra mas o alvo não satisfaz a verificação de recuperação no prazo configurado
- **THEN** a campanha para com diagnóstico e não inicia o nível seguinte

### Requirement: LOAD-09 Capacidade e proteção original em perfis distintos

O perfil de capacidade MUST usar uma cota positiva explicitamente ampliada somente no alvo dedicado não produtivo, com valor efetivo registrado e demais proteções preservadas. O cenário de rate limit MUST usar os 60 requests/minuto por usuário originais com contadores limpos apenas no namespace próprio. MUST verificar compartilhamento entre rotas/tokens e independência entre contas, com 429 JSON:API e Retry-After. Os dois perfis MUST NOT compartilhar contadores contaminados nem desabilitar silenciosamente o middleware; mudança de perfil MUST ser confirmada no servidor, não só no gerador.

#### Scenario: Limite de capacidade ainda insuficiente
- **WHEN** o perfil ampliado recebe 429 durante uma rodada de capacidade
- **THEN** contabiliza os 429 separadamente e identifica a rodada como limitada pela cota, sem concluir saturação da aplicação a partir dela

#### Scenario: Proteção original
- **WHEN** a mesma conta admite 60 requests no período distribuídos pelas rotas medidas e por dois tokens
- **THEN** o próximo request recebe 429 com JSON:API/Retry-After enquanto outra conta dentro da cota é admitida
- **AND** o comportamento é classificado como proteção esperada, não falha de capacidade

### Requirement: LOAD-10 Métricas válidas e percentis sem fabricação

Cada rodada MUST registrar total e taxa de requests, duração efetiva, concorrência configurada/observada, distribuição de statuses, falhas de transporte, timeouts, 429 e latências p50/p95/p99 em milissegundos, com população de medição identificada. Fração de falhas e requests/segundo MUST ter unidades distintas. Percentis MUST derivar das amostras/estatísticas adequadas do motor e MUST NOT ser média de percentis de subprocessos. Métrica indisponível, amostragem insuficiente ou gerador saturado MUST tornar a comparação correspondente inconclusiva/bloqueada, sem zero inventado ou alegação de capacidade da aplicação.

#### Scenario: Múltiplos geradores parciais
- **WHEN** há resultados de contas ou processos diferentes na mesma rodada
- **THEN** o relatório preserva estratos e usa agregação estatisticamente válida para qualquer percentil global
- **AND** não calcula p99 global pela média dos p99 individuais

#### Scenario: Rodada com erros
- **WHEN** existem 429, respostas 5xx ou timeouts
- **THEN** as classes de resultado são discriminadas e a latência das respostas válidas não é confundida com a de todos os resultados

### Requirement: LOAD-11 Calibração precede limiares bloqueantes

A primeira campanha MUST estabelecer referência por endpoint, cenário, estado de cache/registro, perfil e ambiente antes de thresholds de desempenho bloqueantes. MUST incluir ao menos três repetições válidas de cada combinação candidata à referência, registrar variabilidade e suficiência de amostras e solicitar aprovação explícita dos limites. Até a aprovação, resultados de desempenho MUST ser classificados como calibração, sem selo de regressão aprovada; falhas de autenticação, correção, isolamento e ferramenta MUST continuar reprovando. Investigações de capacidade MUST registrar saturação/interrupção como achado, não como sucesso de regressão. Mudanças de código, massa ou recursos MUST NOT substituir automaticamente a referência para esconder regressão.

#### Scenario: Primeira referência sem limite aprovado
- **WHEN** as repetições produzem métricas válidas mas ainda não há thresholds aprovados
- **THEN** são publicados resultados de calibração e proposta de limites por combinação, sem fabricar um SLA

#### Scenario: Comparação entre ambientes
- **WHEN** uma rodada da VPS é comparada a uma referência do Lerd ou com recursos/perfil/dataset diferentes
- **THEN** o relatório identifica a comparação como não equivalente e não decide regressão por essa referência

#### Scenario: Regressão com referência aprovada
- **WHEN** uma rodada equivalente viola os limites aprovados de latência ou falhas
- **THEN** a verificação reprova e preserva referência e evidências anteriores

### Requirement: LOAD-12 Relatórios rastreáveis e instrumentação identificada

O harness MUST produzir resumo legível e relatório estruturado sanitizado por campanha/rodada, com revisão de código, dataset/perfil/seed/referência civil, versões, alvo/gerador, recursos e configuração efetiva de PHP-FPM/OPcache/PostgreSQL/Redis, cota e instrumentação. MUST separar medição de referência com instrumentação pesada desativada de diagnóstico com captura/profiler identificado. Tokens, senhas, credenciais, headers Authorization/Cookie, URLs com segredos, payloads financeiros e dumps brutos de configuração MUST NOT ser exportados. Temporários sensíveis MUST ficar privados e fora de artefatos versionados; retenção de relatórios sanitizados MUST ser explícita.

#### Scenario: Diagnóstico de gargalo
- **WHEN** Lerd captura queries/CPU de uma rodada diagnóstica
- **THEN** o relatório correlaciona a evidência ao cenário e identifica o custo de instrumentação
- **AND** não usa essa rodada como referência equivalente a uma execução sem captura pesada

#### Scenario: Exportação de relatório
- **WHEN** uma campanha exporta resultado legível/estruturado
- **THEN** somente campos permitidos são persistidos e credenciais/valores financeiros não aparecem no resultado ou linha de comando registrada

### Requirement: LOAD-13 Cleanup e interrupção sem resíduos alheios

Ao terminar, falhar ou receber interrupção tratável, o harness MUST encerrar os geradores próprios com prazo limitado, revogar tokens da campanha e limpar somente recursos registrados sob ownership validado. Configurações de perfil/instrumentação alteradas MUST ser restauradas; cleanup MUST NOT apagar relatórios sanitizados nem depender de rollback no cliente para desfazer efeitos HTTP. Recuperação após interrupção não tratável MUST usar manifesto/ownership e diagnóstico de resíduos, sem prometer cleanup automático sob SIGKILL. Reutilizar alvo preexistente MUST NOT autorizar removê-lo como se tivesse sido criado pela execução.

#### Scenario: Assertion ou processo falha
- **WHEN** uma checagem falha após requests criarem associações Core no alvo
- **THEN** finally/teardown encerra filhos e limpa recursos próprios, incluindo associações/tokens e temporários, no banco autorizado
- **AND** o banco operacional e namespaces de outras campanhas permanecem intactos

#### Scenario: Campanha interrompida sem teardown
- **WHEN** um processo é encerrado de forma que impede cleanup
- **THEN** uma operação posterior identifica os resíduos pelo manifesto e valida ownership antes de removê-los
- **AND** a rodada incompleta não recebe resultado aprovado
