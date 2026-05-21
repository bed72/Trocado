# Tasks: couple-scan-qr-code

## Dependências e configuração nativa

- [ ] `pubspec.yaml` — adicionar `mobile_scanner: ^7.x` e `permission_handler: ^12.x` (confirmar versões estáveis atuais via context7 antes de pinar) na seção `dependencies:`; rodar `flutter pub get`
- [ ] `android/app/src/main/AndroidManifest.xml` — adicionar `<uses-permission android:name="android.permission.CAMERA" />` no topo, junto com `INTERNET` e `POST_NOTIFICATIONS`
- [ ] `android/app/build.gradle.kts` — adicionar `implementation("com.google.mlkit:barcode-scanning:17.3.0")` (versão estável atual, confirmar) no bloco `dependencies { }` do app pra forçar MLKit bundled (não Play Services dinâmico)
- [ ] `ios/Runner/Info.plist` — adicionar key `NSCameraUsageDescription` com value `"Usamos a câmera apenas para ler o QR code do convite do seu par."`

## infrastructure/

- [ ] `lib/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart` (NOVO) — `InviteLookupResponse` com `couple_id: int` e `partner: UserResponse` (reusa `UserResponse.fromJson` aninhado)
- [ ] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — adicionar à `IRemoteCoupleDataSource`:
  - `Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({required String code})`
  - `Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({required String code})`
- [ ] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — implementar `lookupInvite` chamando `_client.get(parameter: Requests('${EndpointKey.coupleInvites.path}/$code'))` e `acceptInvite` chamando `_client.post(parameter: Requests('${EndpointKey.coupleInvites.path}/$code/accept'))`; ambos `response.either(FailureResponse.fromJson, InviteLookupResponse.fromJson)`
- [ ] `lib/src/infrastructure/clients/http/responses/failure/failure_code.dart` — verificar/adicionar os códigos `invite_not_found`, `invite_expired`, `invite_already_used`, `invite_own`, `already_in_couple` no enum `FailureCodeResponse` (confirmar com backend os strings exatos no momento da implementação)
- [ ] `lib/src/infrastructure/services/camera_permission_service.dart` (NOVO) — `CameraPermissionService implements ICameraPermissionService` com `status()`, `request()`, `openSettings()`; mapeia `PermissionStatus` (do `permission_handler`) para `CameraPermissionStatus` do domínio (granted/denied/permanentlyDenied)

## domain/

- [ ] `lib/src/domain/models/couple/invite_lookup_model.dart` (NOVO) — `final class InviteLookupModel extends Equatable` com `coupleId: int` e `partner: UserModel`; `copyWith(coupleId, partner)`; props `[coupleId, partner]`
- [ ] `lib/src/domain/services/camera_permission_service.dart` (NOVO) — `enum CameraPermissionStatus { granted, denied, permanentlyDenied }` + `abstract interface class ICameraPermissionService` com `status()`, `request()`, `openSettings()`
- [ ] `lib/src/domain/repositories/interface_couple_repository.dart` — adicionar à `ICoupleRepository`:
  - `Future<Either<Failure, InviteLookupModel>> lookupInvite({required String code})`
  - `Future<Either<Failure, InviteLookupModel>> acceptInvite({required String code})`

## data/

- [ ] `lib/src/data/extensions/invite_lookup_response_extension.dart` (NOVO) — `extension InviteLookupResponseExtension on InviteLookupResponse` com `toModel()` mapeando `coupleId` direto e `partner` para `UserModel(id, name, email)` inline (sem reusar `UserResponseExtension` ainda — extrair só se outra spec precisar)
- [ ] `lib/src/data/repositories/couple_repository.dart` — implementar `lookupInvite({code})` chamando `_dataSource.lookupInvite(code: code)` e retornando `data.either((failure) => failure.toFailure(), (response) => response.toModel())`
- [ ] `lib/src/data/repositories/couple_repository.dart` — implementar `acceptInvite({code})` chamando `_dataSource.acceptInvite(code: code)` e retornando `data.either((failure) => failure.toFailure(), (response) => response.toModel())`

## main/providers/

- [ ] `lib/src/main/providers/services_provider.dart` — adicionar `@Riverpod(keepAlive: true) ICameraPermissionService cameraPermissionService(Ref _) => CameraPermissionService();`

## presentation/ui/couple/scan/ (novo módulo)

- [ ] Criar diretório `lib/src/presentation/ui/couple/scan/` com subpastas `data/`, `locations/`, `notifiers/`, `screens/`, `widgets/`, `preview/screens/`, `preview/widgets/`, `preview/mocks/`
- [ ] `lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart` (NOVO) — `enum CoupleScanStatus { initial, permissionDenied, cameraUnavailable, ready, lookup, lookedUp, failure }` + `final class CoupleScanState extends Equatable` com `code: String`, `message: String`, `canAskAgain: bool`, `isTorchOn: bool`, `status: CoupleScanStatus`, `lookup: InviteLookupModel?`; defaults `('', '', true, false, .initial, null)`; `copyWith(...)`; props
- [ ] `lib/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart` (NOVO) — `enum CoupleScanConfirmStatus { initial, loading, success, failure }` + `final class CoupleScanConfirmState extends Equatable` com `message: String` e `status: CoupleScanConfirmStatus`; defaults `('', .initial)`; `copyWith(...)`; props
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_intent.dart` (NOVO) — `sealed class CoupleScanIntent` + variantes `PermissionRequested`, `OpenSettingsPressed`, `QrDetected(code)`, `ManualCodeSubmitted(code)`, `TorchPressed`, `RetryPressed`; todas com construtor `const`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart` (NOVO) — `sealed class CoupleScanConfirmIntent` + `final class AcceptPressed(this.code) extends CoupleScanConfirmIntent`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` (NOVO) — `@Riverpod()` (sem `keepAlive`) `AsyncNotifier<CoupleScanState>`; `late ICoupleRepository`, `late ICameraPermissionService`, `late MobileScannerController` injetados via `ref.watch` em `build()`; `ref.onDispose(() => _controller.dispose())`; `_bootstrap()` checa permissão e retorna state inicial; `dispatch` switch expression sobre `CoupleScanIntent` chamando métodos privados; `_lookup(code)` faz guard de status, `_controller.stop()`, chama `_repository.lookupInvite(code: code.trim())`, atualiza state com `.lookedUp` (lookup + code) ou `.failure` (message); `_retry()` chama `_controller.start()` e volta a `.ready`; `_toggleTorch()` chama `_controller.toggleTorch()` e flipa `isTorchOn`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart` (NOVO) — `@Riverpod()` (sem `keepAlive`); `late ICoupleRepository`; `build()` síncrono retornando `const CoupleScanConfirmState()`; `dispatch` switch expression sobre `CoupleScanConfirmIntent`; `_accept(code)` guarda loading, chama `_repository.acceptInvite(code: code)`, em sucesso invalida `userProvider`, `coupleProvider`, `expensesProvider`, `insightsProvider`, `budgetsProvider`, `activeBudgetProvider`, `recentExpensesProvider` e seta `.success`; em falha seta `.failure` com `message`
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_overlay_widget.dart` (NOVO) — `StatelessWidget`; `Stack` com overlay preto translúcido `Color(0xAA000000)`, janela central 240x240 com `Border.all(width: 3, color: context.colors.primary)` e `borderRadius: 16`, e texto guia `"Aponte a câmera para o QR code do seu par"` no rodapé
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_torch_button_widget.dart` (NOVO) — `StatelessWidget`; `FloatingActionButton.small` com ícone `Icons.flash_on` / `Icons.flash_off` baseado no `isOn`, callback `onPressed`
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_permission_denied_widget.dart` (NOVO) — `StatelessWidget` com props `canAskAgain: bool`, `onAllow: VoidCallback`, `onOpenSettings: VoidCallback`, `onManualCode: VoidCallback`; layout `Column` com `ScreenHeaderWidget` ("Câmera não disponível"), `Spacer`, `ButtonWidget.elevated` que alterna entre "Permitir câmera" (se `canAskAgain`) e "Abrir configurações"; `ButtonWidget.outlined` "Digitar código manualmente"
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart` (NOVO) — `StatelessWidget` com prop `partner: UserModel`; `Container` com `surfaceContainer` background + 16 radius; `Row` com `CircleAvatar` exibindo inicial do nome (helper `_initial` igual ao `couple_notifier.dart:53-56`), nome em `titleSmall` e email em `bodyMedium`
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_sheet.dart` (NOVO) — função pública `showCoupleScanManualCodeSheet(context) → Future<String?>` que usa `showBottomSheetWidget` do projeto; corpo `_ManualCodeBody` (StatefulWidget privado local — válido pois é input controlado, não screen) com `TextFieldWidget` controlado e `ButtonWidget.elevated("Confirmar")` que pop com o valor trimado; botão desabilitado quando vazio
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` (NOVO) — `StatelessWidget` + `Consumer` interno; `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))`; `ref.listen(coupleScanProvider, ...)` para reagir a `.lookedUp` (navegar pra confirm) e `.failure` (toast + dispatch `RetryPressed`); switch expression sobre `state.status` retornando `CoupleScanPermissionDeniedWidget` (para `.permissionDenied`/`.cameraUnavailable`) ou `MobileScanner` + overlay + torch + botão "Digitar código manualmente" (default); `_openManualSheet` chama o sheet e dispatcha `ManualCodeSubmitted(code)`; `_navigateToConfirm(context, code, lookup)` navega `CoupleScanConfirmLocation(code: code, lookup: lookup)`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` (NOVO) — `StatelessWidget` + `Consumer` interno; props `code: String`, `lookup: InviteLookupModel` via construtor; `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))` + `Padding all(16.0)` + `Column(spacing: 24.0, crossAxisAlignment: .start)` com `ScreenHeaderWidget("Confirmar união", ...)`, `CoupleScanPartnerPreviewWidget(partner: lookup.partner)`, `Spacer`, `ButtonWidget.elevated("Aceitar convite", isLoading: state.status == .loading, onTap: () => notifier.dispatch(AcceptPressed(code)))`; `ref.listen` em `coupleScanConfirmProvider` reagindo a `.success` (toast + `context.root()`) e `.failure` (toast)
- [ ] `lib/src/presentation/ui/couple/scan/locations/couple_scan_location.dart` (NOVO) — `final class CoupleScanLocation extends Location` com `path: AppRoutes.coupleScan.path` e `pageBuilder` retornando `screenPage(const CoupleScanScreen())`
- [ ] `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` (NOVO) — `final class CoupleScanConfirmLocation extends Location` com props `code: String` e `lookup: InviteLookupModel`; `path: AppRoutes.coupleScanConfirm.path`; `pageBuilder` retornando `screenPage(CoupleScanConfirmScreen(code: code, lookup: lookup))`

## presentation/ui/couple/invite/ (wiring do onScan)

- [ ] `lib/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart` — adicionar prop `onScan: VoidCallback` no construtor (após `onGenerate`); passar `onScan: onScan` no `CoupleInviteActionsWidget` (linha 47, hoje é `onScan: () {}`)
- [ ] `lib/src/presentation/ui/couple/invite/locations/couple_invite_location.dart` — importar `CoupleScanLocation`; injetar `onScan: () => context.navigate(CoupleScanLocation())` no `CoupleInviteScreen`

## main/

- [ ] `lib/app_route.dart` — adicionar `coupleScan` (path `/couple/scan`, name `couple-scan-route`, regex `^/couple/scan$`) e `coupleScanConfirm` (path `/couple/scan/confirm`, name `couple-scan-confirm-route`, regex `^/couple/scan/confirm$`)
- [ ] `lib/app_route.dart` — adicionar ambos em `_all` (preservando convenção visual da ordenação por tamanho)

## preview/

- [ ] `lib/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart` (NOVO) — função `inviteLookupMock({coupleId, partnerName, partnerEmail})` retornando `InviteLookupModel`
- [ ] `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_overlay_widget_preview.dart` (NOVO) — `@TrocadoPreview(group: 'Scan', name: 'Overlay')` com `Stack` (fundo preto + overlay)
- [ ] `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_partner_preview_widget_preview.dart` (NOVO) — `@TrocadoPreview(group: 'Scan', name: 'Partner Preview')` exibindo o card com mock
- [ ] `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_permission_denied_widget_preview.dart` (NOVO) — dois previews: `@TrocadoPreview(name: 'Permissão — Primeira negação')` com `canAskAgain: true` e `@TrocadoPreview(name: 'Permissão — Negada permanente')` com `canAskAgain: false`
- [ ] `lib/src/presentation/ui/couple/scan/preview/screens/couple_scan_confirm_screen_preview.dart` (NOVO) — `@TrocadoPreview(group: 'Scan', name: 'Confirmar — Estado inicial')` instanciando a screen com mock; sem mockar provider (apenas visual)

## test/

- [ ] `test/src/infrastructure/responses/invite_lookup_response_test.dart` (NOVO) — teste de `fromJson` com payload válido cobrindo todos os campos (`couple_id`, `partner.id`, `partner.name`, `partner.email`)
- [ ] `test/src/data/repositories/couple_repository_test.dart` — adicionar grupo `GET /couple/invites/{code} (lookup)` com 5 testes: sucesso → `Right(InviteLookupModel)`; `not_found` → `NotFoundFailure`; `invite_expired` (código novo) → `ValidationFailure('Convite expirou')`; `connection_error` → `NetworkFailure`; `server_error` → `ServerFailure`
- [ ] `test/src/data/repositories/couple_repository_test.dart` — adicionar grupo `POST /couple/invites/{code}/accept (accept)` com 5 testes: sucesso → `Right(InviteLookupModel)`; `invite_already_used` → `ValidationFailure`; `invite_own` → `ValidationFailure`; `already_in_couple` → `ValidationFailure`; `connection_error` → `NetworkFailure`
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` (NOVO) — `ProviderContainer` com `coupleRepositoryProvider` e `cameraPermissionServiceProvider` mockados; cobre: bootstrap com permissão `granted` → state `.ready`; bootstrap com `denied` → `.permissionDenied` com `canAskAgain: true`; bootstrap com `permanentlyDenied` → `.permissionDenied` com `canAskAgain: false`; lookup success transita a `.lookedUp` e carrega `lookup` + `code`; segundo `QrDetected` enquanto em `.lookup`/`.lookedUp` é ignorado (dedup); lookup failure transita a `.failure` com `message`; `ManualCodeSubmitted` segue o mesmo caminho; `RetryPressed` reseta para `.ready`
- [ ] `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` (NOVO) — `ProviderContainer` com `coupleRepositoryProvider` mockado; cobre estado inicial `.initial`/`''`; `AcceptPressed` com sucesso → `.success`; com falha → `.failure` carregando `message`; guarda de double-dispatch durante loading
- [ ] `test/mocks/mocks.dart` — verificar/adicionar `class MockCoupleRepository extends Mock implements ICoupleRepository {}` (deve existir desde `couple-dissolve`) e `class MockCameraPermissionService extends Mock implements ICameraPermissionService {}`

## Verificação

- [ ] `flutter pub get` — sem conflitos de versão; `mobile_scanner` e `permission_handler` resolvidos
- [ ] `dart run build_runner build --delete-conflicting-outputs` — gera `couple_scan_notifier.g.dart`, `couple_scan_confirm_notifier.g.dart`, providers atualizados em `services_provider.g.dart`
- [ ] `flutter analyze` — zero issues nos arquivos tocados; sem warnings sobre `late` mal usado nem switches não-exaustivos
- [ ] `flutter test` — todos os testes existentes continuam passando; novos testes (4 arquivos) passam
- [ ] Smoke "permissão grant primeira vez": app instalado, navegar Settings → Convidar parceiro → Scanear QR code → diálogo nativo de câmera aparece → permitir → câmera abre com overlay
- [ ] Smoke "permissão negada primeira vez": negar o diálogo nativo → tela `CoupleScanPermissionDeniedWidget` aparece com botão "Permitir câmera" → tocar → diálogo nativo aparece de novo
- [ ] Smoke "permissão negada permanente": negar com "Não perguntar de novo" → tela aparece com botão "Abrir configurações" → tocar → app de configurações abre
- [ ] Smoke "scan sucesso": com QR de convite válido gerado por outro user → apontar câmera → tela de scan trava → loading curto → navega pra `CoupleScanConfirmScreen` mostrando nome/email do par
- [ ] Smoke "aceitar com sucesso": na tela de confirm → tocar "Aceitar convite" → loading no botão (1-2s) → toast de sucesso `Pronto · Vocês estão conectados.` → app volta direto pra `HomeLocation` (não passa por settings nem invite)
- [ ] Smoke "scan código não existe": apontar pra QR com code aleatório → toast de erro → scanner volta a `.ready` (consegue scanear de novo sem sair da tela)
- [ ] Smoke "scan convite expirado": (depende do backend retornar `invite_expired`) → toast com mensagem do erro → scanner volta a `.ready`
- [ ] Smoke "scan próprio convite": gerar QR no device A, escanear no device A → toast com mensagem do backend → scanner volta a `.ready`
- [ ] Smoke "fallback manual code — sucesso": tocar "Digitar código manualmente" na tela de scan → bottom sheet abre → digitar code válido → "Confirmar" → mesmo fluxo do scan automático (navega pra confirm)
- [ ] Smoke "fallback manual code — código inválido": digitar code inválido → "Confirmar" → toast com erro → sheet permanece aberto? (DECIDIR durante implementação — recomendação: sheet fecha, toast aparece sobre a tela de scan, e scanner volta a `.ready`)
- [ ] Smoke "torch": câmera aberta → tocar FAB de flash → câmera fica iluminada → ícone vira `flash_off` → tocar de novo → desliga
- [ ] Smoke "back na tela de scan": pop a tela → `MobileScannerController` é descartado (verificar via Android Studio que não há leak de câmera)
- [ ] Smoke "back na tela de confirm": pop a confirm → volta pra scan com câmera ativa (controller foi mantido); apontar QR de novo continua funcionando
- [ ] Smoke pós-accept: home re-renderiza com despesas/orçamentos compartilhados (caches invalidados); Settings → card de casal vira `SettingsCoupleConnectedWidget` com o nome do par
- [ ] iOS device físico: testar todo o fluxo (Simulator não tem câmera)
- [ ] `flutter build appbundle --release` — AAB compila sem erro; conferir tamanho (esperado +~3MB pelo MLKit bundled vs antes da spec)
