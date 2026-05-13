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
