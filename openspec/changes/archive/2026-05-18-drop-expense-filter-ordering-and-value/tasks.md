# Tasks: drop-expense-filter-ordering-and-value

## Deletes

- [x] `lib/src/domain/enums/expense/expense_ordering_enum.dart`
- [x] `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_ordering_section_widget.dart`
- [x] `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_value_section_widget.dart`
- [x] `lib/src/presentation/widgets/formatters/currency_field_formatter.dart` (+ pasta `formatters/` removida ao ficar vazia)
- [x] `test/src/domain/enums/expense/expense_ordering_enum_test.dart`

## Edits — Lib

- [x] `lib/src/domain/models/expense/expense_filter_model.dart` — campos `ordering`/`minValue`/`maxValue` removidos junto com `clearMinValue`/`clearMaxValue`, método `normalized()` deletado, imports limpos.
- [x] `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart` — fragmentos `ge(value,...)`, `le(value,...)` e `ordering=...` removidos; helper `_formatValue` deletado por ficar sem consumidor.
- [x] `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — enum reduzido para `{ category, period }`.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart` — classes `MinValueChanged`, `MaxValueChanged`, `OrderingSelected` removidas; import do enum removido.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart` — braços correspondentes do switch removidos.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `removeFilter` perde `.value`/`.ordering`, `_buildChips` perde os dois blocos, helper `_valueLabel` deletado, `applyFilter` chama `_loadFirstPage(filter)` direto.
- [x] `lib/src/presentation/ui/expenses/screens/expenses_filter_screen.dart` — blocos `ExpensesFilterValueSectionWidget` e `ExpensesFilterOrderingSectionWidget` removidos + imports.

## Edits — Tests

- [x] `test/src/infrastructure/clients/http/requests/expense_filter_request.dart` — testes de `ordering=` / `ge(value,…)` / `le(value,…)` removidos; novo teste consolidado garantindo que esses fragments nunca aparecem.
- [x] `test/src/data/repositories/expense_repository_test.dart` — `test 'embeds RQL fragments and ordering'` reescrito sem `ordering`/`minValue`; import do enum removido.
- [x] `test/src/domain/models/expense/expense_filter_model_test.dart` — asserts de `ordering`/`minValue`/`maxValue` removidos, grupo `normalized` deletado.
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — testes `removeFilter(.value)` e `removeFilter(.ordering)` removidos; import do enum removido.
- [x] `test/src/presentation/providers/expenses_filters_notifier_test.dart` — grupos `MinValueChanged / MaxValueChanged` e `OrderingSelected` removidos; uso de `MinValueChanged` no `Cleared` test removido; import do enum removido.

## Verificação

- [x] `flutter analyze` limpo.
- [x] `flutter test` full verde (654/654).
- [x] `grep -rn "ExpenseOrderingEnum\|OrderingSelected\|MinValueChanged\|MaxValueChanged\|ExpensesFilterOrderingSection\|ExpensesFilterValueSection\|CurrencyFieldFormatter\|filter\.ordering\|\.minValue\|\.maxValue\|ChipKind\.value\|ChipKind\.ordering" lib/ test/` retorna vazio.
- [ ] Smoke manual no app — confirmar que `ExpensesFilterScreen` mostra só Categoria + Período, footer encostado, pílulas ativas e dismiss continuam funcionando, lista permanece em `-date`.
