## Why

A dashboard navegará entre meses por gestos, mas Insights hoje rejeita filtros e calcula somente o mês vigente. Além disso, títulos como “Um figurante? Claro que não” ocupam espaço sem identificar o fato: precisamos de mensagens muito curtas, específicas e úteis para o mês selecionado.

## What Changes

- Aceitar `filter[year]` e `filter[month]` como conjunto opcional em `GET /api/insights`, seguindo a nomenclatura de Expense. Sem filtros, conservar o mês vigente no timezone da aplicação.
- Analisar o mês vigente do dia 1 até hoje, inclusive; meses passados do dia 1 ao último dia do mês selecionado. Rejeitar meses futuros e parâmetros inválidos com `422` JSON:API.
- Preservar comparação corrente de dias completos equivalentes e acrescentar comparação explícita entre totais de meses encerrados. Manter elegibilidade, exatidão, isolamento, prioridades e deduplicação existentes.
- Substituir títulos genéricos/piadas por informação concreta; adotar limites aprovados de 24 caracteres Unicode para título e 80 para descrição após interpolação, com alternativas completas e verificáveis no catálogo editorial revisão 1.
- Identificar a maior despesa por descrição utilizável; quando ausente ou longa, usar categoria e data. Conservar percentual e, quando couber, valor monetário exato, sem inventar descrição nem truncar fatos.
- Separar mês analisado de dia da consulta, para preservar rotação diária mesmo navegando por meses passados; adequar onboarding e linguagem histórica.
- Atualizar a coleção Bruno de Insights com filtros opcionais, exemplos de mês vigente/passado e casos inválidos, mantendo a consulta sem filtro disponível.
- **BREAKING (editorial):** reduzir os limites máximos de texto e remover a obrigação de humor; consumidores e testes não devem depender de títulos literais ou variantes antigas. Grupos, tipos e formato JSON:API permanecem compatíveis. A aceitação de filtros amplia o contrato anterior de rejeição.

## Capabilities

### New Capabilities

Nenhuma. A evolução pertence ao contexto existente de Insights; Bruno é suporte de consumo desta mesma capacidade.

### Modified Capabilities

- `insights`: seleção mensal opcional, validação, períodos correntes/encerrados, comparações, mensagens informativas, identificação do maior lançamento, onboarding histórico, rotação diária e atualização da coleção Bruno.

## Impact

- Presentation de Insights: Request, Controller e preservação do contrato de `InsightResponse`.
- Application/Domain de Insights: entradas temporais explícitas, projeções, candidatos, comparação mensal, catálogo e composição editorial.
- Infrastructure de Insights: leitura única e somente de leitura de `expenses`, incluindo descrição/data do maior lançamento no mesmo snapshot dos agregados.
- Testes focados de Core/Insights quando necessários, arquitetura e evidências PostgreSQL/HTTP na futura implementação.
- `bruno/Insights/01 - Get Insights.bru` e exemplos relacionados em `bruno/Insights/`; documentação existente de arquitetura/API quando aplicável.
- Flutter deverá iniciar no mês vigente, enviar ano/mês ao navegar e limitar avanço ao vigente. A implementação Flutter está fora deste repositório e desta mudança.
- Sem dependências, migrations, cache, filas, IA, estado de navegação persistido ou alterações no CRUD de Expense.

O catálogo editorial revisão 1 e os limites 24/80 foram aprovados explicitamente em 11/10/2026, concluindo a task 1.1. O usuário autorizou depois a etapa “2. Implementar filtros e períodos”, incluindo verificações focadas de seleção mensal e calendário. As evidências dessa entrega estão em `tasks.md`; a integração editorial completa, identificação do maior lançamento, Bruno e demais tarefas continuam pendentes.
