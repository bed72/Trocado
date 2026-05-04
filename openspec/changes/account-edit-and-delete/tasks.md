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
  - Renderiza `Column(crossAxisAlignment: .center)` com: `AvatarWidget(name: user.name, size: 96.0)` + `SizedBox(height: 16.0)` + `Text(user.name, style: titleLarge bold)` + `SizedBox(height: 4.0)` + `Text(user.email, style: bodyMedium onSurfaceVariant)`.
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
  - Renderiza `Container(width: .infinity, padding: const .only(top: 16.0))` com filho `Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: context.colors.error)), child: ButtonWidget.outlined(label: 'Apagar conta', onTap: onTap, child: const Icon(Icons.delete_outline, size: 20.0)))`.

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

## Parte 3+ — A definir

- **Parte 3** — Forms de edição (nome, senha).
- **Parte 4** — Exclusão de conta real + signOut + redirect.
