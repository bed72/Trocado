# Proposal: button-danger-variant

## Intenção

Adicionar uma nova variante `ButtonWidget.danger` (estilo `elevated` com fundo `colors.error` e foreground `colors.onError`) ao `ButtonWidget` central e trocar os botões primários de ações destrutivas — logout, excluir conta (trigger + confirmação final), sair do app — para usar a nova variante. Estender `ConfirmDialogWidget` / `showConfirmDialog` com um parâmetro `isDestructive` (default `true`) que faz o botão de confirmação usar `.danger`.

## Motivação

Hoje todos os botões primários de ações destrutivas no app usam `ButtonWidget.elevated`, que renderiza com a cor `primary` (verde-tema). Isso emite o mesmo sinal visual de qualquer ação positiva ("Entrar", "Salvar"), apagando a diferença entre confirmar uma ação reversível e disparar uma irreversível (logout, exclusão de conta). Pela convenção Material/HIG, ações destrutivas usam a cor de erro do scheme — já temos `colors.error` no `ColorScheme` e ele já é usado em swipe backgrounds, validações e ícones de falha. Falta consistência no nível mais visível: os botões primários.

## Camadas afetadas

- `presentation/widgets/buttons/` — novo case no enum `ButtonWidgetType` + construtor `ButtonWidget.danger`; branch novo no `_buildButton`; ajuste em `_buildLoading` para usar `onError` quando danger.
- `presentation/widgets/dialog/` — `ConfirmDialogWidget` e `showConfirmDialog` ganham `bool isDestructive = true`; troca interna `elevated → danger` quando ativo.
- `presentation/ui/settings/widgets/` — `SettingsLogoutWidget` passa a usar `.danger`.
- `presentation/ui/profile/details/widgets/` — `ProfileDeleteAccountWidget` passa a usar `.danger`.
- `presentation/ui/profile/delete/screens/` — `ProfileDeleteScreen` (botão "Excluir" final) passa a usar `.danger`.
- `presentation/ui/exit/screens/` — `ExitScreen` (botão "Sair") passa a usar `.danger`.

`themes.dart` **não muda** (style por construtor, não via tema global). `FormSubmitButtonWidget` **não muda** (usado em forms não-destrutivos: criar/editar despesa, orçamento, autenticação). Swipe backgrounds **não mudam** (já em `colors.error`).

## Fora do escopo

- Variante `ButtonWidget.dangerOutlined` ou `.dangerText`. Só `.danger` (sólido). Adicionar variantes outlined/text se aparecer caso de uso.
- Tema global de `dangerButton` em `FlexSubThemesData`. Aplicação por `styleFrom` no construtor é suficiente e localiza a regra.
- Mudança no botão "Cancelar" dos dialogs/exit (continua `ButtonWidget.outlined`).
- Promover `colors.error` para uma família semântica (`danger`/`destructive` tokens). YAGNI — `colors.error` já está estabilizado no projeto.
- Animação ou haptic feedback diferente para `.danger`. Mesma `BounceWidget` que os outros.
- Widget tests para o `ButtonWidget` ou para as screens tocadas. Projeto não tem widget tests para nenhuma variante atual de `ButtonWidget`; manter convenção.
- Previews novos. Hoje não há preview de `ButtonWidget` no `presentation/preview/`. Não criar nessa spec.

## Decisões de design

1. **Nome `danger` (não `destructive`, não `error`).**
   `danger` é curto, idiomático em design systems web (Bootstrap, Primer, Tailwind) e não conflita com o token `colors.error` (que continua sendo a cor). `destructive` é mais Apple-HIG mas mais longo; `error` confunde com mensagens de validação. Aceito alternativa do user se preferir.

2. **Estilo aplicado por `styleFrom` no construtor, não via tema global.**
   `FlexSubThemesData` não tem hook pra um "elevatedButton com cor alternativa". Criar uma nova entrada no tema (`dangerButtonRadius`, `dangerButtonSchemeColor`, etc.) seria over-engineering. `ElevatedButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError)` no branch do switch é direto e mantém raio/elevação/tamanho do tema global pelo `ElevatedButton` base.

3. **`isDestructive` no `ConfirmDialogWidget` default `true`.**
   Auditoria dos 6 call sites de `showConfirmDialog` no projeto: **todos** são destrutivos (logout, excluir despesa, excluir orçamento, excluir notificação, excluir conta). Default `true` preserva o comportamento útil sem precisar tocar nas 6 chamadas. Quem quiser confirmação não-destrutiva (no futuro) passa `isDestructive: false` explícito.

4. **Loading indicator usa `onError` quando danger.**
   O `_buildLoading` atual tem branch `isDark ? onPrimaryContainer : onPrimary`. Para `.danger` o foreground é sempre `onError` (não há variação dark/light no padrão Material — `onError` já é o par correto). Mantém legibilidade do spinner sobre o fundo vermelho em ambos os temas.

5. **Swipe-to-delete não muda.**
   `SwipeActionsBackgroundWidget` já usa `colors.error` para o background do gesto de delete (`expenses_list_widget`, `budgets_list_widget`, `notifications_list_widget`). Consistência visual já está lá — quando o user soltar o swipe, abre `showConfirmDialog`, e o botão "Excluir" do dialog passa a ser `.danger` (mesmo vermelho). Loop fechado.

6. **`FormSubmitButtonWidget` fica como está.**
   É um wrapper de `ButtonWidget.elevated` para forms não-destrutivos. Se um dia surgir um form destrutivo (improvável — destrutivos são confirmados via dialog), criamos `FormDangerButtonWidget` ou parametrizamos. Hoje YAGNI.

7. **`profile_delete_screen.dart:99` usa `.danger` direto (não migra para `FormSubmitButtonWidget`).**
   O botão atual já é `SizedBox(width: .infinity, child: ButtonWidget.elevated(...))` — exato shape do `FormSubmitButtonWidget`. Mas como `FormSubmitButtonWidget` não muda nessa spec, e introduzir um wrapper paralelo só pra esse caso seria churn, mantém-se o padrão atual trocando só `.elevated → .danger`.

8. **Sem migration shim ou flag de feature.**
   Mudança visual local, sem risco de runtime. PR único.
