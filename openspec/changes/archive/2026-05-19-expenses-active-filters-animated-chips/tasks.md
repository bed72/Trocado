# Tasks: expenses-active-filters-animated-chips

## Widgets

- [x] `lib/src/presentation/ui/expenses/widgets/expenses_active_filters_widget.dart` — convertido pra `StatefulWidget` com:
  - `late GlobalKey<AnimatedListState> _listKey`
  - `late List<ExpenseActiveFilterChipPresentationData> _items` (espelho local)
  - `initState`: inicializa key + clone de `widget.chips`
  - `didUpdateWidget`: diff por `chip.kind` → removeAt + `removeItem(i, builder, duration: 200ms)` pra cada removido; insert + `insertItem(i, duration: 200ms)` pra cada novo; substituição in-place via `setState` quando label/icon mudam mas kind continua.
  - `build`: `AnimatedSize(duration: 200ms, alignment: .topCenter)` envolvendo `SizedBox(height: 40.0, child: AnimatedList(...))`. `SizedBox.shrink()` quando `_items` está vazio.
  - `itemBuilder(context, index, animation)`: `SizeTransition(axis: .horizontal, sizeFactor: animation, child: FadeTransition(opacity: animation, child: Padding + _chip))`.
  - `_animatedChip` reusado tanto pelo `itemBuilder` quanto pelo builder passado ao `removeItem`.
  - Padding entre chips via `EdgeInsets.only(right: isLast ? 0 : 8.0)` no próprio item; último não tem padding direito.
  - Padding horizontal externo de 16.0 via `padding` do `AnimatedList`.

- [x] `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_period_section_widget.dart` — `Text('De: ...')` envolvido em `AnimatedSize(duration: 200ms, alignment: .topLeft)` + `AnimatedSwitcher(duration: 200ms, transitionBuilder: fade-only)`. Estado vazio: `SizedBox.shrink(key: ValueKey('empty'))`. Estado preenchido: `Text(..., key: ValueKey(formattedSummary))` — key derivada do valor faz a troca de range disparar cross-fade.

## Verificação

- [x] `flutter analyze` limpo.
- [x] `flutter test` full verde (716/716).
- [x] Smoke manual:
  - Aplicar categoria → chip aparece animado (fade + slide horizontal).
  - Tocar `X` em qualquer chip → chip sai animado, vizinhos se reposicionam.
  - "Limpar tudo" → todos os chips saem em paralelo; faixa colapsa via `AnimatedSize`.
  - Digitar na busca rapidamente → label do chip de busca atualiza sem flicker.
  - Aplicar 4 filtros (busca + categoria + valor + período) → cada chip entra individualmente.
  - Na tela de filtros, escolher preset de período → texto "De: ..." aparece com fade + coluna cresce.
  - Trocar pra outro preset → cross-fade entre os dois ranges.
  - "Limpar tudo" → texto some com fade + coluna encolhe.
