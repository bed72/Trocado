## Why

A investigação focal identificou SQL de 160–246 ms nas leituras de Insights/sugestões, com materializações e sorts em disco na massa de 60 mil despesas. O usuário autorizou os ajustes e informou uma VPS com 2 vCPUs/8 GB RAM: reduzir trabalho por request é prioritário antes de aumentar concorrência.

## What Changes

- Reduzir expansão/materialização de linhas largas em Insights e selecionar o maior lançamento sem ordenar todo o histórico expandido.
- Selecionar os cinco grupos de sugestões pelo ranking histórico antes de calcular grafia e fatos detalhados desses grupos, normalizando descrições uma vez.
- Preservar leitura financeira única, snapshot, ownership, exatidão, períodos, normalização, ranking e IDs estáveis.
- Verificar com testes existentes PostgreSQL e comparação antes/depois na massa dedicada; registrar limitações e nenhum SLA/capacidade VPS presumido.

## Capabilities

### New Capabilities

- `read-query-efficiency`: execução eficiente das leituras sem alterar contratos financeiros ou HTTP.

### Modified Capabilities

Nenhuma alteração funcional nas capacidades de Insights e sugestões.

## Impact

Dois Repositories de Infrastructure e artefatos desta change. Sem novos pacotes, cache, schema, índices, alterações de pool/cota, deploy ou operação da VPS. A autorização cobre implementação e verificações focadas, preservando a investigação anterior como evidência histórica.
