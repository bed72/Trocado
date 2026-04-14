# Spec: correcao-arquitetura-clean-arch

## Requirements

---

### Requirement: Domain Errors

The system SHALL define a `sealed class Failure` in `lib/src/domain/errors/failure.dart`
with subtypes `NetworkFailure`, `NotFoundFailure`, `ServerFailure`, `DatabaseFailure`,
`ValidationFailure` e `UnknownFailure`.

The system SHALL expose a `message` field em cada `Failure`.

#### Scenario: Failure padrão
Given um erro de rede sem mensagem customizada
When `NetworkFailure()` é instanciado
Then `failure.message` retorna uma string não vazia padrão

#### Scenario: Failure customizada
Given uma mensagem de validação específica
When `ValidationFailure('Valor deve ser maior que zero')` é instanciado
Then `failure.message` retorna `'Valor deve ser maior que zero'`

#### Scenario: toString
Given qualquer `Failure`
When `failure.toString()` é chamado
Then retorna o valor de `failure.message`

---

### Requirement: Repository Interfaces com Failure

The system SHALL update `IExpenseRepository` e `IBudgetRepository` para retornar
`Either<Failure, T>` em vez de `Either<String, T>`.

#### Scenario: Interface atualizada compila
Given os repositórios atualizados
When `flutter analyze` é executado
Then zero erros relacionados a tipos Either

---

### Requirement: Expense Entity alinhada com openapi.json

The system SHALL define `ExpenseEntity` em
`lib/src/infrastructure/clients/database/entities/expense_entity.dart`
com os campos: `id`, `value` (String decimal), `description`, `date` (ISO date),
`category` (nullable), `createdAt` (nullable).

The system SHALL define `PaginatedExpenses` como wrapper de cursor pagination
com campos `next`, `previous` e `results`.

#### Scenario: Campos obrigatórios do backend
Given a resposta `GET /api/v1/expenses/`
When os campos do schema `Expenses` do openapi.json são mapeados
Then `id`, `value`, `created_at` e `category` estão presentes na entity

#### Scenario: Category nullable
Given uma despesa cujo backend não atribuiu categoria
When a entity é criada com `category: null`
Then o campo `category` aceita `null` sem exceção

---

### Requirement: Budget Entity alinhada com openapi.json

The system SHALL define `BudgetEntity` com campos: `id`, `value`, `startDate`, `endDate`,
`description`, `totalSpent`, `remaining`, `createdAt`.

#### Scenario: Campos computados do backend
Given a resposta `GET /api/v1/budgets/active/`
When o schema `Budgets` é mapeado
Then `total_spent` e `remaining` estão presentes como `String` na entity

---

### Requirement: Datasource Interfaces em infrastructure/

The system SHALL define `IExpenseDataSource` em
`lib/src/infrastructure/datasources/expense_data_source.dart`
retornando `Future<PaginatedExpenses>` para listagem e `Future<void>` para mutações.

The system SHALL define `IBudgetDataSource` em
`lib/src/infrastructure/datasources/budget_data_source.dart`
com métodos para `findAll`, `findActive`, `upsert` e `deleteById`.

The system SHALL NOT use `Either`, `Failure` ou qualquer tipo de `domain/`
nas interfaces de datasource.

#### Scenario: Datasource independente de domain
Given `expense_data_source.dart`
When o arquivo é inspecionado por imports
Then não há import de `domain/` em nenhuma linha

---

### Requirement: Logger Datasource Interface movida

The system SHALL move `ILoggerDataSource` de `lib/src/data/datasources/`
para `lib/src/infrastructure/datasources/logger_data_source.dart`.

The system SHALL update o import em `logger_local_data_source.dart`.

The system SHALL delete a pasta `lib/src/data/datasources/` após a movimentação.

#### Scenario: Importação circular eliminada
Given `logger_local_data_source.dart` atualizado
When `flutter analyze` é executado
Then nenhum erro de import circular entre `infrastructure/` e `data/`

---

### Requirement: Datasource Stubs Locais

The system SHALL define `ExpenseLocalDataSource` e `BudgetLocalDataSource`
em `lib/src/infrastructure/datasources/local/`
implementando as respectivas interfaces e lançando `UnimplementedError`
com a mensagem `'Offline-first not implemented yet.'`.

#### Scenario: Stub é instanciável
Given `ExpenseLocalDataSource()`
When instanciado sem argumentos
Then não lança exceção na construção

#### Scenario: Stub sinaliza intenção
Given `ExpenseLocalDataSource()`
When `findByPeriod(...)` é chamado
Then lança `UnimplementedError` com mensagem contendo `'not implemented'`

---

### Requirement: Mappers entity ↔ domain model

The system SHALL define `ExpenseEntityToModelMapper` e `ExpenseModelToEntityMapper`
em `lib/src/data/mappers/expense_mapper.dart`.

The system SHALL define `BudgetEntityToModelMapper` e `BudgetModelToEntityMapper`
em `lib/src/data/mappers/budget_mapper.dart`.

The system SHALL convert `value: String` → `amount: double` via `double.parse()`.

The system SHALL convert `date: String` → `date: int` via
`DateTime.parse(date).millisecondsSinceEpoch`.

The system SHALL convert `category: null` → `category: ''` no modelo de domínio.

#### Scenario: Conversão de valor decimal
Given `ExpenseEntity(value: '85.50', ...)`
When `ExpenseEntityToModelMapper` é aplicado
Then `model.amount == 85.50`

#### Scenario: Conversão de data
Given `ExpenseEntity(date: '2026-03-15', ...)`
When o mapper é aplicado
Then `model.date == DateTime.parse('2026-03-15').millisecondsSinceEpoch`

#### Scenario: Category null → string vazia
Given `ExpenseEntity(category: null, ...)`
When o mapper é aplicado
Then `model.category == ''`

#### Scenario: Round-trip entity → model → entity preserva dados
Given uma entity com todos os campos preenchidos
When convertida para model e de volta para entity
Then `id`, `value`, `description` e `date` são preservados

---

### Requirement: Repository Implementations

The system SHALL define `ExpenseRepository` e `BudgetRepository`
em `lib/src/data/repositories/`
implementando as interfaces de `domain/repositories/`.

The system SHALL inject `IExpenseDataSource` (interface) — nunca a implementação concreta.

The system SHALL throw `UnimplementedError` nos métodos até a migração async Riverpod.

#### Scenario: Repository usa interface de datasource
Given `ExpenseRepository`
When inspecionado por imports
Then depende de `IExpenseDataSource`, não de `ExpenseLocalDataSource`

---

### Requirement: DI registrado

The system SHALL register em `injection.dart`:
- `IExpenseDataSource` → `ExpenseLocalDataSource`
- `IBudgetDataSource` → `BudgetLocalDataSource`
- `IExpenseRepository` → `ExpenseRepository`
- `IBudgetRepository` → `BudgetRepository`
- Mappers de expense e budget como factories

#### Scenario: App inicializa sem crash de DI
Given `injection.dart` atualizado com todos os registros
When o app é iniciado e as telas são navegadas
Then nenhum `StateError: No element` ou `GetItError` é lançado

---

### Requirement: Testes atualizados

The system SHALL update `test/mocks/mocks.dart` para incluir
`MockExpenseDataSource` e `MockBudgetDataSource`.

The system SHALL update os testes de BLoC para usar
`Left(const NetworkFailure())` em vez de `Left('mensagem')`.

The system SHALL create testes para os mappers de expense e budget.

The system SHALL create testes para `Failure` (mensagens padrão e customizadas).

#### Scenario: Suite de testes passa
Given todos os arquivos atualizados
When `flutter test` é executado
Then zero falhas e zero erros de compilação
