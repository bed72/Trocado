# Spec: sign-in-datasource

## Requirements

### Requirement: Sign In with valid credentials

The system SHALL call `POST /auth/token/` with email and password and return an `AuthenticationModel` containing the access and refresh tokens.

#### Scenario: success

Given a valid email and password
When `AuthenticationRepository.signIn` is called
Then it returns `Right(AuthenticationModel)` with non-empty `access` and `refresh`

---

### Requirement: Sign In with invalid credentials

The system SHALL return a `Left(ValidationFailure)` when the API responds with an error.

#### Scenario: invalid credentials

Given an email/password combination not recognized by the API
When `AuthenticationRepository.signIn` is called
Then it returns `Left(ValidationFailure)` with the message from the API

---

### Requirement: Sign In with no network

The system SHALL return a `Left(NetworkFailure)` when the client cannot reach the server.

#### Scenario: network error

Given no network connectivity
When `AuthenticationRepository.signIn` is called
Then it returns `Left(NetworkFailure)`

---

### Requirement: SignInResponse deserialization

The system SHALL correctly deserialize the API response into `SignInResponse` and convert to `AuthenticationModel`.

#### Scenario: fromJson parses tokens

Given a JSON `{ "access": "abc", "refresh": "xyz" }`
When `SignInResponse.fromJson` is called
Then `response.access == "abc"` and `response.refresh == "xyz"`

#### Scenario: toModel maps to domain

Given a `SignInResponse` with access and refresh
When `toModel()` is called
Then it returns an `AuthenticationModel` with the same values
