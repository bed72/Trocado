# Design — sign-in-screen

## Regra de dependência

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

Nenhuma camada nova de domínio ou dados é criada. Apenas presentation + main.

---

## Pré-requisito: Riverpod

`flutter_riverpod`, `riverpod_annotation` e `riverpod_generator` ainda não estão no `pubspec.yaml`. Devem ser adicionados nesta feature — é a primeira a usar Riverpod no projeto.

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

dev_dependencies:
  riverpod_generator: ^2.6.1
  build_runner: ^2.4.15
```

`main.dart` deve envolver `AppWidget` com `ProviderScope`.

---

## Provider do repositório

Arquivo: `lib/src/main/providers/authentication_repository_provider.dart`

- Anota com `@Riverpod(keepAlive: true)` — singleton, shared state de autenticação
- Retorna `IAuthenticationRepository` (interface do domínio)
- Instancia internamente toda a cadeia: `HttpClient → RemoteAuthenticationDataSource`, `StorageClient → LocalTokenDataSource`, `AuthenticationRepository`

---

## MVI — SignIn

### State (`sign_in_state.dart`)

| Campo | Tipo | Default |
|---|---|---|
| `email` | `String` | `''` |
| `password` | `String` | `''` |
| `status` | `SignInStatus` | `initial` |
| `message` | `String` | `''` |

`SignInStatus`: enum com `initial`, `loading`, `success`, `failure`.

### Intent (`sign_in_intent.dart`)

```dart
sealed class SignInIntent {}
final class EmailChanged extends SignInIntent { final String value; }
final class PasswordChanged extends SignInIntent { final String value; }
final class SubmitPressed extends SignInIntent {}
```

### Notifier (`sign_in_notifier.dart`)

- `@riverpod` (gerado: `signInNotifierProvider`)
- `dispatch` com switch exhaustivo
- `_submit`: seta `loading` → chama `ref.read(authenticationRepositoryProvider).signIn` → fold: success → `success` | failure → `failure` + `message`
- Lê o repositório com `ref.read` (não `ref.watch` — é uma ação pontual)

---

## Screen

Arquivo: `lib/src/presentation/screens/sign_in_screen.dart`

- `StatelessWidget` — **nunca `ConsumerWidget`**
- Recebe `onSuccess: VoidCallback` via construtor (convenção da splash)
- `Consumer` interno no `build`
- `ref.listen` no status para chamar `onSuccess()` quando `success`

### Layout (fiel ao screenshot)

```
ScaffoldWidget(
  bottomNavigationBar: _Bottom,
  child: _Body,
)
```

**`_Body`** — `Padding(24px h)` → `Column`:
- `Spacer()`
- `Text('Bem-vindo')` — `headlineLarge`, `bold`
- `SizedBox(4)`
- `Text('Entre na sua conta para continuar')` — `bodyMedium`, `onSurfaceVariant`
- `SizedBox(32)`
- `TextFieldWidget(hint: 'E-mail', keyboardType: emailAddress)`
- `SizedBox(16)`
- `TextFieldWidget(hint: 'Senha', obscureText: true, inputAction: done)`
- `SizedBox(8)`
- `Align(centerRight)` → `ButtonWidget.text('Esqueci minha senha', onTap: null)`
- `Spacer()`

**`_Bottom`** — `Padding(24px h, 16px v)` → `Column`:
- `ButtonWidget.elevated('Entrar', isLoading: status == loading, onTap: SubmitPressed)`
- `SizedBox(12)`
- `Row(center)`: `Text('Ainda não tem uma conta? ')` + `ButtonWidget.text('Criar conta', onTap: null)`

---

## Rota

`AppRoutes.signIn`: path `/sign-in`, regex `^/sign-in$`.

`SignInLocation`: navega para `HomeLocation(root: true, replace: true)` ao sucesso.

`SplashLocation`: durante desenvolvimento, navega para `SignInLocation` (substituindo `HomeLocation`).

---

## Decisões

| Decisão | Escolha | Motivo |
|---|---|---|
| Widget base da screen | `StatelessWidget + Consumer` | Regra do projeto — nunca `ConsumerWidget` |
| `onSuccess` via callback | Sim | Mesma convenção da `SplashScreen`; separa navegação da lógica |
| Provider do repositório | `keepAlive: true` | Singleton — autenticação é shared state |
| `ref.read` no `_submit` | Sim | É uma ação, não uma observação reativa |
