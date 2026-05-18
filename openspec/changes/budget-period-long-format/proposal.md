# Proposal: budget-period-long-format

## Intenção

Trocar o formato de período exibido no campo de data do form de Budget (e, por consequência, em todos os consumidores de `IDateFormatterService.formatPeriod`) do estilo curto numérico (`12/05 – 20/05`, `01/12/25 – 31/01/26`) para o estilo longo em pt_BR, alinhado com o que `formatLongDate` já produz em despesas:

- Range no ano corrente: `12 de Mai até 20 de Mai`
- Range cruzando virada de ano (start no ano corrente, end no próximo): `20 de Dez até 25 de Jan de 2027` — ano só no extremo final
- Data única (start == end no nível do dia): `20 de Mai` (ou `20 de Mai de 2027` se fora do ano corrente)

A regra reaproveita a mesma lógica de ano contextual já validada em `formatLongDate` ([[expenses-display-event-date]]): omite o ano quando bate com `_now().year`, mostra quando difere.

## Motivação

`formatPeriod` foi introduzido junto da feature de Budget com o formato curto numérico (`dd/MM` ou `dd/MM/yy` quando cruza ano). O resto do app convergiu para o estilo longo em pt_BR (`28 de Abr`, `28 de Abr de 2025`) na change de despesas — esse formato é mais legível em telas verticais, casa com o tom dos demais labels do form e elimina a ambiguidade de mês/dia (`12/05` pode ser lido como 5 de dezembro por estrangeiros, `12 de Mai` não).

O campo do form de Budget é o ponto onde o usuário **decide** o período — então a clareza pesa mais aqui do que numa lista. Mas como o mesmo `formatPeriod` é consumido também pelo `BudgetListItemWidget` (lista de orçamentos passados), mantê-lo coerente entre form e lista é o mais simples e barato.

## Camadas afetadas

- `domain/services/date_formatter_service.dart` — sem mudança de assinatura (`formatPeriod(int startMillis, int endMillis) → String`); contrato segue idêntico.
- `infrastructure/services/date_formatter_service.dart` — `formatPeriod` reescrito conforme a regra abaixo. `formatLongDate` permanece intocado (já tem a regra de ano contextual).
- `presentation/ui/budgets/widgets/budgets_loading_widget.dart` — placeholder `'00/00 – 00/00'` passa para `'00 de Mmm até 00 de Mmm'` (cobre o caso comum sem ano).
- `test/src/infrastructure/services/date_formatter_service_test.dart` — substitui os 3 cenários atuais de `formatPeriod` pelos cenários novos da regra (single, range mesmo ano, range cruzando ano) e adiciona o cenário de start==end colapsando.

**Não muda:**
- `BudgetFormNotifier`, `BudgetsNotifier`, `BudgetItemPresentationData`, `BudgetFormState`, `BudgetDateFieldWidget`, `BudgetListItemWidget`, `BudgetScreen` — todos os consumidores chamam `formatPeriod(start, end)` e leem o String pronto do view-model; o swap é interno ao service.

## Decisões de design

1. **Reaproveitar `formatPeriod` ao invés de criar `formatLongPeriod`.** A assinatura do service não muda — o que muda é a string retornada. Todos os consumidores existentes herdam o novo formato automaticamente. Não há sinalização visual de que "form" e "lista" deveriam divergir; coerência > parametrização.

2. **Ano só no extremo final quando o range cruza a virada.** Quando `start.year == _now().year` mas `end.year != _now().year`, a regra é `'{day} de {monthAbbrev} até {day} de {monthAbbrev} de {end.year}'`. O ano no start é redundante (é o ano corrente, já implícito) e poluiria a leitura. O ano no end é informação genuína porque marca que o período "atravessa". Espelha a convenção tipográfica usada em PT-BR para intervalos com virada (ex: "20 de dezembro até 5 de janeiro de 2027").

3. **Colapsar para `formatLongDate(start)` quando start == end no nível do dia.** O `DateRangeScreen` emite `(startDate, startDate)` quando o usuário seleciona apenas uma data ([[date_range_screen.dart:86-87]]: `endDate = _range?.endDate ?? _range?.startDate`). Mostrar `20 de Mai até 20 de Mai` é redundante. A comparação é em `DateTime(year, month, day)` (start of day) para tolerar diferença de horário caso o picker passe a normalizar diferente no futuro.

4. **Separador `até` em vez de en-dash `–`.** O en-dash existente (`–`) é tipograficamente correto mas visualmente fraco em pt_BR — `até` lê como linguagem natural e casa com o tom do form (labels "Selecione o período", "Cadastrar").

5. **Não tocar nas pegadinhas de range fora do ano corrente.** Casos como `start = 10/05/2025, end = 20/05/2025` (ambos num ano não-corrente) ou `start = 10/05/2025, end = 20/05/2027` (atravessa múltiplos anos) **não estão cobertos** por esta change — deferidos para uma follow-up. Ver "Fora de escopo".

## Critério de aceitação

- `flutter analyze` limpo.
- `flutter test` verde, com os cenários novos de `formatPeriod` cobrindo: (a) data única, (b) range no ano corrente, (c) range cruzando virada de ano, (d) data única fora do ano corrente.
- Smoke manual no form de Budget (`BudgetScreen`):
  - Selecionar `12/05/2026 → 20/05/2026` → campo exibe `12 de Mai até 20 de Mai`.
  - Selecionar apenas `20/05/2026` (single tap no picker) → `20 de Mai`.
  - Selecionar `20/12/2026 → 25/01/2027` → `20 de Dez até 25 de Jan de 2027`.
- Smoke manual na lista de orçamentos (`BudgetsScreen`): cards passados renderizam períodos no novo formato.
- Placeholder do `BudgetsLoadingWidget` não destrói o layout (largura próxima da versão curta — verificar visualmente).

## Fora de escopo

- **Range entirely in a non-current year** (e.g., `10/05/2025 → 20/05/2025` quando hoje é 2026): deferido. Decidir entre `10 de Mai até 20 de Mai de 2025` (ano só no end, igual à regra do cross-year) ou `10 de Mai de 2025 até 20 de Mai de 2025` (ano em ambos). Como hoje o produto não exibe orçamentos antigos com proeminência, fica para a próxima.
- **Range cruzando mais de uma virada de ano** (e.g., `10/12/2025 → 20/01/2027`): mesmo motivo — caso de borda raríssimo para o domínio de orçamentos de casal.
- Outras superfícies que poderiam usar `formatPeriod` no futuro (ex: filtros de expense por período, headers de grupo): não criadas por esta change.
- Mudança no `IDateFormatterService` (nova assinatura, novo método): sem necessidade — o contrato permanece.
- i18n: o app é pt_BR-only por design; sem mudança.
- Backend: sem mudança.
