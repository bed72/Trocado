# Design — list-all-budgets

## Contexto técnico

A stack de Budget já está parcialmente em pé: `IBudgetRepository.findActive` + `findActive` no datasource + `ActiveBudgetResponse` + `ActiveBudgetNotifier` alimentam o `BudgetCardWidget` da Home. A stack de criação (`POST /api/v1/budgets`) também existe (`create` no repository, `BudgetLocation` singular para o formulário). Faltam apenas:

- Leitura de **todos** os budgets via `GET /api/v1/budgets` (paginado).
- Tela de listagem.
- Entry point a partir do card na Home.

A feature `expenses/` é o template direto: paginação cursor-based em `ExpensesNotifier` (manual com `AsyncNotifier`, sem pacote externo), `ExpensesPageModel` em `domain/`, `_cursorFrom` em `data/extensions/`, scroll infinito via `ScrollController` na screen, `ref.invalidate` para pull-to-refresh, tail de load-more com loading e failure isolados. Esta change replica esse padrão sem reinventar nada.

A API `GET /api/v1/budgets` devolve `total_spent` e `remaining` para **todos** os budgets — não só o ativo. Isso significa que `BudgetModel` pode ser enriquecido com esses campos, eliminando (no futuro) a duplicação `ActiveBudgetModel` vs `BudgetModel`. Esta change estende `BudgetModel` mas **não** remove `ActiveBudgetModel` — esse refactor fica para change separada que possa validar com calma todos os call sites.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

- `domain/` ganha campos em `BudgetModel`, novo `BudgetsPageModel`, e nova assinatura em `IBudgetRepository`. Zero Flutter, zero Dio.
- `infrastructure/` ganha campos em `BudgetResponse.fromJson`, novo `BudgetsResponse`, e novo `findAll` no datasource. `BudgetsResponse` segue a regra: apenas `fromJson`, **nunca** `toModel`.
- `data/` implementa `findAll` no `BudgetRepository` reusando `FailureResponseExtension.toFailure()`; cria `BudgetsResponseExtension.toPageModel()` com `_cursorFrom` privado idêntico ao de Expenses; estende `BudgetResponseExtension.toModel()` para mapear os novos campos.
- `presentation/` ganha a feature `budgets/` (notifier, state, screen, location, widgets, view-model), promove `BudgetCardWidget` para widget compartilhado em `presentation/widgets/budget/card/`, e estende `HomeScreen` + `HomeLocation` com o callback de navegação.
- `main/` ganha apenas a rota `AppRoutes.budgets`.

## Decisões de design

### 1. Estender `BudgetModel` em vez de criar `BudgetSummaryModel`

**Decisão**: `BudgetModel` ganha `int totalSpent` (centavos), `int remaining` (centavos, signed), `int createdAt` (ms epoch). `copyWith` e `props` atualizados.

**Rationale**: o backend já devolve esses campos em **todas** as variantes do recurso budget — `findActive`, `findAll` e (a verificar) `create`. Manter dois modelos paralelos (`BudgetModel` slim + `ActiveBudgetModel` rico) só faz sentido se houver fluxos que devolvem subset; como não há, a duplicação é puro débito. Esta change paga parte do débito (enriquecendo `BudgetModel`) sem ainda migrar o consumer (`ActiveBudgetNotifier` continua usando `ActiveBudgetModel`).

**Trade-off / risco a verificar**: o endpoint `POST /api/v1/budgets` (usado por `IBudgetRepository.create`) hoje devolve `BudgetResponse`. Se o backend **não** devolver `total_spent`/`remaining`/`created_at` no payload do POST, o `fromJson` estendido vai estourar (campo ausente). Mitigação no momento da implementação:

1. Inspecionar o curl real do `POST /api/v1/budgets` para confirmar a shape.
2. Se o POST não devolver os 3 campos: tornar os novos campos do response **opcionais** (`String?` no response, `int?` no model) e usar `??` para defaults.
3. Se o POST devolver: manter como required.

A spec assume required (caminho mais simples) — verificação fica como **primeira tarefa** em `tasks.md`.

### 2. `BudgetsPageModel` espelhando literalmente `ExpensesPageModel`

**Decisão**: `final class BudgetsPageModel extends Equatable` com `String? nextCursor`, `String? previousCursor`, `List<BudgetModel> budgets`, `copyWith` + `props`. Sem genérico.

**Rationale**: o projeto explicitamente rejeita wrappers genéricos de paginação (`PaginatedResponse<T>`). Cada page model é concreto e fechado pra um modelo específico — facilita refactor por feature, evita type erasure em mocks de teste, e mantém o domínio Dart-puro sem flertar com generics. Já decidido em `archive/list-all-expenses`; replicar.

### 3. Cursor extraído via `Uri.parse(...).queryParameters['cursor']` em `data/extensions/`

**Decisão**: helper privado em `BudgetsResponseExtension`:

```dart
String? _cursorFrom(String? url) =>
  url == null ? null : Uri.parse(url).queryParameters['cursor'];
```

**Rationale**: o backend devolve URLs completas em `next`/`previous` (ex: `"http://api.example.org/budgets/?cursor=cD00ODY%3D"`). O cliente HTTP do app não aceita URL absoluta — só path + query map. Extrair só o valor do `cursor` mantém a invariante: o app sempre constrói as URLs ele mesmo, o backend só fornece o opaque cursor. Padrão idêntico ao de Expenses; manter consistência.

### 4. `findAll(cursor: cursor)` passa `cursor` como query map ao Client

**Decisão**: `RemoteBudgetDataSource.findAll` chama:

```dart
_client.get(
  parameter: Requests(
    EndpointKey.budgets.path,
    query: cursor == null ? null : {'cursor': cursor},
  ),
)
```

**Rationale**: a interface aceita parâmetro de domínio (`String? cursor`) — nunca DTO. A implementação concreta monta o `Requests` (que é o DTO de request do `IHttpClient`). Quando `cursor == null`, **não** envia a chave — evita query string inútil (`?cursor=`) na primeira página. Espelha exatamente o padrão de `RemoteExpenseDataSource.findAll`.

### 5. `BudgetsNotifier` com `keepAlive: true` e `loadMore` manual

**Decisão**: `@Riverpod(keepAlive: true)` `AsyncNotifier<BudgetsState>`. `build()` async carrega primeira página. `loadMore()` é método público com guards manuais (`isLoadingMore`, `nextCursor != null`). Sem `applyFilter` / `searchChanged` (sem filtros nesta entrega). Pull-to-refresh via `ref.invalidate(budgetsProvider)` na screen — **nunca** `ref.refresh`.

**Rationale**: padrão idêntico ao `ExpensesNotifier` (já validado e em produção). `keepAlive` evita refetch ao navegar entre Home e Budgets. `ref.invalidate` (não `refresh`) é o idioma correto para keepAlive: refresh força execução imediata, invalidate apenas marca para próxima leitura — ideal pra pull-to-refresh onde a screen já está montada.

### 6. Active selecionado client-side por intervalo de datas (não chamar `findActive`)

**Decisão**: `BudgetsNotifier._pickActive(List<BudgetModel> budgets, DateTime now)` retorna o primeiro budget cujo `[startDate, endDate]` cobre `now` (compara em ms epoch). O active é **excluído** da lista `items` para evitar duplicação visual.

**Rationale**: a tela já vai bater na API uma vez para `findAll`. Bater de novo em `findActive` seria N+1 desnecessário (a info já está em todos os items da página 1). Selecionar client-side é O(n) sobre o tamanho da primeira página (tipicamente < 30 itens) — custo desprezível.

**Trade-off**: se nenhum budget da página 1 cobrir `now` (ex: o usuário não tem budget ativo, ou o ativo está em página 2), a tela mostra `activeItem == null` mesmo que exista um. Mitigação: como a API ordena por `created_at desc` e budgets são tipicamente mensais, o ativo está sempre nos primeiros itens. Se virar problema real, adicionar fetch separado de `findActive` na build.

### 7. Promover `BudgetCardWidget` de `home/widgets/budget/card/` para `presentation/widgets/budget/card/`

**Decisão**: mover **toda** a pasta `card/` (7 arquivos: `budget_card_widget.dart`, `budget_card_success_widget.dart`, `budget_card_loading_widget.dart`, `budget_card_failure_widget.dart`, `budget_card_empty_widget.dart`, `budget_card_label_widget.dart`, `budget_progress_bar_painter.dart`) para `lib/src/presentation/widgets/budget/card/`. Atualizar todos os imports (HomeScreen + previews + testes que mencionarem). Após mover, adicionar `VoidCallback? onTap` em `BudgetCardWidget` e `BudgetCardSuccessWidget`.

**Rationale**: o widget agora é consumido por **duas features** (`home` e `budgets`). A regra do projeto é dura: features são autocontidas; widget compartilhado mora em `presentation/widgets/<família>/`. Manter o widget em `home/widgets/` e importar de `budgets/` violaria encapsulamento e abriria o precedente errado.

**Mecânica do tap**: o `BudgetCardSuccessWidget` envolve seu corpo em `BounceWidget.withOnPress(onPress: onTap, child: ...)` quando `onTap != null`; quando `null`, renderiza o card sem feedback. Garante que o card no estado `loading`/`empty`/`failure` não seja clicável (faz sentido — só clica quando há dado).

### 8. `HomeScreen` recebe `navigateToBudgets` via construtor; `HomeLocation` injeta o callback

**Decisão**: `HomeScreen` ganha `final VoidCallback navigateToBudgets;` (named, required); repassa para `BudgetCardWidget(onTap: widget.navigateToBudgets)`. `HomeLocation.pageBuilder` constrói o callback `() => context.navigate(BudgetsLocation())` e injeta.

**Rationale**: padrão canônico do projeto — Locations compõem navegação; Screens recebem callbacks. `HomeScreen` continua sem importar `BudgetsLocation` (regra de encapsulamento entre features). A única exceção autorizada — Locations importando outras Locations — fica isolada em `HomeLocation`.

### 9. `BudgetsScreen` é `StatefulWidget` (precisa de `ScrollController`) com `Consumer` interno

**Decisão**: `class BudgetsScreen extends StatefulWidget`. O `_BudgetsScreenState` cria/dispõe o `ScrollController`, registra listener de scroll para `loadMore` (threshold 200px antes de `maxScrollExtent`), e o `build` retorna `Consumer` que lê `budgetsProvider` e renderiza o sliver tree.

**Rationale**: `ConsumerWidget` é proibido pelo projeto. `StatelessWidget + Consumer` interno é o default — mas `ScrollController` exige State para ciclo de vida (init/dispose). Resposta: `StatefulWidget + Consumer` interno (mesma forma que `ExpensesScreen`).

### 10. `BudgetItemPresentationData` formatado pelo notifier; vive na feature

**Decisão**: `final class BudgetItemPresentationData extends Equatable` com `BudgetModel budget`, `String formattedValue`, `String formattedTotalSpent`, `String formattedRemaining`, `String formattedPeriod`. Construído em `BudgetsNotifier._toItem(BudgetModel)` usando `IMoneyService.format(...)` e helper interno `_formatPeriod(int startMs, int endMs)`. Vive em `lib/src/presentation/ui/budgets/data/budget_item_presentation_data.dart`.

**Rationale**: regra de ouro do projeto — screen **nunca** lê `moneyServiceProvider` ou `dateFormatterProvider` direto; o notifier injeta o service e emite view-model com strings prontas. Vive na feature por enquanto (não em `presentation/data/budget/`) porque ninguém mais consome — promove se outra feature precisar.

**Formato do período** (`formattedPeriod`):
- Quando `startDate.year == endDate.year == DateTime.now().year`: `"01/05 – 30/05"`.
- Caso contrário: `"01/05/26 – 30/05/26"` (ano com 2 dígitos).
- Helper privado no notifier — não cria service novo só pra isso.

### 11. Tail da lista reflete três estados (loading / failure / fim)

**Decisão**: o último sliver da `BudgetsListWidget` é dinâmico:
- `state.isLoadingMore == true` → `BudgetsLoadMoreLoadingWidget` (CircularProgressIndicator centralizado, padding 16).
- `state.loadMoreFailure != null` → `BudgetsLoadMoreFailureWidget(onRetry: () => ref.read(budgetsProvider.notifier).loadMore())` (texto + botão "Tentar novamente").
- `state.nextCursor == null` → `SizedBox.shrink()` (fim da lista, sem indicador "fim" — segue convenção de Expenses).
- caso contrário → `SizedBox.shrink()` (idle; load disparado por scroll).

**Rationale**: idêntico ao tail de `ExpensesListWidget`. Failure de load-more é **estado isolado** — não substitui a lista (que continua visível com os items já carregados). Esse é o ponto inteiro de ter `loadMoreFailure` separado de uma transição para `AsyncError`.

### 12. Sem testes de widget obrigatórios

**Decisão**: cobertura mínima é response (`fromJson`), repository (mock em `IHttpClient`), e notifier (mock em `IBudgetRepository` + `IMoneyService`). Widget tests só se houver lógica visual complexa.

**Rationale**: a screen é puro tree-building condicional sobre `AsyncValue` — equivalente em complexidade à `ExpensesScreen`, que também não tem widget tests. Se virar bug recorrente, adiciona-se em change futura.

## Fluxos

### Tap no card da Home → tela de listagem

```
[HomeScreen] user taps BudgetCardWidget
  → BudgetCardSuccessWidget.onTap()
  → screen callback: widget.navigateToBudgets()
  → composto em HomeLocation.pageBuilder
  → context.navigate(BudgetsLocation())

[BudgetsLocation → BudgetsScreen] build
  → BudgetsNotifier.build() async
  → repository.findAll(cursor: null)
  → on Right(page):
      activeItem = _pickActive(page.budgets, DateTime.now())
      items = page.budgets where !active map _toItem
      state = AsyncData(BudgetsState(activeItem, items, nextCursor: page.nextCursor))
  → on Left(failure): rethrow → AsyncError

[BudgetsScreen] renderiza por AsyncValue:
  - AsyncLoading → BudgetsLoadingWidget
  - AsyncError → BudgetsFailureWidget(onRetry: () => ref.invalidate(budgetsProvider))
  - AsyncData(items: empty, activeItem: null) → BudgetsEmptyWidget
  - AsyncData → CustomScrollView com active card no topo + BudgetsListWidget + tail
```

### Scroll infinito

```
[BudgetsScreen._onScroll]
  if (position.pixels >= position.maxScrollExtent - 200)
    → ref.read(budgetsProvider.notifier).loadMore()

[BudgetsNotifier.loadMore]
  if (state is! AsyncData) return                    [guard]
  if (state.value.isLoadingMore) return              [guard duplicate]
  if (state.value.nextCursor == null) return         [guard end]
  state = AsyncData(state.value.copyWith(
    isLoadingMore: true, clearLoadMoreFailure: true))
  data = await repository.findAll(cursor: state.value.nextCursor)
  data.fold(
    (failure) => state = AsyncData(state.value.copyWith(
                   isLoadingMore: false, loadMoreFailure: failure)),
    (page) => state = AsyncData(state.value.copyWith(
                items: [...state.value.items, ...page.budgets.map(_toItem)],
                nextCursor: page.nextCursor,
                clearNextCursor: page.nextCursor == null,
                isLoadingMore: false, clearLoadMoreFailure: true)),
  )
```

### Pull-to-refresh

```
[BudgetsScreen] RefreshIndicator.onRefresh
  → ref.invalidate(budgetsProvider)
  → provider transita para AsyncLoading
  → build() roda de novo, recarrega página 1
```

## Trade-offs assumidos

- **Active client-side**: se o ativo estiver em página > 1, não aparece destacado no topo. Mitigado pelo ordering desc da API e tamanho típico de página. Se virar problema, adicionar `findActive` separado na build.
- **`BudgetModel` enriquecido sem deduplicar `ActiveBudgetModel`**: dois modelos passam a coexistir com mesmos campos. Aceitável a curto prazo; a deduplicação é change separada que precisa validar com calma todos os call sites de `ActiveBudgetNotifier`.
- **POST `/api/v1/budgets` precisa devolver os 3 novos campos**: se não devolver, fallback é tornar os campos opcionais. Verificação obrigatória na primeira tarefa.
- **Tap no item da lista não navega**: itens são read-only. Quando edit/delete forem implementados (change separada, padrão `expense-edit-and-delete`), o long-press abrirá um `BudgetActionsScreen` análogo.
- **Sem agrupamento por mês**: a lista é flat (cards individuais ordenados por API). Se o usuário acumular muitos budgets, agrupar por ano é evolução futura.
- **Promoção do `BudgetCardWidget`**: implica refactor de imports em arquivos da feature `home/`. Risco é diff grande; mitigado por busca textual e `flutter analyze` ao final.

## O que este design **não** pretende resolver

- Edit/delete de budget — change separada.
- Filtros (por valor, por status ativo/encerrado, por ano) — change separada se virar necessidade.
- Busca textual por descrição — change separada.
- Deep link para `/budgets` — entry exclusivo via Home nesta entrega.
- Notificação de orçamento estourando — fluxo separado no domínio de insights.
- Compartilhamento de orçamento com parceiro — escopo macro, fora de qualquer change isolada.
