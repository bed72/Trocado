# Proposal: expenses-description-as-visible-chip

## Intenção

Tornar o filtro de **descrição** (busca textual) tão visível quanto os filtros de categoria e período na tela de listagem de despesas, e mantê-los **composicionais por AND** sem efeitos colaterais escondidos.

Hoje, quando o usuário busca por "Alugel" e depois abre a tela de filtros e marca categoria + período, o filtro de descrição permanece silenciosamente ativo:

- `ExpensesFiltersNotifier.dispatch` ([expenses_filters_notifier.dart:30-43]) só altera `category`, `startDate` e `endDate` do `draft`. O `description` herdado do `seed` (vindo de `state.value?.filter` na `ExpensesScreen`) nunca é tocado.
- `ExpensesNotifier._buildChips` ([expenses_notifier.dart:186-211]) só gera chips para `category` e `period`. O `description` ativo não aparece na barra de chips.
- O `TextEditingController` da busca vive na `_ExpensesScreenState` e a barra de busca é colapsável (estado `_expanded` interno em `ExpensesSearchFieldWidget`), então o usuário pode nem ver o texto da busca depois que rolou pela tela.

Resultado: a query final é `description AND category AND startDate AND endDate`. Se nada cruza os três, a lista vem vazia — e o usuário não tem como entender por quê, porque só vê dois chips ativos.

## Motivação

Os três filtros (busca, categoria, período) são **filtros de igual peso** — todos restringem a listagem. Dar a um deles status diferente (escondido) é o que causa o bug. A solução natural é tratá-los uniformemente:

1. Quando `filter.description` não está vazio, gerar um chip "Busca: \<texto\>" junto dos outros.
2. Quando o usuário remove o chip de busca via `X`, o filtro **e** o `TextEditingController` da search bar são sincronizados pra vazio.
3. A composição por AND entre busca + categoria + período continua valendo — agora com feedback visual completo. O usuário pode legitimamente buscar "Alugel" dentro de "Alimentação no mês passado" se quiser, e — se nada vier — remover qualquer um dos três chips.

Não há mudança de comportamento de query. Só de **visibilidade** do que já está ativo.

## Camadas afetadas

### Edit

#### Domain (presentation/data)

- `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — adicionar valor `description` ao enum: `enum ExpenseFilterChipKind { description, category, period }`. Ordem do enum reflete a ordem natural de leitura/exibição (busca primeiro como filtro mais "direto" do usuário, depois categoria, depois período).

#### Notifier

- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`:
  - `_buildChips(ExpenseFilterModel filter)` — se `filter.description.isNotEmpty`, adicionar como primeiro chip `ExpenseActiveFilterChipPresentationData(kind: .description, icon: Icons.search, label: 'Busca: ${filter.description}')`. Chips de category/period continuam idênticos, depois do de busca.
  - `removeFilter(ExpenseFilterChipKind kind)` — estender o `switch` com o caso `.description => current.copyWith(description: '')`. Lógica de update otimista (`AsyncData` com chips re-buildados) + `applyFilter(next)` permanece igual.

#### Screen (sincronização do search controller)

- `lib/src/presentation/ui/expenses/screens/expenses_screen.dart`:
  - Adicionar `ref.listen(expensesProvider, ...)` que reage a mudanças em `filter.description` e sincroniza `_searchController.text` quando ele divergir do valor do filtro. Detalhes:
    - Só atualiza o controller se `_searchController.text != next.value?.filter.description` — evita loop com o `onChanged → searchChanged → applyFilter → state.filter.description` quando o usuário está digitando.
    - Reusa o `ref.listen` já existente da `expensesProvider` (que hoje trata `deleteFailure`) — adiciona o ramo de sincronização junto.

#### Widget

- `lib/src/presentation/ui/expenses/widgets/expenses_active_filters_widget.dart` — nenhuma mudança de lógica; o widget já renderiza o `label` + `icon` de qualquer `ExpenseActiveFilterChipPresentationData`. Beneficia automaticamente do novo kind.

### Tests

- `test/src/presentation/providers/expenses_notifier_test.dart`:
  - Novo teste em `group('_buildChips' / 'activeFilterChips')`: aplicar filtro com `description: 'Alugel'` → primeiro chip é `kind: .description, label: 'Busca: Alugel'`, com `Icons.search` no `icon`.
  - Novo teste em `group('_buildChips')`: filtro com `description: 'X' + category + período` → 3 chips, ordem: description, category, period.
  - Novo teste em `group('removeFilter')`: `removeFilter(.description)` produz update otimista com `filter.description == ''` e o chip de busca some, depois reload retorna sem o filtro de descrição.
- `test/src/presentation/ui/expenses/expenses_screen_test.dart` (criar se não existir, senão estender):
  - Widget test: dado filtro com `description: 'Alugel'` no state inicial, `_searchController.text` é "Alugel" depois do primeiro frame.
  - Widget test: invocar `removeFilter(.description)` no notifier → após pump, `_searchController.text` é "".
  - Pular se não houver harness de widget test pra essa screen; cobertura via teste do notifier já garante o comportamento canônico.

## Decisões de design

1. **Sincronização do controller fica na screen (não no notifier).** O `TextEditingController` é estado de UI puro (`Flutter` é dependência), e o notifier é Dart puro. Mover o controller pra dentro do notifier quebraria a regra de camada. A screen escuta o provider via `ref.listen` e sincroniza o controller quando o filtro muda — idioma canônico do Riverpod.

2. **Listener guarda contra loop.** O `onChanged` do TextField já dispara `searchChanged` → `applyFilter` → `state.filter.description` muda. Se o listener atualizasse o controller a cada mudança, o cursor saltaria pro fim a cada tecla. Por isso a guarda `if (_searchController.text != next.value?.filter.description)`: só sincroniza quando há divergência real (ex: chip removido programaticamente).

3. **Chip mostra valor da busca, não label genérico.** "Busca: Alugel" é mais útil que só "Busca" — o usuário enxerga o quê está filtrando sem precisar abrir a barra. Truncamento natural do `InputChip` cobre strings longas.

4. **`Icons.search` como icon do chip.** Reusa o vocabulário visual da barra de busca; chips de categoria já têm icon (icone da categoria); chips de período não têm icon — mantemos essa heterogeneidade existente.

5. **Ordem dos chips: description → category → period.** Refletida no `_buildChips` (insert order) e no enum (mais semântico que funcional). Não é critico, mas é a ordem em que o usuário tipicamente compõe filtros.

6. **Não muda a tela de filtros.** A `ExpensesFilterScreen` não ganha um campo de descrição — busca continua entrando exclusivamente pela barra na AppBar. A spec só conserta o "fantasma" do que já existe; expor descrição também na tela de filtros é UX separada e pode virar follow-up.

7. **Compor por AND sem mudar a query.** Não há mudança no datasource nem no `ExpenseFilterModel.copyWith`. A query AND já existe — só estamos tornando o estado visível.

8. **Sem flag de "tinha description antes" no state.** O `filter.description.isNotEmpty` já é a fonte da verdade — `_buildChips` consulta diretamente.

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde, incluindo os novos casos.
- Smoke manual:
  - Buscar "Alugel" → vê um chip "Busca: Alugel" na barra de chips ativos junto da lista filtrada.
  - Com a busca ativa, abrir filtros e marcar Alimentação + Mês passado → ao aplicar, vê 3 chips (Busca: Alugel, Alimentação, Mês passado). Se a lista for vazia, fica óbvio o porquê.
  - Tocar `X` no chip "Busca: Alugel" → o chip somita instantaneamente, a barra de busca limpa o texto (controller volta a "") e a lista re-fetcha sem o filtro de descrição.
  - Tocar `X` no chip de categoria/período → comportamento atual permanece, busca continua ativa se ainda houver texto.
  - Limpar tudo via tela de filtros → busca também é limpa (controller zera, chip de busca some).
  - Buscar, abrir tela de filtros, tocar "Limpar tudo" e Aplicar → todos os 3 filtros desaparecem (chip de busca some + controller limpa via listener da screen).

## Fora de escopo

- Adicionar campo de busca dentro da `ExpensesFilterScreen` — fica como UX follow-up.
- Mudanças no `ExpenseFilterModel` (struct, copyWith) — não é necessário; `description` já é parte do modelo.
- Mudanças no backend ou no datasource — não há mudança de query.
- Outras telas com busca + filtros (couple, notifications) — replicar o padrão pode virar follow-up se aparecer queixa equivalente.
- Refactor do `ExpensesSearchFieldWidget` pra não usar `TextEditingController` próprio — fora de escopo; manter contrato atual.

## Sequência de implementação

1. Spec aprovada (esta proposal).
2. Implementação:
   - Enum `ExpenseFilterChipKind` — adicionar `description`.
   - `ExpensesNotifier._buildChips` — chip de busca.
   - `ExpensesNotifier.removeFilter` — caso `.description`.
   - `ExpensesScreen` — `ref.listen` sincroniza `_searchController` com `filter.description` (com guarda).
   - Testes novos cobrindo geração de chip de busca + remoção via `.description`.
3. `flutter analyze` + `flutter test` full.
4. Smoke manual cobrindo o checklist de aceitação.
5. Arquivar em `openspec/changes/archive/` com prefixo de data.
