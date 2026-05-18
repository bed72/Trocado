# Tasks: budget-period-long-format

## infrastructure/services — reescrita do formatPeriod

- [ ] `lib/src/infrastructure/services/date_formatter_service.dart` — reescrever `formatPeriod`:
  - Normalizar `start` e `end` para start-of-day via `DateTime(year, month, day)`.
  - Se `startDay == endDay`: renderizar como single long date (`'{dd} de {Mmm}'` ou `'{dd} de {Mmm} de {yyyy}'` se ano ≠ corrente).
  - Senão: render `'{start sem ano} até {end com ou sem ano}'`, onde o `end` carrega `' de {yyyy}'` quando `end.year != _now().year`.
  - Separador literal `' até '` (sem en-dash).
  - Inlinar a montagem do label (não chamar `formatLongDate` — manter os métodos desacoplados conforme decisão #2 da spec).
- [ ] `lib/src/infrastructure/services/date_formatter_service.dart` — remover o campo `_dayMonthShortYear` (deixa de ter consumidor após a reescrita).

## presentation/ui/budgets — loading placeholder

- [ ] `lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart` — trocar `formattedPeriod: '00/00 – 00/00'` por `formattedPeriod: '00 de Mmm até 00 de Mmm'`.

## test — atualização do grupo formatPeriod

- [ ] `test/src/infrastructure/services/date_formatter_service_test.dart` — substituir os 3 cenários atuais do `group('formatPeriod', ...)` pelos novos:
  - single day ano corrente → `'20 de Mai'`
  - single day ano fora do corrente → `'20 de Mai de 2027'`
  - mesmo dia com horários intra-dia distintos → colapsa para `'20 de Mai'`
  - range mesmo ano, mesmo mês → `'12 de Mai até 20 de Mai'`
  - range mesmo ano, meses distintos → `'05 de Jan até 31 de Dez'`
  - range cruzando virada → `'20 de Dez até 25 de Jan de 2027'`
  - range cruzando virada na borda extrema → `'31 de Dez até 01 de Jan de 2027'`
  - asserts genéricos: contém `' até '` e não contém `'–'`.

## Verificação final

- [ ] `flutter analyze` limpo.
- [ ] `flutter test test/src/infrastructure/services/date_formatter_service_test.dart` verde.
- [ ] `flutter test` full verde.
- [ ] `git diff --name-only` mostra apenas os 3 arquivos acima (+ os 3 da pasta `openspec/changes/budget-period-long-format/`).
- [ ] Smoke manual no form de Budget cobrindo single-day, range-mesmo-ano e range-cross-year (sem commit, por instrução do usuário).
