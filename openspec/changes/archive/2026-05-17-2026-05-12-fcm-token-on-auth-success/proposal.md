# Proposal: fcm-token-on-auth-success

## Intenção

Registrar o token FCM do dispositivo no backend (`POST /api/v1/me/fcm-token`) imediatamente após `SignInNotifier` ou `SignUpNotifier` confirmarem sucesso da autenticação. Operação transparente para o usuário — `unawaited(...)`, mesmo padrão da `SplashNotifier`.

## Motivação

A spec anterior (`fcm-token-registration`, arquivada em 2026-05-12) cobriu apenas o caminho da Splash com sessão válida. Resultado: new user que faz SignIn ou SignUp pela primeira vez fica sem token registrado durante toda a primeira sessão — só captura no próximo cold start.

Backend confirmou em 2026-05-12 que o endpoint `POST /api/v1/me/fcm-token` é idempotente (`204` em qualquer caso, atualiza `updated_at` em re-post), então re-postar não tem custo. Isso libera o gatilho de pós-auth: sempre que o sucesso de auth materializar uma sessão nova, posta-se o token, independente de já ter sido postado antes.

## Camadas afetadas

- `presentation/ui/authentication/sign_in/notifiers/` — `SignInNotifier` ganha `INotificationRepository` via `ref.watch` e dispara `unawaited(...)` no ramo `Right` do fold de `signIn`.
- `presentation/ui/authentication/sign_up/notifiers/` — `SignUpNotifier` idem para o ramo `Right` do fold de `signUp`.

Nada novo em `domain/`, `data/`, `infrastructure/` ou `main/providers/` — tudo já existe.

## Fora do escopo

- Listener de `FirebaseMessaging.onTokenRefresh` (Spec 2).
- DELETE do token no logout (Spec 3).
- Permissões iOS (`requestPermission`).
- Recebimento e handling de notificações.

## Decisões de design

1. **Mesmo padrão `unawaited(...)` da Splash.**
   No ramo `Right` do `fold`, antes de emitir `status: .success`, disparar `unawaited(_notificationRepository.registerToken())`. Não bloqueia navegação nem afeta state.

2. **Notifier importa apenas de `domain/`.**
   `INotificationRepository` é o único símbolo novo no notifier. Sem `IMessagingClient`, sem `ILoggerClient`, sem `try-catch`. Respeita `presentation → domain` (regra dura do CLAUDE.md).

3. **Either retornado é descartado intencionalmente.**
   Não há feedback ao usuário (transparente). `IMessagingClient` swallow-all + `IHttpClient` Either já garantem que nenhuma exception vaza.

4. **Mesmo gatilho nos dois notifiers, não extrair helper.**
   Duas linhas em duas classes não justifica abstração. Três similares > abstração prematura.

5. **Não checar se já foi registrado nesta sessão.**
   Backend dedupe via `update_or_create` na chave `token`. Cliente não precisa cachear "já enviei" — o custo de re-post é uma query UPSERT no servidor.
