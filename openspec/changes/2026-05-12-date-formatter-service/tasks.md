# Tasks: date-formatter-service

## domain/

- [ ] `lib/src/domain/services/date_formatter_service.dart` (NOVO) — interface `IDateFormatterService` com 9 métodos (`formatShortDate`, `formatDayMonth`, `formatTime`, `formatMonth`, `formatPeriod`, `relativeGroupHeader`, `daysUntil`, `toIsoDate`, `fromIsoDate`). Sem imports.

## infrastructure/

- [ ] `lib/src/infrastructure/services/date_formatter_service.dart` (NOVO) — classe `DateFormatterService implements IDateFormatterService`, construtor nomeado `{required DateTime Function() now}`, instâncias `DateFormat` como campos `final` (pt_BR exceto ISO). Helpers privados `_atStartOfDay`, `_weekdayHeader`, `_capitalize`.

## main/providers/

- [ ] `lib/src/main/providers/services_provider.dart` — adicionar `@Riverpod(keepAlive: true) IDateFormatterService dateFormatterService(Ref ref) => DateFormatterService(now: ref.watch(nowProvider));` após o `nowProvider` existente.
- [ ] `dart run build_runner build --delete-conflicting-outputs`

## test/mocks/

- [ ] `test/mocks/mocks.dart` — adicionar `final class MockDateFormatterService extends Mock implements IDateFormatterService {}` e o import de `package:trocado/src/domain/services/date_formatter_service.dart`.

## presentation/ — notifiers principais

- [ ] `lib/src/presentation/ui/home/notifiers/active_budget_notifier.dart` — injetar `dateFormatterServiceProvider`; substituir `_formatEndDate` por `_dateFormatter.formatDayMonth(model.endDate)`; substituir `_daysRemaining(endDate)` por `_dateFormatter.daysUntil(model.endDate)`; remover métodos `_formatEndDate` e `_daysRemaining`; remover import de `intl`.
- [ ] `lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart` — injetar `dateFormatterServiceProvider` e `nowProvider`; substituir `_formatPeriod`, `_formatEndDate`, `_daysRemaining`; trocar `DateTime.now().millisecondsSinceEpoch` em `_loadFirstPage` por `_now().millisecondsSinceEpoch`; remover métodos privados de data; remover import de `intl`.
- [ ] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — injetar `dateFormatterServiceProvider`; `_periodLabel` passa a usar `_dateFormatter.formatShortDate(...)` mantendo a lógica condicional (`desde X`, `até Y`, `X – Y`); `_toItem` passa a popular `formattedDate` e `formattedTime` no presentation data; remover import de `intl`.

## presentation/ — Item A: expense item presentation

- [ ] `lib/src/presentation/data/expense_item_presentation_data.dart` — adicionar `final String formattedDate;` e `final String formattedTime;`; atualizar construtor, `props` e qualquer call site que instancie diretamente.
- [ ] `lib/src/presentation/widgets/expense/expense_item_widget.dart` — adicionar `final String formattedDate;` e `final String formattedTime;` ao construtor; remover formatação inline `DateFormat('dd/MM', 'pt_BR').format(...)` e `DateFormat('HH:mm', 'pt_BR').format(...)`; usar os novos campos direto; remover import de `intl`.
- [ ] `lib/src/presentation/preview/mocks/expense/expense_item_mock.dart` — atualizar mock builder para preencher `formattedDate` e `formattedTime` (valores fixos legíveis para preview).
- [ ] `lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart` — se também emite `ExpenseItemPresentationData`, formatar os novos campos via service injetado (auditar e migrar).
- [ ] Outros call sites de `ExpenseItemPresentationData(...)` no codebase — auditar via `grep` e atualizar.

## presentation/ — Item B: notification item presentation

- [ ] `lib/src/presentation/data/notification/notification_item_presentation_data.dart` (NOVO) — classe Equatable com `final NotificationModel notification;`, `final String formattedTime;`, construtor nomeado, `props`.
- [ ] `lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` — retipa `items` de `List<NotificationModel>` para `List<NotificationItemPresentationData>`.
- [ ] `lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart` — injetar `dateFormatterServiceProvider`; criar `_toItem(NotificationModel)` retornando o presentation data; aplicar `_toItem` em `_loadFirstPage` e `loadMore` (no `map`).
- [ ] `lib/src/presentation/ui/notifications/data/notification_group_presentation_data.dart` — retipa `notifications` de `List<NotificationModel>` para `List<NotificationItemPresentationData>`.
- [ ] `lib/src/presentation/ui/notifications/data/notification_groups_builder.dart` — assinatura passa a aceitar `List<NotificationItemPresentationData>` e `IDateFormatterService dateFormatter`; remove `_atStartOfDay`, `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize`; header vem de `dateFormatter.relativeGroupHeader(item.notification.createdAt)`; remove import de `intl`.
- [ ] `lib/src/presentation/ui/notifications/widgets/notification_card_widget.dart` — recebe `NotificationItemPresentationData` ao invés de `NotificationModel`; usa `data.formattedTime` direto; remove `DateFormat` e import de `intl`.
- [ ] `lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — atualizar como passa `notification` para o card widget (agora passa o presentation data inteiro).
- [ ] `lib/src/presentation/ui/notifications/widgets/notifications_list_widget.dart` — atualizar tipos do parâmetro de items.

## presentation/ — Item C: form date fields

- [ ] `lib/src/presentation/ui/expense/notifiers/form/expense_state.dart` — adicionar `final String? formattedDate;` em `ExpenseState`; atualizar `copyWith`, construtor, `props`.
- [ ] `lib/src/presentation/ui/expense/notifiers/form/expense_notifier.dart` — injetar `dateFormatterServiceProvider`; em `build()` calcular `formattedDate` para o estado inicial (`DateTime.now().millisecondsSinceEpoch` → `_dateFormatter.formatShortDate(...)`); no `DateChanged` intent, recalcular `formattedDate`.
- [ ] `lib/src/presentation/ui/expense/widgets/expense_date_field_widget.dart` — substituir `int? date` por `String? displayValue`; remover import de `date_time_extension.dart`; remover `DateTime.fromMillisecondsSinceEpoch(date!).format()` do `_displayValue`.
- [ ] `lib/src/presentation/ui/expense/screens/expense_screen.dart` (ou onde `ExpenseDateFieldWidget` é construído) — passar `state.formattedDate` ao invés de `state.date`.
- [ ] `lib/src/presentation/ui/budget/notifiers/form/budget_form_state.dart` — adicionar `final String? formattedPeriod;`; atualizar `copyWith`, construtor, `props`.
- [ ] `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart` — injetar `dateFormatterServiceProvider`; em `build()` e em qualquer intent que mude `startDate`/`endDate`, recalcular `formattedPeriod` via `_dateFormatter.formatPeriod(...)` (null se algum dos dois estiver vazio).
- [ ] `lib/src/presentation/ui/budget/widgets/fields/budget_date_field_widget.dart` — substituir `int? startDate, int? endDate` por `String? displayValue`; remover import de `date_time_extension.dart`; remover formatação inline; passar `displayValue` direto pra `TextFieldWidget.initialValue`.
- [ ] `lib/src/presentation/ui/budget/screens/budget_screen.dart` (ou onde `BudgetDateFieldWidget` é construído) — passar `state.formattedPeriod`.

## presentation/ — Item D: budget description hint

- [ ] `lib/src/presentation/ui/budget/notifiers/form/budget_form_state.dart` — adicionar `final String descriptionHint;` (não nullable — sempre tem um mês corrente); atualizar `copyWith`, construtor, `props`.
- [ ] `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart` — em `build()`, calcular `descriptionHint: 'Ex: Orçamento de ${_dateFormatter.formatMonth(_now())}'` (injetar `nowProvider` também).
- [ ] `lib/src/presentation/ui/budget/widgets/fields/budget_description_field_widget.dart` — adicionar `final String hint;` no construtor; remover método `getCurrentMonth()`; remover import de `intl`; usar `hint` direto.
- [ ] `lib/src/presentation/ui/budget/screens/budget_screen.dart` (ou onde `BudgetDescriptionFieldWidget` é construído) — passar `state.descriptionHint`.

## presentation/ — Item E: expenses filter period summary

- [ ] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_state.dart` — adicionar `final String? formattedPeriodSummary;`; atualizar `copyWith`, construtor, `props`.
- [ ] `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart` — injetar `dateFormatterServiceProvider`; helper privado `String? _periodSummaryOf(ExpenseFilterModel draft)`; em todo `state = state.copyWith(draft: ...)` que envolva mudança de data, atualizar `formattedPeriodSummary` (`PresetSelected`, `CustomRangeChanged`, `Cleared`).
- [ ] `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_period_section_widget.dart` — substituir `int? startDate, int? endDate` por `String? formattedSummary`; remover `_summary` interno que cria `DateFormat`; renderizar Text condicional direto; remover import de `intl`.
- [ ] `lib/src/presentation/ui/expenses/screens/expenses_filters_screen.dart` (ou onde a seção é construída) — passar `state.formattedPeriodSummary` ao invés de `state.draft.startDate`/`endDate`.

## presentation/ — expense_groups_builder (toca o builder porque já está sendo migrado)

- [ ] `lib/src/presentation/ui/expenses/data/expense_groups_builder.dart` — assinatura passa a aceitar `IDateFormatterService dateFormatter`; remove `_atStartOfDay`, `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize`; header vem de `dateFormatter.relativeGroupHeader(item.expense.createdAt)`; remove import de `intl`.
- [ ] Quem chama `buildExpenseGroups(...)` — passar `dateFormatter: _dateFormatter` (auditar via grep; provavelmente um único notifier/provider derivado).

## Remoção das extensions (último passo — só depois de C, D, E completos)

- [ ] `lib/src/presentation/extensions/date_time_extension.dart` — DELETAR arquivo.
- [ ] `lib/src/presentation/extensions/int_time_extension.dart` — DELETAR arquivo.
- [ ] Verificar via `grep -rn "date_time_extension\|int_time_extension\|DateTimeExtensions\|IntExtensions\|StringToDateTimeExtension" lib/ test/` que zero referências restam.

## test/ — implementação do service

- [ ] `test/src/infrastructure/services/date_formatter_service_test.dart` (NOVO) — `setUpAll: initializeDateFormatting('pt_BR')`; `setUp: formatter = DateFormatterService(now: () => DateTime(2026, 5, 12, 14, 30))`; cobrir todos os 9 métodos; bordas críticas de `relativeGroupHeader` (hoje, ontem, 6 dias atrás como weekday, 7+ dias como mês/ano); `formatPeriod` em mesmo ano e cruzando anos; `toIsoDate`/`fromIsoDate` simetria; descrições de teste em inglês.

## test/ — notifiers migrados

- [ ] `test/src/presentation/providers/active_budget_notifier_test.dart` — injetar `MockDateFormatterService`; stubar `formatDayMonth` e `daysUntil`; remover `initializeDateFormatting('pt_BR')` e `DateFormat(...)` dos asserts.
- [ ] `test/src/presentation/providers/budgets_notifier_test.dart` — idem; stubar também `formatPeriod`.
- [ ] `test/src/presentation/providers/expenses_notifier_test.dart` — idem; cobrir `formattedDate`/`formattedTime` nos itens do state.
- [ ] `test/src/presentation/providers/expenses_filters_notifier_test.dart` — stubar `formatPeriod`; cobrir aparecer/limpar de `formattedPeriodSummary` conforme mutações.
- [ ] `test/src/presentation/providers/notifications_notifier_test.dart` — stubar `formatTime`; cobrir items de presentation data; remover `initializeDateFormatting`.
- [ ] `test/src/presentation/providers/budget_by_id_notifier_test.dart` — auditar se ainda usa `DateFormat`/`initializeDateFormatting` após mudanças no form state; migrar se sim.
- [ ] `test/src/presentation/providers/recent_expenses_notifier_test.dart` — auditar; se emite `ExpenseItemPresentationData`, stubar service.
- [ ] `test/src/presentation/screens/expenses/data/expense_groups_builder_test.dart` — stubar `MockDateFormatterService.relativeGroupHeader`; remover `initializeDateFormatting('pt_BR')`.
- [ ] `test/src/presentation/screens/notifications/data/notification_groups_builder_test.dart` — idem.

## Verificação final

- [ ] `flutter analyze` — zero issues.
- [ ] `flutter test` — verde.
- [ ] `grep -rn "DateFormat(" lib/src/presentation/` — **zero linhas**.
- [ ] `grep -rn "DateFormat(" lib/src/` — apenas: `lib/src/infrastructure/services/date_formatter_service.dart`, `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart`, `lib/src/infrastructure/clients/http/requests/expense_request.dart`, `lib/src/infrastructure/clients/http/requests/budget_request.dart`, `lib/src/data/extensions/expense_response_extension.dart`, `lib/src/data/extensions/budget/active_budget_response_extension.dart`, `lib/src/data/extensions/budget/budget_response_extension.dart`.
- [ ] `grep -rn "package:intl" lib/src/presentation/` — **zero linhas**.
- [ ] Arquivos `lib/src/presentation/extensions/date_time_extension.dart` e `lib/src/presentation/extensions/int_time_extension.dart` não existem.
- [ ] Smoke manual: rodar app, abrir Home, Despesas, Orçamentos, Notificações; criar/editar despesa e orçamento; conferir formatos visuais (especialmente o `dd/MM/yyyy` que agora aparece nos form fields no lugar do antigo "X de Mês de AAAA").
