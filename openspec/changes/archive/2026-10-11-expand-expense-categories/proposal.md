## Why

O catálogo atual concentra financiamentos, investimentos, impostos, seguros, cuidados pessoais, pets, presentes/doações e viagens em categorias genéricas. Expandir o catálogo permite registrar e interpretar essas saídas com mais precisão, mantendo os identificadores existentes e a integração entre Expense, Metrics e Insights.

## What Changes

- Acrescentar oito categorias: `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations` e `travel`, totalizando dezoito identificadores.
- Aceitar as novas categorias na criação, edição e filtros de despesas; preservar as dez categorias atuais, o padrão `other` e a proteção de categorias informadas pelo cliente.
- Descrever as novas categorias e seus limites no classificador automático, especialmente financiamento versus compra parcelada, investimento versus consumo e viagem versus deslocamento cotidiano.
- Incluir todas as novas categorias nos totais, percentuais e análises de valores registrados. Investimentos representam saídas registradas neste escopo, sem serem apresentados como consumo, prejuízo ou rendimento.
- Aprovar rótulos editoriais compactos para Insights e verificar interpolação completa dentro dos limites aplicáveis, incluindo os limites 24/80 da change `add-monthly-insights-filters`.
- Manter dados existentes sem recategorização automática ou alteração dos valores persistidos.
- Expansão aditiva do contrato: clientes com enums/listas fechadas das dez categorias precisarão aceitar os novos valores. Endpoints, envelopes JSON:API e tipos de recursos permanecem iguais.

## Capabilities

### New Capabilities

Nenhuma. A expansão pertence às capacidades existentes.

### Modified Capabilities

- `expense`: catálogo fechado ampliado, semântica das novas categorias, aceitação no ciclo de vida e filtros, classificação automática e preservação de dados existentes.
- `expense-metrics`: identificadores ampliados no agrupamento e inclusão explícita de investimentos e financiamentos nos totais e participações.
- `insights`: rótulos das novas categorias, integração analítica e linguagem fiel às saídas registradas, com compatibilidade editorial.

## Impact

- Core Domain: `ExpenseCategoryEnum`, compartilhado por Expense e Metrics, sem novas fronteiras ou dependências entre contextos.
- Expense Infrastructure: instruções de `ExpenseClassificationAgent`; seu schema já deriva os identificadores do enum.
- Expense Domain/Presentation e filtros: revisar e provar os consumidores do enum, sem duplicar listas de validação.
- Metrics: revisar validação e agregação existentes e atualizar evidências com expectativas fixas do catálogo.
- Insights Application: rótulos de `ComposeInsightMessageUseCase` e revisão dos templates que recebem categorias.
- Testes focados de catálogo, HTTP, classificação, persistência, agregação e editorial, a executar somente após autorização de implementação.
- Documentação/API e exemplos Bruno existentes, quando apresentarem o catálogo ou precisarem demonstrar os novos valores.
- Coordenação com `add-monthly-insights-filters`: a revisão editorial atual lista somente dez categorias e precisa de verificação com os oito novos rótulos antes da conclusão conjunta.
- Sem migrations previstas: `expenses.category` é `varchar(32)` e não possui constraint com catálogo fechado. Sem novas dependências, tabelas, endpoints, jobs, filas ou gestão de carteira, contratos de crédito e viagens.
