# Tasks: couple-scan-confirm-as-bottom-sheet

## presentation/ — novos widgets

- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_body_widget.dart` (NOVO) — `class CoupleScanConfirmBodyWidget extends StatelessWidget` com prop `code: String`; `Consumer` interno; `ref.listen` em `coupleScanConfirmProvider` cobrindo `.success` (toast + `Navigator.of(context, rootNavigator: true).pop()` + `context.root()`) e `.failure` (toast); body `PopScope(canPop: state.status != .loading, child: Column(mainAxisSize: .min, crossAxisAlignment: .stretch, children: [SizedBox(height: 8), Center(Text(code, headlineMedium w600 letterSpacing 4.0)), SizedBox(height: 24), ButtonWidget.elevated(label: 'Aceitar convite', isLoading: state.status == .loading, onTap: ... dispatch AcceptPressed(code))]))`
- [ ] `lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_sheet.dart` (NOVO) — função pública `Future<void> showCoupleScanConfirmSheet({required BuildContext context, required String code})` que chama `bottomSheetScaffoldWidget<void>` com `title: 'Confirmar união'`, `subtitle: 'Confira o código do convite antes de aceitar.'` e `child: CoupleScanConfirmBodyWidget(code: code)`

## presentation/ — wiring da CoupleScanScreen

- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — trocar import `couple_scan_confirm_location.dart` por `couple_scan_confirm_sheet.dart`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — renomear `_navigateToConfirm` → `_openConfirmSheet` (async): chama `await showCoupleScanConfirmSheet(context: context, code: code)`, no `then` lê `coupleScanProvider.notifier` via `ProviderScope.containerOf` e dispatcha `RetryPressed()` se `mounted`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — atualizar `_onStatusChanged`: na detecção (`next.status == .detected`) chamar `_openConfirmSheet(next.code)`
- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart` — adicionar caso no switch de `_onStatusChanged`: `case .ready when previous == .detected: await _safeStart();` (mantém o `case .ready when previous == .failure` existente)

## main/

- [ ] `lib/app_route.dart` — remover `static final coupleScanConfirm = AppRoutes._(...)` (entrada do route) e a referência em `_all`

## Limpeza

- [ ] `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — **DELETAR**
- [ ] `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` — **DELETAR**
- [ ] `grep -r 'CoupleScanConfirmLocation\|CoupleScanConfirmScreen\|coupleScanConfirm' lib/ test/` deve retornar vazio após as remoções

## Verificação

- [ ] `flutter analyze` — zero issues; sem imports orfãos
- [ ] `flutter test` — 760 testes existentes seguem passando (sem novos testes)
- [ ] Smoke "scan + sheet abre": apontar QR válido → câmera para → bottom-sheet sobe com header "Confirmar união" + code grande + botão "Aceitar convite"
- [ ] Smoke "accept sucesso": tocar "Aceitar convite" → botão loading → toast verde com nome do parceiro → sheet fecha → app vai pra Home (não pra scan/invite)
- [ ] Smoke "accept falha": code inválido → toast vermelho com mensagem do backend → sheet permanece aberto → botão volta ao estado normal pra tentar de novo (ou fechar)
- [ ] Smoke "fechar sheet manualmente": swipe-down ou back → sheet fecha → câmera reinicia (scan volta a `.ready`) → apontar QR de novo funciona
- [ ] Smoke "loading bloqueia dismiss": dispatch accept → enquanto loading, back-button do Android é ignorado (PopScope); swipe-down idem (Flutter 3.14+)
- [ ] Smoke "manual code → sheet": tocar "Digitar código manualmente" → bottom-sheet de manual → digitar code válido → confirmar → manual sheet fecha → confirm sheet abre com o code → mesmo fluxo
- [ ] Confirmar via DevTools: rota `/couple/scan/confirm` não existe mais; só `/couple/scan` na pilha
