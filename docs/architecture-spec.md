# Architecture Spec — Trocado Flutter

> Spec de refatoração arquitetural. Guia a implementação passo a passo.
> Cada step é atômico: o projeto deve compilar ao final de cada um.

---

## Contexto

O projeto tem violações de Clean Architecture identificadas:
- Interface de datasource (`ILoggerDataSource`) está na camada `data/` mas pertence a `infrastructure/`
- `infrastructure/` importa de `data/` (dependência circular invertida)
- Não existem implementações concretas de repositórios em `data/`
- Não existem interfaces de datasource para `expense` e `budget`
- Erros são strings cruas (`Either<String, T>`) sem tipagem
- Mapper contract em `domain/contracts/` mas usado como utilitário cross-layer

**Objetivo:** Alinhar à estrutura do app nativo Kotlin (documentado no Obsidian em `Trocado/Native/02 - Architecture.md`), sem tocar em `presentation/`, mantendo o projeto compilável em cada etapa.

---

## Regra de Dependência

```
domain ← data ← infrastructure
domain ← presentation
main → tudo
```

| Camada          | Depende de                          | Nunca conhece                  |
|-----------------|-------------------------------------|--------------------------------|
| `domain/`       | nada                                | tudo                           |
| `data/`         | `domain/` + interfaces de `infrastructure/` | `presentation/`, `main/` |
| `infrastructure/` | suas próprias interfaces           | `domain/`, `data/`, `presentation/` |
| `presentation/` | `domain/` (models + interfaces)     | `data/`, `infrastructure/`     |
| `main/`         | tudo                                | —                              |

> **Regra crítica**: `infrastructure/` nunca importa de `domain/` ou `data/`.
> Datasource interfaces retornam tipos próprios de `infrastructure/` (entities, tipos primitivos) — não domain models.
> A conversão entity → domain model é responsabilidade de `data/mappers/`.

---

## Estrutura Alvo

```
lib/
├── main.dart
├── app_widget.dart
├── app_route.dart
└── src/
    ├── main/
    │   ├── injection.dart              ← atualizado com novos registros
    │   └── locations/                  ← sem alteração
    │
    ├── domain/                         ← Dart puro, zero Flutter
    │   ├── errors/                     ← NEW
    │   │   └── failure.dart            ← sealed class Failure
    │   ├── models/                     ← sem alteração
    │   │   ├── expense_model.dart
    │   │   ├── category_model.dart
    │   │   └── budget/
    │   │       ├── budget_model.dart
    │   │       └── budget_summary_model.dart
    │   ├── contracts/
    │   │   └── mapper.dart             ← sem alteração
    │   ├── either/
    │   │   └── either.dart             ← sem alteração
    │   └── repositories/
    │       ├── interface_expense_repository.dart   ← Either<String> → Either<Failure>
    │       └── interface_budget_repository.dart    ← Either<String> → Either<Failure>
    │
    ├── application/
    │   └── services/
    │       └── money_service.dart      ← sem alteração
    │
    ├── data/                           ← implementa contratos de domain
    │   ├── mappers/                    ← NEW (pasta)
    │   │   ├── expense_mapper.dart     ← ExpenseEntity ↔ ExpenseModel
    │   │   └── budget_mapper.dart      ← BudgetEntity ↔ BudgetModel
    │   └── repositories/              ← NEW (pasta)
    │       ├── expense_repository.dart ← implements IExpenseRepository
    │       └── budget_repository.dart  ← implements IBudgetRepository
    │
    └── infrastructure/                 ← clientes externos e framework-specific
        ├── clients/
        │   ├── database/
        │   │   └── entities/           ← NEW (pasta)
        │   │       ├── expense_entity.dart   ← plain data class, sem ORM
        │   │       └── budget_entity.dart    ← plain data class, sem ORM
        │   ├── http/                   ← NEW (pasta, placeholder)
        │   │   └── .gitkeep
        │   └── logger/
        │       └── logger_client.dart  ← sem alteração
        └── datasources/
            ├── expense_data_source.dart    ← NEW interface (Future<T>)
            ├── budget_data_source.dart     ← NEW interface (Future<T>)
            ├── logger_data_source.dart     ← MOVE de data/datasources/
            └── local/
                ├── expense_local_data_source.dart   ← NEW stub
                ├── budget_local_data_source.dart    ← NEW stub
                └── logger_local_data_source.dart    ← atualizar import
```

---

## Steps de Implementação

### Step 1 — `domain/errors/failure.dart` (sem deps, não quebra nada)

**Criar:** `lib/src/domain/errors/failure.dart`

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com o servidor.']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro interno do servidor.']);
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Erro ao acessar o banco de dados.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Erro desconhecido.']);
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 2 — Atualizar `Either<String>` → `Either<Failure>` nos contratos de domain

**Atualizar:** `lib/src/domain/repositories/interface_expense_repository.dart`

```dart
import 'package:trocado/src/domain/errors/failure.dart';
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';

abstract interface class IExpenseRepository {
  Either<Failure, void> deleteById(int id);
  Either<Failure, ExpenseModel> findById(int id);
  Either<Failure, void> upsert(ExpenseModel model);
  Either<Failure, List<ExpenseModel>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  });
}
```

**Atualizar:** `lib/src/domain/repositories/interface_budget_repository.dart`

```dart
import 'package:trocado/src/domain/errors/failure.dart';
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';

abstract interface class IBudgetRepository {
  Either<Failure, void> deleteById(int id);
  Either<Failure, List<BudgetModel>> findAll();
  Either<Failure, void> upsert(BudgetModel model);
  Either<Failure, BudgetModel?> findActive(int currentDate);
}
```

**Atualizar BLoCs** (mínimo, para compilar):
Nos `fold()` onde `failure` era `String`, trocar por `failure.message`:

```dart
// antes
result.fold(
  (failure) => emit(state.copyWith(message: failure)),
  ...
)

// depois
result.fold(
  (failure) => emit(state.copyWith(message: failure.message)),
  ...
)
```

Arquivos afetados:
- `lib/src/presentation/bloc/expense_list/expense_list_bloc.dart`
- `lib/src/presentation/bloc/expense_form/expense_form_bloc.dart`
- `lib/src/presentation/bloc/budget/budget_bloc.dart`

**Atualizar mocks de teste:** `test/mocks/mocks.dart` — os mocks de repositório continuam funcionando porque implementam a interface (o tipo de retorno muda automaticamente).

**Atualizar testes existentes** onde `thenReturn(Left('mensagem'))`:

```dart
// antes
when(() => repo.findByPeriod(...)).thenReturn(Left('erro'));

// depois
when(() => repo.findByPeriod(...)).thenReturn(Left(const NetworkFailure('erro')));
```

**Verificar:** `flutter test` todos passando.

---

### Step 3 — Entities em `infrastructure/clients/database/entities/`

**Criar:** `lib/src/infrastructure/clients/database/entities/expense_entity.dart`

```dart
// Plain data class — sem anotações de ORM.
// Quando offline-first for implementado, adicionar anotações aqui.
final class ExpenseEntity {
  const ExpenseEntity({
    this.id,
    required this.value,
    required this.description,
    required this.date,
    this.category,
  });

  final int? id;
  final double value;
  final String description;
  final String date;      // ISO 8601: "2026-03-15"
  final String? category; // atribuído automaticamente pelo backend
}
```

**Criar:** `lib/src/infrastructure/clients/database/entities/budget_entity.dart`

```dart
final class BudgetEntity {
  const BudgetEntity({
    this.id,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.description,
  });

  final int? id;
  final double value;
  final String startDate; // ISO 8601: "2026-03-01"
  final String endDate;   // ISO 8601: "2026-03-31"
  final String? description;
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 4 — Datasource interfaces em `infrastructure/datasources/`

> Interfaces retornam `Future<T>` (async por natureza) e tipos próprios da infraestrutura (entities).
> **Não usam `Either` nem `Failure`** — infrastructure não conhece domain.
> O repository (data layer) é quem converte exceções em `Left(Failure)`.

**Criar:** `lib/src/infrastructure/datasources/expense_data_source.dart`

```dart
import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';

abstract interface class IExpenseDataSource {
  Future<List<ExpenseEntity>> findByPeriod({
    required int startAt,
    required int endAt,
    int limit = 20,
    int offset = 0,
  });
  Future<ExpenseEntity?> findById(int id);
  Future<void> upsert(ExpenseEntity entity);
  Future<void> deleteById(int id);
}
```

**Criar:** `lib/src/infrastructure/datasources/budget_data_source.dart`

```dart
import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

abstract interface class IBudgetDataSource {
  Future<List<BudgetEntity>> findAll();
  Future<BudgetEntity?> findActive(String currentDate);
  Future<void> upsert(BudgetEntity entity);
  Future<void> deleteById(int id);
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 5 — Mover `ILoggerDataSource` para `infrastructure/`

**Mover:** `lib/src/data/datasources/interface_logger_data_source.dart`
→ `lib/src/infrastructure/datasources/logger_data_source.dart`

**Renomear classe** de `ILoggerDataSource` para `ILoggerDataSource` (sem alteração) mas **atualizar o path do import** em:
- `lib/src/infrastructure/datasources/local/logger_local_data_source.dart`

```dart
// antes
import 'package:trocado/src/data/datasources/interface_logger_data_source.dart';

// depois
import 'package:trocado/src/infrastructure/datasources/logger_data_source.dart';
```

**Deletar:** `lib/src/data/datasources/interface_logger_data_source.dart`

**Verificar:** `flutter analyze` sem erros.

---

### Step 6 — Datasource stubs locais em `infrastructure/datasources/local/`

> Stubs para habilitar a estrutura sem implementação real.
> `UnimplementedError` sinaliza claramente que precisa ser preenchido.

**Criar:** `lib/src/infrastructure/datasources/local/expense_local_data_source.dart`

```dart
import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';
import 'package:trocado/src/infrastructure/datasources/expense_data_source.dart';

final class ExpenseLocalDataSource implements IExpenseDataSource {
  @override
  Future<List<ExpenseEntity>> findByPeriod({
    required int startAt,
    required int endAt,
    int limit = 20,
    int offset = 0,
  }) => throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<ExpenseEntity?> findById(int id) =>
      throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<void> upsert(ExpenseEntity entity) =>
      throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<void> deleteById(int id) =>
      throw UnimplementedError('Offline-first not implemented yet.');
}
```

**Criar:** `lib/src/infrastructure/datasources/local/budget_local_data_source.dart`

```dart
import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';
import 'package:trocado/src/infrastructure/datasources/budget_data_source.dart';

final class BudgetLocalDataSource implements IBudgetDataSource {
  @override
  Future<List<BudgetEntity>> findAll() =>
      throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<BudgetEntity?> findActive(String currentDate) =>
      throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<void> upsert(BudgetEntity entity) =>
      throw UnimplementedError('Offline-first not implemented yet.');

  @override
  Future<void> deleteById(int id) =>
      throw UnimplementedError('Offline-first not implemented yet.');
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 7 — Mappers em `data/mappers/`

> Mappers são funções puras que convertem entity ↔ domain model.
> Implementam `Mapper<IN, OUT>` de `domain/contracts/mapper.dart`.

**Criar:** `lib/src/data/mappers/expense_mapper.dart`

```dart
import 'package:trocado/src/domain/contracts/mapper.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/expense_entity.dart';

final class ExpenseEntityToModelMapper
    implements Mapper<ExpenseEntity, ExpenseModel> {
  const ExpenseEntityToModelMapper();

  @override
  ExpenseModel call(ExpenseEntity entity) => ExpenseModel(
        id: entity.id,
        amount: entity.value,
        description: entity.description,
        category: entity.category ?? '',
        date: DateTime.parse(entity.date).millisecondsSinceEpoch,
      );
}

final class ExpenseModelToEntityMapper
    implements Mapper<ExpenseModel, ExpenseEntity> {
  const ExpenseModelToEntityMapper();

  @override
  ExpenseEntity call(ExpenseModel model) => ExpenseEntity(
        id: model.id,
        value: model.amount,
        description: model.description,
        category: model.category.isEmpty ? null : model.category,
        date: DateTime.fromMillisecondsSinceEpoch(model.date)
            .toIso8601String()
            .substring(0, 10),
      );
}
```

**Criar:** `lib/src/data/mappers/budget_mapper.dart`

```dart
import 'package:trocado/src/domain/contracts/mapper.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/infrastructure/clients/database/entities/budget_entity.dart';

final class BudgetEntityToModelMapper
    implements Mapper<BudgetEntity, BudgetModel> {
  const BudgetEntityToModelMapper();

  @override
  BudgetModel call(BudgetEntity entity) => BudgetModel(
        id: entity.id,
        amount: entity.value,
        description: entity.description,
        startDate: DateTime.parse(entity.startDate).millisecondsSinceEpoch,
        endDate: DateTime.parse(entity.endDate).millisecondsSinceEpoch,
      );
}

final class BudgetModelToEntityMapper
    implements Mapper<BudgetModel, BudgetEntity> {
  const BudgetModelToEntityMapper();

  @override
  BudgetEntity call(BudgetModel model) => BudgetEntity(
        id: model.id,
        value: model.amount,
        description: model.description,
        startDate: DateTime.fromMillisecondsSinceEpoch(model.startDate)
            .toIso8601String()
            .substring(0, 10),
        endDate: DateTime.fromMillisecondsSinceEpoch(model.endDate)
            .toIso8601String()
            .substring(0, 10),
      );
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 8 — Repository implementations em `data/repositories/`

> Repositórios implementam as interfaces de `domain/`.
> Dependem de interfaces de datasource de `infrastructure/` — nunca das implementações concretas.
> Convertem exceções do datasource em `Left(Failure)`.
>
> **Nota temporária:** Os repositórios atuais chamam datasources async (Future) a partir de uma
> interface sync (Either<Failure, T>). Isso é uma limitação transitória: quando a migração para
> Riverpod + async completar, as interfaces de repositório também serão async.
> Por ora, os repositórios lançam `UnimplementedError` e serão preenchidos na migração.

**Criar:** `lib/src/data/repositories/expense_repository.dart`

```dart
import 'package:trocado/src/domain/errors/failure.dart';
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/expense_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';
import 'package:trocado/src/infrastructure/datasources/expense_data_source.dart';
import 'package:trocado/src/data/mappers/expense_mapper.dart';

final class ExpenseRepository implements IExpenseRepository {
  const ExpenseRepository({
    required IExpenseDataSource dataSource,
    required ExpenseEntityToModelMapper toModel,
    required ExpenseModelToEntityMapper toEntity,
  }) : _dataSource = dataSource,
       _toModel = toModel,
       _toEntity = toEntity;

  final IExpenseDataSource _dataSource;
  final ExpenseEntityToModelMapper _toModel;
  final ExpenseModelToEntityMapper _toEntity;

  // TODO: converter para async (Future<Either<Failure, T>>) na migração Riverpod
  @override
  Either<Failure, void> deleteById(int id) =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, ExpenseModel> findById(int id) =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, void> upsert(ExpenseModel model) =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, List<ExpenseModel>> findByPeriod({
    int? limit,
    int? offset,
    int? startAt,
    int? endAt,
  }) => throw UnimplementedError('Implement when async migration is done.');
}
```

**Criar:** `lib/src/data/repositories/budget_repository.dart`

```dart
import 'package:trocado/src/domain/errors/failure.dart';
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';
import 'package:trocado/src/infrastructure/datasources/budget_data_source.dart';
import 'package:trocado/src/data/mappers/budget_mapper.dart';

final class BudgetRepository implements IBudgetRepository {
  const BudgetRepository({
    required IBudgetDataSource dataSource,
    required BudgetEntityToModelMapper toModel,
    required BudgetModelToEntityMapper toEntity,
  }) : _dataSource = dataSource,
       _toModel = toModel,
       _toEntity = toEntity;

  final IBudgetDataSource _dataSource;
  final BudgetEntityToModelMapper _toModel;
  final BudgetModelToEntityMapper _toEntity;

  // TODO: converter para async (Future<Either<Failure, T>>) na migração Riverpod
  @override
  Either<Failure, void> deleteById(int id) =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, List<BudgetModel>> findAll() =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, void> upsert(BudgetModel model) =>
      throw UnimplementedError('Implement when async migration is done.');

  @override
  Either<Failure, BudgetModel?> findActive(int currentDate) =>
      throw UnimplementedError('Implement when async migration is done.');
}
```

**Verificar:** `flutter analyze` sem erros.

---

### Step 9 — Atualizar `injection.dart`

Registrar os novos datasources e repositórios.

```dart
// Data Sources (Infrastructure)
sl.registerLazySingleton<IExpenseDataSource>(ExpenseLocalDataSource.new);
sl.registerLazySingleton<IBudgetDataSource>(BudgetLocalDataSource.new);

// Mappers (Data)
sl
  ..registerFactory(ExpenseEntityToModelMapper.new)
  ..registerFactory(ExpenseModelToEntityMapper.new)
  ..registerFactory(BudgetEntityToModelMapper.new)
  ..registerFactory(BudgetModelToEntityMapper.new);

// Repositories (Data)
sl.registerLazySingleton<IExpenseRepository>(
  () => ExpenseRepository(
    dataSource: sl(),
    toModel: sl(),
    toEntity: sl(),
  ),
);
sl.registerLazySingleton<IBudgetRepository>(
  () => BudgetRepository(
    dataSource: sl(),
    toModel: sl(),
    toEntity: sl(),
  ),
);
```

**Verificar:** `flutter analyze` + `flutter test` sem erros.

---

### Step 10 — Organizar testes

**Estrutura alvo de testes** (espelha `lib/src/`):

```
test/
├── mocks/
│   └── mocks.dart                          ← adicionar mocks de datasources
└── src/
    ├── domain/
    │   ├── either_test.dart                ← sem alteração
    │   ├── errors/
    │   │   └── failure_test.dart           ← NEW: testa sealed class
    │   └── services/
    │       └── money_service_test.dart     ← MOVER de domain/services/
    ├── data/
    │   ├── mappers/
    │   │   ├── expense_mapper_test.dart    ← NEW
    │   │   └── budget_mapper_test.dart     ← NEW
    │   └── repositories/                  ← para quando as implementações chegarem
    └── presentation/
        └── bloc/                          ← sem alteração (atualizar Left() para Failure)
            ├── budget_bloc_test.dart
            ├── expense_form_bloc_test.dart
            └── expense_list_bloc_test.dart
```

**Adicionar mocks em** `test/mocks/mocks.dart`:

```dart
// Datasources
final class MockExpenseDataSource extends Mock implements IExpenseDataSource {}
final class MockBudgetDataSource extends Mock implements IBudgetDataSource {}
```

**Verificar:** `flutter test` todos passando.

---

## Resumo de Arquivos

### Criar
| Arquivo | Descrição |
|---|---|
| `lib/src/domain/errors/failure.dart` | sealed class Failure + subtipos |
| `lib/src/infrastructure/clients/database/entities/expense_entity.dart` | Entity sem ORM |
| `lib/src/infrastructure/clients/database/entities/budget_entity.dart` | Entity sem ORM |
| `lib/src/infrastructure/datasources/expense_data_source.dart` | Interface async |
| `lib/src/infrastructure/datasources/budget_data_source.dart` | Interface async |
| `lib/src/infrastructure/datasources/logger_data_source.dart` | Movido de data/ |
| `lib/src/infrastructure/datasources/local/expense_local_data_source.dart` | Stub |
| `lib/src/infrastructure/datasources/local/budget_local_data_source.dart` | Stub |
| `lib/src/data/mappers/expense_mapper.dart` | Entity ↔ Model |
| `lib/src/data/mappers/budget_mapper.dart` | Entity ↔ Model |
| `lib/src/data/repositories/expense_repository.dart` | Implementação |
| `lib/src/data/repositories/budget_repository.dart` | Implementação |
| `test/src/domain/errors/failure_test.dart` | Testes de Failure |
| `test/src/data/mappers/expense_mapper_test.dart` | Testes de mapper |
| `test/src/data/mappers/budget_mapper_test.dart` | Testes de mapper |

### Renomear / Mover
| De | Para |
|---|---|
| `lib/src/data/datasources/interface_logger_data_source.dart` | `lib/src/infrastructure/datasources/logger_data_source.dart` |

### Atualizar
| Arquivo | O que muda |
|---|---|
| `lib/src/domain/repositories/interface_expense_repository.dart` | `Either<String>` → `Either<Failure>` |
| `lib/src/domain/repositories/interface_budget_repository.dart` | `Either<String>` → `Either<Failure>` |
| `lib/src/infrastructure/datasources/local/logger_local_data_source.dart` | import path |
| `lib/src/main/injection.dart` | registrar datasources + repos |
| `lib/src/presentation/bloc/*/` | `failure` → `failure.message` nos fold() |
| `test/mocks/mocks.dart` | adicionar datasource mocks |
| `test/src/presentation/bloc/*_test.dart` | `Left('msg')` → `Left(Failure('msg'))` |

### Deletar
| Arquivo | Razão |
|---|---|
| `lib/src/data/datasources/interface_logger_data_source.dart` | movido para infrastructure/ |
| `lib/src/data/datasources/` (pasta vazia) | não existem mais datasources em data/ |

---

## Decisões Arquiteturais

| Decisão | Escolha | Razão |
|---|---|---|
| Interfaces de datasource em `infrastructure/` | Sim | Datasources falam em entities (tipos de framework) — pertencem à infra |
| Datasources retornam `Future<T>` (sem Either) | Sim | Infrastructure não conhece domain. Repository converte exceções em Failure |
| Repository interfaces continuam síncronas | Temporário | BLoCs existentes dependem de sync. Mudar para async na migração Riverpod |
| Repository implementations com `UnimplementedError` | Sim | Viabiliza estrutura correta sem implementação prematura |
| Entities sem anotações de ORM | Sim | Aguarda decisão de storage local (sem ObjectBox) |
| `domain/contracts/mapper.dart` mantido | Sim | Puro Dart, zero deps, usado como contrato cross-layer |
| `category` no `ExpenseEntity` como `String?` | Sim | Atribuída pelo backend automaticamente; opcional localmente |

---

## Próximos Passos (fora deste spec)

1. **Migração Riverpod** — substituir BLoCs por Notifiers, GetIt por providers, repository interfaces async
2. **Remote datasources** — implementar HTTP client + datasources remotos (guiado por `openapi.yaml`)
3. **Offline-first** — preencher `ExpenseLocalDataSource` + `BudgetLocalDataSource` (Room/Drift)
4. **Autenticação** — JWT + refresh interceptor (ver `Trocado/Native/04 - Telas de Autenticação.md`)
