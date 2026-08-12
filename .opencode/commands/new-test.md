---
description: Apply Trocado's mocktail and layered testing patterns to a new or changed test.
agent: build
---

# New Test Patterns

Apply these patterns to the requested test: $ARGUMENTS

## Setup

Declare mocks in `test/mocks/mocks.dart` using the interface type:

```dart
final class MockHttpClient extends Mock implements IHttpClient {}
final class MockMoneyService extends Mock implements IMoneyService {}
final class MockXxxRepository extends Mock implements IXxxRepository {}
```

There are no datasource mocks. Test the datasource together with its repository through a mocked `IHttpClient`.

## General rules

- Test descriptions in `test()`, `group()`, and `testWidgets()` are always in English.
- Use `registerFallbackValue` for custom types passed as mock arguments.
- Use typed failures such as `Left(const NetworkFailure())`, never `Left('message')`.
- Test each sealed intent individually.
- Cover edge cases such as empty lists, null values, and failures with custom messages.

## Failure tests

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

## Response tests

Test `fromJson` in `test/src/infrastructure/responses/` without mocks:

```dart
test('parses success response', () {
  final response = XxxResponse.fromJson({'field': 'value'});
  expect(response.field, 'value');
});

test('parses failure response', () {
  final failure = FailureResponse.fromJson({
    'errors': [
      {'field': 'email', 'message': 'Invalid', 'code': 'invalid'},
    ],
  });
  expect(failure.errors.first.code, 'invalid');
});
```

## Repository tests

Mock `IHttpClient` so the repository and datasource are tested together:

```dart
late IHttpClient client;
late XxxRepository repository;

setUp(() {
  client = MockHttpClient();
  final dataSource = RemoteXxxDataSource(client: client);
  repository = XxxRepository(dataSource: dataSource);
});

test('returns Right with model on success', () async {
  when(() => client.post(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Right({'field': 'value'}));

  final data = await repository.action();

  expect(data.isRight, isTrue);
});
```

Cover success, validation failure, and network failure.

## Notifier tests

Use `ProviderContainer`, override the repository provider, dispatch each intent, and assert loading, success, and failure states:

```dart
late ProviderContainer container;
late IXxxRepository repository;

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
```
