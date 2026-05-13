# Spec: notifications-delete-by-id

## Capability

Permitir ao user excluir uma notificação individual via swipe da direita-pra-esquerda no `NotificationCardWidget`, com confirmação destrutiva, atualização otimista da UI e rollback automático em caso de falha.

## Comportamento

### Gesto de swipe

- Cada `NotificationCardWidget` é envolto em um `Dismissible` dentro de `NotificationsListWidget`.
- `direction`: `DismissDirection.endToStart` (apenas swipe da direita pra esquerda).
- `key`: `ValueKey(item.notification.id)`.
- `background`: `NotificationDismissBackgroundWidget` — `Container` com `color: context.colors.error`, `alignment: centerRight`, ícone `Icons.delete_outline` em `context.colors.onError` revelando à direita conforme o swipe avança.

### Confirmação

- `Dismissible.confirmDismiss` chama `showConfirmDialog`:
  - `title`: `'Excluir notificação'`
  - `description`: `'Esta ação não pode ser desfeita.'`
  - `confirmLabel`: `'Excluir'`
  - `denyLabel`: default (`'Cancelar'`).
- Retorna `true` → swipe completa → `onDismissed` dispara.
- Retorna `false` ou dismiss → item volta com animação nativa do `Dismissible`.

### Optimistic delete

- `onDismissed` chama `notifier.deleteById(id)`.
- Notifier:
  1. Captura `originalItem` + `originalIndex` no `state.items`.
  2. Remove item do `items`; rebuild `groups`; limpa `deleteFailure`.
  3. Chama `_repository.deleteById(id: id)`.
  4. Em sucesso: nada a fazer (item já removido).
  5. Em falha: reinsere `originalItem` em `originalIndex.clamp(0, items.length)`; rebuild `groups`; seta `deleteFailure: failure`.

### Feedback de erro

- `NotificationsScreen` faz `ref.listen` no `notificationsProvider` e reage à transição `deleteFailure: null → Failure` (ou mudança de instância) chamando `showToastWidget(type: .failure, description: failure.message)`.
- O mesmo listener continua reagindo a `deleteAllFailure` (não conflitam — são campos separados).

### No-op

- `deleteById(id)` é no-op quando:
  - `state.value` é `null`.
  - Nenhum item no `items` tem `notification.id == id` (`indexWhere` retorna `< 0`).

### Endpoint

- `DELETE ${EndpointKey.notifications.path}/$id`
- Auth: `Authorization: Bearer <access>` (interceptor existente).
- Sem query, sem body.
- Sucesso: HTTP 204.
- Erro: `FailureResponse` padrão.

### Mapeamento de erros

Via `FailureResponseExtension.toFailure()` existente — mesma tabela do `deleteAll`:

| Código (`FailureItemResponse.code`) | Failure |
|---|---|
| `network_error` / `connection_error` / `timeout` | `NetworkFailure` |
| `not_found` | `NotFoundFailure` |
| `server_error` | `ServerFailure` |
| outros | `ValidationFailure(message)` |
| desconhecido / errors vazio | `UnknownFailure` |

## Não-comportamentos

- **Não** mostra SnackBar com undo. Confirmação no swipe já mitiga delete acidental.
- **Não** anima a re-inserção em rollback. Flutter rebuilda o item naturalmente — aceita-se o "pop" visual.
- **Não** trava swipe de outros items durante delete em flight de um item. Operações são independentes.
- **Não** suporta swipe LTR. Apenas RTL (`endToStart`).
- **Não** abre screen de edit no tap. Tap continua sem efeito (mesmo comportamento do `notifications-list`).
- **Não** invalida outros providers. Nenhuma feature externa depende de `notificationsProvider`.
- **Não** persiste delete localmente se a API falhar. Rollback reinsere e mostra toast — user pode tentar de novo.
