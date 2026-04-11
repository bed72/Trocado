# New Test Patterns

Padrões de teste para o projeto Trocado.

## Setup

```dart
final class MockXxxRepository extends Mock implements IXxxRepository {}
final class MockXxxDataSource extends Mock implements IXxxDataSource {}
final class MockMoneyService extends Mock implements IMoneyService {}
```

Todos os mocks em `test/mocks/mocks.dart`.

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

## Testes de Repositório

```dart
late MockXxxDataSource mockDataSource;
late XxxRepository repository;

setUp(() {
  mockDataSource = MockXxxDataSource();
  repository = XxxRepository(dataSource: mockDataSource);
});

test('returns Right when datasource responds', () async {
  when(() => mockDataSource.findAll())
      .thenAnswer((_) async => Right([model]));

  final result = await repository.findAll();

  expect(result.isRight, isTrue);
});

test('returns Left NetworkFailure on connection error', () async {
  when(() => mockDataSource.findAll()).thenThrow(
    DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    ),
  );

  final result = await repository.findAll();

  expect(result.isLeft, isTrue);
  result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
});
```

---

## Testes de Notifier (MVI)

```dart
late ProviderContainer container;
late MockXxxRepository mockRepo;

setUp(() {
  mockRepo = MockXxxRepository();
  container = ProviderContainer(
    overrides: [xxxRepositoryProvider.overrideWithValue(mockRepo)],
  );
});

tearDown(container.dispose);

test('dispatch XxxActionA updates state', () {
  container.read(xxxNotifierProvider.notifier).dispatch(const XxxActionA('value'));

  expect(container.read(xxxNotifierProvider).field, 'value');
});

test('dispatch XxxSubmit emits loading then success', () async {
  when(() => mockRepo.action()).thenAnswer((_) async => Right(model));

  final notifier = container.read(xxxNotifierProvider.notifier);
  final future = notifier.dispatch(const XxxSubmit());

  expect(container.read(xxxNotifierProvider).status, XxxStatus.loading);
  await future;
  expect(container.read(xxxNotifierProvider).status, XxxStatus.success);
});

test('dispatch XxxSubmit emits failure', () async {
  when(() => mockRepo.action())
      .thenAnswer((_) async => Left(const NetworkFailure()));

  await container.read(xxxNotifierProvider.notifier).dispatch(const XxxSubmit());

  final state = container.read(xxxNotifierProvider);
  expect(state.status, XxxStatus.failure);
  expect(state.message, isNotEmpty);
});
```
