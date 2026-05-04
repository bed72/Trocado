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

### Requirement: ProfileAccountActionsWidget exposes Deactivate and Delete side-by-side

The system SHALL create `lib/src/presentation/ui/profile/details/widgets/profile_account_actions_widget.dart` (replacing the previous `profile_delete_account_widget.dart` from Part 2) as a `StatelessWidget` with `final VoidCallback onDelete;` and `final VoidCallback onDeactivate;` (both named-required).

The widget SHALL render `Padding(padding: const EdgeInsets.only(top: 16.0))` containing a `Row(spacing: 16.0)` with two `Expanded` children:

- Left: `ButtonWidget.outlined(label: 'Desativar', onTap: onDeactivate)` — reversible action.
- Right: `ButtonWidget.elevated(label: 'Deletar', onTap: onDelete)` — irreversible action.

The buttons SHALL NOT render icons — only the label is shown.

The widget SHALL NOT apply a `Theme` override or custom destructive coloring — the destructive intent is communicated exclusively through the confirmation dialog text.

This widget mirrors the visual pattern of `BudgetEditActionsWidget` (Row with two `Expanded` buttons, outlined on the left, elevated on the right).

`ProfileDetailsScreen` SHALL provide two private methods that invoke `showConfirmDialog`:

- `_confirmDelete`: `title: 'Deletar conta'`, `confirmLabel: 'Deletar'`, description containing the explicit irreversibility wording.
- `_confirmDeactivate`: `title: 'Desativar conta'`, `confirmLabel: 'Desativar'`, description explaining that data is preserved and reactivation happens via sign-in.

In Part 4 the post-confirmation action of both flows is a no-op — Part 5 wires the actual API calls.

#### Scenario: Both buttons are rendered side by side

Given the user is on `ProfileDetailsScreen` with data loaded
When `ProfileAccountActionsWidget` builds
Then a `Row` with two `Expanded` children SHALL be present
And the left child SHALL be `ButtonWidget.outlined` with label `'Desativar'`
And the right child SHALL be `ButtonWidget.elevated` with label `'Deletar'`

#### Scenario: Tap on Deletar opens deletion dialog

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Deletar'` button
Then `showConfirmDialog` SHALL be invoked with `title: 'Deletar conta'` and `confirmLabel: 'Deletar'`
And the description SHALL contain the explicit irreversibility wording

#### Scenario: Tap on Desativar opens deactivation dialog

Given the user is on `ProfileDetailsScreen` with data loaded
When the user taps the `'Desativar'` button
Then `showConfirmDialog` SHALL be invoked with `title: 'Desativar conta'` and `confirmLabel: 'Desativar'`
And the description SHALL explain that data is preserved and reactivation is possible by signing in again

#### Scenario: Cancel does not trigger any side effect

Given any of the two confirmation dialogs is open
When the user taps `'Cancelar'`
Then the dialog SHALL close
And no further action SHALL be triggered

---

### Requirement: profile feature is organised in subdirectories

The system SHALL reorganise `lib/src/presentation/ui/profile/` to mirror the `lib/src/presentation/ui/authentication/` pattern — every screen of the feature lives in its own subdirectory.

The following subdirectories SHALL exist after this part:

- `profile/details/` — listing screen (renamed from the root-level files of Parts 1 and 2). Contains `screens/profile_details_screen.dart`, `locations/profile_details_location.dart` and `widgets/profile_*.dart` (the four widgets created in Part 2).
- `profile/name/` — name editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.
- `profile/password/` — password editing screen, with `screens/`, `locations/`, `notifiers/`, `validators/`.

The class `ProfileScreen` SHALL be renamed to `ProfileDetailsScreen` and `ProfileLocation` to `ProfileDetailsLocation`. Imports in `HomeLocation` and `SettingsLocation` SHALL be updated accordingly. The route path `/profile` SHALL continue to map to `ProfileDetailsLocation` — no change to `AppRoutes.profile`.

#### Scenario: Subdirectories exist

Given the reorganisation is complete
When `find lib/src/presentation/ui/profile -maxdepth 1 -mindepth 1 -type d` is executed
Then the result SHALL list exactly three directories: `details`, `name`, `password`

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
- `_submit()` that validates via the form validator, propagates failures into `state`, and returns early when invalid. When valid the body SHALL contain a `// TODO Parte 4` comment and SHALL NOT call any repository in this part.

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
And no repository call SHALL be made (deferred to Part 4)

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

`_submit()` SHALL validate via `profilePasswordFormValidatorProvider`, propagate failures and return early when invalid. When valid the body SHALL contain a `// TODO Parte 4` comment and SHALL NOT call any repository in this part.

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
