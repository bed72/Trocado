# Design — budgets-edit-delete-and-id-based-refactor

## Contexto técnico

A stack de Budget está em pé até read paginado (`findActive`, `findAll`, `create`). Falta `update`, `delete`, `findById`. Os contratos do backend são paralelos aos de Expense: `PATCH /api/v1/budgets/{id}` retorna o `BudgetResponse` completo (mesmo schema do GET); `DELETE /api/v1/budgets/{id}` retorna 204 sem body; `GET /api/v1/budgets/{id}` (a confirmar em task 1) retorna o mesmo `BudgetResponse`.

`BudgetRequest` existente já serializa `{value, startDate, endDate, description}` — exatamente o que o backend aceita no PATCH. Reuso direto, sem `UpdateBudgetRequest` separado (mesma decisão tomada e validada no design da change obsoleta `expense-edit-and-delete`).

`ExpenseResponse` + `ExpenseResponseExtension.toModel()` e `BudgetResponse` + `BudgetResponseExtension.toModel()` já mapeiam tudo o que o PATCH retorna — `findById` reusa o mesmo mapping.

No lado de presentation:

- **`ExpenseNotifier`** hoje é `Notifier` síncrono (family por `ExpenseModel?`) — tem `_submit` que ramifica por `state.id == null` entre create/update, e `_delete()` chamado por `DeletePressed`. O footer (`ExpenseEditActionsWidget`) já existe e tem botões "Excluir"/"Atualizar" lado a lado.
- **`BudgetFormNotifier`** hoje é `Notifier` síncrono sem family — só faz create. Footer atual é `BudgetSaveButtonWidget` único ("Salvar").

Migrar para id-based **obriga** ambos a virar `AsyncNotifier` (precisam aguardar o `byIdProvider` resolver em modo edit). Escolha confirmada.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

- `domain/` ganha `findById` em ambas interfaces; `IBudgetRepository` ganha `update`/`delete`/`findById`. Zero Flutter, zero Dio.
- `infrastructure/` ganha métodos concretos no datasource remoto. Reusa `BudgetRequest` e `ExpenseRequest` existentes.
- `data/` implementa as três operações de Budget e o `findById` de Expense via extensions já existentes.
- `presentation/` ganha `ConfirmDialogWidget` compartilhado, `budgetByIdProvider` + `expenseByIdProvider`, migra notifiers para `AsyncNotifier` family por `int? id`, atualiza screens para switch sobre `AsyncValue`, adiciona `BudgetEditActionsWidget`, torna `BudgetListItemWidget` clicável.
- `main/` (via `lib/src/presentation/ui/budget/locations/budget_location.dart` e `expense_location.dart`) muda assinatura para `int? id`.

`ConfirmDialogWidget` mora em `lib/src/presentation/widgets/dialog/` — pasta nova, alinhada com as demais famílias compartilhadas (`widgets/budget/card/`, `widgets/expense/`, `widgets/buttons/`, etc.).

## Decisões de design

### 1. AsyncNotifier family por `int? id` (Budget e Expense)

**Decisão**: `BudgetFormNotifier` e `ExpenseNotifier` migram para `AsyncNotifier<XxxState>` com `build(int? id)` async. `null` = modo create (estado inicial); não-null = `await ref.watch(byIdProvider(id).future)` → estado pré-preenchido.

**Rationale**: passar apenas o `id` desacopla a tela de form da origem de navegação (lista, deep-link, atalho de outra feature) e garante dados frescos no momento da edição (Trocado é colaborativo — outra pessoa pode ter editado). O comentário `// TODO deveriamos passar so o ID` no `expense_screen.dart:24` é o reconhecimento explícito do débito.

**Consequência**: a screen renderiza via switch sobre `AsyncValue<XxxState>`:

- `AsyncLoading()` → loading da tela inteira (apenas no carregamento inicial em modo edit).
- `AsyncError(:final error)` → mensagem + retry (`ref.invalidate(byIdProvider(id))`).
- `AsyncData(:final value)` → form normal; `value.id == null` discrimina create vs edit (sem enum `mode`).

**Trade-off**: modo create roda `build(null)` e termina sincronamente — o `AsyncNotifier` resolve imediatamente para `AsyncData`, não há flicker visível. Há overhead mínimo (extra microtask) que é aceitável.

### 2. `byIdProvider` é cache-first com fallback para `findById`

**Decisão**: `budgetByIdProvider(int id)` (e `expenseByIdProvider(int id)`) é uma family que:

1. Lê o `budgetsProvider` / `expensesProvider` (cache da listagem) e procura por `id`.
2. Se encontrar → retorna o `BudgetModel` / `ExpenseModel` do cache.
3. Se não encontrar → chama `repository.findById(id)`.
4. Em falha do repository → propaga via `AsyncError` (a `byIdProvider` é `Future<Model>`, não `Either`).

**Rationale**: o caso comum (90%+) é o usuário tocar num item da listagem ou no card ativo — em ambos o cache já tem o model. O fallback existe para deep-link e para invalidações. Evita network round-trip desnecessário quando o dado já está em memória.

**Cuidado**: a leitura do cache usa `ref.read` (não `ref.watch`) — mudanças no `budgetsProvider` não devem reexecutar o `byIdProvider` automaticamente. Se a lista invalidar (post-delete, post-update), a screen de edit já fechou (via `context.root()`); o byIdProvider não precisa reagir.

**Trade-off**: se `budgetsProvider` ainda não foi resolvido (`AsyncLoading`), o `byIdProvider` pula direto para `findById` — comportamento correto.

### 3. `BudgetFormState` ganha `int? id` como discriminador (sem enum `mode`)

**Decisão**: espelhar `ExpenseState`. `id == null` = create, preenchido = edit. `_submit()` ramifica por `state.id == null` entre `repository.create(...)` e `repository.update(id: state.id!, ...)`.

**Rationale**: introduzir um `BudgetFormMode { create, edit }` redundante com `id` cria duas fontes de verdade. A presença do `id` é a única coisa que distingue os modos em comportamento — tornar isso explícito no state é mais barato.

### 4. `BudgetFormIntent` ganha `DeletePressed`; `SubmitPressed` cobre create+update

**Decisão**: espelhar `ExpenseIntent`. Sealed permanece com `ValueChanged`, `DateRangeChanged`, `DescriptionChanged`, `SubmitPressed` + novo `DeletePressed`. `dispatch` exhaustivo via switch expression.

**Rationale**: `SubmitPressed` cobre os dois modos (create e update); a ramificação acontece dentro de `_submit()` via `state.id`. `DeletePressed` é exclusivo do modo edit (`_delete()` retorna cedo se `state.id == null`).

### 5. `ConfirmDialogWidget` é genérico, sempre chamado na screen

**Decisão**: API top-level `Future<bool> showConfirmDialog(...)` em `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`. Recebe `BuildContext`, `title`, `description`, `confirmLabel`, `denyLabel`, `destructive`. Retorna `true` em confirm; `false` em deny ou dismiss (barrier/Android back).

A screen aguarda o `Future<bool>` no `onDelete` callback do `XxxEditActionsWidget` e só despacha `DeletePressed` em `true`.

**Rationale**: o notifier é Dart puro (sem `BuildContext`); diálogos pertencem à camada UI. Centralizar a confirmação em um widget compartilhado evita drift visual entre features (Budget e Expense vão usá-lo idêntico) e dá um ponto único pra evoluir (estilo destrutivo, animação, a11y).

**Onde fica a string?** No call site da screen — `ExpenseScreen` passa "Excluir despesa" / "Esta ação não pode ser desfeita."; `BudgetScreen` passa "Excluir orçamento" / mesma descrição. O widget é agnóstico de domínio.

### 6. `BudgetEditActionsWidget` é espelho de `ExpenseEditActionsWidget` por feature (não widget genérico)

**Decisão**: criar `lib/src/presentation/ui/budget/widgets/budget_edit_actions_widget.dart` com a mesma assinatura de `ExpenseEditActionsWidget`: `isLoading`, `isDeleting`, `onUpdate`, `onDelete`. Internamente renderiza `Row(spacing: 16, children: [Expanded(ButtonWidget.outlined(label: 'Excluir', ...)), Expanded(ButtonWidget.elevated(label: 'Atualizar', ...))])`.

**Rationale**: encapsulamento por feature (regra do CLAUDE.md). Extrair um `EditActionsWidget` genérico em `widgets/buttons/` parece tentador, mas:

- As labels ("Excluir despesa" / "Excluir orçamento") variam por contexto.
- A composição ainda é simples (~30 linhas) e pode divergir no futuro (ex.: Budget ganhar 3º botão).
- DRY prematuro vira acoplamento. O conteúdo é idêntico hoje, mas a feature dona controla o widget.

**Trade-off**: se um terceiro form aparecer com a mesma necessidade, aí sim extraímos.

### 7. Reusar `BudgetRequest` para PATCH (sem `UpdateBudgetRequest`)

**Decisão**: o PATCH do backend aceita o objeto inteiro `{value, startDate, endDate, description}` — exatamente o `BudgetRequest` já usado no POST. Não criar `UpdateBudgetRequest` idêntico.

**Rationale**: criar duas classes com o mesmo formato serializado adiciona superfície sem ganho. Mesma decisão validada em Expense (`ExpenseRequest` reusado para create/update). Se no futuro o PATCH divergir (partial patch, novos campos exclusivos), partimos em duas.

### 8. `delete` retorna `Future<Either<Failure, void>>` (espelhar Expense)

**Decisão**: `IBudgetRepository.delete({ required int id }) → Future<Either<Failure, void>>`. Datasource retorna `Future<Either<FailureResponse, void>>` (mesmo padrão do Expense — `response.either(FailureResponse.fromJson, (_) {})` ignora o body do 204).

**Rationale**: `void` é mais honesto que `bool` ou `Unit` para "operação bem-sucedida sem payload". `Either` carrega o erro tipado; sucesso é só `Right`. Espelhar exatamente a assinatura de `IExpenseRepository.delete`.

### 9. Refresco cross-feature pós-mutação via `ref.invalidate`

**Decisão**: em sucesso de `_submit()` (create ou update) e `_delete()`, o notifier chama:

- `ref.invalidate(budgetsProvider)` — re-executa a listagem.
- `ref.invalidate(activeBudgetProvider)` — re-executa o card ativo da Home.

(Mesmo padrão do `ExpenseNotifier`, que invalida `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider`.)

**Rationale**: idioma canônico Riverpod cross-feature após mutação (CLAUDE.md). Sem isso, a lista mostraria dados stale após edit/delete.

### 10. `BudgetCardSuccessWidget.onTap` já existe; reusar

**Decisão**: `BudgetCardSuccessWidget` já tem `final VoidCallback? onTap;` (legado da spec `list-all-budgets`, com wrap em `BounceWidget.withOnPress`). A `BudgetsScreen` passa `onTap: () => context.navigate(BudgetLocation(id: item.budget.id))` ao card ativo.

**Decisão complementar**: `BudgetListItemWidget` ganha o mesmo `final VoidCallback? onTap;` no construtor — wrap idêntico em `BounceWidget.withOnPress`. A spec atual de `BudgetListItemWidget` diz "SHALL NOT be tappable"; esta change reverte essa restrição porque agora há destino para o tap.

### 11. Cancelamento da change `expense-edit-and-delete` obsoleta

**Decisão**: mover `openspec/changes/expense-edit-and-delete/` → `openspec/changes/archive/2026-05-03-expense-edit-and-delete/` e adicionar `STATUS.md` explicando: "Approach descrito (bottom sheet `expense_actions/` + `ExpensesNotifier.delete`) não foi seguido — implementação real adotou footer dinâmico no `ExpenseNotifier` (form), e o id-based refactor foi feito na change `budgets-edit-delete-and-id-based-refactor`."

**Rationale**: preservar histórico de decisão. A change ficou divergente da realidade — arquivar como superseded é o caminho honesto.

## Fluxos

### Listagem → editar

```
[BudgetsScreen] user toca em card ou item
  → onTap fired
  → context.navigate(BudgetLocation(id: budget.id))

[BudgetLocation → BudgetScreen] build com id != null
  → ref.watch(budgetFormProvider(id))
    → AsyncNotifier.build(id) async
      → await ref.watch(budgetByIdProvider(id).future)
        → cache-hit em budgetsProvider.value.items / activeCard → BudgetModel
        → cache-miss → repository.findById(id) → Right(BudgetModel) | Left(Failure → AsyncError)
      → BudgetFormState(id, value, startDate, endDate, description)
  → screen switch sobre AsyncValue:
      AsyncLoading  → BudgetLoadingWidget
      AsyncError    → BudgetFailureWidget(retry → invalidate(budgetByIdProvider(id)))
      AsyncData     → form preenchido, título "Editar orçamento", footer BudgetEditActionsWidget

[BudgetScreen] user altera campos e tap "Atualizar"
  → dispatch(SubmitPressed)
  → _submit() ramifica por state.id != null
  → repository.update(id, value, startDate, endDate, description)
  → on Right(BudgetModel):
      ref.invalidate(budgetsProvider)
      ref.invalidate(activeBudgetProvider)
      state.status = success
  → screen listener faz context.root()
```

### Edição → excluir

```
[BudgetScreen] user tap "Excluir"
  → onDelete callback (na screen)
  → final confirmed = await showConfirmDialog(
      context: context,
      title: 'Excluir orçamento',
      description: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    )
  → if (!confirmed) return;
  → notifier.dispatch(DeletePressed())

[BudgetFormNotifier._delete]
  → state = state.copyWith(isDeleting: true)
  → final data = await repository.delete(id: state.id!)
  → on Right:
      ref.invalidate(budgetsProvider)
      ref.invalidate(activeBudgetProvider)
      state = state.copyWith(isDeleting: false, status: .success)
  → on Left(failure):
      state = state.copyWith(isDeleting: false, status: .failure, message: failure.message)

[BudgetScreen] listener:
  status == .success → context.root()
  status == .failure → showToastWidget(...)
```

## Trade-offs assumidos

- **Cache-first com `ref.read` no byIdProvider**: se a listagem ainda não foi resolvida quando o usuário entra via deep-link, vamos direto para `findById`. Aceitável — é o caminho HTTP de qualquer forma.
- **Confirmação só no delete (não no update)**: a operação destrutiva é a exclusão; updates podem ser revertidos editando de novo. Sem dialog em update mantém o fluxo enxuto.
- **`ExpenseEditActionsWidget` ganha confirmação dentro do `onDelete` da screen** (não do widget): o widget continua agnóstico de dialog — só dispara `onDelete`. A screen é quem decide mostrar dialog antes de despachar `DeletePressed`. Isso simétrico para Budget.
- **Migrar Expense de `Notifier` para `AsyncNotifier`** rompe a assinatura do provider — todos os call sites (screen, listeners, tests) precisam ajustar para `AsyncValue<ExpenseState>`. Trabalho maior, mas é o caminho correto e o usuário confirmou.
- **`AsyncNotifier.build(null)` resolve sincronamente** — não há flicker no fluxo de criação. Se aparecer, é bug e exige investigação.

## O que este design **não** pretende resolver

- Optimistic update na listagem após delete/update (remover/atualizar item localmente antes da resposta).
- Snackbar "Desfazer" pós-delete.
- Multi-seleção / batch operations.
- Audit trail / histórico de edições.
- Notificação ao parceiro quando edita/exclui.
- Deep-link com ID inválido (404 do `findById` cai em `AsyncError` — comportamento aceitável; sem tratamento especial).
