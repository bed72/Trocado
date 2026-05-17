# Proposal: settings-couple-error-and-loading-states

## Intenção

Diferenciar três estados no banner de casal da `SettingsScreen` que hoje colapsam em um só (card de convite):

- **Conectado** → `SettingsCoupleConnectedWidget` (mantém).
- **Sem casal** (`NotFoundFailure` vindo do code `not_in_couple` ou `not_found`) → `SettingsInvitePartnerWidget` (mantém).
- **Falha** (`NetworkFailure`, `ServerFailure`, `ValidationFailure`, `UnknownFailure`) → novo `SettingsCoupleFailureWidget` com mensagem amigável e botão "Tentar novamente".
- **Loading** → novo `SettingsCoupleLoadingWidget` (Skeletonizer envolvendo o `SettingsCoupleConnectedWidget` com placeholder) em vez de cair no card de convite enquanto o GET ainda está em voo.

## Motivação

A spec anterior ([[2026-05-15-settings-couple-card]]) explicitamente colocou "empty state distinto pra falha de rede" e "skeleton enquanto carrega" como **fora de escopo**, com a justificativa de que o card de convite era um fallback aceitável. Em uso, as duas decisões se mostraram problemáticas:

1. **Falso negativo confunde o user em casal**: se o GET `/api/v1/couple` falhar (rede offline, 500 do backend), um user **já conectado** vê "Convidar parceiro · Comecem a usar juntos". A CTA é inválida (backend rejeita o POST do invite com 400 "já está em casal") e o user não tem affordance de que algo deu errado — apenas a percepção de que o app "esqueceu" o casal.

2. **Sem feedback de falha**: nenhum toast, nenhum snackbar, nenhum estado de retry. O user precisa adivinhar que algo falhou e sair/voltar pra tentar de novo.

3. **Flicker durante loading**: enquanto `AsyncLoading`, mostra o card de convite, que é trocado pelo card connected ~1 frame depois — visualmente parece um glitch pra quem já está em casal.

A correção é uma evolução natural: separar os três estados de negócio (conectado / sem casal / erro) do estado de infra (loading) e renderizar widgets distintos pra cada um.

## Camadas afetadas

- `presentation/ui/settings/data/couple_card_state.dart` (NOVO) — `sealed class CoupleCardState` com `CoupleConnectedState(data)`, `CoupleNoneState()`, `CoupleFailureState(message)`.
- `presentation/ui/settings/notifiers/couple_notifier.dart` — refatorar `build()` pra retornar `Future<CoupleCardState>` em vez de `Future<CoupleCardPresentationData?>`; no `fold`, mapear `NotFoundFailure` → `CoupleNoneState`, demais failures → `CoupleFailureState(failure.message)`.
- `presentation/ui/settings/widgets/settings_couple_status_widget.dart` — switch passa a cobrir 4 cenários: `AsyncData(CoupleConnectedState)`, `AsyncData(CoupleNoneState)`, `AsyncData(CoupleFailureState)`, `_` (loading/error do AsyncValue).
- `presentation/ui/settings/widgets/settings_couple_failure_widget.dart` (NOVO) — Card com ícone `error_outline`, mensagem amigável, botão `OutlinedButton` "Tentar novamente"; recebe `onRetry: VoidCallback`.
- `presentation/ui/settings/widgets/settings_couple_loading_widget.dart` (NOVO) — `Skeletonizer` envolvendo `SettingsCoupleConnectedWidget` com `_placeholder` const, seguindo o padrão `BudgetCardLoadingWidget`.
- `test/src/presentation/providers/couple_notifier_test.dart` — atualizar os asserts existentes (de `asData?.value` retornando `CoupleCardPresentationData?` pra retornar `CoupleCardState`); adicionar testes para `CoupleFailureState` carregar a `failure.message`.

## Fora do escopo

- **Retry com debounce ou exponential backoff**. O botão chama `ref.invalidate(coupleProvider)` direto — Riverpod cuida da deduplicação se o user clicar em rajada.
- **Telemetria de erro / log de falhas no banner**. Se decidido necessário depois, entra como spec separada.
- **Diferenciar visual entre `NetworkFailure` e `ServerFailure`**. A mensagem usa `failure.message` (que já vem com texto distinto por tipo) — sem ícones nem cores diferentes.
- **Skeleton custom com Container**. Usar o `Skeletonizer` package que já é convenção do projeto (`BudgetCardLoadingWidget`, `RecentExpensesLoadingWidget`, etc.) — animação shimmer vem incluída sem código adicional.
- **Pull-to-refresh na settings**. Retry é só via botão do card de falha.
- **Mensagens i18n**. Hardcoded `pt_BR` como o resto do app.
- **Falha do `userProvider.future`** propagada separadamente. Continua o mesmo comportamento: se `userProvider` lançar, o `coupleNotifier` propaga `AsyncError` e o switch cai no default (skeleton). Aceitável porque `userProvider` falhar implica problema mais grave (sessão inválida) que será tratado no nível do app.

## Decisões de design

1. **Sealed class `CoupleCardState` em vez de `AsyncError`.**
   Opção avaliada: lançar `throw failure` no fold e diferenciar via `AsyncError` no switch da view. Rejeitada porque mistura sinal de negócio (sem casal vs erro) com canal de erro infraestrutural do Riverpod — `AsyncError` é pra falhas inesperadas (exception não tratada), não pra um Left esperado do Either. Sealed class deixa as três variantes de **negócio** explícitas e o `AsyncValue<CoupleCardState>` carrega só o que é infra (loading). Padrão também é mais fácil de testar (assert direto em `state.asData?.value is CoupleFailureState`).

2. **`NotFoundFailure` → `CoupleNoneState` (mantém a conflation).**
   O `FailureResponseExtension` já mapeia tanto `not_found` quanto `not_in_couple` pra `NotFoundFailure`. No caller (couple endpoint), `not_found` puro não acontece — só `not_in_couple`. Manter `NotFoundFailure → CoupleNoneState` é consistente com a spec original e não exige criar um failure dedicado (que seria overkill por ora).

3. **`CoupleFailureState` carrega a `failure.message`.**
   Mensagem default do `Failure` já é amigável (ex: `'Sem conexão com o servidor.'`, `'Falha interna do servidor.'`). Usar `failure.message` direto evita um segundo mapeamento na presentation e mantém a única fonte da verdade no domain. Se uma falha vier com mensagem técnica futura, o ajuste é no `Failure` (lugar correto), não na UI.

4. **Retry via `ref.invalidate(coupleProvider)`.**
   Idioma canônico do Riverpod, citado no CLAUDE.md como o caminho de invalidação. Funciona com `@Riverpod(keepAlive: true)` — força reexecução do `build()` na próxima leitura, que é imediata porque o `SettingsCoupleStatusWidget` continua escutando. Não precisa expor método no notifier — o widget de falha recebe `WidgetRef` via `Consumer` e chama direto.

5. **`SettingsCoupleFailureWidget` segue o estilo do `BudgetCardFailureWidget`.**
   Já existe um padrão no projeto pra "card de falha com retry": ícone `error_outline` 48px (cor `colors.error`), texto centralizado em `bodyMedium`, `OutlinedButton` "Tentar novamente". Replicar o padrão mantém consistência visual e familiariza o user com a affordance.

6. **Skeleton via `Skeletonizer` package, padrão do projeto.**
   Convenção estabelecida em `BudgetCardLoadingWidget`, `RecentExpensesLoadingWidget`, `InviteQrCodeLoadingWidget`, etc.: wrap o widget de sucesso com `Skeletonizer` + um `_placeholder` const com dados fake. O package cuida da animação shimmer e do mascaramento dos elementos. Reaproveita o `SettingsCoupleConnectedWidget` existente — zero duplicação visual, mesma estrutura/dimensão (sem layout shift).

7. **Widget de loading vive ao lado do couple connected e failure widgets.**
   `presentation/ui/settings/widgets/settings_couple_loading_widget.dart`. Justifica: específico do banner de casal (depende do `SettingsCoupleConnectedWidget`). Nome `LoadingWidget` segue a convenção do projeto (`BudgetCardLoadingWidget`, `ExpensesLoadingWidget`, etc.).

8. **Loading default + AsyncError do user→couple flow caem no loading.**
   O switch do `SettingsCoupleStatusWidget` resolve `AsyncData` pra um dos 3 widgets de negócio; `AsyncLoading` e `AsyncError` ambos caem no `_` → `SettingsCoupleLoadingWidget`. Justifica: `AsyncError` é raro (só se `userProvider` lançar — sessão inválida); mostrar loading brevemente é menos ruim que mostrar erro que não dá pra resolver com retry local. Se o `userProvider` realmente quebrou, o app vai sair pra SignIn de qualquer jeito.

9. **Sealed class fica em `data/` (não em `notifiers/`).**
   Convenção do projeto: view-models de apresentação ficam em `<feature>/data/` ([[CLAUDE.md]] §Services-via-notifier). `CoupleCardState` é exatamente isso — o "shape" do dado consumido pela view. Vizinho do `couple_card_presentation_data.dart` que já existe.

10. **Mantém `CoupleCardPresentationData` como está.**
    `CoupleConnectedState` encapsula um `CoupleCardPresentationData` em vez de espalhar os campos. Mantém o presentation data reutilizável e separa "estado" de "dados do estado conectado".
