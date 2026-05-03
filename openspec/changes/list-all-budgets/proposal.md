# Proposal — list-all-budgets

## Why

A feature de Budget hoje só expõe duas afordâncias: o card do orçamento ativo na Home (`BudgetCardWidget` lendo `IBudgetRepository.findActive`) e a tela de criação (`BudgetLocation`). Não existe lugar nenhum no app onde o usuário veja o histórico de orçamentos passados ou futuros — toda a noção de continuidade temporal de orçamentos está invisível.

A API do backend Django já expõe `GET /api/v1/budgets` com paginação cursor-based e devolve `total_spent` / `remaining` para **todos** os budgets (não só o ativo). Toda a stack necessária é Flutter, e o padrão de paginação infinita já está consolidado em `ExpensesNotifier` / `ExpensesScreen` — basta espelhar.

Esta change fecha a leitura completa da feature Budget (depois ficam só edit e delete, em changes separadas) e fornece o entry point natural para essas próximas evoluções.

## What Changes

Adicionar uma nova tela de listagem de orçamentos (`BudgetsScreen`) ativada por **tap no `BudgetCardWidget` da Home**. A tela tem duas regiões:

- **Topo**: o orçamento atualmente vigente (em que `DateTime.now()` está dentro de `[startDate, endDate]`) renderizado com o **mesmo `BudgetCardWidget` rico já usado na Home** — progress bar, remaining, total spent, end date label.
- **Lista infinita abaixo**: os demais budgets (passados e futuros), em cards mais simples (`BudgetListItemWidget` — sem progress bar; mostra descrição, período, valor, total gasto e saldo).

Paginação cursor-based espelhando exatamente o padrão de `ExpensesPageModel` / `ExpensesNotifier` / `ExpensesScreen`: scroll infinito via `ScrollController` (threshold 200px), swipe-to-refresh via `RefreshIndicator` + `ref.invalidate(budgetsProvider)`, tail de load-more com loading e failure isolados, estados completos (loading inicial, erro inicial, empty, sucesso).

Para reutilizar o `BudgetCardWidget` na nova tela sem violar a regra de encapsulamento entre features, a pasta inteira `lib/src/presentation/ui/home/widgets/budget/card/` é **promovida** para `lib/src/presentation/widgets/budget/card/` (família compartilhada), e o widget ganha `VoidCallback? onTap` — usado pela Home para navegar para a listagem e usado pela própria listagem como o card destacado no topo.

`BudgetModel` é estendido com `totalSpent`, `remaining` e `createdAt` (vindos do mesmo endpoint), e `BudgetResponse.fromJson` ganha o mapeamento desses três campos. `ActiveBudgetModel` / `ActiveBudgetNotifier` permanecem **intactos** — a deduplicação eventual é decisão de outra change.

## Scope

### Em escopo

- **Domain**: estender `BudgetModel` com `totalSpent`/`remaining`/`createdAt`; criar `BudgetsPageModel`; estender `IBudgetRepository` com `findAll({String? cursor})`.
- **Infrastructure**: estender `BudgetResponse.fromJson` com os três novos campos; criar `BudgetsResponse` (apenas `fromJson`); estender `IRemoteBudgetDataSource` + `RemoteBudgetDataSource` com `findAll({String? cursor})`.
- **Data**: estender `BudgetRepository.findAll`; estender `BudgetResponseExtension.toModel()` com mapping dos novos campos; criar `BudgetsResponseExtension.toPageModel()` com `_cursorFrom` privado (espelhar `ExpensesResponseExtension`).
- **Presentation — promover widget compartilhado**: mover toda a pasta `home/widgets/budget/card/` para `presentation/widgets/budget/card/`; adicionar `VoidCallback? onTap` em `BudgetCardWidget` e `BudgetCardSuccessWidget`.
- **Presentation — Home**: `HomeScreen` ganha prop `navigateToBudgets`; `HomeLocation` injeta `() => context.navigate(BudgetsLocation())`; `BudgetCardWidget` recebe esse callback como `onTap`.
- **Presentation — nova feature `budgets/`**: `BudgetsNotifier` (`AsyncNotifier` com `keepAlive: true`, `loadMore`, sem `applyFilter`), `BudgetsState`, `BudgetItemPresentationData`, `BudgetsScreen` (Stateful para `ScrollController`, `Consumer` interno), `BudgetsLocation`, e widgets de estado: `BudgetsListWidget`, `BudgetListItemWidget`, `BudgetsLoadingWidget`, `BudgetsFailureWidget`, `BudgetsEmptyWidget`, `BudgetsLoadMoreLoadingWidget`, `BudgetsLoadMoreFailureWidget`.
- **Main**: `AppRoutes.budgets` (path `/budgets`) em `lib/app_route.dart`.
- **Testes**: response (`BudgetResponse`/`BudgetsResponse`), repository (`findAll` mockando `IHttpClient`), notifier (`BudgetsNotifier` com `ProviderContainer` + mock em `IBudgetRepository` e `IMoneyService`).

### Fora de escopo

- **Filtros, busca ou ordenação** na listagem — entrega só paginação. Filtros de orçamento ficam em change separada se virarem necessidade.
- **Navegação para detalhe** ao tocar num item da lista — sem destino para tap nesta entrega; itens da lista são read-only e não-clicáveis.
- **CTA "Criar orçamento"** no empty state — escopo é só listagem; criação continua acessível pelos pontos atuais.
- **Editar / excluir budget** — mantém-se como evolução futura; `BudgetLocation` (singular, criação) fica intocada.
- **Remover `ActiveBudgetModel` / `ActiveBudgetNotifier`** — eles continuam alimentando o card da Home; deduplicação contra o novo `BudgetModel` estendido é decisão de outra change.
- **Wrapper genérico de paginação** (`PaginatedResponse<T>`, `Page<T>`) — replicar o padrão concreto já existente (`BudgetsResponse` / `BudgetsPageModel` espelhando `ExpensesResponse` / `ExpensesPageModel`).
- **Mudanças no backend** — `GET /api/v1/budgets` já existe e já devolve `total_spent`/`remaining`/`created_at` para todos os budgets.
- **Pacote externo de paginação** (`infinite_scroll_pagination` etc.) — restrição dura herdada de `list-all-expenses`.
- **Sticky headers / agrupamento por mês** — a lista é simples (cards individuais em ordem cronológica desc retornada pela API).
- **Deep link para `/budgets`** — entrada exclusiva via tap no card da Home nesta entrega.
- **Widget tests obrigatórios** — só são adicionados se houver lógica visual complexa (não há nesta entrega).
