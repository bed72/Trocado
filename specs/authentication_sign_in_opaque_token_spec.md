# Spec: Authentication Sign-In with Opaque Token

## Context

The Kotlin backend replaces the previous JWT authentication contract. The first
migration step covers sign-in and local session handling only.

All responses in this flow SHALL follow the shared contract defined in
`specs/api_response_envelope_spec.md`.

The preview API is available at `https://cordato.cloud`.

## API Contract

### Sign-in

The app SHALL call `POST /v1/authentication/sign-in` with
`Content-Type: application/json`.

Request body:

```json
{
  "email": "gabriel@email.com",
  "password": "super-s3cret"
}
```

Successful response:

```json
{
  "data": {
    "token": "opaque-token",
    "expires_at": "2026-08-12T00:32:04.543677844Z"
  }
}
```

The token SHALL be treated as an opaque string. The app SHALL NOT decode it,
inspect claims, or assume that it is a JWT.

The sign-in response parser SHALL read the token and expiration from
`data.token` and `data.expires_at`; it SHALL not read either field from the
response root.

## Requirements

### Requirement: Sign in with valid credentials

The system SHALL send the supplied email and password to the new sign-in
endpoint and return an authentication model containing the opaque token and its
expiration instant.

#### Scenario: Successful sign-in

Given valid credentials
When `IAuthenticationRepository.signIn` is called
Then the datasource SHALL call `POST /v1/authentication/sign-in`
And the response SHALL be deserialized from the nested `data` object
And the repository SHALL return `Right(AuthenticationModel)`
And the model SHALL contain the same non-empty `token`
And the model SHALL contain `expiresAt` parsed from `expires_at`
And the token SHALL be persisted locally only after the response is parsed successfully

### Requirement: Sign-in response deserialization

The infrastructure response SHALL deserialize `data.token` as `String` and
`data.expires_at` as an ISO 8601 instant.

#### Scenario: Nested response is parsed

Given the response body contains `data.token = "opaque-token"`
And `data.expires_at = "2026-08-12T00:32:04.543677844Z"`
When the response is deserialized
Then the token SHALL equal `"opaque-token"`
And the expiration instant SHALL represent the supplied UTC timestamp

#### Scenario: JWT-shaped token is not decoded

Given the token contains arbitrary characters and no JWT claims
When the response is deserialized
Then deserialization SHALL preserve the token exactly
And no JWT parsing or validation SHALL be attempted

### Requirement: Sign-in failure

The system SHALL convert non-successful API responses using the existing
`FailureResponse` mapping and SHALL NOT persist a token when sign-in fails.

#### Scenario: Invalid credentials

Given the API rejects the credentials
When `IAuthenticationRepository.signIn` is called
Then it SHALL return `Left(Failure)` with the mapped API failure
And the local authentication data SHALL remain unchanged

#### Scenario: Network failure

Given the client cannot reach the API
When `IAuthenticationRepository.signIn` is called
Then it SHALL return `Left(NetworkFailure)`
And the local authentication data SHALL remain unchanged

### Requirement: Authenticated HTTP requests

The HTTP authentication interceptor SHALL attach the opaque token using the
`Authorization: Bearer <token>` header to protected requests.

#### Scenario: Protected request with a valid local session

Given a locally stored token whose expiration is later than the current UTC instant
When a protected request is sent
Then the request SHALL contain `Authorization: Bearer <token>`

#### Scenario: Public sign-in request

Given a sign-in request to `/v1/authentication/sign-in`
When the request interceptor runs
Then it SHALL not attach an authentication header

#### Scenario: Expired local session

Given the stored expiration is equal to or earlier than the current UTC instant
When a protected request is about to be sent
Then the token SHALL not be sent
And the local authentication data SHALL be cleared
And the existing unauthenticated callback SHALL be invoked

### Requirement: Session restoration

Because this authentication contract has no refresh token or token introspection
endpoint, session restoration SHALL rely on the locally stored token and its
expiration instant.

#### Scenario: Valid stored session

Given a non-empty stored token with a future expiration
When `checkSession` is called
Then it SHALL return `Right(null)`

#### Scenario: Missing or expired stored session

Given the token or expiration is missing, or the expiration has passed
When `checkSession` is called
Then local authentication data SHALL be cleared
And it SHALL return `Left(Failure)` representing an unauthenticated session
And no refresh request SHALL be made

## Affected Areas

- Sign-in endpoint and request body
- Authentication response parsing and domain model
- Local authentication storage for token and expiration
- Authentication interceptor
- Session restoration used by the splash flow
- Repository, datasource, extension, provider wiring, and related tests
- Shared API response envelope parsing

## Out of Scope

- Logout contract and server-side token revocation
- Sign-up contract
- Password reset contracts
- Any refresh-token endpoint or token rotation
- Changes to authentication error payloads not provided by the backend contract

These flows require their Kotlin backend contracts before being migrated.

## Approval Gate

Implementation SHALL NOT begin until this spec is approved.
