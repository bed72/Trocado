# Proposal: notification-lifecycle-via-repository

## Intenção

Refatorar `NotificationLifecycle` (`lib/src/main/providers/notification_lifecycle_provider.dart`) para que ele **não** acesse `IMessagingClient` diretamente. O sinal de rotação de token (`onTokenRefresh`) passa a ser exposto através do `IRemoteNotificationDataSource` e do `INotificationRepository` como `Stream<void> get onTokenRefreshed`. O notifier global passa a depender exclusivamente do repositório.

## Motivação

Hoje o notifier viola a regra de dependência da Clean Architecture do projeto:

```dart
// notification_lifecycle_provider.dart:14
final messaging = ref.watch(messagingClientProvider);   // ❌ presentation → infrastructure
final repository = ref.watch(notificationRepositoryProvider); // ✅ presentation → domain
```

CLAUDE.md é explícito: `presentation` só depende de `domain`. O fluxo canônico é `Notifier → Repository → DataSource → Client`. Pular do notifier direto pro `IMessagingClient` (infraestrutura) fura camadas. O fato do notifier morar em `main/providers/` não muda o pecado — `main/providers/` é pra **wiring** (instanciar concretos), não pra comportamento com `listen`/`onDispose`/side effect.

Resultado prático após o refactor: o único arquivo do app que conhece `IMessagingClient` continua sendo `RemoteNotificationDataSource` (a interface já vive bem ali, fazendo `getToken()` + `platform` pro `registerToken`/`revokeToken`). O notifier vira um cliente puro do domínio.

## Camadas afetadas

- `infrastructure/datasources/remote/remote_notification_data_source.dart` — `IRemoteNotificationDataSource` ganha `Stream<void> get onTokenRefreshed`; impl delega a `_messagingClient.onTokenRefresh.map((_) {})`.
- `domain/repositories/interface_notification_repository.dart` — `INotificationRepository` ganha `Stream<void> get onTokenRefreshed`.
- `data/repositories/notification_repository.dart` — `NotificationRepository` delega a `_dataSource.onTokenRefreshed`.
- `main/providers/notification_lifecycle_provider.dart` — para de ler `messagingClientProvider`; lê só `notificationRepositoryProvider` e escuta `repository.onTokenRefreshed`.
- `test/src/infrastructure/datasources/remote/remote_notification_data_source_test.dart` — novo grupo cobrindo a delegação do stream.
- `test/src/data/repositories/notification_repository_test.dart` — novo grupo cobrindo a delegação do stream.
- `test/src/main/providers/notification_lifecycle_provider_test.dart` — reescreve mocks: passa a stubar `INotificationRepository.onTokenRefreshed` em vez de `IMessagingClient.onTokenRefresh`; deixa de overridear `messagingClientProvider`.

Nada novo em `presentation/`. Nenhuma feature de UI muda.

## Fora do escopo

- **Mover `NotificationLifecycle` pra outro lugar** (ex: `presentation/lifecycle/`). Cosmético. Continua em `main/providers/` porque é efeito colateral app-wide ancorado no boot, próximo do composition root. Se virar regra dura "main/providers/ é só wiring", aí entra spec própria.
- **Mudar `IMessagingClient.onTokenRefresh` pra `Stream<void>`**. O cliente segue expondo `Stream<String>` (o que o Firebase entrega) — o estreitamento pra `Stream<void>` acontece no boundary `infrastructure → data` (datasource), porque é ali que decidimos que o **domínio** não precisa do valor, só do gatilho.
- **Outras violações de camada do projeto** (notifiers acessando clients direto em outros lugares). Spec foca só no `NotificationLifecycle`. Varredura geral fica pra arch-review separada se aparecer.
- **Remover o `unawaited(...)` ou mudar a semântica fire-and-forget**. Comportamento atual (1 emit → 1 call, falhas silenciosas, slow call não bloqueia próximo emit) é preservado byte-a-byte.
- **Renomear `onTokenRefresh` (cliente) pra alinhar com `onTokenRefreshed` (domain/data)**. Nomes diferentes de propósito: o cliente espelha o nome do Firebase (`FirebaseMessaging.onTokenRefresh`); o domain usa particípio passado (`onTokenRefreshed`) pra deixar claro que é um sinal de "evento ocorrido" sem carregar valor.

## Decisões de design

1. **Estreitar pra `Stream<void>` no boundary do datasource, não no repositório.**
   Alternativa rejeitada: datasource expõe `Stream<String>`, repositório mapeia pra `Stream<void>`. Motivo da rejeição: o `String` é apenas um detalhe de transporte (o token); o domínio nunca usa esse valor (`registerToken()` busca o token internamente via `IMessagingClient.getToken()`). Estreitar mais cedo deixa a interface do repositório honesta sobre o que o domínio realmente precisa: "houve rotação", não "o novo token é X". Repositório vira delegação trivial — `dataSource.onTokenRefreshed` direto.

2. **Tipo `Stream<void>` em vez de `Stream<()>` ou `Stream<bool>` ou enum-de-evento.**
   `Stream<void>` é o idioma Dart pra "stream de eventos sem payload". `null`/`()` em testes é o sinal canônico. Sealed class de evento (`TokenRefreshedEvent`) seria overengineering — não há outros eventos pra agrupar nem variantes.

3. **Repositório vira delegação pura (`=>` direto).**
   `Stream<void> get onTokenRefreshed => _dataSource.onTokenRefreshed;` Sem `try-catch`, sem transformação, sem failure (não há `Either` aqui — é um stream de eventos, não uma operação requisição/resposta). Failures de I/O do `registerToken()` continuam canalizadas via `Future<Either<Failure, void>>` no método existente.

4. **Mocks de teste passam a stubar `INotificationRepository.onTokenRefreshed`.**
   Test do notifier deixa de importar `IMessagingClient`. `MockMessagingClient` continua existindo em `test/mocks/mocks.dart` (é usado em outros testes), mas o `notification_lifecycle_provider_test.dart` não toca mais nele. `MockNotificationRepository` já existe — só ganha um `when(() => repository.onTokenRefreshed)` no `setUp`.

5. **Comportamento observável é zero-delta.**
   O notifier continua: (a) atachando 1 listener no boot via kick em `main.dart`; (b) chamando `registerToken()` 1 vez por emit; (c) `unawaited`; (d) cancelando subscription no `ref.onDispose`. Os 5 cenários da spec `fcm-token-on-refresh` (que vive arquivada) continuam passando — só a fonte do stream muda (`messaging.onTokenRefresh` → `repository.onTokenRefreshed`).

6. **`map((_) {})` no datasource em vez de `asyncMap` ou similar.**
   Transformação síncrona, 1-pra-1, sem alocar futures. Stream original do Firebase é broadcast; o mapeado herda o comportamento. Sem buffering, sem replay.

7. **Continua sendo `@Riverpod(keepAlive: true)`.**
   Mesma justificativa da spec original: provider é puro side effect (retorna `void`), kept-alive até o app morrer, materializado uma vez via `container.read` no `main.dart`. Nada disso muda.
