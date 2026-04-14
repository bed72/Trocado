# Tasks — sign-in-screen

## Checklist

### Setup
- [x] `pubspec.yaml` — adicionar `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`
- [x] `flutter pub get`
- [x] `lib/main.dart` — envolver `AppWidget` com `ProviderScope`

### Main
- [x] `lib/app_route.dart` — adicionar `AppRoutes.signIn` (`/sign-in`) e incluir em `_all`
- [x] `lib/src/main/providers/authentication_repository_provider.dart` — `@Riverpod(keepAlive: true)` retornando `IAuthenticationRepository`
- [x] `lib/src/main/locations/sign_in_location.dart` — `SignInLocation` com `onSuccess → HomeLocation`
- [x] `lib/src/main/locations/splash_location.dart` — mudar destino para `SignInLocation`

### Presentation — Providers
- [x] `lib/src/presentation/providers/sign_in/sign_in_status.dart` — enum `SignInStatus`
- [x] `lib/src/presentation/providers/sign_in/sign_in_state.dart` — `SignInState` (Equatable, copyWith)
- [x] `lib/src/presentation/providers/sign_in/sign_in_intent.dart` — sealed `SignInIntent`
- [x] `lib/src/presentation/providers/sign_in/sign_in_notifier.dart` — `@riverpod SignInNotifier`
- [x] `dart run build_runner build --delete-conflicting-outputs`

### Presentation — Screen
- [x] `lib/src/presentation/screens/sign_in_screen.dart` — `StatelessWidget + Consumer`

### Testes
- [x] `test/mocks/mocks.dart` — adicionar `MockAuthenticationRepository`
- [x] `test/src/presentation/providers/sign_in_notifier_test.dart` — cobrir: EmailChanged, PasswordChanged, SubmitPressed success, SubmitPressed failure
