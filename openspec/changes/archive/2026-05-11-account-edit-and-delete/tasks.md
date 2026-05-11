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
    // Parte 5: navegar para ProfileDeleteScreen
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

A `ProfileDetailsScreen` mantém o botão único de exclusão criado na Parte 2; apenas o label muda. Sem dialog de confirmação na detail — o `onTap` apenas dispara navegação para `ProfileDeleteScreen` (Parte 5).

### 24. Atualizar `ProfileDeleteAccountWidget`

- [ ] 24.1 Em `lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart`, garantir que o botão use `ButtonWidget.elevated(label: 'Excluir conta', onTap: onTap)` — full-width, sem ícone.

### 25. Atualizar `ProfileDetailsScreen`

- [ ] 25.1 `_buildBody` recebe apenas `required VoidCallback onDelete` (sem `onDeactivate`). O argumento `onDelete` é repassado para `ProfileDeleteAccountWidget(onTap: onDelete)`.
- [ ] 25.2 No branch `AsyncData`, `onDelete` é repassado direto ao `ProfileDeleteAccountWidget` — sem dialog inline.
- [ ] 25.3 Manter o branch `Skeletonizer` (loading) com `onDelete: () {}`.

### 26. Verificação Parte 4

- [ ] 26.1 `flutter analyze` — zero warnings.
- [ ] 26.2 `flutter test` — toda a suíte passa.
- [ ] 26.3 **Smoke manual — botão**: a `ProfileDetailsScreen` mostra um único botão "Excluir conta" full-width no rodapé.
- [ ] 26.4 **Smoke manual — navegação**: tap em "Excluir conta" navega para `ProfileDeleteScreen` (sem dialog inline na detail).

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

## Parte 5 — Exclusão definitiva via API

Ordem fixa: domain → infrastructure → data → presentation (subfeature `profile/delete/`) → wiring (rota + detail screen + location) → code generation → tests → verificação.

### 38. Domain

- [ ] 38.1 Adicionar à `IUserRepository`:
  ```dart
  Future<Either<Failure, void>> delete({required String password});
  ```
  A senha é o único primitivo de domínio que atravessa a fronteira; o refresh token é orquestrado pelo repositório.

### 39. Infrastructure

- [ ] 39.1 Adicionar à interface `IRemoteUserDataSource`:
  ```dart
  Future<Either<FailureResponse, void>> delete({
    required String refresh,
    required String password,
  });
  ```
- [ ] 39.2 Implementar `RemoteUserDataSource.delete`:
  ```dart
  final response = await _client.delete(
    parameter: Requests(
      EndpointKey.me.path,
      body: {'refresh': refresh, 'password': password},
    ),
  );
  return response.either(FailureResponse.fromJson, (_) {});
  ```
  Body inline, sem DTO (mesmo padrão do antigo deactivate). `EndpointKey.me` já existe — não cria nova entrada.

### 40. Data

- [ ] 40.1 Atualizar `UserRepository`:
  - Construtor passa a aceitar `ILocalTokenDataSource tokenDataSource` + `IRemoteUserDataSource userDataSource` (espelha `AuthenticationRepository`).
  - `delete({required String password})`:
    ```dart
    final tokens = await _tokenDataSource.get();
    if (tokens.refresh == null) return const Left(UnknownFailure());
    final data = await _userDataSource.delete(
      refresh: tokens.refresh!,
      password: password,
    );
    return data.either((failure) => failure.toFailure(), (_) {});
    ```
- [ ] 40.2 Atualizar `userRepositoryProvider` em `lib/src/main/providers/repositories_provider.dart` para injetar `localTokenDataSourceProvider` junto com `remoteUserDataSourceProvider`.

### 41. Presentation — subfeature `profile/delete/`

- [ ] 41.1 Criar `lib/src/presentation/ui/profile/delete/notifiers/profile_delete_state.dart`:
  - `enum ProfileDeleteStatus { initial, loading, success, failure }`.
  - `final class ProfileDeleteState extends Equatable` com `final String password;`, `final String message;`, `final bool obscurePassword;`, `final String? passwordFailure;`, `final ProfileDeleteStatus status;`.
  - Defaults: `password = ''`, `message = ''`, `obscurePassword = true`, `passwordFailure = null`, `status = initial`.
  - `copyWith({String? password, String? message, bool? obscurePassword, String? passwordFailure, ProfileDeleteStatus? status, bool clearPasswordFailure = false})`.
  - `props = [password, message, obscurePassword, passwordFailure, status]`.
- [ ] 41.2 Criar `lib/src/presentation/ui/profile/delete/notifiers/profile_delete_intent.dart`:
  - `sealed class ProfileDeleteIntent { const ProfileDeleteIntent(); }`.
  - `final class PasswordChanged extends ProfileDeleteIntent { final String value; const PasswordChanged(this.value); }`.
  - `final class PasswordVisibilityToggled extends ProfileDeleteIntent { const PasswordVisibilityToggled(); }`.
  - `final class ValidatePressed extends ProfileDeleteIntent { const ValidatePressed(); }` — usado pela screen para validar antes de abrir o confirm dialog.
  - `final class SubmitPressed extends ProfileDeleteIntent { const SubmitPressed(); }`.
- [ ] 41.3 Criar `lib/src/presentation/ui/profile/delete/validators/profile_delete_form_validator.dart`:
  ```dart
  final class ProfileDeleteFormValidator {
    final PasswordValidation _passwordValidation;
    const ProfileDeleteFormValidator({required PasswordValidation passwordValidation})
        : _passwordValidation = passwordValidation;

    ({ProfileDeleteState state, bool isValid}) call(ProfileDeleteState state) {
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
- [ ] 41.4 Criar `lib/src/presentation/ui/profile/delete/notifiers/profile_delete_notifier.dart`:
  - `@riverpod final class ProfileDeleteNotifier extends _$ProfileDeleteNotifier`.
  - `late IUserRepository _repository; late ProfileDeleteFormValidator _validator;`.
  - `ProfileDeleteState build() { _repository = ref.watch(userRepositoryProvider); _validator = ref.watch(profileDeleteFormValidatorProvider); return const ProfileDeleteState(); }`.
  - `dispatch(ProfileDeleteIntent intent)` exhaustivo:
    - `PasswordChanged(:final value)` → `state = state.copyWith(password: value, clearPasswordFailure: true)`.
    - `PasswordVisibilityToggled()` → `state = state.copyWith(obscurePassword: !state.obscurePassword)`.
    - `ValidatePressed()` → `_validate()`.
    - `SubmitPressed()` → `_submit()`.
  - `void _validate()` — `final (state: validated, isValid: _) = _validator(state); state = validated;`.
  - `Future<void> _submit()`:
    1. `final (:state, :isValid) = _validator(this.state); this.state = state;`.
    2. `if (!isValid) return;`.
    3. `if (this.state.status == ProfileDeleteStatus.loading) return;`.
    4. `this.state = this.state.copyWith(status: .loading);`.
    5. `final data = await _repository.delete(password: this.state.password);`.
    6. `data.fold((failure) => this.state = this.state.copyWith(status: .failure, message: failure.message), (_) { ref.invalidate(userProvider); this.state = this.state.copyWith(status: .success); });`.
- [ ] 41.5 Criar `lib/src/presentation/ui/profile/delete/screens/profile_delete_screen.dart`:
  - `StatelessWidget` + `Consumer` interno (jamais `ConsumerWidget`).
  - `ref.listen(profileDeleteProvider, (previous, next) { if (next.status == .failure && previous?.status != .failure) showToastWidget(context: context, title: 'Opps', type: .failure, description: next.message); });`.
  - Lê `final state = ref.watch(profileDeleteProvider); final notifier = ref.read(profileDeleteProvider.notifier);` e `final email = switch (ref.watch(userProvider)) { AsyncData(:final value) => value.email, _ => '' };` (apenas para reforço visual readonly — não atravessa o estado do notifier).
  - Body envolto em `CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: false, child: Padding(...))])` para evitar overflow quando o teclado abre.
  - Layout interno: `Padding(padding: const .all(16.0), child: Column(spacing: 24.0, crossAxisAlignment: .start, children: [ScreenHeaderWidget(title: 'Excluir conta', description: 'Esta ação é irreversível.\nConfirme com sua senha para excluir definitivamente sua conta e todos os dados associados.'), TextFieldWidget(label: 'E-mail', hint: '', readOnly: true, enabled: false, initialValue: email), PasswordFieldWidget(label: 'Senha', hint: 'Digite sua senha', inputAction: .done, obscure: state.obscurePassword, onToggle: () => notifier.dispatch(const PasswordVisibilityToggled()), failure: state.passwordFailure, onChanged: (v) => notifier.dispatch(PasswordChanged(v))), const Spacer(), SizedBox(width: .infinity, child: ButtonWidget.elevated(label: 'Excluir', isLoading: state.status == .loading, onTap: () => _submit(context, ref, notifier)))]))`.
  - Método privado `_submit(BuildContext context, WidgetRef ref, ProfileDeleteNotifier notifier)` — valida **antes** de abrir o dialog, abortando se inválido:
    ```dart
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
    ```
  - Sem classes privadas no arquivo — apenas métodos privados (CLAUDE.md).
- [ ] 41.6 Criar `lib/src/presentation/ui/profile/delete/locations/profile_delete_location.dart`:
  ```dart
  final class ProfileDeleteLocation extends Location {
    @override
    String get path => AppRoutes.profileDelete.path;

    @override
    LocationPageBuilder get pageBuilder =>
        (_) => screenPage(const ProfileDeleteScreen());
  }
  ```

### 42. Provider de form validator

- [ ] 42.1 Adicionar em `lib/src/main/providers/validators_provider.dart`:
  ```dart
  @Riverpod()
  ProfileDeleteFormValidator profileDeleteFormValidator(Ref _) =>
      const ProfileDeleteFormValidator(passwordValidation: PasswordValidation());
  ```
- [ ] 42.2 Adicionar import de `profile_delete_form_validator.dart`.

### 43. Rota

- [ ] 43.1 Adicionar em `lib/app_route.dart`:
  ```dart
  static final profileDelete = AppRoutes._(
    path: '/profile/delete',
    name: 'profile-delete-route',
    regex: RegExp(r'^/profile/delete$'),
  );
  ```
- [ ] 43.2 Incluir `profileDelete` em `AppRoutes._all`.

### 44. Wiring na detail

- [ ] 44.1 Atualizar `lib/src/presentation/ui/profile/details/screens/profile_details_screen.dart`:
  - Adicionar `final VoidCallback onDelete;` named-required (junto aos demais callbacks).
  - Atualizar construtor para incluir `required this.onDelete`.
  - Em `_buildBody`, no branch `AsyncData`, passar `onDelete: onDelete` direto (sem dialog inline).
  - Manter o branch `Skeletonizer` passando `onDelete: () {}` (no-op enquanto carrega).
- [ ] 44.2 Atualizar `lib/src/presentation/ui/profile/details/locations/profile_details_location.dart`:
  - Importar `package:trocado/src/presentation/ui/profile/delete/locations/profile_delete_location.dart`.
  - Injetar `onDelete: () => context.navigate(ProfileDeleteLocation())` ao construir `ProfileDetailsScreen`.

### 45. Code generation

- [ ] 45.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar:
  - `profile_delete_notifier.g.dart`.
  - `validators_provider.g.dart` (com o novo `profileDeleteFormValidatorProvider`).

### 46. Testes

- [ ] 46.1 Estender `test/src/data/repositories/user_repository_test.dart` com `group('delete')` cobrindo:
  - Right(null) quando DELETE `/api/v1/me` retorna 204 — verificar path **e** que o body envia `{'refresh': '<token>', 'password': '<password>'}`.
  - Left(UnknownFailure) quando `tokenDataSource.get()` retorna `refresh: null` — confirmar que `client.delete` **não** é chamado.
  - Left(NetworkFailure) quando código `'network_error'`.
  - Left(NotFoundFailure) quando código `'not_found'`.
  - Left(ServerFailure) quando código `'server_error'`.
  - Left(ValidationFailure('Invalid credentials.')) quando código `'invalid_credentials'` com mensagem do backend.
  - O `setUp` mocka `ILocalTokenDataSource.get()` retornando refresh válido como default.
- [ ] 46.2 Criar `test/src/presentation/profile/delete/validators/profile_delete_form_validator_test.dart` com 3 cenários:
  - empty → `passwordFailure == 'Senha obrigatória'` e `isValid == false`.
  - <8 chars → `passwordFailure == 'Senha deve ter ao menos 8 caracteres'` e `isValid == false`.
  - 8+ chars → `passwordFailure == null` e `isValid == true`.
- [ ] 46.3 Criar `test/src/presentation/profile/delete/notifiers/profile_delete_notifier_test.dart` cobrindo:
  - `build returns initial state`.
  - `PasswordChanged updates password and clears passwordFailure` (após dispatch SubmitPressed que populou failure).
  - `PasswordVisibilityToggled toggles obscurePassword` (default true → false → true).
  - `SubmitPressed with empty password sets passwordFailure and does not call repository`.
  - `SubmitPressed with valid password sets status to loading then success and invalidates userProvider on success`.
  - `SubmitPressed with valid password and repository failure sets status to failure with message`.
  - `SubmitPressed during loading is a no-op` (re-entrancy guard).
  - Mock `IUserRepository` com `MockUserRepository` (já existe em `test/mocks/mocks.dart`).
- [ ] 46.4 Convenções: descrições em inglês; mocks declarados com tipo da interface (`late IUserRepository repository;`); variáveis nunca chamadas `result`/`either`; `final` com tipo explícito quando agrega legibilidade.

### 47. Verificação Parte 5

- [ ] 47.1 `flutter analyze` — zero warnings.
- [ ] 47.2 `flutter test` — toda a suíte passa.
- [ ] 47.3 **Smoke manual — navegação**: tap em "Excluir conta" no `ProfileDetailsScreen` abre `ProfileDeleteScreen` com email readonly preenchido (do usuário logado) e campo senha vazio.
- [ ] 47.4 **Smoke manual — validação**: tap "Excluir" com senha vazia → `'Senha obrigatória'`. Senha < 8 chars → `'Senha deve ter ao menos 8 caracteres'`. Senha válida → abre `showConfirmDialog`.
- [ ] 47.5 **Smoke manual — confirm dialog**: dialog tem título `'Excluir conta'`, label `'Excluir'`, descrição reforçando irreversibilidade. Cancel fecha sem efeito; confirm dispara loading no botão.
- [ ] 47.6 **Smoke manual — sucesso**: backend 204 → `userProvider` invalidado → próxima request 401 → refresh fail → app redireciona para SignIn.
- [ ] 47.7 **Smoke manual — falha "senha incorreta"**: digitar senha errada → toast `'Opps'` com mensagem do backend (ex: `'Senha incorreta.'`) aparece. Botão sai do loading; usuário continua na `ProfileDeleteScreen` para tentar de novo.
- [ ] 47.8 **Smoke manual — falha de rede**: backend timeout → toast `'Opps'` com mensagem do `NetworkFailure`. Botão sai do loading.
- [ ] 47.9 **Smoke manual — double-tap**: tap rápido em "Excluir" no dialog não dispara duas requests (verificar via logs).
- [ ] 47.10 **Smoke manual — toggle de visibilidade**: tap no ícone do olho alterna entre obscured/visible no campo senha.
- [ ] 47.11 **Smoke manual — voltar**: a partir da `ProfileDeleteScreen`, `GoBackWidget` retorna para `ProfileDetailsScreen` com state limpo.
- [ ] 47.12 Verificar com `find lib/src/presentation/ui/profile -maxdepth 1 -type d` que `delete/` foi adicionada como 4ª subpasta junto com `details/`, `name/`, `password/`.

---

## Parte 6 — Edição real de nome/senha (PATCH)

Ordem fixa: domain → infrastructure → data → presentation (state/intent/validator/notifier nas duas subfeatures + reshape da `ProfilePasswordScreen`) → wiring (locations + `onSuccess` callback) → code generation → testes → verificação.

### 48. Domain

- [ ] 48.1 Adicionar à `IUserRepository` em `lib/src/domain/repositories/interface_user_repository.dart`:
  ```dart
  Future<Either<Failure, UserModel>> updateName({required String name});

  Future<Either<Failure, UserModel>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  ```
  Ambas devolvem `UserModel` (a API retorna `{id, name, email}` no sucesso). Não há novo enum/sealed novo no domínio.

### 49. Infrastructure

- [ ] 49.1 Adicionar à interface `IRemoteUserDataSource` em `lib/src/infrastructure/datasources/remote/remote_user_data_source.dart`:
  ```dart
  Future<Either<FailureResponse, UserResponse>> update({
    String? name,
    String? currentPassword,
    String? newPassword,
  });
  ```
  Um único método (espelha o endpoint único PATCH `/api/v1/me`). Todos os campos opcionais — o repositório monta a chamada conforme a intenção.
- [ ] 49.2 Implementar `RemoteUserDataSource.update`:
  ```dart
  final response = await _client.patch(
    parameter: Requests(
      EndpointKey.me.path,
      body: {
        if (name != null) 'name': name,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      },
    ),
  );

  return response.either(FailureResponse.fromJson, UserResponse.fromJson);
  ```
  Body inline com map literal usando spread condicional — sem DTO (espelha o padrão do `delete`). `EndpointKey.me` já existe. `UserResponse` já existe.

### 50. Data

- [ ] 50.1 Em `lib/src/data/repositories/user_repository.dart`, adicionar `updateName`:
  ```dart
  @override
  Future<Either<Failure, UserModel>> updateName({required String name}) async {
    final data = await _userDataSource.update(name: name);

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
  ```
- [ ] 50.2 Adicionar `updatePassword`:
  ```dart
  @override
  Future<Either<Failure, UserModel>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final data = await _userDataSource.update(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
  ```
  Reusa `UserResponseExtension.toModel()` e `FailureResponseExtension.toFailure()` existentes — nenhuma extension nova.

### 51. Presentation — subfeature `profile/name/`

- [ ] 51.1 Atualizar `lib/src/presentation/ui/profile/name/notifiers/profile_name_state.dart` adicionando o status do submit:
  - Novo `enum ProfileNameStatus { initial, loading, success, failure }` no topo do arquivo.
  - Campos novos antes do construtor: `final String message;` (default `''`) e `final ProfileNameStatus status;` (default `.initial`).
  - Atualizar construtor, `copyWith` e `props` para incluir os novos campos.
- [ ] 51.2 Atualizar `lib/src/presentation/ui/profile/name/notifiers/profile_name_notifier.dart`:
  - Importar `repositories_provider.dart` e `interface_user_repository.dart`.
  - Adicionar `late IUserRepository _repository;` (antes do `_validator`, seguindo a ordenação de membros).
  - Em `build()`, antes de retornar: `_repository = ref.watch(userRepositoryProvider);`.
  - Trocar `void _submit()` por `Future<void> _submit() async {...}`:
    1. `final (state: validated, :isValid) = _validator(this.state.value!);`
    2. `this.state = AsyncData(validated);`
    3. `if (!isValid) return;`
    4. `if (validated.status == ProfileNameStatus.loading) return;` (re-entrancy guard)
    5. `this.state = AsyncData(validated.copyWith(status: .loading));`
    6. `final data = await _repository.updateName(name: validated.name);`
    7. `data.fold((failure) => state = AsyncData(state.value!.copyWith(status: .failure, message: failure.message)), (_) { ref.invalidate(userProvider); state = AsyncData(state.value!.copyWith(status: .success)); });`
  - Remover o `// TODO Parte 6`.

### 52. Presentation — subfeature `profile/password/`

- [ ] 52.1 Refazer `lib/src/presentation/ui/profile/password/notifiers/profile_password_state.dart`:
  - Novo `enum ProfilePasswordStatus { initial, loading, success, failure }`.
  - Campos antes do construtor: `currentPassword` (`String`, default `''`), `newPassword` (`String`, default `''`), `obscureCurrentPassword` (`bool`, default `true`), `obscureNewPassword` (`bool`, default `true`), `currentPasswordFailure` (`String?`), `newPasswordFailure` (`String?`), `message` (`String`, default `''`), `status` (`ProfilePasswordStatus`, default `.initial`).
  - **Drop**: `confirmPassword`, `confirmPasswordFailure`, `obscureConfirmPassword`.
  - `copyWith` com flags `clearCurrentPasswordFailure` e `clearNewPasswordFailure` (drop `clearConfirmPasswordFailure`).
  - `props` reflete os novos campos.
- [ ] 52.2 Refazer `lib/src/presentation/ui/profile/password/notifiers/profile_password_intent.dart`:
  - **Substituir** `ConfirmPasswordChanged(value)` por `CurrentPasswordChanged(value)`.
  - **Substituir** `ConfirmPasswordVisibilityToggled()` por `CurrentPasswordVisibilityToggled()`.
  - Manter `NewPasswordChanged(value)`, `NewPasswordVisibilityToggled()`, `SubmitPressed()`.
- [ ] 52.3 Refazer `lib/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart`:
  - Validar `currentPassword` via `PasswordValidation` (min 8) → popula `currentPasswordFailure`.
  - Validar `newPassword` via `PasswordValidation` (min 8) → popula `newPasswordFailure`.
  - Drop a checagem `confirmPassword != newPassword` e a mensagem `'As senhas não coincidem'`.
  - `isValid` é `true` somente quando ambas validações são `Valid`.
- [ ] 52.4 Migrar `lib/src/presentation/ui/profile/password/notifiers/profile_password_notifier.dart` para `AsyncNotifier`:
  - Assinatura: `Future<ProfilePasswordState> build() async`.
  - `build()` retorna `const ProfilePasswordState()` (não há nada para preloadar — `await` serve só para alinhar o padrão de submit assíncrono).
  - Dependências: `late IUserRepository _repository;` + `late ProfilePasswordFormValidator _validator;`.
  - `dispatch(ProfilePasswordIntent intent)` atualiza via `state = AsyncData(state.value!.copyWith(...))` em cada branch:
    - `CurrentPasswordChanged(:final value)` → `copyWith(currentPassword: value, clearCurrentPasswordFailure: true)`.
    - `NewPasswordChanged(:final value)` → `copyWith(newPassword: value, clearNewPasswordFailure: true)`.
    - `CurrentPasswordVisibilityToggled()` → `copyWith(obscureCurrentPassword: !state.value!.obscureCurrentPassword)`.
    - `NewPasswordVisibilityToggled()` → `copyWith(obscureNewPassword: !state.value!.obscureNewPassword)`.
    - `SubmitPressed()` → `_submit()`.
  - `Future<void> _submit() async` espelha o do name: valida; early-return se inválido; re-entrancy guard via `state.value!.status == .loading`; `state = AsyncData(state.value!.copyWith(status: .loading))`; `await _repository.updatePassword(currentPassword: state.value!.currentPassword, newPassword: state.value!.newPassword);`; `fold` → failure popula `status .failure` + `message`; success → `ref.invalidate(userProvider)` + `status .success`.
  - Remover o `// TODO Parte 6`.

### 53. Presentation — screens

- [ ] 53.1 Atualizar `lib/src/presentation/ui/profile/name/screens/profile_name_screen.dart`:
  - Adicionar `final VoidCallback onSuccess;` named-required antes do construtor.
  - Construtor: `const ProfileNameScreen({ super.key, required this.onSuccess });`.
  - Dentro do `Consumer` (antes do `switch`), adicionar:
    ```dart
    ref.listen(profileNameProvider, (previous, next) {
      final previousStatus = previous?.value?.status;
      final nextStatus = next.value?.status;
      if (nextStatus == ProfileNameStatus.failure &&
          previousStatus != ProfileNameStatus.failure) {
        showToastWidget(
          context: context,
          title: 'Opps',
          type: ToastType.failure,
          description: next.value?.message ?? '',
        );
      }
      if (nextStatus == ProfileNameStatus.success &&
          previousStatus != ProfileNameStatus.success) {
        onSuccess();
      }
    });
    ```
  - No `_buildBody`, trocar `ButtonWidget.elevated(label: 'Atualizar', onTap: ...)` por `ButtonWidget.elevated(label: 'Atualizar', isLoading: state.status == ProfileNameStatus.loading, onTap: ...)`.
  - Imports novos: `toast_widget.dart`.
  - Não usar `widget.onSuccess` (StatelessWidget — o callback está disponível via `this`).
- [ ] 53.2 Refazer `lib/src/presentation/ui/profile/password/screens/profile_password_screen.dart`:
  - Adicionar `final VoidCallback onSuccess;` named-required.
  - Refletir mudança do notifier para `AsyncNotifier` — `switch (ref.watch(profilePasswordProvider))` com três braços: `AsyncData(:final value)` → `_buildBody(state: value, notifier: ref.read(profilePasswordProvider.notifier))`, `AsyncError` → `_buildError(...)` (mesma forma do `profile_name_screen.dart`), `_` → `const Center(child: CircularProgressIndicatorWidget())`.
  - `ref.listen(profilePasswordProvider, ...)` idêntico ao do name (toast em failure, `onSuccess()` em success).
  - Body interno usando `CustomScrollView` + `SliverFillRemaining(hasScrollBody: false)` para evitar overflow com o teclado (espelha `ProfileDeleteScreen` / `ProfileNameScreen`).
  - Renderiza, em ordem dentro de `Column(spacing: 24.0, crossAxisAlignment: .start)`:
    - `ScreenHeaderWidget(title: 'Senha', description: 'Crie uma nova senha para sua conta.')`.
    - `Column(spacing: 12.0, crossAxisAlignment: .start, children: [...])` com **dois** `PasswordFieldWidget`:
      - `PasswordFieldWidget(label: 'Senha atual', hint: 'Digite sua senha atual', inputAction: .next, failure: state.currentPasswordFailure, obscure: state.obscureCurrentPassword, onChanged: (v) => notifier.dispatch(CurrentPasswordChanged(v)), onToggle: () => notifier.dispatch(const CurrentPasswordVisibilityToggled()))`.
      - `PasswordFieldWidget(label: 'Nova senha', hint: 'Digite a nova senha', inputAction: .done, failure: state.newPasswordFailure, obscure: state.obscureNewPassword, onChanged: (v) => notifier.dispatch(NewPasswordChanged(v)), onToggle: () => notifier.dispatch(const NewPasswordVisibilityToggled()))`.
    - `const Spacer()`.
    - `SizedBox(width: .infinity, child: ButtonWidget.elevated(label: 'Atualizar', isLoading: state.status == ProfilePasswordStatus.loading, onTap: () { hideKeyboard(); notifier.dispatch(const SubmitPressed()); }))`.
  - Drop campo "Confirmar senha" e qualquer referência a `ConfirmPasswordChanged`/`ConfirmPasswordVisibilityToggled`/`confirmPasswordFailure`/`obscureConfirmPassword`.

### 54. Wiring — Locations propagam `onSuccess`

- [ ] 54.1 Atualizar `lib/src/presentation/ui/profile/name/locations/profile_name_location.dart`:
  - Adicionar `final VoidCallback onSuccess;` antes da declaração do override de `path`.
  - Construtor: `const ProfileNameLocation({required this.onSuccess});`.
  - `pageBuilder` passa a ser `(_) => screenPage(ProfileNameScreen(onSuccess: onSuccess))`.
- [ ] 54.2 Idem `lib/src/presentation/ui/profile/password/locations/profile_password_location.dart` — `ProfilePasswordLocation({required this.onSuccess})` + `screenPage(ProfilePasswordScreen(onSuccess: onSuccess))`.
- [ ] 54.3 Atualizar `lib/src/presentation/ui/profile/details/locations/profile_details_location.dart`:
  - Em `pageBuilder`, trocar `ProfileNameLocation()` por `ProfileNameLocation(onSuccess: () => context.pop())` e idem para `ProfilePasswordLocation`.

### 55. Code generation

- [ ] 55.1 Rodar `dart run build_runner build --delete-conflicting-outputs` para regenerar:
  - `profile_name_notifier.g.dart` (a forma do build não muda, mas o conteúdo do notifier sim — re-gerar por garantia).
  - `profile_password_notifier.g.dart` (assinatura mudou para `Future<...>`).

### 56. Testes

- [ ] 56.1 Em `test/src/data/repositories/user_repository_test.dart`, adicionar `group('updateName')` com cenários:
  - Right(UserModel) quando PATCH `/api/v1/me` retorna `{id, name, email}` — verificar payload `{'name': 'Jane Smith'}` (sem `current_password`/`new_password`).
  - Left(NetworkFailure) quando código `'connection_error'`.
  - Left(NotFoundFailure) quando código `'not_found'`.
  - Left(ServerFailure) quando código `'server_error'`.
  - Left(ValidationFailure('mensagem')) quando código desconhecido com mensagem do backend.
- [ ] 56.2 Adicionar `group('updatePassword')` no mesmo arquivo com cenários equivalentes:
  - Right(UserModel) — verificar payload `{'current_password': 'OldPassword!123', 'new_password': 'NewSecure!456'}` (sem `name`).
  - Quatro failures mapeadas (Network/NotFound/Server/Validation).
- [ ] 56.3 Atualizar `test/src/presentation/profile/name/notifiers/profile_name_notifier_test.dart`:
  - Acrescentar mock `late IUserRepository repository;` no `setUp`.
  - Override de `userRepositoryProvider` no `ProviderContainer` retornando o mock.
  - Manter os cenários atuais (build pre-fills, NameChanged, SubmitPressed empty, valid clears failure).
  - **Adicionar** cenários novos:
    - `SubmitPressed with valid name calls repository and sets status success`.
    - `SubmitPressed with valid name and repository failure sets status failure with message`.
    - `SubmitPressed with valid name invalidates userProvider on success`.
    - `SubmitPressed with invalid name does not call repository`.
    - `SubmitPressed during loading is a no-op` (re-entrancy guard).
  - Variáveis nunca chamadas `result` ou `either` (CLAUDE.md). Mocks declarados com o tipo da interface.
- [ ] 56.4 Refazer `test/src/presentation/profile/password/validators/profile_password_form_validator_test.dart`:
  - Drop cenário "mismatch → confirmPasswordFailure".
  - Manter/adicionar: empty currentPassword → `currentPasswordFailure == 'Senha obrigatória'`; empty newPassword → `newPasswordFailure == 'Senha obrigatória'`; <8 chars em qualquer um → failure correspondente; ambos válidos → `isValid == true` e ambas failures `null`.
- [ ] 56.5 Atualizar `test/src/presentation/profile/password/notifiers/profile_password_notifier_test.dart`:
  - Mock `IUserRepository` (já existe `MockUserRepository` em `test/mocks/mocks.dart` — verificar).
  - Substituir intents de `Confirm*` por `Current*` em todos os cenários.
  - Migrar para `AsyncNotifier` — testes inspecionam `state.value!` em vez de `state`.
  - Adicionar cenários de submit: valid → loading então success + repository chamado com `currentPassword`/`newPassword` corretos; valid + repository failure → status failure + message; invalid → não chama repository; re-entrancy guard.
  - Convenções: descrições em inglês; mocks via interface; variáveis nunca `result`/`either`.

### 57. Verificação Parte 6

- [ ] 57.1 `flutter analyze` — zero warnings.
- [ ] 57.2 `flutter test` — toda a suíte passa (incluindo os novos cenários de repository e notifier).
- [ ] 57.3 **Smoke manual — Nome — sucesso**: na `ProfileDetailsScreen`, tap em "Nome" → `ProfileNameScreen` com o campo já preenchido → trocar para "Kevin Editado" → tap "Atualizar" → botão entra em loading → request 200 → screen volta para `ProfileDetailsScreen` automaticamente → header e item "Nome" refletem o novo valor.
- [ ] 57.4 **Smoke manual — Nome — falha de validação local**: limpar o campo → tap "Atualizar" → failure inline `'Nome obrigatório'`; o botão **não** entra em loading e nenhuma request é feita.
- [ ] 57.5 **Smoke manual — Nome — falha do backend**: simular 500 ou `validation_error` → toast `'Opps'` com mensagem do backend; botão sai do loading; usuário continua na screen.
- [ ] 57.6 **Smoke manual — Senha — sucesso**: tap em "Senha" → `ProfilePasswordScreen` com dois campos vazios ("Senha atual" + "Nova senha") → preencher ambos válidos → tap "Atualizar" → loading → 200 → volta para `ProfileDetailsScreen` (sem toast de sucesso).
- [ ] 57.7 **Smoke manual — Senha — falha de validação local**: tap "Atualizar" com ambos vazios → failures inline em ambos os campos; sem request; sem loading.
- [ ] 57.8 **Smoke manual — Senha — falha do backend (senha atual errada)**: digitar `current_password` incorreta + nova válida → tap "Atualizar" → toast `'Opps'` com a mensagem do backend (ex: `'Senha incorreta.'`); usuário continua na screen.
- [ ] 57.9 **Smoke manual — Senha — falha de rede**: backend timeout → toast `'Opps'` com mensagem do `NetworkFailure`; botão sai do loading.
- [ ] 57.10 **Smoke manual — Senha — toggle de visibilidade**: tap no olho dos dois campos alterna obscured/visible independentemente.
- [ ] 57.11 **Smoke manual — re-entrância**: durante loading, tap repetido em "Atualizar" não dispara segunda request (verificar via logs).
- [ ] 57.12 Verificar com grep que nenhum `// TODO Parte 6` permanece:
  - `grep -rn "TODO Parte 6" lib/` retorna vazio.
