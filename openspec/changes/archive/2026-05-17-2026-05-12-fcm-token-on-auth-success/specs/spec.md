# Spec: fcm-token-on-auth-success

## Requirements

### Requirement: Register FCM token after successful SignIn

The system SHALL register the device FCM token on the backend whenever `SignInNotifier` resolves the authentication as successful. Registration runs in the background and does not affect or delay the state transition to `.success`.

#### Scenario: successful sign in triggers registration

- **Given** valid credentials and a backend that authenticates the user
- **When** `SignInNotifier._submit()` receives `Right` from `IAuthenticationRepository.signIn`
- **Then** `INotificationRepository.registerToken()` is invoked exactly once
- **And** the emitted `SignInState.status` is `.success`

#### Scenario: failed sign in does not trigger registration

- **Given** invalid credentials or a backend error
- **When** `SignInNotifier._submit()` receives `Left` from `IAuthenticationRepository.signIn`
- **Then** `INotificationRepository.registerToken()` is NOT invoked
- **And** the emitted `SignInState.status` is `.failure`

#### Scenario: invalid form does not trigger registration

- **Given** a form that fails validation (empty email, invalid password, etc.)
- **When** `SignInNotifier._submit()` runs
- **Then** `IAuthenticationRepository.signIn` is NOT invoked
- **And** `INotificationRepository.registerToken()` is NOT invoked

---

### Requirement: Register FCM token after successful SignUp

The system SHALL register the device FCM token on the backend whenever `SignUpNotifier` resolves the registration as successful. Registration runs in the background and does not affect or delay the state transition to `.success`.

#### Scenario: successful sign up triggers registration

- **Given** valid registration input and a backend that creates the account
- **When** `SignUpNotifier._submit()` receives `Right` from `IAuthenticationRepository.signUp`
- **Then** `INotificationRepository.registerToken()` is invoked exactly once
- **And** the emitted `SignUpState.status` is `.success`

#### Scenario: failed sign up does not trigger registration

- **Given** invalid input (existing email, terms unchecked, backend error, etc.)
- **When** `SignUpNotifier._submit()` receives `Left` from `IAuthenticationRepository.signUp`
- **Then** `INotificationRepository.registerToken()` is NOT invoked
- **And** the emitted `SignUpState.status` is `.failure`

#### Scenario: invalid form does not trigger registration

- **Given** a form that fails validation
- **When** `SignUpNotifier._submit()` runs
- **Then** `IAuthenticationRepository.signUp` is NOT invoked
- **And** `INotificationRepository.registerToken()` is NOT invoked

---

### Requirement: Registration is transparent to the user

The system SHALL not surface success or failure of the FCM token registration to the user. The notifier state, navigation, and screen state SHALL be unaffected by the result of the registration call.

#### Scenario: backend returns 4xx/5xx during registration

- **Given** a successful auth response and a backend that responds to the token POST with a `FailureResponse`
- **When** the registration flow runs
- **Then** the final `SignInState.status` (or `SignUpState.status`) is `.success`
- **And** no additional UI state change is emitted from the registration failure

#### Scenario: slow registration does not delay success emission

- **Given** a slow backend on `/api/v1/me/fcm-token`
- **When** `SignInNotifier._submit()` (or `SignUpNotifier._submit()`) reaches the `Right` branch
- **Then** the state transitions to `.success` without awaiting `registerToken()`
- **And** the registration call continues in the background via `unawaited(...)`

---

### Requirement: Notifiers depend only on domain

The system SHALL keep `SignInNotifier` and `SignUpNotifier` free of `data/` and `infrastructure/` imports. The notifier interacts with notifications only through `INotificationRepository` from `domain/repositories/`.

#### Scenario: SignInNotifier imports

- **Given** the implementation of `SignInNotifier`
- **When** its import list is inspected
- **Then** the only notification-related symbol imported is `INotificationRepository` from `domain/repositories/`
- **And** it does NOT import `IMessagingClient`, `ILoggerClient`, or any other `infrastructure/` symbol

#### Scenario: SignUpNotifier imports

- **Given** the implementation of `SignUpNotifier`
- **When** its import list is inspected
- **Then** the only notification-related symbol imported is `INotificationRepository` from `domain/repositories/`
- **And** it does NOT import `IMessagingClient`, `ILoggerClient`, or any other `infrastructure/` symbol
