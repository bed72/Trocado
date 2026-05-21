# Tasks: couple-invite-scan-flow-fix

## infrastructure/

- [ ] `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar entrada `invites('/api/v1/invites')` ao enum (mantendo `coupleInvites` que continua usado pelo `createInvite`)
- [ ] `lib/src/infrastructure/clients/http/responses/couple/invite_accept_response.dart` (NOVO) — `final class InviteAcceptResponse` com `coupleId: int`, `partner: UserResponse`; `fromJson` igual ao do antigo `InviteLookupResponse` (`couple_id`, `partner`)
- [ ] `lib/src/infrastructure/clients/http/responses/couple/invite_lookup_response.dart` — **DELETAR**
- [ ] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — remover `lookupInvite` da `IRemoteCoupleDataSource` e da implementação `RemoteCoupleDataSource`
- [ ] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — `acceptInvite` muda assinatura para retornar `Future<Either<FailureResponse, InviteAcceptResponse>>` e monta path `'${EndpointKey.invites.path}/$code/accept'` (não mais `coupleInvites`); deserialização `response.either(FailureResponse.fromJson, InviteAcceptResponse.fromJson)`

## domain/

- [ ] `lib/src/domain/models/couple/invite_accept_model.dart` (NOVO) — `final class InviteAcceptModel extends Equatable` com `coupleId: int`, `partner: UserModel`; `copyWith(coupleId, partner)`; props `[coupleId, partner]`
- [ ] `lib/src/domain/models/couple/invite_lookup_model.dart` — **DELETAR**
- [ ] `lib/src/domain/repositories/interface_couple_repository.dart` — remover `lookupInvite`; `acceptInvite` passa a retornar `Future<Either<Failure, InviteAcceptModel>>`; trocar import de `InviteLookupModel` para `InviteAcceptModel`

## data/

- [ ] `lib/src/data/extensions/invite_accept_response_extension.dart` (NOVO) — `extension InviteAcceptResponseExtension on InviteAcceptResponse` com `toModel()` mapeando `coupleId` direto e `partner` para `UserModel(id, name, email)` inline
- [ ] `lib/src/data/extensions/invite_lookup_response_extension.dart` — **DELETAR**
- [ ] `lib/src/data/repositories/couple_repository.dart` — remover método `lookupInvite`
- [ ] `lib/src/data/repositories/couple_repository.dart` — `acceptInvite` passa a retornar `Future<Either<Failure, InviteAcceptModel>>` (corpo igual com `data.either((failure) => failure.toFailure(), (response) => response.toModel())`); atualizar imports (`InviteLookupModel` → `InviteAcceptModel`, response e extension)

## presentation/ui/couple/scan/

### State + Notifiers

- [ ] `lib/src/presentation/ui/couple/scan/data/couple_scan_state.dart` — remover status `.lookup` e `.lookedUp` do enum; adicionar status `.detected`; remover campo `lookup: InviteLookupModel?` do state e do `copyWith`; remover do `props`; remover import de `InviteLookupModel`
- [ ] `lib/src/presentation/ui/couple/scan/data/couple_scan_confirm_state.dart` — adicionar campo `partnerName: String` com default `''`; incluir no `copyWith` e nos `props`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` — remover `late ICoupleRepository _repository`; remover `ref.watch(coupleRepositoryProvider)` do `build()`; remover import de `ICoupleRepository` e do `repositories_provider`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` — renomear método `_lookup` → `_detect`; corpo passa a apenas validar guard de status, chamar `_parseCode`, e setar `state = AsyncData(current.copyWith(code: parsed, status: .detected))` (sem chamada async)
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` — atualizar dispatch: `QrDetected(:final code) => _detect(code)`; `_onManualCodeSubmitted` chama `_detect(validated.code!)` no caminho válido
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_notifier.dart` — manter `_parseCode` e `_retry`; `_retry` continua devolvendo `AsyncData(CoupleScanState(status: .ready))`
- [ ] `lib/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart` — no `_accept`, no branch `Right`, capturar `model.partner.name` e setar `state = state.copyWith(status: .success, partnerName: model.partner.name)`

### Screens + Locations

- [ ] `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` — remover prop `lookup: InviteLookupModel` e do construtor; `pageBuilder` passa só `code: code`; remover import de `InviteLookupModel`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — `_onStatusChanged` reage a `.detected` (em vez de `.lookup`/`.lookedUp`): chama `_safeStop()` e navega via `_navigateToConfirm(state.code)`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — `_navigateToConfirm` muda assinatura para `(String code)` e instancia `CoupleScanConfirmLocation(code: code)`; remover import de `InviteLookupModel`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — renomear variável `isLooking` → `isCapturing`; lógica `state.status == .detected` no botão "Digitar código manualmente"
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — remover prop `lookup: InviteLookupModel` do construtor (mantém só `code: String`)
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — substituir `CoupleScanPartnerPreviewWidget(partner: lookup.partner)` por `Center(child: Text(code, style: context.typography.headlineMedium?.copyWith(fontWeight: .w600, letterSpacing: 4.0)))`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — atualizar `description` do `ScreenHeaderWidget` para `'Confira o código do convite antes de aceitar.'`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — `_onSuccess` muda assinatura para `(BuildContext context, String partnerName)`; toast `description: 'Você está conectado com $partnerName.'`; ainda chama `context.root()` no fim
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — no `ref.listen`, ler `next.partnerName` ao invocar `_onSuccess`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — remover imports de `InviteLookupModel` e `CoupleScanPartnerPreviewWidget`

### Limpeza

- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart` — **DELETAR**
- [ ] `lib/src/presentation/ui/couple/scan/preview/widgets/couple_scan_partner_preview_widget_preview.dart` — **DELETAR**
- [ ] `lib/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart` → renomear para `invite_accept_mock.dart`; função `inviteAcceptMock({coupleId, partnerId, partnerName, partnerEmail})` retornando `InviteAcceptModel`

## test/

- [ ] `test/src/infrastructure/responses/invite_lookup_response_test.dart` → renomear para `invite_accept_response_test.dart`; substituir `InviteLookupResponse` → `InviteAcceptResponse` nos imports e nas asserções; cenários permanecem (sucesso + erro de schema, se existir)
- [ ] `test/src/data/repositories/couple_repository_test.dart` — **deletar** `group('lookupInvite', ...)` completo (linhas ~273-343)
- [ ] `test/src/data/repositories/couple_repository_test.dart` — no `group('acceptInvite', ...)`, trocar `InviteLookupResponse` → `InviteAcceptResponse` nos stubs e asserções; atualizar imports
- [ ] `test/src/data/extensions/invite_lookup_response_extension_test.dart` (se existir) → renomear para `invite_accept_response_extension_test.dart`; trocar classes alvo
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` — remover `late ICoupleRepository coupleRepository`, `coupleRepository = MockCoupleRepository()` e o `coupleRepositoryProvider.overrideWithValue(...)` do `makeContainer`
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` — remover todos `when(() => coupleRepository.lookupInvite(...))` e `verify(...lookupInvite...)`
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` — reescrever no `group('QrDetected', ...)`:
  - "transitions to lookedUp on successful lookup" → "transitions to detected and stores code" (sem stub; `state.code == 'ABC'` e `state.status == .detected`)
  - "ignores second QrDetected while in lookup status" → "ignores second QrDetected while in detected status" (sem stub; `state.code` não muda no segundo dispatch)
  - **deletar** "transitions to failure on Left and exposes message"
  - manter "ignores empty code", "extracts code from trocado://invite/<code> deep link", "ignores deep link with empty code segment"
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` — no `group('ManualCodeSubmitted', ...)`:
  - "runs lookup when code is valid" → "transitions to detected with code when manual code is valid" (sem stub; assertions de state)
  - "sets manualCodeFailure when code is invalid" — sem alteração
- [ ] `test/src/presentation/providers/couple_scan_notifier_test.dart` — no `group('RetryPressed', ...)`: ajustar setup para começar em `.detected` (manualmente via QrDetected) e validar volta a `.ready`; remover stub de `lookupInvite`
- [ ] `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` — trocar `InviteLookupResponse`/`InviteLookupModel` → `InviteAcceptResponse`/`InviteAcceptModel` nos stubs
- [ ] `test/src/presentation/providers/couple_scan_confirm_notifier_test.dart` — no teste de sucesso, adicionar `expect(state.partnerName, 'Marina');`

## Verificação

- [ ] `dart run build_runner build --delete-conflicting-outputs` — regenera `couple_scan_notifier.g.dart`, `couple_scan_confirm_notifier.g.dart` sem erros
- [ ] `flutter analyze` — zero issues nos arquivos tocados (atenção: ainda referências orfãs a `InviteLookupModel`/`InviteLookupResponse` viram erro de import — corrigir até passar)
- [ ] `flutter test` — todos os testes (existentes + ajustados) passam
- [ ] Smoke "scan sucesso": gerar convite no device A → device B abre Settings → Convidar parceiro → Scanear QR code → aponta câmera no QR do A → screen navega imediatamente pra Confirmar união mostrando o code grande no centro
- [ ] Smoke "accept sucesso": na Confirmar união → tocar "Aceitar convite" → loading curto → toast verde `Pronto · Você está conectado com {nome}.` → app volta direto pra Home
- [ ] Smoke "fallback manual": tocar "Digitar código manualmente" → digitar code do A → "Confirmar" → mesmo fluxo (confirm screen → accept → toast)
- [ ] Smoke "accept inválido": digitar code aleatório → confirm screen abre → "Aceitar convite" → toast vermelho `Opps · {mensagem do backend}` → permanece no confirm (não navega)
- [ ] Smoke "convite próprio": tentar aceitar o code que o próprio device gerou → backend retorna `invite_own` → toast com mensagem
- [ ] Confirmar via DevTools / proxy / log do app que o request final é `POST {BASE_URL}/api/v1/invites/{code}/accept` (sem `/couple` no meio) e sem o prefixo `trocado://invite/` no `{code}`
