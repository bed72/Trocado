# Spec: date-formatter-service

## Context

A camada `presentation/` formata e converte datas em ≈ 15 sítios via `DateFormat` instanciado inline com locale `'pt_BR'` hardcoded. Duas extensions (`DateTimeExtensions`, `IntExtensions`, `StringToDateTimeExtension`) tentam abstrair parte disso mas convivem com os `DateFormat` inline criando dois caminhos pro mesmo problema. Lógica de "Hoje / Ontem / weekday / mês" está duplicada byte-a-byte entre `expense_groups_builder.dart` e `notification_groups_builder.dart`. `_daysRemaining` e `_formatEndDate` duplicados entre `active_budget_notifier.dart` e `budgets_notifier.dart`. Nada disso é injetável ou mockável.

O projeto já tem `IMoneyService` como padrão: interface pura em `domain/services/`, implementação em `infrastructure/services/`, provider em `main/providers/services_provider.dart`. Esta spec aplica o mesmo template a datas.

## Scope

**Dentro do escopo:**
- Criar `IDateFormatterService` em `domain/services/` (interface pura).
- Criar `DateFormatterService` em `infrastructure/services/` (impl com `intl`).
- Registrar `dateFormatterServiceProvider` em `main/providers/services_provider.dart`.
- Migrar todos os call sites de `DateFormat(...)` em `lib/src/presentation/` para o service via notifier.
- Estender presentation data (`ExpenseItemPresentationData`, novo `NotificationItemPresentationData`) e form states com strings pré-formatadas para que widgets parem de chamar `DateFormat` direto.
- Remover `lib/src/presentation/extensions/date_time_extension.dart` e `lib/src/presentation/extensions/int_time_extension.dart`.
- Atualizar testes de notifiers afetados para mockar `IDateFormatterService`.

**Fora do escopo:**
- Conversões `'yyyy-MM-dd'` em `infrastructure/clients/http/requests/` e `data/extensions/` (5 arquivos): ficam como estão.
- `home_greeting_widget.dart`: usa `DateTime.now().hour` — não é formatação.
- Suporte multi-locale: locale `pt_BR` continua hardcoded **na impl**, mas centralizado num único arquivo.

---

## Requirements

### Requirement: Interface `IDateFormatterService` pura em `domain/`

The system SHALL expose `IDateFormatterService` em `lib/src/domain/services/date_formatter_service.dart` declarando exatamente 9 métodos: `formatShortDate(int millis)`, `formatDayMonth(int millis)`, `formatTime(int millis)`, `formatMonth(DateTime date)`, `formatPeriod(int startMillis, int endMillis)`, `relativeGroupHeader(int millis)`, `daysUntil(int endMillis)`, `toIsoDate(int millis)`, `fromIsoDate(String iso)`.

The system SHALL NOT importar nenhum pacote externo nesse arquivo (Dart puro, mesma regra de `IMoneyService`).

#### Scenario: Interface sem dependências externas

- **Given** a interface criada
- **When** `grep -rn "import" lib/src/domain/services/date_formatter_service.dart` é executado
- **Then** zero linhas retornam (arquivo sem imports)

#### Scenario: Interface declara as 9 assinaturas

- **Given** `IDateFormatterService`
- **When** sua superfície pública é inspecionada
- **Then** os 9 métodos listados estão presentes com exatamente as assinaturas especificadas (sem parâmetros opcionais extras como `{DateTime? now}`)

---

### Requirement: Implementação `DateFormatterService` em `infrastructure/`

The system SHALL implementar `DateFormatterService` em `lib/src/infrastructure/services/date_formatter_service.dart` recebendo `{required DateTime Function() now}` no construtor. As instâncias internas de `DateFormat` SHALL ser campos `final` (uma por padrão de formato), alocadas no construtor. Locale `'pt_BR'` SHALL ser constante privada usada em todos os formatos exceto `_iso` (ISO 8601 não recebe locale).

The system SHALL formatar datas relativas (`relativeGroupHeader`, `daysUntil`) usando exclusivamente o `now()` injetado — sem chamadas a `DateTime.now()` direto na impl.

#### Scenario: formatShortDate em pt_BR

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.formatShortDate(DateTime(2026, 3, 15).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'15/03/2026'`

#### Scenario: relativeGroupHeader para o mesmo dia

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12, 14, 30))`
- **When** `formatter.relativeGroupHeader(DateTime(2026, 5, 12, 9, 0).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'Hoje'`

#### Scenario: relativeGroupHeader para o dia anterior

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.relativeGroupHeader(DateTime(2026, 5, 11).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'Ontem'`

#### Scenario: relativeGroupHeader para 3 dias atrás

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.relativeGroupHeader(DateTime(2026, 5, 9).millisecondsSinceEpoch)` é chamado
- **Then** retorna uma string começando com weekday capitalizado + `, ` + dia abreviado em lowercase (ex: `'Sábado, 09 mai'`)

#### Scenario: relativeGroupHeader para 7+ dias atrás

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.relativeGroupHeader(DateTime(2026, 3, 1).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'Março 2026'`

#### Scenario: formatPeriod no mesmo ano

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.formatPeriod(start, end)` com `start = 01/01/2026` e `end = 31/12/2026`
- **Then** retorna `'01/01 – 31/12'`

#### Scenario: formatPeriod cruzando anos

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 1, 5))`
- **When** `formatter.formatPeriod(start, end)` com `start = 01/12/2025` e `end = 31/01/2026`
- **Then** retorna `'01/12/25 – 31/01/26'`

#### Scenario: daysUntil cruzando meia-noite

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12, 23, 30))`
- **When** `formatter.daysUntil(DateTime(2026, 5, 15, 6, 0).millisecondsSinceEpoch)` é chamado
- **Then** retorna `4` (ignora hora; 12→13, 13→14, 14→15, +1 inclusivo)

#### Scenario: toIsoDate e fromIsoDate são simétricos

- **Given** `formatter`
- **When** `formatter.fromIsoDate(formatter.toIsoDate(millis))` é chamado para uma data qualquer
- **Then** retorna o `millis` original (truncado ao início do dia local)

---

### Requirement: Provider Riverpod registrado em `services_provider.dart`

The system SHALL registrar `dateFormatterServiceProvider` em `lib/src/main/providers/services_provider.dart` com anotação `@Riverpod(keepAlive: true)`, consumindo `nowProvider` existente via `ref.watch(nowProvider)` e injetando no construtor de `DateFormatterService`.

#### Scenario: Provider materializado tem instância singleton

- **Given** um `ProviderContainer` com overrides padrão
- **When** `container.read(dateFormatterServiceProvider)` é chamado duas vezes em sequência
- **Then** as duas chamadas retornam a mesma instância (`keepAlive: true` + provider funcional)

#### Scenario: Provider injeta `nowProvider`

- **Given** um override de `nowProvider` para retornar `() => DateTime(2030, 1, 1)`
- **When** `container.read(dateFormatterServiceProvider).relativeGroupHeader(DateTime(2030, 1, 1).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'Hoje'` (provando que o `now()` injetado foi usado)

---

### Requirement: Todos os call sites de `DateFormat` em `presentation/` migrados

The system SHALL eliminar toda chamada a `DateFormat(...)` da camada `lib/src/presentation/`. Notifiers SHALL injetar `IDateFormatterService` via `ref.watch(dateFormatterServiceProvider)` em `build()` como campo `late` (não `late final`). Widgets SHALL receber strings pré-formatadas via presentation data ou parâmetros — nunca chamar `DateFormat` direto.

#### Scenario: Zero `DateFormat(` na camada presentation

- **Given** a migração concluída
- **When** `grep -rn "DateFormat(" lib/src/presentation/` é executado
- **Then** retorna zero linhas

#### Scenario: Zero import de `intl` na camada presentation

- **Given** a migração concluída
- **When** `grep -rn "package:intl" lib/src/presentation/` é executado
- **Then** retorna zero linhas

#### Scenario: Notifiers que formatam datas injetam o service

- **Given** `active_budget_notifier.dart`, `budgets_notifier.dart`, `expenses_notifier.dart`, `expenses_filters_notifier.dart`, `notifications_notifier.dart`, `expense_notifier.dart` (form), `budget_form_notifier.dart`
- **When** seus métodos `build()` são inspecionados
- **Then** cada um contém `_dateFormatter = ref.watch(dateFormatterServiceProvider);`

---

### Requirement: Extensions globais removidas

The system SHALL remover `lib/src/presentation/extensions/date_time_extension.dart` e `lib/src/presentation/extensions/int_time_extension.dart`. Nenhum arquivo em `lib/` ou `test/` SHALL importar essas extensions ou referenciar `DateTimeExtensions`, `IntExtensions`, `StringToDateTimeExtension`.

#### Scenario: Arquivos não existem

- **Given** a migração concluída
- **When** `ls lib/src/presentation/extensions/date_time_extension.dart lib/src/presentation/extensions/int_time_extension.dart` é executado
- **Then** ambos os arquivos não existem (erro "No such file")

#### Scenario: Sem referências remanescentes

- **Given** a migração concluída
- **When** `grep -rn "date_time_extension\|int_time_extension\|DateTimeExtensions\|IntExtensions\|StringToDateTimeExtension" lib/ test/` é executado
- **Then** retorna zero linhas

---

### Requirement: Builders de grupo delegam formatação ao service

The system SHALL refatorar `expense_groups_builder.dart` e `notification_groups_builder.dart` para receber `IDateFormatterService dateFormatter` como parâmetro nomeado obrigatório. Os helpers privados `_atStartOfDay`, `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize` SHALL ser removidos de ambos os arquivos. Header de cada item SHALL vir de `dateFormatter.relativeGroupHeader(item.expense.createdAt)` (ou `item.notification.createdAt`).

#### Scenario: expense_groups_builder sem helpers de data

- **Given** o builder refatorado
- **When** `grep -n "_atStartOfDay\|_headerFor\|_weekdayHeader\|_monthHeader\|_capitalize" lib/src/presentation/ui/expenses/data/expense_groups_builder.dart` é executado
- **Then** retorna zero linhas

#### Scenario: notification_groups_builder sem helpers de data

- **Given** o builder refatorado
- **When** `grep -n "_atStartOfDay\|_headerFor\|_weekdayHeader\|_monthHeader\|_capitalize" lib/src/presentation/ui/notifications/data/notification_groups_builder.dart` é executado
- **Then** retorna zero linhas

#### Scenario: notification_groups_builder aceita presentation data

- **Given** o builder refatorado
- **When** sua assinatura é inspecionada
- **Then** o primeiro parâmetro tipa `List<NotificationItemPresentationData>` (não `List<NotificationModel>`)

---

### Requirement: Presentation data carrega strings pré-formatadas

The system SHALL estender `ExpenseItemPresentationData` com campos `final String formattedDate;` e `final String formattedTime;`, incluídos em `props` para igualdade Equatable.

The system SHALL criar `NotificationItemPresentationData` em `lib/src/presentation/data/notification/notification_item_presentation_data.dart` com campos `final NotificationModel notification;` e `final String formattedTime;`.

The system SHALL substituir `List<NotificationModel>` por `List<NotificationItemPresentationData>` em `NotificationsState.items` e `NotificationGroupPresentationData.notifications`.

#### Scenario: ExpenseItemPresentationData estendido

- **Given** o tipo refatorado
- **When** sua superfície é inspecionada
- **Then** contém `formattedDate: String` e `formattedTime: String` no construtor e em `props`

#### Scenario: notification_card_widget não formata

- **Given** o widget refatorado
- **When** seu arquivo é inspecionado
- **Then** não contém `DateFormat` nem `import 'package:intl/intl.dart';`
- **And** consome `NotificationItemPresentationData` ao invés de `NotificationModel` direto

#### Scenario: expense_item_widget não formata

- **Given** o widget refatorado
- **When** seu arquivo é inspecionado
- **Then** não contém `DateFormat` nem `import 'package:intl/intl.dart';`
- **And** os campos `formattedDate` e `formattedTime` aparecem no construtor

---

### Requirement: Form states carregam strings pré-formatadas

The system SHALL adicionar `final String? formattedDate;` em `ExpenseState` (form).

The system SHALL adicionar `final String? formattedPeriod;` e `final String descriptionHint;` em `BudgetFormState`.

The system SHALL adicionar `final String? formattedPeriodSummary;` em `ExpensesFiltersState`.

Esses campos SHALL ser recalculados pelos respectivos notifiers em `build()` e em qualquer mutação que mude as datas subjacentes.

#### Scenario: expense_date_field_widget recebe display value

- **Given** o widget refatorado
- **When** seu construtor é inspecionado
- **Then** aceita `String? displayValue` (não `int? date`)
- **And** o import de `date_time_extension.dart` foi removido

#### Scenario: budget_date_field_widget recebe display value

- **Given** o widget refatorado
- **When** seu construtor é inspecionado
- **Then** aceita `String? displayValue` (não `int? startDate, int? endDate`)
- **And** o import de `date_time_extension.dart` foi removido

#### Scenario: budget_description_field_widget recebe hint

- **Given** o widget refatorado
- **When** seu construtor é inspecionado
- **Then** aceita `String hint` (não-nullable, vem do notifier)
- **And** o método `getCurrentMonth()` foi removido

#### Scenario: expenses_filter_period_section_widget recebe summary

- **Given** o widget refatorado
- **When** seu construtor é inspecionado
- **Then** aceita `String? formattedSummary` (não `int? startDate, int? endDate`)

---

### Requirement: Testes migrados mockam `IDateFormatterService`

The system SHALL adicionar `MockDateFormatterService` em `test/mocks/mocks.dart`. Testes de notifiers que dependem de `IDateFormatterService` SHALL declarar a variável com o tipo da interface (`late IDateFormatterService dateFormatter;`) e instanciar com o mock. Asserts sobre strings formatadas SHALL usar valores stubados (não chamar `DateFormat` no próprio teste).

The system SHALL adicionar `test/src/infrastructure/services/date_formatter_service_test.dart` com cobertura dos 9 métodos, incluindo as bordas críticas de `relativeGroupHeader` (mesmo dia, dia anterior, 6 dias atrás, 7+ dias) e `formatPeriod` (mesmo ano, anos diferentes).

The system SHALL remover `await initializeDateFormatting('pt_BR')` dos testes de notifier migrados (não dependem mais de `intl` runtime). O setup permanece apenas no teste do `DateFormatterService` próprio e nos testes de builder enquanto migram.

#### Scenario: Mock declarado com o tipo da interface

- **Given** um teste de notifier migrado
- **When** `setUp` é inspecionado
- **Then** declara `late IDateFormatterService dateFormatter;` (não `late MockDateFormatterService dateFormatter;`)

#### Scenario: Asserts não chamam DateFormat

- **Given** um teste de notifier migrado
- **When** seu corpo é inspecionado
- **Then** não contém `DateFormat(`

---

### Requirement: `intl` permanece restrito a infra/data fora de escopo

The system SHALL preservar os call sites de `DateFormat('yyyy-MM-dd')` em `infrastructure/clients/http/requests/` (`expense_request.dart`, `budget_request.dart`, `expense_filter_request.dart`) e `data/extensions/` (`expense_response_extension.dart`, `budget_response_extension.dart`, `active_budget_response_extension.dart`). Esses não migram nessa spec.

#### Scenario: `DateFormat` apenas em arquivos esperados

- **Given** a migração concluída
- **When** `grep -rn "DateFormat(" lib/src/` é executado
- **Then** retorna exatamente 7 arquivos: `infrastructure/services/date_formatter_service.dart`, `infrastructure/clients/http/requests/expense_filter_request.dart`, `infrastructure/clients/http/requests/expense_request.dart`, `infrastructure/clients/http/requests/budget_request.dart`, `data/extensions/expense_response_extension.dart`, `data/extensions/budget/active_budget_response_extension.dart`, `data/extensions/budget/budget_response_extension.dart`

---

## Verificação

- `flutter analyze` — zero issues.
- `flutter test` — verde.
- Todos os cenários acima validados via grep/inspeção.
- Smoke manual: Home, Despesas, Orçamentos, Notificações; criar/editar despesa e orçamento; conferir que o display das datas nos form fields agora aparece como `dd/MM/yyyy` (mudança proposital — antes era `"15 de Março de 2026"` long-form).
