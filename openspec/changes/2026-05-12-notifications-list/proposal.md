# Proposal: notifications-list

## Intenção

Substituir o `Placeholder()` da `NotificationsScreen` por uma listagem paginada de notificações vinda de `GET /api/v1/notifications`. Espelhar 100% o padrão já existente da listagem de despesas (`ExpensesScreen` + `ExpensesNotifier`): cursor pagination, agrupamento por data, `RefreshIndicator`, `loadMore` por scroll.

## Motivação

Trilha FCM (Specs 1-4) ligou o envio/recebimento e o ciclo de vida do token. Faltava a tela onde o user de fato **lê** o que chegou. O backend já entrega a lista paginada (curl confirmado em 2026-05-12); precisamos só consumir.

Reusar o padrão de expenses garante consistência UX (mesmo agrupamento por data, mesmo comportamento de load-more, mesma RefreshIndicator) e zero invenção arquitetural — todo o pipeline já está validado em produção.

## Camadas afetadas

- `domain/enums/notification/` — `NotificationTypeEnum`.
- `domain/models/notification/` — `NotificationModel`, `NotificationsPageModel`.
- `domain/repositories/` — `INotificationRepository.findAll`.
- `infrastructure/clients/http/` — `EndpointKey.notifications` + responses + datasource `findAll`.
- `data/extensions/` — `NotificationResponseExtension` (toModel + toPageModel + cursor extraction).
- `data/repositories/` — `NotificationRepository.findAll`.
- `presentation/widgets/notification/` — `NotificationTypeVisualExtension`.
- `presentation/ui/notifications/` — `notifiers/`, `data/`, `widgets/`, `screens/` (mirror do `expenses/`).

`main/providers/` não muda — providers já existem.

## Fora do escopo

- Filtros (tipo, período).
- Tap no card / deep link via `link` — vira spec dedicada usando `/deep-link`.
- Read/unread state.
- Mark-all-as-read, ações bulk.
- Push notification em foreground/background (handling) — só listagem.
- Empty state com CTA — só ícone + texto.
- Per-tipo cores muito específicas: apenas 3 visuais (sharedExpenseCreated, budgetEightyPercent, unknown). Outros tipos do backend caem no fallback `unknown`.

## Decisões de design

1. **Espelhar 100% o padrão de expenses.**
   `NotificationsState`, `NotificationsNotifier`, `notification_groups_builder`, `notifications_list_widget`, etc. existem como contrapartes diretas dos arquivos de expenses. Diferenças: sem filter/chips/search/filter-button. Tap é no-op.

2. **`NotificationTypeEnum` com fallback `unknown` para forward-compat.**
   Backend pode adicionar tipos. `fromString` retorna `unknown` pra strings que não match — visual cai em ícone genérico + cor neutra. Cliente nunca quebra por enum desconhecido.

3. **`link` preservado no `NotificationModel` mesmo sem uso.**
   Custo zero. Quando a spec de deep link rodar, o campo já está. Tipo `String?` porque backend pode entregar `null` em notificações sem ação.

4. **`createdAt` ISO 8601 → `int` milliseconds no model.**
   Padrão do projeto (mesmo que `ExpenseModel.createdAt`). Conversão em `NotificationResponseExtension.toModel()`.

5. **`NotificationItemPresentationData` dentro do feature folder.**
   `presentation/ui/notifications/data/notification_item_presentation_data.dart`. Não vai pra `presentation/data/` raiz porque (por enquanto) só esta feature consome. Promove se aparecer recent_notifications no Home.

6. **Visual extension em `presentation/widgets/notification/`.**
   Espelha `expense_category_visual_extension`. Mapeia `NotificationTypeEnum → (icon, color, label)`. Resolvido no notifier dentro de `_toItem`, screen não conhece o enum.

7. **`AsyncNotifier` com `keepAlive: true`.**
   Estado sobrevive a navegações dentro do app (user abre notificação → volta — não recarrega tudo). Mesma decisão de expenses.

8. **Sem search debounce** (não há search nesta spec).

9. **`refresh()` recarrega a primeira página.**
   `RefreshIndicator` chama `notifier.refresh()`. Reinicia state (cursor null, items vazio, depois `_loadFirstPage`).

10. **Cursor extraído da URL `next`/`previous`.**
    `Uri.parse(url).queryParameters['cursor']` — mesma helper de `ExpensesResponseExtension._cursorFrom`. Repositório nunca passa URL completa adiante; sempre só o cursor.
