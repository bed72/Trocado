# Design: home-app-bar

## Regra de dependência

```
domain ← data ← infrastructure
domain ← presentation
main → tudo
```

Nenhuma camada viola essa regra. `UserModel` já existe em `domain/models/`.

---

## infrastructure/

### EndpointKey

Adicionar entrada:

```dart
me('/api/v1/me'),
```

Não é público — requer token de autenticação.

### MeResponse

`lib/src/infrastructure/clients/http/responses/me_response.dart`

```dart
final class MeResponse {
  final int id;
  final String email;
  final String name;
  final String? avatar;

  const MeResponse({required this.id, required this.email, required this.name, this.avatar});

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    avatar: json['avatar'] as String?,
  );
}
```

### IRemoteUserDataSource + RemoteUserDataSource

`lib/src/infrastructure/datasources/remote/remote_user_data_source.dart`

Interface:
```dart
abstract interface class IRemoteUserDataSource {
  Future<Either<FailureResponse, MeResponse>> me();
}
```

Implementação chama `GET EndpointKey.me.path` via `IHttpClient` e deserializa com `FailureResponse.fromJson` / `MeResponse.fromJson`.

---

## data/

### MeResponseExtension

`lib/src/data/extensions/me_response_extension.dart`

```dart
extension MeResponseExtension on MeResponse {
  UserModel toModel() => UserModel(
    id: id,
    email: email,
    name: name,
    avatar: avatar,
  );
}
```

### UserRepository

`lib/src/data/repositories/user_repository.dart`

Implementa `IUserRepository`. Chama `_dataSource.me()` e faz fold:
- Left: `FailureResponseExtension.toFailure()`
- Right: `MeResponseExtension.toModel()`

---

## domain/

### IUserRepository

`lib/src/domain/repositories/interface_user_repository.dart`

```dart
abstract interface class IUserRepository {
  Future<Either<Failure, UserModel>> me();
}
```

---

## presentation/

### UserNotifier

`lib/src/presentation/screens/home/user_notifier.dart`

`AsyncNotifier<UserModel>` — busca dados no `build()`:

```dart
@riverpod
final class UserNotifier extends _$UserNotifier {
  late IUserRepository _repository;

  @override
  Future<UserModel> build() async {
    _repository = ref.watch(userRepositoryProvider);
    return await _fetchUser();
  }

  Future<UserModel> _fetchUser() async {
    final data = await _repository.me();
    return data.fold(
      (failure) => throw failure,
      (user) => user,
    );
  }
}
```

> Nota: o Notifier lança a `Failure` para que o `AsyncValue.error` seja capturado na UI — nenhuma tela de erro separada por enquanto.

### Widgets

Todos em `lib/src/presentation/widgets/home/`:

#### AvatarWidget

`avatar_widget.dart` — `StatelessWidget`

- Recebe `String? avatarUrl` e `double size`
- Se `avatarUrl != null`: `CircleAvatar` com `NetworkImage`
- Se `avatarUrl == null`: `CircleAvatar` com `Icon(Icons.person)`

#### GreetingWidget

`greeting_widget.dart` — `StatelessWidget`

- Recebe `String name`
- Computa o texto de saudação baseado em `DateTime.now().hour`:
  - 5–11 → "Bom dia"
  - 12–17 → "Boa tarde"
  - 18–23 → "Boa noite"
  - 0–4 → "Isso são horas..."
- Exibe coluna: texto da saudação (estilo smaller, muted) + nome do usuário (estilo titleMedium, bold)

#### HomeAppBarWidget

`home_app_bar_widget.dart` — `StatelessWidget`, implementa `PreferredSizeWidget`

- Recebe `AsyncValue<UserModel> userState`, `VoidCallback onNotification`, `VoidCallback onSettings`
- Usa `Skeletonizer` envolvendo o conteúdo quando `userState` é `AsyncLoading`
- Layout: `Row` com `AvatarWidget` + `GreetingWidget` à esquerda, `IconButton`s à direita
- No estado de loading: exibe dados de placeholder para o shimmer renderizar

### HomeScreen

Atualizar `lib/src/presentation/screens/home_screen.dart`:

- Adicionar `Consumer` interno para observar `userNotifierProvider`
- Passar `AsyncValue<UserModel>` para `HomeAppBarWidget`
- `onNotification` e `onSettings` recebidos como `VoidCallback` via construtor (a navegação fica na Location)

---

## main/

### data_sources.provider.dart

Adicionar `remoteUserDataSourceProvider` usando `RemoteUserDataSource` com `httpClientProvider`.

### repositories_provider.dart

Adicionar `userRepositoryProvider` usando `UserRepository` com `remoteUserDataSourceProvider`.
