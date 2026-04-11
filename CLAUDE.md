# Trocado — Flutter App

App de controle financeiro para casais. "Trocado" é o nome coloquial brasileiro para dinheiro.
Consome a API REST Django.

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
- `clients/http/responses/failure_response.dart` — `FailureResponse` genérico compartilhado: `{ "errors": [{ "field", "message", "code" }] }`
- `clients/logger/logger_client.dart` — `ILoggerClient` + `LoggerClient`
- `datasources/` — interfaces de datasource retornam `Either<FailureResponse, XxxResponse>`
- `datasources/remote/` — mapeia `Either<Map, Map>` do Client para `Either<FailureResponse, XxxResponse>` via `fromJson`

**Regra:** o único `try-catch` fica no Client. Datasources deserializam ambos os lados do `Either`. Repositórios convertem `FailureResponse → Failure` (via `FailureResponseExtension.toFailure()`) e `XxxResponse → Model`.

- `infrastructure/clients/http/responses/failure/failure_code_response.dart` — enum `FailureCode` com os códigos da API
- `data/extensions/failure_response_extension.dart` — extension `toFailure()` compartilhada por todos os repositórios

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

### Tipos explícitos — sem `var`

Nunca usar `var`. Para `final`, omitir o tipo quando ele é inferível pelo contexto (retorno de método, `fromJson`, etc.). Declarar o tipo explicitamente apenas quando a inferência não é óbvia ou quando aumenta a legibilidade.

```dart
// correto — tipo inferível, omitir
final data = await repository.findAll();
final data = await _dataSource.signIn(parameter: request);

// correto — tipo explícito quando agrega legibilidade
final List<ErrorItemResponse> errors = (json['errors'] as List)
    .map((e) => ErrorItemResponse.fromJson(e as Map<String, dynamic>))
    .toList();

// evitar — var sempre
var data = await repository.findAll();
var errors = [...];
```

### Nomes de variáveis descritivos — sem `result` e sem `either`

Nunca nomear variável de `result` ou `either`. Usar `data` para retorno de operações assíncronas, ou o nome do conceito que representa.

```dart
// correto — implementação
final data = await repository.findAll();
final data = await _dataSource.signIn(parameter: request);

// correto — testes
final data = await repository.signIn(email: 'jane@trocado.app', password: '123');
final state = container.read(expenseNotifierProvider);
final FailureResponse failure = FailureResponse.fromJson(json);

// evitar
final result = await repository.findAll();
final either = await _dataSource.signIn(parameter: request);
```

### Sem comentários explicativos

Código deve ser autoexplicativo pelo nome de variáveis, métodos e classes.
Nenhum `//` para descrever o que o código faz.

### Expression body (`=>`)

Usar `=>` sempre que o corpo da função for uma única expressão. Evitar `return` com chaves nesses casos.

```dart
// correto
Map<String, dynamic> _unknownError() => {
  'errors': [{'field': 'non_field_errors', 'message': 'Unknown error', 'code': 'unknown'}],
};

Either<L2, R2> either<L2, R2>(L2 Function(L l) fnL, R2 Function(R r) fnR) =>
    fold((l) => Left(fnL(l)), (r) => Right(fnR(r)));

// evitar
Map<String, dynamic> _unknownError() {
  return {'errors': [...]};
}
```

### Pattern matching

Usar pattern matching do Dart 3 sempre que possível: destructuring, switch expressions, record patterns.

```dart
// destructuring em assignment
final Response(data: data) = await _dio.get(path);

// switch expression no dispatch (MVI)
void dispatch(XxxIntent intent) => switch (intent) {
  EmailChanged(:final value) => state = state.copyWith(email: value),
  SubmitPressed()            => _submit(),
};

// evitar if/else ou switch statement onde switch expression serve
```

### Injeção de dependência

Dependências recebidas via construtor com parâmetro **nomeado obrigatório**. Nunca posicional para dependências.

```dart
// correto
final class DioHttpClient implements IHttpClient {
  final Dio _dio;
  DioHttpClient({required Dio dio}) : _dio = dio;
}

final class XxxRepository implements IXxxRepository {
  final IXxxDataSource _dataSource;
  XxxRepository({required IXxxDataSource dataSource}) : _dataSource = dataSource;
}

// evitar
DioHttpClient(this._dio);         // posicional
DioHttpClient(Dio dio) { ... }    // sem named parameter
```

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
| Interfaces (classe) | prefixo `I` | `IExpenseRepository` |
| Interfaces (arquivo) | prefixo `interface_` | `interface_expense_repository.dart` |
| Datasources e Clients | interface + implementação no mesmo arquivo | `remote_authentication_data_source.dart` |
| Datasources remotos | prefixo `IRemote` na interface | `IRemoteAuthenticationDataSource` |
| Datasources locais | prefixo `ILocal` na interface | `ILocalTokenDataSource` |
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
├── mocks/mocks.dart               ← todos os mocks (mocktail)
└── src/
    ├── infrastructure/
    │   └── responses/             ← testes de fromJson das responses
    ├── domain/                    ← testes de models, services, failures
    │   └── failures/              ← testes de Failure
    ├── data/
    │   └── repositories/          ← testes de repositórios (mock em IHttpClient)
    └── presentation/
        └── providers/             ← testes de Notifiers (ProviderContainer)
```

### Estratégia de mock por camada

| O que testar | Mock em | Não mockar |
|---|---|---|
| Response `fromJson` | — (puro) | — |
| Repositório + Datasource | `IHttpClient` | `IXxxDataSource` |
| Notifier | `IXxxRepository` | — |

**Não há testes de datasource separados.** O datasource só deserializa JSON — coberto pelos testes de `fromJson` das responses e pelos testes de repositório.

**Declaração de mocks com o tipo da interface**, não do mock:

```dart
// correto
late IHttpClient client;
late IAuthenticationRepository repository;

setUp(() {
  client = MockHttpClient();
  repository = MockAuthenticationRepository();
});

// evitar
late MockHttpClient mockClient;
late MockAuthenticationRepository mockRepository;
```

**Descrições de testes sempre em inglês.** Nomes de `test()`, `group()` e `testWidgets()` em inglês.

```dart
// correto
test('returns Right when datasource responds', () async { ... });
group('POST', () {
  test('returns Left with body on 400 error', () async { ... });
});

// evitar
test('retorna Right quando datasource responde', () async { ... });
```

```bash
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```

---

## SDD — Spec-Driven Development

> **OBRIGATÓRIO: NUNCA implemente nada sem antes criar a spec com `/sdd`.**
> A spec é a base de toda implementação. Implementar sem spec é proibido — sem exceção.

Antes de qualquer linha de código, usar o skill `/sdd` para criar a spec e aguardar aprovação.
Ver skill `/sdd` para o fluxo completo.

**Escopo:** implementar exatamente o que está na spec — nem mais, nem menos.
Se outras camadas forem necessárias além do que foi pedido, perguntar antes de incluir.

---

## Documentação de Referência

- App nativo Kotlin (referência): Obsidian `Trocado/Native/`
- Backend Django (referência): Obsidian `Trocado/BackEnd/`
