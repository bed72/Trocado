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

---

# v2 — 2026-05-13 — Corpo componentizado

A v1 (acima) entregou o `Placeholder`. Esta seção descreve o corpo real, conforme mockup aprovado pelo user.

## Layout completo

```
PartnerInviteScreen (Consumer, lê userProvider)
└── ScaffoldWidget
    ├── AppBarWidget(leading: GoBackWidget())
    └── Padding(all: 16)
        └── Column(crossAxisAlignment: .start)
            ├── ScreenHeaderWidget(title: 'Casal', description: 'Vocês dois, uma única visão.')
            ├── SizedBox(height: 32)
            ├── PartnerPairIndicatorWidget(userState)
            ├── SizedBox(height: 32)
            ├── PartnerInviteHeroWidget()
            ├── SizedBox(height: 24)
            ├── PartnerInviteActionsWidget(onInviteByEmail: () {}, onCopyLink: () {})
            ├── SizedBox(height: 16)
            └── PartnerInviteSecurityNoteWidget()
```

Spacings entre seções: 32 (header → indicator), 32 (indicator → hero), 24 (hero → actions), 16 (actions → security note). Maior respiração ao redor do indicator (elemento visual central); menor entre actions e nota (relação semântica próxima).

## `PartnerInviteScreen` — diff sobre a v1

`lib/src/presentation/ui/partner/screens/partner_invite_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart';

class PartnerInviteScreen extends StatelessWidget {
  const PartnerInviteScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          final userState = ref.watch(userProvider);

          return Column(
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Casal',
                description: 'Vocês dois, uma única visão.',
              ),
              const SizedBox(height: 32.0),
              PartnerPairIndicatorWidget(userState: userState),
              const SizedBox(height: 32.0),
              const PartnerInviteHeroWidget(),
              const SizedBox(height: 24.0),
              PartnerInviteActionsWidget(
                onInviteByEmail: () {},
                onCopyLink: () {},
              ),
              const SizedBox(height: 16.0),
              const PartnerInviteSecurityNoteWidget(),
            ],
          );
        },
      ),
    ),
  );
}
```

Trocas vs v1:
- `StatelessWidget` continua (regra do projeto: nunca `ConsumerWidget`).
- `Consumer` agora é interno, lê `userProvider`.
- Header text muda (`'Casal'` / `'Vocês dois, uma única visão.'`).
- `Expanded(Placeholder())` removido — corpo agora tem altura intrínseca.

`PartnerInviteLocation` **não muda** — continua `screenPage(const PartnerInviteScreen())`.

## `PartnerPairIndicatorWidget`

`lib/src/presentation/ui/partner/widgets/partner_pair_indicator_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/avatar/avatar_widget.dart';

import 'package:trocado/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart';

class PartnerPairIndicatorWidget extends StatelessWidget {
  static const double _slotSize = 72.0;
  static const double _connectorWidth = 56.0;
  static const double _connectorHeight = 2.0;

  final AsyncValue<UserModel> userState;

  const PartnerPairIndicatorWidget({super.key, required this.userState});

  @override
  Widget build(BuildContext context) {
    final isLoading = userState is AsyncLoading;
    final user = switch (userState) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return Skeletonizer(
      enabled: isLoading,
      child: Row(
        mainAxisAlignment: .center,
        children: [
          AvatarWidget(
            size: _slotSize,
            name: user?.name ?? 'Carregando',
          ),
          SizedBox(
            width: _connectorWidth,
            height: _connectorHeight,
            child: CustomPaint(
              painter: DashedLinePainter(
                color: context.colors.outlineVariant,
                strokeWidth: _connectorHeight,
                dashLength: 6.0,
                dashGap: 4.0,
              ),
            ),
          ),
          _buildEmptySlot(context),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context) => SizedBox(
    width: _slotSize,
    height: _slotSize,
    child: CustomPaint(
      painter: DashedRoundedRectPainter(
        radius: context.radius.cornerRadius100.topLeft,
        color: context.colors.outlineVariant,
        strokeWidth: 1.5,
        dashLength: 6.0,
        dashGap: 4.0,
      ),
      child: Center(
        child: Icon(
          Icons.person_add_alt,
          size: 28.0,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
```

**Sobre o `Radius` passado ao painter:** `context.radius.cornerRadius100` é `BorderRadius` (4 cantos). O painter precisa apenas de um `Radius` uniforme — pego `topLeft` (todos são iguais no theme). Se algum dia o theme tiver cantos não uniformes, ajustamos o painter pra aceitar `BorderRadius` direto.

## `PartnerInviteHeroWidget`

`lib/src/presentation/ui/partner/widgets/partner_invite_hero_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class PartnerInviteHeroWidget extends StatelessWidget {
  const PartnerInviteHeroWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .center,
    children: [
      Text(
        'Trocado fica melhor a dois',
        textAlign: .center,
        style: context.typography.titleLarge?.copyWith(fontWeight: .bold),
      ),
      const SizedBox(height: 8.0),
      Text(
        'Compartilhem orçamentos, vejam quem gastou o quê — sem precisar perguntar.',
        textAlign: .center,
        style: context.typography.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
```

Estático, sem props.

## `PartnerInviteActionsWidget`

`lib/src/presentation/ui/partner/widgets/partner_invite_actions_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class PartnerInviteActionsWidget extends StatelessWidget {
  final VoidCallback onCopyLink;
  final VoidCallback onInviteByEmail;

  const PartnerInviteActionsWidget({
    super.key,
    required this.onCopyLink,
    required this.onInviteByEmail,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: ButtonWidget.elevated(
          onTap: onInviteByEmail,
          label: 'Convidar por e-mail',
          child: const Icon(Icons.mail_outline, size: 20.0),
        ),
      ),
      const SizedBox(height: 12.0),
      SizedBox(
        width: double.infinity,
        child: ButtonWidget.outlined(
          onTap: onCopyLink,
          label: 'Copiar link de convite',
          child: const Icon(Icons.link, size: 20.0),
        ),
      ),
    ],
  );
}
```

`SizedBox(width: double.infinity)` força full-width — `ButtonWidget` por dentro usa `Row(mainAxisSize: .min)` que sem o wrapper ficaria do tamanho do conteúdo.

## `PartnerInviteSecurityNoteWidget`

`lib/src/presentation/ui/partner/widgets/partner_invite_security_note_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class PartnerInviteSecurityNoteWidget extends StatelessWidget {
  const PartnerInviteSecurityNoteWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .all(12.0),
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      color: context.colors.primary.withValues(alpha: 0.08),
    ),
    child: Row(
      spacing: 12.0,
      crossAxisAlignment: .start,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 20.0,
          color: context.colors.primary,
        ),
        Expanded(
          child: Text(
            'Vocês compartilham orçamentos e despesas, mas senhas e dados de login são individuais.',
            style: context.typography.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
```

Background sutil: `primary.withValues(alpha: 0.08)`. Mesmo idioma de `AvatarWidget` (que usa `alpha: 0.2` mas no avatar precisa ser mais opaco pra letra ser legível).

## `DashedLinePainter`

`lib/src/presentation/ui/partner/widgets/painters/dashed_line_painter.dart`:

```dart
import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const DashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .round
      ..style = .stroke;

    final y = size.height / 2;
    double x = 0;

    while (x < size.width) {
      final next = (x + dashLength).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(next, y), paint);
      x = next + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap;
}
```

## `DashedRoundedRectPainter`

`lib/src/presentation/ui/partner/widgets/painters/dashed_rounded_rect_painter.dart`:

```dart
import 'package:flutter/material.dart';

class DashedRoundedRectPainter extends CustomPainter {
  final Radius radius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const DashedRoundedRectPainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .round
      ..style = .stroke;

    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, radius));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap;
}
```

Usa `Path.computeMetrics` pra varrer o perímetro do `RRect` e extrair segmentos de `dashLength`. Funciona uniformemente em retos e cantos arredondados.

## Decisões de design do v2

1. **Tamanho do slot 72×72 dp.**
   `AvatarWidget` default é 48. No mockup o par-indicator é claramente maior que o avatar do AppBar da Home. 72 dp é um número redondo que cabe a letra e mantém respiração.

2. **Conector 56 dp de largura.**
   Largura comparável a ~80% do tamanho do slot. Visualmente "respira" entre os dois.

3. **`outlineVariant` pra cor dos dashes.**
   Cinza suave do theme, harmoniza com o cinza-esverdeado do mockup. Não é `primary` (verde forte) — daria peso demais ao slot vazio.

4. **`Skeletonizer` no loading do user.**
   Mesma técnica da `HomeAppBarWidget`. `name: user?.name ?? 'Carregando'` garante 1 caractere ('C') durante o loading.

5. **Sem `Spacer()` no fim da `Column`.**
   `Padding > Column` sem `Expanded` significa que o conteúdo tem altura intrínseca e não estica até o bottom. Se ficar feio com `Scaffold` esticado (espaço vazio embaixo), embrulhar em `SingleChildScrollView` — mas adiar até observar o smoke. Mockup não mostra scroll.

6. **Ícones nos botões via `child: Icon(...)` em vez de novo variant.**
   `ButtonWidget.elevated(child: Icon, label: ...)` já renderiza `Row(spacing: 8, children: [Icon, Text])` por dentro. Zero código novo no `ButtonWidget`.

7. **Painters em pasta `painters/` separada (não como classes privadas inline).**
   Decisão do user. Vantagem: arquivo dedicado por painter, fácil de preview/test isolado, não polui o widget principal. CLAUDE.md proíbe widget privado em arquivo de widget — `CustomPainter` não é widget, mas o spírito da regra (1 conceito = 1 arquivo) se aplica.

8. **`PartnerInviteActionsWidget` agrupa os 2 botões.**
   Sempre aparecem juntos nessa ordem. Decisão do user.

9. **Sem testes nesta etapa.**
   Sem business logic, sem notifier. Mesma justificativa da v1.
