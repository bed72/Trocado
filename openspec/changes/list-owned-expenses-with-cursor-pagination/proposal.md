## Why

A API permite criar despesas, mas ainda não oferece uma listagem para o titular acompanhar seus gastos. Uma consulta sem limite ou sem escopo por proprietário exporia dados de outras contas e não escalaria com o crescimento do histórico.

## What Changes

- Disponibilizar `GET /api/expenses` somente para a conta autenticada, retornando apenas suas despesas ativas.
- Paginar com cursor opaco e ordenação estável por data de ocorrência decrescente e identificador decrescente, incluindo links para navegação.
- Limitar o tamanho da página e validar parâmetros de paginação; manter a resposta no formato JSON:API.
- Acrescentar índice adequado à consulta paginada, sem alterar os identificadores existentes nem a criação de despesas.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `expense`: acrescentar consulta autenticada, isolada por proprietário e paginada por cursor às operações de despesa.

## Impact

Contrato `ExpenseRepository`, caso de uso de listagem, consulta Eloquent, rota e apresentação HTTP em Expense; índice da tabela `expenses` e especificação `expense`. Nenhuma dependência nova ou mudança em Identity é necessária.
