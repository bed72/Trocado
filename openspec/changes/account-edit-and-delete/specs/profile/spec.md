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

The system SHALL replace the `ScreenHeaderWidget` + `Placeholder` body from Part 1 with a `Consumer` that calls `ref.watch(userProvider)` and renders an `AsyncValue<UserModel>` switch.

The screen SHALL remain a `StatelessWidget` (not `ConsumerWidget`) with an inner `Consumer` (CLAUDE.md feature rule).

The `AsyncValue` switch SHALL handle three states:

- `AsyncLoading()` → `Skeletonizer(enabled: true, child: <success layout with placeholder UserModel>)`.
- `AsyncError(:final error)` → `Center` with the failure message and a `'Tentar novamente'` button that invalidates `userProvider`.
- `AsyncData(:final value)` → success layout: `ProfileHeaderWidget(user: value)` + `ProfileFieldsCardWidget(children: [...])` (3 items) + `ProfileDeleteAccountWidget(onTap: ...)` at the bottom.

#### Scenario: Loading state shows skeletonized layout

Given `userProvider` has not yet resolved
When `ProfileScreen` builds
Then a `Skeletonizer` widget SHALL wrap the success layout with `enabled: true`

#### Scenario: Error state shows retry button

Given `userProvider` resolves with an error
When `ProfileScreen` builds
Then a `'Tentar novamente'` button SHALL be present
And tapping it SHALL invalidate `userProvider`

#### Scenario: Data state renders header, three items and delete button

Given `userProvider` resolves with `AsyncData(UserModel(name: 'Kevin', email: 'kevin@trocado.app'))`
When `ProfileScreen` builds
Then a `ProfileHeaderWidget` SHALL render the avatar, name `'Kevin'` and email `'kevin@trocado.app'`
And a `ProfileFieldsCardWidget` SHALL contain three `ProfileFieldItemWidget` children with labels `'Nome'`, `'E-mail'`, `'Senha'` in that order
And the `'E-mail'` item SHALL be disabled
And a `ProfileDeleteAccountWidget` SHALL be rendered at the bottom

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

### Requirement: ProfileDeleteAccountWidget triggers destructive confirmation

The system SHALL create `lib/src/presentation/ui/profile/widgets/profile_delete_account_widget.dart` as a `StatelessWidget` with `final VoidCallback onTap;`.

The widget SHALL render `ButtonWidget.outlined` (full width via `Container(width: double.infinity)`) with label `'Apagar conta'` and an `Icons.delete_outline` icon child.

The button SHALL be wrapped in a `Theme` override that swaps `colorScheme.primary` for `context.colors.error`, so the outlined button surfaces the destructive color in its border, label and icon.

`ProfileScreen` SHALL handle the `onTap` by calling `showConfirmDialog(title: 'Apagar conta', description: 'Esta ação é irreversível. Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.', confirmLabel: 'Apagar')` and SHALL only proceed with the destructive action when the dialog resolves to `true`. In Part 2 the post-confirmation action is a no-op (Part 4 wires the API call).

#### Scenario: Tap opens confirmation dialog

Given the user is on `ProfileScreen` with data loaded
When the user taps the `'Apagar conta'` button
Then `showConfirmDialog` SHALL be invoked with `title: 'Apagar conta'`, `confirmLabel: 'Apagar'` and the explicit irreversibility description

#### Scenario: Cancel does not trigger any side effect

Given the confirmation dialog is open
When the user taps `'Cancelar'`
Then the dialog SHALL close
And no further action SHALL be triggered
