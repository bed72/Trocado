# Proposal: fcm-token-on-refresh

## Intenção

Reagir a rotações do token FCM em runtime registrando o novo token no backend automaticamente. `FirebaseMessaging.instance.onTokenRefresh` é um `Stream<String>` que dispara quando o Firebase rotaciona internamente o token, app é reinstalado, user limpa dados, restore em device novo, ou o token é invalidado por inatividade. Sem listener, qualquer push direcionado ao token antigo é perdido até o próximo cold start.

## Motivação

Spec 1 (`fcm-token-registration`) cobre o cold start com sessão válida. Spec 2 (`fcm-token-on-auth-success`) cobre o primeiro pós-auth. Faltam os eventos de rotação em runtime — sem isso, um token que rotaciona às 14h só registra de novo no próximo abrir-do-app.

Backend já está pronto: `POST /api/v1/me/fcm-token` é idempotente (UPSERT), aceita re-posts sem efeito colateral. Não precisa enviar o token anterior — cleanup é reativo via `UNREGISTERED` no envio de push (decisão do backend confirmada em 2026-05-12).

## Camadas afetadas

- `infrastructure/clients/messaging/` — `IMessagingClient` ganha `Stream<String> get onTokenRefresh`.
- `main/providers/` — novo `notification_lifecycle_provider.dart` com `@Riverpod(keepAlive: true)`.
- `main.dart` — após `firebaseClient.initialize()`, kick `container.read(notificationLifecycleProvider)` pra materializar o listener.

Nada novo em `domain/`, `data/`, `presentation/`.

## Fora do escopo

- DELETE do token no logout (Spec 4).
- Permissões iOS (`requestPermission`).
- Recebimento e handling de notificações (foreground, background, terminated).
- Persistência local de "último token enviado" para dedup.
- Auth gating antes do POST.

## Decisões de design

1. **Provider Riverpod com `keepAlive: true` em vez de subscribe direto no `main()`.**
   - DI nativa via `ref.watch`: mock fácil de `IMessagingClient` + `INotificationRepository` em testes.
   - Lifecycle automático: `ref.onDispose(subscription.cancel)` garante cleanup; em produção roda no shutdown do app, em testes roda no `container.dispose()`.
   - `keepAlive: true` previne descarte quando ninguém faz `ref.watch` (porque o provider é puro side-effect, retorna `void`).

2. **Kick explícito no `main.dart`.**
   - Provider só materializa quando alguém faz `ref.read`/`watch`. Ninguém depende dele, então sem kick fica inerte.
   - `container.read(notificationLifecycleProvider)` faz `build()` rodar uma vez e ligar o listener. Após isso, provider fica vivo até o app morrer.

3. **Rotação enquanto unauthenticated: ignora silenciosamente.**
   - Listener sempre chama `registerToken()`. Se não tiver auth, o `AuthenticationInterceptor` deixa a request seguir sem `Authorization`, backend responde 401, talker_dio_logger loga, fim.
   - Não vale criar `authStateProvider` observável só pra esse gate. Próximo cold start (Splash) ou próximo auth event (SignIn/SignUp) cobre.

4. **Sem dedup de "último token enviado" no cliente.**
   - Backend dedupe via `update_or_create` na chave `token`. Cliente envia toda vez que o stream emitir; backend transforma em UPSERT (atualiza `updated_at`).
   - Adicionar cache local introduz invalidação que não temos sinal pra fazer direito.

5. **`onTokenRefresh` é wrapper trivial.**
   - `Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;`
   - Sem `try-catch`, sem transform. Se o SDK lançar (raríssimo, geralmente só na primeira chamada), o stream propaga o erro — listener default ignora porque não tem `onError`.

6. **`unawaited(registerToken())` no callback.**
   - Mesmo padrão de Spec 1 e 2. `registerToken()` retorna `Either<Failure, void>` que ignoramos — fluxo inteiro fire-and-forget.

7. **Provider não retorna estado (`void`).**
   - Não há nada útil pra UI consumir. Existência do provider = listener ativo.
