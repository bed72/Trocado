# Design: notification-lifecycle-via-repository

## Estado atual

### `NotificationLifecycle` (a violação)

`lib/src/main/providers/notification_lifecycle_provider.dart`:

```dart
@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final messaging = ref.watch(messagingClientProvider);          // ❌ infra
    final repository = ref.watch(notificationRepositoryProvider);  // ✅ domain

    final subscription = messaging.onTokenRefresh.listen((_) {
      unawaited(repository.registerToken());
    });

    ref.onDispose(subscription.cancel);
  }
}
```

### Camadas tocadas hoje

- `IMessagingClient.onTokenRefresh: Stream<String>` — único consumer em produção é o notifier.
- `RemoteNotificationDataSource` — já depende de `IMessagingClient` pra `getToken()` e `platform`. Não expõe `onTokenRefresh` ainda.
- `NotificationRepository` — não conhece stream nenhum.

---

## Mudanças por camada

### Infrastructure — `RemoteNotificationDataSource`

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart`:

```dart
abstract interface class IRemoteNotificationDataSource {
  Stream<void> get onTokenRefreshed; // ← novo

  Future<Either<FailureResponse, void>> deleteAll();
  Future<Either<FailureResponse, void>> revokeToken();
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> deleteById({required int id});
  Future<Either<FailureResponse, NotificationsResponse>> findAll({String? cursor});
}

final class RemoteNotificationDataSource implements IRemoteNotificationDataSource {
  final IHttpClient _httpClient;
  final IMessagingClient _messagingClient;

  RemoteNotificationDataSource({
    required IHttpClient httpClient,
    required IMessagingClient messagingClient,
  }) : _httpClient = httpClient,
       _messagingClient = messagingClient;

  @override
  Stream<void> get onTokenRefreshed =>
      _messagingClient.onTokenRefresh.map((_) {});

  // ... métodos existentes inalterados
}
```

**Notas:**
- `map((_) {})` descarta o valor e estreita `Stream<String>` → `Stream<void>`.
- Stream do Firebase é broadcast — `.map` preserva o comportamento. Múltiplos `.listen` chamados em momentos diferentes (cenário hipotético) compartilham a mesma subscription upstream.
- Sem `try-catch`. Se o Firebase SDK propagar erro no stream (raríssimo), ele propaga até o listener no notifier, que **não** tem `onError` — o erro vira unhandled stream error (mesmo comportamento de antes da refatoração).

### Domain — `INotificationRepository`

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
abstract interface class INotificationRepository {
  Stream<void> get onTokenRefreshed; // ← novo

  Future<Either<Failure, void>> deleteAll();
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> deleteById({required int id});
  Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor});
}
```

`Stream<void>` é tipo Dart puro — domínio segue sem importar nada de `flutter` ou `dart:ui`. Sem `Either<Failure, Stream>` aqui: stream de eventos não tem semântica de falha de transporte aplicável (não há request/response — é apenas o gatilho propagado do SDK).

### Data — `NotificationRepository`

`lib/src/data/repositories/notification_repository.dart`:

```dart
final class NotificationRepository implements INotificationRepository {
  final IRemoteNotificationDataSource _dataSource;

  NotificationRepository({required IRemoteNotificationDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Stream<void> get onTokenRefreshed => _dataSource.onTokenRefreshed;

  // ... métodos existentes inalterados
}
```

Delegação pura, expressão única, `=>`. Nenhuma transformação porque o estreitamento `Stream<String>` → `Stream<void>` já aconteceu no datasource.

### Main — `NotificationLifecycle`

`lib/src/main/providers/notification_lifecycle_provider.dart`:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

part 'notification_lifecycle_provider.g.dart';

@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final repository = ref.watch(notificationRepositoryProvider);

    final subscription = repository.onTokenRefreshed.listen((_) {
      unawaited(repository.registerToken());
    });

    ref.onDispose(subscription.cancel);
  }
}
```

**Diffs concretos:**
- Remove `import '.../clients_provider.dart'`.
- Remove `ref.watch(messagingClientProvider)` e a variável `messaging`.
- Substitui `messaging.onTokenRefresh.listen(...)` por `repository.onTokenRefreshed.listen(...)`.

Estrutura, `keepAlive`, `unawaited`, `ref.onDispose` — tudo mantido.

---

## Testes

### `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart`

Novo group `onTokenRefreshed`:

```dart
group('onTokenRefreshed', () {
  test('emits void for each emit on messagingClient.onTokenRefresh', () async {
    final controller = StreamController<String>.broadcast();
    addTearDown(controller.close);

    when(() => messagingClient.onTokenRefresh).thenAnswer((_) => controller.stream);

    final emissions = <void>[];
    final subscription = dataSource.onTokenRefreshed.listen(emissions.add);
    addTearDown(subscription.cancel);

    controller.add('token-1');
    controller.add('token-2');
    await pumpEventQueue();

    expect(emissions, hasLength(2));
  });

  test('propagates listener attachment to messagingClient stream', () async {
    final controller = StreamController<String>.broadcast();
    addTearDown(controller.close);

    when(() => messagingClient.onTokenRefresh).thenAnswer((_) => controller.stream);

    final subscription = dataSource.onTokenRefreshed.listen((_) {});
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(controller.hasListener, isTrue);
  });
});
```

Adicionar `import 'dart:async';` no top do arquivo.

### `test/src/data/repositories/notification_repository_test.dart`

Novo group `onTokenRefreshed`:

```dart
group('onTokenRefreshed', () {
  test('delegates to dataSource.onTokenRefreshed', () async {
    final controller = StreamController<void>.broadcast();
    addTearDown(controller.close);

    when(() => dataSource.onTokenRefreshed).thenAnswer((_) => controller.stream);

    final emissions = <void>[];
    final subscription = repository.onTokenRefreshed.listen(emissions.add);
    addTearDown(subscription.cancel);

    controller.add(null);
    controller.add(null);
    await pumpEventQueue();

    expect(emissions, hasLength(2));
  });
});
```

Adicionar `import 'dart:async';` se ainda não houver.

### `test/src/main/providers/notification_lifecycle_provider_test.dart` (reescrita)

Substituir o `MockMessagingClient` pelo `MockNotificationRepository` como fonte do stream:

```dart
import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';
import 'package:trocado/src/main/providers/notification_lifecycle_provider.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';

import '../../../mocks/mocks.dart';

void main() {
  late INotificationRepository repository;
  late StreamController<void> controller;

  setUp(() {
    repository = MockNotificationRepository();
    controller = StreamController<void>.broadcast();

    when(() => repository.onTokenRefreshed).thenAnswer((_) => controller.stream);
    when(() => repository.registerToken())
        .thenAnswer((_) async => const Right(null));
  });

  tearDown(() async {
    await controller.close();
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repository),
    ],
  );

  group('NotificationLifecycle', () {
    test('materialization attaches a listener to repository.onTokenRefreshed', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      await pumpEventQueue();

      expect(controller.hasListener, isTrue);
      verifyNever(() => repository.registerToken());
    });

    test('single emit triggers registerToken exactly once', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add(null);
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(1);
    });

    test('multiple emits trigger one registerToken per emit', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add(null);
      controller.add(null);
      controller.add(null);
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(3);
    });

    test('container dispose cancels the subscription', () async {
      final container = makeContainer();

      container.read(notificationLifecycleProvider);
      await pumpEventQueue();
      expect(controller.hasListener, isTrue);

      container.dispose();
      await pumpEventQueue();

      expect(controller.hasListener, isFalse);
    });

    test('slow registerToken does not block subsequent emits', () async {
      final completer = Completer<Either<Failure, void>>();
      when(() => repository.registerToken())
          .thenAnswer((_) => completer.future);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(notificationLifecycleProvider);
      controller.add(null);
      controller.add(null);
      await pumpEventQueue();

      verify(() => repository.registerToken()).called(2);
      expect(completer.isCompleted, isFalse);

      completer.complete(const Right(null));
    });
  });
}
```

**Diffs vs versão atual:**
- Remove `MockMessagingClient`, import de `clients_provider`, import de `messaging_client`.
- `StreamController<String>` → `StreamController<void>`; `controller.add('token-1')` → `controller.add(null)`.
- `messagingClientProvider.overrideWithValue` é removido — só `notificationRepositoryProvider` é overrideado.
- Os 5 cenários da spec original (`fcm-token-on-refresh` archived) continuam testados, com a fonte do stream substituída.

---

## Considerações

### Compatibilidade

- `IMessagingClient.onTokenRefresh` **permanece** na interface (não é removida). Continua sendo consumida pelo `RemoteNotificationDataSource`. Nenhum outro consumer existe hoje.
- `MockMessagingClient` **permanece** em `test/mocks/mocks.dart` — é usado pelo `remote_notification_data_source_test.dart` (que já tem stubs em `getToken`/`platform`).
- `messagingClientProvider` **permanece** em `clients_provider.dart` — injeção do `RemoteNotificationDataSource` depende dele.

### Risco

Mínimo. O comportamento end-to-end é byte-a-byte preservado: o Firebase SDK emite um `String` → `RemoteNotificationDataSource` descarta o valor e propaga como `void` → `NotificationRepository` repassa → `NotificationLifecycle` listener chama `registerToken()`. O `registerToken()` por sua vez busca o token corrente via `IMessagingClient.getToken()` (já era assim antes — não passamos token pelo stream).

### Smoke manual

- App boot autenticado → `notificationLifecycleProvider` materializa → listener atachado.
- Forçar rotação (apagar app data + abrir → novo token gerado pelo Firebase) → backend recebe `POST /api/v1/me/fcm-token` com o novo token. Mesmo cenário que a spec original cobre — só checar que nada quebrou na refatoração.
