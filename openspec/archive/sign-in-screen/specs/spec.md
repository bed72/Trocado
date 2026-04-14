# Spec — sign-in-screen

## Requirements

### Requirement: Email Input
The system SHALL render a text field with floating label "E-mail", keyboard type `emailAddress`, that dispatches `EmailChanged` on every character change.

#### Scenario: User types an email
Given the sign-in screen is displayed
When the user types into the email field
Then `SignInState.email` SHALL reflect the typed value

---

### Requirement: Password Input
The system SHALL render a text field with floating label "Senha", `obscureText: true`, `inputAction: done`, that dispatches `PasswordChanged` on every character change.

#### Scenario: User types a password
Given the sign-in screen is displayed
When the user types into the password field
Then `SignInState.password` SHALL reflect the typed value

---

### Requirement: Submit Loading
The system SHALL show a loading indicator on the "Entrar" button while `SignInStatus.loading`.

#### Scenario: Submission in progress
Given the user pressed "Entrar"
When the repository call has not yet returned
Then `SignInState.status` SHALL be `loading`
And the "Entrar" button SHALL display a loading indicator

---

### Requirement: Submit Success
The system SHALL navigate to HomeLocation when sign-in succeeds.

#### Scenario: Successful sign-in
Given the user has filled email and password
When the repository returns `Right(AuthenticationModel)`
Then `SignInState.status` SHALL be `success`
And the screen SHALL call `onSuccess`, navigating to `HomeLocation`

---

### Requirement: Submit Failure
The system SHALL set `status = failure` and populate `message` when sign-in fails.

#### Scenario: Invalid credentials
Given the user has filled email and password
When the repository returns `Left(ValidationFailure('message'))`
Then `SignInState.status` SHALL be `failure`
And `SignInState.message` SHALL equal the failure message

#### Scenario: Network error
Given the user has filled email and password
When the repository returns `Left(NetworkFailure())`
Then `SignInState.status` SHALL be `failure`

---

### Requirement: Forgot Password (stub)
The system SHALL render a "Esqueci minha senha" text button aligned to the right.
The button onTap SHALL be `null` (no action implemented in this scope).

---

### Requirement: Register Link (stub)
The system SHALL render the text "Ainda não tem uma conta?" followed by a "Criar conta" text button.
The button onTap SHALL be `null` (no action implemented in this scope).
