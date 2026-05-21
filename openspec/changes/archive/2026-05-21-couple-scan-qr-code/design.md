# Design: couple-scan-qr-code

## Estado atual

### `CoupleInviteScreen` — botão "Scanear" no-op

`lib/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart:47`:

```dart
CoupleInviteActionsWidget(onGenerate: onGenerate, onScan: () {}),
```

`CoupleInviteLocation` (`couple_invite_location.dart:15-19`) injeta apenas `onGenerate`. O `onScan` é hardcoded como `() {}` no próprio screen, ainda não exposto como parâmetro da Location.

### `IRemoteCoupleDataSource` — sem lookup/accept

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart:10-14`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
}
```

### `ICoupleRepository` — sem lookup/accept

`lib/src/domain/repositories/interface_couple_repository.dart:7-12`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, void>> dissolve();
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, void>> shareInvite({required String qrData});
}
```

### Sem dependências de câmera nem permissão

`pubspec.yaml` não tem `mobile_scanner` nem `permission_handler`. Os manifests Android (`android/app/src/main/AndroidManifest.xml`) e iOS (`ios/Runner/Info.plist`) não declaram permissão de câmera.

---

## Infrastructure

### `InviteLookupResponse`

`lib/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart` (NOVO):

```dart
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class InviteLookupResponse {
  final int coupleId;
  final UserResponse partner;

  const InviteLookupResponse({required this.coupleId, required this.partner});

  factory InviteLookupResponse.fromJson(Map<String, dynamic> json) =>
      InviteLookupResponse(
        coupleId: json['couple_id'] as int,
        partner: UserResponse.fromJson(json['partner'] as Map<String, dynamic>),
      );
}
```

Mesmo padrão de `CoupleResponse.fromJson` (`couple_response.dart:14-18`) — aninha `UserResponse.fromJson` no campo `partner`.

### `IRemoteCoupleDataSource.lookupInvite` e `acceptInvite`

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({
    required String code,
  });
  Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({
    required String code,
  });
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  final IHttpClient _client;

  RemoteCoupleDataSource({required IHttpClient client}) : _client = client;

  // existing findActive(), createInvite(), dissolve() ...

  @override
  Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({
    required String code,
  }) async {
    final response = await _client.get(
      parameter: Requests('${EndpointKey.coupleInvites.path}/$code'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteLookupResponse.fromJson,
    );
  }

  @override
  Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({
    required String code,
  }) async {
    final response = await _client.post(
      parameter: Requests('${EndpointKey.coupleInvites.path}/$code/accept'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteLookupResponse.fromJson,
    );
  }
}
```

Notas:
- Path dinâmico montado por interpolação direta, padrão `RemoteExpenseDataSource.findById` (`remote_expense_data_source.dart:77`).
- `acceptInvite` envia POST sem body — o backend identifica a ação pelo path + Bearer token.

---

## Domain

### `InviteLookupModel`

`lib/src/domain/models/couple/invite_lookup_model.dart` (NOVO):

```dart
import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class InviteLookupModel extends Equatable {
  final int coupleId;
  final UserModel partner;

  const InviteLookupModel({required this.coupleId, required this.partner});

  InviteLookupModel copyWith({int? coupleId, UserModel? partner}) =>
      InviteLookupModel(
        coupleId: coupleId ?? this.coupleId,
        partner: partner ?? this.partner,
      );

  @override
  List<Object?> get props => [coupleId, partner];
}
```

### `ICoupleRepository` — interface estendida

`lib/src/domain/repositories/interface_couple_repository.dart`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, void>> dissolve();
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, void>> shareInvite({required String qrData});
  Future<Either<Failure, InviteLookupModel>> lookupInvite({
    required String code,
  });
  Future<Either<Failure, InviteLookupModel>> acceptInvite({
    required String code,
  });
}
```

---

## Data

### `InviteLookupResponseExtension`

`lib/src/data/extensions/invite_lookup_response_extension.dart` (NOVO):

```dart
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart';

extension InviteLookupResponseExtension on InviteLookupResponse {
  InviteLookupModel toModel() => InviteLookupModel(
    coupleId: coupleId,
    partner: UserModel(
      id: partner.id,
      name: partner.name,
      email: partner.email,
    ),
  );
}
```

Mapeamento inline `UserResponse → UserModel` (3 campos), sem criar `user_response_extension.dart` ainda — se aparecer em outra spec a necessidade de reuso, extrair lá.

### `CoupleRepository.lookupInvite` e `acceptInvite`

`lib/src/data/repositories/couple_repository.dart`:

```dart
@override
Future<Either<Failure, InviteLookupModel>> lookupInvite({
  required String code,
}) async {
  final data = await _dataSource.lookupInvite(code: code);

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toModel(),
  );
}

@override
Future<Either<Failure, InviteLookupModel>> acceptInvite({
  required String code,
}) async {
  final data = await _dataSource.acceptInvite(code: code);

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toModel(),
  );
}
```

Padrão idêntico a `findActive()` / `createInvite()` — sem operação async no Right, usa `data.either`.

---

## Presentation — `couple/scan/`

### `CoupleScanState`

`lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart` (NOVO):

```dart
import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

enum CoupleScanStatus {
  initial,
  permissionDenied,
  cameraUnavailable,
  ready,
  lookup,
  lookedUp,
  failure,
}

final class CoupleScanState extends Equatable {
  final String message;
  final bool canAskAgain;
  final bool isTorchOn;
  final CoupleScanStatus status;
  final InviteLookupModel? lookup;

  const CoupleScanState({
    this.message = '',
    this.lookup,
    this.isTorchOn = false,
    this.canAskAgain = true,
    this.status = .initial,
  });

  CoupleScanState copyWith({
    String? message,
    bool? canAskAgain,
    bool? isTorchOn,
    CoupleScanStatus? status,
    InviteLookupModel? lookup,
  }) => CoupleScanState(
    message: message ?? this.message,
    lookup: lookup ?? this.lookup,
    isTorchOn: isTorchOn ?? this.isTorchOn,
    canAskAgain: canAskAgain ?? this.canAskAgain,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [status, message, canAskAgain, isTorchOn, lookup];
}
```

Notas:
- `canAskAgain: false` quando permissão é `.permanentlyDenied` ou `.restricted` — UI usa pra decidir entre "Permitir câmera" e "Abrir configurações".
- `lookup` populado somente quando `status == .lookedUp` — a screen lê e navega pra `CoupleScanConfirmLocation(lookup: state.lookup!)`.

### `CoupleScanIntent`

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart` (NOVO):

```dart
sealed class CoupleScanIntent {
  const CoupleScanIntent();
}

final class PermissionRequested extends CoupleScanIntent {
  const PermissionRequested();
}

final class OpenSettingsPressed extends CoupleScanIntent {
  const OpenSettingsPressed();
}

final class QrDetected extends CoupleScanIntent {
  final String code;
  const QrDetected(this.code);
}

final class ManualCodeSubmitted extends CoupleScanIntent {
  final String code;
  const ManualCodeSubmitted(this.code);
}

final class TorchPressed extends CoupleScanIntent {
  const TorchPressed();
}

final class RetryPressed extends CoupleScanIntent {
  const RetryPressed();
}
```

### `CoupleScanNotifier`

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` (NOVO):

```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';

part 'couple_scan_notifier.g.dart';

@Riverpod()
final class CoupleScanNotifier extends _$CoupleScanNotifier {
  late ICoupleRepository _repository;
  late MobileScannerController _controller;

  MobileScannerController get controller => _controller;

  @override
  Future<CoupleScanState> build() async {
    _repository = ref.watch(coupleRepositoryProvider);
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: .normal,
      torchEnabled: false,
    );

    ref.onDispose(() => _controller.dispose());

    return await _bootstrap();
  }

  Future<CoupleScanState> _bootstrap() async {
    final status = await Permission.camera.status;

    return switch (status) {
      .granted => const CoupleScanState(status: .ready),
      .restricted ||
      .permanentlyDenied => const CoupleScanState(
        status: .permissionDenied,
        canAskAgain: false,
      ),
      _ => const CoupleScanState(
        status: .permissionDenied,
        canAskAgain: true,
      ),
    };
  }

  void dispatch(CoupleScanIntent intent) => switch (intent) {
    PermissionRequested() => _requestPermission(),
    OpenSettingsPressed() => _openSettings(),
    QrDetected(:final code) => _lookup(code),
    ManualCodeSubmitted(:final code) => _lookup(code),
    TorchPressed() => _toggleTorch(),
    RetryPressed() => _retry(),
  };

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    state = AsyncData(
      switch (status) {
        .granted => const CoupleScanState(status: .ready),
        .restricted ||
        .permanentlyDenied => const CoupleScanState(
          status: .permissionDenied,
          canAskAgain: false,
        ),
        _ => const CoupleScanState(
          status: .permissionDenied,
          canAskAgain: true,
        ),
      },
    );
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  Future<void> _lookup(String code) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.status != .ready) return;
    if (code.trim().isEmpty) return;

    await _controller.stop();
    state = AsyncData(current.copyWith(status: .lookup));

    final data = await _repository.lookupInvite(code: code.trim());

    state = AsyncData(
      data.fold(
        (failure) => current.copyWith(
          status: .failure,
          message: failure.message,
        ),
        (lookup) => current.copyWith(status: .lookedUp, lookup: lookup),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _controller.toggleTorch();
    state = AsyncData(current.copyWith(isTorchOn: !current.isTorchOn));
  }

  Future<void> _retry() async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _controller.start();
    state = AsyncData(
      current.copyWith(
        status: .ready,
        message: '',
        lookup: null,
      ),
    );
  }
}
```

Notas:
- `AsyncNotifier<CoupleScanState>` porque o `build()` é async (checagem de permissão).
- `late MobileScannerController _controller` — não `late final` (Riverpod re-executa `build()` em watch changes).
- `ref.onDispose` garante dispose do controller quando o notifier é descartado (screen pop).
- `_lookup` é o ponto único de entrada (QR auto + manual) — DRY.
- Dedup: `if (current.status != .ready) return;` — múltiplos `QrDetected` enquanto `lookup`/`lookedUp` são ignorados.
- `_retry()` reinicia o scanner após erro, mantendo o controller vivo (não recria).

### `CoupleScanScreen`

`lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` (NOVO):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_torch_button_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_sheet.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart';
import 'package:trocado/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart';

class CoupleScanScreen extends StatelessWidget {
  const CoupleScanScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Consumer(
      builder: (_, ref, _) {
        ref.listen(coupleScanProvider, (previous, next) {
          if (next case AsyncData(:final value)) {
            switch (value.status) {
              .lookedUp when value.lookup != null =>
                _navigateToConfirm(context, value.lookup!),
              .failure when previous?.valueOrNull?.status != .failure =>
                _showFailure(context, ref, value.message),
              _ => null,
            };
          }
        });

        final asyncState = ref.watch(coupleScanProvider);
        final notifier = ref.read(coupleScanProvider.notifier);

        return switch (asyncState) {
          AsyncLoading() ||
          AsyncError() => const SizedBox.shrink(),
          AsyncData(:final value) => _body(
            context: context,
            state: value,
            notifier: notifier,
          ),
        };
      },
    ),
  );

  Widget _body({
    required BuildContext context,
    required CoupleScanState state,
    required CoupleScanNotifier notifier,
  }) => switch (state.status) {
    .permissionDenied => CoupleScanPermissionDeniedWidget(
      canAskAgain: state.canAskAgain,
      onAllow: () => notifier.dispatch(const PermissionRequested()),
      onOpenSettings: () => notifier.dispatch(const OpenSettingsPressed()),
      onManualCode: () => _openManualSheet(context, notifier),
    ),
    .cameraUnavailable => CoupleScanPermissionDeniedWidget(
      canAskAgain: false,
      onAllow: () {},
      onOpenSettings: () => notifier.dispatch(const OpenSettingsPressed()),
      onManualCode: () => _openManualSheet(context, notifier),
    ),
    _ => _scanner(context: context, state: state, notifier: notifier),
  };

  Widget _scanner({
    required BuildContext context,
    required CoupleScanState state,
    required CoupleScanNotifier notifier,
  }) => Stack(
    children: [
      MobileScanner(
        controller: notifier.controller,
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null) {
            notifier.dispatch(QrDetected(code));
          }
        },
      ),
      const Positioned.fill(child: IgnorePointer(child: CoupleScanOverlayWidget())),
      Positioned(
        right: 16.0,
        bottom: 16.0,
        child: CoupleScanTorchButtonWidget(
          isOn: state.isTorchOn,
          onPressed: () => notifier.dispatch(const TorchPressed()),
        ),
      ),
      Positioned(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        child: TextButton(
          onPressed: () => _openManualSheet(context, notifier),
          child: const Text('Digitar código manualmente'),
        ),
      ),
    ],
  );

  void _navigateToConfirm(BuildContext context, InviteLookupModel lookup) =>
      context.navigate(CoupleScanConfirmLocation(lookup: lookup));

  void _showFailure(BuildContext context, WidgetRef ref, String message) {
    showToastWidget(
      context: context,
      type: .failure,
      title: 'Opps',
      description: message,
    );
    ref.read(coupleScanProvider.notifier).dispatch(const RetryPressed());
  }

  Future<void> _openManualSheet(
    BuildContext context,
    CoupleScanNotifier notifier,
  ) async {
    final code = await showCoupleScanManualCodeSheet(context: context);
    if (code != null && code.isNotEmpty) {
      notifier.dispatch(ManualCodeSubmitted(code));
    }
  }
}
```

Notas:
- `StatelessWidget` + `Consumer` interno (CLAUDE.md).
- Estados `AsyncLoading`/`AsyncError` retornam `SizedBox.shrink()` — `_bootstrap` é praticamente instantâneo (só checa permission status); o flash de tela vazia é imperceptível. Se virar problema, troca por `LoadWidget` (já existe no projeto).
- `_body` é switch expression no `status` retornando o widget apropriado.
- `MobileScanner` widget recebe o controller do notifier — fica vivo durante toda a sessão de scan.
- Overlay é `IgnorePointer` pra não bloquear taps no scanner (e o scanner detect via `onDetect`, não tap).
- `ref.listen` reage a transições do `status`: `.lookedUp` → navega; `.failure` → toast + retry. Padrão `couple_dissolve_screen.dart:287-297`.
- `_navigateToConfirm` passa o `InviteLookupModel` via construtor da Location.

### `CoupleScanOverlayWidget`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanOverlayWidget extends StatelessWidget {
  const CoupleScanOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const ColoredBox(
        color: Color(0xAA000000),
        child: SizedBox.expand(),
      ),
      Center(
        child: Container(
          width: 240.0,
          height: 240.0,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              width: 3.0,
              color: context.colors.primary,
            ),
            borderRadius: .circular(16.0),
          ),
        ),
      ),
      Positioned(
        left: 24.0,
        right: 24.0,
        bottom: 96.0,
        child: Text(
          'Aponte a câmera para o QR code do seu par',
          textAlign: .center,
          style: context.typography.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}
```

Visual minimalista: overlay escurecido com janela quadrada vazada (square 240x240). Versão MVP — refinos visuais (cantos arredondados, corte do overlay) ficam pra spec separada de design polishing.

### `CoupleScanTorchButtonWidget`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_torch_button_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanTorchButtonWidget extends StatelessWidget {
  final bool isOn;
  final VoidCallback onPressed;

  const CoupleScanTorchButtonWidget({
    super.key,
    required this.isOn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    onPressed: onPressed,
    backgroundColor: context.colors.surface,
    foregroundColor: context.colors.onSurface,
    child: Icon(isOn ? Icons.flash_off : Icons.flash_on),
  );
}
```

### `CoupleScanPermissionDeniedWidget`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class CoupleScanPermissionDeniedWidget extends StatelessWidget {
  final bool canAskAgain;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onManualCode;

  const CoupleScanPermissionDeniedWidget({
    super.key,
    required this.canAskAgain,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onManualCode,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(16.0),
    child: Column(
      spacing: 24.0,
      crossAxisAlignment: .start,
      children: [
        const ScreenHeaderWidget(
          title: 'Câmera não disponível',
          description:
              'Precisamos da câmera para ler o QR code do convite. Você pode liberar a permissão ou digitar o código manualmente.',
        ),
        const Spacer(),
        SizedBox(
          width: .infinity,
          child: ButtonWidget.elevated(
            label: canAskAgain ? 'Permitir câmera' : 'Abrir configurações',
            onTap: canAskAgain ? onAllow : onOpenSettings,
          ),
        ),
        SizedBox(
          width: .infinity,
          child: ButtonWidget.outlined(
            label: 'Digitar código manualmente',
            onTap: onManualCode,
          ),
        ),
      ],
    ),
  );
}
```

### `CoupleScanManualCodeSheet`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_sheet.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart';

Future<String?> showCoupleScanManualCodeSheet({
  required BuildContext context,
}) => showBottomSheetWidget<String>(
  context: context,
  child: const _ManualCodeBody(),
);

class _ManualCodeBody extends StatefulWidget {
  const _ManualCodeBody();

  @override
  State<_ManualCodeBody> createState() => _ManualCodeBodyState();
}

class _ManualCodeBodyState extends State<_ManualCodeBody> {
  final _controller = TextEditingController();
  String _value = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .all(16.0),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 16.0,
      children: [
        Text(
          'Digite o código do convite',
          style: context.typography.titleMedium,
        ),
        TextFieldWidget(
          controller: _controller,
          label: 'Código',
          onChanged: (value) => setState(() => _value = value),
        ),
        SizedBox(
          width: .infinity,
          child: ButtonWidget.elevated(
            label: 'Confirmar',
            onTap: _value.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_value.trim()),
          ),
        ),
      ],
    ),
  );
}
```

Notas:
- Função `showCoupleScanManualCodeSheet(context)` retorna `Future<String?>` — `null` se user cancelou (back / drag down), string se confirmou.
- `StatefulWidget` é local ao arquivo do sheet apenas pra controlar `TextEditingController`. Não é uma screen — não viola "screens são `StatelessWidget`". O sheet é um widget de input controlado.
- Validação só "não vazio" — o lookup faz validação semântica.

### `CoupleScanConfirmState`

`lib/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart` (NOVO):

```dart
import 'package:equatable/equatable.dart';

enum CoupleScanConfirmStatus { initial, loading, success, failure }

final class CoupleScanConfirmState extends Equatable {
  final String message;
  final CoupleScanConfirmStatus status;

  const CoupleScanConfirmState({
    this.message = '',
    this.status = .initial,
  });

  CoupleScanConfirmState copyWith({
    String? message,
    CoupleScanConfirmStatus? status,
  }) => CoupleScanConfirmState(
    message: message ?? this.message,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [status, message];
}
```

### `CoupleScanConfirmIntent`

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart` (NOVO):

```dart
sealed class CoupleScanConfirmIntent {
  const CoupleScanConfirmIntent();
}

final class AcceptPressed extends CoupleScanConfirmIntent {
  final String code;
  const AcceptPressed(this.code);
}
```

### `CoupleScanConfirmNotifier`

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart` (NOVO):

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/settings/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';

part 'couple_scan_confirm_notifier.g.dart';

@Riverpod()
final class CoupleScanConfirmNotifier extends _$CoupleScanConfirmNotifier {
  late ICoupleRepository _repository;

  @override
  CoupleScanConfirmState build() {
    _repository = ref.watch(coupleRepositoryProvider);

    return const CoupleScanConfirmState();
  }

  void dispatch(CoupleScanConfirmIntent intent) => switch (intent) {
    AcceptPressed(:final code) => _accept(code),
  };

  Future<void> _accept(String code) async {
    if (state.status == .loading) return;

    state = state.copyWith(status: .loading);

    final data = await _repository.acceptInvite(code: code);

    data.fold(
      (failure) =>
          state = state.copyWith(status: .failure, message: failure.message),
      (_) {
        ref.invalidate(userProvider);
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
- `@Riverpod()` sem `keepAlive` — descarta junto com a tela de confirm.
- `build()` síncrono — não há nada pra carregar (o lookup já veio via construtor da Location).
- Guard de loading evita duplo accept se user tocar duas vezes rápido.
- Lista de `ref.invalidate` é simétrica à do `CoupleDissolveNotifier` (ver `couple_dissolve_notifier.dart:235-240`) mais `userProvider` — exceção narrada do CLAUDE.md (único uso permitido de provider de outra feature após mutação).

### `CoupleScanConfirmScreen`

`lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` (NOVO):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart';

class CoupleScanConfirmScreen extends StatelessWidget {
  final String code;
  final InviteLookupModel lookup;

  const CoupleScanConfirmScreen({
    super.key,
    required this.code,
    required this.lookup,
  });

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(
            coupleScanConfirmProvider,
            (previous, next) => switch (next.status) {
              .success when previous?.status != .success => _onSuccess(context),
              .failure when previous?.status != .failure => _onFailure(
                context,
                next.message,
              ),
              _ => null,
            },
          );

          final state = ref.watch(coupleScanConfirmProvider);
          final notifier = ref.read(coupleScanConfirmProvider.notifier);

          return Column(
            spacing: 24.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Confirmar união',
                description:
                    'Confira os dados do seu par e confirme para começar a compartilhar finanças.',
              ),
              CoupleScanPartnerPreviewWidget(partner: lookup.partner),
              const Spacer(),
              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Aceitar convite',
                  isLoading: state.status == .loading,
                  onTap: () => notifier.dispatch(AcceptPressed(code)),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _onSuccess(BuildContext context) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Vocês estão conectados.',
    );
    context.root();
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
- Recebe `code` e `lookup` via construtor — passados pela `CoupleScanConfirmLocation`.
- `_onSuccess` toast primeiro, depois `context.root()` — reseta a pilha de navegação até a `HomeLocation`. Padrão de `CoupleDissolveScreen._onSuccess` (toast + pop).
- `ref.listen` switch expression (CLAUDE.md).
- `Spacer` empurra o botão pro rodapé, partner card fica logo abaixo do header.

### `CoupleScanPartnerPreviewWidget`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class CoupleScanPartnerPreviewWidget extends StatelessWidget {
  final UserModel partner;

  const CoupleScanPartnerPreviewWidget({super.key, required this.partner});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .all(16.0),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
      borderRadius: .circular(16.0),
    ),
    child: Row(
      spacing: 16.0,
      children: [
        CircleAvatar(
          radius: 28.0,
          backgroundColor: context.colors.primary,
          child: Text(
            _initial(partner.name),
            style: context.typography.titleMedium?.copyWith(
              color: context.colors.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: Column(
            spacing: 4.0,
            crossAxisAlignment: .start,
            children: [
              Text(partner.name, style: context.typography.titleSmall),
              Text(
                partner.email,
                style: context.typography.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}
```

Mesma técnica de inicial do `CoupleNotifier._initial` (`couple_notifier.dart:53-56`). Pattern visual segue o `SettingsCoupleConnectedWidget`.

### `CoupleScanLocation`

`lib/src/presentation/ui/couple/scan/locations/couple_scan_location.dart` (NOVO):

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart';

final class CoupleScanLocation extends Location {
  @override
  String get path => AppRoutes.coupleScan.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(const CoupleScanScreen());
}
```

### `CoupleScanConfirmLocation`

`lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` (NOVO):

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart';

final class CoupleScanConfirmLocation extends Location {
  final InviteLookupModel lookup;

  CoupleScanConfirmLocation({required this.lookup});

  @override
  String get path => AppRoutes.coupleScanConfirm.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    CoupleScanConfirmScreen(code: '${lookup.coupleId}', lookup: lookup),
  );
}
```

> **Observação**: a Location precisa do `code` original (a string opaca lida do QR) para chamar o `accept` no backend. Mas o lookup retorna `coupleId`, não o `code`. O `code` que o user escaneou precisa ser propagado também pra Location de confirm.
>
> **Correção**: a Location recebe **dois** params:
>
> ```dart
> final class CoupleScanConfirmLocation extends Location {
>   final String code;
>   final InviteLookupModel lookup;
>
>   CoupleScanConfirmLocation({required this.code, required this.lookup});
>   ...
> }
> ```
>
> E no `CoupleScanScreen._navigateToConfirm` propaga o code junto:
>
> ```dart
> void _navigateToConfirm(BuildContext context, String code, InviteLookupModel lookup) =>
>     context.navigate(CoupleScanConfirmLocation(code: code, lookup: lookup));
> ```
>
> Para isso, o `CoupleScanState` precisa também guardar o `code` no momento do `.lookedUp`. Ajuste:
>
> ```dart
> final class CoupleScanState extends Equatable {
>   final String code;   // populado quando status == .lookedUp
>   final String message;
>   final bool canAskAgain;
>   final bool isTorchOn;
>   final CoupleScanStatus status;
>   final InviteLookupModel? lookup;
>   ...
> }
> ```
>
> No `_lookup`, sucesso → `current.copyWith(status: .lookedUp, lookup: lookup, code: trimmedCode)`.
>
> No `ref.listen` da screen → `_navigateToConfirm(context, value.code, value.lookup!)`.

---

## Wiring

### `CoupleInviteLocation` — wire do `onScan`

`lib/src/presentation/ui/couple/invite/locations/couple_invite_location.dart`:

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart';
import 'package:trocado/src/presentation/ui/couple/invite/locations/invite_qr_code_location.dart';
import 'package:trocado/src/presentation/ui/couple/scan/locations/couple_scan_location.dart';

final class CoupleInviteLocation extends Location {
  @override
  String get path => AppRoutes.coupleInvite.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    CoupleInviteScreen(
      onScan: () => context.navigate(CoupleScanLocation()),
      onGenerate: () => context.navigate(InviteQrCodeLocation()),
    ),
  );
}
```

### `CoupleInviteScreen` — aceitar `onScan` no construtor

`lib/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart`:

```dart
class CoupleInviteScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onGenerate;

  const CoupleInviteScreen({
    super.key,
    required this.onScan,
    required this.onGenerate,
  });

  // build() trocar onScan: () {} por onScan: onScan
}
```

Atualizar `CoupleInviteActionsWidget(onGenerate: onGenerate, onScan: onScan)` (linha 47).

### `app_route.dart` — adicionar rotas

```dart
static final coupleScan = AppRoutes._(
  path: '/couple/scan',
  name: 'couple-scan-route',
  regex: RegExp(r'^/couple/scan$'),
);

static final coupleScanConfirm = AppRoutes._(
  path: '/couple/scan/confirm',
  name: 'couple-scan-confirm-route',
  regex: RegExp(r'^/couple/scan/confirm$'),
);
```

E adicionar ambos na lista `_all` (preservando a ordem por tamanho de string que parece convenção visual).

### `AndroidManifest.xml`

`android/app/src/main/AndroidManifest.xml` — adicionar antes do `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### `build.gradle.kts` (app)

`android/app/build.gradle.kts` — no bloco `dependencies { }`:

```kotlin
implementation("com.google.mlkit:barcode-scanning:17.3.0")
```

Forçar versão bundled (não Play Services). Versão exata a confirmar via context7 / docs do MLKit no momento da implementação.

### `Info.plist`

`ios/Runner/Info.plist` — adicionar antes do `</dict>` final:

```xml
<key>NSCameraUsageDescription</key>
<string>Usamos a câmera apenas para ler o QR code do convite do seu par.</string>
```

### `pubspec.yaml`

Adicionar em `dependencies:` (junto com as outras do mesmo grupo):

```yaml
mobile_scanner: ^7.x       # confirmar versão estável atual ao implementar
permission_handler: ^12.x  # idem
```

---

## Testes

### `test/src/infrastructure/responses/invite_lookup_response_test.dart` (NOVO)

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart';

void main() {
  group('InviteLookupResponse', () {
    test('parses valid json', () {
      final json = {
        'couple_id': 1,
        'partner': {
          'id': 2,
          'name': 'Jane Doe',
          'email': 'jane@trocado.app',
        },
      };

      final response = InviteLookupResponse.fromJson(json);

      expect(response.coupleId, 1);
      expect(response.partner.id, 2);
      expect(response.partner.name, 'Jane Doe');
      expect(response.partner.email, 'jane@trocado.app');
    });
  });
}
```

### `test/src/data/repositories/couple_repository_test.dart` — adicionar grupos

```dart
group('GET /couple/invites/{code} (lookup)', () {
  setUp(() {
    when(() => client.get(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Right({
              'couple_id': 1,
              'partner': {
                'id': 2,
                'name': 'Jane',
                'email': 'jane@trocado.app',
              },
            }));
  });

  test('returns Right with InviteLookupModel on success', () async {
    final data = await repository.lookupInvite(code: 'ABC123');

    expect(data.isRight, isTrue);
    expect(data.right.coupleId, 1);
    expect(data.right.partner.email, 'jane@trocado.app');
  });

  test('returns Left NotFoundFailure when code does not exist', () async {
    when(() => client.get(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('not_found')));

    final data = await repository.lookupInvite(code: 'BAD');

    expect(data.left, isA<NotFoundFailure>());
  });

  test('returns Left ValidationFailure when invite expired', () async {
    when(() => client.get(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('invite_expired', 'Convite expirou')));

    final data = await repository.lookupInvite(code: 'OLD');

    expect(data.left, isA<ValidationFailure>());
    expect((data.left as ValidationFailure).message, 'Convite expirou');
  });

  test('returns Left NetworkFailure on connection error', () async {
    when(() => client.get(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('connection_error')));

    final data = await repository.lookupInvite(code: 'X');

    expect(data.left, isA<NetworkFailure>());
  });

  test('returns Left ServerFailure on 5xx', () async {
    when(() => client.get(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('server_error')));

    final data = await repository.lookupInvite(code: 'X');

    expect(data.left, isA<ServerFailure>());
  });
});

group('POST /couple/invites/{code}/accept (accept)', () {
  setUp(() {
    when(() => client.post(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Right({
              'couple_id': 1,
              'partner': {
                'id': 2,
                'name': 'Jane',
                'email': 'jane@trocado.app',
              },
            }));
  });

  test('returns Right with InviteLookupModel on success', () async {
    final data = await repository.acceptInvite(code: 'ABC123');

    expect(data.right.coupleId, 1);
    expect(data.right.partner.name, 'Jane');
  });

  test('returns Left ValidationFailure when invite already used', () async {
    when(() => client.post(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('invite_already_used', 'Convite já foi aceito')));

    final data = await repository.acceptInvite(code: 'USED');

    expect(data.left, isA<ValidationFailure>());
    expect((data.left as ValidationFailure).message, 'Convite já foi aceito');
  });

  test('returns Left ValidationFailure when own invite', () async {
    when(() => client.post(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('invite_own', 'Você não pode aceitar seu próprio convite')));

    final data = await repository.acceptInvite(code: 'SELF');

    expect(data.left, isA<ValidationFailure>());
  });

  test('returns Left ValidationFailure when already in couple', () async {
    when(() => client.post(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('already_in_couple', 'Você já está em um casal')));

    final data = await repository.acceptInvite(code: 'X');

    expect(data.left, isA<ValidationFailure>());
  });

  test('returns Left NetworkFailure on connection error', () async {
    when(() => client.post(parameter: any(named: 'parameter')))
        .thenAnswer((_) async => Left(_failure('connection_error')));

    final data = await repository.acceptInvite(code: 'X');

    expect(data.left, isA<NetworkFailure>());
  });
});
```

Helper `_failure(code, [message])` segue o padrão dos grupos `GET`/`POST`/`DELETE` já existentes em `couple_repository_test.dart`.

### `test/src/presentation/providers/couple_scan_notifier_test.dart` (NOVO)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart';

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

  const lookup = InviteLookupModel(
    coupleId: 1,
    partner: UserModel(id: 2, name: 'Jane', email: 'jane@trocado.app'),
  );

  group('CoupleScanNotifier', () {
    test('transitions to lookedUp on successful lookup', () async {
      when(() => repository.lookupInvite(code: 'ABC'))
          .thenAnswer((_) async => const Right(lookup));

      // Bootstrap permission via override or stub at the notifier level
      // (see comment below about permission stubbing)
      await container.read(coupleScanProvider.future);

      container.read(coupleScanProvider.notifier).dispatch(
            const QrDetected('ABC'),
          );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.status, CoupleScanStatus.lookedUp);
      expect(state.lookup, lookup);
      expect(state.code, 'ABC');
    });

    test('does not re-trigger lookup while in lookup status', () async {
      var callCount = 0;
      when(() => repository.lookupInvite(code: any(named: 'code')))
          .thenAnswer((_) async {
        callCount++;
        return const Right(lookup);
      });

      final notifier = container.read(coupleScanProvider.notifier);
      notifier.dispatch(const QrDetected('ABC'));
      notifier.dispatch(const QrDetected('ABC'));

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });

    test('transitions to failure on Left and exposes message', () async {
      when(() => repository.lookupInvite(code: any(named: 'code')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      container.read(coupleScanProvider.notifier).dispatch(
            const QrDetected('ABC'),
          );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanProvider).value!;
      expect(state.status, CoupleScanStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('manual code follows the same lookup path', () async {
      when(() => repository.lookupInvite(code: 'XYZ'))
          .thenAnswer((_) async => const Right(lookup));

      container.read(coupleScanProvider.notifier).dispatch(
            const ManualCodeSubmitted('XYZ'),
          );

      await Future<void>.delayed(Duration.zero);

      verify(() => repository.lookupInvite(code: 'XYZ')).called(1);
    });
  });
}
```

> **Cobertura de permissão**: `Permission.camera.status` é um método de `permission_handler` que retorna um `Future<PermissionStatus>`. Para testar, ou (a) extrair uma interface fina `ICameraPermissionService` em `domain/services/` com provider em `services_provider.dart` e mockar nos testes, ou (b) usar `PermissionHandlerPlatform` test mock conforme docs do package. Recomendo (a) — segue o padrão do projeto de "services testáveis via interface" (ex: `IMoneyService`, `IDateFormatterService`). A implementação fica em `infrastructure/services/camera_permission_service.dart`.

### `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` (NOVO)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';

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

  const lookup = InviteLookupModel(
    coupleId: 1,
    partner: UserModel(id: 2, name: 'Jane', email: 'jane@trocado.app'),
  );

  group('CoupleScanConfirmNotifier', () {
    test('returns initial state on build', () {
      final state = container.read(coupleScanConfirmProvider);

      expect(state.status, CoupleScanConfirmStatus.initial);
      expect(state.message, '');
    });

    test('transitions to success on Right', () async {
      when(() => repository.acceptInvite(code: 'ABC'))
          .thenAnswer((_) async => const Right(lookup));

      container.read(coupleScanConfirmProvider.notifier).dispatch(
            const AcceptPressed('ABC'),
          );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanConfirmProvider);
      expect(state.status, CoupleScanConfirmStatus.success);
    });

    test('transitions to failure with message on Left', () async {
      when(() => repository.acceptInvite(code: any(named: 'code')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      container.read(coupleScanConfirmProvider.notifier).dispatch(
            const AcceptPressed('ABC'),
          );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(coupleScanConfirmProvider);
      expect(state.status, CoupleScanConfirmStatus.failure);
      expect(state.message, 'Sem conexão com o servidor.');
    });

    test('skips second dispatch while loading', () async {
      var callCount = 0;
      when(() => repository.acceptInvite(code: any(named: 'code')))
          .thenAnswer((_) async {
        callCount++;
        return const Right(lookup);
      });

      final notifier = container.read(coupleScanConfirmProvider.notifier);
      notifier.dispatch(const AcceptPressed('A'));
      notifier.dispatch(const AcceptPressed('A'));

      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);
    });
  });
}
```

### `test/mocks/mocks.dart`

Verificar se `MockCoupleRepository` já existe (foi adicionado em `couple-dissolve`). Se não, adicionar:

```dart
class MockCoupleRepository extends Mock implements ICoupleRepository {}
```

---

## Previews

Apenas widgets puros — `MobileScanner` exige câmera real e não roda no Widget Previewer.

### `couple_scan_overlay_widget_preview.dart`

`lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_overlay_widget_preview.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Overlay')
Widget couple_scan_overlay_preview() => const Scaffold(
  body: Stack(
    children: [
      ColoredBox(color: Colors.black, child: SizedBox.expand()),
      CoupleScanOverlayWidget(),
    ],
  ),
);
```

### `couple_scan_partner_preview_widget_preview.dart`

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Partner Preview')
Widget couple_scan_partner_preview() => const Scaffold(
  body: Padding(
    padding: .all(16.0),
    child: CoupleScanPartnerPreviewWidget(
      partner: UserModel(id: 2, name: 'Jane Doe', email: 'jane@trocado.app'),
    ),
  ),
);
```

### `couple_scan_permission_denied_widget_preview.dart`

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart';

@TrocadoPreview(group: 'Scan', name: 'Permissão — Primeira negação')
Widget couple_scan_permission_first_denial_preview() => Scaffold(
  body: CoupleScanPermissionDeniedWidget(
    canAskAgain: true,
    onAllow: () {},
    onOpenSettings: () {},
    onManualCode: () {},
  ),
);

@TrocadoPreview(group: 'Scan', name: 'Permissão — Negada permanente')
Widget couple_scan_permission_permanent_denial_preview() => Scaffold(
  body: CoupleScanPermissionDeniedWidget(
    canAskAgain: false,
    onAllow: () {},
    onOpenSettings: () {},
    onManualCode: () {},
  ),
);
```

### `couple_scan_confirm_screen_preview.dart`

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart';

@TrocadoPreview(group: 'Scan', name: 'Confirmar — Estado inicial')
Widget couple_scan_confirm_initial_preview() => const CoupleScanConfirmScreen(
  code: 'ABC123',
  lookup: InviteLookupModel(
    coupleId: 1,
    partner: UserModel(id: 2, name: 'Jane Doe', email: 'jane@trocado.app'),
  ),
);
```

> A preview da `CoupleScanConfirmScreen` não consegue mockar diretamente o `coupleScanConfirmProvider` (não há override fácil em previews). Cobre apenas o visual no estado inicial. Estados loading/success/failure ficam validados via teste de notifier.

### Mock builder

`lib/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart`:

```dart
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_lookup_model.dart';

InviteLookupModel inviteLookupMock({
  int coupleId = 1,
  String partnerName = 'Jane Doe',
  String partnerEmail = 'jane@trocado.app',
}) => InviteLookupModel(
  coupleId: coupleId,
  partner: UserModel(id: 2, name: partnerName, email: partnerEmail),
);
```

---

## Camera permission service (suporte a testes)

Pra permitir testar `CoupleScanNotifier._bootstrap` sem chamar `Permission.camera.status` direto, criar uma interface de service:

### `lib/src/domain/services/camera_permission_service.dart` (NOVO)

```dart
enum CameraPermissionStatus { granted, denied, permanentlyDenied }

abstract interface class ICameraPermissionService {
  Future<CameraPermissionStatus> status();
  Future<CameraPermissionStatus> request();
  Future<void> openSettings();
}
```

### `lib/src/infrastructure/services/camera_permission_service.dart` (NOVO)

```dart
import 'package:permission_handler/permission_handler.dart';

import 'package:trocado/src/domain/services/camera_permission_service.dart';

final class CameraPermissionService implements ICameraPermissionService {
  @override
  Future<CameraPermissionStatus> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermissionStatus> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  CameraPermissionStatus _map(PermissionStatus status) => switch (status) {
    .granted => CameraPermissionStatus.granted,
    .restricted ||
    .permanentlyDenied => CameraPermissionStatus.permanentlyDenied,
    _ => CameraPermissionStatus.denied,
  };
}
```

### Provider

`lib/src/main/providers/services_provider.dart` — adicionar:

```dart
@Riverpod(keepAlive: true)
ICameraPermissionService cameraPermissionService(Ref _) =>
    CameraPermissionService();
```

### Atualização do `CoupleScanNotifier`

Substitui chamadas diretas a `Permission.camera.*` por `_cameraPermission` (injetado via `ref.watch(cameraPermissionServiceProvider)` em `build()`).

---

## Ordem sugerida da implementação

1. **Adicionar deps no `pubspec.yaml`** (`mobile_scanner`, `permission_handler`) + `flutter pub get`.
2. **Manifests** (Android `CAMERA`, iOS `NSCameraUsageDescription`, gradle bundled MLKit).
3. **Camada infrastructure/data/domain do lookup + accept**:
   - `InviteLookupResponse` + teste de fromJson.
   - Estender `IRemoteCoupleDataSource` + `RemoteCoupleDataSource`.
   - `InviteLookupModel` (domain).
   - Estender `ICoupleRepository` + `CoupleRepository`.
   - `InviteLookupResponseExtension`.
   - Adicionar grupos `GET` e `POST` no `couple_repository_test.dart`.
4. **Camera permission service** (interface + impl + provider).
5. **Camada presentation do scan** (state/intent/notifier + screen + widgets + locations).
6. **Camada presentation do confirm** (state/intent/notifier + screen + widget partner preview + location).
7. **Wire na `CoupleInviteLocation` + `CoupleInviteScreen`** (aceitar `onScan` no construtor).
8. **app_route.dart** (adicionar `coupleScan`, `coupleScanConfirm` + `_all`).
9. **Testes dos notifiers** (`couple_scan_notifier_test.dart`, `couple_scan_confirm_notifier_test.dart`).
10. **Previews** dos widgets puros.
11. **`dart run build_runner build --delete-conflicting-outputs`** — gera os `.g.dart` novos.
12. **`flutter analyze`** — zero issues.
13. **`flutter test`** — todos passam.
14. **Smoke tests** — ver `tasks.md`.

---

## Atenções e riscos

1. **`mobile_scanner` v7+** introduziu breaking changes vs v5/v6 (API do controller, callback `onDetect`). Confirmar a API exata no momento da implementação via context7 / docs do pub.dev. Os snippets acima usam a API v7.
2. **iOS — permissão de câmera no Simulator** não funciona (simulator não tem câmera). Testar em device físico.
3. **MLKit bundled adiciona ~3MB no AAB**. Conferir tamanho final do AAB pós-implementação (`flutter build appbundle --release`). Se ficar acima do limite confortável, voltar pra Play Services.
4. **Permission flow no Android 13+** — `Permission.camera.request()` retorna direto `granted`/`denied`. O Android até 12 podia retornar estados intermediários — `permission_handler` normaliza.
5. **`context.root()` depende de `duck_router`** — confirmar se o método existe na versão atual (`^7.3.1`). Se não, usar `context.pop()` repetido até a home (ou `Navigator.popUntil`).
6. **`coupleProvider` é `keepAlive: true`** (`couple_notifier.dart:18`) — `ref.invalidate` força re-execução do `build()` na próxima leitura, conforme idioma canônico do Riverpod. Sem precisar mexer no `keepAlive`.
