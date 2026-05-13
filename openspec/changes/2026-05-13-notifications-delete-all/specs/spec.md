# Spec: notifications-delete-all

## Capability

Permitir ao user excluir todas as notificações dele em uma única ação, com confirmação destrutiva, feedback de erro e atualização imediata da UI.

## Comportamento

### Botão de "excluir todas"

- Aparece nas `actions` da `AppBarWidget` da `NotificationsScreen` **somente quando** `state.value?.items.length > 10`.
- Visual idêntico ao `ExpensesFilterButtonWidget` (mesmo `IconButtonWidget`, mesmo tamanho 36×36 com `iconSize` 18, mesma `Padding.only(right: 16)` no container).
- Ícone: `Icons.delete_sweep_outlined`.
- Ao tocar, abre dialog de confirmação.

### Dialog de confirmação

- Reusa `showConfirmDialog` de `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart`.
- `title`: `'Excluir notificações'`
- `description`: `'Esta ação não pode ser desfeita.'`
- `confirmLabel`: `'Excluir'`
- `denyLabel`: `'Cancelar'` (default do widget).
- Se o user cancelar (ou dismissar), nenhuma ação é disparada.
- Se confirmar, dispara `NotificationsNotifier.deleteAll()`.

### Ação no notifier

- `deleteAll()` é **no-op** quando:
  - `state.value` é `null` (build ainda não concluiu / state em erro).
  - `state.value!.isDeletingAll` já é `true` (segunda chamada concorrente).
- Início: seta `isDeletingAll: true`, limpa `deleteAllFailure`.
- Chama `_repository.deleteAll()`.
- Em sucesso: seta `items: []`, `groups: []`, `nextCursor: null`, `isDeletingAll: false`, `deleteAllFailure: null`.
- Em falha: mantém `items`/`groups`/`nextCursor` intactos, seta `isDeletingAll: false`, `deleteAllFailure: failure`.

### Feedback de erro

- `NotificationsScreen` faz `ref.listen` no `notificationsProvider`.
- Quando `deleteAllFailure` transita de `null → Failure` (ou muda de instância), dispara `showToastWidget(context, title: 'Opps', type: .failure, description: failure.message)`.
- Lista permanece intacta — user pode tentar de novo.

### Empty state pós-delete

- Após sucesso, `items.isEmpty == true` → screen renderiza `NotificationsEmptyWidget` (mesmo widget já usado quando a primeira página vem vazia).
- Botão de delete some automaticamente (threshold `> 10` deixa de ser satisfeito).

### Endpoint

- `DELETE /api/v1/notifications`
- Auth: `Authorization: Bearer <access>` (interceptor existente).
- Sem query, sem body.
- Sucesso: HTTP 204.
- Erro: `FailureResponse` padrão.

### Mapeamento de erros

| Código (`FailureItemResponse.code`) | Failure |
|---|---|
| `network_error` / `connection_error` / `timeout` | `NetworkFailure` |
| `not_found` | `NotFoundFailure` |
| `server_error` | `ServerFailure` |
| outros | `ValidationFailure(message)` |
| desconhecido / errors vazio | `UnknownFailure` |

Via `FailureResponseExtension.toFailure()` existente.

## Não-comportamentos

- **Não** refaz fetch após sucesso. Limpeza é local.
- **Não** invalida nenhum outro provider (`ref.invalidate`). Nenhuma feature externa depende de `notificationsProvider`.
- **Não** mostra loading no botão. Operação é rápida; o dialog já fecha antes do retorno da request.
- **Não** mostra toast de sucesso. Limpeza da lista já é o feedback visual.
- **Não** anima a saída dos items. `state.items = []` é instantâneo.
- **Não** oferece undo / restore.
- **Não** persiste delete localmente caso a request falhe — items continuam no servidor e na UI.
