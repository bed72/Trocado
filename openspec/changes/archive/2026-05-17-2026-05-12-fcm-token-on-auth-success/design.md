# Design: fcm-token-on-auth-success

## Fluxo de responsabilidades

```
SignInNotifier._submit() / SignUpNotifier._submit()
    → repository.signIn / signUp
    → data.fold(
        (failure) => state = state.copyWith(status: .failure, message: ...),
        (_) {
          unawaited(_notificationRepository.registerToken());
          state = state.copyWith(status: .success);
        },
      );

INotificationRepository.registerToken()
    [já implementado em 2026-05-12-fcm-token-registration]
    → RemoteNotificationDataSource.registerToken()
        → IMessagingClient.getToken() → String?
        → if null: Right(null) no-op
        → IHttpClient.post(EndpointKey.fcmToken, FcmTokenRequest(token, platform))
        → Either<FailureResponse, void>
    → either((f) => f.toFailure(), (_) {})
    → Either<Failure, void>  (descartado pelo notifier)
```

`unawaited(...)` desacopla o registro do fluxo de UI: o `state.copyWith(status: .success)` é emitido na mesma linha lógica, sem esperar pela resposta HTTP. A screen recebe `success`, navega, e o POST roda em paralelo.

---

## SignInNotifier — diff

`lib/src/presentation/ui/authentication/sign_in/notifiers/sign_in_notifier.dart`:

```diff
+ import 'dart:async';
+
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  import 'package:trocado/src/main/providers/validators_provider.dart';
  import 'package:trocado/src/main/providers/repositories_provider.dart';

+ import 'package:trocado/src/domain/repositories/interface_notification_repository.dart';
  import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

  ...

  @riverpod
  final class SignInNotifier extends _$SignInNotifier {
    late SignInFormValidator _validator;
+   late INotificationRepository _notificationRepository;
    late IAuthenticationRepository _repository;

    @override
    SignInState build() {
      _validator = ref.watch(signInFormValidatorProvider);
+     _notificationRepository = ref.watch(notificationRepositoryProvider);
      _repository = ref.watch(authenticationRepositoryProvider);

      return const SignInState();
    }

    ...

    Future<void> _submit() async {
      ...

      data.fold(
        (failure) => this.state = this.state.copyWith(
          status: .failure,
          message: failure.message,
        ),
-       (_) => this.state = this.state.copyWith(status: .success),
+       (_) {
+         unawaited(_notificationRepository.registerToken());
+         this.state = this.state.copyWith(status: .success);
+       },
      );
    }
  }
```

---

## SignUpNotifier — diff

`lib/src/presentation/ui/authentication/sign_up/notifiers/sign_up_notifier.dart`:

Idêntico ao `SignInNotifier`: adicionar `import 'dart:async';`, `INotificationRepository` em `domain/repositories/`, campo `late _notificationRepository`, `ref.watch(notificationRepositoryProvider)` em `build()`, e o `unawaited(...)` no ramo `Right` do `_submit()`.

---

## Ordem de execução no ramo Right

```
unawaited(_notificationRepository.registerToken());  // dispara
this.state = this.state.copyWith(status: .success);   // emite
```

`unawaited(...)` é não-bloqueante. A primeira microtask que roda é a chamada de `registerToken()` (até o primeiro `await` interno — `_messagingClient.getToken()`). Em paralelo, o `state =` é avaliado imediatamente.

Resultado prático na screen:
- `ref.listen(signInNotifierProvider, ...)` recebe `.success` antes (ou no mesmo frame) do POST sair do device.
- Navegação acontece imediatamente.
- POST completa em background — sucesso/falha invisível ao usuário (`talker_dio_logger` cobre nos logs).

---

## Por que ordem `unawaited` antes do `state =`?

Mesma ordem que a `SplashNotifier` no fold:

```dart
return data.fold((_) => .unauthenticated, (_) {
  unawaited(_notificationRepository.registerToken());
  return .authenticated;
});
```

Ordem é cosmética (ambas as linhas são sync e o `unawaited` retorna imediatamente), mas a leitura fica linear: "dispara o efeito colateral, depois confirma o sucesso". Mantém consistência com a Splash.

---

## Estratégia de testes

| Arquivo | Mock em | Testa |
|---|---|---|
| `sign_in_notifier_test.dart` | `IAuthenticationRepository`, `INotificationRepository`, `SignInFormValidator` | • sucesso chama `registerToken()` uma vez<br>• falha de auth NÃO chama `registerToken()`<br>• form inválido NÃO chama `registerToken()`<br>• `registerToken()` lento não bloqueia transição para `.success` |
| `sign_up_notifier_test.dart` | `IAuthenticationRepository`, `INotificationRepository`, `SignUpFormValidator` | mesmos 4 cenários do SignIn |

Se já existirem testes desses notifiers, **adicionar os 4 cenários a cada arquivo** sem refatorar o existente. Se não existirem, criar.

---

## Decisões

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| Hook nos notifiers, não em listener de auth global | Provider central observando estado de auth e disparando `registerToken()` | Custo arquitetural alto pra fechar 2 gatilhos; spec futura pode revisitar se aparecerem mais |
| Sem helper extraído | `AuthSuccessSideEffect` mixin/función | 2 linhas em 2 lugares; abstração prematura |
| Não emitir state intermediário de "registrando token" | Status `.registeringToken` antes de `.success` | Visível ao usuário viola o requisito de transparência da Spec 1 |
| `unawaited` antes do `state =` | `state =` antes do `unawaited` | Consistência com Splash (cosmético) |
| Sem retry se falhar | Retry exponencial | Próximo cold start (Splash) e `onTokenRefresh` (Spec 2) cobrem o retry natural |
