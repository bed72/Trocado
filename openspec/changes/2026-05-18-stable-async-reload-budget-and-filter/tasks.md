# Tasks: stable-async-reload-budget-and-filter

## Notifier

- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `removeFilter` aplica update otimista (`state = AsyncData(currentValue.copyWith(filter: next, activeFilterChips: _buildChips(next)))`) antes do `await applyFilter(next)`.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `applyFilter` permanece com `state = const AsyncLoading()`; confirmado em teste que o `AsyncNotifier` do Riverpod auto-preserva o valor anterior via `copyWithPrevious` interno do setter.
- [x] `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart` — `_submit` invalida `insightsProvider` no ramo de sucesso (junto de `budgetsProvider` e `activeBudgetProvider`).
- [x] `lib/src/presentation/ui/expense/notifiers/form/expense_notifier.dart` — `_submit` invalida `insightsProvider` no ramo de sucesso (junto de `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider`).
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` (`deleteById`) — ramo de sucesso invalida `insightsProvider` (junto de `activeBudgetProvider`, `recentExpensesProvider`).

## Widgets

- [x] `lib/src/presentation/widgets/budget/card/budget_card_widget.dart` — switch refatorado (pattern matching), guard contra `value` nullable do `BudgetCardPresentationData?`. Durante `state.isLoading` o widget retorna `BudgetCardLoadingWidget` (skeleton) — decisão de UX consciente: card central usa o idioma do projeto, sem `LinearProgressIndicator` no topo. Preservação de valor anterior via `copyWithPrevious` continua no state pra eventual uso futuro.
- [x] `lib/src/presentation/ui/expenses/screens/expenses_screen.dart` — `_contentSlivers` reescrito como switch expression priorizando `AsyncValue(:final value?)`. Sem `LinearProgressIndicator`: dismiss otimista da pílula + lista anterior estável já dão o feedback necessário.
- [x] `lib/src/presentation/ui/home/widgets/insights/insights_carousel_widget.dart` — switch refatorado pro mesmo padrão do `BudgetCardWidget`: skeleton (`InsightsCarouselLoadingWidget`) durante qualquer `state.isLoading`, switch expression cobrindo success/empty/error fora do loading.

## Tests

- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — novo teste `applyFilter preserves previous value during reload so the list stays visible` cobrindo `loadingSnapshot.isLoading && hasValue && value?.items.isNotEmpty` durante o await do reload (usa `Completer` pra segurar a resposta).
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — novo teste `removeFilter dismisses chip synchronously before the reload completes` cobrindo o update otimista (intermediate `state.value.filter.category == null` e `activeFilterChips.isEmpty` antes do reload completar).

## Verificação

- [x] `flutter analyze` limpo.
- [x] `flutter test` full verde (656/656).
- [ ] Smoke manual:
  - Salvar/editar orçamento → ao voltar pra home, card antigo permanece com indicador sutil até o novo dado chegar (sem flash de skeleton).
  - Aplicar filtro de categoria → lista anterior persiste até o novo fetch, sem flash de skeleton.
  - Clicar `X` numa pílula → pílula somita instantaneamente, lista permanece visível até o novo fetch chegar.
  - Limpar tudo → todas as pílulas somem na hora, lista persiste durante reload.
  - Pull-to-refresh continua funcionando normalmente.
  - Primeiro acesso a `/expenses` (sem cache) continua mostrando skeleton — comportamento correto.
  - Home sem nenhum budget continua mostrando skeleton durante o `findActive()` inicial.
