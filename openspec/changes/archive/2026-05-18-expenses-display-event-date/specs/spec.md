# Spec: expenses-display-event-date

## Context

`ExpenseModel` carrega dois timestamps: `date` (quando a despesa aconteceu, ex.: `2026-04-30`) e `createdAt` (quando a linha foi gravada no banco, ex.: `2026-05-18T11:41:53Z`). Até esta change, a camada de apresentação da lista de despesas (`ExpensesScreen` e `RecentExpensesSection` no Home) formatava a string visível a partir de `createdAt`, e o agrupamento "Hoje/Ontem/..." também era calculado em cima de `createdAt`.

O viés ficou invisível em produção até o ambiente do reportador ter todos os seeds inseridos no mesmo dia (2026-05-18). Aplicar filtros por `Período` ou trocar `Ordenação` parecia ineficaz: a tela continuava mostrando "Hoje" e "18/05 · 11:41" para qualquer despesa, mesmo as de meses anteriores. Investigação descartou bug no client de filtro/RQL, na transmissão Dio e no backend (curl validou que `ge(date,...)` e `ordering=` funcionam). A causa real era o display lendo o campo errado.

A spec captura a regra explícita: **na camada de apresentação de despesas, `expense.date` é a fonte canônica do display e do agrupamento; `createdAt` é detalhe de persistência e não aparece pro usuário**. Notificações ficam fora — não têm um "date" separado, então `createdAt` é a única data disponível e permanece como hoje.

## Scope

**Dentro do escopo:**
- Substituir `expense.createdAt` por `expense.date` em todo display da lista de despesas (notifier individual, notifier de recent, builder de agrupamento).
- Trocar o formato apresentado de `dd/MM · HH:mm` (short date + time) para `28 de Abr` (long date, sem hora; ano omitido quando bate com o ano corrente, exibido quando difere) via `formatLongDate` do `IDateFormatterService`.
- Eliminar o campo `formattedTime` de `ExpenseItemPresentationData` e propagar a remoção em widgets, loading widgets, mock de preview e testes.

**Fora do escopo:**
- Notifications (`NotificationItemPresentationData`, `notification_groups_builder.dart`, `notification_card_widget.dart`) — mantêm `formattedTime` por `createdAt`.
- Couple "Conectados há ..." — `couple.createdAt` é semanticamente correto.
- Expense form (`ExpenseScreen`/`ExpenseNotifier`) — já usa `expense.date` + `formatLongDate`.
- Budgets — auditado e correto; usa `model.endDate`/`startDate`.
- Renomear `formattedDate` para `formattedEventDate` ou similar.
- Adicionar método novo ao `IDateFormatterService` — `formatLongDate` já cobre (após o ajuste do ano contextual nesta change).

---

## Requirements

### Requirement: Lista de despesas exibe a data do evento, não a de criação

The system SHALL formatar o `formattedDate` de `ExpenseItemPresentationData` a partir de `expense.date` (data do evento), nunca a partir de `expense.createdAt`. A regra SHALL valer tanto para `ExpensesNotifier._toItem` (tela de Despesas) quanto para `RecentExpensesNotifier._toItem` (Home).

#### Scenario: ExpensesNotifier formata a partir de expense.date

- **Given** o `ExpensesNotifier` carregando uma página de despesas
- **When** `_toItem(expense)` é executado
- **Then** o `formattedDate` resultante é igual a `_dateFormatter.formatLongDate(expense.date)`
- **And** nenhuma chamada a `_dateFormatter.formatTime` ou `formatDayMonth(expense.createdAt)` ocorre

#### Scenario: RecentExpensesNotifier formata a partir de expense.date

- **Given** o `RecentExpensesNotifier` carregando o resumo da Home
- **When** `_toItem(expense)` é executado
- **Then** o `formattedDate` resultante é igual a `_dateService.formatLongDate(expense.date)`

#### Scenario: Zero referências a createdAt nos notifiers de display

- **Given** a change concluída
- **When** `grep -n "createdAt" lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart` é executado
- **Then** retorna zero linhas

---

### Requirement: Agrupamento por dia usa a data do evento

The system SHALL calcular o header de grupo (`'Hoje'`, `'Ontem'`, weekday, `'Mês AAAA'`) em `buildExpenseGroups` a partir de `item.expense.date`, nunca de `item.expense.createdAt`.

#### Scenario: builder agrupa pela data da despesa

- **Given** uma lista contendo um `ExpenseItemPresentationData` com `expense.date` em 2026-04-30 e `expense.createdAt` em 2026-05-18
- **When** `buildExpenseGroups(items, dateFormatter: fmt)` é executado
- **Then** o header solicitado a `dateFormatter.relativeGroupHeader` recebe a data 2026-04-30 (não 2026-05-18)

#### Scenario: Zero referências a createdAt no builder

- **Given** a change concluída
- **When** `grep -n "createdAt" lib/src/presentation/ui/expenses/data/expense_groups_builder.dart` é executado
- **Then** retorna zero linhas

---

### Requirement: Item de despesa exibe apenas a data, sem hora

The system SHALL remover o campo `final String formattedTime;` de `ExpenseItemPresentationData` (parâmetro do construtor, atributo e entrada em `props`). O `ExpenseItemWidget` SHALL deixar de receber `formattedTime` no construtor e SHALL renderizar `Text(formattedDate, ...)` no canto trailing do item (sem o caractere `·` nem o sufixo de hora).

#### Scenario: ExpenseItemPresentationData não expõe formattedTime

- **Given** o view-model refatorado
- **When** sua superfície pública é inspecionada
- **Then** não há campo, parâmetro ou entrada em `props` chamada `formattedTime`

#### Scenario: ExpenseItemWidget não recebe formattedTime

- **Given** o widget refatorado
- **When** seu construtor é inspecionado
- **Then** não há parâmetro `formattedTime`
- **And** o `Text` no slot trailing renderiza `formattedDate` direto, sem concatenação com hora

#### Scenario: Zero ocorrências de formattedTime no escopo de expenses

- **Given** a change concluída
- **When** `grep -rn "formattedTime" lib/src/presentation/ui/expenses lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart lib/src/presentation/widgets/expense/ lib/src/presentation/data/expense_item_presentation_data.dart lib/src/presentation/preview/mocks/expense/` é executado
- **Then** retorna zero linhas

---

### Requirement: Formato long date com ano contextual

The system SHALL usar `IDateFormatterService.formatLongDate(int millis)` como única fonte do `formattedDate` em despesas. O formatador SHALL produzir:

- `'DD de Mmm'` quando `DateTime.fromMillisecondsSinceEpoch(millis).year == _now().year`.
- `'DD de Mmm de AAAA'` quando o ano da data diferir do ano corrente injetado (passado ou futuro).

O mês SHALL ser o abreviado em `pt_BR` (`MMM`), capitalizado, sem o ponto final que `intl` adiciona.

#### Scenario: Ano corrente é omitido

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.formatLongDate(DateTime(2026, 5, 17).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'17 de Mai'`

#### Scenario: Ano anterior é exibido

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.formatLongDate(DateTime(2025, 11, 8).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'08 de Nov de 2025'`

#### Scenario: Ano futuro também é exibido

- **Given** `formatter = DateFormatterService(now: () => DateTime(2026, 5, 12))`
- **When** `formatter.formatLongDate(DateTime(2027, 1, 1).millisecondsSinceEpoch)` é chamado
- **Then** retorna `'01 de Jan de 2027'`

#### Scenario: notifier chama formatLongDate

- **Given** `ExpensesNotifier._toItem` e `RecentExpensesNotifier._toItem`
- **When** a implementação é inspecionada
- **Then** a única chamada de formatação de data presente é `formatLongDate(expense.date)`

#### Scenario: mock de preview alinha com o formato

- **Given** `expense_item_mock.dart`
- **When** sua implementação é inspecionada
- **Then** popula `formattedDate` via `_formatter.formatLongDate(millis)` (não `formatDayMonth`)

---

### Requirement: Placeholders dos loading widgets refletem o novo tamanho

The system SHALL atualizar `_placeholderDate` de `expenses_loading_widget.dart` e `recent_expenses_loading_widget.dart` para `'00 de Mmm'` (proporcional ao caso comum — despesa do ano corrente), e SHALL remover o `_placeholderTime` desses arquivos.

#### Scenario: Loading widgets sem placeholder de hora

- **Given** os dois loading widgets refatorados
- **When** seus arquivos são inspecionados
- **Then** não existe declaração `_placeholderTime` nem arg `formattedTime:` na construção do `ExpenseItemWidget`
- **And** `_placeholderDate` vale `'00 de Mmm'`

---

### Requirement: Testes atualizam stubs do date formatter

The system SHALL substituir, em `expenses_notifier_test.dart`, `recent_expenses_notifier_test.dart` e `expense_by_id_notifier_test.dart`, os stubs `when(() => dateFormatter.formatDayMonth(any())).thenReturn(...)` e `when(() => dateFormatter.formatTime(any())).thenReturn(...)` por um único `when(() => dateFormatter.formatLongDate(any())).thenReturn('22 de Abr de 2026')`.

The system SHALL ajustar o helper `_item` em `expense_groups_builder_test.dart` para não exigir `formattedTime` e usar uma string `formattedDate` no formato long date.

#### Scenario: Stubs alinhados com o novo método

- **Given** os testes migrados
- **When** o bloco `setUp` é inspecionado
- **Then** contém `when(() => dateFormatter.formatLongDate(any())).thenReturn(...)`
- **And** não contém stub de `formatDayMonth` nem `formatTime` no escopo do display de despesa

#### Scenario: Suíte verde após a refatoração

- **Given** as edições aplicadas
- **When** `flutter test` é executado
- **Then** todos os 661 testes passam

---

### Requirement: Áreas auditadas e mantidas

The system SHALL preservar o uso atual de `createdAt`/`formattedTime` em áreas onde a semântica está correta:

- `NotificationItemPresentationData` mantém `formattedTime` e o builder de grupos de notificação continua agrupando por `createdAt` — notificações não têm "data do evento" separada.
- `CoupleNotifier._buildMessage` mantém `formatRelativePast(couple.createdAt)` — `createdAt` aqui é a data em que o casal se conectou.
- `BudgetsNotifier`, `ActiveBudgetNotifier`, `BudgetByIdNotifier` continuam usando `model.startDate`/`model.endDate` (que já era o correto antes desta change).
- `ExpenseNotifier` (form) continua usando `expense.date` com `formatLongDate` (já era o correto antes desta change).

#### Scenario: Notifications mantêm formattedTime

- **Given** `lib/src/presentation/data/notification/notification_item_presentation_data.dart`
- **When** o arquivo é inspecionado
- **Then** o campo `formattedTime: String` permanece

#### Scenario: Budgets seguem corretos

- **Given** `active_budget_notifier.dart` e `budgets_notifier.dart`
- **When** os métodos `_toCardData` e `_toItem` são inspecionados
- **Then** formatam datas a partir de `model.endDate`/`model.startDate`, nunca `createdAt`

---

## Verificação

- `flutter analyze` — sem novos issues (warnings pré-existentes em `insights_carousel_loading_widget.dart` continuam).
- `flutter test` — 663/663 verde (inclui 3 cenários novos pra `formatLongDate` cobrindo a regra do ano contextual).
- Greps de verificação dos requirements acima retornam zero linhas.
- Smoke manual: aplicar `Período → Personalizado` em abril/2026 → cabeçalho passa a refletir o dia da despesa, item mostra `30 de Abr de 2026` no lugar de `18/05 · 11:41`.
