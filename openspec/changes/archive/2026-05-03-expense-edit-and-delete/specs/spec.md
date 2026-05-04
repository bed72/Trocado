# Spec — expense-edit-and-delete

## Context

The expenses listing (`ExpensesScreen` at `lib/src/presentation/ui/expenses/screens/expenses_screen.dart`) currently renders a paginated, filtered, grouped list of the authenticated user's expenses. Items are read-only — there is no affordance for editing or deleting.

This change adds edit and delete on top of the existing list via a long-press gesture on a list item, which opens a new bottom sheet (`ExpenseActionsScreen`) with two actions — **Editar** and **Excluir**. "Editar" reuses the existing `ExpenseScreen` (the create form) in edit mode — same screen, same notifier, dynamic texts. "Excluir" deletes immediately, without a confirmation dialog.

The backend already supports `PATCH /api/v1/expenses/{id}` and `DELETE /api/v1/expenses/{id}`. All work is on the Flutter side: widen `IExpenseRepository` / `IRemoteExpenseDataSource` with the two new verbs, extend the `ExpenseNotifier` to a Riverpod family so the same notifier serves create and edit, add a new self-contained `expense_actions/` feature for the bottom sheet, wire a `delete` method into `ExpensesNotifier`, and compose long-press navigation inside `ExpensesLocation`.

The existing `ExpenseRequest` DTO (`lib/src/infrastructure/clients/http/requests/expense_request.dart`) already has the exact shape the PATCH expects — `{value, description, date}` — and is therefore reused for both create and update; no new DTO is introduced.

---

## Requirements

### Requirement: IExpenseRepository gains update and delete

The system SHALL extend `IExpenseRepository` (`lib/src/domain/repositories/interface_expense_repository.dart`) with two new methods:

```dart
Future<Either<Failure, ExpenseModel>> update({
  required int id,
  required int date,
  required int value,
  required String description,
});

Future<Either<Failure, void>> delete({required int id});
```

Existing methods (`create`, `findRecent`, `findAll`) SHALL remain unchanged.

#### Scenario: Repository contract exposes both new verbs

Given `IExpenseRepository`
Then the interface SHALL declare `update` and `delete` with the signatures above
And `ExpenseRepository` SHALL implement both methods

---

### Requirement: IRemoteExpenseDataSource gains update and delete

The system SHALL extend `IRemoteExpenseDataSource` (`lib/src/infrastructure/datasources/remote/remote_expense_data_source.dart`) with:

```dart
Future<Either<FailureResponse, ExpenseResponse>> update({
  required int id,
  required int date,
  required int value,
  required String description,
});

Future<Either<FailureResponse, void>> delete({required int id});
```

The interface SHALL accept domain primitives (`int id`, `int date`, `int value`, `String description`) — **no** DTO (`UpdateExpenseRequest`) is introduced. The concrete implementation builds the existing `ExpenseRequest` internally.

#### Scenario: update sends PATCH with the reused ExpenseRequest body

Given `update(id: 132, date: 1745366400000, value: 9230, description: "Mercado")`
When the method runs
Then `IHttpClient.patch` SHALL be invoked with `path == "${EndpointKey.expenses.path}/132"`
And the request body SHALL equal `ExpenseRequest(date: 1745366400000, value: 9230, description: "Mercado").toJson()`
And the returned `Either<FailureResponse, ExpenseResponse>` SHALL come from `response.either(FailureResponse.fromJson, ExpenseResponse.fromJson)`

#### Scenario: delete sends DELETE with no body and returns void on success

Given `delete(id: 132)`
When the method runs
Then `IHttpClient.delete` SHALL be invoked with `path == "${EndpointKey.expenses.path}/132"` and **no body**
And on success the datasource SHALL return `Right(null)` (the `Either<FailureResponse, void>` right side)
And on failure the datasource SHALL return `Left(FailureResponse.fromJson(errorMap))`

---

### Requirement: ExpenseRequest is reused for both create and update

The existing `ExpenseRequest` at `lib/src/infrastructure/clients/http/requests/expense_request.dart` SHALL be used by both `create` and `update`. No `UpdateExpenseRequest` SHALL be introduced.

The wire body is:
```json
{ "value": "92.30", "description": "Mercado", "date": "2026-04-22" }
```

Where `value` is `(int centavos / 100).toStringAsFixed(2)` and `date` is `DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(millis))`.

#### Scenario: PATCH body shape matches POST body shape

Given the same `(date, value, description)` triple
When `RemoteExpenseDataSource.create` and `RemoteExpenseDataSource.update` both serialize it
Then the produced JSON bodies SHALL be byte-equivalent

---

### Requirement: ExpenseRepository implements update and delete with existing extensions

The system SHALL implement `update` and `delete` in `ExpenseRepository` (`lib/src/data/repositories/expense_repository.dart`) as straight pass-throughs to the datasource:

- `update`: calls `_dataSource.update(...)`, folds via `FailureResponseExtension.toFailure()` on the left and `ExpenseResponseExtension.toModel()` on the right.
- `delete`: calls `_dataSource.delete(...)`, folds via `FailureResponseExtension.toFailure()` on the left and `(_) => null` on the right.

No new extension is created. No mapping logic is added — the existing `ExpenseResponseExtension.toModel()` already handles the full `ExpenseResponse → ExpenseModel` conversion (value `"92.30"` → 9230 centavos, date string → millis, etc.).

#### Scenario: update maps FailureResponse to Failure and ExpenseResponse to ExpenseModel

Given `_dataSource.update` returns `Right(ExpenseResponse(id: 132, value: "92.30", ...))`
When the repository folds the result
Then the returned value SHALL be `Right(ExpenseModel)` with `id == 132`, `value == 9230`, and other fields correctly mapped by the existing extension

Given `_dataSource.update` returns `Left(FailureResponse(errors: [{ code: "validation_error", message: "..." }]))`
When the repository folds the result
Then the returned value SHALL be `Left(ValidationFailure("..."))` via the existing `toFailure()` extension

#### Scenario: delete maps FailureResponse to Failure and discards the void right side

Given `_dataSource.delete` returns `Right(null)`
Then the repository SHALL return `Right(null)`

Given `_dataSource.delete` returns `Left(FailureResponse(errors: [{ code: "not_found" }]))`
Then the repository SHALL return `Left(NotFoundFailure)` via the existing `toFailure()` extension

---

### Requirement: ExpenseState gains an optional id

The system SHALL add `final int? id;` to `ExpenseState` (`lib/src/presentation/ui/expense/notifiers/expense_state.dart`).

- `null` means create mode (no existing expense being edited).
- Non-null means edit mode (`id` identifies the expense being PATCHed).

`id` SHALL be included in the constructor (as `this.id`, optional), in `copyWith` (as `int? id`, assigned with `id: id ?? this.id`), and in `props`.

No enum `ExpenseMode` is introduced — the presence of `id` is the sole discriminator between the two modes.

#### Scenario: id defaults to null in create mode

Given `ExpenseState()` with no id passed
Then `state.id` SHALL be `null`

#### Scenario: copyWith preserves id

Given `ExpenseState(id: 132)`
When `copyWith(value: 1000)` is called
Then `state.id` SHALL still be `132`

---

### Requirement: ExpenseNotifier becomes a family parameterized by ExpenseModel?

The system SHALL convert `ExpenseNotifier` (`lib/src/presentation/ui/expense/notifiers/expense_notifier.dart`) into a Riverpod family. The `@riverpod` annotation stays; the `build` method gains an `ExpenseModel?` parameter:

```dart
@riverpod
final class ExpenseNotifier extends _$ExpenseNotifier {
  late IExpenseRepository _repository;
  late ExpenseFormValidator _validator;

  @override
  ExpenseState build(ExpenseModel? expense) {
    _repository = ref.watch(expenseRepositoryProvider);
    _validator = ref.watch(expenseFormValidatorProvider);
    return expense == null
      ? ExpenseState(date: DateTime.now().millisecondsSinceEpoch)
      : ExpenseState(
          id: expense.id,
          date: expense.date,
          value: expense.value,
          description: expense.description,
        );
  }
  // ...
}
```

Fields in `build()` SHALL remain `late`, never `late final` (Riverpod re-executes `build()` when a watched dependency changes).

#### Scenario: create mode yields an initial state with today's date

Given `build(null)` is invoked
Then `state.id` SHALL be `null`
And `state.date` SHALL equal `DateTime.now().millisecondsSinceEpoch` (within a reasonable clock tolerance)
And `state.value` SHALL be `0`
And `state.description` SHALL be `""`

#### Scenario: edit mode yields a state pre-filled from the passed expense

Given an `ExpenseModel(id: 132, date: 1745366400000, value: 9230, description: "Mercado", category: food, createdAt: ...)`
When `build(expense)` is invoked
Then `state.id` SHALL be `132`
And `state.date` SHALL be `1745366400000`
And `state.value` SHALL be `9230`
And `state.description` SHALL be `"Mercado"`

#### Scenario: ExpenseModel instances with equal fields share the same provider

Given `expense1` and `expense2` are two `ExpenseModel` instances with identical field values
Then `expenseNotifierProvider(expense1)` and `expenseNotifierProvider(expense2)` SHALL be the same provider (because `ExpenseModel extends Equatable`)

---

### Requirement: _submit branches between create and update by state.id

The system SHALL update `_submit()` in `ExpenseNotifier` to branch on `state.id == null`:

- `state.id == null` → `_repository.create(date: state.date!, value: state.value, description: state.description)` (current behavior, unchanged).
- `state.id != null` → `_repository.update(id: state.id!, date: state.date!, value: state.value, description: state.description)`.

In **both** success branches, the notifier SHALL invalidate `expensesProvider`, `activeBudgetProvider`, and `recentExpensesProvider` (same three providers as today) and set `state.status = ExpenseStatus.success`.

In both failure branches, the notifier SHALL set `state.status = ExpenseStatus.failure` and `state.message = failure.message`, preserving form fields.

`ExpenseIntent` SHALL remain **unchanged** — the same intents (`ValueChanged`, `DescriptionChanged`, `DateChanged`, `SubmitPressed`) cover both modes. No `DeletePressed` intent is added (delete is exclusive to the bottom sheet).

#### Scenario: Submit in create mode calls repository.create

Given `state.id == null` and all fields are valid
When `_submit()` runs
Then `_repository.create(date: state.date, value: state.value, description: state.description)` SHALL be called exactly once
And `_repository.update` SHALL NOT be called

#### Scenario: Submit in edit mode calls repository.update

Given `state.id == 132` and all fields are valid
When `_submit()` runs
Then `_repository.update(id: 132, date: state.date, value: state.value, description: state.description)` SHALL be called exactly once
And `_repository.create` SHALL NOT be called

#### Scenario: Success in either mode invalidates the three providers

Given a successful `create` or `update` call
Then `ref.invalidate(expensesProvider)`, `ref.invalidate(activeBudgetProvider)`, and `ref.invalidate(recentExpensesProvider)` SHALL all be invoked
And `state.status` SHALL be `success`

#### Scenario: Failure in edit mode preserves form fields

Given `state == ExpenseState(id: 132, value: 9230, description: "Mercado", date: someDate)` and repository returns `Left(ValidationFailure("..."))`
When `_submit()` runs
Then `state.status` SHALL be `failure`
And `state.message` SHALL equal the failure message
And `state.id`, `state.value`, `state.description`, `state.date` SHALL remain unchanged

---

### Requirement: ExpenseLocation accepts ExpenseModel? and passes it down

The system SHALL update `ExpenseLocation` (`lib/src/presentation/ui/expense/locations/expense_location.dart`) to replace `final int? id` with `final ExpenseModel? expense`:

```dart
final class ExpenseLocation extends Location {
  final ExpenseModel? expense;
  const ExpenseLocation({this.expense});

  @override
  String get path => AppRoutes.expense.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(
        ExpenseScreen(
          expense: expense,
          navigateToDate: () => context.navigate(ExpenseDateLocation()),
          navigateToCalculator: (onValueConfirmed) => context.navigate(
            CalculatorLocation(onValueConfirmed: onValueConfirmed),
          ),
        ),
      );
}
```

#### Scenario: Navigating without expense opens create mode

Given `context.navigate(ExpenseLocation())`
Then `ExpenseScreen` SHALL receive `expense: null`
And `ExpenseNotifier.build(null)` SHALL be invoked

#### Scenario: Navigating with expense opens edit mode

Given `context.navigate(ExpenseLocation(expense: someExpense))`
Then `ExpenseScreen` SHALL receive `expense: someExpense`
And `ExpenseNotifier.build(someExpense)` SHALL be invoked

---

### Requirement: ExpenseScreen parametrizes title, subtitle and submit label by mode

The system SHALL update `ExpenseScreen` (`lib/src/presentation/ui/expense/screens/expense_screen.dart`) to accept `final ExpenseModel? expense;` in its constructor and to derive three texts from the presence of `expense`:

| Element | Create (`expense == null`) | Edit (`expense != null`) |
|---|---|---|
| Title | `"Nova despesa"` | `"Editar despesa"` |
| Subtitle | `"Preencha as informações abaixo para registrar sua despesa."` | `"Atualize as informações da sua despesa."` |
| Submit button label | `"Cadastrar"` | `"Atualizar"` |

The screen SHALL watch and read `expenseNotifierProvider(expense)` (the family variant with the passed model). All existing behavior (loading indicator, inline validation errors, success toast, `context.pop()` on success, failure toast) SHALL be preserved without modification.

#### Scenario: Create screen shows create-mode copy

Given `ExpenseScreen(expense: null)` is rendered
Then the title text SHALL be `"Nova despesa"`
And the subtitle SHALL be `"Preencha as informações abaixo para registrar sua despesa."`
And the submit button label SHALL be `"Cadastrar"`

#### Scenario: Edit screen shows edit-mode copy

Given `ExpenseScreen(expense: someExpense)` is rendered
Then the title text SHALL be `"Editar despesa"`
And the subtitle SHALL be `"Atualize as informações da sua despesa."`
And the submit button label SHALL be `"Atualizar"`

---

### Requirement: ExpenseSaveButtonWidget accepts a dynamic label

The system SHALL add `final String label;` to `ExpenseSaveButtonWidget` (`lib/src/presentation/ui/expense/widgets/expense_save_button_widget.dart`) and propagate it to `ButtonWidget.outlined(label: label, …)`. The current hardcoded `'Salvar'` string SHALL be removed.

The `isLoading` and `onSave` parameters SHALL remain unchanged.

#### Scenario: Widget renders the label passed in

Given `ExpenseSaveButtonWidget(label: 'Atualizar', isLoading: false, onSave: () {})` is rendered
Then the visible button text SHALL be `"Atualizar"`

---

### Requirement: ExpenseActionsScreen (bottom sheet, stateless, two callbacks)

The system SHALL add `ExpenseActionsScreen` at `lib/src/presentation/ui/expense_actions/screens/expense_actions_screen.dart` as a `StatelessWidget` that accepts two callbacks via its constructor:

```dart
class ExpenseActionsScreen extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ExpenseActionsScreen({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });
  // ...
}
```

Layout SHALL mirror `ExitScreen` (`lib/src/presentation/ui/exit/screens/exit_screen.dart`):
- `BottomSheetScaffoldWidget(title: 'Despesa', subtitle: 'O que deseja fazer?', child: Column(...))`
- Inside the column: a `Row(spacing: 16.0)` with two `Expanded` children:
  - `ButtonWidget.elevated(label: 'Editar', onTap: onEdit)` (primary, left)
  - `ButtonWidget.outlined(label: 'Excluir', onTap: onDelete)` (secondary, right)
- Vertical 16 px spacing above and below the row (matching `ExitScreen`).

The screen SHALL NOT consume any Riverpod provider. It has no internal state. It is feature-local to `expense_actions/` and SHALL NOT import anything from `expense/` or `expenses/`.

#### Scenario: Tapping Editar invokes onEdit

Given the bottom sheet is rendered
When the user taps the "Editar" elevated button
Then `onEdit()` SHALL be invoked exactly once

#### Scenario: Tapping Excluir invokes onDelete

Given the bottom sheet is rendered
When the user taps the "Excluir" outlined button
Then `onDelete()` SHALL be invoked exactly once

---

### Requirement: ExpenseActionsLocation wraps the screen in a BottomSheetPage

The system SHALL add `ExpenseActionsLocation` at `lib/src/presentation/ui/expense_actions/locations/expense_actions_location.dart` following the `ExitLocation` pattern:

```dart
final class ExpenseActionsLocation extends Location {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ExpenseActionsLocation({required this.onEdit, required this.onDelete});

  @override
  String get path => AppRoutes.expenseActions.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => BottomSheetPage(
    builder: (_) => ExpenseActionsScreen(onEdit: onEdit, onDelete: onDelete),
  );
}
```

The Location SHALL NOT inject navigation logic itself — it only carries the callbacks from its caller (`ExpensesLocation`) down to the screen. The screen invokes the callbacks; callers decide what to do.

#### Scenario: Location composes BottomSheetPage with the screen

Given `context.navigate(ExpenseActionsLocation(onEdit: cb1, onDelete: cb2))`
Then a `BottomSheetPage` SHALL be pushed
And the page builder SHALL return an `ExpenseActionsScreen` wired with `cb1` and `cb2`

---

### Requirement: AppRoutes gains expenseActions

The system SHALL add `expenseActions` to `AppRoutes` in `lib/app_route.dart`:

```dart
static final expenseActions = AppRoutes._(
  path: '/expense-actions',
  name: 'expense-actions-route',
  regex: RegExp(r'^/expense-actions$'),
);
```

The new entry SHALL be included in the `_all` list used by `AppRoutes.match`.

#### Scenario: Deep link matching recognizes the new route

Given `AppRoutes.match('/expense-actions')`
Then the returned `AppRoutes` SHALL be `AppRoutes.expenseActions`

---

### Requirement: ExpensesNotifier gains a delete method (not an intent)

The system SHALL add a method `Future<Either<Failure, void>> delete(int id)` to `ExpensesNotifier` (`lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`). This notifier does **not** use MVI dispatch — its surface is method-based (`applyFilter`, `searchChanged`, `removeFilter`, `loadMore`, `delete`). No `ExpensesIntent` sealed class is introduced.

Behavior:
1. Call `_repository.delete(id: id)`.
2. On `Right(_)`: invoke `ref.invalidate(activeBudgetProvider)`, `ref.invalidate(recentExpensesProvider)`, and `ref.invalidate(expensesProvider)`. The self-invalidate causes Riverpod to re-run `build()`, which refetches the first page with the current filter — the deleted item is naturally absent. Return `Right(null)`.
3. On `Left(failure)`: return `Left(failure)` **without mutating state**. The list stays visible and intact; the caller (composed callback in `ExpensesLocation`) surfaces the failure via a toast. `state` SHALL NOT be transitioned to `AsyncError` on delete failures — that path is reserved for list-loading errors.

The method SHALL NOT receive or know about the `ExpenseModel`; it only needs the `id`. The caller (`ExpensesLocation`'s composed callback) is responsible for passing `expense.id` and for handling the returned `Either` (showing the toast on `Left`).

#### Scenario: delete invokes repository.delete with the given id

Given the notifier's state is `AsyncData(...)` with some items including one with `id == 132`
When `notifier.delete(132)` is called
Then `_repository.delete(id: 132)` SHALL be invoked exactly once

#### Scenario: Successful delete invalidates three providers and returns Right(null)

Given `_repository.delete(id: 132)` returns `Right(null)`
When the fold runs
Then `ref.invalidate(activeBudgetProvider)`, `ref.invalidate(recentExpensesProvider)`, and `ref.invalidate(expensesProvider)` SHALL all be invoked
And the method SHALL return `Right(null)`
And the next read of `expensesProvider` SHALL trigger a fresh `build()` (first-page fetch with current filter)

#### Scenario: Failed delete returns Left without mutating state

Given the notifier's state is `AsyncData(ExpensesState(items: [...], filter: f))`
And `_repository.delete(id: 132)` returns `Left(ServerFailure())`
When the fold runs
Then the method SHALL return `Left(ServerFailure())`
And `state` SHALL remain `AsyncData(ExpensesState(items: [...], filter: f))` unchanged
And no `ref.invalidate` SHALL be called

---

### Requirement: ExpenseItemWidget gains an optional onLongPress

The system SHALL add `final VoidCallback? onLongPress;` to `ExpenseItemWidget` (`lib/src/presentation/widgets/expense/expense_item_widget.dart`). The existing `Padding(...)` body SHALL be wrapped in `GestureDetector(onLongPress: onLongPress, child: Padding(...))`.

The widget SHALL NOT use `InkWell` or any other ripple-producing affordance. The item has no `onTap`, so adding visual feedback for a non-existent tap would be noise. The long-press triggers navigation to the action sheet — the sheet's appearance is the feedback.

If `onLongPress == null`, the gesture is effectively disabled (matching Flutter's default `GestureDetector` behavior). Existing usages of `ExpenseItemWidget` that do not pass `onLongPress` SHALL continue to work.

#### Scenario: Long-press invokes the callback

Given `ExpenseItemWidget(expense: e, formattedValue: f, onLongPress: cb)` is rendered
When the user long-presses anywhere on the item's row
Then `cb()` SHALL be invoked exactly once

#### Scenario: Widget without onLongPress has no gesture

Given `ExpenseItemWidget(expense: e, formattedValue: f)` with `onLongPress` omitted or `null`
Then long-press on the row SHALL have no effect

---

### Requirement: ExpensesListWidget propagates long-press up to the screen

The system SHALL update `ExpensesListWidget` (`lib/src/presentation/ui/expenses/widgets/expenses_list_widget.dart`) to accept `final ValueChanged<ExpenseModel> onLongPressExpense;` and pass `onLongPress: () => onLongPressExpense(item.expense)` to each `ExpenseItemWidget` it builds inside `SliverList.builder`.

`ExpensesScreen` SHALL in turn accept `final ValueChanged<ExpenseModel> onLongPressExpense;` in its constructor and forward it to `ExpensesListWidget`.

#### Scenario: Long-press on list item bubbles up with the expense model

Given the list has an item with `expense.id == 132`
When the user long-presses that item
Then the screen-level `onLongPressExpense` SHALL be invoked with that exact `ExpenseModel` instance

---

### Requirement: ExpensesLocation composes onEdit and onDelete callbacks

The system SHALL update `ExpensesLocation` (`lib/src/presentation/ui/expenses/locations/expenses_location.dart`) to wrap its `pageBuilder` body in a `Consumer` (from `flutter_riverpod`) — so that the long-press callback can capture `ref` without turning `ExpensesScreen` into a `ConsumerWidget` and without leaking Riverpod into `ExpenseActionsScreen`.

```dart
@override
LocationPageBuilder get pageBuilder => (context) => screenPage(
  Consumer(
    builder: (context, ref, _) => ExpensesScreen(
      navigateToFilter: () => context.navigate(ExpensesFilterLocation()),
      onLongPressExpense: (expense) => context.navigate(
        ExpenseActionsLocation(
          onEdit: () {
            context.pop();
            context.navigate(ExpenseLocation(expense: expense));
          },
          onDelete: () async {
            context.pop();
            final data = await ref.read(expensesProvider.notifier).delete(expense.id);
            data.fold(
              (failure) => showToastWidget(
                context: context,
                title: 'Opps',
                type: ToastConstant.failure,
                description: failure.message,
              ),
              (_) {},
            );
          },
        ),
      ),
    ),
  ),
);
```

This is the **only** place that simultaneously knows about `ExpenseLocation`, `ExpenseActionsLocation`, and `expensesProvider`. It is the sole authorized cross-feature cohesion point per the project's "features are self-contained" rule (Locations composing navigation is the explicit exception).

The `onDelete` callback is `async`: it pops the sheet first, then awaits the delete, then folds the returned `Either`. On `Left`, it invokes `showToastWidget` (the same toast helper used by `ExpenseScreen` for submit failures) so the user sees the error on the list screen. On `Right`, it is a no-op — the provider invalidation inside the notifier already refreshes the list.

`ExpensesScreen` SHALL NOT import `ExpenseActionsLocation` or `ExpenseLocation` directly.
`ExpenseActionsScreen` / `ExpenseActionsLocation` SHALL NOT import anything from `expenses/` or `expense/`.

#### Scenario: Long-press opens the action sheet

Given the user is on `ExpensesScreen`
When they long-press an item with `expense.id == 132`
Then `ExpenseActionsLocation` SHALL be pushed with two callbacks `onEdit` and `onDelete` closed over that specific expense

#### Scenario: Tapping Editar pops the sheet and opens edit screen

Given the action sheet is open for expense `e`
When the user taps "Editar"
Then `context.pop()` SHALL close the sheet
And `context.navigate(ExpenseLocation(expense: e))` SHALL open `ExpenseScreen` in edit mode with the state pre-filled

#### Scenario: Tapping Excluir pops the sheet, deletes, and shows no confirmation

Given the action sheet is open for expense `e` with `e.id == 132`
When the user taps "Excluir"
Then `context.pop()` SHALL close the sheet
And `ref.read(expensesProvider.notifier).delete(132)` SHALL be invoked
And **no** confirmation dialog SHALL appear

#### Scenario: Successful delete leaves the list refreshed without a toast

Given the delete call returns `Right(null)`
Then no toast SHALL be displayed
And the list SHALL re-render without the deleted item (via the self-invalidate inside the notifier)

#### Scenario: Failed delete surfaces a toast and keeps the list intact

Given the delete call returns `Left(ServerFailure())`
Then `showToastWidget(context: context, type: ToastConstant.failure, description: failure.message, …)` SHALL be invoked on the `ExpensesScreen` context
And the list SHALL remain visible and unchanged (no `AsyncError`, no item removal)

---

### Requirement: API contract — PATCH /api/v1/expenses/{id}

`PATCH /api/v1/expenses/{id}` — requires Bearer token.

Request body (always sends all three fields, even if only one changed — create and update share the same DTO):
```json
{
  "value": "92.30",
  "description": "Mercado - compras do mês",
  "date": "2026-04-22"
}
```

Response 200 OK:
```json
{
  "id": 132,
  "value": "92.30",
  "description": "Mercado - compras do mês",
  "date": "2026-04-22",
  "created_at": "2026-04-23T10:55:20.918144-03:00",
  "category": "food"
}
```

Failure (400/401/404/422/5xx) — standard `FailureResponse` shape:
```json
{
  "errors": [
    { "field": "string", "message": "string", "code": "string" }
  ]
}
```

Value is a decimal `String` on the wire; stored as `int` centavos in the app. Date is ISO `yyyy-MM-dd`; stored as `int` millis in the app. Category is generated by the backend from the description — **not** editable from the client, and therefore absent from the request body.

Status code → failure mapping is unchanged (reuses `FailureResponseExtension.toFailure()` via `FailureCodeResponse`).

#### Scenario: Request omits category

Given any update call
Then the request body SHALL contain exactly three keys: `value`, `description`, `date`
And SHALL NOT contain a `category` key

#### Scenario: Response fields are mapped via the existing extension

Given a 200 response as above
When `ExpenseResponseExtension.toModel()` runs
Then `ExpenseModel.id == 132`, `.value == 9230`, `.description == "Mercado - compras do mês"`, `.date == DateFormat('yyyy-MM-dd').parse("2026-04-22").millisecondsSinceEpoch`, `.createdAt == DateTime.parse("2026-04-23T10:55:20.918144-03:00").millisecondsSinceEpoch`, `.category == ExpenseCategoryEnum.food`

---

### Requirement: API contract — DELETE /api/v1/expenses/{id}

`DELETE /api/v1/expenses/{id}` — requires Bearer token. No request body.

Response 204 No Content — empty body.

Failure (401/404/5xx) — standard `FailureResponse` shape (same as above).

#### Scenario: Successful delete has no body to parse

Given a 204 response
When `RemoteExpenseDataSource.delete` runs
Then the right side of the returned `Either` SHALL be `null` (`void`)
And no JSON parsing SHALL occur on the success path

---

### Requirement: Clean Architecture layering

The feature SHALL respect the project's dependency rule (`domain ← data ← infrastructure; domain ← presentation`):

- `domain/` — two new interface methods on `IExpenseRepository`. Zero Flutter imports.
- `infrastructure/` — two new datasource methods. Reuses existing `ExpenseRequest`. Depends only on `domain` types and infrastructure primitives.
- `data/` — two new repository implementations, straight pass-throughs. No DTOs introduced here.
- `presentation/` — `ExpenseState` gains `id`; `ExpenseNotifier` becomes a family; `ExpenseScreen` + `ExpenseSaveButtonWidget` parametrize copy; new `expense_actions/` feature (screen + location); `ExpensesNotifier` gains `delete`; `ExpenseItemWidget` gains `onLongPress`; `ExpensesListWidget` / `ExpensesScreen` propagate the callback; `ExpensesLocation` composes the cross-feature navigation (the exception point).
- `main/` — `AppRoutes.expenseActions` added to `app_route.dart`. No new providers.

Violations explicitly forbidden by this change:

- `expense_actions/` SHALL NOT import anything from `expense/` or `expenses/`.
- `ExpenseActionsScreen` SHALL NOT be a `ConsumerWidget` and SHALL NOT read any provider (Riverpod or otherwise).
- `ExpenseScreen` SHALL NOT import `ExpenseActionsLocation`.
- `ExpenseNotifier` SHALL NOT be called with `ref.watch` / `ref.read` from any feature other than `expense/` (its family parameter is passed by `ExpenseLocation`, which is allowed because Locations compose navigation).
- No private widget classes (`class _FooWidget extends StatelessWidget`) SHALL be declared inside any file touched by this change.
- No `var` SHALL be used.
- All `switch`es introduced or modified SHALL be switch expressions (never switch statements).

---

### Requirement: Tests

#### ExpenseRepository (mock `IHttpClient` — path: `test/src/data/repositories/expense_repository_test.dart`)

- `update` sends `IHttpClient.patch` with path `"/api/v1/expenses/132"` and body equal to `ExpenseRequest(date, value, description).toJson()` — no extra keys, no `category`.
- `update` success (200 with ExpenseModel body) returns `Right(ExpenseModel)` with `id == 132`, `value == 9230` centavos (from `"92.30"`), and all other fields correctly mapped.
- `update` 400 with `{errors: [{code: "validation_error", message: "..."}]}` returns `Left(ValidationFailure("..."))`.
- `update` network error (DioException) returns `Left(NetworkFailure())`.
- `update` 500 returns `Left(ServerFailure())`.
- `delete` sends `IHttpClient.delete` with path `"/api/v1/expenses/132"` and **no body**.
- `delete` 204 (empty body) returns `Right(null)`.
- `delete` 404 with `{errors: [{code: "not_found"}]}` returns `Left(NotFoundFailure())`.
- `delete` network error returns `Left(NetworkFailure())`.

#### ExpenseNotifier family (mock `IExpenseRepository` via `ProviderContainer` — path: `test/src/presentation/providers/expense_notifier_test.dart`)

- `build(null)` returns an initial state with `id == null`, `date == DateTime.now().millisecondsSinceEpoch` (assert within a 1-second tolerance), `value == 0`, `description == ""`.
- `build(expense)` with an `ExpenseModel(id: 132, date: 1745366400000, value: 9230, description: "Mercado", ...)` returns state with those exact fields.
- `dispatch(SubmitPressed())` in create mode (state.id == null, valid fields) calls `repository.create` exactly once with the state's `date`, `value`, `description`. `repository.update` is NOT called.
- `dispatch(SubmitPressed())` in edit mode (state.id == 132, valid fields) calls `repository.update(id: 132, date: …, value: …, description: …)` exactly once. `repository.create` is NOT called.
- Successful `create` invalidates `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider`; status → `success`.
- Successful `update` invalidates the same three providers; status → `success`.
- Failed `update` (e.g. `Left(ValidationFailure("bad value"))`) sets status → `failure`, message → `"bad value"`, and preserves `state.id`, `state.value`, `state.description`, `state.date`.

#### ExpensesNotifier.delete (mock `IExpenseRepository` via `ProviderContainer` — path: `test/src/presentation/providers/expenses_notifier_test.dart`)

- `delete(132)` invokes `repository.delete(id: 132)` exactly once.
- Successful delete invalidates `activeBudgetProvider`, `recentExpensesProvider`, and `expensesProvider` (self-invalidate); returns `Right(null)`.
- Failed delete (`Left(ServerFailure())`) returns `Left(ServerFailure())` **without** mutating state; the pre-existing `AsyncData(ExpensesState)` is preserved; no provider is invalidated.

#### Widget tests (desirable, not blocking — path: `test/src/presentation/widgets/` and `test/src/presentation/ui/expense_actions/`)

- `ExpenseItemWidget` invokes `onLongPress` callback when the user long-presses anywhere on the row.
- `ExpenseActionsScreen` invokes `onEdit` when the "Editar" button is tapped.
- `ExpenseActionsScreen` invokes `onDelete` when the "Excluir" button is tapped.

#### Conventions (CLAUDE.md)

- All `test()`, `group()`, and `testWidgets()` descriptions SHALL be in **English**.
- Mocks SHALL be declared with the **interface type** (`late IHttpClient client;`, `late IExpenseRepository repository;`), never with the mock concrete type.
- Variables holding the result of `Future` / `Either` operations SHALL be named `data`, `state`, or the domain concept — never `result` or `either`.
- `var` SHALL NOT be used.

#### Mocks

- `test/mocks/mocks.dart` already exposes `MockHttpClient` (from `http_client_test`) and `MockExpenseRepository` (from prior expense specs). These are reused as-is — no new mock class is added unless a gap is discovered during implementation.

---

## Out of scope

- Confirmation dialog before delete — explicitly descoped by the UX decision; delete is immediate.
- Delete button inside `ExpenseScreen` — delete is exclusive to the bottom sheet.
- Category field in the form — the backend generates it from the description; the form never edits it.
- `findById` in `IExpenseRepository` or `IRemoteExpenseDataSource` — the `ExpenseModel` is passed in memory through `ExpenseLocation(expense: ...)` from the list item.
- Swipe-to-delete on list items — rejected in favor of long-press for lower accidental-deletion risk.
- "Undo delete" snackbar — out of scope this iteration; will be a separate spec if accidental deletion turns out to be an issue in use.
- Partial PATCH (sending only changed fields) — not worth the code complexity today; `ExpenseRequest` sends all three fields always.
- Optimistic UI (removing the item locally before the server confirms) — deferred.
- Multi-select + batch delete.
- Edit history / audit trail.
- Notifying the partner about edits/deletes (social layer — out of CRUD scope).
- Backend changes — `PATCH` and `DELETE` already exist.
- Changes to `findAll`, `findRecent`, `create`, or to `ExpenseModel` / `ExpensesPageModel` domain shapes.
- Deep link for editing a specific expense by id — requires Location to accept `int?` and fetch the model; the current long-press flow passes the model in memory.

---

## Decisions (approved)

- **Reuse `ExpenseRequest` for create and update**: approved. Same wire shape; no reason to fork into two DTOs until the backend diverges.
- **`ExpenseNotifier` family parameterized by `ExpenseModel?`, not `int?`**: approved. Model is already in memory; avoids a `findById` round-trip.
- **`ExpenseState.id` as the sole discriminator between create and edit**: approved. No `ExpenseMode` enum — presence of id is load-bearing and explicit.
- **No `DeletePressed` intent in `ExpenseNotifier`**: approved. Delete lives exclusively in the bottom sheet; adding it to the form notifier would imply a delete button on the edit screen, which was explicitly rejected.
- **`ExpensesNotifier.delete` as a direct method, not an intent**: approved. This notifier does not use MVI dispatch — its existing surface is method-based (`applyFilter`, `searchChanged`, etc.). Consistency with the existing idiom trumps uniformity across notifiers.
- **`expense_actions/` is screen + location only (no notifier)**: approved. The sheet is a pure callback surface; introducing a notifier would be ceremony.
- **Delete without confirmation dialog**: approved by UX decision. Long-press → bottom sheet → tap "Excluir" is deliberate enough; we trade reversibility for speed. If accidental deletion surfaces as a real issue, the next evolution is a 5-second "Desfazer" snackbar, not a modal dialog.
- **Long-press via `GestureDetector`, not `InkWell`**: approved. The item has no `onTap`; adding ripple feedback for a non-existent gesture is visual noise.
- **`ExpensesLocation` as the sole cross-feature composition point** (via `Consumer` in `pageBuilder`): approved. This is the explicit exception in the "features are self-contained" rule — Locations compose navigation.
- **Self-invalidate `expensesProvider` on successful delete**: approved. Cleaner than manually splicing the item out of the list; re-executing `build()` refetches with the current filter and yields an identical outcome.
- **Dynamic submit button label via a `label` parameter on `ExpenseSaveButtonWidget`**: approved. Parametrizing at the widget keeps it mode-agnostic; the screen owns the string.
- **Delete failure surfaces as a toast on the list screen, not as `AsyncError`**: approved. Transitioning `ExpensesNotifier.state` to `AsyncError` on a delete failure would replace the whole list with an error screen — disproportionate to the failure and destroys context the user had. Instead, `delete(id)` returns `Future<Either<Failure, void>>`; the composed callback in `ExpensesLocation` pops the sheet, awaits, and shows `showToastWidget(..., type: ToastConstant.failure, description: failure.message)` on `Left`. The list stays intact. This mirrors the toast pattern already used by `ExpenseScreen` for submit failures.
