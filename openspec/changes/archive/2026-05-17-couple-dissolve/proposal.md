# Proposal: couple-dissolve

## Intenção

Permitir que um usuário desfaça o vínculo de casal ativo via uma tela dedicada acessível pelo card de casal conectado da `SettingsScreen`. A ação:

1. Apresenta a tela `CoupleDissolveScreen` explicando o efeito da operação.
2. Botão único `ButtonWidget.danger` no rodapé abre um `showConfirmDialog` destrutivo.
3. Confirmado, dispara `DELETE /api/v1/couple`.
4. Em caso de sucesso (204), invalida os providers afetados, mostra toast e volta para a `SettingsScreen` (que re-renderiza automaticamente o `SettingsInvitePartnerWidget`).

Adicionalmente, esta spec **reorganiza** a feature de convite que hoje vive em `lib/src/presentation/ui/partner/` para um módulo `lib/src/presentation/ui/couple/`, espelhando o padrão do módulo `lib/src/presentation/ui/authentication/` (que agrupa `sign_in/`, `sign_up/`, `forgot_password/`, `password_reset_confirm/`).

Estrutura alvo:

```
presentation/ui/couple/
  invite/        ← migra de presentation/ui/partner/
    data/ locations/ notifiers/ screens/ widgets/ widgets/painters/
  dissolve/      ← NOVO
    locations/ notifiers/ screens/
```

## Motivação

1. **Sem affordance pra desfazer**: hoje `SettingsCoupleStatusWidget` resolve para `SettingsCoupleConnectedWidget` quando há casal ativo, mas `onCoupleDetails` é `() => {}` em `settings_location.dart:23` — o tap não faz nada. O usuário não consegue desfazer o vínculo pelo app.

2. **Backend pronto**: endpoint `DELETE /api/v1/couple` (verificado via curl no escopo deste change) retorna 204 No Content em sucesso e `FailureResponse` padrão em erro. Sem dependências ou mudanças no backend.

3. **Agrupamento por domínio**: a feature de "convite" já vive isolada em `partner/`, fora do conceito de domínio (`couple/`). Adicionar uma nova sub-feature `dissolve/` reabre a oportunidade de unificar tudo em `couple/`, mirroring o `authentication/` (já validado como padrão do projeto). O nome `partner` é redundante: o ator é "parceiro", mas o domínio é "casal" — exatamente como `signIn`/`signUp` são ações sobre `authentication`.

4. **Sem deep links bloqueando rename**: verificado via grep em `lib/src/main/deep_link/` — nenhum deep link aponta para `/partner/...`, então as paths `/partner/invite` e `/partner/invite/qr-code` podem virar `/couple/invite` e `/couple/invite/qr-code` sem migração de dados.

## Camadas afetadas

### Infrastructure / data / domain (endpoint dissolve)

- `lib/src/infrastructure/datasources/remote/remote_couple_data_source.dart` — adicionar método `dissolve()` na interface `IRemoteCoupleDataSource` e implementação `RemoteCoupleDataSource`, seguindo o padrão de `RemoteUserDataSource.delete()` (linha 38-51).
- `lib/src/domain/repositories/interface_couple_repository.dart` — adicionar `Future<Either<Failure, void>> dissolve()`.
- `lib/src/data/repositories/couple_repository.dart` — implementar `dissolve()` chamando o datasource e usando `data.either((failure) => failure.toFailure(), (_) {})`.
- `EndpointKey.couple` já existe (`/api/v1/couple`) e é reaproveitado pelo DELETE.

### Presentation (dissolve)

- `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_state.dart` (NOVO) — `enum CoupleDissolveStatus { initial, loading, success, failure }` + `CoupleDissolveState` com `status` e `message` (Equatable + copyWith).
- `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_intent.dart` (NOVO) — `sealed class CoupleDissolveIntent` com `final class DissolvePressed`.
- `lib/src/presentation/ui/couple/dissolve/notifiers/couple_dissolve_notifier.dart` (NOVO) — `@riverpod` Notifier MVI. Injeta `coupleRepositoryProvider` em `build()`. `dispatch(DissolvePressed)` → `_dissolve()`: guard loading, chama `_repository.dissolve()`, no `fold`:
  - `failure` → `state.copyWith(status: .failure, message: failure.message)`.
  - `success` → invalida `coupleProvider`, `recentExpensesProvider`, `activeBudgetProvider`, `insightsProvider`, `expensesProvider`, `budgetsProvider`; depois `state.copyWith(status: .success)`.
- `lib/src/presentation/ui/couple/dissolve/screens/couple_dissolve_screen.dart` (NOVO) — `StatelessWidget` + `Consumer`. Estrutura: `ScaffoldWidget` + `AppBarWidget(leading: GoBackWidget())` + `Padding all(16.0)` + `Column` com `ScreenHeaderWidget`, corpo (lista de efeitos) e `ButtonWidget.danger` no rodapé. `ref.listen` em `coupleDissolveProvider`:
  - `.success` (when previous != success) → `showToastWidget(type: .success, title: 'Pronto', description: 'Vocês não estão mais conectados.')` + `context.pop()`.
  - `.failure` (when previous != failure) → `showToastWidget(type: .failure, title: 'Opps', description: state.message)`.
  - demais → `null`.
- `lib/src/presentation/ui/couple/dissolve/locations/couple_dissolve_location.dart` (NOVO) — path `/couple/dissolve`, `pageBuilder` instancia `CoupleDissolveScreen` (sem callbacks externos).

### Presentation (rename partner → couple/invite)

Move todos os arquivos de `lib/src/presentation/ui/partner/` para `lib/src/presentation/ui/couple/invite/`, mantendo o conteúdo. Renames de classe/arquivo seguindo o padrão `partner_invite_*` → `couple_invite_*` apenas onde o nome contém "partner"; `invite_qr_code_*` mantém o nome (já é "invite", não "partner").

| De | Para |
|---|---|
| `partner/locations/partner_invite_location.dart` (`PartnerInviteLocation`) | `couple/invite/locations/couple_invite_location.dart` (`CoupleInviteLocation`) |
| `partner/screens/partner_invite_screen.dart` (`PartnerInviteScreen`) | `couple/invite/screens/couple_invite_screen.dart` (`CoupleInviteScreen`) |
| `partner/widgets/partner_invite_hero_widget.dart` (`PartnerInviteHeroWidget`) | `couple/invite/widgets/couple_invite_hero_widget.dart` (`CoupleInviteHeroWidget`) |
| `partner/widgets/partner_invite_actions_widget.dart` (`PartnerInviteActionsWidget`) | `couple/invite/widgets/couple_invite_actions_widget.dart` (`CoupleInviteActionsWidget`) |
| `partner/widgets/partner_invite_security_note_widget.dart` (`PartnerInviteSecurityNoteWidget`) | `couple/invite/widgets/couple_invite_security_note_widget.dart` (`CoupleInviteSecurityNoteWidget`) |
| `partner/widgets/partner_pair_indicator_widget.dart` (`PartnerPairIndicatorWidget`) | `couple/invite/widgets/couple_pair_indicator_widget.dart` (`CouplePairIndicatorWidget`) |
| `partner/widgets/invite_qr_card_widget.dart` | `couple/invite/widgets/invite_qr_card_widget.dart` |
| `partner/widgets/invite_qr_code_failure_widget.dart` | `couple/invite/widgets/invite_qr_code_failure_widget.dart` |
| `partner/widgets/invite_qr_code_loading_widget.dart` | `couple/invite/widgets/invite_qr_code_loading_widget.dart` |
| `partner/widgets/painters/dashed_line_painter.dart` | `couple/invite/widgets/painters/dashed_line_painter.dart` |
| `partner/widgets/painters/dashed_rounded_rect_painter.dart` | `couple/invite/widgets/painters/dashed_rounded_rect_painter.dart` |
| `partner/locations/invite_qr_code_location.dart` | `couple/invite/locations/invite_qr_code_location.dart` |
| `partner/screens/invite_qr_code_screen.dart` | `couple/invite/screens/invite_qr_code_screen.dart` |
| `partner/notifiers/invite_qr_code_notifier.dart` | `couple/invite/notifiers/invite_qr_code_notifier.dart` |
| `partner/data/invite_qr_code_presentation_data.dart` | `couple/invite/data/invite_qr_code_presentation_data.dart` |

### Wiring

- `lib/app_route.dart` — renomear `AppRoutes.partnerInvite` → `AppRoutes.coupleInvite` (path `/couple/invite`, name `couple-invite-route`); renomear `AppRoutes.partnerInviteQrCode` → `AppRoutes.coupleInviteQrCode` (path `/couple/invite/qr-code`); adicionar `AppRoutes.coupleDissolve` (path `/couple/dissolve`, name `couple-dissolve-route`); atualizar `_all` com os novos nomes.
- `lib/src/presentation/ui/settings/locations/settings_location.dart` — trocar o import `partner_invite_location` por `couple_invite_location` e `CoupleInviteLocation()`; fazer `onCoupleDetails` navegar para `CoupleDissolveLocation()` (hoje `() {}`).

### Testes

- `test/src/data/repositories/couple_repository_test.dart` — adicionar grupo `DELETE /couple` (`dissolve`) cobrindo:
  - Sucesso (204 No Content) → `Right(null)`.
  - `NetworkFailure`, `ServerFailure`, `NotFoundFailure`, `ValidationFailure('custom message')` via códigos do `FailureCodeResponse`.
- `test/src/presentation/providers/couple_dissolve_notifier_test.dart` (NOVO) — mock `ICoupleRepository`. Cobre:
  - `dispatch(DissolvePressed)` com sucesso → state `.success`.
  - `dispatch(DissolvePressed)` com falha → state `.failure` carregando `failure.message`.
  - `dispatch(DissolvePressed)` durante loading → segunda chamada não executa (guarda).
- Sem testes de `fromJson` (não há response body).
- Sem teste de datasource isolado (padrão do projeto).

## Fora do escopo

- **Guard simétrico na `CoupleInviteLocation`** (redirect para `CoupleDissolveLocation` se já existe casal ativo). Hoje a única affordance pra abrir a invite é o `SettingsInvitePartnerWidget`, que só renderiza quando `CoupleNoneState`. Adicionar guard de Location exige resolver o `coupleProvider` (async) dentro de um `LocationInterceptor` (síncrono em `duck_router`), o que é uma decisão arquitetural maior e fora do foco aqui. Defer para spec separada se aparecer caso de uso (deep link, etc.).
- **Re-conectar imediatamente após dissolver**. Após o pop, o user vê o `SettingsInvitePartnerWidget` e segue o fluxo normal de criar invite. Sem atalho "desfazer e convidar de novo" — comportamento normal seria estranho ("desfez por engano? vai ter que recriar manualmente").
- **Undo / desfazer dentro de uma janela de tempo**. DELETE é definitivo no backend. Sem grace period, sem snackbar "desfeito, desfazer".
- **Notificar o parceiro**. O backend é responsável por enviar push/email para o parceiro quando o vínculo é desfeito. Fora do escopo da app (já implementado server-side via FCM, presumido).
- **Telemetria / log da ação de dissolve**. Se necessário, entra como spec separada.
- **Mensagens i18n**. Hardcoded `pt_BR` como o resto do app.
- **`partner_invite_actions_widget.onScan: () {}`**: o botão "Escanear" da `CoupleInviteScreen` continua no-op (já era antes). Não é regressão. Fora do escopo desta spec — entra na spec de scan QR code.

## Decisões de design

1. **Pop após sucesso via `ref.listen` + `context.pop()`, não via callback do Location.**
   `CoupleDissolveLocation` não recebe `onSuccess` no construtor. O notifier emite `.success` no state, o `ref.listen` da screen detecta a transição e chama `context.pop()`. Justifica: o `coupleProvider` é invalidado *antes* do state ir pra `.success`, então quando voltarmos pra settings, o `SettingsCoupleStatusWidget` já vai re-resolver para `CoupleNoneState` (mostra `SettingsInvitePartnerWidget`). Não precisa de side-effect explícito vindo da Location — é orgânico via invalidation + pop.

2. **`@riverpod` (não `keepAlive`) no `CoupleDissolveNotifier`.**
   O notifier é state de mutação efêmera; descarta junto com a screen. Diferente do `CoupleNotifier` (settings), que é `keepAlive: true` porque o estado do casal é compartilhado por outras telas. Análogo ao `ProfileDeleteNotifier` (`profile_delete_notifier.dart:16`).

3. **Sem `build()` async.**
   Não há nada pra carregar quando a tela abre — o `coupleProvider` já carregou no settings. O state inicial é `.initial` e só vira `.loading` quando o user toca em desfazer. `build()` síncrono retornando `const CoupleDissolveState()`. Análogo ao `ProfileDeleteNotifier.build()` (linha 22-27).

4. **Lista de providers a invalidar.**
   - `coupleProvider` — obrigatório, é o source of truth do estado de casal.
   - `recentExpensesProvider`, `activeBudgetProvider`, `insightsProvider` — todos `@Riverpod(keepAlive: true)` consumidos pela `HomeScreen`. Após dissolver, despesas/orçamentos/insights compartilhados deixam de fazer parte do feed do user; sem invalidar, o home mostra dados stale até o user dar refresh.
   - `expensesProvider`, `budgetsProvider` — análogo para a tela de listagem completa.

   **Não invalidar** `userProvider` (dados do user — name, email — não mudam) nem `settingsProvider` (só lida com logout). Não há `notificationsProvider` afetado diretamente (notificação de dissolve vem por push, já fora do cache do app).

5. **Toast de sucesso vem antes do pop, não depois.**
   Ordem no `ref.listen` em `.success`: primeiro `showToastWidget`, depois `context.pop()`. Isso garante que o `ScaffoldMessenger` que mostra o toast é o da tela atual (dissolve), antes de ser desmontada. O pop é síncrono em `duck_router`, então o toast já está visível quando voltamos para settings. Padrão usado em outras telas (ex: `profile_delete_screen.dart`).

6. **`showConfirmDialog` é chamado da screen, não do notifier.**
   O dialog precisa do `BuildContext`. Pattern: tap no `ButtonWidget.danger` chama `_confirm(context, notifier)` que mostra o dialog e, se confirmado, dispara `DispatchPressed`. Análogo ao `profile_delete_screen.dart:112-133` e `settings_screen.dart:86-99` (logout).

7. **Botão danger no rodapé com `SizedBox(width: .infinity, ...)`.**
   Mesma estrutura do `profile_delete_screen.dart:97-104`. Largura cheia para passar peso visual à ação. `isLoading: state.status == .loading` desabilita re-tap durante a chamada.

8. **Header copy direto, sem dramaturgia.**
   - Título: `'Desfazer casal'`.
   - Descrição: `'Esta ação encerra a conexão com seu parceiro. Os dados de cada um permanecem, mas vocês deixam de compartilhar.'`

   Tom factual. O dialog reforça a confirmação destrutiva, então o header não precisa "assustar".

9. **Corpo: lista de bullets explicando o efeito.**
   Três itens, com `Row(spacing: 12.0)` e ícone à esquerda:
   - `Icons.visibility_off_outlined` — `'Vocês deixarão de visualizar despesas e orçamentos compartilhados imediatamente.'`
   - `Icons.history` — `'Seus dados pessoais (despesas, orçamentos, histórico) permanecem intactos.'`
   - `Icons.handshake_outlined` — `'Vocês podem se reconectar a qualquer momento por um novo convite.'`

   Componente: extrair `CoupleDissolveEffectWidget` (privado por método, pois trivial: ícone + texto multi-linha). Decisão de extrair em arquivo próprio ou método privado fica em `design.md`.

10. **Dialog destrutivo.**
    `showConfirmDialog(title: 'Desfazer casal', confirmLabel: 'Desfazer', description: 'Tem certeza? Vocês deixarão de compartilhar despesas e orçamentos imediatamente.', isDestructive: true)`. `isDestructive: true` é o default — não precisa passar explicitamente. Mesmo padrão do logout (`settings_screen.dart:89-95`) e profile delete (`profile_delete_screen.dart:123-129`).

11. **Renomear path `partnerInvite` → `coupleInvite` é decisão deliberada.**
    Caminhos no `AppRoutes` são fonte da verdade do esquema de URL. Manter `/partner/invite` enquanto a feature vive em `couple/invite/` cria descompasso entre estrutura de pasta e path. Como não há deep link público nem nada externo apontando para `/partner/...`, o rename é seguro e mais limpo a longo prazo.

12. **`couple_notifier.dart` do settings permanece em `presentation/ui/settings/notifiers/`.**
    Embora o nome sugira "couple", o notifier é o state do **card de casal do settings** — alimenta `SettingsCoupleStatusWidget` que vive em settings/widgets. Mover para `couple/` violaria o encapsulamento de feature: settings consumiria um notifier de couple só pra renderizar um sub-card seu. Mantém em settings, fim.

13. **`CoupleDissolveNotifier` invalida providers cross-feature — é a exceção narrada permitida pelo CLAUDE.md.**
    Padrão idêntico ao `ExpenseNotifier.dart` (linha 102-104) e `BudgetFormNotifier.dart` (linha 106-107). Único uso de `ref.invalidate` em providers de outras features — qualquer outro uso (`ref.watch`, `ref.read(...).notifier.X`) seria violação.

14. **Migração: deletar a pasta `partner/` antiga (não deixar wrappers).**
    Sem backwards-compat. Os imports da `SettingsLocation` (único consumer externo de `PartnerInviteLocation`) são reescritos pra apontar para `CoupleInviteLocation`. Sem aliases, sem re-exports, sem `// removed` comments. Padrão do projeto: rename limpo (regra de CLAUDE.md "Avoid backwards-compatibility hacks").
