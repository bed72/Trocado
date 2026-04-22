# Spec — insights-home-carousel

## Requirements

### Requirement: Auto-load on Home mount
The system SHALL load insights from `GET /api/v1/insights` when the `HomeScreen` mounts, via an `AsyncNotifier` whose `build()` calls `IInsightsRepository.findAll()`.
The notifier SHALL re-throw `Failure` on `Left` so the provider transitions to `AsyncError`, and SHALL return `InsightsBundleModel` on `Right`.

#### Scenario: Screen opens and insights are loaded
Given the user lands on the Home screen
When `InsightsNotifier.build()` runs
Then `IInsightsRepository.findAll()` SHALL be called once
And the provider SHALL transition from `AsyncLoading` to either `AsyncData` or `AsyncError`

---

### Requirement: Horizontal carousel UI
The system SHALL render an `InsightsCarouselWidget` below the `BudgetCard` in the Home `ListView`, containing a section title "Insights" and the state-dependent content.
The content SHALL be one of: loading skeleton, empty placeholder, failure placeholder, or horizontal `ListView.separated` of insight cards.
Each card SHALL be 300dp wide with a circular icon (40–48dp) on the left, a short title derived from `InsightType` in pt_BR, and the raw `message` truncated to 2 lines with ellipsis.

#### Scenario: Section title always visible
Given the carousel renders in any state
Then a "Insights" title SHALL appear above the state-dependent content

#### Scenario: Successful render with multiple insights
Given the repository returns `Right(bundle)` with non-empty `insights` and `hasEnoughData = true`
Then the carousel SHALL render a horizontal scrollable list of `InsightCardWidget`
And each card SHALL display the icon, title, and message (truncated)

---

### Requirement: Card tap opens detail bottom sheet
The system SHALL make each `InsightCardWidget` tappable; tapping SHALL open a bottom sheet via `bottomSheetScaffoldWidget` with the insight title as sheet title and `InsightDetailSheetWidget` (icon + full `message`) as body.

#### Scenario: User taps a truncated card
Given a card displays the message truncated to 2 lines
When the user taps the card
Then a bottom sheet SHALL appear with the derived title and the full message without truncation

---

### Requirement: Empty state
The system SHALL render `InsightsCarouselEmptyWidget` when `AsyncData.value.insights.isEmpty`.
The empty widget SHALL mirror the card layout (circular icon, short title, short description) without a CTA.

#### Scenario: Backend returns no insights
Given the repository returns `Right(bundle)` with `insights = []`
Then the empty placeholder SHALL render with title "Ainda sem insights" and description "Registre mais despesas para liberar sugestões."

---

### Requirement: Failure state with retry
The system SHALL render `InsightsCarouselFailureWidget` when the provider is in `AsyncError`, with a circular error-colored icon, a short title "Não foi possível carregar os insights.", and a `ButtonWidget.text` labeled "Tentar novamente".
Pressing the button SHALL call `ref.refresh(insightsProvider)`.

#### Scenario: Repository failure
Given the repository returns `Left(Failure)`
Then the carousel SHALL render the failure placeholder
When the user presses "Tentar novamente"
Then the provider SHALL re-enter `AsyncLoading` and re-invoke `IInsightsRepository.findAll()`

---

### Requirement: Loading state
The system SHALL render `InsightsCarouselLoadingWidget` while the provider is in `AsyncLoading`, using `Skeletonizer` over 3 placeholder `InsightCardWidget` instances with the same horizontal layout as the success state.

#### Scenario: Initial load
Given the screen just mounted and the repository has not responded
Then a shimmering skeleton of 3 insight cards SHALL be visible

---

### Requirement: API contract
`GET /api/v1/insights` — requires Bearer token.

Response (200):
```json
{
  "insights": [
    {
      "type": "budget_utilization | will_overspend | daily_average | top_category",
      "severity": "danger | warning | info",
      "message": "string",
      "data": { "...": "varies by type" }
    }
  ],
  "has_enough_data": false,
  "generated_at": "2026-04-22T18:24:36.544845+00:00"
}
```

`data` shape by `type`:
- `budget_utilization`: `{ budget_value, total_spent, budget_pct, period_pct }`
- `will_overspend`: `{ budget_value, total_spent, daily_rate, days_until_overspend }`
- `daily_average`: `{ actual_daily_rate, ideal_daily_rate }`
- `top_category`: `{ category, pct }`

Error format: `{ "errors": [{ "field", "message", "code" }] }` — standard `FailureResponse`.

Unknown `type` or `severity` values SHALL map to `InsightType.unknown` / `InsightSeverity.unknown` without throwing.
`generated_at` is converted from ISO 8601 `String` to `DateTime` via `DateTime.parse` in the `InsightsResponseExtension.toModel()` mapping.
`data` is preserved as `Map<String, dynamic>` in `InsightModel` — no typed subclasses per `type` in this version.

---

### Requirement: pt_BR card titles
The system SHALL map `InsightType` to a pt_BR title via a shared `titleFor(InsightType)` function used by both `InsightCardWidget` and the detail bottom sheet.

| `InsightType` | Title |
|---|---|
| `budgetUtilization` | Uso do orçamento |
| `willOverspend` | Projeção de gasto |
| `dailyAverage` | Média diária |
| `topCategory` | Categoria em destaque |
| `unknown` | Insight |

---

### Requirement: Icon and color per insight
The system SHALL render `InsightIconWidget` with:
- An icon derived from `InsightType` (`pie_chart_outline`, `schedule`, `show_chart`, `trending_up`, `lightbulb_outline` for unknown).
- A foreground color derived from `InsightSeverity` (`colors.error` for `danger`, `Colors.amber` for `warning`, `colors.primary` for `info`, `colors.outline` for `unknown`).
- A circular background using the foreground color at 15% alpha.

---

### Requirement: Clean Architecture layering
The insights feature SHALL follow the project's layered dependency rules:
- `domain/` defines `InsightModel`, `InsightsBundleModel`, `InsightType`, `InsightSeverity`, and `IInsightsRepository` (zero Flutter, zero infrastructure).
- `infrastructure/` defines `InsightItemResponse`, `InsightsResponse` (`fromJson` only), and `IRemoteInsightsDataSource` (returns `Either<FailureResponse, InsightsResponse>`).
- `data/` defines `InsightsRepository` and the `InsightsResponseExtension.toModel()` / `InsightItemResponseExtension.toModel()` mappings; `FailureResponse → Failure` via the shared `FailureResponseExtension.toFailure()`.
- `presentation/` defines the `InsightsNotifier` (AsyncNotifier) and widgets under `presentation/screens/home/widgets/insights/`.
- `main/providers/` wires `remoteInsightsDataSourceProvider` and `insightsRepositoryProvider`.

---

### Requirement: Previews
The system SHALL expose `@Preview` functions for each state (loading, empty, failure, success with 1 insight, success with all types, success with info-only) in `insights_carousel_widget_preview.dart`, using `MaterialPreviewWidget` as the host.

---

### Out of scope
- Tap-driven navigation or dismiss for cards beyond the detail bottom sheet.
- Typed subclasses for the `data` field per `InsightType`.
- Pull-to-refresh, periodic refresh, or local cache.
- Animations on enter/exit.
- Reading individual `data` fields to enrich the card (e.g., showing `pct` numerically).
