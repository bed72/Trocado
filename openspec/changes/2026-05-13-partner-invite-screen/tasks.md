# Tasks: partner-invite-screen

## v1 — casca (concluída)

### main/

- [x] `lib/app_route.dart` — adicionar `static final partnerInvite = AppRoutes._(path: '/partner/invite', name: 'partner-invite-route', regex: RegExp(r'^/partner/invite$'))`; incluir `partnerInvite` em `_all`

### presentation/ui/partner/ (NOVA feature)

- [x] `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` (NOVO) — `StatelessWidget` com `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + `Padding(all: 16)` + `Column` contendo `ScreenHeaderWidget(title: 'Convidar parceiro', description: 'Comecem a usar juntos.')` + `SizedBox(height: 16)` + `Expanded(child: Placeholder())`  (será reescrito na v2)
- [x] `lib/src/presentation/ui/partner/locations/partner_invite_location.dart` (NOVO) — `final class PartnerInviteLocation extends Location`, `path => AppRoutes.partnerInvite.path`, `pageBuilder => (_) => screenPage(const PartnerInviteScreen())`

### presentation/ui/settings/ (WIRE-UP)

- [x] `lib/src/presentation/ui/settings/screens/settings_screen.dart` — adicionar `final VoidCallback onInvitePartner` (required) ao construtor; no getter `_buildCouple`, trocar `SettingsInvitePartnerWidget(onTap: () {})` por `SettingsInvitePartnerWidget(onTap: onInvitePartner)`
- [x] `lib/src/presentation/ui/settings/locations/settings_location.dart` — importar `PartnerInviteLocation`; passar `onInvitePartner: () => context.navigate(PartnerInviteLocation())` ao construir `SettingsScreen`

### Verificação v1

- [x] `flutter analyze` — zero issues nos arquivos tocados
- [x] `flutter test` — verde (606 testes; sem regressão)
- [ ] Smoke: `flutter run` → entrar em Configurações → tocar no card "Convidar parceiro" → tela abre com header e Placeholder visível → botão de voltar funciona e retorna pra Settings
- [x] `PartnerInviteScreen` é `StatelessWidget` (não `ConsumerWidget`)
- [x] `SettingsScreen` NÃO importa `PartnerInviteLocation` nem nada de `presentation/ui/partner/`

---

## v2 — corpo componentizado

### presentation/ui/partner/widgets/painters/ (NOVA pasta)

- [x] `lib/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart` (NOVO) — `CustomPainter` com `Color color, double strokeWidth, dashLength, dashGap`; desenha linha horizontal pontilhada via loop `drawLine` em `y = size.height / 2`; `strokeCap: .round`; `shouldRepaint` compara todos os campos
- [x] `lib/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart` (NOVO) — `CustomPainter` com `Radius radius, Color color, double strokeWidth, dashLength, dashGap`; desenha borda pontilhada num `RRect.fromRectAndRadius(rect, radius)` iterando `path.computeMetrics()` + `metric.extractPath(start, end)` por dash; `strokeCap: .round`; `shouldRepaint` compara todos os campos

### presentation/ui/partner/widgets/ (NOVA pasta)

- [x] `lib/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart` (NOVO) — `StatelessWidget` recebendo `AsyncValue<UserModel> userState` (required); `Row(mainAxisAlignment: .center)` com `AvatarWidget(size: 72, name: user?.name ?? 'Carregando')` + `SizedBox(width: 56, height: 2) > CustomPaint(DashedLinePainter(color: outlineVariant, ...))` + slot vazio `SizedBox(72 × 72) > CustomPaint(DashedRoundedRectPainter(radius: cornerRadius100.topLeft, ...), child: Center(Icon(person_add_alt, size: 28, color: onSurfaceVariant)))`; envolto em `Skeletonizer(enabled: userState is AsyncLoading)`
- [x] `lib/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart` (NOVO) — `StatelessWidget` sem props; `Column(crossAxisAlignment: .center)` com `Text('Trocado fica melhor a dois', textAlign: .center, titleLarge bold)` + `SizedBox(8)` + `Text('Compartilhem orçamentos, vejam quem gastou o quê — sem precisar perguntar.', textAlign: .center, bodyMedium, color: onSurfaceVariant)`
- [x] `lib/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart` (NOVO) — `StatelessWidget` com `VoidCallback onInviteByEmail, onCopyLink` (required); `Column` com `SizedBox(width: double.infinity, child: ButtonWidget.elevated(label: 'Convidar por e-mail', child: Icon(mail_outline, size: 20), onTap: onInviteByEmail))` + `SizedBox(12)` + `SizedBox(width: double.infinity, child: ButtonWidget.outlined(label: 'Copiar link de convite', child: Icon(link, size: 20), onTap: onCopyLink))`
- [x] `lib/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart` (NOVO) — `StatelessWidget` sem props; `Container(padding: all(12), decoration: BoxDecoration(borderRadius: cornerRadius100, color: primary.withValues(alpha: 0.08)))` envolvendo `Row(spacing: 12, crossAxisAlignment: .start)` com `Icon(shield_outlined, size: 20, color: primary)` + `Expanded(Text('Vocês compartilham orçamentos e despesas, mas senhas e dados de login são individuais.', bodySmall, color: onSurfaceVariant))`

### presentation/ui/partner/screens/ (REESCRITA)

- [x] `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` — adicionar imports (`flutter_riverpod`, `user_notifier`, 4 widgets novos); manter `StatelessWidget`; envolver corpo em `Consumer(builder: (_, ref, _) { final userState = ref.watch(userProvider); return Column(...); })`; trocar header text (`'Casal'` / `'Vocês dois, uma única visão.'`); substituir `Expanded(Placeholder())` pela sequência: `PartnerPairIndicatorWidget(userState)` + sp32 + `PartnerInviteHeroWidget()` + sp24 + `PartnerInviteActionsWidget(onInviteByEmail: () {}, onCopyLink: () {})` + sp16 + `PartnerInviteSecurityNoteWidget()`

### Pré-condições v2 (já satisfeitas)

- `AvatarWidget` existe (`presentation/widgets/avatar/avatar_widget.dart`) e aceita `size` e `name`
- `userProvider` existe (`presentation/notifiers/user_notifier.dart`) e devolve `AsyncValue<UserModel>`
- `UserModel` existe (`domain/models/user_model.dart`) com campo `name`
- `Skeletonizer` está no pubspec (`skeletonizer: ^2.1.3`)
- `ButtonWidget.elevated` / `.outlined` aceitam `child` + `label` simultâneos e renderizam `Row(spacing: 8, children: [?child, Text(label)])` internamente
- `context.radius.cornerRadius100` retorna `BorderRadius` uniforme (4 cantos iguais) — `.topLeft` devolve o `Radius` pra passar ao painter
- `context.colors.outlineVariant`, `primary`, `onSurfaceVariant` existem no theme

### Verificação v2

- [x] `flutter analyze lib/src/presentation/ui/partner` — zero issues
- [x] `flutter test` — verde (sem novos testes; suíte existente não regrediu)
- [ ] Smoke: `flutter run` → Settings → tocar "Convidar parceiro" → tela abre com Casal/descrição, par-indicator (avatar com letra + linha pontilhada + slot pontilhado com person_add), hero "Trocado fica melhor a dois", 2 botões full-width, nota de privacidade verde-clara → botões não fazem nada → voltar funciona
- [x] `PartnerInviteScreen` continua `StatelessWidget` (não `ConsumerWidget`) — `Consumer` é interno
- [x] Painters NÃO contêm `Widget` (são `CustomPainter` puros)
- [x] `PartnerPairIndicatorWidget` reusa `AvatarWidget` existente (não duplica visual de avatar)
- [x] Slot vazio tem mesmo `borderRadius` que o `AvatarWidget` (`cornerRadius100`) — não é círculo
