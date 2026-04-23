# Spec — expenses-filters

## Context

The list-all-expenses screen (`lib/src/presentation/screens/expenses/`) already renders a paginated, cursor-based list of the authenticated user's expenses via `ExpensesNotifier` → `IExpenseRepository.findAll(cursor)` → `IRemoteExpenseDataSource.findAll(cursor)`. The filter icon button in the app bar (`expenses_filter_button_widget.dart`) currently has an empty `onPress: () {}`.

This change wires that button to a bottom-sheet with four filter sections (category, period, value range, ordering), plus an always-visible search field in the app bar (debounced) for the description, and a strip of active-filter chips above the list. Filter state is sent to the API as RQL query fragments (`eq(category,X)`, `ge(date,…)`, `le(value,…)`, `like(description,…)`) together with `ordering`, `page_size`, and `cursor`. Applying any filter resets the pagination cursor and the list reloads from the first page.

No other feature currently consumes these filters — the change is fully contained inside the `expenses` feature, the shared `IExpenseRepository` / `IRemoteExpenseDataSource`, and the `expense` domain models.

---

## Requirements

### Requirement: ExpenseFilter domain model

The system SHALL add `ExpenseFilterModel` at `lib/src/domain/models/expense/expense_filter_model.dart` as an immutable `Equatable` value object with:

| Field | Type | Meaning |
|---|---|---|
| `category` | `ExpenseCategory?` | selected category; `null` means unfiltered |
| `startDate` | `int?` | inclusive lower bound (millis since epoch); `null` means unfiltered |
| `endDate` | `int?` | inclusive upper bound (millis since epoch); `null` means unfiltered |
| `minValue` | `int?` | inclusive lower bound in centavos; `null` means unfiltered |
| `maxValue` | `int?` | inclusive upper bound in centavos; `null` means unfiltered |
| `description` | `String` | free-text search; empty string means unfiltered (never null) |
| `ordering` | `ExpenseOrdering` | required; default `ExpenseOrdering.dateDesc` |

All fields SHALL come **before** the constructor. `copyWith` SHALL expose per-field overrides plus explicit `clear*` booleans for every nullable field (`clearCategory`, `clearStartDate`, `clearEndDate`, `clearMinValue`, `clearMaxValue`), mirroring the existing pattern used by `ExpensesState.copyWith`. `props` SHALL include every field.

The model SHALL expose a `bool get isEmpty` returning `true` iff every filter is in its "unfiltered" state (category null, start/end null, min/max null, description empty, ordering == default). This is used by the chip strip and by the notifier to decide whether to render/reset UI.

The model SHALL expose a `const ExpenseFilterModel.empty()` factory (or `static const empty = ExpenseFilterModel(...)` constant) that returns the default, fully-unfiltered instance.

#### Scenario: Empty filter is detected

Given `ExpenseFilterModel.empty()`
Then `isEmpty` SHALL be `true`
And `ordering` SHALL be `ExpenseOrdering.dateDesc`

#### Scenario: Any set filter flips isEmpty

Given `ExpenseFilterModel.empty().copyWith(category: ExpenseCategory.food)`
Then `isEmpty` SHALL be `false`

Given `ExpenseFilterModel.empty().copyWith(ordering: ExpenseOrdering.valueDesc)`
Then `isEmpty` SHALL be `false`

#### Scenario: copyWith clears a nullable field explicitly

Given a filter with `category: ExpenseCategory.food`
When `copyWith(clearCategory: true)` is called
Then the returned filter SHALL have `category == null`

---

### Requirement: ExpenseOrdering domain enum

The system SHALL add `enum ExpenseOrdering` at `lib/src/domain/models/expense/expense_ordering.dart` with four values and their API wire strings:

| Enum value | API string (`ordering` query param) | pt_BR label |
|---|---|---|
| `dateDesc` | `-date` | Mais recentes |
| `dateAsc` | `date` | Mais antigos |
| `valueDesc` | `-value` | Maior valor |
| `valueAsc` | `value` | Menor valor |

The wire string SHALL be exposed via `String get query`. The pt_BR label SHALL be exposed via `String get label`. The default ordering value used by `ExpenseFilterModel.empty()` SHALL be `dateDesc`.

#### Scenario: ordering wire strings match the RQL contract

Given each `ExpenseOrdering` value
Then `.query` SHALL return exactly `-date`, `date`, `-value`, or `value`

---

### Requirement: ExpensePeriodPreset domain enum

The system SHALL add `enum ExpensePeriodPreset` at `lib/src/domain/models/expense/expense_period_preset.dart` with four values:

| Enum value | pt_BR label | Range at evaluation time `now` |
|---|---|---|
| `currentMonth` | Mês atual | first day of `now`'s month 00:00 → last day of `now`'s month 23:59:59.999 |
| `last30Days` | Últimos 30 dias | `now - 30d` 00:00 → `now` 23:59:59.999 |
| `previousMonth` | Mês passado | first day of previous month 00:00 → last day of previous month 23:59:59.999 |
| `custom` | Personalizado | no implicit range — user picks both ends manually |

Each non-`custom` preset SHALL expose `({int startDate, int endDate}) toRange({required DateTime now})` returning millis since epoch. The `custom` preset SHALL throw `UnsupportedError` if `toRange` is called — the screen uses a date picker to populate the range directly.

`now` is passed as a parameter (never read from `DateTime.now()` internally) so the preset is pure and testable.

Labels SHALL be exposed via `String get label`.

#### Scenario: currentMonth range uses the first and last day of the month

Given `now == DateTime(2026, 4, 23, 14, 30)`
When `ExpensePeriodPreset.currentMonth.toRange(now: now)` is invoked
Then `startDate == DateTime(2026, 4, 1).millisecondsSinceEpoch`
And `endDate == DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch`

#### Scenario: last30Days is inclusive on both ends

Given `now == DateTime(2026, 4, 23, 14, 30)`
When `ExpensePeriodPreset.last30Days.toRange(now: now)` is invoked
Then `startDate == DateTime(2026, 3, 24).millisecondsSinceEpoch` (30 days earlier at 00:00)
And `endDate == DateTime(2026, 4, 23, 23, 59, 59, 999).millisecondsSinceEpoch`

#### Scenario: custom preset has no implicit range

Given `ExpensePeriodPreset.custom.toRange(now: DateTime.now())`
Then `UnsupportedError` SHALL be thrown

---

### Requirement: IExpenseRepository.findAll accepts an optional filter

The system SHALL update `IExpenseRepository.findAll` (`lib/src/domain/repositories/interface_expense_repository.dart`) to accept an optional named `ExpenseFilterModel? filter` parameter in addition to the existing optional `String? cursor`.

The existing contract SHALL hold: cursor alone (no filter) continues to return the first/next page with the server's default ordering (`-date`) and no predicates. Calling with a filter SHALL cause the repository/datasource to serialize that filter into RQL query fragments + `ordering` + `cursor`.

`findRecent` and `create` SHALL remain unchanged.

#### Scenario: findAll without filter behaves exactly like today

Given `findAll(cursor: null)` is invoked without a filter
Then the network call SHALL be equivalent to the existing implementation — no filter query fragments, no `ordering` param

#### Scenario: findAll with filter forwards it to the datasource

Given a filter `ExpenseFilterModel(category: food, minValue: 10000, ordering: valueDesc)`
When `findAll(filter: filter, cursor: null)` is invoked
Then the repository SHALL pass the same `filter` reference to `IRemoteExpenseDataSource.findAll`
And SHALL convert the returned `FailureResponse` / `ExpensesResponse` the same way it does today (no new mapping rules)

---

### Requirement: IRemoteExpenseDataSource.findAll accepts an optional filter

The system SHALL update `IRemoteExpenseDataSource.findAll` to accept `ExpenseFilterModel? filter` alongside `String? cursor`. Interface parameters remain domain types — **no** DTO (`ExpenseFilterRequest` or similar) is introduced.

`RemoteExpenseDataSource.findAll` SHALL:
1. Build the list of RQL predicate fragments from the filter (see "RQL query construction" below).
2. Assemble the final query string by concatenating the predicate fragments with `&`, then appending `cursor=…`, `ordering=…`, `page_size=20` as needed.
3. Send the GET via `_client.get(parameter: Requests(path, query: null))`, where `path` already contains the query string appended after a `?`.
4. Deserialize both sides of the returned `Either<Map, Map>` via `response.either(FailureResponse.fromJson, ExpensesResponse.fromJson)`.

The decision to embed the query string into `path` (rather than using Dio's `queryParameters`) is intentional: RQL predicates have the form `eq(category,food)` — they are **keys with no value** and their parentheses/commas must survive intact. Dio's `queryParameters` serializer assumes `key=value` pairs and percent-encodes punctuation, which breaks the RQL grammar. Embedding the query string manually sidesteps both issues. Values inside predicates that may contain special characters (only `description`) SHALL be percent-encoded via `Uri.encodeQueryComponent` before being wrapped in the predicate.

#### Scenario: findAll without filter sends no RQL predicates and no ordering param

Given `findAll(filter: null, cursor: null)`
Then the GET path SHALL be exactly `EndpointKey.expenses.path` with no query string appended

Given `findAll(filter: null, cursor: "abc123")`
Then the GET path SHALL be `EndpointKey.expenses.path + "?cursor=abc123"` (or equivalent)

#### Scenario: findAll with a full filter emits valid RQL

Given filter `{category: food, startDate: 2026-03-01, endDate: 2026-03-31, minValue: 100 centavos → "1.00", maxValue: 50000 centavos → "500.00", description: "Merc", ordering: valueDesc}` and `cursor: null`
Then the GET path SHALL contain each of the following fragments joined by `&`:
- `eq(category,food)`
- `ge(date,2026-03-01)`
- `le(date,2026-03-31)`
- `ge(value,1.00)`
- `le(value,500.00)`
- `like(description,Merc*)` (with `Merc` URL-encoded — plain ASCII here so no transformation)
- `ordering=-value`
- `page_size=20`

Predicate fragments SHALL be emitted in the order listed above (category, date-start, date-end, value-min, value-max, description). `ordering` and `page_size` always come last, in that order. `cursor`, when present, goes at the very end.

#### Scenario: Description with accents is percent-encoded

Given a filter with `description: "Café"`
Then the emitted fragment SHALL be `like(description,Caf%C3%A9*)`

---

### Requirement: RQL query construction — ExpenseFilterRqlBuilder

The system SHALL add a pure Dart helper at `lib/src/infrastructure/clients/http/requests/expense_filter_rql_builder.dart` — a `final class ExpenseFilterRqlBuilder` — that converts an `ExpenseFilterModel` (plus optional cursor and page size) into the appended query string.

Public API:

```dart
final class ExpenseFilterRqlBuilder {
  static const int defaultPageSize = 20;

  String build({
    required ExpenseFilterModel? filter,
    String? cursor,
    int pageSize = defaultPageSize,
  });
}
```

`build` SHALL:
- Return an empty string (no leading `?`) when `filter == null && cursor == null`. The datasource is responsible for prepending `?` only when the result is non-empty.
- Format decimal values as `"${centavos ~/ 100}.${(centavos % 100).toString().padLeft(2, '0')}"` — centavos converted to two decimal places with `.` as separator (RQL/API contract, not a locale format).
- Format millis as ISO `yyyy-MM-dd` (local date of the day the millis fall on).
- Emit `like(description,<encoded>*)` when description is non-empty (trimmed). Wildcard is always a trailing `*`.
- Emit `ordering=<wire>` only when `filter != null` (even if ordering equals the server default `-date`, the client still sends it, to keep behavior explicit). When `filter == null` (or `filter.isEmpty == true`), `ordering` is **omitted** — this preserves the current paginated behavior as a no-op when no filters are applied.

Because the builder is pure and depends on no Dio types, it is fully unit-testable without mocks.

#### Scenario: build returns empty when there is nothing to serialize

Given `filter: null, cursor: null`
Then `build` SHALL return `""`

#### Scenario: build preserves fragment ordering

Given a filter with every field set and `cursor: "abc"`
Then `build` SHALL return a string whose fragments appear in order: category → date-start → date-end → value-min → value-max → description → `ordering=` → `page_size=` → `cursor=`, joined by `&`

#### Scenario: empty filter still serializes cursor

Given `filter: ExpenseFilterModel.empty(), cursor: "abc"`
Then `build` SHALL return `"cursor=abc"` (no predicates, no ordering, no page_size) — i.e. `isEmpty` filters are equivalent to `null` from the builder's perspective for cursor-only pagination during load-more

---

### Requirement: ExpenseRepository forwards filter to datasource

The system SHALL update `ExpenseRepository.findAll` (`lib/src/data/repositories/expense_repository.dart`) to accept the new `ExpenseFilterModel? filter` parameter and forward it directly to `_dataSource.findAll(cursor: …, filter: …)`. The repository SHALL NOT create a DTO, SHALL NOT rewrite the filter, and SHALL NOT serialize RQL — that is the datasource's responsibility.

The existing `FailureResponse → Failure` conversion (via `FailureResponseExtension.toFailure()`) and `ExpensesResponse → ExpensesPageModel` mapping (via `ExpensesResponseExtension.toPageModel()`) SHALL remain unchanged.

#### Scenario: Repository is a straight pass-through for the filter

Given `ExpenseRepository.findAll(cursor: "c", filter: f)` is called
Then `IRemoteExpenseDataSource.findAll` SHALL be called with `cursor: "c", filter: f`
And the returned `Either<Failure, ExpensesPageModel>` SHALL be mapped via the existing extensions

---

### Requirement: ExpensesNotifier owns the active filter and search term

The system SHALL extend `ExpensesNotifier` (`lib/src/presentation/screens/expenses/notifiers/expenses_notifier.dart`) to maintain the currently applied filter in its state and re-issue the first-page request whenever the filter changes.

`ExpensesState` SHALL gain:
- `ExpenseFilterModel filter` — defaults to `ExpenseFilterModel.empty()`; represents the filter actually in effect (already dispatched to the API, possibly still loading). It is **not** the draft being edited inside the bottom-sheet — that lives in `ExpensesFiltersNotifier` (next requirement).

The notifier SHALL expose three methods (no MVI Intent — this notifier is already an `AsyncNotifier`, and the surface is narrow):

1. `Future<void> applyFilter(ExpenseFilterModel filter)` — called by the bottom-sheet's "Aplicar" button. Stores the filter in the state and reloads the first page.
2. `Future<void> searchChanged(String description)` — called by the app-bar search field on every keystroke. Internally debounced (400 ms, using `DebounceAction`) so multiple rapid keystrokes cause at most one network request. Updates the filter's `description` field and reloads the first page. `DebounceAction` is disposed by the notifier via `ref.onDispose`.
3. `Future<void> removeFilter(ExpenseFilterChipKind kind)` — called when the user taps the `×` on an active-filter chip. Clears the corresponding fields and reloads the first page. See `ExpenseFilterChipKind` below.

`build()` SHALL:
- Read dependencies the same way it does today.
- Call `_loadFirstPage(filter: ExpenseFilterModel.empty())` on first build.
- On subsequent invalidations (e.g. `RefreshIndicator` pulling), the filter SHALL reset to empty **only** when the notifier is being disposed then rebuilt from scratch (standard `ref.invalidate` semantics). Pull-to-refresh in the screen SHALL be updated to call `applyFilter(state.valueOrNull?.filter ?? ExpenseFilterModel.empty())` instead of `ref.invalidate(expensesProvider)` so the filter survives the refresh. Applying the filter is a no-op when the filter didn't change — but it still reloads the list, which is exactly what "refresh" means.

`loadMore` SHALL pass the current filter through: `_repository.findAll(cursor: current.nextCursor, filter: current.filter)`. Every pagination page shares the same filter.

`_loadFirstPage` SHALL:
- Call `_repository.findAll(filter: filter)` (no cursor).
- On `Right(ExpensesPageModel)`: build an `ExpensesState` with the new items, the new cursor, and the passed-in `filter`. Also reset `isLoadingMore` and `loadMoreFailure`.
- On `Left(Failure)`: set state to `AsyncError(failure)` — matching current behavior.

When `applyFilter` / `searchChanged` / `removeFilter` run, the notifier SHALL set `state = AsyncLoading()` before the network call (a full-screen skeleton is preferable here vs. an in-place spinner that would leave the old filtered list visible with the new filter label already rendered in the chip strip — visually inconsistent).

Fields in `build()` SHALL remain `late`, never `late final`.

#### Scenario: applyFilter reloads first page with new filter

Given the list currently shows 20 items under filter `f1` with `nextCursor = "c1"`
When the user applies filter `f2 != f1`
Then the state SHALL transition to `AsyncLoading()`
And `_repository.findAll(filter: f2)` SHALL be called (no cursor)
And on success the state SHALL transition to `AsyncData(ExpensesState(filter: f2, items: newItems, nextCursor: newCursor, isLoadingMore: false, loadMoreFailure: null))`

#### Scenario: searchChanged coalesces rapid keystrokes

Given the user types `"C"`, `"Ca"`, `"Caf"`, `"Café"` within 200 ms
Then `_repository.findAll` SHALL be called **exactly once**, with the final filter whose description is `"Café"`, 400 ms after the last keystroke

#### Scenario: loadMore preserves the active filter

Given the state has `filter: f` with `nextCursor: "cN"`
When `loadMore` runs
Then `_repository.findAll(cursor: "cN", filter: f)` SHALL be called
And the returned items SHALL be appended to the existing list (same behavior as today)

#### Scenario: removeFilter clears the targeted fields and reloads

Given an applied filter with `category: food, minValue: 10000`
When `removeFilter(ExpenseFilterChipKind.value)` is called
Then the resulting filter SHALL be `(category: food, minValue: null, maxValue: null, …)`
And the first page SHALL be reloaded with that filter

---

### Requirement: ExpenseFilterChipKind — identifier for a removable chip group

The system SHALL add `enum ExpenseFilterChipKind` at `lib/src/presentation/screens/expenses/data/expense_filter_chip_kind.dart` with four values, each representing one "group" of filters that is removed together when its chip is dismissed:

| Enum value | Clears |
|---|---|
| `category` | `category` |
| `period` | `startDate` + `endDate` |
| `value` | `minValue` + `maxValue` |
| `ordering` | resets `ordering` to `ExpenseOrdering.dateDesc` (the chip is only shown when ordering ≠ default; removing it means "go back to default") |

Search term is **not** represented as a chip — it is cleared by clearing the app-bar search field. The chip strip therefore never includes a description chip.

#### Scenario: kind → cleared fields mapping is total

Given any `ExpenseFilterChipKind`
When `ExpensesNotifier.removeFilter(kind)` runs
Then the exhaustive switch SHALL clear the correct fields without a default branch

---

### Requirement: ExpensesFiltersNotifier (MVI) owns the bottom-sheet draft state

The system SHALL add `ExpensesFiltersNotifier` at `lib/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart`, a `Notifier<ExpensesFiltersState>` generated with `@Riverpod(keepAlive: false)` (instance is disposed when the bottom-sheet is popped). This notifier owns the **draft** filter being edited inside the bottom-sheet — it is separate from `ExpensesNotifier` so the user can explore filter combinations without triggering requests until they tap "Aplicar".

`ExpensesFiltersState` SHALL live at `lib/src/presentation/screens/expenses/notifiers/expenses_filters_state.dart` and contain:

| Field | Type | Meaning |
|---|---|---|
| `draft` | `ExpenseFilterModel` | current draft |
| `selectedPreset` | `ExpensePeriodPreset?` | which preset chip is highlighted; `null` means no preset (either "Personalizado" for custom, or untouched) |

Intents (`lib/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart`), as a `sealed class ExpensesFiltersIntent`:

| Intent | Effect on draft |
|---|---|
| `InitializeFrom(ExpenseFilterModel filter)` | seeds `draft` when the bottom-sheet opens, copying from the currently applied filter on `ExpensesNotifier` |
| `CategorySelected(ExpenseCategory? category)` | sets `draft.category` (or clears when `null` — tapping the selected chip deselects it) |
| `PresetSelected(ExpensePeriodPreset preset)` | for `currentMonth`/`last30Days`/`previousMonth`: computes the range via `toRange(now: DateTime.now())` and sets `draft.startDate`/`endDate`; sets `selectedPreset`. For `custom`: opens a date-range picker (see screen requirement) and sets `selectedPreset = custom`; does **not** change the draft itself. |
| `CustomRangeChanged({int startDate, int endDate})` | explicitly sets `draft.startDate`/`endDate` from the custom picker; sets `selectedPreset = custom` |
| `MinValueChanged(int? centavos)` | sets `draft.minValue`; `null` or zero clears it |
| `MaxValueChanged(int? centavos)` | sets `draft.maxValue`; `null` or zero clears it |
| `OrderingSelected(ExpenseOrdering ordering)` | sets `draft.ordering` |
| `Cleared()` | resets `draft` to `ExpenseFilterModel.empty()` and `selectedPreset = null` |

The notifier SHALL expose `void dispatch(ExpensesFiltersIntent intent)` that is a **switch expression** over the sealed hierarchy (never a switch statement), per project convention.

The notifier SHALL NOT call the repository. Applying the draft is done by the bottom-sheet screen: on "Aplicar" it reads `ref.read(expensesFiltersNotifierProvider).draft`, pops the sheet via `context.pop()`, and calls `ref.read(expensesNotifierProvider.notifier).applyFilter(draft)`.

#### Scenario: Bottom-sheet opens with the currently applied filter as draft

Given `ExpensesNotifier.state.value.filter == f1`
When the user opens the bottom-sheet
Then `ExpensesFiltersNotifier` SHALL initialize its draft from `f1` via `InitializeFrom(f1)` (called from the screen's `initState` or equivalent mount hook)

#### Scenario: Preset updates the date range and highlights the chip

Given `now == DateTime(2026, 4, 23, 14, 30)` (mocked / injected for the test)
When `PresetSelected(ExpensePeriodPreset.currentMonth)` is dispatched
Then `draft.startDate == DateTime(2026, 4, 1).millisecondsSinceEpoch`
And `draft.endDate == DateTime(2026, 4, 30, 23, 59, 59, 999).millisecondsSinceEpoch`
And `selectedPreset == ExpensePeriodPreset.currentMonth`

#### Scenario: Cleared resets the draft

Given any non-empty draft
When `Cleared()` is dispatched
Then `draft == ExpenseFilterModel.empty()`
And `selectedPreset == null`

---

### Requirement: ExpensesFilterLocation + ExpensesFilterScreen — bottom-sheet via duck_router

The system SHALL add a new Location at `lib/src/presentation/screens/expenses/locations/expenses_filter_location.dart` that uses the existing `BottomSheetPage` helper (same pattern as `ExpenseDateLocation`, `CalculatorLocation`, `ExitLocation`).

```dart
final class ExpensesFilterLocation extends Location {
  @override
  String get path => 'expenses-filter';

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(builder: (_) => const ExpensesFilterScreen());
}
```

The `ExpensesFilterButtonWidget`'s `onPress` SHALL be refactored to take a `VoidCallback onPress` via its constructor (no longer owning the action). `ExpensesScreen` SHALL wire it via a callback that calls `context.navigate(ExpensesFilterLocation())`. This keeps the screen free of inter-feature Location imports and follows the existing navigation-callback pattern documented in CLAUDE.md.

Actually — `ExpensesFilterLocation` lives **inside the same feature** as `ExpensesScreen`, so it is allowed to be imported directly by `ExpensesScreen` (the "no cross-feature Location import" rule only applies across features). To keep things consistent with other same-feature navigation in the project (e.g. `expense_date_location.dart` imported from `expense_screen.dart`), `ExpensesScreen` SHALL import `ExpensesFilterLocation` directly and pass `() => context.navigate(ExpensesFilterLocation())` to the button.

#### Scenario: Tapping the filter button navigates to the bottom-sheet

Given the user is on `ExpensesScreen`
When the filter icon is tapped
Then `context.navigate(ExpensesFilterLocation())` SHALL be invoked
And a modal bottom-sheet SHALL appear hosting `ExpensesFilterScreen`

---

### Requirement: ExpensesFilterScreen layout

The system SHALL add `ExpensesFilterScreen` at `lib/src/presentation/screens/expenses/screens/expenses_filter_screen.dart` as a `StatelessWidget` whose body is a `BottomSheetScaffoldWidget` with:

- `title: 'Filtros'`
- `subtitle: 'Refine a lista de despesas'`
- `withoutPadding: false` (default 20 px horizontal)
- `child`: a `SingleChildScrollView` containing:
  1. A top row with **only** a `ButtonWidget.text(label: 'Limpar tudo', onTap: …)` pinned to the right. Visible only when `ExpensesFiltersNotifier.state.draft.isEmpty == false`. Tapping dispatches `Cleared()`.
  2. Section **"Categoria"** — a `Wrap` of category chips (one per `ExpenseCategory` value **except** `unknown` — `unknown` is a fallback and is never a user choice). Each chip SHALL use the existing `ExpenseCategoryVisualExtension` for icon/color/label. Single-select: tapping a chip selects it; tapping the already-selected chip deselects. Visual: selected chips use the category's color as background at 0.15 alpha with full-strength text/icon; unselected use `context.colors.surfaceContainerHighest` with `onSurfaceVariant`.
  3. Section **"Período"** — a row of four preset chips (`currentMonth`, `last30Days`, `previousMonth`, `custom`) followed by a readonly summary row "`dd/MM/yyyy` – `dd/MM/yyyy`" when `draft.startDate` and `draft.endDate` are set. Tapping `custom` SHALL open the existing `SfDateRangePicker` inline (via a nested `BottomSheetScaffoldWidget` pushed as another route? — **no**: to stay within one sheet, the custom picker SHALL render inline below the preset chips only when `selectedPreset == custom`, using `SfDateRangePicker` with `selectionMode: .range`). Completing the range dispatches `CustomRangeChanged`.
  4. Section **"Valor"** — two `TextFieldWidget`s side-by-side, one for min and one for max, with currency formatting (reuse the existing formatting pattern from the create-expense flow; the centavos value is stored in the notifier's draft). Labels "Mínimo" and "Máximo". Either field may be left empty.
  5. Section **"Ordenação"** — four `SelectorWidget`-style radio chips (single-select, always one selected) using `ExpenseOrdering.label` for each. Default selection reflects `draft.ordering`.
  6. A sticky footer (or the last child of the column, given the sheet height policy) with a full-width `ButtonWidget` labeled "Aplicar" that:
     - Reads the current `draft` from `ExpensesFiltersNotifier`.
     - Calls `context.pop()` to close the sheet.
     - Calls `ref.read(expensesNotifierProvider.notifier).applyFilter(draft)`.

Each section heading uses `context.typography.titleMedium` with `FontWeight.w600`, pt_BR copy. Spacing between sections SHALL be 16 px.

The screen SHALL call `ref.read(expensesFiltersNotifierProvider.notifier).dispatch(InitializeFrom(currentFilter))` when mounted, where `currentFilter` comes from `ref.read(expensesNotifierProvider).valueOrNull?.filter ?? ExpenseFilterModel.empty()`.

The screen SHALL follow project rules:
- `StatelessWidget` + internal `Consumer` (never `ConsumerWidget`).
- No private widget classes (`class _FooWidget`) inside this file — any non-trivial subtree extracts to its own file under `screens/expenses/widgets/filter/`.
- Switches over `ExpenseOrdering` / `ExpensePeriodPreset` / `ExpenseCategory` SHALL be switch expressions, exhaustive.

Widget files created under `screens/expenses/widgets/filter/`:
- `expenses_filter_category_section_widget.dart`
- `expenses_filter_period_section_widget.dart`
- `expenses_filter_value_section_widget.dart`
- `expenses_filter_ordering_section_widget.dart`

Each takes its relevant slice of the draft + a callback to dispatch the corresponding intent — no direct Riverpod `ref` access inside these child widgets; the parent screen wires everything.

#### Scenario: Limpar tudo only shows when draft has at least one filter

Given the bottom-sheet opens with an empty draft
Then the "Limpar tudo" link SHALL NOT render

Given the user selects category = food
Then "Limpar tudo" SHALL render in the top-right of the sheet

#### Scenario: Tapping Aplicar closes the sheet and triggers the reload

Given any draft `d`
When the user taps "Aplicar"
Then the sheet SHALL be popped
And `ExpensesNotifier.applyFilter(d)` SHALL be called exactly once

#### Scenario: Selecting custom shows the inline date-range picker

Given the user taps the "Personalizado" chip
Then an `SfDateRangePicker` (range mode) SHALL render inline below the preset chips
And completing a range SHALL dispatch `CustomRangeChanged` with the start/end in millis

---

### Requirement: Search field in the expenses app bar

The system SHALL replace the current static `AppBarWidget(title: …, actions: [ExpensesFilterButtonWidget])` usage inside `ExpensesScreen` with an app bar that contains an always-visible **search field** on the left (or title area) next to the leading `GoBackWidget`, plus the existing filter button on the right.

The system SHALL add `ExpensesSearchFieldWidget` at `lib/src/presentation/screens/expenses/widgets/expenses_search_field_widget.dart`, a `StatelessWidget` that:
- Renders a compact `TextField` styled as a pill (rounded, `context.colors.surfaceContainerHigh` background, leading lupa icon, optional trailing `×` to clear).
- Accepts `String initialValue` and `ValueChanged<String> onChanged` via its constructor.
- Internally uses a `TextEditingController` initialized with `initialValue` (via a `StatefulWidget` implementation detail — or, if the screen owns the controller, pass it in).

Wiring:
- The screen owns a `TextEditingController` for the search field (in `_ExpensesScreenState`).
- On every change, it calls `ref.read(expensesNotifierProvider.notifier).searchChanged(controller.text)` — the notifier itself applies the 400 ms debounce.
- When the user taps `×` (or backspaces to empty), the screen clears the controller and calls `searchChanged("")` synchronously.

Hint text: `"Buscar por descrição"`.

The `AppBarWidget` signature SHALL be extended (or a second variant added) to accept a `Widget? titleWidget` that, when provided, replaces the `title` text. The search field is passed as `titleWidget`. The existing `title: String?` API SHALL remain for the other screens that use a plain text title.

#### Scenario: Typing in the search field triggers a debounced search

Given the user types `"Mer"` and stops
Then after ~400 ms, the notifier SHALL call the repository with `filter.description == "Mer"`
And the list SHALL reload with the result

#### Scenario: Clearing the search field resets the description filter

Given the search field contains `"Mer"` and the list reflects that filter
When the user taps `×`
Then the controller and the notifier's filter description SHALL both become `""`
And the list SHALL reload without the description predicate

---

### Requirement: Active-filter chips strip above the list

The system SHALL add `ExpensesActiveFiltersWidget` at `lib/src/presentation/screens/expenses/widgets/expenses_active_filters_widget.dart`, a `StatelessWidget` that renders a horizontally-scrollable `Row` of dismissible chips **above** the list (inserted into `ExpensesScreen`'s `CustomScrollView` as a `SliverToBoxAdapter` between the `ScreenHeaderWidget` and the list sliver).

It SHALL take:
- `ExpenseFilterModel filter` (the **applied** filter, from `ExpensesNotifier` state)
- `ValueChanged<ExpenseFilterChipKind> onRemove`

It SHALL render one chip per active group (see `ExpenseFilterChipKind`):
- **Category**: label `ExpenseCategory.label`; leading `ExpenseCategory.icon` (same visual extension); only shown when `filter.category != null`.
- **Period**: label `"dd/MM/yyyy – dd/MM/yyyy"` (pt_BR) when both `startDate` and `endDate` are set; label `"desde dd/MM/yyyy"` if only startDate; `"até dd/MM/yyyy"` if only endDate; shown when either bound is set.
- **Value**: label `"R$ X – R$ Y"` if both bounds; `"≥ R$ X"` if only min; `"≤ R$ Y"` if only max; uses `IMoneyService.format` for each bound. Shown when either bound is set.
- **Ordering**: label `ExpenseOrdering.label`; shown only when `filter.ordering != ExpenseOrdering.dateDesc`.

Each chip has a trailing `×` icon; tapping it invokes `onRemove(kind)`.

Description filter is **not** rendered as a chip — it is represented by the search field's text and the `×` inside that field.

The widget SHALL NOT read any provider directly. The notifier builds a view-model-ready shape: actually, it is cheapest to pass the `ExpenseFilterModel` plus `IMoneyService` and `intl` date formatters down — but per the `services-via-notifier` rule (`MEMORY.md`: "Services só via notifier"), this formatting SHALL be done in the notifier and the chip strip SHALL receive a prebuilt `List<ExpenseActiveFilterChipData>`.

A new view-model `ExpenseActiveFilterChipData` at `lib/src/presentation/screens/expenses/data/expense_active_filter_chip_data.dart`:

```dart
final class ExpenseActiveFilterChipData extends Equatable {
  final String label;
  final IconData? icon;
  final ExpenseFilterChipKind kind;
  const ExpenseActiveFilterChipData({
    required this.label,
    required this.kind,
    this.icon,
  });
  @override
  List<Object?> get props => [label, icon, kind];
}
```

The notifier SHALL expose these on `ExpensesState` as `List<ExpenseActiveFilterChipData> activeFilterChips` (recomputed every time the filter changes — a pure function of the filter + the services).

The widget is therefore a pure consumer of `state.filter` and `state.activeFilterChips`.

#### Scenario: No filters → no chip strip

Given `filter.isEmpty == true`
Then `activeFilterChips` SHALL be an empty list
And the widget SHALL render a `SliverToBoxAdapter` with zero-height content (or not render the sliver at all)

#### Scenario: Two active groups render two chips

Given `filter.category == food` and `filter.minValue == 10000`
Then `activeFilterChips.length == 2`
And the chips' kinds SHALL be `[category, value]` in the enum declaration order of `ExpenseFilterChipKind`

#### Scenario: Tapping × on a chip removes the group

Given a value chip is rendered
When the user taps `×`
Then `onRemove(ExpenseFilterChipKind.value)` SHALL be invoked
And upstream `ExpensesNotifier.removeFilter(value)` SHALL clear `minValue` and `maxValue` and reload the first page

---

### Requirement: Pull-to-refresh preserves the active filter

The `RefreshIndicator` in `ExpensesScreen` currently calls `ref.invalidate(expensesProvider)`, which would reset the filter to empty (since `build()` initializes with `ExpenseFilterModel.empty()`).

The system SHALL change the `onRefresh` callback to `await ref.read(expensesNotifierProvider.notifier).applyFilter(state.valueOrNull?.filter ?? ExpenseFilterModel.empty())`. This re-issues a first-page request with the current filter without disposing the notifier.

#### Scenario: Pull-to-refresh while filtered

Given the list is filtered by `category: food` and the user pulls down
Then the first page SHALL be re-fetched with `filter: {category: food, …}`
And the filter chip strip SHALL continue to display the category chip

---

### Requirement: RQL query is embedded in the request path, not queryParameters

`Requests` (`lib/src/infrastructure/clients/http/requests/requests.dart`) SHALL NOT be changed. `RemoteExpenseDataSource.findAll` SHALL pass `query: null` to `Requests` and instead pre-build the path as `"${EndpointKey.expenses.path}${rqlSuffix}"` where `rqlSuffix` is either empty or starts with `?`.

Rationale: Dio's `queryParameters` serializer percent-encodes RQL punctuation (`(`, `)`, `,`, `*`) in a way that breaks the server's RQL grammar. Embedding a manually-built query string keeps the encoding explicit and predictable. This decision is scoped to expenses and does not alter the HTTP client abstraction.

Existing calls that use `query: {'cursor': cursor}` (the non-filter paginated flow) SHALL be migrated to the same path-embedding approach so the builder is the single source of truth.

#### Scenario: RemoteExpenseDataSource.findAll delegates to the builder

Given a `filter` and `cursor`
When `findAll` runs
Then `ExpenseFilterRqlBuilder.build(filter: filter, cursor: cursor)` SHALL be invoked
And its result SHALL be prepended with `?` (if non-empty) and appended to `EndpointKey.expenses.path`
And the resulting string SHALL be passed as `Requests.path` with `query: null`

---

### Requirement: Provider wiring

The system SHALL add `expensesFiltersNotifierProvider` (auto-generated from `@Riverpod(keepAlive: false)` on `ExpensesFiltersNotifier`). No changes to `expensesNotifierProvider` declaration are required beyond the new methods added to the class.

`expenseRepositoryProvider` and `remoteExpenseDataSourceProvider` continue to be reused — no new provider files for data/infrastructure.

#### Scenario: Container resolves the new notifier

Given a fresh `ProviderContainer`
When `expensesFiltersNotifierProvider` is read
Then `ExpensesFiltersNotifier` SHALL be instantiated
And disposed when the last listener goes away (keepAlive: false)

---

### Requirement: Clean Architecture layering

The feature SHALL respect the project's layer rules:
- `domain/` owns `ExpenseFilterModel`, `ExpenseOrdering`, `ExpensePeriodPreset`. Zero Flutter imports.
- `infrastructure/` owns `ExpenseFilterRqlBuilder` and the updated `RemoteExpenseDataSource.findAll`. It depends on domain types (filter model, ordering enum) but never on data/presentation.
- `data/` updates `ExpenseRepository.findAll` (no DTO created here; it's a straight pass-through for the filter).
- `presentation/` owns the new notifiers, state, intent hierarchy, screens, widgets, and view-models. `ExpensesFilterChipKind` and `ExpenseActiveFilterChipData` live under `screens/expenses/data/` because they are feature-specific.
- `main/` receives no changes beyond what code generation produces.

No `ConsumerWidget` SHALL be introduced. All notifier dependencies SHALL come via `ref.watch` in `build()`, using `late` (not `late final`). All switches SHALL be switch expressions, exhaustive. No private widget classes declared inside another widget file — each non-trivial subtree extracts to its own file under `screens/expenses/widgets/filter/`.

---

### Requirement: API contract

`GET /api/v1/expenses` — requires Bearer token. Query parameters supported (all optional):

- `eq(category,<value>)` — single-select category filter; `<value>` is one of the server-known category wire strings.
- `ge(date,YYYY-MM-DD)` / `le(date,YYYY-MM-DD)` — date range; inclusive.
- `ge(value,X.YY)` / `le(value,X.YY)` — value range; inclusive; value is a decimal string in the same format as the response's `value` field.
- `like(description,<encoded>*)` — substring match with trailing wildcard.
- `ordering=<wire>` — one of `-date`, `date`, `-value`, `value`.
- `page_size=<int>` — page size; default 20 on the client.
- `cursor=<opaque>` — opaque cursor returned by the server in the previous response's `next`.

Multiple predicates and scalar params are joined by `&` in the query string. The server returns the same `ExpensesResponse` shape as today regardless of which filters are present.

Error response (standard `FailureResponse`):
```json
{ "errors": [ { "field": "string", "message": "string", "code": "string" } ] }
```

Status code → failure mapping is unchanged (reuses `FailureResponseExtension.toFailure()` via `FailureCodeResponse`).

---

### Requirement: Tests

#### ExpenseFilterModel (pure Dart)

- `ExpenseFilterModel.empty().isEmpty` is `true`.
- Changing any single field via `copyWith` flips `isEmpty` to `false`.
- `clearCategory: true` wipes the category field even when `category` is not passed.
- `props` contains every field (covered by two instances differing in one field being `!=`).

#### ExpenseOrdering / ExpensePeriodPreset (pure Dart)

- Each `ExpenseOrdering.query` returns the exact wire string from the contract.
- `ExpensePeriodPreset.currentMonth.toRange` at a mid-month `now` returns (1st of month 00:00, last of month 23:59:59.999).
- `ExpensePeriodPreset.previousMonth.toRange` at Jan 15 returns (Dec 1 prev year 00:00, Dec 31 prev year 23:59:59.999).
- `ExpensePeriodPreset.last30Days.toRange(now)` returns (now - 30d at 00:00, now at 23:59:59.999).
- `ExpensePeriodPreset.custom.toRange(now: …)` throws `UnsupportedError`.

#### ExpenseFilterRqlBuilder (pure Dart)

- `build(filter: null, cursor: null, pageSize: 20)` returns `""`.
- `build(filter: null, cursor: "abc", pageSize: 20)` returns `"cursor=abc"`.
- `build(filter: empty, cursor: null, pageSize: 20)` returns `""` (isEmpty filter treated as null for URL).
- `build(filter: empty, cursor: "abc", pageSize: 20)` returns `"cursor=abc"`.
- Fragment ordering test: a filter with every field set produces `"eq(category,food)&ge(date,2026-03-01)&le(date,2026-03-31)&ge(value,1.00)&le(value,500.00)&like(description,Merc*)&ordering=-value&page_size=20&cursor=abc"`.
- Decimal formatting: `minValue: 100` (centavos) → `"ge(value,1.00)"`; `minValue: 9` → `"ge(value,0.09)"`; `minValue: 0` → no fragment (treated as unset by the notifier before calling the builder).
- Description encoding: `"Café"` → `"like(description,Caf%C3%A9*)"`.
- Ordering at default (`-date`) with filter non-null — still emits `"ordering=-date"`.
- Ordering omitted when filter is null.

#### ExpenseRepository.findAll (mock `IHttpClient`)

- GET with filter `{category: food, minValue: 10000}` and no cursor → the HTTP client receives a request whose path contains `eq(category,food)&ge(value,100.00)&ordering=-date&page_size=20` and no `cursor` segment.
- GET with filter + cursor → same predicates plus `cursor=<value>` at the end.
- GET 200 success → `Right(ExpensesPageModel)` with mapped items.
- GET 400 with `{errors: [{code: "validation_error", message: "…"}]}` → `Left(ValidationFailure("…"))`.
- GET 500 → `Left(ServerFailure)`.

The test SHALL NOT assert exact percent-encoding of ASCII — any test payload uses plain-ASCII descriptions. A dedicated test in `ExpenseFilterRqlBuilder` covers accented description encoding.

#### ExpensesNotifier (mock `IExpenseRepository`, `ProviderContainer`)

- `build()` with empty filter → repository called with `cursor: null, filter: empty` → state = `AsyncData(ExpensesState(filter: empty, items: …, activeFilterChips: []))`.
- `applyFilter(f)` → state transitions `AsyncData → AsyncLoading → AsyncData(ExpensesState(filter: f, items: newItems, activeFilterChips: [...]))`. Repository called once with `cursor: null, filter: f`.
- `applyFilter` twice in a row with different filters → two distinct repository calls, second state reflects second filter.
- `searchChanged("Mer")` followed immediately by `searchChanged("Merc")` within debounce window → repository called **once** with description `"Merc"` after the debounce elapses. Test uses `fake_async` or `FakeAsync` to advance time.
- `searchChanged("")` while filter had `description: "Merc"` → repository called with `description: ""` after debounce.
- `removeFilter(ExpenseFilterChipKind.value)` → filter's `minValue` and `maxValue` nullified; repository called with the updated filter.
- `removeFilter(ExpenseFilterChipKind.ordering)` → filter's `ordering` reset to `dateDesc`.
- `loadMore` after `applyFilter(f)` → repository called with `cursor: state.nextCursor, filter: f`.
- `Left(NetworkFailure)` on first-page reload → state = `AsyncError(NetworkFailure)`.

The test SHALL use a fake `IMoneyService` with a deterministic `format` (e.g. `"R\$ ${value.toStringAsFixed(2)}"`) so `activeFilterChips` labels can be asserted.

#### ExpensesFiltersNotifier (mock nothing, pure state)

- Initial state: `draft == ExpenseFilterModel.empty()`, `selectedPreset == null`.
- `InitializeFrom(f)` where `f` has `startDate`/`endDate` matching `currentMonth.toRange(now: someFixedNow)` → `selectedPreset` SHALL be **null** (we do not reverse-engineer the preset from the dates on init — the UI simply shows `custom` highlighted if either bound is set, via a separate derived flag in the screen, OR no highlight at all). The test locks in the actually chosen behavior: `selectedPreset == null` on init.
- `PresetSelected(currentMonth)` with injected `now` → draft's dates match the preset's range; `selectedPreset == currentMonth`.
- `CategorySelected(food)` → draft.category == food; other fields untouched.
- `CategorySelected(null)` → draft.category cleared.
- `MinValueChanged(0)` or `MinValueChanged(null)` → draft.minValue cleared.
- `OrderingSelected(valueAsc)` → draft.ordering == valueAsc.
- `Cleared()` → draft == empty, selectedPreset == null.
- `dispatch` uses a switch expression — verified by the exhaustiveness of the test matrix (all Intent subtypes exercised).

The test for `now`-dependent presets SHALL accept a `DateTime` via a collaborator or override (e.g. the notifier takes a `DateTime Function() nowProvider` through a provider override in tests). Approach: add an `@riverpod DateTime nowProvider(Ref ref) => DateTime.now();` helper in `main/providers/services_provider.dart` (or a new `time_provider.dart`) and override it in tests.

#### Widget / integration tests

Out of scope for this change — project convention is notifier-level tests plus pure-Dart unit tests. No `flutter_test` screen tests are added.

#### Mocks

- `test/mocks/mocks.dart` already exposes `MockExpenseRepository` (from recent-expenses). Reuse it.
- Add `MockMoneyService` if not already present (it is — used by `ExpensesNotifier` tests introduced with list-all-expenses).

---

## Out of scope

- Persisting the last-used filter across app launches (SharedPreferences / local storage) — the filter resets to empty on fresh app start.
- Multi-select categories. The API only supports `eq(category,X)` (single). Multi-select would require either N parallel requests or client-side post-filtering that breaks cursor pagination; both are deferred.
- A saved-filters feature ("Meus filtros") or smart suggestions.
- Filtering by user/payer (not in the contract).
- A separate "sort" menu outside the bottom-sheet.
- Keyboard shortcut or voice input in the search field.
- Analytics / telemetry events for filter usage.
- Backend changes — RQL, ordering, and `page_size` already exist on the server.
- Updating the home's `RecentExpensesNotifier` to also accept filters — the home section intentionally shows the 4 globally most recent.
- Any change to `findRecent` or to `ExpensesPageModel` / `ExpenseModel` domain shapes. The model fields are unchanged.
- Error-handling UX in the chip strip (e.g. "filter produced no results" different from the existing empty state) — the existing `ExpensesEmptyWidget` covers an empty filtered list.

---

## Decisions (approved)

- **Single-select category**: approved. The API only supports `eq(category,X)`; multi-select is deferred.
- **Description filter lives outside the bottom-sheet**: approved as an always-visible search field in the app bar with a 400 ms debounce.
- **Bottom-sheet only triggers requests on "Aplicar"**: approved. Users can explore combinations inside the sheet without disturbing the list; only tapping "Aplicar" applies the draft.
- **Active-filter chip strip above the list**: approved. Rendered inside the `CustomScrollView` as a sliver between header and list.
- **Chip groups (category / period / value / ordering)**: approved. Description is represented by the search field, not by a chip. Period is one chip spanning both bounds; value is one chip spanning both bounds.
- **Draft filter lives in a separate notifier (`ExpensesFiltersNotifier`, MVI)**: approved. Isolates the sheet's state from the list's state.
- **RQL is embedded in the `Requests.path`, not in `queryParameters`**: approved. Dio's default encoder breaks RQL punctuation; manual embedding is clean and pure (covered by the `ExpenseFilterRqlBuilder` tests).
- **`page_size` default = 20**: approved. The screen does not expose it to the user.
- **Ordering default (`-date`) is still emitted on the wire when any filter is present**: approved — keeps the client's behavior explicit. Omitted when no filter is active, preserving today's paginated no-op behavior for load-more without filters.
- **Pull-to-refresh preserves the active filter**: approved — calls `applyFilter(currentFilter)` instead of `invalidate`.
- **Period presets**: approved — `currentMonth`, `last30Days`, `previousMonth`, `custom`. `custom` opens the range picker inline inside the same sheet (no nested sheet).
- **Value input in centavos + pt_BR formatting**: approved. Reuses the create-expense formatting pattern.
- **`now` injected via a provider for testability**: approved — adds `nowProvider` so preset ranges can be deterministically asserted.
- **`unknown` category is never selectable**: approved. It remains a fallback for server values we don't recognize but is never offered as a filter option.
