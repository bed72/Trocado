# Design: notifications-list

## Contrato da API

**Endpoint:** `GET /api/v1/notifications`

**Auth:** `Authorization: Bearer <access>` (injetado por `AuthenticationInterceptor`).

**Query:**
- `cursor` (opcional) — omitido na primeira página.

**Response 200:**
```json
{
  "next": "http://api/?cursor=cD00ODY%3D",
  "previous": "http://api/?cursor=cj0xJnA9NDg3",
  "results": [
    {
      "id": 42,
      "type": "shared_expense_created",
      "title": "Nova despesa do casal",
      "description": "Gabriel registrou R$ 85,50 em Mercado.",
      "link": "/expenses/17",
      "created_at": "2026-05-11T14:30:00Z"
    }
  ]
}
```

**Response 4xx/5xx:** `FailureResponse` padrão (`{ errors: [...] }`).

`next`/`previous` são URLs completas; o cliente extrai apenas o valor do query param `cursor`.

---

## Domain

### `NotificationTypeEnum`

`lib/src/domain/enums/notification/notification_type_enum.dart`:

```dart
enum NotificationTypeEnum {
  unknown,
  sharedExpenseCreated,
  budgetEightyPercent;

  factory NotificationTypeEnum.fromString(String value) => switch (value) {
    'shared_expense_created' => sharedExpenseCreated,
    'budget_eighty_percent'  => budgetEightyPercent,
    _                        => unknown,
  };
}
```

### `NotificationModel`

`lib/src/domain/models/notification/notification_model.dart`:

```dart
final class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String? link;
  final int createdAt;
  final NotificationTypeEnum type;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.link,
  });

  NotificationModel copyWith({ ... });

  @override
  List<Object?> get props => [id, type, title, description, link, createdAt];
}
```

### `NotificationsPageModel`

`lib/src/domain/models/notification/notifications_page_model.dart`:

```dart
final class NotificationsPageModel extends Equatable {
  final String? nextCursor;
  final String? previousCursor;
  final List<NotificationModel> notifications;

  const NotificationsPageModel({
    this.nextCursor,
    this.previousCursor,
    this.notifications = const [],
  });

  NotificationsPageModel copyWith({ ... });

  @override
  List<Object?> get props => [notifications, nextCursor, previousCursor];
}
```

### `INotificationRepository` — extensão

`lib/src/domain/repositories/interface_notification_repository.dart`:

```dart
abstract interface class INotificationRepository {
  Future<Either<Failure, void>> registerToken();
  Future<Either<Failure, void>> revokeToken();
  Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor});
}
```

---

## Infrastructure

### `EndpointKey`

`lib/src/infrastructure/clients/http/endpoint_key.dart` — adicionar:
```dart
notifications('/api/v1/notifications'),
```
Não público.

### Responses

`lib/src/infrastructure/clients/http/responses/notification/notification_response.dart`:

```dart
final class NotificationResponse {
  final int id;
  final String type;
  final String title;
  final String description;
  final String? link;
  final String createdAt;

  const NotificationResponse({ ... });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      NotificationResponse(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        link: json['link'] as String?,
        createdAt: json['created_at'] as String,
      );
}
```

`lib/src/infrastructure/clients/http/responses/notification/notifications_response.dart`:

```dart
final class NotificationsResponse {
  final String? next;
  final String? previous;
  final List<NotificationResponse> notifications;

  const NotificationsResponse({
    required this.notifications,
    this.next,
    this.previous,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsResponse(
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        notifications: (json['results'] as List)
            .map((item) => NotificationResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
```

### `IRemoteNotificationDataSource` — extensão

`lib/src/infrastructure/datasources/remote/remote_notification_data_source.dart`:

```dart
abstract interface class IRemoteNotificationDataSource {
  Future<Either<FailureResponse, void>> registerToken();
  Future<Either<FailureResponse, void>> revokeToken();
  Future<Either<FailureResponse, NotificationsResponse>> findAll({String? cursor});
}

// implementação:
@override
Future<Either<FailureResponse, NotificationsResponse>> findAll({
  String? cursor,
}) async {
  final path = cursor == null
      ? EndpointKey.notifications.path
      : '${EndpointKey.notifications.path}?cursor=$cursor';

  final response = await _httpClient.get(parameter: Requests(path));

  return response.either(
    FailureResponse.fromJson,
    NotificationsResponse.fromJson,
  );
}
```

Cursor já vem URL-encoded da API (`cD00ODY%3D`), então concatenar direto está correto. Se aparecer caso de cursor com `&` ou outros chars problemáticos, evoluir pra `Uri` builder — não é o caso hoje.

---

## Data

### Extension de mapping

`lib/src/data/extensions/notification_response_extension.dart`:

```dart
import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';
import 'package:trocado/src/domain/models/notification/notification_model.dart';
import 'package:trocado/src/domain/models/notification/notifications_page_model.dart';

import 'package:trocado/src/infrastructure/clients/http/responses/notification/notification_response.dart';
import 'package:trocado/src/infrastructure/clients/http/responses/notification/notifications_response.dart';

extension NotificationResponseExtension on NotificationResponse {
  NotificationModel toModel() => NotificationModel(
    id: id,
    title: title,
    description: description,
    link: link,
    type: NotificationTypeEnum.fromString(type),
    createdAt: DateTime.parse(createdAt).millisecondsSinceEpoch,
  );
}

extension NotificationsResponseExtension on NotificationsResponse {
  NotificationsPageModel toPageModel() => NotificationsPageModel(
    nextCursor: _cursorFrom(next),
    previousCursor: _cursorFrom(previous),
    notifications: notifications.map((item) => item.toModel()).toList(),
  );

  String? _cursorFrom(String? url) {
    if (url == null) return null;
    return Uri.parse(url).queryParameters['cursor'];
  }
}
```

### `NotificationRepository` — extensão

`lib/src/data/repositories/notification_repository.dart`:

```dart
@override
Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor}) async {
  final data = await _dataSource.findAll(cursor: cursor);

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.toPageModel(),
  );
}
```

---

## Presentation

### `NotificationTypeVisualExtension`

`lib/src/presentation/widgets/notification/notification_type_visual_extension.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/notification/notification_type_enum.dart';

extension NotificationTypeVisualExtension on NotificationTypeEnum {
  IconData get icon => switch (this) {
    NotificationTypeEnum.sharedExpenseCreated => Icons.shopping_cart_outlined,
    NotificationTypeEnum.budgetEightyPercent  => Icons.warning_amber_rounded,
    NotificationTypeEnum.unknown              => Icons.notifications_outlined,
  };

  Color get color => switch (this) {
    NotificationTypeEnum.sharedExpenseCreated => Colors.blueGrey,
    NotificationTypeEnum.budgetEightyPercent  => Colors.amber,
    NotificationTypeEnum.unknown              => Colors.grey,
  };

  String get label => switch (this) {
    NotificationTypeEnum.sharedExpenseCreated => 'Despesa do casal',
    NotificationTypeEnum.budgetEightyPercent  => 'Orçamento',
    NotificationTypeEnum.unknown              => 'Aviso',
  };
}
```

### View-model

`lib/src/presentation/ui/notifications/data/notification_item_presentation_data.dart`:

```dart
final class NotificationItemPresentationData extends Equatable {
  final IconData icon;
  final Color color;
  final String typeLabel;
  final String formattedTime;
  final NotificationModel notification;

  const NotificationItemPresentationData({
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.formattedTime,
    required this.notification,
  });

  @override
  List<Object?> get props => [notification, icon, color, typeLabel, formattedTime];
}
```

### `notification_group_presentation_data.dart`

`lib/src/presentation/ui/notifications/data/notification_group_presentation_data.dart`:

```dart
final class NotificationGroupPresentationData extends Equatable {
  final String header;
  final List<NotificationItemPresentationData> notifications;

  const NotificationGroupPresentationData({
    required this.header,
    required this.notifications,
  });

  @override
  List<Object?> get props => [header, notifications];
}
```

### `notification_groups_builder.dart`

`lib/src/presentation/ui/notifications/data/notification_groups_builder.dart` — espelho exato de `expense_groups_builder` com nomes adaptados. Headers `Hoje` / `Ontem` / `EEEE, dd MMM` / `MMMM y` em `pt_BR`. Agrupa por `createdAt` (não `date`).

### `NotificationsState`

`lib/src/presentation/ui/notifications/notifiers/notifications_state.dart`:

```dart
final class NotificationsState extends Equatable {
  final String? nextCursor;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;
  final List<NotificationItemPresentationData> items;

  const NotificationsState({
    this.nextCursor,
    this.loadMoreFailure,
    this.items = const [],
    this.isLoadingMore = false,
  });

  NotificationsState copyWith({
    String? nextCursor,
    bool? isLoadingMore,
    Failure? loadMoreFailure,
    List<NotificationItemPresentationData>? items,
    bool clearNextCursor = false,
    bool clearLoadMoreFailure = false,
  }) => ...;

  @override
  List<Object?> get props => [items, nextCursor, isLoadingMore, loadMoreFailure];
}
```

### `NotificationsNotifier`

`lib/src/presentation/ui/notifications/notifiers/notifications_notifier.dart`:

```dart
@Riverpod(keepAlive: true)
final class NotificationsNotifier extends _$NotificationsNotifier {
  late INotificationRepository _repository;

  @override
  Future<NotificationsState> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    return await _loadFirstPage();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));

    final data = await _repository.findAll(cursor: current.nextCursor);

    state = AsyncData(
      data.fold<NotificationsState>(
        (failure) => current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (page) => current.copyWith(
          isLoadingMore: false,
          clearLoadMoreFailure: true,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          items: [...current.items, ...page.notifications.map(_toItem)],
        ),
      ),
    );
  }

  Future<NotificationsState> _loadFirstPage() async {
    final data = await _repository.findAll();

    return data.fold(
      (failure) => throw failure,
      (page) => NotificationsState(
        nextCursor: page.nextCursor,
        items: page.notifications.map(_toItem).toList(),
      ),
    );
  }

  NotificationItemPresentationData _toItem(NotificationModel n) =>
      NotificationItemPresentationData(
        notification: n,
        icon: n.type.icon,
        color: n.type.color,
        typeLabel: n.type.label,
        formattedTime: DateFormat('HH:mm', 'pt_BR')
            .format(DateTime.fromMillisecondsSinceEpoch(n.createdAt)),
      );
}
```

Throw em failure do `_loadFirstPage` é intencional — converte em `AsyncError`, que a screen renderiza via `AsyncError() => failure widget`.

### Widgets

Diretório `lib/src/presentation/ui/notifications/widgets/` — espelho do `expenses/widgets/`:

- `notification_card_widget.dart` — visual do card individual (ícone colorido + título + descrição + hora).
- `notifications_date_header_widget.dart` — header de grupo "Hoje" / "Ontem" / etc.
- `notifications_list_widget.dart` — SliverMainAxisGroup com headers + items + tail (loading/failure de loadMore).
- `notifications_empty_widget.dart` — ícone + texto "Nenhuma notificação ainda".
- `notifications_failure_widget.dart` — ícone + texto + botão Tentar de novo.
- `notifications_loading_widget.dart` — spinner.
- `notifications_load_more_loading_widget.dart` — spinner no rodapé da lista.
- `notifications_load_more_failure_widget.dart` — mini-botão "Tentar de novo".

### Screen

`lib/src/presentation/ui/notifications/screens/notifications_screen.dart` — converte de `StatelessWidget` para `StatefulWidget` (espelho do `ExpensesScreen` sem search/filter). `ScrollController` chama `_onLoadMore = notifier.loadMore` no threshold 200px. `RefreshIndicator` chama `notifier.refresh`.

```dart
@override
Widget build(BuildContext context) => Consumer(
  builder: (_, ref, _) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    _onLoadMore = notifier.loadMore;

    return ScaffoldWidget(
      appBar: AppBarWidget(leading: const GoBackWidget()),
      child: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: .symmetric(horizontal: 16.0, vertical: 8.0),
                child: ScreenHeaderWidget(
                  title: 'Notificações',
                  description: 'Acompanhe os alertas e avisos da sua conta.',
                ),
              ),
            ),
            ..._contentSlivers(notifier, state),
          ],
        ),
      ),
    );
  },
);
```

`_contentSlivers` faz `switch (state)` em `AsyncLoading()`, `AsyncError()`, `AsyncData(empty)`, `AsyncData(items)` exatamente como `ExpensesScreen._contentSlivers`.

Tap no item: card é `BounceWidget.withOnPress` com `onPress: () {}` (no-op). Mantém affordance visual pra quando vier o deep-link.

---

## Estratégia de testes

| Arquivo | Mock em | Cobre |
|---|---|---|
| `notification_response_test.dart` (NOVO) | — | `fromJson` mapeia todos os campos; `link` null aceito |
| `notifications_response_test.dart` (NOVO) | — | `fromJson` com cursors populados e null, results vazio e populado |
| `notification_response_extension_test.dart` (NOVO) | — | `toModel` (type via enum, createdAt ISO→ms, link preservado); `toPageModel` (cursors extraídos via Uri.queryParameters); URL sem `cursor` → null |
| `notification_type_enum_test.dart` (NOVO) | — | `fromString` para cada known + qualquer string desconhecida → `unknown` |
| `notification_repository_test.dart` (ESTENDER) | `IRemoteNotificationDataSource` | group `findAll`: Right(page) success; Left mapeado por cada FailureResponse code (network/server/notFound/validation) |
| `remote_notification_data_source_test.dart` (ESTENDER) | `IHttpClient` (`get`) | group `findAll`: GET sem cursor (path puro), GET com cursor (path com query), erro HTTP retorna Left |
| `notification_groups_builder_test.dart` (NOVO) | — | empty → []; 1 item hoje → header "Hoje"; ontem → "Ontem"; < 7d → weekday `pt_BR`; > 7d → mês `pt_BR`; transição entre dias gera 2 grupos |
| `notifications_notifier_test.dart` (NOVO) | `INotificationRepository` | build success com page; build error → AsyncError; loadMore success (append); loadMore com cursor null (no-op); loadMore concorrente (segunda chamada no-op); refresh recarrega primeira página |

Sem teste de widget — convenção do projeto (golden/widget tests não cobrem essa camada hoje, e os notifiers + builder já dão confiança suficiente sobre a lógica).

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Espelhar padrão de expenses 1:1 | Reescrever pagination genérica | Custo de extração não compensa hoje; expenses é a referência viva — bug em um se reflete no outro, fica mais fácil sincronizar |
| `NotificationTypeEnum` com `unknown` | Sem fallback (parsing strict) | Forward-compat: backend adiciona tipo e cliente não quebra |
| `NotificationItemPresentationData` em feature folder | `presentation/data/notification/...` shared | Por enquanto, só esta feature consome. Promove se aparecer recent_notifications no Home |
| `_loadFirstPage` throw em failure | Retornar state com flag de failure | AsyncError é o caminho idiomático do Riverpod; screen consome `AsyncError() => failure widget` |
| Cursor extraído de URL | Backend envia cursor cru | Backend padrão DRF/Django Rest Framework já dá URL completa; mesma extração que expenses |
| Cursor inserido na URL via concat | `Uri` builder | Cursor já vem URL-encoded; concat é o que expenses faz; sem mudança de regra entre features |
| Tap = no-op (BounceWidget sem ação) | Sem BounceWidget | Mantém affordance visual; spec de deep-link adiciona ação sem mexer no widget |
| Visual extension em `widgets/notification/` | Em `domain/enums/` direto | Visual é detalhe de apresentação, não de domínio (regra do CLAUDE.md) |
| Sem search/filter | Adicionar busca por título | Spec separada se aparecer demanda; padrão "entregar o cerne primeiro" |
