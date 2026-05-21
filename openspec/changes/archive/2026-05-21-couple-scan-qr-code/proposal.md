# Proposal: couple-scan-qr-code

## Intenção

Implementar o lado de **escanear** do fluxo de união de casal. Hoje, `CoupleInviteScreen` (`lib/src/presentation/ui/couple/invite/screens/couple_invite_screen.dart:47`) já tem o botão "Scanear QR code", mas o callback `onScan: () {}` é no-op (`CoupleInviteLocation`). Esta spec fecha o ciclo:

1. Da `CoupleInviteScreen`, "Scanear QR code" navega para uma nova `CoupleScanScreen`.
2. `CoupleScanScreen` pede permissão de câmera, abre o scanner e detecta o `code` embutido no QR (o `qrData` gerado pelo par é a string crua do `code`).
3. Em sucesso, faz `GET /api/v1/couple/invites/{code}` para validar o convite e buscar dados do parceiro **sem aceitar**.
4. Navega para `CoupleScanConfirmScreen` que mostra um card com nome/email do parceiro e botão "Aceitar convite".
5. Confirmado, dispara `POST /api/v1/couple/invites/{code}/accept`. Em sucesso, invalida caches de couple/expenses/budgets/insights e navega pra `HomeLocation`.

Inclui fallback "Digitar código" via bottom sheet, tratamento explícito de permissão negada (com `openAppSettings()`) e deduplicação de leituras para evitar disparar o lookup N vezes.

## Motivação

1. **Fluxo de pareamento incompleto**: a sub-feature `invite/` (gerar QR + compartilhar) foi entregue por `2026-05-14-generate-couple-invite-qr-code`, e a proposta explicitamente diferiu o lado do scan: *"Scanear QR code — o callback `onScan` continua `() {}`. Vira spec dedicada"*. Sem o scan, a única forma do par convidado entrar é compartilhamento de texto (link → fluxo de deep link futuro). Esta spec entrega a porta principal documentada na UI.

2. **Backend pronto**: ambos os endpoints (`GET /couple/invites/{code}` e `POST /couple/invites/{code}/accept`) já existem no Django, retornando o mesmo payload `{ couple_id, partner: { id, email, name } }` em sucesso e o schema padrão `FailureResponse` em erro. Sem dependência server-side.

3. **Reuso de modelos**: o `partner` do payload tem os mesmos três campos do `UserModel/UserResponse` já existentes (`lib/src/domain/models/user_model.dart:5-22`, `lib/src/infrastructure/clients/http/responses/user_response.dart:1-17`). A spec evita criar `PartnerModel` redundante e reusa `UserModel` direto.

4. **Padrão de feature já estabelecido**: o módulo `lib/src/presentation/ui/couple/` já organiza sub-features (`invite/`, `dissolve/`) — adicionar `scan/` é a continuação natural sem reorganização.

## Camadas afetadas

### Infrastructure (responses + datasource)

- `lib/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart` (NOVO) — `InviteLookupResponse` com `couple_id: int` e `partner: UserResponse`. Reusa `UserResponse.fromJson` aninhado.
- `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — adicionar à interface `IRemoteCoupleDataSource`:
  - `Future<Either<FailureResponse, InviteLookupResponse>> lookupInvite({required String code})`
  - `Future<Either<FailureResponse, InviteLookupResponse>> acceptInvite({required String code})`
  - Path: `'${EndpointKey.coupleInvites.path}/$code'` (lookup, GET) e `'${EndpointKey.coupleInvites.path}/$code/accept'` (accept, POST sem body), seguindo padrão do `RemoteExpenseDataSource.findById/delete` que monta `'${EndpointKey.expenses.path}/$id'`.

### Domain

- `lib/src/domain/models/couple/invite_lookup_model.dart` (NOVO) — `InviteLookupModel` com `coupleId: int` e `partner: UserModel`. Equatable + `copyWith`. Sem novo `PartnerModel` — reusa `UserModel` direto (campos batem 1:1 com o payload).
- `lib/src/domain/repositories/interface_couple_repository.dart` — adicionar:
  - `Future<Either<Failure, InviteLookupModel>> lookupInvite({required String code})`
  - `Future<Either<Failure, InviteLookupModel>> acceptInvite({required String code})`

### Data

- `lib/src/data/extensions/invite_lookup_response_extension.dart` (NOVO) — `InviteLookupResponseExtension.toModel()` mapeando `InviteLookupResponse → InviteLookupModel` (e `UserResponse → UserModel` via construtor direto, já que campos batem; sem reusar uma extension genérica de UserResponse porque hoje nenhuma existe — caso apareça em outra spec, criar `user_response_extension.dart`. Por ora, mapeamento inline).
- `lib/src/data/repositories/couple_repository.dart` — implementar:
  - `lookupInvite({code})` → chama `_dataSource.lookupInvite(code: code)`, retorna `data.either((failure) => failure.toFailure(), (response) => response.toModel())`.
  - `acceptInvite({code})` → idem mas chama `_dataSource.acceptInvite`.

### Presentation — feature `couple/scan/`

Nova sub-feature autocontida em `lib/src/presentation/ui/couple/scan/`:

```
scan/
  data/
    couple_scan_state.dart                 ← view-model / state do scan
    couple_scan_confirm_state.dart         ← view-model / state do accept
  locations/
    couple_scan_location.dart              ← /couple/scan
    couple_scan_confirm_location.dart      ← /couple/scan/confirm (recebe InviteLookupModel)
  notifiers/
    couple_scan_intent.dart                ← QrDetected, TorchPressed, ManualCodeSubmitted, RetryPressed, PermissionRequested, OpenSettingsPressed
    couple_scan_notifier.dart              ← câmera + permissão + lookup
    couple_scan_confirm_intent.dart        ← AcceptPressed
    couple_scan_confirm_notifier.dart      ← accept + invalidate
  preview/
    screens/
      couple_scan_screen_preview.dart
      couple_scan_confirm_screen_preview.dart
    widgets/
      couple_scan_overlay_widget_preview.dart
      couple_scan_partner_preview_widget_preview.dart
      couple_scan_permission_denied_widget_preview.dart
    mocks/
      invite_lookup_mock.dart
  screens/
    couple_scan_screen.dart                ← MobileScanner + overlay + ações
    couple_scan_confirm_screen.dart        ← partner preview + accept
  widgets/
    couple_scan_overlay_widget.dart        ← cantos do scan area + texto guia
    couple_scan_torch_button_widget.dart   ← FAB torch on/off
    couple_scan_partner_preview_widget.dart← card com inicial, nome e email
    couple_scan_permission_denied_widget.dart ← tela explicando + "Permitir câmera" / "Abrir configurações"
    couple_scan_manual_code_sheet.dart     ← bottom sheet com TextField + "Confirmar"
```

### Presentation — wiring na `couple/invite/`

- `lib/src/presentation/ui/couple/invite/locations/couple_invite_location.dart` — trocar `onScan: () {}` (hoje no `couple_invite_screen.dart:47`) por `onScan: () => context.navigate(CoupleScanLocation())`. A injeção é feita na Location (Location compõe navegação — exceção narrada no CLAUDE.md), screen continua sem importar Location de outra sub-feature.

### Main — wiring + permissões + deps

- `pubspec.yaml` — adicionar:
  - `mobile_scanner: ^7.x` (consultar context7 / pub.dev no momento da implementação para a última versão estável)
  - `permission_handler: ^12.x` (idem)
- `lib/app_route.dart` — adicionar:
  - `coupleScan` → path `/couple/scan`, name `couple-scan-route`, regex `RegExp(r'^/couple/scan$')`.
  - `coupleScanConfirm` → path `/couple/scan/confirm`, name `couple-scan-confirm-route`, regex `RegExp(r'^/couple/scan/confirm$')`.
  - Adicionar ambos em `_all`.
- `android/app/src/main/AndroidManifest.xml` — adicionar `<uses-permission android:name="android.permission.CAMERA"/>` ao bloco do início (mesma seção dos `INTERNET` e `POST_NOTIFICATIONS` existentes).
- `android/app/build.gradle.kts` — adicionar dependência explícita `implementation("com.google.mlkit:barcode-scanning:17.x.x")` no `dependencies { }` do app pra forçar o modelo MLKit bundled (sem depender do Google Play Services dinamicamente).
- `ios/Runner/Info.plist` — adicionar key `NSCameraUsageDescription` com texto `"Usamos a câmera apenas para ler o QR code do convite do seu par."` (pt_BR, factual, escopo limitado conforme guidelines da App Store).

### Testes

- `test/src/infrastructure/responses/invite_lookup_response_test.dart` (NOVO) — `fromJson` (sucesso + erro de schema).
- `test/src/data/repositories/couple_repository_test.dart` — adicionar grupos:
  - `GET /couple/invites/{code}` (lookup) — sucesso + 4 failures.
  - `POST /couple/invites/{code}/accept` (accept) — sucesso + 4 failures + cobertura de códigos específicos da feature (`expired_invite`, `already_accepted`, `own_invite`, `already_in_couple`).
- `test/src/presentation/providers/couple_scan_notifier_test.dart` (NOVO) — mock `ICoupleRepository` + mock de permission status; cobre estados iniciais, transições de scan/lookup, deduplication, manual code, permission flow.
- `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` (NOVO) — mock `ICoupleRepository`; cobre accept success/failure e guard de loading.

Sem testes de datasource isolado (padrão do projeto). Sem widget tests.

## Erros tratados explicitamente

A spec exige cobrir os seguintes códigos no `FailureCodeResponse` (criar/estender o enum em `lib/src/infrastructure/clients/http/responses/failure/failure_code.dart` se algum não existir hoje):

| Cenário                          | Código da API esperado | `Failure`                              | UX                                                                |
| -------------------------------- | ---------------------- | -------------------------------------- | ----------------------------------------------------------------- |
| Permissão de câmera negada       | (cliente)              | (estado próprio do scan)               | Tela cheia com botão "Permitir câmera" / "Abrir configurações"    |
| Câmera indisponível no device    | (cliente)              | (estado próprio do scan)               | Mensagem + botão "Digitar código manualmente"                     |
| Code não existe                  | `invite_not_found`     | `NotFoundFailure`                      | Toast "Convite não encontrado" + scanner volta ao estado `.ready` |
| Convite expirado                 | `invite_expired`       | `ValidationFailure('Convite expirou')` | Toast + scanner volta ao estado `.ready`                          |
| Convite já aceito                | `invite_already_used`  | `ValidationFailure(msg da API)`        | Toast + scanner volta ao estado `.ready`                          |
| Tentativa de aceitar próprio QR  | `invite_own`           | `ValidationFailure(msg da API)`        | Toast + scanner volta ao estado `.ready`                          |
| Usuário já está em outro casal   | `already_in_couple`    | `ValidationFailure(msg da API)`        | Toast + scanner volta ao estado `.ready`                          |
| Erro de rede genérico            | `connection_error`     | `NetworkFailure`                       | Toast "Sem conexão com o servidor" + scanner volta a `.ready`     |
| Erro 5xx genérico                | `server_error`         | `ServerFailure`                        | Toast "Erro no servidor" + scanner volta a `.ready`               |

> Para os códigos novos (`invite_not_found`, `invite_expired`, `invite_already_used`, `invite_own`, `already_in_couple`): se já existirem no enum `FailureCodeResponse`, reusar. Senão, adicionar — verificar o backend ao implementar e ajustar os strings exatos.

## Fora do escopo

- **Deep link** `trocado://invite/<code>` no QR. O QR contém `code` cru por decisão de produto desta spec (confirmado em conversa). Caso futuro queira encodar deep link, vira spec separada com parser + intent filter no `AndroidManifest`.
- **Acesso ao scan fora do fluxo de convite** (ex: tile "Scanear convite" direto na home / settings). Hoje a única affordance é o botão da `CoupleInviteScreen`, e isso basta — adicionar entry points novos é decisão de produto pra outra rodada.
- **Reflow após accept** para mostrar a tela de casal conectado. Após sucesso, navegamos pra `HomeLocation`; o re-render do `SettingsCoupleStatusWidget` (que vira `SettingsCoupleConnectedWidget` quando há casal ativo) acontece organicamente via `ref.invalidate(coupleProvider)`. Sem tela "Pronto! Vocês estão conectados" intermediária — toast de sucesso + home é suficiente.
- **Som / haptics** ao detectar QR válido. Pode entrar em refino visual depois; spec atual foca no funcional.
- **Animação de leitura** (linha verde varrendo, etc). Spec define overlay estático com cantos do scan area. Animar fica pra spec separada se houver demanda.
- **Switch de câmera** (frontal/traseira). Apenas a traseira (que é o uso real). `MobileScannerController` tem `switchCamera()` se quisermos adicionar depois.
- **Galeria** (ler QR de uma imagem já salva). Casos de uso raros e exigem `image_picker`. Spec separada se aparecer.
- **Telemetria** (eventos de scan iniciado / sucesso / falha). Quando entrar telemetria global, esta feature adere — sem spec dedicada.
- **i18n**. Hardcoded `pt_BR` como o resto do app.
- **Re-leitura imediata após erro de lookup**. Quando o scan falha, mostramos toast e voltamos pro `.ready` — o user precisa apontar o QR de novo. Sem retry automático.

## Decisões de design

1. **Dois notifiers separados, não um notifier multi-fase.**
   `CoupleScanNotifier` cuida de câmera + permissão + lookup. `CoupleScanConfirmNotifier` cuida do accept. Justificativa: cada notifier tem ciclo de vida natural diferente — o de scan vive enquanto a câmera está aberta (descarta junto com a tela), o de confirm é instanciado quando entramos na confirmação (com o `code` já em mãos via param da Location) e descartado quando confirmamos. Separação evita state explodido com 6+ status.

2. **`InviteLookupModel` separado de `CoupleModel`, mesmo que payload se sobreponha.**
   Embora o backend retorne o mesmo payload tanto no lookup quanto no accept, a semântica é diferente: lookup é "preview do que vai acontecer", accept é "casal foi criado". `CoupleModel` tem `createdAt: int` que não vem nesse payload (vem do `GET /couple` que retorna `created_at: String`). Manter `InviteLookupModel` separado evita campos nullable / opcionais no `CoupleModel`. Após accept, invalidamos `coupleProvider` que faz refetch via `GET /couple` (que devolve o `CoupleModel` completo).

3. **Reusa `UserModel` para o partner (não cria `PartnerModel`).**
   Os 3 campos do `partner` no payload (`id`, `email`, `name`) batem 1:1 com `UserModel`. `CoupleResponse.fromJson` já faz `UserResponse.fromJson(json['partner'])` e `CoupleModel.partner` é `UserModel` (`couple_model.dart:8`). Manter consistência.

4. **MobileScannerController é mantido pelo notifier, com `ref.onDispose`.**
   Para evitar `StatefulWidget` (segue padrão `StatelessWidget + Consumer` interno), o `CoupleScanNotifier` instancia `MobileScannerController` em `build()` e registra `ref.onDispose(() => controller.dispose())`. Expõe `controller` via getter para a screen passar pro `MobileScanner` widget. `_controller.stop()` é chamado ao detectar QR (dedup) e `_controller.start()` no retry.

5. **Deduplication via state guard, não debounce.**
   `MobileScanner` dispara múltiplos eventos com o mesmo `code` enquanto o QR está visível. No `dispatch(QrDetected(code))`, se `state.status` não for `.ready`, ignoramos. Primeiro evento válido → muda pra `.lookup` + `_controller.stop()` + chama o repo. Sem `Timer.debounce` (não é precisão de tempo, é regra de estado).

6. **Permissão é checada em `build()` do `CoupleScanNotifier`.**
   `Future<CoupleScanState> build()` chama `Permission.camera.status` e popula o state inicial. Não usar `AsyncNotifier` aqui — o overlay/UI tem múltiplos estados simultâneos (permissão + scan), e expor `AsyncValue<CoupleScanState>` esconderia transições intermediárias. Usar `Future<CoupleScanState>` síncrono que retorna o `state` inicial com `status: .ready` / `.permissionDenied` / `.cameraUnavailable`.

7. **Manual code é bottom sheet, não tela.**
   Bottom sheet é mais leve, preserva o contexto do scanner (user pode fechar e voltar pra câmera), e segue padrão do projeto (`bottom_sheet_widget.dart` existe). Dispatcha `ManualCodeSubmitted(code)` no mesmo `CoupleScanNotifier` — código toma o mesmo caminho do scan automático (lookup → navega pra confirm).

8. **`CoupleScanConfirmLocation` recebe `InviteLookupModel` no construtor.**
   Padrão usado em outras locations com argumento (ex: futuras `ExpenseLocation(id:)`). Location passa o model pra screen via construtor. Notifier de confirm recebe o `code` via `dispatch(AcceptPressed(code))` — sem pegar do model (princípio: state explícito > estado escondido).

9. **Após accept com sucesso, navegar para `HomeLocation` via `context.root()`.**
   Reseta a pilha de navegação (scan → confirm → invite → settings → home vira apenas → home). User não deveria poder voltar pra tela de scan/confirm/invite após criar o casal — não faria sentido. `duck_router` expõe `context.root()` (`presentation/extensions/context_extension.dart`). Toast de sucesso vem **antes** do `root()`, mesmo padrão de `CoupleDissolveScreen._onSuccess`.

10. **Invalidações após accept = mesma lista do dissolve, mais `userProvider`.**
    - `coupleProvider`: source of truth do estado de casal — obrigatório.
    - `userProvider`: o `UserModel` agora carrega info de casal indireta (via subsequent requests); invalidar garante refetch consistente.
    - `recentExpensesProvider`, `activeBudgetProvider`, `insightsProvider`, `expensesProvider`, `budgetsProvider`: passam a refletir dados compartilhados com o parceiro. Sem invalidate, home/listagens mostram cache só-do-user até refresh.

11. **MLKit bundled, não Play Services.**
    Decisão de produto: scanner deve funcionar instantaneamente desde a primeira leitura, sem depender de modelo baixar on-demand. Adiciona ~3MB ao AAB mas garante UX consistente. Configurado via dependência gradle explícita.

12. **Camera permission denied tem dois estados.**
    - **Primeira negação** (status `.denied`): mostra widget de explicação + botão "Permitir câmera" → chama `Permission.camera.request()`.
    - **Permanente** (status `.permanentlyDenied` ou `.restricted`): mostra mesma widget mas com botão "Abrir configurações" → chama `openAppSettings()` do `permission_handler`. O `permission_handler` faz a distinção automaticamente; o notifier mapeia para um único estado `.permissionDenied(canAskAgain: bool)`.

13. **Sem validação local do conteúdo do QR.**
    Como decisão de produto o `code` é uma string opaca, o cliente não tenta validar formato (regex, comprimento). Envia direto pro backend — se for inválido, vem `invite_not_found` ou `validation_failure` e o erro é exibido no toast. Único validation client-side é "tem alguma coisa lida" (string não vazia).

14. **Wire-up `onScan` é responsabilidade da Location, não da screen.**
    `CoupleInviteScreen` continua recebendo `onScan: VoidCallback` no construtor; a `CoupleInviteLocation` injeta `() => context.navigate(CoupleScanLocation())`. Segue exceção narrada do CLAUDE.md: "Locations compondo navegação podem importar outras Locations".

15. **Previews mockam apenas widgets puros, nunca a screen com câmera.**
    `MobileScanner` exige permissão e câmera reais — não roda no Widget Previewer. Os previews cobrem: `CoupleScanOverlayWidget` (overlay sobre placeholder), `CoupleScanPartnerPreviewWidget` (card de partner), `CoupleScanPermissionDeniedWidget` (estado de permissão), `CoupleScanConfirmScreen` (estados loading/success/failure com mock). A `CoupleScanScreen` em si não tem preview porque depende da câmera.
