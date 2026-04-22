# Spec — recent-expenses-home-section

## Context

`ExpenseModel`, `ExpenseResponse`, `ExpenseResponseExtension`, `ExpenseRepository`, `IExpenseRepository` and `IRemoteExpenseDataSource` already exist in the project to support the **create-expense** flow. This change **extends** the existing domain/data/infrastructure layers and **adds** a read-path (list recent expenses) plus a new Home section. A placeholder file `lib/src/presentation/screens/home/widgets/expense/expense_widget.dart` exists with literal strings and SHALL be removed and replaced by the widgets defined here.

---

## Requirements

### Requirement: Extend ExpenseModel with category and createdAt
The system SHALL extend `ExpenseModel` (`lib/src/domain/models/expense_model.dart`) with two additional fields:
- `category: ExpenseCategory` — new domain enum.
- `createdAt: int` — milliseconds since epoch, mapped from the API field `created_at`.

`copyWith`, `props` (Equatable) and constructor SHALL be updated accordingly.

#### Scenario: Expense model exposes category and creation timestamp
Given an `ExpenseModel` is constructed
Then it SHALL expose non-nullable `category` (of type `ExpenseCategory`) and `createdAt` (int millis)
And `copyWith` SHALL allow overriding either field
And `props` SHALL include both fields for equality

---

### Requirement: ExpenseCategory domain enum
The system SHALL define `enum ExpenseCategory` in `lib/src/domain/models/expense_category.dart` with the following values and API wire strings:

| Enum value | API string |
|---|---|
| `food` | `food` |
| `transport` | `transport` |
| `shopping` | `shopping` |
| `health` | `health` |
| `housing` | `housing` |
| `debt` | `debt` |
| `entertainment` | `entertainment` |
| `unknown` | *(fallback only)* |

A `static ExpenseCategory fromString(String value)` method SHALL return the matching enum value, falling back to `ExpenseCategory.unknown` for any unmapped string without throwing.

#### Scenario: Unknown API category does not crash mapping
Given the API returns a category string that is not mapped (e.g. `"travel"`)
When `ExpenseCategory.fromString("travel")` is called
Then it SHALL return `ExpenseCategory.unknown`

---

### Requirement: Extend ExpenseResponse with category and created_at
The system SHALL extend `ExpenseResponse` (`lib/src/infrastructure/clients/http/responses/expense_response.dart`) with:
- `category: String` — read from JSON key `category`.
- `createdAt: String` — read from JSON key `created_at`.

Both fields SHALL be required in the constructor and read in `fromJson` as `json['category'] as String` / `json['created_at'] as String`. **No** `toModel` method SHALL be added to `ExpenseResponse` — mapping remains in `data/extensions/expense_response_extension.dart`.

#### Scenario: fromJson maps the extended payload
Given a JSON matching `{ "id": 129, "value": "85.50", "description": "Cafezinho com o meu amor", "date": "2026-04-15", "created_at": "2026-04-22T11:45:03.220605-03:00", "category": "food" }`
When `ExpenseResponse.fromJson(json)` is called
Then the returned instance SHALL expose all six fields as raw strings/ints with no type conversion

---

### Requirement: Extend ExpenseResponseExtension with category and createdAt mapping
The system SHALL update `ExpenseResponseExtension.toModel()` in `lib/src/data/extensions/expense_response_extension.dart` to map the two new fields:
- `category` (String) → `ExpenseCategory` via `ExpenseCategory.fromString`.
- `created_at` (ISO 8601 String with timezone) → `int` millis since epoch via `DateTime.parse(createdAt).millisecondsSinceEpoch`.

Existing mapping rules (value decimal → centavos, date `yyyy-MM-dd` → millis) SHALL remain unchanged.

#### Scenario: toModel maps the full payload
Given an `ExpenseResponse` with `value: "85.50"`, `date: "2026-04-15"`, `created_at: "2026-04-22T11:45:03.220605-03:00"`, `category: "food"`
When `toModel()` is called
Then the resulting `ExpenseModel` SHALL have `value == 8550`, `date == DateTime(2026,4,15).millisecondsSinceEpoch`, `createdAt == DateTime.parse("2026-04-22T11:45:03.220605-03:00").millisecondsSinceEpoch`, and `category == ExpenseCategory.food`

---

### Requirement: ExpensesResponse wrapper for list payload
The system SHALL add `lib/src/infrastructure/clients/http/responses/expenses_response.dart` containing `ExpensesResponse` with a single field `expenses: List<ExpenseResponse>`. `fromJson` SHALL read the API key `results` and map each entry via `ExpenseResponse.fromJson`. Fields `next` and `previous` SHALL be **ignored** — pagination is out of scope for this version.

#### Scenario: ExpensesResponse.fromJson parses the results array
Given a JSON `{ "next": "...", "previous": null, "results": [ { ... }, { ... } ] }`
When `ExpensesResponse.fromJson(json)` is called
Then the returned instance SHALL expose `expenses` with the two items mapped via `ExpenseResponse.fromJson`

---

### Requirement: Extend IExpenseRepository and ExpenseRepository with findRecent
The system SHALL add `Future<Either<Failure, List<ExpenseModel>>> findRecent({int limit = 4})` to `IExpenseRepository` (`lib/src/domain/repositories/interface_expense_repository.dart`) and implement it in `ExpenseRepository` (`lib/src/data/repositories/expense_repository.dart`).

The implementation SHALL:
- Call `_dataSource.findRecent(limit: limit)` returning `Either<FailureResponse, ExpensesResponse>`.
- On `Left`: convert via `FailureResponseExtension.toFailure()`.
- On `Right`: take the first `limit` entries of `response.expenses` and map each via `ExpenseResponseExtension.toModel()` — preserve the order returned by the API (which is `created_at desc`).

The existing `create` method SHALL remain unchanged.

#### Scenario: findRecent maps response to domain models with slicing
Given the datasource returns `Right(ExpensesResponse)` with 20 entries
When `ExpenseRepository.findRecent(limit: 4)` is called
Then the repository SHALL return `Right(List<ExpenseModel>)` with length 4
And the first item SHALL correspond to the first JSON entry (most recent)

#### Scenario: findRecent converts FailureResponse to Failure
Given the datasource returns `Left(FailureResponse)` with `code: "network_error"`
When `ExpenseRepository.findRecent()` is called
Then the repository SHALL return `Left(NetworkFailure)`

---

### Requirement: Extend IRemoteExpenseDataSource with findRecent
The system SHALL add `Future<Either<FailureResponse, ExpensesResponse>> findRecent({required int limit})` to `IRemoteExpenseDataSource` and implement it in `RemoteExpenseDataSource` (`lib/src/infrastructure/datasources/remote/remote_expense_data_source.dart`).

The implementation SHALL:
- Call `_client.get(parameter: Requests(path: EndpointKey.expenses.path))`.
- Deserialize both sides of the returned `Either<Map, Map>` via `response.either(FailureResponse.fromJson, ExpensesResponse.fromJson)`.
- Use existing `EndpointKey.expenses` entry (already declared) — no new endpoint key is required.
- **Not** pass `limit` as a query param in this version — the API is paginated server-side and the repository slices client-side.

The interface method accepts a primitive `int limit` (domain type), never a DTO.

#### Scenario: Datasource issues a GET to the expenses endpoint
Given `findRecent(limit: 4)` is invoked
When the method runs
Then `_client.get` SHALL be called with `Requests` pointing at `EndpointKey.expenses.path`
And the response SHALL be forwarded as `Either<FailureResponse, ExpensesResponse>` via the standard `either` deserialization

---

### Requirement: RecentExpensesNotifier loads 4 most-recent expenses on Home mount
The system SHALL add `RecentExpensesNotifier` as an `AsyncNotifier<List<ExpenseModel>>` at `lib/src/presentation/screens/home/notifiers/recent_expenses_notifier.dart`, generated via `@riverpod` (file `recent_expenses_notifier.g.dart`).

`build()` SHALL:
- Read `_repository` via `ref.watch(expenseRepositoryProvider)` (field marked `late`, **never** `late final`).
- Invoke `await _repository.findRecent(limit: 4)`.
- On `Right`: return the `List<ExpenseModel>`.
- On `Left`: rethrow the `Failure` so the provider transitions to `AsyncError` (same pattern as `InsightsNotifier`).

The notifier SHALL expose **no** intents or mutators — it is a pure read notifier.

#### Scenario: Screen mounts and notifier loads recent expenses
Given the user lands on the Home screen
When `RecentExpensesNotifier.build()` runs
Then `IExpenseRepository.findRecent(limit: 4)` SHALL be called exactly once
And the provider SHALL transition from `AsyncLoading` to either `AsyncData(List<ExpenseModel>)` or `AsyncError`

---

### Requirement: RecentExpensesSectionWidget renders on the Home below InsightsCarousel
The system SHALL add `RecentExpensesSectionWidget` at `lib/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_section_widget.dart` as a `StatelessWidget` receiving the provider state as an `AsyncValue<List<ExpenseModel>>` via constructor (named required `state`).

It SHALL render a header row containing:
- A title "Despesas recentes" on the left (`context.typography.titleMedium` with `FontWeight.w600`).
- A `ButtonWidget.text(label: 'Ver tudo', onTap: () {})` on the right — the button SHALL exist with an empty `onTap` callback. Navigation to a full list screen is **out of scope**.

Below the header, the content SHALL switch over the `AsyncValue`:
- `AsyncLoading()` → `RecentExpensesLoadingWidget` (skeleton of 3 item rows using `Skeletonizer`).
- `AsyncError()` → `RecentExpensesFailureWidget` with a short message "Não foi possível carregar as despesas." and a `ButtonWidget.text(label: 'Tentar novamente')` that calls `ref.refresh(recentExpensesProvider)`.
- `AsyncData(value)` with `value.isEmpty` → `RecentExpensesEmptyWidget` with title "Ainda sem despesas" and description "Suas despesas mais recentes aparecerão aqui.".
- `AsyncData(value)` with `value.isNotEmpty` → a `Column` of `ExpenseItemWidget`, one per model (up to 4).

The section SHALL be inserted in `lib/src/presentation/screens/home/home_screen.dart` inside the `ListView.children`, **immediately after** `InsightsCarouselWidget`. The Home `Consumer` SHALL read `ref.watch(recentExpensesProvider)` and pass the resulting `AsyncValue` to the widget.

Padding SHALL mirror the existing sections (16.0 horizontal).

#### Scenario: Section title and "Ver tudo" are always visible
Given the section renders in any state
Then the "Despesas recentes" title SHALL appear on the left
And the "Ver tudo" `ButtonWidget.text` SHALL appear on the right

#### Scenario: Success state renders at most 4 items
Given the provider exposes `AsyncData([e1, e2, e3, e4, e5])`
When the section renders
Then exactly 4 `ExpenseItemWidget` instances SHALL be rendered
And they SHALL follow the order received from the notifier

#### Scenario: Empty state
Given the provider exposes `AsyncData([])`
Then `RecentExpensesEmptyWidget` SHALL render with the defined title and description

#### Scenario: Failure state with retry
Given the provider is in `AsyncError`
Then `RecentExpensesFailureWidget` SHALL render the error message and a "Tentar novamente" button
When the user taps the retry button
Then `ref.refresh(recentExpensesProvider)` SHALL be invoked, causing the provider to re-enter `AsyncLoading`

---

### Requirement: ExpenseItemWidget layout and formatting
The system SHALL add `ExpenseItemWidget` at `lib/src/presentation/screens/home/widgets/recent_expenses/expense_item_widget.dart` as a `StatelessWidget` receiving `ExpenseModel expense` and `IMoneyService moneyService` as named required constructor parameters.

The layout SHALL be a horizontal row with:
- **Leading**: `BackgroundIconWidget` (reusing the existing widget used by `InsightIconWidget`) displaying `expense.category.icon` with `expense.category.color(context)` at 15% alpha background and full-strength foreground.
- **Center** (Expanded — this is the region that SHALL shrink first when space is tight): two stacked `Text`s —
  - Line 1: `expense.description` using `context.typography.bodyMedium` with `FontWeight.w600`, truncated to 1 line with ellipsis (`softWrap: false, overflow: TextOverflow.ellipsis`). Long descriptions SHALL be cut with `…` — the value is the most important element and SHALL never be compressed.
  - Line 2: `categoryLabel` only (no date/time) using `context.typography.bodySmall` with `context.colors.onSurfaceVariant`, also truncated to 1 line with ellipsis.
- **Trailing** (intrinsic width, never shrinks): a `Column` aligned to the end with two stacked `Text`s —
  - Line 1: formatted amount `moneyService.format(expense.value / 100)` using `context.typography.bodyMedium` with `FontWeight.w600`.
  - Line 2: a composed string `"{dd/MM} · {HH:mm}"` using `context.typography.bodySmall` with `context.colors.onSurfaceVariant`. `dd/MM` and `HH:mm` come from `intl`'s `DateFormat('dd/MM', 'pt_BR')` and `DateFormat('HH:mm', 'pt_BR')` applied to `DateTime.fromMillisecondsSinceEpoch(expense.createdAt)`.

Vertical padding SHALL be 12.0; horizontal padding matches the section (16.0). Row spacing 12.0.

#### Scenario: Item renders description and category on the left; value and date/time on the right
Given `ExpenseModel(description: "Cafezinho com o meu amor", value: 8550, category: ExpenseCategory.food, createdAt: millis of 2026-04-22T18:42:00-03:00)` and a `MoneyService` that formats `85.50` as `"R$ 85,50"`
When `ExpenseItemWidget` builds
Then the center SHALL show "Cafezinho com o meu amor" on line 1 and "Alimentação" on line 2
And the trailing SHALL show "R$ 85,50" on line 1 and "22/04 · 18:42" on line 2

#### Scenario: Long description is truncated with ellipsis without compressing the value
Given an expense whose description is wider than the available center column
Then the description SHALL render with a trailing `…`
And the trailing amount + date/time SHALL render at their intrinsic width, uncompressed

---

### Requirement: Category visual mapping (icon + color + label)
The system SHALL add `lib/src/presentation/screens/home/widgets/recent_expenses/expense_category_visual_extension.dart` with an extension `ExpenseCategoryVisualExtension on ExpenseCategory` exposing:
- `IconData get icon`
- `Color color(BuildContext context)` (takes `BuildContext` so it can read `context.colors`)
- `String get label` (pt_BR label)

Mapping:

All colors are semantic tokens from `context.colors` (Material 3 `ColorScheme` exposed by `flex_color_scheme`). Some categories intentionally share a token — differentiation relies primarily on the icon and label.

| Enum value | Icon | Color token | Label |
|---|---|---|---|
| `food` | `Icons.restaurant_outlined` | `context.colors.tertiary` | Alimentação |
| `transport` | `Icons.directions_car_outlined` | `context.colors.primary` | Transporte |
| `shopping` | `Icons.shopping_bag_outlined` | `context.colors.secondary` | Compras |
| `health` | `Icons.favorite_outline` | `context.colors.error` | Saúde |
| `housing` | `Icons.home_outlined` | `context.colors.tertiary` | Moradia |
| `debt` | `Icons.account_balance_outlined` | `context.colors.error` | Dívidas |
| `entertainment` | `Icons.movie_outlined` | `context.colors.secondary` | Lazer |
| `unknown` | `Icons.receipt_long_outlined` | `context.colors.outline` | Despesa |

#### Scenario: Category visual lookup is exhaustive
Given any `ExpenseCategory` value
Then `icon`, `color(context)` and `label` SHALL return a non-null value without falling through a default branch (the switch expression SHALL be exhaustive)

---

### Requirement: Provider wiring
The system SHALL add `recentExpensesProvider` (auto-generated from `@riverpod` on `RecentExpensesNotifier`) and ensure `expenseRepositoryProvider` and `remoteExpenseDataSourceProvider` are either already present or added in `lib/src/main/providers/`.

If provider files for `Expense` already exist (they do for `create-expense`), the existing file SHALL be reused — **no** duplicate provider files. The new notifier provider SHALL live alongside its notifier under `presentation/screens/home/notifiers/` and be exported through code generation.

#### Scenario: Provider container resolves the full dependency chain
Given a fresh `ProviderContainer`
When `recentExpensesProvider` is read
Then the chain `RecentExpensesNotifier → IExpenseRepository → IRemoteExpenseDataSource → IHttpClient` SHALL resolve without missing overrides in production wiring

---

### Requirement: Placeholder widget removal
The file `lib/src/presentation/screens/home/widgets/expense/expense_widget.dart` (placeholder with literal strings `'data.description'`, `'data.date'`, `'data.formattedAmount'`) SHALL be deleted as part of this change. Any import of it SHALL be removed. The directory `presentation/screens/home/widgets/expense/` SHALL also be removed if it becomes empty.

#### Scenario: No references to the placeholder remain
Given the change is implemented
Then `grep -r "expense_widget.dart"` under `lib/` SHALL return no matches
And `ExpenseWidget` SHALL no longer be defined anywhere

---

### Requirement: API contract
`GET /api/v1/expenses` — requires Bearer token. No query params are sent in this version.

Response (200):
```json
{
  "next": "http://.../expenses?cursor=...",
  "previous": null,
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

Error response (standard `FailureResponse`):
```json
{ "errors": [ { "field": "string", "message": "string", "code": "string" } ] }
```

The API returns `results` ordered by `created_at desc`. The repository takes the first `limit` entries and preserves that order. `next` and `previous` are ignored.

Status code → failure mapping follows the existing `FailureResponseExtension.toFailure()` via `FailureCodeResponse` (`network_error`, `server_error`, `not_found`, other → `ValidationFailure(message)`, unknown → `UnknownFailure`).

---

### Requirement: Clean Architecture layering
The feature SHALL follow the project's layered dependency rules:
- `domain/` defines `ExpenseCategory`, the extended `ExpenseModel`, and the extended `IExpenseRepository` (zero Flutter, zero infrastructure).
- `infrastructure/` defines the extended `ExpenseResponse`, the new `ExpensesResponse` (`fromJson` only), and the extended `IRemoteExpenseDataSource` + `RemoteExpenseDataSource`.
- `data/` defines the extended `ExpenseRepository` and the extended `ExpenseResponseExtension.toModel()`; `FailureResponse → Failure` via the shared `FailureResponseExtension.toFailure()`.
- `presentation/` defines `RecentExpensesNotifier` (AsyncNotifier) and widgets under `presentation/screens/home/widgets/recent_expenses/`, plus the category visual extension.
- `main/providers/` wires datasource, repository and notifier providers.

No `ConsumerWidget` SHALL be introduced. All notifier dependencies SHALL come via `ref.watch` in `build()`, using `late` (not `late final`). All switches SHALL use switch expressions (no switch statements). No private widget classes (`class _FooWidget`) SHALL be declared inside another widget file.

---

### Requirement: Tests

#### ExpenseResponse.fromJson (pure Dart)
- Given a JSON payload containing all six fields (including `category` and `created_at`) → all fields are exposed as raw strings/ints.
- Missing `category` or `created_at` key → the test SHALL document current behavior (throws `TypeError`); keys are required in this version.

#### ExpensesResponse.fromJson (pure Dart)
- Given a JSON with `results: []` → `expenses` SHALL be an empty list.
- Given a JSON with `results: [ {…}, {…} ]` → `expenses.length == 2` and each entry is parsed via `ExpenseResponse.fromJson`.
- Extra fields (`next`, `previous`) SHALL be ignored without error.

#### ExpenseResponseExtension.toModel (pure Dart)
- `"85.50"` → `8550`; `"1200.00"` → `120000`; `"19.24"` → `1924`.
- `date: "2026-04-15"` → `DateTime(2026, 4, 15).millisecondsSinceEpoch`.
- `created_at: "2026-04-22T11:45:03.220605-03:00"` → `DateTime.parse(...).millisecondsSinceEpoch`.
- `category: "food"` → `ExpenseCategory.food`; `"travel"` (unknown) → `ExpenseCategory.unknown`.

#### ExpenseRepository.findRecent (mock `IHttpClient`)
- GET 200 with ≥ 4 results → `Right(List<ExpenseModel>)` of length 4, preserving order.
- GET 200 with empty `results` → `Right([])`.
- GET 200 with fewer than 4 results → `Right` with the actual length (no padding).
- Error with `code: "network_error"` → `Left(NetworkFailure)`.
- Error with `code: "server_error"` → `Left(ServerFailure)`.
- Error with `code: "not_found"` → `Left(NotFoundFailure)`.
- Error with a custom code + message → `Left(ValidationFailure(message))`.

#### RecentExpensesNotifier (mock `IExpenseRepository`, `ProviderContainer`)
- `build()` with `Right(List<ExpenseModel>)` → `AsyncData<List<ExpenseModel>>`.
- `build()` with `Left(NetworkFailure)` → `AsyncError` with error of type `NetworkFailure`.
- `build()` with empty list → `AsyncData([])`.
- Test descriptions SHALL be in English; `group` per scenario; `addTearDown(container.dispose)`.

#### ExpenseCategory.fromString (pure Dart)
- Each valid API string maps to the matching enum value.
- Any other string maps to `ExpenseCategory.unknown` (no throw).

#### Mocks
- `test/mocks/mocks.dart` SHALL add `MockExpenseRepository extends Mock implements IExpenseRepository` and `MockRemoteExpenseDataSource extends Mock implements IRemoteExpenseDataSource` following the existing pattern.

---

## Out of scope

- The "Ver tudo" destination screen, `ExpensesLocation`, and any navigation wiring — the button SHALL render with an empty `onTap`. Creating the full-list screen requires a separate change.
- Rendering a user avatar / badge per item — the API does not currently expose a `user` field. To be revisited when the backend contract is extended.
- Pagination (cursor traversal via `next` / `previous`) and infinite scroll.
- RQL date filters (`ge`, `le`, etc.) — server returns the first page ordered `created_at desc`, which is sufficient for 4 items.
- Edit / delete expense flows.
- Pull-to-refresh on the Home or periodic background refresh.
- Localized currency other than pt_BR.
- Backend changes of any kind.

---

## Decisions (approved)

- **Extending `ExpenseModel`**: approved. `ExpenseModel` is rewritten with `category` and `createdAt` as non-nullable fields. The `create-expense` flow and its tests are updated to propagate the new fields (the POST response exposes them as well).
- **Placeholder `expense_widget.dart`**: approved for removal. The file and its directory are deleted as part of this change.
- **Category colors**: approved — semantic tokens from `context.colors` (Material 3 `ColorScheme` via `flex_color_scheme`). Some categories share a token; differentiation relies on icon + label.
- **Section title**: approved — `"Despesas recentes"` with `context.typography.titleMedium` and `FontWeight.w600`.
- **Empty-state copy**: approved — `"Ainda sem despesas"` / `"Suas despesas mais recentes aparecerão aqui."`.
- **Date format in item subtitle**: approved — always `"{categoryLabel} · dd/MM · HH:mm"` in pt_BR. No `"hoje"` / `"ontem"` / weekday variants. No dedicated helper; formatted inline with `intl`.
