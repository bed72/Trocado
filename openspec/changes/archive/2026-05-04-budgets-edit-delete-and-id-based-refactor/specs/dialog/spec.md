# dialog Specification (delta)

## Purpose

Diálogos compartilhados de UI usados por múltiplas features. O primeiro membro é `ConfirmDialogWidget`, padronizando confirmação de ações destrutivas (delete) em Budget e Expense.

## Requirements

### Requirement: ConfirmDialogWidget — generic confirmation dialog

The system SHALL add `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart` exposing a top-level function:

```dart
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  String confirmLabel = 'Confirmar',
  String denyLabel = 'Cancelar',
  bool destructive = false,
});
```

The function SHALL call `showDialog<bool>` and return the resolved value `?? false` (so dismiss-by-barrier resolves as `false`).

The internal `ConfirmDialogWidget` SHALL be a `StatelessWidget` rendering `title` (style `context.typography.titleLarge`/headline as appropriate), `description` (`context.typography.bodyMedium` with `context.colors.onSurfaceVariant`), and two action buttons:

- **Deny button**: text-style button (`ButtonWidget.text` or equivalent) with `denyLabel`. On tap, calls `Navigator.of(context).pop(false)`.
- **Confirm button**: filled/outlined button with `confirmLabel`. On tap, calls `Navigator.of(context).pop(true)`. When `destructive == true`, the confirm button SHALL apply `context.colors.error` (background or foreground per the project's destructive button convention).

The widget SHALL NOT contain private widget classes inside its file (project rule: no `class _Foo extends StatelessWidget` in another widget file). Trivial subwidgets SHALL be private methods returning `Widget`.

The widget SHALL NOT import anything from `lib/src/presentation/ui/<feature>/` — only `widgets/`, `extensions/`, and Flutter/Material.

#### Scenario: Title and description render

Given `showConfirmDialog(context: ctx, title: 'X', description: 'Y')` is invoked
When the dialog renders
Then a Text widget with content `'X'` SHALL appear
And a Text widget with content `'Y'` SHALL appear

#### Scenario: Default labels render when not provided

Given `showConfirmDialog(context: ctx, title: 'X', description: 'Y')` (no labels)
When the dialog renders
Then the deny button SHALL display `'Cancelar'`
And the confirm button SHALL display `'Confirmar'`

#### Scenario: Custom labels render when provided

Given `showConfirmDialog(context: ctx, title: 'X', description: 'Y', confirmLabel: 'Excluir', denyLabel: 'Voltar')` is invoked
When the dialog renders
Then the deny button SHALL display `'Voltar'`
And the confirm button SHALL display `'Excluir'`

#### Scenario: Tap on confirm resolves Future with true

Given the dialog is rendered
When the user taps the confirm button
Then the returned `Future<bool>` SHALL resolve to `true`
And the dialog SHALL be popped from the navigator

#### Scenario: Tap on deny resolves Future with false

Given the dialog is rendered
When the user taps the deny button
Then the returned `Future<bool>` SHALL resolve to `false`
And the dialog SHALL be popped

#### Scenario: Dismiss by barrier resolves Future with false

Given the dialog is rendered
When the user taps outside the dialog (barrier)
Then the navigator SHALL pop with `null`
And the function SHALL coerce that to `false` via `?? false`
And the returned `Future<bool>` SHALL resolve to `false`

#### Scenario: Destructive flag applies error color to confirm button

Given `showConfirmDialog(..., destructive: true)`
When the dialog renders
Then the confirm button SHALL render with `context.colors.error` applied (background or foreground per the project's destructive convention)

#### Scenario: Non-destructive default does not apply error color

Given `showConfirmDialog(...)` (without `destructive`)
When the dialog renders
Then the confirm button SHALL use the project's default primary styling (no error color)

#### Scenario: Widget is feature-agnostic

Given the file `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`
When `grep -E "presentation/ui/" <file>` is executed
Then the result SHALL be empty (no feature imports)

---
