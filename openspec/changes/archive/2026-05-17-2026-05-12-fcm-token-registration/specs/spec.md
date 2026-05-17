# Spec: fcm-token-registration

## Requirements

### Requirement: Register FCM token after authenticated splash

The system SHALL register the device FCM token on the backend whenever the Splash determines that the user is authenticated. Registration runs in the background and does not affect or delay navigation.

#### Scenario: authenticated session triggers registration

- **Given** an authenticated session
- **When** `SplashNotifier.build()` resolves the session check as `authenticated`
- **Then** `INotificationRepository.registerToken()` is invoked exactly once
- **And** the returned `SplashStatus` is `authenticated`

#### Scenario: unauthenticated session skips registration

- **Given** no valid session
- **When** `SplashNotifier.build()` resolves the session check as `unauthenticated`
- **Then** `INotificationRepository.registerToken()` is NOT invoked
- **And** the returned `SplashStatus` is `unauthenticated`

---

### Requirement: Registration is transparent to the user

The system SHALL not surface success or failure of the FCM token registration to the user. The splash status, navigation, and screen state SHALL be unaffected by the result of the registration call.

#### Scenario: backend returns 4xx/5xx

- **Given** an authenticated session and a backend that responds with a `FailureResponse`
- **When** the registration flow runs
- **Then** the final `SplashStatus` is still `authenticated`
- **And** no UI state change is emitted

#### Scenario: messaging client returns null token

- **Given** `IMessagingClient.getToken()` returns `null` (e.g. APNs token not yet available on iOS, or Firebase init delayed)
- **When** `RemoteNotificationDataSource.registerToken()` runs
- **Then** no HTTP request is made
- **And** the method returns `Right(null)`

#### Scenario: messaging client SDK throws

- **Given** `FirebaseMessaging.instance.getToken()` throws any exception
- **When** `IMessagingClient.getToken()` runs
- **Then** the exception is swallowed and `null` is returned
- **And** the registration flow proceeds as in the previous scenario (no POST, `Right(null)`)

---

### Requirement: Splash navigation is not blocked by registration

The system SHALL NOT await the FCM registration call before returning the `SplashStatus`. The registration runs via `unawaited(...)` in parallel to the navigation triggered by the Splash screen.

#### Scenario: registration is in-flight when Splash returns

- **Given** an authenticated session and a slow backend
- **When** `SplashNotifier.build()` resolves
- **Then** the resolution does not depend on `INotificationRepository.registerToken()` completing
- **And** the Splash screen navigates to Home as soon as `authenticated` is emitted

---

### Requirement: Presentation depends only on domain

The system SHALL keep the Splash notifier free of `data/` and `infrastructure/` imports. All orchestration involving `IMessagingClient` and HTTP belongs in the data source layer.

#### Scenario: SplashNotifier imports

- **Given** the implementation of `SplashNotifier`
- **When** its import list is inspected
- **Then** it imports only `domain/repositories/`, `presentation/`, and `main/providers/`
- **And** it does NOT import `infrastructure/clients/messaging`, `infrastructure/clients/logger`, or any other `infrastructure/` symbol

---

### Requirement: FcmTokenRequest serialization

The system SHALL serialize the registration body with exactly two fields: `token` (string) and `platform` (string, lowercase `"android"` or `"ios"`).

#### Scenario: toJson outputs both fields

- **Given** a `FcmTokenRequest(token: "abc123", platform: "android")`
- **When** `toJson()` is called
- **Then** the result is `{"token": "abc123", "platform": "android"}`

---

### Requirement: DataSource orchestrates fetch and POST

The system SHALL fetch the FCM token and platform from `IMessagingClient` inside `RemoteNotificationDataSource.registerToken()` and post to `/api/v1/me/fcm-token` with the resulting `FcmTokenRequest` body.

#### Scenario: token available

- **Given** `IMessagingClient.getToken()` returns a non-null string and `IMessagingClient.platform` returns `"android"`
- **When** `RemoteNotificationDataSource.registerToken()` is called
- **Then** `IHttpClient.post` is called once with `path == "/api/v1/me/fcm-token"` and `body == {"token": <token>, "platform": "android"}`
- **And** the method returns `Right(null)` if the HTTP layer succeeds

#### Scenario: token unavailable

- **Given** `IMessagingClient.getToken()` returns `null`
- **When** `RemoteNotificationDataSource.registerToken()` is called
- **Then** `IHttpClient.post` is NOT invoked
- **And** the method returns `Right(null)`

---

### Requirement: Repository maps backend errors to typed Failure

The system SHALL convert the `FailureResponse` returned by the datasource into the appropriate `Failure` subtype using `FailureResponseExtension.toFailure()`.

#### Scenario: network error

- **Given** the datasource returns `Left(FailureResponse)` with `code == "network_error"`
- **When** `NotificationRepository.registerToken()` is called
- **Then** it returns `Left(NetworkFailure())`

#### Scenario: server error

- **Given** the datasource returns `Left(FailureResponse)` with `code == "server_error"`
- **When** `NotificationRepository.registerToken()` is called
- **Then** it returns `Left(ServerFailure())`

#### Scenario: validation error

- **Given** the datasource returns `Left(FailureResponse)` with an unrecognized code (e.g. `"invalid"`)
- **When** `NotificationRepository.registerToken()` is called
- **Then** it returns `Left(ValidationFailure(message))` carrying the message from the API

#### Scenario: success returns Right(null)

- **Given** the datasource returns `Right(null)`
- **When** `NotificationRepository.registerToken()` is called
- **Then** it returns `Right(null)`

---

### Requirement: Endpoint uses the authenticated path

The system SHALL call `POST /api/v1/me/fcm-token` with the `Authorization: Bearer <access>` header injected by `AuthenticationInterceptor`. The endpoint SHALL NOT be added to `EndpointKey._publicEndpoints`.

#### Scenario: request hits the protected endpoint

- **Given** a registered access token in `ILocalTokenDataSource`
- **When** `RemoteNotificationDataSource.registerToken()` is called with a valid FCM token
- **Then** the HTTP request targets `/api/v1/me/fcm-token`
- **And** it carries the `Authorization: Bearer` header (verified indirectly via interceptor behavior)

---

### Requirement: MessagingClient exposes platform and never throws on getToken

The system SHALL expose the runtime platform string via `IMessagingClient.platform`, returning lowercase `"android"` on Android and `"ios"` on iOS. `IMessagingClient.getToken()` SHALL never propagate exceptions — failures from the Firebase SDK result in a `null` return.

#### Scenario: platform on Android

- **Given** the app is running on Android
- **When** `IMessagingClient.platform` is read
- **Then** it returns `"android"`

#### Scenario: platform on iOS

- **Given** the app is running on iOS
- **When** `IMessagingClient.platform` is read
- **Then** it returns `"ios"`

#### Scenario: SDK exception swallowed

- **Given** `FirebaseMessaging.instance.getToken()` throws an exception
- **When** `IMessagingClient.getToken()` is called
- **Then** it returns `null` without propagating the exception
