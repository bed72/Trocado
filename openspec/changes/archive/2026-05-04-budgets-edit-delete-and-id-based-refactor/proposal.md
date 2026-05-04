# Proposal — budgets-edit-delete-and-id-based-refactor

## Why

Budget hoje só tem create + read paginado. O usuário precisa **editar** valores/datas/descrição (correção de erros do dia-a-dia) e **excluir** orçamentos passados ou cadastrados por engano — exatamente o que Expense já tem. Sem essa peça, o usuário não consegue manter os orçamentos consistentes ao longo do tempo.

Em paralelo, há dois débitos técnicos no código atual que esta change resolve junto:

1. **Expense passa `ExpenseModel?` para a tela de form** (via `ExpenseLocation` → `ExpenseScreen`). O comentário `// TODO deveriamos passar so o ID` em `lib/src/presentation/ui/expense/screens/expense_screen.dart:24` reconhece o débito. Passar o model em memória acopla a tela ao estado da lista, impossibilita deep-link e usa cache stale (Trocado é app de casal — outra pessoa pode ter editado).

2. **Não existe diálogo de confirmação genérico** no projeto. Hoje, `ExpenseEditActionsWidget` dispara delete imediato. Para Budget o usuário pediu confirmação explícita; o padrão do projeto é criar widget compartilhado em `lib/src/presentation/widgets/<família>/`, e a feature consume.

**Pré-requisito:** a change `openspec/changes/expense-edit-and-delete/` está obsoleta — descreve um approach (bottom sheet + `ExpensesNotifier.delete`) que **não foi seguido** na implementação real. As tasks estão `[ ]`, mas o código já implementou outro caminho (footer dinâmico no form notifier). Esta change arquiva aquela como `2026-05-03-expense-edit-and-delete` (superseded), preservando o histórico.

A API do backend Django expõe `PATCH /api/v1/budgets/{id}`, `DELETE /api/v1/budgets/{id}` e (a confirmar) `GET /api/v1/budgets/{id}` — toda a stack que falta é Flutter.

## What

### Budget — adicionar update + delete + findById

- **Domain**: `IBudgetRepository` ganha `update`, `delete`, `findById`.
- **Infrastructure**: `IRemoteBudgetDataSource` ganha as três operações; reusa `BudgetRequest` existente para o PATCH (sem `UpdateBudgetRequest` separado, espelhando a decisão tomada em Expense).
- **Data**: `BudgetRepository` implementa as três; reusa extensions `BudgetResponseExtension.toModel()` e `FailureResponseExtension.toFailure()`.
- **Presentation (form)**: `BudgetFormNotifier` vira `AsyncNotifier` family por `int? id`; `BudgetFormState` ganha `int? id` e `bool isDeleting`; `BudgetFormIntent` ganha `DeletePressed`; `BudgetScreen` vira dinâmica (título, subtítulo e rodapé conforme modo). Novo `BudgetEditActionsWidget` espelha `ExpenseEditActionsWidget` (botões "Excluir" + "Atualizar" lado a lado em modo edit). Novo `budgetByIdProvider(int id)` (cache-first via `budgetsProvider.items` + `activeCard`, fallback para `repository.findById`).
- **Presentation (lista)**: `BudgetCardSuccessWidget` já tem `onTap?` (legado da spec `list-all-budgets`); `BudgetListItemWidget` ganha `onTap` similar — ambos navegam para `BudgetLocation(id: budget.id)`. O card ativo no topo da `BudgetsScreen` também navega para edição.
- **Main**: `BudgetLocation` aceita `int? id` (ausente = create, presente = edit).

### Expense — refactor id-based + dialog

- **Domain**: `IExpenseRepository` ganha `findById` (assinaturas atuais de `update`/`delete` permanecem inalteradas).
- **Infrastructure / Data**: `IRemoteExpenseDataSource.findById` + `ExpenseRepository.findById` (mapping via extension).
- **Presentation**: `ExpenseLocation` troca `ExpenseModel? expense` por `int? id`. `ExpenseNotifier` migra de `Notifier<ExpenseState>` family por `ExpenseModel?` para `AsyncNotifier<ExpenseState>` family por `int? id`. Novo `expenseByIdProvider(int id)` (cache-first via `expensesProvider.items`, fallback para `repository.findById`). `ExpenseScreen` passa a renderizar via switch sobre `AsyncValue<ExpenseState>` (loading inicial em modo edit, error com retry, data com form). `ExpenseEditActionsWidget` ganha `ConfirmDialogWidget` antes de disparar `DeletePressed`.
- Callers (listagem, navegação) passam `id` em vez de `model`.

### Compartilhado — ConfirmDialogWidget

- Novo `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`.
- API top-level: `Future<bool> showConfirmDialog({ required BuildContext context, required String title, required String description, String confirmLabel = 'Confirmar', String denyLabel = 'Cancelar', bool destructive = false })`.
- Estilo Material 3 via `context.colors`/`context.typography`; `destructive: true` aplica `colors.error` no botão de confirm.
- Chamado **na screen**, nunca no notifier — confirmação resolve antes de despachar `DeletePressed`.
- Usado por Budget (novo) e Expense (refactor).

### Arquivamento da change obsoleta

- Mover `openspec/changes/expense-edit-and-delete/` para `openspec/changes/archive/2026-05-03-expense-edit-and-delete/`.
- Adicionar `STATUS.md` na pasta arquivada explicando que foi superseded.

## Scope

### Em escopo

- Budget update/delete/findById em todas as camadas (domain/infrastructure/data/presentation/main).
- Expense refactor `ExpenseModel? expense` → `int? id` em Location/Notifier/Screen + `findById` em todas as camadas.
- `ConfirmDialogWidget` compartilhado em `presentation/widgets/dialog/`.
- `budgetByIdProvider` e `expenseByIdProvider` (cache-first).
- `BudgetEditActionsWidget` (espelho de `ExpenseEditActionsWidget`).
- `BudgetListItemWidget` ganha `onTap`; navegação para `BudgetLocation(id: ...)` a partir de listagem e card ativo.
- Testes em todas as camadas afetadas (incluindo widget tests do dialog e dos notifiers as `AsyncNotifier`).
- Arquivamento de `expense-edit-and-delete`.

### Fora de escopo

- **Bottom sheet de actions** (`expense_actions/`) descrito na change obsoleta — abandonado.
- **Snackbar "Desfazer" pós-delete** — eventual evolução futura.
- **Swipe-to-delete** — descartado em favor do botão explícito + confirmação.
- **Multi-seleção de budgets/expenses para delete em lote** — fora do escopo.
- **Audit trail / histórico de edições** — fora do escopo.
- **Notificação ao parceiro quando edita/exclui** — fora do escopo de CRUD local.
- **Mudanças no backend** — `PATCH`, `DELETE` já existem; `GET /budgets/{id}` é confirmado em task 1; se não existir, `byIdProvider` opera cache-only (deep-link sem listagem carregada falha com `NotFoundFailure` controlado).
- **Refactor de outras telas/listas** — apenas o necessário para callers passarem `id`.
- **Categoria nos forms** — Expense gera categoria no backend; form nunca edita.
- **Refatorar `BudgetRequest` em `Create`/`Update` separados** — reuso direto, espelhando Expense.
- **Mudanças visuais/de design system** — apenas widgets novos seguindo theme atual; sem redesign.
