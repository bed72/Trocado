# Tasks: settings-couple-error-and-loading-states

## presentation/data/

- [ ] `lib/src/presentation/ui/settings/data/couple_card_state.dart` (NOVO) — sealed class `CoupleCardState` com `CoupleConnectedState(CoupleCardPresentationData data)`, `CoupleNoneState()`, `CoupleFailureState(String message)`; todos Equatable

## presentation/notifiers/

- [ ] `lib/src/presentation/ui/settings/notifiers/couple_notifier.dart` — refatorar `build()`:
  - Trocar retorno `Future<CoupleCardPresentationData?>` → `Future<CoupleCardState>`
  - No `fold`, ramificação Right encapsula em `CoupleConnectedState(_toPresentationData(user, couple))`
  - Ramificação Left chama `_toFailureState(failure)` com switch exhaustivo: `NotFoundFailure()` → `CoupleNoneState()`; `_` → `CoupleFailureState(failure.message)`
  - Manter `_toPresentationData` e `_initial` como estão

## presentation/widgets/

- [ ] `lib/src/presentation/ui/settings/widgets/settings_couple_failure_widget.dart` (NOVO) — Card com ícone `error_outline` 48px (color: `colors.error`), Text `bodyMedium` centralizado, `OutlinedButton` "Tentar novamente"; props: `message: String`, `onRetry: VoidCallback`; padding 16, spacing 8, radius `cornerRadius100`
- [ ] `lib/src/presentation/ui/settings/widgets/settings_couple_skeleton_widget.dart` (NOVO) — Card cinza estático (sem shimmer); Row com bloco placeholder do avatar pair (64x40 rounded) + Column com 2 retângulos placeholder (140x14, 100x12); cor `surfaceContainerHighest`; mesma estrutura/padding do `SettingsCoupleConnectedWidget` (12/12)
- [ ] `lib/src/presentation/ui/settings/widgets/settings_couple_status_widget.dart` — substituir switch atual por switch exhaustivo da sealed class:
  ```
  AsyncData(value: CoupleConnectedState(:data)) → SettingsCoupleConnectedWidget(data, onCoupleDetails)
  AsyncData(value: CoupleNoneState())           → SettingsInvitePartnerWidget(onInvitePartner)
  AsyncData(value: CoupleFailureState(:message))→ SettingsCoupleFailureWidget(message, onRetry: ref.invalidate(coupleProvider))
  _                                             → SettingsCoupleSkeletonWidget()
  ```

## test/

- [ ] `test/src/presentation/providers/couple_notifier_test.dart` — atualizar:
  - Asserts dos testes existentes para usar `isA<CoupleConnectedState>()` + extrair `data` antes de checar `title`/`subtitle`/`initials`
  - Renomear `'returns null when repository returns NotFoundFailure'` → `'returns CoupleNoneState when repository returns NotFoundFailure'`; assert `isA<CoupleNoneState>()`
  - Renomear `'returns null when repository returns NetworkFailure'` → `'returns CoupleFailureState with message on NetworkFailure'`; assert `isA<CoupleFailureState>()` + `(state as CoupleFailureState).message == 'Sem conexão com o servidor.'`
  - Idem para `ServerFailure` (message: 'Falha interna do servidor.')
  - Adicionar test pra `ValidationFailure('mensagem custom')` retornar `CoupleFailureState('mensagem custom')`
  - Adicionar test pra `UnknownFailure()` retornar `CoupleFailureState('Falha desconhecido.')`
  - Manter `'handles partner name with diacritics'`

## Verificação

- [ ] `dart run build_runner build --delete-conflicting-outputs` — regenera `couple_notifier.g.dart` com novo retorno
- [ ] `flutter analyze` — zero issues nos arquivos tocados
- [ ] `flutter test` — todos os testes passam, incluindo os atualizados
- [ ] Smoke positivo: app autenticado **com casal ativo** → Settings → card connected aparece (sem flicker)
- [ ] Smoke "sem casal": app autenticado **sem casal** → Settings → card invite aparece
- [ ] Smoke offline: matar rede → puxar Settings → card de falha aparece com mensagem "Sem conexão com o servidor." e botão "Tentar novamente" → restaurar rede + tocar botão → card connected aparece
- [ ] Smoke loading: cold-launch da Settings → skeleton cinza aparece por <1s antes do card real
- [ ] `SettingsCoupleStatusWidget` continua sem imports de `data/` nem `infrastructure/`
- [ ] `couple_card_state.dart` em `presentation/ui/settings/data/` (não em `notifiers/`)
