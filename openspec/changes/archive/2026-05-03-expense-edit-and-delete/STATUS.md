# STATUS: SUPERSEDED

**Data de arquivamento:** 2026-05-03
**Substituída por:** `openspec/changes/budgets-edit-delete-and-id-based-refactor/`

## Por que foi arquivada sem implementação

Esta change foi proposta com o approach de **bottom sheet** (`expense_actions/` feature autocontida) acionado por **long-press** no item da lista, com:

- `ExpenseActionsScreen` + `ExpenseActionsLocation` (sheet com botões "Editar" / "Excluir").
- `ExpensesNotifier.delete(int id)` como método direto (não intent), retornando `Future<Either<Failure, void>>`.
- Composição de callbacks em `ExpensesLocation.pageBuilder` via `Consumer`.
- Delete imediato sem confirmação.

A **implementação real** seguiu um caminho diferente:

- Sem bottom sheet — botões "Excluir" / "Atualizar" diretamente no rodapé da `ExpenseScreen` em modo edit (via `ExpenseEditActionsWidget`).
- `DeletePressed` como intent dentro do `ExpenseIntent` (sealed) e `_delete()` como método privado no `ExpenseNotifier` (form), não em `ExpensesNotifier` (lista).
- Navegação para edit por **tap** no item, não long-press.
- Continuou sem confirmação por dialog.

A divergência se acumulou ao longo de implementações iterativas e a change ficou desalinhada com o código real.

## O que foi continuado em outra change

A nova change `budgets-edit-delete-and-id-based-refactor` (2026-05-03):

1. Adiciona update + delete + findById em **Budget** (espelhando o approach que já vingou em Expense).
2. Refatora **Expense** para o approach **id-based** que foi explicitamente reconhecido como débito técnico no comentário `// TODO deveriamos passar so o ID` em `lib/src/presentation/ui/expense/screens/expense_screen.dart:24`. `ExpenseLocation` passa a aceitar `int? id` em vez de `ExpenseModel?`; `ExpenseNotifier` vira `AsyncNotifier` family por `int?`; novo `expenseByIdProvider` cache-first.
3. Cria **`ConfirmDialogWidget`** compartilhado em `lib/src/presentation/widgets/dialog/` e **adiciona confirmação por dialog antes do delete em ambas as features** — superando a decisão UX original de "delete imediato".

## Não retomar

Esta change está congelada como histórico de decisão. Não implementar; não retomar tasks; não considerar como referência para novas mudanças. A referência viva está em `budgets-edit-delete-and-id-based-refactor`.
