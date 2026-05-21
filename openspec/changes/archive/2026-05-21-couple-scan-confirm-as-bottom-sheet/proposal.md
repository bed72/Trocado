# Proposal: couple-scan-confirm-as-bottom-sheet

## Intenção

Converter `CoupleScanConfirmScreen` de tela navegada em **bottom-sheet** lançado pela `CoupleScanScreen` quando o estado do scan vira `.detected`. A lógica de negócio (notifier, state, intent, accept) permanece intacta — só o invólucro de UI muda.

Fluxo novo:

1. `CoupleScanScreen` detecta code (QR ou manual) → state vai pra `.detected`.
2. `_onStatusChanged` chama `showCoupleScanConfirmSheet(context: context, code: state.code)` em vez de `context.navigate(CoupleScanConfirmLocation(...))`.
3. Sheet exibe header (`'Confirmar união'` / `'Confira o código do convite antes de aceitar.'`), o code estilizado e botão `'Aceitar convite'`. `Consumer` interno reage ao `coupleScanConfirmProvider`.
4. Em `.success`: toast `'Você está conectado com {nome}.'`, fecha o sheet via root navigator, navega pra `HomeLocation` via `context.root()`.
5. Em `.failure`: toast com `state.message`, sheet permanece aberto (user pode tentar de novo).
6. Em `.loading`: sheet bloqueia dismiss (back/drag) via `PopScope(canPop: ...)`.
7. Quando o sheet fecha **sem** accept (back/drag), `CoupleScanScreen` dispatcha `RetryPressed()` no `then(...)` do `showCoupleScanConfirmSheet`, voltando o scan a `.ready` e reiniciando a câmera.

## Motivação

1. **Fluxo mais leve.** Confirmar união é uma ação curta (1 code + 1 botão). Tela inteira é over-engineering pro escopo — bottom-sheet preserva o contexto do scanner e reduz fricção pra desistir.
2. **Consistência com o módulo.** `CoupleScanScreen` já abre `couple_scan_manual_code_sheet` como bottom-sheet via `bottomSheetScaffoldWidget`. Confirm vira o segundo sheet do mesmo screen, alinhando os dois affordances de "ação rápida sobre o scan".
3. **Menos rota.** `CoupleScanConfirmLocation` e `AppRoutes.coupleScanConfirm` morrem. A árvore de navegação fica mais simples: `/couple/scan` é a única rota da feature.
4. **Cancelar é natural.** Hoje o user volta da confirm com back-button do app bar e a câmera fica em estado `.detected` (a tela some, mas pra escanear de novo ele teria que navegar pra trás e pra frente). Com sheet, o swipe-down/back já reseta pro `.ready` via `RetryPressed`, mantendo a câmera ativa.

## Camadas afetadas

### Presentation

- `lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_sheet.dart` (NOVO) — função pública `showCoupleScanConfirmSheet({required BuildContext context, required String code}) → Future<void>` que chama `bottomSheetScaffoldWidget<void>` com `title: 'Confirmar união'`, `subtitle: 'Confira o código do convite antes de aceitar.'` e `child: CoupleScanConfirmBodyWidget(code: code)`.
- `lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_body_widget.dart` (NOVO) — `class CoupleScanConfirmBodyWidget extends StatelessWidget` (classe pública, conforme CLAUDE.md). `Consumer` interno: `ref.watch(coupleScanConfirmProvider)` + `ref.listen(...)`. Layout: `Column` com `Text(code)` (`headlineMedium` w600 letterSpacing 4.0, centralizado) + `SizedBox(height: 24.0)` + `ButtonWidget.elevated('Aceitar convite')`. Envolve a `Column` em `PopScope(canPop: state.status != .loading, ...)` pra travar dismiss durante o accept.
- `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — `_navigateToConfirm` vira `_openConfirmSheet`: chama `showCoupleScanConfirmSheet(context: context, code: code).then((_) { if (mounted) ref-context.read(coupleScanProvider.notifier).dispatch(const RetryPressed()); })`. Remover import de `CoupleScanConfirmLocation`. (Detalhe sintático: pegar `notifier` via `ProviderScope.containerOf(context, listen: false).read(coupleScanProvider.notifier)` igual ao `_showFailure` já faz, ou via `Consumer` no escopo do build — decidir no design.)
- `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — **DELETAR**.
- `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` — **DELETAR**.

### Main

- `lib/app_route.dart` — remover a entrada `static final coupleScanConfirm = AppRoutes._(...)` (linhas ~148-152) e a referência em `_all` (linha ~222).

### Testes

- Testes de `CoupleScanNotifier` e `CoupleScanConfirmNotifier` — sem mudança. O notifier de confirm continua com a mesma API; o sheet é só UI.
- Sem testes de widget novos (consistente com o resto do app).

## Fora do escopo

- **Parametrizar `bottomSheetScaffoldWidget` com `isDismissible`/`enableDrag`.** A trava de dismiss durante loading é feita via `PopScope` no body do sheet, sem tocar no helper compartilhado. Caso outra tela precise futuramente, vira spec dedicada.
- **Tela de sucesso intermediária** pós-accept. Mantém toast + `context.root()` igual à versão atual.
- **Telemetria de scan/accept.** Mesma posição da spec anterior.
- **Refatoração do helper `bottomSheetScaffoldWidget` para suportar header opcional ou diferentes paddings.** Não é necessário — o `title`/`subtitle` atuais já cobrem o caso.
- **Animação custom de transição sheet → home.** O `context.root()` continua sendo a forma única de sair do fluxo pós-accept.
- **Reabrir o sheet se o user navegar voltar pra `CoupleScanScreen` em estado `.detected` órfão.** Não acontece — `RetryPressed` no `.then` garante reset pro `.ready` antes de qualquer próxima detecção.

## Decisões de design

1. **Sheet como widget, não como Location.** O fluxo é "ação modal sobre o scan", não uma nova tela na pilha. `duck_router` não precisa saber dele — segue o padrão de `couple_scan_manual_code_sheet`.

2. **`PopScope` no body, não `isDismissible: false` no helper.** A trava é local ao caso de uso (loading do accept). Mexer no helper compartilhado pra um único consumidor é over-engineering. `PopScope(canPop: state.status != .loading)` cobre back-button do Android; o swipe-down respeita o mesmo gate via `onPopInvokedWithResult`.

3. **`RetryPressed` no `.then` do sheet, não no `_onStatusChanged`.** O `.then` dispara quando o sheet é dismissado por qualquer caminho (sucesso via `Navigator.pop`, swipe, back, falha-que-fica-aberto que o user depois fecha). Único side-effect: reseta o scan pra `.ready` e a câmera volta a ler. Em caso de sucesso, o `_onSuccess` já navegou pra `context.root()` antes do `.then` disparar — o `RetryPressed` cai num provider que pode estar sendo descartado, mas Riverpod tolera (provider já não é mais ouvido pela home).

4. **Body em widget público, não anônimo.** CLAUDE.md proíbe classe privada com lógica em outro arquivo. `CoupleScanConfirmBodyWidget` é pública e tem responsabilidade clara — pode até ganhar preview no futuro (`CoupleScanConfirmBodyWidget(code: 'A3K7FN')` num `@TrocadoPreview`).

5. **`Navigator.of(context, rootNavigator: true).pop()` no `_onSuccess`.** O sheet foi aberto com `useRootNavigator: true` (default do helper). Fechar via root garante que a chamada subsequente `context.root()` opere sobre a pilha limpa, sem o sheet ainda em cima.

6. **Header (`title`/`subtitle`) no helper, não no body.** Mantém o handle visual + tipografia consistentes com o sheet de manual code. Body fica enxuto: code + botão.

7. **Sem `isDismissible: false` durante loading no helper, mas `PopScope` cobre só o Android back.** No iOS, swipe-down em modal bottom sheet também respeita o `PopScope` desde Flutter 3.x (via `onPopInvokedWithResult`). Aceitável.

8. **Apagar a rota `coupleScanConfirm` do `AppRoutes`.** Não há outro consumidor — confirmado por grep. Manter a entrada seria código morto.

9. **Manter `CoupleScanConfirmNotifier`, `CoupleScanConfirmState`, `CoupleScanConfirmIntent` exatamente como estão.** Toda a lógica (loading guard, invalidations pós-accept, captura de `partnerName`) continua válida. Mudar UI não toca em business logic.

10. **Spec de UI puro.** Sem mudanças em datasource, repository, model ou response. Sem mudanças em testes — a cobertura existente cobre o comportamento do notifier que não muda.
