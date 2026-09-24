## Why

Hoje o registro de gastos depende da criação prévia de Budget, o que adiciona atrito ao uso inicial. Expense inaugura o fluxo direto de registrar um gasto de uma conta existente, sem remover Budget nesta mudança.

## What Changes

- Criar uma despesa vinculada ao User autenticado, com valor positivo em centavos de BRL, data do gasto e descrição opcional.
- Permitir categoria opcional de uma lista fechada, usando `other` quando ela não for informada.
- Persistir despesas independentemente de Budget, com exclusão lógica individual e exclusão definitiva quando a conta proprietária for removida.
- Expor a criação por API JSON:API autenticada, com validação e resposta do recurso criado.

## Capabilities

### New Capabilities

- `expense`: Regras de criação, propriedade, categorias e persistência de despesas.

### Modified Capabilities

- `user`: A exclusão definitiva da conta também remove suas despesas.

## Impact

- Novo contexto `Expense`, tabela `expenses`, endpoint de criação e vínculo com a tabela `users` do contexto Identity.
- A exclusão de User já existente passa a remover as despesas da conta na mesma operação; Budget e suas rotas não são alterados aqui.
- Relacionar `UserModel` e `ExpenseModel` nas duas direções somente em Infrastructure e bloquear lazy loading fora de produção para revelar consultas N+1.
