# Tasks: button-danger-variant

## presentation/widgets/buttons/

- [ ] `lib/src/presentation/widgets/buttons/button_widget.dart` — adicionar `ButtonWidgetType.danger` ao enum; adicionar construtor `ButtonWidget.danger(...)`; adicionar branch `.danger` no `_buildButton` com `ElevatedButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError)`; extrair `_loadingColor(BuildContext)` para selecionar `onError` quando `type == .danger`.

## presentation/widgets/dialog/

- [ ] `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart` — adicionar parâmetro `bool isDestructive = true` em `showConfirmDialog` e `ConfirmDialogWidget`; trocar o botão de confirmação por `ButtonWidget.danger` quando `isDestructive == true`, caso contrário manter `ButtonWidget.elevated`.

## presentation/ui/

- [ ] `lib/src/presentation/ui/settings/widgets/settings_logout_widget.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger`.
- [ ] `lib/src/presentation/ui/profile/details/widgets/profile_delete_account_widget.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger`.
- [ ] `lib/src/presentation/ui/profile/delete/screens/profile_delete_screen.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger` no botão "Excluir" (linha ~99).
- [ ] `lib/src/presentation/ui/exit/screens/exit_screen.dart` — trocar `ButtonWidget.elevated` por `ButtonWidget.danger` no botão "Sair" (linha ~27). Botão "Cancelar" permanece `ButtonWidget.outlined`.

## main/providers/

- [ ] (nenhuma mudança)

## test/

- [ ] (nenhuma mudança — projeto não tem widget tests para `ButtonWidget` ou para os widgets/screens tocados; manter convenção)

## Pré-condições (já satisfeitas)

- `ButtonWidget` existe com `.text`/`.elevated`/`.outlined` em `lib/src/presentation/widgets/buttons/button_widget.dart`
- `context.colors.error` e `context.colors.onError` disponíveis via `context_extension.dart` (ColorScheme do tema)
- `ConfirmDialogWidget` e `showConfirmDialog` existem em `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`
- `BounceWidget`, `CircularProgressIndicatorWidget`, `SwitcherAnimation` (dependências do `ButtonWidget`) inalterados

## Verificação

- [ ] `flutter analyze` — zero issues nos arquivos tocados (warnings pré-existentes fora do escopo OK).
- [ ] `flutter test` — verde (sem testes novos; garantir que nenhum existente quebrou).
- [ ] Smoke visual em light theme: abrir Settings → botão "Sair" vermelho; tocar → dialog de confirmação com botão "Sair" vermelho à direita e "Cancelar" outlined à esquerda.
- [ ] Smoke visual em dark theme: idem, conferir contraste do texto/ícone sobre o fundo `colors.error` (dark: `#FFB4AB`, foreground `onError: #690005`).
- [ ] Smoke Profile → "Excluir conta": botão trigger vermelho; tela seguinte com botão "Excluir" vermelho no rodapé; após tocar, dialog com "Excluir" vermelho.
- [ ] Smoke Exit (back-press na home): bottom sheet com "Sair" vermelho à esquerda e "Cancelar" outlined à direita.
- [ ] Smoke swipe-to-delete (despesa/orçamento/notificação): swipe vermelho → dialog com "Excluir" vermelho. Lista permanece consistente.
- [ ] Loading state: disparar logout (ou outra ação destrutiva com `isLoading`), verificar spinner com cor `onError` legível sobre o fundo vermelho.
- [ ] Nenhuma feature importa `presentation/widgets/buttons/` violando regra de encapsulamento — só importa o `ButtonWidget` público, que é compartilhado.
