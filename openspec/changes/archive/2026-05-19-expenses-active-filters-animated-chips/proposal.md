# Proposal: expenses-active-filters-animated-chips

## Intenção

Adicionar animações **sutis** em dois pontos do fluxo de filtros de despesas:

1. **Chips de filtros ativos na `ExpensesScreen`** — hoje, ao aplicar/remover um filtro, a barra de chips muda abruptamente. Trocar `ListView.separated` por `AnimatedList`, animando cada chip com `FadeTransition` + `SizeTransition` (eixo horizontal). Quando a lista vai a zero, a faixa de 40px colapsa via `AnimatedSize`.
2. **Texto "De: \<período\>" na `ExpensesFilterPeriodSectionWidget`** — hoje, ao escolher um preset de período ou range customizado, o texto resumo aparece/some/troca de valor sem transição. Envolver em `AnimatedSwitcher` + `AnimatedSize` pra suavizar a entrada/saída e a troca de label.

## Motivação

Cada chip representa um filtro ativo — uma ação "real" do usuário (buscou, escolheu categoria, escolheu faixa de valor). Visualmente sumir/aparecer sem transição faz o usuário perder o rastro da ação. Animação sutil (fade + size, ~200ms) reforça o causalidade "toquei aqui → isso reagiu" sem ser flashy.

`AnimatedList` é a ferramenta canônica do Flutter pra esse padrão: ele mantém `GlobalKey<AnimatedListState>` interno, mas expõe `insertItem`/`removeItem` que casam com um builder de `Animation<double>` por item. Sem dependência externa nova.

## Camadas afetadas

### Edit

- `lib/src/presentation/ui/expenses/widgets/expenses_active_filters_widget.dart`:
  - Converter `StatelessWidget` → `StatefulWidget`.
  - Manter espelho local `List<ExpenseActiveFilterChipPresentationData> _items`.
  - `initState` popula `_items` a partir de `widget.chips`.
  - `didUpdateWidget` faz diff por `chip.kind` (cada kind aparece no máximo uma vez):
    - Remoções: iterar `_items` reverso; pra cada kind ausente em `widget.chips`, `removeAt(i)` + `_listKey.currentState?.removeItem(i, builder, duration: 200ms)`.
    - Adições: iterar `widget.chips`; pra cada kind ausente em `_items`, `insert(i, ...)` + `_listKey.currentState?.insertItem(i, duration: 200ms)`.
    - Atualizações in-place (ex: chip de descrição mudou de label "Busca: Alu" pra "Busca: Aluguel"): substituir o item no `_items` sem chamar insert/remove — `AnimatedList` re-builda o item.
  - `itemBuilder(context, index, animation)`: envelopar o `InputChip` em `SizeTransition(sizeFactor: animation, axis: .horizontal, child: FadeTransition(opacity: animation, child: chip))`.
  - `removedItemBuilder`: idem ao itemBuilder, recebendo o snapshot do item removido + a animação reverse.
  - Outer `AnimatedSize(duration: 200ms, alignment: .topCenter)` em volta do `AnimatedList` — colapsa a faixa quando `_items` fica vazio. Mantém a `SizedBox(height: 40.0)` como conteúdo interno quando há chips.
  - Separadores: `AnimatedList` não tem `separatorBuilder`. Inserir o `SizedBox(width: 8.0)` no próprio `itemBuilder` (ex: padding `EdgeInsets.only(right: 8.0)` no chip, exceto o último). Decisão: padding direto no item é mais simples que tentar gerenciar separadores como items virtuais. Última posição sem padding direito.

- `lib/src/presentation/ui/expenses/widgets/filter/expenses_filter_period_section_widget.dart`:
  - Trocar o `if (formattedSummary != null) Text(...)` por `AnimatedSize` + `AnimatedSwitcher` (200ms, fade-only). Quando `formattedSummary` é `null`, child = `SizedBox.shrink(key: ValueKey('empty'))`; quando setado, child = `Text('De: $formattedSummary', key: ValueKey(formattedSummary))`. A key baseada no valor faz o `AnimatedSwitcher` disparar o fade ao trocar o range (ex: usuário muda do preset "Mês atual" pra "Últimos 30 dias"). `AnimatedSize` cuida do crescimento/encolhimento da altura.

### Tests

- Widget test opcional cobrindo o ciclo de inserção/remoção animada. Decisão: **fora de escopo** — animações são notoriamente difíceis de testar de forma determinística sem usar `tester.pump(duration)` com timing exato, e o ganho de confiança é baixo comparado ao smoke manual. Testes existentes do notifier continuam cobrindo a lista de chips ativa (não a animação em si).

## Decisões de design

1. **`AnimatedList` em vez de `AnimatedSwitcher` por item.** `AnimatedSwitcher` troca apenas um child de cada vez; pra múltiplos chips entrando/saindo independentes, `AnimatedList` é o idioma. Custo: precisa do diff manual no `didUpdateWidget`.

2. **Diff por `kind`, não por índice.** Cada `ExpenseFilterChipKind` aparece no máximo uma vez (description, category, value, period). Identidade direta — sem precisar de key composta ou hash.

3. **Animação: fade + size, 200ms, sem curva exótica.** `Curves.easeOut` é o default do Flutter pra entrada — match com material guidelines. Sem scale/slide/rotate — "sutil" significa não chamar atenção pra própria animação.

4. **`AnimatedSize` no outer pra empty→non-empty.** Sem isso, quando o último chip sai, a faixa de 40px continua ocupando espaço (porque `AnimatedList` não colapsa sozinho). Com `AnimatedSize`, a faixa encolhe pra zero suavemente.

5. **Separador como padding do item, não item virtual.** Mais simples que duplicar a lista interna com separators intercalados. `EdgeInsets.only(right: 8.0)` em todos os chips menos o último.

6. **Sem testes de animação.** Custo > benefício. Smoke manual cobre.

7. **Update in-place do label sem animar.** Quando só o label muda (ex: chip de busca "Busca: Alu" → "Busca: Aluguel" enquanto o usuário digita), substituir o item silenciosamente — animar a cada keystroke seria mais distração que ajuda.

8. **Resumo de período: `AnimatedSwitcher` com fade-only, sem `SizeTransition` interna.** O `AnimatedSize` externo já cuida da altura. Adicionar `SizeTransition` no `transitionBuilder` redundaria com o `AnimatedSize` e poderia gerar pulos visuais. Key derivada do próprio valor (`ValueKey(formattedSummary)`) faz a troca disparar fade entre duas strings diferentes.

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` full verde (animação não muda os testes do notifier).
- Smoke manual:
  - Aplicar filtro de categoria → chip aparece com fade + slide (size) suave.
  - Tocar `X` no chip → chip encolhe + fade out, vizinhos se aproximam.
  - Aplicar busca, categoria, valor e período em sequência → cada chip entra individualmente.
  - "Limpar tudo" → todos os chips saem em paralelo; faixa colapsa suavemente.
  - Digitar na busca rapidamente → label do chip de busca atualiza sem flicker (update in-place).
  - Pull-to-refresh com filtros ativos → chips permanecem, sem reanimar.
  - Na tela de filtros, escolher preset "Mês atual" → texto "De: PERÍODO" aparece com fade + a coluna cresce suavemente.
  - Trocar pra "Últimos 30 dias" → texto faz cross-fade entre o range antigo e o novo, com a altura ajustando se necessário.
  - "Limpar tudo" com período setado → texto desaparece com fade + a coluna encolhe.

## Fora de escopo

- Testes automatizados de animação — manual chega.
- Animação em outras barras de chip do app (notifications, couple, etc.) — só `/expenses` muda aqui.
- Custom animation curves, hero transitions, etc. — só fade + size.
- Refactor da `InputChip` em si — mantém o material widget.

## Sequência de implementação

1. Spec aprovada.
2. Implementação do widget (StatefulWidget + AnimatedList + diff).
3. `flutter analyze` + `flutter test`.
4. Smoke manual.
5. Arquivar.
