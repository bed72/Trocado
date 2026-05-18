# Proposal: notifications-delete-all

## Intenção

Adicionar ação "excluir todas as notificações" à `NotificationsScreen`: botão na top bar (`actions:` do `AppBarWidget`) que abre dialog de confirmação. Confirmar dispara `DELETE /api/v1/notifications`. Sucesso limpa a lista localmente; falha mostra toast de erro.

## Motivação

Após a spec `notifications-list`, o user consegue ler — mas não tem como esvaziar o histórico em massa. Conforme o volume cresce, dar uma saída de "limpar tudo" é UX mínima esperada antes de pensar em ações granulares (delete por item, mark-as-read, etc.).

Backend já entrega o endpoint (curl confirmado em 2026-05-13). Cliente só consome.

## Camadas afetadas

- `domain/repositories/` — `INotificationRepository.deleteAll`.
- `infrastructure/datasources/remote/` — `IRemoteNotificationDataSource.deleteAll`.
- `data/repositories/` — `NotificationRepository.deleteAll`.
- `presentation/ui/notifications/notifiers/` — `NotificationsState` + `NotificationsNotifier.deleteAll`.
- `presentation/ui/notifications/widgets/` — novo `notifications_delete_all_button_widget.dart`.
- `presentation/ui/notifications/screens/` — wiring do botão, dialog, listen pro toast de erro.

`main/providers/` não muda — providers já existem. Sem novo `EndpointKey` (reusa `notifications`). Sem mudança em response/extension (DELETE retorna 204, sem corpo).

## Fora do escopo

- Delete por item.
- Mark-as-read / unread state.
- Undo / soft-delete client-side.
- Animação de saída da lista (fade-out per row). Limpeza é instantânea via `state.items = []`.
- Empty state diferente pós-delete — reusa `NotificationsEmptyWidget` existente.
- Restaurar notificações do servidor caso o user desfaça — não há fluxo de undo.

## Decisões de design

1. **Botão visível somente quando `state.items.length > 10`.**
   Decisão do user. Abaixo desse threshold, esconder pra não poluir a top bar quando o volume é pequeno. Avaliado contra "sempre visível" e "só quando tem qualquer item" — `> 10` é o ponto onde o user já tem algum acúmulo que justifica limpar tudo.

2. **Pós-sucesso: limpar `state.items` localmente.**
   Sem refetch, sem `ref.invalidate`. O backend retorna 204 sem corpo — confiamos no sucesso e refletimos zerando `items`, `groups` e `nextCursor` no state. `previousCursor` também limpa por consistência. UX instantânea, zero round-trip extra.

3. **Erro: toast via `showToastWidget(type: .failure)` na screen.**
   O user chamou de "SnackBar"; a convenção do projeto pra esse role é `showToastWidget` (toastification) — usado em `expense_screen.dart`. State expõe `Failure? deleteAllFailure`; screen reage via `ref.listen` na transição `null → Failure`, mostra o toast e o notifier limpa a flag em seguida. Lista permanece intacta no erro.

4. **`isDeletingAll` no state pra impedir taps duplicados.**
   Espelha o padrão `isDeleting` do `ExpenseState`. Enquanto `true`, `deleteAll()` é no-op e o botão fica desabilitado (passa `onPress` no-op ou esconde). Sem indicador de loading no botão — operação é rápida o suficiente; o dialog já fecha antes de a request voltar.

5. **Dialog: `showConfirmDialog` existente do projeto.**
   `lib/src/presentation/widgets/dialog/confirm_dialog_widget.dart` já tem a API exata: `title`, `description`, `confirmLabel`, `denyLabel`. Reuso direto — labels: `'Excluir notificações'`, `'Esta ação não pode ser desfeita.'`, `'Excluir'`, `'Cancelar'`.

6. **Botão segue o padrão visual de `ExpensesFilterButtonWidget`.**
   `IconButtonWidget` com `width: 36`, `height: 36`, `iconSize: 18`. Único diff: ícone `Icons.delete_sweep_outlined`. Novo widget `NotificationsDeleteAllButtonWidget` em `presentation/ui/notifications/widgets/` (não promove pra `presentation/widgets/notification/` porque só esta feature consome).

7. **Datasource sem parâmetros (não tem cursor, não tem body).**
   `Future<Either<FailureResponse, void>> deleteAll()` na interface. Implementação chama `_httpClient.delete(parameter: Requests(EndpointKey.notifications.path))` e mapeia `response.either(FailureResponse.fromJson, (_) {})`. Mesmo padrão de `revokeToken`/`registerToken` na ramificação Right-void.

8. **Repository retorna `Either<Failure, void>`.**
   Já é convenção do projeto pra operações sem retorno útil (`registerToken`, `revokeToken`). Não usar `Unit` — não existe no projeto.

9. **Sem MVI/Intent — método público no notifier.**
   `NotificationsNotifier` hoje não tem `dispatch`/Intent (é AsyncNotifier sem form). Mantém o padrão atual: screen chama `notifier.deleteAll()` direto. MVI é a regra pra formulários e telas com múltiplas interações de input; aqui é uma única ação imperativa.
