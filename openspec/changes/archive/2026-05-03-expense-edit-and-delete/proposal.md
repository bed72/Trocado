# Proposal — expense-edit-and-delete

## Why

A listagem de despesas (`ExpensesScreen`) hoje só permite leitura. Criamos, listamos com filtro, paginamos e agrupamos — mas não editamos nem excluímos. Para que o app seja efetivamente útil no dia-a-dia, o usuário precisa corrigir despesas lançadas (valor errado, data trocada, descrição incompleta) e apagar lançamentos duplicados ou enganos. Essa é a última peça do CRUD básico de despesa antes que o foco migre para orçamento, insights e compartilhamento com parceiro.

A API do backend Django já expõe `PATCH /api/v1/expenses/{id}` e `DELETE /api/v1/expenses/{id}` — toda a stack necessária é Flutter.

## What

Adicionar edição e exclusão de despesas via long-press em um item da lista, abrindo um bottom sheet com duas ações — **Editar** e **Excluir** — em um ponto de entrada único:

- **Editar** reutiliza a `ExpenseScreen` (tela de cadastro) em modo edição, transformando-a em espelho dinâmico do cadastro (título, subtítulo e label do botão trocam conforme o modo). O formulário pré-preenche com os valores da despesa selecionada. Ao salvar, dispara `PATCH /api/v1/expenses/{id}`. O fluxo de cadastro (create) existente **não muda em comportamento** — apenas é parametrizado.
- **Excluir** dispara `DELETE /api/v1/expenses/{id}` imediatamente, **sem diálogo de confirmação** (decisão de UX: velocidade sobre reversibilidade confirmada em conversa prévia). O bottom sheet fecha e a lista se atualiza. Falhas exibem toast de erro.

Uma nova feature autocontida `expense_actions/` hospeda o bottom sheet (screen + location), espelhando o padrão visual do `ExitScreen` (`BottomSheetScaffoldWidget` + dois `ButtonWidget`s).

## Scope

### Em escopo

- **Infrastructure**: `IRemoteExpenseDataSource` ganha `update` e `delete`; `RemoteExpenseDataSource` implementa ambos reusando o `ExpenseRequest` já existente
- **Domain**: `IExpenseRepository` ganha `update` e `delete`
- **Data**: `ExpenseRepository` implementa os dois métodos usando as extensions existentes (`FailureResponseExtension.toFailure`, `ExpenseResponseExtension.toModel`)
- **Presentation — expense (edit)**: `ExpenseLocation` passa a aceitar `ExpenseModel?`; `ExpenseNotifier` vira family com parâmetro `ExpenseModel?`; `ExpenseState` ganha `int? id`; `ExpenseScreen` e `ExpenseSaveButtonWidget` parametrizam textos
- **Presentation — expense_actions (nova feature)**: `ExpenseActionsScreen` + `ExpenseActionsLocation` usando `BottomSheetPage`
- **Presentation — expenses (delete + long-press)**: método `delete(int id)` em `ExpensesNotifier`; `ExpenseItemWidget` ganha `onLongPress`; `ExpensesListWidget` e `ExpensesScreen` propagam o callback; `ExpensesLocation` usa `Consumer` no `pageBuilder` para compor os callbacks `onEdit` e `onDelete`
- **Main**: `app_route.dart` ganha rota `expenseActions`
- **Testes**: repository (update/delete mockando `IHttpClient`), notifier `ExpenseNotifier` family (modos create e edit), notifier `ExpensesNotifier` (método `delete`), widget tests do `ExpenseItemWidget` e `ExpenseActionsScreen`

### Fora de escopo

- **Dialogo de confirmação de exclusão** — decisão UX explícita: delete é imediato
- **Botão "Excluir" dentro da `ExpenseScreen`** de edição — delete só existe via bottom sheet; a tela de edição mantém só o botão de salvar
- **Campo de categoria no formulário** — categoria é gerada pelo backend a partir da description; o form nunca edita esse campo (nem em create, nem em edit)
- **`findById` no repositório / datasource** — a `ExpenseModel` é passada em memória via `ExpenseLocation(expense: ...)` a partir do item long-pressado; sem round-trip adicional
- **Swipe-to-delete na lista** — avaliado e descartado em favor do long-press + bottom sheet (menos risco de exclusão acidental, padrão mais consistente com `ExitScreen`)
- **Snackbar "Desfazer"** pós-delete — fora do escopo desta iteração; se exclusões acidentais virarem problema, será adicionado em spec separada
- **Mudanças no backend** — `PATCH` e `DELETE` já existem
- **Alteração de `findAll`, `findRecent`, `create` ou de `ExpenseModel` / `ExpensesPageModel`** — o modelo de domínio e os endpoints de leitura permanecem intactos
- **Refatorar `ExpenseRequest` em `UpdateExpenseRequest` / `CreateExpenseRequest` separados** — o request atual já tem a shape exata necessária para o PATCH; criar duas classes idênticas é over-engineering
