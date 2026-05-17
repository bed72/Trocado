# Design: couple-dissolve

## Estado atual

### Settings — card "Casal conectado" sem ação

`lib/src/presentation/ui/settings/locations/settings_location.dart:23` injeta `onCoupleDetails: () {}` na `SettingsScreen`. O `SettingsCoupleConnectedWidget` (`settings_couple_connected_widget.dart`) chama `onTap: onCoupleDetails` quando o user toca no card, mas o callback é no-op.

### Repositório de Couple — sem `dissolve`

`lib/src/domain/repositories/interface_couple_repository.dart`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
}
```

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
}
```

### Pasta `partner/`

`lib/src/presentation/ui/partner/` agrupa 5 widgets, 2 locations, 1 notifier, 1 screen e 1 presentation data. Estrutura:

```
partner/
  data/invite_qr_code_presentation_data.dart
  locations/invite_qr_code_location.dart
  locations/partner_invite_location.dart
  notifiers/invite_qr_code_notifier.dart
  notifiers/invite_qr_code_notifier.g.dart
  screens/invite_qr_code_screen.dart
  screens/partner_invite_screen.dart
  widgets/invite_qr_card_widget.dart
  widgets/invite_qr_code_failure_widget.dart
  widgets/invite_qr_code_loading_widget.dart
  widgets/partner_invite_actions_widget.dart
  widgets/partner_invite_hero_widget.dart
  widgets/partner_invite_security_note_widget.dart
  widgets/partner_pair_indicator_widget.dart
  widgets/painters/dashed_line_painter.dart
  widgets/painters/dashed_rounded_rect_painter.dart
```

### Rotas

`lib/app_route.dart:124-134`:

```dart
static final partnerInvite = AppRoutes._(
  path: '/partner/invite',
  name: 'partner-invite-route',
  regex: RegExp(r'^/partner/invite$'),
);

static final partnerInviteQrCode = AppRoutes._(
  path: '/partner/invite/qr-code',
  name: 'partner-invite-qr-code-route',
  regex: RegExp(r'^/partner/invite/qr-code$'),
);
```

---

## Infrastructure — dissolve endpoint

### `IRemoteCoupleDataSource.dissolve()`

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, void>> dissolve();
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  final IHttpClient _client;

  RemoteCoupleDataSource({required IHttpClient client}) : _client = client;

  // existing findActive() and createInvite() …

  @override
  Future<Either<FailureResponse, void>> dissolve() async {
    final response = await _client.delete(
      parameter: Requests(EndpointKey.couple.path),
    );

    return response.either(FailureResponse.fromJson, (_) {});
  }
}
```

Padrão idêntico ao `RemoteUserDataSource.delete()` (`remote_user_data_source.dart:38-51`): no Right, descarta o body (204 No Content) com `(_) {}`.

Sem `Requests(..., body: ...)` — DELETE não envia payload (curl confirmou: só Authorization e CSRF).

## Data — repositório

### `ICoupleRepository.dissolve()`

`lib/src/domain/repositories/interface_couple_repository.dart`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, void>> dissolve();
}
```

### `CoupleRepository.dissolve()`

`lib/src/data/repositories/couple_repository.dart`:

```dart
@override
Future<Either<Failure, void>> dissolve() async {
  final data = await _dataSource.dissolve();

  return data.either((failure) => failure.toFailure(), (_) {});
}
```

Sem operação async no Right — usa `data.either(...)` direto (padrão `findActive`/`createInvite`). `FailureResponseExtension.toFailure()` faz o mapeamento de códigos → `Failure` tipado.

---

## Presentation — dissolve

### `CoupleDissolveState`

`lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart`:

```dart
import 'package:equatable/equatable.dart';

enum CoupleDissolveStatus { initial, loading, success, failure }

final class CoupleDissolveState extends Equatable {
  final String message;
  final CoupleDissolveStatus status;

  const CoupleDissolveState({
    this.message = '',
    this.status = .initial,
  });

  CoupleDissolveState copyWith({
    String? message,
    CoupleDissolveStatus? status,
  }) => CoupleDissolveState(
    message: message ?? this.message,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [status, message];
}
```

### `CoupleDissolveIntent`

`lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart`:

```dart
sealed class CoupleDissolveIntent {
  const CoupleDissolveIntent();
}

final class DissolvePressed extends CoupleDissolveIntent {
  const DissolvePressed();
}
```

### `CoupleDissolveNotifier`

`lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';

part 'couple_dissolve_notifier.g.dart';

@riverpod
final class CoupleDissolveNotifier extends _$CoupleDissolveNotifier {
  late ICoupleRepository _repository;

  @override
  CoupleDissolveState build() {
    _repository = ref.watch(coupleRepositoryProvider);

    return const CoupleDissolveState();
  }

  void dispatch(CoupleDissolveIntent intent) => switch (intent) {
    DissolvePressed() => _dissolve(),
  };

  Future<void> _dissolve() async {
    if (state.status == .loading) return;

    state = state.copyWith(status: .loading);

    final data = await _repository.dissolve();

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) {
        ref.invalidate(coupleProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(insightsProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
        state = state.copyWith(status: .success);
      },
    );
  }
}
```

Notas:
- `late ICoupleRepository _repository` (não `late final` — Riverpod re-executa `build()` em watch changes).
- `build()` síncrono — não há nada pra carregar quando a tela abre. `const CoupleDissolveState()` (default `.initial`).
- `dispatch` é switch expression em sealed class — exhaustivo via Dart 3 (uma única variante por ora; novas intents simplesmente adicionam braços ao switch).
- Guard de loading no `_dissolve()` — duplo tap não enfila segunda chamada.
- Invalidations em sequência: `coupleProvider` primeiro (source of truth), depois caches de home/listagens. Ordem não importa funcionalmente (Riverpod lazy re-invalidates), mas mantém leitura natural.

### `CoupleDissolveScreen`

`lib/src/presentation/ui/couple/dissolve/screens/couple_dissolve_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart';

class CoupleDissolveScreen extends StatelessWidget {
  const CoupleDissolveScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(
            coupleDissolveProvider,
            (previous, next) => switch (next.status) {
              .success when previous?.status != .success => _onSuccess(context),
              .failure when previous?.status != .failure => _onFailure(
                context,
                next.message,
              ),
              _ => null,
            },
          );

          final state = ref.watch(coupleDissolveProvider);
          final notifier = ref.read(coupleDissolveProvider.notifier);

          return _buildBody(context: context, state: state, notifier: notifier);
        },
      ),
    ),
  );

  Column _buildBody({
    required BuildContext context,
    required CoupleDissolveState state,
    required CoupleDissolveNotifier notifier,
  }) => Column(
    spacing: 24.0,
    crossAxisAlignment: .start,
    children: [
      const ScreenHeaderWidget(
        title: 'Desfazer casal',
        description:
            'Esta ação encerra a conexão com seu parceiro. Os dados de cada um permanecem, mas vocês deixam de compartilhar.',
      ),
      _effect(
        context,
        icon: Icons.visibility_off_outlined,
        label:
            'Vocês deixarão de visualizar despesas e orçamentos compartilhados imediatamente.',
      ),
      _effect(
        context,
        icon: Icons.history,
        label:
            'Seus dados pessoais (despesas, orçamentos, histórico) permanecem intactos.',
      ),
      _effect(
        context,
        icon: Icons.handshake_outlined,
        label:
            'Vocês podem se reconectar a qualquer momento por um novo convite.',
      ),
      const Spacer(),
      SizedBox(
        width: .infinity,
        child: ButtonWidget.danger(
          label: 'Desfazer casal',
          isLoading: state.status == .loading,
          onTap: () => _submit(context, notifier),
        ),
      ),
    ],
  );

  Widget _effect(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) => Row(
    spacing: 12.0,
    crossAxisAlignment: .start,
    children: [
      Icon(icon, size: 20.0, color: context.colors.onSurfaceVariant),
      Expanded(
        child: Text(
          label,
          style: context.typography.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );

  Future<void> _submit(
    BuildContext context,
    CoupleDissolveNotifier notifier,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Desfazer casal',
      confirmLabel: 'Desfazer',
      description:
          'Tem certeza? Vocês deixarão de compartilhar despesas e orçamentos imediatamente.',
    );
    if (!confirmed) return;

    notifier.dispatch(const DissolvePressed());
  }

  void _onSuccess(BuildContext context) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Vocês não estão mais conectados.',
    );
    context.pop();
  }

  void _onFailure(BuildContext context, String message) => showToastWidget(
    context: context,
    type: .failure,
    title: 'Opps',
    description: message,
  );
}
```

Notas:
- `StatelessWidget` + `Consumer` interno (CLAUDE.md: nunca `ConsumerWidget`).
- `ref.listen` é switch expression como statement (resultado descartado), seguindo padrão `settings_screen.dart:46-58`.
- `_effect` é método helper (widget trivial: ícone 20px + texto multi-linha). Não vira widget próprio porque é apenas um Row com 2 filhos — overhead de arquivo separado seria desproporcional. CLAUDE.md: "Widget trivial → método privado que retorna o widget".
- Sem widget privado `_FooWidget` classe — CLAUDE.md regra dura.
- `_submit` no fluxo: confirm dialog primeiro, depois `dispatch(DissolvePressed)`. Mesmo pattern do `profile_delete_screen.dart:112-133`.
- `_onSuccess` chama o toast **antes** do pop (toast precisa do ScaffoldMessenger da tela ativa).

### `CoupleDissolveLocation`

`lib/src/presentation/ui/couple/dissolve/locations/couple_dissolve_location.dart`:

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/screens/couple_dissolve_screen.dart';

final class CoupleDissolveLocation extends Location {
  @override
  String get path => AppRoutes.coupleDissolve.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(const CoupleDissolveScreen());
}
```

Sem callbacks externos — pop é local; settings reage via invalidation do `coupleProvider`.

---

## Presentation — rename `partner/` → `couple/invite/`

Move 1:1 com renames apenas em arquivos que contém `partner_*` no nome.

### Arquivos que mudam de **nome** (classe + arquivo)

| Antes | Depois |
|---|---|
| `partner/locations/partner_invite_location.dart` (`PartnerInviteLocation`) | `couple/invite/locations/couple_invite_location.dart` (`CoupleInviteLocation`) |
| `partner/screens/partner_invite_screen.dart` (`PartnerInviteScreen`) | `couple/invite/screens/couple_invite_screen.dart` (`CoupleInviteScreen`) |
| `partner/widgets/partner_invite_hero_widget.dart` (`PartnerInviteHeroWidget`) | `couple/invite/widgets/couple_invite_hero_widget.dart` (`CoupleInviteHeroWidget`) |
| `partner/widgets/partner_invite_actions_widget.dart` (`PartnerInviteActionsWidget`) | `couple/invite/widgets/couple_invite_actions_widget.dart` (`CoupleInviteActionsWidget`) |
| `partner/widgets/partner_invite_security_note_widget.dart` (`PartnerInviteSecurityNoteWidget`) | `couple/invite/widgets/couple_invite_security_note_widget.dart` (`CoupleInviteSecurityNoteWidget`) |
| `partner/widgets/partner_pair_indicator_widget.dart` (`PartnerPairIndicatorWidget`) | `couple/invite/widgets/couple_pair_indicator_widget.dart` (`CouplePairIndicatorWidget`) |

### Arquivos que apenas **mudam de pasta** (sem rename)

| Antes | Depois |
|---|---|
| `partner/locations/invite_qr_code_location.dart` | `couple/invite/locations/invite_qr_code_location.dart` |
| `partner/screens/invite_qr_code_screen.dart` | `couple/invite/screens/invite_qr_code_screen.dart` |
| `partner/notifiers/invite_qr_code_notifier.dart` | `couple/invite/notifiers/invite_qr_code_notifier.dart` |
| `partner/notifiers/invite_qr_code_notifier.g.dart` | `couple/invite/notifiers/invite_qr_code_notifier.g.dart` (regenerado, não movido) |
| `partner/data/invite_qr_code_presentation_data.dart` | `couple/invite/data/invite_qr_code_presentation_data.dart` |
| `partner/widgets/invite_qr_card_widget.dart` | `couple/invite/widgets/invite_qr_card_widget.dart` |
| `partner/widgets/invite_qr_code_failure_widget.dart` | `couple/invite/widgets/invite_qr_code_failure_widget.dart` |
| `partner/widgets/invite_qr_code_loading_widget.dart` | `couple/invite/widgets/invite_qr_code_loading_widget.dart` |
| `partner/widgets/painters/dashed_line_painter.dart` | `couple/invite/widgets/painters/dashed_line_painter.dart` |
| `partner/widgets/painters/dashed_rounded_rect_painter.dart` | `couple/invite/widgets/painters/dashed_rounded_rect_painter.dart` |

### Updates de imports internos

Cada arquivo movido tem imports de outros arquivos do módulo (ex: `PartnerInviteScreen` importa `PartnerInviteHeroWidget`). Após o move, todos os imports `package:trocado/src/presentation/ui/partner/...` viram `package:trocado/src/presentation/ui/couple/invite/...` com o sufixo de filename atualizado se houve rename.

### Build runner

`invite_qr_code_notifier.g.dart` é regenerado via `dart run build_runner build --delete-conflicting-outputs` após o move. Não copiar o `.g.dart` antigo — ele aponta para o path antigo.

---

## Wiring

### `app_route.dart`

Substituições no `lib/app_route.dart`:

```dart
// REMOVER
static final partnerInvite = AppRoutes._(
  path: '/partner/invite',
  name: 'partner-invite-route',
  regex: RegExp(r'^/partner/invite$'),
);

static final partnerInviteQrCode = AppRoutes._(
  path: '/partner/invite/qr-code',
  name: 'partner-invite-qr-code-route',
  regex: RegExp(r'^/partner/invite/qr-code$'),
);

// ADICIONAR (na mesma seção, agrupado)
static final coupleInvite = AppRoutes._(
  path: '/couple/invite',
  name: 'couple-invite-route',
  regex: RegExp(r'^/couple/invite$'),
);

static final coupleInviteQrCode = AppRoutes._(
  path: '/couple/invite/qr-code',
  name: 'couple-invite-qr-code-route',
  regex: RegExp(r'^/couple/invite/qr-code$'),
);

static final coupleDissolve = AppRoutes._(
  path: '/couple/dissolve',
  name: 'couple-dissolve-route',
  regex: RegExp(r'^/couple/dissolve$'),
);
```

E atualizar a lista `_all`: trocar `partnerInvite` por `coupleInvite`, `partnerInviteQrCode` por `coupleInviteQrCode` e adicionar `coupleDissolve`.

### `settings_location.dart`

`lib/src/presentation/ui/settings/locations/settings_location.dart`:

```dart
// ANTES
import 'package:trocado/src/presentation/ui/partner/locations/partner_invite_location.dart';

// ...
SettingsScreen(
  // ...
  onCoupleDetails: () {},
  onInvitePartner: () => context.navigate(PartnerInviteLocation()),
)

// DEPOIS
import 'package:trocado/src/presentation/ui/couple/invite/locations/couple_invite_location.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/locations/couple_dissolve_location.dart';

// ...
SettingsScreen(
  // ...
  onCoupleDetails: () => context.navigate(CoupleDissolveLocation()),
  onInvitePartner: () => context.navigate(CoupleInviteLocation()),
)
```

`onInvitePartner` mantém o nome do callback (definido em `SettingsScreen`) — não vale a pena renomear o callback nesta spec; é puramente cosmético e não afeta comportamento.

---

## Testes

### `test/src/data/repositories/couple_repository_test.dart` — adicionar grupo `DELETE`

Modelar igual aos grupos `GET` e `POST` já existentes. Pattern:

```dart
group('DELETE', () {
  setUp(() {
    when(() => client.delete(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => const Right(<String, dynamic>{}));
  });

  test('returns Right when API responds 204', () async {
    final data = await repository.dissolve();

    expect(data.isRight, isTrue);
  });

  test('returns Left NetworkFailure on network error', () async {
    when(() => client.delete(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left(_failure('connection_error')));

    final data = await repository.dissolve();

    expect(data.isLeft, isTrue);
    expect(data.left, isA<NetworkFailure>());
  });

  test('returns Left ServerFailure on server error', () async {
    when(() => client.delete(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left(_failure('server_error')));

    final data = await repository.dissolve();

    expect(data.left, isA<ServerFailure>());
  });

  test('returns Left NotFoundFailure when no active couple', () async {
    when(() => client.delete(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left(_failure('not_in_couple')));

    final data = await repository.dissolve();

    expect(data.left, isA<NotFoundFailure>());
  });

  test('returns Left ValidationFailure on unknown code', () async {
    when(() => client.delete(parameter: any(named: 'parameter')))
      .thenAnswer((_) async => Left(_failure('custom', 'Some message')));

    final data = await repository.dissolve();

    expect(data.left, isA<ValidationFailure>());
    expect((data.left as ValidationFailure).message, 'Some message');
  });
});
```

Helper `_failure(code, [message])` segue o padrão dos grupos existentes (`couple_repository_test.dart`).

Cobertura mínima: 5 testes (sucesso + 4 failures).

### `test/src/presentation/providers/couple_dissolve_notifier_test.dart` (NOVO)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart';
import 'package:trocado/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ICoupleRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockCoupleRepository();
    container = ProviderContainer(
      overrides: [coupleRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  group('CoupleDissolveNotifier', () {
    test('returns initial state on build', () {
      final state = container.read(coupleDissolveProvider);

      expect(state.status, CoupleDissolveStatus.initial);
      expect(state.message, '');
    });

    test('transitions to success when repository returns Right', () async {
      when(() => repository.dissolve())
        .thenAnswer((_) async => const Right(null));

      container.read(coupleDissolveProvider.notifier).dispatch(
        const DissolvePressed(),
      );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleDissolveProvider);
      expect(state.status, CoupleDissolveStatus.success);
    });

    test('transitions to failure with message on Left', () async {
      when(() => repository.dissolve())
        .thenAnswer((_) async => const Left(NetworkFailure()));

      container.read(coupleDissolveProvider.notifier).dispatch(
        const DissolvePressed(),
      );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleDissolveProvider);
      expect(state.status, CoupleDissolveStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('skips second dispatch while loading', () async {
      var callCount = 0;
      when(() => repository.dissolve()).thenAnswer((_) async {
        callCount++;
        return const Right(null);
      });

      final notifier = container.read(coupleDissolveProvider.notifier);
      notifier.dispatch(const DissolvePressed());
      notifier.dispatch(const DissolvePressed());

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });
  });
}
```

`MockCoupleRepository` em `test/mocks/mocks.dart` — adicionar se ainda não existir:

```dart
class MockCoupleRepository extends Mock implements ICoupleRepository {}
```

Sem teste de `ref.invalidate(...)` direto — Riverpod não expõe um listener publicly para "este provider foi invalidado". A invalidação é coberta indiretamente: se o teste de notifier passa com `Right`, sabemos que a ramificação de sucesso é executada (que é onde os invalidates estão). Cobertura visual via smoke manual (ver `tasks.md`).

### Sem widget tests

Conforme padrão do projeto.

---

## Migração

### Ordem sugerida da implementação

1. **Camadas de dados (domain/data/infrastructure)** primeiro — sem dependências reversas. Adiciona `dissolve` na interface, datasource, repositório. Testes do repo passam.
2. **Move `partner/` → `couple/invite/`** em uma operação (manter conteúdo inalterado, só rename de arquivo/classe). Atualiza imports internos do módulo movido. Atualiza `app_route.dart`. Atualiza `settings_location.dart`. `flutter analyze` passa.
3. **Adiciona `couple/dissolve/`** — state, intent, notifier, screen, location. Wiring final em `app_route.dart` (já adicionado no passo 2) e `settings_location.dart` (callback `onCoupleDetails`).
4. **Testes do notifier** — `couple_dissolve_notifier_test.dart`.
5. **`dart run build_runner build --delete-conflicting-outputs`** — regenera `couple_dissolve_notifier.g.dart` e `invite_qr_code_notifier.g.dart` (path mudou).
6. **Smoke tests** — ver `tasks.md`.

### Atenção

- `invite_qr_code_notifier.g.dart` precisa ser **regenerado** após o move, não copiado (path do source mudou).
- Nenhum arquivo fora do módulo `couple/` ou `settings/` deveria precisar mudar. Se aparecer outro consumer durante a implementação (ex: deep link handler), validar antes de incluir.
- Sem migração de dados — DELETE é server-side.

## Build runner

```bash
dart run build_runner build --delete-conflicting-outputs
```
