# Spec — logout

## API contract

`POST /api/v1/auth/logout` — requer Bearer token.

Request body:
```json
{ "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }
```

Response: `{}` (corpo ignorado, sucesso = 2xx).
Erros: formato padrão `{ "errors": [...] }`.

O `refresh` token é lido de `ILocalTokenDataSource.get()` dentro do repositório — a interface de domínio não recebe parâmetros.

---

## Camadas

### 1. EndpointKey
Adicionar `logout('/api/v1/auth/logout')`.

### 2. IRemoteAuthenticationDataSource + RemoteAuthenticationDataSource
Adicionar método:
```dart
Future<Either<FailureResponse, void>> logout({required String refresh});
```
Body inlined (sem `LogoutRequest`), mesmo padrão de `verifyToken`:
```dart
response.either(FailureResponse.fromJson, (_) {})
```

### 3. IAuthenticationRepository
Adicionar:
```dart
Future<Either<Failure, void>> logout();
```
Sem parâmetros — o repositório lê o refresh token internamente.

### 4. AuthenticationRepository
Fluxo:
1. `_tokenDataSource.get()` → obter tokens
2. Se `refresh == null` → `await _tokenDataSource.clear()` + `return Right(null)` (best-effort)
3. `_authenticationDataSource.logout(refresh: tokens.refresh!)`
4. Se `isLeft` → `return Left(data.left.toFailure())` **sem** limpar tokens (API falhou)
5. `await _tokenDataSource.clear()`
6. `return Right(null)`

### 5. SettingsIntent / SettingsState / SettingsNotifier
Novo notifier MVI para a tela de settings.

**Intent:**
```dart
sealed class SettingsIntent {}
final class LogoutPressed extends SettingsIntent {}
```

**State:**
```dart
enum SettingsStatus { initial, loading, success, failure }

final class SettingsState extends Equatable {
  final String message;
  final SettingsStatus status;
  ...
}
```

**Notifier:**
- Injeta `IAuthenticationRepository` via `ref.watch(authenticationRepositoryProvider)`
- `LogoutPressed()` → `_logout()`
- `_logout()`: `loading` → chama `logout()` → `success` ou `failure`

### 6. SettingsScreen
- Adiciona `Consumer` que lê `settingsProvider`
- `ref.listen`: quando `status == success` → `routerConfig.navigate(root: true, replace: true, to: SignInLocation())`
- Quando `status == failure` → `showToastWidget` com `state.message`
- Remove parâmetro `onLogout` do construtor
- Passa `isLoading: state.status == SettingsStatus.loading` para `SettingsLogoutWidget`
- Botão despacha `LogoutPressed()`

### 7. SettingsLocation
Remove `onLogout: () {}`.

### 8. SettingsLogoutWidget
Adiciona parâmetro `bool isLoading` (default `false`) — passa para `ButtonWidget.outlined`.

---

## Arquivos

### Criar
- `lib/src/presentation/screens/settings/notifiers/settings_intent.dart`
- `lib/src/presentation/screens/settings/notifiers/settings_state.dart`
- `lib/src/presentation/screens/settings/notifiers/settings_notifier.dart`

### Modificar
| Arquivo | Mudança |
|---|---|
| `endpoint_key.dart` | + `logout` |
| `remote_authentication_data_source.dart` | + `logout` method |
| `interface_authentication_repository.dart` | + `logout()` |
| `authentication_repository.dart` | implementa `logout()` |
| `settings_screen.dart` | Consumer + notifier; remove `onLogout` param |
| `settings_location.dart` | remove `onLogout: () {}` |
| `settings_logout_widget.dart` | + `isLoading` param |

### Testes
- `test/src/data/repositories/authentication_repository_test.dart` — adicionar `group('logout', ...)` com 4 casos: Right, best-effort sem refresh, Left ValidationFailure, Left NetworkFailure
- `test/src/presentation/providers/settings_notifier_test.dart` — LogoutPressed: success, failure, loading state, não chama repo quando já loading

---

## Fora do escopo
- Confirmação de logout (dialog)
- Invalidar cache de `userProvider`
- Outros intents do `SettingsNotifier` (edit profile, notification, subscription)
