# Tasks — expense-edit-and-delete

Ordem fixa: domain → infrastructure → data → presentation (edit) → presentation (action sheet) → presentation (list delete + long-press) → main (rota) → code generation → testes → verificação.

---

## 1. Domain

- [ ] 1.1 Adicionar `update({required int id, required int date, required int value, required String description}) → Future<Either<Failure, ExpenseModel>>` em `lib/src/domain/repositories/interface_expense_repository.dart`.
- [ ] 1.2 Adicionar `delete({required int id}) → Future<Either<Failure, void>>` na mesma interface.

## 2. Infrastructure

- [ ] 2.1 Adicionar as duas assinaturas correspondentes na interface `IRemoteExpenseDataSource` em `lib/src/infrastructure/datasources/remote/remote_expense_data_source.dart`:
  - `update({required int id, required int date, required int value, required String description}) → Future<Either<FailureResponse, ExpenseResponse>>`
  - `delete({required int id}) → Future<Either<FailureResponse, void>>`
- [ ] 2.2 Implementar `update` em `RemoteExpenseDataSource`: monta `ExpenseRequest` existente (reuso, sem DTO novo), envia `PATCH ${EndpointKey.expenses.path}/$id`, mapeia via `response.either(FailureResponse.fromJson, ExpenseResponse.fromJson)`.
- [ ] 2.3 Implementar `delete` em `RemoteExpenseDataSource`: envia `DELETE ${EndpointKey.expenses.path}/$id` (sem body), mapeia falha via `FailureResponse.fromJson` e sucesso via `(_) => null` (descarta o `{}` que o client retorna em 204).

## 3. Data

- [ ] 3.1 Implementar `update` em `ExpenseRepository` (`lib/src/data/repositories/expense_repository.dart`): chama datasource, mapeia falha via `FailureResponseExtension.toFailure()` e sucesso via `ExpenseResponseExtension.toModel()`.
- [ ] 3.2 Implementar `delete` em `ExpenseRepository`: chama datasource, mapeia falha via `FailureResponseExtension.toFailure()` e sucesso via `(_) => null`.

## 4. Presentation — expense (edit mode)

- [ ] 4.1 Adicionar `final int? id;` em `ExpenseState` (`lib/src/presentation/ui/expense/notifiers/expense_state.dart`): incluir no construtor (`this.id`), no `copyWith` (named `int? id`, assign `id: id ?? this.id`), e em `props`.
- [ ] 4.2 Converter `ExpenseNotifier` em **family** com parâmetro `ExpenseModel?`:
  - Mudar assinatura para `ExpenseState build(ExpenseModel? expense)`.
  - Se `expense == null`: retorna `ExpenseState(date: DateTime.now().millisecondsSinceEpoch)` (comportamento atual, criação).
  - Se `expense != null`: retorna state pré-preenchido com `id: expense.id, date: expense.date, value: expense.value, description: expense.description`.
  - Dependências continuam vindo via `ref.watch` em `build()` (repositório, validator) — permanecem `late`, nunca `late final`.
- [ ] 4.3 Atualizar `_submit()` em `ExpenseNotifier`: ramifica por `state.id == null`:
  - `null` → `_repository.create(date: …, value: …, description: …)` (comportamento atual).
  - não-null → `_repository.update(id: state.id!, date: …, value: …, description: …)`.
  - Em ambos os ramos de sucesso, manter as três `ref.invalidate(expensesProvider, activeBudgetProvider, recentExpensesProvider)` e `state.status = .success`.
- [ ] 4.4 Atualizar `ExpenseScreen` (`lib/src/presentation/ui/expense/screens/expense_screen.dart`):
  - Aceitar `final ExpenseModel? expense;` no construtor.
  - `ref.watch(expenseNotifierProvider(expense))` e `ref.read(expenseNotifierProvider(expense).notifier)`.
  - Título: `expense == null ? 'Nova despesa' : 'Editar despesa'`.
  - Subtítulo: `expense == null ? 'Preencha as informações abaixo para registrar sua despesa.' : 'Atualize as informações da sua despesa.'`.
  - Passar `label` ao `ExpenseSaveButtonWidget` conforme o modo.
- [ ] 4.5 Adicionar `final String label;` em `ExpenseSaveButtonWidget` (`lib/src/presentation/ui/expense/widgets/expense_save_button_widget.dart`); propagar para `ButtonWidget.outlined(label: label, …)`.
- [ ] 4.6 Atualizar `ExpenseLocation` (`lib/src/presentation/ui/expense/locations/expense_location.dart`): trocar `final int? id` por `final ExpenseModel? expense;`; construtor `const ExpenseLocation({this.expense})`; passar `expense: expense` ao `ExpenseScreen`.

## 5. Presentation — nova feature `expense_actions/`

- [ ] 5.1 Criar `lib/src/presentation/ui/expense_actions/screens/expense_actions_screen.dart` como `StatelessWidget` puro com parâmetros `VoidCallback onEdit` e `VoidCallback onDelete`. Usa `BottomSheetScaffoldWidget(title: 'Despesa', subtitle: 'O que deseja fazer?', child: Column(...))` com `Row(spacing: 16.0, children: [Expanded(ButtonWidget.elevated(label: 'Editar', onTap: onEdit)), Expanded(ButtonWidget.outlined(label: 'Excluir', onTap: onDelete))])` — mirror visual do `ExitScreen`.
- [ ] 5.2 Criar `lib/src/presentation/ui/expense_actions/locations/expense_actions_location.dart` — `BottomSheetPage` (padrão `ExitLocation`). Construtor aceita `{required VoidCallback onEdit, required VoidCallback onDelete}`; `pageBuilder` retorna `BottomSheetPage(builder: (_) => ExpenseActionsScreen(onEdit: onEdit, onDelete: onDelete))`.
- [ ] 5.3 **Nenhum** import cruzado: `expense_actions/` não importa `expense/` nem `expenses/` (verificar analisando os imports do arquivo).

## 6. Presentation — expenses (delete + long-press)

- [ ] 6.1 Adicionar método `Future<Either<Failure, void>> delete(int id)` em `ExpensesNotifier` (`lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart`):
  - Chama `_repository.delete(id: id)`.
  - Em `Right(_)`: `ref.invalidate(activeBudgetProvider)`, `ref.invalidate(recentExpensesProvider)`, `ref.invalidate(expensesProvider)` (auto-invalida para refetch) e retorna `Right(null)`.
  - Em `Left(failure)`: retorna `Left(failure)` **sem mutar state** — a lista permanece intacta; o caller mostra toast. Nenhum `ref.invalidate` é chamado.
- [ ] 6.2 Adicionar `final VoidCallback? onLongPress;` em `ExpenseItemWidget` (`lib/src/presentation/widgets/expense/expense_item_widget.dart`); embrulhar o `Padding` existente em `GestureDetector(onLongPress: onLongPress, child: Padding(...))`. **Não** usar `InkWell`.
- [ ] 6.3 Atualizar `ExpensesListWidget` (`lib/src/presentation/ui/expenses/widgets/expenses_list_widget.dart`): adicionar `final ValueChanged<ExpenseModel> onLongPressExpense;` no construtor; passar `onLongPress: () => onLongPressExpense(item.expense)` para cada `ExpenseItemWidget` dentro do `SliverList.builder`.
- [ ] 6.4 Atualizar `ExpensesScreen` (`lib/src/presentation/ui/expenses/screens/expenses_screen.dart`): adicionar `final ValueChanged<ExpenseModel> onLongPressExpense;` no `StatefulWidget`; propagar para `ExpensesListWidget(onLongPressExpense: widget.onLongPressExpense, …)`.

## 7. Presentation — composição na Location

- [ ] 7.1 Atualizar `ExpensesLocation` (`lib/src/presentation/ui/expenses/locations/expenses_location.dart`): envolver o body do `pageBuilder` em `Consumer`, capturar `ref`, e compor:
  ```dart
  onLongPressExpense: (expense) => context.navigate(
    ExpenseActionsLocation(
      onEdit: () {
        context.pop();
        context.navigate(ExpenseLocation(expense: expense));
      },
      onDelete: () async {
        context.pop();
        final data = await ref.read(expensesProvider.notifier).delete(expense.id);
        data.fold(
          (failure) => showToastWidget(
            context: context,
            title: 'Opps',
            type: ToastConstant.failure,
            description: failure.message,
          ),
          (_) {},
        );
      },
    ),
  )
  ```
  Importar `showToastWidget` / `ToastConstant` do mesmo caminho usado em `ExpenseScreen` (`lib/src/presentation/widgets/toast_widget.dart`).
- [ ] 7.2 Verificar que `ExpensesScreen` **não** importa `ExpenseActionsLocation` diretamente — só recebe o callback `onLongPressExpense`.

## 8. Main — rota

- [ ] 8.1 Adicionar `expenseActions` em `lib/app_route.dart`:
  ```dart
  static final expenseActions = AppRoutes._(
    path: '/expense-actions',
    name: 'expense-actions-route',
    regex: RegExp(r'^/expense-actions$'),
  );
  ```
  Incluir na lista `_all`.

## 9. Code generation

- [ ] 9.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar `expense_notifier.g.dart` (family com parâmetro).

## 10. Testes

### 10.1 Repository (mock em `IHttpClient`) — `test/src/data/repositories/expense_repository_test.dart`

- [ ] 10.1.1 `update` — `test('returns Right(ExpenseModel) when PATCH succeeds with 200')` — body `{value: "92.30", description: "...", date: "2026-04-22", id: 132, created_at, category}` deserializado corretamente; value `"92.30"` → `9230` centavos após `toModel`.
- [ ] 10.1.2 `update` — `test('returns Left(ValidationFailure) when PATCH returns 400 with errors body')`.
- [ ] 10.1.3 `update` — `test('returns Left(NetworkFailure) when PATCH fails with network error')`.
- [ ] 10.1.4 `update` — `test('returns Left(ServerFailure) when PATCH returns 5xx')`.
- [ ] 10.1.5 `update` — `test('sends body {value, description, date} serialized via ExpenseRequest')`.
- [ ] 10.1.6 `update` — `test('sends PATCH to /api/v1/expenses/<id>')`.
- [ ] 10.1.7 `delete` — `test('returns Right(null) when DELETE returns 204 with empty body')`.
- [ ] 10.1.8 `delete` — `test('returns Left(Failure) when DELETE returns 4xx with errors body')`.
- [ ] 10.1.9 `delete` — `test('returns Left(NetworkFailure) when DELETE fails with network error')`.
- [ ] 10.1.10 `delete` — `test('sends DELETE to /api/v1/expenses/<id> with no body')`.

### 10.2 `ExpenseNotifier` family — `test/src/presentation/providers/expense_notifier_test.dart`

- [ ] 10.2.1 `test('build(null) returns initial state with id null and date defaulted to now')`.
- [ ] 10.2.2 `test('build(expense) returns state pre-filled with id, date, value, description')`.
- [ ] 10.2.3 `test('SubmitPressed in create mode calls repository.create and does not call update')`.
- [ ] 10.2.4 `test('SubmitPressed in edit mode calls repository.update with state.id and does not call create')`.
- [ ] 10.2.5 `test('SubmitPressed in edit mode passes current state.date, state.value, state.description')`.
- [ ] 10.2.6 `test('successful create invalidates expenses, activeBudget, recentExpenses providers')`.
- [ ] 10.2.7 `test('successful update invalidates expenses, activeBudget, recentExpenses providers')`.
- [ ] 10.2.8 `test('failed update sets status to failure with message, preserves form fields')`.

### 10.3 `ExpensesNotifier.delete` — `test/src/presentation/providers/expenses_notifier_test.dart`

- [ ] 10.3.1 `test('delete(id) calls repository.delete with the given id')`.
- [ ] 10.3.2 `test('successful delete invalidates activeBudget and recentExpenses providers')`.
- [ ] 10.3.3 `test('successful delete invalidates own provider to refetch the list')`.
- [ ] 10.3.4 `test('successful delete returns Right(null)')`.
- [ ] 10.3.5 `test('failed delete returns Left(failure) without mutating state')` — assert que `state` permanece `AsyncData(ExpensesState)` inalterado e que nenhum `ref.invalidate` foi chamado.

### 10.4 Widget tests — desejáveis, não bloqueantes

- [ ] 10.4.1 `testWidgets('ExpenseItemWidget invokes onLongPress when user long-presses the item')`.
- [ ] 10.4.2 `testWidgets('ExpenseActionsScreen invokes onEdit when Editar button is tapped')`.
- [ ] 10.4.3 `testWidgets('ExpenseActionsScreen invokes onDelete when Excluir button is tapped')`.

### 10.5 Mocks

- [ ] 10.5.1 Verificar que `test/mocks/mocks.dart` já expõe `MockHttpClient` e `MockExpenseRepository` (provavelmente já existem a partir da spec `create-expense` e `list-all-expenses`). Se algum faltar, adicionar.

### 10.6 Convenções

- [ ] 10.6.1 Todas as descrições de `test()`, `group()` e `testWidgets()` em **inglês**.
- [ ] 10.6.2 Declarar mocks pelo **tipo da interface** (`late IHttpClient client;`, `late IExpenseRepository repository;`), nunca pelo mock concreto.
- [ ] 10.6.3 Variável de retorno de `Future` / `Either` nunca é `result` nem `either`; usar `data`, `state`, ou o nome do conceito.
- [ ] 10.6.4 Nunca usar `var`.

## 11. Verificação

- [ ] 11.1 `flutter analyze` — zero warnings.
- [ ] 11.2 `flutter test` — toda a suite passa.
- [ ] 11.3 **Smoke manual — fluxo create (regressão)**: criar nova despesa via botão "+", verificar que a tela mostra "Nova despesa" / "Cadastrar" / "Preencha as informações…". Salvar. Lista e budget atualizam. Nenhum comportamento alterado.
- [ ] 11.4 **Smoke manual — fluxo edit**: long-press em despesa da lista → sheet aparece. Tap "Editar" → sheet fecha, tela abre com título "Editar despesa", subtítulo "Atualize…", campos pré-preenchidos, botão "Atualizar". Alterar valor/description/data → "Atualizar". Tela fecha, lista reflete nova despesa, budget atualiza.
- [ ] 11.5 **Smoke manual — fluxo delete**: long-press em outra despesa → tap "Excluir". Sheet fecha, item some da lista, budget recalcula.
- [ ] 11.6 **Smoke manual — falha de delete**: forçar erro 500 (ex: throttling proposital ou endpoint mockado) → verificar que o sheet fecha, a **lista permanece visível e intacta** (nenhum item some), e um **toast de erro** aparece com a mensagem da falha. Nenhuma `ExpensesFailureWidget` deve ser mostrada — esse fluxo é reservado para falha de carregamento da lista, não de mutação.
- [ ] 11.7 Rodar `arch-review` para validar que nenhuma violação de camada foi introduzida (`expense_actions/` sem import de outras features, `domain/` sem Flutter imports, etc.).
