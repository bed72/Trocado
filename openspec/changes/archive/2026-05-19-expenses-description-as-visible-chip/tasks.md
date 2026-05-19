# Tasks: expenses-description-as-visible-chip

## Domain (presentation/data)

- [x] `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — `enum ExpenseFilterChipKind { description, category, period }` (descrição como primeiro valor, refletindo ordem de exibição).

## Notifier

- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `_buildChips`: se `filter.description.isNotEmpty`, prepend `ExpenseActiveFilterChipPresentationData(kind: .description, icon: Icons.search, label: 'Busca: ${filter.description}')` antes dos chips de category/period.
- [x] `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart` — `removeFilter`: estender `switch (kind)` com `.description => current.copyWith(description: '')`.

## Screen

- [x] `lib/src/presentation/ui/expenses/screens/expenses_screen.dart` — sincronização do `_searchController` em duas frentes:
  - `_syncInitialDescription(ref)` chamado no `Consumer.builder` na primeira leitura (flag `_initialDescriptionSynced`), aplicando via `WidgetsBinding.instance.addPostFrameCallback` pra não mutar controller durante build. Cobre o caso "voltar pra tela com notifier keepAlive cacheando descrição".
  - `ref.listen(expensesProvider, ...)` estendido: quando `previousDescription.isNotEmpty && nextDescription.isEmpty && controller.text.isNotEmpty`, limpa o controller. Cobre chip removido + "Limpar tudo" da tela de filtros. Guarda contra interferir com digitação ao vivo.

## Tests

- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — teste `prepends a search chip with Icons.search when description is not empty` cobrindo `chips.first.kind == .description`, `label == 'Busca: Alugel'`, `icon == Icons.search`.
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — teste `orders chips as description, category, period when all three filters are active`.
- [x] `test/src/presentation/providers/expenses_notifier_test.dart` — teste `clears description and rebuilds chips without the search chip` cobrindo update otimista (intermediate `state.value.filter.description == ''` + chip de busca ausente) e reload final.

## Verificação

- [x] `flutter analyze` limpo.
- [x] `flutter test` full verde (704/704).
- [x] Smoke manual:
  - Buscar "Alugel" → chip "Busca: Alugel" aparece junto da lista filtrada.
  - Adicionar categoria + período via tela de filtros → 3 chips visíveis (Busca, Categoria, Período); lista vazia é justificada pelos 3 chips.
  - Tocar `X` no chip de busca → chip somita instantaneamente, search bar limpa o texto, lista re-fetcha sem `description`.
  - Tocar `X` em categoria/período com busca ainda ativa → outros chips somem, chip de busca permanece, lista filtra só pela busca.
  - "Limpar tudo" na tela de filtros → todos os chips somem incluindo o de busca; controller da search bar volta a vazio.
