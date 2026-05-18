# Spec: auth-interceptor-skip-refresh-when-absent

## Requirements

### Requirement: Interceptor short-circuits 401 handling when refresh token is absent

The system SHALL detect, in `AuthenticationInterceptor.onError`, the absence of a stored refresh token **before** attempting any call to `EndpointKey.refreshToken.path`. When `_dataSource.get()` returns a record whose `refresh` field is `null`, the interceptor SHALL: (a) clear local tokens via `_dataSource.clear()`, (b) invoke the `onUnauthenticated` callback, (c) propagate the original `DioException` via `handler.next(err)`. It SHALL NOT send any request to `/auth/refresh` in this scenario.

#### Scenario: 401 with no stored refresh token

- **Given** a protected request that responds with HTTP 401
- **And** `_dataSource.get()` returns `(access: null, refresh: null)`
- **When** `AuthenticationInterceptor.onError` runs
- **Then** the HTTP client adapter is **not** invoked for the refresh-token endpoint
- **And** `_dataSource.clear()` is called exactly once
- **And** the `onUnauthenticated` callback is invoked
- **And** `_dataSource.save(...)` is never called
- **And** the original `DioException` is propagated to the caller

#### Scenario: 401 with only access token stored (refresh missing)

- **Given** a protected request that responds with HTTP 401
- **And** `_dataSource.get()` returns `(access: 'stale_access', refresh: null)`
- **When** `AuthenticationInterceptor.onError` runs
- **Then** the early-return path is taken (same observable behavior as the all-null scenario)
- **And** no request to `/auth/refresh` is dispatched

---

### Requirement: Existing 401 refresh behavior is preserved

The system SHALL preserve, byte-for-byte, the observable behavior of `onError` for every scenario in which a refresh token **is** present. The early-return path SHALL only apply when `tokens.refresh == null`.

#### Scenario: 401 with valid refresh token succeeds via refresh + retry

- **Given** a protected request that responds with HTTP 401
- **And** `_dataSource.get()` returns `(access: 'old_access', refresh: 'old_refresh')`
- **And** the refresh endpoint responds 200 with new tokens
- **When** `AuthenticationInterceptor.onError` runs
- **Then** `_dataSource.save(access: 'new_access', refresh: 'new_refresh')` is called once
- **And** the original request is retried with the new bearer token
- **And** `onUnauthenticated` is NOT invoked

#### Scenario: 401 with expired refresh token falls into catch

- **Given** a protected request that responds with HTTP 401
- **And** `_dataSource.get()` returns `(access: 'old_access', refresh: 'expired_refresh')`
- **And** the refresh endpoint responds 401 (or 4xx with `token_not_valid`)
- **When** `AuthenticationInterceptor.onError` runs
- **Then** the POST to `/auth/refresh` is sent (early return does NOT trigger because `refresh != null`)
- **And** the `catch (_)` block runs: `_dataSource.clear()` is called and `onUnauthenticated` is invoked
- **And** the original `DioException` is propagated

---

### Requirement: Non-401 errors and public paths remain untouched

The system SHALL NOT alter the existing handling for: (a) errors whose status code is not 401, (b) errors originating from public endpoints. These continue to be forwarded directly via `handler.next(err)` without consulting the token data source.

#### Scenario: non-401 error propagates without refresh

- **Given** a protected request that responds with HTTP 500
- **When** `AuthenticationInterceptor.onError` runs
- **Then** no call is made to `_dataSource.get()`, `_dataSource.clear()`, or the refresh endpoint
- **And** the original error is propagated unchanged

#### Scenario: 401 on a public endpoint propagates without refresh

- **Given** a public endpoint (per `EndpointKey.isPublicPath`) that responds with HTTP 401
- **When** `AuthenticationInterceptor.onError` runs
- **Then** no call is made to `_dataSource.get()`, `_dataSource.clear()`, or the refresh endpoint
- **And** the original error is propagated unchanged

---

### Requirement: Defense-in-depth via try/catch is preserved

The system SHALL keep the `try/catch (_)` around the refresh POST + token persistence + retry. The early return for missing refresh token SHALL NOT replace the catch; it SHALL be an additional, earlier short-circuit. Failures of the refresh POST, JSON parsing, or `_dataSource.save(...)` SHALL continue to fall through to the catch and trigger the same `clear` + `onUnauthenticated` + `handler.next(err)` flow.

#### Scenario: catch block still triggers on null response body

- **Given** a protected request that responds with HTTP 401
- **And** `_dataSource.get()` returns `(access: 'a', refresh: 'r')`
- **And** the refresh endpoint responds 200 with body `null` (defying contract)
- **When** `AuthenticationInterceptor.onError` runs
- **Then** the `data!['access']` access throws and is caught
- **And** `_dataSource.clear()` is called and `onUnauthenticated` is invoked
- **And** the original `DioException` is propagated
