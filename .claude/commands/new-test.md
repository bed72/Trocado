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

## Testes de Failure

```dart
test('NetworkFailure retorna mensagem padrão', () {
  const failure = NetworkFailure();
  expect(failure.message, isNotEmpty);
  expect(failure.toString(), equals(failure.message));
});

test('ValidationFailure aceita mensagem customizada', () {
  const failure = ValidationFailure('Valor deve ser maior que zero');
  expect(failure.message, 'Valor deve ser maior que zero');
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

test('retorna Right quando datasource responde', () async {
  when(() => mockDataSource.findAll())
      .thenAnswer((_) async => [model]);

  final result = await repository.findAll();

  expect(result.isRight(), true);
});

test('retorna Left NetworkFailure em DioException de conexão', () async {
  when(() => mockDataSource.findAll())
      .thenThrow(DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError));

  final result = await repository.findAll();

  expect(result.isLeft(), true);
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

test('dispatch XxxActionA atualiza state', () {
  container.read(xxxNotifierProvider.notifier)
      .dispatch(const XxxActionA('valor'));

  expect(container.read(xxxNotifierProvider).field, 'valor');
});

test('dispatch XxxSubmit emite loading e success', () async {
  when(() => mockRepo.action())
      .thenAnswer((_) async => Right(model));

  final notifier = container.read(xxxNotifierProvider.notifier);
  final future = notifier.dispatch(const XxxSubmit());

  expect(container.read(xxxNotifierProvider).status, XxxStatus.loading);
  await future;
  expect(container.read(xxxNotifierProvider).status, XxxStatus.success);
});

test('dispatch XxxSubmit emite failure', () async {
  when(() => mockRepo.action())
      .thenAnswer((_) async => Left(const NetworkFailure()));

  await container.read(xxxNotifierProvider.notifier).dispatch(const XxxSubmit());

  final state = container.read(xxxNotifierProvider);
  expect(state.status, XxxStatus.failure);
  expect(state.message, isNotEmpty);
});
```

---

## Regras gerais

- `registerFallbackValue` para tipos customizados passados como argumento
- `Left(const NetworkFailure())` — nunca `Left('msg')` diretamente
- Testar cada intent do sealed class individualmente
- Testar edge cases: lista vazia, null, failure com mensagem customizada
