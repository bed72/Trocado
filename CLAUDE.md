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

## Releases

Releases Android são automatizadas via GitHub Action **`Android release`** (`.github/workflows/android-release.yml`). iOS continua manual (até virar spec própria).

### Fluxo

1. **Bumpar versão**: PR mudando `pubspec.yaml` linha `version: X.Y.Z+N`. Merge na `main`. Versão é single source of truth — `android/version.properties` **não controla** mais o versionName/versionCode (só NDK + SDK pins).
2. **Disparar a action**:
   ```bash
   gh workflow run android-release.yml
   ```
   ou via UI: `github.com/bed72/Trocado → Actions → Android release → Run workflow → main`.
3. **Aguardar a action** (~10-15min). Output: AAB em draft no Play Console + tag `vX.Y.Z+N` no commit.
4. **Rollout manual**: `play.google.com/console → Trocado → Testing → Internal testing → Review release → Start rollout`. Sem isso, testers não recebem.

### Pré-requisitos (one-time)
- 6 secrets no GitHub: `TROCADO_KEYSTORE_BASE64`, `TROCADO_KEY_ALIAS`, `TROCADO_KEY_PASSWORD`, `TROCADO_STORE_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`, `BASE_URL`.
- App `br.com.bed.trocado` criada no Play Console com pelo menos 1 release manual inicial.
- SHA-256 do keystore release registrada em Firebase App Check (Play Integrity provider).

### Dev local — build release

Pra buildar release localmente (smoke):

```bash
# Copia o keystore pra .keys/trocado.jks (gitignored), ou exporta TROCADO_KEYSTORE_PATH apontando pra outro path absoluto.
export TROCADO_KEY_ALIAS=trocado
export TROCADO_KEY_PASSWORD=<senha-da-key>
export TROCADO_STORE_PASSWORD=<senha-do-keystore>
flutter build appbundle --release --dart-define=BASE_URL=<url>
```

## Arquitetura

Clean Architecture estrita. Regra de dependência:

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

| Camada            | Depende de                                   | Nunca conhece                       |
|-------------------|----------------------------------------------|-------------------------------------|
| `domain/`         | nada                                         | tudo exceto si mesmo                |
| `data/`           | `domain/` + concretos de `infrastructure/`   | `presentation/`, `main/`            |
| `infrastructure/` | nada                                         | `domain/`, `data/`, `presentation/` |
| `presentation/`   | `domain/`                                    | `data/`, `infrastructure/`          |
| `main/`           | tudo                                         | —                                   |

---

## Camadas

### `domain/` — Dart puro, zero Flutter

- `either/either.dart` — `Either<L, R>` importado por todas as camadas (boundary type nas assinaturas de repositório)
- `failures/failure.dart` — `sealed class Failure` (NetworkFailure, NotFoundFailure, ServerFailure, DatabaseFailure, ValidationFailure, UnknownFailure)
- `models/` — models de domínio (definir por feature, ex: `ExpenseModel`, `CategoryModel`)
- `enums/` — enums de domínio por feature (ex: `ExpenseCategoryEnum`, `InsightTypeEnum`)
- `repositories/` — interfaces abstratas de repositório (ex: `IExpenseRepository`)
- `services/` — interfaces puras de serviços utilitários (ex: `IMoneyService`, `IDateFormatterService`)
- `validators/validation.dart` — `sealed class ValidationBase<T>` + interface `Validation<T>`

**Regra de ouro:** zero imports de `flutter`, `dart:ui` ou qualquer pacote externo.

### Fluxo

A arquitetura **não tem** `use_cases/`. O fluxo padrão é:

```
Notifier → Repository → DataSource → Client (Dio)
```

### `data/` — Implementa contratos de `domain`

- `repositories/` — implementações de `IXxxRepository`
- `extensions/` — extensions de mapping: `FailureResponseExtension.toFailure()`, `XxxResponseExtension.toModel()`

Repositórios dependem de **interfaces** de datasource (`infrastructure/datasources/`), nunca das implementações concretas.

O mapping `XxxResponse → XxxModel` é feito via extension em `data/extensions/`, **nunca** como método `toModel()` diretamente na response (que é infraestrutura e não pode conhecer domain).

### `infrastructure/` — Clientes externos e framework-specific

- `clients/http/requests/` — classes de request com `toJson()` (ex: `SignInRequest`)
- `clients/http/responses/` — classes de response com `fromJson()` apenas (ex: `SignInResponse`) — **nunca `toModel()`**
- `clients/http/responses/failure_response.dart` — `FailureResponse` genérico compartilhado: `{ "errors": [{ "field", "message", "code" }] }`
- `clients/logger/logger_client.dart` — `ILoggerClient` + `LoggerClient`
- `services/` — implementações concretas das interfaces de `domain/services/` (ex: `MoneyService` com `intl`)
- `datasources/` — interfaces de datasource retornam `Either<FailureResponse, XxxResponse>`
- `datasources/remote/` — mapeia `Either<Map, Map>` do Client para `Either<FailureResponse, XxxResponse>` via `fromJson`

**Regra:** o único `try-catch` fica no Client. Datasources deserializam ambos os lados do `Either`. Repositórios convertem `FailureResponse → Failure` (via `FailureResponseExtension.toFailure()`) e `XxxResponse → Model` (via `XxxResponseExtension.toModel()` de `data/extensions/`).

**Interfaces de datasource aceitam parâmetros de domínio** (tipos primitivos como `String`, `int`), nunca DTOs de infraestrutura (`XxxRequest`). A criação do `XxxRequest` é responsabilidade da implementação concreta do datasource, não da interface nem do repositório.

```dart
// correto — interface aceita domínio
abstract interface class IRemoteAuthenticationDataSource {
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required String email,
    required String password,
  });
}

// correto — implementação cria o DTO internamente
Future<Either<FailureResponse, SignInResponse>> signIn({
  required String email,
  required String password,
}) async {
  final response = await _client.post(
    parameter: Requests(EndpointKey.signIn.path,
      body: SignInRequest(email: email, password: password).toJson()),
  );
  return response.either(FailureResponse.fromJson, SignInResponse.fromJson);
}

// proibido — interface conhece DTO de infra
abstract interface class IRemoteAuthenticationDataSource {
  Future<Either<FailureResponse, SignInResponse>> signIn({
    required SignInRequest parameter, // ❌
  });
}
```

- `infrastructure/clients/http/responses/failure/failure_code_response.dart` — enum `FailureCode` com os códigos da API
- `data/extensions/failure_response_extension.dart` — extension `toFailure()` compartilhada por todos os repositórios

### `presentation/` — UI e state

Riverpod Notifiers com padrão MVI: sealed class `XxxIntent` + método `dispatch` + `switch` exhaustivo.
Widgets são `StatelessWidget` puros. Apenas screens usam `Consumer` para acessar providers.

**Regra:** nunca usar `ConsumerWidget`. Sempre `StatelessWidget` + `Consumer` interno:

### Services nunca são lidos direto na screen

Screens **nunca** chamam `ref.watch`/`ref.read` em providers de service (`moneyServiceProvider`, `dateFormatterProvider`, etc.). O notifier é a única porta: injeta o service via `ref.watch(...)` em `build()` e emite no `State` um view-model com os dados já prontos (valores formatados, labels, etc.). A screen consome apenas o estado.

View-models de apresentação vivem em `lib/src/presentation/ui/<feature>/data/` quando são específicos da feature (ex: `BudgetCardPresentationData`). Se o mesmo view-model for consumido por mais de uma feature, promover para `lib/src/presentation/data/<família>/` (ex: `presentation/data/expense/expense_item_presentation_data.dart`). Nunca use nomes genéricos como `helpers/`.

**Convenção de nome:** classe sufixada com `PresentationData`, arquivo sufixado com `_presentation_data.dart`. Nunca usar apenas `Data` ou `Model` para view-models de apresentação.

```dart
// correto — notifier traz o dado formatado; screen só lê o state
final class ExpenseItemPresentationData extends Equatable {
  final ExpenseModel expense;
  final String formattedValue;
  const ExpenseItemPresentationData({
    required this.expense,
    required this.formattedValue,
  });
}

@Riverpod(keepAlive: true)
final class ExpensesNotifier extends _$ExpensesNotifier {
  late IMoneyService _moneyService;
  late IExpenseRepository _repository;

  @override
  Future<ExpensesState> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);
    ...
  }

  ExpenseItemPresentationData _toItem(ExpenseModel expense) =>
      ExpenseItemPresentationData(
        expense: expense,
        formattedValue: _moneyService.format(expense.value / 100),
      );
}

class ExpensesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(expensesProvider); // só o estado
      return ...;
    },
  );
}

// proibido — screen lê service direto
final moneyService = ref.watch(moneyServiceProvider); // ❌
```



### Encapsulamento entre features (screens)

Cada feature em `lib/src/presentation/ui/<feature>/` é **autocontida**. Uma feature **nunca** importa widgets, notifiers, states, view-models, intents ou screens de outra feature. Essa é uma regra dura — qualquer tentativa de `import 'package:trocado/src/presentation/ui/<outra>/...'` fora das exceções abaixo é uma violação.

**Como compartilhar entre features:**

- **Widgets** comuns vivem em `lib/src/presentation/widgets/<família>/` — sempre com subpasta por família (`expense/`, `icons/`, `buttons/`, `fields/`, etc.), nunca arquivos soltos na raiz de `widgets/`.
- **View-models (data)** comuns vivem em `lib/src/presentation/data/<família>/` — mesma regra de subpasta.
- **Extensions de apresentação** comuns (ex: `ExpenseCategoryVisualExtension` que mapeia categoria → ícone/cor/label) ficam ao lado do widget compartilhado em `presentation/widgets/<família>/`.

**Exceções narradas à regra:**

1. **Locations compondo navegação** — `<feature>/<feature>_location.dart` pode importar outras Locations, mas apenas em outras Locations (tipicamente `home_location.dart` referenciando `SettingsLocation`, `BudgetLocation`, etc. para compor callbacks de navegação). Screens **não** importam Locations — recebem `VoidCallback` injetado pela Location para navegar.

2. **`ref.invalidate` cross-feature após mutação** — um notifier de mutação (ex: `ExpenseNotifier`) pode importar providers de leitura de outras features para chamar `ref.invalidate(...)` na ramificação de sucesso. É o idioma canônico do Riverpod para refrescar caches compartilhados. Apenas `ref.invalidate` é permitido nesse import — qualquer outro uso (`ref.watch`, `ref.read(...).notifier.method()`, ler o state, etc.) é violação. Ver seção "Invalidação cross-feature após mutação" abaixo.

```dart
// correto — screen não conhece outras features
class HomeScreen extends StatefulWidget {
  final VoidCallback navigateToExpenses;
  const HomeScreen({super.key, required this.navigateToExpenses});
}

// HomeLocation compõe a navegação
final class HomeLocation extends Location {
  @override
  LocationBuilder? get builder => (context) => HomeScreen(
    navigateToExpenses: () => context.navigate(ExpensesLocation()),
  );
}

// proibido — screen importa Location de outra feature
import 'package:trocado/src/presentation/ui/expenses/locations/expenses_location.dart'; // ❌
context.navigate(ExpensesLocation()); // dentro da HomeScreen ❌
```

**Checklist antes de importar entre features:**
1. É `<feature>_location.dart` importando outra `<feature>_location.dart`? → OK.
2. É um notifier de mutação importando provider de leitura de outra feature exclusivamente para `ref.invalidate(...)` em caso de sucesso? → OK.
3. Caso contrário, o arquivo importado deveria estar em `presentation/widgets/<família>/` ou `presentation/data/<família>/`? → Mova e importe do local comum.
4. Precisa navegar para outra feature? → Receba um callback pela Location.

### Invalidação cross-feature após mutação

Quando uma feature faz uma mutação (criar/editar/deletar) e outras features leem os mesmos dados em cache, o produtor usa o idioma canônico do Riverpod: `ref.invalidate(otherProvider)` na ramificação de sucesso da mutação. Riverpod re-executa `build()` do provider invalidado na próxima leitura (funciona mesmo para `@Riverpod(keepAlive: true)`).

```dart
// ExpenseNotifier — após criar com sucesso
data.fold(
  (failure) => this.state = this.state.copyWith(status: .failure, message: failure.message),
  (_) {
    ref.invalidate(expensesProvider);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(recentExpensesProvider);
    this.state = this.state.copyWith(status: .success);
  },
);
```

**Exceção narrada à regra de encapsulamento de feature**: esse é o **único** caso em que uma feature pode importar símbolos de outra. A regra geral continua — widgets, states, intents, screens, view-models, visual extensions **nunca** atravessam fronteira de feature. `ref.invalidate` de um provider de outra feature é permitido exclusivamente para sincronizar caches após mutação. Qualquer outro uso do provider importado (ex: `ref.watch`, `ref.read(...).notifier.algumMetodo()`) é violação.

### Widget Previews

Toda feature e widget compartilhado pode ter previews usando o Widget Previewer do Flutter (`@Preview`). Nunca usar `@Preview` direto — sempre `@TrocadoPreview` (de `lib/src/presentation/preview/trocado_preview.dart`), que injeta automaticamente `MaterialPreviewWidget` + inicialização do locale `pt_BR` como wrapper. Sem isso, `DateFormat('dd/MM', 'pt_BR')` etc. quebram com `LocaleDataException`.

**Layout por feature** — previews vivem em `preview/` dentro da pasta da feature, com subpastas espelhando a estrutura da feature:

```
lib/src/presentation/ui/<feature>/
  preview/
    screens/    → <screen>_preview.dart     (previews da screen completa)
    widgets/    → <widget>_preview.dart     (previews de widgets da feature)
    mocks/      → <type>_mock.dart          (builders de mock específicos da feature)
```

**Layout commons** — quando um mock ou preview serve mais de uma feature, vai para `lib/src/presentation/preview/`:

```
lib/src/presentation/preview/
  trocado_preview.dart         → @TrocadoPreview base annotation
  widgets/<família>/           → previews de widgets compartilhados (presentation/widgets/<família>/)
  mocks/<família>/             → mocks cross-feature (ex: expense/expense_item_mock.dart)
```

**Regras**:
- Sempre `@TrocadoPreview(group: 'categoria', name: 'cenário')` — o `group` organiza os cards na UI do Previewer; usar português curto (ex: `'Agrupamento'`, `'Scroll'`, `'Tail'`, `'Estados'`).
- Mock builders públicos e bem nomeados (`expenseItemMock`, `budgetCardMock`), com API posicional-nomeada; usam `DateTime.now().subtract(ago)` para datas relativas ao runtime.
- Cada função de preview devolve a estrutura "real" (Scaffold, CustomScrollView etc.) — o wrapper do `@TrocadoPreview` já envolve em `MaterialApp`.
- Previews não leem providers Riverpod direto. Se a tela consome um notifier, extrair a estrutura visual num widget puro (ou um helper `_shell` local) e preview esse widget com estado mockado.

### Widgets privados em arquivos de widget

Nunca criar uma classe de widget privada dentro de outro arquivo de widget (ex: `class _FooWidget extends StatelessWidget`).
Em vez disso:
- Widget com corpo não-trivial → extrair para seu próprio arquivo (`foo_widget.dart`)
- Widget trivial (ex: espaçador, placeholder fixo) → método privado que retorna o widget

```dart
// correto — widget extraído para arquivo próprio
// settings_profile_widget.dart
class SettingsProfileWidget extends StatelessWidget { ... }

// correto — método para widget trivial
Widget _profilePlaceholder() => const SizedBox(height: 48.0);

// proibido — classe privada dentro do arquivo
class _ProfilePlaceholder extends StatelessWidget {
  Widget build(BuildContext context) => const SizedBox(height: 48.0);
}
```

```dart
// correto
class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(signInNotifierProvider);
        return ...;
      },
    );
  }
}

// proibido
class SignInScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

### `main/` — Composition root

- `locations/` — definições de rota com `duck_router`
- `providers/` — providers Riverpod que fazem o wiring de dependências concretas (clients, datasources, repositories, validators)

---

## Padrões de Código

### Code generation

`riverpod_generator` é usado **exclusivamente** para gerar providers Riverpod (`@Riverpod()`).
Não usar code gen para nenhuma outra finalidade.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Anotação `@Riverpod()` — sempre a forma com parênteses

Sempre usar `@Riverpod()` (PascalCase com parênteses), **nunca** `@riverpod` (lowercase sem parênteses). As duas formas são funcionalmente equivalentes, mas a forma com parênteses é a única que aceita parâmetros (`keepAlive: true`, `dependencies: [...]`), então padronizar nela elimina o switch de estilo no dia que um provider precisa virar `keepAlive`. Vale para Notifiers, AsyncNotifiers e providers funcionais em `main/providers/`.

```dart
// correto
@Riverpod()
final class SignInNotifier extends _$SignInNotifier { ... }

@Riverpod(keepAlive: true)
IShareClient shareClient(Ref _) => ShareClient();

// evitar
@riverpod
final class SignInNotifier extends _$SignInNotifier { ... }
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

**Regra:** usar sempre switch expression — nunca switch statement. Isso se aplica a todo switch no projeto sem exceção.

```dart
// dispatch (MVI) — switch expression
void dispatch(XxxIntent intent) => switch (intent) {
  EmailChanged(:final value) => state = state.copyWith(email: value),
  SubmitPressed()            => _submit(),
};

// ref.listen — switch expression como statement (resultado descartado)
ref.listen(xxxProvider, (_, XxxState state) => switch (state.status) {
  XxxStatus.success      => context.navigate(NextLocation()),
  XxxStatus.failure      => _showError(context, state.message),
  XxxStatus.loading ||
  XxxStatus.initial      => null,
});

// mapeamento de failure — switch expression
return switch (FailureCodeResponse.fromString(item.code)) {
  .networkError => const NetworkFailure(),
  .serverError  => const ServerFailure(),
  .notFound     => const NotFoundFailure(),
  _             => ValidationFailure(item.message),
};

// destructuring em assignment
final Response(data: data) = await _dio.get(path);

// evitar — switch statement
switch (intent) {
  case SubmitPressed():
    _submit();
    break;
}

// evitar — if/else onde switch expression serve
if (status == XxxStatus.success) {
  context.navigate(NextLocation());
} else if (status == XxxStatus.failure) {
  _showError(context, message);
}
```

Para contextos `void` (como `ref.listen`), o braço no-op usa `null` — o resultado do switch expression é descartado.

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

@Riverpod()
final class SignInNotifier extends _$SignInNotifier {
  late SignInFormValidator _validator;
  late IAuthenticationRepository _repository;

  @override
  SignInState build() {
    _validator = ref.watch(signInFormValidatorProvider);
    _repository = ref.watch(authenticationRepositoryProvider);
    return const SignInState();
  }

  void dispatch(SignInIntent intent) => switch (intent) {
    EmailChanged(:final value) => state = state.copyWith(email: value),
    SubmitPressed()            => _submit(),
  };
}
```

**Notifier com inicialização assíncrona automática** — quando não há interação do usuário e o estado é carregado ao montar (ex: splash, carregamento inicial), usar `AsyncNotifier` com `build()` async. A lógica async fica em método privado separado:

```dart
@Riverpod()
final class SplashNotifier extends _$SplashNotifier {
  late IAuthenticationRepository _repository;

  @override
  Future<SplashStatus> build() async {
    _repository = ref.watch(authenticationRepositoryProvider);
    return await _checkSession();
  }

  Future<SplashStatus> _checkSession() async {
    final data = await _repository.checkSession();
    return data.fold((_) => .unauthenticated, (_) => .authenticated);
  }
}
```

Na screen, o provider é `AsyncValue<T>` — usar `AsyncData` no switch do `ref.listen`:

```dart
ref.listen(splashProvider, (_, AsyncValue<SplashStatus> state) => switch (state) {
  AsyncData(:final value) => switch (value) {
    .authenticated   => navigateToHome(),
    .unauthenticated => navigateToSignIn(),
  },
  _ => null,
});
```

**Campos em `build()` são `late`, nunca `late final`.** O Riverpod re-executa `build()` na mesma instância quando uma dependência `ref.watch` muda — `late final` lançaria `LateInitializationError` na segunda execução.

**Todas as dependências do Notifier vêm via `ref.watch` no `build()`**, incluindo validators. Nunca instanciar dependências diretamente no notifier — isso inclui `static const`. Validators são providers em `main/providers/validators_provider.dart`.

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
