# Tasks: expenses-display-event-date

> Spec retroativa — todas as tasks foram concluídas em 2026-05-18 antes da spec ser escrita.

## presentation/data — view-model do item

- [x] `lib/src/presentation/data/expense_item_presentation_data.dart` — remover campo `final String formattedTime;`, parâmetro `required this.formattedTime` no construtor, e a entrada `formattedTime` em `props`.

## presentation/widgets — item widget

- [x] `lib/src/presentation/widgets/expense/expense_item_widget.dart` — remover parâmetro `final String formattedTime;` e do construtor; trocar o `Text('$formattedDate · $formattedTime', ...)` por `Text(formattedDate, ...)`.

## presentation/ui — notifiers que emitem ExpenseItemPresentationData

- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — em `_toItem`, remover `formattedTime: _dateFormatter.formatTime(expense.createdAt)` e trocar `formattedDate: _dateFormatter.formatDayMonth(expense.createdAt)` por `formattedDate: _dateFormatter.formatLongDate(expense.date)`.
- [x] `lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart` — mesma mudança no `_toItem`.

## presentation/ui — agrupamento

- [x] `lib/src/presentation/ui/expenses/data/expense_groups_builder.dart` — substituir `dateFormatter.relativeGroupHeader(item.expense.createdAt)` por `dateFormatter.relativeGroupHeader(item.expense.date)`.

## presentation/ui — consumidores do widget

- [x] `lib/src/presentation/ui/expenses/widgets/expenses_list_widget.dart` — remover o arg `formattedTime: item.formattedTime` na construção do `ExpenseItemWidget`.
- [x] `lib/src/presentation/ui/home/widgets/recent_expenses/recent_expenses_section_widget.dart` — idem.

## presentation/ui — loading widgets

- [x] `lib/src/presentation/ui/expenses/widgets/expenses_loading_widget.dart` — remover `_placeholderTime` e arg `formattedTime: _placeholderTime`; alterar `_placeholderDate` de `'00/00'` para `'00 de Mmm'`.
- [x] `lib/src/presentation/ui/home/widgets/recent_expenses/recent_expenses_loading_widget.dart` — mesmas mudanças.

## infrastructure/services — regra do ano contextual em formatLongDate

- [x] `lib/src/infrastructure/services/date_formatter_service.dart` — `formatLongDate` passa a comparar `date.year` com `_now().year`: se iguais, retorna `'$day de $month'`; se diferentes, mantém `'$day de $month de ${date.year}'`.
- [x] `test/src/infrastructure/services/date_formatter_service_test.dart` — cenários `formatLongDate`: (a) ano igual ao corrente → omite ano; (b) ano anterior → exibe ano; (c) ano futuro → exibe ano; (d) padding e capitalização de mês usam o caso "mesmo ano" (sem `de yyyy` nos asserts).

## presentation/preview — mock

- [x] `lib/src/presentation/preview/mocks/expense/expense_item_mock.dart` — remover `formattedTime: _formatter.formatTime(millis)`; trocar `formattedDate: _formatter.formatDayMonth(millis)` por `formattedDate: _formatter.formatLongDate(millis)`.

## test/ — atualização de stubs

- [x] `test/src/presentation/screens/expenses/data/expense_groups_builder_test.dart` — helper `_item` perde `formattedTime: '00:00'`; `formattedDate` passa a ser `'01 de Jan de 2026'` (apenas estética — agora o item espera long date).
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — substituir `when(() => dateFormatter.formatDayMonth(any())).thenReturn('22/04')` + `when(() => dateFormatter.formatTime(any())).thenReturn('14:30')` por um único `when(() => dateFormatter.formatLongDate(any())).thenReturn('22 de Abr de 2026')`.
- [x] `test/src/presentation/providers/recent_expenses_notifier_test.dart` — idem.
- [x] `test/src/presentation/providers/expense_by_id_notifier_test.dart` — `_makeContainer` deixa de stubar `formatDayMonth`/`formatTime` e passa a stubar `formatLongDate`.

## Auditoria — budgets / outros consumidores

- [x] Conferir `active_budget_notifier.dart` — usa `model.endDate` direto, sem `createdAt`. OK.
- [x] Conferir `budgets_notifier.dart` (`_toItem` e `_toCardData`) — usam `startDate`/`endDate`, sem `createdAt`. OK.
- [x] Conferir `notifications_notifier.dart` e `notification_groups_builder.dart` — usam `createdAt` semanticamente correto (notificação não tem outro "date"). OK.
- [x] Conferir `couple_notifier.dart` "Conectados há ..." — usa `couple.createdAt` semanticamente correto. OK.
- [x] Conferir `expense_screen.dart` (form) — usa `state.formattedDate` derivado de `expense.date` via `formatLongDate`. OK.

## Verificação final

- [x] `flutter analyze` — só warnings pré-existentes em `insights_carousel_loading_widget.dart`.
- [x] `flutter test` — 663/663 verde (3 cenários novos em `date_formatter_service_test` cobrem a regra do ano contextual).
- [x] `grep -rn "formattedTime" lib/src/presentation/ui/expenses lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart lib/src/presentation/widgets/expense/ lib/src/presentation/data/expense_item_presentation_data.dart lib/src/presentation/preview/mocks/expense/` — zero linhas.
- [x] `grep -n "createdAt" lib/src/presentation/ui/expenses/data/expense_groups_builder.dart lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart` — zero linhas.
- [ ] Smoke manual: rodar app, abrir Despesas, aplicar `Período → Mês passado` ou Personalizado em abril/2026; conferir que header passa a refletir as datas dos eventos (não "Hoje" pra tudo) e cada item mostra `30 de Abr de 2026`.
