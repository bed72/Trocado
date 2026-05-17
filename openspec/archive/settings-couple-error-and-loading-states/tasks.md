# Tasks: settings-couple-error-and-loading-states

## presentation/data/

- [x] `lib/src/presentation/ui/settings/data/couple_card_state.dart` (NOVO) — sealed class `CoupleCardState` com `CoupleConnectedState(CoupleCardPresentationData data)`, `CoupleNoneState()`, `CoupleFailureState(String message)`; todos Equatable

## presentation/notifiers/

- [x] `lib/src/presentation/ui/settings/notifiers/couple_notifier.dart` — refatorar `build()`:
  - Trocar retorno `Future<CoupleCardPresentationData?>` → `Future<CoupleCardState>`
  - No `fold`, ramificação Right encapsula em `CoupleConnectedState(_toPresentationData(user, couple))`
  - Ramificação Left chama `_toFailureState(failure)` com switch exhaustivo: `NotFoundFailure()` → `CoupleNoneState()`; `_` → `CoupleFailureState(failure.message)`
  - Manter `_toPresentationData` e `_initial` como estão

## presentation/widgets/

- [x] `lib/src/presentation/widgets/cards/inline_failure_card_widget.dart` (NOVO, compartilhado) — substitui o `SettingsCoupleFailureWidget` previsto na proposta original. Card inline (Row) com `BackgroundIconWidget(error_outline, 20px)`, `Text labelMedium` (maxLines 1, ellipsis) e `ButtonWidget.text` "Tentar novamente"; props: `message: String`, `onRetry: VoidCallback`. Reutilizado também no `InsightsCarouselWidget` (substitui `InsightsCarouselFailureWidget`, deletado). Ver seção "Desvios" abaixo.
- [x] `lib/src/presentation/ui/settings/widgets/settings_couple_loading_widget.dart` (NOVO) — `Skeletonizer` envolvendo `SettingsCoupleConnectedWidget` com `_placeholder` const (title/subtitle/initials fake); segue padrão `BudgetCardLoadingWidget`; `onTap: () {}` no-op
- [x] `lib/src/presentation/ui/settings/widgets/settings_couple_status_widget.dart` — switch exhaustivo da sealed class:
  ```
  AsyncData(value: CoupleConnectedState(:data)) → SettingsCoupleConnectedWidget(data, onCoupleDetails)
  AsyncData(value: CoupleNoneState())           → SettingsInvitePartnerWidget(onInvitePartner)
  AsyncData(value: CoupleFailureState(:message))→ InlineFailureCardWidget(message, onRetry: ref.invalidate(coupleProvider))
  _                                             → SettingsCoupleLoadingWidget()
  ```

## presentation/preview/ (extra)

- [x] `lib/src/presentation/ui/settings/preview/widgets/settings_couple_status_widget_preview.dart` (NOVO) — `@TrocadoPreview` cobrindo os 5 cenários: Loading, Sem parceiro (convite), Conectado, Conectado (nomes longos) e Falha. Renderiza os widgets-filhos diretamente (o status widget lê provider e não pode ser previewed direto).

## test/

- [x] `test/src/presentation/providers/couple_notifier_test.dart` — atualizar:
  - Asserts dos testes existentes para usar `isA<CoupleConnectedState>()` + extrair `data` antes de checar `title`/`subtitle`/`initials`
  - Renomear `'returns null when repository returns NotFoundFailure'` → `'returns CoupleNoneState when repository returns NotFoundFailure'`; assert `isA<CoupleNoneState>()`
  - Renomear `'returns null when repository returns NetworkFailure'` → `'returns CoupleFailureState with message on NetworkFailure'`; assert `isA<CoupleFailureState>()` + `(state as CoupleFailureState).message == 'Sem conexão com o servidor.'`
  - Idem para `ServerFailure` (message: 'Falha interna do servidor.')
  - Adicionar test pra `ValidationFailure('mensagem custom')` retornar `CoupleFailureState('mensagem custom')`
  - Adicionar test pra `UnknownFailure()` retornar `CoupleFailureState('Falha desconhecido.')`
  - Manter `'handles partner name with diacritics'`

## Verificação

- [x] `dart run build_runner build --delete-conflicting-outputs` — regenera `couple_notifier.g.dart` com novo retorno
- [x] `flutter analyze` — zero issues nos arquivos tocados
- [x] `flutter test` — todos os testes passam, incluindo os atualizados (639/639)
- [ ] Smoke positivo: app autenticado **com casal ativo** → Settings → card connected aparece (sem flicker)
- [ ] Smoke "sem casal": app autenticado **sem casal** → Settings → card invite aparece
- [ ] Smoke offline: matar rede → puxar Settings → card de falha aparece com mensagem "Sem conexão com o servidor." e botão "Tentar novamente" → restaurar rede + tocar botão → card connected aparece
- [ ] Smoke loading: cold-launch da Settings → skeleton com shimmer (Skeletonizer mascarando o connected widget) aparece por <1s antes do card real
- [x] `SettingsCoupleStatusWidget` continua sem imports de `data/` nem `infrastructure/`
- [x] `couple_card_state.dart` em `presentation/ui/settings/data/` (não em `notifiers/`)

## Desvios

- **Card de falha compartilhado**: a proposta original previa `SettingsCoupleFailureWidget` próprio (Column vertical, ícone 48px, `OutlinedButton`). Durante a implementação, o usuário pediu para alinhar o visual ao card de falha do `InsightsCarouselFailureWidget` (Row compacto, ícone 20px com fundo, `ButtonWidget.text` inline) e extrair como widget compartilhado. Resultado: `InlineFailureCardWidget` em `lib/src/presentation/widgets/cards/`, consumido tanto pelo couple status quanto pelo insights carousel. Os dois wrappers específicos por feature (`SettingsCoupleFailureWidget` e `InsightsCarouselFailureWidget`) foram deletados — `Padding(horizontal: 16)` que antes vivia no wrapper do insights ficou inline no consumer.
