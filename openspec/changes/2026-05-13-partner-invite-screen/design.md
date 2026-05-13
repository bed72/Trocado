# Design: partner-invite-screen

## Visão geral

Casca visual da feature Parceiros. Uma tela nova, uma rota nova, um wire-up de callback no Settings. Zero camadas de domínio/dados.

```
[Settings] --tap card "Convidar parceiro"--> [PartnerInviteScreen]
                                                  ├── AppBarWidget(leading: GoBackWidget)
                                                  └── Padding(16)
                                                      └── Column
                                                          ├── ScreenHeaderWidget(title, description)
                                                          └── Placeholder()   ← Flutter nativo
```

---

## `app_route.dart`

Adicionar entry:

```dart
static final partnerInvite = AppRoutes._(
  path: '/partner/invite',
  name: 'partner-invite-route',
  regex: RegExp(r'^/partner/invite$'),
);
```

E incluir em `_all` (lista usada por `AppRoutes.match`):

```dart
static final _all = [
  date,
  exit,
  home,
  budget,
  budgets,
  splash,
  signIn,
  signUp,
  expense,
  profile,
  expenses,
  category,
  settings,
  calculator,
  dateRange,
  profileName,
  expenseDate,
  profileDelete,
  notifications,
  partnerInvite,           // NOVO
  expensesFilter,
  forgotPassword,
  profilePassword,
  passwordResetConfirm,
  forgotPasswordSuccess,
];
```

---

## `PartnerInviteLocation`

`lib/src/presentation/ui/partner/locations/partner_invite_location.dart`:

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/partner/screens/partner_invite_screen.dart';

final class PartnerInviteLocation extends Location {
  @override
  String get path => AppRoutes.partnerInvite.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const PartnerInviteScreen());
}
```

Sem callbacks injetados nesta primeira etapa — a screen só precisa do botão de voltar (já vem do `GoBackWidget` interno). Quando o convite for criado e for preciso navegar pra confirmação/sucesso, a Location passa a injetar `onSuccess` etc.

---

## `PartnerInviteScreen`

`lib/src/presentation/ui/partner/screens/partner_invite_screen.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

class PartnerInviteScreen extends StatelessWidget {
  const PartnerInviteScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        crossAxisAlignment: .start,
        children: const [
          ScreenHeaderWidget(
            title: 'Convidar parceiro',
            description: 'Comecem a usar juntos.',
          ),
          SizedBox(height: 16.0),
          Expanded(child: Placeholder()),
        ],
      ),
    ),
  );
}
```

`Expanded(child: Placeholder())` garante que o widget nativo ocupe o espaço restante e fique visualmente óbvio. `Placeholder` sem `Expanded` colapsa pra um quadrado pequeno em `Column` — fica feio e confuso.

---

## `SettingsScreen` — diff

`lib/src/presentation/ui/settings/screens/settings_screen.dart`:

1. **Construtor:** adicionar `onInvitePartner` como `required`:

```dart
class SettingsScreen extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onEditProfile;
  final VoidCallback onNotification;
  final VoidCallback onSubscription;
  final VoidCallback onInvitePartner;     // NOVO

  const SettingsScreen({
    super.key,
    required this.onSignIn,
    required this.onEditProfile,
    required this.onNotification,
    required this.onSubscription,
    required this.onInvitePartner,        // NOVO
  });
  ...
}
```

2. **`_buildCouple`:** troca o `() {}` inline:

```dart
List<Widget> get _buildCouple => [
  _buildTitleItem('Casal'),
  const SizedBox(height: 8.0),
  SettingsInvitePartnerWidget(onTap: onInvitePartner),   // antes: () {}
];
```

Nada mais muda na screen.

---

## `SettingsLocation` — diff

`lib/src/presentation/ui/settings/locations/settings_location.dart`:

Adicionar import de `PartnerInviteLocation` e passar o callback:

```dart
import 'package:trocado/src/presentation/ui/partner/locations/partner_invite_location.dart';

...

@override
LocationPageBuilder get pageBuilder =>
    (context) => screenPage(
      SettingsScreen(
        onNotification: () {},
        onSubscription: () {},
        onInvitePartner: () => context.navigate(PartnerInviteLocation()),  // NOVO
        onEditProfile: () => context.navigate(ProfileDetailsLocation()),
        onSignIn: () =>
            context.clear(SignInLocation(), root: true, replace: true),
      ),
    );
```

`onNotification` e `onSubscription` continuam `() {}` (essas features ainda não têm tela). Esta spec **não** mexe nelas — só adiciona `onInvitePartner`.

---

## Decisões de design

1. **`Placeholder` é nativo, não wrapper.**
   `flutter/material.dart` já exporta. Sem criar `PartnerInvitePlaceholderWidget` ou similar — o ponto é justamente ser o widget de "WIP" do framework, óbvio que vai ser substituído.

2. **`SizedBox(height: 16)` entre header e placeholder.**
   Mesma respiração visual de `SettingsScreen` (`SizedBox(height: 8)` entre `ScreenHeaderWidget` e `Expanded`). Usei 16 aqui pra dar mais ar enquanto o corpo é só placeholder — quando o corpo real entrar (form, lista, etc.), reavalia.

3. **Sem `SafeArea`/`SingleChildScrollView` no corpo agora.**
   `ScaffoldWidget` (do projeto) já trata SafeArea. Scroll só faz sentido quando houver conteúdo que justifique — adiciona na próxima spec se o form estourar.

4. **Não criar `partner_invite_state.dart`, `partner_invite_intent.dart`, `partner_invite_notifier.dart`.**
   Não tem state. Criar arquivos vazios "preparando o terreno" viola "sem half-finished implementations" (CLAUDE.md). Próxima spec cria quando precisar.

5. **Não tocar em `widgets/cards/icon_card_widget.dart` nem em `settings_invite_partner_widget.dart`.**
   O card já tem a API certa (`onTap` recebe `VoidCallback`). Único diff é o caller passar um callback real em vez de `() {}`.

6. **Sem widget previews nesta spec.**
   `PartnerInviteScreen` com header + `Placeholder` não tem variação visual significativa pra justificar `@TrocadoPreview`. Quando o corpo real entrar (com estados de loading/error/success ou variações de form), aí sim se cria preview.

7. **Sem deep link nesta etapa.**
   `DeepLinkHandler` em `lib/src/main/deep_link/` não muda. Quando o convite por URL existir, a próxima spec acrescenta o handler — não é responsabilidade desta casca.
