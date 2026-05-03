# Tasks — list-all-budgets

Ordem fixa: verificação de contrato → domain → infrastructure → data → presentation (promoção do widget) → presentation (Home wiring) → presentation (nova feature `budgets/`) → main (rota) → code generation → testes → verificação manual.

---

## 1. Verificação de contrato (BLOQUEANTE)

- [ ] 1.1 Disparar `POST /api/v1/budgets` (via curl com bearer token) com payload mínimo válido e inspecionar a resposta.
- [ ] 1.2 Confirmar se a resposta contém `total_spent`, `remaining` e `created_at`. Registrar o resultado:
  - Se **sim** → seguir o resto das tasks tratando os campos como **required** (`int` no model, `String` no response).
  - Se **não** → ajustar `BudgetResponse` para tornar os 3 campos `String?` e `BudgetModel` para `int?`; usar `0` como default em `_toItem` (ou ocultar `formattedTotalSpent`/`formattedRemaining` quando null em `BudgetItemPresentationData`).

## 2. Domain

- [ ] 2.1 Estender `BudgetModel` (`lib/src/domain/models/budget/budget_model.dart`):
  - Adicionar `final int totalSpent;` (centavos).
  - Adicionar `final int remaining;` (centavos, signed).
  - Adicionar `final int createdAt;` (ms epoch).
  - Atualizar construtor `const BudgetModel({...})` com os três (nullability conforme task 1.2).
  - Atualizar `copyWith({int? totalSpent, int? remaining, int? createdAt, ...})`.
  - Atualizar `props` com os três.
- [ ] 2.2 Criar `lib/src/domain/models/budget/budgets_page_model.dart`:
  - `final class BudgetsPageModel extends Equatable`.
  - Campos: `final String? nextCursor;`, `final String? previousCursor;`, `final List<BudgetModel> budgets;`.
  - Construtor `const BudgetsPageModel({this.nextCursor, this.previousCursor, this.budgets = const []})`.
  - `copyWith({...})` aceitando overrides para os três campos.
  - `props` com os três.
- [ ] 2.3 Estender `IBudgetRepository` (`lib/src/domain/repositories/interface_budget_repository.dart`) com:
  ```dart
  Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor});
  ```
  Manter `findActive` e `create` intactos.

## 3. Infrastructure

- [ ] 3.1 Estender `BudgetResponse.fromJson` (`lib/src/infrastructure/clients/http/responses/budget/budget_response.dart`):
  - Adicionar `final String totalSpent;` (ou `String?` conforme task 1.2), lido de `json['total_spent']`.
  - Adicionar `final String remaining;` (ou `String?`), lido de `json['remaining']`.
  - Adicionar `final String createdAt;` (ou `String?`), lido de `json['created_at']`.
  - Atualizar construtor e `fromJson`.
- [ ] 3.2 Criar `lib/src/infrastructure/clients/http/responses/budget/budgets_response.dart`:
  - `final class BudgetsResponse`.
  - Campos: `final String? next;`, `final String? previous;`, `final List<BudgetResponse> budgets;`.
  - `fromJson`: lê `json['next']`, `json['previous']`, `(json['results'] as List).map(BudgetResponse.fromJson).toList()`.
  - **Nunca** `toModel()` aqui.
- [ ] 3.3 Estender `IRemoteBudgetDataSource` (`lib/src/infrastructure/datasources/remote/remote_budget_data_source.dart`) com:
  ```dart
  Future<Either<FailureResponse, BudgetsResponse>> findAll({String? cursor});
  ```
- [ ] 3.4 Implementar `findAll` em `RemoteBudgetDataSource`:
  ```dart
  @override
  Future<Either<FailureResponse, BudgetsResponse>> findAll({String? cursor}) async {
    final response = await _client.get(
      parameter: Requests(
        EndpointKey.budgets.path,
        query: cursor == null ? null : {'cursor': cursor},
      ),
    );
    return response.either(FailureResponse.fromJson, BudgetsResponse.fromJson);
  }
  ```
  Nome da var local: `response` (nunca `either`).

## 4. Data

- [ ] 4.1 Atualizar `BudgetResponseExtension.toModel()` (`lib/src/data/extensions/budget/budget_response_extension.dart`):
  - Mapear `totalSpent` via `(double.parse(totalSpent) * 100).round()`.
  - Mapear `remaining` via `(double.parse(remaining) * 100).round()` (suporta negativo).
  - Mapear `createdAt` via `DateTime.parse(createdAt).millisecondsSinceEpoch`.
  - Manter mapping existente de `value`, `startDate`, `endDate`, `description`, `id`.
  - Tratar nullability conforme task 1.2 (defaults se `String?`).
- [ ] 4.2 Criar `lib/src/data/extensions/budget/budgets_response_extension.dart`:
  ```dart
  extension BudgetsResponseExtension on BudgetsResponse {
    BudgetsPageModel toPageModel() => BudgetsPageModel(
      nextCursor: _cursorFrom(next),
      previousCursor: _cursorFrom(previous),
      budgets: budgets.map((b) => b.toModel()).toList(),
    );

    String? _cursorFrom(String? url) =>
        url == null ? null : Uri.parse(url).queryParameters['cursor'];
  }
  ```
- [ ] 4.3 Estender `BudgetRepository` (`lib/src/data/repositories/budget_repository.dart`) com:
  ```dart
  @override
  Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor}) async {
    final data = await _dataSource.findAll(cursor: cursor);
    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toPageModel(),
    );
  }
  ```

## 5. Presentation — promover `BudgetCardWidget` para widget compartilhado

- [ ] 5.1 Mover **toda** a pasta `lib/src/presentation/ui/home/widgets/budget/card/` para `lib/src/presentation/widgets/budget/card/`. Arquivos:
  - `budget_card_widget.dart`
  - `budget_card_success_widget.dart`
  - `budget_card_loading_widget.dart`
  - `budget_card_failure_widget.dart`
  - `budget_card_empty_widget.dart`
  - `budget_card_label_widget.dart`
  - `budget_progress_bar_painter.dart`
- [ ] 5.2 Buscar e atualizar **todos** os imports antigos em todo o projeto:
  ```bash
  grep -r "presentation/ui/home/widgets/budget/card" lib test
  ```
  Substituir por `presentation/widgets/budget/card`.
- [ ] 5.3 Adicionar `final VoidCallback? onTap;` em `BudgetCardWidget`:
  - Construtor aceita `this.onTap`.
  - Repassa para `BudgetCardSuccessWidget(..., onTap: onTap)`.
- [ ] 5.4 Adicionar `final VoidCallback? onTap;` em `BudgetCardSuccessWidget`:
  - Quando `onTap != null`, envolver o body do card em `BounceWidget.withOnPress(onPress: onTap!, child: <body atual>)`.
  - Quando `null`, renderizar o body sem feedback.
- [ ] 5.5 Verificar que estados `loading`/`empty`/`failure` do `BudgetCardWidget` **não** propagam o `onTap` (apenas o success card é clicável).

## 6. Presentation — Home wiring

- [ ] 6.1 Adicionar `final VoidCallback navigateToBudgets;` em `HomeScreen` (`lib/src/presentation/ui/home/screens/home_screen.dart`), named, required.
- [ ] 6.2 Repassar como `onTap` na construção do `BudgetCardWidget` dentro da `HomeScreen`.
- [ ] 6.3 Atualizar `HomeLocation` (`lib/src/presentation/ui/home/locations/home_location.dart`):
  - Importar `BudgetsLocation` (única exceção autorizada — Locations compõem navegação).
  - Injetar `navigateToBudgets: () => context.navigate(BudgetsLocation())` na construção da `HomeScreen`.

## 7. Presentation — nova feature `budgets/`

### 7.1 State + view-model

- [ ] 7.1.1 Criar `lib/src/presentation/ui/budgets/data/budget_item_presentation_data.dart`:
  ```dart
  final class BudgetItemPresentationData extends Equatable {
    final BudgetModel budget;
    final String formattedValue;
    final String formattedTotalSpent;
    final String formattedRemaining;
    final String formattedPeriod;
    const BudgetItemPresentationData({...});
    @override List<Object?> get props => [budget, formattedValue, formattedTotalSpent, formattedRemaining, formattedPeriod];
  }
  ```
- [ ] 7.1.2 Criar `lib/src/presentation/ui/budgets/notifiers/budgets_state.dart`:
  ```dart
  final class BudgetsState extends Equatable {
    final BudgetItemPresentationData? activeItem;
    final List<BudgetItemPresentationData> items;
    final String? nextCursor;
    final bool isLoadingMore;
    final Failure? loadMoreFailure;
    const BudgetsState({this.activeItem, this.items = const [], this.nextCursor, this.isLoadingMore = false, this.loadMoreFailure});
    BudgetsState copyWith({BudgetItemPresentationData? activeItem, List<BudgetItemPresentationData>? items, String? nextCursor, bool? isLoadingMore, Failure? loadMoreFailure, bool clearActiveItem = false, bool clearNextCursor = false, bool clearLoadMoreFailure = false}) => ...;
    @override List<Object?> get props => [activeItem, items, nextCursor, isLoadingMore, loadMoreFailure];
  }
  ```
  As três flags `clearXxx` permitem que `null` no override realmente limpe o campo (padrão do projeto pra nullable em `copyWith`).

### 7.2 Notifier

- [ ] 7.2.1 Criar `lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart` como `@Riverpod(keepAlive: true)` `AsyncNotifier<BudgetsState>`:
  - Dependências em `late` (nunca `late final`): `_repository`, `_moneyService`.
  - `build()` async: chama `_repository.findAll(cursor: null)`, em sucesso retorna `BudgetsState(activeItem: _pickActive(page.budgets), items: page.budgets where !active map _toItem, nextCursor: page.nextCursor)`. Em falha, `throw failure` (vira `AsyncError`).
  - `Future<void> loadMore()`: guards (`state is AsyncData`, `!isLoadingMore`, `nextCursor != null`); seta `isLoadingMore: true, clearLoadMoreFailure: true`; chama `_repository.findAll(cursor: state.value.nextCursor)`; concatena items em sucesso; preserva items + registra `loadMoreFailure` em falha.
  - `_pickActive(List<BudgetModel> budgets)`: retorna o primeiro budget cujo `[startDate, endDate]` cobre `DateTime.now().millisecondsSinceEpoch`. Retorna `null` se nenhum cobre.
  - `_toItem(BudgetModel budget)`: constrói `BudgetItemPresentationData` formatando valores via `_moneyService.format(... / 100)` e período via `_formatPeriod(budget.startDate, budget.endDate)`.
  - `_formatPeriod(int startMs, int endMs)`: helper privado; `intl` `DateFormat('dd/MM', 'pt_BR')` quando ambos no ano corrente, `DateFormat('dd/MM/yy', 'pt_BR')` caso contrário; retorna `"$start – $end"`.
- [ ] 7.2.2 Não adicionar `applyFilter`, `searchChanged`, `removeFilter` — sem filtros nesta entrega.
- [ ] 7.2.3 Pull-to-refresh é responsabilidade da screen (`ref.invalidate(budgetsProvider)`) — **nunca** `ref.refresh`.

### 7.3 Widgets

- [ ] 7.3.1 `lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart` — `StatelessWidget` com Skeletonizer ou `CircularProgressIndicatorWidget` centralizado (espelhar `ExpensesLoadingWidget`).
- [ ] 7.3.2 `lib/src/presentation/ui/budgets/widgets/budgets_failure_widget.dart` — `StatelessWidget` aceitando `final VoidCallback onRetry;`. `BackgroundIconWidget(icon: Icons.error_outline, color: context.colors.error)` + `Text("Não foi possível carregar os orçamentos.", titleMedium bold)` + `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)`.
- [ ] 7.3.3 `lib/src/presentation/ui/budgets/widgets/budgets_empty_widget.dart` — `StatelessWidget`. `BackgroundIconWidget(icon: Icons.savings_outlined, color: context.colors.primary)` + `Text("Nenhum orçamento ainda", titleMedium bold)` + `Text("Quando você criar orçamentos eles aparecerão aqui.", bodySmall onSurfaceVariant)`. Sem CTA.
- [ ] 7.3.4 `lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart` — `StatelessWidget` recebendo `final BudgetItemPresentationData item;`. Card simples (sem progress bar) com:
  - Linha 1: `Text(item.budget.description, titleMedium)` + `Text(item.formattedPeriod, bodySmall onSurfaceVariant)` na direita.
  - Linha 2: rótulo "Valor" + `item.formattedValue`.
  - Linha 3: rótulo "Gasto" + `item.formattedTotalSpent`.
  - Linha 4: rótulo "Saldo" + `item.formattedRemaining` (cor vermelha quando `item.budget.remaining < 0`).
  - Padding e tipografia coerentes com `ExpenseItemWidget`.
- [ ] 7.3.5 `lib/src/presentation/ui/budgets/widgets/budgets_load_more_loading_widget.dart` — `StatelessWidget` centralizando `CircularProgressIndicatorWidget` com padding vertical 16.
- [ ] 7.3.6 `lib/src/presentation/ui/budgets/widgets/budgets_load_more_failure_widget.dart` — `StatelessWidget` aceitando `final VoidCallback onRetry;`. `Text("Não foi possível carregar mais orçamentos.", bodySmall onSurfaceVariant)` + `ButtonWidget.text(label: "Tentar novamente", onTap: onRetry)`. Padding vertical 16.
- [ ] 7.3.7 `lib/src/presentation/ui/budgets/widgets/budgets_list_widget.dart` — `StatelessWidget` recebendo `final BudgetsState state;` e `final VoidCallback onLoadMore;`:
  - `SliverMainAxisGroup` com:
    - `SliverList.builder(itemCount: state.items.length, itemBuilder: (_, i) => BudgetListItemWidget(item: state.items[i]))` usando `ValueKey(state.items[i].budget.id)`.
    - `SliverToBoxAdapter` com tail dinâmico:
      - `state.isLoadingMore` → `BudgetsLoadMoreLoadingWidget()`.
      - `state.loadMoreFailure != null` → `BudgetsLoadMoreFailureWidget(onRetry: onLoadMore)`.
      - else → `SizedBox.shrink()`.

### 7.4 Screen

- [ ] 7.4.1 Criar `lib/src/presentation/ui/budgets/screens/budgets_screen.dart` como `StatefulWidget`:
  - Estado interno cria `ScrollController` em `initState`, registra listener `_onScroll`, dispõe em `dispose`.
  - `_onScroll`: se `position.pixels >= position.maxScrollExtent - 200`, chama `ref.read(budgetsProvider.notifier).loadMore()`.
  - `build`: `Scaffold` com `AppBar` (título "Orçamentos", `GoBackWidget` como leading), `body: SafeArea(Consumer(builder: (_, ref, _) {...}))`.
  - Dentro do `Consumer`, `final state = ref.watch(budgetsProvider);` e switch expression sobre `state`:
    - `AsyncLoading()` → `BudgetsLoadingWidget()`
    - `AsyncError()` → `BudgetsFailureWidget(onRetry: () => ref.invalidate(budgetsProvider))`
    - `AsyncData(value: BudgetsState(activeItem: null, items: empty))` → `BudgetsEmptyWidget()`
    - `AsyncData(:final value)` → `RefreshIndicator(onRefresh: () async => ref.invalidate(budgetsProvider), child: CustomScrollView(controller: _scrollController, slivers: [...]))`.
  - Slivers no caso success: `SliverToBoxAdapter` com active card (`BudgetCardWidget` configurado para receber o active) **se** `value.activeItem != null`; depois `BudgetsListWidget(state: value, onLoadMore: () => ref.read(budgetsProvider.notifier).loadMore())`.
  - **Nunca** `ConsumerWidget`.

### 7.5 Location

- [ ] 7.5.1 Criar `lib/src/presentation/ui/budgets/locations/budgets_location.dart`:
  ```dart
  final class BudgetsLocation extends Location {
    @override String get path => AppRoutes.budgets.path;
    @override LocationPageBuilder get pageBuilder => (_) => screenPage(const BudgetsScreen());
  }
  ```
  Sem callbacks (lista não navega para detalhe).

### 7.6 Composição do active card

- [ ] 7.6.1 Decidir como o `BudgetCardWidget` recebe os dados do `activeItem`:
  - Opção A: o `BudgetCardWidget` continua aceitando `AsyncValue<BudgetCardPresentationData?>` como hoje, e a `BudgetsScreen` constrói esse `AsyncData` localmente a partir de `value.activeItem`.
  - Opção B: refatorar `BudgetCardSuccessWidget` para aceitar diretamente um `BudgetCardPresentationData` e usar isso como API "limpa" para casos não-async (a tela aqui não precisa de loading separado pro active — o estado já é do `BudgetsState`).
  - **Default**: Opção A (mais conservador, sem mudar API do widget compartilhado).
- [ ] 7.6.2 Construir o `BudgetCardPresentationData` necessário a partir do `BudgetItemPresentationData` + `BudgetModel.totalSpent`/`remaining`/`endDate` (todos campos já disponíveis após task 2.1). Verificar a definição atual de `BudgetCardPresentationData` e completar campos faltantes em `_toCardData(BudgetModel)` dentro do `BudgetsNotifier` se necessário.

## 8. Main — rota

- [ ] 8.1 Adicionar em `lib/app_route.dart`:
  ```dart
  static final budgets = AppRoutes._(
    path: '/budgets',
    name: 'budgets-route',
    regex: RegExp(r'^/budgets$'),
  );
  ```
  Incluir em `_all`.

## 9. Code generation

- [ ] 9.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para gerar `budgets_notifier.g.dart`.

## 10. Testes

### 10.1 Response — `test/src/infrastructure/responses/budget/budgets_response_test.dart` (novo)

- [ ] 10.1.1 `test('fromJson maps next, previous and results when all present')`.
- [ ] 10.1.2 `test('fromJson maps next and previous to null when JSON has null values')`.
- [ ] 10.1.3 `test('fromJson returns empty budgets when results is empty')`.

### 10.2 Response (cobertura adicional) — `test/src/infrastructure/responses/budget/budget_response_test.dart` (estender)

- [ ] 10.2.1 `test('fromJson maps total_spent, remaining and created_at as raw strings')`.
- [ ] 10.2.2 `test('fromJson handles negative remaining string')`.
- [ ] 10.2.3 (Se nullable) `test('fromJson maps total_spent, remaining and created_at to null when absent')`.

### 10.3 Repository — `test/src/data/repositories/budget_repository_test.dart` (estender)

Mock em `IHttpClient` (espelhar padrão de `expense_repository_test.dart`):

- [ ] 10.3.1 `test('findAll without cursor calls GET on EndpointKey.budgets.path with no query')`.
- [ ] 10.3.2 `test('findAll with cursor "ABC" calls GET with query {cursor: "ABC"}')`.
- [ ] 10.3.3 `test('findAll returns Right(BudgetsPageModel) with extracted nextCursor on success')`.
- [ ] 10.3.4 `test('findAll returns Right with nextCursor null when next is null')`.
- [ ] 10.3.5 `test('findAll returns Right with nextCursor extracted even when URL has multiple query params')`.
- [ ] 10.3.6 `test('findAll maps value, totalSpent, remaining to centavos including negative remaining')`.
- [ ] 10.3.7 `test('findAll maps startDate, endDate to ms epoch from yyyy-MM-dd')`.
- [ ] 10.3.8 `test('findAll maps createdAt to ms epoch from ISO 8601 with timezone')`.
- [ ] 10.3.9 `test('findAll returns Left(NetworkFailure) when error code is "network_error"')`.
- [ ] 10.3.10 `test('findAll returns Left(ServerFailure) when error code is "server_error"')`.
- [ ] 10.3.11 `test('findAll returns Left(ValidationFailure) with message for unknown error code')`.
- [ ] 10.3.12 Manter testes existentes de `findActive` e `create` passando sem alteração.

### 10.4 Notifier — `test/src/presentation/providers/budgets_notifier_test.dart` (novo)

`ProviderContainer` com overrides de `budgetRepositoryProvider` (mock `IBudgetRepository`) e `moneyServiceProvider` (mock `IMoneyService`):

- [ ] 10.4.1 `test('build loads first page and selects activeItem when a budget covers today')`.
- [ ] 10.4.2 `test('build excludes the active budget from items list')`.
- [ ] 10.4.3 `test('build sets activeItem to null when no budget covers today')`.
- [ ] 10.4.4 `test('build transitions to AsyncError when repository returns Left')`.
- [ ] 10.4.5 `test('loadMore appends new items preserving existing items and active')`.
- [ ] 10.4.6 `test('loadMore updates nextCursor on success')`.
- [ ] 10.4.7 `test('loadMore is a no-op when nextCursor is null (verifyNever on repository)')`.
- [ ] 10.4.8 `test('loadMore is a no-op when isLoadingMore is true (verifyNever on repository)')`.
- [ ] 10.4.9 `test('loadMore on failure preserves items, sets loadMoreFailure, clears isLoadingMore')`.
- [ ] 10.4.10 `test('loadMore retry after failure clears loadMoreFailure on success')`.
- [ ] 10.4.11 `test('item view-model exposes formattedValue, formattedTotalSpent, formattedRemaining via IMoneyService.format')`.
- [ ] 10.4.12 `test('item view-model exposes formattedPeriod with same-year format dd/MM – dd/MM')`.
- [ ] 10.4.13 `test('item view-model exposes formattedPeriod with cross-year format dd/MM/yy – dd/MM/yy')`.

### 10.5 Mocks — `test/mocks/mocks.dart`

- [ ] 10.5.1 Verificar que `MockBudgetRepository`, `MockMoneyService` e `MockHttpClient` já existem (provavelmente sim). Adicionar o que faltar.
- [ ] 10.5.2 **Não** criar `MockRemoteBudgetDataSource` separado — repository é testado mockando `IHttpClient` (consistente com `expense_repository_test.dart`).

### 10.6 Convenções

- [ ] 10.6.1 Descrições de `test()`, `group()`, `testWidgets()` em **inglês**.
- [ ] 10.6.2 Mocks declarados pelo tipo da interface: `late IBudgetRepository repository;` (nunca `late MockBudgetRepository`).
- [ ] 10.6.3 Variável de retorno de `Future`/`Either` nomeada `data` ou `state` (nunca `result`/`either`).
- [ ] 10.6.4 Sem `var` — `final` com tipo inferido ou tipo explícito.

## 11. Verificação

- [ ] 11.1 `flutter analyze` — zero warnings.
- [ ] 11.2 `flutter test` — toda a suite passa (incluindo regressões em `home_screen_test`, `expense_repository_test`, etc.).
- [ ] 11.3 **Smoke manual — fluxo Home (regressão)**: abrir Home, verificar que o card de orçamento ativo continua renderizando idêntico, e que estados loading/empty/failure do card seguem funcionando. Tap no card faz a tela de listagem abrir.
- [ ] 11.4 **Smoke manual — listagem (happy path)**: na nova tela, ver active card no topo (se houver budget ativo) + lista cronológica desc abaixo. Scroll até o fim → load-more loading aparece → mais itens chegam → cursor avança. Continuar até `nextCursor == null` → tail vira `SizedBox.shrink`.
- [ ] 11.5 **Smoke manual — pull-to-refresh**: puxar para baixo no topo da lista → `RefreshIndicator` gira → primeira página recarrega; lista volta ao estado inicial (cursor reset).
- [ ] 11.6 **Smoke manual — empty**: usuário sem nenhum budget → `BudgetsEmptyWidget` aparece sem CTA.
- [ ] 11.7 **Smoke manual — failure inicial**: simular erro de rede na primeira chamada → `BudgetsFailureWidget` aparece com botão "Tentar novamente"; tap reinicia o fluxo.
- [ ] 11.8 **Smoke manual — failure de load-more**: simular erro de rede na 2ª página → lista permanece intacta, tail mostra `BudgetsLoadMoreFailureWidget`; tap em "Tentar novamente" retoma o load-more.
- [ ] 11.9 **Smoke manual — sem budget ativo hoje**: garantir que a tela ainda renderiza a lista normalmente (sem active card no topo) e que nada quebra.
- [ ] 11.10 Rodar `arch-review` para validar que a `budgets/` é autocontida (sem importar nada de outras features), que a promoção do `BudgetCardWidget` não deixou imports antigos, e que `BudgetsScreen` é `StatefulWidget` (não `ConsumerWidget`) com `Consumer` interno.
