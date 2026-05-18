# Spec: notification-lifecycle-via-repository

## Requirements

### Requirement: NotificationLifecycle depends only on the notification repository

The system SHALL refactor `NotificationLifecycle` so its `build()` reads **only** `notificationRepositoryProvider`. The notifier SHALL NOT import or read `messagingClientProvider`, `IMessagingClient`, or any symbol from `infrastructure/clients/messaging/`.

#### Scenario: notifier imports surface

- **Given** the file `lib/src/main/providers/notification_lifecycle_provider.dart`
- **When** its imports are inspected
- **Then** there is no import of `package:trocado/src/main/providers/clients_provider.dart`
- **And** there is no import of `package:trocado/src/infrastructure/clients/messaging/messaging_client.dart`

#### Scenario: notifier build dependencies

- **Given** the body of `NotificationLifecycle.build()`
- **When** the `ref.watch(...)` calls are inspected
- **Then** the only watched provider is `notificationRepositoryProvider`

---

### Requirement: INotificationRepository exposes a token-refresh stream

The system SHALL add `Stream<void> get onTokenRefreshed` to `INotificationRepository`. The stream SHALL emit a `void` event each time the underlying FCM token is rotated. The stream SHALL NOT carry the token value — the domain consumer SHALL fetch the current token through other means (the existing `registerToken()` already does so internally).

#### Scenario: interface surface

- **Given** the interface `INotificationRepository`
- **When** its members are inspected
- **Then** it declares `Stream<void> get onTokenRefreshed`
- **And** it keeps all five existing async methods: `deleteAll`, `revokeToken`, `registerToken`, `deleteById`, `findAll`

#### Scenario: repository delegates to datasource

- **Given** an instance of `NotificationRepository` with a mocked `IRemoteNotificationDataSource`
- **And** the mocked datasource's `onTokenRefreshed` returns a broadcast `StreamController<void>.stream`
- **When** the controller emits two events
- **Then** the listener attached to `repository.onTokenRefreshed` receives exactly two events
- **And** the events arrive in the same order as the controller emissions

---

### Requirement: IRemoteNotificationDataSource exposes a void-narrowed stream

The system SHALL add `Stream<void> get onTokenRefreshed` to `IRemoteNotificationDataSource`. The implementation `RemoteNotificationDataSource` SHALL return `_messagingClient.onTokenRefresh.map((_) {})` — discarding the `String` token value so the boundary `infrastructure → data` exposes only the trigger, not the payload.

#### Scenario: datasource interface surface

- **Given** the interface `IRemoteNotificationDataSource`
- **When** its members are inspected
- **Then** it declares `Stream<void> get onTokenRefreshed`

#### Scenario: datasource maps each upstream emit to a void event

- **Given** a `RemoteNotificationDataSource` instance with mocked `IMessagingClient`
- **And** a `StreamController<String>.broadcast()` wired into `messagingClient.onTokenRefresh`
- **When** the controller emits `'token-1'` and `'token-2'`
- **Then** a listener attached to `dataSource.onTokenRefreshed` receives exactly two `void` events

#### Scenario: datasource subscription propagates upstream

- **Given** the datasource and the same broadcast controller setup
- **When** a listener is attached to `dataSource.onTokenRefreshed`
- **Then** the controller reports `hasListener == true`

---

### Requirement: Notifier behavior is preserved byte-for-byte

The system SHALL preserve the existing observable behavior of `NotificationLifecycle`: materialization attaches exactly one listener; each emit triggers exactly one `repository.registerToken()` call; the call is fire-and-forget via `unawaited(...)`; a slow `registerToken` does not block subsequent emits; container disposal cancels the subscription.

#### Scenario: materialization attaches a listener

- **Given** a fresh `ProviderContainer` overriding `notificationRepositoryProvider` with a mocked `INotificationRepository`
- **And** the mock's `onTokenRefreshed` returns a broadcast `StreamController<void>.stream`
- **When** `container.read(notificationLifecycleProvider)` is called
- **Then** the controller reports `hasListener == true`
- **And** `registerToken()` is not called yet

#### Scenario: single emit triggers one registration

- **Given** a materialized `notificationLifecycleProvider`
- **When** the underlying stream emits one event
- **Then** `INotificationRepository.registerToken()` is called exactly once

#### Scenario: multiple emits trigger one call per emit

- **Given** a materialized `notificationLifecycleProvider`
- **When** the underlying stream emits three events in sequence
- **Then** `INotificationRepository.registerToken()` is called exactly three times

#### Scenario: slow registerToken does not block subsequent emits

- **Given** a materialized `notificationLifecycleProvider`
- **And** `registerToken()` returns a never-completing future
- **When** the underlying stream emits two events in sequence
- **Then** `registerToken()` is invoked twice
- **And** no exception leaks out of the listener callback

#### Scenario: container dispose cancels the subscription

- **Given** a materialized `notificationLifecycleProvider`
- **When** `container.dispose()` is called
- **Then** the controller reports `hasListener == false`

---

### Requirement: IMessagingClient surface is unchanged

The system SHALL keep `IMessagingClient` exactly as today: `String get platform`, `Future<String?> getToken()`, `Stream<String> get onTokenRefresh`. The interface SHALL NOT be widened, narrowed, or renamed. After the refactor, the only production consumer of `IMessagingClient` continues to be `RemoteNotificationDataSource`.

#### Scenario: messaging client interface

- **Given** the interface `IMessagingClient`
- **When** its members are inspected
- **Then** the three existing members are present with their original signatures
- **And** no new members are added or removed

#### Scenario: production consumers of messaging client

- **Given** the entire `lib/` directory
- **When** files importing `infrastructure/clients/messaging/messaging_client.dart` are inspected
- **Then** the only files are `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` (real consumer via DI) and `lib/src/main/providers/clients_provider.dart` (DI wiring point)
- **And** `lib/src/main/providers/notification_lifecycle_provider.dart` is NOT among them
