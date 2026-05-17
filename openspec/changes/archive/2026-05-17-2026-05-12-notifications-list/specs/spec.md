# Spec: notifications-list

## Requirements

### Requirement: Fetch paginated notifications list

The system SHALL expose `Future<Either<Failure, NotificationsPageModel>> findAll({String? cursor})` on `INotificationRepository`. The implementation SHALL call `GET /api/v1/notifications` (with optional `?cursor=<value>` query param) and map the response into the domain page model.

#### Scenario: first page without cursor

- **Given** `INotificationRepository.findAll()` is called without `cursor`
- **When** the request hits the HTTP client
- **Then** the request path is exactly `/api/v1/notifications`
- **And** the body of the request is null (GET)

#### Scenario: subsequent page with cursor

- **Given** `INotificationRepository.findAll(cursor: "abc")` is called
- **When** the request hits the HTTP client
- **Then** the request path is exactly `/api/v1/notifications?cursor=abc`

#### Scenario: backend error maps to Failure

- **Given** the HTTP client returns `Left(...)` with `FailureResponse`-shaped map (e.g. `code: "server_error"`)
- **When** `findAll` runs
- **Then** the repository returns `Left(ServerFailure())`

---

### Requirement: Map response to domain page model

The system SHALL convert `NotificationsResponse` into `NotificationsPageModel`, extracting `nextCursor` and `previousCursor` from the `cursor` query parameter of the `next`/`previous` URLs. Each `NotificationResponse` becomes a `NotificationModel` with `createdAt` parsed from ISO 8601 to milliseconds and `type` resolved through `NotificationTypeEnum.fromString`.

#### Scenario: cursor extracted from URL

- **Given** a `NotificationsResponse` with `next: "http://api/path?cursor=abc&page_size=10"`
- **When** `toPageModel()` is called
- **Then** the resulting `NotificationsPageModel.nextCursor` is `"abc"`

#### Scenario: null URL maps to null cursor

- **Given** a `NotificationsResponse` with `next: null`
- **When** `toPageModel()` is called
- **Then** the resulting `NotificationsPageModel.nextCursor` is `null`

#### Scenario: URL without cursor query param

- **Given** a `NotificationsResponse` with `next: "http://api/path"`
- **When** `toPageModel()` is called
- **Then** the resulting `NotificationsPageModel.nextCursor` is `null`

#### Scenario: createdAt parsed to milliseconds

- **Given** a `NotificationResponse` with `createdAt: "2026-05-11T14:30:00Z"`
- **When** `toModel()` is called
- **Then** the resulting `NotificationModel.createdAt` equals `DateTime.parse("2026-05-11T14:30:00Z").millisecondsSinceEpoch`

---

### Requirement: NotificationTypeEnum forward-compat

The system SHALL provide `NotificationTypeEnum.fromString(value)` that returns the matching enum value for known type strings, and `NotificationTypeEnum.unknown` for any unrecognized value. The client SHALL NOT throw on unrecognized types.

#### Scenario: known type strings

- **Given** the string `"shared_expense_created"`
- **When** `NotificationTypeEnum.fromString` is called
- **Then** it returns `NotificationTypeEnum.sharedExpenseCreated`

- **Given** the string `"budget_eighty_percent"`
- **When** `NotificationTypeEnum.fromString` is called
- **Then** it returns `NotificationTypeEnum.budgetEightyPercent`

#### Scenario: unknown type string

- **Given** any string not in the known set (e.g. `"random_new_type"`, `""`, `"SHARED_EXPENSE_CREATED"`)
- **When** `NotificationTypeEnum.fromString` is called
- **Then** it returns `NotificationTypeEnum.unknown`

---

### Requirement: AsyncNotifier paginates with cursor

The system SHALL expose `NotificationsNotifier` as an `AsyncNotifier<NotificationsState>` annotated with `@Riverpod(keepAlive: true)`. `build()` loads the first page. `loadMore()` appends the next page when triggered. `refresh()` reloads the first page from scratch.

#### Scenario: build loads first page

- **Given** `INotificationRepository.findAll()` returns `Right(NotificationsPageModel(...))` with 2 notifications
- **When** the provider is materialized
- **Then** `state.value.items` has 2 entries
- **And** `state.value.nextCursor` matches the page model's `nextCursor`

#### Scenario: build error becomes AsyncError

- **Given** `INotificationRepository.findAll()` returns `Left(NetworkFailure())`
- **When** the provider is materialized
- **Then** `state` is `AsyncError`
- **And** the error is a `NetworkFailure`

#### Scenario: loadMore appends new items

- **Given** a materialized state with 2 items and `nextCursor: "abc"`
- **And** `INotificationRepository.findAll(cursor: "abc")` returns `Right` with 2 more notifications and `nextCursor: null`
- **When** `loadMore()` is called
- **Then** `state.value.items` has 4 entries (in original order, new items appended)
- **And** `state.value.nextCursor` is `null`
- **And** `state.value.isLoadingMore` is `false`

#### Scenario: loadMore with null cursor is no-op

- **Given** a materialized state with `nextCursor: null`
- **When** `loadMore()` is called
- **Then** `INotificationRepository.findAll` is NOT invoked
- **And** `state.value.items` is unchanged

#### Scenario: concurrent loadMore is no-op

- **Given** a materialized state with `isLoadingMore: true`
- **When** `loadMore()` is called again
- **Then** `INotificationRepository.findAll` is invoked only the first time
- **And** the second call returns immediately without side effect

#### Scenario: refresh reloads first page

- **Given** a materialized state with 4 items (two pages loaded)
- **When** `refresh()` is called and the repository returns `Right` with 1 notification
- **Then** `state.value.items` has exactly 1 entry
- **And** `state.value.nextCursor` matches the new first page

---

### Requirement: Notifier produces presentation-ready items

The system SHALL convert each `NotificationModel` into a `NotificationItemPresentationData` inside the notifier, resolving the icon, color, and label from `NotificationTypeVisualExtension`, and formatting `createdAt` as `HH:mm` in `pt_BR` locale. The screen SHALL NOT read services or call extensions directly.

#### Scenario: presentation data assembled in notifier

- **Given** a `NotificationModel` with `type: budgetEightyPercent` and `createdAt: <ms for 14:30 local>`
- **When** the notifier produces the corresponding `NotificationItemPresentationData`
- **Then** the item's `icon`, `color`, `typeLabel` come from `NotificationTypeVisualExtension.budgetEightyPercent`
- **And** the item's `formattedTime` is `"14:30"` (assuming local timezone matches)

---

### Requirement: Date grouping mirrors expenses

The system SHALL group the items list by day using `buildNotificationGroups(items, {now})`. Headers SHALL follow the same labels as `buildExpenseGroups`: `Hoje`, `Ontem`, weekday + day/month (for days within the last 7), month + year (for older).

#### Scenario: empty list returns empty groups

- **Given** an empty list of items
- **When** `buildNotificationGroups` is called
- **Then** the result is an empty list

#### Scenario: today and yesterday produce two groups

- **Given** 2 items dated today and 1 item dated yesterday
- **When** `buildNotificationGroups(items, now: <today>)` is called
- **Then** the result has 2 groups
- **And** the first group has header `"Hoje"` with 2 items
- **And** the second group has header `"Ontem"` with 1 item

---

### Requirement: Screen renders empty/loading/error/list

The system SHALL render four distinct states on `NotificationsScreen`:

- `AsyncLoading` → loading widget;
- `AsyncError` → failure widget with a retry button calling `notifier.refresh()`;
- `AsyncData` with empty items → empty widget;
- `AsyncData` with items → list of grouped notifications with date headers and a `RefreshIndicator` that triggers `notifier.refresh()`.

The screen SHALL NOT call `IMessagingClient`, `INotificationRepository`, `NotificationTypeEnum`, or `NotificationTypeVisualExtension` directly — it only consumes `NotificationsState` via the notifier.

#### Scenario: screen imports

- **Given** the implementation of `NotificationsScreen`
- **When** its import list is inspected
- **Then** the only notification-related symbols imported are `notificationsProvider`, `NotificationsNotifier`, `NotificationsState`, `NotificationItemPresentationData`, `NotificationGroupPresentationData`, `buildNotificationGroups`, and widgets from `presentation/ui/notifications/widgets/`
- **And** it does NOT import `NotificationTypeEnum`, `NotificationTypeVisualExtension`, `NotificationModel`, `INotificationRepository`, or anything from `infrastructure/`

#### Scenario: pull-to-refresh triggers refresh

- **Given** a populated list state
- **When** the user pulls to refresh
- **Then** `NotificationsNotifier.refresh()` is invoked
- **And** the state transitions through `AsyncLoading` and back to `AsyncData` with the first page

#### Scenario: scroll near bottom triggers loadMore

- **Given** a populated list with `nextCursor != null`
- **When** the scroll position is within 200px of `maxScrollExtent`
- **Then** `NotificationsNotifier.loadMore()` is invoked exactly once per crossing of the threshold

#### Scenario: tap on item is a no-op

- **Given** any notification item rendered in the list
- **When** the item is tapped
- **Then** no navigation occurs
- **And** no state changes on the notifier
- **And** the `BounceWidget` still plays its press animation
