# Tasks: correcao-arquitetura-clean-arch

> Ordem de execução garante que o projeto compile ao final de cada task.
> Marcar `[x]` ao completar. Executar `flutter analyze` após cada step.

---

## Step 1 — domain/errors (sem dependências, não quebra nada)

- [ ] Criar `lib/src/domain/errors/failure.dart` com `sealed class Failure` e subtipos:
  `NetworkFailure`, `NotFoundFailure`, `ServerFailure`, `DatabaseFailure`,
  `ValidationFailure`, `UnknownFailure`
- [ ] Criar `test/src/domain/errors/failure_test.dart` com testes de mensagem padrão,
  customizada e `toString()`
- [ ] `flutter analyze` ✓

---

## Step 2 — Atualizar assinaturas dos repositórios de domain

- [ ] Atualizar `lib/src/domain/repositories/interface_expense_repository.dart`:
  `Either<String, T>` → `Either<Failure, T>`, adicionar import de `failure.dart`
- [ ] Atualizar `lib/src/domain/repositories/interface_budget_repository.dart`:
  `Either<String, T>` → `Either<Failure, T>`, adicionar import de `failure.dart`
- [ ] Atualizar BLoCs (mínimo): `failure` → `failure.message` nos `fold()`
  - `expense_list_bloc.dart`
  - `expense_form_bloc.dart`
  - `budget_bloc.dart`
- [ ] Atualizar testes de BLoC: `Left('msg')` → `Left(const NetworkFailure('msg'))`
  - `expense_list_bloc_test.dart`
  - `expense_form_bloc_test.dart`
  - `budget_bloc_test.dart`
- [ ] `flutter test` ✓

---

## Step 3 — Entities em infrastructure/clients/database/entities/

- [ ] Criar `lib/src/infrastructure/clients/database/entities/expense_entity.dart`
  — campos alinhados com schema `Expenses` do `openapi.json`:
  `id`, `value: String`, `description: String`, `date: String`, `category: String?`, `createdAt: String?`
- [ ] Criar `lib/src/infrastructure/clients/database/entities/pagination_entity.dart`
  — `PaginatedExpenses` com `next: String?`, `previous: String?`, `results: List<ExpenseEntity>`
- [ ] Criar `lib/src/infrastructure/clients/database/entities/budget_entity.dart`
  — campos alinhados com schema `Budgets` do `openapi.json`:
  `id`, `value: String`, `startDate: String`, `endDate: String`, `description: String?`,
  `totalSpent: String`, `remaining: String`, `createdAt: String?`
- [ ] `flutter analyze` ✓

---

## Step 4 — Datasource interfaces em infrastructure/datasources/

- [ ] Criar `lib/src/infrastructure/datasources/expense_data_source.dart`
  — `IExpenseDataSource` com `Future<PaginatedExpenses> findByPeriod(...)`,
  `Future<ExpenseEntity?> findById(int id)`,
  `Future<void> upsert(ExpenseEntity entity)`,
  `Future<void> deleteById(int id)`
- [ ] Criar `lib/src/infrastructure/datasources/budget_data_source.dart`
  — `IBudgetDataSource` com `Future<List<BudgetEntity>> findAll()`,
  `Future<BudgetEntity?> findActive(String currentDate)`,
  `Future<void> upsert(BudgetEntity entity)`,
  `Future<void> deleteById(int id)`
- [ ] Verificar: nenhum import de `domain/` em ambos os arquivos
- [ ] `flutter analyze` ✓

---

## Step 5 — Mover ILoggerDataSource para infrastructure/

- [ ] Criar `lib/src/infrastructure/datasources/logger_data_source.dart`
  com o conteúdo de `data/datasources/interface_logger_data_source.dart`
- [ ] Atualizar import em `lib/src/infrastructure/datasources/local/logger_local_data_source.dart`
- [ ] Deletar `lib/src/data/datasources/interface_logger_data_source.dart`
- [ ] Deletar pasta `lib/src/data/datasources/` (agora vazia)
- [ ] `flutter analyze` ✓ — sem erros de import circular

---

## Step 6 — Datasource stubs locais

- [ ] Criar `lib/src/infrastructure/datasources/local/expense_local_data_source.dart`
  — `ExpenseLocalDataSource implements IExpenseDataSource`, todos os métodos
  lançam `UnimplementedError('Offline-first not implemented yet.')`
- [ ] Criar `lib/src/infrastructure/datasources/local/budget_local_data_source.dart`
  — `BudgetLocalDataSource implements IBudgetDataSource`, todos os métodos
  lançam `UnimplementedError('Offline-first not implemented yet.')`
- [ ] `flutter analyze` ✓

---

## Step 7 — Mappers em data/mappers/

- [ ] Criar `lib/src/data/mappers/expense_mapper.dart`
  — `ExpenseEntityToModelMapper`: `value: String` → `amount: double.parse()`,
  `date: String` → `date: int` (milliseconds), `category: null` → `''`
  — `ExpenseModelToEntityMapper`: inverso, `amount: double` → `value: String`
- [ ] Criar `lib/src/data/mappers/budget_mapper.dart`
  — `BudgetEntityToModelMapper` e `BudgetModelToEntityMapper`
- [ ] Criar `test/src/data/mappers/expense_mapper_test.dart`
  — testar: decimal string, date, category null, round-trip
- [ ] Criar `test/src/data/mappers/budget_mapper_test.dart`
- [ ] `flutter test` ✓

---

## Step 8 — Repository implementations em data/repositories/

- [ ] Criar `lib/src/data/repositories/expense_repository.dart`
  — `ExpenseRepository implements IExpenseRepository`
  — recebe `IExpenseDataSource`, `ExpenseEntityToModelMapper`, `ExpenseModelToEntityMapper`
  — todos os métodos: `throw UnimplementedError('Implement when async migration is done.')`
  — adicionar comentário `// TODO: converter para Future<Either<Failure,T>> na migração Riverpod`
- [ ] Criar `lib/src/data/repositories/budget_repository.dart`
  — `BudgetRepository implements IBudgetRepository`, mesmo padrão
- [ ] `flutter analyze` ✓

---

## Step 9 — Atualizar injection.dart

- [ ] Adicionar imports dos novos datasources, repositórios e mappers
- [ ] Registrar `IExpenseDataSource` → `ExpenseLocalDataSource.new`
- [ ] Registrar `IBudgetDataSource` → `BudgetLocalDataSource.new`
- [ ] Registrar mappers como factories:
  `ExpenseEntityToModelMapper`, `ExpenseModelToEntityMapper`,
  `BudgetEntityToModelMapper`, `BudgetModelToEntityMapper`
- [ ] Registrar `IExpenseRepository` → `ExpenseRepository(dataSource: sl(), toModel: sl(), toEntity: sl())`
- [ ] Registrar `IBudgetRepository` → `BudgetRepository(dataSource: sl(), toModel: sl(), toEntity: sl())`
- [ ] `flutter analyze` ✓

---

## Step 10 — Atualizar mocks e testes

- [ ] Adicionar em `test/mocks/mocks.dart`:
  `MockExpenseDataSource extends Mock implements IExpenseDataSource`
  `MockBudgetDataSource extends Mock implements IBudgetDataSource`
- [ ] Adicionar `registerFallbackValue` para `ExpenseEntity` e `BudgetEntity`
- [ ] `flutter test` ✓ — todos os testes passando

---

## Verificação Final

- [ ] `flutter analyze` — zero warnings e erros
- [ ] `flutter test` — 100% passing
- [ ] Verificar que nenhum arquivo em `infrastructure/` importa de `domain/`
- [ ] Verificar que nenhum arquivo em `data/` importa implementações concretas de `infrastructure/`
- [ ] App roda sem `GetItError` em runtime
