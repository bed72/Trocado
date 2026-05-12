# Spec: fcm-token-on-logout

## Requirements

### Requirement: Revoke FCM token on logout

The system SHALL invoke `INotificationRepository.revokeToken()` as the first step of `AuthenticationRepository.logout()`, before any other operation. Invocation runs via `unawaited(...)` and SHALL NOT block the logout flow.

#### Scenario: successful logout revokes token

- **Given** a valid session with a refresh token in local storage
- **When** `AuthenticationRepository.logout()` is called
- **Then** `INotificationRepository.revokeToken()` is invoked exactly once
- **And** the logout returns `Right(null)`
- **And** local tokens are cleared

#### Scenario: logout with null refresh still revokes token

- **Given** local session with `refresh == null`
- **When** `AuthenticationRepository.logout()` is called
- **Then** `INotificationRepository.revokeToken()` is invoked exactly once
- **And** the logout returns `Right(null)` without calling the remote `signOut`
- **And** local tokens are cleared

#### Scenario: logout with remote signOut error still revokes token

- **Given** a valid local session and a backend that fails the `signOut` call
- **When** `AuthenticationRepository.logout()` is called
- **Then** `INotificationRepository.revokeToken()` is invoked exactly once
- **And** the logout returns `Left(Failure)`
- **And** local tokens are NOT cleared

#### Scenario: slow revokeToken does not block logout

- **Given** a valid session and a `revokeToken()` returning a never-completing Future
- **When** `AuthenticationRepository.logout()` is called
- **Then** the logout returns its normal result without awaiting `revokeToken()`
- **And** `revokeToken()` was invoked once

---

### Requirement: revokeToken interface and behavior

The system SHALL expose `Future<Either<Failure, void>> revokeToken()` on `INotificationRepository` with no parameters. The implementation SHALL fetch the current FCM token via `IMessagingClient.getToken()` and DELETE it on the backend; the caller does not pass the token.

#### Scenario: interface declares revokeToken without parameters

- **Given** the definition of `INotificationRepository`
- **When** the interface is inspected
- **Then** it declares both `registerToken()` and `revokeToken()`
- **And** neither method takes parameters

---

### Requirement: DELETE call uses the protected endpoint with body

The system SHALL call `DELETE /api/v1/me/fcm-token` with a JSON body containing only the `token` field. The endpoint is protected — `Authorization: Bearer <access>` is injected by `AuthenticationInterceptor`.

#### Scenario: token available — DELETE is issued

- **Given** `IMessagingClient.getToken()` returns a non-null string `"abc"`
- **When** `RemoteNotificationDataSource.revokeToken()` is called
- **Then** `IHttpClient.delete` is called exactly once
- **And** the request path is `/api/v1/me/fcm-token`
- **And** the request body is `{"token": "abc"}`
- **And** the method returns `Right(null)` on HTTP success

#### Scenario: token unavailable — no DELETE issued

- **Given** `IMessagingClient.getToken()` returns `null`
- **When** `RemoteNotificationDataSource.revokeToken()` is called
- **Then** `IHttpClient.delete` is NOT invoked
- **And** the method returns `Right(null)`

#### Scenario: HTTP error maps to Left FailureResponse

- **Given** `IMessagingClient.getToken()` returns a valid token
- **And** `IHttpClient.delete` returns `Left(...)` with a `FailureResponse`-shaped map
- **When** `RemoteNotificationDataSource.revokeToken()` is called
- **Then** the method returns `Left(FailureResponse)`

---

### Requirement: FcmTokenDeleteRequest serialization

The system SHALL serialize the DELETE body as a JSON object with exactly one field: `token` (string). The body SHALL NOT include `platform` or any other field.

#### Scenario: toJson contains only token

- **Given** a `FcmTokenDeleteRequest(token: "abc")`
- **When** `toJson()` is called
- **Then** the result is `{"token": "abc"}`
- **And** the result contains no other keys

---

### Requirement: Repository maps backend errors to typed Failure

The system SHALL convert any `FailureResponse` returned by the datasource into the appropriate `Failure` subtype using `FailureResponseExtension.toFailure()`, identically to how `registerToken()` does it.

#### Scenario: network error

- **Given** the datasource returns `Left(FailureResponse)` with code `network_error`
- **When** `NotificationRepository.revokeToken()` is called
- **Then** it returns `Left(NetworkFailure())`

#### Scenario: server error

- **Given** the datasource returns `Left(FailureResponse)` with code `server_error`
- **When** `NotificationRepository.revokeToken()` is called
- **Then** it returns `Left(ServerFailure())`

#### Scenario: validation error

- **Given** the datasource returns `Left(FailureResponse)` with an unrecognized code
- **When** `NotificationRepository.revokeToken()` is called
- **Then** it returns `Left(ValidationFailure(message))` carrying the API message

#### Scenario: success returns Right(null)

- **Given** the datasource returns `Right(null)`
- **When** `NotificationRepository.revokeToken()` is called
- **Then** it returns `Right(null)`

---

### Requirement: Data and infrastructure dependencies wired through main/providers

The system SHALL wire `INotificationRepository` into `AuthenticationRepository` via the existing `repositories_provider.dart`. No client code outside the composition root SHALL construct `AuthenticationRepository` directly.

#### Scenario: provider wiring

- **Given** the `authenticationRepositoryProvider` factory
- **When** its dependencies are inspected
- **Then** it reads `ref.watch(notificationRepositoryProvider)` in addition to the existing dependencies
- **And** it passes the resolved `INotificationRepository` to the `AuthenticationRepository` constructor
