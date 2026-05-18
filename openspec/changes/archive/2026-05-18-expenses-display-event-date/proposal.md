# Proposal: expenses-display-event-date

## Intenção

Corrigir o bug em que a lista de despesas (`ExpensesScreen` + `RecentExpensesSection` no Home) renderizava a data de **inserção no banco** (`expense.createdAt`) no lugar da **data do evento da despesa** (`expense.date`). Trocar o formato apresentado de `dd/MM · HH:mm` para `28 de Abr` (long date com regra: o ano é omitido quando bate com o ano corrente; exibido quando difere — ex.: `28 de Abr de 2025` em despesas do ano passado). Também elimina o campo `formattedTime` do view-model do item de despesa.

## Motivação

Reportado em 2026-05-18: tentar filtrar por `Período → Personalizado` selecionando um mês anterior parecia não funcionar — a tela continuava mostrando "Hoje" e "18/05 · 11:41" pra todas as despesas. Idem pra `Ordenação`. Investigação descartou problema de URL/RQL no client, transmissão Dio e backend (curl bate confirmando que `ge(date,...)`/`le(date,...)`/`ordering=` funcionam). A causa real:

- `ExpensesNotifier._toItem` formatava `formattedDate`/`formattedTime` a partir de `expense.createdAt`.
- `RecentExpensesNotifier._toItem` idem.
- `buildExpenseGroups` agrupava por `item.expense.createdAt` (cabeçalho "Hoje/Ontem/...").

Como os seeds do ambiente foram inseridos todos hoje 11:41, todas as despesas (incluindo as de abril) renderizavam "Hoje · 18/05 · 11:41". Os dados estavam corretamente filtrados e ordenados — só a UI mostrava o campo errado. A hora não agrega valor numa lista de despesas (o expense só tem `date` como `date` puro, sem hora intrínseca); única hora disponível seria a do `createdAt`, que é justamente o que estava enganando o usuário. Por isso o item passa a mostrar **só** a data do evento.

`formatLongDate` (`'$day de $monthAbbrev de $year'`) já existe no `IDateFormatterService` e produz exatamente o formato pedido (`28 de Abr de 2026`).

## Camadas afetadas

- `presentation/data/expense_item_presentation_data.dart` — remove `formattedTime`; mantém `formattedDate` (agora populado com long date a partir de `expense.date`).
- `presentation/widgets/expense/expense_item_widget.dart` — remove parâmetro `formattedTime`; trailing Text passa de `'$formattedDate · $formattedTime'` para `formattedDate` direto.
- `presentation/ui/expenses/notifiers/expenses_notifier.dart` — `_toItem` usa `_dateFormatter.formatLongDate(expense.date)`; remove a chamada a `formatTime(expense.createdAt)`.
- `presentation/ui/home/notifiers/recent_expenses_notifier.dart` — idem.
- `presentation/ui/expenses/data/expense_groups_builder.dart` — `relativeGroupHeader(item.expense.date)` no lugar de `item.expense.createdAt`.
- `presentation/ui/expenses/widgets/expenses_loading_widget.dart` — remove `_placeholderTime`; ajusta `_placeholderDate` pra `'00 de Mmm de 0000'`.
- `presentation/ui/home/widgets/recent_expenses/recent_expenses_loading_widget.dart` — idem.
- `presentation/ui/expenses/widgets/expenses_list_widget.dart` — drop do arg `formattedTime` na construção do `ExpenseItemWidget`.
- `presentation/ui/home/widgets/recent_expenses/recent_expenses_section_widget.dart` — idem.
- `presentation/preview/mocks/expense/expense_item_mock.dart` — mock passa a usar `formatLongDate(millis)` e remove `formattedTime`.
- Testes: `expenses_notifier_test.dart`, `recent_expenses_notifier_test.dart`, `expense_by_id_notifier_test.dart`, `expense_groups_builder_test.dart` — substituem stubs de `formatDayMonth`/`formatTime` por stub de `formatLongDate`; helpers de mock dropam `formattedTime`.

## Itens explicitamente fora de escopo

- **Notifications** (`notifications_notifier.dart`, `notification_groups_builder.dart`, `notification_card_widget.dart`): notificações usam `createdAt` semanticamente correto — não têm uma "data do evento" separada. `NotificationItemPresentationData.formattedTime` permanece.
- **Budgets** (active, list, form): auditado nesta change e está correto. Já usa `model.endDate`/`startDate` em todos os call sites de display. Nenhuma alteração necessária.
- **Couple** (`couple_notifier.dart` "Conectados há X"): usa `couple.createdAt` semanticamente — é a data em que viraram um casal. Mantido.
- **Expense form** (`expense_screen.dart` field do `date`): já formata via `formatLongDate(state.date)` corretamente — só lista estava errada.
- **Renomear `formattedDate` → `formattedEventDate`** ou similar: nome `formattedDate` ainda descreve corretamente o conteúdo. Sem mudança.

## Decisões de design

1. **`expense.date` é a fonte canônica para display.** `createdAt` é detalhe de auditoria/persistência, não pertence à camada de apresentação do item. Esse princípio se estende ao agrupamento: "Hoje/Ontem/..." reflete quando a despesa **aconteceu**, não quando foi digitada.

2. **Dropar `formattedTime` em vez de manter uma string vazia.** Como `expense.date` no domínio carrega o dia ao início (00:00 local), `formatTime` retornaria sempre `00:00` — irrelevante. Em vez de manter campo redundante no view-model, o campo é removido.

3. **Formato `28 de Abr` (com ano contextual) via `formatLongDate` ajustado.** Reutiliza o formatador já testado pelo `date-formatter-service` (`MMM` abreviado capitalizado), com a regra adicionada nesta change: o ano é omitido quando `date.year == _now().year` e mantido caso contrário. Aplica-se globalmente (lista de despesas, mock de preview, campo de data do form de expense), pois é a regra UX coerente em todo lugar — ano corrente é redundante.

4. **Loading widgets ajustam o placeholder pro novo tamanho.** `_placeholderDate` vira `'00 de Mmm'` (caso mais comum — ano corrente). `_placeholderTime` desaparece. Despesas de outro ano renderizam alguns chars a mais que o skeleton, mas o caso é minoria visual.

5. **Spec retroativa.** A change foi implementada antes da spec ser escrita — violação do fluxo SDD. Esta spec documenta o que foi feito pra deixar a trilha consistente. Não é template pra futuras: implementação retroativa não vira norma.

## Critério de aceitação

- `flutter analyze` limpo (warnings pré-existentes em `insights_carousel_loading_widget.dart` continuam — não relacionados).
- `flutter test` verde (661 testes).
- `grep -rn "formattedTime" lib/src/presentation/ui/expenses lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart lib/src/presentation/widgets/expense/ lib/src/presentation/data/expense_item_presentation_data.dart lib/src/presentation/preview/mocks/expense/` retorna zero linhas.
- `grep -n "createdAt" lib/src/presentation/ui/expenses/data/expense_groups_builder.dart lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart lib/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart` retorna zero linhas (não-placeholder).
- Smoke manual: aplicar `Período → Personalizado` em abril/2026 → cabeçalho passa a ser o dia da despesa (`30 de Abr` etc.), item mostra `30 de Abr de 2026` no lugar de `18/05 · 11:41`.
