# Tasks: notifications-delete-all

## domain/

- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — adicionar `Future<Either<Failure, void>> deleteAll()`

## infrastructure/

- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — adicionar `deleteAll()` à interface + impl: `_httpClient.delete(parameter: Requests(EndpointKey.notifications.path))`; `response.either(FailureResponse.fromJson, (_) {})`

## data/

- [x] `lib/src/data/repositories/notification_repository.dart` — adicionar `deleteAll()` forward + mapping via `FailureResponseExtension.toFailure()`

## presentation/

- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` — adicionar campos `isDeletingAll` (bool, default false) e `deleteAllFailure` (Failure?); `copyWith` com `clearDeleteAllFailure`; atualizar `props`
- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart` — adicionar `Future<void> deleteAll()`: guarda concorrência; on success limpa `items`/`groups`/`nextCursor`; on failure seta `deleteAllFailure`
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_delete_all_button_widget.dart` (NOVO) — `IconButtonWidget` 36×36, `iconSize: 18`, `Icons.delete_sweep_outlined`
- [x] `lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — `ref.listen` reagindo a `deleteAllFailure` com `showToastWidget(type: .failure)`; `AppBarWidget.actions` condicional `items.length > 10` mostrando `NotificationsDeleteAllButtonWidget` que abre `showConfirmDialog` e dispara `notifier.deleteAll()`

## main/providers/

- [x] (nenhuma mudança — providers já existem)

## test/

- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` (ESTENDER) — group `deleteAll`: DELETE no path `/api/v1/notifications` sem body retorna Right; erro HTTP retorna Left com FailureResponse correto
- [x] `test/src/data/repositories/notification_repository_test.dart` (ESTENDER) — group `deleteAll`: success → Right; cada code de `FailureResponse` mapeia para o `Failure` correto (NetworkFailure, ServerFailure, NotFoundFailure, ValidationFailure)
- [x] `test/src/presentation/providers/notifications_notifier_test.dart` (ESTENDER) — group `deleteAll`: success limpa items/groups/nextCursor; failure mantém items e seta `deleteAllFailure`; segunda chamada concorrente é no-op

## Pré-condições (já satisfeitas)

- `IHttpClient.delete({required Requests parameter})` existe
- `EndpointKey.notifications` existe
- `FailureResponseExtension.toFailure()` existe
- `INotificationRepository`, `NotificationRepository`, `RemoteNotificationDataSource` existem (Spec `notifications-list`)
- `showConfirmDialog` + `ConfirmDialogWidget` existem em `presentation/widgets/dialog/`
- `showToastWidget` existe em `presentation/widgets/toast_widget.dart`
- `IconButtonWidget` existe em `presentation/widgets/buttons/`
- `AppBarWidget.actions` aceita `List<Widget>?`
- `MockNotificationRepository`, `MockRemoteNotificationDataSource`, `MockHttpClient`, `MockMessagingClient` em `test/mocks/mocks.dart`
- `notificationRepositoryProvider`, `remoteNotificationDataSourceProvider` existem em `main/providers/`
- `NotificationsScreen`, `NotificationsNotifier`, `NotificationsState`, `NotificationsEmptyWidget` existem (Spec `notifications-list`)

## Verificação

- [x] `flutter analyze` — zero issues nos arquivos tocados (warning pré-existente em `recent_expenses_notifier_test.dart` não relacionado)
- [x] `flutter test` — verde (597 testes, 38 nas suítes tocadas)
- [x] Smoke: `flutter run`, abrir `/notifications` com `> 10` itens → tocar botão → dialog aparece → "Excluir" → lista esvazia → empty state → botão some
- [x] Smoke negativo: simular erro → toast aparece → lista permanece intacta
- [x] `NotificationsScreen` não importa `IRemoteNotificationDataSource`, `NotificationsResponse`, nem nada de `infrastructure/`
