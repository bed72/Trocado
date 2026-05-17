# Proposal: fcm-token-registration

## Intenção

Registrar o token FCM do dispositivo no backend (`POST /api/v1/me/fcm-token`) sempre que a Splash confirmar que existe sessão válida. Operação totalmente transparente para o usuário — fire-and-forget, sem feedback de sucesso nem de falha.

## Motivação

Primeira spec da feature de notificações. Sem o token registrado no servidor, o backend não consegue endereçar push notifications a este dispositivo. A Splash é o ponto de entrada autenticado mais cedo no ciclo de vida do app, então faz sentido sincronizar o token aqui no caminho `authenticated`.

A responsabilidade *conceitual* de "registrar o token" não pertence à Splash — pertence a um componente reutilizável (`INotificationRepository`) que outras camadas (SignIn success, SignUp success, listener de `onTokenRefresh`) vão consumir em specs futuras. A Splash é apenas o *primeiro gatilho* a ser ligado.

`INotificationRepository` cobre o bounded context inteiro de notificações: começa com `registerToken` nesta spec e ganhará `list`/`delete`/`markAsRead` em specs subsequentes.

## Camadas afetadas

- `domain/repositories/` — `INotificationRepository` (interface, sem params).
- `infrastructure/clients/http/` — entrada nova no `EndpointKey`; `FcmTokenRequest`.
- `infrastructure/clients/messaging/` — extensão de `IMessagingClient` para expor `String get platform`; `getToken()` vira catch-all silencioso.
- `infrastructure/datasources/remote/` — `IRemoteNotificationDataSource` + implementação. **DataSource orquestra**: pega token via `IMessagingClient`, faz o POST.
- `data/repositories/` — `NotificationRepository` (pipeline puro, só mapeia `FailureResponse → Failure`).
- `main/providers/` — providers Riverpod para datasource (injeta `IMessagingClient`) e repositório.
- `presentation/ui/splash/notifiers/` — `SplashNotifier` ganha apenas `INotificationRepository`; dispara `unawaited(...)` no ramo `authenticated`.

## Fora do escopo

- Hook em SignIn / SignUp success.
- Listener de `FirebaseMessaging.onTokenRefresh`.
- Permissões iOS (`requestPermission`).
- Recebimento e handling de notificações (foreground, background, terminated).
- Tela ou preferências de notificação.
- Logout: remoção do token no servidor.
- Retry/backoff em caso de falha do registro.

## Decisões de design

1. **DataSource orquestra fetch + POST.**
   O `RemoteNotificationDataSource` injeta `IMessagingClient` ao lado do `IHttpClient`. Internamente: pega token, pega platform, monta o `FcmTokenRequest`, posta. A camada `data/repositories/` fica reduzida ao mínimo (mapeia `FailureResponse → Failure`), e a camada `presentation/` fica livre de qualquer detalhe de infraestrutura.

2. **Reusar `IMessagingClient` em vez de criar `IFcmTokenClient`.**
   Já existe um cliente que encapsula FCM. Estendemos com `String get platform` — mantém preocupações Firebase Messaging num só lugar e prepara terreno para `Stream<String> onTokenRefresh` em specs futuras.

3. **`MessagingClient.getToken()` catch-all silencioso.**
   Qualquer exceção do SDK Firebase (incluindo `FirebaseException`, `MissingPluginException`, etc.) vira `null`. Isso preserva a regra "único try-catch no Client" — o cliente é a fronteira, ninguém acima dele precisa de `try-catch`.

4. **Token `null` → `Right(null)` no DataSource.**
   `null` é estado esperado (iOS sem APNs ainda, Firebase inicializando, etc.). Não é falha — é "nada para registrar agora". Próximo gatilho cobre.

5. **Presentation sem imports de infraestrutura.**
   O `SplashNotifier` importa **apenas** de `domain/repositories/` e do composition root de providers. Sem `IMessagingClient`, sem `ILoggerClient`, sem `try-catch`. Respeita a regra dura `presentation → domain` do CLAUDE.md.

6. **`Either<Failure, void>` (não `Unit`).**
   Consistência com `logout`, `requestPasswordReset`, `confirmPasswordReset` e `checkSession`.

7. **Sem logging explícito.**
   `talker_dio_logger` (já configurado no Dio) cobre erros HTTP nos logs de dev. Falhas no FCM client são esperadas/silenciosas. Próximas specs podem reintroduzir logger se necessário (em camada apropriada).

8. **Plataforma: `"android"` / `"ios"` lowercase** — bate com o exemplo do curl.
