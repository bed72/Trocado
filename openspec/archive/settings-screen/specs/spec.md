# Spec — settings-screen

## Scope

UI only — screen and widgets. No new notifier, no new repository, no backend call.
`userProvider` (already existing) is used solely to display name/email/avatar in the profile header.

---

## Layout

```
SettingsScreen
├── AppBarWidget(leading: GoBackWidget())
└── Padding(all: 16)
    └── Column
        ├── SettingsProfileWidget        ← avatar + name + email
        ├── SizedBox(height: 24)
        ├── SettingsSectionWidget(label: 'CONTA')
        ├── SizedBox(height: 8)
        ├── SettingsItemWidget(icon: person_outline,        label: 'Edit Profile',  onTap: ...)
        ├── SettingsItemWidget(icon: notifications_outlined, label: 'Notification',  onTap: ...)
        ├── SettingsItemWidget(icon: star_outline,          label: 'Subscription',  onTap: ..., isPremium: true)
        ├── Spacer()
        └── SettingsLogoutWidget(onTap: ...)
```

---

## Requirements

### Requirement: Profile Header
The system SHALL render `SettingsProfileWidget` at the top of the screen.
`SettingsScreen` SHALL read `userProvider` via `Consumer`.
When `AsyncData`, `SettingsProfileWidget` receives the `UserModel`.
When `AsyncLoading` or `AsyncError`, a fixed-height placeholder SHALL be shown in place of the header.

`SettingsProfileWidget` SHALL display:
- A circular avatar (48×48 dp). If `UserModel.avatar` is non-null, load the image URL; otherwise show the user's initial as a fallback.
- `UserModel.name` — single line, `titleMedium`, bold.
- `UserModel.email` — single line, `bodySmall`, `onSurfaceVariant` color.

#### Scenario: User data loaded
Given `userProvider` returns `AsyncData(UserModel(name:'Ronaldo', email:'r@trocado.app', avatar: null))`
Then the header SHALL display "Ronaldo" and "r@trocado.app"
And the avatar SHALL show the letter "R" as fallback

---

### Requirement: Section Label
The system SHALL render `SettingsSectionWidget` with `label: 'CONTA'` above the item list.
`SettingsSectionWidget` SHALL display the label in uppercase, `labelSmall` typography, `onSurfaceVariant` color.

---

### Requirement: Settings Item
The system SHALL render `SettingsItemWidget` for each option.

`SettingsItemWidget` SHALL have:
| Parameter | Type | Description |
|---|---|---|
| `icon` | `IconData` | Left icon |
| `label` | `String` | Text, single line, `bodyLarge` |
| `onTap` | `VoidCallback` | Tap handler |
| `isPremium` | `bool` (default `false`) | Shows PREMIUM badge |

Each item SHALL render:
- Left: icon (24 dp) in `onSurfaceVariant` color
- Center: label text, expanded, single line, ellipsis overflow
- Right: chevron icon `Icons.chevron_right` in `onSurfaceVariant` color

When `isPremium: true`, a "PREMIUM" label chip SHALL appear between the text and the chevron (small, `primary` color, outlined style).

The item SHALL have a minimum tap target height of 56 dp.
An `InkWell` or `BounceWidget` SHALL provide tap feedback.

#### Scenario: Tapping an item
Given any `SettingsItemWidget` is displayed
When the user taps it
Then `onTap` SHALL be called

---

### Requirement: Items — specific entries

The system SHALL render exactly three items in order:

| Order | icon | label | isPremium |
|---|---|---|---|
| 1 | `Icons.person_outline` | `'Edit Profile'` | `false` |
| 2 | `Icons.notifications_outlined` | `'Notification'` | `false` |
| 3 | `Icons.star_outline` | `'Subscription'` | `true` |

---

### Requirement: Logout
The system SHALL render `SettingsLogoutWidget` pinned to the bottom of the screen (via `Spacer()`).
`SettingsLogoutWidget` SHALL render a full-width `ButtonWidget.outlined` with label `'Logout'` and a leading `Icons.logout` icon.

#### Scenario: Tapping Logout
Given `SettingsLogoutWidget` is displayed
When the user taps it
Then `onTap` SHALL be called

---

### Requirement: Navigation Callbacks
`SettingsScreen` SHALL receive four `VoidCallback` parameters:

| Parameter | Triggered by |
|---|---|
| `onEditProfile` | Edit Profile item tap |
| `onNotification` | Notification item tap |
| `onSubscription` | Subscription item tap |
| `onLogout` | Logout button tap |

`SettingsLocation` SHALL provide stub callbacks (`() {}`) for each — real navigation will be wired in future specs.

---

## Files

### Create
- `lib/src/presentation/screens/settings/widgets/settings_profile_widget.dart`
- `lib/src/presentation/screens/settings/widgets/settings_section_widget.dart`
- `lib/src/presentation/screens/settings/widgets/settings_item_widget.dart`
- `lib/src/presentation/screens/settings/widgets/settings_logout_widget.dart`

### Modify
- `lib/src/presentation/screens/settings/settings_screen.dart` — replace `Placeholder` with actual layout
- `lib/src/presentation/screens/settings/settings_location.dart` — pass stub callbacks

---

## Out of scope
- Notifier / state management
- Edit Profile screen
- Notification preferences
- Subscription/payment logic
- Logout confirmation dialog or business logic
- Tests (UI-only, no testable business logic)
