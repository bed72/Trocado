# Spec — budget-period-long-format

## Context

`IDateFormatterService.formatPeriod(int startMillis, int endMillis) → String` já existe e hoje devolve `'dd/MM – dd/MM'` (ano corrente) ou `'dd/MM/yy – dd/MM/yy'` (cruzando ano). É consumido em três lugares:

- `BudgetFormNotifier` (`lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart`) — popula `BudgetFormState.formattedPeriod` no `build()` e a cada `DateRangeChanged`.
- `BudgetsNotifier._toItem` (`lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart`) — popula `BudgetItemPresentationData.formattedPeriod` para cada card da lista de orçamentos passados.
- `BudgetsLoadingWidget` (`lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart`) — usa o literal `'00/00 – 00/00'` como placeholder no skeleton.

Esta change reescreve **apenas** a implementação de `formatPeriod` em `DateFormatterService` e atualiza o placeholder do loading. Nenhum consumer muda. `formatLongDate` (que já tem a regra de ano contextual) é a referência conceitual mas **não** é chamado a partir de `formatPeriod` — a regra é implementada inline com os mesmos formatters (`_dayMonthAbbrev`, ano explícito) para evitar acoplamento entre métodos do service.

---

## Requirements

### Requirement: formatPeriod renders single-day ranges as a long single date

The system SHALL detect when `startMillis` and `endMillis` represent the same calendar day (in the local timezone, after normalizing both to start-of-day via `DateTime(year, month, day)`) and return the long-date representation of that single day.

The single-day representation SHALL follow the exact rule of `formatLongDate`:
- `'{dd} de {Mmm}'` when the day's year equals `_now().year`.
- `'{dd} de {Mmm} de {yyyy}'` otherwise.

Where `dd` is zero-padded and `Mmm` is the pt_BR three-letter month abbreviation capitalized, without trailing dot (e.g., `Jan`, `Mai`, `Dez`).

#### Scenario: Same day in current year collapses to single long date

Given `_now()` returns a date in 2026
And `start = end = DateTime(2026, 5, 20).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'20 de Mai'`

#### Scenario: Same day in non-current year collapses with year

Given `_now()` returns a date in 2026
And `start = end = DateTime(2027, 5, 20).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'20 de Mai de 2027'`

#### Scenario: Same day computed with different intra-day millis still collapses

Given `_now()` returns a date in 2026
And `start = DateTime(2026, 5, 20, 0, 0).millisecondsSinceEpoch`
And `end = DateTime(2026, 5, 20, 23, 59, 59).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'20 de Mai'` (the comparison normalizes to start-of-day before deciding)

---

### Requirement: formatPeriod renders ranges within the current year without years

The system SHALL render ranges where `start` and `end` are different calendar days **and** both years equal `_now().year` as `'{dd} de {Mmm} até {dd} de {Mmm}'`, with no year on either side.

#### Scenario: Range within the current year

Given `_now()` returns a date in 2026
And `start = DateTime(2026, 5, 12).millisecondsSinceEpoch`
And `end = DateTime(2026, 5, 20).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'12 de Mai até 20 de Mai'`

#### Scenario: Range within the current year across different months

Given `_now()` returns a date in 2026
And `start = DateTime(2026, 1, 5).millisecondsSinceEpoch`
And `end = DateTime(2026, 12, 31).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'05 de Jan até 31 de Dez'`

---

### Requirement: formatPeriod renders year-crossing ranges with year only on the end

The system SHALL render ranges where `start.year == _now().year` and `end.year != _now().year` as `'{dd} de {Mmm} até {dd} de {Mmm} de {end.year}'`. The start side SHALL NOT carry a year — it is implicit as the current year. The end side SHALL include its full four-digit year.

This requirement covers the canonical "budget that bridges the year-end" case (e.g., `20/12/2026 → 25/01/2027` when today is in 2026).

#### Scenario: Range from current year into next year shows year only on end

Given `_now()` returns a date in 2026
And `start = DateTime(2026, 12, 20).millisecondsSinceEpoch`
And `end = DateTime(2027, 1, 25).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'20 de Dez até 25 de Jan de 2027'`

#### Scenario: Range from last day of current year into next year

Given `_now()` returns a date in 2026
And `start = DateTime(2026, 12, 31).millisecondsSinceEpoch`
And `end = DateTime(2027, 1, 1).millisecondsSinceEpoch`
When `formatPeriod(start, end)` is called
Then it SHALL return `'31 de Dez até 01 de Jan de 2027'`

---

### Requirement: Separator is " até " (lowercase, with spaces)

All range outputs of `formatPeriod` SHALL use the literal string `' até '` (a single space, the word `até` in lowercase, a single space) as the separator between the two formatted dates. The previous en-dash `–` SHALL NOT appear anywhere in the output.

#### Scenario: Separator is the Portuguese word "até"

Given any range where `start != end` at day level
When `formatPeriod(start, end)` is called
Then the returned string SHALL contain ` até ` exactly once
And SHALL NOT contain the character `–` (U+2013)

---

### Requirement: BudgetsLoadingWidget placeholder matches the new format

The placeholder string in `lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart` previously set to `'00/00 – 00/00'` SHALL be updated to `'00 de Mmm até 00 de Mmm'` so the skeleton width approximates the rendered range in the common case (range within current year).

The loading widget SHALL continue to feed this literal into the same `formattedPeriod` slot of the mock `BudgetItemPresentationData` — no structural change to the widget.

#### Scenario: Loading placeholder reflects new format width

Given `BudgetsLoadingWidget` is rendered
Then the placeholder for `formattedPeriod` SHALL be `'00 de Mmm até 00 de Mmm'`
And no occurrence of `'00/00'` SHALL remain in the file

---

### Requirement: Public contract of IDateFormatterService is unchanged

`IDateFormatterService.formatPeriod(int startMillis, int endMillis) → String` SHALL keep the same signature, the same parameter names, the same return type, and the same location in `lib/src/domain/services/date_formatter_service.dart`. No new method SHALL be added. No method SHALL be removed.

The change is purely internal to the concrete implementation `DateFormatterService` (`lib/src/infrastructure/services/date_formatter_service.dart`).

#### Scenario: Interface file is untouched

Given the change is applied
Then `git diff lib/src/domain/services/date_formatter_service.dart` SHALL return zero lines
And `IDateFormatterService.formatPeriod` SHALL still be the only period-formatting method on the interface

---

### Requirement: Budget-side consumers are not modified

The following files SHALL NOT be modified by this change (they consume `formatPeriod` and the rendered `formattedPeriod` string transparently):

- `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart`
- `lib/src/presentation/ui/budget/notifiers/form/budget_form_state.dart`
- `lib/src/presentation/ui/budget/screens/budget_screen.dart`
- `lib/src/presentation/ui/budget/widgets/budget_date_field_widget.dart` (or equivalent date-field widget for the budget form)
- `lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart`
- `lib/src/presentation/ui/budgets/data/budget_item_presentation_data.dart`
- `lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart`

These files are explicitly out of the budget-period rollout — their consumption of `formatPeriod` already produces the new format transparently.

---

### Requirement: Tests

The existing `group('formatPeriod', ...)` block in `test/src/infrastructure/services/date_formatter_service_test.dart` SHALL be replaced by tests that cover the new rule. The three existing cases (`'01/01 – 31/12'`, `'01/12/25 – 31/01/26'`, `'01/11/26 – 31/01/27'`) SHALL be removed — they describe the old contract.

The new tests SHALL cover, with `_now()` fixed at `DateTime(2026, 5, 12, 14, 30)` (already set up in `setUp`):

- Single day in current year → `'20 de Mai'`.
- Single day in non-current year → `'20 de Mai de 2027'`.
- Same calendar day with different intra-day times → still collapses to single long date.
- Range within current year, same month → `'12 de Mai até 20 de Mai'`.
- Range within current year, different months → `'05 de Jan até 31 de Dez'`.
- Range from current year into next year → `'20 de Dez até 25 de Jan de 2027'`.
- Range from last day of current year into next year → `'31 de Dez até 01 de Jan de 2027'`.
- Output for any range with distinct days SHALL contain the literal `' até '` and SHALL NOT contain `'–'`.

Test descriptions SHALL be in English. The `group('formatPeriod', ...)` label SHALL remain.

---

### Requirement: Deferred cases are explicitly out of scope

The following date-range shapes are **not** covered by this change. If `formatPeriod` is called with one of these shapes, the current rules above produce a best-effort output that is acceptable as a temporary behavior pending a follow-up spec:

- **Both dates in the same non-current year** (e.g., `start = 10/05/2025`, `end = 20/05/2025` when `_now().year == 2026`): falls through neither the "same current year" rule nor the "cross-year" rule. Implementation SHALL produce `'10 de Mai até 20 de Mai de 2025'` (year only on the end), mirroring the cross-year shape — but this output is provisional and subject to revision.
- **Range crossing more than one year boundary** (e.g., `start = 10/12/2025`, `end = 20/01/2027` when `_now().year == 2026`): SHALL produce `'10 de Dez até 20 de Jan de 2027'` (year only on end, ignoring that start is also non-current). Provisional.
- **Range entirely in the past relative to current year, crossing a year boundary within the past** (e.g., `start = 20/12/2024`, `end = 25/01/2025`): SHALL produce `'20 de Dez até 25 de Jan de 2025'`. Provisional.

These cases SHALL NOT block the change. A separate follow-up will decide the canonical rendering once a real product case surfaces.

#### Scenario: Deferred case renders a non-crashing string

Given any of the deferred shapes above
When `formatPeriod(start, end)` is called
Then it SHALL return a non-empty string ending with the four-digit year of `end`
And SHALL NOT throw

---

### Requirement: ExpensesFiltersNotifier renders the period summary via formatPeriod

`ExpensesFiltersNotifier._summaryOf` (`lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart`) SHALL replace its current implementation — which calls `_dateFormatter.formatShortDate` twice and joins with `' – '` — by a single call to `_dateFormatter.formatPeriod(draft.startDate!, draft.endDate!)`.

The null-guard (returning `null` when either bound is missing) SHALL be preserved.

#### Scenario: Filter summary inherits the long format

Given the user selects the preset `Últimos 30 dias`
And `_now()` returns `2026-05-18`
Then the filter screen footer SHALL render the summary as `'18 de Abr até 18 de Mai'`
And SHALL NOT contain `'/'` or `'–'`

#### Scenario: Filter summary collapses single day

Given `start = end = 2026-05-18` (custom range with a single day picked)
Then the summary SHALL render as `'18 de Mai'`

#### Scenario: Filter summary handles year crossing

Given `start = 2026-12-20`, `end = 2027-01-25`, `_now()` in 2026
Then the summary SHALL render as `'20 de Dez até 25 de Jan de 2027'`

---

### Requirement: ExpensesNotifier renders the period chip via formatPeriod (both-bound) or formatLongDate (one-sided)

`ExpensesNotifier._periodLabel` (`lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`) SHALL be rewritten as:

- When both `start` and `end` are non-null: return `_dateFormatter.formatPeriod(start, end)`.
- When only `start` is non-null: return `'desde ${_dateFormatter.formatLongDate(start)}'`.
- When only `end` is non-null: return `'até ${_dateFormatter.formatLongDate(end)}'`.

The three branches SHALL be expressed as a switch expression over `(start, end)` (or equivalent pattern destructure), consistent with the project's switch-expression rule. No call to `formatShortDate` SHALL remain in the file.

#### Scenario: Active filter chip uses the new range format

Given the user applies the preset `Mês passado`
And the resulting filter has `start = 2026-04-01`, `end = 2026-04-30`
Then the active filter chip for `period` SHALL render `'01 de Abr até 30 de Abr'`

#### Scenario: Active filter chip for a `desde` one-sided range

Given the user applies a filter with only `start = 2026-04-01` (and `end == null`)
Then the active filter chip for `period` SHALL render `'desde 01 de Abr'`

#### Scenario: Active filter chip for an `até` one-sided range

Given the user applies a filter with only `end = 2026-04-30` (and `start == null`)
Then the active filter chip for `period` SHALL render `'até 30 de Abr'`

---

### Requirement: IDateFormatterService.formatShortDate is removed

After the two consumers above stop calling `formatShortDate`, no consumer in `lib/` SHALL reference it. The change SHALL:

- Remove `String formatShortDate(int millis);` from `lib/src/domain/services/date_formatter_service.dart`.
- Remove the implementation and the `_shortDate` `DateFormat` field from `lib/src/infrastructure/services/date_formatter_service.dart`.
- Remove the `group('formatShortDate', ...)` block from `test/src/infrastructure/services/date_formatter_service_test.dart`.

The mock `MockDateFormatterService` in `test/mocks/mocks.dart` does NOT need to change (it implements the interface; removing a method automatically updates the mock).

#### Scenario: No formatShortDate references remain

Given the change is implemented
Then `grep -rn "formatShortDate" lib/ test/` SHALL return zero matches

---

## Out of scope

- Adding a `formatLongPeriod` method or any new public method on `IDateFormatterService`. The contract is unchanged.
- Changing `formatLongDate`, `formatShortDate`, `formatDayMonth`, or any other formatter.
- Refactoring `formatPeriod` to call `formatLongDate` internally (avoid coupling between service methods).
- Updating any consumer file beyond the loading widget placeholder.
- Adding skeleton-width responsiveness for cross-year cases (the placeholder is fixed at the common shape and is good enough).
- Renaming `formattedPeriod` on `BudgetFormState` / `BudgetItemPresentationData`.
- Backend changes.
- i18n / locale variants beyond pt_BR.
- Canonical rendering for the deferred shapes (same-year non-current, multi-year-crossing, past-only year-crossing).
