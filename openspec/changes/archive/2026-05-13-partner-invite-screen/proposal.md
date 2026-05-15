# Proposal: partner-invite-screen

## Intenção

Criar a primeira etapa da funcionalidade **Parceiros**: ao tocar no card "Convidar parceiro" no menu de Configurações, navegar para uma nova tela própria com header (title + description) e um `Placeholder` como corpo.

Hoje o card `SettingsInvitePartnerWidget` existe na `SettingsScreen` mas o `onTap` é um `() {}` hardcoded dentro da própria screen. Esta spec:

1. Cria `PartnerInviteScreen` (Stateless, sem notifier).
2. Cria `PartnerInviteLocation` registrada em `AppRoutes.partnerInvite` (`/partner/invite`).
3. Move o callback `onInvitePartner` para o construtor da `SettingsScreen` e o injeta via `SettingsLocation` (mesmo padrão de `onEditProfile`, `onNotification`, `onSubscription`, `onSignIn` já existentes).

## Motivação

A funcionalidade de Parceiros vai ser construída incrementalmente — gerar convite, ler deep link, aceitar, vincular. Antes de escrever qualquer regra de negócio, o passo zero é: tornar o card clicável e abrir uma tela vazia que sirva de "casca" pras próximas specs.

Essa spec é **viva**. Conforme as próximas etapas forem entrando (form de convite, integração com endpoint, listen pra deep link, etc.), ela é atualizada ou desdobrada em specs filhas.

## Camadas afetadas

- `lib/app_route.dart` — novo entry `partnerInvite` em `AppRoutes`.
- `lib/src/presentation/ui/partner/screens/` — **NOVA** pasta de feature com `partner_invite_screen.dart`.
- `lib/src/presentation/ui/partner/locations/` — **NOVA** com `partner_invite_location.dart`.
- `lib/src/presentation/ui/settings/screens/settings_screen.dart` — adiciona `onInvitePartner` ao construtor; remove o `() {}` inline; encaminha pro `SettingsInvitePartnerWidget`.
- `lib/src/presentation/ui/settings/locations/settings_location.dart` — passa `onInvitePartner: () => context.navigate(PartnerInviteLocation())`.

Sem mudanças em `domain/`, `data/`, `infrastructure/`, `main/providers/`. Sem notifier, sem state, sem MVI — não há interação além do botão de voltar.

## Fora do escopo

- Lógica de geração de convite (endpoint, request, response, notifier).
- Deep link de aceitação de convite.
- Datasource, repositório, validators, services específicos de parceiro.
- Empty state, loading state, error state — corpo é `Placeholder` puro até a próxima spec.
- Testes — sem notifier, sem business logic, sem widget tests no projeto pra esse role.
- Renomear/reorganizar o card existente (`SettingsInvitePartnerWidget`) — segue como está, só passa a receber o callback de verdade.
- Decidir se a tela vai ter pull-to-refresh, scroll, sliver, etc. — adiamos pra quando o conteúdo for definido.

## Decisões de design

1. **Layout de pasta plano (`partner/screens/...`), não aninhado (`partner/invite/screens/...`).**
   Segue o padrão de features simples como `notifications/`, `settings/`, `home/`. O aninhamento (estilo `profile/name/`, `profile/password/`) só faz sentido quando a feature já tem múltiplas sub-features. Se Parceiros crescer (ex: tela de aceitar convite, tela de visualizar parceiro vinculado), refatoramos pra `partner/invite/`, `partner/accept/`, etc. — YAGNI até lá.

2. **Rota `/partner/invite` em vez de `/partner`.**
   Mesmo com pasta plana, a rota já reflete o subdomínio funcional. Custa zero hoje e evita rename quando a próxima sub-feature entrar (ex: `/partner/accept`). O nome do entry no `AppRoutes` fica `partnerInvite` (camelCase de `partner-invite`).

3. **`PartnerInviteScreen` é `StatelessWidget` puro, sem `Consumer`.**
   Não há provider pra ler. Quando a próxima spec adicionar um notifier de convite, a screen passa a ter `Consumer` interno — nunca `ConsumerWidget` (regra do projeto).

4. **Header reusa `ScreenHeaderWidget` existente.**
   Mesmo widget usado em `SettingsScreen`, `ProfileNameScreen`, etc. Title e description são strings literais por enquanto — não vão pra arquivo de strings (projeto não tem i18n centralizado).

5. **Corpo é `Placeholder` (widget nativo do Flutter, dashed-X).**
   Explicitamente o widget `Placeholder()` do `flutter/material.dart`. Não é um custom `PlaceholderWidget` nosso — é o de fábrica, que deixa visualmente óbvio que a tela está incompleta. Será substituído na próxima spec.

6. **`SettingsScreen` ganha `onInvitePartner` no construtor (named, required).**
   Espelha exatamente o padrão dos outros 4 callbacks (`onSignIn`, `onEditProfile`, `onNotification`, `onSubscription`). Mantém a screen ignorante de Locations (não importa `PartnerInviteLocation`). O hoje-`() {}` inline some.

7. **Sem `AppBarWidget.title` — só `leading: GoBackWidget()`.**
   Segue o padrão de `SettingsScreen`, `ProfileNameScreen`, `NotificationsScreen`. O `ScreenHeaderWidget` no corpo já entrega o título visual. A AppBar fica enxuta.

8. **Texto do header espelha o card.**
   - `title`: `'Convidar parceiro'` (igual ao card).
   - `description`: `'Comecem a usar juntos.'` (igual ao subtitle do card, com ponto final pra ficar coerente com outras descriptions do projeto: `'Atualize o seu nome de exibição.'`, `'Gerencie suas preferências.'`).

---

## Adendo 1 — 2026-05-13 — Componentização do corpo

A v1 desta spec entregou só a casca (header + `Placeholder`). Este adendo substitui o `Placeholder` pelo corpo real da tela, conforme mockup aprovado pelo user.

### Nova intenção

Substituir o `Expanded(Placeholder())` por um corpo componentizado: indicador de par (avatar do user + linha pontilhada + slot vazio), hero textual, dois CTAs (convidar por e-mail / copiar link de convite) e nota de privacidade. Botões recebem `VoidCallback`s stub (`() {}`) — wiring real (clipboard, endpoint, deep link) vem em spec(s) filha(s).

### Mudanças no header

- `title`: `'Convidar parceiro'` → **`'Casal'`**
- `description`: `'Comecem a usar juntos.'` → **`'Vocês dois, uma única visão.'`**

A justificativa do adendo: o mockup posiciona "Casal" como categoria/agrupamento (mesma palavra usada como label da seção em Configurações: `_buildTitleItem('Casal')`) e usa o hero abaixo (`'Trocado fica melhor a dois'`) como CTA emocional. O texto antigo (`'Convidar parceiro'`) virou redundante com a hero.

### Camadas adicionadas no adendo

- `lib/src/presentation/ui/partner/widgets/` (NOVA pasta) — 4 widgets componentizados.
- `lib/src/presentation/ui/partner/widgets/painters/` (NOVA pasta) — 2 `CustomPainter` pra dashes.
- `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` — vira `Consumer` lendo `userProvider`.

Sem notifier nesta etapa — a screen só lê `userProvider` (mesmo padrão da `HomeScreen` com `HomeAppBarWidget`). Notifier de convite entra na próxima spec.

### Decisões de design do adendo

1. **Reuso de `AvatarWidget` no slot do user.**
   `AvatarWidget` já existe em `presentation/widgets/avatar/avatar_widget.dart` e já faz exatamente o que precisamos: primeira letra do nome maiúscula, fundo `primary.withValues(alpha: 0.2)`, `borderRadius: cornerRadius100` (quadrado arredondado, não círculo). Zero código novo nesse pedaço.

2. **Slot vazio espelha o `AvatarWidget` visualmente, mas com borda pontilhada.**
   Mesmo tamanho, mesmo `cornerRadius100`. Em vez de fundo sólido + letra: borda dashed + `Icons.person_add_alt` cinza. Decisão do user: "não full rounded, deixa quadrado/ovalado igual a letra do nome".

3. **Dashes via `CustomPainter` próprio — sem dependência nova.**
   Dois painters: `DashedLinePainter` (conector horizontal) e `DashedRoundedRectPainter` (borda do slot vazio). ~30 linhas cada. Ficam em `widgets/painters/` pra não poluir o widget e facilitar isolamento futuro (ex: preview, reuso).

4. **`PartnerInviteActionsWidget` agrupa os dois botões.**
   Os botões "Convidar por e-mail" e "Copiar link de convite" sempre aparecem juntos e nessa ordem — não vejo cenário onde apenas um apareça. Agrupar reduz props na screen (de 2 callbacks soltos pra 1 widget que recebe 2 callbacks) e centraliza o spacing entre eles.

5. **`PartnerInviteHeroWidget` e `PartnerInviteSecurityNoteWidget` são puramente estáticos.**
   Textos hardcoded em `const`. Sem props. Se virarem dinâmicos no futuro (A/B test, copy variável por tipo de conta, etc.), promovemos pra props — YAGNI até lá.

6. **Screen lê `userProvider` direto via `Consumer` + `ref.watch`.**
   Mesmo padrão da `HomeScreen` que passa `AsyncValue<UserModel>` pro `HomeAppBarWidget`. `PartnerPairIndicatorWidget` recebe `AsyncValue<UserModel> userState` e trata loading com `Skeletonizer` (idem `HomeAppBarWidget`).

   Esse acesso NÃO viola a regra "services só via notifier" do CLAUDE.md: `userProvider` é um data provider (entrega `UserModel`), não service (sem lógica de formatação que precise ser cacheada no state). Confirmado pelo precedente da `HomeScreen`.

7. **Botões usam `child: Icon(...)` do `ButtonWidget`.**
   `ButtonWidget` já aceita `child` + `label` simultâneos e renderiza `Row(spacing: 8, children: [?child, Text(label)])`. Reuso direto — sem variant novo, sem fork.

8. **Sem mudança em `domain/`, `data/`, `infrastructure/`, `main/providers/`.**
   `userProvider` já existe e já é provider em `presentation/notifiers/user_notifier.dart`. Nenhum endpoint, request, response novo.

### Fora do escopo do adendo

- Lógica real dos botões (`Clipboard.setData`, chamada de endpoint pra gerar link, navegação pra screen/sheet de convite por e-mail).
- Endpoint, datasource, repository, request, response de convite.
- `PartnerInviteNotifier` / state / intent.
- Deep link de aceite de convite.
- Empty state quando já há convite pendente / partner vinculado.
- `@TrocadoPreview` dos novos widgets — adiar pra spec filha quando os widgets estabilizarem.
- Testes — sem business logic, sem widget tests no projeto pra esse role.
