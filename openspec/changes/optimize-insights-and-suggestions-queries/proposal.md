## Why

A investigação focal identificou SQL de 160–246 ms nas leituras de Insights/sugestões, com materializações e sorts em disco na massa de 60 mil despesas. O usuário autorizou os ajustes e informou uma VPS com 2 vCPUs/8 GB RAM: reduzir trabalho por request é prioritário antes de aumentar concorrência.

Após a primeira otimização, o usuário pediu investigação aprofundada e novos steps nesta mesma change. O diagnóstico ampliado encontrou busca histórica ainda proporcional à massa, ordenações alternativas sem índice específico e custos transversais de sessão/bootstrap, distinguindo o FPM local do Apache definido no Dockerfile. A capacidade e a configuração efetivamente publicadas na VPS continuam desconhecidas.

## What Changes

- Reduzir expansão/materialização de linhas largas em Insights e selecionar o maior lançamento sem ordenar todo o histórico expandido.
- Selecionar os cinco grupos de sugestões pelo ranking histórico antes de calcular grafia e fatos detalhados desses grupos, normalizando descrições uma vez.
- Preservar leitura financeira única, snapshot, ownership, exatidão, períodos, normalização, ranking e IDs estáveis.
- Verificar com testes existentes PostgreSQL e comparação antes/depois na massa dedicada; registrar limitações e nenhum SLA/capacidade VPS presumido.
- Acrescentar evidências de 19 planos SELECT, leituras com cache/persistência e perfis HTTP, preservando as seis tarefas já concluídas.
- Planejar steps posteriores de referência de runtime, busca indexável, sessão, índices de listagem, coordenação condicional de cache e aceitação integrada, com gates de decisão e contratos preservados.
- Neste incremento: executar somente investigação local e atualizar artefatos. Implementações adicionais, DDL, alterações de metadados de sessão e operações na VPS ficam pendentes por step.

## Capabilities

### New Capabilities

- `read-query-efficiency`: execução eficiente das leituras e de seus custos transversais de autenticação/cache/runtime, preservando contratos financeiros e HTTP; EFF-01–03 já implementados, EFF-04–08 prospectivos.

### Modified Capabilities

Nenhuma alteração funcional nas capacidades de Insights e sugestões.

- `authentication`: no STEP 6, explicitar que a releitura bloqueante é obrigatória antes de renovar, permitindo uma releitura fresca sem lock para decidir não renovar. Política 30/15/90, autenticação, tracking e respostas permanecem preservados.

## Impact

A primeira entrega alterou dois Repositories de Infrastructure, sem novos pacotes, cache, schema, índices, pool/cota ou deploy. O incremento atual altera somente os artefatos desta change. Os steps futuros podem atingir Expense Infrastructure/índices, Identity Infrastructure, cache e arquivos de deploy; migrações/extensões e decisões de tracking exigem aprovação no step correspondente. Domain/Application e interfaces HTTP continuam preservados. O incremento não declara configurações locais como configurações da VPS nem reabre como pendentes as correções já verificadas.

### Apply local posterior — STEP 5

Após autorização para executar as melhorias locais e confirmação de que não há acesso à VPS/Dokploy, STEP 4 fica adiado/Blocked. O STEP 5 compara candidatos indexáveis e implementa a alternativa medida de compactar grafias idênticas antes da normalização, com seleção adaptativa entre dois caminhos SQL equivalentes. Não aplicar DDL: o GIN experimental não melhorou a busca ampla e aumentou custo de escrita. O apply fica em Expense Infrastructure e testes focados; não altera Domain/Application/HTTP, runtime, tracking, cache ou cotas. Os resultados e regressões/overhead devem permanecer explícitos no design/tasks.

### Apply local posterior — STEP 6

Pedido “Próxima step” autoriza somente 6.1–6.3. Inventariar tracking e manter last_used_at habilitado pela opção oficial, sem inferir aprovação para descartar histórico de atividade. Otimizar SessionAdapter por leitura fresca sem lock e releitura com lock apenas quando houver possibilidade de renovar; provar estado antigo, mudanças concorrentes e separar contenção do tracking da renovação. Não alterar Notifications, política pura, guard, limiter, schema ou autenticação.
