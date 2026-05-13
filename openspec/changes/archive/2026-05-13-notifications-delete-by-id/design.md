# Design: notifications-delete-by-id

## Contrato da API

**Endpoint:** `DELETE /api/v1/notifications/{id}`

**Auth:** `Authorization: Bearer <access>` (injetado por `AuthenticationInterceptor`).

**Body:** vazio.
**Query:** nenhuma.
**Path param:** `id` (int) — id da notificação a excluir.

**Response 204:** sem corpo.

**Response 4xx/5xx:** `FailureResponse` padrão (`{ errors: [...] }`).

---

## Domain

### `INotificationRepository` — extensão

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
abstract interface class INotificationRepository {
  Future<Either<Failure, void>> deleteAll();
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> deleteById({required int id});
  Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor});
}
```

---

## Infrastructure

### `IRemoteNotificationDataSource` — extensão

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart`:

```dart
abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> deleteAll();
  Future<Either<FailureResponse, void>> revokeToken();
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> deleteById({required int id});
  Future<Either<FailureResponse, NotificationsResponse>> findAll({String? cursor});
}

// impl:
@override
Future<Either<FailureResponse, void>> deleteById({required int id}) async {
  final response = await _httpClient.delete(
    parameter: Requests('${EndpointKey.notifications.path}/$id'),
  );

  return response.either(FailureResponse.fromJson, (_) {});
}
```

Sem body, sem query.

---

## Data

### `NotificationRepository` — extensão

`lib/src/data/repositories/notification_repository.dart`:

```dart
@override
Future<Either<Failure, void>> deleteById({required int id}) async {
  final data = await _dataSource.deleteById(id: id);

  return data.either((failure) => failure.toFailure(), (_) {});
}
```

---

## Presentation

### `NotificationsState` — extensão

`lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` — adicionar:

```dart
final Failure? deleteFailure;
```

E no `copyWith`:

```dart
Failure? deleteFailure,
bool clearDeleteFailure = false,
...
deleteFailure: clearDeleteFailure ? null : deleteFailure ?? this.deleteFailure,
```

Adicionar `deleteFailure` em `props`.

### `NotificationsNotifier.deleteById`

`lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart`:

```dart
Future<void> deleteById(int id) async {
  final current = state.value;
  if (current == null) return;

  final originalIndex = current.items.indexWhere(
    (item) => item.notification.id == id,
  );
  if (originalIndex < 0) return;

  final originalItem = current.items[originalIndex];
  final newItems = [...current.items]..removeAt(originalIndex);

  state = AsyncData(
    current.copyWith(
      items: newItems,
      clearDeleteFailure: true,
      groups: buildNotificationGroups(newItems, dateFormatter: _dateFormatter),
    ),
  );

  final data = await _repository.deleteById(id: id);

  data.fold(
    (Failure failure) {
      final currentItems = state.value!.items;
      final restored = [...currentItems];
      final insertAt = originalIndex.clamp(0, restored.length);
      restored.insert(insertAt, originalItem);

      state = AsyncData(
        state.value!.copyWith(
          items: restored,
          deleteFailure: failure,
          groups: buildNotificationGroups(
            restored,
            dateFormatter: _dateFormatter,
          ),
        ),
      );
    },
    (_) {},
  );
}
```

`state.value!` no fold é seguro: acabamos de setar `AsyncData` na linha acima e o método é sequencial.

### `NotificationDismissBackgroundWidget` (NOVO)

`lib/src/presentation/ui/notifications/widgets/notification_dismiss_background_widget.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

class NotificationDismissBackgroundWidget extends StatelessWidget {
  const NotificationDismissBackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: context.colors.error,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 24.0),
    child: Icon(
      Icons.delete_outline,
      color: context.colors.onError,
    ),
  );
}
```

Background pintado de `error`, ícone alinhado à direita (`centerRight`) — revela conforme o swipe avança.

### `NotificationsListWidget` — wrap com `Dismissible`

`lib/src/presentation/ui/notifications/widgets/notifications_list_widget.dart`:

```dart
class NotificationsListWidget extends StatelessWidget {
  final VoidCallback onLoadMore;
  final NotificationsState state;
  final ValueChanged<int> onDelete;                       // NOVO
  final List<NotificationGroupPresentationData> groups;

  const NotificationsListWidget({
    super.key,
    required this.state,
    required this.groups,
    required this.onDelete,                               // NOVO
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      for (final group in groups) ...[
        SliverToBoxAdapter(
          child: NotificationsDateHeaderWidget(label: group.header),
        ),
        SliverList.builder(
          itemCount: group.notifications.length,
          itemBuilder: (_, index) {
            final item = group.notifications[index];

            return Dismissible(
              key: ValueKey(item.notification.id),
              direction: DismissDirection.endToStart,
              background: const NotificationDismissBackgroundWidget(),
              confirmDismiss: (_) => showConfirmDialog(
                context: context,
                confirmLabel: 'Excluir',
                title: 'Excluir notificação',
                description: 'Esta ação não pode ser desfeita.',
              ),
              onDismissed: (_) => onDelete(item.notification.id),
              child: NotificationCardWidget(item: item),
            );
          },
        ),
      ],
      SliverToBoxAdapter(child: _tail()),
    ],
  );
  ...
}
```

`NotificationCardWidget` perde a `ValueKey` (move pra `Dismissible`).

### `NotificationsScreen` — wiring + listener

`lib/src/presentation/ui/notifications/screens/notifications_screen.dart`:

1. **Passar `onDelete` pro `NotificationsListWidget`:**

```dart
AsyncData(:final NotificationsState value) => [
  NotificationsListWidget(
    state: value,
    groups: value.groups,
    onLoadMore: _onLoadMore,
    onDelete: notifier.deleteById,
  ),
],
```

2. **Estender o `ref.listen` pra reagir também a `deleteFailure`:**

```dart
ref.listen(notificationsProvider, (previous, next) {
  final nextDeleteAllFailure = next.value?.deleteAllFailure;
  final previousDeleteAllFailure = previous?.value?.deleteAllFailure;

  if (nextDeleteAllFailure != null &&
      nextDeleteAllFailure != previousDeleteAllFailure) {
    showToastWidget(
      context: context,
      title: 'Opps',
      type: .failure,
      description: nextDeleteAllFailure.message,
    );
  }

  final nextDeleteFailure = next.value?.deleteFailure;
  final previousDeleteFailure = previous?.value?.deleteFailure;

  if (nextDeleteFailure != null && nextDeleteFailure != previousDeleteFailure) {
    showToastWidget(
      context: context,
      title: 'Opps',
      type: .failure,
      description: nextDeleteFailure.message,
    );
  }
});
```

---

## Decisões de design

1. **Optimistic remove sem flag adicional.**
   `state.items` é a única fonte de verdade do que está visível. Quando o notifier remove, o item some; quando reinsere, volta. `Dismissible` trata visualmente — não precisamos de `deletingIds: Set<int>`.

2. **Rebuild de `groups` toda vez que `items` muda.**
   `buildNotificationGroups` é puro e barato. Espelha o que o notifier já faz em `loadMore`.

3. **Re-inserção no rollback respeita `originalIndex` capturado.**
   Trade-off: se houve refresh entre remove e failure, o índice pode ser inválido. `clamp(0, items.length)` cobre. Não tentamos "encontrar a posição correta por timestamp" — overkill.

4. **`onDismissed` chama `notifier.deleteById(id)`.**
   `Dismissible` faz a animação; `onDismissed` dispara após o animation completar. O notifier remove do state nesse callback — não há gap visual porque o item já está animado pra fora.

5. **`confirmDismiss` retorna `Future<bool>` direto.**
   `showConfirmDialog` já retorna `Future<bool>` e `Dismissible.confirmDismiss` espera `Future<bool?>` — coerção implícita ok. Sem wrapper.

6. **`Dismissible.key` é obrigatório.**
   Sem key, Flutter não consegue trackear identidade durante o swipe. Usamos `ValueKey(notification.id)` — id é único por notificação.

7. **`NotificationCardWidget` não muda.**
   Comportamento de hoje (renderizar ícone + título + descrição + hora) está intacto. Wrapper é externo.

---

## Testes

### `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart`

Adicionar `group('deleteById')`:

- `'DELETEs at /api/v1/notifications/{id} without body on 2xx'` — verifica path com id concatenado.
- `'returns Left with FailureResponse on backend error'`.

### `test/src/data/repositories/notification_repository_test.dart`

Adicionar `group('deleteById')`:

- `'returns Right when datasource succeeds'`
- `'propagates id to datasource'` — `verify(() => dataSource.deleteById(id: 42))`.
- `'returns Left NetworkFailure on network error'`
- `'returns Left ServerFailure on server error'`
- `'returns Left NotFoundFailure on not found'`
- `'returns Left ValidationFailure on unknown code'`

### `test/src/presentation/providers/notifications_notifier_test.dart`

Adicionar `group('deleteById')`:

- `'removes item from items and groups on success'`
- `'no-op when id is not found in items'` — `verifyNever(repository.deleteById)`.
- `'restores item at original index on failure and sets deleteFailure'` — usa `_first` (2 items), deleta o de index 1 (`id: 2`), API falha, verifica item volta no index 1, `deleteFailure != null`, `items.length == 2`.

Sem widget test pro `Dismissible` (segue convenção do projeto — nenhum widget test em outros lugares).
