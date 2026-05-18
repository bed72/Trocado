# Design: expenses-display-event-date

## Estado anterior

A camada de apresentação da lista de despesas formatava o display e calculava o agrupamento "Hoje/Ontem/..." a partir de `expense.createdAt` (data de inserção no banco), não de `expense.date` (data do evento):

`lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` em `_toItem`:

```dart
ExpenseItemPresentationData _toItem(ExpenseModel expense) =>
    ExpenseItemPresentationData(
      expense: expense,
      formattedValue: _moneyService.format(expense.value / 100),
      formattedTime: _dateFormatter.formatTime(expense.createdAt),     // ❌
      formattedDate: _dateFormatter.formatDayMonth(expense.createdAt), // ❌
    );
```

Mesmo padrão em `RecentExpensesNotifier._toItem` e em `expense_groups_builder.dart` (`relativeGroupHeader(item.expense.createdAt)`).

O bug ficou invisível em produção até o ambiente de teste ter todos os seeds inseridos no mesmo dia (2026-05-18). Aplicar `Período → Mês passado` retornava as despesas certas (filtro funcionando), mas a tela mostrava "Hoje · 18/05 · 11:41" pra tudo — passando a impressão de que filtro/ordenação não funcionam. Diagnóstico confirmou via curl no backend que `ge(date,...)`/`le(date,...)`/`ordering=` operam corretamente; o problema era puramente de display.

## Decisão

### 1. `expense.date` é a fonte canônica para display da lista de despesas

`createdAt` é detalhe de persistência. A camada de apresentação SHALL usar `expense.date` no agrupamento (`relativeGroupHeader`) e no `formattedDate` do item. Aplica-se a `ExpensesNotifier`, `RecentExpensesNotifier` e `buildExpenseGroups`.

### 2. Dropar `formattedTime` em vez de mostrar `00:00`

O `expense.date` no domínio carrega o dia ao início (00:00 local) — `formatTime(expense.date)` retornaria sempre `00:00`, irrelevante. Em vez de manter o campo no view-model com valor inútil, removemos `formattedTime` de `ExpenseItemPresentationData` e do `ExpenseItemWidget`. Hora não agrega valor numa lista de despesas (confirmado pelo usuário). Notifications mantêm `formattedTime` porque ali o `createdAt` é a única data disponível e semanticamente correta.

### 3. `formatLongDate` ganha regra de ano contextual

A primeira iteração rendeu `'17 de Mai de 2026'` no item. UX feedback: ano corrente é redundante. Solução: `formatLongDate` compara `date.year` com `_now().year`:

```dart
if (date.year == _now().year) return '$day de $month';
return '$day de $month de ${date.year}';
```

Aplicado no service (não na chamada do notifier) porque é regra UX consistente em todo lugar que mostra long date — lista de despesas, mock de preview, campo de data do form de expense. Centralizar evita repetir a checagem em cada call site.

## Alternativas consideradas

### Manter `formattedTime` exibindo `00:00`

Rejeitado. String inútil consumindo espaço no widget. Quem precisa de "quando foi inserido" já tem `createdAt` no model — mas isso é dado de auditoria, não UI.

### Criar `formatLongDateAdaptive` separado

Manter `formatLongDate` retornando sempre `'DD de Mmm de AAAA'` e adicionar um segundo método com a regra contextual. Rejeitado porque os 4 call sites de `formatLongDate` no app querem o mesmo comportamento — não há call site que precise do ano corrente forçado. Adicionar método novo só pra acomodar uma teórica diferença futura é YAGNI.

### Inline da regra do ano no notifier

`expenses_notifier.dart` faria a checagem `if (date.year == now.year)` antes de chamar o formatter. Rejeitado porque (a) repete a regra em cada notifier que usa long date, (b) força o notifier a injetar `nowProvider` separadamente, (c) viola o princípio da spec do date-formatter-service que centraliza formatação no service.

### Renomear `formattedDate` para `formattedEventDate`

Considerado por clareza. Rejeitado por escopo — todo o codebase já trata `formattedDate` como "a data que o item exibe", e a mudança seria cosmética com churn em ~10 arquivos.

## Itens fora do escopo (auditados como corretos)

- **Budgets** (`BudgetsNotifier`, `ActiveBudgetNotifier`, `BudgetByIdNotifier`): já formatam `model.endDate`/`startDate`, nunca `createdAt`. Sem mudança.
- **Notifications** (`NotificationsNotifier`, `notification_groups_builder.dart`, `notification_card_widget.dart`): `createdAt` é a única data disponível e é semanticamente "quando o evento aconteceu" (notificação não tem outra). Mantém `formattedTime`.
- **Couple** (`CoupleNotifier`): "Conectados há X" usa `formatRelativePast(couple.createdAt)` — `createdAt` aqui é a data do casamento, correto.
- **Expense form** (`ExpenseScreen`, `ExpenseNotifier`): já usa `expense.date` com `formatLongDate`. Indiretamente herda a regra do ano contextual.

## Violação do fluxo SDD

Esta change foi implementada antes da spec ser escrita. Identificado e questionado pelo usuário; spec criada retroativamente para preservar a trilha de decisão. **Não é template** — implementação retroativa não vira norma. CLAUDE.md continua valendo: spec antes de código, sem exceção pra "é só bug fix".
