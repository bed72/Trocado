# expenses Specification (delta — id-based refactor)

## Purpose (refactor)

Expense já entrega CRUD completo (create, list, update, delete). Esta change refatora a navegação para o form de edit: troca `ExpenseModel?` (model em memória vindo da listagem) por `int? id` (resolvido em runtime via `expenseByIdProvider`). Resolve o débito técnico explícito em `expense_screen.dart:24` (`// TODO deveriamos passar so o ID`), desacopla a tela de edit do estado da listagem, viabiliza deep-link e garante dados frescos no momento da edição. Adiciona também confirmação por `ConfirmDialogWidget` antes do delete.

## Requirements

### Requirement: IExpenseRepository extended with findById

The system SHALL extend `lib/src/domain/repositories/interface_expense_repository.dart` with:

```dart
Future<Either<Failure, ExpenseModel>> findById({required int id});
```

The existing `create`, `update`, `delete`, `findAll`, `findRecent` SHALL remain unchanged.

#### Scenario: findById is added to the interface

Given the new interface
Then it SHALL declare `findById` with the signature above
And `update` and `delete` SHALL retain their existing signatures

---

### Requirement: IRemoteExpenseDataSource extended with findById

The system SHALL extend the interface and implementation in `lib/src/infrastructure/datasources/remote/remote_expense_data_source.dart` with:

```dart
Future<Either<FailureResponse, ExpenseResponse>> findById({required int id});
```

The implementation SHALL call `_client.get(parameter: Requests('${EndpointKey.expenses.path}/$id'))` and deserialize via `response.either(FailureResponse.fromJson, ExpenseResponse.fromJson)`. The variable name SHALL be `response` (never `either`).

#### Scenario: findById URL pattern

Given `findById(id: 132)` is invoked
Then `_client.get` SHALL be called with `Requests('${EndpointKey.expenses.path}/132')`

---

### Requirement: ExpenseRepository extended with findById

The system SHALL extend `lib/src/data/repositories/expense_repository.dart` with `findById`:

```dart
@override
Future<Either<Failure, ExpenseModel>> findById({required int id}) async {
  final data = await _dataSource.findById(id: id);
  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toModel(),
  );
}
```

Reuses `ExpenseResponseExtension.toModel()` and `FailureResponseExtension.toFailure()`.

#### Scenario: findById success

Given the datasource returns `Right(ExpenseResponse)` for id 132
When `findById(id: 132)` is invoked
Then the repository SHALL return `Right(ExpenseModel(id: 132, ...))` mapped via `toModel()`

#### Scenario: findById not found

Given the datasource returns `Left(FailureResponse)` with `code: "not_found"`
When `findById(id: 999)` is invoked
Then the repository SHALL return `Left(NotFoundFailure)`

---

### Requirement: expenseByIdProvider — cache-first family by int id

The system SHALL add `lib/src/presentation/ui/expense/notifiers/expense_by_id_notifier.dart` exposing a Riverpod family `expenseByIdProvider(int id)` returning `Future<ExpenseModel>`.

Resolution logic:

1. Read `expensesProvider` via `ref.read` (NOT `ref.watch`).
2. If `expensesProvider` is in `AsyncData`, search for a matching `id` across `value.items.map((i) => i.expense)` (and any other cached collection of expenses, e.g. `recentExpensesProvider` if applicable). If found → return the cached `ExpenseModel`.
3. Otherwise, `ref.watch(expenseRepositoryProvider).findById(id: id)` and on `Right(model)` return; on `Left(failure)` rethrow.

#### Scenario: Cache hit

Given `expensesProvider` value is `AsyncData(ExpensesState(items: [items containing expense id 132]))`
When `expenseByIdProvider(132)` is read
Then the future SHALL resolve to that cached model
And `repository.findById` SHALL NOT be called (`verifyNever`)

#### Scenario: Cache miss falls back to repository

Given `expensesProvider` does not contain id 999
When `expenseByIdProvider(999)` is read
Then `repository.findById(id: 999)` SHALL be called

#### Scenario: Repository failure propagates as AsyncError

Given `repository.findById` returns `Left(NetworkFailure)`
When `expenseByIdProvider(132)` is read
Then the future SHALL throw `NetworkFailure`
And the provider SHALL transition to `AsyncError(NetworkFailure)`

---

### Requirement: ExpenseLocation accepts int? id (replaces ExpenseModel?)

The system SHALL update `lib/src/presentation/ui/expense/locations/expense_location.dart`:

- Replace `final ExpenseModel? expense;` with `final int? id;`.
- Constructor: `const ExpenseLocation({this.id})`.
- `pageBuilder` SHALL pass `id: id` to `ExpenseScreen` (no longer passing the model).
- The `navigateToDate` and `navigateToCalculator` callbacks SHALL be composed inside the `pageBuilder` and SHALL NOT depend on the `model` (only on `id` if needed for sub-routes; current `ExpenseDateLocation` may need to be adjusted to also receive `int? id` instead of `ExpenseModel?`).

#### Scenario: ExpenseLocation no longer carries ExpenseModel

Given the new file
When `grep "ExpenseModel" lib/src/presentation/ui/expense/locations/expense_location.dart` is executed
Then the result SHALL be empty (no field, no parameter, no import of `ExpenseModel` is needed)

#### Scenario: Construction in create mode

Given `ExpenseLocation()` (no args)
When the page builds
Then `ExpenseScreen(id: null, ...)` SHALL be created

#### Scenario: Construction in edit mode

Given `ExpenseLocation(id: 132)`
When the page builds
Then `ExpenseScreen(id: 132, ...)` SHALL be created

---

### Requirement: ExpenseNotifier becomes AsyncNotifier family by int? id

The system SHALL refactor `lib/src/presentation/ui/expense/notifiers/expense_notifier.dart` from `Notifier<ExpenseState>` family `<ExpenseModel?>` to `AsyncNotifier<ExpenseState>` family `<int?>`.

- `Future<ExpenseState> build(int? id)`:
  - `_repository = ref.watch(expenseRepositoryProvider)`.
  - `_validator = ref.watch(expenseFormValidatorProvider)`.
  - If `id == null` → return `ExpenseState(date: DateTime.now().millisecondsSinceEpoch)` (preserve current default behaviour).
  - If `id != null` → `final expense = await ref.watch(expenseByIdProvider(id).future); return ExpenseState(id: expense.id, date: expense.date, value: expense.value, description: expense.description);`.
- `dispatch(ExpenseIntent intent)` continues to be exhaustive over all existing intents (`ValueChanged`, `DescriptionChanged`, `DateChanged`, `SubmitPressed`, `DeletePressed`). Mutations from intents SHALL go through `state = AsyncData(state.value!.copyWith(...))`.
- `_submit()` continues to branch by `state.value!.id == null` between `repository.create(...)` and `repository.update(id: state.value!.id!, ...)`. Invalidations on success: `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider` (preserved from current implementation).
- `_delete()` continues to early-return if `state.value!.id == null`; in edit mode, calls `repository.delete(id: state.value!.id!)`. Same invalidations on success. `isDeleting` lifecycle preserved.

The notifier SHALL NOT call `showDialog` or any function requiring `BuildContext` — confirmation is handled in the screen.

`late` (never `late final`) for fields hydrated in `build()`.

#### Scenario: build(null) returns initial AsyncData with default date

Given `expenseProvider(null)` is read
When the provider builds
Then the future SHALL resolve to `ExpenseState(id: null, date: <now ms>, value: 0, description: "")`

#### Scenario: build(id) awaits byIdProvider

Given `expenseByIdProvider(132)` resolves to `ExpenseModel(id: 132, date: <ms>, value: 9230, description: "lunch")`
When `expenseProvider(132)` builds
Then the future SHALL resolve to `ExpenseState(id: 132, date: <ms>, value: 9230, description: "lunch")`

#### Scenario: build(id) propagates AsyncError

Given `expenseByIdProvider(132)` throws
When `expenseProvider(132)` builds
Then the provider SHALL transition to `AsyncError`

#### Scenario: SubmitPressed in edit mode calls update with state.id

Given `state.value.id == 132`
When `dispatch(const SubmitPressed())` is invoked with valid form
Then `repository.update(id: 132, ...)` SHALL be called

#### Scenario: DeletePressed in create mode is a no-op (regression)

Given `state.value.id == null`
When `dispatch(const DeletePressed())` is invoked
Then `repository.delete` SHALL NOT be called

---

### Requirement: ExpenseScreen renders via switch on AsyncValue

The system SHALL refactor `lib/src/presentation/ui/expense/screens/expense_screen.dart`:

- Replace `final ExpenseModel? expense;` with `final int? id;`.
- Remove the `// TODO deveriamos passar so o ID` comment (the TODO is resolved by this change).
- Watch `expenseProvider(id)` returning `AsyncValue<ExpenseState>` and switch:
  - `AsyncLoading()` → loading widget (full-screen).
  - `AsyncError(:final error)` → failure widget with retry calling `ref.invalidate(expenseByIdProvider(id!))`.
  - `AsyncData(:final value)` → existing form layout, with `value.id == null` discriminating create vs edit (title, subtitle, footer).
- The `ExpenseEditActionsWidget` (footer in edit mode) SHALL be wired with an `onDelete` that calls `showConfirmDialog(context: context, title: 'Excluir despesa', description: 'Esta ação não pode ser desfeita.', confirmLabel: 'Excluir', destructive: true)` and only dispatches `DeletePressed` if `confirmed == true`. This is **new behaviour** — current implementation deletes immediately.

The screen SHALL continue to be `StatelessWidget` with internal `Consumer` (NEVER `ConsumerWidget`). The `ref.listen` for status transitions (`success → context.pop()`, `failure → showToastWidget`) SHALL be preserved with the new `AsyncValue` shape (listen to `expenseProvider(id)` and read `next.value?.status` inside the switch).

#### Scenario: ExpenseScreen no longer accepts ExpenseModel

Given the new file
When `grep "ExpenseModel" lib/src/presentation/ui/expense/screens/expense_screen.dart` is executed
Then the result SHALL contain no field of type `ExpenseModel?`

#### Scenario: AsyncLoading renders loading

Given `expenseProvider(132)` is `AsyncLoading`
When the screen builds
Then a centered loading indicator SHALL render
And no form fields SHALL render

#### Scenario: AsyncError renders retry

Given `expenseProvider(132)` is `AsyncError`
When the screen builds and the user taps retry
Then `ref.invalidate(expenseByIdProvider(132))` SHALL be called

#### Scenario: AsyncData(create) renders save button

Given `expenseProvider(null)` is `AsyncData(ExpenseState(id: null, ...))`
When the screen builds
Then the title SHALL read `'Nova despesa'`
And the footer SHALL render `ExpenseSaveButtonWidget` (single button)

#### Scenario: AsyncData(edit) renders edit actions

Given `expenseProvider(132)` is `AsyncData(ExpenseState(id: 132, ...))`
When the screen builds
Then the title SHALL read `'Editar despesa'`
And the footer SHALL render `ExpenseEditActionsWidget` (two buttons)

#### Scenario: Delete in edit mode shows confirmation dialog (new behaviour)

Given the screen is in edit mode and the user taps the delete button
When the `onDelete` handler runs
Then `showConfirmDialog` SHALL be invoked with `title: 'Excluir despesa', destructive: true`
And `notifier.dispatch(const DeletePressed())` SHALL only fire if `confirmed == true`

#### Scenario: Cancelled delete does nothing

Given `showConfirmDialog` resolves to `false`
When the handler continues
Then no dispatch SHALL happen and no network request SHALL be made

---

### Requirement: Callers updated to pass id (not model)

The system SHALL update every call site that constructs `ExpenseLocation(...)` to pass `id:` instead of `expense:`. Locations to audit (non-exhaustive — verify with grep):

- `lib/src/presentation/ui/expenses/locations/expenses_location.dart` — composer of the list; the long-press / tap callback that opens `ExpenseLocation` SHALL pass `id: expense.id`.
- Any preview file constructing `ExpenseLocation` SHALL be updated.
- `ExpenseDateLocation` (if it currently receives `ExpenseModel?`) SHALL be adjusted to receive what it actually needs from the date sub-flow (likely just current `date` value or `int? id` for context).

#### Scenario: No call site passes ExpenseModel to ExpenseLocation

Given the codebase after the refactor
When `grep -rn "ExpenseLocation(expense:" lib/ test/` is executed
Then the result SHALL be empty

#### Scenario: Call sites pass id

Given the codebase after the refactor
When `grep -rn "ExpenseLocation(id:" lib/` is executed
Then the result SHALL contain at least one match (the listing's tap/long-press composer)

---

### Requirement: Tests — regression and new coverage

The change SHALL include test updates and additions. All descriptions in **English**. Mocks declared by interface type. No `result`/`either` variable names. No `var`.

**`ExpenseRepository.findById` (mock `IHttpClient`) — `test/src/data/repositories/expense_repository_test.dart`:**

- New `findById` group:
  - `test('returns Right(ExpenseModel) when GET /api/v1/expenses/<id> succeeds')`.
  - `test('returns Left(NotFoundFailure) when GET returns 404')`.
  - `test('returns Left(NetworkFailure) on network error')`.

The existing tests for `create`, `update`, `delete`, `findAll`, `findRecent` SHALL continue to pass unchanged (no signature changes in those repository methods).

**`ExpenseByIdNotifier` — `test/src/presentation/providers/expense_by_id_notifier_test.dart`:**

- `test('returns cached ExpenseModel when id is in expensesProvider items')` — `verifyNever(repository.findById)`.
- `test('falls back to repository.findById when not in cache')`.
- `test('falls back to repository.findById when expensesProvider is AsyncLoading')`.
- `test('throws Failure when repository returns Left, surfacing AsyncError')`.

**`ExpenseNotifier` AsyncNotifier family — `test/src/presentation/providers/expense_notifier_test.dart` (refactor existing):**

- `test('build(null) returns AsyncData with id null and date defaulted to now')`.
- `test('build(id) awaits expenseByIdProvider and returns AsyncData prefilled with id, date, value, description')`.
- `test('build(id) returns AsyncError when expenseByIdProvider throws')`.
- Regression — preserve coverage of:
  - `SubmitPressed` create vs update branching.
  - `DeletePressed` no-op in create mode.
  - `DeletePressed` happy path in edit mode (isDeleting toggle, success).
  - Failure preserves form fields.
  - Invalidations of `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider` on success of submit/delete.

#### Scenario: Test suite passes

Given the change has been implemented per `tasks.md`
When `flutter test` runs
Then all `expense`-related tests SHALL pass

#### Scenario: ExpenseNotifier tests use int family parameter

Given the new test file
When inspecting how the notifier is built in tests
Then the family parameter SHALL be `int?` (e.g. `container.read(expenseProvider(132).notifier)`)
And no test SHALL construct the notifier with `ExpenseModel?`

---
