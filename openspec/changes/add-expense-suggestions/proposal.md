## Why

Cadastrar despesas exige redigitar descrições e valores já utilizados pela própria conta. Um autocomplete baseado no histórico reduz esse esforço e permite sugerir um valor quando os três meses anteriores apresentam um padrão consistente, sem inferência externa ou criação automática de lançamentos.

## What Changes

- Adicionar `GET /api/expenses/suggestions?query=Int`, protegido pelos mesmos middlewares das demais rotas de Expense, com até cinco sugestões JSON:API.
- Buscar descrições parcialmente, sem diferenciar caixa e ignorando espaços nas extremidades para comparação; deduplicar e conservar a grafia do lançamento mais recentemente cadastrado.
- Priorizar prefixos, depois última utilização, frequência histórica e desempate estável.
- Sugerir `amount` em centavos somente quando cada um dos três meses civis anteriores possui registros e todos os seus valores são iguais. Múltiplos registros iguais no mesmo mês são permitidos; qualquer divergência ou mês ausente impede a sugestão.
- Consultar exclusivamente despesas do proprietário autenticado, sem escrita, cache adicional ou carregamento integral do histórico na aplicação.
- Acrescentar testes de regra, orquestração, consulta PostgreSQL e transporte HTTP seguindo a organização e o launcher do projeto.
- Preservar criação, edição, exclusão e categorização assíncrona existentes. Não incluir Flutter, reutilização de categorias, recorrência, agendamento, novas tabelas, dependências, Redis, filas, jobs ou chamadas de IA nesta funcionalidade.

## Capabilities

### New Capabilities

- `expense-suggestions`: autocomplete autenticado e isolado por proprietário, com descrições únicas e ordenadas e valor opcional baseado na consistência dos três meses anteriores.

### Modified Capabilities

Nenhuma. O contrato de CRUD de `ExpenseRepository` e o fluxo de categorização permanecem preservados; a nova consulta tem contrato de Repository próprio.

## Impact

- Backend do bounded context Expense: novo fluxo Request → Controller → UseCase → Repository → Response e binding no provider existente.
- Leitura dos campos existentes `expenses.user_id`, `description`, `amount`, `occurred_on`, `created_at` e `id`, no PostgreSQL.
- Nova rota nomeada `expenses.suggestions`, sem alteração incompatível nos endpoints atuais.
- Testes em `tests/Unit/Expense/` e `tests/Feature/Expense/`, além da verificação de fronteiras existente.
- Sem migration planejada, alteração de configuração operacional ou dependência nova. A eficiência será verificada com consulta limitada, contagem de statements e plano de execução.
