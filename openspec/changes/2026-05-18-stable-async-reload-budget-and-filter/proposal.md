# Proposal: stable-async-reload-budget-and-filter

## Intenção

Eliminar o flash de skeleton em dois fluxos que o usuário percebe como "delay":

1. **Home depois de salvar um orçamento** — o `BudgetCardWidget` cai em `AsyncLoading()` e troca o card por skeleton até o `findActive()` retornar, mesmo já tendo um valor anterior cacheado.
2. **Remoção de pílula no filtro de despesas** — `applyFilter` faz `state = const AsyncLoading()` e descarta `items`, `groups` e `activeFilterChips` antes do fetch, então toda a lista somita até a resposta chegar.

A correção é tornar o reload "estável": durante o refresh, a UI continua mostrando o valor anterior; o sinal de "atualizando" vira um indicador leve (overlay/refresh indicator) em vez do skeleton de primeira carga. O dismiss de pílula passa a ser síncrono — a pílula some na hora que o usuário toca o `X`, o fetch acontece em background mantendo a lista anterior visível.

## Motivação

Riverpod já fornece o idioma `AsyncLoading<T>().copyWithPrevious(state)` justamente pra esse caso: o `state` passa a ter `isLoading == true` **e** `hasValue == true` ao mesmo tempo, com `state.value` apontando para o valor anterior. Por convenção, widgets devem renderizar a partir de `state.value` quando ele existe e usar `state.isLoading` apenas para um indicador acessório.

Hoje os dois widgets caem em `switch (state) { AsyncLoading() => skeleton, ... }`, o que casa **primeiro** em `AsyncLoading` independente de ter valor anterior. Por isso o skeleton flasha mesmo quando há um valor perfeitamente válido pra mostrar.

Especificamente:

- `BudgetFormNotifier._submit` ([form/budget_form_notifier.dart:106-107]) chama `ref.invalidate(activeBudgetProvider)` no ramo de sucesso. Riverpod invalida o cache do provider; como `HomeScreen` está viva no stack de navegação (push, não replace), `activeBudgetProvider` rebuilda e — quando `BudgetFormNotifier` foi quem provocou a invalidação — emite `AsyncLoading<T>().copyWithPrevious(prev)` na próxima leitura. Ou seja, o valor anterior já existe no `state`; só o widget é que ignora.

- `ExpensesNotifier.applyFilter` ([expenses_notifier.dart:50-53]) faz `state = const AsyncLoading()` (sem `copyWithPrevious`), o que descarta deliberadamente o valor. Isso é o pior de dois mundos: a chip volta a aparecer só junto da lista nova porque `state.value` vira `null`.

O fix tem três pontas, todas no app Flutter:

1. **`ExpensesNotifier.applyFilter` (e `removeFilter`)** — preservar valor anterior durante reload + atualizar `filter`/`activeFilterChips` de forma síncrona antes do fetch, pra que o dismiss da pílula seja imediato.
2. **`BudgetCardWidget`** — renderizar success a partir de `state.value` quando ele existe, mesmo durante reload.
3. **`ExpensesScreen._contentSlivers` + `ExpensesActiveFiltersWidget`** — mesma ideia: mostrar a lista anterior durante reload em vez de cair em skeleton.

Indicador de "atualizando" durante reload com valor anterior: linha fina de `LinearProgressIndicator` ou pílula sutil. O `RefreshIndicator` do pull-to-refresh já cobre o caso explícito; o que precisamos é um sinal pra o caso programático (`applyFilter`/invalidate).

## Camadas afetadas

### Edit

#### Notifiers

- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`:
  - `applyFilter` — segue com `state = const AsyncLoading()` seguido de `state = await AsyncValue.guard(...)`. O `AsyncNotifier` do Riverpod já chama `copyWithPrevious` internamente no setter de `state`, então o valor anterior é preservado automaticamente (`copyWithPrevious` é `@internal`, não pode ser chamado manualmente).
  - `removeFilter` — atualizar `state` de forma otimista com filtro novo + `_buildChips(next)` **antes** de chamar `applyFilter(next)`. Isso garante o sinal imediato do dismiss, mesmo que o reload demore. A optimistic-value vira a "previous" durante o loading.
  - `searchChanged` — segue chamando `applyFilter`, ganha o mesmo comportamento de "manter lista anterior" naturalmente.

- `lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart`:
  - Adicionar `ref.invalidate(insightsProvider)` no ramo de sucesso de `_submit` — hoje insights ficam stale após mutação de budget. Comportamento de "manter valor anterior visível" fica do lado do widget de consumo via `copyWithPrevious` automático do Riverpod.

- `lib/src/presentation/ui/expense/notifiers/form/expense_notifier.dart`:
  - Adicionar `ref.invalidate(insightsProvider)` no ramo de sucesso de `_submit` (criar/editar despesa) — mesmo motivo.

- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` (`deleteById`):
  - Adicionar `ref.invalidate(insightsProvider)` no ramo de sucesso — deletar despesa também muda os insights.

#### Widgets

- `lib/src/presentation/widgets/budget/card/budget_card_widget.dart` — durante qualquer `state.isLoading`, retornar `BudgetCardLoadingWidget` (skeleton). Decisão refinada na implementação: o card de orçamento usa o mesmo idioma de "skeleton" que o resto do app, em vez de introduzir um `LinearProgressIndicator` que destoa do projeto. O ganho do spec aqui é mais arquitetural (switch refatorado, `state.value` priorizado quando não há reload) do que o overlay sutil. A preservação do valor anterior via `copyWithPrevious` ainda existe no `state`, mas o widget opta por skeleton enquanto recarrega.

- `lib/src/presentation/ui/expenses/screens/expenses_screen.dart` (`_contentSlivers`) — switch reescrito priorizando `AsyncValue(:final value?)` (success / empty) sobre `AsyncError()` e `_` (loading). Durante reload-com-previous, o `state.value` é o estado anterior (ou o otimisticamente atualizado pelo `removeFilter`), então a lista permanece visível sem precisar de indicador adicional. Sem `LinearProgressIndicator`: o feedback de "está atualizando" vem do próprio dismiss instantâneo da pílula + lista estável; adicionar uma barra de progresso poluía a screen sem ganho.

- `lib/src/presentation/ui/expenses/widgets/expenses_active_filters_widget.dart` (revisar) — já lê de `state.value?.activeFilterChips ?? const []` no consumer. Como `state.value` agora persiste durante reload, as pílulas continuam visíveis e refletindo o filter atualizado otimisticamente.

- `lib/src/presentation/ui/home/widgets/insights/insights_carousel_widget.dart` — switch refatorado pro mesmo padrão do `BudgetCardWidget`: durante `state.isLoading` retorna `InsightsCarouselLoadingWidget` (skeleton). Fora do loading, `AsyncValue(:final value?)` matcha primeiro (success/empty), depois `AsyncError()`, e `_` cobre AsyncLoading sem previous.

### Tests

- `test/src/presentation/providers/expenses_notifier_test.dart`:
  - Adicionar teste: `removeFilter(.category)` emite estado intermediário com chip removido sincronamente, depois `AsyncLoading` com `previous != null`, depois `AsyncData` final com a lista nova.
  - Adicionar teste: `applyFilter` preserva `state.value` durante o loading.
- `test/src/presentation/providers/active_budget_notifier_test.dart`:
  - Adicionar teste: após invalidate (simulada via container.refresh), o `state` durante o reload exibe `isLoading && hasValue` com o valor anterior, e não `AsyncLoading()` puro.
- Possíveis testes de widget (opcional, decidir na implementação):
  - `BudgetCardWidget` com `AsyncValue<BudgetCardPresentationData?>` que é `AsyncLoading().copyWithPrevious(data)` deve renderizar `BudgetCardSuccessWidget` + indicador.

## Decisões de design

1. **Preservar previous em vez de bandeira `isRefreshing` custom no state.** Riverpod já tem `AsyncLoading<T>().copyWithPrevious(prev)`. Adicionar um `bool isRefreshing` no `ExpensesState` seria reinventar o que o framework já entrega.

2. **Otimismo no dismiss da pílula.** O `removeFilter` calcula `next` e atualiza `state.value` (filter + chips re-buildados) **antes** do fetch. O usuário vê o feedback instantâneo do toque; se o fetch falhar, o handler já existente (estado `AsyncError`) cobre o caso. Não há rollback do filtro porque o request usa o mesmo filtro otimista — coerência garantida.

3. **Não trocar `ref.invalidate` por `ref.refresh` no `BudgetFormNotifier`.** Os dois funcionam pra esse caso, mas `invalidate` é o idioma canônico em mutações cross-feature (já documentado em CLAUDE.md). O fix está no consumo do estado, não na invalidação.

4. **Indicador visual durante reload — diferente nas duas telas, sem `LinearProgressIndicator`.** No filtro de despesas, a lista anterior permanece visível e o dismiss da pílula é instantâneo via update otimista; o "está atualizando" fica implícito (a pílula sumiu, mas a lista ainda é a antiga até o fetch chegar) — sem barra de progresso, sem skeleton. No card de budget da home, durante `state.isLoading` o widget retorna `BudgetCardLoadingWidget` (skeleton), porque o card é o elemento principal da tela e o skeleton é o idioma estabelecido — não vale inventar overlay novo. A preservação do valor anterior via `copyWithPrevious` ainda fica registrada no state pra eventual uso, mas o widget opta pelo skeleton durante o load.

5. **`Cleared()` continua usando `applyFilter(const .empty())`.** Como o filtro novo é vazio e os chips ficam `[]`, o feedback otimista ainda é instantâneo — a barra de chips some na hora e a lista permanece (anterior) até a nova chegar.

6. **`pull-to-refresh` (`RefreshIndicator`) continua intocado.** Ele já tem indicador próprio + não recria o estado pra `AsyncLoading()` (faz reload via `applyFilter`, que agora preserva previous). O comportamento melhora "de graça".

7. **Não tocar em outros fluxos que mostram skeleton de primeira carga.** Splash → home, abrir tela de despesas pela primeira vez, etc. — esses **devem** mostrar skeleton porque não há valor anterior. A spec só muda o caso onde já existe valor anterior.

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde, incluindo os testes novos.
- Smoke manual:
  - Salvar um orçamento (criar ou editar) → ao voltar pra home, o card mostra o `BudgetCardLoadingWidget` (skeleton) por instantes e atualiza com o novo valor. **Os insights também atualizam** — `InsightsCarouselLoadingWidget` aparece durante o reload e dá lugar aos insights recalculados.
  - Salvar uma despesa (criar ou editar) → mesma coisa: home recarrega budget card, recent expenses, lista de despesas **e insights**.
  - Deletar uma despesa pela lista → home recarrega budget card, recent expenses **e insights**.
  - Aplicar filtro de categoria, depois clicar `X` na pílula → pílula desaparece **instantaneamente**, lista mantém os itens anteriores até a nova lista chegar (sem flash de skeleton, sem indicador adicional).
  - Idem para pílula de período.
  - Aplicar filtro novo via `ExpensesFilterScreen` → ao voltar, a lista anterior fica visível até a nova chegar.
  - `Cleared()` (Limpar tudo) — pílulas somem na hora, lista persiste durante reload.
  - Pull-to-refresh continua funcionando normalmente.
  - Primeiro acesso a `/expenses` (sem cache prévio) **continua** mostrando o `ExpensesLoadingWidget` skeleton — isso é correto.
  - Primeiro acesso à home antes de qualquer budget existir continua mostrando `BudgetCardLoadingWidget` durante o `findActive()` inicial.

## Fora de escopo

- Skeleton de primeira carga em qualquer tela — não muda, é o comportamento correto pra caso "sem valor anterior".
- Outras telas (couple, settings, notifications) — replicar o padrão pode virar follow-up se aparecer queixa equivalente.
- Animação custom de transição entre estados — usar `LinearProgressIndicator` padrão; refino visual fica como tarefa futura.
- Spec do backend — tudo aqui é cliente.
- Refactor de `ExpensesState` para incluir um campo `isRefreshing` — explicitamente descartado pela decisão #1.

## Sequência de implementação

1. Spec aprovada (esta proposal).
2. Implementação:
   - Notifier (`ExpensesNotifier.applyFilter` + `removeFilter`) com `copyWithPrevious`.
   - Widgets (`BudgetCardWidget`, `ExpensesScreen._contentSlivers`) reordenando o switch e adicionando indicador sutil.
   - Testes novos cobrindo os cenários de reload-com-previous.
3. `flutter analyze` + `flutter test` full.
4. Smoke manual cobrindo o checklist.
5. Arquivar em `openspec/changes/archive/`.
