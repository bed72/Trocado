## 1. Autorizar investigação e confirmar contexto

- [x] 1.1 Obter autorização explícita de apply e reconferir pelo Lerd alvo não produtivo, URL/HTTPS, revisão realmente servida, banco efetivo, conta/PAT, 60 mil despesas/distribuição mensal e referência civil/timezone; bloquear divergências antes do tráfego. [INV-02; D2]
- [ ] 1.2 Inventariar separadamente gerador/servidor, versões/arquitetura, CPU/memória/limites, PHP-FPM/OPcache, PostgreSQL/Redis, compartilhamento físico e estado/alcance da instrumentação disponível, registrando dados ausentes. [INV-02/05/06; D2/D6]
- [ ] 1.3 Registrar matriz reduzida, orçamento de requests/tempo total, timeouts, recuperação/interrupção e plano de restauração da instrumentação antes de executar; conferir limites reais do tooling existente sem criar outro harness. [INV-03/06; D2–D4]

## 2. Reproduzir o sintoma sem confundir cota e capacidade

- [x] 2.1 Reconferir a classificação do histórico e identificar diferenças de revisão/data/massa/cache/registro/termo; preservar as seis reprovações e distinguir janela de 1s, tail e população incluindo erros. [INV-01/02; Context/D1]
- [ ] 2.2 Executar sondas/preflight e três repetições independentes de Insights/Sugestões em C=1/10/20, inicialmente 1s, com janela de cota renovada e resultados individuais; registrar rodadas inválidas/bloqueadas sem ocultá-las. [INV-03; D3]
- [ ] 2.3 Executar controles listagem/métricas em C=1/20 com três repetições nas mesmas condições declaradas; observar diferenças de população/cache sem tratá-los como operações de custo idêntico. [INV-02/03; D1/D3]
- [ ] 2.4 Avaliar suficiência/variação das amostras; justificar necessidade ou dispensa de C=5/sonda C=1 até 5s, executando somente se caber no orçamento/cota e autorização, ou registrar a prova dependente Inconclusive/Blocked. [INV-01/03; D3]

## 3. Identificar queries, planos e esperas relevantes

- [x] 3.1 Em janela diagnóstica separada, partir de route timing e tráfego fresco das duas rotas prioritárias para capturar queries/contagens/tempos e callers no checkout servido, com site/branch/intervalo/correlação e lacunas registrados. [INV-04/06; D4]
- [x] 3.2 Inspecionar schema/índices/estatísticas por leitura e obter planos dos SELECTs relevantes com parâmetros privados e timeout, registrando cardinalidade/scans/sort/buffers/spills disponíveis; recusar planos executados de escrita/DDL ou destino não comprovado. [INV-04; D5]
- [x] 3.3 Confrontar H1/H2/H5 com queries/planos/esperas observadas, distinguindo consulta analítica, busca histórica, autenticação/PAT, registro Core e Redis; não presumir escrita/lock em cada GET nem criar índice/manutenção. [INV-04/05/07; D5/D7]

## 4. Distinguir CPU, fila de workers e gerador

- [x] 4.1 Capturar perfil CPU/tempo nas rotas prioritárias em rodadas explicitamente instrumentadas, relacionando hotspots/SQL ao mesmo request ou janela, sem subtrair p95 de populações diferentes. [INV-05/06; D4/D6]
- [ ] 4.2 Observar workers/fila/limites FPM e consumo do PostgreSQL/Redis/gerador/host; confrontar H3/H4/H6 com evidência correlacionada ou registrar impossibilidade, sem alterar pool, recursos ou runtime. [INV-05/07; D6/D7]
- [ ] 4.3 Avaliar H7/overhead em contexto equivalente quando viável e restaurar os estados anteriores após cada janela/falha; coordenar toggles globais ou bloquear a captura afetada, preservando instrumentação preexistente. [INV-06/07; D4/D7]

## 5. Sintetizar o diagnóstico e propor próximas decisões

- [x] 5.1 Preencher H1–H8 por rota com evidência favorável/contrária, alternativas, confiança e estado Proven/Partially proven/Unproven/Blocked; indicar se a hipótese foi apoiada/refutada ou permanece inconclusiva. [INV-07; D7]
- [x] 5.2 Produzir relatório com inventário sanitizado, rodadas válidas/inválidas e propostas priorizadas por owner/camada, mecanismo esperado, risco e experimento de validação; obter decisão própria antes de qualquer correção. [INV-08; D8]
- [x] 5.3 Verificar saúde/recuperação e restauração final, encerrar apenas processos/temporários próprios, conferir sanitização/limitações de retenção das capturas e preservar massa/PATs/recursos preexistentes. [INV-06/08; Migration Plan]

## 6. Fechar evidências documentais

- [x] 6.1 Atualizar a matriz requisito/cenário → evidência com comandos, versões, alvos, resultados e limitações reais; revisar truthfulness das tarefas e validar esta change estritamente após registrar a execução. [INV-01–08]
- [ ] 6.2 Entregar achados e decisões pendentes ao usuário, deixando explícitos bloqueios e ausência de implementação/melhoria/capacidade VPS; não arquivar, publicar ou aplicar intervenções por inferência. [INV-07/08]

## Dependências e estado inicial

- **0/18 tarefas de execução concluídas.** O pedido atual autoriza somente a elaboração/validação documental. Resultados históricos já executados não marcam tarefas desta investigação como cumpridas.
- Grupo 1 precede novas rodadas; grupos 3–4 usam o contexto das rodadas do grupo 2 e dados frescos, não inferência por leitura de código. Não começar uma sequência maior se o alvo não recuperar.
- Usar apenas Pest/Stressless e os diagnósticos existentes. Não criar JS, outro gerador, campanha automática ou hierarquia nova de código.
- Nenhuma correção de produto/SQL/índice/cache/pool/limiter está autorizada por esta change. Se uma próxima intervenção for aprovada em escopo próprio, ela deverá definir suas verificações funcionais/arquiteturais; esta investigação não executa o quality gate inteiro da aplicação como substituto de diagnóstico.
- Hipóteses H1–H8 começam **Unproven**. Dados históricos de latência/falhas são observações, não prova de SQL lento, N+1, índice ausente ou saturação do FPM/gerador.

## Validação da elaboração — 2026-10-16

- OpenSpec CLI **1.6.0**; doctor indicou root saudável. Change criada pelo CLI; proposal/design/specs/tasks seguiram as instruções de cada artefato.
- `openspec validate investigate-read-endpoint-performance --type change --strict --json --no-interactive`: **válido, sem issues**. Status confirma os quatro artefatos de planejamento completos, não a execução da investigação.
- Conferidos **1 capability nova, 8 requisitos, 23 cenários e 18 tarefas de execução pendentes**, com matriz de rastreabilidade em design. Os dados das 16 rodadas foram transcritos da change de carga, mantendo falhas, unidades e limitações.
- Whitespace dos quatro Markdown novos conferido individualmente com `git diff --no-index --check /dev/null <arquivo>`, sem erros. Alterações desta elaboração limitadas à nova pasta; alterações preexistentes foram preservadas.
- Nenhuma nova carga, captura/profiler, query operacional, teste da aplicação, migration, correção, commit, push ou archive foi executado para elaborar esta spec.

## Investigação focal autorizada — 2026-10-16

- Pedido: “Pode fazer essa investigacao aqui — Insights e sugestões merecem investigação prioritária.” Iniciada investigação focal das duas rotas; a matriz completa de carga e o fechamento das 18 tarefas não são presumidos deste recorte.
- Preflight: site dedicado e revisão `628c93294ba8d82dc7d87e5cb7599768db543454` confirmados; `APP_ENV=load-testing`, banco dedicado exato, uma conta, 60.000 despesas/10.000 por mês de maio a outubro, 18 categorias, referência 2026-10-16/UTC. Configuração privada existente está no PHP compartilhado, não no custom-FPM; não foi copiada nem exposta. Sonda autenticada de Insights retornou 200.
- Instrumentação inicial: dumps e SPX já habilitados globalmente; watcher parado, route timing sem amostras. Estados preexistentes serão preservados; sem limpar capturas globais. Referência sem instrumentação fica bloqueada enquanto não houver decisão coordenada sobre os toggles globais. Medições atuais são diagnósticas.
- Orçamento da etapa focal: até 30 requests HTTP individuais (sondas incluídas), sequenciais, connect timeout 3s/request timeout 10s; até duas sondas instrumentadas adicionais de profiler. Não executar burst de 50/100 ou nova matriz antes de resolver suficiência/instrumentação. EXPLAIN apenas SELECT observado no banco dedicado, transação read-only, statement timeout 5s; sem mudar configurações. Prazo operacional desta etapa: 15 minutos a partir do preflight. Parar em HTTP não 200, timeout ou falta de recuperação; não repetir até verde. Saúde final por `/up` com timeout 10s. Nenhuma correção de produto autorizada.
- Primeiras seis leituras diagnósticas após preflight: Insights 380,92/250,61/234,25 ms; sugestões 323,10/310,52/292,83 ms, todas 200. Não são percentis de carga nem evidência de regime estacionário. Estado de captura preexistente impede classificá-las como referência limpa.
- Relatório e matriz requisito/cenários → evidência em `design.md`, seção “Diagnóstico focal executado”. Query principal de Insights 160,16–185,34 ms; sugestões 202,06–245,54 ms. Planos read-only demonstraram materializações/expansão e sorts temporários em Insights; 60 mil linhas/900 grupos e sort em disco antes do LIMIT em sugestões. Perfis HTTP identificaram SELECT como maior hotspot de wall; geração/composição editorial sub-ms a poucos ms. Não equivalem a CPU separada ou prova de capacidade.
- Logs FPM comprovam max_children=5 atingido historicamente. Não foi medido tempo em fila; atribuição de todo o platô ao pool continua parcial. Outlier instrumentado de Insights foi preservado (HTTP 1.132,65 ms; SPX wall 908 ms), inclusive seu warning agregado no route timing.
- Nove tarefas com evidência focal foram marcadas; 4.1 prova perfil de tempo/wall, não CPU isolada. 1.2/1.3 continuam parciais; 2.2/2.3/2.4 e 4.2/4.3 não são consideradas concluídas por sondas individuais. A matriz completa C=1/10/20, controles e referência limpa não foi executada. Nenhuma hipótese inconclusiva foi convertida em pass.
- Encerramento operacional: nove requests autenticados no total (uma sonda inicial, seis leituras, duas sondas SPX) e `/up` final 200. Dumps/SPX preservados habilitados; nenhum toggle, limpeza global ou processo persistente próprio. Capturas mantidas nos armazenamentos privados preexistentes das ferramentas, com retenção declarada no design. Sem correção de produto, testes funcionais, migrations, novo harness ou alteração de cota/pool/índices.
- Gate documental focal: `openspec validate investigate-read-endpoint-performance --type change --strict --json --no-interactive` passou sem issues; whitespace de design/tasks conferido por `git diff --no-index --check /dev/null <arquivo>`. Com rastreabilidade/validação 6.1, estado atual **10/18 tarefas concluídas**, oito pendentes; change inteira não declarada concluída/arquivável. Sem edição PHP própria, Pint/testes funcionais não se aplicam a este diagnóstico documental. Edição concorrente do usuário em Bruno detectada e preservada.
