# New Test Patterns

Padrões de teste para o projeto Trocado.

## Setup

```dart
final class MockHttpClient extends Mock implements IHttpClient {}
final class MockMoneyService extends Mock implements IMoneyService {}
final class MockXxxRepository extends Mock implements IXxxRepository {}
```

Todos os mocks em `test/mocks/mocks.dart`.

**Não há mocks de datasource.** O datasource é testado junto com o repositório via mock do `IHttpClient`.

---

## Regras gerais

- **Descrições sempre em inglês** — `test()`, `group()` e `testWidgets()`
- `registerFallbackValue` para tipos customizados passados como argumento
- `Left(const NetworkFailure())` — nunca `Left('msg')` diretamente
- Testar cada intent do sealed class individualmente
- Testar edge cases: lista vazia, null, failure com mensagem customizada

---

## Testes de Failure

```dart
test('NetworkFailure returns default message', () {
  const failure = NetworkFailure();
  expect(failure.message, isNotEmpty);
  expect(failure.toString(), equals(failure.message));
});

test('ValidationFailure accepts custom message', () {
  const failure = ValidationFailure('Value must be greater than zero');
  expect(failure.message, 'Value must be greater than zero');
});
```

---

## Testes de Response (fromJson)

```dart
test('parses success response', () {
  final  response = XxxResponse.fromJson({'field': 'value'});
  expect(response.field, 'value');
});

test('parses failure response', () {
  final  failure = FailureResponse.fromJson({
    'errors': [{'field': 'email', 'message': 'Invalid', 'code': 'invalid'}],
  });
  expect(failure.errors.first.code, 'invalid');
});
```

---

## Testes de Repositório

Mock em `IHttpClient` — testa repositório + datasource juntos. **Não mockar datasource.**

Declarar mocks com o **tipo da interface**, não o tipo do mock:

```dart
late IHttpClient client;  // correto — tipo da interface
late XxxRepository repository;

setUp(() {
  client = MockHttpClient();  // mock atribuído, não declarado
  final dataSource = RemoteXxxDataSource(client: client);
  repository = XxxRepository(dataSource: dataSource);
});

test('returns Right with model on success', () async {
  when(() => client.post(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Right({'field': 'value'}));

  final data = await repository.action();

  expect(data.isRight, isTrue);
});

test('returns Left ValidationFailure on 400', () async {
  when(() => client.post(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left({
        'errors': [{'field': 'email', 'message': 'Invalid email', 'code': 'invalid'}],
      }));

  final data = await repository.action();

  expect(data.isLeft, isTrue);
  data.fold((failure) => expect(failure, isA<ValidationFailure>()), (_) {});
});

test('returns Left NetworkFailure on connection error', () async {
  when(() => client.post(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left({
        'errors': [{'field': 'non_field_errors', 'message': 'No connection', 'code': 'connection_error'}],
      }));

  final data = await repository.action();

  data.fold((failure) => expect(failure, isA<NetworkFailure>()), (_) {});
});
```

---

## Testes de Notifier (MVI)

```dart
late ProviderContainer container;
late MockXxxRepository repository;

setUp(() {
  repository = MockXxxRepository();
  container = ProviderContainer(
    overrides: [xxxRepositoryProvider.overrideWithValue(repository)],
  );
});

tearDown(container.dispose);

test('dispatch XxxActionA updates state', () {
  container.read(xxxNotifierProvider.notifier).dispatch(const XxxActionA('value'));

  expect(container.read(xxxNotifierProvider).field, 'value');
});

test('dispatch XxxSubmit emits loading then success', () async {
  when(() => repository.action()).thenAnswer((_) async => Right(model));

  final notifier = container.read(xxxNotifierProvider.notifier);
  final future = notifier.dispatch(const XxxSubmit());

  expect(container.read(xxxNotifierProvider).status, XxxStatus.loading);
  await future;
  expect(container.read(xxxNotifierProvider).status, XxxStatus.success);
});

test('dispatch XxxSubmit emits failure', () async {
  when(() => repository.action())
      .thenAnswer((_) async => Left(const NetworkFailure()));

  await container.read(xxxNotifierProvider.notifier).dispatch(const XxxSubmit());

  final state = container.read(xxxNotifierProvider);
  expect(state.status, XxxStatus.failure);
  expect(state.message, isNotEmpty);
});
```
