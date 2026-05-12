# Tasks: fcm-token-on-auth-success

## presentation/

- [x] `lib/src/presentation/ui/authentication/sign_in/notifiers/sign_in_notifier.dart` — adicionar `import 'dart:async';`, importar `INotificationRepository` de `domain/repositories/`, novo campo `late INotificationRepository _notificationRepository`, `ref.watch(notificationRepositoryProvider)` em `build()`, no ramo `Right` do fold do `_submit()` trocar a expressão única por bloco com `unawaited(_notificationRepository.registerToken());` antes do `state = state.copyWith(status: .success)`
- [x] `lib/src/presentation/ui/authentication/sign_up/notifiers/sign_up_notifier.dart` — mesmo conjunto de mudanças do SignInNotifier

## test/

- [x] `test/src/presentation/providers/sign_in_notifier_test.dart` — se já existir, adicionar 4 cenários (sucesso chama registerToken, falha não chama, form inválido não chama, registerToken lento não bloqueia `.success`); se não existir, criar com cobertura completa dos cenários da spec
- [x] `test/src/presentation/providers/sign_up_notifier_test.dart` — idem para SignUp

## Pré-condições (já satisfeitas)

- `INotificationRepository` existe (`lib/src/domain/repositories/interface_notification_repository.dart`)
- `notificationRepositoryProvider` existe (`lib/src/main/providers/repositories_provider.dart`)
- `MockNotificationRepository` existe em `test/mocks/mocks.dart`
- Backend confirmou contrato `POST /api/v1/me/fcm-token` idempotente

## Verificação

- [x] `flutter analyze` — zero issues
- [x] `flutter test` — verde
- [x] Sem alteração em arquivos fora de `presentation/ui/authentication/{sign_in,sign_up}/notifiers/` e `test/src/presentation/providers/`
