# Proposal: expenses-filter-value-presets-and-ilike-search

## Intenção

Dois ajustes complementares no filtro de despesas (`/expenses`), entregues juntos porque dividem `ExpenseFilterRequest` e tornam a experiência "buscar e refinar" próxima do esperado:

1. **Nova seção de filtro por faixa de valor** na tela de filtros (`ExpensesFilterScreen`), com 4 chips de presets contíguos cobrindo de R$0 a infinito. Equivalente ao que já existe pra período, mas em torno de `value`. Sem opção "Personalizado" nessa entrega — pode virar follow-up.
2. **Correção da busca por descrição** pra ser case-insensitive e match parcial em qualquer posição (estilo Google). Hoje o `ExpenseFilterRequest` emite `like(description,${valor}*)`, que é case-sensitive e exige começo exato. Trocar pra `ilike(description,*${valor}*)` casa "Aluguel", "ALUGUEL", "aluguel do mês", "ALU 123" — todos a partir de "alu".

Ambos são puramente cliente. Backend (py_rql) já expõe `ilike` no set default de strings e operadores `ge`/`le` em campos numéricos; nada muda do lado server.

## Motivação

### Faixa de valor

Hoje o usuário só consegue refinar a lista por categoria, período e busca. Não há jeito de "ver só despesas grandes" ou "filtrar gastos pequenos do mês". Adicionar faixa de valor é o terceiro eixo natural do trio "o quê + quanto + quando".

A escolha por **presets contíguos** (em vez de slider) tem três razões: (a) UX consistente com o filtro de período que já existe (chips de seleção única); (b) presets viram pílulas auto-explicativas na barra de chips ativos; (c) reduz a superfície de implementação — sem range picker, sem validação min<max, sem teclado numérico. Slider/range custom pode virar follow-up (intent `CustomValueRangeChanged` análogo ao `CustomRangeChanged` de período).

Buckets escolhidos (em centavos internamente; R$ exibido na UI):

| Preset            | minValue (centavos) | maxValue (centavos) | Label visível       |
|-------------------|---------------------|---------------------|---------------------|
| `upTo50`          | `null`              | `5000`              | "Até R$50"          |
| `from50To200`     | `5000`              | `20000`             | "R$50 – R$200"      |
| `from200To500`    | `20000`             | `50000`             | "R$200 – R$500"     |
| `above500`        | `50000`             | `null`              | "Acima de R$500"    |

Contiguidade evita gaps confusos. Cobre o range típico de despesas domésticas (pão a aluguel) com granularidade suficiente. Os limites inclusivos (`ge`/`le` no backend) garantem que R$200 cai tanto em "R$50 – R$200" quanto em "R$200 – R$500" — comportamento aceito (overlap de borda é raro e não engana o usuário).

### Search ilike

`like(description,Aluguel)` no py_rql é match exato (sem `*` curinga). O código atual sempre acrescenta `*` no fim, então `like(description,Alu*)` casa "Aluguel" e "Alugado", mas **não** casa "ALUGUEL" (case-sensitive) nem "do aluguel" (sem prefix match). O usuário hoje precisa lembrar a capitalização exata e começar a string certa pra ver resultado — anti-padrão.

`ilike(description,*${valor}*)` resolve todos os casos:
- `ilike(description,*alu*)` → casa "Aluguel", "aluguel", "ALU 123", "alugado"
- `ilike(description,*mercado*)` → casa "Mercado", "MERCADO", "supermercado do bairro"

A normalização do input fica em `ExpenseFilterRequest._buildSearchFragment` (helper privado novo):
1. `trim()` no input.
2. Se vazio, não emite o fragmento.
3. `Uri.encodeComponent(trimmed)` no valor (preserva `*` literal do usuário como `%2A`, ou seja, vira parte da string buscada e não curinga).
4. Wrap em `*…*` na string final do RQL: `ilike(description,*$encoded*)`.

`*` adicionado pelo frontend é literal no RQL (curinga); `*` digitado pelo usuário é encoded e vira parte da busca. Comportamento previsível.

## Camadas afetadas

### Edit

#### Domain

- `lib/src/domain/enums/expense/expense_value_preset_enum.dart` **(novo)** — enum com 4 valores: `upTo50`, `from50To200`, `from200To500`, `above500`. Campo `label` (`String`) pra exibição. Método `toRange()` retornando `ExpenseValueRange` (typedef `({int? minValue, int? maxValue})`, em centavos).

- `lib/src/domain/models/expense/expense_filter_model.dart` — adicionar `final int? minValue`, `final int? maxValue` (centavos). `isEmpty` passa a checar também esses dois. `copyWith` ganha `minValue`, `maxValue`, `clearMinValue`, `clearMaxValue`. Construtor mantém compatibilidade nominal — todos os usos atuais (sem value) continuam compilando porque os campos novos são opcionais.

#### Infrastructure

- `lib/src/infrastructure/clients/http/requests/expense_filter_request.dart`:
  - **Search fix**: linha que monta o fragmento de descrição passa de `like(description,${Uri.encodeComponent(trimmedDescription)}*)` pra `ilike(description,*${Uri.encodeComponent(trimmedDescription)}*)`. O `Uri.encodeComponent` cuida de encodar `*` literal que o usuário digitar.
  - **Value range**: se `filter.minValue != null`, emitir `ge(value,${_formatValue(filter.minValue!)})`; se `filter.maxValue != null`, emitir `le(value,${_formatValue(filter.maxValue!)})`. Helper `_formatValue(int cents)` retorna `(cents / 100).toStringAsFixed(2)` (decimal com 2 casas, mesma convenção do `ExpenseRequest.toJson`).
  - Posição dos fragmentos (irrelevante pra semântica RQL, mas pra consistência): category → date(start,end) → value(min,max) → description → page_size.

#### Presentation — Notifier de filtros

- `lib/src/presentation/ui/expenses/notifiers/expenses_filters_state.dart`:
  - Renomear `selectedPreset` → `selectedPeriodPreset` (refletindo que agora há mais de um tipo de preset). `formattedPeriodSummary` mantém o nome (já é específico de período).
  - Adicionar `final ExpenseValuePresetEnum? selectedValuePreset`.
  - `copyWith` ganha `selectedValuePreset` + `clearSelectedValuePreset`.
  - `props` atualizado.

- `lib/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart`:
  - Renomear `PresetSelected` → `PeriodPresetSelected` (consistência com state).
  - Adicionar `final class ValuePresetSelected extends ExpensesFiltersIntent { final ExpenseValuePresetEnum preset; const ValuePresetSelected(this.preset); }`.
  - `Cleared`, `CategorySelected`, `CustomRangeChanged` ficam intactos.

- `lib/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart`:
  - `dispatch` ganha branch `ValuePresetSelected(:final preset) => _selectValuePreset(preset)`.
  - `_selectValuePreset(preset)` aplica `preset.toRange()` no draft (`copyWith(minValue: ..., maxValue: ..., clearMinValue: range.minValue == null, clearMaxValue: range.maxValue == null)`).
  - Toggle: se o preset selecionado já estiver ativo (`state.selectedValuePreset == preset`), considerar deselecionar (chamando `clearMinValue: true, clearMaxValue: true, clearSelectedValuePreset: true`). Análogo ao que period faz hoje? **Decisão**: period hoje não toggles — re-clicar mantém selecionado. Seguir o mesmo: re-clicar **não** desmarca; pra desmarcar usa "Limpar tudo" ou (na tela de listagem) o `X` do chip. Consistência > sutileza.

#### Presentation — Tela de filtros

- `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_value_section_widget.dart` **(novo)** — espelho de `ExpensesFilterPeriodSectionWidget`. Recebe `selectedPreset: ExpenseValuePresetEnum?`, `onPresetSelected: ValueChanged<ExpenseValuePresetEnum>`. Renderiza título "Valor" + `Wrap` de `ExpensesFilterChoiceChipWidget` (um chip por valor do enum).

- `lib/src/presentation/ui/expenses/screens/expenses_filter_screen.dart`:
  - Adicionar a `ExpensesFilterValueSectionWidget` entre a section de categoria e a section de período (ordem visual: Categoria → Valor → Período).
  - Passa `state.selectedValuePreset` e `(preset) => notifier.dispatch(ValuePresetSelected(preset))`.

#### Presentation — Listagem (chip ativo)

- `lib/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart` — adicionar `value` entre `category` e `period`: `enum ExpenseFilterChipKind { description, category, value, period }`. Ordem reflete a ordem natural de exibição.

- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`:
  - `_buildChips`: se `filter.minValue != null || filter.maxValue != null`, adicionar chip `kind: .value, icon: Icons.payments_outlined, label: _valueLabel(filter.minValue, filter.maxValue)`. Inserir entre category e period.
  - `_valueLabel(int? min, int? max)`: usa `_moneyService.format(x / 100)` e retorna:
    - `(null, max)` → "Até ${formatted(max)}"
    - `(min, null)` → "Acima de ${formatted(min)}"
    - `(min, max)` → "${formatted(min)} – ${formatted(max)}"
    - `(null, null)` → nunca acontece (guarda pelo `if` anterior).
  - `removeFilter`: estender o `switch` com `.value => current.copyWith(clearMinValue: true, clearMaxValue: true)`.

### Tests

- `test/src/infrastructure/requests/expense_filter_request_test.dart` (se não existir, criar; senão estender):
  - `description: 'alu'` → fragmento contém `ilike(description,*alu*)` (não mais `like(...)`).
  - `description: '  Alu  '` → fragmento contém `ilike(description,*Alu*)` (trim aplicado).
  - `description: 'a*b'` → fragmento contém `ilike(description,*a%2Ab*)` (curinga literal do usuário encoded).
  - `minValue: 5000, maxValue: null` → fragmento contém `ge(value,50.00)`.
  - `minValue: null, maxValue: 5000` → fragmento contém `le(value,50.00)`.
  - `minValue: 5000, maxValue: 20000` → fragmento contém `ge(value,50.00)&le(value,200.00)`.
  - `description: 'alu', minValue: 10000` → ambos os fragmentos presentes.

- `test/src/presentation/providers/expenses_filters_notifier_test.dart`:
  - `ValuePresetSelected(.upTo50)` → `state.selectedValuePreset == .upTo50`, `state.draft.minValue == null`, `state.draft.maxValue == 5000`.
  - `ValuePresetSelected(.from50To200)` → `state.draft.minValue == 5000`, `state.draft.maxValue == 20000`.
  - `Cleared` → ambos os campos voltam pra null/null e `selectedValuePreset` vira null.

- `test/src/presentation/providers/expenses_notifier_test.dart`:
  - Novo teste: filtro com `minValue: 5000, maxValue: 20000` → chip de valor presente, `label: 'R$ 50,00 – R$ 200,00'` (ou conforme o que `MoneyService.format` devolver — o mock no teste já formata como `'R\$ ${value}'`).
  - Novo teste: `removeFilter(.value)` zera `minValue` e `maxValue` no filter resultante.
  - Atualizar o teste de ordenação de chips (description→category→period) pra incluir o novo kind: description→category→value→period.

- `test/src/domain/enums/expense/expense_value_preset_enum_test.dart` **(novo)** — `toRange()` de cada um dos 4 presets retorna o tuple esperado.

## Decisões de design

1. **Centavos no model, decimal no request.** Mesma convenção do `ExpenseRequest` (`value / 100).toStringAsFixed(2)`). Mantém consistência entre criar despesa e filtrar por faixa.

2. **Sem toggle ao re-clicar.** `ExpensesFilterPeriodSectionWidget` hoje não permite deselecionar um preset clicando de novo — seguir a mesma regra pra valor. Quem quer desmarcar usa "Limpar tudo" ou o `X` do chip ativo na listagem. Mudar pra "toggle" seria consistência cross-feature melhor mas é fora do escopo dessa spec.

3. **Sem "Personalizado".** Slider de range / range picker fica fora — entrega só presets nessa rodada. Se houver demanda, adicionar `ExpenseValuePresetEnum.custom` + intent `CustomValueRangeChanged(int? min, int? max)` numa spec follow-up, espelhando o que period já faz.

4. **Ícone do chip: `Icons.payments_outlined`.** Sugere "dinheiro" sem ser específico de tipo de transação (`attach_money` é muito "$$" americano). Pode rever no smoke se ficar destoante.

5. **Posição do chip de valor na lista: entre category e period.** `enum ExpenseFilterChipKind { description, category, value, period }`. Ordem reflete leitura natural: "o quê → tipo → quanto → quando".

6. **`Uri.encodeComponent` cobre o usuário digitando `*`.** Se o usuário digitar `a*b` no campo de busca, vira `%2A` no encoded, e o backend vê `a*b` literal (não como curinga). Curingas vêm só do frontend, sempre wrapping fixo `*…*`. Sem necessidade de "escape manual".

7. **Renomeação `PresetSelected → PeriodPresetSelected` e `selectedPreset → selectedPeriodPreset`.** Custo baixo (3 arquivos) e ganho de clareza imediato — sem essa renomeação, o leitor precisa adivinhar "preset de quê". Quando houver `ValuePresetSelected` lado a lado, a ambiguidade dói.

8. **Spec única, não duas.** Ambas as mudanças tocam `ExpenseFilterRequest` no mesmo `build()`. Risco de conflito entre PRs separados sem ganho real de isolamento. Atomicidade no PR também facilita o smoke ("digitei alu e marquei R$50–R$200 e funcionou").

9. **Limites inclusivos com overlap de borda.** R$200 cai em ambos "R$50 – R$200" e "R$200 – R$500" porque o backend usa `ge`/`le` (inclusivos). Aceitar — exclusividade exigiria `gt`/`lt` ou ranges `[X, X+1)`. Overlap só importa pra valores na borda exata (raros) e não muda nada do que o usuário enxerga.

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde, incluindo testes novos e o teste de ordenação de chips atualizado.
- Smoke manual:
  - Buscar "alu" na barra de busca → lista filtra "Aluguel", "aluguel", "ALU 123" e qualquer outro item que contenha "alu" em qualquer caixa. Chip "Busca: alu" aparece.
  - Abrir filtros → seção "Valor" presente entre Categoria e Período, com 4 chips ("Até R$50", "R$50 – R$200", "R$200 – R$500", "Acima de R$500").
  - Tocar "R$50 – R$200" + Aplicar → chip "R$ 50,00 – R$ 200,00" (ou formato equivalente do `MoneyService`) aparece junto dos demais. Lista mostra só despesas no range.
  - Combinar busca "uber" + faixa "Acima de R$500" → lista filtra ambos (Ubers caros). Os dois chips aparecem.
  - Tocar `X` no chip de valor → faixa some, busca permanece (e vice-versa).
  - "Limpar tudo" na tela de filtros → categoria, valor e período voltam ao default; busca também é limpa pela sincronização do controller já existente.

## Fora de escopo

- "Personalizado" pra valor (slider/range picker) — follow-up.
- Toggle deselect ao re-clicar o preset selecionado (vale pra valor **e** período) — UX separada.
- Backend (py_rql, parser RQL) — já suporta tudo.
- Outras telas com search/filter — só `/expenses` muda aqui.
- Localização do label do valor — usa o que `MoneyService.format` devolver; não inventar string nova.

## Sequência de implementação

1. Spec aprovada (esta proposal).
2. Implementação:
   - Domain: enum `ExpenseValuePresetEnum`, campos `minValue`/`maxValue` no `ExpenseFilterModel`.
   - Infra: `ExpenseFilterRequest` — `ilike` + wrap `*…*` no description, fragmentos de valor.
   - Presentation (filtros): state/intent rename + add `ValuePresetSelected`, widget de seção, integração na screen.
   - Presentation (listagem): enum chip kind, `_buildChips`, `removeFilter`.
   - Testes: request, filter notifier, expenses notifier, enum.
3. `flutter analyze` + `flutter test` full.
4. Smoke manual cobrindo o checklist.
5. Arquivar em `openspec/changes/archive/` com prefixo de data.
