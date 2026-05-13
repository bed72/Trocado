# Tasks: partner-invite-screen

## main/

- [x] `lib/app_route.dart` — adicionar `static final partnerInvite = AppRoutes._(path: '/partner/invite', name: 'partner-invite-route', regex: RegExp(r'^/partner/invite$'))`; incluir `partnerInvite` em `_all`

## presentation/ui/partner/ (NOVA feature)

- [x] `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` (NOVO) — `StatelessWidget` com `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + `Padding(all: 16)` + `Column` contendo `ScreenHeaderWidget(title: 'Convidar parceiro', description: 'Comecem a usar juntos.')` + `SizedBox(height: 16)` + `Expanded(child: Placeholder())`
- [x] `lib/src/presentation/ui/partner/locations/partner_invite_location.dart` (NOVO) — `final class PartnerInviteLocation extends Location`, `path => AppRoutes.partnerInvite.path`, `pageBuilder => (_) => screenPage(const PartnerInviteScreen())`

## presentation/ui/settings/ (WIRE-UP)

- [x] `lib/src/presentation/ui/settings/screens/settings_screen.dart` — adicionar `final VoidCallback onInvitePartner` (required) ao construtor; no getter `_buildCouple`, trocar `SettingsInvitePartnerWidget(onTap: () {})` por `SettingsInvitePartnerWidget(onTap: onInvitePartner)`
- [x] `lib/src/presentation/ui/settings/locations/settings_location.dart` — importar `PartnerInviteLocation`; passar `onInvitePartner: () => context.navigate(PartnerInviteLocation())` ao construir `SettingsScreen`

## Pré-condições (já satisfeitas)

- `ScreenHeaderWidget` existe (`presentation/widgets/screen_header_widget.dart`)
- `ScaffoldWidget`, `AppBarWidget`, `GoBackWidget` existem (`presentation/widgets/`)
- `SettingsInvitePartnerWidget` existe e já aceita `VoidCallback onTap` (`presentation/ui/settings/widgets/`)
- `screenPage` existe (`presentation/pages/screen_page.dart`)
- `duck_router` `Location` e `context.navigate` funcionando (usado em todas as outras Locations)

## Verificação

- [x] `flutter analyze` — zero issues nos arquivos tocados
- [x] `flutter test` — verde (suíte existente não regrediu; sem novos testes)
- [ ] Smoke: `flutter run` → entrar em Configurações → tocar no card "Convidar parceiro" → tela abre com header e Placeholder visível → botão de voltar funciona e retorna pra Settings
- [x] `PartnerInviteScreen` é `StatelessWidget` (não `ConsumerWidget`)
- [x] `SettingsScreen` NÃO importa `PartnerInviteLocation` nem nada de `presentation/ui/partner/`
- [x] `Placeholder` no corpo é o widget nativo do `flutter/material.dart` (não wrapper custom)
