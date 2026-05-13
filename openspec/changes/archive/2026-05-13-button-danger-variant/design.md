# Design: button-danger-variant

## Widget central

`lib/src/presentation/widgets/buttons/button_widget.dart` — diffs:

### Enum

```dart
enum ButtonWidgetType { text, elevated, outlined, danger }
```

### Construtor

```dart
const ButtonWidget.danger({
  super.key,
  required this.onTap,
  this.child,
  this.label,
  this.isLoading,
}) : type = ButtonWidgetType.danger;
```

### `_buildButton`

Adicionar branch novo no switch:

```dart
Widget _buildButton({required BuildContext context, required Widget child}) =>
    switch (type) {
      .elevated => ElevatedButton(onPressed: onTap, child: child),
      .outlined => OutlinedButton(onPressed: onTap, child: child),
      .danger => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.error,
          foregroundColor: context.colors.onError,
        ),
        child: child,
      ),
      .text => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: .zero,
          minimumSize: .zero,
          alignment: .centerLeft,
          tapTargetSize: .shrinkWrap,
          overlayColor: Colors.transparent,
          backgroundColor: Colors.transparent,
        ),
        child: child,
      ),
    };
```

O `styleFrom` herda `shape`/`elevation`/`padding`/`minimumSize` do tema global (`FlexSubThemesData.elevatedButtonRadius: 16.0`, `buttonMinSize: Size(54.0, 54.0)`, etc.) — só sobrescrevemos cor.

### `_buildLoading`

Adicionar parâmetro de tipo ou uma propriedade derivada. Solução mais simples: usar `type` direto no método.

```dart
CircularProgressIndicatorWidget _buildLoading(BuildContext context) =>
    CircularProgressIndicatorWidget(
      key: const ValueKey('loading'),
      width: 20.0,
      height: 20.0,
      color: _loadingColor(context),
    );

Color _loadingColor(BuildContext context) => switch (type) {
  .danger => context.colors.onError,
  _ => context.isDark
      ? context.colors.onPrimaryContainer
      : context.colors.onPrimary,
};
```

`_loadingColor` é método privado novo — extraído pra manter `_buildLoading` em expression body.

---

## Confirm dialog

`lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart` — diffs:

### `showConfirmDialog`

```dart
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  String denyLabel = 'Cancelar',
  String confirmLabel = 'Confirmar',
  bool isDestructive = true,
}) async {
  final data = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialogWidget(
      title: title,
      denyLabel: denyLabel,
      description: description,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );

  return data ?? false;
}
```

### `ConfirmDialogWidget`

```dart
class ConfirmDialogWidget extends StatelessWidget {
  final String title;
  final String denyLabel;
  final String description;
  final String confirmLabel;
  final bool isDestructive;

  const ConfirmDialogWidget({
    super.key,
    required this.title,
    required this.description,
    this.denyLabel = 'Cancelar',
    this.confirmLabel = 'Confirmar',
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    // ...resto inalterado...
    actions: [
      Row(
        spacing: 12.0,
        children: [
          Expanded(
            child: ButtonWidget.outlined(
              label: denyLabel,
              onTap: () => context.pop(false),
            ),
          ),
          Expanded(
            child: isDestructive
                ? ButtonWidget.danger(
                    label: confirmLabel,
                    onTap: () => context.pop(true),
                  )
                : ButtonWidget.elevated(
                    label: confirmLabel,
                    onTap: () => context.pop(true),
                  ),
          ),
        ],
      ),
    ],
  );
}
```

Call sites existentes (6 chamadas) **não precisam mudar** — `isDestructive` default `true` mantém comportamento desejado em todas.

---

## Replacements

### `SettingsLogoutWidget`

`lib/src/presentation/ui/settings/widgets/settings_logout_widget.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger`. Sem outras mudanças.

### `ProfileDeleteAccountWidget`

`lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger`. Sem outras mudanças.

### `ProfileDeleteScreen`

`lib/src/presentation/ui/profile/delete/screens/profile_delete_screen.dart:99` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger`. Sem outras mudanças.

### `ExitScreen`

`lib/src/presentation/ui/exit/screens/exit_screen.dart:27` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger` no botão "Sair". Botão "Cancelar" permanece `ButtonWidget.outlined`.

---

## Não mexer

- `themes.dart` — sem entradas novas. Estilo é local ao branch `.danger` no `_buildButton`.
- `FormSubmitButtonWidget` — não destrutivo.
- `SwipeActionsBackgroundWidget` — já vermelho.
- `IconButtonWidget` — não tem variante destrutiva no escopo.
- Todos os outros `ButtonWidget.elevated` (sign_in, sign_up, forgot_password, password_reset_confirm, expenses_filter "Aplicar", date_range "Aplicar", forgot_password_success "OK", confirm dialog default — agora coberto pelo `isDestructive`) — não-destrutivos.

---

## Decisões de implementação

1. **`_loadingColor` extraído como método.**
   Alternativa: inline ternary no `_buildLoading`. Extrair fica mais legível com o switch expression e mantém `_buildLoading` em expression body.

2. **`isDestructive` é a propriedade no `ConfirmDialogWidget`, não `ButtonWidgetType`.**
   O dialog é o decisor (semântica de "esta confirmação é destrutiva?"). O tipo de botão é consequência. Não expor `ButtonWidgetType` direto no dialog API.

3. **Ordem do switch expression em `_buildButton`.**
   Manter a ordem original (`elevated`, `outlined`, `danger`, `text`). `danger` perto de `elevated` deixa o pattern visual fácil — ambos são ElevatedButton com style diferente.

4. **Não tocar em `_buildTitle`.**
   `child` + `label` continuam funcionando igual — ícone branco/onError fica legível sobre vermelho. `SettingsLogoutWidget` passa o `Icon(Icons.logout)` como `child` — o `IconTheme` herda `foregroundColor` do `ElevatedButton`, então o ícone vira `onError` automaticamente. Confirmar no smoke.

5. **Sem teste novo.**
   Não há teste para `ButtonWidget.elevated`/`.outlined`/`.text` hoje. Adicionar widget test só para `.danger` cria assimetria. Smoke manual cobre.
