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

The button SHALL NOT render an icon — only the label is shown. The widget SHALL NOT apply any `Theme` override or custom destructive coloring — the destructive intent is communicated exclusively through the confirmation flow on the dedicated `ProfileDeleteScreen`.

There is no in-screen confirmation dialog on `ProfileDetailsScreen` — tapping the button navigates to `ProfileDeleteScreen` (Part 5) where the user re-enters their password and confirms.

#### Scenario: Single Excluir conta button is rendered

Given the user is on `ProfileDetailsScreen` with data loaded
When `ProfileDeleteAccountWidget` builds
Then a single `ButtonWidget.elevated` SHALL be rendered with label `'Excluir conta'` taking the full available width
And no other action button SHALL be present alongside it

#### Scenario: Tap navigates to ProfileDeleteScreen

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Excluir conta'` button
Then the `onTap` callback SHALL be invoked
And the callback SHALL navigate to `ProfileDeleteLocation` (wired by `ProfileDetailsLocation`)

---

### Requirement: profile feature is organised in subdirectories

The system SHALL reorganise `lib/src/presentation/ui/profile/` to mirror the `lib/src/presentation/ui/authentication/` pattern — every screen of the feature lives in its own subdirectory.

The following subdirectories SHALL exist after this part:

- `profile/details/` — listing screen (renamed from the root-level files of Parts 1 and 2). Contains `screens/profile_details_screen.dart`, `locations/profile_details_location.dart` and `widgets/profile_*.dart` (the four widgets created in Part 2).
- `profile/name/` — name editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.
- `profile/password/` — password editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.
- `profile/delete/` — account deletion screen (added in Part 5), with `screens/`, `locations/`, `notifiers/`, `validators/`.

The class `ProfileScreen` SHALL be renamed to `ProfileDetailsScreen` and `ProfileLocation` to `ProfileDetailsLocation`. Imports in `HomeLocation` and `SettingsLocation` SHALL be updated accordingly. The route path `/profile` SHALL continue to map to `ProfileDetailsLocation` — no change to `AppRoutes.profile`.

#### Scenario: Subdirectories exist

Given the reorganisation is complete
When `find lib/src/presentation/ui/profile -maxdepth 1 -mindepth 1 -type d` is executed
Then the result SHALL list exactly four directories: `details`, `name`, `password`, `delete`

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

### Requirement: AppRoutes.profileDelete entry

The system SHALL add a `profileDelete` entry to `AppRoutes` in `lib/app_route.dart` with `path: '/profile/delete'`, `name: 'profile-delete-route'`, and a regex matching exactly `^/profile/delete$`. The entry SHALL be included in `AppRoutes._all`.

#### Scenario: Route is registered

Given the app starts
Then `AppRoutes.profileDelete.path` SHALL equal `'/profile/delete'`
And `AppRoutes._all` SHALL contain the `profileDelete` entry

---

### Requirement: IUserRepository extended with delete

The system SHALL extend `lib/src/domain/repositories/interface_user_repository.dart` with:

```dart
Future<Either<Failure, void>> delete({required String password});
```

The signature SHALL accept the password as a domain primitive (`String`). The repository — not the caller — orchestrates the refresh token via `ILocalTokenDataSource`.

`IRemoteUserDataSource` SHALL gain `Future<Either<FailureResponse, void>> delete({required String refresh, required String password});`. The implementation SHALL call `_client.delete(parameter: Requests(EndpointKey.me.path, body: {'refresh': refresh, 'password': password}))` and map via `response.either(FailureResponse.fromJson, (_) {})` (the 204 body is discarded). The body is constructed inline — no DTO.

`UserRepository.delete` SHALL accept `ILocalTokenDataSource tokenDataSource` and `IRemoteUserDataSource userDataSource` via constructor (mirroring `AuthenticationRepository`). `delete({required String password})` SHALL:

- Read `tokens.refresh` via `_tokenDataSource.get()`.
- Return `Left(UnknownFailure())` immediately when `tokens.refresh == null` (defensive — no API call).
- Otherwise call `_userDataSource.delete(refresh: tokens.refresh!, password: password)` and map via `data.either((failure) => failure.toFailure(), (_) {})`.

`userRepositoryProvider` in `repositories_provider.dart` SHALL inject `localTokenDataSourceProvider` alongside `remoteUserDataSourceProvider`.

#### Scenario: delete calls DELETE /api/v1/me with refresh and password body

Given `UserRepository.delete(password: 'MyPassword!456')` is invoked
And `tokenDataSource.get()` returns `(access: 'A', refresh: 'R')`
Then `IHttpClient.delete` SHALL be called with `Requests(path: '/api/v1/me', body: {'refresh': 'R', 'password': 'MyPassword!456'})`

#### Scenario: delete short-circuits when refresh is null

Given `tokenDataSource.get()` returns `(access: 'A', refresh: null)`
When `UserRepository.delete(password: 'MyPassword!456')` resolves
Then it SHALL return `Left(UnknownFailure())`
And `IHttpClient.delete` SHALL NOT be called

#### Scenario: delete maps NetworkFailure

Given the datasource returns `Left(FailureResponse with code 'network_error')`
When `UserRepository.delete(...)` resolves
Then it SHALL return `Left(NetworkFailure())`

#### Scenario: delete maps invalid_credentials to ValidationFailure

Given the datasource returns `Left(FailureResponse with code 'invalid_credentials' and message 'Invalid credentials.')`
When `UserRepository.delete(...)` resolves
Then it SHALL return `Left(ValidationFailure('Invalid credentials.'))`

#### Scenario: delete returns Right on 204

Given the datasource returns `Right(null)`
When `UserRepository.delete(...)` resolves
Then it SHALL return `Right(null)`

---

### Requirement: ProfileDeleteFormValidator validates password length

The system SHALL create `lib/src/presentation/ui/profile/delete/validators/profile_delete_form_validator.dart` defining `final class ProfileDeleteFormValidator`.

The validator SHALL receive `PasswordValidation` via constructor (named-required) and expose `({ProfileDeleteState state, bool isValid}) call(ProfileDeleteState state)`.

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

### Requirement: ProfileDeleteNotifier orchestrates account deletion flow

The system SHALL create `lib/src/presentation/ui/profile/delete/notifiers/profile_delete_notifier.dart` as `@riverpod final class ProfileDeleteNotifier extends _$ProfileDeleteNotifier`.

`build()` SHALL be synchronous and return `const ProfileDeleteState()` after `ref.watch(userRepositoryProvider)` and `ref.watch(profileDeleteFormValidatorProvider)`.

`dispatch(ProfileDeleteIntent intent)` SHALL be exhaustive over:

- `PasswordChanged(:final value)` → `state = state.copyWith(password: value, clearPasswordFailure: true)`.
- `PasswordVisibilityToggled()` → `state = state.copyWith(obscurePassword: !state.obscurePassword)`.
- `ValidatePressed()` → `_validate()` — runs the form validator and propagates the validated `state`. Does not call the repository. Used by the screen to gate the confirm dialog (the dialog only opens when validation passes).
- `SubmitPressed()` → `_submit()` — re-validates defensively, then performs the API call.

`_submit()` SHALL:

1. Validate via the form validator and propagate the validated `state` (`this.state = state`).
2. Return early if `!isValid`.
3. Return early if `this.state.status == ProfileDeleteStatus.loading` (re-entrancy guard).
4. Set `this.state = this.state.copyWith(status: ProfileDeleteStatus.loading)`.
5. Call `_repository.delete(password: this.state.password)`. The repository orchestrates the refresh token internally — the notifier does NOT read tokens or `userProvider`.
6. On `Left(failure)` → `this.state = this.state.copyWith(status: failure, message: failure.message)`.
7. On `Right(_)` → `ref.invalidate(userProvider)` and `this.state = this.state.copyWith(status: success)`.

The notifier SHALL NOT navigate directly — redirect after success is delegated to the existing `AuthenticationInterceptor` (the next authenticated request after `userProvider` is invalidated will take 401, refresh will fail because the backend blacklisted the refresh token, and `_onUnauthenticated` will replace the stack with `SignInLocation`).

#### Scenario: Successful delete invalidates userProvider

Given `IUserRepository.delete(...)` returns `Right(null)`
When `dispatch(SubmitPressed())` resolves with `state.password == 'MyPassword!456'`
Then `_repository.delete(password: 'MyPassword!456')` SHALL be called
And `ref.invalidate(userProvider)` SHALL be called
And `state.status` SHALL equal `ProfileDeleteStatus.success`

#### Scenario: Failed delete populates message

Given `IUserRepository.delete(...)` returns `Left(ValidationFailure('Invalid credentials.'))`
When `dispatch(SubmitPressed())` resolves with valid password
Then `state.status` SHALL equal `ProfileDeleteStatus.failure`
And `state.message` SHALL equal `'Invalid credentials.'`

#### Scenario: Empty password short-circuits before repository

Given `state.password == ''`
When `dispatch(SubmitPressed())` is invoked
Then `state.passwordFailure` SHALL equal `'Senha obrigatória'`
And `IUserRepository.delete` SHALL NOT be called

#### Scenario: Re-entrant dispatch is a no-op

Given `state.status == ProfileDeleteStatus.loading`
When `dispatch(SubmitPressed())` is called again with valid password
Then `IUserRepository.delete` SHALL be called exactly once total

---

### Requirement: ProfileDeleteScreen presents email readonly, password field and submit

The system SHALL create `lib/src/presentation/ui/profile/delete/screens/profile_delete_screen.dart` as a `StatelessWidget` with `Consumer` inside (jamais `ConsumerWidget`).

The screen SHALL `ref.listen(profileDeleteProvider, ...)` and call `showToastWidget(context: context, title: 'Opps', type: ToastType.failure, description: state.message)` only on transitions to `ProfileDeleteStatus.failure`. Successful transitions SHALL be silent — redirect is handled by the `AuthenticationInterceptor`.

The screen SHALL read `email` from `userProvider` via a switch over `AsyncValue<UserModel>` (`AsyncData(:final value) => value.email; _ => ''`) — the email is only a visual confirmation of which account is about to be deleted; the API request itself does not include it.

The screen SHALL render:

- `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))`.
- Body: `CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: false, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(spacing: 24.0, crossAxisAlignment: CrossAxisAlignment.start, children: [...])))])` — the scroll wrapper prevents overflow when the keyboard opens.
- Children, in order:
  - `ScreenHeaderWidget(title: 'Excluir conta', description: 'Esta ação é irreversível.\nConfirme com sua senha para excluir definitivamente sua conta e todos os dados associados.')`.
  - `TextFieldWidget(label: 'E-mail', hint: '', readOnly: true, enabled: false, initialValue: email)` — read-only view of the logged-in user's email.
  - `PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', inputAction: TextInputAction.done, obscure: state.obscurePassword, onToggle: ..., failure: state.passwordFailure, onChanged: ...)`.
  - `Spacer()`.
  - `SizedBox(width: double.infinity, child: ButtonWidget.elevated(label: 'Excluir', isLoading: state.status == ProfileDeleteStatus.loading, onTap: ...))`.

The submit handler SHALL be a private method (never a private widget class — CLAUDE.md). It SHALL validate **before** opening the confirm dialog — when validation fails, the dialog SHALL NOT open and the screen SHALL surface `passwordFailure` inline:

```dart
Future<void> _submit(
  BuildContext context,
  WidgetRef ref,
  ProfileDeleteNotifier notifier,
) async {
  hideKeyboard();

  notifier.dispatch(const ValidatePressed());

  if (ref.read(profileDeleteProvider).passwordFailure != null) return;

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

### Requirement: ProfileDeleteLocation registers the delete route

The system SHALL create `lib/src/presentation/ui/profile/delete/locations/profile_delete_location.dart` defining `final class ProfileDeleteLocation extends Location`.

`ProfileDeleteLocation` SHALL declare:

- `String get path` returning `AppRoutes.profileDelete.path`.
- `LocationPageBuilder get pageBuilder` returning `(_) => screenPage(const ProfileDeleteScreen())`.

`ProfileDeleteLocation` SHALL NOT receive any constructor parameters.

#### Scenario: Location resolves the path

Given `ProfileDeleteLocation()` is constructed
Then `path` SHALL equal `'/profile/delete'`

---

### Requirement: ProfileDetailsScreen wires onDelete instead of inline confirm

The system SHALL extend `ProfileDetailsScreen` with `final VoidCallback onDelete;` named-required, declared before the constructor next to the existing `onEditName` and `onEditPassword`.

The previous `_confirmDelete` private method SHALL be removed — the destructive confirmation moves into `ProfileDeleteScreen`. The `ProfileDeleteAccountWidget` SHALL receive `onTap: onDelete` directly in the `AsyncData` branch (no intermediate dialog on the detail screen).

The Skeletonizer (loading) branch SHALL keep `onDelete: () {}` to remain non-interactive while loading.

`ProfileDetailsLocation` SHALL inject `onDelete: () => context.navigate(ProfileDeleteLocation())`. `ProfileDetailsLocation` is the only place authorised to import `ProfileDeleteLocation` (Locations composing navigation — documented exception in CLAUDE.md).

`ProfileDetailsNotifier` SHALL NOT change — delete is fully encapsulated in the new `profile/delete/` subfeature.

#### Scenario: Tapping "Excluir conta" navigates to the delete screen

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Excluir'` button in `ProfileAccountActionsWidget`
Then `DuckRouter.navigate(ProfileDeleteLocation())` SHALL be invoked
And no `showConfirmDialog` SHALL be opened on the detail screen

#### Scenario: ProfileDetailsLocation imports only profile-internal locations

Given the spec implementation is complete
When `grep -n "import 'package:trocado" lib/src/presentation/ui/profile/details/locations/profile_details_location.dart` is executed
Then the only feature locations imported SHALL be `ProfileNameLocation`, `ProfilePasswordLocation` and `ProfileDeleteLocation` (all under `profile/`)

---

### Requirement: IUserRepository extended with updateName and updatePassword

The system SHALL extend `lib/src/domain/repositories/interface_user_repository.dart` with two methods that both return `UserModel` on success:

```dart
Future<Either<Failure, UserModel>> updateName({required String name});

Future<Either<Failure, UserModel>> updatePassword({
  required String currentPassword,
  required String newPassword,
});
```

`IRemoteUserDataSource` SHALL gain a single method reflecting the API shape:

```dart
Future<Either<FailureResponse, UserResponse>> update({
  String? name,
  String? currentPassword,
  String? newPassword,
});
```

`RemoteUserDataSource.update` SHALL call `_client.patch(parameter: Requests(EndpointKey.me.path, body: <map>))` where `<map>` is built inline with conditional spreads, omitting any field whose value is `null`:

```dart
body: {
  if (name != null) 'name': name,
  if (currentPassword != null) 'current_password': currentPassword,
  if (newPassword != null) 'new_password': newPassword,
},
```

It SHALL map the response via `response.either(FailureResponse.fromJson, UserResponse.fromJson)`. No DTO SHALL be introduced for the request body.

`UserRepository.updateName({name})` SHALL call `_userDataSource.update(name: name)` and map via `data.either((failure) => failure.toFailure(), (response) => response.toModel())`. `UserRepository.updatePassword({currentPassword, newPassword})` SHALL call `_userDataSource.update(currentPassword: ..., newPassword: ...)` with identical mapping. Both methods SHALL reuse `UserResponseExtension.toModel()` and `FailureResponseExtension.toFailure()` — no new extension SHALL be introduced.

#### Scenario: updateName calls PATCH /api/v1/me with name only

Given `UserRepository.updateName(name: 'Jane Smith')` is invoked
Then `IHttpClient.patch` SHALL be called with `Requests(path: '/api/v1/me', body: {'name': 'Jane Smith'})`
And the `current_password` and `new_password` keys SHALL NOT be present in the body

#### Scenario: updatePassword calls PATCH /api/v1/me with both password fields

Given `UserRepository.updatePassword(currentPassword: 'OldPassword!123', newPassword: 'NewSecure!456')` is invoked
Then `IHttpClient.patch` SHALL be called with `Requests(path: '/api/v1/me', body: {'current_password': 'OldPassword!123', 'new_password': 'NewSecure!456'})`
And the `name` key SHALL NOT be present in the body

#### Scenario: updateName returns Right(UserModel) on 200

Given the datasource returns `Right(UserResponse(id: 1, name: 'Jane Smith', email: 'jane@trocado.app'))`
When `UserRepository.updateName(name: 'Jane Smith')` resolves
Then it SHALL return `Right(UserModel(id: 1, name: 'Jane Smith', email: 'jane@trocado.app'))`

#### Scenario: updatePassword maps invalid_credentials to ValidationFailure

Given the datasource returns `Left(FailureResponse with code 'invalid_credentials' and message 'Senha incorreta.')`
When `UserRepository.updatePassword(...)` resolves
Then it SHALL return `Left(ValidationFailure('Senha incorreta.'))`

#### Scenario: updateName maps network errors to NetworkFailure

Given the datasource returns `Left(FailureResponse with code 'connection_error')`
When `UserRepository.updateName(...)` resolves
Then it SHALL return `Left(NetworkFailure())`

---

### Requirement: ProfileNameState gains submit status and message

The system SHALL extend `lib/src/presentation/ui/profile/name/notifiers/profile_name_state.dart` with:

- A top-level `enum ProfileNameStatus { initial, loading, success, failure }`.
- A new field `final String message;` (default `''`) declared before the constructor.
- A new field `final ProfileNameStatus status;` (default `ProfileNameStatus.initial`) declared before the constructor.

The constructor, `copyWith` and `props` SHALL all be updated to include the new fields. `copyWith` SHALL accept `String? message` and `ProfileNameStatus? status` (no clear-flags — both default to the current value when omitted).

#### Scenario: Default state has initial status and empty message

Given `const ProfileNameState()`
Then `status` SHALL equal `ProfileNameStatus.initial`
And `message` SHALL equal `''`

---

### Requirement: ProfileNameNotifier calls repository on valid submit

The system SHALL extend `ProfileNameNotifier`:

- Add `late IUserRepository _repository;` declared before `_validator`.
- In `build()`, call `_repository = ref.watch(userRepositoryProvider);` before reading `userProvider.future`.
- Convert `_submit` to `Future<void> _submit() async` with the following logic in order:

  1. `final (state: validated, :isValid) = _validator(this.state.value!);`
  2. `this.state = AsyncData(validated);`
  3. `if (!isValid) return;`
  4. `if (validated.status == ProfileNameStatus.loading) return;` (re-entrancy guard)
  5. `this.state = AsyncData(validated.copyWith(status: ProfileNameStatus.loading));`
  6. `final data = await _repository.updateName(name: validated.name);`
  7. `data.fold((failure) => state = AsyncData(state.value!.copyWith(status: ProfileNameStatus.failure, message: failure.message)), (_) { ref.invalidate(userProvider); state = AsyncData(state.value!.copyWith(status: ProfileNameStatus.success)); });`

The `// TODO Parte 6` comment SHALL be removed.

#### Scenario: Valid submit calls repository and reaches success

Given the user dispatched a valid `NameChanged('Jane')` and `userProvider` resolved with a valid user
When `dispatch(SubmitPressed())` resolves with `_repository.updateName(...)` returning `Right(UserModel)`
Then `_repository.updateName(name: 'Jane')` SHALL be called exactly once
And `ref.invalidate(userProvider)` SHALL be called
And `state.value!.status` SHALL equal `ProfileNameStatus.success`

#### Scenario: Repository failure populates status and message

Given a valid name is set
When `dispatch(SubmitPressed())` resolves with `_repository.updateName(...)` returning `Left(ServerFailure())`
Then `state.value!.status` SHALL equal `ProfileNameStatus.failure`
And `state.value!.message` SHALL equal the failure's `message`

#### Scenario: Invalid submit does not call repository

Given the user dispatched `NameChanged('')`
When `dispatch(SubmitPressed())` runs
Then `state.value!.nameFailure` SHALL equal `'Nome obrigatório'`
And `_repository.updateName` SHALL NOT be called

#### Scenario: Re-entrant submit is a no-op

Given `state.value!.status == ProfileNameStatus.loading`
When `dispatch(SubmitPressed())` runs again with valid input
Then `_repository.updateName` SHALL be called exactly once total

---

### Requirement: ProfilePasswordState reshape — current/new only

The system SHALL refactor `lib/src/presentation/ui/profile/password/notifiers/profile_password_state.dart` to model only the two fields needed by the API:

- A top-level `enum ProfilePasswordStatus { initial, loading, success, failure }`.
- Fields declared before the constructor: `final String currentPassword;` (default `''`), `final String newPassword;` (default `''`), `final bool obscureCurrentPassword;` (default `true`), `final bool obscureNewPassword;` (default `true`), `final String? currentPasswordFailure;`, `final String? newPasswordFailure;`, `final String message;` (default `''`), `final ProfilePasswordStatus status;` (default `ProfilePasswordStatus.initial`).
- The previous fields `confirmPassword`, `confirmPasswordFailure`, `obscureConfirmPassword` SHALL be removed.
- `copyWith` SHALL accept `String? currentPassword`, `String? newPassword`, `bool? obscureCurrentPassword`, `bool? obscureNewPassword`, `String? currentPasswordFailure`, `String? newPasswordFailure`, `String? message`, `ProfilePasswordStatus? status`, `bool clearCurrentPasswordFailure = false`, `bool clearNewPasswordFailure = false` — and SHALL NOT accept any `confirm*` parameter or `clearConfirmPasswordFailure`.
- `props` SHALL reflect the new field list.

#### Scenario: Default state matches new shape

Given `const ProfilePasswordState()`
Then `currentPassword` SHALL equal `''` and `newPassword` SHALL equal `''`
And both `obscureCurrentPassword` and `obscureNewPassword` SHALL be `true`
And `status` SHALL equal `ProfilePasswordStatus.initial`

---

### Requirement: ProfilePasswordIntent — current replaces confirm

The system SHALL replace `ConfirmPasswordChanged(value)` with `CurrentPasswordChanged(value)` and `ConfirmPasswordVisibilityToggled()` with `CurrentPasswordVisibilityToggled()` in `lib/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart`.

The intent hierarchy SHALL be sealed and contain exactly: `CurrentPasswordChanged(String value)`, `NewPasswordChanged(String value)`, `CurrentPasswordVisibilityToggled()`, `NewPasswordVisibilityToggled()`, `SubmitPressed()`.

#### Scenario: Confirm intents are gone

Given the implementation is complete
When `grep -rn "ConfirmPasswordChanged\|ConfirmPasswordVisibilityToggled" lib/src/presentation/ui/profile/password/` is executed
Then there SHALL be no matches

---

### Requirement: ProfilePasswordFormValidator validates current and new without match

The system SHALL refactor `ProfilePasswordFormValidator` to validate **two independent** password fields:

- `currentPassword` via the shared `PasswordValidation` (min 8) → on `Invalid`, populates `currentPasswordFailure`; on `Valid`, clears it via `clearCurrentPasswordFailure: true`.
- `newPassword` via the shared `PasswordValidation` (min 8) → on `Invalid`, populates `newPasswordFailure`; on `Valid`, clears it via `clearNewPasswordFailure: true`.

`isValid` SHALL be `true` only when **both** validations return `Valid`. The validator SHALL NOT compare `newPassword` to any confirmation field — no `'As senhas não coincidem'` message SHALL be emitted.

#### Scenario: Both passwords valid passes

Given `state.currentPassword == 'OldPass!123'` and `state.newPassword == 'NewPass!456'`
When the validator is invoked
Then `currentPasswordFailure` and `newPasswordFailure` SHALL be `null`
And `isValid` SHALL be `true`

#### Scenario: Empty current produces currentPasswordFailure

Given `state.currentPassword == ''` and `state.newPassword == 'NewPass!456'`
When the validator is invoked
Then `state.currentPasswordFailure` SHALL equal `'Senha obrigatória'`
And `isValid` SHALL be `false`

#### Scenario: Short new password produces newPasswordFailure

Given `state.currentPassword == 'OldPass!123'` and `state.newPassword == 'short'`
When the validator is invoked
Then `state.newPasswordFailure` SHALL equal `'Senha deve ter ao menos 8 caracteres'`
And `isValid` SHALL be `false`

---

### Requirement: ProfilePasswordNotifier migrates to AsyncNotifier with repository

The system SHALL migrate `ProfilePasswordNotifier` from synchronous `Notifier<ProfilePasswordState>` to `AsyncNotifier`:

- `Future<ProfilePasswordState> build() async` returns `const ProfilePasswordState()`. There is no `await` in the body — the async signature aligns the dispatch/submit pattern with `ProfileNameNotifier`.
- Dependencies: `late IUserRepository _repository;` and `late ProfilePasswordFormValidator _validator;`, both initialised via `ref.watch` in `build()`.
- `dispatch(ProfilePasswordIntent intent)` SHALL be exhaustive and update the state via `state = AsyncData(state.value!.copyWith(...))`:
  - `CurrentPasswordChanged(:final value)` → `copyWith(currentPassword: value, clearCurrentPasswordFailure: true)`.
  - `NewPasswordChanged(:final value)` → `copyWith(newPassword: value, clearNewPasswordFailure: true)`.
  - `CurrentPasswordVisibilityToggled()` → `copyWith(obscureCurrentPassword: !state.value!.obscureCurrentPassword)`.
  - `NewPasswordVisibilityToggled()` → `copyWith(obscureNewPassword: !state.value!.obscureNewPassword)`.
  - `SubmitPressed()` → `_submit()`.
- `Future<void> _submit() async` SHALL mirror the shape used in `ProfileNameNotifier`:
  1. Run the validator and propagate validated state via `state = AsyncData(validated)`.
  2. Return if `!isValid`.
  3. Return if `validated.status == ProfilePasswordStatus.loading` (re-entrancy guard).
  4. `state = AsyncData(validated.copyWith(status: ProfilePasswordStatus.loading))`.
  5. `await _repository.updatePassword(currentPassword: validated.currentPassword, newPassword: validated.newPassword)`.
  6. `fold` → failure: `state = AsyncData(state.value!.copyWith(status: ProfilePasswordStatus.failure, message: failure.message))`; success: `ref.invalidate(userProvider); state = AsyncData(state.value!.copyWith(status: ProfilePasswordStatus.success))`.
- The `// TODO Parte 6` comment SHALL be removed.

#### Scenario: Valid submit calls updatePassword and reaches success

Given the user dispatched `CurrentPasswordChanged('OldPass!123')` and `NewPasswordChanged('NewPass!456')`
When `dispatch(SubmitPressed())` resolves with `_repository.updatePassword(...)` returning `Right(UserModel)`
Then `_repository.updatePassword(currentPassword: 'OldPass!123', newPassword: 'NewPass!456')` SHALL be called exactly once
And `ref.invalidate(userProvider)` SHALL be called
And `state.value!.status` SHALL equal `ProfilePasswordStatus.success`

#### Scenario: Repository failure populates status and message

Given valid `currentPassword` and `newPassword`
When `dispatch(SubmitPressed())` resolves with `_repository.updatePassword(...)` returning `Left(ValidationFailure('Senha incorreta.'))`
Then `state.value!.status` SHALL equal `ProfilePasswordStatus.failure`
And `state.value!.message` SHALL equal `'Senha incorreta.'`

#### Scenario: Visibility toggles are independent

Given `state.value!.obscureCurrentPassword == true` and `state.value!.obscureNewPassword == true`
When `dispatch(CurrentPasswordVisibilityToggled())` runs
Then `state.value!.obscureCurrentPassword` SHALL become `false`
And `state.value!.obscureNewPassword` SHALL remain `true`

---

### Requirement: ProfileNameScreen receives onSuccess and reacts to status

The system SHALL extend `ProfileNameScreen` with `final VoidCallback onSuccess;` named-required declared before the constructor.

Inside the `Consumer`, the screen SHALL `ref.listen(profileNameProvider, ...)` and:

- On transition to `state.value?.status == ProfileNameStatus.failure` (and previous status was different) → call `showToastWidget(context: context, title: 'Opps', type: ToastType.failure, description: state.value?.message ?? '')`.
- On transition to `state.value?.status == ProfileNameStatus.success` (and previous status was different) → call `onSuccess()`.

The "Atualizar" button SHALL be `ButtonWidget.elevated(label: 'Atualizar', isLoading: state.status == ProfileNameStatus.loading, onTap: ...)`. The screen SHALL remain a `StatelessWidget` with an inner `Consumer` (never `ConsumerWidget`).

#### Scenario: Success calls onSuccess exactly once per transition

Given the notifier transitions from `loading` to `success`
When the listener observes the change
Then `onSuccess()` SHALL be invoked exactly once
And no toast SHALL be shown

#### Scenario: Failure shows the toast with the failure message

Given the notifier transitions from `loading` to `failure` with `message == 'Server error'`
When the listener observes the change
Then `showToastWidget` SHALL be invoked with `title: 'Opps'`, `type: ToastType.failure`, `description: 'Server error'`
And `onSuccess()` SHALL NOT be invoked

#### Scenario: Loading status drives button isLoading

Given `state.value!.status == ProfileNameStatus.loading`
When the screen builds
Then `ButtonWidget.elevated` SHALL receive `isLoading: true`

---

### Requirement: ProfilePasswordScreen is rebuilt with two fields and onSuccess

The system SHALL rebuild `lib/src/presentation/ui/profile/password/screens/profile_password_screen.dart`:

- Add `final VoidCallback onSuccess;` named-required.
- Build via `switch (ref.watch(profilePasswordProvider))`:
  - `AsyncData(:final value)` → `_buildBody(state: value, notifier: ref.read(profilePasswordProvider.notifier))`.
  - `AsyncError(:final error)` → `_buildError(failure: error is Failure ? error : const UnknownFailure(), onRetry: () => ref.invalidate(profilePasswordProvider))` mirroring `ProfileNameScreen`.
  - `_` → `const Center(child: CircularProgressIndicatorWidget())`.
- `ref.listen(profilePasswordProvider, ...)` SHALL fire `showToastWidget(title: 'Opps', type: ToastType.failure, description: state.value?.message ?? '')` on transition to `failure` and `onSuccess()` on transition to `success`.
- `_buildBody` SHALL be a private method (never a private class) and return a `CustomScrollView` with `SliverFillRemaining(hasScrollBody: false, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(spacing: 24.0, crossAxisAlignment: CrossAxisAlignment.start, children: [...])))`.
- The column children, in order, SHALL be:
  - `ScreenHeaderWidget(title: 'Senha', description: 'Crie uma nova senha para sua conta.')`.
  - A nested `Column(spacing: 12.0, crossAxisAlignment: CrossAxisAlignment.start)` containing exactly two `PasswordFieldWidget`:
    - `PasswordFieldWidget(label: 'Senha atual', hint: 'Digite sua senha atual', inputAction: TextInputAction.next, failure: state.currentPasswordFailure, obscure: state.obscureCurrentPassword, onChanged: (v) => notifier.dispatch(CurrentPasswordChanged(v)), onToggle: () => notifier.dispatch(const CurrentPasswordVisibilityToggled()))`.
    - `PasswordFieldWidget(label: 'Nova senha', hint: 'Digite a nova senha', inputAction: TextInputAction.done, failure: state.newPasswordFailure, obscure: state.obscureNewPassword, onChanged: (v) => notifier.dispatch(NewPasswordChanged(v)), onToggle: () => notifier.dispatch(const NewPasswordVisibilityToggled()))`.
  - `const Spacer()`.
  - `SizedBox(width: double.infinity, child: ButtonWidget.elevated(label: 'Atualizar', isLoading: state.status == ProfilePasswordStatus.loading, onTap: () { hideKeyboard(); notifier.dispatch(const SubmitPressed()); }))`.

The screen SHALL NOT reference `confirmPassword`, `confirmPasswordFailure`, `obscureConfirmPassword`, `ConfirmPasswordChanged` or `ConfirmPasswordVisibilityToggled` — any leftover from the previous part is a violation.

#### Scenario: Two password fields are rendered

Given the user opens `ProfilePasswordScreen`
When the screen builds with `AsyncData(ProfilePasswordState())`
Then the `Column` SHALL contain exactly two `PasswordFieldWidget` widgets
And their labels SHALL be `'Senha atual'` and `'Nova senha'` in that order
And there SHALL be no field labelled `'Confirmar senha'`

#### Scenario: Success navigates back via onSuccess

Given the notifier transitions to `ProfilePasswordStatus.success`
When the listener observes the change
Then `onSuccess()` SHALL be invoked exactly once

---

### Requirement: ProfileNameLocation and ProfilePasswordLocation accept onSuccess

The system SHALL extend both `ProfileNameLocation` and `ProfilePasswordLocation` with a named-required `VoidCallback onSuccess` constructor parameter.

```dart
final class ProfileNameLocation extends Location {
  final VoidCallback onSuccess;
  const ProfileNameLocation({required this.onSuccess});

  @override
  String get path => AppRoutes.profileName.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(ProfileNameScreen(onSuccess: onSuccess));
}
```

The same shape SHALL apply to `ProfilePasswordLocation` (pointing to `AppRoutes.profilePassword.path` and constructing `ProfilePasswordScreen(onSuccess: onSuccess)`).

`ProfileDetailsLocation.pageBuilder` SHALL pass `onSuccess: () => context.pop()` when constructing both `ProfileNameLocation(...)` and `ProfilePasswordLocation(...)`. `ProfileDetailsLocation` SHALL remain the only place importing `ProfileNameLocation` and `ProfilePasswordLocation` (Locations composing navigation — the documented exception in CLAUDE.md).

#### Scenario: Pop closes the editor on success

Given the user is on `ProfileNameScreen` (or `ProfilePasswordScreen`)
When the notifier transitions to `success`
Then `context.pop()` SHALL be invoked exactly once
And the user SHALL land back on `ProfileDetailsScreen` with the freshly invalidated `userProvider`

---

### Requirement: No Parte 6 TODOs remain after implementation

The system SHALL remove the placeholders `// TODO Parte 6: chamar repository.updateName(...)` and `// TODO Parte 6: chamar repository.updatePassword(...)` from the notifiers, replacing them with the actual repository calls described above.

#### Scenario: No TODOs left

Given the implementation is complete
When `grep -rn "TODO Parte 6" lib/` is executed
Then the result SHALL be empty

