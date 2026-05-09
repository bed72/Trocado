# profile Specification (delta)

## Purpose (new)

A feature `profile` é a tela de gestão de dados pessoais do usuário (`/profile`). Esta change cria a feature do zero — começa com **scaffold de navegação** (apenas título e descrição, sem lógica de negócio) e será estendida nas próximas partes (leitura, edição, exclusão).

## Requirements

### Requirement: AppRoutes.profile entry

The system SHALL add a `profile` entry to `AppRoutes` in `lib/app_route.dart` with `path: '/profile'`, `name: 'profile-route'`, and a regex matching exactly `/profile`. The entry SHALL be included in `AppRoutes._all`.

#### Scenario: Route is registered

Given the app starts
Then `AppRoutes.profile.path` SHALL equal `'/profile'`
And `AppRoutes._all` SHALL contain the `profile` entry

---

### Requirement: ProfileScreen renders header-only scaffold

The system SHALL create `lib/src/presentation/ui/profile/screens/profile_screen.dart` as a `StatelessWidget` with a `const` constructor, mirroring `NotificationsScreen`.

The screen SHALL render:

- `ScaffoldWidget` with `appBar: AppBarWidget(leading: GoBackWidget())`.
- Body: `Padding(padding: const EdgeInsets.all(16.0), ...)` containing a `Column(crossAxisAlignment: CrossAxisAlignment.start, ...)`.
- Column children, in order: `ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.')`, `SizedBox(height: 24.0)`, `Expanded(child: Placeholder())`.

The screen SHALL NOT depend on any provider, notifier, repository or service in this part.

#### Scenario: Screen renders title and description

Given the user navigates to `ProfileLocation`
When `ProfileScreen` builds
Then a `ScreenHeaderWidget` SHALL be present with `title == 'Dados pessoais'`
And `description == 'Gerencie as informações da sua conta.'`

#### Scenario: Screen has back navigation

Given `ProfileScreen` is rendered
Then its `AppBarWidget` SHALL have a `GoBackWidget` as the `leading`
And tapping `GoBackWidget` SHALL trigger `context.pop()`

---

### Requirement: ProfileLocation registers the route

The system SHALL create `lib/src/presentation/ui/profile/locations/profile_location.dart` defining `final class ProfileLocation extends Location`.

`ProfileLocation` SHALL declare:

- `String get path` returning `AppRoutes.profile.path`.
- `LocationPageBuilder get pageBuilder` returning `(_) => screenPage(const ProfileScreen())`.

`ProfileLocation` SHALL NOT receive any constructor parameters in this part.

#### Scenario: Location resolves the path

Given `ProfileLocation()` is constructed
Then `path` SHALL equal `'/profile'`

#### Scenario: pageBuilder constructs ProfileScreen

Given `ProfileLocation()` is constructed
When `pageBuilder(context)` is invoked
Then it SHALL return a `Page` wrapping a `const ProfileScreen()`

---

### Requirement: HomeAvatarWidget is tappable

The system SHALL extend `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart` with an optional `final VoidCallback? onTap;` parameter declared before the constructor.

The constructor SHALL be `const HomeAvatarWidget({ super.key, required this.name, this.size = 48.0, this.onTap })`.

The `build` method SHALL wrap the existing `Container` in `BounceWidget.withOnPress(onPress: onTap, child: <container>)`. When `onTap == null`, `BounceWidget.withOnPress` receives `null` and SHALL NOT animate or fire any callback.

#### Scenario: Tap on avatar with onTap fires the callback

Given a `HomeAvatarWidget` constructed with a non-null `onTap`
When the user taps the avatar
Then `BounceWidget.withOnPress` SHALL animate the press
And `onTap` SHALL be invoked exactly once

#### Scenario: Tap on avatar without onTap does nothing

Given a `HomeAvatarWidget` constructed with `onTap: null`
When the user taps the avatar
Then no callback SHALL fire and no navigation SHALL occur

---

### Requirement: HomeAppBarWidget propagates navigateToProfile

The system SHALL extend `lib/src/presentation/ui/home/widgets/home_app_bar_widget.dart` with `final VoidCallback navigateToProfile;` named-required, declared before the constructor next to the existing `navigateToSettings` and `navigateToNotification`.

The constructor SHALL include `required this.navigateToProfile`.

In `build`, `HomeAvatarWidget` SHALL be constructed with `onTap: navigateToProfile`.

#### Scenario: Tapping the avatar from the app bar triggers navigateToProfile

Given a `HomeAppBarWidget` constructed with a `navigateToProfile` callback
When the user taps the `HomeAvatarWidget` rendered inside the app bar
Then `navigateToProfile` SHALL be invoked exactly once

---

### Requirement: HomeScreen propagates navigateToProfile

The system SHALL extend `lib/src/presentation/ui/home/screens/home_screen.dart` with `final VoidCallback navigateToProfile;` named-required, declared before the constructor next to the existing `navigateToX` callbacks.

The constructor SHALL include `required this.navigateToProfile`.

`HomeScreen` SHALL pass `navigateToProfile: widget.navigateToProfile` when constructing `HomeAppBarWidget`.

#### Scenario: HomeScreen wires navigateToProfile to the app bar

Given a `HomeScreen` constructed with a `navigateToProfile` callback
When the screen builds
Then `HomeAppBarWidget` SHALL receive that exact callback as its `navigateToProfile` parameter

---

### Requirement: HomeLocation injects navigation to ProfileLocation

`lib/src/presentation/ui/home/locations/home_location.dart` SHALL import `ProfileLocation` and inject `navigateToProfile: () => context.navigate(ProfileLocation())` when constructing `HomeScreen`.

`HomeLocation` is the only place authorised to import `ProfileLocation` from the Home feature side (Locations composing navigation is the documented exception to feature encapsulation in `CLAUDE.md`).

#### Scenario: Tapping the avatar on Home navigates to Profile

Given the user is on `HomeScreen`
When the user taps the avatar with the user's initial
Then `DuckRouter.navigate(ProfileLocation())` SHALL be invoked
And `ProfileScreen` SHALL be pushed on top of the navigation stack

---

### Requirement: SettingsLocation wires onEditProfile to ProfileLocation

`lib/src/presentation/ui/settings/locations/settings_location.dart` SHALL import `ProfileLocation` and replace `onEditProfile: () {}` with `onEditProfile: () => context.navigate(ProfileLocation())`.

`SettingsScreen` SHALL remain unchanged — it continues to receive `onEditProfile` as a `VoidCallback` and SHALL NOT import `ProfileLocation`.

#### Scenario: Tapping "Dados pessoais" in Settings navigates to Profile

Given the user is on `SettingsScreen`
When the user taps the `SettingsItemWidget` with `label == 'Dados pessoais'`
Then `DuckRouter.navigate(ProfileLocation())` SHALL be invoked
And `ProfileScreen` SHALL be pushed on top of the navigation stack

---

### Requirement: userProvider promoted to cross-feature scope

The system SHALL move `lib/src/presentation/ui/home/notifiers/user_notifier.dart` (and its generated `.g.dart`) to `lib/src/presentation/notifiers/user_notifier.dart`.

The provider SHALL retain its name (`userProvider`), signature (`Future<UserModel> build()`) and dependencies (`userRepositoryProvider`). Only the file path and corresponding imports change.

All existing call-sites SHALL be updated to import from the new path:

- `lib/src/presentation/ui/home/screens/home_screen.dart`
- `test/src/presentation/providers/user_notifier_test.dart`

The old files SHALL NOT remain at the previous location.

#### Scenario: New path resolves

Given the move is complete
When `flutter analyze` runs
Then it SHALL report zero errors related to missing imports

#### Scenario: Old path is gone

Given the move is complete
When `find lib/src/presentation/ui/home/notifiers -name "user_notifier*"` is executed
Then the result SHALL be empty

---

### Requirement: AvatarWidget promoted to shared widgets folder

The system SHALL move `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart` to `lib/src/presentation/widgets/avatar/avatar_widget.dart`, renaming the class from `HomeAvatarWidget` to `AvatarWidget`.

The widget API SHALL be preserved: `final String name;`, `final double size;` (default `48.0`), `final VoidCallback? onTap;`. The body SHALL keep wrapping the styled `Container` in `BounceWidget.withOnPress(onPress: onTap, child: <container>)`.

All existing call-sites SHALL be updated:

- `lib/src/presentation/ui/home/widgets/home_app_bar_widget.dart` SHALL import the new path and use `AvatarWidget(...)` instead of `HomeAvatarWidget(...)`.

The old file `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart` SHALL be deleted.

#### Scenario: Avatar still renders the user's initial on Home

Given a `HomeAppBarWidget` rendered with a user named `'Kevin'`
When the avatar builds
Then it SHALL render the letter `'K'` exactly as before the rename

---

### Requirement: ProfileScreen consumes userProvider via Consumer

The system SHALL keep the `ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.')` from Part 1 and replace only the `Placeholder` body with a `Consumer` that calls `ref.watch(userProvider)` and renders an `AsyncValue<UserModel>` switch.

The screen SHALL remain a `StatelessWidget` (not `ConsumerWidget`) with an inner `Consumer` (CLAUDE.md feature rule). Sub-views (`_buildBody`, `_buildError`) SHALL be private methods returning `Widget`, never private classes (CLAUDE.md rule against private widget classes inside widget files).

The `AsyncValue` switch SHALL handle three states:

- `AsyncLoading()` → `Skeletonizer(enabled: true, child: <success layout with placeholder UserModel>)`.
- `AsyncError(:final error)` → `Center` with the failure message and a `'Tentar novamente'` button that invalidates `userProvider`.
- `AsyncData(:final value)` → success layout: `ScreenHeaderWidget` + `ProfileHeaderWidget(user: value)` + `ProfileFieldsCardWidget(children: [...])` (3 items) + `Spacer` + `ProfileAccountActionsWidget(onDelete: ..., onDeactivate: ...)` at the bottom.

#### Scenario: Loading state shows skeletonized layout

Given `userProvider` has not yet resolved
When `ProfileScreen` builds
Then a `Skeletonizer` widget SHALL wrap the success layout with `enabled: true`

#### Scenario: Error state shows retry button

Given `userProvider` resolves with an error
When `ProfileScreen` builds
Then a `'Tentar novamente'` button SHALL be present
And tapping it SHALL invalidate `userProvider`

#### Scenario: Data state renders screen header, profile header, three items and delete button

Given `userProvider` resolves with `AsyncData(UserModel(name: 'Kevin', email: 'kevin@trocado.app'))`
When `ProfileScreen` builds
Then the top of the layout SHALL contain a `ScreenHeaderWidget` with `title == 'Dados pessoais'` and `description == 'Gerencie as informações da sua conta.'`
And a `ProfileHeaderWidget` SHALL render the avatar, name `'Kevin'` and email `'kevin@trocado.app'`
And a `ProfileFieldsCardWidget` SHALL contain three `ProfileFieldItemWidget` children with labels `'Nome'`, `'E-mail'`, `'Senha'` in that order
And the `'E-mail'` item SHALL be disabled
And a `ProfileAccountActionsWidget` SHALL be rendered at the bottom

---

### Requirement: ProfileFieldItemWidget supports enabled/disabled states

The system SHALL create `lib/src/presentation/ui/profile/widgets/profile_field_item_widget.dart` as a `StatelessWidget` with `final String label;`, `final VoidCallback onTap;`, `final bool enabled;` (default `true`).

When `enabled == true`:

- The body SHALL be wrapped in `BounceWidget.withOnPress(onPress: onTap)`.
- The label SHALL render in `bodyMedium` with default text color.
- A `Icons.chevron_right` SHALL be present on the trailing edge with `onSurfaceVariant` color.

When `enabled == false`:

- The body SHALL NOT be wrapped in `BounceWidget`.
- The label SHALL render in `bodyMedium` with `onSurfaceVariant` color.
- The chevron SHALL NOT be rendered.
- Tapping the item SHALL NOT invoke `onTap`.

#### Scenario: Enabled item triggers onTap with bounce

Given a `ProfileFieldItemWidget(label: 'Nome', onTap: callback, enabled: true)`
When the user taps the item
Then `BounceWidget.withOnPress` SHALL animate the press
And `callback` SHALL be invoked exactly once

#### Scenario: Disabled item ignores taps

Given a `ProfileFieldItemWidget(label: 'E-mail', onTap: callback, enabled: false)`
When the user taps the item
Then no animation SHALL occur and `callback` SHALL NOT be invoked

---

### Requirement: ProfileDeleteAccountWidget exposes a single delete action

The system SHALL create `lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart` as a `StatelessWidget` with `final VoidCallback onTap;` (named-required).

The widget SHALL render a `Container(width: double.infinity, padding: EdgeInsets.only(top: 16.0))` whose child is `ButtonWidget.elevated(label: 'Excluir conta', onTap: onTap)`.

The button SHALL NOT render an icon — only the label is shown. The widget SHALL NOT apply any `Theme` override or custom destructive coloring — the destructive intent is communicated exclusively through the confirmation flow on the dedicated `ProfilePurgeScreen`.

There is no in-screen confirmation dialog on `ProfileDetailsScreen` — tapping the button navigates to `ProfilePurgeScreen` (Part 5) where the user re-enters their password and confirms.

#### Scenario: Single Excluir conta button is rendered

Given the user is on `ProfileDetailsScreen` with data loaded
When `ProfileDeleteAccountWidget` builds
Then a single `ButtonWidget.elevated` SHALL be rendered with label `'Excluir conta'` taking the full available width
And no other action button SHALL be present alongside it

#### Scenario: Tap navigates to ProfilePurgeScreen

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Excluir conta'` button
Then the `onTap` callback SHALL be invoked
And the callback SHALL navigate to `ProfilePurgeLocation` (wired by `ProfileDetailsLocation`)

---

### Requirement: profile feature is organised in subdirectories

The system SHALL reorganise `lib/src/presentation/ui/profile/` to mirror the `lib/src/presentation/ui/authentication/` pattern — every screen of the feature lives in its own subdirectory.

The following subdirectories SHALL exist after this part:

- `profile/details/` — listing screen (renamed from the root-level files of Parts 1 and 2). Contains `screens/profile_details_screen.dart`, `locations/profile_details_location.dart` and `widgets/profile_*.dart` (the four widgets created in Part 2).
- `profile/name/` — name editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.
- `profile/password/` — password editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.
- `profile/purge/` — account deletion screen (added in Part 5), with `screens/`, `locations/`, `notifiers/`, `validators/`.

The class `ProfileScreen` SHALL be renamed to `ProfileDetailsScreen` and `ProfileLocation` to `ProfileDetailsLocation`. Imports in `HomeLocation` and `SettingsLocation` SHALL be updated accordingly. The route path `/profile` SHALL continue to map to `ProfileDetailsLocation` — no change to `AppRoutes.profile`.

#### Scenario: Subdirectories exist

Given the reorganisation is complete
When `find lib/src/presentation/ui/profile -maxdepth 1 -mindepth 1 -type d` is executed
Then the result SHALL list exactly four directories: `details`, `name`, `password`, `purge`

#### Scenario: Old paths are gone

Given the reorganisation is complete
When `find lib/src/presentation/ui/profile/screens lib/src/presentation/ui/profile/locations lib/src/presentation/ui/profile/widgets -type f 2>/dev/null` is executed
Then the result SHALL be empty

---

### Requirement: AppRoutes.profileName and AppRoutes.profilePassword entries

The system SHALL add `profileName` and `profilePassword` entries to `AppRoutes` in `lib/app_route.dart`:

- `profileName` — `path: '/profile/name'`, `name: 'profile-name-route'`, regex `^/profile/name$`.
- `profilePassword` — `path: '/profile/password'`, `name: 'profile-password-route'`, regex `^/profile/password$`.

Both SHALL be included in `AppRoutes._all`.

#### Scenario: Routes are registered

Given the app starts
Then `AppRoutes.profileName.path` SHALL equal `'/profile/name'`
And `AppRoutes.profilePassword.path` SHALL equal `'/profile/password'`
And both entries SHALL be present in `AppRoutes._all`

---

### Requirement: NameValidation enforces min 1 and max 128

The system SHALL create `lib/src/presentation/ui/profile/name/validators/name_validation.dart` defining `final class NameValidation implements Validation<String>`.

`NameValidation` SHALL trim the input before validating and apply the following rules in order:

- empty after trim → `Invalid('Nome obrigatório')`.
- length > 128 after trim → `Invalid('Nome deve ter no máximo 128 caracteres')`.
- otherwise → `Valid(normalized)`.

#### Scenario: Empty name is invalid

Given `NameValidation()` is invoked with `'   '`
Then it SHALL return `Invalid('Nome obrigatório')`

#### Scenario: 129-character name is invalid

Given `NameValidation()` is invoked with a 129-character string
Then it SHALL return `Invalid('Nome deve ter no máximo 128 caracteres')`

#### Scenario: Valid name returns trimmed value

Given `NameValidation()` is invoked with `'  Kevin  '`
Then it SHALL return `Valid('Kevin')`

---

### Requirement: ProfileNameNotifier is an AsyncNotifier reading userProvider

The system SHALL create `ProfileNameNotifier` as `@riverpod final class ProfileNameNotifier extends _$ProfileNameNotifier` with:

- `Future<ProfileNameState> build()` async, that watches `profileNameFormValidatorProvider` and `userProvider.future`, returning `ProfileNameState(name: user.name)`.
- `dispatch(ProfileNameIntent intent)` exhaustive over `NameChanged(value)` and `SubmitPressed()`.
- `_submit()` that validates via the form validator, propagates failures into `state`, and returns early when invalid. When valid the body SHALL contain a `// TODO Parte 6` comment and SHALL NOT call any repository in this part.

`ProfileNameState` SHALL pre-fill the field on first render with the current user's name.

#### Scenario: Build pre-fills with the user's current name

Given `userProvider` resolves with `AsyncData(UserModel(name: 'Kevin', ...))`
When `ProfileNameNotifier.build` resolves
Then `state.value` SHALL equal `ProfileNameState(name: 'Kevin')`

#### Scenario: Empty submit produces nameFailure

Given the user clears the name field and dispatches `SubmitPressed`
Then `state.value.nameFailure` SHALL equal `'Nome obrigatório'`
And no repository call SHALL be made

#### Scenario: Valid submit is a no-op in Part 3

Given the user types a valid name and dispatches `SubmitPressed`
Then `state.value.nameFailure` SHALL be `null`
And no repository call SHALL be made (deferred to Part 6)

---

### Requirement: ProfilePasswordFormValidator validates new password and confirmation match

The system SHALL create `ProfilePasswordFormValidator` mirroring `PasswordResetConfirmFormValidator`:

- Validates `newPassword` via the shared `PasswordValidation` (min 8).
- When `newPassword` is `Valid` and `confirmPassword != newPassword`, SHALL set `confirmPasswordFailure` to `'As senhas não coincidem'`.
- `isValid` SHALL be `true` only when both checks pass.

#### Scenario: Mismatched confirmation produces failure

Given `state.newPassword == 'abcdefgh'` and `state.confirmPassword == 'abcdefgi'`
When the validator is invoked
Then `state.confirmPasswordFailure` SHALL equal `'As senhas não coincidem'`
And `isValid` SHALL be `false`

#### Scenario: Matching valid passwords pass

Given `state.newPassword == 'abcdefgh'` and `state.confirmPassword == 'abcdefgh'`
When the validator is invoked
Then `state.newPasswordFailure` and `state.confirmPasswordFailure` SHALL be `null`
And `isValid` SHALL be `true`

---

### Requirement: ProfilePasswordNotifier is a sync Notifier with five intents

The system SHALL create `ProfilePasswordNotifier` as `@riverpod final class ProfilePasswordNotifier extends _$ProfilePasswordNotifier` with synchronous `build()` returning `const ProfilePasswordState()`.

`dispatch` SHALL be exhaustive over: `NewPasswordChanged`, `ConfirmPasswordChanged`, `NewPasswordVisibilityToggled`, `ConfirmPasswordVisibilityToggled`, `SubmitPressed`.

`_submit()` SHALL validate via `profilePasswordFormValidatorProvider`, propagate failures and return early when invalid. When valid the body SHALL contain a `// TODO Parte 6` comment and SHALL NOT call any repository in this part.

#### Scenario: Toggling visibility does not affect other field

Given `state.obscureNewPassword == true` and `state.obscureConfirmPassword == true`
When `dispatch(NewPasswordVisibilityToggled())` is called
Then `state.obscureNewPassword` SHALL become `false`
And `state.obscureConfirmPassword` SHALL remain `true`

#### Scenario: Form validator providers exist

Given the validators provider file is parsed
Then `profileNameFormValidatorProvider` and `profilePasswordFormValidatorProvider` SHALL be defined
And both SHALL inject the appropriate `Validation` instances by default

---

### Requirement: ProfileDetailsScreen wires onEditName and onEditPassword

The system SHALL extend `ProfileDetailsScreen` with `final VoidCallback onEditName;` and `final VoidCallback onEditPassword;` (named-required), declared before the constructor.

The "Nome" `ProfileFieldItemWidget` SHALL receive `onTap: onEditName`. The "Senha" item SHALL receive `onTap: onEditPassword`. The "E-mail" item SHALL remain disabled.

`ProfileDetailsLocation` SHALL inject `() => context.navigate(ProfileNameLocation())` for `onEditName` and `() => context.navigate(ProfilePasswordLocation())` for `onEditPassword`. `ProfileDetailsLocation` is the only place authorised to import `ProfileNameLocation` / `ProfilePasswordLocation` from outside their own subfeature.

#### Scenario: Tapping "Nome" navigates to the name editor

Given the user is on `ProfileDetailsScreen`
When the user taps the `ProfileFieldItemWidget` with `label == 'Nome'`
Then `DuckRouter.navigate(ProfileNameLocation())` SHALL be invoked

#### Scenario: Tapping "Senha" navigates to the password editor

Given the user is on `ProfileDetailsScreen`
When the user taps the `ProfileFieldItemWidget` with `label == 'Senha'`
Then `DuckRouter.navigate(ProfilePasswordLocation())` SHALL be invoked

---

### Requirement: PasswordFieldWidget centralises the obscure-toggle pattern

The system SHALL create `lib/src/presentation/widgets/fields/password_field_widget.dart` defining `class PasswordFieldWidget extends StatelessWidget` that delegates to `TextFieldWidget`.

The widget API SHALL declare these fields before the constructor (CLAUDE.md member ordering):

- `final String hint;`
- `final String label;`
- `final bool obscure;`
- `final String? failure;`
- `final String? initialValue;`
- `final TextInputAction? inputAction;`
- `final ValueChanged<String>? onChanged;`
- `final VoidCallback onToggle;`

The constructor SHALL be `const PasswordFieldWidget({ super.key, required this.hint, required this.label, required this.obscure, required this.onToggle, this.failure, this.onChanged, this.initialValue, this.inputAction });`.

`build` SHALL return a `TextFieldWidget` configured with `obscureText: obscure`, `hideTrailingIconWhenEmpty: true`, `onTrailingIconTap: onToggle`, and `trailingIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined`. All other parameters SHALL be forwarded unchanged.

The widget SHALL NOT own any state — `obscure` is controlled by the caller (typically a notifier with a `*VisibilityToggled` intent).

The following call-sites SHALL be migrated from the inline `TextFieldWidget` pattern to `PasswordFieldWidget`:

- `lib/src/presentation/ui/authentication/sign_in/screens/sign_in_screen.dart` — `'Senha'` field.
- `lib/src/presentation/ui/authentication/sign_up/screens/sign_up_screen.dart` — `'Senha'` field.
- `lib/src/presentation/ui/authentication/password_reset_confirm/screens/password_reset_confirm_screen.dart` — `'Nova senha'` and `'Confirmar senha'` fields.
- `lib/src/presentation/ui/profile/password/screens/profile_password_screen.dart` — `'Nova senha'` and `'Confirmar senha'` fields.

The migrated screens SHALL NOT change their notifier, state, intent, or visibility-toggle dispatch behaviour — only the widget shape is replaced.

#### Scenario: Toggle icon reflects obscure state

Given a `PasswordFieldWidget(obscure: true, ...)`
When the widget builds
Then the rendered `TextFieldWidget` SHALL receive `trailingIcon == Icons.visibility_outlined`

Given a `PasswordFieldWidget(obscure: false, ...)`
When the widget builds
Then the rendered `TextFieldWidget` SHALL receive `trailingIcon == Icons.visibility_off_outlined`

#### Scenario: Tapping the toggle icon invokes onToggle exactly once

Given a `PasswordFieldWidget` rendered with `onToggle: callback`
When the user taps the trailing visibility icon
Then `callback` SHALL be invoked exactly once

#### Scenario: All five call-sites use PasswordFieldWidget

Given the migration is complete
When `grep -n "obscureText:" lib/src/presentation/ui/authentication/sign_in/screens lib/src/presentation/ui/authentication/sign_up/screens lib/src/presentation/ui/authentication/password_reset_confirm/screens lib/src/presentation/ui/profile/password/screens` is executed
Then there SHALL be no remaining occurrences of `obscureText:` outside `PasswordFieldWidget` in those screens

---

### Requirement: AppRoutes.profilePurge entry

The system SHALL add a `profilePurge` entry to `AppRoutes` in `lib/app_route.dart` with `path: '/profile/purge'`, `name: 'profile-purge-route'`, and a regex matching exactly `^/profile/purge$`. The entry SHALL be included in `AppRoutes._all`.

#### Scenario: Route is registered

Given the app starts
Then `AppRoutes.profilePurge.path` SHALL equal `'/profile/purge'`
And `AppRoutes._all` SHALL contain the `profilePurge` entry

---

### Requirement: IUserRepository extended with purge

The system SHALL extend `lib/src/domain/repositories/interface_user_repository.dart` with:

```dart
Future<Either<Failure, void>> purge({
  required String email,
  required String password,
});
```

The signature SHALL accept domain primitives (`String email`, `String password`) — never an infrastructure DTO (`PurgeRequest`).

`IRemoteUserDataSource` SHALL gain `Future<Either<FailureResponse, void>> purge({required String email, required String password});`. The implementation SHALL call `_client.post(parameter: Requests(EndpointKey.purge.path, body: PurgeRequest(email: email, password: password).toJson()))` and map via `response.either(FailureResponse.fromJson, (_) {})` (the 204 body is discarded).

`UserRepository.purge` SHALL pass the primitives directly to the datasource and map `FailureResponse → Failure` via `failure.toFailure()`. It SHALL NOT read tokens — `Authorization` is injected by the existing `AuthenticationInterceptor` for authenticated endpoints.

#### Scenario: purge calls POST /api/v1/me/purge with email and password body

Given `UserRepository.purge(email: 'jane@trocado.app', password: 'MyPassword!456')` is invoked
Then `IHttpClient.post` SHALL be called with `Requests(path: '/api/v1/me/purge', body: {'email': 'jane@trocado.app', 'password': 'MyPassword!456'})`

#### Scenario: purge maps NetworkFailure

Given the datasource returns `Left(FailureResponse with code 'connection_error')`
When `UserRepository.purge(...)` resolves
Then it SHALL return `Left(NetworkFailure())`

#### Scenario: purge maps backend validation error to ValidationFailure

Given the datasource returns `Left(FailureResponse with code 'invalid' and message 'Senha incorreta.')`
When `UserRepository.purge(...)` resolves
Then it SHALL return `Left(ValidationFailure('Senha incorreta.'))`

#### Scenario: purge returns Right on 204

Given the datasource returns `Right(null)`
When `UserRepository.purge(...)` resolves
Then it SHALL return `Right(null)`

---

### Requirement: PurgeRequest DTO carries email and password

The system SHALL create `lib/src/infrastructure/clients/http/requests/purge_request.dart` defining:

```dart
final class PurgeRequest {
  final String email;
  final String password;

  const PurgeRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
```

The DTO SHALL live in `infrastructure/`, never crossing into `domain/` or `data/`. Only the concrete `RemoteUserDataSource.purge` implementation SHALL instantiate it.

#### Scenario: toJson serialises email and password verbatim

Given `PurgeRequest(email: 'jane@trocado.app', password: 'p@ss')`
When `toJson()` is invoked
Then the result SHALL equal `{'email': 'jane@trocado.app', 'password': 'p@ss'}`

---

### Requirement: ProfilePurgeFormValidator validates password length

The system SHALL create `lib/src/presentation/ui/profile/purge/validators/profile_purge_form_validator.dart` defining `final class ProfilePurgeFormValidator`.

The validator SHALL receive `PasswordValidation` via constructor (named-required) and expose `({ProfilePurgeState state, bool isValid}) call(ProfilePurgeState state)`.

It SHALL apply `PasswordValidation` (min 8) to `state.password` and:

- On `Invalid(:final message)` → set `passwordFailure: message` and `isValid: false`.
- On `Valid()` → clear `passwordFailure` (via `clearPasswordFailure: true`) and `isValid: true`.

#### Scenario: Empty password is invalid

Given `state.password == ''`
When the validator is invoked
Then the returned `state.passwordFailure` SHALL equal `'Senha obrigatória'`
And `isValid` SHALL be `false`

#### Scenario: Short password is invalid

Given `state.password == 'abc'`
When the validator is invoked
Then the returned `state.passwordFailure` SHALL equal `'Senha deve ter ao menos 8 caracteres'`
And `isValid` SHALL be `false`

#### Scenario: Valid password clears failure

Given `state.password == 'abcdefgh'`
When the validator is invoked
Then the returned `state.passwordFailure` SHALL be `null`
And `isValid` SHALL be `true`

---

### Requirement: ProfilePurgeNotifier orchestrates purge flow

The system SHALL create `lib/src/presentation/ui/profile/purge/notifiers/profile_purge_notifier.dart` as `@riverpod final class ProfilePurgeNotifier extends _$ProfilePurgeNotifier`.

`build()` SHALL be synchronous and return `const ProfilePurgeState()` after `ref.watch(userRepositoryProvider)` and `ref.watch(profilePurgeFormValidatorProvider)`.

`dispatch(ProfilePurgeIntent intent)` SHALL be exhaustive over:

- `PasswordChanged(:final value)` → `state = state.copyWith(password: value, clearPasswordFailure: true)`.
- `PasswordVisibilityToggled()` → `state = state.copyWith(obscurePassword: !state.obscurePassword)`.
- `ValidatePressed()` → `_validate()` — runs the form validator and propagates the validated `state`. Does not call the repository. Used by the screen to gate the confirm dialog (the dialog only opens when validation passes).
- `SubmitPressed()` → `_submit()` — re-validates defensively, then performs the API call.

`_submit()` SHALL:

1. Validate via the form validator and propagate the validated `state` (`this.state = state`).
2. Return early if `!isValid`.
3. Return early if `this.state.status == ProfilePurgeStatus.loading` (re-entrancy guard).
4. Set `this.state = this.state.copyWith(status: ProfilePurgeStatus.loading)`.
5. Read `final user = ref.read(userProvider).valueOrNull`.
6. If `user == null`, set `this.state = this.state.copyWith(status: ProfilePurgeStatus.failure, message: 'Não foi possível identificar o usuário.')` and return without calling the repository.
7. Call `_repository.purge(email: user.email, password: this.state.password)`.
8. On `Left(failure)` → `this.state = this.state.copyWith(status: failure, message: failure.message)`.
9. On `Right(_)` → `ref.invalidate(userProvider)` and `this.state = this.state.copyWith(status: success)`.

The notifier SHALL NOT navigate directly — redirect after success is delegated to the existing `AuthenticationInterceptor` (the next authenticated request after `userProvider` is invalidated will take 401, refresh will fail, and `_onUnauthenticated` will replace the stack with `SignInLocation`).

#### Scenario: Successful purge invalidates userProvider

Given `IUserRepository.purge(...)` returns `Right(null)`
And `userProvider` resolves with `UserModel(email: 'jane@trocado.app')`
When `dispatch(SubmitPressed())` resolves with `state.password == 'MyPassword!456'`
Then `_repository.purge(email: 'jane@trocado.app', password: 'MyPassword!456')` SHALL be called
And `ref.invalidate(userProvider)` SHALL be called
And `state.status` SHALL equal `ProfilePurgeStatus.success`

#### Scenario: Failed purge populates message

Given `IUserRepository.purge(...)` returns `Left(ValidationFailure('Senha incorreta.'))`
When `dispatch(SubmitPressed())` resolves with valid password
Then `state.status` SHALL equal `ProfilePurgeStatus.failure`
And `state.message` SHALL equal `'Senha incorreta.'`

#### Scenario: Empty password short-circuits before repository

Given `state.password == ''`
When `dispatch(SubmitPressed())` is invoked
Then `state.passwordFailure` SHALL equal `'Senha obrigatória'`
And `IUserRepository.purge` SHALL NOT be called

#### Scenario: Re-entrant dispatch is a no-op

Given `state.status == ProfilePurgeStatus.loading`
When `dispatch(SubmitPressed())` is called again with valid password
Then `IUserRepository.purge` SHALL be called exactly once total

#### Scenario: Null user fallback is defensive

Given `userProvider` resolves with no value (`AsyncLoading` or `AsyncError` such that `valueOrNull == null`)
When `dispatch(SubmitPressed())` resolves with valid password
Then `IUserRepository.purge` SHALL NOT be called
And `state.status` SHALL equal `ProfilePurgeStatus.failure`
And `state.message` SHALL equal `'Não foi possível identificar o usuário.'`

---

### Requirement: ProfilePurgeScreen presents email readonly, password field and submit

The system SHALL create `lib/src/presentation/ui/profile/purge/screens/profile_purge_screen.dart` as a `StatelessWidget` with `Consumer` inside (jamais `ConsumerWidget`).

The screen SHALL `ref.listen(profilePurgeProvider, ...)` and call `showToastWidget(context: context, title: 'Opps', type: ToastType.failure, description: state.message)` only on transitions to `ProfilePurgeStatus.failure`. Successful transitions SHALL be silent — redirect is handled by the `AuthenticationInterceptor`.

The screen SHALL render:

- `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))`.
- Body: `Padding(padding: const EdgeInsets.all(16.0), child: Column(spacing: 24.0, crossAxisAlignment: CrossAxisAlignment.start, children: [...]))`.
- Children, in order:
  - `ScreenHeaderWidget(title: 'Excluir conta', description: 'Esta ação é irreversível. Confirme com sua senha para excluir definitivamente sua conta e todos os dados associados.')`.
  - `TextFieldWidget(label: 'E-mail', hint: '', initialValue: user.email, readOnly: true)` — read-only view of the logged-in user's email.
  - `PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', inputAction: TextInputAction.done, obscure: state.obscurePassword, onToggle: ..., failure: state.passwordFailure, onChanged: ...)`.
  - `Spacer()`.
  - `SizedBox(width: double.infinity, child: ButtonWidget.elevated(label: 'Excluir', isLoading: state.status == ProfilePurgeStatus.loading, onTap: ...))`.

The submit handler SHALL be a private method (never a private widget class — CLAUDE.md). It SHALL validate **before** opening the confirm dialog — when validation fails, the dialog SHALL NOT open and the screen SHALL surface `passwordFailure` inline:

```dart
Future<void> _submit(
  BuildContext context,
  WidgetRef ref,
  ProfilePurgeNotifier notifier,
) async {
  hideKeyboard();

  notifier.dispatch(const ValidatePressed());

  if (ref.read(profilePurgeProvider).passwordFailure != null) return;

  final confirmed = await showConfirmDialog(
    context: context,
    title: 'Excluir conta',
    confirmLabel: 'Excluir',
    description:
        'Esta ação é irreversível.\n\n - Todos os seus dados serão apagados;\n - Você não poderá recuperar sua conta.',
  );
  if (!confirmed) return;

  notifier.dispatch(const SubmitPressed());
}
```

#### Scenario: Email is rendered readonly from userProvider

Given `userProvider` resolves with `UserModel(email: 'jane@trocado.app')`
When `ProfilePurgeScreen` builds
Then a `TextFieldWidget` SHALL be present with `label == 'E-mail'`, `initialValue == 'jane@trocado.app'`, and `readOnly == true`

#### Scenario: Submit opens confirm dialog before dispatching

Given the user typed a valid password
When the user taps `'Excluir'`
Then `notifier.dispatch(ValidatePressed())` SHALL be invoked first
And `showConfirmDialog` SHALL be invoked with `title: 'Excluir conta'` and `confirmLabel: 'Excluir'`
And `notifier.dispatch(SubmitPressed())` SHALL be invoked only after the dialog resolves to `true`

#### Scenario: Invalid password blocks the confirm dialog

Given the user left the password field empty (or below the minimum length)
When the user taps `'Excluir'`
Then `notifier.dispatch(ValidatePressed())` SHALL be invoked
And `state.passwordFailure` SHALL surface inline in the `PasswordFieldWidget`
And `showConfirmDialog` SHALL NOT be invoked
And `notifier.dispatch(SubmitPressed())` SHALL NOT be invoked

#### Scenario: Cancel keeps the user on the screen

Given the confirm dialog is open
When the user taps `'Cancelar'`
Then the dialog SHALL close
And `notifier.dispatch(SubmitPressed())` SHALL NOT be invoked

#### Scenario: Failure shows toast

Given the user confirmed and the API returned a failure
When the listener observes `state.status == failure`
Then `showToastWidget` SHALL be invoked with `type: failure` and `description: state.message`

#### Scenario: Success is silent

Given the user confirmed and the API returned 204
When the listener observes `state.status == success`
Then no toast SHALL be shown
And `userProvider` SHALL be invalidated, triggering the interceptor-driven redirect to SignIn

---

### Requirement: ProfilePurgeLocation registers the purge route

The system SHALL create `lib/src/presentation/ui/profile/purge/locations/profile_purge_location.dart` defining `final class ProfilePurgeLocation extends Location`.

`ProfilePurgeLocation` SHALL declare:

- `String get path` returning `AppRoutes.profilePurge.path`.
- `LocationPageBuilder get pageBuilder` returning `(_) => screenPage(const ProfilePurgeScreen())`.

`ProfilePurgeLocation` SHALL NOT receive any constructor parameters.

#### Scenario: Location resolves the path

Given `ProfilePurgeLocation()` is constructed
Then `path` SHALL equal `'/profile/purge'`

---

### Requirement: ProfileDetailsScreen wires onPurge instead of inline confirm

The system SHALL extend `ProfileDetailsScreen` with `final VoidCallback onPurge;` named-required, declared before the constructor next to the existing `onEditName` and `onEditPassword`.

The previous `_confirmDelete` private method SHALL be removed — the destructive confirmation moves into `ProfilePurgeScreen`. The `ProfileAccountActionsWidget` SHALL receive `onDelete: onPurge` directly in the `AsyncData` branch (no intermediate dialog on the detail screen).

The Skeletonizer (loading) branch SHALL keep `onDelete: () {}` to remain non-interactive while loading.

`ProfileDetailsLocation` SHALL inject `onPurge: () => context.navigate(ProfilePurgeLocation())`. `ProfileDetailsLocation` is the only place authorised to import `ProfilePurgeLocation` (Locations composing navigation — documented exception in CLAUDE.md).

`ProfileDetailsNotifier` SHALL NOT change — purge is fully encapsulated in the new `profile/purge/` subfeature.

#### Scenario: Tapping "Excluir" navigates to the purge screen

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Excluir'` button in `ProfileAccountActionsWidget`
Then `DuckRouter.navigate(ProfilePurgeLocation())` SHALL be invoked
And no `showConfirmDialog` SHALL be opened on the detail screen

#### Scenario: ProfileDetailsLocation imports only profile-internal locations

Given the spec implementation is complete
When `grep -n "import 'package:trocado" lib/src/presentation/ui/profile/details/locations/profile_details_location.dart` is executed
Then the only feature locations imported SHALL be `ProfileNameLocation`, `ProfilePasswordLocation` and `ProfilePurgeLocation` (all under `profile/`)
