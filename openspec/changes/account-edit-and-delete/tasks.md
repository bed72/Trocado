# Tasks — account-edit-and-delete

> Esta change é **incremental**. A Parte 1 (scaffold de navegação) está descrita abaixo. Partes 2+ serão adicionadas como novas seções (`## Parte 2`, `## Parte 3`, etc.) conforme forem implementadas.

---

## Parte 1 — Scaffold de navegação

Ordem fixa: rota → feature `profile` (screen + location) → tornar avatar clicável → propagar callback em widgets/screen da Home → wiring nas Locations → verificação.

### 1. Rota

- [ ] 1.1 Adicionar `AppRoutes.profile` em `lib/app_route.dart`:
  ```dart
  static final profile = AppRoutes._(
    path: '/profile',
    name: 'profile-route',
    regex: RegExp(r'^/profile$'),
  );
  ```
- [ ] 1.2 Adicionar `profile` ao array `_all` em `lib/app_route.dart` (ordem: junto com `settings`/`notifications`).

### 2. Feature `profile`

- [ ] 2.1 Criar pasta `lib/src/presentation/ui/profile/screens/`.
- [ ] 2.2 Criar `lib/src/presentation/ui/profile/screens/profile_screen.dart`:
  - `StatelessWidget` puro com `const ProfileScreen({super.key})`.
  - `build` retorna `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()), child: Padding(padding: const .all(16.0), child: Column(crossAxisAlignment: .start, children: [const ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.'), const SizedBox(height: 24.0), const Expanded(child: Placeholder())])))`.
  - Espelha exatamente o layout de `NotificationsScreen` (mesmos imports: `app_bar_widget`, `go_back_widget`, `scaffold_widget`, `screen_header_widget`).
- [ ] 2.3 Criar pasta `lib/src/presentation/ui/profile/locations/`.
- [ ] 2.4 Criar `lib/src/presentation/ui/profile/locations/profile_location.dart`:
  - `final class ProfileLocation extends Location`.
  - `path` retorna `AppRoutes.profile.path`.
  - `pageBuilder` retorna `(_) => screenPage(const ProfileScreen())`.
  - Espelha exatamente `NotificationsLocation`.

### 3. Avatar da Home clicável

- [ ] 3.1 Atualizar `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart`:
  - Adicionar `final VoidCallback? onTap;` antes do construtor (ordenação de membros do CLAUDE.md).
  - Construtor: `const HomeAvatarWidget({super.key, required this.name, this.size = 48.0, this.onTap})`.
  - Em `build`, envolver o `Container` (que já existe) em `BounceWidget.withOnPress(onPress: onTap, child: <container>)`.
  - Importar `bounce_widget.dart`.
- [ ] 3.2 Verificar que `HomeAvatarWidget` continua sendo construível sem `onTap` (call-sites antigos, previews) — `onTap == null` deve renderizar normalmente, sem efeito de bounce.

### 4. `HomeAppBarWidget` propaga `navigateToProfile`

- [ ] 4.1 Atualizar `lib/src/presentation/ui/home/widgets/home_app_bar_widget.dart`:
  - Adicionar `final VoidCallback navigateToProfile;` named-required, antes do construtor (junto com os demais `navigateToX`).
  - Atualizar construtor para incluir `required this.navigateToProfile`.
  - Em `build`, passar `onTap: navigateToProfile` ao construtor de `HomeAvatarWidget`.

### 5. `HomeScreen` propaga `navigateToProfile`

- [ ] 5.1 Atualizar `lib/src/presentation/ui/home/screens/home_screen.dart`:
  - Adicionar `final VoidCallback navigateToProfile;` named-required (junto com os demais).
  - Atualizar construtor para incluir `required this.navigateToProfile`.
  - Passar `navigateToProfile: widget.navigateToProfile` ao construtor de `HomeAppBarWidget`.

### 6. `HomeLocation` injeta navegação

- [ ] 6.1 Atualizar `lib/src/presentation/ui/home/locations/home_location.dart`:
  - Adicionar `import 'package:trocado/src/presentation/ui/profile/locations/profile_location.dart';`.
  - Em `pageBuilder`, adicionar `navigateToProfile: () => context.navigate(ProfileLocation())` ao construtor de `HomeScreen`.
  - **Exceção narrada (CLAUDE.md)**: Locations podem importar outras Locations.

### 7. `SettingsLocation` injeta navegação

- [ ] 7.1 Atualizar `lib/src/presentation/ui/settings/locations/settings_location.dart`:
  - Adicionar `import 'package:trocado/src/presentation/ui/profile/locations/profile_location.dart';`.
  - Trocar `onEditProfile: () {}` por `onEditProfile: () => context.navigate(ProfileLocation())`.

### 8. Verificação

- [ ] 8.1 `flutter analyze` — zero warnings.
- [ ] 8.2 `flutter test` — toda a suíte passa (nenhum teste novo é necessário; testes existentes que construíam `HomeAvatarWidget` / `HomeAppBarWidget` / `HomeScreen` precisam ser atualizados se quebrarem por causa do novo named-required).
- [ ] 8.3 **Smoke manual — Home → Profile**: rodar app, na Home tocar no avatar com a inicial → `ProfileScreen` abre com título "Dados pessoais" e descrição. Tocar em "voltar" → volta para Home.
- [ ] 8.4 **Smoke manual — Settings → Profile**: navegar para Settings, tocar em "Dados pessoais" → `ProfileScreen` abre. Voltar → retorna para Settings.
- [ ] 8.5 **Smoke manual — feedback de toque no avatar**: o tap no avatar dispara o efeito de bounce (sem ele a tela navega seca).
- [ ] 8.6 Verificar com grep que `ProfileScreen` e `ProfileLocation` foram criados:
  - `find lib/src/presentation/ui/profile -type f` lista 2 arquivos `.dart`.

---

## Parte 2 — Listagem dos campos editáveis (Instagram-style)

Ordem fixa: spec → mover `userProvider` para escopo shared → promover avatar para shared → criar widgets de profile → atualizar `ProfileScreen` → code generation → verificação.

### 9. Promover `userProvider` para escopo cross-feature

- [ ] 9.1 Mover `lib/src/presentation/ui/home/notifiers/user_notifier.dart` para `lib/src/presentation/notifiers/user_notifier.dart`. Conteúdo e `part 'user_notifier.g.dart';` permanecem; só muda o caminho.
- [ ] 9.2 Deletar `lib/src/presentation/ui/home/notifiers/user_notifier.dart` e `user_notifier.g.dart` antigos.
- [ ] 9.3 Atualizar imports:
  - `lib/src/presentation/ui/home/screens/home_screen.dart` — trocar para o novo path.
  - `test/src/presentation/providers/user_notifier_test.dart` — trocar para o novo path.

### 10. Promover `HomeAvatarWidget` para `AvatarWidget` shared

- [ ] 10.1 Criar `lib/src/presentation/widgets/avatar/avatar_widget.dart` com `class AvatarWidget extends StatelessWidget`. Conteúdo idêntico ao `HomeAvatarWidget` (campos `name`, `size = 48.0`, `onTap`; envolto em `BounceWidget.withOnPress(onPress: onTap)` com Container interno).
- [ ] 10.2 Atualizar `lib/src/presentation/ui/home/widgets/home_app_bar_widget.dart` — trocar import para o novo path; trocar `HomeAvatarWidget(...)` por `AvatarWidget(...)`.
- [ ] 10.3 Deletar `lib/src/presentation/ui/home/widgets/home_avatar_widget.dart`.

### 11. Widgets feature-local em `profile/widgets/`

- [ ] 11.1 Criar `lib/src/presentation/ui/profile/widgets/profile_header_widget.dart`:
  - `StatelessWidget` puro recebendo `final UserModel user;` (named, required).
  - Renderiza `Column(crossAxisAlignment: .center)` com: `Center(child: AvatarWidget(name: user.name, size: 72.0))` + `SizedBox(height: 16.0)` + `Text(user.name, style: titleLarge bold)` + `SizedBox(height: 4.0)` + `Text(user.email, style: bodyMedium onSurfaceVariant)`.
- [ ] 11.2 Criar `lib/src/presentation/ui/profile/widgets/profile_field_item_widget.dart`:
  - `StatelessWidget` com `final String label;`, `final VoidCallback onTap;`, `final bool enabled;` (default true).
  - Quando `enabled: true`: envolve em `BounceWidget.withOnPress(onPress: onTap)`; texto `bodyMedium`; chevron `Icons.chevron_right` color `onSurfaceVariant`.
  - Quando `enabled: false`: sem `BounceWidget`; texto `bodyMedium` color `onSurfaceVariant`; sem chevron.
  - Layout: `SizedBox(height: 56.0)` + `Row(spacing: 16.0)` com `Expanded(Text(label, maxLines: 1, overflow: ellipsis))` + chevron condicional.
- [ ] 11.3 Criar `lib/src/presentation/ui/profile/widgets/profile_fields_card_widget.dart`:
  - `StatelessWidget` com `final List<Widget> children;`.
  - Espelha `SettingsCardWidget` (container arredondado 16, `surfaceContainerLowest` background, `outlineVariant` border, `Divider(height: 1.0)` entre filhos com padding horizontal 16 nos filhos).
- [ ] 11.4 Criar `lib/src/presentation/ui/profile/widgets/profile_delete_account_widget.dart`:
  - `StatelessWidget` com `final VoidCallback onTap;`.
  - Renderiza `Container(width: .infinity, padding: const .only(top: 16.0))` com filho `ButtonWidget.elevated(label: 'Apagar conta', onTap: onTap, child: const Icon(Icons.delete_outline, size: 20.0))`. Sem `Theme` override — espelha o padrão visual de `SettingsLogoutWidget`; a destrutividade é sinalizada apenas no dialog de confirmação.

### 12. Atualizar `ProfileScreen`

- [ ] 12.1 Manter o `ScreenHeaderWidget` da Parte 1 e substituir apenas o `Expanded(Placeholder())` por conteúdo real:
  - `Consumer` interno que faz `final userState = ref.watch(userProvider);`.
  - Switch sobre `AsyncValue<UserModel>`:
    - `AsyncLoading()` → `Skeletonizer(enabled: true, child: <success layout com mock UserModel>)`.
    - `AsyncError(:final error)` → `Center` com `Column` contendo `Text(failure.message)` + `ButtonWidget.outlined(label: 'Tentar novamente', onTap: () => ref.invalidate(userProvider))`. Cast `error` para `Failure` (sealed) para extrair `.message`.
    - `AsyncData(:final value)` → `Column(crossAxisAlignment: .start)` com: `ScreenHeaderWidget(title: 'Dados pessoais', description: 'Gerencie as informações da sua conta.')` + `SizedBox(height: 24.0)` + `ProfileHeaderWidget(user: value)` + `SizedBox(height: 32.0)` + `ProfileFieldsCardWidget(children: [ProfileFieldItemWidget(label: 'Nome', onTap: () {}), ProfileFieldItemWidget(label: 'E-mail', enabled: false, onTap: () {}), ProfileFieldItemWidget(label: 'Senha', onTap: () {})])` + `Spacer()` + `ProfileDeleteAccountWidget(onTap: <handler de dialog>)`.
  - `_buildBody` e `_buildError` como **métodos privados** que retornam `Widget` — nunca classes privadas no arquivo (CLAUDE.md).
- [ ] 12.2 Handler do delete account:
  ```dart
  onTap: () async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Apagar conta',
      confirmLabel: 'Apagar',
      description:
          'Esta ação é irreversível. Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.',
    );
    if (!confirmed) return;
    // Parte 5: navegar para ProfilePurgeScreen
  }
  ```
- [ ] 12.3 Imports agrupados (Flutter / pacotes / projeto), seguindo a convenção do projeto.
- [ ] 12.4 `Consumer` interno com `StatelessWidget` — jamais `ConsumerWidget` (CLAUDE.md).

### 13. Code generation

- [ ] 13.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar `user_notifier.g.dart` no novo path.

### 14. Verificação Parte 2

- [ ] 14.1 `flutter analyze` — zero warnings.
- [ ] 14.2 `flutter test` — toda a suíte passa (incluindo `user_notifier_test.dart` com novo import).
- [ ] 14.3 **Smoke manual — Profile via avatar Home**: tocar avatar Home → Profile abre com nome e email do usuário logado, 3 itens (Nome / E-mail cinza / Senha) e botão "Apagar conta" no rodapé.
- [ ] 14.4 **Smoke manual — itens enabled vs disabled**: tap em "Nome" e "Senha" tem efeito de bounce mas não navega (ainda). Tap em "E-mail" não anima nem dispara nada.
- [ ] 14.5 **Smoke manual — confirm dialog destrutivo**: tap em "Apagar conta" → dialog abre com título, descrição explícita de irreversibilidade e botões "Cancelar" / "Apagar". Cancelar fecha sem efeito.
- [ ] 14.6 **Smoke manual — loading**: forçar latência alta no userProvider → Skeletonizer aparece com placeholders enquanto carrega.
- [ ] 14.7 **Smoke manual — error**: forçar erro 500 → mensagem de falha + botão "Tentar novamente" funcional.
- [ ] 14.8 Verificar que nenhuma feature além de Home/Profile importa `presentation/notifiers/user_notifier.dart` ainda — provider está pronto para crescer mas hoje só esses dois consomem.

---

## Parte 3 — UI dos formulários de edição (nome e senha)

Ordem fixa: rotas → reorganização de `profile/` em subdiretórios → subfeature `name/` (validator → state → intent → notifier → screen → location) → subfeature `password/` (validator → state → intent → notifier → screen → location) → providers de form validator → wiring em `details/` → code generation → verificação.

### 15. Novas rotas

- [ ] 15.1 Adicionar em `lib/app_route.dart`:
  ```dart
  static final profileName = AppRoutes._(
    path: '/profile/name',
    name: 'profile-name-route',
    regex: RegExp(r'^/profile/name$'),
  );

  static final profilePassword = AppRoutes._(
    path: '/profile/password',
    name: 'profile-password-route',
    regex: RegExp(r'^/profile/password$'),
  );
  ```
- [ ] 15.2 Incluir `profileName` e `profilePassword` em `AppRoutes._all`.

### 16. Reorganização de `profile/` em subdiretórios

- [ ] 16.1 Mover `lib/src/presentation/ui/profile/screens/profile_screen.dart` para `lib/src/presentation/ui/profile/details/screens/profile_details_screen.dart`. Renomear classe `ProfileScreen` → `ProfileDetailsScreen`.
- [ ] 16.2 Mover `lib/src/presentation/ui/profile/locations/profile_location.dart` para `lib/src/presentation/ui/profile/details/locations/profile_details_location.dart`. Renomear `ProfileLocation` → `ProfileDetailsLocation`.
- [ ] 16.3 Mover os 4 widgets de `profile/widgets/` para `profile/details/widgets/` (paths atualizados, nomes de classe permanecem). Atualizar imports em `profile_details_screen.dart`.
- [ ] 16.4 Atualizar imports em `lib/src/presentation/ui/home/locations/home_location.dart` e `lib/src/presentation/ui/settings/locations/settings_location.dart` — trocar `ProfileLocation` → `ProfileDetailsLocation` e o path do import.
- [ ] 16.5 Deletar pastas vazias `profile/screens/`, `profile/locations/`, `profile/widgets/`.

### 17. Subfeature `name/`

- [ ] 17.1 Criar `lib/src/presentation/ui/profile/name/validators/name_validation.dart`:
  ```dart
  final class NameValidation implements Validation<String> {
    const NameValidation();

    static const _maxLength = 128;

    @override
    ValidationBase<String> call(String value) {
      final normalized = value.trim();

      if (normalized.isEmpty) return const Invalid('Nome obrigatório');
      if (normalized.length > _maxLength) {
        return const Invalid('Nome deve ter no máximo 128 caracteres');
      }

      return Valid(normalized);
    }
  }
  ```
- [ ] 17.2 Criar `lib/src/presentation/ui/profile/name/validators/profile_name_form_validator.dart` — recebe `NameValidation` via construtor; método `call(ProfileNameState state)` retorna `({state, isValid})` no padrão dos demais form validators do projeto.
- [ ] 17.3 Criar `lib/src/presentation/ui/profile/name/notifiers/profile_name_state.dart` — `final String name;` + `final String? nameFailure;` + `copyWith({String? name, String? nameFailure, bool clearNameFailure = false})` + `props`.
- [ ] 17.4 Criar `lib/src/presentation/ui/profile/name/notifiers/profile_name_intent.dart` — sealed `ProfileNameIntent` com `NameChanged(String value)` + `SubmitPressed()`.
- [ ] 17.5 Criar `lib/src/presentation/ui/profile/name/notifiers/profile_name_notifier.dart`:
  - `@riverpod` `final class ProfileNameNotifier extends _$ProfileNameNotifier`.
  - `Future<ProfileNameState> build()` async — `_validator = ref.watch(profileNameFormValidatorProvider)` e `final user = await ref.watch(userProvider.future); return ProfileNameState(name: user.name);`.
  - `dispatch(ProfileNameIntent intent)` exhaustivo — `NameChanged(:final value) => state = AsyncData(state.value!.copyWith(name: value, clearNameFailure: true))`, `SubmitPressed() => _submit()`.
  - `_submit()` valida, mantém o `state` validado e retorna cedo se inválido. Se válido: `// TODO Parte 6: chamar repository.updateName(...)`.
- [ ] 17.6 Criar `lib/src/presentation/ui/profile/name/screens/profile_name_screen.dart`:
  - `StatelessWidget` + `Consumer` interno (jamais `ConsumerWidget`).
  - Switch sobre `AsyncValue<ProfileNameState>`:
    - `AsyncData(:final value)` → `_buildBody(state: value, notifier: ref.read(...))`.
    - `AsyncError(:final error)` → `_buildError(failure: error is Failure ? error : const UnknownFailure(), onRetry: () => ref.invalidate(profileNameProvider))`.
    - `AsyncLoading()` → `Center(child: CircularProgressIndicatorWidget(...))`.
  - `_buildBody`: Column com `ScreenHeaderWidget(title: 'Nome', description: 'Atualize o seu nome de exibição.')` + `SizedBox(24)` + `TextFieldWidget(label: 'Nome', hint: 'Nome', inputAction: .done, initialValue: state.name, failure: state.nameFailure, onChanged: (v) => notifier.dispatch(NameChanged(v)))` + `Spacer` + `SizedBox(width: .infinity, child: ButtonWidget.elevated(label: 'Atualizar', onTap: () { hideKeyboard(); notifier.dispatch(const SubmitPressed()); }))`.
- [ ] 17.7 Criar `lib/src/presentation/ui/profile/name/locations/profile_name_location.dart` — `ProfileNameLocation extends Location` no padrão de `ProfileDetailsLocation` (path = `AppRoutes.profileName.path`, `pageBuilder` = `screenPage(const ProfileNameScreen())`).

### 18. Subfeature `password/`

- [ ] 18.1 Criar `lib/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart` — espelha `PasswordResetConfirmFormValidator` (reusa `PasswordValidation` compartilhado; valida `newPassword` e checa `confirmPassword == newPassword` com mensagem `'As senhas não coincidem'`).
- [ ] 18.2 Criar `lib/src/presentation/ui/profile/password/notifiers/profile_password_state.dart` — `newPassword`, `confirmPassword`, `obscureNewPassword` (default true), `obscureConfirmPassword` (default true), `newPasswordFailure`, `confirmPasswordFailure`. `copyWith` com `bool clearNewPasswordFailure` e `bool clearConfirmPasswordFailure`. `props`.
- [ ] 18.3 Criar `lib/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart` — sealed `ProfilePasswordIntent` com `NewPasswordChanged`, `ConfirmPasswordChanged`, `NewPasswordVisibilityToggled`, `ConfirmPasswordVisibilityToggled`, `SubmitPressed`.
- [ ] 18.4 Criar `lib/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart`:
  - `@riverpod` `final class ProfilePasswordNotifier extends _$ProfilePasswordNotifier`.
  - `ProfilePasswordState build()` — `_validator = ref.watch(profilePasswordFormValidatorProvider)`; retorna `const ProfilePasswordState()`.
  - `dispatch` exhaustivo cobrindo os 5 intents.
  - `_submit()` valida e retorna cedo se inválido. Se válido: `// TODO Parte 6: chamar repository.updatePassword(...)`.
- [ ] 18.5 Criar `lib/src/presentation/ui/profile/password/screens/profile_password_screen.dart`:
  - `StatelessWidget` + `Consumer`.
  - Layout espelhando `PasswordResetConfirmScreen`: `ScreenHeaderWidget(title: 'Senha', description: 'Crie uma nova senha para sua conta.')` + `SizedBox(24)` + dois `TextFieldWidget` (Nova senha / Confirmar senha) com toggle de visibilidade via `trailingIcon` + `hideTrailingIconWhenEmpty: true` + `Spacer` + `ButtonWidget.elevated(label: 'Atualizar')`.
- [ ] 18.6 Criar `lib/src/presentation/ui/profile/password/locations/profile_password_location.dart` — mesmo padrão de `ProfileNameLocation` apontando para `AppRoutes.profilePassword.path`.

### 19. Providers de form validator

- [ ] 19.1 Adicionar em `lib/src/main/providers/validators_provider.dart`:
  ```dart
  @Riverpod()
  ProfileNameFormValidator profileNameFormValidator(Ref _) =>
      const ProfileNameFormValidator(nameValidation: NameValidation());

  @Riverpod()
  ProfilePasswordFormValidator profilePasswordFormValidator(Ref _) =>
      const ProfilePasswordFormValidator(passwordValidation: PasswordValidation());
  ```
- [ ] 19.2 Adicionar imports apropriados (validator + validation).

### 20. Wiring em `details/`

- [ ] 20.1 Atualizar `lib/src/presentation/ui/profile/details/screens/profile_details_screen.dart`:
  - Adicionar `final VoidCallback onEditName;` e `final VoidCallback onEditPassword;` (named-required) antes do construtor.
  - Atualizar construtor para incluir ambos.
  - Substituir os `onTap: () {}` dos itens "Nome" e "Senha" pelos callbacks recebidos.
- [ ] 20.2 Atualizar `lib/src/presentation/ui/profile/details/locations/profile_details_location.dart`:
  - Importar `ProfileNameLocation` e `ProfilePasswordLocation`.
  - Adicionar `LocationBuilder? get builder` (ou estender `pageBuilder` para receber `context`) que injeta `onEditName: () => context.navigate(ProfileNameLocation())` e `onEditPassword: () => context.navigate(ProfilePasswordLocation())`.

### 21. Code generation

- [ ] 21.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar:
  - `profile_name_notifier.g.dart`
  - `profile_password_notifier.g.dart`
  - `validators_provider.g.dart` (com os dois novos providers)

### 22. Testes

- [ ] 22.0 Criar `test/src/presentation/profile/name/validators/name_validation_test.dart` com 6 cenários: empty, whitespace-only, 129+ chars, 1 char, 128 chars exato, valor com espaços (validação trim).
- [ ] 22.1 Criar `test/src/presentation/profile/name/validators/profile_name_form_validator_test.dart` com 3 cenários: empty → failure; >128 → failure; valid → clears failure + isValid true.
- [ ] 22.2 Criar `test/src/presentation/profile/name/notifiers/profile_name_notifier_test.dart` com cenários:
  - `build pre-fills name with the current user name` (mock userProvider via override de `userRepositoryProvider`).
  - `starts as AsyncLoading until userProvider resolves`.
  - `NameChanged updates name in state`.
  - `NameChanged clears nameFailure when name changes` (após dispatch SubmitPressed que populou failure).
  - `SubmitPressed sets nameFailure when name is empty`.
  - `SubmitPressed clears nameFailure when name is valid`.
- [ ] 22.3 Criar `test/src/presentation/profile/password/validators/profile_password_form_validator_test.dart` com 4 cenários: empty → newPasswordFailure; <8 chars → newPasswordFailure; mismatch → confirmPasswordFailure; valid match → isValid true.
- [ ] 22.4 Criar `test/src/presentation/profile/password/notifiers/profile_password_notifier_test.dart` com cenários para os 5 intents (NewPasswordChanged + clear, ConfirmPasswordChanged + clear, NewPasswordVisibilityToggled isolado, ConfirmPasswordVisibilityToggled isolado, SubmitPressed empty/mismatch/valid).
- [ ] 22.5 Convenções: descrições em inglês; mocks via interface (`late IUserRepository repository`); variáveis nunca chamadas `result`/`either`; `final` com tipo explícito quando agrega.

### 23. Verificação Parte 3

- [ ] 23.1 `flutter analyze` — zero warnings.
- [ ] 23.2 `flutter test` — toda a suíte passa (incluindo os 28 novos testes de profile).
- [ ] 23.3 **Smoke manual — navegação**: tap em "Nome" no `ProfileDetailsScreen` abre `ProfileNameScreen` com o campo já preenchido com o nome do usuário logado. Tap em "Senha" abre `ProfilePasswordScreen` com os dois campos vazios.
- [ ] 23.4 **Smoke manual — Nome — validação**: limpar o campo e tap "Atualizar" → mensagem `'Nome obrigatório'`. Digitar 129+ caracteres e tap "Atualizar" → `'Nome deve ter no máximo 128 caracteres'`. Digitar nome válido e tap "Atualizar" → sem feedback visual (esperado nesta parte).
- [ ] 23.5 **Smoke manual — Senha — validação**: tap "Atualizar" com campos vazios → `'Senha obrigatória'` no primeiro campo. Digitar < 8 chars → `'Senha deve ter ao menos 8 caracteres'`. Digitar nova senha válida + confirmar diferente → `'As senhas não coincidem'`. Digitar ambas iguais e válidas → sem feedback visual.
- [ ] 23.6 **Smoke manual — toggle de visibilidade**: nos dois campos da `ProfilePasswordScreen`, tap no ícone do olho alterna entre obscured/visible independentemente.
- [ ] 23.7 **Smoke manual — voltar**: a partir de qualquer dos 3 fluxos (`ProfileNameScreen`, `ProfilePasswordScreen`, `ProfileDetailsScreen`) o `GoBackWidget` retorna ao stack anterior.
- [ ] 23.8 Verificar com `find lib/src/presentation/ui/profile -type d` que existem 3 subdiretórios (`details/`, `name/`, `password/`) e nenhum diretório legado solto.

---

## Parte 4 — Renome do botão de exclusão para "Excluir conta"

A `ProfileDetailsScreen` mantém o botão único de exclusão criado na Parte 2; apenas o label muda. Sem dialog de confirmação na detail — o `onTap` apenas dispara navegação para `ProfilePurgeScreen` (Parte 5).

### 24. Atualizar `ProfileDeleteAccountWidget`

- [ ] 24.1 Em `lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart`, garantir que o botão use `ButtonWidget.elevated(label: 'Excluir conta', onTap: onTap)` — full-width, sem ícone.

### 25. Atualizar `ProfileDetailsScreen`

- [ ] 25.1 `_buildBody` recebe apenas `required VoidCallback onDelete` (sem `onDeactivate`). O argumento `onDelete` é repassado para `ProfileDeleteAccountWidget(onTap: onDelete)`.
- [ ] 25.2 No branch `AsyncData`, `onDelete` recebe o `onPurge` injetado pela Location — sem dialog inline.
- [ ] 25.3 Manter o branch `Skeletonizer` (loading) com `onDelete: () {}`.

### 26. Verificação Parte 4

- [ ] 26.1 `flutter analyze` — zero warnings.
- [ ] 26.2 `flutter test` — toda a suíte passa.
- [ ] 26.3 **Smoke manual — botão**: a `ProfileDetailsScreen` mostra um único botão "Excluir conta" full-width no rodapé.
- [ ] 26.4 **Smoke manual — navegação**: tap em "Excluir conta" navega para `ProfilePurgeScreen` (sem dialog inline na detail).

---

## Parte 5 (passo 0) — Extrair `PasswordFieldWidget` compartilhado

Pré-requisito da Parte 5 propriamente dita. Notifiers/states/intents existentes **não mudam** — só as screens trocam o bloco repetido por `PasswordFieldWidget(...)`.

### 35. Criar `PasswordFieldWidget`

- [ ] 35.1 Criar `lib/src/presentation/widgets/fields/password_field_widget.dart`:
  - `class PasswordFieldWidget extends StatelessWidget`.
  - Campos antes do construtor (CLAUDE.md): `final String hint;`, `final String label;`, `final bool obscure;`, `final String? failure;`, `final String? initialValue;`, `final TextInputAction? inputAction;`, `final ValueChanged<String>? onChanged;`, `final VoidCallback onToggle;`.
  - Construtor: `const PasswordFieldWidget({ super.key, required this.hint, required this.label, required this.obscure, required this.onToggle, this.failure, this.onChanged, this.initialValue, this.inputAction });`.
  - `build` retorna `TextFieldWidget(hint: ..., label: ..., failure: ..., onChanged: ..., obscureText: obscure, inputAction: ..., initialValue: ..., hideTrailingIconWhenEmpty: true, onTrailingIconTap: onToggle, trailingIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)`.

### 36. Migrar call-sites existentes para `PasswordFieldWidget`

- [ ] 36.1 `lib/src/presentation/ui/authentication/sign_in/screens/sign_in_screen.dart` — substituir o `TextFieldWidget` do campo "Senha" por `PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', inputAction: .done, obscure: state.obscurePassword, onToggle: () => notifier.dispatch(const PasswordVisibilityToggled()), failure: state.passwordFailure, onChanged: (v) => notifier.dispatch(PasswordChanged(v)))`. Atualizar import (remover `text_field_widget.dart` se não houver outro uso na screen; adicionar `password_field_widget.dart`).
- [ ] 36.2 `lib/src/presentation/ui/authentication/sign_up/screens/sign_up_screen.dart` — mesma migração para o campo de senha.
- [ ] 36.3 `lib/src/presentation/ui/authentication/password_reset_confirm/screens/password_reset_confirm_screen.dart` — substituir os **dois** `TextFieldWidget` (Nova senha + Confirmar senha) por `PasswordFieldWidget`. `inputAction: .next` no primeiro, `.done` no segundo.
- [ ] 36.4 `lib/src/presentation/ui/profile/password/screens/profile_password_screen.dart` — mesma migração para os dois campos. `inputAction: .next` no primeiro, `.done` no segundo.
- [ ] 36.5 Verificar se algum dos arquivos migrados deixa de usar `TextFieldWidget` — se sim, remover o import.

### 37. Verificação Passo 0

- [ ] 37.1 `flutter analyze` — zero warnings.
- [ ] 37.2 `flutter test` — toda a suíte passa (testes de notifier existentes não dependem do widget — só de `dispatch` em intent).
- [ ] 37.3 **Smoke manual — sign_in**: campo de senha alterna obscure ao tocar no ícone do olho; failure aparece como antes.
- [ ] 37.4 **Smoke manual — sign_up**: idem.
- [ ] 37.5 **Smoke manual — password_reset_confirm**: dois campos, toggles independentes, mismatch de confirmação ainda dispara `'As senhas não coincidem'`.
- [ ] 37.6 **Smoke manual — profile_password**: idem ao reset_confirm.

---

## Parte 5 — Exclusão definitiva via API (purge)

Ordem fixa: domain → infrastructure → data → presentation (subfeature `profile/purge/`) → wiring (rota + detail screen + location) → code generation → tests → verificação.

### 38. Domain

- [ ] 38.1 Adicionar à `IUserRepository`:
  ```dart
  Future<Either<Failure, void>> purge({
    required String email,
    required String password,
  });
  ```

### 39. Infrastructure

- [ ] 39.1 Adicionar `EndpointKey.purge('/api/v1/me/purge')` em `lib/src/infrastructure/clients/http/endpoint_key.dart`. **Não** incluir em `_publicEndpoints`.
- [ ] 39.2 Criar `lib/src/infrastructure/clients/http/requests/purge_request.dart`:
  ```dart
  final class PurgeRequest {
    final String email;
    final String password;

    const PurgeRequest({required this.email, required this.password});

    Map<String, dynamic> toJson() => {'email': email, 'password': password};
  }
  ```
- [ ] 39.3 Adicionar à interface `IRemoteUserDataSource`:
  ```dart
  Future<Either<FailureResponse, void>> purge({
    required String email,
    required String password,
  });
  ```
- [ ] 39.4 Implementar `RemoteUserDataSource.purge`:
  ```dart
  final response = await _client.post(
    parameter: Requests(EndpointKey.purge.path,
      body: PurgeRequest(email: email, password: password).toJson()),
  );
  return response.either(FailureResponse.fromJson, (_) {});
  ```

### 40. Data

- [ ] 40.1 Implementar `UserRepository.purge`:
  ```dart
  @override
  Future<Either<Failure, void>> purge({
    required String email,
    required String password,
  }) async {
    final data = await _userDataSource.purge(email: email, password: password);
    return data.either((failure) => failure.toFailure(), (_) {});
  }
  ```
  Sem leitura de tokens — `Authorization` é injetado pelo `AuthenticationInterceptor` automaticamente.

### 41. Presentation — subfeature `profile/purge/`

- [ ] 41.1 Criar `lib/src/presentation/ui/profile/purge/notifiers/profile_purge_state.dart`:
  - `enum ProfilePurgeStatus { initial, loading, success, failure }`.
  - `final class ProfilePurgeState extends Equatable` com `final String password;`, `final String message;`, `final bool obscurePassword;`, `final String? passwordFailure;`, `final ProfilePurgeStatus status;`.
  - Defaults: `password = ''`, `message = ''`, `obscurePassword = true`, `passwordFailure = null`, `status = initial`.
  - `copyWith({String? password, String? message, bool? obscurePassword, String? passwordFailure, ProfilePurgeStatus? status, bool clearPasswordFailure = false})`.
  - `props = [password, message, obscurePassword, passwordFailure, status]`.
- [ ] 41.2 Criar `lib/src/presentation/ui/profile/purge/notifiers/profile_purge_intent.dart`:
  - `sealed class ProfilePurgeIntent { const ProfilePurgeIntent(); }`.
  - `final class PasswordChanged extends ProfilePurgeIntent { final String value; const PasswordChanged(this.value); }`.
  - `final class PasswordVisibilityToggled extends ProfilePurgeIntent { const PasswordVisibilityToggled(); }`.
  - `final class ValidatePressed extends ProfilePurgeIntent { const ValidatePressed(); }` — usado pela screen para validar antes de abrir o confirm dialog.
  - `final class SubmitPressed extends ProfilePurgeIntent { const SubmitPressed(); }`.
- [ ] 41.3 Criar `lib/src/presentation/ui/profile/purge/validators/profile_purge_form_validator.dart`:
  ```dart
  final class ProfilePurgeFormValidator {
    final PasswordValidation _passwordValidation;
    const ProfilePurgeFormValidator({required PasswordValidation passwordValidation})
        : _passwordValidation = passwordValidation;

    ({ProfilePurgeState state, bool isValid}) call(ProfilePurgeState state) {
      final password = _passwordValidation(state.password);
      final isValid = password is Valid;
      final validated = state.copyWith(
        passwordFailure: switch (password) {
          Valid() => null,
          Invalid(:final message) => message,
        },
        clearPasswordFailure: password is Valid,
      );
      return (state: validated, isValid: isValid);
    }
  }
  ```
- [ ] 41.4 Criar `lib/src/presentation/ui/profile/purge/notifiers/profile_purge_notifier.dart`:
  - `@riverpod final class ProfilePurgeNotifier extends _$ProfilePurgeNotifier`.
  - `late IUserRepository _repository; late ProfilePurgeFormValidator _validator;`.
  - `ProfilePurgeState build() { _repository = ref.watch(userRepositoryProvider); _validator = ref.watch(profilePurgeFormValidatorProvider); return const ProfilePurgeState(); }`.
  - `dispatch(ProfilePurgeIntent intent)` exhaustivo:
    - `PasswordChanged(:final value)` → `state = state.copyWith(password: value, clearPasswordFailure: true)`.
    - `PasswordVisibilityToggled()` → `state = state.copyWith(obscurePassword: !state.obscurePassword)`.
    - `ValidatePressed()` → `_validate()`.
    - `SubmitPressed()` → `_submit()`.
  - `void _validate()` — `final (state: validated, isValid: _) = _validator(state); state = validated;`.
  - `Future<void> _submit()`:
    1. `final (:state, :isValid) = _validator(this.state); this.state = state;`.
    2. `if (!isValid) return;`.
    3. `if (this.state.status == ProfilePurgeStatus.loading) return;`.
    4. `this.state = this.state.copyWith(status: .loading);`.
    5. `final user = ref.read(userProvider).valueOrNull;`.
    6. `if (user == null) { this.state = this.state.copyWith(status: .failure, message: 'Não foi possível identificar o usuário.'); return; }`.
    7. `final data = await _repository.purge(email: user.email, password: this.state.password);`.
    8. `data.fold((failure) => this.state = this.state.copyWith(status: .failure, message: failure.message), (_) { ref.invalidate(userProvider); this.state = this.state.copyWith(status: .success); });`.
- [ ] 41.5 Criar `lib/src/presentation/ui/profile/purge/screens/profile_purge_screen.dart`:
  - `StatelessWidget` + `Consumer` interno (jamais `ConsumerWidget`).
  - `ref.listen(profilePurgeProvider, (previous, next) { if (next.status == .failure && previous?.status != .failure) showToastWidget(context: context, title: 'Opps', type: .failure, description: next.message); });`.
  - Lê `final user = ref.watch(userProvider).valueOrNull` — se `null` (defensivo), renderiza `SizedBox.shrink()` ou um `Center` neutro (não esperado em prática).
  - Lê `final state = ref.watch(profilePurgeProvider); final notifier = ref.read(profilePurgeProvider.notifier);`.
  - Layout: `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()), child: Padding(padding: const .all(16.0), child: Column(spacing: 24.0, crossAxisAlignment: .start, children: [ScreenHeaderWidget(title: 'Excluir conta', description: 'Esta ação é irreversível. Confirme com sua senha para excluir definitivamente sua conta e todos os dados associados.'), TextFieldWidget(label: 'E-mail', hint: '', initialValue: user.email, readOnly: true), PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', inputAction: .done, obscure: state.obscurePassword, onToggle: () => notifier.dispatch(const PasswordVisibilityToggled()), failure: state.passwordFailure, onChanged: (v) => notifier.dispatch(PasswordChanged(v))), const Spacer(), SizedBox(width: .infinity, child: ButtonWidget.elevated(label: 'Excluir', isLoading: state.status == .loading, onTap: () => _submit(context, notifier)))])))`.
  - Método privado `_submit(BuildContext context, WidgetRef ref, ProfilePurgeNotifier notifier)` — valida **antes** de abrir o dialog, abortando se inválido:
    ```dart
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
    ```
  - Sem classes privadas no arquivo — apenas métodos privados (CLAUDE.md).
- [ ] 41.6 Criar `lib/src/presentation/ui/profile/purge/locations/profile_purge_location.dart`:
  ```dart
  final class ProfilePurgeLocation extends Location {
    @override
    String get path => AppRoutes.profilePurge.path;

    @override
    LocationPageBuilder get pageBuilder =>
        (_) => screenPage(const ProfilePurgeScreen());
  }
  ```

### 42. Provider de form validator

- [ ] 42.1 Adicionar em `lib/src/main/providers/validators_provider.dart`:
  ```dart
  @Riverpod()
  ProfilePurgeFormValidator profilePurgeFormValidator(Ref _) =>
      const ProfilePurgeFormValidator(passwordValidation: PasswordValidation());
  ```
- [ ] 42.2 Adicionar import de `profile_purge_form_validator.dart`.

### 43. Rota

- [ ] 43.1 Adicionar em `lib/app_route.dart`:
  ```dart
  static final profilePurge = AppRoutes._(
    path: '/profile/purge',
    name: 'profile-purge-route',
    regex: RegExp(r'^/profile/purge$'),
  );
  ```
- [ ] 43.2 Incluir `profilePurge` em `AppRoutes._all`.

### 44. Wiring na detail

- [ ] 44.1 Atualizar `lib/src/presentation/ui/profile/details/screens/profile_details_screen.dart`:
  - Adicionar `final VoidCallback onPurge;` named-required (junto aos demais callbacks).
  - Atualizar construtor para incluir `required this.onPurge`.
  - Em `_buildBody`, no branch `AsyncData`, passar `onDelete: onPurge` direto (sem ir por `_confirmDelete`).
  - Manter o branch `Skeletonizer` passando `onDelete: () {}` (no-op enquanto carrega).
  - **Remover** o método `_confirmDelete` — o dialog de confirmação migra para `ProfilePurgeScreen`.
  - Limpar imports não usados (`confirm_dialog_widget.dart` continua sendo usado pelo `_confirmDeactivate`, então fica).
- [ ] 44.2 Atualizar `lib/src/presentation/ui/profile/details/locations/profile_details_location.dart`:
  - Importar `package:trocado/src/presentation/ui/profile/purge/locations/profile_purge_location.dart`.
  - Injetar `onPurge: () => context.navigate(ProfilePurgeLocation())` ao construir `ProfileDetailsScreen`.

### 45. Code generation

- [ ] 45.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar:
  - `profile_purge_notifier.g.dart`.
  - `validators_provider.g.dart` (com o novo `profilePurgeFormValidatorProvider`).

### 46. Testes

- [ ] 46.1 Estender `test/src/data/repositories/user_repository_test.dart` com `group('purge')` cobrindo:
  - Right(null) quando POST `/api/v1/me/purge` retorna 204 — verificar path **e** que o body envia `{'email': '<email>', 'password': '<password>'}`.
  - Left(NetworkFailure) quando código `'connection_error'` ou `'timeout'`.
  - Left(NotFoundFailure) quando código `'not_found'`.
  - Left(ServerFailure) quando código `'server_error'`.
  - Left(ValidationFailure('Senha incorreta.')) quando código `'invalid'` com mensagem genérica do backend.
- [ ] 46.2 Criar `test/src/presentation/profile/purge/validators/profile_purge_form_validator_test.dart` com 3 cenários:
  - empty → `passwordFailure == 'Senha obrigatória'` e `isValid == false`.
  - <8 chars → `passwordFailure == 'Senha deve ter ao menos 8 caracteres'` e `isValid == false`.
  - 8+ chars → `passwordFailure == null` e `isValid == true`.
- [ ] 46.3 Criar `test/src/presentation/profile/purge/notifiers/profile_purge_notifier_test.dart` cobrindo:
  - `build returns initial state`.
  - `PasswordChanged updates password and clears passwordFailure` (após dispatch SubmitPressed que populou failure).
  - `PasswordVisibilityToggled toggles obscurePassword` (default true → false → true).
  - `SubmitPressed with empty password sets passwordFailure and does not call repository`.
  - `SubmitPressed with valid password sets status to loading then success and invalidates userProvider on success`.
  - `SubmitPressed with valid password and repository failure sets status to failure with message`.
  - `SubmitPressed during loading is a no-op` (re-entrancy guard).
  - `SubmitPressed when userProvider is null sets failure defensively with 'Não foi possível identificar o usuário.'`.
  - Mock `IUserRepository` com `MockUserRepository` (já existe em `test/mocks/mocks.dart`); override `userProvider` com um valor de `UserModel` ou explicitamente `null` conforme o cenário.
- [ ] 46.4 Convenções: descrições em inglês; mocks declarados com tipo da interface (`late IUserRepository repository;`); variáveis nunca chamadas `result`/`either`; `final` com tipo explícito quando agrega legibilidade.

### 47. Verificação Parte 5

- [ ] 47.1 `flutter analyze` — zero warnings.
- [ ] 47.2 `flutter test` — toda a suíte passa.
- [ ] 47.3 **Smoke manual — navegação**: tap em "Excluir" no `ProfileDetailsScreen` abre `ProfilePurgeScreen` com email readonly preenchido e campo senha vazio.
- [ ] 47.4 **Smoke manual — validação**: tap "Excluir" com senha vazia → `'Senha obrigatória'`. Senha < 8 chars → `'Senha deve ter ao menos 8 caracteres'`. Senha válida → abre `showConfirmDialog`.
- [ ] 47.5 **Smoke manual — confirm dialog**: dialog tem título `'Excluir conta'`, label `'Excluir'`, descrição reforçando irreversibilidade. Cancel fecha sem efeito; confirm dispara loading no botão.
- [ ] 47.6 **Smoke manual — sucesso**: backend 204 → `userProvider` invalidado → próxima request 401 → refresh fail → app redireciona para SignIn.
- [ ] 47.7 **Smoke manual — falha "senha incorreta"**: digitar senha errada → toast `'Opps'` com mensagem do backend (ex: `'Senha incorreta.'`) aparece. Botão sai do loading; usuário continua na `ProfilePurgeScreen` para tentar de novo.
- [ ] 47.8 **Smoke manual — falha de rede**: backend timeout → toast `'Opps'` com mensagem do `NetworkFailure`. Botão sai do loading.
- [ ] 47.9 **Smoke manual — double-tap**: tap rápido em "Excluir" no dialog não dispara duas requests (verificar via logs).
- [ ] 47.10 **Smoke manual — toggle de visibilidade**: tap no ícone do olho alterna entre obscured/visible no campo senha.
- [ ] 47.11 **Smoke manual — voltar**: a partir da `ProfilePurgeScreen`, `GoBackWidget` retorna para `ProfileDetailsScreen` com state limpo.
- [ ] 47.12 Verificar com `find lib/src/presentation/ui/profile -maxdepth 1 -type d` que `purge/` foi adicionada como 4ª subpasta junto com `details/`, `name/`, `password/`.

---

## Parte 6+ — A definir

- **Parte 6** — Edição real de nome/senha (PATCH) — substitui os `// TODO Parte 6` nos notifiers correspondentes.
