# Spec — list-all-budgets

## Context

The Budget feature today exposes only two affordances: an active-budget card on the Home (`BudgetCardWidget` reading `IBudgetRepository.findActive`) and a creation form (`BudgetLocation`). There is no place in the app where the user can browse historical or future budgets — the temporal continuity of budgets is invisible.

This change adds a dedicated screen that lists **all** budgets with cursor-based infinite pagination, mirroring the consolidated pattern already in production for `ExpensesScreen` (`ExpensesNotifier` / `ExpensesPageModel` / `ExpensesResponse` / `ExpensesResponseExtension._cursorFrom`). The active budget — the one whose `[startDate, endDate]` covers `DateTime.now()` — is rendered at the top using the same rich `BudgetCardWidget` already used on Home; the remaining budgets render as simpler `BudgetListItemWidget`s in an infinite list below.

The pagination strategy is **manual with Riverpod `AsyncNotifier`** (no third-party pagination packages — same hard constraint as `list-all-expenses`). Performance is a first-class requirement: viewport-lazy rendering, `keepAlive` between navigations, guard against duplicate requests, and `ref.invalidate` (lazy) for pull-to-refresh.

The entry point is the existing `BudgetCardWidget` on the Home: it gains a `VoidCallback? onTap` that navigates to the new `BudgetsLocation`. To enable that without violating the project's feature-encapsulation rule, the entire `home/widgets/budget/card/` folder is **promoted** to `presentation/widgets/budget/card/`.

`BudgetModel` is extended with `totalSpent`, `remaining` and `createdAt` (the API returns these fields for every budget, not just the active one). `BudgetResponse.fromJson` is extended in lockstep. `ActiveBudgetModel` and `ActiveBudgetNotifier` are **not** removed — the eventual deduplication is a separate change.

---

## ADDED Requirements

### Requirement: Navigation from Home via BudgetCardWidget tap

The system SHALL add a `final VoidCallback? onTap;` parameter to `BudgetCardWidget` and `BudgetCardSuccessWidget` (after both files have been moved to `lib/src/presentation/widgets/budget/card/`).

The `BudgetCardSuccessWidget` SHALL wrap its body in `BounceWidget.withOnPress(onPress: onTap!, child: <body>)` when `onTap != null`, and render the body unwrapped when `onTap == null`. Loading, empty and failure states of the card SHALL NOT be tappable.

The system SHALL add `final VoidCallback navigateToBudgets;` (named, required) to `HomeScreen`, and pass it as the `onTap` of the `BudgetCardWidget`.

`HomeLocation` SHALL inject `navigateToBudgets: () => context.navigate(BudgetsLocation())` when constructing `HomeScreen`. `HomeLocation` is the only place authorised to import `BudgetsLocation` (Locations composing navigation is the documented exception to feature encapsulation).

#### Scenario: Tapping the active budget card opens the list

Given the user is on `HomeScreen`
And `BudgetCardWidget` is in the success state with a non-null `onTap`
When the user taps the card
Then `BounceWidget.withOnPress` SHALL fire `onTap`
And `DuckRouter.navigate(BudgetsLocation())` SHALL be invoked

#### Scenario: Tapping the card in non-success states does nothing

Given `BudgetCardWidget` is rendering its loading, empty or failure variant
When the user taps the card area
Then no callback SHALL fire and no navigation SHALL occur

---

### Requirement: AppRoutes.budgets entry

The system SHALL add a `budgets` entry to `AppRoutes` in `lib/app_route.dart` with `path: '/budgets'`, `name: 'budgets-route'`, and a regex matching exactly `/budgets`. The entry SHALL be included in `AppRoutes._all`.

#### Scenario: Route is registered

Given the app starts
Then `AppRoutes.budgets.path` SHALL equal `'/budgets'`
And `AppRoutes._all` SHALL contain the `budgets` entry

---

### Requirement: BudgetCardWidget moved to shared widgets folder

The system SHALL move the entire folder `lib/src/presentation/ui/home/widgets/budget/card/` (containing `budget_card_widget.dart`, `budget_card_success_widget.dart`, `budget_card_loading_widget.dart`, `budget_card_failure_widget.dart`, `budget_card_empty_widget.dart`, `budget_card_label_widget.dart`, `budget_progress_bar_painter.dart`) to `lib/src/presentation/widgets/budget/card/`.

All existing imports of these files (in `HomeScreen`, previews, tests, etc.) SHALL be updated to point at the new path. No file SHALL remain at the old location.

#### Scenario: Old imports are gone

Given the move is complete
When `grep -r "presentation/ui/home/widgets/budget/card" lib test` is executed
Then the result SHALL be empty

#### Scenario: New imports resolve

Given any file that previously imported `BudgetCardWidget`
When `flutter analyze` runs
Then it SHALL report zero errors related to missing imports

---

### Requirement: Extend BudgetModel with totalSpent, remaining and createdAt

The system SHALL extend `lib/src/domain/models/budget/budget_model.dart` with three new fields:

- `final int totalSpent;` — amount already spent against the budget, in centavos.
- `final int remaining;` — `value - totalSpent`, in centavos. **MAY be negative** when the budget is overspent.
- `final int createdAt;` — milliseconds since epoch.

The constructor, `copyWith` and `props` SHALL include these fields.

If the verification task in `tasks.md §1` reveals that `POST /api/v1/budgets` does **not** return these fields, the three SHALL be made nullable (`int?`) and `BudgetResponse` SHALL declare them as `String?`.

#### Scenario: Equatable behavior with new fields

Given two `BudgetModel` instances with identical fields including the three new ones
Then they SHALL be equal via `==`

#### Scenario: copyWith preserves and overrides

Given `final budget = BudgetModel(... totalSpent: 100, remaining: 900 ...)`
When `final updated = budget.copyWith(remaining: 800)`
Then `updated.remaining` SHALL equal `800` and `updated.totalSpent` SHALL equal `100`

---

### Requirement: BudgetsPageModel domain model

The system SHALL add `lib/src/domain/models/budget/budgets_page_model.dart` with an `Equatable` class `BudgetsPageModel` exposing:

- `String? nextCursor`
- `String? previousCursor`
- `List<BudgetModel> budgets` (default `const []`)
- `copyWith({ String? nextCursor, String? previousCursor, List<BudgetModel>? budgets })`

`props` SHALL include all three fields. The class SHALL **NOT** be a generic wrapper over `T` — it is a concrete page model for budgets.

#### Scenario: Equatable behavior

Given two `BudgetsPageModel` instances with identical fields
Then they SHALL be equal via `==`

---

### Requirement: Extend BudgetResponse with totalSpent, remaining and createdAt

The system SHALL extend `lib/src/infrastructure/clients/http/responses/budget/budget_response.dart` to map three new JSON keys:

- `total_spent` → `String totalSpent`
- `remaining` → `String remaining`
- `created_at` → `String createdAt`

`fromJson` SHALL read all three. The response SHALL keep `fromJson` only — **never** a `toModel()` method (that mapping lives in `data/extensions/`).

If the verification task reveals `POST` does not return them, the three SHALL be `String?` with `??` defaults at the call site.

#### Scenario: fromJson maps the new fields as raw strings

Given a JSON `{ "id": 1, "value": "1000.00", "start_date": "2026-05-01", "end_date": "2026-05-30", "description": "May", "total_spent": "285.50", "remaining": "714.50", "created_at": "2026-05-02T17:58:42.119430-03:00" }`
When `BudgetResponse.fromJson(json)` is called
Then `totalSpent` SHALL equal `"285.50"`, `remaining` SHALL equal `"714.50"`, and `createdAt` SHALL equal `"2026-05-02T17:58:42.119430-03:00"` as raw strings

---

### Requirement: BudgetsResponse with cursor fields

The system SHALL add `lib/src/infrastructure/clients/http/responses/budget/budgets_response.dart` exposing:

- `String? next` — raw URL of the next page, read from JSON key `next`.
- `String? previous` — raw URL of the previous page, read from JSON key `previous`.
- `List<BudgetResponse> budgets` — read from JSON key `results`.

The response SHALL keep `fromJson` only. Cursor parsing SHALL NOT happen at this layer.

#### Scenario: fromJson with both cursors

Given a JSON `{ "next": "http://host/api/v1/budgets?cursor=ABC", "previous": "http://host/api/v1/budgets?cursor=XYZ", "results": [] }`
When `BudgetsResponse.fromJson(json)` is called
Then `next` SHALL equal `"http://host/api/v1/budgets?cursor=ABC"` and `previous` SHALL equal `"http://host/api/v1/budgets?cursor=XYZ"` as raw strings

#### Scenario: fromJson with null cursors

Given a JSON `{ "next": null, "previous": null, "results": [] }`
When parsed
Then both fields SHALL be `null` and `budgets` SHALL be empty

#### Scenario: fromJson maps each result via BudgetResponse.fromJson

Given a JSON with three items in `results`
When parsed
Then `budgets.length` SHALL equal `3` and each element SHALL be a `BudgetResponse`

---

### Requirement: Cursor extraction lives in data/extensions

The system SHALL add `BudgetsResponseExtension` in `lib/src/data/extensions/budget/budgets_response_extension.dart` with:

```dart
extension BudgetsResponseExtension on BudgetsResponse {
  BudgetsPageModel toPageModel() => BudgetsPageModel(
    nextCursor: _cursorFrom(next),
    previousCursor: _cursorFrom(previous),
    budgets: budgets.map((b) => b.toModel()).toList(),
  );

  String? _cursorFrom(String? url) =>
      url == null ? null : Uri.parse(url).queryParameters['cursor'];
}
```

`BudgetResponseExtension.toModel()` (in the same folder) SHALL be extended to map `totalSpent`, `remaining` and `createdAt`:
- `value`, `totalSpent`, `remaining`: `(double.parse(x) * 100).round()`.
- `startDate`, `endDate`: `DateFormat('yyyy-MM-dd').parse(x).millisecondsSinceEpoch`.
- `createdAt`: `DateTime.parse(x).millisecondsSinceEpoch`.

The existing mapping of `value`, `startDate`, `endDate`, `description`, `id` SHALL remain unchanged.

#### Scenario: toPageModel extracts cursor

Given `BudgetsResponse(next: "http://host/api/v1/budgets?cursor=ABC123", previous: null, budgets: [b1, b2])`
When `toPageModel()` is called
Then the result SHALL be `BudgetsPageModel(budgets: [b1Model, b2Model], nextCursor: "ABC123", previousCursor: null)`

#### Scenario: cursor parsing is robust to other query params

Given `next == "http://host/api/v1/budgets?cursor=ABC&ordering=desc"`
When `_cursorFrom(next)` runs
Then it SHALL return `"ABC"`

#### Scenario: null cursors

Given `BudgetsResponse(next: null, previous: null, budgets: [])`
When `toPageModel()` is called
Then `nextCursor` and `previousCursor` SHALL be `null` and `budgets` SHALL be empty

#### Scenario: toModel handles negative remaining

Given a `BudgetResponse` with `remaining: "-1734.97"`
When `toModel()` runs
Then `BudgetModel.remaining` SHALL equal `-173497`

---

### Requirement: Extend IRemoteBudgetDataSource and implementation with findAll

The system SHALL add `Future<Either<FailureResponse, BudgetsResponse>> findAll({String? cursor})` to `IRemoteBudgetDataSource` and implement it in `RemoteBudgetDataSource` (`lib/src/infrastructure/datasources/remote/remote_budget_data_source.dart`).

The implementation SHALL call:

```dart
_client.get(
  parameter: Requests(
    EndpointKey.budgets.path,
    query: cursor == null ? null : {'cursor': cursor},
  ),
)
```

and deserialize via `response.either(FailureResponse.fromJson, BudgetsResponse.fromJson)`. The local variable holding the client return SHALL be named `response` (never `either`). The interface accepts a primitive `String? cursor` — **no** DTO.

The existing `findActive` and `create` methods SHALL remain untouched.

#### Scenario: First page (no cursor)

Given `findAll(cursor: null)` is invoked
When the implementation runs
Then `_client.get` SHALL be called with `Requests(EndpointKey.budgets.path)` **without** the `cursor` query param

#### Scenario: Subsequent page (with cursor)

Given `findAll(cursor: "ABC")` is invoked
Then `_client.get` SHALL be called with `Requests(EndpointKey.budgets.path, query: {'cursor': 'ABC'})`

---

### Requirement: Extend IBudgetRepository and BudgetRepository with findAll

The system SHALL add `Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor})` to `IBudgetRepository` (`lib/src/domain/repositories/interface_budget_repository.dart`) and implement it in `BudgetRepository` (`lib/src/data/repositories/budget_repository.dart`).

The implementation SHALL call `_dataSource.findAll(cursor: cursor)` and use:

```dart
data.either(
  (failure) => failure.toFailure(),
  (response) => response.toPageModel(),
);
```

The existing `findActive` and `create` methods SHALL remain unchanged.

#### Scenario: Success maps response to page model

Given the datasource returns `Right(BudgetsResponse)` with 3 budgets and a non-null `next`
When `BudgetRepository.findAll(cursor: null)` is called
Then the repository SHALL return `Right(BudgetsPageModel)` with 3 mapped `BudgetModel`s and `nextCursor != null`

#### Scenario: Failure mapping

Given the datasource returns `Left(FailureResponse)` with `code: "network_error"`
When `findAll` is called
Then the repository SHALL return `Left(NetworkFailure)`

---

### Requirement: BudgetItemPresentationData view-model

The system SHALL add `lib/src/presentation/ui/budgets/data/budget_item_presentation_data.dart` with an `Equatable` class `BudgetItemPresentationData` exposing:

- `BudgetModel budget`
- `String formattedValue` — `IMoneyService.format(budget.value / 100)`.
- `String formattedTotalSpent` — `IMoneyService.format(budget.totalSpent / 100)`.
- `String formattedRemaining` — `IMoneyService.format(budget.remaining / 100)` (preserves negative sign for overspent budgets).
- `String formattedPeriod` — `"dd/MM – dd/MM"` when both `startDate` and `endDate` fall in the current calendar year, otherwise `"dd/MM/yy – dd/MM/yy"`. `intl` `pt_BR`.

Construction is the responsibility of `BudgetsNotifier._toItem(BudgetModel)` — the screen SHALL NOT read `moneyServiceProvider` directly.

#### Scenario: Equatable behavior

Given two view-models with identical fields
Then they SHALL be equal via `==`

#### Scenario: Period format same year

Given `startDate` = May 1 of the current year and `endDate` = May 30 of the current year
When `_toItem` runs
Then `formattedPeriod` SHALL equal `"01/05 – 30/05"`

#### Scenario: Period format cross year

Given `startDate` = December 15, 2025 and `endDate` = January 14, 2026, with current year != either
When `_toItem` runs
Then `formattedPeriod` SHALL equal `"15/12/25 – 14/01/26"`

---

### Requirement: BudgetsState (presentation)

The system SHALL add `lib/src/presentation/ui/budgets/notifiers/budgets_state.dart` with an `Equatable` class `BudgetsState`:

- `BudgetItemPresentationData? activeItem` (default `null`)
- `List<BudgetItemPresentationData> items` (default `const []`)
- `String? nextCursor` (default `null`)
- `bool isLoadingMore` (default `false`)
- `Failure? loadMoreFailure` (default `null`)

`copyWith` SHALL support overriding each field, plus the explicit flags `clearActiveItem: bool`, `clearNextCursor: bool`, `clearLoadMoreFailure: bool` so a `null` override genuinely means "clear the field" (project pattern for nullable fields in `copyWith`).

`props` SHALL include all five fields.

#### Scenario: Initial state defaults

Given a fresh `BudgetsState()`
Then `activeItem` SHALL be null, `items` SHALL be empty, `nextCursor` SHALL be null, `isLoadingMore` SHALL be false, `loadMoreFailure` SHALL be null

---

### Requirement: BudgetsNotifier with keepAlive and cursor-based loadMore

The system SHALL add `lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart`, an `AsyncNotifier<BudgetsState>` annotated with `@Riverpod(keepAlive: true)`.

Dependencies SHALL be obtained via `ref.watch` in `build()`, marked `late` (never `late final`):
- `_repository = ref.watch(budgetRepositoryProvider)`
- `_moneyService = ref.watch(moneyServiceProvider)`

`build()` SHALL:
1. Call `await _repository.findAll(cursor: null)`.
2. On `Right(page)`: select `activeItem = _pickActive(page.budgets)` (the first budget whose `[startDate, endDate]` covers `DateTime.now().millisecondsSinceEpoch`); build `items = page.budgets.where((b) => b != active).map(_toItem).toList()`; return `BudgetsState(activeItem: ..., items: ..., nextCursor: page.nextCursor)`.
3. On `Left(failure)`: rethrow `failure` so the provider transitions to `AsyncError`.

A public method `Future<void> loadMore()` SHALL:
1. Early-return if `state is! AsyncData<BudgetsState>`.
2. Early-return if `state.value.isLoadingMore == true`.
3. Early-return if `state.value.nextCursor == null`.
4. Set `state = AsyncData(state.value.copyWith(isLoadingMore: true, clearLoadMoreFailure: true))`.
5. Call `_repository.findAll(cursor: state.value.nextCursor)`.
6. On `Right(page)`: `state = AsyncData(state.value.copyWith(items: [...state.value.items, ...page.budgets.map(_toItem)], nextCursor: page.nextCursor, clearNextCursor: page.nextCursor == null, isLoadingMore: false, clearLoadMoreFailure: true))`.
7. On `Left(failure)`: `state = AsyncData(state.value.copyWith(isLoadingMore: false, loadMoreFailure: failure))` — items and `activeItem` are preserved.

Pull-to-refresh SHALL be triggered **by the screen** via `ref.invalidate(budgetsProvider)` — **never** `ref.refresh`. There SHALL be no `applyFilter`, `searchChanged` or `removeFilter` method (out of scope).

#### Scenario: Initial build success with active

Given the repository returns `Right(BudgetsPageModel(budgets: [a, b, c], nextCursor: "X"))` and budget `b` covers today
When the notifier builds
Then the provider SHALL transition to `AsyncData(BudgetsState(activeItem: bView, items: [aView, cView], nextCursor: "X", isLoadingMore: false, loadMoreFailure: null))`

#### Scenario: Initial build success without active

Given the repository returns `Right(BudgetsPageModel(budgets: [a, b], nextCursor: null))` and neither covers today
When the notifier builds
Then `activeItem` SHALL be `null`, `items` SHALL contain both view-models, `nextCursor` SHALL be `null`

#### Scenario: Initial build failure

Given the repository returns `Left(NetworkFailure)`
When the notifier builds
Then the provider SHALL transition to `AsyncError` with an error of type `NetworkFailure`

#### Scenario: loadMore appends items on success

Given state is `AsyncData(items: [a, b], nextCursor: "X", isLoadingMore: false, activeItem: actv)` and the repository returns `Right(page(budgets: [c, d], nextCursor: "Y"))`
When `loadMore()` is invoked
Then state transitions through `isLoadingMore: true` and ends at `AsyncData(items: [a, b, cView, dView], nextCursor: "Y", isLoadingMore: false, loadMoreFailure: null, activeItem: actv)`

#### Scenario: loadMore while already loading is a no-op

Given state is `AsyncData(isLoadingMore: true, nextCursor: "X")`
When `loadMore()` is invoked
Then the repository SHALL NOT be called (`verifyNever`)

#### Scenario: loadMore at end of list is a no-op

Given state is `AsyncData(isLoadingMore: false, nextCursor: null)`
When `loadMore()` is invoked
Then the repository SHALL NOT be called

#### Scenario: loadMore failure preserves items and active

Given state is `AsyncData(items: [a, b], activeItem: actv, nextCursor: "X", isLoadingMore: false)` and the repository returns `Left(ServerFailure)`
When `loadMore()` is invoked
Then the final state SHALL be `AsyncData(items: [a, b], activeItem: actv, nextCursor: "X", isLoadingMore: false, loadMoreFailure: ServerFailure)`

#### Scenario: loadMore retry after failure clears the failure

Given state is `AsyncData(items: [a, b], nextCursor: "X", loadMoreFailure: ServerFailure)` and repository now returns `Right(page(budgets: [c], nextCursor: null))`
When `loadMore()` is invoked
Then the final state SHALL be `AsyncData(items: [a, b, cView], nextCursor: null, isLoadingMore: false, loadMoreFailure: null)`

#### Scenario: Pull-to-refresh via invalidate

Given state is populated with items and `activeItem`
When `ref.invalidate(budgetsProvider)` is called
Then the provider SHALL transition to `AsyncLoading` and re-invoke `findAll(cursor: null)`

---

### Requirement: BudgetsScreen layout

The system SHALL add `lib/src/presentation/ui/budgets/screens/budgets_screen.dart` as a **`StatefulWidget`** (because it owns a `ScrollController`) with a `Consumer` internal builder. **`ConsumerWidget` SHALL NOT be used.**

The state SHALL:
- Create a `ScrollController` in `initState` and dispose it in `dispose`.
- Register a scroll listener that, on every event, checks `position.pixels >= position.maxScrollExtent - 200` and calls `ref.read(budgetsProvider.notifier).loadMore()`.

The `build` SHALL return a `Scaffold` with:
- `AppBar` titled `"Orçamentos"` (final copy), `GoBackWidget` as leading.
- `body: SafeArea(child: Consumer(builder: (_, ref, _) { ... }))`.

Inside the `Consumer`, `final state = ref.watch(budgetsProvider);` SHALL drive a switch expression:

- `AsyncLoading()` → `BudgetsLoadingWidget()`
- `AsyncError()` → `BudgetsFailureWidget(onRetry: () => ref.invalidate(budgetsProvider))`
- `AsyncData(value: BudgetsState(activeItem: null, items: [], ...))` → `BudgetsEmptyWidget()`
- `AsyncData(:final value)` → `RefreshIndicator(onRefresh: () async => ref.invalidate(budgetsProvider), child: CustomScrollView(controller: _scrollController, slivers: [activeSliver?, BudgetsListWidget(state: value, onLoadMore: () => ref.read(budgetsProvider.notifier).loadMore())]))`.

The `activeSliver` SHALL be a `SliverToBoxAdapter` containing the `BudgetCardWidget` rendered with the `value.activeItem` data, and SHALL be omitted from the slivers list when `value.activeItem == null`.

#### Scenario: Screen renders each AsyncValue case correctly

Given the provider emits `AsyncLoading`, `AsyncError`, `AsyncData(empty + null active)`, and `AsyncData(non-empty)` sequentially
When the screen rebuilds on each
Then the corresponding widget SHALL render (loading / failure / empty / list with optional active card on top)

---

### Requirement: BudgetsListWidget with cursor-driven loadMore tail

The system SHALL add `lib/src/presentation/ui/budgets/widgets/budgets_list_widget.dart` as a `StatelessWidget` accepting `final BudgetsState state;` and `final VoidCallback onLoadMore;`.

It SHALL render a `SliverMainAxisGroup` containing:

- `SliverList.builder(itemCount: state.items.length, itemBuilder: (_, i) => BudgetListItemWidget(item: state.items[i]))` using `ValueKey(state.items[i].budget.id)` for efficient diffing.
- A trailing `SliverToBoxAdapter` reflecting tail state:
  - `state.isLoadingMore == true` → `BudgetsLoadMoreLoadingWidget()`.
  - `state.loadMoreFailure != null` → `BudgetsLoadMoreFailureWidget(onRetry: onLoadMore)`.
  - else → `SizedBox.shrink()` (idle or end-of-list — no extra UI in either case).

Items, the optional active card adapter (owned by the screen) and the trailing sliver SHALL all live inside a single `CustomScrollView` — no nested scrollables.

#### Scenario: Trailing sliver reflects tail state

Given `isLoadingMore == true` → trailing renders `BudgetsLoadMoreLoadingWidget`
Given `loadMoreFailure != null` → trailing renders `BudgetsLoadMoreFailureWidget`
Given `isLoadingMore == false` and `loadMoreFailure == null` → trailing renders `SizedBox.shrink`

#### Scenario: Items are keyed by budget id

Given a list with two items
Then each `BudgetListItemWidget` SHALL be wrapped in a `ValueKey(item.budget.id)`

#### Scenario: Retry triggers onLoadMore

Given the load-more failure widget is rendered and the user taps the retry button
Then `onLoadMore` SHALL be invoked (which the screen wires to `ref.read(budgetsProvider.notifier).loadMore()`)

---

### Requirement: BudgetsScreen pull-to-refresh and infinite scroll wiring

The screen SHALL wrap the success-state `CustomScrollView` in `RefreshIndicator(onRefresh: () async => ref.invalidate(budgetsProvider))`. `ref.refresh` SHALL NOT be used.

The scroll listener inside `_BudgetsScreenState._onScroll` SHALL fire `loadMore` when `position.pixels >= position.maxScrollExtent - 200`. The 200px threshold is fixed.

The notifier owns the duplicate-request guards (`isLoadingMore`, `nextCursor != null`); the listener is dumb (fires on every applicable event).

#### Scenario: Near-bottom scroll triggers loadMore

Given the list is scrolled such that `position.pixels >= position.maxScrollExtent - 200`
When the scroll listener fires
Then `ref.read(budgetsProvider.notifier).loadMore()` SHALL be called

#### Scenario: Rapid scroll does not duplicate requests

Given multiple near-bottom events fire while `isLoadingMore == true`
Then only one call to the repository SHALL occur (the duplicate-guard is inside the notifier)

---

### Requirement: BudgetsLocation

The system SHALL add `lib/src/presentation/ui/budgets/locations/budgets_location.dart`:

```dart
final class BudgetsLocation extends Location {
  @override String get path => AppRoutes.budgets.path;
  @override LocationPageBuilder get pageBuilder => (_) => screenPage(const BudgetsScreen());
}
```

The location SHALL NOT receive callbacks (the list does not navigate to detail in this change).

#### Scenario: Location resolves to BudgetsScreen

Given a `BudgetsLocation` is navigated to
Then the `pageBuilder` SHALL produce a page hosting `BudgetsScreen`

---

### Requirement: BudgetListItemWidget

The system SHALL add `lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart` as a `StatelessWidget` accepting `final BudgetItemPresentationData item;`.

It SHALL render a card-like surface with the budget description, period, value, total spent and remaining — all formatted strings come from the view-model. Negative `remaining` SHALL be rendered with the project's error/danger color (`context.colors.error`).

The widget SHALL NOT be tappable (no `GestureDetector`, no `InkWell`, no `BounceWidget`). Edit/delete affordances are out of scope.

#### Scenario: Negative remaining is visually distinguished

Given `item.budget.remaining < 0`
When the widget renders
Then the formatted remaining text SHALL use `context.colors.error`

#### Scenario: Item is read-only

Given the widget is rendered
When the user taps the item
Then no callback SHALL fire and no navigation SHALL occur

---

### Requirement: First-page state widgets

The system SHALL add three widgets in `lib/src/presentation/ui/budgets/widgets/`:

- `budgets_loading_widget.dart` — `StatelessWidget` rendering a Skeletonizer or centered `CircularProgressIndicatorWidget` consistent with `ExpensesLoadingWidget`.
- `budgets_empty_widget.dart` — `StatelessWidget` with a centered `Column`: `BackgroundIconWidget(icon: Icons.savings_outlined, color: context.colors.primary)` + `Text("Nenhum orçamento ainda", titleMedium bold)` + `Text("Quando você criar orçamentos eles aparecerão aqui.", bodySmall onSurfaceVariant)`. **No** "Create budget" CTA.
- `budgets_failure_widget.dart` — `StatelessWidget` accepting `final VoidCallback onRetry;`. `BackgroundIconWidget(icon: Icons.error_outline, color: context.colors.error)` + `Text("Não foi possível carregar os orçamentos.", titleMedium bold)` + `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)`.

#### Scenario: Empty widget on empty first page with no active

Given `AsyncData(BudgetsState(activeItem: null, items: []))`
Then `BudgetsEmptyWidget` SHALL render inside the screen body

---

### Requirement: Tail widgets (load-more loading and failure)

The system SHALL add:

- `budgets_load_more_loading_widget.dart` — a `StatelessWidget` centering a `CircularProgressIndicatorWidget` with vertical padding 16.
- `budgets_load_more_failure_widget.dart` — a `StatelessWidget` accepting `VoidCallback onRetry`, rendering centered:
  - `Text("Não foi possível carregar mais orçamentos.", bodySmall onSurfaceVariant)`
  - `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)`
  - Vertical padding 16.

Both widgets SHALL be placed inside a `SliverToBoxAdapter` at the use site (the widgets themselves are plain widgets).

#### Scenario: Retry triggers loadMore

Given the failure widget is rendered and the user taps the retry button
Then `onRetry` SHALL be invoked (the list widget wires this to `loadMore`)

---

### Requirement: API contract

The system SHALL consume `GET /api/v1/budgets` with `Authorization: Bearer <access_token>` and an optional `cursor` query parameter (absent on the first page). The response is a JSON object with `next` (nullable URL), `previous` (nullable URL), and `results` (array of budget objects with keys `id`, `value`, `start_date`, `end_date`, `description`, `total_spent`, `remaining`, `created_at`). Errors follow the standard `FailureResponse` shape `{ "errors": [{ "field", "message", "code" }] }`.

The cursor SHALL always be extracted from the URL via `Uri.parse(url).queryParameters['cursor']` and sent back as `query: {'cursor': value}` on the next request — the full URL SHALL never be passed to `IHttpClient`.

`POST /api/v1/budgets` (used by the existing `create`) SHALL be inspected before implementation to confirm it returns `total_spent`, `remaining`, `created_at` in its response payload. If it does not, the new fields on `BudgetResponse` and `BudgetModel` SHALL be made nullable.

Reference response (200):
```json
{
  "next": "http://api.example.org/budgets/?cursor=cD00ODY%3D",
  "previous": "http://api.example.org/budgets/?cursor=cj0xJnA9NDg3",
  "results": [
    {
      "id": 9,
      "value": "1000.00",
      "start_date": "2026-05-01",
      "end_date": "2026-05-30",
      "description": "May budget",
      "total_spent": "285.50",
      "remaining": "714.50",
      "created_at": "2026-05-02T17:58:42.119430-03:00"
    }
  ]
}
```

#### Scenario: Cursor extracted and sent back as query param

Given a successful response with `next == "http://api.example.org/budgets/?cursor=cD00ODY%3D"`
When the next page is requested
Then the client SHALL be invoked with `query: {'cursor': 'cD00ODY='}` (URL-decoded)
And the full URL SHALL NOT be passed to `IHttpClient`

#### Scenario: First page omits cursor entirely

Given the first page is being loaded
When the request is built
Then no `cursor` query param SHALL be present in the request

---

### Requirement: Performance constraints

The system SHALL satisfy the following performance constraints:

- Viewport-lazy rendering via `SliverList.builder`.
- Near-bottom detection threshold: 200px before `maxScrollExtent`.
- Duplicate-request guard inside the notifier (`isLoadingMore` + `nextCursor != null`).
- `@Riverpod(keepAlive: true)` so navigating away and back SHALL NOT refetch.
- `Equatable.props` SHALL cover every field of `BudgetsState` so identical `copyWith`s do not trigger rebuilds.
- `ValueKey(budget.id)` SHALL be used on every `BudgetListItemWidget` for efficient diffing.
- `const` constructors SHALL be used on every pure widget that admits it.
- `ref.invalidate(budgetsProvider)` SHALL be used for pull-to-refresh — never `ref.refresh`.
- All state mutations SHALL pass through the notifier's guards; the screen SHALL NOT mutate state directly.

#### Scenario: Navigating away and back does not refetch

Given the user opens `BudgetsScreen` and the first page is loaded
When the user navigates back to Home and then back to `BudgetsScreen`
Then the repository SHALL NOT be called again (`verifyNever`) because the provider is `keepAlive: true`

#### Scenario: Repeated near-bottom scroll events do not trigger duplicate requests

Given the list has been scrolled past the threshold and `loadMore` is already in flight (`isLoadingMore == true`)
When subsequent scroll events fire within the threshold
Then only one call to `_repository.findAll` SHALL occur for that page

---

### Requirement: Clean Architecture layering

The system SHALL respect the project's Clean Architecture dependency rule across the affected layers:

- `domain/` SHALL extend `BudgetModel`, add `BudgetsPageModel`, and extend `IBudgetRepository.findAll`. Zero Flutter and zero infrastructure imports.
- `infrastructure/` SHALL extend `BudgetResponse.fromJson`, add `BudgetsResponse.fromJson`, and extend `IRemoteBudgetDataSource.findAll`. Responses SHALL NOT expose `toModel`.
- `data/` SHALL extend `BudgetRepository.findAll` and `BudgetResponseExtension.toModel`, and add `BudgetsResponseExtension.toPageModel` with cursor extraction via `Uri.parse`.
- `presentation/` SHALL add the `budgets/` feature (notifier, state, screen, location, widgets, view-model), promote `BudgetCardWidget` to `presentation/widgets/budget/card/`, and extend `HomeScreen` + `HomeLocation` with the navigation callback.
- `main/` SHALL only add the new `AppRoutes.budgets` entry; the notifier provider is auto-generated by `@Riverpod`; `budgetRepositoryProvider` already exists.

`ConsumerWidget` SHALL NOT be used anywhere. Notifier dependencies SHALL arrive via `ref.watch` in `build()`, marked `late` (never `late final`). Every switch SHALL be an expression. `var` SHALL NOT be used. Private widget classes inside widget files are forbidden — they SHALL be extracted to their own files.

The `budgets/` feature SHALL NOT import anything from other features (`home/`, `expenses/`, `expense/`, `budget/`). The single allowed cross-feature import is `HomeLocation` importing `BudgetsLocation` to compose the navigation callback (Locations-compose-navigation exception).

#### Scenario: budgets/ feature is self-contained

Given any Dart file under `lib/src/presentation/ui/budgets/`
When `grep -rE "presentation/ui/(home|expenses|expense|budget)/" lib/src/presentation/ui/budgets/` is executed
Then the result SHALL be empty (no cross-feature imports)

#### Scenario: HomeLocation is the only cross-feature importer of BudgetsLocation

Given the codebase after this change
When `grep -rl "BudgetsLocation" lib/src/presentation/ui/` is executed
Then the result SHALL include `home/locations/home_location.dart` and `budgets/locations/budgets_location.dart` and SHALL NOT include any other feature

#### Scenario: No ConsumerWidget in the new feature

Given the new `budgets/` feature
When `grep -rE "extends ConsumerWidget|extends ConsumerStatefulWidget" lib/src/presentation/ui/budgets/` is executed
Then the result SHALL be empty

---

### Requirement: Tests

The change SHALL include the test coverage described below. Test descriptions SHALL be in English. Mocks SHALL be declared by the interface type (e.g. `late IBudgetRepository repository`) and SHALL NOT use `result` / `either` as variable names. `var` SHALL NOT be used.

**`BudgetResponse.fromJson` (pure Dart):**
- JSON with `total_spent`, `remaining`, `created_at` → all three exposed as `String` on the response.
- (If nullable) JSON without the three fields → all three `null`.
- JSON with negative `remaining` (`"-1734.97"`) → exposed as `"-1734.97"` raw string.

**`BudgetsResponse.fromJson` (pure Dart):**
- JSON with non-null `next` and `previous` → both exposed as `String` on the response.
- JSON with null `next` and `previous` → both `null`.
- JSON with non-empty `results` → `budgets` has correct length.
- JSON with empty `results` → `budgets` is empty.

**`BudgetResponseExtension.toModel` + `BudgetsResponseExtension.toPageModel`** (covered via repository tests):
- Cursor extraction (with cursor / null / multiple query params) covered through repository tests.
- Centavos conversion (positive + negative) covered through repository tests.

**`BudgetRepository.findAll` (mock `IHttpClient`):**
- First page (no cursor) → GET called with `Requests(EndpointKey.budgets.path)` (no `cursor` in query).
- Subsequent page (cursor "ABC") → GET called with `Requests(EndpointKey.budgets.path, query: {'cursor': 'ABC'})`.
- Success with 3 budgets + non-null `next` → `Right(BudgetsPageModel(budgets: List.length=3, nextCursor: extracted))`.
- Success with empty results + null next/previous → `Right(BudgetsPageModel(budgets: [], nextCursor: null, previousCursor: null))`.
- Mapping: `value`, `totalSpent`, `remaining` in centavos (including negative `remaining`).
- Mapping: `startDate`, `endDate` in ms epoch from `yyyy-MM-dd`.
- Mapping: `createdAt` in ms epoch from ISO 8601 with timezone.
- Error `code: "network_error"` → `Left(NetworkFailure)`.
- Error `code: "server_error"` → `Left(ServerFailure)`.
- Error `code: "not_found"` → `Left(NotFoundFailure)`.
- Unknown `code` with message → `Left(ValidationFailure(message))`.
- `findActive` and `create` regression tests SHALL continue to pass unchanged.

**`BudgetsNotifier` (mock `IBudgetRepository` + `IMoneyService`, `ProviderContainer`):**
- `build` loads first page, selects `activeItem` when one budget covers today, excludes it from `items`.
- `build` sets `activeItem == null` when none covers today.
- `build` returns `AsyncError` when repository returns Left.
- `loadMore` happy path appends items and updates `nextCursor`.
- `loadMore` while `isLoadingMore == true` → `verifyNever` on repository.
- `loadMore` when `nextCursor == null` → `verifyNever` on repository.
- `loadMore` failure preserves items and `activeItem`, sets `loadMoreFailure`.
- `loadMore` retry after failure clears `loadMoreFailure` on success.
- `ref.invalidate(budgetsProvider)` → provider returns to `AsyncLoading` and refetches page 1.
- `_toItem` produces a view-model with `formattedValue` / `formattedTotalSpent` / `formattedRemaining` from `IMoneyService.format`.
- `_toItem` produces `formattedPeriod` in `dd/MM – dd/MM` for same-year and `dd/MM/yy – dd/MM/yy` for cross-year.

**Mocks:**
- `test/mocks/mocks.dart` already has `MockBudgetRepository`, `MockMoneyService`, `MockHttpClient` (verify and add what is missing). No `MockRemoteBudgetDataSource` is required (repository is tested with `MockHttpClient`, mirroring `expense_repository_test.dart`).

#### Scenario: Test suite passes after implementation

Given the change has been implemented per `tasks.md`
When `flutter analyze && flutter test` is executed
Then both commands SHALL succeed with zero errors

#### Scenario: Coverage areas exist

Given the new test files
Then `test/src/infrastructure/responses/budget/budgets_response_test.dart` SHALL exist
And `test/src/presentation/providers/budgets_notifier_test.dart` SHALL exist
And `test/src/data/repositories/budget_repository_test.dart` SHALL include tests covering `findAll`

---

## Out of scope

- Filters, search or ordering on the budget list.
- Tap-to-navigate on list items (read-only items in this change).
- "Create budget" CTA on the empty state.
- Editing or deleting budgets from this screen.
- Removing `ActiveBudgetModel` or `ActiveBudgetNotifier` (deduplication is a separate change).
- A generic `PaginatedResponse<T>` / `Page<T>` wrapper.
- Backend changes.
- Adding any external pagination package.
- Sticky headers or grouping by month/year — flat list ordered by API.
- Deep linking to `/budgets` from external URLs.
- Widget tests (non-blocking; only added if visual logic becomes complex).

---

## Decisions (approved)

- **Entry point**: tap on the active `BudgetCardWidget` on the Home (no separate menu entry).
- **Active selection strategy**: client-side, by interval `[startDate, endDate]` covering `DateTime.now()`. The active is excluded from the list `items` to avoid visual duplication.
- **Header copy**: AppBar title `"Orçamentos"`.
- **Empty state copy**: title `"Nenhum orçamento ainda"` / description `"Quando você criar orçamentos eles aparecerão aqui."` (no CTA).
- **Failure state (first page)**: title `"Não foi possível carregar os orçamentos."`.
- **Load-more failure copy**: `"Não foi possível carregar mais orçamentos."`.
- **Empty state icon**: `Icons.savings_outlined`.
- **Failure state icon**: `Icons.error_outline`.
- **Route path**: `/budgets` (added to `AppRoutes`, included in `_all`).
- **Period format (same year)**: `"dd/MM – dd/MM"` (e.g. `"01/05 – 30/05"`).
- **Period format (cross year)**: `"dd/MM/yy – dd/MM/yy"` (e.g. `"15/12/25 – 14/01/26"`).
- **Negative remaining**: rendered in `context.colors.error` to flag overspent budgets.
- **Near-bottom threshold**: 200px before `maxScrollExtent`.
- **Pagination strategy**: manual with Riverpod `AsyncNotifier` + `keepAlive: true`; **no** external package.
- **Pull-to-refresh**: `ref.invalidate(budgetsProvider)` (never `ref.refresh`).
- **`BudgetCardWidget` location**: promoted to `lib/src/presentation/widgets/budget/card/` (entire folder moved).
- **`BudgetModel` extension**: keeps `ActiveBudgetModel` untouched in this change; deduplication is a separate concern.
- **`POST /api/v1/budgets` shape**: to be verified before implementation; if it does not return `total_spent`/`remaining`/`created_at`, the new fields on `BudgetResponse` and `BudgetModel` become nullable.
