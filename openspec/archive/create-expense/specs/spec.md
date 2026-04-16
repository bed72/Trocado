# Spec — create-expense

## Requirements

### Requirement: Description Input
The system SHALL render a text field with label "Descrição" that dispatches `DescriptionChanged` on every character change.

#### Scenario: User types a description
Given the create expense screen is displayed
When the user types into the description field
Then `ExpenseState.description` SHALL reflect the typed value

---

### Requirement: Amount Field (read-only, opens calculator)
The system SHALL render a read-only tappable field with label "Valor" that navigates to `CalculatorLocation` on tap.
When the calculator bottom sheet is dismissed with a value > 0, `ValueChanged(centValue)` SHALL be dispatched to `ExpenseNotifier`.
The field SHALL display the formatted `pt_BR` currency value when `state.value > 0`.

#### Scenario: User selects an amount
Given the user taps the amount field
When the calculator bottom sheet opens and the user enters digits and presses ✓
Then `ExpenseState.value` SHALL reflect the value in cents
And the field SHALL display the formatted currency

---

### Requirement: Date Field (read-only, opens date picker)
The system SHALL render a read-only tappable field with label "Data" that navigates to `ExpenseDateLocation` on tap.
The date SHALL be pre-filled with the current day on screen load.
`ExpenseDateScreen` SHALL use `SfDateRangePicker` in `single` selection mode.
When the user presses "Selecionar", `DateChanged(millisecondsSinceEpoch)` SHALL be dispatched.
The field SHALL display the formatted `pt_BR` long date when a date is set.

#### Scenario: Date pre-filled on open
Given the create expense screen loads
Then `ExpenseState.date` SHALL be `DateTime.now().millisecondsSinceEpoch`

#### Scenario: User changes the date
Given the user taps the date field
When the date bottom sheet opens and the user selects a date and presses "Selecionar"
Then `ExpenseState.date` SHALL reflect the selected date

---

### Requirement: Validation
The system SHALL validate all fields on `SubmitPressed` before calling the repository.

| Field | Rule | Message |
|---|---|---|
| `value` | > 0 | "Valor é obrigatório" |
| `description` | non-empty after trim, ≤ 256 chars | "Descrição é obrigatória" |
| `date` | not null | "Data é obrigatória" |

Each field SHALL display its failure message inline below the field.
Changing a field's value SHALL clear its failure.

#### Scenario: Submit with missing value and description
Given the date is pre-filled and value and description are empty
When the user presses "Salvar"
Then `ExpenseState.valueFailure` SHALL be non-null
And `ExpenseState.descriptionFailure` SHALL be non-null
And `ExpenseState.dateFailure` SHALL be null
And the repository SHALL NOT be called

---

### Requirement: Submit — Loading
The system SHALL show a loading indicator on the "Salvar" button while `ExpenseStatus.loading`.

#### Scenario: Submission in progress
Given all fields are valid
When the repository call has not yet returned
Then `ExpenseState.status` SHALL be `loading`
And the "Salvar" button SHALL be disabled and display a loading indicator

---

### Requirement: Submit — Success
The system SHALL call `context.pop()` when the repository returns `Right(ExpenseModel)`.

#### Scenario: Successful creation
Given all fields are valid
When `POST /api/v1/expenses` returns 201 with the created expense
Then `ExpenseState.status` SHALL be `success`
And the screen SHALL pop back to the previous route

---

### Requirement: Submit — Failure
The system SHALL show a failure toast with the error message when the repository returns a `Left`.

#### Scenario: API validation error
Given all fields are valid
When the repository returns `Left(ValidationFailure('message'))`
Then `ExpenseState.status` SHALL be `failure`
And `ExpenseState.message` SHALL equal the failure message
And a failure toast SHALL be displayed

#### Scenario: Network error
Given all fields are valid
When the repository returns `Left(NetworkFailure())`
Then `ExpenseState.status` SHALL be `failure`
And a failure toast SHALL be displayed

---

### Requirement: API contract
`POST /api/v1/expenses` — requires Bearer token.

Request body:
```json
{ "value": "85.50", "description": "Mercado", "date": "2026-03-15" }
```

Response (201):
```json
{ "id": 1, "value": "85.50", "description": "Mercado", "date": "2026-03-15" }
```

Error format: `{ "errors": [{ "field": null, "message": "string", "code": "string" }] }`

Value is `String` decimal in the API; stored as `int` cents in the app.
Date is `String` ISO 8601 `"yyyy-MM-dd"` in the API; stored as `int` milliseconds since epoch in the app.

---

### Requirement: Calculator reuse
`CalculatorScreen` SHALL accept an optional `onValueConfirmed(int centValue)` callback.
When `onValueConfirmed` is null, the screen SHALL fall back to dispatching `ValueChanged` to `budgetProvider` (backward compatibility).

---

### Out of scope
- Category field (`expense_category_field_widget.dart` exists but not in this feature)
- Edit expense (id parameter reserved for future use)
