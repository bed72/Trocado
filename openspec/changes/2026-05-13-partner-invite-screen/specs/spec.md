# Spec: partner-invite-screen

## Capability

Permitir ao user abrir uma tela dedicada de "Convidar parceiro" ao tocar no card homônimo em Configurações. Tela serve como casca visual — header com title + description e um `Placeholder` no corpo — sobre a qual as próximas specs vão construir o fluxo real de convite.

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
- Construtor `const PartnerInviteScreen({super.key})` — sem parâmetros nesta etapa.
- Estrutura:
  - `ScaffoldWidget` como raiz.
  - `appBar: AppBarWidget(leading: GoBackWidget())` — sem `title`, sem `actions`.
  - Corpo: `Padding(all: 16)` envolvendo `Column(crossAxisAlignment: .start)` com:
    1. `ScreenHeaderWidget(title: 'Convidar parceiro', description: 'Comecem a usar juntos.')`
    2. `SizedBox(height: 16.0)`
    3. `Expanded(child: Placeholder())` — `Placeholder` é o widget nativo do Flutter (`flutter/material.dart`), não wrapper do projeto.

### Botão de voltar

- O `GoBackWidget` da `AppBarWidget` SHALL ser o único caminho de saída da tela nesta etapa.
- Tocar nele SHALL fazer `context.pop()` (comportamento padrão do widget).

### Card de origem em Settings

- `settings_screen.dart` SHALL passar `onTap: onInvitePartner` ao `SettingsInvitePartnerWidget` no getter `_buildCouple`.
- O valor `() {}` hardcoded atualmente nesse local SHALL ser removido.
- Nenhuma outra mudança em `SettingsInvitePartnerWidget` (`presentation/ui/settings/widgets/settings_invite_partner_widget.dart`) — a API dele já aceita `VoidCallback onTap`.

## Não-comportamentos

- **Não** há notifier, state, intent, repository, datasource, request, response associado à tela nesta spec.
- **Não** há `Consumer`, `ref.watch`, `ref.listen` na screen — sem provider pra consumir.
- **Não** há leitura/escrita de deep link.
- **Não** há `AppBarWidget.title` nem `actions` — somente `leading`.
- **Não** há toast, dialog, snackbar, loading indicator ou error state.
- **Não** há scroll (`SingleChildScrollView`, `CustomScrollView`) — corpo é estático.
- **Não** há mudança em `onNotification` ou `onSubscription` da `SettingsScreen` — continuam `() {}` na `SettingsLocation`.
- **Não** há testes nesta spec (sem business logic, sem widget tests no projeto pra esse role).
- **Não** há `@TrocadoPreview` nesta spec (sem variação visual significativa).
- **Não** há criação de pasta `notifiers/`, `widgets/`, `data/`, `validators/` em `presentation/ui/partner/` — apenas `screens/` e `locations/`.

## Estrutura de arquivos

### Criar

- `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart`
- `lib/src/presentation/ui/partner/locations/partner_invite_location.dart`
- `openspec/changes/2026-05-13-partner-invite-screen/proposal.md`
- `openspec/changes/2026-05-13-partner-invite-screen/design.md`
- `openspec/changes/2026-05-13-partner-invite-screen/tasks.md`
- `openspec/changes/2026-05-13-partner-invite-screen/specs/spec.md`

### Modificar

- `lib/app_route.dart` — adicionar `partnerInvite` e incluir em `_all`.
- `lib/src/presentation/ui/settings/locations/settings_location.dart` — importar `PartnerInviteLocation` e passar `onInvitePartner`.
- `lib/src/presentation/ui/settings/screens/settings_screen.dart` — adicionar `onInvitePartner` ao construtor; usar em `_buildCouple`.
