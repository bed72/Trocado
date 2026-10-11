## Why

O frontend precisa combinar período, categorias, faixa de valor e ordenações na mesma listagem paginada de despesas. Os filtros locais de ano/mês/dia já implementados são o ponto de partida, mas não cobrem intervalos abertos nem múltiplas ordenações.

## What Changes

- Compor filtros e ordenações com o Query Builder nativo do Laravel, por meio de Eloquent em Expense Infrastructure, sem adicionar dependências.
- Preservar os filtros opcionais `filter[year]`, `filter[month]` e `filter[day]`; adicionar `filter[from]`, `filter[to]`, `filter[category]`, `filter[amount_min]` e `filter[amount_max]`.
- Permitir categorias por OU e critérios distintos por E, com limites de data e valor independentes e inclusivos.
- Permitir `sort` com múltiplos campos entre `occurred_on`, `description` e `amount`, nas duas direções, com ID decrescente como desempate final.
- Adaptar cursor, links e cache à consulta efetiva, conservando o comportamento da listagem sem parâmetros.
- Preservar o contrato atual de descrição opcional/nullable, sem alteração de criação, edição, invariantes ou dados existentes.
- Ordenar descrições ignorando maiúsculas/minúsculas e acentos, conforme decisão do usuário, com collation ICU explícita e desempate pelos critérios seguintes e ID decrescente; preservar o texto original.

## Capabilities

### New Capabilities

- `expense-querying`: contrato de filtros combináveis e múltiplas ordenações implementados com Query Builder nativo, sem dependência HTTP na Application.

### Modified Capabilities

- `expense`: paginação configurável, links e cache coerentes com consultas combináveis.
- `expense-repository-boundaries`: invalidação de todas as variantes filtradas/ordenadas após escritas confirmadas.

## Impact

- Request, Controller, UseCase, Data, contratos e Repositories de consulta de Expense. A implementação não exige mudanças em `composer.json` ou `composer.lock`.
- Doubles e testes afetados pela nova assinatura; coleção Bruno quando explicitamente afetada pelo contrato, preservando alterações locais existentes. Descrição, fixtures e seeders conservam seu comportamento atual.
- Banco PostgreSQL e cache Redis: collation explícita para ordenação, versionamento de cache e invalidação por proprietário. Sem limpeza de dados, NOT NULL/CHECK de descrição, novo endpoint, contexto, relação cross-context, linguagem RQL arbitrária ou mudança nas filas.
- Em 2026-10-11, a etapa 1 foi concluída. A etapa de descrição obrigatória chegou a ser implementada e testada, mas foi cancelada pelo usuário: todo seu código, migration, suporte e testes foram revertidos. Nenhuma limpeza ou migration dessa etapa foi aplicada ao banco local. A mudança ativa volta a se limitar às consultas combináveis.
