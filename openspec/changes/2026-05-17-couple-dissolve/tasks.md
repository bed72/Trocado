# Tasks: couple-dissolve

## infrastructure/

- [x] `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — adicionar `dissolve()` na `IRemoteCoupleDataSource` e implementar em `RemoteCoupleDataSource` chamando `_client.delete(parameter: Requests(EndpointKey.couple.path))` e retornando `response.either(FailureResponse.fromJson, (_) {})` (mesmo padrão de `RemoteUserDataSource.delete`)

## domain/

- [x] `lib/src/domain/repositories/interface_couple_repository.dart` — adicionar `Future<Either<Failure, void>> dissolve()` à interface

## data/

- [x] `lib/src/data/repositories/couple_repository.dart` — implementar `dissolve()` chamando `_dataSource.dissolve()` e retornando `data.either((failure) => failure.toFailure(), (_) {})`

## presentation/ui/couple/invite/ (migração de partner/)

- [x] Criar diretório `lib/src/presentation/ui/couple/invite/` com subpastas `data/`, `locations/`, `notifiers/`, `screens/`, `widgets/`, `widgets/painters/`
- [x] Mover + renomear `partner/locations/partner_invite_location.dart` → `couple/invite/locations/couple_invite_location.dart`; renomear classe `PartnerInviteLocation` → `CoupleInviteLocation`; atualizar `path` para `AppRoutes.coupleInvite.path`
- [x] Mover + renomear `partner/screens/partner_invite_screen.dart` → `couple/invite/screens/couple_invite_screen.dart`; renomear classe `PartnerInviteScreen` → `CoupleInviteScreen`
- [x] Mover + renomear `partner/widgets/partner_invite_hero_widget.dart` → `couple/invite/widgets/couple_invite_hero_widget.dart`; classe `PartnerInviteHeroWidget` → `CoupleInviteHeroWidget`
- [x] Mover + renomear `partner/widgets/partner_invite_actions_widget.dart` → `couple/invite/widgets/couple_invite_actions_widget.dart`; classe `PartnerInviteActionsWidget` → `CoupleInviteActionsWidget`
- [x] Mover + renomear `partner/widgets/partner_invite_security_note_widget.dart` → `couple/invite/widgets/couple_invite_security_note_widget.dart`; classe `PartnerInviteSecurityNoteWidget` → `CoupleInviteSecurityNoteWidget`
- [x] Mover + renomear `partner/widgets/partner_pair_indicator_widget.dart` → `couple/invite/widgets/couple_pair_indicator_widget.dart`; classe `PartnerPairIndicatorWidget` → `CouplePairIndicatorWidget`
- [x] Mover (sem rename) `partner/locations/invite_qr_code_location.dart` → `couple/invite/locations/invite_qr_code_location.dart`
- [x] Mover (sem rename) `partner/screens/invite_qr_code_screen.dart` → `couple/invite/screens/invite_qr_code_screen.dart`
- [x] Mover (sem rename) `partner/notifiers/invite_qr_code_notifier.dart` → `couple/invite/notifiers/invite_qr_code_notifier.dart`
- [x] Mover (sem rename) `partner/data/invite_qr_code_presentation_data.dart` → `couple/invite/data/invite_qr_code_presentation_data.dart`
- [x] Mover (sem rename) `partner/widgets/invite_qr_card_widget.dart` → `couple/invite/widgets/invite_qr_card_widget.dart`
- [x] Mover (sem rename) `partner/widgets/invite_qr_code_failure_widget.dart` → `couple/invite/widgets/invite_qr_code_failure_widget.dart`
- [x] Mover (sem rename) `partner/widgets/invite_qr_code_loading_widget.dart` → `couple/invite/widgets/invite_qr_code_loading_widget.dart`
- [x] Mover (sem rename) `partner/widgets/painters/dashed_line_painter.dart` → `couple/invite/widgets/painters/dashed_line_painter.dart`
- [x] Mover (sem rename) `partner/widgets/painters/dashed_rounded_rect_painter.dart` → `couple/invite/widgets/painters/dashed_rounded_rect_painter.dart`
- [x] Atualizar imports relativos entre arquivos do módulo movido (qualquer `package:trocado/src/presentation/ui/partner/...` vira `package:trocado/src/presentation/ui/couple/invite/...` com filename atualizado)
- [x] Deletar a pasta `lib/src/presentation/ui/partner/` (incluindo `.g.dart` antigo do `invite_qr_code_notifier`) — sem backwards-compat / re-exports

## presentation/ui/couple/dissolve/ (novo)

- [x] Criar diretório `lib/src/presentation/ui/couple/dissolve/` com subpastas `locations/`, `notifiers/`, `screens/`
- [x] `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart` (NOVO) — `enum CoupleDissolveStatus { initial, loading, success, failure }` + `final class CoupleDissolveState extends Equatable` com `status` e `message`, default `.initial` e `''`; `copyWith(status, message)`
- [x] `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart` (NOVO) — `sealed class CoupleDissolveIntent` + `final class DissolvePressed extends CoupleDissolveIntent` com construtor const
- [x] `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart` (NOVO) — `@riverpod` (sem `keepAlive`), injeta `coupleRepositoryProvider` via `ref.watch` em `build()` síncrono retornando `const CoupleDissolveState()`; `dispatch` switch expression em `CoupleDissolveIntent`; `_dissolve()` guarda loading, chama `_repository.dissolve()`, no `fold` falha → `state.copyWith(status: .failure, message: failure.message)` e sucesso → invalida `coupleProvider`, `expensesProvider`, `insightsProvider`, `budgetsProvider`, `activeBudgetProvider`, `recentExpensesProvider` e `state.copyWith(status: .success)`
- [x] `lib/src/presentation/ui/couple/dissolve/screens/couple_dissolve_screen.dart` (NOVO) — `StatelessWidget` + `Consumer` interno; `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))` + `Padding all(16.0)` + `Column(spacing: 24.0, crossAxisAlignment: .start)` com `ScreenHeaderWidget('Desfazer casal', ...)`, 3 efeitos via método privado `_effect(icon, label)`, `Spacer` e `SizedBox(width: .infinity, child: ButtonWidget.danger(...))`; `ref.listen` em `coupleDissolveProvider` com switch expression: `.success` → `_onSuccess` (toast + pop), `.failure` → `_onFailure` (toast), demais → null; `_submit` chama `showConfirmDialog` (title 'Desfazer casal', confirmLabel 'Desfazer', description listada na proposta) e dispatch `DissolvePressed()` se confirmado
- [x] `lib/src/presentation/ui/couple/dissolve/locations/couple_dissolve_location.dart` (NOVO) — `final class CoupleDissolveLocation extends Location` com `path: AppRoutes.coupleDissolve.path` e `pageBuilder` retornando `screenPage(const CoupleDissolveScreen())`

## main/

- [x] `lib/app_route.dart` — remover `partnerInvite` e `partnerInviteQrCode`; adicionar `coupleInvite` (`/couple/invite`), `coupleInviteQrCode` (`/couple/invite/qr-code`), `coupleDissolve` (`/couple/dissolve`); atualizar a lista `_all`
- [x] `lib/src/presentation/ui/settings/locations/settings_location.dart` — trocar import `partner_invite_location` por `couple_invite_location` + adicionar import `couple_dissolve_location`; substituir `PartnerInviteLocation()` por `CoupleInviteLocation()`; trocar `onCoupleDetails: () {}` por `onCoupleDetails: () => context.navigate(CoupleDissolveLocation())`

## test/

- [x] `test/mocks/mocks.dart` — verificar/adicionar `class MockCoupleRepository extends Mock implements ICoupleRepository {}` (se ainda não existe)
- [x] `test/src/data/repositories/couple_repository_test.dart` — adicionar grupo `DELETE` com 5 testes: 204 → Right; `connection_error` → `NetworkFailure`; `server_error` → `ServerFailure`; `not_in_couple` → `NotFoundFailure`; código desconhecido com mensagem → `ValidationFailure(message)`
- [x] `test/src/presentation/providers/couple_dissolve_notifier_test.dart` (NOVO) — `ProviderContainer` overriding `coupleRepositoryProvider`; cobre estado inicial, transição para `.success`, transição para `.failure` com `message`, e guarda de double-dispatch durante loading

## Verificação

- [x] `dart run build_runner build --delete-conflicting-outputs` — regenera `couple_dissolve_notifier.g.dart` (novo) e `invite_qr_code_notifier.g.dart` (path mudou); deletar o `.g.dart` antigo de `partner/notifiers/` antes
- [x] `flutter analyze` — zero issues nos arquivos tocados; sem imports órfãos apontando para `partner/`
- [x] `flutter test` — todos os testes existentes continuam passando; novos testes do dissolve passam
- [ ] Smoke "tem casal": app com casal ativo → Settings → tocar no card connected → tela de dissolver abre com header, 3 efeitos e botão `Desfazer casal`
- [ ] Smoke "cancelar dialog": na dissolve, tocar `Desfazer casal` → dialog destrutivo abre → tocar `Cancelar` → volta sem chamada à API; state permanece `.initial`
- [ ] Smoke "sucesso": na dissolve, tocar `Desfazer casal` → confirmar dialog → loading no botão (1-2s) → toast de sucesso (`Pronto · Vocês não estão mais conectados.`) → pop pra Settings → card vira `SettingsInvitePartnerWidget` (`Convidar parceiro`)
- [ ] Smoke "falha de rede": dissolve com rede off → confirmar dialog → toast `Opps · Sem conexão com o servidor.`; permanece na tela; state `.failure`; botão volta a ficar tocável
- [ ] Smoke "sem casal pós-dissolve": após sucesso, abrir Home → não há mais despesas/orçamentos/insights compartilhados (caches invalidados)
- [ ] Smoke invite: app sem casal → Settings → tocar `Convidar parceiro` → tela `CoupleInviteScreen` abre (mesmo conteúdo do antigo partner_invite, só renomeada); fluxo de gerar QR code continua funcional
- [x] Sem nenhum import do projeto apontando para `lib/src/presentation/ui/partner/...`
- [x] `app_route.dart`: nenhuma referência a `partner` (campos, paths, regex, lista `_all`)
- [x] `settings_location.dart`: `onCoupleDetails` navega para `CoupleDissolveLocation`, `onInvitePartner` navega para `CoupleInviteLocation`
