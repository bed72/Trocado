# Spec — list-all-expenses

## Context

This change adds a dedicated screen that lists **all** user expenses with cursor-based infinite pagination. It **extends** the existing expense stack (already implemented for the Home's recent-expenses section: `ExpenseModel`, `ExpenseResponse`, `ExpensesResponse`, `ExpenseRepository.findRecent`, `RecentExpensesSectionWidget`, etc.) — it does **not** duplicate or replace any of it. The "Ver tudo" button on `RecentExpensesSectionWidget` (currently `onSeeAll: () {}` in `home_screen.dart`) is wired to navigate into this new screen.

The pagination strategy is **manual with Riverpod `AsyncNotifier`** (no third-party pagination packages). Performance is a first-class requirement: viewport-lazy rendering, keep-alive between navigations, guard against duplicate requests, and `ref.invalidate` (lazy) for pull-to-refresh.

---

## Requirements

### Requirement: Navigation from Home via "Ver tudo"
The system SHALL create an `ExpensesLocation` (a `duck_router` `Location`) at `lib/src/presentation/screens/expenses/expenses_location.dart` and register a new `AppRoutes.expenses` entry (path `/expenses`) in `lib/app_route.dart` (including `_all`).

The `onSeeAll` callback on `RecentExpensesSectionWidget` — currently `() {}` in `home_screen.dart` line ~95 — SHALL be replaced by `() => context.navigate(ExpensesLocation())`.

#### Scenario: User taps "Ver tudo" on Home
Given the user is on `HomeScreen`
When the user taps the "Ver tudo" `ButtonWidget.text` in `RecentExpensesSectionWidget`
Then `DuckRouter.navigate(ExpensesLocation())` SHALL be invoked
And the `ExpensesScreen` SHALL be pushed on top of the Home

---

### Requirement: Extend ExpensesResponse with cursor fields
The system SHALL extend `lib/src/infrastructure/clients/http/responses/expense/expenses_response.dart` to expose two new nullable fields: `next: String?` and `previous: String?`, read directly from the JSON keys `next` and `previous` (the raw URLs).

Cursor parsing SHALL NOT happen in the response — this layer keeps `fromJson` only, no `toModel`.

#### Scenario: fromJson with both cursors
Given a JSON `{ "next": "http://.../expenses?cursor=ABC", "previous": "http://.../expenses?cursor=XYZ", "results": [] }`
When `ExpensesResponse.fromJson(json)` is called
Then `next` SHALL equal `"http://.../expenses?cursor=ABC"` and `previous` SHALL equal `"http://.../expenses?cursor=XYZ"` as raw strings

#### Scenario: fromJson with null cursors
Given a JSON `{ "next": null, "previous": null, "results": [] }`
When parsed
Then both fields SHALL be `null`

---

### Requirement: ExpensesPageModel domain model
The system SHALL add `lib/src/domain/models/expense/expenses_page_model.dart` with an Equatable class `ExpensesPageModel` exposing:
- `List<ExpenseModel> expenses`
- `String? nextCursor`
- `String? previousCursor`
- `copyWith({ List<ExpenseModel>? expenses, String? nextCursor, String? previousCursor })`

`props` SHALL include all three fields.

#### Scenario: Equatable behavior
Given two `ExpensesPageModel` instances with identical fields
Then they SHALL be equal via `==`

---

### Requirement: Cursor extraction lives in data/extensions
The system SHALL add `ExpensesResponseExtension.toPageModel()` in `lib/src/data/extensions/expense_response_extension.dart` returning a `ExpensesPageModel`. Each `ExpenseResponse` SHALL be mapped via the existing `ExpenseResponseExtension.toModel()`. Cursors SHALL be extracted via `Uri.parse(url).queryParameters['cursor']` when the URL is non-null, otherwise `null`.

The existing `toModel()` on `ExpensesResponseExtension` (returning `List<ExpenseModel>` for `findRecent`) SHALL remain intact and continue to be used by `ExpenseRepository.findRecent`.

#### Scenario: toPageModel extracts cursor
Given `ExpensesResponse(next: "http://host/api/v1/expenses?cursor=ABC123", previous: null, expenses: [one, two])`
When `toPageModel()` is called
Then the result SHALL be `ExpensesPageModel(expenses: [oneModel, twoModel], nextCursor: "ABC123", previousCursor: null)`

#### Scenario: null cursors
Given `ExpensesResponse(next: null, previous: null, expenses: [])`
When `toPageModel()` is called
Then `nextCursor` and `previousCursor` SHALL be `null` and `expenses` SHALL be empty

---

### Requirement: Extend IRemoteExpenseDataSource and implementation with findAll
The system SHALL add `Future<Either<FailureResponse, ExpensesResponse>> findAll({String? cursor})` to `IRemoteExpenseDataSource` and implement it in `RemoteExpenseDataSource` (`lib/src/infrastructure/datasources/remote/remote_expense_data_source.dart`).

The implementation SHALL call:
```dart
_client.get(
  parameter: Requests(
    EndpointKey.expenses.path,
    query: cursor == null ? null : {'cursor': cursor},
  ),
)
```
and deserialize via `response.either(FailureResponse.fromJson, ExpensesResponse.fromJson)`. The interface accepts a primitive `String? cursor` — **no** DTO.

The existing `findRecent` and `create` methods SHALL remain untouched.

#### Scenario: First page (no cursor)
Given `findAll(cursor: null)` is invoked
When the implementation runs
Then `_client.get` SHALL be called with `Requests(EndpointKey.expenses.path)` **without** the `cursor` query param

#### Scenario: Subsequent page (with cursor)
Given `findAll(cursor: "ABC")` is invoked
Then `_client.get` SHALL be called with `Requests(EndpointKey.expenses.path, query: {'cursor': 'ABC'})`

---

### Requirement: Extend IExpenseRepository and ExpenseRepository with findAll
The system SHALL add `Future<Either<Failure, ExpensesPageModel>> findAll({String? cursor})` to `IExpenseRepository` and implement it in `ExpenseRepository` (`lib/src/data/repositories/expense_repository.dart`).

The implementation SHALL call `_dataSource.findAll(cursor: cursor)` and use `data.either((failure) => failure.toFailure(), (response) => response.toPageModel())`.

The existing `create` and `findRecent` methods SHALL remain unchanged.

#### Scenario: Success maps response to page model
Given the datasource returns `Right(ExpensesResponse)` with 3 expenses and a non-null `next`
When `ExpenseRepository.findAll(cursor: null)` is called
Then the repository SHALL return `Right(ExpensesPageModel)` with 3 mapped `ExpenseModel`s and `nextCursor != null`

#### Scenario: Failure mapping
Given the datasource returns `Left(FailureResponse)` with `code: "network_error"`
When `findAll` is called
Then the repository SHALL return `Left(NetworkFailure)`

---

### Requirement: ExpensesState (presentation)
The system SHALL add `lib/src/presentation/screens/expenses/notifiers/expenses_state.dart` with an Equatable class `ExpensesState`:
- `List<ExpenseModel> items` (default: `const []`)
- `String? nextCursor` (default: `null`)
- `bool isLoadingMore` (default: `false`)
- `Failure? loadMoreFailure` (default: `null`)

`copyWith` SHALL support overriding each field, and SHALL accept explicit `clearLoadMoreFailure: bool` and `clearNextCursor: bool` helpers so a `null` override genuinely means "clear the field" (the project's pattern for nullable fields in copyWith).

`props` SHALL include all four fields.

#### Scenario: Initial state defaults
Given a fresh `ExpensesState()`
Then `items` SHALL be empty, `nextCursor` SHALL be null, `isLoadingMore` SHALL be false, `loadMoreFailure` SHALL be null

---

### Requirement: ExpensesNotifier with keepAlive and cursor-based loadMore
The system SHALL add `lib/src/presentation/screens/expenses/notifiers/expenses_notifier.dart`, an `AsyncNotifier<ExpensesState>` annotated with `@Riverpod(keepAlive: true)`.

`build()` SHALL:
- Read `_repository` via `ref.watch(expenseRepositoryProvider)` with `late` (never `late final`).
- Call `await _repository.findAll(cursor: null)`.
- On `Right(page)`: return `ExpensesState(items: page.expenses, nextCursor: page.nextCursor)`.
- On `Left(failure)`: rethrow `failure` so the provider transitions to `AsyncError`.

A public method `Future<void> loadMore()` SHALL:
1. Early-return if `state is! AsyncData<ExpensesState>`.
2. Early-return if `state.value.isLoadingMore == true`.
3. Early-return if `state.value.nextCursor == null`.
4. Set `state = AsyncData(state.value.copyWith(isLoadingMore: true, clearLoadMoreFailure: true))`.
5. Call `_repository.findAll(cursor: state.value.nextCursor)`.
6. On `Right(page)`: `state = AsyncData(state.value.copyWith(items: [...state.value.items, ...page.expenses], nextCursor: page.nextCursor, isLoadingMore: false))`.
7. On `Left(failure)`: `state = AsyncData(state.value.copyWith(isLoadingMore: false, loadMoreFailure: failure))` — items are preserved.

Pull-to-refresh SHALL be triggered **by the screen** via `ref.invalidate(expensesProvider)` — **never** `ref.refresh`. With `keepAlive: true`, only `invalidate` rebuilds the state.

#### Scenario: Initial build success
Given the repository returns `Right(ExpensesPageModel(expenses: [a, b, c], nextCursor: "X"))`
When the notifier builds
Then the provider SHALL transition to `AsyncData(ExpensesState(items: [a, b, c], nextCursor: "X", isLoadingMore: false, loadMoreFailure: null))`

#### Scenario: Initial build failure
Given the repository returns `Left(NetworkFailure)`
When the notifier builds
Then the provider SHALL transition to `AsyncError` with an error of type `NetworkFailure`

#### Scenario: loadMore appends items on success
Given state is `AsyncData(items: [a, b], nextCursor: "X", isLoadingMore: false)` and the repository returns `Right(page(expenses: [c, d], nextCursor: "Y"))`
When `loadMore()` is invoked
Then state transitions through `isLoadingMore: true` and ends at `AsyncData(items: [a, b, c, d], nextCursor: "Y", isLoadingMore: false, loadMoreFailure: null)`

#### Scenario: loadMore while already loading is a no-op
Given state is `AsyncData(isLoadingMore: true, nextCursor: "X")`
When `loadMore()` is invoked
Then the repository SHALL NOT be called (`verifyNever`)

#### Scenario: loadMore at end of list is a no-op
Given state is `AsyncData(isLoadingMore: false, nextCursor: null)`
When `loadMore()` is invoked
Then the repository SHALL NOT be called

#### Scenario: loadMore failure preserves items and records failure
Given state is `AsyncData(items: [a, b], nextCursor: "X", isLoadingMore: false)` and the repository returns `Left(ServerFailure)`
When `loadMore()` is invoked
Then the final state SHALL be `AsyncData(items: [a, b], nextCursor: "X", isLoadingMore: false, loadMoreFailure: ServerFailure)`

#### Scenario: loadMore retry after failure
Given state is `AsyncData(items: [a, b], nextCursor: "X", loadMoreFailure: ServerFailure)` and repository now returns `Right(page(expenses: [c], nextCursor: null))`
When `loadMore()` is invoked
Then the final state SHALL be `AsyncData(items: [a, b, c], nextCursor: null, isLoadingMore: false, loadMoreFailure: null)`

#### Scenario: Pull-to-refresh via invalidate
Given state is populated with items
When `ref.invalidate(expensesProvider)` is called
Then the provider SHALL transition to `AsyncLoading` and re-invoke `findAll(cursor: null)`

---

### Requirement: ExpenseGroupsBuilder (pure date grouping)
The system SHALL add `lib/src/presentation/screens/expenses/helpers/expense_groups_builder.dart` containing a pure top-level function:

```dart
List<ExpenseGroup> buildExpenseGroups(List<ExpenseModel> expenses, {DateTime? now})
```

A sealed-or-union structure SHALL represent a group:
```dart
final class ExpenseGroup {
  final String header;
  final List<ExpenseModel> expenses;
  const ExpenseGroup({ required this.header, required this.expenses });
}
```

Grouping key SHALL be the day portion of `ExpenseModel.date` (milliseconds → `DateTime` → truncated to year/month/day). The header text SHALL follow these rules (`now` defaults to `DateTime.now()`; compared by year/month/day truncation):

- Same day as `now` → `"Hoje"`
- Previous day → `"Ontem"`
- Within the current calendar week of `now` and not today/yesterday → weekday name capitalized, comma, then `dd MMM` lowercase (e.g. `"Terça, 15 abr"`), via `intl` `pt_BR`
- Older than the current week → `"MMMM yyyy"` with month capitalized (e.g. `"Março 2026"`), via `intl` `pt_BR`

Ordering SHALL preserve input order (the API returns descending). Groups SHALL be emitted in the order the first item of each group appears.

#### Scenario: Today and yesterday are grouped distinctly
Given `expenses = [e(today, 18:00), e(today, 10:00), e(yesterday, 20:00)]` and `now = today at 22:00`
When `buildExpenseGroups(expenses, now: now)` runs
Then the result SHALL be `[ExpenseGroup("Hoje", [e1, e2]), ExpenseGroup("Ontem", [e3])]`

#### Scenario: Within the week
Given an expense whose `date` is 3 days before `now` (same week) on a Tuesday, April 15
When grouped
Then the header SHALL be `"Terça, 15 abr"`

#### Scenario: Older than the week
Given an expense whose `date` is in March 2026 and `now` is in April 2026
When grouped
Then the header SHALL be `"Março 2026"`

#### Scenario: Empty list
Given an empty input list
Then the result SHALL be an empty list

---

### Requirement: ExpensesScreen layout
The system SHALL add `lib/src/presentation/screens/expenses/screens/expenses_screen.dart` as a `StatelessWidget` with a `Consumer` internal builder (**never** `ConsumerWidget`).

The scaffold SHALL contain:
- `AppBar` with only a `GoBackWidget` as the leading action; no title; elevation 0; matching other "detail" screens in the app.
- `body` inside `SafeArea`, a `Column` containing:
  1. Padding with `ScreenHeaderWidget(title: "Despesas", description: "Acompanhe todas as suas despesas.")` — final copy confirmed via open question 1.
  2. A `Row` with `MainAxisAlignment.end` containing the `ExpensesFilterButtonWidget` (icon-only button, no-op).
  3. `Expanded` holding the scrollable list region:
     - On `AsyncLoading` → `ExpensesLoadingWidget` (Skeletonizer with ~6 placeholder `ExpenseItemWidget`s).
     - On `AsyncError` → `ExpensesFailureWidget` with copy + retry via `ref.invalidate(expensesProvider)`.
     - On `AsyncData` with `state.items.isEmpty` → `ExpensesEmptyWidget`.
     - On `AsyncData` with items → `RefreshIndicator` wrapping `ExpensesListWidget(state: state, groups: buildExpenseGroups(state.items))`.

The whole screen SHALL read `final state = ref.watch(expensesProvider)` and `final moneyService = ref.watch(moneyServiceProvider)` in a single `Consumer`.

#### Scenario: Screen renders each AsyncValue case correctly
Given the provider emits `AsyncLoading`, `AsyncError`, `AsyncData(empty)`, and `AsyncData(non-empty)` sequentially
When the screen rebuilds on each
Then the corresponding widget SHALL render (loading skeleton / failure / empty / list)

---

### Requirement: ExpensesListWidget with cursor-driven loadMore
The system SHALL add `lib/src/presentation/screens/expenses/widgets/expenses_list_widget.dart`, a `StatefulWidget` (required for owning a `ScrollController`).

It SHALL:
- Own a `ScrollController` attached to a `CustomScrollView`.
- Build slivers from `groups`: for each group, one `SliverToBoxAdapter` with `ExpensesDateHeaderWidget` + one `SliverList.builder` with `ExpenseItemWidget` per expense (using `ValueKey(expense.id)`).
- After all groups, append a trailing sliver that reflects the tail state:
  - If `state.isLoadingMore == true` → `ExpensesLoadMoreLoadingWidget`.
  - Else if `state.loadMoreFailure != null` → `ExpensesLoadMoreFailureWidget(onRetry: () => ref.read(expensesProvider.notifier).loadMore())`.
  - Else if `state.nextCursor == null` → `SliverToBoxAdapter(child: SizedBox.shrink())` (end of list; no extra UI).
  - Else → `SliverToBoxAdapter(child: SizedBox.shrink())` (idle; load triggered by scroll).
- Use a `ScrollController.addListener` callback that, on each event, checks `position.pixels >= position.maxScrollExtent - 200` and calls `ref.read(expensesProvider.notifier).loadMore()` (the notifier has its own guards against duplicates).
- Dispose the `ScrollController` in `dispose()`.
- Be wrapped by the screen in a `RefreshIndicator` whose `onRefresh: () async => ref.invalidate(expensesProvider)`.

Items, headers and the trailing sliver SHALL all live in a single `CustomScrollView` — no nested scrollables.

#### Scenario: Near-bottom scroll triggers loadMore
Given the list is scrolled such that `position.pixels >= position.maxScrollExtent - 200`
When the scroll listener fires
Then `ref.read(expensesProvider.notifier).loadMore()` SHALL be called

#### Scenario: Rapid scroll does not duplicate requests
Given multiple near-bottom events fire while `isLoadingMore == true`
Then only one call to the repository SHALL occur (guard is inside the notifier)

#### Scenario: Trailing sliver reflects tail state
Given `isLoadingMore == true` → trailing renders `ExpensesLoadMoreLoadingWidget`
Given `loadMoreFailure != null` → trailing renders `ExpensesLoadMoreFailureWidget`
Given `nextCursor == null` and no failure and not loading → trailing renders `SizedBox.shrink` (no extra UI at end)

---

### Requirement: Tail widgets (load-more loading and failure)
The system SHALL add:

- `expenses_load_more_loading_widget.dart` — a `StatelessWidget` centering a `CircularProgressIndicatorWidget` with vertical padding 16.
- `expenses_load_more_failure_widget.dart` — a `StatelessWidget` accepting `VoidCallback onRetry`, rendering a `Column` centered with:
  - `Text("Não foi possível carregar mais despesas.", context.typography.bodySmall, color: context.colors.onSurfaceVariant)`
  - `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)`
  - Vertical padding 16.

Both widgets SHALL be wrapped in `SliverToBoxAdapter` at the use site (the widgets themselves are plain widgets).

#### Scenario: Retry triggers loadMore
Given the failure widget is rendered and the user taps the retry button
Then `onRetry` SHALL be invoked, which (per the list widget wiring) calls `loadMore()`

---

### Requirement: First-page empty and failure widgets
The system SHALL add:

- `expenses_empty_widget.dart` — a `StatelessWidget` with a centered `Column`: `BackgroundIconWidget(icon: Icons.receipt_long_outlined, color: context.colors.primary)` + `Text("Sem despesas registradas ainda", titleMedium bold)` + `Text("Quando você registrar despesas elas aparecerão aqui.", bodySmall onSurfaceVariant)` — mirrors `RecentExpensesEmptyWidget` tone.
- `expenses_failure_widget.dart` — a `StatelessWidget` accepting `VoidCallback onRetry`, with `BackgroundIconWidget(icon: Icons.error_outline, color: context.colors.error)` + `Text("Não foi possível carregar as despesas.", titleMedium bold)` + `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)` — mirrors `RecentExpensesFailureWidget`.

Final copy SHALL be validated by the user in open question 2.

#### Scenario: Empty widget on empty first page
Given `AsyncData(ExpensesState(items: []))`
Then `ExpensesEmptyWidget` SHALL render inside the screen (no list, no filter bar navigation breakage)

---

### Requirement: Filter button (visual only)
The system SHALL add `expenses_filter_button_widget.dart` — a `StatelessWidget` rendering an `IconButtonWidget` with:
- `icon: Icons.tune_outlined` (proposal; the spec confirms default)
- `onPress: () {}` (no-op in this change)
- Using the standard `BackgroundIconWidget` defaults (size 48, `cornerRadius100`, `context.colors.primary` tint).

Real filtering is **out of scope**.

#### Scenario: Tapping the filter button does nothing
Given the user taps the filter button
Then no state change or navigation SHALL happen (confirmed by `verifyNever` on the repository in a widget test if one exists)

---

### Requirement: Loading skeleton for initial load
The system SHALL add `expenses_loading_widget.dart` — a `StatelessWidget` accepting `IMoneyService moneyService` (for the placeholder `ExpenseItemWidget`) and rendering a `Skeletonizer` wrapping a `Column` of **12** placeholder `ExpenseItemWidget`s, mirroring the pattern already used in `RecentExpensesLoadingWidget`.

#### Scenario: Initial load shows skeleton
Given the provider is in `AsyncLoading`
Then the skeleton list SHALL render with 12 shimmering placeholder items

---

### Requirement: API contract
`GET /api/v1/expenses` — requires Bearer token.

Query params:
- `cursor` (string, optional) — absent on the first page.

Response (200):
```json
{
  "next": "http://host/api/v1/expenses?cursor=cD0yMDI2...",
  "previous": "http://host/api/v1/expenses?cursor=cj0xJnA9...",
  "results": [
    {
      "id": 129,
      "value": "85.50",
      "description": "Cafezinho com o meu amor",
      "date": "2026-04-15",
      "created_at": "2026-04-22T11:45:03.220605-03:00",
      "category": "food"
    }
  ]
}
```

Error format: `{ "errors": [{ "field", "message", "code" }] }` — standard `FailureResponse`.

The cursor value SHALL always be extracted from the URL via `Uri.parse(url).queryParameters['cursor']` and sent back to the client as `query: {'cursor': value}` on the next request — the full URL SHALL never be passed to `IHttpClient`.

---

### Requirement: Performance constraints
- Viewport-lazy rendering via `SliverList.builder`.
- Near-bottom detection threshold: 200px before `maxScrollExtent`.
- Duplicate-request guard inside the notifier (`isLoadingMore`).
- `@Riverpod(keepAlive: true)` so navigating away and back does not refetch.
- `Equatable.props` covers every field of `ExpensesState` so identical `copyWith`s don't trigger rebuilds.
- `ValueKey(expense.id)` on every `ExpenseItemWidget` for efficient diffing.
- `const` constructors on every pure widget.
- `ref.invalidate(expensesProvider)` — never `ref.refresh` — for pull-to-refresh.
- No `state = ...` inside the scroll listener without passing through the notifier's guards.

---

### Requirement: Clean Architecture layering
- `domain/` adds `ExpensesPageModel`; extends `IExpenseRepository` with `findAll`. Zero Flutter, zero infrastructure imports.
- `infrastructure/` extends `ExpensesResponse` (`fromJson` only) and `IRemoteExpenseDataSource`.`findAll`. Still no `toModel` on responses.
- `data/` extends `ExpenseRepository.findAll` and adds `ExpensesResponseExtension.toPageModel()` with cursor extraction via `Uri.parse`.
- `presentation/` adds `ExpensesNotifier` (`AsyncNotifier` with `keepAlive: true`), `ExpensesState`, `ExpensesScreen`, `ExpensesLocation`, the grouping helper, and all state widgets under `presentation/screens/expenses/widgets/`.
- `main/` only adds the new `AppRoutes.expenses` entry; the notifier provider is auto-generated by `@riverpod`; `expenseRepositoryProvider` already exists.

No `ConsumerWidget` anywhere. All dependencies arrive via `ref.watch` in the notifier's `build()`, marked `late` (never `late final`). Every switch is an expression. No `var`. No private widget classes inside widget files — extract to their own files.

---

### Requirement: Tests

#### ExpensesResponse.fromJson (pure Dart)
- JSON with non-null `next` and `previous` → both exposed as `String` on the response.
- JSON with null `next` and `previous` → both `null`.
- JSON with non-empty `results` → `expenses` has correct length.
- JSON with empty `results` → `expenses` is empty.

#### ExpensesResponseExtension.toPageModel (covered via repository tests)
- Covered through `ExpenseRepository.findAll` tests that assert `nextCursor` extraction.
- Unknown/malformed `next` (no `cursor` query param) → `nextCursor == null` without throwing.

#### ExpenseRepository.findAll (mock `IHttpClient`)
- First page (no cursor) → GET called with `Requests(EndpointKey.expenses.path)` (no cursor in query).
- Subsequent page (cursor "ABC") → GET called with `Requests(EndpointKey.expenses.path, query: {'cursor': 'ABC'})`.
- Success with 3 expenses + non-null `next` → `Right(ExpensesPageModel(expenses: List.length=3, nextCursor: extracted))`.
- Success with empty results + null next/previous → `Right(ExpensesPageModel(expenses: [], nextCursor: null, previousCursor: null))`.
- Error `code: "network_error"` → `Left(NetworkFailure)`.
- Error `code: "server_error"` → `Left(ServerFailure)`.
- Error `code: "not_found"` → `Left(NotFoundFailure)`.
- Unknown `code` with message → `Left(ValidationFailure(message))`.
- `findRecent` regression tests SHALL continue to pass unchanged.

#### ExpensesNotifier (mock `IExpenseRepository`, `ProviderContainer`)
- Initial build success → `AsyncData` with expected state.
- Initial build failure → `AsyncError` typed correctly.
- `loadMore` happy path appends items and updates `nextCursor`.
- `loadMore` when `isLoadingMore == true` → `verifyNever` on repository.
- `loadMore` when `nextCursor == null` → `verifyNever` on repository.
- `loadMore` failure preserves items and sets `loadMoreFailure`.
- `loadMore` retry after failure clears `loadMoreFailure` on success.
- `ref.invalidate` → provider returns to `AsyncLoading` and refetches page 1.
- Test descriptions in English.

#### ExpenseGroupsBuilder (pure Dart)
- Empty list → empty output.
- All today → single `"Hoje"` group.
- Today + yesterday → two groups in that order.
- Current week (not today/yesterday) → `"Terça, 15 abr"` format.
- Previous month → `"Março 2026"` format.
- Input order preserved.

#### Mocks
- `test/mocks/mocks.dart` already has `MockExpenseRepository` — no new mocks required.

---

## Out of scope

- Real filter logic (filter by category, by date range, by value). Only a no-op visual button is delivered here; filter UX is a separate change.
- Textual search on the expense list.
- Edit / delete of an expense from this screen.
- Multi-select, sharing, exporting.
- Custom entrance/exit animations beyond `RefreshIndicator` and native scroll physics.
- Backend changes.
- Adding any external pagination package (`infinite_scroll_pagination` etc.) — this is a hard constraint from the design discussion.
- Rewriting `findRecent`, `RecentExpensesNotifier`, `RecentExpensesSectionWidget`, or any existing `create-expense` code.
- Sticky headers (`SliverStickyHeader` or equivalent) — headers scroll with content in this version.
- Deep linking to `ExpensesLocation` from external URLs.

---

## Decisions (approved)

- **Header copy**: title `"Despesas"` / description `"Acompanhe todas as suas despesas."`
- **Empty state**: title `"Sem despesas registradas ainda"` / description `"Quando você registrar despesas elas aparecerão aqui."`
- **Failure state (first page)**: title `"Não foi possível carregar as despesas."`
- **Load-more failure**: `"Não foi possível carregar mais despesas."`
- **Filter icon**: `Icons.tune_outlined`.
- **Route path**: `/expenses` (added to `AppRoutes`, included in `_all`).
- **Grouping header (current week, not today/yesterday)**: `"Terça, 15 abr"` (weekday capitalized, comma, day + short month lowercase).
- **Grouping header (older months)**: `"Março 2026"` (month capitalized + year).
- **Skeleton item count** on initial load: **12**.
- **Near-bottom threshold**: 200px before `maxScrollExtent`.
