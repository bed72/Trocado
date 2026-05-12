# Tasks: notifications-list

## domain/

- [x] `lib/src/domain/enums/notification/notification_type_enum.dart` (NOVO) — enum com `sharedExpenseCreated`, `budgetEightyPercent`, `unknown` + factory `fromString`
- [x] `lib/src/domain/models/notification/notification_model.dart` (NOVO) — `id`, `type`, `title`, `description`, `link`, `createdAt`; `copyWith`; Equatable
- [x] `lib/src/domain/models/notification/notifications_page_model.dart` (NOVO) — `nextCursor`, `previousCursor`, `notifications`; `copyWith`; Equatable
- [x] `lib/src/domain/repositories/interface_notification_repository.dart` — adicionar `Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor})`

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar `notifications('/api/v1/notifications')`
- [x] `lib/src/infrastructure/clients/http/responses/notification/notification_response.dart` (NOVO) — `id`, `type`, `title`, `description`, `link` (nullable), `createdAt`; `fromJson`
- [x] `lib/src/infrastructure/clients/http/responses/notification/notifications_response.dart` (NOVO) — `next`, `previous`, `notifications`; `fromJson` (parse de `results: List`)
- [x] `lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart` — adicionar `findAll({String? cursor})` à interface + impl: monta path com/sem cursor; `_httpClient.get(parameter: Requests(path))`; `response.either(FailureResponse.fromJson, NotificationsResponse.fromJson)`

## data/

- [x] `lib/src/data/extensions/notification_response_extension.dart` (NOVO) — `NotificationResponseExtension.toModel()` + `NotificationsResponseExtension.toPageModel()` com `_cursorFrom(url)` via `Uri.parse(...).queryParameters['cursor']`
- [x] `lib/src/data/repositories/notification_repository.dart` — adicionar `findAll({String? cursor})` forward + mapping `FailureResponse → Failure` e `NotificationsResponse → NotificationsPageModel`

## presentation/

- [x] `lib/src/presentation/widgets/notification/notification_type_visual_extension.dart` (NOVO) — extension em `NotificationTypeEnum`: `IconData get icon`, `Color get color`, `String get label`. Fallback `unknown` com ícone genérico
- [x] `lib/src/presentation/ui/notifications/data/notification_item_presentation_data.dart` (NOVO) — `notification`, `icon`, `color`, `typeLabel`, `formattedTime`; Equatable
- [x] `lib/src/presentation/ui/notifications/data/notification_group_presentation_data.dart` (NOVO) — `header`, `notifications`; Equatable
- [x] `lib/src/presentation/ui/notifications/data/notification_groups_builder.dart` (NOVO) — `buildNotificationGroups(items, {now})` espelhando `buildExpenseGroups` (agrupa por `createdAt`, labels pt_BR)
- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_state.dart` (NOVO) — `items`, `nextCursor`, `isLoadingMore`, `loadMoreFailure`; `copyWith` com `clearNextCursor`/`clearLoadMoreFailure`; Equatable
- [x] `lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart` (NOVO) — `@Riverpod(keepAlive: true)` `AsyncNotifier<NotificationsState>`; `build()` async chama `_loadFirstPage`; `refresh()`, `loadMore()`, `_toItem(NotificationModel)` resolve visual via extension + `DateFormat('HH:mm', 'pt_BR')`
- [x] `lib/src/presentation/ui/notifications/widgets/notification_card_widget.dart` (NOVO) — ícone colorido + título + descrição + hora
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_date_header_widget.dart` (NOVO) — header de grupo (mesmo estilo do `ExpensesDateHeaderWidget`)
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_list_widget.dart` (NOVO) — `SliverMainAxisGroup` com headers + items (`BounceWidget.withOnPress` com `onPress: () {}`) + tail
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_loading_widget.dart` (NOVO) — espelho
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_empty_widget.dart` (NOVO) — ícone + "Nenhuma notificação ainda"
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_failure_widget.dart` (NOVO) — ícone + texto + botão tentar de novo (`onRetry`)
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_load_more_loading_widget.dart` (NOVO) — spinner pequeno
- [x] `lib/src/presentation/ui/notifications/widgets/notifications_load_more_failure_widget.dart` (NOVO) — mini-botão tentar de novo
- [x] `lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — converter para `StatefulWidget`, `ScrollController` com listener no threshold 200px chamando `notifier.loadMore`, `Consumer` interno, `RefreshIndicator` chamando `notifier.refresh`, `CustomScrollView` com slivers e `switch (state)` igual ao `ExpensesScreen`

## main/providers/

- [x] `dart run build_runner build --delete-conflicting-outputs` (apenas regen de hashes)

## test/

- [x] `test/src/domain/enums/notification/notification_type_enum_test.dart` (NOVO) — `fromString` known + unknown fallback
- [x] `test/src/infrastructure/responses/notification_response_test.dart` (NOVO) — `fromJson` todos os campos, `link` null aceito
- [x] `test/src/infrastructure/responses/notifications_response_test.dart` (NOVO) — `fromJson` com cursors populados e null; `results` vazio e populado
- [x] `test/src/data/extensions/notification_response_extension_test.dart` (NOVO) — `toModel`; `toPageModel`; cursor extraído via `Uri`; URL sem `cursor` → null; URL null → null
- [x] `test/src/data/repositories/notification_repository_test.dart` (ESTENDER) — group `findAll`: success retorna `Right(NotificationsPageModel)`; cada code de `FailureResponse` mapeia para o `Failure` correto
- [x] `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` (ESTENDER) — group `findAll`: GET sem cursor (path `/api/v1/notifications`); GET com cursor (path `/api/v1/notifications?cursor=abc`); erro HTTP retorna Left
- [x] `test/src/presentation/ui/notifications/data/notification_groups_builder_test.dart` (NOVO) — empty → []; só hoje → 1 grupo "Hoje"; ontem → "Ontem"; < 7d → weekday + dia/mês; > 7d → mês/ano; 2 dias diferentes → 2 grupos
- [x] `test/src/presentation/providers/notifications_notifier_test.dart` (NOVO) — build success; build error; loadMore success (append items); loadMore com cursor null (no-op); loadMore concorrente (segundo call no-op); refresh recarrega primeira página

## Pré-condições (já satisfeitas)

- `IHttpClient.get({required Requests parameter})` existe
- `EndpointKey` enum + interceptor de auth existem
- `INotificationRepository`, `NotificationRepository`, `RemoteNotificationDataSource` existem (Specs 1+4)
- `MockNotificationRepository`, `MockRemoteNotificationDataSource`, `MockHttpClient`, `MockMessagingClient` em `test/mocks/mocks.dart`
- `notificationRepositoryProvider`, `remoteNotificationDataSourceProvider` existem em `main/providers/`
- `NotificationsScreen` + `NotificationsLocation` existem (Placeholder)

## Verificação

- [x] `flutter analyze` — zero issues
- [x] `flutter test` — verde
- [x] Tela renderiza sem erro (smoke: `flutter run`, abrir `/notifications`)
- [x] `NotificationsScreen` não importa `NotificationTypeEnum`, `NotificationTypeVisualExtension`, `NotificationModel`, `INotificationRepository`, nem nada de `infrastructure/`
