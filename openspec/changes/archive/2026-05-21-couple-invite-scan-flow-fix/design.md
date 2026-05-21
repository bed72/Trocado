# Design: couple-invite-scan-flow-fix

## Estado atual

### `IRemoteCoupleDataSource` chama rota inexistente

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart:11-21`:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({  // ❌ rota não existe
    required String code,
  });
  Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({
    required String code,
  });
}
```

`lookupInvite` monta `GET ${EndpointKey.coupleInvites.path}/$code` → `/api/v1/couple/invites/{code}`. Swagger lista só 4 rotas em Couples; essa não está entre elas.

`acceptInvite` monta `POST ${EndpointKey.coupleInvites.path}/$code/accept` → `/api/v1/couple/invites/{code}/accept`. O path real é `/api/v1/invites/{code}/accept`.

### `EndpointKey`

`lib/src/infrastructure/clients/http/endpoint_key.dart:15`:

```dart
coupleInvites('/api/v1/couple/invites'),
```

Sem entrada `invites('/api/v1/invites')`.

### Scan dispatcha lookup com valor cru do QR

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart:68-89` (fix parcial já aplicado):

```dart
Future<void> _lookup(String code) async {
  ...
  final parsed = _parseCode(code);
  if (parsed.isEmpty) return;

  state = AsyncData(current.copyWith(status: .lookup));

  final data = await _repository.lookupInvite(code: parsed);  // ❌ rota não existe
  ...
}

String _parseCode(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.scheme == 'trocado' && uri.host == 'invite') {
    return uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
  }
  return trimmed;
}
```

`_parseCode` está correto e fica. O resto do `_lookup` (chamada a `_repository.lookupInvite`, transições `.lookup`/`.lookedUp`, gravação de `state.lookup`) é o que desaparece.

### `CoupleScanState` carrega `lookup` que vai sumir

`lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart:5-65` — enum tem `.lookup`, `.lookedUp`; state tem `lookup: InviteLookupModel?`.

### `CoupleScanConfirmScreen` exige `lookup` pra renderizar partner preview

`lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart:19-27,58`:

```dart
class CoupleScanConfirmScreen extends StatelessWidget {
  final String code;
  final InviteLookupModel lookup;
  ...
  CoupleScanPartnerPreviewWidget(partner: lookup.partner),
```

Sem `lookup` (porque o lookup deixou de ser chamado), a screen quebra.

### `CoupleScanConfirmNotifier` não captura `partnerName` do accept

`couple_scan_confirm_notifier.dart:36-57` — no `Right` do accept, descarta o model (`(_) { ... ref.invalidate ...; state = ... .success }`). Para mostrar `'Você está conectado com Marina.'` no toast, precisa ler `model.partner.name`.

### `CoupleScanPartnerPreviewWidget` fica órfão

Usado só em `couple_scan_confirm_screen.dart:58` e no preview. Sem o uso na screen, o widget e seu preview viram código morto.

---

## Infrastructure

### `EndpointKey.invites`

`lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar entrada nova mantendo a convenção do enum:

```dart
enum EndpointKey {
  me('/api/v1/me'),
  signIn('/api/v1/token'),
  couple('/api/v1/couple'),
  invites('/api/v1/invites'),         // NOVO
  budgets('/api/v1/budgets'),
  expenses('/api/v1/expenses'),
  ...
  coupleInvites('/api/v1/couple/invites'),  // continua — usado pelo createInvite
  ...
}
```

`isPublic`/`isPublicPath` não mudam (a rota de invites exige Bearer; já é o default).

### `InviteAcceptResponse`

Renomear arquivo e classe. Conteúdo idêntico ao `InviteLookupResponse` atual:

`lib/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart`:

```dart
import 'package:trocado/src/infrastructure/clients/http/responses/user_response.dart';

final class InviteAcceptResponse {
  final int coupleId;
  final UserResponse partner;

  const InviteAcceptResponse({required this.coupleId, required this.partner});

  factory InviteAcceptResponse.fromJson(Map<String, dynamic> json) =>
      InviteAcceptResponse(
        coupleId: json['couple_id'] as int,
        partner: UserResponse.fromJson(json['partner'] as Map<String, dynamic>),
      );
}
```

Deletar `invite_lookup_response.dart`.

### `RemoteCoupleDataSource`

`lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` passa a:

```dart
abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, void>> dissolve();
  Future<Either<FailureResponse, CoupleResponse>> findActive();
  Future<Either<FailureResponse, InviteResponse>> createInvite();
  Future<Either<FailureResponse, InviteAcceptResponse>> acceptInvite({
    required String code,
  });
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  ...
  @override
  Future<Either<FailureResponse, InviteAcceptResponse>> acceptInvite({
    required String code,
  }) async {
    final response = await _client.post(
      parameter: Requests('${EndpointKey.invites.path}/$code/accept'),
    );

    return response.either(
      FailureResponse.fromJson,
      InviteAcceptResponse.fromJson,
    );
  }
}
```

`lookupInvite` some.

---

## Domain

### `InviteAcceptModel`

`lib/src/domain/models/couple/invite_accept_model.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class InviteAcceptModel extends Equatable {
  final int coupleId;
  final UserModel partner;

  const InviteAcceptModel({required this.coupleId, required this.partner});

  InviteAcceptModel copyWith({int? coupleId, UserModel? partner}) =>
      InviteAcceptModel(
        partner: partner ?? this.partner,
        coupleId: coupleId ?? this.coupleId,
      );

  @override
  List<Object?> get props => [coupleId, partner];
}
```

Deletar `invite_lookup_model.dart`.

### `ICoupleRepository`

`lib/src/domain/repositories/interface_couple_repository.dart`:

```dart
abstract interface class ICoupleRepository {
  Future<Either<Failure, void>> dissolve();
  Future<Either<Failure, CoupleModel>> findActive();
  Future<Either<Failure, InviteModel>> createInvite();
  Future<Either<Failure, void>> shareInvite({required String qrData});
  Future<Either<Failure, InviteAcceptModel>> acceptInvite({
    required String code,
  });
}
```

`lookupInvite` removido.

---

## Data

### `InviteAcceptResponseExtension`

`lib/src/data/extensions/invite_accept_response_extension.dart`:

```dart
import 'package:trocado/src/domain/models/user_model.dart';
import 'package:trocado/src/domain/models/couple/invite_accept_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart';

extension InviteAcceptResponseExtension on InviteAcceptResponse {
  InviteAcceptModel toModel() => InviteAcceptModel(
    coupleId: coupleId,
    partner: UserModel(id: partner.id, name: partner.name, email: partner.email),
  );
}
```

Deletar `invite_lookup_response_extension.dart`.

### `CoupleRepository`

`lib/src/data/repositories/couple_repository.dart`:

```dart
@override
Future<Either<Failure, InviteAcceptModel>> acceptInvite({
  required String code,
}) async {
  final data = await _dataSource.acceptInvite(code: code);

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toModel(),
  );
}
```

Método `lookupInvite` deletado. Imports limpos.

---

## Presentation

### `CoupleScanState` enxuto

`lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart`:

```dart
enum CoupleScanStatus {
  ready,
  failure,
  initial,
  detected,                // NOVO — substitui .lookup + .lookedUp
  permissionDenied,
  cameraUnavailable,
}

final class CoupleScanState extends Equatable {
  final String code;
  final String message;
  final String manualCode;
  final bool canAskAgain;
  final CoupleScanStatus status;
  final String? manualCodeFailure;

  const CoupleScanState({
    this.code = '',
    this.message = '',
    this.manualCode = '',
    this.manualCodeFailure,
    this.status = .initial,
    this.canAskAgain = true,
  });

  CoupleScanState copyWith({
    String? code,
    String? message,
    String? manualCode,
    bool? canAskAgain,
    CoupleScanStatus? status,
    String? manualCodeFailure,
    bool clearManualCodeFailure = false,
  }) => CoupleScanState(
    code: code ?? this.code,
    status: status ?? this.status,
    message: message ?? this.message,
    manualCode: manualCode ?? this.manualCode,
    manualCodeFailure: clearManualCodeFailure
        ? null
        : manualCodeFailure ?? this.manualCodeFailure,
    canAskAgain: canAskAgain ?? this.canAskAgain,
  );

  @override
  List<Object?> get props => [
    code,
    status,
    message,
    manualCode,
    canAskAgain,
    manualCodeFailure,
  ];
}
```

Removidos: `lookup: InviteLookupModel?`, status `.lookup`/`.lookedUp`, parâmetro `lookup` do `copyWith`.

### `CoupleScanNotifier` sem repository

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart`:

```dart
@Riverpod()
final class CoupleScanNotifier extends _$CoupleScanNotifier {
  late ICameraPermissionService _permission;
  late CoupleScanFormValidator _formValidator;

  @override
  Future<CoupleScanState> build() async {
    _permission = ref.watch(cameraPermissionServiceProvider);
    _formValidator = ref.watch(coupleScanFormValidatorProvider);

    return _stateFromPermission(await _permission.status());
  }

  void dispatch(CoupleScanIntent intent) => switch (intent) {
    RetryPressed() => _retry(),
    OpenSettingsPressed() => _openSettings(),
    QrDetected(:final code) => _detect(code),
    PermissionRequested() => _requestPermission(),
    ManualCodeSubmitted() => _onManualCodeSubmitted(),
    ManualCodeChanged(:final code) => _onManualCodeChanged(code),
  };

  ...

  void _detect(String code) {
    final current = state.value;
    if (current == null) return;
    if (current.status != .ready) return;

    final parsed = _parseCode(code);
    if (parsed.isEmpty) return;

    state = AsyncData(current.copyWith(code: parsed, status: .detected));
  }

  void _onManualCodeSubmitted() {
    final current = state.value;
    if (current == null) return;

    final validated = _formValidator(current);
    state = AsyncData(validated.state);

    if (validated.code != null) _detect(validated.code!);
  }

  String _parseCode(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'trocado' && uri.host == 'invite') {
      return uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    }
    return trimmed;
  }

  ...
}
```

Mudanças: remove `_repository`, remove `_lookup`, renomeia para `_detect`. `_retry()` continua igual (volta pra `.ready`). `_parseCode` é o mesmo.

### `CoupleScanScreen` reage a `.detected`

`lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart`:

```dart
Future<void> _onStatusChanged(
  CoupleScanStatus? previous,
  CoupleScanState next,
) async {
  if (previous == next.status) return;

  switch (next.status) {
    case .detected:
      await _safeStop();
    case .ready when previous == .failure:
      await _safeStart();
    default:
  }

  if (next.status == .detected) {
    if (mounted) _navigateToConfirm(next.code);
  }

  if (next.status == .failure && previous != .failure) {
    if (mounted) _showFailure(next.message);
  }
}

...

void _navigateToConfirm(String code) =>
    context.navigate(CoupleScanConfirmLocation(code: code));
```

Não importa mais `InviteLookupModel`. O botão "Digitar código manualmente" considera `isLooking` agora? Não — passa a `state.status == .detected` (curtíssimo, até navegar) só pra desabilitar interação dupla; o efeito visível é mínimo. Ajuste:

```dart
final isCapturing = state.status == .detected;
...
ButtonWidget.elevated(
  isLoading: isCapturing,
  onTap: isCapturing ? null : _openManualSheet,
  ...
)
```

### `CoupleScanConfirmLocation` sem `lookup`

`lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart`:

```dart
final class CoupleScanConfirmLocation extends Location {
  final String code;

  const CoupleScanConfirmLocation({required this.code});

  @override
  String get path => AppRoutes.coupleScanConfirm.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(CoupleScanConfirmScreen(code: code));
}
```

### `CoupleScanConfirmScreen` mostra só o code

`lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart`:

```dart
class CoupleScanConfirmScreen extends StatelessWidget {
  final String code;

  const CoupleScanConfirmScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          ref.listen(coupleScanConfirmProvider, (previous, next) {
            switch (next.status) {
              case .success when previous?.status != .success:
                _onSuccess(context, next.partnerName);
              case .failure when previous?.status != .failure:
                _onFailure(context, next.message);
              default:
            }
          });

          final state = ref.watch(coupleScanConfirmProvider);
          final notifier = ref.read(coupleScanConfirmProvider.notifier);

          return Column(
            spacing: 24.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Confirmar união',
                description:
                    'Confira o código do convite antes de aceitar.',
              ),
              Center(
                child: Text(
                  code,
                  style: context.typography.headlineMedium?.copyWith(
                    fontWeight: .w600,
                    letterSpacing: 4.0,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: .infinity,
                child: ButtonWidget.elevated(
                  label: 'Aceitar convite',
                  isLoading: state.status == .loading,
                  onTap: state.status == .loading
                      ? null
                      : () => notifier.dispatch(AcceptPressed(code)),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _onSuccess(BuildContext context, String partnerName) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Você está conectado com $partnerName.',
    );
    context.root();
  }

  void _onFailure(BuildContext context, String message) => showToastWidget(
    context: context,
    title: 'Opps',
    type: .failure,
    description: message,
  );
}
```

Import de `InviteLookupModel` e `CoupleScanPartnerPreviewWidget` removidos. O `Text(code)` herda o estilo idêntico do `invite_qr_card_widget.dart:42-46`.

### `CoupleScanConfirmState` ganha `partnerName`

`lib/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart`:

```dart
final class CoupleScanConfirmState extends Equatable {
  final String message;
  final String partnerName;
  final CoupleScanConfirmStatus status;

  const CoupleScanConfirmState({
    this.message = '',
    this.partnerName = '',
    this.status = .initial,
  });

  CoupleScanConfirmState copyWith({
    String? message,
    String? partnerName,
    CoupleScanConfirmStatus? status,
  }) => CoupleScanConfirmState(
    status: status ?? this.status,
    message: message ?? this.message,
    partnerName: partnerName ?? this.partnerName,
  );

  @override
  List<Object?> get props => [status, message, partnerName];
}
```

### `CoupleScanConfirmNotifier` captura partner

`lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart`:

```dart
Future<void> _accept(String code) async {
  if (state.status == .loading) return;

  state = state.copyWith(status: .loading);

  final data = await _repository.acceptInvite(code: code);

  data.fold(
    (failure) =>
        state = state.copyWith(status: .failure, message: failure.message),
    (model) {
      ref.invalidate(userProvider);
      ref.invalidate(coupleProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(insightsProvider);
      ref.invalidate(activeBudgetProvider);
      ref.invalidate(recentExpensesProvider);
      state = state.copyWith(
        status: .success,
        partnerName: model.partner.name,
      );
    },
  );
}
```

### Limpeza

- `lib/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart` — deletar.
- `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_partner_preview_widget_preview.dart` — deletar.
- `lib/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart` → renomear pra `invite_accept_mock.dart`; classe alvo `InviteAcceptModel`; função `inviteAcceptMock(...)`. Continua usado pelos testes de notifier/repo.

---

## Testes

### `test/src/data/repositories/couple_repository_test.dart`

- Remover `group('lookupInvite', ...)` inteiro (linhas ~273-343).
- No `group('acceptInvite', ...)`:
  - Trocar `InviteLookupResponse` → `InviteAcceptResponse` em todos os stubs.
  - Trocar asserções `data.right.partner.name == 'Marina'` para usar `InviteAcceptModel`.
- Atualizar imports.

### `test/src/infrastructure/responses/invite_lookup_response_test.dart`

- Renomear arquivo para `invite_accept_response_test.dart`.
- Trocar `InviteLookupResponse` → `InviteAcceptResponse`.
- Mesmos casos de teste (sucesso + erro de schema).

### `test/src/data/extensions/` — sem teste novo

A extension `InviteAcceptResponseExtension.toModel()` herda os casos do `invite_lookup_response_extension_test.dart` se existir. Renomear se houver; senão, sem ação.

### `test/src/presentation/providers/couple_scan_notifier_test.dart`

Reescrita parcial:

- Remover `late ICoupleRepository coupleRepository;`, `coupleRepository = MockCoupleRepository();`, e `coupleRepositoryProvider.overrideWithValue(...)` do `makeContainer`.
- Remover todos os `when(() => coupleRepository.lookupInvite(...))`.
- Atualizar testes do grupo `QrDetected`:
  - "transitions to lookedUp on successful lookup" → "transitions to detected and stores code" (sem mock de repo; só checa `state.code == 'ABC'` e `state.status == .detected`).
  - "ignores second QrDetected while in lookup status" → "ignores second QrDetected while in detected status" (não chama mais lookup; só verifica que `state.code` não muda).
  - "transitions to failure on Left and exposes message" → **deletar** (não há mais Left no scan; failure pertence ao confirm).
  - Manter "ignores empty code", "extracts code from trocado://invite/<code> deep link" (do fix anterior), "ignores deep link with empty code segment".
- Grupo `ManualCodeSubmitted`:
  - "runs lookup when code is valid" → "transitions to detected with code when manual code is valid" (sem stub de lookup; só checa `state.code == 'AB3K7N'` e `state.status == .detected`).
  - "sets manualCodeFailure when code is invalid" — sem mudança estrutural.
- Grupo `RetryPressed`:
  - "resets state back to ready" — agora começa de `.detected` em vez de `.failure` (não há failure pós-detect no scan); assertions mudam pra refletir.

### `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart`

- Atualizar stubs de `acceptInvite` para retornar `Right(InviteAcceptModel)`.
- Adicionar asserção no teste de sucesso: `expect(state.partnerName, 'Marina');`.

### `test/mocks/mocks.dart`

- Sem mudança estrutural — `MockCoupleRepository` continua válido sem `lookupInvite`.

---

## Riscos

1. **Confirm screen sem preview = user pode aceitar code errado.** Mitigação: code exibido grande e centralizado na confirm; user verifica visualmente contra o QR/digitação. Sem partner data antes do accept, é o melhor que dá com a API atual.
2. **Compat com `couple_scan_qr_code` (spec anterior).** A spec original previu `lookup → confirm → accept`. Estamos cortando a primeira etapa. Os campos `lookup` que sumiram são todos internos da feature scan/; nada fora desse módulo dependia deles.
3. **Build runner.** As mudanças no notifier (remoção de `_repository` como dependência) e no state requerem rerun do `build_runner` pros `.g.dart`. Listado em `Verificação`.
4. **Cache invalidations no accept** continuam idênticas; comportamento pós-accept (home re-renderiza, settings vira "couple connected", etc) não muda.

---

## Notas

- `share_client` continua usando `qrData` (a string completa do deep link) na mensagem de compartilhar — comportamento desejado para o caminho de partilha sem QR.
- O `InviteCodeValidation` (`length: 6`, alphabet alfanumérico) continua aplicável: o backend tem o code com 6 chars no payload de criação. Sem mudanças.
- Se uma rodada futura adicionar deep link nativo (`trocado://invite/<code>` abrindo o app), o `_parseCode` já suporta — basta wirar no `DeepLinkHandler` para emitir `QrDetected(code)` no notifier.
