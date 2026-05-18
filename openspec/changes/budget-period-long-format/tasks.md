# Tasks: budget-period-long-format

## Pass 1 — Budget surfaces (shipped em d4eb6d6)

- [x] `lib/src/infrastructure/services/date_formatter_service.dart` — reescrever `formatPeriod`:
  - Normalizar `start` e `end` para start-of-day via `DateTime(year, month, day)`.
  - Se `startDay == endDay`: renderizar como single long date (`'{dd} de {Mmm}'` ou `'{dd} de {Mmm} de {yyyy}'` se ano ≠ corrente).
  - Senão: render `'{start sem ano} até {end com ou sem ano}'`, onde o `end` carrega `' de {yyyy}'` quando `end.year != _now().year`.
  - Separador literal `' até '` (sem en-dash).
  - Inlinar a montagem do label (não chamar `formatLongDate` — manter os métodos desacoplados conforme decisão #2 da spec).
- [x] `lib/src/infrastructure/services/date_formatter_service.dart` — remover o campo `_dayMonthShortYear` (deixa de ter consumidor após a reescrita).
- [x] `lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart` — trocar `formattedPeriod: '00/00 – 00/00'` por `formattedPeriod: '00 de Mmm até 00 de Mmm'`.
- [x] `test/src/infrastructure/services/date_formatter_service_test.dart` — substituir os 3 cenários atuais do `group('formatPeriod', ...)` pelos novos:
  - single day ano corrente → `'20 de Mai'`
  - single day ano fora do corrente → `'20 de Mai de 2027'`
  - mesmo dia com horários intra-dia distintos → colapsa para `'20 de Mai'`
  - range mesmo ano, mesmo mês → `'12 de Mai até 20 de Mai'`
  - range mesmo ano, meses distintos → `'05 de Jan até 31 de Dez'`
  - range cruzando virada → `'20 de Dez até 25 de Jan de 2027'`
  - range cruzando virada na borda extrema → `'31 de Dez até 01 de Jan de 2027'`
  - asserts genéricos: contém `' até '` e não contém `'–'`.

## Pass 2 — Expense filter surfaces + drop formatShortDate

- [ ] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart` — `_summaryOf` chama `_dateFormatter.formatPeriod(draft.startDate!, draft.endDate!)`, preservando o guard de null nos dois bounds.
- [ ] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `_periodLabel` vira switch expression sobre `(start, end)`:
  - `(int s, int e)` → `_dateFormatter.formatPeriod(s, e)`
  - `(int s, null)` → `'desde ${_dateFormatter.formatLongDate(s)}'`
  - `(null, int e)` → `'até ${_dateFormatter.formatLongDate(e)}'`
  - `(null, null)` não ocorre (o filtro só entra na lista de chips quando ao menos um bound existe — preservar a precondição atual).
- [ ] `lib/src/domain/services/date_formatter_service.dart` — remover `String formatShortDate(int millis);`.
- [ ] `lib/src/infrastructure/services/date_formatter_service.dart` — remover método `formatShortDate` e campo `_shortDate`.
- [ ] `test/src/infrastructure/services/date_formatter_service_test.dart` — remover `group('formatShortDate', ...)`.
- [ ] `test/src/presentation/providers/expenses_filters_notifier_test.dart` — substituir stub `formatShortDate` por stub `formatPeriod`; ajustar o expect de `'SHORT($start) – SHORT($end)'` para o novo formato.
- [ ] `test/src/presentation/providers/expenses_notifier_test.dart` — substituir stub `formatShortDate` por stub `formatPeriod` (e adicionar stub `formatLongDate` se algum cenário cobrir one-sided).

## Verificação final

- [x] `flutter analyze` limpo (pass 1).
- [x] `flutter test test/src/infrastructure/services/date_formatter_service_test.dart` verde (pass 1).
- [x] `flutter test` full verde (pass 1 — 668/668).
- [ ] `flutter analyze` limpo (após pass 2).
- [ ] `flutter test` full verde (após pass 2).
- [ ] `grep -rn "formatShortDate" lib/ test/` retorna zero linhas.
- [ ] Smoke manual cobrindo: form de Budget, summary do `ExpensesFilterScreen` e pílula de período ativo no `ExpensesScreen`.
