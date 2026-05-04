# Proposal — account-edit-and-delete

## Why

O usuário hoje **não consegue ver, editar nem excluir** os próprios dados de conta no Trocado. O `UserModel` é carregado no boot e usado apenas para saudação na Home (avatar com inicial + greeting). Não há tela de perfil, nem caminho de saída para gestão da conta — o único acesso a "Conta" pelo menu Settings é o item "Dados pessoais", que hoje aponta para `() {}` (no-op em `lib/src/presentation/ui/settings/locations/settings_location.dart:18`).

Sem essa peça, o usuário fica preso ao que cadastrou no sign-up — não consegue corrigir nome/email, ajustar dados pessoais, nem excluir a conta. Para um app de finanças pessoais isso é UX inaceitável e bloqueia conformidade com LGPD (direito de retificação e direito ao apagamento).

A feature completa de **Edição e Exclusão de Conta** será entregue de forma incremental — esta change vai ser editada conforme as próximas partes forem implementadas. A primeira parte (esta proposal) entrega apenas o **scaffold de navegação**: as duas portas de entrada (avatar da Home e item "Dados pessoais" em Settings) levam o usuário a uma `ProfileScreen` vazia (apenas título e descrição, no padrão de `NotificationsScreen`).

Partes futuras (a serem adicionadas a esta mesma change):

- **Parte 2** — exibição dos dados atuais do usuário na `ProfileScreen` (provider/notifier de leitura).
- **Parte 3** — formulário de edição de dados pessoais (PATCH no backend).
- **Parte 4** — exclusão da conta (DELETE no backend) com confirmação destrutiva (provavelmente reusando `ConfirmDialogWidget` já criado na change anterior).

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
- Click em "Apagar conta" → `showConfirmDialog(title: 'Apagar conta', description: 'Esta ação é irreversível. Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.', confirmLabel: 'Apagar')` → no-op se confirmado (Parte 4 liga na API).

### Parte 3 — UI dos formulários de edição (nome e senha)

Nesta parte a `profile/` ganha duas telas de form (nome e senha) com **apenas UI + validações** — sem lógica de API, sem repository. A integração com PATCH do backend fica para a Parte 4.

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
- `name/notifiers/profile_name_notifier.dart` — `AsyncNotifier<ProfileNameState>` com `Future<ProfileNameState> build()` async que faz `await ref.watch(userProvider.future)` para pré-preencher `name: user.name`. `dispatch` exhaustivo. `_submit` apenas valida (sem API): se inválido popula failures; se válido, no-op com `// TODO Parte 4`.
- `name/screens/profile_name_screen.dart` — `StatelessWidget` + `Consumer` switch sobre `AsyncValue<ProfileNameState>` (loading / error retry / data com form). Layout: `ScreenHeaderWidget(title: 'Nome', description: 'Atualize o seu nome de exibição.')` + `TextFieldWidget(label: 'Nome', hint: 'Nome', initialValue: state.name, failure: state.nameFailure, inputAction: .done)` + `Spacer` + `ButtonWidget.elevated(label: 'Atualizar')` no rodapé.
- `name/locations/profile_name_location.dart` — `ProfileNameLocation extends Location`, sem parâmetros.

#### Subfeature `password/`

- **Sem validator novo** — reusa `PasswordValidation` compartilhado (`presentation/validators/password_validation.dart`, min 8).
- `password/validators/profile_password_form_validator.dart` — `ProfilePasswordFormValidator` espelhando `PasswordResetConfirmFormValidator`: valida `newPassword` via `PasswordValidation`; `confirmPassword` deve coincidir com `newPassword` (`'As senhas não coincidem'`).
- `password/notifiers/profile_password_state.dart` — `newPassword`, `confirmPassword`, `obscureNewPassword` (default true), `obscureConfirmPassword` (default true), `newPasswordFailure`, `confirmPasswordFailure`.
- `password/notifiers/profile_password_intent.dart` — sealed com `NewPasswordChanged`, `ConfirmPasswordChanged`, `NewPasswordVisibilityToggled`, `ConfirmPasswordVisibilityToggled`, `SubmitPressed`.
- `password/notifiers/profile_password_notifier.dart` — `Notifier<ProfilePasswordState>` (sync, sem dependência async). `_submit` valida e faz no-op com `// TODO Parte 4`.
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

### Parte 4 — Dual action (Excluir + Desativar) na tela de detalhes

A `ProfileDetailsScreen` deixa de ter um único botão "Apagar conta" no rodapé e passa a expor **duas ações lado a lado** (espelhando o pattern de `BudgetEditActionsWidget` / `ExpenseEditActionsWidget`):

- **Excluir** (esquerda, `ButtonWidget.outlined`, sem ícone) — ação irreversível: dados financeiros apagados.
- **Desativar** (direita, `ButtonWidget.elevated`, sem ícone) — ação reversível principal: a conta fica oculta, dados preservados, login reativa.

#### Substituição do widget

- `profile_delete_account_widget.dart` (com `ProfileDeleteAccountWidget`) → renomeado para `profile_account_actions_widget.dart` com `ProfileAccountActionsWidget`.
- API: `final VoidCallback onDelete;` + `final VoidCallback onDeactivate;` (ambos named-required).
- Layout: `Padding(top: 16) → Row(spacing: 16, [Expanded(outlined Excluir), Expanded(elevated Desativar)])` — apenas labels, sem ícones.

#### Dois dialogs no `ProfileDetailsScreen`

`_buildBody` agora recebe ambos `onDelete` e `onDeactivate`. A screen ganha dois métodos `_confirmDelete` e `_confirmDeactivate`:

- **Excluir** (atualizado): title `'Excluir conta'`, confirmLabel `'Excluir'`, description `'Esta ação é irreversível.\n\n - Todos os seus dados financeiros serão apagados e você não poderá recuperá-los.'`.
- **Desativar** (novo): title `'Desativar conta'`, confirmLabel `'Desativar'`, description `'Sua conta ficará desativada e seus dados ficarão preservados.\n\n - Você poderá reativá-la fazendo login novamente.'`.

Ambos pós-confirmação são no-op nesta parte — Parte 5 plugará na API real (`IUserRepository.deactivate()` e `IUserRepository.delete()`).

### Parte 5+ (placeholder)

- **Parte 5 — Edição e exclusão reais via API**: `IUserRepository.update(...)`, `IUserRepository.delete()`, `IUserRepository.deactivate()`, `UserRequest`, signOut + redirect para `SignInLocation` nos fluxos de excluir/desativar, troca dos `// TODO` nos notifiers/screen pelas chamadas reais de PATCH/DELETE.

## Scope

### Em escopo (Parte 4 — atual)

- Renome de `profile_delete_account_widget.dart`/`ProfileDeleteAccountWidget` para `profile_account_actions_widget.dart`/`ProfileAccountActionsWidget`.
- Layout do widget passa de single elevated para `Row` com 2 `Expanded` (outlined Excluir à esquerda + elevated Desativar à direita), apenas labels.
- `ProfileDetailsScreen._buildBody` recebe `onDelete` e `onDeactivate` (ambos named-required).
- Novos métodos `_confirmDelete` (atualizado: title/label `'Excluir'`) e `_confirmDeactivate` (novo) na screen, cada um chamando `showConfirmDialog` com texto explicando o efeito.
- Ambos pós-confirmação são no-op (Parte 5 plugará na API).
- `flutter analyze` zero warnings; `flutter test` passa toda a suíte.

### Fora de escopo (Parte 4 — virá em partes futuras)

- **Endpoints reais** `DELETE /api/v1/users/me` e `POST /api/v1/users/me/deactivate` (ou similar) — Parte 5.
- **`IUserRepository.delete()` e `IUserRepository.deactivate()`** — Parte 5.
- **SignOut + redirect** para `SignInLocation` após confirmação — Parte 5.
- **Loading state nos botões** durante a chamada de API — Parte 5 (adiciona `isLoading` flags).
- **Mudança visual destrutiva** (Theme override, cor de erro) — mantemos o visual padrão; a destrutividade é comunicada exclusivamente pelo dialog.
- **Testes da screen / widget de actions** — comportamento ainda é só wiring de `showConfirmDialog`; testes virão na Parte 5 junto com a ramificação success/failure da API.

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

- **Lógica de API real** — `_submit` apenas valida nesta parte; `// TODO Parte 4` marca o ponto de entrada do PATCH.
- **Toast/navegação de feedback pós-submit** — sem simulação de sucesso ou falha conforme decisão acordada; o usuário fica na tela após submit válido sem feedback visual além do estado limpo do form.
- **Endpoints `PATCH /api/v1/users/me`** e **`DELETE /api/v1/users/me`** — Parte 4.
- **Toggle de visibilidade no nome** — não tem (campo não-secreto).
- **Validação de "senha atual"** antes de trocar — fora do escopo desta parte; será reavaliada na Parte 4 conforme contrato do backend.
- **Estados de loading/erro** no notifier de nome além do `AsyncValue` natural — Parte 4 adicionará `status: loading/success/failure` quando houver chamada de API.
- **Testes do caminho de erro do `ProfileNameNotifier`** (userProvider em `AsyncError`) — Parte 4, junto com a chamada real de API, vai estabilizar o caminho de erro completo.

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
- **Endpoints e repository** de update/delete de user (Partes 3 e 4).
- **Lógica real do delete** (Parte 4).
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
- **Exclusão de conta** (Parte 4).
- **Testes de widget para `ProfileScreen`** — a tela é só placeholder; testes vêm quando houver comportamento (Parte 2+).
- **Mudanças no backend** — endpoints de update/delete de user serão validados nas partes 3 e 4.
- **Refactor de `userProvider`** — fica como está; eventual unificação ou divisão será decidida na Parte 2.
- **Logout** — já existe em Settings; não muda.
- **Avatar com foto** — hoje é só inicial; mudança visual fora de escopo.
- **Indicador visual de "tap target" no avatar** (cursor pointer, ripple custom) — `BounceWidget.withOnPress` já dá feedback de toque suficiente.
