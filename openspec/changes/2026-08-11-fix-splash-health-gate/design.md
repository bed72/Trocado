# Design: fix-splash-health-gate

## Fluxo

`SplashNotifier.build()` seguirá esta ordem:

1. Verificar conectividade.
2. Retornar `SplashStatus.noConnection` se não houver conexão.
3. Chamar `IHealthRepository.check()`.
4. Mapear `Left` ou `Right(false)` para `SplashStatus.maintenance`.
5. Chamar `_checkSession()` apenas para `Right(true)`.

O mapeamento continuará local ao notifier usando `Either.fold`, sem novas abstrações ou dependências.

## Arquivos afetados

- `lib/src/presentation/ui/splash/notifiers/splash_notifier.dart`
- `test/src/presentation/providers/splash_notifier_test.dart` apenas se a verificação revelar alguma lacuna adicional.
