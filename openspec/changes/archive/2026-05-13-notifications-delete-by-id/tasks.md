# Tasks: notifications-delete-by-id

## domain/

- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — adicionar `Future<Either<Failure, void>> deleteById({required int id})`

## infrastructure/

- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — adicionar `deleteById({required int id})` à interface + impl: `_httpClient.delete(parameter: Requests('${EndpointKey.notifications.path}/$id'))`; `response.either(FailureResponse.fromJson, (_) {})`

## data/

- [x] `lib/src/data/repositories/notification_repository.dart` — adicionar `deleteById({required int id})` forward + mapping via `FailureResponseExtension.toFailure()`

## presentation/

- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` — adicionar campo `deleteFailure` (`Failure?`); `copyWith` com `clearDeleteFailure`; atualizar `props`
- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart` — adicionar `Future<void> deleteById(int id)`: captura `originalItem` + `originalIndex`; remove optimistic + rebuild groups; chama repo; em falha reinsere com `clamp` + seta `deleteFailure`
- [x] `lib/src/presentation/ui/notifications/widgets/notification_dismiss_background_widget.dart` (NOVO) — `Container` `color: context.colors.error`, `alignment: centerRight`, `Icons.delete_outline` em `context.colors.onError`
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_list_widget.dart` — adicionar `ValueChanged<int> onDelete` no construtor; envolver `NotificationCardWidget` em `Dismissible` (key, direction, background, confirmDismiss → showConfirmDialog, onDismissed → onDelete); remover `key` do `NotificationCardWidget`
- [x] `lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — passar `onDelete: notifier.deleteById` pro `NotificationsListWidget`; estender o `ref.listen` pra também reagir a `deleteFailure` com `showToastWidget(type: .failure)`

## main/providers/

- [x] (nenhuma mudança — providers já existem)

## test/

- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` (ESTENDER) — group `deleteById`: DELETE no path `/api/v1/notifications/{id}` sem body retorna Right; erro HTTP retorna Left com FailureResponse correto
- [x] `test/src/data/repositories/notification_repository_test.dart` (ESTENDER) — group `deleteById`: success → Right; cada code de `FailureResponse` mapeia pro `Failure` correto (NetworkFailure, ServerFailure, NotFoundFailure, ValidationFailure); `verify` que `id` é propagado ao datasource
- [x] `test/src/presentation/providers/notifications_notifier_test.dart` (ESTENDER) — group `deleteById`: success remove item; falha reinsere item no `originalIndex` e seta `deleteFailure`; no-op quando id não existe nos items

## Pré-condições (já satisfeitas)

- `IHttpClient.delete({required Requests parameter})` existe
- `EndpointKey.notifications` existe
- `FailureResponseExtension.toFailure()` existe
- `INotificationRepository`, `NotificationRepository`, `RemoteNotificationDataSource` existem
- `showConfirmDialog` + `ConfirmDialogWidget` existem em `presentation/widgets/dialog/`
- `showToastWidget` existe em `presentation/widgets/toast_widget.dart`
- `context.colors.error` / `context.colors.onError` existem (já usados em `expenses_failure_widget.dart` etc.)
- `MockNotificationRepository`, `MockRemoteNotificationDataSource`, `MockHttpClient`, `MockMessagingClient` em `test/mocks/mocks.dart`
- `NotificationsScreen`, `NotificationsNotifier`, `NotificationsState`, `NotificationsListWidget`, `NotificationCardWidget`, `buildNotificationGroups` existem

## Verificação

- [x] `flutter analyze` — zero issues nos arquivos tocados (warning pré-existente em `recent_expenses_notifier_test.dart` não relacionado)
- [x] `flutter test` — verde (608 testes, 11 novos nas suítes tocadas)
- [ ] Smoke: `flutter run`, abrir `/notifications`, swipe RTL num item → dialog aparece → "Excluir" → item some imediatamente
- [ ] Smoke confirm-cancel: swipe → "Cancelar" → item volta com animação
- [ ] Smoke negativo: simular erro de rede → item some momentaneamente → reinsere → toast aparece
- [x] `NotificationsScreen`/`NotificationsListWidget` não importam nada de `infrastructure/`
