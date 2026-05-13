# Design: date-formatter-service

## Interface — `domain/services/date_formatter_service.dart`

```dart
abstract interface class IDateFormatterService {
  String formatShortDate(int millis);
  String formatDayMonth(int millis);
  String formatTime(int millis);
  String formatMonth(DateTime date);

  String formatPeriod(int startMillis, int endMillis);
  String relativeGroupHeader(int millis);
  int daysUntil(int endMillis);

  String toIsoDate(int millis);
  int fromIsoDate(String iso);
}
```

**Regras:**
- Arquivo sem imports (Dart puro). Mantém a regra de ouro do `domain/`.
- Nenhum método recebe `DateTime? now`. Implementação injeta `now()` via construtor.
- Tipos primitivos (`int millis`, `String iso`) ou `DateTime` quando faz mais sentido (`formatMonth` aceita `DateTime` porque chamadores sempre têm).
- Métodos relativos (`relativeGroupHeader`, `daysUntil`) usam o `now()` injetado — comportamento determinístico em testes.

**Por que `formatMonth` recebe `DateTime` e não `int`?** O único call site hoje (`budget_description_field_widget`) tem `DateTime.now()` direto. Aceitar `DateTime` evita conversão dupla; outros métodos que recebem `int millis` é porque os dados internos do app são `int millis` (CLAUDE.md "Datas").

---

## Implementação — `infrastructure/services/date_formatter_service.dart`

```dart
import 'package:intl/intl.dart';

import 'package:trocado/src/domain/services/date_formatter_service.dart';

final class DateFormatterService implements IDateFormatterService {
  static const _locale = 'pt_BR';

  final DateTime Function() _now;

  final DateFormat _shortDate = DateFormat('dd/MM/yyyy', _locale);
  final DateFormat _dayMonth = DateFormat('dd/MM', _locale);
  final DateFormat _dayMonthShortYear = DateFormat('dd/MM/yy', _locale);
  final DateFormat _time = DateFormat('HH:mm', _locale);
  final DateFormat _month = DateFormat('MMMM', _locale);
  final DateFormat _weekday = DateFormat('EEEE', _locale);
  final DateFormat _dayMonthAbbrev = DateFormat('dd MMM', _locale);
  final DateFormat _monthYear = DateFormat('MMMM y', _locale);
  final DateFormat _iso = DateFormat('yyyy-MM-dd');

  DateFormatterService({required DateTime Function() now}) : _now = now;

  @override
  String formatShortDate(int millis) =>
      _shortDate.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatDayMonth(int millis) =>
      _dayMonth.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatTime(int millis) =>
      _time.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  String formatMonth(DateTime date) => _capitalize(_month.format(date));

  @override
  String formatPeriod(int startMillis, int endMillis) {
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final currentYear = _now().year;
    final sameYear = start.year == currentYear && end.year == currentYear;
    final format = sameYear ? _dayMonth : _dayMonthShortYear;

    return '${format.format(start)} – ${format.format(end)}';
  }

  @override
  String relativeGroupHeader(int millis) {
    final day = _atStartOfDay(DateTime.fromMillisecondsSinceEpoch(millis));
    final reference = _atStartOfDay(_now());
    final diff = reference.difference(day).inDays;

    return switch (diff) {
      0 => 'Hoje',
      1 => 'Ontem',
      >= 2 && < 7 => _weekdayHeader(day),
      _ => _capitalize(_monthYear.format(day)),
    };
  }

  @override
  int daysUntil(int endMillis) {
    final now = _now();
    final end = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays + 1;
  }

  @override
  String toIsoDate(int millis) =>
      _iso.format(DateTime.fromMillisecondsSinceEpoch(millis));

  @override
  int fromIsoDate(String iso) => _iso.parse(iso).millisecondsSinceEpoch;

  DateTime _atStartOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _weekdayHeader(DateTime day) {
    final weekday = _capitalize(_weekday.format(day));
    final dayMonth = _dayMonthAbbrev.format(day).toLowerCase();

    return '$weekday, $dayMonth';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
```

**Pontos:**
- Todas as instâncias `DateFormat` são `final` — alocadas uma vez por instância do service. `keepAlive: true` no provider garante uma única instância no app.
- `_iso` não recebe locale — formato ISO 8601 é universal.
- `relativeGroupHeader` usa `switch` expression com pattern matching no `int diff` (Dart 3) — substitui a sequência de `if`s espalhada nos dois group builders.
- `_capitalize` substitui o regex `RegExp(r'de (\w)')` do `date_time_extension.dart` antigo — capitaliza só a primeira letra do mês, que é o que todos os call sites realmente queriam.

---

## Provider — `main/providers/services_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/infrastructure/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
IMoneyService moneyService(Ref _) => MoneyService();

@Riverpod(keepAlive: true)
DateTime Function() now(Ref _) => DateTime.now;

@Riverpod(keepAlive: true)
IDateFormatterService dateFormatterService(Ref ref) =>
    DateFormatterService(now: ref.watch(nowProvider));
```

`nowProvider` já existe — provider novo só consome.

---

## Migração — call sites

### `active_budget_notifier.dart`

Antes:
```dart
String _formatEndDate(int endDate) =>
    DateFormat('dd/MM', 'pt_BR').format(DateTime.fromMillisecondsSinceEpoch(endDate));

int _daysRemaining(int endDate) {
  final now = DateTime.now();
  ...
}
```

Depois:
```dart
late IMoneyService _moneyService;
late IBudgetRepository _repository;
late IDateFormatterService _dateFormatter;

@override
Future<BudgetCardPresentationData?> build() async {
  _moneyService = ref.watch(moneyServiceProvider);
  _repository = ref.watch(budgetRepositoryProvider);
  _dateFormatter = ref.watch(dateFormatterServiceProvider);
  return await _load();
}

BudgetCardPresentationData _toCardData(ActiveBudgetModel model) {
  final daysRemaining = _dateFormatter.daysUntil(model.endDate);
  final dailyBudget = (model.remaining / max(1, daysRemaining)).round();
  return BudgetCardPresentationData(
    ...
    formattedEndDate: _dateFormatter.formatDayMonth(model.endDate),
    ...
  );
}
```

Métodos `_formatEndDate` e `_daysRemaining` deletados. Import de `intl` e de `dart:math` permanecem (math ainda usado para `max`).

### `budgets_notifier.dart`

Mesmo padrão. `_formatPeriod` → `_dateFormatter.formatPeriod(startMs, endMs)`. `_formatEndDate` → `_dateFormatter.formatDayMonth(endDate)`. `_daysRemaining` → `_dateFormatter.daysUntil(endDate)`. Linha 67 (`DateTime.now().millisecondsSinceEpoch` em `_loadFirstPage`) muda para `_now().millisecondsSinceEpoch` injetando `nowProvider` também (consistência — outro lugar lendo `DateTime.now()` direto).

Decisão: injetar `nowProvider` separado **ou** expor `IDateFormatterService.currentMillis()` para esse uso? Recomendo injetar `nowProvider` separado nesse notifier — `currentMillis()` no service polui a API com algo que não é formatação. Pattern consistente: notifier que precisa de "agora" injeta `nowProvider`.

### `expenses_notifier.dart`

`_periodLabel(int? start, int? end)` → continua existindo (não é um simples `formatPeriod` — tem "desde X", "até Y", "X – Y" condicionalmente). Internamente troca `DateFormat('dd/MM/yyyy', 'pt_BR').format(...)` por `_dateFormatter.formatShortDate(...)`. Estrutura condicional permanece no notifier.

`_toItem(ExpenseModel expense)` → passa a popular `formattedDate` e `formattedTime` via `_dateFormatter.formatDayMonth(expense.createdAt)` / `formatTime(expense.createdAt)`.

### `expense_groups_builder.dart`

Antes: 67 linhas com `_atStartOfDay`, `_headerFor`, `_weekdayHeader`, `_monthHeader`, `_capitalize`.

Depois:

```dart
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_group_presentation_data.dart';

List<ExpenseGroupPresentationData> buildExpenseGroups(
  List<ExpenseItemPresentationData> items, {
  required IDateFormatterService dateFormatter,
}) {
  if (items.isEmpty) return const [];

  final groups = <ExpenseGroupPresentationData>[];
  String? current;
  List<ExpenseItemPresentationData> currentBucket = [];

  for (final item in items) {
    final header = dateFormatter.relativeGroupHeader(item.expense.createdAt);

    if (current == null || current != header) {
      if (current != null) {
        groups.add(ExpenseGroupPresentationData(
          header: current, expenses: currentBucket,
        ));
      }
      current = header;
      currentBucket = [item];
    } else {
      currentBucket.add(item);
    }
  }

  if (current != null) {
    groups.add(ExpenseGroupPresentationData(header: current, expenses: currentBucket));
  }

  return groups;
}
```

Builder fica em ≈ 30 linhas. Sem helpers privados de data. Quem chama (futuro notifier consumidor — hoje o builder é exportado para a screen via outro provider, ver `expense_groups_builder_test.dart`) passa `dateFormatter` explicitamente. Alternativa: builder vira método de classe que recebe `dateFormatter` no construtor — rejeitada por não trazer benefício e mudar mais call sites.

### `notification_groups_builder.dart`

Mesmo padrão. Item recebido muda de `NotificationModel` para `NotificationItemPresentationData` (consequência do Item B do proposal). Header derivado de `item.notification.createdAt`.

### `notifications_notifier.dart`

Antes: emite `List<NotificationModel>` em `NotificationsState.items`.

Depois:
```dart
late IDateFormatterService _dateFormatter;
late INotificationRepository _repository;

@override
Future<NotificationsState> build() async {
  _dateFormatter = ref.watch(dateFormatterServiceProvider);
  _repository = ref.watch(notificationRepositoryProvider);
  return await _loadFirstPage();
}

NotificationItemPresentationData _toItem(NotificationModel notification) =>
    NotificationItemPresentationData(
      notification: notification,
      formattedTime: _dateFormatter.formatTime(notification.createdAt),
    );
```

`NotificationsState.items: List<NotificationItemPresentationData>`. `loadMore` e `_loadFirstPage` aplicam `_toItem` no map.

### `notification_card_widget.dart`

Antes: recebe `NotificationModel`, formata `time` inline.

Depois: recebe `NotificationItemPresentationData`. Usa `data.formattedTime` direto. Remove import de `intl`. Remove cálculo inline de `createdAt`.

### `expense_item_widget.dart`

Antes: recebe `expense` + `formattedValue`, formata `date` e `time` inline.

Depois: recebe `expense` + `formattedValue` + `formattedDate` + `formattedTime`. Sem cálculo inline. Remove import de `intl`.

### `expenses_filter_period_section_widget.dart`

Antes:
```dart
final int? endDate;
final int? startDate;
// ...
Widget _summary(BuildContext context) {
  final format = DateFormat('dd/MM/yyyy', 'pt_BR');
  // ...
}
```

Depois:
```dart
final String? formattedSummary;
// ...
if (formattedSummary != null) _summary(context, formattedSummary!),

Widget _summary(BuildContext context, String text) => Text(
  text,
  style: context.typography.bodyMedium?.copyWith(...),
);
```

Notifier `ExpensesFiltersNotifier` precisa preencher `formattedPeriodSummary` no state sempre que `draft.startDate` e `draft.endDate` estiverem ambos preenchidos:

```dart
String? _periodSummaryOf(ExpenseFilterModel draft) {
  if (draft.startDate == null || draft.endDate == null) return null;
  return _dateFormatter.formatPeriod(draft.startDate!, draft.endDate!);
}
```

Aplicado em todo `state = state.copyWith(...)` que envolve mudança em `draft`. Considerar getter computado em `ExpensesFiltersState` ao invés de campo (`String? get formattedPeriodSummary => ...`) — mais simples e elimina drift. Decisão: **getter computado**, com referência ao `dateFormatter`? Não — `Equatable` precisa de campos para `props`, e o state não tem acesso ao service. Solução: o **notifier** computa e injeta no state como campo. Trabalho extra é trivial — uma linha em cada mutação.

### `expense_date_field_widget.dart` / `budget_date_field_widget.dart`

Antes:
```dart
import 'package:trocado/src/presentation/extensions/date_time_extension.dart';
// ...
String? get _displayValue =>
    date != null ? DateTime.fromMillisecondsSinceEpoch(date!).format() : null;
```

Depois:
```dart
final String? displayValue;
// ... usa direto sem extension
```

Form notifiers (`ExpenseNotifier`, `BudgetFormNotifier`) populam `formattedDate` / `formattedPeriod` no state via `_dateFormatter.formatShortDate(...)` (para `expense`) ou `_dateFormatter.formatPeriod(start, end)` (para `budget`). **Diferença com extensions antigas:**

- `date_time_extension.format()` produzia `"15 de Março de 2026"` (long form `d 'de' MMMM 'de' y` capitalizado).
- `date_time_extension.formatShort()` produzia `"15 de Mar"` (`d 'de' MMM` capitalizado).
- API nova usa `formatShortDate()` → `"15/03/2026"`.

**Mudança visual proposital:** padronizar com o resto do app (filtro de período, lista de despesas — todos usam `dd/MM/yyyy` ou `dd/MM`). Format long-form `"15 de Março de 2026"` só existia nessas extensions e em 2 fields. Se você quiser preservar o formato long, adicionamos `formatLongDate(int millis)` e `formatLongDayMonth(int millis)` à API — mas recomendo padronizar.

### `budget_description_field_widget.dart`

Antes:
```dart
hint: 'Ex: Orçamento de ${getCurrentMonth()}',
// ...
String getCurrentMonth() => DateFormat('MMMM', 'pt_BR').format(DateTime.now());
```

Depois:
```dart
final String hint;
// ...
hint: hint,
```

`BudgetFormNotifier.build()`:
```dart
late IDateFormatterService _dateFormatter;
late DateTime Function() _now;

@override
BudgetFormState build(...) {
  _dateFormatter = ref.watch(dateFormatterServiceProvider);
  _now = ref.watch(nowProvider);
  // ...
  return BudgetFormState(
    descriptionHint: 'Ex: Orçamento de ${_dateFormatter.formatMonth(_now())}',
    // ...
  );
}
```

`BudgetFormState.descriptionHint: String` é imutável (não muda durante a vida do form). Calculado uma vez no `build()`.

---

## Remoção das extensions

Após Itens C + D migrados, os seguintes arquivos **não têm mais consumidores** e são deletados:

- `lib/src/presentation/extensions/date_time_extension.dart`
- `lib/src/presentation/extensions/int_time_extension.dart`

Verificação:
```bash
grep -rn "date_time_extension\|int_time_extension\|DateTimeExtensions\|IntExtensions\|StringToDateTimeExtension" lib/ test/
```
deve retornar zero linhas (excluindo definição inexistente).

---

## Estratégia de testes

| Arquivo | Tipo | Mock em | Testa |
|---|---|---|---|
| `test/src/infrastructure/services/date_formatter_service_test.dart` (NOVO) | unit | — (instancia com `now: () => DateTime(...)` fixo) | Cada método em pt_BR; bordas de `relativeGroupHeader` (mesmo dia, ontem, 6 dias atrás, 7+ dias); `formatPeriod` em mesmo ano e em anos diferentes; `daysUntil` cruzando meia-noite |
| `test/src/presentation/providers/active_budget_notifier_test.dart` | update | `MockDateFormatterService` | Stubar `formatDayMonth`/`daysUntil` com valores conhecidos; remover `initializeDateFormatting('pt_BR')` e `DateFormat(...)` dos asserts |
| `test/src/presentation/providers/budgets_notifier_test.dart` | update | `MockDateFormatterService` | Idem |
| `test/src/presentation/providers/expenses_notifier_test.dart` | update | `MockDateFormatterService` | Idem; cobrir `formattedDate`/`formattedTime` no item |
| `test/src/presentation/providers/expenses_filters_notifier_test.dart` | update | `MockDateFormatterService` | Cobrir `formattedPeriodSummary` aparecendo/limpando conforme `draft` |
| `test/src/presentation/providers/notifications_notifier_test.dart` | update | `MockDateFormatterService` | `formattedTime` no item |
| `test/src/presentation/screens/expenses/data/expense_groups_builder_test.dart` | update | `MockDateFormatterService` | Stubar `relativeGroupHeader` com headers conhecidos; o builder não roda `DateFormat` mais |
| `test/src/presentation/screens/notifications/data/notification_groups_builder_test.dart` | update | `MockDateFormatterService` | Idem |
| Testes que removem | — | — | Se `int_time_extension_test.dart` / `date_time_extension_test.dart` existirem (não encontrados na auditoria), remover |

`test/mocks/mocks.dart` ganha:
```dart
final class MockDateFormatterService extends Mock implements IDateFormatterService {}
```

**`initializeDateFormatting('pt_BR')` nos testes de notifier:** removida nos testes migrados — eles usam `MockDateFormatterService` agora, sem dependência real do `intl` runtime. Permanece no teste do `DateFormatterService` (único que executa `intl` de verdade) e nos testes de builder se eles ainda existirem antes da migração estar completa.

---

## Sequência de execução em testes do `DateFormatterService`

```dart
void main() {
  late IDateFormatterService formatter;
  final fixedNow = DateTime(2026, 5, 12, 14, 30);

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    formatter = DateFormatterService(now: () => fixedNow);
  });

  test('formatShortDate returns dd/MM/yyyy in pt_BR', () {
    final data = formatter.formatShortDate(
      DateTime(2026, 3, 15).millisecondsSinceEpoch,
    );
    expect(data, '15/03/2026');
  });

  test('relativeGroupHeader returns Hoje for today', () {
    final data = formatter.relativeGroupHeader(fixedNow.millisecondsSinceEpoch);
    expect(data, 'Hoje');
  });

  test('relativeGroupHeader returns Ontem for yesterday', () {
    final yesterday = fixedNow.subtract(const Duration(days: 1));
    final data = formatter.relativeGroupHeader(yesterday.millisecondsSinceEpoch);
    expect(data, 'Ontem');
  });

  test('relativeGroupHeader returns weekday + dayMonth for last 6 days', () {
    final threeDaysAgo = fixedNow.subtract(const Duration(days: 3));
    final data = formatter.relativeGroupHeader(threeDaysAgo.millisecondsSinceEpoch);
    expect(data, matches(r'^(Segunda|Terça|Quarta|Quinta|Sexta|Sábado|Domingo)-feira, \d{2} \w{3}$'));
  });

  test('relativeGroupHeader returns Month Year for older dates', () {
    final twoMonthsAgo = DateTime(2026, 3, 1).millisecondsSinceEpoch;
    final data = formatter.relativeGroupHeader(twoMonthsAgo);
    expect(data, 'Março 2026');
  });

  test('formatPeriod uses dd/MM when both in current year', () {
    final start = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    final end = DateTime(2026, 12, 31).millisecondsSinceEpoch;
    final data = formatter.formatPeriod(start, end);
    expect(data, '01/01 – 31/12');
  });

  test('formatPeriod uses dd/MM/yy when crossing years', () {
    final start = DateTime(2025, 12, 1).millisecondsSinceEpoch;
    final end = DateTime(2026, 1, 31).millisecondsSinceEpoch;
    final data = formatter.formatPeriod(start, end);
    expect(data, '01/12/25 – 31/01/26');
  });

  test('toIsoDate and fromIsoDate are symmetric', () {
    final original = DateTime(2026, 3, 15).millisecondsSinceEpoch;
    final iso = formatter.toIsoDate(original);
    expect(iso, '2026-03-15');
    expect(formatter.fromIsoDate(iso), original);
  });
}
```

---

## Decisões alternativas descartadas

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Service injetado via Riverpod | Static utility class | Não permite mock, não permite trocar locale futuramente, foge do padrão do projeto |
| `now()` via construtor | `{DateTime? now}` em cada método | Polui assinatura, força null check em N call sites, inconsistente com `ExpensesFiltersNotifier` que já usa `nowProvider` |
| Provider depende de `nowProvider` existente | Novo `DateTime Function()` interno do service | `nowProvider` é o ponto único de "agora" no app; novo provider duplica responsabilidade |
| `formatMonth(DateTime)` aceita DateTime | `formatMonth(int millis)` | Único call site tem `DateTime.now()` direto; aceitar DateTime evita conversão dupla |
| Item B retipa `NotificationsState.items` | Widget continua recebendo `NotificationModel` e passa por extension | Mantém `DateFormat` no widget, viola CLAUDE.md "Services nunca lidos direto na screen" estendido pra widgets |
| Itens C/D propagam pelo form notifier | Widget chama service via Consumer interno | Viola "screens nunca leem service direto" — widget mais ainda |
| Long-form `"15 de Março de 2026"` removido | Adicionar `formatLongDate` à API | Já não usado em mais de 2 fields isolados; padronizar com o resto do app é positivo |
| Group builders mantidos (não viraram genéricos) | `buildGroups<T, G>(items, headerFor, groupBuilder)` | Genérico aumenta complexidade pra eliminar ~10 linhas; manter dois builders finos é mais legível |
| `_capitalize` na impl | Manter regex `RegExp(r'de (\w)')` | Regex hack — só capitaliza primeira letra do mês; substring direto é mais claro |
