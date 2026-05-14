# Design: generate-couple-invite-qr-code

## Visão geral

```
[PartnerInviteScreen]
  └── PartnerInviteActionsWidget
        ├── "Scanear QR code"  → onScan: () {}           (out of scope)
        └── "Gerar QR code"    → onGenerate: NAVIGATE
                                       │
                                       ▼
                              [InviteQrCodeScreen]
                                  ├── AppBarWidget(leading: GoBackWidget)
                                  └── Padding(16)
                                      └── Column
                                          ├── ScreenHeaderWidget('Convite', 'Mostre o QR code...')
                                          ├── InviteQrCardWidget       ← QR + code + expiração
                                          └── ButtonWidget.elevated    ← "Compartilhar"
```

Pipeline:
```
InviteQrCodeNotifier.build() async
  ↓
ICoupleRepository.createInvite()
  ↓
RemoteCoupleDataSource.createInvite()
  ↓
IHttpClient.post('/api/v1/couple/invites')
  ↓
InviteResponse.fromJson  →  InviteResponseExtension.toModel  →  InviteModel
  ↓
notifier produz InviteQrCodePresentationData (com expiração formatada)
  ↓
Consumer na screen renderiza AsyncValue<InviteQrCodePresentationData>
```

Share:
```
[Compartilhar] → notifier.share()
                    ↓
                  IShareClient.shareText('Vamos juntar nossas finanças...')
                    ↓
                  share_plus → share sheet nativo
```

---

## API Contract

### `POST /api/v1/couple/invites`

**Request:** sem body. Header `Authorization: Bearer <jwt>` (interceptor existente).

**Success 201:**
```json
{
  "code": "A3K7FN",
  "expires_at": "2026-03-18T14:30:00Z",
  "qr_data": "trocado://invite/A3K7FN"
}
```

**Error (qualquer 4xx/5xx):**
```json
{
  "errors": [
    { "field": "...", "message": "...", "code": "..." }
  ]
}
```

Tratamento padrão via `FailureResponse` + `FailureResponseExtension.toFailure()`. Sem casos especiais.

---

## `pubspec.yaml`

Adicionar em `dependencies`:

```yaml
pretty_qr_code: ^3.6.0
share_plus: ^11.0.0
```

Sem necessidade de configuração nativa pra `share_plus` (compartilhamos só texto, sem arquivos). `pretty_qr_code` é Dart puro (renderiza via Canvas).

---

## `app_route.dart`

Novo entry:

```dart
static final partnerInviteQrCode = AppRoutes._(
  path: '/partner/invite/qr-code',
  name: 'partner-invite-qr-code-route',
  regex: RegExp(r'^/partner/invite/qr-code$'),
);
```

Incluir em `_all` logo após `partnerInvite`.

---

## `endpoint_key.dart`

Novo entry:

```dart
coupleInvites('/api/v1/couple/invites'),
```

Privado (precisa auth). NÃO entra em `_publicEndpoints`.

---

## `domain/`

### `domain/models/couple/invite_model.dart` (NOVO)

```dart
import 'package:equatable/equatable.dart';

class InviteModel extends Equatable {
  final String code;
  final String qrData;
  final int expiresAt;

  const InviteModel({
    required this.code,
    required this.qrData,
    required this.expiresAt,
  });

  InviteModel copyWith({
    String? code,
    String? qrData,
    int? expiresAt,
  }) =>
      InviteModel(
        code: code ?? this.code,
        qrData: qrData ?? this.qrData,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [code, qrData, expiresAt];
}
```

### `domain/repositories/interface_couple_repository.dart` (NOVO)

```dart
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/invite_model.dart';

abstract interface class ICoupleRepository {
  Future<Either<Failure, InviteModel>> createInvite();
}
```

---

## `infrastructure/`

### `infrastructure/clients/http/responses/couple/invite_response.dart` (NOVO)

```dart
class InviteResponse {
  final String code;
  final String qrData;
  final String expiresAt;

  const InviteResponse({
    required this.code,
    required this.qrData,
    required this.expiresAt,
  });

  factory InviteResponse.fromJson(Map<String, dynamic> json) => InviteResponse(
    code: json['code'] as String,
    qrData: json['qr_data'] as String,
    expiresAt: json['expires_at'] as String,
  );
}
```

> **NUNCA** adicionar `toModel()` aqui. Mapping fica em `data/extensions/`.

### `infrastructure/clients/share/share_client.dart` (NOVO)

```dart
import 'package:share_plus/share_plus.dart';

abstract interface class IShareClient {
  Future<void> shareText(String text);
}

final class ShareClient implements IShareClient {
  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
```

> Interface + impl no mesmo arquivo (padrão de clients).

### `infrastructure/datasources/remote/remote_couple_data_source.dart` (NOVO)

```dart
import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests.dart';
import 'package:trocado/src/infrastructure/clients/http/endpoint_key.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_response.dart';

abstract interface class IRemoteCoupleDataSource {
  Future<Either<FailureResponse, InviteResponse>> createInvite();
}

final class RemoteCoupleDataSource implements IRemoteCoupleDataSource {
  final IHttpClient _client;

  RemoteCoupleDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, InviteResponse>> createInvite() async {
    final response = await _client.post(
      parameter: Requests(EndpointKey.coupleInvites.path),
    );
    return response.either(FailureResponse.fromJson, InviteResponse.fromJson);
  }
}
```

> POST sem body. `Requests(path)` sem `body:` (usar default — provavelmente `null`/`{}` no `Requests` class — confirmar no contrato existente do `Requests` durante implementação).

---

## `data/`

### `data/extensions/invite_response_extension.dart` (NOVO)

```dart
import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/couple/invite_response.dart';

extension InviteResponseExtension on InviteResponse {
  InviteModel toModel() => InviteModel(
    code: code,
    qrData: qrData,
    expiresAt: DateTime.parse(expiresAt).millisecondsSinceEpoch,
  );
}
```

### `data/repositories/couple_repository.dart` (NOVO)

```dart
import 'package:trocado/src/domain/either/either.dart';
import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/data/extensions/invite_response_extension.dart';
import 'package:trocado/src/data/extensions/failure_response_extension.dart';

import 'package:trocado/src/infrastructure/datasources/remote/remote_couple_data_source.dart';

final class CoupleRepository implements ICoupleRepository {
  final IRemoteCoupleDataSource _dataSource;

  CoupleRepository({required IRemoteCoupleDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, InviteModel>> createInvite() async {
    final data = await _dataSource.createInvite();
    return data.either(
      (failure) => failure.toFailure(),
      (response) => response.toModel(),
    );
  }
}
```

---

## `main/providers/`

### `clients_provider.dart` — adicionar

```dart
@Riverpod()
IShareClient shareClient(Ref ref) => ShareClient();
```

### `data_sources.provider.dart` — adicionar

```dart
@Riverpod()
IRemoteCoupleDataSource remoteCoupleDataSource(Ref ref) =>
    RemoteCoupleDataSource(client: ref.watch(httpClientProvider));
```

### `repositories_provider.dart` — adicionar

```dart
@Riverpod()
ICoupleRepository coupleRepository(Ref ref) =>
    CoupleRepository(dataSource: ref.watch(remoteCoupleDataSourceProvider));
```

Após editar: `dart run build_runner build --delete-conflicting-outputs`.

---

## `presentation/`

### `presentation/ui/partner/data/invite_qr_code_presentation_data.dart` (NOVO)

```dart
import 'package:equatable/equatable.dart';

final class InviteQrCodePresentationData extends Equatable {
  final String code;
  final String qrData;
  final String formattedExpiration;

  const InviteQrCodePresentationData({
    required this.code,
    required this.qrData,
    required this.formattedExpiration,
  });

  @override
  List<Object?> get props => [code, qrData, formattedExpiration];
}
```

### `presentation/ui/partner/notifiers/invite_qr_code_notifier.dart` (NOVO)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';
import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/models/couple/invite_model.dart';
import 'package:trocado/src/domain/services/interface_date_formatter_service.dart';
import 'package:trocado/src/domain/repositories/interface_couple_repository.dart';

import 'package:trocado/src/infrastructure/clients/share/share_client.dart';

import 'package:trocado/src/presentation/ui/partner/data/invite_qr_code_presentation_data.dart';

part 'invite_qr_code_notifier.g.dart';

@riverpod
final class InviteQrCodeNotifier extends _$InviteQrCodeNotifier {
  late IShareClient _shareClient;
  late ICoupleRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<InviteQrCodePresentationData> build() async {
    _shareClient = ref.watch(shareClientProvider);
    _repository = ref.watch(coupleRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);
    return await _create();
  }

  Future<InviteQrCodePresentationData> _create() async {
    final data = await _repository.createInvite();
    return data.fold(
      (failure) => throw failure,
      (invite) => _toPresentation(invite),
    );
  }

  InviteQrCodePresentationData _toPresentation(InviteModel invite) =>
      InviteQrCodePresentationData(
        code: invite.code,
        qrData: invite.qrData,
        formattedExpiration: _dateFormatter.formatInviteExpiration(invite.expiresAt),
      );

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_create);
  }

  Future<void> share() async {
    final current = state.valueOrNull;
    if (current == null) return;

    await _shareClient.shareText(
      'Vamos juntar nossas finanças no Trocado! Aceite meu convite: ${current.qrData}',
    );
  }
}
```

> `_create()` lança a `Failure` em caso de erro. `AsyncNotifier` captura como `AsyncError` (assumido). Se essa hipótese não bater com o runtime do Riverpod 3, ajustar pra `AsyncValue.guard` no `build` também.
>
> Sobre `_dateFormatter.formatInviteExpiration`: depende do `IDateFormatterService` ter (ou ganhar) um método pra formato curto de expiração (ex: `'Expira em 18/03 às 14:30'`). Se ainda não tem, **adicionar à interface + impl** como parte desta spec (escopo justificável: o notifier precisa do método; sem ele a screen ficaria com formatação ad-hoc). Confirmar contrato atual do `IDateFormatterService` ao implementar.

### `presentation/ui/partner/widgets/invite_qr_card_widget.dart` (NOVO)

```dart
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:trocado/src/presentation/extensions/colors_extension.dart';
import 'package:trocado/src/presentation/extensions/radius_extension.dart';

import 'package:trocado/src/presentation/ui/partner/data/invite_qr_code_presentation_data.dart';

class InviteQrCardWidget extends StatelessWidget {
  final InviteQrCodePresentationData data;

  const InviteQrCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24.0),
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius100,
      color: context.colors.surfaceContainerHighest,
    ),
    child: Column(
      spacing: 16.0,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PrettyQrView.data(
            data: data.qrData,
            decoration: PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: context.colors.onSurface),
            ),
          ),
        ),
        Text(
          data.code,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 4.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          data.formattedExpiration,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
```

### `presentation/ui/partner/widgets/invite_qr_code_failure_widget.dart` (NOVO)

Card com ícone `Icons.error_outline`, texto de erro e `ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry)`.

### `presentation/ui/partner/widgets/invite_qr_code_loading_widget.dart` (NOVO)

`Skeletonizer(enabled: true, child: InviteQrCardWidget(data: <placeholder>))`. Placeholder com `qrData: 'trocado://invite/AAAAAA'`, `code: 'AAAAAA'`, `formattedExpiration: 'Expira em 00/00 às 00:00'`.

### `presentation/ui/partner/screens/invite_qr_code_screen.dart` (NOVO)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/partner/notifiers/invite_qr_code_notifier.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/invite_qr_card_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/invite_qr_code_loading_widget.dart';
import 'package:trocado/src/presentation/ui/partner/widgets/invite_qr_code_failure_widget.dart';

class InviteQrCodeScreen extends StatelessWidget {
  const InviteQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(inviteQrCodeNotifierProvider);
          final notifier = ref.read(inviteQrCodeNotifierProvider.notifier);

          return Column(
            spacing: 24.0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeaderWidget(
                title: 'Convite',
                description: 'Mostre o QR code para seu par escanear.',
              ),
              Expanded(
                child: switch (state) {
                  AsyncLoading() => const InviteQrCodeLoadingWidget(),
                  AsyncError() => InviteQrCodeFailureWidget(onRetry: notifier.retry),
                  AsyncData(:final value) => InviteQrCardWidget(data: value),
                  _ => const SizedBox.shrink(),
                },
              ),
              ButtonWidget.elevated(
                label: 'Compartilhar',
                onTap: state is AsyncData ? notifier.share : null,
                child: const Icon(Icons.share, size: 20.0),
              ),
            ],
          );
        },
      ),
    ),
  );
}
```

### `presentation/ui/partner/locations/invite_qr_code_location.dart` (NOVO)

```dart
import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/screen_page.dart';
import 'package:trocado/src/presentation/ui/partner/screens/invite_qr_code_screen.dart';

final class InviteQrCodeLocation extends Location {
  @override
  String get path => AppRoutes.partnerInviteQrCode.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => screenPage(const InviteQrCodeScreen());
}
```

### `partner_invite_screen.dart` — ALTERAR

Adicionar `onGenerate` ao construtor:

```dart
class PartnerInviteScreen extends StatelessWidget {
  final VoidCallback onGenerate;

  const PartnerInviteScreen({super.key, required this.onGenerate});
  ...
  PartnerInviteActionsWidget(onGenerate: onGenerate, onScan: () {}),
  ...
}
```

### `partner_invite_location.dart` — ALTERAR

Injetar `onGenerate`:

```dart
final class PartnerInviteLocation extends Location {
  @override
  String get path => AppRoutes.partnerInvite.path;

  @override
  LocationPageBuilder get pageBuilder => (context) => screenPage(
    PartnerInviteScreen(
      onGenerate: () => context.navigate(InviteQrCodeLocation()),
    ),
  );
}
```

> A screen continua sem importar Locations de outras features (não precisa, já que recebe callback). A regra de encapsulamento da spec pai é mantida.

---

## Testes

### Estratégia
- `InviteResponse.fromJson` — puro.
- `CoupleRepository.createInvite` — mock em `IHttpClient` (mesma estratégia das outras suítes de repository).
- `InviteResponseExtension.toModel` — puro.
- `InviteQrCodeNotifier` — mock em `ICoupleRepository`, `IShareClient`, `IDateFormatterService` + `ProviderContainer`.

### Cobertura por arquivo
- `test/src/infrastructure/responses/couple/invite_response_test.dart`
- `test/src/data/extensions/invite_response_extension_test.dart`
- `test/src/data/repositories/couple_repository_test.dart`
- `test/src/presentation/providers/invite_qr_code_notifier_test.dart`

### Mocks novos em `test/mocks/mocks.dart`
- `MockCoupleRepository implements ICoupleRepository`
- `MockRemoteCoupleDataSource implements IRemoteCoupleDataSource`
- `MockShareClient implements IShareClient`
- (`MockDateFormatterService` provavelmente já existe — confirmar)

---

## Riscos e considerações

1. **POST a cada visita.** Decisão explícita (item 2 das decisões). Se virar problema (rate limit no backend, custo, etc.), a próxima spec pode adicionar `keepAlive` + botão "Gerar novo".
2. **Sem deep link.** O `qr_data` é `trocado://invite/CODE`. Hoje só funciona se o app está instalado e o handler de deep link estiver wired (não está, ainda). Spec de scan/aceite/deep link resolve.
3. **Compartilhar texto puro.** Quem recebe o link via WhatsApp/SMS precisa do app instalado. Sem app → nada acontece. Decisão consciente — Universal Links são fase posterior.
4. **`formatInviteExpiration` no `IDateFormatterService`.** Se o método ainda não existe, **esta spec adiciona** (interface + impl). Justificado pelo escopo (notifier precisa formatar; manter formato consolidado no service evita strings de formato espalhadas pela presentation).
5. **`Requests(path)` sem body.** Validar no contrato atual da classe `Requests` que aceita construção sem `body:`. Se exigir body, passar `body: const {}`.
6. **`pretty_qr_code` API.** A versão 3.x usa `PrettyQrView.data(data: ..., decoration: ...)`. Validar no import durante implementação; ajustar conforme a release exata do pubspec resolver.
