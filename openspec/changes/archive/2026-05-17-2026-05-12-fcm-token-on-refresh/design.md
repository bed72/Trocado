# Design: fcm-token-on-refresh

## Fluxo de responsabilidades

```
main() async
    → container.read(firebaseClientProvider).initialize()
    → container.read(notificationLifecycleProvider)   // kick — materializa
        → NotificationLifecycle.build()
            → messaging = ref.watch(messagingClientProvider)
            → repository = ref.watch(notificationRepositoryProvider)
            → subscription = messaging.onTokenRefresh.listen((_) {
                unawaited(repository.registerToken());
              })
            → ref.onDispose(subscription.cancel)

// runtime
FirebaseMessaging rotates token
    → MessagingClient.onTokenRefresh emits new token
    → listener callback fires
    → unawaited(repository.registerToken())
        → RemoteNotificationDataSource.registerToken()  [Spec 1]
            → messagingClient.getToken()   // pega o token atual (já rotacionado)
            → IHttpClient.post(EndpointKey.fcmToken, FcmTokenRequest(...))
        → backend UPSERT, 204
```

O callback ignora o valor emitido pelo stream porque `RemoteNotificationDataSource.registerToken()` (Spec 1) já pega o token corrente via `messagingClient.getToken()`. Mantém uma fonte única — o método existente — e evita duplicar a montagem do `FcmTokenRequest` aqui.

---

## IMessagingClient — extensão

`lib/src/infrastructure/clients/messaging/messaging_client.dart`:

```dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class IMessagingClient {
  String get platform;
  Stream<String> get onTokenRefresh;
  Future<String?> getToken();
}

final class MessagingClient implements IMessagingClient {
  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
```

- Getter sync devolve o `Stream<String>` do SDK direto. Sem map, sem transform.
- Não swallow exceptions no getter — se o SDK lançar ao acessar o stream (raríssimo), propaga. O listener default não tem `onError`, então a falha é silenciosa em runtime via zone handler do app.

---

## notificationLifecycleProvider — novo

`lib/src/main/providers/notification_lifecycle_provider.dart`:

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

part 'notification_lifecycle_provider.g.dart';

@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final messaging = ref.watch(messagingClientProvider);
    final repository = ref.watch(notificationRepositoryProvider);

    final subscription = messaging.onTokenRefresh.listen((_) {
      unawaited(repository.registerToken());
    });

    ref.onDispose(subscription.cancel);
  }
}
```

- `keepAlive: true` é o que mantém o provider vivo enquanto o container existir, mesmo sem `ref.watch` externo.
- `ref.watch` (não `ref.read`) em `messagingClientProvider` e `notificationRepositoryProvider`: se algum deles rebuildar (raro, mas possível em testes via override dinâmico), Riverpod re-executa `build()` e descarta a subscription antiga via `onDispose` antes de criar a nova.
- O callback do listener ignora o `event` emitido (`(_) { ... }`) — `registerToken()` busca o token atual internamente.
- `ref.onDispose(subscription.cancel)`: passa a referência ao método; Dart aceita tear-off.

---

## main.dart — kick

`lib/main.dart`:

```dart
import 'package:trocado/src/main/providers/notification_lifecycle_provider.dart';

// ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(observers: [stateObserver]);
  await container.read(firebaseClientProvider).initialize();
  await container.read(appCheckClientProvider).activate();

  container.read(notificationLifecycleProvider);  // NOVO — liga o listener

  final crashClient = container.read(crashClientProvider);

  FlutterError.onError = crashClient.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashClient.recordError(error: error, stackTrace: stack, fatal: true);
    return true;
  };

  unawaited(_logFcmToken(container));

  runApp(UncontrolledProviderScope(container: container, child: AppWidget()));
}
```

- Posicionado **depois** de `firebaseClient.initialize()` — sem Firebase pronto, `FirebaseMessaging.instance.onTokenRefresh` lançaria.
- Posicionado **antes** de `_logFcmToken` por organização (efeitos relacionados a messaging juntos).
- O `_logFcmToken` (TODO de debug) fica intocado nesta spec.

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `notification_lifecycle_provider_test.dart` (NOVO) | `IMessagingClient` (`StreamController<String>`), `INotificationRepository` | • emit único → `registerToken()` chamada exatamente 1 vez<br>• emits múltiplos → uma chamada por emit<br>• `container.dispose()` → subscription cancelada (`controller.hasListener == false`) |

Sem teste para `MessagingClient.onTokenRefresh` — wrapper trivial sobre `FirebaseMessaging.instance.onTokenRefresh` (mesma justificativa do `getToken()` na Spec 1).

Sem alteração nos testes da Splash, SignIn, SignUp ou `MessagingClient`.

---

## Sequência de execução em testes

Cenário "emit único → registerToken chamada":

```dart
final controller = StreamController<String>.broadcast();
when(() => messaging.onTokenRefresh).thenAnswer((_) => controller.stream);

final container = ProviderContainer(overrides: [
  messagingClientProvider.overrideWithValue(messaging),
  notificationRepositoryProvider.overrideWithValue(repository),
]);
container.read(notificationLifecycleProvider);  // materializa, listener ligado

controller.add('new-token-1');
await pumpEventQueue();

verify(() => repository.registerToken()).called(1);
```

Cenário "dispose cancela":

```dart
// ... setup igual ...
container.read(notificationLifecycleProvider);
expect(controller.hasListener, isTrue);

container.dispose();
expect(controller.hasListener, isFalse);
```

`StreamController.broadcast()` é importante: o stream do `FirebaseMessaging.onTokenRefresh` é broadcast (múltiplos listeners suportados), então o mock precisa imitar. Com single-subscription, `hasListener` flicka diferente.

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Provider Riverpod `keepAlive: true` | Subscribe direto em `main()` antes do `runApp` | DI manual, testes difíceis, não é o padrão do projeto |
| Callback ignora o `event` do stream | Passar token via parâmetro pra `registerToken(token)` | Quebraria assinatura de `INotificationRepository`; `registerToken()` já busca token atual via `messagingClient.getToken()` (Spec 1) |
| `ref.watch` nas dependências | `ref.read` | `read` ignora rebuild; `watch` reexecuta `build()` corretamente se dependência mudar (relevante em testes) |
| `onTokenRefresh` sem `try-catch` | Wrapper com catch-all | SDK não lança ao acessar getter; só ao subscribe (raro); listener sem `onError` engole |
| Sem auth gate antes de `registerToken` | Checar `authStateProvider` | Custo de criar provider observável só pra isso não compensa; 401 silencioso é aceitável |
| Sem cache de "último token" | `SharedPreferences` ou in-memory | Backend dedupe via UPSERT; cache local introduz invalidação sem benefício |
