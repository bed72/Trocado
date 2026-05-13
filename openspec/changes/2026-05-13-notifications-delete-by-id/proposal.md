# Proposal: notifications-delete-by-id

## Intenção

Permitir ao user excluir uma notificação individual via swipe da direita-pra-esquerda no `NotificationCardWidget` da `NotificationsScreen`. Swipe abre dialog de confirmação; confirmar dispara `DELETE /api/v1/notifications/{id}`. UX otimista: item some na hora, rollback automático se a API falhar.

## Motivação

Após `notifications-list` e `notifications-delete-all`, falta a granularidade — user precisa poder dispensar uma notificação específica sem zerar tudo. Backend já entrega o endpoint (curl confirmado em 2026-05-13).

A escolha por **swipe** (e não por tap → screen como no `expense`) é deliberada: notificação é semanticamente diferente de expense — read-only e single-action (apenas delete). Criar uma screen pra hospedar um botão "excluir" único seria overhead. O pattern do expense existe pra hospedar view + edit + delete; notificação não tem o que editar.

## Camadas afetadas

- `domain/repositories/` — `INotificationRepository.deleteById`.
- `infrastructure/datasources/remote/` — `IRemoteNotificationDataSource.deleteById`.
- `data/repositories/` — `NotificationRepository.deleteById`.
- `presentation/ui/notifications/notifiers/` — `NotificationsState` + `NotificationsNotifier.deleteById`.
- `presentation/ui/notifications/widgets/` — wrapping `NotificationCardWidget` em `Dismissible` dentro de `NotificationsListWidget` + novo `notification_dismiss_background_widget.dart`.
- `presentation/ui/notifications/screens/` — estender `ref.listen` pra reagir também a `deleteFailure`.

`main/providers/` não muda — providers já existem. Sem novo `EndpointKey` (path `${EndpointKey.notifications.path}/$id`).

## Fora do escopo

- Undo via SnackBar — sem padrão no projeto; confirm dialog já mitiga delete acidental.
- Animação custom de re-inserção em rollback — Flutter rebuilda o item naturalmente; aceitar o "pop" visual.
- Mark-as-read separado do delete.
- Edit screen — não há o que editar numa notificação.
- Batch select (multi-delete) — já temos `delete-all` pra esse caso.

## Decisões de design

1. **Swipe + `confirmDismiss` reusando `showConfirmDialog`.**
   `Dismissible.confirmDismiss` chama `showConfirmDialog` com labels do delete-all (`'Excluir notificação'` no singular). Retorna `true` → swipe completa e dispara `onDismissed`. Retorna `false` → item volta com animação.

2. **Optimistic remove com rollback no notifier.**
   `onDismissed` chama `notifier.deleteById(id)`. Notifier:
   1. Captura `originalItem` + `originalIndex` no `state.items`.
   2. Remove do state imediatamente; rebuild de `groups`.
   3. Chama `_repository.deleteById(id: id)`.
   4. Em sucesso: nada a fazer (já está removido).
   5. Em falha: reinsere `originalItem` no `originalIndex` (clamped), rebuild de `groups`, seta `deleteFailure`.

3. **`DismissDirection.endToStart`.**
   Apenas direita-pra-esquerda. Decisão do user. Swipe LTR fica reservado pra eventual `mark as read` no futuro (não nesta spec).

4. **Background do swipe: `context.colors.error` + `Icons.delete_outline` branco.**
   Novo widget `NotificationDismissBackgroundWidget` em `presentation/ui/notifications/widgets/` — pinta o slot todo de error e revela o ícone alinhado à direita. Não promove pra `presentation/widgets/` raiz porque só esta feature usa; promove se outra feature pedir Dismissible.

5. **`Dismissible.key` = `ValueKey(notification.id)`.**
   Move o `ValueKey(item.notification.id)` que hoje está no `NotificationCardWidget` pra `Dismissible`. O card fica sem key (Flutter usa identidade por posição). Identidade estável é responsabilidade do `Dismissible` aqui.

6. **Erro reusa `deleteAllFailure` pattern.**
   Campo `Failure? deleteFailure` no state. Screen ouve via `ref.listen` exatamente como já faz pra `deleteAllFailure` (toast com `showToastWidget(type: .failure)`).
   - Optei por `deleteFailure` (separado de `deleteAllFailure`) pra evitar conflito caso user dispare ambos em sequência. Listener distingue cada um.

7. **Sem flag `isDeleting` no state.**
   `Dismissible` já trava o gesto durante a animação. Re-swipe acidental do mesmo item enquanto rollback acontece é impossível porque o item nem está no tree. Re-swipe de OUTRO item durante delete em flight é OK — operações são independentes no backend, e o notifier processa em sequência por await.

8. **Endpoint: concatenar id no path existente.**
   `${EndpointKey.notifications.path}/$id` — mesmo idioma de outros endpoints com id no projeto. Não adicionar nova entrada no enum `EndpointKey` pra um path parametrizado.

9. **Repository aceita `int id` posicional-nomeado.**
   `Future<Either<Failure, void>> deleteById({required int id})`. Mesmo padrão do `findAll({String? cursor})`.

10. **Re-inserção usa `clamp(0, items.length)` pra segurança.**
    Se entre o optimistic remove e o failure callback o user fizer pull-to-refresh, `state.value!.items` pode ter mudado. Clampar o índice evita `RangeError`. Trade-off aceitável: o item pode acabar numa posição ligeiramente diferente da original — preferível a um crash. Edge case extremamente raro na prática.
