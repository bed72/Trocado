# push-notification-local Specification

## Purpose

Exibir notificações locais no device (banner, som, badge) quando mensagens FCM chegam com o app em **foreground**. Quando o app está em background/terminated, o FCM já exibe a notification message automaticamente via sistema — essa spec cobre apenas o gap de foreground onde o FCM **não** exibe nada por padrão.

Adicionar também `requestPermission()` ao `IMessagingClient` para que a UI possa solicitar permissão de notificação ao usuário (Android 13+ e iOS).

---

## Requirements

### Requirement: Adicionar `flutter_local_notifications` ao projeto

O sistema SHALL adicionar `flutter_local_notifications: ^21.0.0` ao `pubspec.yaml` em `dependencies`.

#### Scenario: Dependência instalada

Given o `pubspec.yaml` atualizado
When `flutter pub get` é executado
Then SHALL resolver sem erros

---

### Requirement: Configuração nativa Android

O sistema SHALL adicionar ao `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml`), dentro de `<application>`, o receiver necessário para notification actions do `flutter_local_notifications`:

```xml
<receiver
    android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
```

O `AndroidInitializationSettings` SHALL usar `'ic_notification'` como ícone default — o drawable já existe em todas as densidades.

Nenhuma permission adicional é necessária — `POST_NOTIFICATIONS` já está declarado e `VIBRATE` está fora de escopo.

#### Scenario: Manifest válido após alteração

Given o `AndroidManifest.xml` atualizado
When `flutter build apk --debug` é executado
Then SHALL compilar sem erros de manifest

---

### Requirement: Configuração nativa iOS

O sistema SHALL garantir que o `AppDelegate.swift` configure o delegate de notificações do `UNUserNotificationCenter` para que foreground notifications sejam exibidas como banner:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

Isso é necessário para que o `flutter_local_notifications` consiga exibir notificações em foreground no iOS. Sem esse delegate, as notificações são silenciadas pelo sistema.

#### Scenario: AppDelegate configurado

Given o `AppDelegate.swift` atualizado
When o app é executado no iOS
Then notificações em foreground SHALL ser exibidas como banner pelo sistema

---

### Requirement: ILocalNotificationClient — interface

O sistema SHALL adicionar `lib/src/infrastructure/clients/notification/local_notification_client.dart` com a interface e implementação no mesmo arquivo (padrão de client do projeto):

```dart
abstract interface class ILocalNotificationClient {
  Future<void> initialize();
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}
```

- `initialize()` — configura o plugin com settings de Android e iOS, cria o notification channel.
- `show(id, title, body)` — exibe uma notificação local imediatamente.

A interface SHALL NOT conter `requestPermission()` — essa responsabilidade é do `IMessagingClient` que já gerencia a relação com Firebase Messaging e permissions.

#### Scenario: Interface segue padrão de client do projeto

Given a interface `ILocalNotificationClient`
Then SHALL seguir o mesmo padrão de `IFirebaseClient`, `IStorageClient` — interface + implementação no mesmo arquivo, em `infrastructure/clients/notification/`

---

### Requirement: LocalNotificationClient — implementação

A implementação `LocalNotificationClient` SHALL:

1. Receber `FlutterLocalNotificationsPlugin` via construtor com named parameter obrigatório.
2. Em `initialize()`:
   - Usar `AndroidInitializationSettings('ic_notification')` como ícone.
   - Usar `DarwinInitializationSettings()` com todas as permissions em `false` (permissions são solicitadas em outro momento via `IMessagingClient.requestPermission()`).
   - Criar o `AndroidNotificationChannel` com id `'trocado_default'`, name `'Notificações'`, importance `Importance.high`.
   - Chamar `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel)`.
   - Chamar `flutterLocalNotificationsPlugin.initialize(settings: initializationSettings)`.
3. Em `show(id, title, body)`:
   - Usar `AndroidNotificationDetails('trocado_default', 'Notificações', channelDescription: 'Notificações do Trocado', importance: Importance.high, priority: Priority.high, icon: 'ic_notification')`.
   - Usar `DarwinNotificationDetails()` default para iOS.
   - Chamar `flutterLocalNotificationsPlugin.show(id, title, body, notificationDetails)`.

```dart
final class LocalNotificationClient implements ILocalNotificationClient {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationClient({
    required FlutterLocalNotificationsPlugin plugin,
  }) : _plugin = plugin;

  @override
  Future<void> initialize() async { ... }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async { ... }
}
```

#### Scenario: initialize cria channel e configura plugin

Given uma nova instância de `LocalNotificationClient`
When `initialize()` é chamado
Then o plugin SHALL ser inicializado com `AndroidInitializationSettings('ic_notification')`
And o channel `'trocado_default'` SHALL ser criado com `Importance.high`

#### Scenario: show exibe notificação com dados corretos

Given o client inicializado
When `show(id: 1, title: 'Novo gasto', body: 'R$ 25,00 no Mercado')` é chamado
Then `flutterLocalNotificationsPlugin.show` SHALL ser invocado com id `1`, title `'Novo gasto'`, body `'R$ 25,00 no Mercado'`, channel `'trocado_default'`

---

### Requirement: Estender IMessagingClient com onForegroundMessage e requestPermission

O sistema SHALL estender a interface `IMessagingClient` em `lib/src/infrastructure/clients/messaging/messaging_client.dart` com dois novos membros:

```dart
abstract interface class IMessagingClient {
  String get platform;
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<Map<String, dynamic>> get onForegroundMessage;  // NOVO
  Future<bool> requestPermission();                       // NOVO
}
```

- `onForegroundMessage` — expõe `FirebaseMessaging.onMessage` mapeado para `Map<String, dynamic>` contendo `{'title': ..., 'body': ...}` extraídos da `RemoteMessage.notification`. Mensagens sem `notification` (data-only) SHALL ser filtradas (não emitidas no stream).
- `requestPermission()` — chama `FirebaseMessaging.instance.requestPermission()` e retorna `true` se `authorizationStatus` for `authorized` ou `provisional`, `false` caso contrário.

A implementação `MessagingClient` SHALL:

```dart
@override
Stream<Map<String, dynamic>> get onForegroundMessage =>
    FirebaseMessaging.onMessage.where((m) => m.notification != null).map(
      (m) => {
        'title': m.notification!.title ?? '',
        'body': m.notification!.body ?? '',
      },
    );

@override
Future<bool> requestPermission() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  } catch (_) {
    return false;
  }
}
```

#### Scenario: onForegroundMessage emite mensagem com notification

Given o app em foreground
When uma `RemoteMessage` com `notification.title == 'Teste'` e `notification.body == 'Corpo'` chega
Then o stream SHALL emitir `{'title': 'Teste', 'body': 'Corpo'}`

#### Scenario: onForegroundMessage filtra data-only messages

Given o app em foreground
When uma `RemoteMessage` com `notification == null` (data-only) chega
Then o stream SHALL NOT emitir nenhum evento

#### Scenario: onForegroundMessage com title ou body null

Given uma `RemoteMessage` com `notification.title == null` e `notification.body == 'Só body'`
When o stream emite
Then SHALL emitir `{'title': '', 'body': 'Só body'}`

#### Scenario: requestPermission autorizado

Given o usuário concede permissão
When `requestPermission()` é chamado
Then SHALL retornar `true`

#### Scenario: requestPermission negado

Given o usuário nega permissão
When `requestPermission()` é chamado
Then SHALL retornar `false`

#### Scenario: requestPermission com erro

Given uma exception ocorre ao solicitar permissão
When `requestPermission()` é chamado
Then SHALL retornar `false` (sem propagar a exception)

---

### Requirement: Provider do LocalNotificationClient

O sistema SHALL adicionar em `lib/src/main/providers/clients_provider.dart`:

```dart
@Riverpod(keepAlive: true)
ILocalNotificationClient localNotificationClient(Ref _) =>
    LocalNotificationClient(
      plugin: FlutterLocalNotificationsPlugin(),
    );
```

O import de `FlutterLocalNotificationsPlugin` e `LocalNotificationClient` SHALL ser adicionado ao arquivo.

#### Scenario: Provider registrado como keepAlive

Given o provider `localNotificationClientProvider`
Then SHALL ser `keepAlive: true` (singleton durante o ciclo de vida do app)

---

### Requirement: Inicialização do LocalNotificationClient no main.dart

O sistema SHALL adicionar a inicialização do `LocalNotificationClient` em `lib/main.dart`, **após** a inicialização do Firebase e App Check, e **antes** da leitura do `notificationLifecycleProvider`:

```dart
await container.read(firebaseClientProvider).initialize();
await container.read(appCheckClientProvider).initialize();
await container.read(localNotificationClientProvider).initialize();  // NOVO
container.read(notificationLifecycleProvider);
```

#### Scenario: Ordem de inicialização

Given o app inicializa
Then `localNotificationClient.initialize()` SHALL ser chamado após `appCheckClient.initialize()` e antes de `notificationLifecycleProvider`

---

### Requirement: Estender NotificationLifecycleProvider com foreground handler

O sistema SHALL estender `NotificationLifecycleProvider` em `lib/src/main/providers/notification_lifecycle_provider.dart` para escutar `IMessagingClient.onForegroundMessage` e exibir notificações locais via `ILocalNotificationClient.show()`.

```dart
@Riverpod(keepAlive: true)
final class NotificationLifecycle extends _$NotificationLifecycle {
  @override
  void build() {
    final repository = ref.watch(notificationRepositoryProvider);
    final messagingClient = ref.watch(messagingClientProvider);
    final localNotificationClient = ref.watch(localNotificationClientProvider);

    final tokenSubscription = repository.onTokenRefreshed.listen((_) {
      unawaited(repository.registerToken());
    });

    final foregroundSubscription =
        messagingClient.onForegroundMessage.listen((message) {
      unawaited(
        localNotificationClient.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message['title'] as String,
          body: message['body'] as String,
        ),
      );
    });

    ref.onDispose(() {
      tokenSubscription.cancel();
      foregroundSubscription.cancel();
    });
  }
}
```

O `id` da notificação local SHALL ser `DateTime.now().millisecondsSinceEpoch ~/ 1000` — um int suficientemente único para evitar sobrescrever notificações recentes.

O `ref.onDispose` SHALL cancelar **ambas** as subscriptions (token refresh e foreground messages).

#### Scenario: Foreground message exibe notificação local

Given o `NotificationLifecycleProvider` está ativo
When `onForegroundMessage` emite `{'title': 'Gasto compartilhado', 'body': 'R$ 50,00'}`
Then `localNotificationClient.show` SHALL ser chamado com title `'Gasto compartilhado'` e body `'R$ 50,00'`

#### Scenario: Token refresh continua funcionando

Given o `NotificationLifecycleProvider` está ativo
When `onTokenRefreshed` emite
Then `repository.registerToken()` SHALL ser chamado (comportamento existente preservado)

#### Scenario: Dispose cancela ambas as subscriptions

Given o `NotificationLifecycleProvider` está ativo
When o container é disposed
Then ambos os streams (token refresh e foreground messages) SHALL NOT ter listeners ativos

---

### Requirement: Clean Architecture layering

O sistema SHALL respeitar a regra de dependência do projeto:

- `infrastructure/clients/notification/` — `LocalNotificationClient` wrapa `FlutterLocalNotificationsPlugin`. Não conhece `domain/`, `data/`, `presentation/`.
- `infrastructure/clients/messaging/` — `MessagingClient` wrapa `FirebaseMessaging`. Não conhece `domain/`, `data/`, `presentation/`.
- `main/providers/` — faz o wiring: `localNotificationClientProvider`, e `NotificationLifecycleProvider` orquestra os clients e repository.

Nenhuma camada de `domain/` ou `data/` é alterada. O `ILocalNotificationClient` vive em `infrastructure/` (como `IFirebaseClient`, `IStorageClient`) porque é um wrapper de plugin externo, não um contrato de domínio.

#### Scenario: Nenhum import de domain em infrastructure/clients/notification/

Given o arquivo `local_notification_client.dart`
When `grep -rE "domain/" lib/src/infrastructure/clients/notification/` é executado
Then o resultado SHALL ser vazio

#### Scenario: Nenhum import de presentation em main/providers/notification_lifecycle_provider.dart

Given o arquivo `notification_lifecycle_provider.dart`
When `grep -rE "presentation/" lib/src/main/providers/notification_lifecycle_provider.dart` é executado
Then o resultado SHALL ser vazio

---

### Requirement: Tests

A mudança SHALL incluir a cobertura de testes descrita abaixo. Descrições de testes em inglês. Mocks declarados pelo tipo da interface. `var` SHALL NOT ser usado.

**`test/mocks/mocks.dart` — novos mocks:**

```dart
final class MockLocalNotificationClient extends Mock
    implements ILocalNotificationClient {}
```

**`test/src/main/providers/notification_lifecycle_provider_test.dart` — estender testes existentes:**

- Foreground message triggers `localNotificationClient.show` with correct title and body.
- Multiple foreground messages trigger one `show` per message.
- Token refresh continues to trigger `registerToken` (regressão — teste existente deve continuar passando).
- Container dispose cancels both subscriptions (foreground + token refresh).
- Slow `show` does not block subsequent foreground messages (`unawaited`).

Os testes existentes de token refresh SHALL continuar passando sem alteração de comportamento. O `makeContainer` SHALL ser atualizado para injetar `MockLocalNotificationClient` e `MockMessagingClient` via overrides.

#### Scenario: Testes passam

Given a implementação completa
When `flutter analyze && flutter test` é executado
Then ambos os comandos SHALL finalizar com zero erros

#### Scenario: Arquivos de teste existentes

Given os testes
Then `test/src/main/providers/notification_lifecycle_provider_test.dart` SHALL conter testes para foreground message handling
And os testes existentes de token refresh SHALL continuar passando

---
