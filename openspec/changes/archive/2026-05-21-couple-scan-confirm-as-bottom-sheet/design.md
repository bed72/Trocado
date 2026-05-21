# Design: couple-scan-confirm-as-bottom-sheet

## Estado atual

### `CoupleScanScreen._navigateToConfirm`

`lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart:205-206`:

```dart
void _navigateToConfirm(String code) =>
    context.navigate(CoupleScanConfirmLocation(code: code));
```

Chamado em `_onStatusChanged` quando `state.status == .detected`. Empilha a rota `/couple/scan/confirm` no `duck_router`.

### `CoupleScanConfirmLocation`

`lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart`:

```dart
final class CoupleScanConfirmLocation extends Location {
  final String code;
  const CoupleScanConfirmLocation({required this.code});

  @override
  String get path => AppRoutes.coupleScanConfirm.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (context) => screenPage(CoupleScanConfirmScreen(code: code));
}
```

### `CoupleScanConfirmScreen`

`lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — `StatelessWidget` + `Consumer`, `ScaffoldWidget(appBar: AppBarWidget(leading: GoBackWidget()))` + `Padding all(16.0)` + `Column`. Conteúdo: `ScreenHeaderWidget('Confirmar união', 'Confira o código do convite antes de aceitar.')`, `Center(child: Text(code, ...))`, `Spacer`, `ButtonWidget.elevated('Aceitar convite')`. `ref.listen` reage a `.success`/`.failure`.

### `app_route.dart` — `coupleScanConfirm`

```dart
static final coupleScanConfirm = AppRoutes._(
  path: '/couple/scan/confirm',
  name: 'couple-scan-confirm-route',
  regex: RegExp(r'^/couple/scan/confirm$'),
);
```

Listado em `_all`.

### `bottomSheetScaffoldWidget<T>`

`lib/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart`:

```dart
Future<T?> bottomSheetScaffoldWidget<T>({
  required BuildContext context,
  required Widget child,
  final String? title,
  final String? subtitle,
  double marginTop = 32,
  bool autoResize = false,
}) => showModalBottomSheet<T>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (context) => Container(
    constraints: autoResize ? null : BoxConstraints(maxHeight: context.height - marginTop),
    padding: .only(bottom: context.bottom),
    child: BottomSheetScaffoldWidget(title: title, subtitle: subtitle, child: child),
  ),
);
```

`isDismissible` e `enableDrag` não são parametrizáveis no helper — assumem o default `true` do `showModalBottomSheet`. Não vamos mudar.

### Precedente: `couple_scan_manual_code_sheet`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_manual_code_sheet.dart`:

```dart
Future<void> showCoupleScanManualCodeSheet({required BuildContext context}) =>
    bottomSheetScaffoldWidget<void>(
      context: context,
      title: 'Código do convite',
      subtitle: 'Digite o código que seu par compartilhou.',
      child: const CoupleScanManualCodeBodyWidget(),
    );
```

Modelo exato pro novo sheet de confirm.

### `CoupleScanConfirmNotifier`

Sem mudança. Continua respondendo a `AcceptPressed(code)`, capturando `partnerName` em `Right`, invalidando os providers de couple/expenses/budgets/etc, e setando `.success`.

---

## Presentation

### `CoupleScanConfirmBodyWidget`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_body_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_intent.dart';
import 'package:trocado/src/presentation/ui/couple/scan/notifiers/couple_scan_confirm_notifier.dart';

class CoupleScanConfirmBodyWidget extends StatelessWidget {
  final String code;

  const CoupleScanConfirmBodyWidget({super.key, required this.code});

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      ref.listen(coupleScanConfirmProvider, (previous, next) {
        switch (next.status) {
          case .success when previous?.status != .success:
            _onSuccess(context, next.partnerName);
          case .failure when previous?.status != .failure:
            _onFailure(context, next.message);
          default:
        }
      });

      final state = ref.watch(coupleScanConfirmProvider);
      final notifier = ref.read(coupleScanConfirmProvider.notifier);
      final isLoading = state.status == .loading;

      return PopScope(
        canPop: !isLoading,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            const SizedBox(height: 8.0),
            Center(
              child: Text(
                code,
                style: context.typography.headlineMedium?.copyWith(
                  fontWeight: .w600,
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ButtonWidget.elevated(
              label: 'Aceitar convite',
              isLoading: isLoading,
              onTap: isLoading
                  ? null
                  : () => notifier.dispatch(AcceptPressed(code)),
            ),
          ],
        ),
      );
    },
  );

  void _onSuccess(BuildContext context, String partnerName) {
    showToastWidget(
      context: context,
      type: .success,
      title: 'Pronto',
      description: 'Você está conectado com $partnerName.',
    );
    Navigator.of(context, rootNavigator: true).pop();
    context.root();
  }

  void _onFailure(BuildContext context, String message) => showToastWidget(
    context: context,
    title: 'Opps',
    type: .failure,
    description: message,
  );
}
```

Decisões:
- `PopScope` aplica só ao back-button do Android; o swipe-down no iOS respeita o `onPopInvokedWithResult` desde Flutter 3.14. Sem `isDismissible: false` no helper.
- `_onSuccess` faz `pop()` antes do `context.root()` pra garantir que o sheet some antes de qualquer transição de rota.
- `_onFailure` deixa o sheet aberto — user pode tentar de novo (botão volta a ficar habilitado quando `state.status` sai de `.loading`).

### `showCoupleScanConfirmSheet`

`lib/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_sheet.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_widget.dart';

import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_confirm_body_widget.dart';

Future<void> showCoupleScanConfirmSheet({
  required BuildContext context,
  required String code,
}) => bottomSheetScaffoldWidget<void>(
  context: context,
  title: 'Confirmar união',
  subtitle: 'Confira o código do convite antes de aceitar.',
  child: CoupleScanConfirmBodyWidget(code: code),
);
```

### `CoupleScanScreen` — abrir sheet + reset no fechamento

`lib/src/presentation/ui/couple/scan/screens/couple_scan_screen.dart`:

- Trocar import `couple_scan_confirm_location.dart` → `couple_scan_confirm_sheet.dart`.
- Renomear `_navigateToConfirm` → `_openConfirmSheet`:

```dart
Future<void> _openConfirmSheet(String code) async {
  await showCoupleScanConfirmSheet(context: context, code: code);
  if (!mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(coupleScanProvider.notifier).dispatch(const RetryPressed());
}
```

- Atualizar `_onStatusChanged`:

```dart
if (next.status == .detected) {
  if (mounted) _openConfirmSheet(next.code);
}
```

`RetryPressed` é dispatch em qualquer caminho de fechamento (sucesso/erro/back/drag). No sucesso, a screen já navegou via `context.root()` antes do `await` retornar — o `read` do provider ainda vai funcionar (Riverpod tolera reads em providers que viraram unused; e como o scan tem `keepAlive: false` por padrão, o reset acontece sobre uma instância já marcada pra disposal — o efeito é nulo, sem warning). Em caso de fechamento manual sem accept, o status volta a `.ready` e a câmera reinicia via `_safeStart` no próximo `_onStatusChanged` (já existe).

Atenção: o `_onStatusChanged` só chama `_safeStart` quando `previous == .failure`. Para reiniciar a câmera após fechar o sheet sem accept (`.detected → .ready`), adicionar caso:

```dart
case .ready when previous == .detected:
  await _safeStart();
```

Sem isso, a câmera fica parada porque o `_safeStop` foi chamado no `.detected`. Patch direto no switch existente.

### `app_route.dart`

Remover linhas ~148-152 (`coupleScanConfirm`) e a referência em `_all` (linha ~222). Ajustar indentação se necessário.

---

## Limpeza

- `lib/src/presentation/ui/couple/scan/screens/couple_scan_confirm_screen.dart` — **DELETAR**.
- `lib/src/presentation/ui/couple/scan/locations/couple_scan_confirm_location.dart` — **DELETAR**.
- Verificar via `grep -r 'CoupleScanConfirmLocation\|CoupleScanConfirmScreen\|coupleScanConfirm'` que não há mais nada após a remoção.

---

## Testes

- Sem alterações. `couple_scan_confirm_notifier_test.dart` cobre o notifier; `couple_scan_notifier_test.dart` cobre as transições do scan. O sheet/body é UI sem state — sem teste de widget novo.
- Re-rodar `flutter analyze` e `flutter test` confirma que nada quebrou após o rename do entrypoint.

---

## Riscos

1. **`RetryPressed` em provider que pode estar sendo descartado.** Em caso de sucesso, o `context.root()` substitui a pilha; o provider `coupleScanProvider` perde listeners e pode ter sido invalidado pelo Riverpod. O `read(...notifier)` ainda retorna a instância em vida no `ProviderContainer` raiz (não-tree-scoped) — o `dispatch` é seguro, mas o state-change subsequente é descartado quando o provider de fato é GC'd. Aceitável.
2. **Câmera não reinicia após dismiss sem accept.** Sem o patch no `_onStatusChanged` (case `.ready when previous == .detected`), a câmera fica parada. Coberto na seção de design — risco mitigado pela mudança explícita no switch.
3. **`PopScope` no iOS.** Em Flutter < 3.14 o swipe-down de modal bottom sheet ignora `PopScope`. Hoje o projeto roda 3.10+. Conferir a versão atual; se ainda não estiver em 3.14, vale forçar `isDismissible: false` enquanto loading via uma extensão pontual do helper. Spec atual aposta no `PopScope` — se quebrar no smoke, fallback é estender o `bottomSheetScaffoldWidget` com `isDismissible: bool? = true` opcional.
4. **Sheet aberto + back nativo Android durante loading.** `PopScope(canPop: false)` bloqueia. User percebe que o app "ignora" o back — mensagem implícita: aguarde. Não exibimos feedback visual extra (o botão já está em loading state); aceitável.

---

## Notas

- `useRootNavigator: true` no `bottomSheetScaffoldWidget` é importante: garante que `Navigator.of(context, rootNavigator: true).pop()` no `_onSuccess` opere sobre o mesmo Navigator que abriu o sheet.
- A escolha de `Column(mainAxisSize: .min)` ao invés de `Spacer + SizedBox(width: .infinity)` (padrão da screen atual) é porque sheet tem altura natural pelo `BoxConstraints(maxHeight: context.height - 32)` do helper — não precisa expandir.
- O `BottomSheetScaffoldWidget` já adiciona padding 20/20/20/32 e o handle visual; body só cuida do conteúdo.
