# Tasks: generate-couple-invite-qr-code

> Spec filha de `2026-05-13-partner-invite-screen`. Resolve o callback `onGenerate` que está como `() {}` na spec pai.

## pubspec.yaml

- [x] `pubspec.yaml` — adicionar em `dependencies`:
  - `pretty_qr_code: ^3.6.0`
  - `share_plus: ^11.0.0`
- [x] `flutter pub get`

## app_route.dart

- [x] `lib/app_route.dart` — adicionar `static final partnerInviteQrCode = AppRoutes._(path: '/partner/invite/qr-code', name: 'partner-invite-qr-code-route', regex: RegExp(r'^/partner/invite/qr-code$'))`
- [x] `lib/app_route.dart` — incluir `partnerInviteQrCode` em `_all` (logo após `partnerInvite`)

## domain/

- [x] `lib/src/domain/models/couple/invite_model.dart` (NOVO) — `code: String`, `qrData: String`, `expiresAt: int`; `copyWith`; `Equatable`
- [x] `lib/src/domain/repositories/interface_couple_repository.dart` (NOVO) — `abstract interface class ICoupleRepository { Future<Either<Failure, InviteModel>> createInvite(); }`
- [x] (Se ainda não existe no projeto) `lib/src/domain/services/interface_date_formatter_service.dart` — adicionar `String formatInviteExpiration(int millisecondsSinceEpoch)`. **Confirmar contrato atual antes de editar; se método já existe com mesma semântica, reusar.**

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar `coupleInvites('/api/v1/couple/invites')`. NÃO entra em `_publicEndpoints`
- [x] `lib/src/infrastructure/clients/http/responses/couple/invite_response.dart` (NOVO) — `code`, `qrData`, `expiresAt` (todos `String`); `fromJson` mapeando `code`, `qr_data`, `expires_at`. **SEM `toModel()`**
- [x] `lib/src/infrastructure/clients/share/share_client.dart` (NOVO) — interface `IShareClient` com `Future<void> shareText(String text)` + impl `ShareClient` chamando `SharePlus.instance.share(ShareParams(text: text))`. Interface + impl no MESMO arquivo
- [x] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` (NOVO) — interface `IRemoteCoupleDataSource.createInvite()` retornando `Future<Either<FailureResponse, InviteResponse>>` + impl `RemoteCoupleDataSource({required IHttpClient client})`. Implementação chama `_client.post(parameter: Requests(EndpointKey.coupleInvites.path))` e mapeia via `response.either(FailureResponse.fromJson, InviteResponse.fromJson)`. **Validar contrato do `Requests` — se exige `body:`, passar `body: const {}`**
- [x] (Se a interface `IDateFormatterService` ganhou método novo) `lib/src/infrastructure/services/date_formatter_service.dart` — implementar `formatInviteExpiration` usando `DateFormat("dd/MM 'às' HH:mm", 'pt_BR')`

## data/

- [x] `lib/src/data/extensions/invite_response_extension.dart` (NOVO) — `InviteResponseExtension.toModel()` retornando `InviteModel(code: code, qrData: qrData, expiresAt: DateTime.parse(expiresAt).millisecondsSinceEpoch)`
- [x] `lib/src/data/repositories/couple_repository.dart` (NOVO) — `CoupleRepository implements ICoupleRepository` com `createInvite()` usando `data.either((failure) => failure.toFailure(), (response) => response.toModel())`. **Sem `try-catch`. Sem `_toFailure` local**

## main/providers/

- [x] `lib/src/main/providers/clients_provider.dart` — adicionar `@Riverpod() IShareClient shareClient(Ref ref) => ShareClient();`
- [x] `lib/src/main/providers/data_sources.provider.dart` — adicionar `@Riverpod() IRemoteCoupleDataSource remoteCoupleDataSource(Ref ref) => RemoteCoupleDataSource(client: ref.watch(httpClientProvider));`
- [x] `lib/src/main/providers/repositories_provider.dart` — adicionar `@Riverpod() ICoupleRepository coupleRepository(Ref ref) => CoupleRepository(dataSource: ref.watch(remoteCoupleDataSourceProvider));`
- [x] `dart run build_runner build --delete-conflicting-outputs`

## presentation/

### View-model

- [x] `lib/src/presentation/ui/partner/data/invite_qr_code_presentation_data.dart` (NOVO) — `final class InviteQrCodePresentationData extends Equatable` com `code`, `qrData`, `formattedExpiration` (todos `String`); `props` com os 3; SEM `copyWith`

### Notifier

- [x] `lib/src/presentation/ui/partner/notifiers/invite_qr_code_notifier.dart` (NOVO) — `@riverpod` `AsyncNotifier<InviteQrCodePresentationData>`:
  - Campos `late` (NUNCA `late final`): `_shareClient`, `_repository`, `_dateFormatter`
  - `build()` async: `ref.watch` nos 3 providers + `await _create()`
  - `_create()` chama `_repository.createInvite()`; `Left` → `throw failure`; `Right` → `_toPresentation(invite)`
  - `_toPresentation(InviteModel)` produz VM com `formattedExpiration` via `_dateFormatter.formatInviteExpiration(invite.expiresAt)`
  - `retry()`: `state = const AsyncLoading()` + `state = await AsyncValue.guard(_create)`
  - `share()`: lê `state.valueOrNull`; se null no-op; senão chama `_shareClient.shareText('Vamos juntar nossas finanças no Trocado! Aceite meu convite: ${current.qrData}')`
  - SEM `keepAlive: true`
- [x] `dart run build_runner build --delete-conflicting-outputs`

### Widgets

- [x] `lib/src/presentation/ui/partner/widgets/invite_qr_card_widget.dart` (NOVO) — `Container(padding: 24, borderRadius: cornerRadius100, color: surfaceContainerHighest)` envolvendo `Column(spacing: 16)` com `AspectRatio(1) > PrettyQrView.data(...)` + `Text(code, headlineMedium letterSpacing 4 w600)` + `Text(formattedExpiration, bodySmall onSurfaceVariant)`
- [x] `lib/src/presentation/ui/partner/widgets/invite_qr_code_loading_widget.dart` (NOVO) — `Skeletonizer(enabled: true, child: InviteQrCardWidget(data: <placeholder fixo>))`. Placeholder: `code: 'AAAAAA'`, `qrData: 'trocado://invite/AAAAAA'`, `formattedExpiration: 'Expira em 00/00 às 00:00'`
- [x] `lib/src/presentation/ui/partner/widgets/invite_qr_code_failure_widget.dart` (NOVO) — `Center > Column(mainAxisAlignment: .center, spacing: 16)` com `Icon(error_outline, 48, error)` + `Text('Não conseguimos gerar o convite agora.', textAlign center, bodyMedium)` + `ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry)`

### Screen

- [x] `lib/src/presentation/ui/partner/screens/invite_qr_code_screen.dart` (NOVO) — `StatelessWidget`; `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()), child: Padding(16) > Consumer > Column(stretch, spacing: 24))` com `ScreenHeaderWidget('Convite', 'Mostre o QR code para seu par escanear.')` + `Expanded(switch state)` + `ButtonWidget.elevated(label: 'Compartilhar', icon: Icons.share)`. Switch: `AsyncLoading() => InviteQrCodeLoadingWidget()`, `AsyncError() => InviteQrCodeFailureWidget(onRetry: notifier.retry)`, `AsyncData(:final value) => InviteQrCardWidget(data: value)`, `_ => SizedBox.shrink()`. `onTap` do share: `state is AsyncData ? notifier.share : null`

### Location

- [x] `lib/src/presentation/ui/partner/locations/invite_qr_code_location.dart` (NOVO) — `final class InviteQrCodeLocation extends Location`; `path => AppRoutes.partnerInviteQrCode.path`; `pageBuilder => (_) => screenPage(const InviteQrCodeScreen())`

### Wire-up na spec pai

- [x] `lib/src/presentation/ui/partner/screens/partner_invite_screen.dart` — adicionar `final VoidCallback onGenerate;` (required) ao construtor; passar `onGenerate: onGenerate` ao `PartnerInviteActionsWidget` (deixar `onScan: () {}`)
- [x] `lib/src/presentation/ui/partner/locations/partner_invite_location.dart` — passar `onGenerate: () => context.navigate(InviteQrCodeLocation())` ao construir `PartnerInviteScreen`. Mudar `pageBuilder` de `(_) => screenPage(const PartnerInviteScreen())` para `(context) => screenPage(PartnerInviteScreen(onGenerate: () => context.navigate(InviteQrCodeLocation())))`

## test/

### Mocks

- [x] `test/mocks/mocks.dart` — adicionar `MockCoupleRepository implements ICoupleRepository`, `MockRemoteCoupleDataSource implements IRemoteCoupleDataSource`, `MockShareClient implements IShareClient`

### Response

- [x] `test/src/infrastructure/responses/couple/invite_response_test.dart` (NOVO) — `fromJson` com `{ "code": "A3K7FN", "expires_at": "2026-03-18T14:30:00Z", "qr_data": "trocado://invite/A3K7FN" }` mapeando os 3 campos

### Extension

- [x] `test/src/data/extensions/invite_response_extension_test.dart` (NOVO) — `toModel()` com `code` e `qrData` mapeados; `expiresAt` ISO 8601 convertido para ms epoch (validar com `DateTime.utc(2026, 3, 18, 14, 30).millisecondsSinceEpoch`)

### Repository

- [x] `test/src/data/repositories/couple_repository_test.dart` (NOVO) — mock em `IHttpClient`:
  - `createInvite` success (POST 201 com JSON válido) → `Right(InviteModel)`
  - Cada `code` de `FailureResponse` → `Failure` correspondente:
    - `connection_error` → `NetworkFailure`
    - `not_found` → `NotFoundFailure`
    - `server_error` → `ServerFailure`
    - código desconhecido → `ValidationFailure(message)`

### Notifier

- [x] `test/src/presentation/providers/invite_qr_code_notifier_test.dart` (NOVO) — `ProviderContainer` com overrides em `coupleRepositoryProvider`, `shareClientProvider`, `dateFormatterServiceProvider`:
  - `build` success → `AsyncData(InviteQrCodePresentationData)` com `formattedExpiration` igual ao stub do mock do dateFormatter
  - `build` failure → `AsyncError(NetworkFailure)` (ou similar)
  - `retry` reset: state vira `AsyncLoading` antes de virar `AsyncData`/`AsyncError`
  - `share` em `AsyncData` chama `shareClient.shareText` com `'Vamos juntar nossas finanças no Trocado! Aceite meu convite: trocado://invite/A3K7FN'`
  - `share` em `AsyncLoading` é no-op (verificar `verifyNever(() => shareClient.shareText(any()))`)
  - `share` em `AsyncError` é no-op

## Pré-condições (validar antes de implementar)

- `IHttpClient.post({required Requests parameter})` existe e aceita `Requests` sem body explicitamente — se exigir body, ajustar para `body: const {}`
- `EndpointKey` enum existe e o interceptor de auth injeta token nos endpoints não-públicos
- `FailureResponseExtension.toFailure()` existe em `lib/src/data/extensions/failure_response_extension.dart`
- `Requests` class em `lib/src/infrastructure/clients/http/` aceita só `path` (sem `body`) — confirmar ao implementar
- `ButtonWidget.elevated(label, child, onTap)` aceita `onTap: null` para desabilitar — confirmar visual de disabled (provavelmente já implementado pra essa variant)
- `IDateFormatterService` existe; confirmar se já tem método com semântica equivalente a `formatInviteExpiration`. Se não, adicionar nesta spec
- `Skeletonizer` está no pubspec (`^2.1.3` — confirmado)
- `context.colors.surfaceContainerHighest`, `error`, `onSurface`, `onSurfaceVariant` existem no theme
- `context.radius.cornerRadius100` existe
- `MockHttpClient`, `MockDateFormatterService` (se já existe) em `test/mocks/mocks.dart`

## Verificação

- [x] `flutter analyze` — zero issues nos arquivos tocados
- [x] `flutter test` — toda a suíte verde (sem regressão na suíte existente)
- [ ] Smoke `flutter run` (pendente — rodar manualmente):
  - Settings → tocar "Convidar parceiro" → `PartnerInviteScreen` abre normalmente
  - Tocar em "Gerar QR code" → `InviteQrCodeScreen` abre
  - Loading inicial mostra skeleton do card
  - Após sucesso, QR aparece com código e expiração formatada
  - Botão "Compartilhar" abre o share sheet nativo com o texto esperado
  - Botão de voltar retorna para `PartnerInviteScreen` sem erros
  - Voltar e reabrir gera um QR diferente (novo POST)
  - Forçar erro (mock backend offline) → tela de failure com botão "Tentar novamente" funciona
- [x] `InviteQrCodeScreen` é `StatelessWidget` (não `ConsumerWidget`); `Consumer` é interno
- [x] `InviteQrCodeScreen` NÃO importa `shareClientProvider` nem `dateFormatterServiceProvider`
- [x] `PartnerInviteScreen` NÃO importa `InviteQrCodeLocation` nem `presentation/ui/partner/locations/`
- [x] Provider do notifier NÃO usa `keepAlive: true`
- [x] Interface + impl do `IShareClient` e do `IRemoteCoupleDataSource` estão no mesmo arquivo (sem arquivo `interface_` separado — regra de clients/datasources)
- [x] `InviteResponse` NÃO tem `toModel()` — mapping fica em `data/extensions/`
- [x] Datasource NÃO tem `try-catch`
- [x] Repository NÃO tem `try-catch` nem `_toFailure` local
- [x] Todas as descrições de testes em inglês
- [x] Mocks declarados pelo tipo da interface (`late ICoupleRepository repository`), não pelo tipo do mock
