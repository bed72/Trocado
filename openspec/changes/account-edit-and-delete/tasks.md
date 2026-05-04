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

## Parte 2+ — A definir

Seções abaixo serão adicionadas conforme cada parte for proposta e aprovada:

- **Parte 2** — Leitura e exibição dos dados do usuário na `ProfileScreen`.
- **Parte 3** — Edição (formulário + PATCH).
- **Parte 4** — Exclusão de conta + signOut + confirmação destrutiva.
