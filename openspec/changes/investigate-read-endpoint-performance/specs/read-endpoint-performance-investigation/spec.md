## ADDED Requirements

### Requirement: INV-01 Evidência histórica sem atribuição prematura

A investigação MUST preservar as rodadas históricas, suas falhas e fontes, identificando concorrência, janela configurada, requests/RPS, fração de falhas e p50/p95 com unidades/população. MUST distinguir fatos, indícios e hipóteses e MUST NOT converter p95 de burst em SLA, número de usuários humanos ou capacidade VPS. Rodadas com erros MUST permanecer separadas das usadas para inferir custo de leituras bem-sucedidas; sonda 429 posterior MUST NOT ser apresentada como classificação de todos os requests anteriores.

#### Scenario: Latência crescente sem falhas
- **WHEN** a série histórica mostra pouco ganho de RPS e aumento de p95 sem falhas HTTP
- **THEN** o relatório registra o indício e a necessidade de reprodução
- **AND** não declara SQL, índice, FPM ou gerador como causa comprovada

#### Scenario: Rodada com erros e sonda 429
- **WHEN** uma rodada tem falhas e uma sonda posterior confirma 429/Retry-After
- **THEN** ela é identificada como afetada pela proteção e suas métricas incluem erros
- **AND** não é apresentada como limite de capacidade da operação nem taxonomia individual dos requests

#### Scenario: Latência superior à janela configurada
- **WHEN** a geração dura 1s e requests em voo terminam depois
- **THEN** o relatório distingue janela, término das requisições e tempo do processo
- **AND** não multiplica latências por cinco para prever uma rodada de 5s nem trata requests/1s como RPS efetivo

### Requirement: INV-02 Alvo e contexto reproduzíveis

Antes de tráfego/captura, o operador MUST confirmar explicitamente a instância dedicada não produtiva, URL/HTTPS, revisão realmente servida, configuração, PostgreSQL efetivo, conta/PAT e dados. MUST registrar data civil/timezone, parâmetros/população consultada, cache/registro e versões/recursos do gerador e servidor, distinguindo isolamento lógico de compartilhamento físico. MUST recusar contexto não comprovado e MUST NOT preparar/apagar massa ou presumir que o banco/revisão do Pest configure o servidor.

#### Scenario: Alvo ou credencial divergentes
- **WHEN** não é possível confirmar a instância/banco não produtivos ou o alvo rejeita a credencial
- **THEN** a prova dependente é bloqueada antes da carga/captura
- **AND** não existe fallback para o desenvolvimento ou criação automática de dados

#### Scenario: Revisão ou referência civil alteradas
- **WHEN** a revisão, distribuição mensal, data efetiva ou parâmetros diferem do histórico
- **THEN** a diferença é registrada e uma série nova é identificada
- **AND** ela não é apresentada como repetição equivalente sem justificar a comparação

#### Scenario: Gerador e servidor compartilham recursos
- **WHEN** processos dependem do mesmo host/VM/serviços físicos
- **THEN** ambos os lados têm recursos/arquiteturas/versões inventariados e a interferência é declarada
- **AND** execução AMD64 compatível em ARM64 não é rotulada como nativa nem extrapolada para produção

### Requirement: INV-03 Rodadas reduzidas com validade e limites explícitos

A investigação MUST priorizar Insights/Sugestões em C=1/10/20, usar listagem/métricas como controles em C=1/20 e obter pelo menos três repetições independentes por combinação selecionada ou registrar bloqueio/interrupção. MUST definir antes da execução orçamento de requests/tempo, timeouts, aquecimento e recuperação conforme recursos/cota, executar uma rota/processo por vez e preservar as proteções existentes. MUST iniciar com rodadas curtas e somente estender até 5s em C=1 quando o orçamento conservador permitir. MUST NOT repetir 50/100 automaticamente, ampliar cota, limpar contadores ou agregar percentis de rodadas como percentil global.

#### Scenario: Repetições comparáveis
- **WHEN** uma combinação é selecionada para reprodução
- **THEN** suas repetições usam contexto/parâmetros/estado declarados, janela de cota renovada e registro individual de resultados/variação
- **AND** preflight e sondas contam no orçamento da cota mas não nas latências da fase medida

#### Scenario: Cota ou amostragem impedem a análise
- **WHEN** surgem 429, amostras insuficientes ou impossibilidade de respeitar o orçamento
- **THEN** o resultado correspondente é inválido para vazão de negócio ou Inconclusive/Blocked, com causa registrada
- **AND** erros não são descartados, a duração/cota não aumenta automaticamente e percentis ausentes não recebem zero

#### Scenario: Falta de recuperação ou prazo excedido
- **WHEN** o alvo/gerador não recupera no prazo, há timeout ou limite de recursos excedido
- **THEN** a sequência para e os processos próprios são encerrados com prazo finito
- **AND** não começa uma rodada maior para tentar compensar a falha

### Requirement: INV-04 SQL e callers identificados por tráfego real

O diagnóstico de queries MUST partir de tráfego fresco da rota/site/branch selecionados, com correlação temporal suficiente para localizar callers, contagens e tempos por request. MUST inspecionar schema/índices/estatísticas por leitura antes de sugerir DDL. Planos com execução MUST ser limitados a SELECTs de leitura no banco dedicado, com parâmetros privados e timeout, registrando cardinalidades/scans/sort/buffers/spills quando disponíveis. MUST NOT adivinhar N+1 pelo controller, executar ANALYZE de escritas, criar índices, rodar manutenção ou alterar planos/configuração como correção nesta change.

#### Scenario: Query candidata observada
- **WHEN** captura de uma rota aponta SELECTs repetidos ou de custo relevante
- **THEN** o relatório vincula query/caller do checkout servido, request/rodada e plano/contagens/tempos obtidos
- **AND** distingue o custo observado de uma recomendação ainda não validada

#### Scenario: Plano exige executar SQL
- **WHEN** se pretende usar EXPLAIN com ANALYZE
- **THEN** o operador confirma SELECT de leitura, destino dedicado, parâmetros privados e limite de execução
- **AND** escrita/DDL ou destino não comprovado bloqueiam essa execução

#### Scenario: Captura ausente ou antiga
- **WHEN** não há evidência fresca da rota selecionada ou a ferramenta não fornece o dado necessário
- **THEN** a lacuna é registrada como Unproven/Blocked
- **AND** ausência de alerta não é tratada como prova de ausência de gargalo

### Requirement: INV-05 Separação entre execução, espera e geração de carga

A investigação MUST observar separadamente CPU PHP, queries/esperas PostgreSQL/Redis, disponibilidade/fila/limites do PHP-FPM e consumo/compatibilidade do gerador/host, usando capacidades locais existentes. MUST correlacionar medidas comparáveis por request/janela e MUST NOT fabricar tempo de fila por subtração de percentis agregados de populações distintas. Falta de observação ou gerador saturado MUST limitar explicitamente qualquer conclusão sobre o alvo; status/debug endpoints públicos ou mudanças de recursos/runtime não fazem parte da investigação.

#### Scenario: Hipótese de espera no FPM
- **WHEN** o tempo HTTP cresce com concorrência e a fila de workers é suspeita
- **THEN** a conclusão procura observações de workers/queue/limites e tempos na mesma janela
- **AND** latência crescente isolada não confirma saturação do pool

#### Scenario: Hipótese de CPU ou banco
- **WHEN** captura/perfil mostra funções ou queries custosas
- **THEN** seus tempos/contagens são relacionados ao request e aos recursos observados
- **AND** nenhum custo é atribuído a composição, autenticação, PAT ou registro Core sem evidência do mecanismo

#### Scenario: Gerador indisponível ou saturado
- **WHEN** o gerador limita a emissão/medição ou faltam métricas para distingui-lo do alvo
- **THEN** a inferência correspondente é Inconclusive/Blocked
- **AND** troca de runtime, gerador externo ou recursos é proposta para decisão, não executada implicitamente

### Requirement: INV-06 Instrumentação identificada e reversível

Medições de referência MUST ser separadas das rodadas com captura/profiler pesado. Antes de mudar instrumentação, o operador MUST registrar o estado/alcance anterior e coordenar efeitos globais; MUST restaurar exatamente esse estado e verificar recuperação ao terminar/falhar. Capturas MUST usar site/branch/intervalo e dados permitidos, sem tokens, headers secretos, SQL bindings, fatos financeiros ou dumps brutos em relatórios. MUST encerrar somente processos/temporários próprios e MUST NOT apagar massa, credenciais ou recursos preexistentes para concluir a investigação.

#### Scenario: Comparação instrumentada
- **WHEN** captura de queries/CPU é ativada para diagnosticar uma rota
- **THEN** a rodada é identificada como diagnóstica e não substitui a referência sem captura pesada
- **AND** uma comparação de overhead usa contexto equivalente e informa diferenças

#### Scenario: Toggle global ou falha de restauração
- **WHEN** uma mudança afetaria outro site ou o estado anterior não pode ser restaurado
- **THEN** a parte afetada é bloqueada ou encerrada com a pendência explicitamente registrada
- **AND** instrumentação preexistente do usuário não é desligada como se fosse criada pela investigação

#### Scenario: Relatório e encerramento
- **WHEN** evidências são consolidadas ou uma rodada falha
- **THEN** só campos sanitizados são publicados e processos/temporários próprios são tratados com prazo limitado
- **AND** recursos e dados preexistentes são preservados, com saúde e limitações de cleanup registradas

### Requirement: INV-07 Hipóteses com evidência e alternativas

Cada hipótese MUST ter observação motivadora, mecanismo, evidência a coletar, critérios que a apoiam/refutam e limitações. Achados MUST ser classificados como Proven, Partially proven, Unproven ou Blocked, com hipótese apoiada/refutada/inconclusiva e confiança justificadas. Confirmação causal MUST exigir evidência do mecanismo e comparação controlada suficiente; correlação isolada, leitura de código ou um único p95 MUST NOT ser apresentados como causa confirmada.

#### Scenario: Evidência parcial
- **WHEN** há hotspot/plano/espera correlacionado mas alternativas relevantes permanecem
- **THEN** o achado é Partially proven ou inconclusivo e as alternativas são listadas
- **AND** a proposta de próxima intervenção não é descrita como correção comprovada

#### Scenario: Hipótese refutada
- **WHEN** uma observação adequada contradiz o mecanismo proposto
- **THEN** o relatório registra a evidência contrária e o contexto em que ela vale
- **AND** não remove a hipótese do histórico para aparentar confirmação uniforme

#### Scenario: Controle depende de mudança fora do escopo
- **WHEN** distinguir uma hipótese exige índice, alteração de pool/cota/runtime, novos dados ou mudança de produto
- **THEN** o controle é proposto com evidência/risco e decisão necessária
- **AND** a prova dependente permanece Unproven/Blocked sem execução implícita da mudança

### Requirement: INV-08 Relatório decisório sem implementação presumida

A entrega MUST conter inventário/contexto, histórico preservado, rodadas válidas/inválidas, matriz de hipóteses/evidências e propostas priorizadas por rota/owner/camada, com risco, mecanismo esperado e forma de validação. MUST preservar os contratos/limites arquiteturais e o harness PHP simples existente. MUST NOT aplicar correções, alterar assertions/limiter para obter verde, definir SLA arbitrário, criar dependências/harness, operar VPS ou arquivar/publicar por inferência. A autorização de criar esta spec MUST NOT ser interpretada como apply da investigação; sua execução futura exige autorização explícita.

#### Scenario: Encerramento com causa inconclusiva
- **WHEN** as provas viáveis não distinguem suficientemente as causas
- **THEN** o relatório descreve achados, lacunas e os próximos experimentos/decisões necessários
- **AND** não alega causa resolvida, melhoria ou capacidade de produção

#### Scenario: Proposta de otimização após diagnóstico
- **WHEN** uma intervenção é recomendada a partir das evidências
- **THEN** ela informa owner, alcance, risco e validação proposta para decisão separada
- **AND** a investigação não altera produto/infraestrutura nem enfraquece os contratos para implementá-la
