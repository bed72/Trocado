# Proposal — account-edit-and-delete

## Why

O usuário hoje **não consegue ver, editar nem excluir** os próprios dados de conta no Trocado. O `UserModel` é carregado no boot e usado apenas para saudação na Home (avatar com inicial + greeting). Não há tela de perfil, nem caminho de saída para gestão da conta — o único acesso a "Conta" pelo menu Settings é o item "Dados pessoais", que hoje aponta para `() {}` (no-op em `lib/src/presentation/ui/settings/locations/settings_location.dart:18`).

Sem essa peça, o usuário fica preso ao que cadastrou no sign-up — não consegue corrigir nome/email, ajustar dados pessoais, nem excluir a conta. Para um app de finanças pessoais isso é UX inaceitável e bloqueia conformidade com LGPD (direito de retificação e direito ao apagamento).

A feature completa de **Edição e Exclusão de Conta** será entregue de forma incremental — esta change vai ser editada conforme as próximas partes forem implementadas. A primeira parte (esta proposal) entrega apenas o **scaffold de navegação**: as duas portas de entrada (avatar da Home e item "Dados pessoais" em Settings) levam o usuário a uma `ProfileScreen` vazia (apenas título e descrição, no padrão de `NotificationsScreen`).

Partes futuras (a serem adicionadas a esta mesma change):

- **Parte 2** — exibição dos dados atuais do usuário na `ProfileScreen` (provider/notifier de leitura).
- **Parte 3** — formulário de edição de dados pessoais (PATCH no backend).
- **Parte 4** — atualização do label do botão de exclusão (renome para `'Excluir conta'`) sem dialog inline.
- **Parte 5** — exclusão definitiva via API (`DELETE /api/v1/me`) em screen dedicada com re-confirmação por senha.
- **Parte 6** — edição real de nome/senha via `PATCH /api/v1/me` com `AsyncNotifier` em ambas as subfeatures, toast genérico em falha e navegação automática de volta para `ProfileDetailsScreen` no sucesso. A `ProfilePasswordScreen` é refeita com 2 campos (`Senha atual` + `Nova senha`), sem confirmação.

## What

### Parte 1 — Scaffold de navegação (esta entrega)

#### Nova rota e feature `profile`

- **`lib/app_route.dart`**: nova entrada `AppRoutes.profile` (`path: '/profile'`, `name: 'profile-route'`, regex `^/profile$`), incluída em `_all`.
- **`lib/src/presentation/ui/profile/screens/profile_screen.dart`**: `StatelessWidget` puro espelhando `NotificationsScreen` — `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + Padding 16 + Column com `ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.')` + `Expanded(Placeholder())`.
- **`lib/src/presentation/ui/profile/locations/profile_location.dart`**: `ProfileLocation extends Location` no padrão de `NotificationsLocation` — `path = AppRoutes.profile.path`, `pageBuilder = (_) => screenPage(const ProfileScreen())`.

#### Tornar avatar da Home clicável

- **`lib/src/presentation/ui/home/widgets/home_avatar_widget.dart`**: aceita novo parâmetro `final VoidCallback? onTap;` e envolve o `Container` em `BounceWidget.withOnPress(onPress: onTap, child: <container>)`. Quando `onTap == null`, o `BounceWidget.withOnPress` recebe `null` e não dispara animação nem callback.
- **`lib/src/presentation/ui/home/widgets/home_app_bar_widget.dart`**: ganha `final VoidCallback navigateToProfile;` (named, required) e propaga para `HomeAvatarWidget(onTap: navigateToProfile)`.
- **`lib/src/presentation/ui/home/screens/home_screen.dart`**: ganha `final VoidCallback navigateToProfile;` (named, required) e propaga para `HomeAppBarWidget`.

#### Wiring de navegação nas Locations

- **`lib/src/presentation/ui/home/locations/home_location.dart`**: importa `ProfileLocation` e injeta `navigateToProfile: () => context.navigate(ProfileLocation())` ao construir `HomeScreen`.
- **`lib/src/presentation/ui/settings/locations/settings_location.dart`**: importa `ProfileLocation` e troca `onEditProfile: () {}` por `onEditProfile: () => context.navigate(ProfileLocation())`.

### Parte 2 — Listagem dos campos editáveis (Instagram-style)

A `ProfileScreen` deixa de ser placeholder e vira a tela de **listagem dos campos editáveis**, no estilo Instagram (avatar grande centralizado + lista de campos navegáveis):

#### Promoção do `userProvider` para escopo cross-feature

- `lib/src/presentation/ui/home/notifiers/user_notifier.dart` (e `.g.dart`) **movem** para `lib/src/presentation/notifiers/user_notifier.dart`. O provider deixa de ser exclusivo da feature Home — passa a ser dado global do usuário logado, consumível por qualquer feature.
- Imports atualizados em: `home_screen.dart`, `test/src/presentation/providers/user_notifier_test.dart`.

#### Promoção do avatar para widget compartilhado

- `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart` **renomeia e move** para `lib/src/presentation/widgets/avatar/avatar_widget.dart`, virando `AvatarWidget` (sem prefixo de feature). API preservada (`name`, `size`, `onTap`).
- `HomeAppBarWidget` atualizado para importar/usar `AvatarWidget`.

#### Novos widgets feature-local em `profile/widgets/`

- `profile_header_widget.dart` — `AvatarWidget` grande (size 96) centralizado + `Text(user.name)` em `titleLarge bold` + `Text(user.email)` em `bodyMedium onSurfaceVariant`.
- `profile_field_item_widget.dart` — Row com label (Expanded) + chevron right, dentro de `SizedBox(height: 56)`. Quando `enabled: false`: texto cinza `onSurfaceVariant`, sem chevron, sem `BounceWidget` (não-tappable).
- `profile_fields_card_widget.dart` — container arredondado com `outlineVariant` border, dividers entre filhos (espelha `SettingsCardWidget` sem promovê-lo — mantém encapsulamento de feature).
- `profile_delete_account_widget.dart` — `ButtonWidget.elevated` width full com ícone `Icons.delete_outline` e label `'Apagar conta'`. A natureza destrutiva é comunicada exclusivamente pelo dialog de confirmação (descrição explícita de irreversibilidade); o botão segue o padrão visual de `SettingsLogoutWidget`.

#### `ProfileScreen` consumindo `userProvider`

- Mantém o `ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.')` no topo (herdado da Parte 1) e adiciona o conteúdo abaixo.
- `Consumer` interno faz `ref.watch(userProvider)` e renderiza switch sobre `AsyncValue<UserModel>`:
  - `AsyncLoading` → `Skeletonizer` envolvendo o layout success com placeholders.
  - `AsyncError(:final error)` → `Center` com mensagem do failure + botão `'Tentar novamente'` (`ref.invalidate(userProvider)`).
  - `AsyncData(:final value)` → `ScreenHeaderWidget` + `ProfileHeaderWidget(user: value)` + `ProfileFieldsCardWidget(items: [...])` (3 itens) + `Spacer` + `ProfileDeleteAccountWidget(onTap: ...)` no rodapé.
- 3 itens no card: `'Nome'` (enabled, onTap no-op), `'E-mail'` (disabled), `'Senha'` (enabled, onTap no-op). Os onTap dos campos editáveis são placeholders nesta parte — Parte 3 vai ligá-los aos forms.
- Click em "Apagar conta" → `showConfirmDialog(title: 'Apagar conta', description: 'Esta ação é irreversível. Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.', confirmLabel: 'Apagar')` → no-op se confirmado (Parte 5 plugará a chamada real). _Histórico: a Parte 4 substituiu este dialog por navegação direta para a `ProfileDeleteScreen`._

### Parte 3 — UI dos formulários de edição (nome e senha)

Nesta parte a `profile/` ganha duas telas de form (nome e senha) com **apenas UI + validações** — sem lógica de API, sem repository. A integração com PATCH do backend fica para a Parte 6.

#### Reorganização da feature `profile/` em subdiretórios (espelho de `authentication/`)

```
profile/
  details/        ← listing das Partes 1 e 2 (renomeado)
    screens/      → profile_details_screen.dart    (era profile_screen.dart)
    locations/    → profile_details_location.dart  (era profile_location.dart)
    widgets/      → profile_header, field_item, fields_card, delete_account
  name/
    screens/, locations/, notifiers/, validators/
  password/
    screens/, locations/, notifiers/, validators/
```

Renomes de classe:
- `ProfileScreen` → `ProfileDetailsScreen`
- `ProfileLocation` → `ProfileDetailsLocation`

A rota `/profile` continua mapeada em `ProfileDetailsLocation` — `HomeLocation` e `SettingsLocation` apenas atualizam imports e nome da classe; o caminho não muda.

#### Novas rotas

- `AppRoutes.profileName` → `/profile/name` (regex `^/profile/name$`).
- `AppRoutes.profilePassword` → `/profile/password` (regex `^/profile/password$`).

#### Subfeature `name/`

- **Validator feature-local** `name/validators/name_validation.dart` — `NameValidation implements Validation<String>`. Min 1 (vazio → `'Nome obrigatório'`), max 128 (>128 → `'Nome deve ter no máximo 128 caracteres'`). Trim aplicado antes da checagem.
- `name/validators/profile_name_form_validator.dart` — `ProfileNameFormValidator` recebendo `NameValidation` via construtor; método `call(state)` retorna `({state, isValid})`.
- `name/notifiers/profile_name_state.dart` — `final String name;` + `final String? nameFailure;` + `copyWith` com `bool clearNameFailure`.
- `name/notifiers/profile_name_intent.dart` — sealed `ProfileNameIntent` com `NameChanged(value)` + `SubmitPressed()`.
- `name/notifiers/profile_name_notifier.dart` — `AsyncNotifier<ProfileNameState>` com `Future<ProfileNameState> build()` async que faz `await ref.watch(userProvider.future)` para pré-preencher `name: user.name`. `dispatch` exhaustivo. `_submit` apenas valida (sem API): se inválido popula failures; se válido, no-op com `// TODO Parte 6`.
- `name/screens/profile_name_screen.dart` — `StatelessWidget` + `Consumer` switch sobre `AsyncValue<ProfileNameState>` (loading / error retry / data com form). Layout: `ScreenHeaderWidget(title: 'Nome', description: 'Atualize o seu nome de exibição.')` + `TextFieldWidget(label: 'Nome', hint: 'Nome', initialValue: state.name, failure: state.nameFailure, inputAction: .done)` + `Spacer` + `ButtonWidget.elevated(label: 'Atualizar')` no rodapé.
- `name/locations/profile_name_location.dart` — `ProfileNameLocation extends Location`, sem parâmetros.

#### Subfeature `password/`

- **Sem validator novo** — reusa `PasswordValidation` compartilhado (`presentation/validators/password_validation.dart`, min 8).
- `password/validators/profile_password_form_validator.dart` — `ProfilePasswordFormValidator` espelhando `PasswordResetConfirmFormValidator`: valida `newPassword` via `PasswordValidation`; `confirmPassword` deve coincidir com `newPassword` (`'As senhas não coincidem'`).
- `password/notifiers/profile_password_state.dart` — `newPassword`, `confirmPassword`, `obscureNewPassword` (default true), `obscureConfirmPassword` (default true), `newPasswordFailure`, `confirmPasswordFailure`.
- `password/notifiers/profile_password_intent.dart` — sealed com `NewPasswordChanged`, `ConfirmPasswordChanged`, `NewPasswordVisibilityToggled`, `ConfirmPasswordVisibilityToggled`, `SubmitPressed`.
- `password/notifiers/profile_password_notifier.dart` — `Notifier<ProfilePasswordState>` (sync, sem dependência async). `_submit` valida e faz no-op com `// TODO Parte 6`.
- `password/screens/profile_password_screen.dart` — espelha `PasswordResetConfirmScreen` (dois `TextFieldWidget` com toggle de visibilidade) com title `'Senha'`, description `'Crie uma nova senha para sua conta.'`, labels `'Nova senha'` / `'Confirmar senha'`, botão `'Atualizar'`.
- `password/locations/profile_password_location.dart` — `ProfilePasswordLocation extends Location`, sem parâmetros.

#### Wiring em `details/`

- `ProfileDetailsScreen` ganha `final VoidCallback onEditName;` e `final VoidCallback onEditPassword;` (named-required).
- Os itens "Nome" e "Senha" do card recebem esses callbacks no `onTap` (item "E-mail" continua disabled).
- `ProfileDetailsLocation` injeta:
  ```dart
  onEditName: () => context.navigate(ProfileNameLocation()),
  onEditPassword: () => context.navigate(ProfilePasswordLocation()),
  ```
  `ProfileDetailsLocation` é o único lugar autorizado a importar `ProfileNameLocation`/`ProfilePasswordLocation` — exceção narrada (Locations compondo navegação) preservada também entre subfeatures de `profile/`.

#### Providers de form validator

Adicionar em `lib/src/main/providers/validators_provider.dart`:

- `profileNameFormValidatorProvider` → `ProfileNameFormValidator(nameValidation: NameValidation())`.
- `profilePasswordFormValidatorProvider` → `ProfilePasswordFormValidator(passwordValidation: PasswordValidation())`.

### Parte 4 — Renome do botão de exclusão para "Excluir conta"

A `ProfileDetailsScreen` mantém o **botão único** de exclusão criado na Parte 2, apenas atualizando o label. Não há fluxo de desativação — a conta tem um único caminho de saída (delete definitivo, plugado na Parte 5).

- `profile_delete_account_widget.dart` (com `ProfileDeleteAccountWidget`) preserva a API original: `final VoidCallback onTap;` (named-required).
- Layout permanece `Container(width: .infinity, padding: .only(top: 16))` envolvendo `ButtonWidget.elevated(label: 'Excluir conta', onTap: onTap)` — full-width, sem ícone.
- O botão **não** abre `showConfirmDialog` na própria detail; o `onTap` apenas dispara navegação para `ProfileDeleteScreen` (Parte 5), onde o usuário re-digita a senha e confirma a ação.

A natureza destrutiva é comunicada exclusivamente pela copy da `ProfileDeleteScreen` e pelo `showConfirmDialog` final disparado lá dentro.

### Parte 5 — Exclusão definitiva via API

`DELETE /api/v1/me` exclui a conta de forma atômica e irreversível. O backend exige body `{ refresh, password }`: a senha reautentica a operação (gate de segurança extra contra exclusão acidental, mesmo o usuário já estando autenticado por Bearer token) e o refresh token é blacklistado simultaneamente. A operação anonimiza PII (email vira `deleted-{pk}@trocado.invalid`, name `"Deleted User"`), seta `deleted_at` (a row some do active manager) e dissolve qualquer couple ativo. Resposta de sucesso: 204 sem body. Resposta de falha: envelope `FailureResponse` padrão; o caso conhecido é `field: 'password'`, `code: 'invalid_credentials'`, `message: 'Invalid credentials.'`.

Fluxo UX: o botão "Excluir conta" da `ProfileDetailsScreen` navega para uma `ProfileDeleteScreen` dedicada (criada na Parte 4). A tela tem título, descrição de irreversibilidade, e-mail readonly (lido do `userProvider`, apenas reforço visual de "qual conta vai sumir") e campo de senha. O `showConfirmDialog` final ("Tem certeza?") é disparado pelo botão "Excluir" antes do dispatch — uma porta de confirmação extra após a senha digitada.

Após sucesso, o redirect para `SignInLocation` é delegado ao `AuthenticationInterceptor` existente: `ref.invalidate(userProvider)` → próxima request 401 (refresh blacklistado e usuário fora do active manager) → refresh fail → `_onUnauthenticated` → SignIn.

#### Passo 0 — Extração do `PasswordFieldWidget` compartilhado

O bloco "obscure + trailingIcon `visibility_outlined`/`visibility_off_outlined` + onTrailingIconTap" se repete em vários call-sites (sign_in, sign_up, password_reset_confirm ×2, profile_password ×2). Antes de adicionar o consumidor da delete, extrair `PasswordFieldWidget` para `lib/src/presentation/widgets/fields/password_field_widget.dart` e migrar os call-sites existentes.

API:

```dart
class PasswordFieldWidget extends StatelessWidget {
  final String hint;
  final String label;
  final bool obscure;
  final String? failure;
  final String? initialValue;
  final TextInputAction? inputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback onToggle;
}
```

Internamente delega ao `TextFieldWidget` aplicando `obscureText: obscure`, `hideTrailingIconWhenEmpty: true`, `trailingIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined`, `onTrailingIconTap: onToggle`. Notifiers/states/intents existentes **não mudam** — `obscure*` continua no state; o intent `...VisibilityToggled` continua sendo a fonte da verdade.

#### Camadas

- **Domain** (`lib/src/domain/repositories/interface_user_repository.dart`): `Future<Either<Failure, void>> delete({required String password});`. A senha é o único primitivo de domínio que atravessa a fronteira — o refresh token é detalhe de implementação que o repositório resolve internamente.
- **Infrastructure** (`lib/src/infrastructure/datasources/remote/remote_user_data_source.dart`):
  - `IRemoteUserDataSource` ganha `Future<Either<FailureResponse, void>> delete({required String refresh, required String password});` recebendo primitivos.
  - Implementação: `_client.delete(parameter: Requests(EndpointKey.me.path, body: {'refresh': refresh, 'password': password}))` → `response.either(FailureResponse.fromJson, (_) {})`. Body inline, sem DTO (mesmo padrão do antigo deactivate).
- **Data** (`lib/src/data/repositories/user_repository.dart`):
  - `UserRepository` aceita `ILocalTokenDataSource tokenDataSource` + `IRemoteUserDataSource userDataSource` via construtor (espelha `AuthenticationRepository`).
  - `delete({password})` lê `tokens.refresh` via `_tokenDataSource.get()`. Se `refresh == null` retorna `Left(UnknownFailure())` (defensivo, sem chamar a API). Caso contrário propaga para `_userDataSource.delete(refresh: tokens.refresh!, password: password)` e mapeia via `data.either((failure) => failure.toFailure(), (_) {})`.
  - `userRepositoryProvider` em `repositories_provider.dart` injeta `localTokenDataSourceProvider`.

#### Subfeature `profile/delete/`

Estrutura espelhando `profile/name/` e `profile/password/`:

```
profile/delete/
  notifiers/
    profile_delete_state.dart
    profile_delete_intent.dart
    profile_delete_notifier.dart
  validators/
    profile_delete_form_validator.dart
  screens/
    profile_delete_screen.dart
  locations/
    profile_delete_location.dart
```

- **State**: `ProfileDeleteStatus` enum (`initial/loading/success/failure`) + `password`, `obscurePassword` (default true), `passwordFailure`, `status`, `message`. `copyWith` com `clearPasswordFailure`.
- **Intent (sealed)**: `PasswordChanged(value)`, `PasswordVisibilityToggled()`, `SubmitPressed()`.
- **Notifier**: sync `Notifier<ProfileDeleteState>`. `build()` retorna `const ProfileDeleteState()` após `ref.watch` em `userRepositoryProvider` e `profileDeleteFormValidatorProvider`. `_submit()`:
  1. Valida via `_validator(this.state)` e propaga state validado.
  2. Se `!isValid`, retorna.
  3. Early-return se já estiver em loading (re-entrancy guard).
  4. `state.status = loading`.
  5. `await _repository.delete(password: this.state.password)`.
  6. **Right(_)**: `ref.invalidate(userProvider)` + `state.status = success`. Interceptor cuida do redirect.
  7. **Left(failure)**: `state.status = failure` com `state.message = failure.message`.
- **Validator**: `ProfileDeleteFormValidator` reusando `PasswordValidation` (min 8). Provider em `validators_provider.dart`.
- **Screen**: `StatelessWidget` + `Consumer` interno (jamais `ConsumerWidget`). Layout — `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + `CustomScrollView` (anti-overflow no teclado) + Padding 16 + Column(spacing 24, crossAxisAlignment .start):
  - `ScreenHeaderWidget(title: 'Excluir conta', description: 'Esta ação é irreversível.\nConfirme com sua senha para excluir definitivamente sua conta e todos os dados associados.')`.
  - `PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', obscure: state.obscurePassword, onToggle: ..., failure: state.passwordFailure, onChanged: ..., inputAction: .done)`.
  - `Spacer`.
  - `SizedBox(width: .infinity, child: ButtonWidget.elevated(label: 'Excluir', isLoading: state.status == .loading, onTap: ...))`.
  
  `ref.listen(profileDeleteProvider, ...)` mostra `showToastWidget(type: failure, title: 'Opps', description: state.message)` somente em transições para failure. Sucesso é silencioso.
  
  `_submit(context, notifier)`:
  - `hideKeyboard()`.
  - `await showConfirmDialog(context, title: 'Excluir conta', confirmLabel: 'Excluir', description: 'Esta ação é irreversível.\n\n - Todos os seus dados serão apagados;\n - Você não poderá recuperar sua conta.')`.
  - Se confirmed → `notifier.dispatch(const SubmitPressed())`.
- **Location**: `ProfileDeleteLocation extends Location`, sem parâmetros, `path = AppRoutes.profileDelete.path`, `pageBuilder = (_) => screenPage(const ProfileDeleteScreen())`.

#### Rota nova

`AppRoutes.profileDelete` → `/profile/delete` (regex `^/profile/delete$`), incluída em `_all`.

#### Wiring na detail

- `ProfileDetailsScreen` ganha `final VoidCallback onDelete;` named-required. Não há `_confirmDelete` na detail — o dialog de confirmação fica na `ProfileDeleteScreen`. O callback é repassado direto ao `ProfileDeleteAccountWidget(onTap: onDelete)`.
- `ProfileDetailsLocation` injeta `onDelete: () => context.navigate(ProfileDeleteLocation())` (exceção narrada: Locations compondo navegação).

### Parte 6 — Edição real de nome/senha (PATCH)

`PATCH /api/v1/me` atualiza a conta do usuário autenticado. O backend expõe **um único endpoint** com body parcial: `{name?, current_password?, new_password?}` — campos que vierem são atualizados. Resposta de sucesso: `200` com `UserResponse {id, name, email}`. Resposta de falha: envelope `FailureResponse` padrão (`{errors: [{field, message, code}]}`).

Substituir os `// TODO Parte 6` em `profile_name_notifier._submit()` e `profile_password_notifier._submit()` por chamadas reais ao `IUserRepository`. A tela de senha é **refeita** — passa a ter apenas dois campos ("Senha atual" + "Nova senha"), sem confirmação (a confirmação `confirm_password` deixa de existir porque a API exige `current_password` em vez disso, e exigir três campos de senha é hostil ao usuário).

Fluxo UX:

- **Nome**: usuário entra na `ProfileNameScreen` (pré-preenchida via `userProvider`), edita, tap "Atualizar" → loading no botão → 200 → toast silencioso, navega de volta para `ProfileDetailsScreen` (que re-lê o `userProvider` invalidado e mostra o novo nome).
- **Senha**: idem, mas com 2 campos novos. Sem toast de sucesso, sem dialog de confirmação extra (a senha atual já é a porta de segurança).
- **Falha** (em ambas): toast genérico `'Opps'` com `Failure.message` via `ref.listen` na transição para `status: .failure` (mesmo padrão do `ProfileDeleteScreen`).

#### Camadas

- **Domain** (`lib/src/domain/repositories/interface_user_repository.dart`): adiciona dois métodos que devolvem `UserModel` na ramificação `Right`:
  - `Future<Either<Failure, UserModel>> updateName({required String name});`
  - `Future<Either<Failure, UserModel>> updatePassword({required String currentPassword, required String newPassword});`
  Domínio expressa **intenção** (atualizar nome vs atualizar senha); o fato de ambas hits o mesmo endpoint é detalhe de infra.
- **Infrastructure** (`lib/src/infrastructure/datasources/remote/remote_user_data_source.dart`):
  - `IRemoteUserDataSource` ganha um único método `Future<Either<FailureResponse, UserResponse>> update({String? name, String? currentPassword, String? newPassword});` — todos os parâmetros opcionais, refletindo a forma da API.
  - Implementação: `_client.patch(parameter: Requests(EndpointKey.me.path, body: {if (name != null) 'name': name, if (currentPassword != null) 'current_password': currentPassword, if (newPassword != null) 'new_password': newPassword}))` → `response.either(FailureResponse.fromJson, UserResponse.fromJson)`. Body inline com spread condicional (sem DTO, espelha o padrão do `delete`).
  - `UserResponse` já existe (`{id, name, email}`) — sem mudança.
- **Data** (`lib/src/data/repositories/user_repository.dart`):
  - `UserRepository.updateName({name})` chama `_userDataSource.update(name: name)` e mapeia via `data.either((failure) => failure.toFailure(), (response) => response.toModel())`. Reusa `UserResponseExtension.toModel()` e `FailureResponseExtension.toFailure()` existentes.
  - `UserRepository.updatePassword({currentPassword, newPassword})` idem, chamando `_userDataSource.update(currentPassword: ..., newPassword: ...)`.

#### Notifiers — Async em ambos, status interno

Tanto `ProfileNameNotifier` (já é `AsyncNotifier`) quanto `ProfilePasswordNotifier` (migra de `Notifier` síncrono para `AsyncNotifier`) seguem o mesmo padrão de submit:

```dart
Future<void> _submit() async {
  final (state: validated, :isValid) = _validator(this.state.value!);
  this.state = AsyncData(validated);

  if (!isValid) return;
  if (validated.status == .loading) return; // re-entrancy guard

  this.state = AsyncData(validated.copyWith(status: .loading));

  final data = await _repository.updateName(name: validated.name);

  data.fold(
    (failure) => state = AsyncData(
      state.value!.copyWith(status: .failure, message: failure.message),
    ),
    (_) {
      ref.invalidate(userProvider);
      state = AsyncData(state.value!.copyWith(status: .success));
    },
  );
}
```

O `AsyncValue<T>` externo cobre o build phase (preload do `userProvider` no name; sem nada para preload no password — `build()` é `async` apenas para alinhar o padrão). O submit phase é representado **dentro** do `T` via `enum XxxStatus { initial, loading, success, failure }` + `String message`. Loading aparece no botão (`ButtonWidget.elevated(isLoading: state.status == .loading)`), exatamente como no `ProfileDeleteScreen`.

#### Reshape da `ProfilePasswordScreen`

- **Drop**: `confirmPassword`, `confirmPasswordFailure`, `obscureConfirmPassword` no state; `ConfirmPasswordChanged`/`ConfirmPasswordVisibilityToggled` nos intents; validação `confirmPassword != newPassword` no validator; segundo `PasswordFieldWidget` ("Confirmar senha") na screen.
- **Add**: `currentPassword`, `currentPasswordFailure`, `obscureCurrentPassword`, `message`, `status` no state; `CurrentPasswordChanged`/`CurrentPasswordVisibilityToggled` nos intents; validação `PasswordValidation` no `currentPassword`; primeiro `PasswordFieldWidget` ("Senha atual") na screen.
- **Mantém**: `newPassword`, `newPasswordFailure`, `obscureNewPassword` no state; `NewPasswordChanged`/`NewPasswordVisibilityToggled`/`SubmitPressed` nos intents; segundo `PasswordFieldWidget` ("Nova senha").

#### Navegação de volta — callback `onSuccess`

`ProfileNameScreen` e `ProfilePasswordScreen` ganham `final VoidCallback onSuccess;` named-required. Locations passam `onSuccess: () => context.pop()` na `ProfileDetailsLocation.pageBuilder`. Em ambas as screens, `ref.listen` dispara `onSuccess()` na transição para `status: .success`. Isso mantém o notifier fora da navegação (CLAUDE.md) e permite que `ProfileDetailsLocation` continue sendo o único lugar que conhece as Locations filhas.

### Parte 6 — referência completa do contrato

**Endpoint**: `PATCH /api/v1/me`

**Headers**: `Authorization: Bearer <access>` (injetado pelo `AuthenticationInterceptor`), `Content-Type: application/json`.

**Body** (todos opcionais — a API aceita atualização parcial):

```json
{
  "name": "Jane Smith",
  "current_password": "OldPassword!123",
  "new_password": "NewSecure!456"
}
```

**Resposta sucesso (200)**:

```json
{
  "id": 1,
  "email": "jane@trocado.app",
  "name": "Jane Smith"
}
```

**Resposta falha**: envelope padrão `FailureResponse`:

```json
{
  "errors": [
    { "field": "current_password", "message": "Senha incorreta.", "code": "invalid_credentials" }
  ]
}
```

O app **não mapeia `field` para failures por campo** — o toast genérico (Opção A) usa apenas `Failure.message` (mesmo padrão de `ProfileDeleteScreen`).

## Scope

### Em escopo (Parte 6 — atual)

- `IUserRepository.updateName({name})` e `IUserRepository.updatePassword({currentPassword, newPassword})` (interface + impl). Ambos devolvem `UserModel` na ramificação `Right`.
- `IRemoteUserDataSource.update({name?, currentPassword?, newPassword?})` (interface + impl) chamando `_client.patch(EndpointKey.me.path)` com body inline (spread condicional, sem DTO) e mapeando para `UserResponse.fromJson`.
- `ProfileNameState` ganha `enum ProfileNameStatus` + campos `status` e `message`. `ProfileNameNotifier._submit` deixa de ser no-op e chama `_repository.updateName(...)` com re-entrancy guard, invalidação de `userProvider` no sucesso e propagação de `Failure.message` na falha.
- `ProfilePasswordState` refeito: drop `confirmPassword`/`confirmPasswordFailure`/`obscureConfirmPassword`; add `currentPassword`/`currentPasswordFailure`/`obscureCurrentPassword` + `enum ProfilePasswordStatus` + `message` + `status`.
- `ProfilePasswordIntent`: substituir `ConfirmPasswordChanged`/`ConfirmPasswordVisibilityToggled` por `CurrentPasswordChanged`/`CurrentPasswordVisibilityToggled`. Manter `NewPasswordChanged`/`NewPasswordVisibilityToggled`/`SubmitPressed`.
- `ProfilePasswordFormValidator`: valida `currentPassword` e `newPassword` via `PasswordValidation`; drop a checagem de match.
- `ProfilePasswordNotifier` migra para `AsyncNotifier` (`Future<ProfilePasswordState> build()`). `_submit` chama `_repository.updatePassword(...)` com re-entrancy guard, invalidação de `userProvider` no sucesso e propagação de `Failure.message` na falha.
- `ProfileNameScreen` e `ProfilePasswordScreen` ganham `final VoidCallback onSuccess;` named-required. `ref.listen` dispara `onSuccess()` em transição para `success` e `showToastWidget(type: failure, title: 'Opps', description: state.message)` em transição para `failure`. `ButtonWidget.elevated` com `isLoading: state.status == .loading`. `ProfilePasswordScreen` é refeita com 2 `PasswordFieldWidget` ("Senha atual" + "Nova senha"), sem o campo de confirmação.
- `ProfileNameLocation` e `ProfilePasswordLocation` aceitam `onSuccess` via construtor. `ProfileDetailsLocation` injeta `onSuccess: () => context.pop()` em ambas.
- Testes:
  - `user_repository_test.dart` — `group('updateName')` (Right + 4 failures) e `group('updatePassword')` (Right + 4 failures), verificando payload PATCH em cada caso.
  - `profile_password_form_validator_test.dart` — redo sem match; cobre empty currentPassword, empty newPassword, ambos válidos.
  - `profile_name_notifier_test.dart` — cenários de submit success/failure/invalid/re-entrant + invalidação do `userProvider` no sucesso.
  - `profile_password_notifier_test.dart` — substituir intents de `Confirm*` por `Current*` + cenários de submit equivalentes ao name + migração para inspeção via `state.value!`.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte; nenhum `// TODO Parte 6` permanece em `lib/`.

### Fora de escopo (Parte 6 — virá em partes futuras)

- **Atualização atômica de nome + senha numa única request** — embora a API aceite, o app dispara cada operação em sua própria screen.
- **Mapeamento de `field` do `FailureResponse` para failures por campo** — decisão tomada para usar toast genérico (Opção A); o `field` é ignorado pelo app.
- **Toast de sucesso** — sucesso é silencioso e a screen volta para `ProfileDetailsScreen` automaticamente.
- **Confirm dialog antes do submit** — a senha atual já é a porta de reautenticação suficiente; não há `showConfirmDialog` extra.
- **Edição de e-mail** — o campo continua disabled (Parte 2); decidir separadamente se/como suportar (exige verificação por link, fluxo distinto).
- **Atualização do avatar/foto** — fora do escopo da change inteira.
- **Validações adicionais** (ex: força da senha além de min 8, listas de senhas vazadas, complexidade) — `PasswordValidation` existente já é a fonte da verdade.

### Em escopo (Parte 5 — atual)

- Extração de `PasswordFieldWidget` em `lib/src/presentation/widgets/fields/password_field_widget.dart`, delegando para `TextFieldWidget`.
- Migração dos 5 call-sites existentes (sign_in_screen, sign_up_screen, password_reset_confirm_screen ×2 campos, profile_password_screen ×2 campos) para `PasswordFieldWidget`. Notifiers/states/intents inalterados.
- `IUserRepository.delete({password})` (interface + impl); repositório lê `refresh` via `ILocalTokenDataSource` e injeta `localTokenDataSourceProvider` em `userRepositoryProvider`.
- `IRemoteUserDataSource.delete({refresh, password})` (interface + impl) chamando `_client.delete(EndpointKey.me.path)` com body inline `{refresh, password}` — sem DTO.
- Nova subfeature `profile/delete/` com state, intent, notifier (`@riverpod` sync `Notifier`), validator, screen e location.
- Nova rota `AppRoutes.profileDelete` em `_all`.
- `ProfileDetailsScreen` ganha `onDelete` named-required. `ProfileDetailsLocation` injeta navegação para `ProfileDeleteLocation`.
- `ProfileDeleteScreen` com header + email readonly (lido do `userProvider` via switch sobre `AsyncValue`, fallback `''`) + campo de senha + botão Excluir; envolto em `CustomScrollView + SliverFillRemaining(hasScrollBody: false)` pra não overflowar com o teclado.
- Showconfirm dialog de "Excluir conta" disparado pelo botão Excluir da `ProfileDeleteScreen` (depois da senha digitada). Confirm despacha `SubmitPressed`.
- Pós-success: `ref.invalidate(userProvider)` + `status: success`. Interceptor 401 → SignIn.
- Pós-failure: toast `'Opps'` com `Failure.message` via `ref.listen`.
- Provider `profileDeleteFormValidatorProvider` em `validators_provider.dart`.
- Testes:
  - `user_repository_test.dart` — `group('delete')` com Right (verificando body `{refresh, password}` no DELETE), refresh-null defensivo, e cada Failure mapeado (Network/NotFound/Server/ValidationFailure com `invalid_credentials`).
  - `profile_delete_form_validator_test.dart` — empty / <8 / valid.
  - `profile_delete_notifier_test.dart` — build inicial, `PasswordChanged` (clear failure), `PasswordVisibilityToggled` isolado, `SubmitPressed` empty/valid/loading-guard, repository failure com message.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.

### Fora de escopo (Parte 5 — virá em partes futuras)

- **Edição real de nome/senha** (PATCH `/api/v1/me`) — Parte 6.
- **Confirmação de e-mail digitada pelo usuário** (estilo GitHub "type your account name") — refresh+password no backend já são porta de segurança suficiente.
- **Toast de sucesso** após delete — silencioso, redirect via interceptor.
- **Testes de widget para `PasswordFieldWidget`** — apenas delega para `TextFieldWidget`; cobertura visual via smoke manual nos call-sites refatorados.

### Em escopo (Parte 4 — atual)

- Atualização do label do botão único de exclusão na `ProfileDetailsScreen` para `'Excluir conta'` (mantendo `ProfileDeleteAccountWidget` da Parte 2).
- `_buildBody` continua recebendo apenas `onDelete` (named-required) — sem callbacks adicionais.
- Sem dialog de confirmação na detail — `onTap` apenas dispara navegação para a screen dedicada de delete (Parte 5).
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.

### Fora de escopo (Parte 4 — virá em partes futuras)

- **Endpoint real** `DELETE /api/v1/me` — Parte 5.
- **`IUserRepository.delete()`** — Parte 5.
- **`ProfileDeleteScreen` dedicada com confirm dialog e toast de falha** — Parte 5.
- **Loading state no botão** durante a chamada de API — Parte 5 (a screen de delete controla seu próprio loading).
- **Mudança visual destrutiva** (Theme override, cor de erro) — mantemos o visual padrão; a destrutividade é comunicada pela copy da `ProfileDeleteScreen` e pelo `showConfirmDialog` final.

### Em escopo (Parte 3 — atual)

- Reorganização de `lib/src/presentation/ui/profile/` em subdiretórios `details/`, `name/`, `password/` (espelho do padrão de `authentication/`).
- Renome `ProfileScreen` → `ProfileDetailsScreen` e `ProfileLocation` → `ProfileDetailsLocation`. Imports em `HomeLocation` e `SettingsLocation` atualizados.
- Novas rotas `AppRoutes.profileName` e `AppRoutes.profilePassword` registradas em `_all`.
- `NameValidation` feature-local em `profile/name/validators/`.
- `ProfileNameFormValidator`, state, intent, notifier (AsyncNotifier reading `userProvider`), screen e location.
- `ProfilePasswordFormValidator` (reusa `PasswordValidation` compartilhado), state, intent, notifier (sync), screen (com toggle de visibilidade dos dois campos) e location.
- `ProfileDetailsScreen` ganha `onEditName` / `onEditPassword` callbacks; `ProfileDetailsLocation` injeta navegação para as novas locations.
- Providers `profileNameFormValidatorProvider` / `profilePasswordFormValidatorProvider` registrados em `validators_provider.dart`; build_runner regenera `.g.dart`.
- Testes unitários de `NameValidation`, `ProfileNameFormValidator`, `ProfilePasswordFormValidator`, `ProfileNameNotifier` (build success + dispatches) e `ProfilePasswordNotifier` (todos os 5 intents).
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.

### Fora de escopo (Parte 3 — virá em partes futuras)

- **Lógica de API real** — `_submit` apenas valida nesta parte; `// TODO Parte 6` marca o ponto de entrada do PATCH.
- **Toast/navegação de feedback pós-submit** — sem simulação de sucesso ou falha conforme decisão acordada; o usuário fica na tela após submit válido sem feedback visual além do estado limpo do form.
- **Endpoint `PATCH /api/v1/me`** — Parte 6. **Endpoint `DELETE /api/v1/me`** — Parte 5.
- **Toggle de visibilidade no nome** — não tem (campo não-secreto).
- **Validação de "senha atual"** antes de trocar — fora do escopo desta parte; será reavaliada na Parte 6 conforme contrato do backend.
- **Estados de loading/erro** no notifier de nome além do `AsyncValue` natural — Parte 6 adicionará `status: loading/success/failure` quando houver chamada de API.
- **Testes do caminho de erro do `ProfileNameNotifier`** (userProvider em `AsyncError`) — Parte 6, junto com a chamada real de API, vai estabilizar o caminho de erro completo.

### Em escopo (Parte 2 — atual)

- Mover `user_notifier.dart`/`.g.dart` para `lib/src/presentation/notifiers/`; atualizar imports em Home e teste.
- Mover/renomear `HomeAvatarWidget` para `lib/src/presentation/widgets/avatar/avatar_widget.dart` como `AvatarWidget`; atualizar `HomeAppBarWidget`.
- Criar 4 widgets em `lib/src/presentation/ui/profile/widgets/`: header, field item, fields card, delete account button.
- Atualizar `ProfileScreen` para consumir `userProvider` via `Consumer` com switch sobre `AsyncValue` (loading skeletonizer / error retry / data layout completo).
- Wiring do `showConfirmDialog` destrutivo no botão de apagar conta — pós-confirmação no-op por ora.
- onTap dos itens "Nome" e "Senha" é no-op por ora.
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte (incluindo `user_notifier_test.dart` com novo path).

### Fora de escopo (Parte 2 — virá em partes futuras)

- **Tela de form** para edição de nome/senha (Parte 3).
- **Endpoints e repository** de update/delete de user (Partes 5 e 6).
- **Lógica real do delete** (Parte 5).
- **Promoção de `SettingsItemWidget`/`SettingsCardWidget`** para shared — profile cria os seus próprios widgets equivalentes para preservar encapsulamento.
- **Mudança visual no avatar da Home** — só renomeia/move o widget; a aparência permanece idêntica.
- **Refactor de `HomeScreen`** para qualquer outra coisa além do import atualizado.

### Em escopo (Parte 1)

- Nova rota `AppRoutes.profile` e arquivo `app_route.dart` atualizado.
- Pasta nova `lib/src/presentation/ui/profile/` com subpastas `screens/` e `locations/`.
- `ProfileScreen` minimalista (apenas header — sem state, sem lógica de negócio).
- `ProfileLocation` simples (sem callbacks injetados, sem parâmetros).
- `HomeAvatarWidget` aceitando `onTap` opcional via `BounceWidget.withOnPress`.
- `HomeAppBarWidget` e `HomeScreen` com novo named parameter `navigateToProfile` (required).
- `HomeLocation` e `SettingsLocation` ajustadas para navegar à `ProfileLocation`.
- Testes de regressão dos widgets afetados (`home_avatar_widget` se houver testes; `home_app_bar_widget` se houver testes; nada novo se não houver).
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.

### Fora de escopo (Parte 1 — virá em partes futuras)

- **Notifier, state, intent ou repository** para a feature `profile` — apenas scaffold.
- **Leitura/exibição dos dados do usuário** na `ProfileScreen` (Parte 2).
- **Formulário de edição** (Parte 3).
- **Exclusão de conta** (Parte 5).
- **Testes de widget para `ProfileScreen`** — a tela é só placeholder; testes vêm quando houver comportamento (Parte 2+).
- **Mudanças no backend** — endpoints de update/delete de user serão validados nas partes 3 e 4.
- **Refactor de `userProvider`** — fica como está; eventual unificação ou divisão será decidida na Parte 2.
- **Logout** — já existe em Settings; não muda.
- **Avatar com foto** — hoje é só inicial; mudança visual fora de escopo.
- **Indicador visual de "tap target" no avatar** (cursor pointer, ripple custom) — `BounceWidget.withOnPress` já dá feedback de toque suficiente.
