# Design: settings-couple-error-and-loading-states

## Estado atual

`CoupleNotifier.build()` retorna `Future<CoupleCardPresentationData?>`:

```dart
return data.fold(
  (_) => null,
  (couple) => _toPresentationData(user, couple),
);
```

`SettingsCoupleStatusWidget` resolve em 2 ramos:

```dart
return switch (state) {
  AsyncData(:final value) when value != null =>
    SettingsCoupleConnectedWidget(data: value, onTap: onCoupleDetails),
  _ => SettingsInvitePartnerWidget(onTap: onInvitePartner),
};
```

Todo failure + loading colapsam em `SettingsInvitePartnerWidget`. Diferenciar exige separar o sinal de negócio (sem casal vs erro) do sinal de infra (loading).

---

## Presentation

### `CoupleCardState` (novo)

`lib/src/presentation/ui/settings/data/couple_card_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

sealed class CoupleCardState extends Equatable {
  const CoupleCardState();

  @override
  List<Object?> get props => const [];
}

final class CoupleConnectedState extends CoupleCardState {
  final CoupleCardPresentationData data;

  const CoupleConnectedState(this.data);

  @override
  List<Object?> get props => [data];
}

final class CoupleNoneState extends CoupleCardState {
  const CoupleNoneState();
}

final class CoupleFailureState extends CoupleCardState {
  final String message;

  const CoupleFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
```

`CoupleConnectedState` encapsula o `CoupleCardPresentationData` existente — sem duplicar campos.

### `CoupleNotifier` — refatorado

`lib/src/presentation/ui/settings/notifiers/couple_notifier.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/couple_model.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/data/couple_card_state.dart';
import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';

part 'couple_notifier.g.dart';

@Riverpod(keepAlive: true)
final class CoupleNotifier extends _$CoupleNotifier {
  late ICoupleRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<CoupleCardState> build() async {
    _repository = ref.watch(coupleRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    final data = await _repository.findActive();
    final user = await ref.watch(userProvider.future);

    return data.fold(
      _toFailureState,
      (couple) => CoupleConnectedState(_toPresentationData(user, couple)),
    );
  }

  CoupleCardState _toFailureState(Failure failure) => switch (failure) {
    NotFoundFailure() => const CoupleNoneState(),
    _ => CoupleFailureState(failure.message),
  };

  CoupleCardPresentationData _toPresentationData(
    UserModel user,
    CoupleModel couple,
  ) => CoupleCardPresentationData(
    currentUserInitial: _initial(user.name),
    partnerInitial: _initial(couple.partner.name),
    title: '${user.name} & ${couple.partner.name}',
    subtitle:
        'Conectados há ${_dateFormatter.formatRelativePast(couple.createdAt)}',
  );

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();
  }
}
```

Notas:
- Retorno passa de `Future<CoupleCardPresentationData?>` pra `Future<CoupleCardState>` (sem nullable — o ausente é `CoupleNoneState`).
- `_toFailureState` faz o switch exhaustivo da `sealed class Failure`. `NotFoundFailure` → `CoupleNoneState` (sem casal); todas as outras (`NetworkFailure`, `ServerFailure`, `ValidationFailure`, `UnknownFailure`) → `CoupleFailureState(failure.message)`.
- `failure.message` vem do default da `Failure` (ex: "Sem conexão com o servidor.", "Falha interna do servidor.").

### `SettingsCoupleStatusWidget` — refatorado

`lib/src/presentation/ui/settings/widgets/settings_couple_status_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/data/couple_card_state.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_failure_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_skeleton_widget.dart';

class SettingsCoupleStatusWidget extends StatelessWidget {
  final VoidCallback onInvitePartner;
  final VoidCallback onCoupleDetails;

  const SettingsCoupleStatusWidget({
    super.key,
    required this.onInvitePartner,
    required this.onCoupleDetails,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(coupleProvider);

      return switch (state) {
        AsyncData(value: CoupleConnectedState(:final data)) =>
          SettingsCoupleConnectedWidget(data: data, onTap: onCoupleDetails),
        AsyncData(value: CoupleNoneState()) =>
          SettingsInvitePartnerWidget(onTap: onInvitePartner),
        AsyncData(value: CoupleFailureState(:final message)) =>
          SettingsCoupleFailureWidget(
            message: message,
            onRetry: () => ref.invalidate(coupleProvider),
          ),
        _ => const SettingsCoupleSkeletonWidget(),
      };
    },
  );
}
```

Switch exhaustivo via pattern matching da sealed class. `_` cobre `AsyncLoading` e `AsyncError` (que nesse fluxo só ocorre se `userProvider.future` lançar).

### `SettingsCoupleFailureWidget` (novo)

`lib/src/presentation/ui/settings/widgets/settings_couple_failure_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsCoupleFailureWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SettingsCoupleFailureWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: .zero,
    elevation: 0.0,
    clipBehavior: .antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: context.radius.cornerRadius100,
    ),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        spacing: 8.0,
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.0,
            color: context.colors.error,
          ),
          Text(
            message,
            textAlign: .center,
            style: context.typography.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
```

Espelha o `BudgetCardFailureWidget` (mesmo ícone, mesma estrutura, mesmo botão), mas com:
- `Card` envolvendo (padronizar shape com o `SettingsCoupleConnectedWidget`).
- `borderRadius: context.radius.cornerRadius100` pra alinhar com o card connected.

### `SettingsCoupleSkeletonWidget` (novo)

`lib/src/presentation/ui/settings/widgets/settings_couple_skeleton_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class SettingsCoupleSkeletonWidget extends StatelessWidget {
  const SettingsCoupleSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) => Card(
    margin: .zero,
    elevation: 0.0,
    clipBehavior: .antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: context.radius.cornerRadius100,
    ),
    child: Padding(
      padding: const .all(12.0),
      child: Row(
        spacing: 12.0,
        crossAxisAlignment: .center,
        children: [
          Container(
            width: 64.0,
            height: 40.0,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          Expanded(
            child: Column(
              spacing: 6.0,
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Container(
                  width: 140.0,
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                Container(
                  width: 100.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

Dimensões espelham o `SettingsCoupleConnectedWidget`:
- Padding 12, spacing 12, radius `cornerRadius100`.
- Bloco do avatar pair (64x40 — mesma soma `2 * 40 - 16 = 64`).
- Duas linhas de texto placeholder (140x14 e 100x12 — ~tamanho do title/subtitle).

Sem animação — Container estático com `surfaceContainerHighest`.

---

## Testes

### `test/src/presentation/providers/couple_notifier_test.dart` — atualizar

Mudanças:
- Asserts atualizados para checar `state.asData?.value is CoupleConnectedState` etc.
- Extrair o `data` do `CoupleConnectedState` antes de assertar `title`/`subtitle`/`initials`.
- Novos testes pra `CoupleFailureState`:
  - `'returns CoupleFailureState with failure message on NetworkFailure'`.
  - `'returns CoupleFailureState with failure message on ServerFailure'`.
  - `'returns CoupleFailureState with failure message on ValidationFailure'`.
  - `'returns CoupleFailureState with failure message on UnknownFailure'`.
- Teste existente `'returns null when repository returns NotFoundFailure'` vira `'returns CoupleNoneState when repository returns NotFoundFailure'`.
- Testes existentes `'returns null when repository returns NetworkFailure/ServerFailure'` viram `'returns CoupleFailureState ...'` (carregando o `failure.message`).

Estrutura:

```dart
test('returns CoupleConnectedState with title, subtitle and initials', () async {
  when(() => coupleRepository.findActive())
    .thenAnswer((_) async => Right(_couple));

  final container = await makeContainer();
  final state = container.read(coupleProvider).asData?.value;

  expect(state, isA<CoupleConnectedState>());
  final data = (state as CoupleConnectedState).data;
  expect(data.title, 'Gabriel & Marina');
  expect(data.subtitle, 'Conectados há 4 meses');
  expect(data.currentUserInitial, 'G');
  expect(data.partnerInitial, 'M');
});

test('returns CoupleNoneState when repository returns NotFoundFailure', () async {
  when(() => coupleRepository.findActive())
    .thenAnswer((_) async => const Left(NotFoundFailure()));

  final container = await makeContainer();
  final state = container.read(coupleProvider).asData?.value;

  expect(state, isA<CoupleNoneState>());
});

test('returns CoupleFailureState with message on NetworkFailure', () async {
  when(() => coupleRepository.findActive())
    .thenAnswer((_) async => const Left(NetworkFailure()));

  final container = await makeContainer();
  final state = container.read(coupleProvider).asData?.value;

  expect(state, isA<CoupleFailureState>());
  expect((state as CoupleFailureState).message, 'Sem conexão com o servidor.');
});
```

Manter os testes para `ServerFailure`, `ValidationFailure('custom message')`, `UnknownFailure` com a mesma estrutura.

Manter `'handles partner name with diacritics'` (continua válido — `Ágata` → `Á`).

### Sem widget tests

Conforme padrão do projeto. Cobertura via notifier tests + análise estática.

---

## Migração

Sem migração de dados (mudança puramente UI). O notifier mantém `@Riverpod(keepAlive: true)` — instâncias em cache continuam funcionando com o novo tipo retornado.

Atenção:
- `couple_notifier.g.dart` precisa ser regenerado (mudança na assinatura de `build()`).
- Nenhum outro arquivo consome `coupleProvider.future` ou o tipo retornado fora do `SettingsCoupleStatusWidget`.

## Build runner

```bash
dart run build_runner build --delete-conflicting-outputs
```
