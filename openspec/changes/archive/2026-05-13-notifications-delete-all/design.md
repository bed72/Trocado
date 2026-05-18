# Design: notifications-delete-all

## Contrato da API

**Endpoint:** `DELETE /api/v1/notifications`

**Auth:** `Authorization: Bearer <access>` (injetado por `AuthenticationInterceptor`).

**Body:** vazio.

**Query:** nenhuma.

**Response 204:** sem corpo.

**Response 4xx/5xx:** `FailureResponse` padrão (`{ errors: [...] }`).

---

## Domain

### `INotificationRepository` — extensão

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
abstract interface class INotificationRepository {
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> deleteAll();
  Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor});
}
```

---

## Infrastructure

### `IRemoteNotificationDataSource` — extensão

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart`:

```dart
abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> revokeToken();
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> deleteAll();
  Future<Either<FailureResponse, NotificationsResponse>> findAll({String? cursor});
}

// impl:
@override
Future<Either<FailureResponse, void>> deleteAll() async {
  final response = await _httpClient.delete(
    parameter: Requests(EndpointKey.notifications.path),
  );

  return response.either(FailureResponse.fromJson, (_) {});
}
```

Sem `body`, sem `query`. `EndpointKey.notifications` já existe.

---

## Data

### `NotificationRepository` — extensão

`lib/src/data/repositories/notification_repository.dart`:

```dart
@override
Future<Either<Failure, void>> deleteAll() async {
  final data = await _dataSource.deleteAll();

  return data.either((failure) => failure.toFailure(), (_) {});
}
```

Sem extension nova em `data/extensions/` — não há response pra mapear.

---

## Presentation

### `NotificationsState` — extensão

`lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` — adicionar:

```dart
final class NotificationsState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final bool isDeletingAll;                       // NOVO
  final Failure? deleteAllFailure;                // NOVO
  final List<NotificationItemPresentationData> items;
  final List<NotificationGroupPresentationData> groups;

  const NotificationsState({
    this.nextCursor,
    this.loadMoreFailure,
    this.deleteAllFailure,
    this.items = const [],
    this.groups = const [],
    this.isLoadingMore = false,
    this.isDeletingAll = false,
  });

  NotificationsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    bool? isDeletingAll,
    Failure? loadMoreFailure,
    Failure? deleteAllFailure,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
    bool clearDeleteAllFailure = false,
    List<NotificationItemPresentationData>? items,
    List<NotificationGroupPresentationData>? groups,
  }) => NotificationsState(
    items: items ?? this.items,
    groups: groups ?? this.groups,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isDeletingAll: isDeletingAll ?? this.isDeletingAll,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
    deleteAllFailure: clearDeleteAllFailure
        ? null
        : deleteAllFailure ?? this.deleteAllFailure,
  );

  @override
  List<Object?> get props => [
    items,
    groups,
    nextCursor,
    isLoadingMore,
    loadMoreFailure,
    isDeletingAll,
    deleteAllFailure,
  ];
}
```

### `NotificationsNotifier.deleteAll`

`lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart`:

```dart
Future<void> deleteAll() async {
  final current = state.value;
  if (current == null) return;
  if (current.isDeletingAll) return;

  state = AsyncData(
    current.copyWith(isDeletingAll: true, clearDeleteAllFailure: true),
  );

  final data = await _repository.deleteAll();

  state = AsyncData(
    data.fold<NotificationsState>(
      (Failure failure) => state.value!.copyWith(
        isDeletingAll: false,
        deleteAllFailure: failure,
      ),
      (_) => state.value!.copyWith(
        isDeletingAll: false,
        clearDeleteAllFailure: true,
        items: const [],
        groups: const [],
        clearNextCursor: true,
      ),
    ),
  );
}
```

A leitura de `state.value!` no fold é segura porque acabamos de setar `AsyncData` na linha de cima e `deleteAll` é sequencial.

### Botão na top bar

`lib/src/presentation/ui/notifications/widgets/notifications_delete_all_button_widget.dart` (NOVO):

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';

class NotificationsDeleteAllButtonWidget extends StatelessWidget {
  final VoidCallback onPress;

  const NotificationsDeleteAllButtonWidget({super.key, required this.onPress});

  @override
  Widget build(BuildContext context) => IconButtonWidget(
    width: 36.0,
    height: 36.0,
    iconSize: 18.0,
    onPress: onPress,
    icon: Icons.delete_sweep_outlined,
  );
}
```

Espelha 100% `ExpensesFilterButtonWidget` — único diff é o ícone.

### Screen wiring

`lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — diffs:

1. **Imports:** adicionar `confirm_dialog_widget.dart`, `toast_widget.dart`, `notifications_delete_all_button_widget.dart`.

2. **`ref.listen` no `Consumer`** pra reagir a `deleteAllFailure`:

```dart
ref.listen<AsyncValue<NotificationsState>>(notificationsProvider, (previous, next) {
  final previousFailure = previous?.value?.deleteAllFailure;
  final nextFailure = next.value?.deleteAllFailure;

  if (nextFailure != null && nextFailure != previousFailure) {
    showToastWidget(
      context: context,
      title: 'Opps',
      type: .failure,
      description: nextFailure.message,
    );
  }
});
```

3. **`AppBarWidget.actions`** condicional baseado em `state.value?.items.length`:

```dart
AppBarWidget(
  leading: const GoBackWidget(),
  actions: (state.value?.items.length ?? 0) > 10
      ? [
          Padding(
            padding: const .only(right: 16.0),
            child: NotificationsDeleteAllButtonWidget(
              onPress: () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  confirmLabel: 'Excluir',
                  title: 'Excluir notificações',
                  description: 'Esta ação não pode ser desfeita.',
                );
                if (!confirmed) return;
                await notifier.deleteAll();
              },
            ),
          ),
        ]
      : null,
),
```

Threshold `> 10` segue exatamente a decisão do user. Quando esconde, `actions` é `null` — `AppBarWidget` já aceita.

---

## Decisões de design

1. **`previousCursor` não é tocado no delete.**
   Embora `nextCursor` precise limpar (não há próxima página), `previousCursor` no state hoje nem é exposto (não consta no `NotificationsState`). Não criar caso pra isso.

2. **`deleteAllFailure` no state em vez de stream/evento separado.**
   Convenção do projeto: erros viram campo no state, screen reage via `ref.listen` na transição. Sem `Cubit`-style listeners ou `StreamController` separados.

3. **Toast no projeto = `showToastWidget(type: .failure)`.**
   User mencionou "SnackBar" — convenção do projeto pra esse role é toastification. Comportamento equivalente: aparece no bottom, auto-dismiss, mensagem do failure. Se o user preferir o `SnackBar` material puro, ajustar depois — toast é o padrão atual em `expense_screen.dart`, `settings_screen.dart`, etc.

4. **Notifier não invalida outros providers.**
   `NotificationsNotifier` é `keepAlive: false` (sem `keepAlive: true` no `@Riverpod()`). Nenhum outro provider depende dele. Sem `ref.invalidate(...)` cross-feature. Se uma futura feature ler notifications, ela invalida quando precisar.

5. **Limpeza local sem refetch é segura.**
   Backend retorna 204 — sucesso é binário. Se eventualmente houver lag e mais notificações entrarem entre o user confirmar e o delete chegar, esses items ficam no servidor mas somem na UI até o próximo `refresh()` (pull-to-refresh). Trade-off aceitável.

6. **Threshold `> 10` é hardcoded.**
   Não vira const pública nem entra em `presentation/constants/`. Se virar configurável, promove depois — YAGNI.

---

## Testes

### `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart`

Adicionar `group('deleteAll')`:

- `'sends DELETE without body and returns Right on 2xx'` — verifica `_httpClient.delete` chamado com `Requests('/api/v1/notifications')` (sem body), retorna `Right`.
- `'returns Left with FailureResponse on backend error'` — `_httpClient.delete` retorna `Left(map)`, datasource retorna `Left(FailureResponse.fromJson(map))`.

### `test/src/data/repositories/notification_repository_test.dart`

Adicionar `group('deleteAll')`:

- `'returns Right when datasource succeeds'`
- `'returns Left NetworkFailure on network error'`
- `'returns Left ServerFailure on server error'`
- `'returns Left NotFoundFailure on not found'`
- `'returns Left ValidationFailure on unknown code'`

### `test/src/presentation/providers/notifications_notifier_test.dart`

Adicionar `group('deleteAll')`:

- `'clears items, groups and nextCursor on success'` — build com items + cursor → call `deleteAll` (mock retorna `Right(null)`) → state vazio.
- `'sets deleteAllFailure without clearing items on failure'` — build com items → `deleteAll` retorna `Left(NetworkFailure)` → items intactos, `deleteAllFailure` setado.
- `'no-op when already deleting'` — second call durante a primeira retorna sem disparar repo.
- `'isDeletingAll toggles true → false'` — observable via container listener (opcional, depende do quanto cobre os outros casos).

Sem widget test para o botão/dialog (projeto não tem widget tests para outros widgets equivalentes — segue convenção).
