# Design: correcao-arquitetura-clean-arch

## Fluxo de dados (imutável)

```
Notifier → Repository → DataSource → Client (Dio)
```

Use cases são opcionais — criar apenas quando o Notifier orquestrar múltiplos
repositórios ou ultrapassar ~20 linhas de lógica de negócio.

## Regra de Dependência (imutável)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

| Camada            | Depende de                                    | Nunca conhece                        |
|-------------------|-----------------------------------------------|--------------------------------------|
| `domain/`         | nada                                          | tudo                                 |
| `data/`           | `domain/` + interfaces de `infrastructure/`  | `presentation/`, `main/`             |
| `infrastructure/` | suas próprias interfaces                      | `domain/`, `data/`, `presentation/`  |
| `presentation/`   | `domain/` (models + interfaces)               | `data/`, `infrastructure/`           |
| `main/`           | tudo                                          | —                                    |

---

## Decisões Técnicas

### 1. `sealed class Failure` em `domain/errors/`

Erros tipados permitem tratar categorias diferentes de falha sem inspecionar strings.

```
Failure (sealed)
├── NetworkFailure      — sem conexão, timeout
├── NotFoundFailure     — recurso não encontrado (404)
├── ServerFailure       — erro interno do servidor (5xx)
├── DatabaseFailure     — erro de storage local
├── ValidationFailure   — validação de negócio (mensagem customizada)
└── UnknownFailure      — fallback
```

Repositórios retornam `Either<Failure, T>`.
BLoCs existentes precisam de ajuste mínimo: `failure` → `failure.message` nos `fold()`.

### 2. Datasource interfaces em `infrastructure/` — sem `Either`, sem `Failure`

Seguindo a arquitetura nativa Kotlin: datasource interfaces falam em termos de entities
(tipos próprios da infra) e retornam `Future<T>` puro. Quem converte exceções em
`Left(Failure)` é o repositório em `data/`.

```dart
// ✅ infrastructure — Future<T>, sem domínio
abstract interface class IExpenseDataSource {
  Future<List<ExpenseEntity>> findByPeriod({...});
  Future<void> upsert(ExpenseEntity entity);
}

// ✅ data — Either<Failure, T>, com domínio
final class ExpenseRepository implements IExpenseRepository {
  Either<Failure, List<ExpenseModel>> findByPeriod({...}) {
    try {
      final entities = _dataSource.findByPeriod(...); // Future — limitação transitória
      return Right(entities.map(_toModel.call).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

### 3. Limitação transitória: repositórios síncronos com datasources async

Os repositórios do `domain/` definem contratos síncronos (`Either<Failure, T>` sem `Future`)
porque os BLoCs existentes os chamam de forma síncrona. Datasources são `Future<T>`.

Esta incompatibilidade é resolvida nos repository stubs com `throw UnimplementedError()`.
Na migração Riverpod (próximo ciclo), os repositórios se tornarão
`Future<Either<Failure, T>>` e os BLoCs serão substituídos por Notifiers async.

### 4. Entities sem anotações de ORM

`ExpenseEntity` e `BudgetEntity` são plain Dart classes por ora.
Quando offline-first for implementado, as anotações (Drift, Floor, etc.) são adicionadas
sem alterar as interfaces de datasource.

```dart
// Alinhado com openapi.json — schemas Expenses e Budgets
final class ExpenseEntity {
  final int? id;
  final String value;      // decimal string: "85.50"
  final String description;
  final String date;       // ISO 8601 date: "2026-03-15"
  final String? category;  // readOnly no backend, nullable
  final String? createdAt; // readOnly, date-time
}
```

### 5. Paginação cursor-based (openapi.json)

O backend usa cursor pagination (`next`/`previous` como URLs).
As entities e datasource interfaces já refletem isso:

```dart
// PaginatedExpensesList do openapi.json
final class PaginatedExpenses {
  final String? next;
  final String? previous;
  final List<ExpenseEntity> results;
}
```

O datasource retorna `PaginatedExpenses`, não `List<ExpenseEntity>` diretamente.

### 6. DI: GetIt mantido neste ciclo

`injection.dart` com GetIt é mantido e expandido com os novos registros.
A migração para `ProviderScope` do Riverpod é o próximo ciclo.

---

## Estrutura alvo

```
lib/src/
├── domain/
│   ├── errors/
│   │   └── failure.dart                    ← NEW
│   ├── models/                             (sem alteração)
│   └── repositories/
│       ├── interface_expense_repository.dart   ← Either<Failure>
│       └── interface_budget_repository.dart    ← Either<Failure>
│
├── application/
│   └── services/
│       └── money_service.dart              ← sem alteração
│
├── infrastructure/
│   ├── clients/
│   │   └── database/
│   │       └── entities/
│   │           ├── expense_entity.dart     ← NEW (plain, sem ORM)
│   │           └── budget_entity.dart      ← NEW (plain, sem ORM)
│   └── datasources/
│       ├── expense_data_source.dart        ← NEW interface
│       ├── budget_data_source.dart         ← NEW interface
│       ├── logger_data_source.dart         ← MOVE de data/datasources/
│       └── local/
│           ├── expense_local_data_source.dart  ← NEW stub
│           ├── budget_local_data_source.dart   ← NEW stub
│           └── logger_local_data_source.dart   ← atualizar import
│
├── data/
│   ├── mappers/
│   │   ├── expense_mapper.dart             ← NEW
│   │   └── budget_mapper.dart              ← NEW
│   └── repositories/
│       ├── expense_repository.dart         ← NEW (stub + UnimplementedError)
│       └── budget_repository.dart          ← NEW (stub + UnimplementedError)
│
└── main/
    └── injection.dart                      ← registrar novos datasources e repos
```

---

## Mapeamento openapi.json → entities

| Schema openapi.json | Entity Flutter | Observação |
|---|---|---|
| `Expenses.value` | `ExpenseEntity.value: String` | decimal string `"85.50"` |
| `Expenses.date` | `ExpenseEntity.date: String` | ISO date `"2026-03-15"` |
| `Expenses.category` | `ExpenseEntity.category: String?` | readOnly, nullable |
| `Expenses.created_at` | `ExpenseEntity.createdAt: String?` | readOnly, date-time |
| `PaginatedExpensesList` | `PaginatedExpenses` | cursor: `next`/`previous` |
| `Budgets.value` | `BudgetEntity.value: String` | decimal string |
| `Budgets.total_spent` | `BudgetEntity.totalSpent: String` | readOnly, default "0.00" |
| `Budgets.remaining` | `BudgetEntity.remaining: String` | readOnly, default "0.00" |

## Mapeamento entity → domain model

| Entity | Domain Model | Conversão |
|---|---|---|
| `value: String` | `amount: double` | `double.parse(value)` |
| `date: String` | `date: int` | `DateTime.parse(date).millisecondsSinceEpoch` |
| `category: String?` | `category: String` | `category ?? ''` |
| `total_spent: String` | `BudgetSummaryModel.spent` | `double.parse(totalSpent)` |
