# Trocado — Flutter App

App de controle financeiro para casais. "Trocado" é o nome coloquial brasileiro para dinheiro.
Consome a API REST Django documentada em `openapi.json`.

## Stack

- **Flutter** (Dart SDK `^3.10.0`) — iOS e Android
- **Riverpod** (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`) — state management e DI
- **Dio** — HTTP client para datasources remotos
- **duck_router** — navegação declarativa por `Location`
- **flex_color_scheme** — tema Material 3, dark mode
- **equatable** — igualdade em modelos de domínio
- **intl** — formatação de moeda e datas em `pt_BR`

## Arquitetura

Clean Architecture estrita. Regra de dependência:

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

| Camada            | Depende de                                   | Nunca conhece                       |
|-------------------|----------------------------------------------|-------------------------------------|
| `domain/`         | nada                                         | tudo                                |
| `data/`           | `domain/` + interfaces de `infrastructure/`  | `presentation/`, `main/`            |
| `infrastructure/` | suas próprias interfaces                     | `domain/`, `data/`, `presentation/` |
| `presentation/`   | `domain/` (models + interfaces)              | `data/`, `infrastructure/`          |
| `main/`           | tudo                                         | —                                   |

---

## Camadas

### `domain/` — Dart puro, zero Flutter

- `failures/failure.dart` — `sealed class Failure` (NetworkFailure, NotFoundFailure, ServerFailure, DatabaseFailure, ValidationFailure, UnknownFailure)
- `models/` — models de domínio (definir por feature, ex: `ExpenseModel`, `CategoryModel`)
- `contracts/repositories/` — interfaces abstratas de repositório (ex: `IExpenseRepository`)
- `either/either.dart` — `Either<L, R>` para tratamento funcional de erros
- `contracts/mapper.dart` — interface base `Mapper<IN, OUT>`

**Regra de ouro:** zero imports de `flutter`, `dart:ui` ou qualquer pacote externo.

### `application/` — Serviços utilitários

- `services/money_service.dart` — formatação de moeda `pt_BR` (`IMoneyService`)

A arquitetura **não tem** `use_cases/`. O fluxo padrão é:

```
Notifier → Repository → DataSource → Client (Dio)
```

### `data/` — Implementa contratos de `domain`

- `repositories/` — implementações de `IXxxRepository`

Repositórios dependem de **interfaces** de datasource (`infrastructure/datasources/`),
nunca das implementações concretas.

### `infrastructure/` — Clientes externos e framework-specific

- `clients/http/requests/` — classes de request com `toJson()` (ex: `SignInRequest`)
- `clients/http/responses/` — classes de response com `fromJson()` (ex: `SignInResponse`)
- `clients/logger/logger_client.dart` — `ILoggerClient` + `LoggerClient`
- `datasources/` — interfaces de datasource (retornam `Future<Model>` puro, sem `Either`, sem `Failure`)
- `datasources/remote/` — usa `Request`/`Response` do cliente HTTP, converte `Response` → `Model`

**Regra:** datasources retornam models de domínio diretamente.
Nunca retornam `Failure` ou `Either` — quem converte exceções é o repositório em `data/`.

### `presentation/` — UI e state

Riverpod Notifiers com padrão MVI: sealed class `XxxIntent` + método `dispatch` + `switch` exhaustivo.
Widgets são `StatelessWidget` puros. Apenas screens usam `Consumer` para acessar providers.

### `main/` — Composition root

- `locations/` — definições de rota com `duck_router`

---

## Padrões de Código

### Code generation

`riverpod_generator` é usado **exclusivamente** para gerar providers Riverpod (`@riverpod`).
Não usar code gen para nenhuma outra finalidade.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Ordenação de membros em classes

Campos e dependências sempre **antes** do construtor:

```dart
class ExpenseState extends Equatable {
  final List<ExpenseModel> expenses;
  final ExpenseStatus status;
  final String message;

  const ExpenseState({
    this.expenses = const [],
    this.status = ExpenseStatus.initial,
    this.message = '',
  });
}
```

### Sem comentários explicativos

Código deve ser autoexplicativo pelo nome de variáveis, métodos e classes.
Nenhum `//` para descrever o que o código faz.

### MVI para formulários e state

Toda interação do usuário é um `Intent`. O Notifier expõe apenas `dispatch`:

```dart
sealed class SignInIntent {}
final class EmailChanged extends SignInIntent {
  final String value;
  const EmailChanged(this.value);
}
final class SubmitPressed extends SignInIntent {}

@riverpod
class SignInNotifier extends _$SignInNotifier {
  @override
  SignInState build() => const SignInState();

  void dispatch(SignInIntent intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(email: value),
    SubmitPressed()            => _submit(),
  };
}
```

### Either para erros

Repositórios retornam `Either<Failure, T>`. Nunca lançam exceptions.

```dart
Either<Failure, List<ExpenseModel>> findByPeriod({int? startAt, int? endAt});

result.fold(
  (failure) => state = state.copyWith(status: Status.failure, message: failure.message),
  (data)    => state = state.copyWith(status: Status.success, expenses: data),
);
```

### Failure tipada

```dart
Left(const NetworkFailure())
Left(const NotFoundFailure())
Left(const ServerFailure())
Left(const DatabaseFailure())
Left(ValidationFailure('mensagem'))
```

### Imutabilidade com copyWith

Todo model e state implementa `copyWith()`.

### Moeda

Valores monetários são `int` em centavos internamente no app.
A API envia/recebe `String` decimal (ex: `"85.50"`).

```dart
int amount = 8550;
moneyService.format(amount / 100);
```

### Datas

- **Domínio / app**: `int` (milliseconds since epoch) ou `DateTime`
- **API**: `String` ISO 8601 — `"2026-03-15"` (date) ou `"2026-03-15T18:30:00Z"` (datetime)
- Conversão no datasource ao deserializar o JSON

### Datasource interfaces

Funções que retornam `Future<T>` não devem ser desnecessariamente encapsuladas.
Funções que retornam `Stream<T>` não são `async`.

### Nomenclatura

| Tipo | Convenção | Exemplo |
|---|---|---|
| Arquivos | `snake_case.dart` | `expense_model.dart` |
| Classes | `PascalCase` | `ExpenseModel` |
| Interfaces | prefixo `I` | `IExpenseRepository` |
| Failures | sufixo `Failure` | `NetworkFailure` |
| Requests | sufixo `Request` | `SignInRequest` |
| Responses | sufixo `Response` | `SignInResponse` |
| Notifiers | sufixo `Notifier` | `SignInNotifier` |
| Intents | sufixo `Intent` | `SignInIntent` |
| Screens | sufixo `Screen` | `HomeScreen` |
| Widgets | sufixo `Widget` | `ButtonWidget` |
| Locations | sufixo `Location` | `HomeLocation` |
| Testes | sufixo `_test.dart` | `expense_model_test.dart` |

---

## Navegação

`duck_router` com `Location` em `lib/src/main/locations/`.

```dart
context.navigate(HomeLocation());
context.navigate(ExpenseLocation(id: 123));
context.pop();
context.root();
```

---

## Testes

```
test/
├── mocks/mocks.dart          ← todos os mocks (mocktail)
└── src/
    ├── domain/               ← testes de models, services, failures
    │   └── failures/         ← testes de Failure
    ├── data/
    │   └── repositories/     ← testes de repositórios
    └── presentation/
        └── providers/        ← testes de Notifiers (ProviderContainer)
```

```bash
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```

---

## SDD — Spec-Driven Development

Contratos da API estão em `openapi.json`.
Antes de implementar qualquer datasource remoto, verificar o contrato do endpoint em `openapi.json`.
Ver skill `/sdd` para o fluxo completo.

---

## Documentação de Referência

- API backend: `openapi.json`
- App nativo Kotlin (referência): Obsidian `Trocado/Native/`
- Backend Django (referência): Obsidian `Trocado/BackEnd/`
