<task>Implementar a tela de listagem paginada de Budgets (cursor-based) espelhando o fluxo já existente de Expenses</task>

<goals>
    Entregar a feature de listagem de orçamentos com o budget ativo destacado no topo, lista infinita cursor-based para os demais, swipe-to-refresh e estados completos de loading/erro/empty — consumindo `GET /api/v1/budgets` via Repository → DataSource → Dio, e tornando o card de budget na Home o entry point de navegação.
</goals>

<role>
    Você é um engenheiro Flutter senior trabalhando no app **Trocado** (controle financeiro para casais).
    Stack: Flutter, Dart, Riverpod (`@Riverpod` codegen, MVI com `dispatch` quando há intents), Dio, duck_router, equatable, intl, Clean Architecture estrita (`domain/`, `data/`, `infrastructure/`, `presentation/`, `main/`) **sem** `use_cases/`.
    Contexto da feature: hoje a Home exibe um `BudgetCardWidget` com o orçamento ativo (lendo `IBudgetRepository.findActive`). Não existe tela de listagem de budgets — apenas a tela de criação (`BudgetLocation` singular). Sua tarefa é construir essa listagem reproduzindo o padrão consolidado de `ExpensesNotifier` / `ExpensesScreen` / `ExpensesPageModel` (cursor-based pagination, scroll infinito, view-models pré-formatados pelo notifier), promovendo o `BudgetCardWidget` para widget compartilhado e adicionando `onTap` para abrir a nova tela.
</role>

---

<requirements>
    ### Business

    - Ao tocar no card de budget na Home, abrir a nova tela **Orçamentos**.
    - O orçamento atualmente vigente (em que `DateTime.now()` está dentro de `[startDate, endDate]`) é exibido em destaque no topo, usando o mesmo `BudgetCardWidget` rico já mostrado na Home (progress bar + remaining + total spent + end date).
    - Abaixo, lista paginada **infinita** dos demais budgets (passados e futuros), ordenados conforme a API (já vem por `created_at` desc).
    - Cada item da lista mostra: descrição, período (`startDate – endDate`), valor planejado, total gasto e saldo restante — todos formatados em `pt_BR`.
    - Se não houver orçamento ativo, exibir apenas a lista (sem destaque no topo). Se não houver nenhum budget, exibir empty state.
    - Esta entrega **não** inclui criar, editar, deletar, filtrar nem buscar — só listagem.

    ### Technical

    - **Camadas afetadas:** `domain/`, `data/`, `infrastructure/`, `presentation/`, `main/`. Tudo respeitando a regra de dependência (`domain` puro Dart; `data` ← `domain` + interfaces de `infrastructure`; `presentation` ← `domain`).
    - **Fluxo padrão:** `BudgetsNotifier` → `IBudgetRepository.findAll(cursor?)` → `IRemoteBudgetDataSource.findAll(cursor?)` → `IHttpClient` (Dio). Sem `use_cases`.
    - **Domain — estender:**
        - `BudgetModel` ganha `int totalSpent` (centavos) e `int remaining` (centavos, pode ser negativo) e `int createdAt` (ms epoch). `copyWith` atualizado, `props` atualizado.
        - `IBudgetRepository` ganha `Future<Either<Failure, BudgetsPageModel>> findAll({String? cursor})`. Mantém `findActive`/`create` intactos.
    - **Domain — criar:**
        - `BudgetsPageModel extends Equatable` com `String? nextCursor`, `String? previousCursor`, `List<BudgetModel> budgets`. `copyWith` + `props`. **NÃO** criar wrapper genérico `PaginatedResponse<T>` — espelhar `ExpensesPageModel` literalmente.
    - **Infrastructure — estender:**
        - `BudgetResponse.fromJson` mapeia `total_spent`, `remaining`, `created_at` (mantém `id`, `value`, `start_date`, `end_date`, `description`).
        - `IRemoteBudgetDataSource` ganha `Future<Either<FailureResponse, BudgetsResponse>> findAll({String? cursor})`. Implementação concreta monta o path `${EndpointKey.budgets.path}?cursor=$cursor` quando `cursor != null`. Interface aceita parâmetro de domínio (`String?`), nunca DTO.
        - `EndpointKey.budgets` já existe (`/api/v1/budgets`) — reutilizar.
    - **Infrastructure — criar:**
        - `BudgetsResponse` com `String? next`, `String? previous`, `List<BudgetResponse> budgets`. Apenas `fromJson` — **nunca** `toModel()` na response.
    - **Data — estender:**
        - `BudgetRepository.findAll` chama o datasource e usa `data.either(FailureResponseExtension.toFailure, BudgetsResponseExtension.toPageModel)`.
        - `BudgetResponseExtension.toModel()` mapeia novos campos: `value/totalSpent/remaining` via `(double.parse(...) * 100).round()`; `createdAt` via `DateTime.parse(...).millisecondsSinceEpoch`; `startDate/endDate` via `DateFormat('yyyy-MM-dd').parse(...).millisecondsSinceEpoch`.
    - **Data — criar:**
        - `BudgetsResponseExtension on BudgetsResponse` com `toPageModel()` e helper privado `String? _cursorFrom(String? url) => url == null ? null : Uri.parse(url).queryParameters['cursor']` (espelhar `ExpensesResponseExtension`).
    - **Presentation — criar pasta `lib/src/presentation/ui/budgets/` (plural)** com:
        - `notifiers/budgets_notifier.dart` — `@Riverpod(keepAlive: true)` `AsyncNotifier<BudgetsState>`. `build()` async carrega primeira página. Métodos públicos: `Future<void> loadMore()`, `Future<void> refresh()`. Sem `applyFilter` (sem filtros nesta entrega). Dependências em `late` (não `late final`): `_moneyService`, `_dateFormatter` (ver "Decisões de design" abaixo), `_repository`. View-models construídos em `_toItem(BudgetModel)`. O active é selecionado em `_pickActive(List<BudgetModel>, DateTime now)`.
        - `notifiers/budgets_state.dart` — `final class BudgetsState extends Equatable` com:
            - `String? nextCursor`
            - `bool isLoadingMore`
            - `Failure? loadMoreFailure`
            - `BudgetItemPresentationData? activeItem`
            - `List<BudgetItemPresentationData> items` (lista dos não-ativos, acumulativa)
            - `copyWith` com flags `clearNextCursor`, `clearLoadMoreFailure`, `clearActiveItem`.
        - `screens/budgets_screen.dart` — `StatelessWidget` que usa `Consumer` interno (NUNCA `ConsumerWidget`). É na verdade um `StatefulWidget` para controlar `ScrollController` (espelhar `ExpensesScreen`). `AppBar` com título "Orçamentos". `RefreshIndicator` envolvendo `CustomScrollView` com `Slivers`: header opcional + `SliverToBoxAdapter` com active card (se houver) + `BudgetsListWidget` (sliver com itens da lista) + tail de load-more. Switch expression sobre `AsyncValue<BudgetsState>` para escolher entre `BudgetsLoadingWidget`, `BudgetsFailureWidget`, `BudgetsEmptyWidget`, conteúdo. Scroll listener dispara `notifier.loadMore()` quando `pixels >= maxScrollExtent - 200`.
        - `locations/budgets_location.dart` — `final class BudgetsLocation extends Location` com `path` apontando para `AppRoutes.budgets.path` e `LocationPageBuilder` montando `BudgetsScreen()`. Sem callbacks nesta entrega (lista não navega para detalhe).
        - `widgets/budgets_list_widget.dart` — `StatelessWidget` recebendo `BudgetsState` + `VoidCallback onLoadMore`. `SliverMainAxisGroup` com `SliverList.builder` dos `items` (renderizando `BudgetListItemWidget`) + `SliverToBoxAdapter` com tail (loading/failure).
        - `widgets/budget_list_item_widget.dart` — `StatelessWidget` recebendo `BudgetItemPresentationData`. Card simples (sem progress bar) com descrição, período, valor, total gasto, saldo. **NÃO** privado dentro de outro arquivo.
        - `widgets/budgets_loading_widget.dart`, `widgets/budgets_failure_widget.dart` (com `onRetry`), `widgets/budgets_empty_widget.dart`, `widgets/budgets_load_more_loading_widget.dart`, `widgets/budgets_load_more_failure_widget.dart` (com `onRetry`).
        - `data/budget_item_presentation_data.dart` — `final class BudgetItemPresentationData extends Equatable` com `BudgetModel budget`, `String formattedValue`, `String formattedTotalSpent`, `String formattedRemaining`, `String formattedPeriod` (ex: `"01/05 – 30/05"`). Nome do arquivo `_presentation_data.dart`, classe sufixada com `PresentationData`. Vive **dentro da feature** (`presentation/ui/budgets/data/`) por enquanto — promover para `presentation/data/budget/` apenas se vier a ser consumido por outra feature.
    - **Presentation — promover widget compartilhado:**
        - Mover `lib/src/presentation/ui/home/widgets/budget/card/` (todos os arquivos: `budget_card_widget.dart`, `budget_card_success_widget.dart`, `budget_card_loading_widget.dart`, `budget_card_failure_widget.dart`, `budget_card_empty_widget.dart`, `budget_card_label_widget.dart`, `budget_progress_bar_painter.dart`) para `lib/src/presentation/widgets/budget/card/`. Atualizar **todos** os imports (`HomeScreen` e qualquer preview/teste). Após mover, adicionar parâmetro `VoidCallback? onTap` em `BudgetCardWidget` e `BudgetCardSuccessWidget` (envolvendo o card em `BounceWidget.withOnPress` quando `onTap != null` — verificar widget de bounce já usado no projeto).
    - **Presentation — estender Home:**
        - `HomeScreen` ganha prop `final VoidCallback navigateToBudgets`. Repassa para o `BudgetCardWidget` como `onTap`.
        - `HomeLocation` injeta `navigateToBudgets: () => context.navigate(BudgetsLocation())` na construção do `HomeScreen` (esta é a única feature autorizada a importar `BudgetsLocation` — exceção narrada de Locations compondo navegação).
    - **Main — estender:**
        - `AppRoutes` ganha `budgets('/budgets')` em `app_route.dart`.
        - Provider de repository (`budgetRepositoryProvider`) já existe — reutilizar. Não criar provider novo.
    - **Imutabilidade & nomenclatura:** `BudgetsResponse`, `BudgetsPageModel`, `BudgetsNotifier`, `BudgetsState`, `BudgetsScreen`, `BudgetsLocation`, `BudgetItemPresentationData`. Arquivos em `snake_case`.
    - **Datas:** ms epoch no domínio; conversão exclusivamente no `BudgetResponseExtension.toModel()`.
    - **Moeda:** `int` em centavos no `BudgetModel`; formatação só via `IMoneyService` injetado no `BudgetsNotifier`.
    - **Decisões de design fixas (não revisitar):**
        1. Active selecionado client-side por intervalo de datas (não usa `findActive` na listagem — evita 2ª chamada).
        2. Active **não** é removido do `items` quando aparece em `activeItem` — para evitar duplicação visual, o `_pickActive` já o exclui de `items`. (Implementar essa exclusão no notifier.)
        3. Período formatado como `"dd/MM – dd/MM"` quando ano de start == ano de end == ano corrente; senão `"dd/MM/yy – dd/MM/yy"`. Helper privado no notifier (não criar service novo).

    ### UI/UX

    - **Loading inicial** (sem dados ainda): `BudgetsLoadingWidget` ocupando o sliver — espelhar visual de `ExpensesLoadingWidget` (skeleton ou progress).
    - **Erro inicial**: `BudgetsFailureWidget` com mensagem do `Failure` + botão "Tentar novamente" que chama `notifier.refresh()`.
    - **Empty**: `BudgetsEmptyWidget` com ilustração/copy "Nenhum orçamento ainda" — espelhar tom de `ExpensesEmptyWidget`. **NÃO** incluir CTA "criar" nesta entrega (escopo é só listagem).
    - **Sucesso**:
        - Active card no topo (se houver), idêntico ao da Home.
        - Lista de items abaixo (fora do active).
        - Tail: `BudgetsLoadMoreLoadingWidget` enquanto `isLoadingMore`; `BudgetsLoadMoreFailureWidget` com "Tentar novamente" quando `loadMoreFailure != null`; `SizedBox.shrink()` quando `nextCursor == null` (fim da lista).
    - **Swipe-to-refresh** em todos os estados (incluso loading/empty/erro) — `RefreshIndicator` chama `notifier.refresh()`, que recarrega a primeira página.
    - **Scroll infinito**: `ScrollController` listener em `_onScroll`; threshold de `200.0` antes de `maxScrollExtent`; chama `notifier.loadMore()` (notifier é responsável pelos guards `isLoadingMore` e `nextCursor != null`).
    - **Tap no card da Home**: feedback de bounce (mesmo `BounceWidget.withOnPress` já usado em itens de expense).
    - **Acessibilidade**: manter contraste e tamanhos do design system existente; nada de cores hardcoded — usar `context.colors.*`.

</requirements>

---

<context-tools>
    ### Skills relevantes

    - `sdd` — **OBRIGATÓRIA**: criar a spec aprovada antes de qualquer linha de código (este `spec.md` é o input).
    - `notifier` — estrutura do `BudgetsNotifier` (AsyncNotifier com `build` async + `loadMore` + `refresh`).
    - `new-feature` — checklist de criação de feature nova (pasta `presentation/ui/budgets/`).
    - `new-test` — padrões de teste de Notifier (ProviderContainer + mock em `IBudgetRepository`) e de Repository (mock em `IRemoteBudgetDataSource`).
    - `arch-review` — validar Clean Architecture e SOLID após implementação (sem usar `var`, switch expression em todo lugar, sem `ConsumerWidget`, services não lidos na screen, encapsulamento entre features).

    ### MCPs disponíveis

    - `context7` — verificar API atual de Riverpod (`AsyncNotifier`, `keepAlive`) e Dio antes de usar.
    - `octocode` — referência cruzada com a feature Expenses já implementada (`localSearchCode` por `ExpensesNotifier`, `ExpensesPageModel`, `_cursorFrom`).

</context-tools>

---

<workflow>
    1. Ler `spec.md` (este arquivo) e abrir os arquivos-espelho de Expenses como referência viva: `expenses_notifier.dart`, `expenses_state.dart`, `expenses_screen.dart`, `expenses_list_widget.dart`, `expense_item_presentation_data.dart`, `expense_response_extension.dart` (helper `_cursorFrom`), `expenses_response.dart`.
    2. **Domain**:
       a. Estender `BudgetModel` com `totalSpent`, `remaining`, `createdAt` (atualizar `copyWith` e `props`).
       b. Criar `domain/models/budget/budgets_page_model.dart`.
       c. Estender `IBudgetRepository` com `findAll({String? cursor})`.
    3. **Infrastructure**:
       a. Estender `BudgetResponse.fromJson` com os novos campos.
       b. Criar `infrastructure/clients/http/responses/budget/budgets_response.dart` (apenas `fromJson`).
       c. Estender `IRemoteBudgetDataSource` e `RemoteBudgetDataSource` com `findAll({String? cursor})` montando o path com query param.
    4. **Data**:
       a. Atualizar `data/extensions/budget/budget_response_extension.dart` com mapping dos novos campos.
       b. Criar `data/extensions/budget/budgets_response_extension.dart` com `toPageModel()` + `_cursorFrom()` privado.
       c. Estender `BudgetRepository.findAll` mapeando `Either<FailureResponse, BudgetsResponse>` → `Either<Failure, BudgetsPageModel>`.
    5. **Presentation — promover widget compartilhado**:
       a. Mover toda a pasta `home/widgets/budget/card/` para `presentation/widgets/budget/card/`.
       b. Adicionar `VoidCallback? onTap` em `BudgetCardWidget` e `BudgetCardSuccessWidget`.
       c. Atualizar imports em `HomeScreen` e em qualquer arquivo de preview/teste.
    6. **Presentation — Home**:
       a. Adicionar `VoidCallback navigateToBudgets` em `HomeScreen` (named, required).
       b. Repassar como `onTap` do `BudgetCardWidget`.
       c. `HomeLocation` injeta `navigateToBudgets: () => context.navigate(BudgetsLocation())`.
    7. **Presentation — feature Budgets**:
       a. `BudgetsState` + `copyWith` com `clearXxx`.
       b. `BudgetsNotifier` (`build` async carrega 1ª página + seleciona active; `loadMore` com guards; `refresh` invalida + recarrega).
       c. `BudgetItemPresentationData`.
       d. Widgets (lista, item, loading, failure, empty, load-more loading, load-more failure).
       e. `BudgetsScreen` (Stateful para ScrollController; Consumer interno; switch expression sobre AsyncValue).
       f. `BudgetsLocation`.
    8. **Main**:
       a. `AppRoutes.budgets('/budgets')`.
    9. **Codegen**: `dart run build_runner build --delete-conflicting-outputs`.
    10. **Mocks**:
       a. Adicionar `MockRemoteBudgetDataSource` em `test/mocks/mocks.dart` (reutilizar `MockBudgetRepository` e `MockMoneyService` existentes).
    11. **Testes** (ver bloco `<tests>`).
    12. **Verificação**: `flutter analyze` (zero issues), `flutter test` (verde), smoke manual no simulador (tap na Home → tela de listagem com active no topo e scroll infinito funcionando + swipe-to-refresh).

</workflow>

<output>
    Arquivos **criados**:
    - `lib/src/domain/models/budget/budgets_page_model.dart`
    - `lib/src/infrastructure/clients/http/responses/budget/budgets_response.dart`
    - `lib/src/data/extensions/budget/budgets_response_extension.dart`
    - `lib/src/presentation/ui/budgets/notifiers/budgets_notifier.dart`
    - `lib/src/presentation/ui/budgets/notifiers/budgets_state.dart`
    - `lib/src/presentation/ui/budgets/screens/budgets_screen.dart`
    - `lib/src/presentation/ui/budgets/locations/budgets_location.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_list_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_loading_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_failure_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_empty_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_load_more_loading_widget.dart`
    - `lib/src/presentation/ui/budgets/widgets/budgets_load_more_failure_widget.dart`
    - `lib/src/presentation/ui/budgets/data/budget_item_presentation_data.dart`
    - `test/src/infrastructure/responses/budget/budgets_response_test.dart`
    - `test/src/data/extensions/budget/budgets_response_extension_test.dart` (cursor parsing + mapping)
    - `test/src/presentation/providers/budgets_notifier_test.dart`

    Arquivos **modificados**:
    - `lib/src/domain/models/budget/budget_model.dart` (+`totalSpent`, +`remaining`, +`createdAt`)
    - `lib/src/domain/repositories/interface_budget_repository.dart` (+`findAll`)
    - `lib/src/infrastructure/clients/http/responses/budget/budget_response.dart` (+`totalSpent`, +`remaining`, +`createdAt`)
    - `lib/src/infrastructure/datasources/remote/remote_budget_data_source.dart` (+`findAll`)
    - `lib/src/data/repositories/budget_repository.dart` (+`findAll`)
    - `lib/src/data/extensions/budget/budget_response_extension.dart` (mapping dos novos campos)
    - `lib/src/presentation/ui/home/screens/home_screen.dart` (+prop `navigateToBudgets`)
    - `lib/src/presentation/ui/home/locations/home_location.dart` (injeta callback `navigateToBudgets`)
    - `lib/app_route.dart` (+`AppRoutes.budgets`)
    - `test/mocks/mocks.dart` (+`MockRemoteBudgetDataSource`)
    - `test/src/infrastructure/responses/budget/budget_response_test.dart` (cobre novos campos)
    - `test/src/data/repositories/budget_repository_test.dart` (cobre `findAll`)

    Arquivos **movidos** (com imports atualizados em todo o projeto):
    - `lib/src/presentation/ui/home/widgets/budget/card/*` → `lib/src/presentation/widgets/budget/card/*` (todos os arquivos da pasta)

</output>

---

<endpoints>
    ### Listar budgets (cursor-based)

    - **URL:** `GET /api/v1/budgets`
    - **Auth:** `Authorization: Bearer <access_token>`
    - **Query params:** `cursor` (opcional, opaco, vindo do campo `next` da resposta anterior — o app extrai via `Uri.parse(next).queryParameters['cursor']`)
    - **Status codes:** 200 OK, 401 Unauthorized, 500 Server Error
    - **Resposta sucesso (`200`):**
        ```json
        {
          "next": "http://api.example.org/budgets/?cursor=cD00ODY%3D",
          "previous": "http://api.example.org/budgets/?cursor=cj0xJnA9NDg3",
          "results": [
            {
              "id": 9,
              "value": "1000.00",
              "start_date": "2026-05-01",
              "end_date": "2026-05-30",
              "description": "May budget",
              "total_spent": "285.50",
              "remaining": "714.50",
              "created_at": "2026-05-02T17:58:42.119430-03:00"
            }
          ]
        }
        ```
    - **Resposta erro:** formato padrão `FailureResponse`:
        ```json
        { "errors": [{ "field": "string", "message": "string", "code": "string" }] }
        ```
    - **Mapping:**
        - `value`, `total_spent`, `remaining`: String decimal → `int` centavos via `(double.parse(x) * 100).round()` (suporta valor negativo em `remaining`).
        - `start_date`, `end_date`: `"yyyy-MM-dd"` → `int` ms epoch via `DateFormat('yyyy-MM-dd').parse(x).millisecondsSinceEpoch`.
        - `created_at`: ISO 8601 com timezone → `int` ms epoch via `DateTime.parse(x).millisecondsSinceEpoch`.
        - `next`/`previous`: extrair apenas o valor de `cursor` via `Uri.parse(url).queryParameters['cursor']`.

</endpoints>

<tests>
    ### `BudgetsResponse.fromJson` (Dart puro)

    - JSON com `next`, `previous` e `results` válidos → mapeia 3 campos corretamente.
    - JSON com `next: null` e `previous: null` → mapeia para `null`.
    - JSON com `results: []` → lista vazia.

    ### `BudgetResponse.fromJson` (Dart puro — cobertura adicional)

    - JSON com `total_spent`, `remaining` e `created_at` → mapeados como `String` (deserialização crua).

    ### `BudgetsResponseExtension` (Dart puro)

    - `toPageModel()` extrai `cursor` de `next` quando URL contém `?cursor=ABC` → `nextCursor == 'ABC'`.
    - `toPageModel()` retorna `nextCursor == null` quando `next == null`.
    - `toPageModel()` extrai cursor mesmo quando há outros query params (`?cursor=ABC&ordering=desc`).
    - `toPageModel()` mapeia cada `BudgetResponse` para `BudgetModel` com `value/totalSpent/remaining` em centavos e datas em ms epoch.
    - `toPageModel()` lida com `remaining` negativo (ex: `"-1734.97"` → `-173497`).

    ### `BudgetRepository.findAll` (mock em `IRemoteBudgetDataSource`)

    - Sucesso com `cursor: null` → `Right(BudgetsPageModel)` com `nextCursor` extraído.
    - Sucesso com `cursor: 'ABC'` → datasource é chamado com `cursor: 'ABC'`.
    - Falha do datasource → `Left(Failure)` mapeada via `FailureResponseExtension.toFailure`.

    ### `BudgetsNotifier` (ProviderContainer + mock em `IBudgetRepository` + `IMoneyService`)

    - `build()` carrega primeira página (cursor null), seleciona `activeItem` quando há budget no intervalo, exclui o active de `items`, salva `nextCursor`.
    - `build()` define `activeItem == null` quando nenhum budget cobre `DateTime.now()`.
    - `loadMore()` concatena novos items preservando os existentes; atualiza `nextCursor` e zera `isLoadingMore`.
    - `loadMore()` é no-op quando `nextCursor == null` (não chama o repository).
    - `loadMore()` é no-op quando `isLoadingMore == true` (não chama o repository duas vezes).
    - `loadMore()` em erro: preserva `items` e `activeItem`, registra `loadMoreFailure`, zera `isLoadingMore`.
    - `refresh()` recarrega a primeira página, substituindo state (recompondo active e items).
    - View-models de `items` têm `formattedValue`, `formattedTotalSpent`, `formattedRemaining` produzidos por `IMoneyService.format`.

    ### Estratégias de mock (referência ao padrão do projeto)

    - Notifier: `ProviderContainer` com overrides de `budgetRepositoryProvider` (mock `IBudgetRepository`) e `moneyServiceProvider` (mock `IMoneyService`).
    - Repository: mock em `IRemoteBudgetDataSource` (não `IHttpClient` aqui — espelha o padrão de `ExpenseRepository` tests; verificar e seguir o que estiver lá).
    - Mocks declarados com tipo da interface: `late IBudgetRepository repository;`, nunca `late MockBudgetRepository`.
    - Descrições de teste em **inglês**.

</tests>

---

<critical>
    ### Skills obrigatórias

    - `sdd` — **OBRIGATÓRIA**: este `spec.md` precisa ser aprovado antes de qualquer implementação.
    - `notifier` — para `BudgetsNotifier` (AsyncNotifier com `build` async + `loadMore` + `refresh`).
    - `new-feature` — checklist da nova feature `presentation/ui/budgets/`.
    - `new-test` — padrões de testes de Notifier e Repository.
    - `arch-review` — varredura final pós-implementação (Clean Architecture, SOLID, regras do `CLAUDE.md`).

    ### Fora do Escopo

    - *NÃO* implementar criar / editar / deletar budget — `BudgetLocation` (singular) e o fluxo de criação ficam **intocados**.
    - *NÃO* implementar filtros, busca ou ordenação na listagem — entregar apenas paginação cursor-based.
    - *NÃO* remover `ActiveBudgetModel` nem `ActiveBudgetNotifier` — eles continuam alimentando o card da Home (a deduplicação fica para refactor futuro).
    - *NÃO* criar wrapper genérico `PaginatedResponse<T>` / `Page<T>` — replicar o padrão concreto de `ExpensesResponse` / `ExpensesPageModel` com `BudgetsResponse` / `BudgetsPageModel`.
    - *NÃO* criar `use_cases/` — fluxo é `Notifier → Repository → DataSource → Client` (regra do projeto).
    - *NÃO* adicionar `applyFilter` ou `searchChanged` no `BudgetsNotifier` (sem filtros nesta entrega).
    - *NÃO* navegar para tela de detalhe ao tocar num item da lista — sem destino para tap nesta entrega.
    - *NÃO* incluir CTA "criar budget" no empty state — escopo é só listagem.
    - *NUNCA* usar `ConsumerWidget` — apenas `StatelessWidget` (ou `StatefulWidget` quando precisar de `ScrollController`) com `Consumer` interno.
    - *NUNCA* ler `moneyServiceProvider` / `dateFormatterProvider` direto na screen — view-models já vêm formatados pelo notifier.
    - *NUNCA* usar `var` — `final` com tipo inferido ou tipo explícito.
    - *NUNCA* usar `switch` statement — só switch expression (inclusive em `dispatch`, `ref.listen` e mapping de failure).
    - *NUNCA* usar `late final` em campos de `build()` do Notifier — Riverpod re-executa `build` na mesma instância.
    - *NUNCA* criar widgets privados (`class _Foo`) dentro de outro arquivo de widget — extrair para arquivo próprio ou usar método privado.
    - *NUNCA* fazer `BudgetsScreen` importar Locations de outras features — receber callbacks via `BudgetsLocation`.
    - *NUNCA* expor `XxxRequest` na interface do datasource — interface aceita parâmetros de domínio (`String? cursor`); a implementação concreta cria o request internamente.
    - *NUNCA* incluir `toModel()` na response (`BudgetResponse`/`BudgetsResponse`) — mapping é via extension em `data/extensions/budget/`.
    - *NÃO* adicionar comentários explicativos no código — nomes devem ser autoexplicativos.

</critical>
