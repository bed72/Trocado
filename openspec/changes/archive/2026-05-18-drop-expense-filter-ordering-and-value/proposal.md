# Proposal: drop-expense-filter-ordering-and-value

## Intenção

Remover do filtro de despesas duas seções inteiras: **Ordenação** (chips "Mais antigos / Mais recentes / Maior valor / Menor valor") e **Valor** (inputs `Mínimo` / `Máximo`), junto com pílulas de filtro ativo, intents, fragmentos de request, campos de model, validações e testes correspondentes. O filtro fica reduzido a **Categoria** + **Período**, refletindo as duas dimensões que efetivamente importam na UX atual.

Lista de despesas continua exibindo a ordem default do backend (`-date`, mais recentes primeiro) — sem opção do usuário trocar.

## Motivação

Duas decisões tomadas em conversa hoje, com gatilhos distintos mas o mesmo remédio (remover):

**Ordenação.** A seção nunca funcionou de verdade. O cliente manda `?ordering=-value` / `?ordering=value` / `?ordering=date` / `?ordering=-date` corretamente, mas o backend ignora silenciosamente: a `CursorPagination` da rota fixa o campo de ordenação na própria classe (`SharedExpensesCursorPagination.ordering = "-date"`, conforme [[Trocado/BackEnd/09 - Complementos.md]] §3) e o cursor precisa de campo determinístico para encodar/decodar, então o `?ordering=` da `RQLFilterBackend` é descartado. Mudar o backend para suportar ordering dinâmico exige trocar paginação cursor por page-number (degrada performance) ou implementar cursor multi-campo — fora do roadmap. Em vez de manter chips inertes ou aguardar fix server-side indefinidamente, removemos a feature.

**Valor.** A seção funciona tecnicamente (o backend honra `ge(value,...)` / `le(value,...)` via `RQLFilterBackend`), mas o usuário decidiu que não agrega o suficiente: a UX exige digitar dois valores em `R$` para filtrar uma faixa que raramente é o critério natural quando se procura uma despesa específica. Os filtros realmente úteis na lista são **categoria** (o que foi gasto) e **período** (quando foi gasto). Manter "Valor" inflaciona a screen de filtro e adiciona código (formatter custom, controllers, parseCentavos/formatCentavos, normalize de min/max) sem payoff observável. Decisão é de produto, não técnica.

Resultado: a tela de filtros fica mais curta e direta, o request fica mais simples (sem fragmentos `ge(value,...)`/`le(value,...)`/`ordering=...`), o domain model perde 3 campos (`ordering`, `minValue`, `maxValue`) e quatro flags de `copyWith` (`clearMinValue`, `clearMaxValue`, ... — `clearMinValue`/`clearMaxValue` saem com o campo, `ordering` perde o default mais o parâmetro).

## Camadas afetadas

### Delete

- `lib/src/domain/enums/expense/expense_ordering_enum.dart` — enum.
- `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_ordering_section_widget.dart` — widget.
- `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_value_section_widget.dart` — widget (StatefulWidget com controllers de currency).
- `lib/src/presentation/widgets/formatters/currency_field_formatter.dart` — `CurrencyFieldFormatter` fica sem consumidor após a remoção do widget de valor (verificado por `grep -rn CurrencyFieldFormatter lib/`). Sai junto.
- `test/src/domain/enums/expense/expense_ordering_enum_test.dart` — teste do enum.

### Edit

#### Domain

- `lib/src/domain/models/expense/expense_filter_model.dart`:
  - Remover campos `final ExpenseOrderingEnum ordering`, `final int? minValue`, `final int? maxValue`.
  - Remover default `ordering = .dateDesc` e parâmetros `minValue`/`maxValue` do construtor.
  - Remover do `copyWith`: parâmetros `ordering`, `minValue`, `maxValue` + flags `clearMinValue`, `clearMaxValue`.
  - Remover entradas em `props` (`minValue`, `maxValue`, `ordering`).
  - Remover do `isEmpty` as checagens `minValue == null && maxValue == null && ordering == .dateDesc`.
  - Apagar o método `normalized()` (swap de min↔max quando min > max) — sem `minValue`/`maxValue` deixa de fazer sentido. Atualizar o único caller (`ExpensesNotifier.applyFilter` chama `filter.normalized()` em `expenses_notifier.dart:52`) para passar o filtro direto, sem o `normalized()`.
  - Remover imports do `ExpenseOrderingEnum`.

#### Infrastructure

- `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart`:
  - Remover bloco `if (filter.minValue != null && filter.minValue! > 0) { fragments.add('ge(value,...)') }` ([[expense_filter_request.dart:28-30]]).
  - Remover bloco `if (filter.maxValue != null && filter.maxValue! > 0) { fragments.add('le(value,...)') }` ([[expense_filter_request.dart:31-33]]).
  - Remover `fragments.add('ordering=${filter.ordering.query}')` ([[expense_filter_request.dart:42]]).
  - Remover helper `_formatValue` se ficar sem consumidor após as remoções (verificar).

#### Presentation

- `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — reduzir o enum de `{ category, period, value, ordering }` para `{ category, period }`.
- `lib/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart`:
  - Remover classes `MinValueChanged`, `MaxValueChanged`, `OrderingSelected`.
  - Remover imports de `ExpenseOrderingEnum`.
- `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart`:
  - Remover os braços `MinValueChanged`, `MaxValueChanged`, `OrderingSelected` do `switch (intent)`.
- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`:
  - `removeFilter` ([[expenses_notifier.dart:62-73]]) — remover braços `.value =>` e `.ordering =>` do switch.
  - `_buildChips` — remover bloco `if (filter.minValue != null || filter.maxValue != null)` e bloco `if (filter.ordering != .dateDesc)`.
  - Apagar helper privado `_valueLabel` ([[expenses_notifier.dart:228-236]]) — sem consumidor após a remoção do chip de valor.
  - `applyFilter` — chamar `_loadFirstPage(filter)` direto, sem `filter.normalized()`.
- `lib/src/presentation/ui/expenses/screens/expenses_filter_screen.dart` ([[expenses_filter_screen.dart:86-105]]) — remover os dois blocos `SizedBox(8) + ExpensesFilterValueSectionWidget(...)` e `SizedBox(8) + ExpensesFilterOrderingSectionWidget(...)`, ajustando spacing para que o footer fique encostado na seção de período. Remover imports correspondentes.

### Tests

- `test/src/infrastructure/clients/http/requests/expense_filter_request.dart`:
  - Remover asserts envolvendo `ge(value,...)`, `le(value,...)`, `ordering=...`.
  - Remover testes específicos como "min ignored when zero/negative", "emits ordering when matches default", "all fields set" (reescrever sem `minValue`/`maxValue`/`ordering`).
  - O caso "omits ordering when filter is null" passa a asserir que o request nunca contém `ordering=`, `ge(value`, `le(value`, independente do filtro.
- `test/src/data/repositories/expense_repository_test.dart`:
  - Ajustar o filtro de teste em `expense_repository_test.dart:491` removendo `ordering: ExpenseOrderingEnum.valueDesc` (e `minValue`/`maxValue` se houver — verificar).
- `test/src/domain/models/expense/expense_filter_model_test.dart`:
  - Remover asserts envolvendo `ordering`, `minValue`, `maxValue`, `clearMinValue`, `clearMaxValue`, `normalized()`.
- `test/src/presentation/providers/expenses_notifier_test.dart`:
  - Remover teste `removeFilter(.ordering)` ([[expenses_notifier_test.dart:422-425]]) e equivalente para `.value`.
- `test/src/presentation/providers/expenses_filters_notifier_test.dart`:
  - Remover testes `dispatch(OrderingSelected(...))`, `dispatch(MinValueChanged(...))`, `dispatch(MaxValueChanged(...))` e correlatos.

## Decisões de design

1. **Remoção total das duas seções no mesmo commit.** As duas mudanças tocam exatamente os mesmos arquivos de model, request, intent, notifier e screen — separar em dois commits causaria edição dupla nos mesmos arquivos. Coesão > granularidade.

2. **`normalized()` morre junto.** O método existia exclusivamente pra fazer `minValue ↔ maxValue` swap quando o usuário invertia os extremos (não invalidava o request). Sem `minValue`/`maxValue` no model, não há comportamento a preservar. O único caller (`ExpensesNotifier.applyFilter`) passa a chamar `_loadFirstPage(filter)` direto.

3. **`CurrencyFieldFormatter` sai junto.** Confirmado por `grep -rn CurrencyFieldFormatter lib/`: o único consumidor é `expenses_filter_value_section_widget.dart`. Forms de criação/edição de despesa usam outro caminho (validadores + `IMoneyService` para display, não input formatter). Manter o formatter "para o caso de precisar" seria dead code.

4. **`ExpenseFilterChipKind.value` e `.ordering` saem do enum.** Sem campos no model que disparem essas pílulas, manter os valores no enum criaria branches inalcançáveis no switch de `removeFilter`. Cortar agora.

5. **Sem migração de estado salvo.** O filtro não é persistido entre sessões (`ExpensesFiltersNotifier` recebe o `ExpenseFilterModel` como `seed` por instância). Não há cache/preferences para limpar.

6. **`-date` continua sendo a ordem visível, sem precisar de fallback explícito.** O default da `CursorPagination` no backend já entrega `-date`. Não é preciso mandar `ordering=-date` no request — economiza 17 bytes por chamada e simplifica o request builder.

7. **Não tocar em outras telas/filtros.** `/budgets`, `/notifications` etc. permanecem como estão. Esta change é exclusivamente sobre o filtro de despesas.

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde após a remoção dos arquivos/testes citados.
- `grep -rn "ExpenseOrderingEnum\|OrderingSelected\|MinValueChanged\|MaxValueChanged\|ExpensesFilterOrderingSection\|ExpensesFilterValueSection\|CurrencyFieldFormatter\|\.minValue\|\.maxValue\|filter\.ordering\|ChipKind\.value\|ChipKind\.ordering" lib/ test/` retorna zero resultados.
- Smoke manual:
  - Tela de filtros (`ExpensesFilterScreen`) mostra apenas **Categoria** e **Período**, com footer encostado.
  - Aplicar categoria + período funciona, e ao voltar para a lista as despesas filtram corretamente.
  - Botão "Limpar tudo" reseta para o estado vazio (sem mais ordering/value pra resetar).
  - Pílulas ativas na `ExpensesScreen`: aparecem só `Categoria` e `Período` quando aplicáveis. Dismiss de pílula recarrega corretamente.
  - Lista de despesas continua em ordem `-date` (mais recente no topo).
  - Scroll infinito (`loadMore`) preserva ordem.

## Fora de escopo

- Mudança na paginação do backend para suportar ordering dinâmico. Continua sendo bug conhecido server-side, mas sem deadline definido — não bloqueia esta change.
- Re-introduzir as seções no futuro. Se voltarem, voltam por spec nova.
- Filtros de outras listagens.
- Refactor do `ExpensesFiltersIntent` para sealed class menor (já é sealed; só sumirão classes filhas).

## Sequência de implementação

1. Spec aprovada pelo usuário (esta proposal).
2. Aplicar deletes/edits acima — único commit, mensagem `:fire: drop ordering and value sections from expense filter`.
3. `flutter analyze` + `flutter test` full.
4. Smoke manual cobrindo o checklist acima.
5. Arquivar em `openspec/changes/archive/2026-05-18-drop-expense-filter-ordering-and-value/`.
