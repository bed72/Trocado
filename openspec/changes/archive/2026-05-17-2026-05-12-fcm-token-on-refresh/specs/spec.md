# Spec: fcm-token-on-refresh

## Requirements

### Requirement: Subscribe to FCM token refresh stream at app boot

The system SHALL subscribe to `IMessagingClient.onTokenRefresh` once during app boot via a Riverpod provider with `keepAlive: true`. The subscription SHALL remain active for the entire app lifetime and SHALL be canceled when the `ProviderContainer` is disposed.

#### Scenario: provider materializes and listener is attached

- **Given** a fresh `ProviderContainer` with mocked `IMessagingClient` and `INotificationRepository`
- **When** `container.read(notificationLifecycleProvider)` is called
- **Then** the `IMessagingClient.onTokenRefresh` stream has exactly one listener attached
- **And** no call to `registerToken()` happens until the stream emits

#### Scenario: container dispose cancels the subscription

- **Given** a materialized `notificationLifecycleProvider`
- **When** `container.dispose()` is called
- **Then** the stream subscription is canceled
- **And** the stream has no listeners (`StreamController.hasListener == false`)

---

### Requirement: Each token refresh event triggers a single registerToken call

The system SHALL invoke `INotificationRepository.registerToken()` exactly once per event emitted by `IMessagingClient.onTokenRefresh`. The new token value is NOT passed as a parameter — `registerToken()` fetches the current token internally.

#### Scenario: single emit triggers one registration

- **Given** a materialized `notificationLifecycleProvider`
- **When** `IMessagingClient.onTokenRefresh` emits a single token value
- **Then** `INotificationRepository.registerToken()` is called exactly once
- **And** it is called without arguments

#### Scenario: multiple emits trigger one call per emit

- **Given** a materialized `notificationLifecycleProvider`
- **When** `IMessagingClient.onTokenRefresh` emits three token values sequentially
- **Then** `INotificationRepository.registerToken()` is called exactly three times

---

### Requirement: Registration runs fire-and-forget

The system SHALL invoke `INotificationRepository.registerToken()` via `unawaited(...)`. The listener callback SHALL NOT await the result, and failures of `registerToken()` SHALL NOT propagate out of the callback.

#### Scenario: slow registerToken does not block subsequent emits

- **Given** a materialized `notificationLifecycleProvider` and a slow `registerToken()` (never-completing Future)
- **When** `IMessagingClient.onTokenRefresh` emits two token values in sequence
- **Then** `registerToken()` is invoked twice
- **And** no exception is thrown out of the listener callback

#### Scenario: registerToken failure does not break the listener

- **Given** a materialized `notificationLifecycleProvider` and a `registerToken()` returning `Left(NetworkFailure())`
- **When** `IMessagingClient.onTokenRefresh` emits a token value
- **And** subsequently emits a second token value
- **Then** `registerToken()` is invoked twice
- **And** the listener remains attached to the stream

---

### Requirement: MessagingClient exposes the FCM token refresh stream

The system SHALL expose `Stream<String> get onTokenRefresh` on `IMessagingClient` as a thin pass-through to `FirebaseMessaging.instance.onTokenRefresh`. The getter SHALL NOT wrap, transform, or filter the stream.

#### Scenario: IMessagingClient interface

- **Given** the implementation of `IMessagingClient`
- **When** its interface is inspected
- **Then** it declares `Stream<String> get onTokenRefresh`
- **And** it declares the existing `String get platform` and `Future<String?> getToken()`

---

### Requirement: Provider is initialized once at app boot

The system SHALL call `container.read(notificationLifecycleProvider)` in `main.dart` after `firebaseClientProvider.initialize()` and before `runApp(...)`. This call SHALL be the sole materialization trigger — no other code path is expected to read or watch this provider.

#### Scenario: main.dart kick after Firebase init

- **Given** the implementation of `main()`
- **When** the boot sequence is inspected
- **Then** `container.read(notificationLifecycleProvider)` appears after `await container.read(firebaseClientProvider).initialize()`
- **And** it appears before `runApp(...)`
