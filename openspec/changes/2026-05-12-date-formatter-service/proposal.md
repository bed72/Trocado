# Proposal: date-formatter-service

## Intenção

Introduzir `IDateFormatterService` (interface em `domain/services/`, implementação em `infrastructure/services/`) como porta única de formatação e conversão de datas no app. Eliminar `DateFormat(...)` solto na camada `presentation/` e remover as duas extensions globais (`date_time_extension.dart` e `int_time_extension.dart`) que hoje convivem com formatadores inline criando dois caminhos pro mesmo problema.

## Motivação

Auditoria de 2026-05-12 mapeou:

- 9 arquivos da camada `presentation/` instanciando `DateFormat(...)` direto (≈ 12 padrões distintos: `dd/MM`, `dd/MM/yy`, `dd/MM/yyyy`, `dd MMM`, `EEEE`, `MMMM`, `MMMM y`, `HH:mm`).
- Locale `'pt_BR'` hardcoded em ≈ 15 sítios.
- `_atStartOfDay`, `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize` duplicados byte-a-byte entre `expense_groups_builder.dart` e `notification_groups_builder.dart`.
- `_formatEndDate` (`DateFormat('dd/MM', 'pt_BR')`) e `_daysRemaining` duplicados entre `active_budget_notifier.dart` e `budgets_notifier.dart`.
- Regex pra capitalizar mês após "de" duplicado em `date_time_extension.dart` (`format()` e `formatShort()`).
- Duas extensions de formatação (`DateTimeExtensions`, `IntExtensions`, `StringToDateTimeExtension`) que não são injetáveis — não dá pra mockar em testes nem trocar locale futuramente.

`IMoneyService` já estabelece o padrão correto para esse tipo de utilitário no projeto. O mesmo template aplicado a datas elimina toda essa duplicação, centraliza o locale, e torna a formatação testável via injeção Riverpod (incluindo `nowProvider` já existente para datas relativas).

## Camadas afetadas

- `domain/services/` — novo arquivo `date_formatter_service.dart` com a interface pura.
- `infrastructure/services/` — novo arquivo `date_formatter_service.dart` com a implementação usando `intl`.
- `main/providers/services_provider.dart` — registra `dateFormatterServiceProvider` consumindo `nowProvider` existente.
- `presentation/extensions/` — remoção de `date_time_extension.dart` e `int_time_extension.dart`.
- `presentation/ui/home/notifiers/active_budget_notifier.dart` — migra `_formatEndDate` e `_daysRemaining` pro service; injeta `nowProvider` indiretamente via service.
- `presentation/ui/budgets/notifiers/budgets_notifier.dart` — migra `_formatPeriod`, `_formatEndDate`, `_daysRemaining`.
- `presentation/ui/expenses/notifiers/expenses_notifier.dart` — migra `_periodLabel`; `_toItem` passa a emitir `formattedDate` e `formattedTime` (ver Item A em "Escopo").
- `presentation/ui/expenses/data/expense_groups_builder.dart` — toda a lógica de header relativo vai pro service; builder vira casca fina que delega.
- `presentation/ui/notifications/data/notification_groups_builder.dart` — idem.
- `presentation/ui/notifications/notifiers/notifications_notifier.dart` — passa a emitir `NotificationItemPresentationData` (ver Item B).
- `presentation/data/expense_item_presentation_data.dart` — ganha `formattedDate` e `formattedTime` (Item A).
- `presentation/data/notification/notification_item_presentation_data.dart` (NOVO) — view-model com `formattedTime` (Item B).
- `presentation/widgets/expense/expense_item_widget.dart` — para de chamar `DateFormat`; recebe strings prontas do presentation data (Item A).
- `presentation/ui/notifications/widgets/notification_card_widget.dart` — idem (Item B).
- `presentation/ui/expense/widgets/expense_date_field_widget.dart` — recebe `displayValue: String?` do form notifier ao invés de formatar (Item C).
- `presentation/ui/budget/widgets/fields/budget_date_field_widget.dart` — idem (Item C).
- `presentation/ui/budget/widgets/fields/budget_description_field_widget.dart` — recebe `hint: String` do form notifier ao invés de formatar (Item D).
- `presentation/ui/expense/notifiers/form/expense_notifier.dart` — passa a injetar `IDateFormatterService` e emitir `formattedDate` em `ExpenseState` (Item C).
- `presentation/ui/expense/notifiers/form/expense_state.dart` — ganha campo `formattedDate: String?` (Item C).
- `presentation/ui/budget/notifiers/form/budget_form_notifier.dart` — idem para `formattedPeriod` e `descriptionHint` (Itens C + D).
- `presentation/ui/budget/notifiers/form/budget_form_state.dart` — ganha campos `formattedPeriod: String?` e `descriptionHint: String` (Itens C + D).
- `presentation/ui/expenses/notifiers/expenses_filters_notifier.dart` — passa a injetar `IDateFormatterService` e emitir `formattedPeriodSummary: String?` em `ExpensesFiltersState` (Item E).
- `presentation/ui/expenses/notifiers/expenses_filters_state.dart` — ganha campo `formattedPeriodSummary: String?` (Item E).
- `presentation/ui/expenses/widgets/filter/expenses_filter_period_section_widget.dart` — recebe `formattedSummary: String?` ao invés de `startDate`/`endDate` (Item E).
- `test/mocks/mocks.dart` — adiciona `MockDateFormatterService`.
- `test/src/infrastructure/services/date_formatter_service_test.dart` (NOVO) — testes unitários da implementação.
- Testes de notifier afetados — atualizar mocks para incluir `IDateFormatterService`.

## Itens explicitamente fora de escopo

- **Conversões `'yyyy-MM-dd'` em `infrastructure/clients/http/requests/` e `data/extensions/`**: `expense_request.dart`, `budget_request.dart`, `expense_filter_request.dart`, `expense_response_extension.dart`, `budget_response_extension.dart`, `active_budget_response_extension.dart`. Camadas `infrastructure/` e `data/` não devem depender de service via Riverpod. Essas conversões ficam onde estão. Se virar dor, vira spec separada com `DateMapper` puro estático ou similar.
- **`home_greeting_widget.dart:10`** (`DateTime.now().hour` para "Bom dia/Boa tarde"): não é formatação de data, é decisão semântica baseada em hora. Fora.
- **Widgets de calendário (`SfDateRangePicker`)**: usa o picker do `syncfusion_flutter_datepicker`, sem formatação custom.
- **Conversão de timezone**: app inteiro opera em local time. Service não introduz `toUtc()` / timezone arithmetic — fora.
- **Internacionalização real (i18n)**: locale `pt_BR` continua hardcoded **na implementação concreta** (`DateFormatterService`). Ganho da spec é que vira único ponto a mexer se um dia for trocado. Adicionar suporte multi-locale é spec separada.

## Decisões de design

1. **Service recebe `DateTime Function() now` via construtor nomeado.** Elimina o parâmetro `{DateTime? now}` nos métodos relativos. Provider passa `ref.watch(nowProvider)`, testes passam função fixa. Mesmo padrão que `ExpensesFiltersNotifier` já usa para `nowProvider`.

2. **Provider depende de `nowProvider` existente.** Não cria novo `now`. `nowProvider` já vive em `services_provider.dart` ao lado do `moneyServiceProvider`.

3. **Interface 100% pura.** `domain/services/date_formatter_service.dart` não importa `intl` nem nada externo — mesma regra do `IMoneyService`. Vive em domain porque `presentation/` precisa importar a abstração e a regra de dependência proíbe `presentation/ → infrastructure/`.

4. **Implementação singleton via `keepAlive: true`.** `DateFormat` é pesado pra construir; manter uma instância por método via campos privados na impl. Provider `keepAlive: true` (mesmo do `moneyService`).

5. **Notifier é a única porta — widgets não chamam `DateFormat`.** CLAUDE.md já proíbe screens lerem providers de service. Estendido na spec: **widgets também não formatam datas inline**. Toda string formatada vem do notifier via presentation data. Isso justifica os Itens A–E abaixo.

6. **Group builders viram cascas finas.** `expense_groups_builder.dart` e `notification_groups_builder.dart` perdem `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize`, `_atStartOfDay`. Recebem `IDateFormatterService` como parâmetro e chamam `service.relativeGroupHeader(item.createdAt)` direto. Sem genéricos — mantém dois builders por clareza.

7. **Não vira extension nem static.** Service injetado é o padrão do projeto (Money). Static não permite mock; extension não permite injeção e não permite trocar locale futuramente.

## Itens A–E — refatorações de presentation para destravar a remoção das extensions

Essas migrações **não são novas features** — são consequência direta de eliminar `DateFormat(...)` em widgets e remover as duas extensions. Listadas aqui pra você aprovar como bloco ou recortar:

- **Item A** — `ExpenseItemPresentationData` ganha `formattedDate` e `formattedTime`. `ExpensesNotifier._toItem` formata via service. `expense_item_widget.dart` deixa de chamar `DateFormat`. Afeta: previews/mocks de `expense_item_widget`, testes de `expenses_notifier`. **Sem isso o widget continua chamando `DateFormat` direto.**

- **Item B** — `NotificationItemPresentationData(notification, formattedTime)` (novo, em `presentation/data/notification/`). `NotificationsState.items` retipa para `List<NotificationItemPresentationData>`. `NotificationsNotifier` injeta `IDateFormatterService` e formata. `notification_card_widget.dart` recebe o presentation data. `notification_groups_builder.dart` muda assinatura para receber `List<NotificationItemPresentationData>` e usar `item.notification.createdAt`. **Sem isso o widget continua chamando `DateFormat` direto.**

- **Item C** — `ExpenseNotifier` (form) e `BudgetFormNotifier` injetam `IDateFormatterService`. `ExpenseState` ganha `formattedDate: String?`. `BudgetFormState` ganha `formattedPeriod: String?`. `expense_date_field_widget.dart` e `budget_date_field_widget.dart` deixam de importar `date_time_extension.dart` — passam a receber `displayValue: String?`. **Sem isso a extension `date_time_extension.dart` não pode ser removida.**

- **Item D** — `BudgetFormState` ganha `descriptionHint: String`. `BudgetFormNotifier` calcula via `service.formatMonth(now)` em `build()`. `budget_description_field_widget.dart` recebe `hint` como parâmetro ao invés de gerar internamente. **Sem isso `budget_description_field_widget.dart` continua chamando `DateFormat`.**

- **Item E** — `ExpensesFiltersState` ganha `formattedPeriodSummary: String?`. `ExpensesFiltersNotifier` calcula via `service.formatPeriod(...)` em cada update do draft que envolva data. `expenses_filter_period_section_widget.dart` recebe `formattedSummary` ao invés de `startDate`/`endDate`. **Sem isso o widget continua chamando `DateFormat`.**

Se você aprovar só A + B + C + D + E parcialmente, ajusto o critério de verificação final (que hoje é "grep DateFormat( em lib/src/presentation retorna zero").

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde.
- `grep -rn "DateFormat(" lib/src/presentation/` retorna **zero** linhas (todas migradas pro service).
- `grep -rn "DateFormat(" lib/src/` retorna apenas: `lib/src/infrastructure/services/date_formatter_service.dart` + os 5 arquivos de infra/data já listados como fora de escopo.
- Arquivos `lib/src/presentation/extensions/date_time_extension.dart` e `lib/src/presentation/extensions/int_time_extension.dart` removidos.
- Nenhum arquivo da camada `presentation/` importa `package:intl/intl.dart`.
