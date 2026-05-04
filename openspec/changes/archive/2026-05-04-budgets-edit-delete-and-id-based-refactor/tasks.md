# Tasks — budgets-edit-delete-and-id-based-refactor

Ordem fixa: pré-checks → shared dialog → domain → infrastructure → data → presentation (Budget form id-based) → presentation (Expense refactor id-based) → presentation (Budget list/card clicáveis) → main → code generation → testes → arquivamento da change obsoleta → verificação.

---

## 1. Pré-checks

- [ ] 1.1 Confirmar com backend (curl/swagger) que `GET /api/v1/budgets/{id}` existe e retorna o mesmo schema de `BudgetResponse`. Confirmar idem `GET /api/v1/expenses/{id}`.
  - Se **algum não existir**: documentar nesta task e ajustar o respectivo `byIdProvider` para operar **cache-only** (deep-link sem listagem carregada falha com `NotFoundFailure` controlado). Ajustar tasks 4.3 e 7.4 para remover a chamada `findById` do datasource correspondente.
- [ ] 1.2 Verificar que `test/mocks/mocks.dart` expõe `MockBudgetRepository`, `MockExpenseRepository`, `MockHttpClient`, `MockMoneyService`. Adicionar o que faltar.

## 2. Shared — ConfirmDialogWidget

- [ ] 2.1 Criar `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`:
  - Função top-level `Future<bool> showConfirmDialog({ required BuildContext context, required String title, required String description, String confirmLabel = 'Confirmar', String denyLabel = 'Cancelar', bool destructive = false })`.
  - Implementação: `showDialog<bool>(context: context, builder: (_) => ConfirmDialogWidget(...))` retornando `?? false`.
  - `ConfirmDialogWidget` interno é `StatelessWidget` com title/description/buttons (`ButtonWidget.text` para deny, `ButtonWidget.elevated` ou `outlined` para confirm; quando `destructive == true` aplica `colors.error` no confirm).
  - Estilo via `context.colors`/`context.typography` (Material 3, dark mode compatible).
  - Confirm: `Navigator.of(context).pop(true)`. Deny: `Navigator.of(context).pop(false)`. Dismiss por barrier/Android back: retorna `null` → `?? false`.
- [ ] 2.2 **Não** criar widget privado dentro do arquivo. Se houver subwidget não-trivial, extrair para arquivo próprio. Se for trivial, método privado retornando `Widget`.
- [ ] 2.3 Verificar que o widget **não** importa nada de features (`ui/...`) — apenas `widgets/`, `extensions/` e Flutter.

## 3. Domain — Budget

- [ ] 3.1 Adicionar em `lib/src/domain/repositories/interface_budget_repository.dart`:
  ```dart
  Future<Either<Failure, BudgetModel>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });

  Future<Either<Failure, void>> delete({required int id});

  Future<Either<Failure, BudgetModel>> findById({required int id});
  ```
- [ ] 3.2 Verificar que `BudgetModel.copyWith` cobre todos os campos (já deve cobrir conforme spec `list-all-budgets`); ajustar se faltar.

## 4. Domain — Expense

- [ ] 4.1 Adicionar em `lib/src/domain/repositories/interface_expense_repository.dart`:
  ```dart
  Future<Either<Failure, ExpenseModel>> findById({required int id});
  ```
  As assinaturas de `update` e `delete` permanecem inalteradas (`delete` já retorna `Future<Either<Failure, void>>`).

## 5. Infrastructure — Budget

- [ ] 5.1 Adicionar `EndpointKey.budgetsById` (ou similar) em `lib/src/infrastructure/clients/http/endpoint_key.dart`. Se o padrão atual é construir o path via concat (ex.: `'${EndpointKey.budgets.path}/$id'`), seguir o mesmo padrão usado em Expense para `update`/`delete`.
- [ ] 5.2 Adicionar à interface `IRemoteBudgetDataSource` em `lib/src/infrastructure/datasources/remote/remote_budget_data_source.dart`:
  ```dart
  Future<Either<FailureResponse, BudgetResponse>> update({
    required int id,
    required int value,
    required int endDate,
    required int startDate,
    required String description,
  });

  Future<Either<FailureResponse, void>> delete({required int id});

  Future<Either<FailureResponse, BudgetResponse>> findById({required int id});
  ```
- [ ] 5.3 Implementar em `RemoteBudgetDataSource`:
  - `update`: `_client.patch(parameter: Requests('${EndpointKey.budgets.path}/$id', body: BudgetRequest(value: value, endDate: endDate, startDate: startDate, description: description).toJson()))` → `response.either(FailureResponse.fromJson, BudgetResponse.fromJson)`. **Reusa `BudgetRequest` existente** — sem `UpdateBudgetRequest`.
  - `delete`: `_client.delete(parameter: Requests('${EndpointKey.budgets.path}/$id'))` → `response.either(FailureResponse.fromJson, (_) {})` (descarta body do 204).
  - `findById`: `_client.get(parameter: Requests('${EndpointKey.budgets.path}/$id'))` → `response.either(FailureResponse.fromJson, BudgetResponse.fromJson)`.
- [ ] 5.4 Variável de retorno do client sempre nomeada `response` (nunca `either`).

## 6. Infrastructure — Expense

- [ ] 6.1 Adicionar à interface `IRemoteExpenseDataSource`:
  ```dart
  Future<Either<FailureResponse, ExpenseResponse>> findById({required int id});
  ```
- [ ] 6.2 Implementar `findById` em `RemoteExpenseDataSource` espelhando o padrão de `update`: GET para `'${EndpointKey.expenses.path}/$id'`, mapeia via `response.either(FailureResponse.fromJson, ExpenseResponse.fromJson)`.

## 7. Data — Budget

- [ ] 7.1 Implementar em `lib/src/data/repositories/budget_repository.dart`:
  - `update`: chama datasource, mapeia via `data.either((failure) => failure.toFailure(), (response) => response.toModel())`. Reusa `BudgetResponseExtension.toModel()` existente.
  - `delete`: chama datasource, mapeia via `data.either((failure) => failure.toFailure(), (_) {})`. Sucesso é `Right(null)`.
  - `findById`: idêntico ao `update` (mapping para model).
- [ ] 7.2 Variáveis nomeadas `data` (nunca `result`/`either`).

## 8. Data — Expense

- [ ] 8.1 Implementar `findById` em `lib/src/data/repositories/expense_repository.dart` espelhando `update`: usa `ExpenseResponseExtension.toModel()` existente.

## 9. Presentation — Budget form (id-based + edit/delete)

- [ ] 9.1 Estender `BudgetFormState` (`lib/src/presentation/ui/budget/notifiers/form/budget_form_state.dart`):
  - Adicionar `final int? id;` e `final bool isDeleting;`.
  - Construtor com defaults (`this.id`, `this.isDeleting = false`).
  - `copyWith` cobre os dois novos campos (`int? id` named, atribui `id ?? this.id`; `bool? isDeleting` named, atribui `isDeleting ?? this.isDeleting`).
  - `props` inclui ambos.
- [ ] 9.2 Estender `BudgetFormIntent` (`lib/src/presentation/ui/budget/notifiers/form/budget_form_intent.dart`):
  - Adicionar `final class DeletePressed extends BudgetFormIntent { const DeletePressed(); }`.
  - Demais intents (`ValueChanged`, `DateRangeChanged`, `DescriptionChanged`, `SubmitPressed`) permanecem inalterados.
- [ ] 9.3 Criar `lib/src/presentation/ui/budget/notifiers/budget_by_id_notifier.dart`:
  ```dart
  @riverpod
  Future<BudgetModel> budgetById(Ref ref, int id) async {
    // 1. Cache-first: tenta resolver via budgetsProvider
    final budgetsState = ref.read(budgetsProvider);
    if (budgetsState case AsyncData(:final value)) {
      final cached = [
        if (value.activeItem != null) value.activeItem!.budget,
        ...value.items.map((i) => i.budget),
      ].firstWhereOrNull((b) => b.id == id);
      if (cached != null) return cached;
    }
    // 2. Fallback HTTP
    final repository = ref.watch(budgetRepositoryProvider);
    final data = await repository.findById(id: id);
    return data.fold((failure) => throw failure, (model) => model);
  }
  ```
  Usa `ref.read` no `budgetsProvider` (não watch — não queremos re-execução automática quando a lista muda).
- [ ] 9.4 Migrar `BudgetFormNotifier` (`lib/src/presentation/ui/budget/notifiers/form/budget_form_notifier.dart`) para `AsyncNotifier` family por `int? id`:
  - Trocar a anotação para `@Riverpod(keepAlive: false)` se ainda não estiver; declarar `Future<BudgetFormState> build(int? id)`.
  - Em `build(id)`:
    - `_repository = ref.watch(budgetRepositoryProvider)`.
    - `_validator = ref.watch(budgetFormValidatorProvider)`.
    - Se `id == null`: retornar `BudgetFormState()` (estado inicial).
    - Se `id != null`: `final budget = await ref.watch(budgetByIdProvider(id).future); return BudgetFormState(id: budget.id, value: budget.value, startDate: budget.startDate, endDate: budget.endDate, description: budget.description);`.
  - Campos `late` (nunca `late final`).
  - `dispatch` exhaustivo cobre todos os intents incluindo `DeletePressed() => _delete()`.
  - `_submit()` ramifica por `state.value!.id == null` entre `repository.create(...)` e `repository.update(id: state.value!.id!, ...)`. Em sucesso: `ref.invalidate(budgetsProvider)`, `ref.invalidate(activeBudgetProvider)`, e atualiza state com `status: .success`.
  - `_delete()`: early-return se `state.value!.id == null`; senão set `isDeleting: true`; chama `repository.delete(id: state.value!.id!)`; em sucesso invalida ambos providers, em falha popula `message` e `status: .failure`. Sempre limpa `isDeleting: false` ao final.
  - **Importante**: como agora é `AsyncNotifier`, todas as mutações de state usam `state = AsyncData(state.value!.copyWith(...))` (ou helper similar).
- [ ] 9.5 Criar `lib/src/presentation/ui/budget/widgets/budget_edit_actions_widget.dart`:
  - `StatelessWidget` puro com `final bool isLoading;`, `final bool isDeleting;`, `final VoidCallback onUpdate;`, `final VoidCallback onDelete;`.
  - Renderiza `Row(spacing: 16.0, children: [Expanded(ButtonWidget.outlined(label: 'Excluir', isLoading: isDeleting, onTap: () { if (isLoading || isDeleting) return; onDelete(); })), Expanded(ButtonWidget.elevated(label: 'Atualizar', isLoading: isLoading, onTap: () { if (isLoading || isDeleting) return; onUpdate(); }))])`.
  - Espelha exatamente `ExpenseEditActionsWidget` (mesma assinatura, mesmas regras de habilitação).
- [ ] 9.6 Refatorar `BudgetScreen` (`lib/src/presentation/ui/budget/screens/budget_screen.dart`):
  - Aceitar `final int? id;` no construtor (sem `BudgetModel`).
  - `Consumer` interno (StatelessWidget + Consumer; **nunca** `ConsumerWidget`).
  - `ref.listen(budgetFormProvider(id), (prev, next) => ...)` para `success → context.root()`, `failure → showToastWidget(...)`.
  - `final asyncState = ref.watch(budgetFormProvider(id));`
  - Switch sobre `AsyncValue<BudgetFormState>`:
    - `AsyncLoading()` → loading da tela inteira (centered `CircularProgressIndicatorWidget`).
    - `AsyncError(:final error)` → mensagem + botão `'Tentar novamente'` chamando `ref.invalidate(budgetByIdProvider(id!))`.
    - `AsyncData(:final value)` → form com `value.id == null ? 'Novo orçamento' : 'Editar orçamento'` no título; subtítulo similar; rodapé condicional (`value.id == null` → `BudgetSaveButtonWidget`, senão → `BudgetEditActionsWidget`).
  - **Confirmação de delete**: `onDelete` callback do `BudgetEditActionsWidget` é:
    ```dart
    onDelete: () async {
      hideKeyboard();
      final confirmed = await showConfirmDialog(
        context: context,
        title: 'Excluir orçamento',
        description: 'Esta ação não pode ser desfeita.',
        confirmLabel: 'Excluir',
        destructive: true,
      );
      if (!confirmed) return;
      notifier.dispatch(const DeletePressed());
    }
    ```
- [ ] 9.7 Atualizar `BudgetSaveButtonWidget` se necessário para receber `final String label;` (espelhar `ExpenseSaveButtonWidget`); permitir "Cadastrar" no modo create. Se já tem label fixo "Salvar", parametrizar.

## 10. Presentation — Expense refactor (id-based)

- [ ] 10.1 Criar `lib/src/presentation/ui/expense/notifiers/expense_by_id_notifier.dart`:
  ```dart
  @riverpod
  Future<ExpenseModel> expenseById(Ref ref, int id) async {
    final expensesState = ref.read(expensesProvider);
    if (expensesState case AsyncData(:final value)) {
      final cached = value.items
          .map((i) => i.expense)
          .firstWhereOrNull((e) => e.id == id);
      if (cached != null) return cached;
    }
    final repository = ref.watch(expenseRepositoryProvider);
    final data = await repository.findById(id: id);
    return data.fold((failure) => throw failure, (model) => model);
  }
  ```
- [ ] 10.2 Migrar `ExpenseNotifier` (`lib/src/presentation/ui/expense/notifiers/expense_notifier.dart`) de `Notifier<ExpenseState>` family `<ExpenseModel?>` para `AsyncNotifier<ExpenseState>` family `<int?>`:
  - `Future<ExpenseState> build(int? id)`:
    - `_repository = ref.watch(expenseRepositoryProvider)`.
    - `_validator = ref.watch(expenseFormValidatorProvider)`.
    - Se `id == null`: retornar `ExpenseState(date: DateTime.now().millisecondsSinceEpoch)`.
    - Se `id != null`: `final expense = await ref.watch(expenseByIdProvider(id).future); return ExpenseState(id: expense.id, date: expense.date, value: expense.value, description: expense.description);`.
  - `dispatch` continua exhaustivo cobrindo `ValueChanged`, `DescriptionChanged`, `DateChanged`, `SubmitPressed`, `DeletePressed`.
  - `_submit()` e `_delete()` migrados para mutar via `state = AsyncData(state.value!.copyWith(...))`.
- [ ] 10.3 Atualizar `ExpenseLocation` (`lib/src/presentation/ui/expense/locations/expense_location.dart`):
  - Trocar `final ExpenseModel? expense;` por `final int? id;`.
  - Construtor `const ExpenseLocation({this.id})`.
  - Passar `id: id` ao `ExpenseScreen`.
  - `ExpenseDateLocation` continua recebendo o que precisar — se hoje recebe `expense`, ajustar para receber só os dados de data necessários (ou aceitar `int?` se for o caso). Manter o que está se não impactar.
- [ ] 10.4 Refatorar `ExpenseScreen` (`lib/src/presentation/ui/expense/screens/expense_screen.dart`):
  - Trocar `final ExpenseModel? expense;` por `final int? id;`.
  - Remover o comentário `// TODO deveriamos passar so o ID`.
  - `ref.watch(expenseProvider(id))` retorna `AsyncValue<ExpenseState>` — adicionar switch sobre `AsyncValue` espelhando o padrão de `BudgetScreen` (loading / error / data).
  - **Confirmação de delete**: `onDelete` do `ExpenseEditActionsWidget` chama `showConfirmDialog(title: 'Excluir despesa', description: 'Esta ação não pode ser desfeita.', confirmLabel: 'Excluir', destructive: true)` antes de despachar `DeletePressed`.
- [ ] 10.5 Atualizar todos os call sites que abrem `ExpenseLocation` com `expense:` para passar `id:`. Lugares prováveis (verificar com grep):
  - `lib/src/presentation/ui/expenses/locations/expenses_location.dart` (composer da listagem de despesas).
  - `ExpensesScreen` ou widgets que disparam navegação direta.
  - Previews que constroem `ExpenseLocation`.

## 11. Presentation — Budget list/card clicáveis

- [ ] 11.1 Atualizar `BudgetListItemWidget` (`lib/src/presentation/ui/budgets/widgets/budget_list_item_widget.dart`):
  - Adicionar `final VoidCallback? onTap;` no construtor.
  - Wrap o conteúdo em `BounceWidget.withOnPress(onPress: onTap!, child: <body>)` quando `onTap != null`; render unwrapped quando null.
  - **Atualiza spec atual** — `BudgetListItemWidget` deixa de ser "SHALL NOT be tappable" (a spec atual de `list-all-budgets` afirmava isso). Esta change reverte a restrição.
- [ ] 11.2 Atualizar `BudgetsListWidget` para passar `onTap: () => onTapItem(item.budget)` (ou similar), com o callback chegando da `BudgetsScreen` via parâmetro.
- [ ] 11.3 Atualizar `BudgetsScreen`:
  - Adicionar `void _onTapBudget(BudgetModel budget) => context.navigate(BudgetLocation(id: budget.id));` (ou via callback injetado pela Location).
  - Passar para `BudgetCardSuccessWidget` (card ativo no topo) como `onTap`.
  - Passar para `BudgetsListWidget` (que repassa para cada item).

## 12. Main — Locations e composição

- [ ] 12.1 `BudgetLocation` (`lib/src/presentation/ui/budget/locations/budget_location.dart`):
  - Trocar `const BudgetLocation()` por `const BudgetLocation({this.id})` com `final int? id;`.
  - `pageBuilder` passa `id: id` ao `BudgetScreen`.
  - Os callbacks de navegação para calculator/date podem permanecer como estão (não dependem do id).
- [ ] 12.2 Verificar que `BudgetsLocation` (composer da listagem) **não** importa `BudgetLocation` diretamente — o tap passa pelo callback injetado, e quem importa é a Location. **Exceção narrada**: Locations compondo navegação podem importar outras Locations (CLAUDE.md). Concretamente: `BudgetsLocation.pageBuilder` envolve em `Consumer` (se necessário pra capturar `ref`) ou injeta `onTapBudget: (id) => context.navigate(BudgetLocation(id: id))` na construção do `BudgetsScreen`.

## 13. Code generation

- [ ] 13.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar:
  - `budget_form_notifier.g.dart` (AsyncNotifier family).
  - `expense_notifier.g.dart` (AsyncNotifier family).
  - `budget_by_id_notifier.g.dart`.
  - `expense_by_id_notifier.g.dart`.

## 14. Testes — ConfirmDialogWidget

- [ ] 14.1 Criar `test/src/presentation/widgets/dialog/confirm_dialog_widget_test.dart`:
  - `testWidgets('renders title and description')`.
  - `testWidgets('renders default confirm and deny labels when not provided')`.
  - `testWidgets('renders custom confirmLabel and denyLabel when provided')`.
  - `testWidgets('tap on confirm resolves Future<bool> with true')`.
  - `testWidgets('tap on deny resolves Future<bool> with false')`.
  - `testWidgets('dismiss by tapping barrier resolves with false')`.
  - `testWidgets('destructive: true applies error color to confirm button')`.

## 15. Testes — BudgetByIdNotifier

- [ ] 15.1 Criar `test/src/presentation/providers/budget_by_id_notifier_test.dart`:
  - `test('returns cached BudgetModel when id is in budgetsProvider.items')`.
  - `test('returns cached BudgetModel when id matches activeItem')`.
  - `test('falls back to repository.findById when not in cache')`.
  - `test('throws Failure when repository returns Left')` — verifica que `AsyncError` é propagado.
  - `test('does not call repository when cache hit')` — `verifyNever`.

## 16. Testes — ExpenseByIdNotifier

- [ ] 16.1 Criar `test/src/presentation/providers/expense_by_id_notifier_test.dart` espelhando 15.1 para Expense.

## 17. Testes — BudgetRepository (mock IHttpClient)

- [ ] 17.1 Estender `test/src/data/repositories/budget_repository_test.dart`:
  - **`update`**:
    - `test('returns Right(BudgetModel) when PATCH /api/v1/budgets/<id> succeeds with 200')`.
    - `test('sends body serialized via BudgetRequest with value/startDate/endDate/description')`.
    - `test('returns Left(ValidationFailure) when PATCH returns 400 with errors body')`.
    - `test('returns Left(NetworkFailure) when PATCH fails with network error')`.
    - `test('returns Left(ServerFailure) when PATCH returns 5xx')`.
    - `test('returns Left(NotFoundFailure) when PATCH returns 404')`.
  - **`delete`**:
    - `test('returns Right(null) when DELETE /api/v1/budgets/<id> returns 204 with empty body')`.
    - `test('sends DELETE with no body')`.
    - `test('returns Left(NetworkFailure) when DELETE fails with network error')`.
    - `test('returns Left(NotFoundFailure) when DELETE returns 404')`.
  - **`findById`**:
    - `test('returns Right(BudgetModel) when GET /api/v1/budgets/<id> succeeds')`.
    - `test('returns Left(NotFoundFailure) when GET returns 404')`.
    - `test('returns Left(NetworkFailure) on network error')`.

## 18. Testes — ExpenseRepository.findById

- [ ] 18.1 Estender `test/src/data/repositories/expense_repository_test.dart` com casos de `findById` espelhando 17.1.

## 19. Testes — BudgetFormNotifier (AsyncNotifier family)

- [ ] 19.1 Estender `test/src/presentation/providers/budget_notifier_test.dart` (renomear/adicionar conforme necessidade) com cenários do AsyncNotifier:
  - `test('build(null) returns initial AsyncData with id null')`.
  - `test('build(id) awaits budgetByIdProvider and returns AsyncData with id and fields populated')`.
  - `test('build(id) returns AsyncError when budgetByIdProvider throws')`.
  - `test('SubmitPressed in create mode (id == null) calls repository.create')`.
  - `test('SubmitPressed in edit mode (id != null) calls repository.update with state.id')`.
  - `test('SubmitPressed in edit mode does not call create')`.
  - `test('successful create invalidates budgets and activeBudget providers')`.
  - `test('successful update invalidates budgets and activeBudget providers')`.
  - `test('failed update sets status: failure with message, preserves form fields')`.
  - `test('DeletePressed in edit mode calls repository.delete with state.id, sets isDeleting true → false, then status: success')`.
  - `test('DeletePressed in create mode (id == null) is a no-op (verifyNever)')`.
  - `test('successful delete invalidates budgets and activeBudget providers')`.
  - `test('failed delete sets status: failure with message, isDeleting back to false')`.

## 20. Testes — ExpenseNotifier regressão (AsyncNotifier family por int?)

- [ ] 20.1 Atualizar `test/src/presentation/providers/expense_notifier_test.dart` para refletir a nova assinatura family por `int?`:
  - `test('build(null) returns initial AsyncData with id null and date defaulted to now')`.
  - `test('build(id) awaits expenseByIdProvider and returns AsyncData prefilled with id, date, value, description')`.
  - `test('build(id) returns AsyncError when expenseByIdProvider throws')`.
  - Manter regressão de `SubmitPressed` (create + update), `DeletePressed`, invalidations de `expensesProvider`/`activeBudgetProvider`/`recentExpensesProvider`.

## 21. Testes — Convenções

- [ ] 21.1 Todas as descrições de `test()`, `group()`, `testWidgets()` em **inglês**.
- [ ] 21.2 Mocks declarados pelo **tipo da interface** (`late IBudgetRepository repository;`), nunca pelo Mock concreto.
- [ ] 21.3 Variáveis nunca nomeadas `result` ou `either` — usar `data`, `state`, ou nome do conceito.
- [ ] 21.4 Nunca `var` — usar `final` (com tipo explícito quando agrega legibilidade).

## 22. Arquivar change obsoleta

- [ ] 22.1 Mover diretório `openspec/changes/expense-edit-and-delete/` para `openspec/changes/archive/2026-05-03-expense-edit-and-delete/`.
- [ ] 22.2 Adicionar `openspec/changes/archive/2026-05-03-expense-edit-and-delete/STATUS.md` com nota:
  ```
  Status: SUPERSEDED

  Esta change foi proposta em 2026-04 com approach de bottom sheet (`expense_actions/`) +
  método `delete` em `ExpensesNotifier`. A implementação real seguiu approach diferente:
  footer dinâmico no `ExpenseNotifier` (form), com `DeletePressed` no `ExpenseIntent`.

  O id-based refactor (TODO em `expense_screen.dart:24`) e a confirmação por dialog
  foram movidos para a change `budgets-edit-delete-and-id-based-refactor` (2026-05-03),
  que tornou esta proposta obsoleta.

  Arquivada como histórico de decisão. Não implementar nem retomar.
  ```

## 23. Verificação

- [ ] 23.1 `flutter analyze` — zero warnings.
- [ ] 23.2 `flutter test` — toda a suíte passa.
- [ ] 23.3 **Smoke manual — Budget create**: abrir tela via `+`, preencher, salvar. Tela mostra "Novo orçamento" / "Salvar". Lista atualiza.
- [ ] 23.4 **Smoke manual — Budget edit**: tap no card ativo da Home → abre edit pré-preenchido. Tap em item da listagem → mesmo fluxo. Título "Editar orçamento", footer com "Excluir" + "Atualizar". Alterar valor e tap "Atualizar" → toast/sucesso, volta para root, lista reflete novo valor.
- [ ] 23.5 **Smoke manual — Budget delete**: na tela de edit, tap "Excluir" → dialog aparece com "Excluir orçamento" / "Esta ação não pode ser desfeita." / "Cancelar" / "Excluir" (vermelho). Cancelar → dialog fecha, nada acontece. Tap "Excluir" no dialog → request dispara, tela fecha, item some da listagem.
- [ ] 23.6 **Smoke manual — Expense regressão**: criar, editar e excluir despesa funcionam igual a hoje, mas agora a navegação é por `id` (verificar via logs ou breakpoint). Delete agora **passa pelo dialog** antes de disparar (regressão do comportamento atual de delete imediato — confirmar que isso é desejável; se não for, ajustar para Expense **não** ter dialog e Budget ter — mas spec diz ambos têm).
- [ ] 23.7 **Smoke manual — falha de findById**: forçar erro 500 no `GET /budgets/<id>` (ou navegar para id inválido) → tela mostra `BudgetFailureWidget` com botão de retry.
- [ ] 23.8 **Smoke manual — deep-link sem cache**: invalidar `budgetsProvider`, navegar diretamente para `BudgetLocation(id: X)` → byIdProvider faz `findById`. Loading aparece enquanto resolve. Sucesso → form preenchido.
- [ ] 23.9 Rodar `arch-review` para validar Clean Architecture e encapsulamento de feature.
- [ ] 23.10 Verificar com grep que nenhum import de feature cruzou fronteira indevidamente: `grep -rE "presentation/ui/budgets/" lib/src/presentation/ui/budget/` deve retornar vazio (e vice-versa).
- [ ] 23.11 Verificar que `ConfirmDialogWidget` não importa nada de `ui/`: `grep -E "presentation/ui/" lib/src/presentation/widgets/dialog/` retorna vazio.
