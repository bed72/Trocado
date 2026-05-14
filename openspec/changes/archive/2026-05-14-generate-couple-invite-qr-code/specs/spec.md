# Spec: generate-couple-invite-qr-code

> Spec filha de `2026-05-13-partner-invite-screen` — implementa o callback `onGenerate` do `PartnerInviteActionsWidget` (que está como `() {}` na spec pai).

## Capability

Permitir ao user gerar um convite de casal a partir da `PartnerInviteScreen`. Ao tocar em "Gerar QR code", o app navega para a `InviteQrCodeScreen`, chama o backend para criar um convite, exibe o QR code + código curto + data de expiração, e oferece um botão "Compartilhar" que abre o share sheet nativo com o link do convite.

A spec NÃO cobre o lado do convidado (scanear, deep link, aceitar) nem operações sobre o casal já vinculado (visualizar, desfazer). Cada um vira spec separada.

## Comportamento

### Navegação a partir da `PartnerInviteScreen`

- `PartnerInviteScreen` SHALL receber `onGenerate` como `VoidCallback` `required` no construtor, espelhando o padrão de `onInvitePartner` em `SettingsScreen`.
- `PartnerInviteScreen` SHALL passar `onGenerate` ao `PartnerInviteActionsWidget` no campo `onGenerate`. O `onScan` permanece `() {}` literal.
- `PartnerInviteScreen` SHALL NOT importar `InviteQrCodeLocation` nem qualquer artefato de location. A regra de encapsulamento da spec pai é mantida — só Locations conhecem Locations.
- `PartnerInviteLocation` SHALL passar `onGenerate: () => context.navigate(InviteQrCodeLocation())` ao construir `PartnerInviteScreen`.

### Rota

- `AppRoutes.partnerInviteQrCode` SHALL existir em `lib/app_route.dart` com:
  - `path`: `'/partner/invite/qr-code'`
  - `name`: `'partner-invite-qr-code-route'`
  - `regex`: `RegExp(r'^/partner/invite/qr-code$')`
- `AppRoutes.partnerInviteQrCode` SHALL estar incluído na lista `_all`.

### Endpoint key

- `EndpointKey.coupleInvites` SHALL existir com `path: '/api/v1/couple/invites'`.
- `EndpointKey.coupleInvites` SHALL NOT estar em `_publicEndpoints` (requer auth).

### `InviteQrCodeLocation`

- Vive em `lib/src/presentation/ui/partner/locations/invite_qr_code_location.dart`.
- `extends Location` (do `duck_router`).
- `path` SHALL retornar `AppRoutes.partnerInviteQrCode.path`.
- `pageBuilder` SHALL retornar `screenPage(const InviteQrCodeScreen())`.
- Sem callbacks injetados nesta etapa.

### `InviteQrCodeScreen`

- Vive em `lib/src/presentation/ui/partner/screens/invite_qr_code_screen.dart`.
- `class InviteQrCodeScreen extends StatelessWidget`. NUNCA `ConsumerWidget`.
- Construtor `const InviteQrCodeScreen({super.key})` — sem parâmetros.
- Estrutura:
  - Raiz `ScaffoldWidget`.
  - `appBar: AppBarWidget(leading: GoBackWidget())`.
  - Corpo: `Padding(all: 16)` envolvendo `Consumer > Column(crossAxisAlignment: .stretch, spacing: 24)`.
  - Conteúdo do `Column`:
    1. `ScreenHeaderWidget(title: 'Convite', description: 'Mostre o QR code para seu par escanear.')`.
    2. `Expanded` com switch em `AsyncValue`:
       - `AsyncLoading` → `InviteQrCodeLoadingWidget()`.
       - `AsyncError` → `InviteQrCodeFailureWidget(onRetry: notifier.retry)`.
       - `AsyncData(:final value)` → `InviteQrCardWidget(data: value)`.
    3. `ButtonWidget.elevated(label: 'Compartilhar', child: Icon(Icons.share, size: 20), onTap: ...)`.
- O `onTap` do botão "Compartilhar" SHALL ser `notifier.share` apenas quando `state is AsyncData`; em loading/error o `onTap` SHALL ser `null` (botão desabilitado).
- `InviteQrCodeScreen` SHALL ler o provider via `Consumer` interno + `ref.watch`/`ref.read`. NUNCA `ConsumerWidget`.
- `InviteQrCodeScreen` SHALL NOT chamar `ref.watch`/`ref.read` em providers de service (`shareClientProvider`, `dateFormatterServiceProvider`). Toda formatação chega pronta no `InviteQrCodePresentationData`.

### `InviteQrCodeNotifier`

- Vive em `lib/src/presentation/ui/partner/notifiers/invite_qr_code_notifier.dart`.
- `@riverpod final class InviteQrCodeNotifier extends _$InviteQrCodeNotifier`.
- `Future<InviteQrCodePresentationData> build() async`:
  - SHALL ler dependências via `ref.watch` nos campos `late` (nunca `late final`):
    - `_shareClient = ref.watch(shareClientProvider)`
    - `_repository = ref.watch(coupleRepositoryProvider)`
    - `_dateFormatter = ref.watch(dateFormatterServiceProvider)`
  - SHALL chamar `_create()` e retornar o resultado.
- `_create()` SHALL:
  - Chamar `_repository.createInvite()`.
  - Em `Left(failure)` SHALL lançar `failure` (capturado como `AsyncError` pelo runtime do AsyncNotifier).
  - Em `Right(invite)` SHALL retornar `_toPresentation(invite)`.
- `_toPresentation(InviteModel invite)` SHALL produzir `InviteQrCodePresentationData` com:
  - `code: invite.code`
  - `qrData: invite.qrData`
  - `formattedExpiration: _dateFormatter.formatInviteExpiration(invite.expiresAt)`
- `retry()` SHALL setar `state = const AsyncLoading()` e em seguida `state = await AsyncValue.guard(_create)`.
- `share()` SHALL:
  - Ler `state.valueOrNull`; se `null`, retornar sem efeito.
  - Chamar `_shareClient.shareText('Vamos juntar nossas finanças no Trocado! Aceite meu convite: ${current.qrData}')`.
- O provider SHALL NOT usar `keepAlive: true`. Cada montagem da tela = novo POST.

### `InviteQrCodePresentationData`

- Vive em `lib/src/presentation/ui/partner/data/invite_qr_code_presentation_data.dart`.
- `final class InviteQrCodePresentationData extends Equatable`.
- Campos: `final String code`, `final String qrData`, `final String formattedExpiration`.
- `props` inclui os 3 campos.
- Sem `copyWith` (VM read-only, produzido só pelo notifier).

### `InviteQrCardWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/invite_qr_card_widget.dart`.
- `class InviteQrCardWidget extends StatelessWidget`.
- Construtor: `const InviteQrCardWidget({super.key, required this.data})` com `final InviteQrCodePresentationData data`.
- Renderiza um `Container` com `padding: all(24)`, `borderRadius: context.radius.cornerRadius100`, `color: context.colors.surfaceContainerHighest`, envolvendo `Column(spacing: 16)` com:
  1. `AspectRatio(aspectRatio: 1)` envolvendo `PrettyQrView.data(data: data.qrData, decoration: PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: context.colors.onSurface)))`.
  2. `Text(data.code, style: headlineMedium.copyWith(letterSpacing: 4, fontWeight: w600))`.
  3. `Text(data.formattedExpiration, style: bodySmall.copyWith(color: context.colors.onSurfaceVariant))`.

### `InviteQrCodeLoadingWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/invite_qr_code_loading_widget.dart`.
- `class InviteQrCodeLoadingWidget extends StatelessWidget`. Sem props.
- Renderiza `Skeletonizer(enabled: true, child: InviteQrCardWidget(data: <placeholder>))` com placeholder fixo: `code: 'AAAAAA'`, `qrData: 'trocado://invite/AAAAAA'`, `formattedExpiration: 'Expira em 00/00 às 00:00'`.

### `InviteQrCodeFailureWidget`

- Vive em `lib/src/presentation/ui/partner/widgets/invite_qr_code_failure_widget.dart`.
- `class InviteQrCodeFailureWidget extends StatelessWidget`.
- Construtor: `const InviteQrCodeFailureWidget({super.key, required this.onRetry})` com `final VoidCallback onRetry`.
- Renderiza `Center > Column(mainAxisAlignment: .center, spacing: 16)` com:
  1. `Icon(Icons.error_outline, size: 48, color: context.colors.error)`.
  2. `Text('Não conseguimos gerar o convite agora.', textAlign: .center, style: bodyMedium)`.
  3. `ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry)`.

### Camada de dados

- `InviteModel` SHALL existir em `lib/src/domain/models/couple/invite_model.dart` com `String code`, `String qrData`, `int expiresAt`, `copyWith`, `Equatable`.
- `ICoupleRepository` SHALL existir em `lib/src/domain/repositories/interface_couple_repository.dart` com `Future<Either<Failure, InviteModel>> createInvite()`. Nesta spec é o único método; futuras specs adicionam outros.
- `InviteResponse` SHALL existir em `lib/src/infrastructure/clients/http/responses/couple/invite_response.dart` com `String code`, `String qrData`, `String expiresAt` e `fromJson` mapeando `code`, `qr_data`, `expires_at`. SHALL NOT ter `toModel()`.
- `InviteResponseExtension` SHALL existir em `lib/src/data/extensions/invite_response_extension.dart` com `toModel()` retornando `InviteModel` (convertendo `expiresAt` ISO 8601 → ms epoch via `DateTime.parse(expiresAt).millisecondsSinceEpoch`).
- `IRemoteCoupleDataSource` + `RemoteCoupleDataSource` SHALL existir em `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` (mesmo arquivo). Método `createInvite()` SHALL retornar `Future<Either<FailureResponse, InviteResponse>>`. Implementação SHALL chamar `_client.post(parameter: Requests(EndpointKey.coupleInvites.path))` e mapear via `response.either(FailureResponse.fromJson, InviteResponse.fromJson)`.
- `CoupleRepository` SHALL existir em `lib/src/data/repositories/couple_repository.dart` implementando `ICoupleRepository`. `createInvite()` SHALL ser:
  ```dart
  final data = await _dataSource.createInvite();
  return data.either((failure) => failure.toFailure(), (response) => response.toModel());
  ```
  SHALL NOT ter `try-catch`. SHALL NOT criar `_toFailure` local.

### Cliente de Share

- `IShareClient` + `ShareClient` SHALL existir em `lib/src/infrastructure/clients/share/share_client.dart` (mesmo arquivo, padrão de clients).
- `IShareClient` SHALL expor `Future<void> shareText(String text)`.
- `ShareClient.shareText` SHALL chamar `SharePlus.instance.share(ShareParams(text: text))` (API do `share_plus` ^11.x).

### Serviço de formatação de data

- Se `IDateFormatterService` ainda não tem método `String formatInviteExpiration(int millisecondsSinceEpoch)`, SHALL ser adicionado nesta spec (interface + impl).
- O formato SHALL ser `'Expira em dd/MM \'às\' HH:mm'` em locale `pt_BR` (ex: `'Expira em 18/03 às 14:30'`).
- SHALL usar `intl.DateFormat`.

### Providers (`main/providers/`)

- `clients_provider.dart` SHALL ganhar `@Riverpod() IShareClient shareClient(Ref ref) => ShareClient();`.
- `data_sources.provider.dart` SHALL ganhar `@Riverpod() IRemoteCoupleDataSource remoteCoupleDataSource(Ref ref) => RemoteCoupleDataSource(client: ref.watch(httpClientProvider));`.
- `repositories_provider.dart` SHALL ganhar `@Riverpod() ICoupleRepository coupleRepository(Ref ref) => CoupleRepository(dataSource: ref.watch(remoteCoupleDataSourceProvider));`.
- Após adicionar, `dart run build_runner build --delete-conflicting-outputs` SHALL regerar os `.g.dart`.

### `pubspec.yaml`

- SHALL adicionar `pretty_qr_code: ^3.6.0` em `dependencies`.
- SHALL adicionar `share_plus: ^11.0.0` em `dependencies`.
- SHALL NOT adicionar configuração nativa adicional (compartilhamento é só texto; QR é renderizado em Dart puro).

### Testes

- `test/src/infrastructure/responses/couple/invite_response_test.dart` SHALL cobrir `InviteResponse.fromJson` com payload válido (todos os 3 campos).
- `test/src/data/extensions/invite_response_extension_test.dart` SHALL cobrir `toModel()` — `code` e `qrData` mapeados, `expiresAt` convertido de ISO 8601 para ms epoch.
- `test/src/data/repositories/couple_repository_test.dart` SHALL cobrir `createInvite()`:
  - success retorna `Right(InviteModel)`.
  - cada `FailureResponse.code` mapeia para o `Failure` correto (`networkError → NetworkFailure`, `serverError → ServerFailure`, `notFound → NotFoundFailure`, outros → `ValidationFailure(message)`).
  - Mock em `IHttpClient` (não em `IRemoteCoupleDataSource`).
- `test/src/presentation/providers/invite_qr_code_notifier_test.dart` SHALL cobrir:
  - `build` success → `AsyncData(InviteQrCodePresentationData)` com `formattedExpiration` vindo do mock do `IDateFormatterService`.
  - `build` failure → `AsyncError(Failure)`.
  - `retry` reset → `AsyncLoading` → `AsyncData`/`AsyncError`.
  - `share` em `AsyncData` chama `_shareClient.shareText` com o texto esperado.
  - `share` em `AsyncLoading`/`AsyncError` SHALL NOT chamar `_shareClient.shareText` (no-op).
- `test/mocks/mocks.dart` SHALL ganhar:
  - `MockCoupleRepository implements ICoupleRepository`.
  - `MockRemoteCoupleDataSource implements IRemoteCoupleDataSource`.
  - `MockShareClient implements IShareClient`.
- Descrições de testes SHALL estar em inglês.
- Declaração de mocks SHALL usar o tipo da interface (`late ICoupleRepository repository`), não o tipo do mock.

### Restrições de encapsulamento

- `InviteQrCodeScreen` SHALL NOT importar widgets/states/intents/data de outras features (`presentation/ui/<outra>/`).
- `InviteQrCodeNotifier` SHALL NOT importar providers de outras features.
- `PartnerInviteScreen` SHALL NOT importar `InviteQrCodeLocation` nem `presentation/ui/partner/locations/`. Só recebe `onGenerate` via construtor.
- Widgets desta spec (`InviteQrCardWidget`, `InviteQrCodeLoadingWidget`, `InviteQrCodeFailureWidget`) SHALL viver em `presentation/ui/partner/widgets/` (família partner). NÃO são compartilhados com outras features nesta spec.

### Botão de voltar

- O `GoBackWidget` da `AppBarWidget` SHALL ser o único caminho de saída da `InviteQrCodeScreen`.
- Tocar nele SHALL fazer `context.pop()` (comportamento padrão).
- Não há outro caminho de saída (sem `onSuccess`, sem auto-close).
