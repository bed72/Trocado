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
    // Parte 4: dispatch DeleteAccountPressed
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
  - `_submit()` valida, mantém o `state` validado e retorna cedo se inválido. Se válido: `// TODO Parte 4: chamar repository.updateName(...)`.
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
  - `_submit()` valida e retorna cedo se inválido. Se válido: `// TODO Parte 4: chamar repository.updatePassword(...)`.
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

## Parte 4 — Dual action (Excluir + Desativar) na tela de detalhes

### 24. Substituição do widget de delete

- [ ] 24.1 Renomear `lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart` para `profile_account_actions_widget.dart`.
- [ ] 24.2 Reescrever a classe como `ProfileAccountActionsWidget extends StatelessWidget` com:
  - `final VoidCallback onDelete;` + `final VoidCallback onDeactivate;` (ambos named-required, antes do construtor).
  - Renderiza `Padding(padding: .only(top: 16.0)) → Row(spacing: 16.0)` com:
    - Esquerda: `Expanded(child: ButtonWidget.outlined(label: 'Excluir', onTap: onDelete))`.
    - Direita: `Expanded(child: ButtonWidget.elevated(label: 'Desativar', onTap: onDeactivate))`.
  - Sem ícones — apenas labels.

### 25. `ProfileDetailsScreen` ganha dois fluxos destrutivos

- [ ] 25.1 Atualizar imports — trocar `profile_delete_account_widget.dart` por `profile_account_actions_widget.dart`.
- [ ] 25.2 `_buildBody` ganha `required VoidCallback onDeactivate` (além do `onDelete` existente). Substituir `ProfileDeleteAccountWidget(onTap: onDelete)` por `ProfileAccountActionsWidget(onDelete: onDelete, onDeactivate: onDeactivate)`.
- [ ] 25.3 Atualizar o branch `AsyncData` para passar `onDeactivate: () => _confirmDeactivate(context)`.
- [ ] 25.4 Atualizar o branch `Skeletonizer` (loading) para passar `onDeactivate: () {}` além do `onDelete: () {}` existente.
- [ ] 25.5 Atualizar `_confirmDelete`: trocar `title: 'Apagar conta'` → `'Excluir conta'` e `confirmLabel: 'Apagar'` → `'Excluir'`. Description permanece (irreversível).
- [ ] 25.6 Adicionar método `_confirmDeactivate(BuildContext context)`:
  - Chama `showConfirmDialog(context, title: 'Desativar conta', confirmLabel: 'Desativar', description: 'Sua conta ficará desativada e seus dados ficarão preservados.\n\n - Você poderá reativá-la fazendo login novamente.')`.
  - Pós-confirm: no-op (Parte 5).

### 26. Verificação Parte 4

- [ ] 26.1 `flutter analyze` — zero warnings.
- [ ] 26.2 `flutter test` — toda a suíte passa.
- [ ] 26.3 **Smoke manual — botões**: a `ProfileDetailsScreen` mostra dois botões lado a lado no rodapé (Excluir à esquerda outlined, Desativar à direita elevated, sem ícones).
- [ ] 26.4 **Smoke manual — Desativar**: tap em "Desativar" abre dialog com título `'Desativar conta'` + descrição explicando reativação por login + botões `'Cancelar'` / `'Desativar'`. Cancelar fecha sem efeito. Confirm fecha (no-op).
- [ ] 26.5 **Smoke manual — Excluir**: tap em "Excluir" abre dialog com título `'Excluir conta'` + descrição de irreversibilidade + botões `'Cancelar'` / `'Excluir'`. Cancelar fecha sem efeito. Confirm fecha (no-op).

---

## Parte 5+ — A definir

- **Parte 5** — Edição (PATCH `/api/v1/users/me`) + Excluir + Desativar reais. `IUserRepository.update`/`delete`/`deactivate`, `UserRequest`, signOut + redirect para `SignInLocation` nos fluxos destrutivos, substitui os `// TODO Parte 4` nos notifiers de Nome/Senha e os no-ops dos confirms da screen pela chamada real à API.
