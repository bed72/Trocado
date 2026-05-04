# budgets Specification (delta)

## Purpose (extends existing)

Budget completa o CRUD básico — ganha edição (PATCH), exclusão (DELETE) e busca por id (GET) — mantendo a paginação e o card ativo já entregues. A tela de form vira dinâmica entre create e edit, e a navegação para edit usa exclusivamente `int id` (não `BudgetModel`), preparando deep-link e desacoplando do estado da listagem.

## Requirements

### Requirement: IBudgetRepository extended with update, delete, findById

The system SHALL extend `lib/src/domain/repositories/interface_budget_repository.dart` with three new methods:

```dart
Future<Either<Failure, BudgetModel>> update({
  required int id,
  required int value,
  required int endDate,
  required int startDate,
  required String description,
});

Future<Either<Failure, void>> delete({required int id});

Future<Either<Failure, BudgetModel>> findById({required int id});
```

The signature of `delete` SHALL match `IExpenseRepository.delete` exactly (`Future<Either<Failure, void>>` — not `Unit`, not `bool`).

The existing `findActive`, `findAll` and `create` methods SHALL remain unchanged.

#### Scenario: All three methods are present

Given the new interface is in place
When the file is parsed
Then it SHALL declare `update`, `delete`, and `findById` with the signatures above

#### Scenario: Delete signature mirrors Expense

Given both repositories
Then `IBudgetRepository.delete` and `IExpenseRepository.delete` SHALL have identical signatures

---

### Requirement: IRemoteBudgetDataSource extended with update, delete, findById

The system SHALL extend the interface and implementation in `lib/src/infrastructure/datasources/remote/remote_budget_data_source.dart` with:

```dart
Future<Either<FailureResponse, BudgetResponse>> update({
  required int id,
  required int value,
  required int endDate,
  required int startDate,
  required String description,
});

Future<Either<FailureResponse, void>> delete({required int id});

Future<Either<FailureResponse, BudgetResponse>> findById({required int id});
```

The interface SHALL accept **only primitive domain parameters** — never `BudgetRequest` or any infrastructure DTO.

The implementation SHALL:

- For `update`: call `_client.patch(parameter: Requests('${EndpointKey.budgets.path}/$id', body: BudgetRequest(value: value, endDate: endDate, startDate: startDate, description: description).toJson()))` and deserialize via `response.either(FailureResponse.fromJson, BudgetResponse.fromJson)`. **Reuse the existing `BudgetRequest`** — `UpdateBudgetRequest` SHALL NOT be introduced.
- For `delete`: call `_client.delete(parameter: Requests('${EndpointKey.budgets.path}/$id'))` and deserialize via `response.either(FailureResponse.fromJson, (_) {})` (discards the empty body returned for 204).
- For `findById`: call `_client.get(parameter: Requests('${EndpointKey.budgets.path}/$id'))` and deserialize via `response.either(FailureResponse.fromJson, BudgetResponse.fromJson)`.

The variable holding the client return SHALL be named `response` (never `either`).

#### Scenario: update reuses BudgetRequest for the body

Given `update(id: 9, value: 1200000, endDate: ..., startDate: ..., description: "May")` is invoked
Then the implementation SHALL build a `BudgetRequest` and call `_client.patch` with `body: <request>.toJson()`
And no `UpdateBudgetRequest` class SHALL exist in the codebase

#### Scenario: delete discards 204 body

Given `delete(id: 9)` is invoked and the client returns `Right({})` for a 204
When the datasource maps the result
Then the right side SHALL be `void` (the `(_) {}` closure consumes the empty payload)

#### Scenario: findById URL pattern

Given `findById(id: 9)` is invoked
Then `_client.get` SHALL be called with `Requests('${EndpointKey.budgets.path}/9')`

---

### Requirement: BudgetRepository extended with update, delete, findById

The system SHALL extend `lib/src/data/repositories/budget_repository.dart` with the three implementations:

- `update`: `data.either((failure) => failure.toFailure(), (response) => response.toModel())` — reuses `BudgetResponseExtension.toModel()` and `FailureResponseExtension.toFailure()` already in `data/extensions/`.
- `delete`: `data.either((failure) => failure.toFailure(), (_) {})` — success is `Right(null)`.
- `findById`: identical mapping to `update`.

Variables holding the datasource return SHALL be named `data` (never `result` or `either`).

The existing `findActive`, `findAll`, `create` methods SHALL remain unchanged.

#### Scenario: update success returns Right(BudgetModel) with centavos conversion

Given the datasource returns `Right(BudgetResponse(value: "1000.00", ...))`
When `update` is called
Then the repository SHALL return `Right(BudgetModel(value: 100000, ...))`

#### Scenario: delete success returns Right(null)

Given the datasource returns `Right(<void>)`
When `delete` is called
Then the repository SHALL return `Right(null)`

#### Scenario: Failure mapping uses FailureResponseExtension.toFailure

Given the datasource returns `Left(FailureResponse(errors: [item with code "not_found"]))`
When any of the three methods is called
Then the repository SHALL return `Left(NotFoundFailure)` via `failure.toFailure()`

---

### Requirement: budgetByIdProvider — cache-first family by int id

The system SHALL add `lib/src/presentation/ui/budget/notifiers/budget_by_id_notifier.dart` exposing a Riverpod family provider `budgetByIdProvider(int id)` that returns `Future<BudgetModel>`.

Resolution logic:

1. Read the current value of `budgetsProvider` via `ref.read` (NOT `ref.watch` — the by-id provider SHALL NOT re-execute when the list changes).
2. If `budgetsProvider` is in `AsyncData` and any item in `value.items` (or `value.activeItem`, if present) has matching `id`, return that `BudgetModel`.
3. Otherwise, read `budgetRepositoryProvider` (via `ref.watch`) and call `repository.findById(id: id)`. On `Right(model)` return the model; on `Left(failure)` rethrow `failure` so the provider transitions to `AsyncError`.

#### Scenario: Cache hit via items list

Given `budgetsProvider` value is `AsyncData(BudgetsState(items: [item1 with budget id 5, item2 with id 7], activeItem: null))`
When `budgetByIdProvider(7)` is read
Then the future SHALL resolve to the `BudgetModel` of `item2`
And `repository.findById` SHALL NOT be called (`verifyNever`)

#### Scenario: Cache hit via activeItem

Given `budgetsProvider` value is `AsyncData(BudgetsState(items: [], activeItem: <item with budget id 9>))`
When `budgetByIdProvider(9)` is read
Then the future SHALL resolve to the `BudgetModel` of `activeItem`
And `repository.findById` SHALL NOT be called

#### Scenario: Cache miss falls back to repository

Given `budgetsProvider` value is `AsyncData(BudgetsState(items: [items with ids 1 and 2]))` and the user requests id 999
When `budgetByIdProvider(999)` is read
Then `repository.findById(id: 999)` SHALL be called once
And on `Right(model)` the future SHALL resolve to that model

#### Scenario: AsyncLoading list also triggers fallback

Given `budgetsProvider` is `AsyncLoading`
When `budgetByIdProvider(9)` is read
Then `repository.findById(id: 9)` SHALL be called

#### Scenario: Repository failure propagates as AsyncError

Given `repository.findById(id: 9)` returns `Left(NotFoundFailure)`
When `budgetByIdProvider(9)` is read
Then the future SHALL throw `NotFoundFailure`
And the provider SHALL transition to `AsyncError(NotFoundFailure)`

---

### Requirement: BudgetFormState extended with id and isDeleting

The system SHALL extend `lib/src/presentation/ui/budget/notifiers/form/budget_form_state.dart` with:

- `final int? id;` — `null` discriminates create mode; non-null discriminates edit mode (the budget being edited).
- `final bool isDeleting;` — independent loading flag for the delete action (so the update button can stay enabled while delete is in flight, and vice versa).

Both fields SHALL be in `props` and `copyWith`. The `copyWith` SHALL accept `int? id` (named) and `bool? isDeleting` (named) following the existing `value ?? this.value` pattern. **No** clear-flag is needed for `id` (going from edit back to create is not a real flow — the screen is reconstructed via the family parameter).

The remaining fields (`value`, `startDate`, `endDate`, `description`, `dateFailure`, `valueFailure`, `descriptionFailure`, `status`, `message`) SHALL remain unchanged.

#### Scenario: Initial state has id null and isDeleting false

Given `const BudgetFormState()`
Then `id` SHALL be `null`
And `isDeleting` SHALL be `false`

#### Scenario: copyWith preserves and overrides id

Given `const BudgetFormState(id: 9)`
When `copyWith(value: 100000)` is invoked
Then the result SHALL have `id == 9` and `value == 100000`

#### Scenario: Equatable includes new fields

Given two `BudgetFormState` instances differing only by `isDeleting`
Then `==` SHALL return `false`

---

### Requirement: BudgetFormIntent extended with DeletePressed

The system SHALL extend `lib/src/presentation/ui/budget/notifiers/form/budget_form_intent.dart` with:

```dart
final class DeletePressed extends BudgetFormIntent {
  const DeletePressed();
}
```

The existing intents (`ValueChanged`, `DateRangeChanged`, `DescriptionChanged`, `SubmitPressed`) SHALL remain unchanged. The sealed class hierarchy SHALL stay sealed so the `dispatch` switch is exhaustive.

#### Scenario: dispatch is exhaustive

Given the new intent
When `BudgetFormNotifier.dispatch(intent)` is implemented as `switch (intent) { ... }`
Then the analyzer SHALL accept it as exhaustive (sealed hierarchy + all cases handled)

---

### Requirement: BudgetFormNotifier becomes AsyncNotifier family by int? id

The system SHALL refactor `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart` to:

- Be annotated as a Riverpod async family provider (`@riverpod` with `Future<BudgetFormState> build(int? id)`).
- Dependencies obtained via `ref.watch` in `build()`, marked `late` (never `late final`):
  - `_repository = ref.watch(budgetRepositoryProvider)`.
  - `_validator = ref.watch(budgetFormValidatorProvider)`.
- `build(int? id)`:
  - If `id == null` → return `const BudgetFormState()`.
  - If `id != null` → `final budget = await ref.watch(budgetByIdProvider(id).future); return BudgetFormState(id: budget.id, value: budget.value, startDate: budget.startDate, endDate: budget.endDate, description: budget.description);`.
- `dispatch(BudgetFormIntent intent)` SHALL be a switch expression covering all intents, with `DeletePressed() => _delete()`. State mutations from `dispatch` SHALL go through `state = AsyncData(state.value!.copyWith(...))`.
- `_submit()`:
  - Run validator: `final (:state, :isValid) = _validator(this.state.value!);`.
  - If `!isValid` → `state = AsyncData(state)`; return.
  - Set `status: .loading`.
  - Branch by `state.value!.id == null`:
    - `null` → `_repository.create(value: ..., endDate: ..., startDate: ..., description: ...)`.
    - non-null → `_repository.update(id: state.value!.id!, value: ..., endDate: ..., startDate: ..., description: ...)`.
  - On `Right(_)`: `ref.invalidate(budgetsProvider)`, `ref.invalidate(activeBudgetProvider)`, set `status: .success`.
  - On `Left(failure)`: set `status: .failure` and `message: failure.message`.
- `_delete()`:
  - Early-return if `state.value!.id == null` (no-op).
  - Set `isDeleting: true`.
  - Call `_repository.delete(id: state.value!.id!)`.
  - On `Right(_)`: `ref.invalidate(budgetsProvider)`, `ref.invalidate(activeBudgetProvider)`, set `isDeleting: false, status: .success`.
  - On `Left(failure)`: set `isDeleting: false, status: .failure, message: failure.message`.

The notifier SHALL NOT call `showDialog` or any function requiring `BuildContext` — confirmation lives entirely in the screen.

#### Scenario: build(null) returns initial state synchronously

Given `budgetFormProvider(null)` is read
When the provider builds
Then the future SHALL resolve to `BudgetFormState()` with `id == null`

#### Scenario: build(id) awaits byIdProvider

Given `budgetFormProvider(9)` is read and `budgetByIdProvider(9)` resolves to `BudgetModel(id: 9, value: 1200000, ...)`
When the provider builds
Then the future SHALL resolve to `BudgetFormState(id: 9, value: 1200000, startDate: ..., endDate: ..., description: ...)`

#### Scenario: build(id) propagates AsyncError

Given `budgetByIdProvider(9)` throws `NotFoundFailure`
When `budgetFormProvider(9)` builds
Then the provider SHALL transition to `AsyncError(NotFoundFailure)`

#### Scenario: SubmitPressed in create mode calls create

Given `state.value.id == null`
When `dispatch(const SubmitPressed())` is invoked with a valid form
Then `_repository.create(...)` SHALL be called once
And `_repository.update(...)` SHALL NOT be called

#### Scenario: SubmitPressed in edit mode calls update with state.id

Given `state.value.id == 9`
When `dispatch(const SubmitPressed())` is invoked with a valid form
Then `_repository.update(id: 9, ...)` SHALL be called once
And `_repository.create(...)` SHALL NOT be called

#### Scenario: Successful update invalidates listing providers

Given `update` returns `Right(model)`
When the success branch runs
Then `ref.invalidate(budgetsProvider)` and `ref.invalidate(activeBudgetProvider)` SHALL be called
And `state.value.status` SHALL be `success`

#### Scenario: DeletePressed in create mode is a no-op

Given `state.value.id == null`
When `dispatch(const DeletePressed())` is invoked
Then `_repository.delete(...)` SHALL NOT be called (`verifyNever`)
And `state` SHALL remain unchanged

#### Scenario: DeletePressed in edit mode toggles isDeleting and sets success

Given `state.value.id == 9`
When `dispatch(const DeletePressed())` is invoked and `delete` returns `Right(null)`
Then state SHALL transition through `isDeleting: true` and end at `isDeleting: false, status: success`
And `ref.invalidate(budgetsProvider)` and `ref.invalidate(activeBudgetProvider)` SHALL be called

#### Scenario: DeletePressed failure preserves form

Given `state.value.id == 9` and `delete` returns `Left(NetworkFailure)`
When `dispatch(const DeletePressed())` is invoked
Then the final state SHALL have `isDeleting: false, status: failure, message: NetworkFailure.message`
And the form fields (`value`, `startDate`, `endDate`, `description`) SHALL remain populated with the budget being edited

#### Scenario: Notifier never imports BuildContext-dependent APIs

Given the notifier file
When `grep -E "showDialog|BuildContext" lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart` is executed
Then the result SHALL be empty

---

### Requirement: BudgetEditActionsWidget — dynamic footer for edit mode

The system SHALL add `lib/src/presentation/ui/budget/widgets/budget_edit_actions_widget.dart` as a `StatelessWidget` mirroring `ExpenseEditActionsWidget`:

```dart
final class BudgetEditActionsWidget extends StatelessWidget {
  final bool isLoading;
  final bool isDeleting;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const BudgetEditActionsWidget({
    super.key,
    required this.isLoading,
    required this.isDeleting,
    required this.onUpdate,
    required this.onDelete,
  });
  ...
}
```

The build SHALL render `Row(spacing: 16.0, children: [Expanded(<delete button>), Expanded(<update button>)])`:

- Delete button: `ButtonWidget.outlined` (or destructive variant) with `label: 'Excluir'`, `isLoading: isDeleting`, `onTap: () { if (isLoading || isDeleting) return; onDelete(); }`.
- Update button: `ButtonWidget.elevated` with `label: 'Atualizar'`, `isLoading: isLoading`, `onTap: () { if (isLoading || isDeleting) return; onUpdate(); }`.

Either button SHALL be disabled while the other is in flight (`isLoading || isDeleting`).

The widget SHALL NOT contain private widget classes (project rule). Trivial subwidgets SHALL be private methods.

#### Scenario: Renders two buttons side-by-side

Given the widget is rendered
When the layout settles
Then a `Row` SHALL contain two `Expanded` children
And one button SHALL display `'Excluir'`, the other `'Atualizar'`

#### Scenario: Delete button shows loading when isDeleting is true

Given `isDeleting: true, isLoading: false`
When the widget renders
Then the delete button SHALL show its loading indicator
And the update button SHALL be disabled (does not call onUpdate)

#### Scenario: Update button shows loading when isLoading is true

Given `isLoading: true, isDeleting: false`
When the widget renders
Then the update button SHALL show its loading indicator
And the delete button SHALL be disabled

---

### Requirement: BudgetScreen — dynamic between create and edit modes

The system SHALL refactor `lib/src/presentation/ui/budget/screens/budget_screen.dart` to:

- Accept `final int? id;` (NOT `BudgetModel?`) on the constructor.
- Be a `StatelessWidget` with an internal `Consumer` (NEVER `ConsumerWidget`).
- Listen to `budgetFormProvider(id)` for status transitions:
  - On `success` (from non-success previous): `context.root()`.
  - On `failure` (from non-failure previous): `showToastWidget(context: ctx, title: 'Opps', type: failure, description: state.message)`.
- Watch `budgetFormProvider(id)` and switch on `AsyncValue<BudgetFormState>`:
  - `AsyncLoading()` → centered loading widget (full-screen).
  - `AsyncError(:final error)` → failure widget with `'Tentar novamente'` button calling `ref.invalidate(budgetByIdProvider(id!))`.
  - `AsyncData(:final value)` → form layout:
    - Title: `value.id == null ? 'Novo orçamento' : 'Editar orçamento'`.
    - Subtitle: `value.id == null ? 'Preencha as informações...' : 'Atualize as informações do seu orçamento.'`.
    - Body: existing form fields (`BudgetAmountFieldWidget`, `BudgetDescriptionFieldWidget`, `BudgetDateFieldWidget`) bound to `value.*`.
    - Footer:
      - `value.id == null` → `BudgetSaveButtonWidget(label: 'Cadastrar', isLoading: value.status == .loading, onSave: () { hideKeyboard(); notifier.dispatch(const SubmitPressed()); })`.
      - `value.id != null` → `BudgetEditActionsWidget(isLoading: value.status == .loading, isDeleting: value.isDeleting, onUpdate: () { hideKeyboard(); notifier.dispatch(const SubmitPressed()); }, onDelete: () async { hideKeyboard(); final confirmed = await showConfirmDialog(context: context, title: 'Excluir orçamento', description: 'Esta ação não pode ser desfeita.', confirmLabel: 'Excluir', destructive: true); if (!confirmed) return; notifier.dispatch(const DeletePressed()); })`.

The screen SHALL NOT use `ConsumerWidget` (project rule). The screen SHALL NOT read `moneyServiceProvider` or any other service provider directly (project rule — services flow through the notifier).

#### Scenario: Constructor accepts only int? id

Given the new `BudgetScreen` is parsed
Then its constructor SHALL declare `final int? id;` and SHALL NOT declare any field of type `BudgetModel?`

#### Scenario: AsyncLoading renders loading widget

Given `budgetFormProvider(9)` is `AsyncLoading`
When the screen builds
Then a centered loading indicator SHALL render
And the form fields SHALL NOT render

#### Scenario: AsyncError renders retry

Given `budgetFormProvider(9)` is `AsyncError(NotFoundFailure)`
When the screen builds and the user taps `'Tentar novamente'`
Then `ref.invalidate(budgetByIdProvider(9))` SHALL be called

#### Scenario: AsyncData(create) renders save button

Given `budgetFormProvider(null)` is `AsyncData(BudgetFormState(id: null, ...))`
When the screen builds
Then the title SHALL read `'Novo orçamento'`
And the footer SHALL render `BudgetSaveButtonWidget` (single button)

#### Scenario: AsyncData(edit) renders edit actions

Given `budgetFormProvider(9)` is `AsyncData(BudgetFormState(id: 9, value: ..., ...))`
When the screen builds
Then the title SHALL read `'Editar orçamento'`
And the footer SHALL render `BudgetEditActionsWidget` (two buttons)

#### Scenario: Delete tap shows confirmation dialog

Given the screen is in edit mode and the user taps the delete button
When the `onDelete` handler runs
Then `showConfirmDialog` SHALL be called with `title: 'Excluir orçamento', description: 'Esta ação não pode ser desfeita.', confirmLabel: 'Excluir', destructive: true`

#### Scenario: Confirmed delete dispatches DeletePressed

Given `showConfirmDialog` resolves to `true`
When the handler continues
Then `notifier.dispatch(const DeletePressed())` SHALL be invoked

#### Scenario: Cancelled delete does not dispatch

Given `showConfirmDialog` resolves to `false`
When the handler continues
Then `notifier.dispatch(const DeletePressed())` SHALL NOT be invoked
And no network request SHALL be made

---

### Requirement: BudgetSaveButtonWidget — parametric label

The system SHALL extend `lib/src/presentation/ui/budget/widgets/budget_save_button_widget.dart` to accept `final String label;` in its constructor (mirroring `ExpenseSaveButtonWidget`).

If the current implementation has `'Salvar'` hardcoded, it SHALL be replaced by the `label` parameter. The `BudgetScreen` SHALL pass `'Cadastrar'` (consistent with Expense's create label) when in create mode.

#### Scenario: Label is propagated to the button

Given `BudgetSaveButtonWidget(label: 'Cadastrar', isLoading: false, onSave: cb)`
When the widget renders
Then a button with text `'Cadastrar'` SHALL appear

---

### Requirement: BudgetListItemWidget becomes tappable

The system SHALL update `lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart` to accept `final VoidCallback? onTap;`.

When `onTap != null`, the body SHALL be wrapped in `BounceWidget.withOnPress(onPress: onTap!, child: <body>)`. When `onTap == null`, the body SHALL render unwrapped.

This change supersedes the previous `budgets` capability requirement that stated "the widget SHALL NOT be tappable" — that restriction is lifted because there is now a destination (`BudgetLocation(id: budget.id)`).

#### Scenario: Tapping the item invokes onTap

Given `BudgetListItemWidget(item: ..., onTap: cb)`
When the user taps the rendered item
Then `cb` SHALL fire

#### Scenario: Without onTap, taps do nothing

Given `BudgetListItemWidget(item: ...)` (no onTap)
When the user taps the rendered item
Then no callback SHALL fire and the item SHALL render unwrapped

---

### Requirement: BudgetsScreen wires onTap on items and active card

The system SHALL update `lib/src/presentation/ui/budgets/screens/budgets_screen.dart` to:

- Pass `onTap: () => <navigate to BudgetLocation(id: budget.id)>` to each `BudgetListItemWidget` (via the `BudgetsListWidget` wiring) AND to the `BudgetCardSuccessWidget` (active card on top).
- The navigation callback SHALL be received by the screen via parameter from the Location (a `void Function(int id)` injected by `BudgetsLocation` — Locations-compose-navigation exception).

The screen SHALL NOT import `BudgetLocation` directly (encapsulation rule). The Location is the only place authorized to compose navigation.

#### Scenario: Active card tap navigates to edit

Given `BudgetsScreen` is rendered with a non-null `activeItem` and the user taps the active card
Then the screen SHALL invoke the injected navigation callback with `activeItem.budget.id`
And the callback (composed in `BudgetsLocation`) SHALL fire `context.navigate(BudgetLocation(id: <id>))`

#### Scenario: List item tap navigates to edit

Given `BudgetsScreen` is rendered with `items: [item1 with id 5, item2 with id 7]` and the user taps `item2`
Then the screen SHALL invoke the navigation callback with id 7

#### Scenario: Screen does not import BudgetLocation

Given the file `lib/src/presentation/ui/budgets/screens/budgets_screen.dart`
When `grep "BudgetLocation" <file>` is executed
Then the result SHALL be empty

---

### Requirement: BudgetLocation accepts int? id

The system SHALL update `lib/src/presentation/ui/budget/locations/budget_location.dart`:

- Trade `const BudgetLocation()` (no params) for `const BudgetLocation({this.id})` with `final int? id;`.
- `pageBuilder` SHALL pass `id: id` to `BudgetScreen`.
- The existing navigation callbacks (calculator, date) remain — they SHALL continue to be composed inside the Location's `pageBuilder` and SHALL NOT depend on `id`.

#### Scenario: Create flow passes null id

Given `BudgetLocation()` is constructed (no args)
When the page builds
Then `BudgetScreen(id: null, ...)` SHALL be created

#### Scenario: Edit flow passes int id

Given `BudgetLocation(id: 9)` is constructed
When the page builds
Then `BudgetScreen(id: 9, ...)` SHALL be created

---

### Requirement: BudgetsLocation composes navigation to BudgetLocation

The system SHALL update `lib/src/presentation/ui/budgets/locations/budgets_location.dart` to inject the navigation callback into `BudgetsScreen` (via parameter), and the callback inside SHALL fire `context.navigate(BudgetLocation(id: <id>))`.

`BudgetsLocation` is the only file in the `budgets/` feature authorized to import `BudgetLocation` (Locations-compose-navigation exception per CLAUDE.md).

#### Scenario: BudgetsLocation imports BudgetLocation

Given the file `lib/src/presentation/ui/budgets/locations/budgets_location.dart`
When `grep "BudgetLocation" <file>` is executed
Then the result SHALL contain at least one import of `BudgetLocation`

#### Scenario: Other budgets/ files do not import BudgetLocation

Given any file under `lib/src/presentation/ui/budgets/` that is not the Location
When `grep -rl "BudgetLocation" lib/src/presentation/ui/budgets/` is executed
Then the result SHALL only include `budgets_location.dart`

---

### Requirement: API contract — PATCH/DELETE/GET by id

The system SHALL consume:

- `PATCH /api/v1/budgets/{id}` with `Authorization: Bearer <token>`, `Content-Type: application/json`, body `{ value: "12000.00", start_date: "2026-05-01", end_date: "2026-05-30", description: "May budget" }` (full payload accepted; backend tolerates the same shape used in POST). Response 200 returns `BudgetResponse` (same schema as GET).
- `DELETE /api/v1/budgets/{id}` with `Authorization: Bearer <token>`. Response 204 with **empty body**. The datasource SHALL NOT attempt to deserialize a body for 204.
- `GET /api/v1/budgets/{id}` with `Authorization: Bearer <token>`. Response 200 returns `BudgetResponse`. **To be confirmed in tasks 1.1**: if the endpoint does not exist, `budgetByIdProvider` SHALL operate cache-only and the deep-link case fails with `NotFoundFailure` controlled.

Errors for all three follow the standard `FailureResponse` shape `{ errors: [{ field, message, code }] }`.

#### Scenario: PATCH success response

Given `PATCH /api/v1/budgets/9` returns 200 with `{id: 9, value: "12000.00", start_date: "2026-05-01", end_date: "2026-05-30", description: "May budget", total_spent: "285.50", remaining: "11714.50", created_at: "..."}`
When `repository.update` is called
Then the result SHALL be `Right(BudgetModel(id: 9, value: 1200000, ...))`

#### Scenario: DELETE success returns 204 with empty body

Given `DELETE /api/v1/budgets/9` returns 204
When `repository.delete` is called
Then the result SHALL be `Right(null)`
And no JSON deserialization SHALL be attempted on the empty body

---

### Requirement: Tests

The change SHALL include test coverage in the following test files. All `test()`, `group()`, `testWidgets()` descriptions SHALL be in **English**. Mocks SHALL be declared by the interface type (e.g. `late IBudgetRepository repository;`). Variable names SHALL NOT be `result` or `either` — use `data` or the concept name. `var` SHALL NOT be used.

**`BudgetRepository` (mock `IHttpClient`) — `test/src/data/repositories/budget_repository_test.dart`:**

- `update` (group):
  - `test('returns Right(BudgetModel) when PATCH /api/v1/budgets/<id> succeeds with 200')` — value `"12000.00"` → `1200000` centavos.
  - `test('sends body serialized via BudgetRequest with value, startDate, endDate, description')`.
  - `test('returns Left(ValidationFailure) when PATCH returns 400 with errors body')`.
  - `test('returns Left(NetworkFailure) when PATCH fails with network error')`.
  - `test('returns Left(ServerFailure) when PATCH returns 5xx')`.
  - `test('returns Left(NotFoundFailure) when PATCH returns 404')`.
- `delete` (group):
  - `test('returns Right(null) when DELETE /api/v1/budgets/<id> returns 204 with empty body')`.
  - `test('sends DELETE with no body')`.
  - `test('returns Left(NetworkFailure) when DELETE fails with network error')`.
  - `test('returns Left(NotFoundFailure) when DELETE returns 404')`.
- `findById` (group):
  - `test('returns Right(BudgetModel) when GET /api/v1/budgets/<id> succeeds')`.
  - `test('returns Left(NotFoundFailure) when GET returns 404')`.
  - `test('returns Left(NetworkFailure) on network error')`.

The existing tests for `findActive`, `findAll`, `create` SHALL continue to pass unchanged.

**`BudgetByIdNotifier` — `test/src/presentation/providers/budget_by_id_notifier_test.dart`:**

- `test('returns cached BudgetModel when id is in budgetsProvider items')` — `verifyNever(repository.findById)`.
- `test('returns cached BudgetModel when id matches activeItem')` — `verifyNever`.
- `test('falls back to repository.findById when not in cache')`.
- `test('falls back to repository.findById when budgetsProvider is AsyncLoading')`.
- `test('throws Failure when repository returns Left, surfacing AsyncError')`.

**`BudgetFormNotifier` (AsyncNotifier family) — `test/src/presentation/providers/budget_notifier_test.dart` (or new `budget_form_notifier_test.dart`):**

- `test('build(null) returns AsyncData with id null and default state')`.
- `test('build(id) awaits budgetByIdProvider and returns AsyncData with id, value, dates, description populated')`.
- `test('build(id) returns AsyncError when budgetByIdProvider throws')`.
- `test('SubmitPressed in create mode (id null) calls repository.create and not update')`.
- `test('SubmitPressed in edit mode (id non-null) calls repository.update with state.id and not create')`.
- `test('successful create invalidates budgets and activeBudget providers')`.
- `test('successful update invalidates budgets and activeBudget providers')`.
- `test('failed update sets status: failure with message, preserves form fields')`.
- `test('DeletePressed in create mode (id null) is a no-op')` — `verifyNever(repository.delete)`.
- `test('DeletePressed in edit mode toggles isDeleting and ends with status: success')`.
- `test('successful delete invalidates budgets and activeBudget providers')`.
- `test('failed delete sets status: failure with message, isDeleting back to false, form preserved')`.

**Widget tests (desejáveis):**

- `testWidgets('BudgetEditActionsWidget renders two buttons with Excluir and Atualizar labels')`.
- `testWidgets('BudgetEditActionsWidget disables update button while isDeleting is true')`.
- `testWidgets('BudgetEditActionsWidget disables delete button while isLoading is true')`.

#### Scenario: Coverage areas exist

Given the new test files
Then `test/src/data/repositories/budget_repository_test.dart` SHALL contain groups covering `update`, `delete`, and `findById`
And `test/src/presentation/providers/budget_by_id_notifier_test.dart` SHALL exist
And the `BudgetFormNotifier` test file SHALL include the AsyncNotifier family scenarios

#### Scenario: Test suite passes

Given the change has been implemented per `tasks.md`
When `flutter analyze && flutter test` runs
Then both SHALL succeed with zero errors

---
