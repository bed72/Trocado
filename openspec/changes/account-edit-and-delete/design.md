# Design — account-edit-and-delete

## Contexto técnico

A Home expõe o usuário via `HomeAvatarWidget` (Container puro com a inicial maiúscula do nome, sem qualquer interatividade) renderizado dentro do `title` do `AppBar` em `HomeAppBarWidget`. O `Settings` já tem o item "Dados pessoais" (`SettingsItemWidget(label: 'Dados pessoais', icon: Icons.person_outline, onTap: onEditProfile)`) mas o callback é `() {}` em `SettingsLocation` — não vai a lugar nenhum.

`NotificationsScreen` é o template canônico de tela "vazia" (só header) no projeto: `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + Column com `ScreenHeaderWidget(title:, description:)` + `Expanded(Placeholder())`. `NotificationsLocation` segue o padrão mais simples — `path` + `pageBuilder = (_) => screenPage(const Screen())`.

`BounceWidget.withOnPress(onPress:, child:)` é o widget compartilhado de toque com feedback (uso canônico em `ButtonWidget`, `lib/src/presentation/widgets/buttons/button_widget.dart:44`). Aceita `onPress: VoidCallback?` — quando `null`, não anima nem dispara nada.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

Esta change é **100% presentation/main**. Não toca `domain/`, `data/` nem `infrastructure/` (Parte 1 não tem leitura/escrita de dados). Isso simplifica o blast radius — mudança puramente UI/navegação.

## Decisões de design

### 1. Nome da feature: `profile`

**Decisão**: a pasta é `lib/src/presentation/ui/profile/`; a rota é `AppRoutes.profile` (`/profile`); a screen é `ProfileScreen`; a location é `ProfileLocation`.

**Rationale**: alinha com o nome do callback já existente `onEditProfile` em `SettingsScreen`. Termos alternativos descartados: `account` (genérico demais — confunde com auth/billing), `personal_data` (ruim em código, redundante com o título da tela), `user` (sobrepõe-se a `userProvider` e `UserModel` que são domínio).

**Trade-off**: o título da tela é "Dados pessoais" (PT-BR para o usuário) mas o código é `profile` (EN) — convenção do projeto, espelha `notifications` (folder EN, label PT-BR).

### 2. `HomeAvatarWidget.onTap` é `VoidCallback?` opcional

**Decisão**: o parâmetro é opcional. Quando ausente/null, o widget renderiza com `BounceWidget.withOnPress(onPress: null, ...)` — sem efeito de bounce, sem callback.

**Rationale**: previews e testes atuais que constroem o avatar isolado não precisam fornecer um callback. Mantém a API retrocompatível para qualquer call-site existente. Como `BounceWidget.withOnPress` já trata `onPress: null` (espelha `ButtonWidget` em `button_widget.dart:45`), o cuidado é mínimo.

**Trade-off**: o widget hoje é puramente visual; adicionar `onTap` borra um pouco a separação. Aceitável — a alternativa (criar um `HomeAvatarButtonWidget` separado) seria over-engineering para um único call-site.

### 3. Propagação de callback `navigateToProfile` por named parameter required

**Decisão**: `HomeAppBarWidget` e `HomeScreen` ganham `final VoidCallback navigateToProfile;` named-required, exatamente no mesmo padrão de `navigateToSettings` e `navigateToNotification` que já existem.

**Rationale**: encapsulamento de feature (CLAUDE.md) — `HomeScreen` e `HomeAppBarWidget` jamais importam `ProfileLocation`. A composição (importar `ProfileLocation` e instanciar) é responsabilidade exclusiva de `HomeLocation` (exceção narrada de Locations compondo navegação).

### 4. `SettingsLocation` importa `ProfileLocation` (exceção narrada)

**Decisão**: `SettingsLocation` adiciona `import '...profile/locations/profile_location.dart';` e troca `onEditProfile: () {}` por `onEditProfile: () => context.navigate(ProfileLocation())`.

**Rationale**: pelo CLAUDE.md, "Locations compondo navegação podem importar outras Locations" — é a exceção documentada. `SettingsScreen` continua agnóstica (recebe `VoidCallback`).

### 5. `ProfileScreen` é `const` constructor sem dependências

**Decisão**: `ProfileScreen` é `StatelessWidget` com construtor `const ProfileScreen({super.key})` — sem callbacks, sem providers, sem state. `pageBuilder` constrói `const ProfileScreen()`.

**Rationale**: Parte 1 é só visual. Quando a Parte 2 entrar com leitura de `userProvider`, a screen ganhará um `Consumer` interno (padrão do projeto — sempre `StatelessWidget` + `Consumer`, jamais `ConsumerWidget`).

### 6. Texto fixo no `ScreenHeaderWidget`

**Decisão**: `title: 'Dados pessoais'`, `description: 'Gerencie as informações da sua conta.'` — strings literais no widget, sem internacionalização.

**Rationale**: o app é PT-BR-only hoje (sem `intl` configurado para mensagens, só formatação). Espelha `NotificationsScreen` que tem strings literais. Mover para i18n é trabalho separado, fora do escopo.

### 7. Parte 5 — Delete dedicada por screen, não por dialog (extensão)

**Decisão**: o tap em "Excluir conta" na `ProfileDetailsScreen` **navega** para uma `ProfileDeleteScreen` dedicada, em vez de abrir um dialog inline com campo de senha. O `showConfirmDialog` final ("Tem certeza?") é disparado **dentro** da `ProfileDeleteScreen`, depois da senha já ter sido digitada — funciona como uma porta de confirmação extra antes de mandar a request.

**Rationale**: a feature `profile/` já segue o padrão "uma screen por intenção" (`details/`, `name/`, `password/`); delete se encaixa como mais uma subfeature (`delete/`). Dialog enriquecido com TextField + validação inline + estado de loading/error é incomum no projeto e teria menos espaço para a copy de irreversibilidade. A screen ainda permite o `AppBarWidget`/`GoBackWidget` natural para o usuário desistir antes do submit. Tradeoff: um clique extra (navegar → dialog → confirm) em vez de um único dialog, mas o ganho em clareza visual e consistência arquitetural compensa.

### 8. Parte 5 (passo 0) — `PasswordFieldWidget` compartilhado em `widgets/fields/`

**Decisão**: extrair `PasswordFieldWidget` para `lib/src/presentation/widgets/fields/password_field_widget.dart` antes de implementar a delete, e migrar os 5 call-sites existentes (sign_in, sign_up, password_reset_confirm ×2, profile_password ×2). Notifiers/states/intents permanecem inalterados — `obscure*` continua no state e o intent `...VisibilityToggled` continua sendo a fonte da verdade.

**Rationale**: o bloco de 5+ linhas (`obscureText`, `trailingIcon` condicional, `onTrailingIconTap`) se repete idêntico em todos os call-sites. Adicionar a 6ª réplica na delete sem extrair seria criar débito no momento exato em que ele se manifesta. A API mantém `obscure: bool` + `onToggle: VoidCallback` recebidos do exterior — o widget é puramente apresentacional e não decide quando alternar a visibilidade. Tradeoff: refatorar 5 call-sites antes da feature nova adiciona um passo de regressão visual; mitigado por ser um delegate puro para `TextFieldWidget` (sem mudança de comportamento) e por já existir cobertura indireta via testes de notifier nos campos afetados.

### 9. Parte 5 — `IUserRepository.delete` recebe password como primitivo; refresh é orquestrado pelo repositório

**Decisão**: `IUserRepository.delete({required String password})` aceita apenas a senha digitada pelo usuário. O repositório lê o `refresh_token` via `ILocalTokenDataSource` (espelhando `AuthenticationRepository`) e envia `{refresh, password}` no body de `DELETE /api/v1/me`. O `Authorization: Bearer <access>` continua sendo injetado pelo `AuthenticationInterceptor`.

**Rationale**: o backend exige `password` no body para reautenticar (gate de segurança extra contra exclusão acidental ou tap-fantasma) **e** o `refresh_token` para blacklistá-lo no mesmo transaction (revogação simétrica — a exclusão é atômica e idempotente no servidor). A senha vem da camada de presentation (digitada pelo usuário); o refresh é segredo persistido localmente e não atravessa a UI. Manter ambos no body é decisão do backend, mas só a password precisa atravessar o domínio — o refresh é detalhe de implementação do repositório, mesmo padrão usado quando havia um endpoint separado de revogação.

### 10. Parte 5 — Notifier sync sem dependência de `userProvider`

**Decisão**: o `ProfileDeleteNotifier.build()` é **sync** (`Notifier<ProfileDeleteState>`, não `AsyncNotifier`) e retorna `const ProfileDeleteState()`. O notifier **não** lê `userProvider` — toda a entrada do caso de uso é a `password` do `state` e o repositório resolve o resto.

**Rationale**: como o repositório passou a aceitar só `password`, o notifier não precisa mais buscar o email do usuário no `userProvider`. Isso elimina a guarda defensiva contra `valueOrNull == null` e o caminho de erro "Não foi possível identificar o usuário." — agora o único caminho de falha é o repositório (`Failure.message`). Mantém o notifier mínimo, sem switch `AsyncValue` no estado. A screen ainda lê o `userProvider` por conta própria (switch sobre `AsyncValue` com fallback `''`) para mostrar o email readonly como reforço visual de "qual conta vai sumir", mas isso não atravessa o estado do notifier.

## Fluxos

### Avatar da Home → ProfileScreen

```
[HomeScreen renderiza HomeAppBarWidget(navigateToProfile: ...)]
  → HomeAppBarWidget renderiza HomeAvatarWidget(name, onTap: navigateToProfile)
    → HomeAvatarWidget envelopa Container em BounceWidget.withOnPress(onPress: onTap)

[user toca no avatar]
  → BounceWidget anima o press
  → onPress dispara → navigateToProfile()
  → HomeLocation chamou context.navigate(ProfileLocation())
  → DuckRouter empilha ProfileLocation → ProfileScreen no topo
```

### Settings → ProfileScreen

```
[SettingsScreen renderiza item "Dados pessoais" com onTap: onEditProfile]
[user toca]
  → onEditProfile() → context.navigate(ProfileLocation())
  → DuckRouter empilha ProfileLocation → ProfileScreen no topo
```

### Voltar

```
[ProfileScreen no topo]
  → AppBarWidget(leading: GoBackWidget())
  → user toca no GoBackWidget → context.pop()
  → DuckRouter desempilha → volta para Home (ou Settings, conforme origem)
```

## Trade-offs assumidos

- **Sem testes de widget para a tela placeholder** — `ProfileScreen` é só `ScaffoldWidget` + `ScreenHeaderWidget` com strings fixas; um teste de "renders title and description" seria tautológico. Quando houver lógica (Parte 2+), aí sim testes fazem sentido.
- **`navigateToProfile` é required em `HomeScreen` mesmo quando ainda não há nada para mostrar** — alternativa seria opcional, mas isso esconderia um caminho de navegação esperado e abriria espaço para esquecer de plugar. Required força a composição correta na Location.
- **`HomeAvatarWidget` ganha `onTap` opcional ao invés de required** — diferente de `navigateToProfile` no app bar, o widget pode ser usado em previews/contextos puros (e potencialmente em outras telas no futuro). Opcional é mais flexível sem custo.
- **Não há feedback de "loading" ao navegar** — navegação é síncrona via `DuckRouter`; transição padrão de `screenPage` cobre.

## O que este design **não** pretende resolver

- **Comportamento da `ProfileScreen` vazia** — o `Placeholder()` é literalmente o widget do Flutter (caixa cinza com X). Será substituído pelos campos do usuário na Parte 2.
- **Provider/notifier de profile** — Parte 2.
- **Endpoints e modelos de update/delete** — Partes 3 e 4.
- **Confirmação destrutiva ao excluir conta** — Parte 5 (screen `ProfileDeleteScreen` dedicada com `showConfirmDialog`).
- **Mudança no `HomeAvatarWidget` para suportar foto/imagem** — fora de escopo.
- **Ripple custom ou indicador de "tap area"** — `BounceWidget.withOnPress` é o padrão.
