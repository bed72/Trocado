# Spec: partner-invite-screen

> v2 (2026-05-13) — corpo componentizado. Substituiu o `Placeholder` da v1 pelo layout real do mockup. Botões ainda recebem callbacks stub (`() {}`) — wiring real vem em spec(s) filha(s).

## Capability

Permitir ao user abrir uma tela dedicada de Casal ao tocar no card "Convidar parceiro" em Configurações. A tela apresenta visualmente o conceito de par (avatar do user + slot vazio), explica o valor da feature ("Trocado fica melhor a dois") e oferece dois caminhos de convite (e-mail e link), além de uma nota de privacidade.

## Comportamento

### Gatilho

- Em `SettingsScreen`, ao tocar no `SettingsInvitePartnerWidget` (card "Convidar parceiro" / "Comecem a usar juntos"), o app SHALL navegar para `PartnerInviteLocation`.
- A navegação SHALL ser feita via `context.navigate(PartnerInviteLocation())` injetado pela `SettingsLocation` no callback `onInvitePartner` da `SettingsScreen`.
- `SettingsScreen` SHALL receber `onInvitePartner` como `VoidCallback` `required` no construtor, espelhando o padrão de `onEditProfile`, `onNotification`, `onSubscription`, `onSignIn`.
- `SettingsScreen` NÃO pode importar `PartnerInviteLocation` nem qualquer artefato de `presentation/ui/partner/`. O conhecimento da rota fica isolado na `SettingsLocation`.

### Rota

- `AppRoutes.partnerInvite` SHALL existir em `lib/app_route.dart` com:
  - `path`: `'/partner/invite'`
  - `name`: `'partner-invite-route'`
  - `regex`: `RegExp(r'^/partner/invite$')`
- `AppRoutes.partnerInvite` SHALL estar incluído na lista `_all` (usada por `AppRoutes.match`).

### `PartnerInviteLocation`

- Vive em `lib/src/presentation/ui/partner/locations/partner_invite_location.dart`.
- `extends Location` (do `duck_router`).
- `path` SHALL retornar `AppRoutes.partnerInvite.path`.
- `pageBuilder` SHALL retornar `screenPage(const PartnerInviteScreen())`.
- Sem callbacks injetados nesta etapa (nenhuma navegação saindo da tela além do botão de voltar nativo).

### `PartnerInviteScreen`

- Vive em `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart`.
- `class PartnerInviteScreen extends StatelessWidget`. NUNCA `ConsumerWidget`.
- Construtor `const PartnerInviteScreen({super.key})` — sem parâmetros.
- Lê `userProvider` (de `presentation/notifiers/user_notifier.dart`) via `Consumer` interno + `ref.watch`. NUNCA `ConsumerWidget`.
- Estrutura:
  - `ScaffoldWidget` como raiz.
  - `appBar: AppBarWidget(leading: GoBackWidget())` — sem `title`, sem `actions`.
  - Corpo: `Padding(all: 16)` envolvendo `Consumer > Column(crossAxisAlignment: .start)` com a seguinte sequência:
    1. `ScreenHeaderWidget(title: 'Casal', description: 'Vocês dois, uma única visão.')`
    2. `SizedBox(height: 32.0)`
    3. `PartnerPairIndicatorWidget(userState: ref.watch(userProvider))`
    4. `SizedBox(height: 32.0)`
    5. `PartnerInviteHeroWidget()`
    6. `SizedBox(height: 24.0)`
    7. `PartnerInviteActionsWidget(onInviteByEmail: () {}, onCopyLink: () {})`
    8. `SizedBox(height: 16.0)`
    9. `PartnerInviteSecurityNoteWidget()`
- Os `VoidCallback`s passados ao `PartnerInviteActionsWidget` SHALL ser `() {}` literais nesta spec. Wiring real (clipboard, navegação, endpoint) é responsabilidade de spec filha.

### Botão de voltar

- O `GoBackWidget` da `AppBarWidget` SHALL ser o único caminho de saída da tela nesta etapa.
- Tocar nele SHALL fazer `context.pop()` (comportamento padrão do widget).

### Card de origem em Settings

- `settings_screen.dart` SHALL passar `onTap: onInvitePartner` ao `SettingsInvitePartnerWidget` no getter `_buildCouple`.
- O valor `() {}` hardcoded atualmente nesse local SHALL ser removido.
- Nenhuma outra mudança em `SettingsInvitePartnerWidget` (`presentation/ui/settings/widgets/settings_invite_partner_widget.dart`) — a API dele já aceita `VoidCallback onTap`.

### `PartnerPairIndicatorWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart`.
- `StatelessWidget`. Recebe `AsyncValue<UserModel> userState` (required).
- Layout: `Row(mainAxisAlignment: .center)` com `[AvatarWidget(size: 72), conector pontilhado, slot vazio pontilhado]`.
- Slot do user: reusa `AvatarWidget` (de `presentation/widgets/avatar/avatar_widget.dart`) com `size: 72` e `name: user?.name ?? 'Carregando'`. **Não** duplica visual nem cria novo widget de avatar.
- Conector: `SizedBox(width: 56, height: 2)` com `CustomPaint(painter: DashedLinePainter(...))`.
- Slot vazio: `SizedBox(72 × 72)` com `CustomPaint(painter: DashedRoundedRectPainter(radius: cornerRadius100.topLeft, ...))` e `Center(Icon(Icons.person_add_alt, size: 28, color: onSurfaceVariant))` no `child`.
- Loading (`userState is AsyncLoading`): widget inteiro envolto em `Skeletonizer(enabled: true)` (mesma técnica da `HomeAppBarWidget`).
- Cor dos dashes: `context.colors.outlineVariant`.

### `PartnerInviteHeroWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart`.
- `StatelessWidget`. Sem props.
- Layout: `Column(crossAxisAlignment: .center)` com `Text` título + `SizedBox(8)` + `Text` descrição.
- Título: `'Trocado fica melhor a dois'`, `titleLarge` bold, `textAlign: .center`.
- Descrição: `'Compartilhem orçamentos, vejam quem gastou o quê — sem precisar perguntar.'`, `bodyMedium`, cor `onSurfaceVariant`, `textAlign: .center`.

### `PartnerInviteActionsWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart`.
- `StatelessWidget`. Recebe `VoidCallback onInviteByEmail` e `VoidCallback onCopyLink` (ambos required).
- Layout: `Column` com 2 `SizedBox(width: double.infinity, child: ButtonWidget.*)` separados por `SizedBox(height: 12)`.
- Primeiro botão (primário): `ButtonWidget.elevated(label: 'Convidar por e-mail', child: Icon(Icons.mail_outline, size: 20), onTap: onInviteByEmail)`.
- Segundo botão (secundário): `ButtonWidget.outlined(label: 'Copiar link de convite', child: Icon(Icons.link, size: 20), onTap: onCopyLink)`.

### `PartnerInviteSecurityNoteWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart`.
- `StatelessWidget`. Sem props.
- Layout: `Container` com `padding: all(12)`, `decoration: BoxDecoration(borderRadius: cornerRadius100, color: primary.withValues(alpha: 0.08))`.
- Conteúdo: `Row(spacing: 12, crossAxisAlignment: .start)` com `Icon(Icons.shield_outlined, size: 20, color: primary)` + `Expanded(Text(...))`.
- Texto: `'Vocês compartilham orçamentos e despesas, mas senhas e dados de login são individuais.'`, `bodySmall`, cor `onSurfaceVariant`.

### `DashedLinePainter`

- Vive em `lib/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart`.
- `class DashedLinePainter extends CustomPainter`.
- Props: `Color color`, `double strokeWidth`, `double dashLength`, `double dashGap` (todos required).
- Desenha linha horizontal pontilhada no centro vertical da `size` recebida. `strokeCap: .round`.
- `shouldRepaint` compara todos os campos.

### `DashedRoundedRectPainter`

- Vive em `lib/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart`.
- `class DashedRoundedRectPainter extends CustomPainter`.
- Props: `Radius radius`, `Color color`, `double strokeWidth`, `double dashLength`, `double dashGap` (todos required).
- Desenha borda pontilhada num `RRect.fromRectAndRadius(rect, radius)` usando `path.computeMetrics()` → `metric.extractPath(start, end)` por dash.
- `shouldRepaint` compara todos os campos.

## Não-comportamentos

- **Não** há notifier, state, intent, repository, datasource, request, response associado à tela nesta spec. `userProvider` é leitura simples — não é notifier desta feature.
- **Não** há `ref.listen` (sem evento pra escutar).
- **Não** há leitura/escrita de deep link.
- **Não** há `AppBarWidget.title` nem `actions` — somente `leading`.
- **Não** há toast, dialog, snackbar, error state. Loading do user é tratado por `Skeletonizer` no `PartnerPairIndicatorWidget`.
- **Não** há scroll (`SingleChildScrollView`, `CustomScrollView`) — corpo cabe sem rolagem em viewports típicos.
- **Não** há clipboard, `Clipboard.setData`, integração com Share Sheet, navegação pra screen/sheet de form de e-mail. Os callbacks dos botões SHALL ser `() {}` stub nesta spec.
- **Não** há mudança em `onNotification` ou `onSubscription` da `SettingsScreen` — continuam `() {}` na `SettingsLocation`.
- **Não** há `Placeholder` (widget nativo) no corpo — foi substituído pelo layout componentizado.
- **Não** há testes nesta spec (sem business logic, sem widget tests no projeto pra esse role).
- **Não** há `@TrocadoPreview` nesta spec.
- **Não** há criação de pasta `notifiers/`, `data/`, `validators/` em `presentation/ui/partner/` — apenas `screens/`, `locations/` e `widgets/{,painters/}`.
- **Não** há novo entry no `AppRoutes` além de `partnerInvite` (já criado na v1).

## Estrutura de arquivos

### Criar (v2)

- `lib/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart`
- `lib/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart`
- `lib/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart`
- `lib/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart`
- `lib/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart`
- `lib/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart`

### Modificar (v2)

- `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` — vira `Consumer`, lê `userProvider`, troca textos do header, substitui `Expanded(Placeholder())` pela `Column` componentizada.

### Criados na v1 (mantidos)

- `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` (modificado em v2)
- `lib/src/presentation/ui/partner/locations/partner_invite_location.dart` (intocado em v2)
- `openspec/changes/2026-05-13-partner-invite-screen/{proposal,design,tasks,specs/spec}.md`

### Modificados na v1 (intocados em v2)

- `lib/app_route.dart`
- `lib/src/presentation/ui/settings/locations/settings_location.dart`
- `lib/src/presentation/ui/settings/screens/settings_screen.dart`
