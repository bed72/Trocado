# Tasks: expenses-filter-value-presets-and-ilike-search

## Domain

- [x] `lib/src/domain/enums/expense/expense_value_preset_enum.dart` — novo enum `ExpenseValuePresetEnum` com `label` e `toRange()` retornando `ExpenseValueRange` (typedef `({int? minValue, int? maxValue})`, em centavos). Ordem final dos valores ajustada na revisão pra `upTo50, above500, from50To200, from200To500` (presets abertos primeiro, contíguos depois).
- [x] `lib/src/domain/models/expense/expense_filter_model.dart` — adicionar `int? minValue`, `int? maxValue` (centavos). Atualizar `isEmpty`, `copyWith` (com `clearMinValue` / `clearMaxValue`), `props`.

## Infrastructure

- [x] `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart` — trocar `like(description,${encoded}*)` por `ilike(description,*${encoded}*)`.
- [x] `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart` — emitir `ge(value,${_formatValue(minValue)})` e `le(value,${_formatValue(maxValue)})` quando os campos estão setados. Helper `_formatValue(int cents) => (cents / 100).toStringAsFixed(2)`. Ordem dos fragmentos: category → date(start,end) → value(min,max) → description → page_size.

## Presentation — Notifier de filtros

- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_state.dart` — renomear `selectedPreset` → `selectedPeriodPreset`. Adicionar `selectedValuePreset: ExpenseValuePresetEnum?`. Atualizar `copyWith` (com `clearSelectedPeriodPreset` e `clearSelectedValuePreset`) e `props`.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart` — renomear `PresetSelected` → `PeriodPresetSelected`. Adicionar `ValuePresetSelected(ExpenseValuePresetEnum preset)`.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart` — `dispatch` atualizado + `_selectValuePreset(preset)` aplicando `preset.toRange()` no draft + atualizando `selectedValuePreset`. `Cleared()` continua zerando tudo via `const ExpensesFiltersState()`.

## Presentation — Tela de filtros

- [x] `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_value_section_widget.dart` — novo widget espelhando `ExpensesFilterPeriodSectionWidget`. Props: `selectedPreset: ExpenseValuePresetEnum?`, `onPresetSelected: ValueChanged<ExpenseValuePresetEnum>`.
- [x] `lib/src/presentation/ui/expenses/screens/expenses_filter_screen.dart` — seção de Valor inserida entre Categoria e Período. Wire `state.selectedValuePreset` + `(preset) => notifier.dispatch(ValuePresetSelected(preset))`. Callsites do rename atualizados.

## Presentation — Listagem (chip ativo)

- [x] `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — `enum ExpenseFilterChipKind { description, category, value, period }`.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `_buildChips`: chip de valor com `icon: Icons.payments_outlined` e label via `_valueLabel(min, max)` (helper privado que usa `_moneyService.format`). Posição entre category e period.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `removeFilter`: estender `switch (kind)` com `.value => current.copyWith(clearMinValue: true, clearMaxValue: true)`.

## Tests

- [x] `test/src/infrastructure/clients/http/requests/expense_filter_request.dart` — `ilike(description,*X*)`, trim do input, encode de `*` digitado (`%2A`), fragmentos `ge`/`le` de value (só min, só max, ambos), combinação search + value, ordenação documentada atualizada.
- [x] `test/src/presentation/providers/expenses_filters_notifier_test.dart` — `ValuePresetSelected(.upTo50/.from50To200/.above500)`, `Cleared` zera value preset. Renames `selectedPeriodPreset` / `PeriodPresetSelected` aplicados.
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — chip de valor (`kind: .value`, `icon: Icons.payments_outlined`, labels nos 3 formatos), `removeFilter(.value)` zera ambos, ordenação atualizada pra `description → category → value → period`.
- [x] `test/src/domain/enums/expense/expense_value_preset_enum_test.dart` — `toRange()` e `label` de cada preset.

## Verificação

- [x] `flutter analyze` limpo.
- [x] `flutter test` full verde (716/716).
- [ ] Smoke manual:
  - Buscar "alu" → casa "Aluguel", "aluguel", "ALU 123" em qualquer caixa.
  - Buscar "*" → backend não interpreta como curinga (encoded como `%2A`).
  - Filtro "R$50 – R$200" sozinho → lista filtra range; chip "R$ 50,00 – R$ 200,00" visível.
  - Filtro "Acima de R$500" → chip "Acima de R$ 500,00", lista mostra só itens ≥ R$500.
  - Combinar busca + valor + categoria + período → 4 chips ativos, lista respeita todos.
  - Tocar `X` no chip de valor → faixa some, demais permanecem.
  - "Limpar tudo" → todos os 4 filtros voltam ao default.
