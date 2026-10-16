## Why

As rodadas locais com 60 mil despesas mostraram pouco ganho de vazão e forte aumento de latência em Insights e sugestões: de 10 para 20 concorrentes, o p95 passou de aproximadamente 1s para 2s, sem falhas HTTP. Em cargas maiores, respostas 429 contaminaram parte das métricas; precisamos separar custo de SQL, PHP, espera no PHP-FPM, gerador e limiter antes de propor correções.

## What Changes

- Definir uma investigação reproduzível, priorizando `GET /api/insights` e `/api/expenses/suggestions?query=teste`, com listagem e métricas como controles.
- Preservar a tabela das 16 rodadas de concorrência 10/20/50/100 e suas limitações; distinguir fatos, hipóteses e causas comprovadas.
- Conferir alvo/revisão/massa, configuração e recursos do servidor e do gerador antes de qualquer nova captura.
- Repetir uma matriz reduzida sem cota contaminada e correlacionar tráfego real com queries, planos PostgreSQL, CPU e espera de workers pelo tooling existente do Lerd.
- Separar medições de referência de rodadas instrumentadas, com prazos finitos, restauração da instrumentação e relatórios sem segredos/dados financeiros.
- Entregar diagnóstico por hipótese, evidências, limitações e propostas priorizadas para decisão do usuário. Conclusão inconclusiva permanece explícita quando faltar prova.

O pedido atual autoriza **escrever/validar esta spec**, não executar a investigação. O futuro apply da investigação também não autoriza corrigir produto, criar índices/migrations, mudar pool/recursos, alterar cota, fazer deploy ou iniciar uma suíte/harness novo. Qualquer intervenção proposta exige decisão e escopo próprios.

## Capabilities

### New Capabilities

- `read-endpoint-performance-investigation`: protocolo e critérios de evidência para investigar latência/vazão das leituras, distinguindo efeitos da aplicação, runtime, gerador, amostragem e proteção de requisições.

### Modified Capabilities

Nenhuma. Esta investigação preserva os contratos de Insights, sugestões, métricas, Expense, observabilidade e rate limiting. Não altera a change de carga simples nem reintroduz sua adaptação/harness descartados.

## Impact

- Nesta elaboração: somente os artefatos de `openspec/changes/investigate-read-endpoint-performance/`.
- No futuro apply autorizado: servidor Lerd dedicado existente, PostgreSQL/Redis e gerador Pest/Stressless já disponíveis; uso de diagnósticos, logs e profiler existentes, respeitando seu alcance global/per-site.
- Os resultados podem indicar responsáveis em Insights/Expense/Metrics Infrastructure, Core, composição PHP/Laravel ou ambiente, sem antecipar qual deles é a causa nem ampliar fronteiras arquiteturais.
- Sem dependências novas, APIs públicas, alterações em `app/`, testes funcionais, migrations, limiter, código JS, runtime k6 próprio ou operações VPS nesta change.
