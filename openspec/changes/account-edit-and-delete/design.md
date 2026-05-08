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

### 7. Parte 6 — Purge dedicada por screen, não por dialog (extensão)

**Decisão**: o tap em "Excluir" na `ProfileDetailsScreen` **navega** para uma `ProfilePurgeScreen` dedicada, em vez de abrir um dialog inline com campo de senha. O `showConfirmDialog` final ("Tem certeza?") é disparado **dentro** da `ProfilePurgeScreen`, depois da senha já ter sido digitada — funciona como uma porta de confirmação extra antes de mandar a request.

**Rationale**: a feature `profile/` já segue o padrão "uma screen por intenção" (`details/`, `name/`, `password/`); purge se encaixa como mais uma subfeature (`purge/`). Dialog enriquecido com TextField + validação inline + estado de loading/error é incomum no projeto e teria menos espaço para a copy de irreversibilidade. A screen ainda permite o `AppBarWidget`/`GoBackWidget` natural para o usuário desistir antes do submit. Tradeoff: um clique extra (navegar → dialog → confirm) em vez de um único dialog, mas o ganho em clareza visual e consistência arquitetural compensa.

### 8. Parte 6 — `PasswordFieldWidget` compartilhado em `widgets/fields/`

**Decisão**: extrair `PasswordFieldWidget` para `lib/src/presentation/widgets/fields/password_field_widget.dart` antes de implementar a purge, e migrar os 5 call-sites existentes (sign_in, sign_up, password_reset_confirm ×2, profile_password ×2). Notifiers/states/intents permanecem inalterados — `obscure*` continua no state e o intent `...VisibilityToggled` continua sendo a fonte da verdade.

**Rationale**: o bloco de 5+ linhas (`obscureText`, `trailingIcon` condicional, `onTrailingIconTap`) se repete idêntico em todos os call-sites. Adicionar a 6ª réplica na purge sem extrair seria criar débito no momento exato em que ele se manifesta. A API mantém `obscure: bool` + `onToggle: VoidCallback` recebidos do exterior — o widget é puramente apresentacional e não decide quando alternar a visibilidade. Tradeoff: refatorar 5 call-sites antes da feature nova adiciona um passo de regressão visual; mitigado por ser um delegate puro para `TextFieldWidget` (sem mudança de comportamento) e por já existir cobertura indireta via testes de notifier nos campos afetados.

### 9. Parte 6 — `IUserRepository.purge` recebe email/password como primitivos (sem ler tokens)

**Decisão**: `purge` recebe `email` e `password` via parâmetros nomeados na interface de domínio. Diferente de `deactivate` (que lê o `refresh_token` via `ILocalTokenDataSource`), `purge` **não** lê tokens — o `Authorization: Bearer <access>` é injetado pelo `AuthenticationInterceptor` automaticamente em endpoints autenticados.

**Rationale**: o backend exige `email` e `password` no body como confirmação extra de identidade — esses dois primitivos vêm da camada de presentation (email lido do `userProvider`, password digitada pelo usuário) e atravessam o repositório como dados de entrada do caso de uso, não como segredo persistido. Isso simplifica o repositório e mantém a regra do CLAUDE.md de "interfaces aceitam parâmetros de domínio". `deactivate` precisa ler tokens porque o backend revoga o refresh token simetricamente — purge não tem essa simetria; o backend invalida tokens quando a conta some.

### 10. Parte 6 — `userProvider` lido defensivamente em `_submit`, não no `build`

**Decisão**: o `ProfilePurgeNotifier.build()` é **sync** (`Notifier<ProfilePurgeState>`, não `AsyncNotifier`) e retorna `const ProfilePurgeState()`. O email do usuário é lido on-demand dentro do `_submit` via `ref.read(userProvider).valueOrNull`. Caso o valor seja `null` (defensivo), o notifier seta `status: failure` com mensagem `'Não foi possível identificar o usuário.'` e retorna sem chamar o repositório.

**Rationale**: o usuário só chega à `ProfilePurgeScreen` via `ProfileDetailsScreen`, que já bloqueia em loading/error e só renderiza o botão "Excluir" no branch `AsyncData`. Ler `userProvider` de novo no `build` da purge causaria um await redundante — e tornaria o notifier `AsyncNotifier`, exigindo um switch `AsyncValue` na screen para um caminho que nunca dispara em prática. A leitura on-demand mantém o notifier simples e adiciona a guarda defensiva apenas onde ela importa (no momento do submit). Tradeoff: futuro deep-link direto para `/profile/purge` (sem passar pela detail) cairia no caminho defensivo — aceitável; rota não é pública e a UX de "carregando user antes de mostrar form" pode ser refeita com `AsyncNotifier` quando esse cenário existir.

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
- **Confirmação destrutiva ao excluir conta** — Parte 4 (provavelmente reusando `showConfirmDialog` já criado).
- **Mudança no `HomeAvatarWidget` para suportar foto/imagem** — fora de escopo.
- **Ripple custom ou indicador de "tap area"** — `BounceWidget.withOnPress` é o padrão.
