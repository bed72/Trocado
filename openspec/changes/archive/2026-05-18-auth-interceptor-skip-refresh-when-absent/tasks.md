# Tasks: auth-interceptor-skip-refresh-when-absent

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart` — em `onError`, mover `final tokens = await _dataSource.get();` pra antes do `try`; adicionar `if (tokens.refresh == null) { await _dataSource.clear(); _onUnauthenticated(); return handler.next(err); }` antes do `try`; manter o `try/catch` existente como está

## test/

- [x] `test/src/infrastructure/clients/http/interceptors/authentication_interceptor_test.dart` — adicionar `_CountingAdapter` (conta calls + lista paths, sempre responde 401); novo teste no `group('onError — 401')`: `'skips refresh and short-circuits when refresh token is absent'` valida que (a) adapter foi chamado exatamente 1 vez, (b) o único path foi a request original (`/api/v1/expenses`), (c) nenhum path contém `token/refresh`, (d) `dataSource.clear()` chamado 1x, (e) `dataSource.save(...)` nunca chamado, (f) `onUnauthenticatedCalled == true`

## Pré-condições (já satisfeitas)

- `ILocalTokenDataSource.get()` retorna `Future<({String? access, String? refresh})>` (`local_token_data_source.dart:6`)
- `EndpointKey.isPublicPath` existe e cobre os paths públicos
- `EndpointKey.refreshToken.path` é o destino do POST de refresh
- `MockTokenDataSource` existe em `test/mocks/mocks.dart`
- Teste do interceptor já tem 5 cenários (`onRequest` public/protected; `onError` non-401, 401-success, 401-failure)
- Adapters de teste (`_CapturingAdapter`, `_ServerFailureAdapter`, `_RefreshSuccessAdapter`, `_RefreshFailureAdapter`) servem de molde pro `_CountingAdapter`

## Verificação

- [x] `flutter analyze` — zero issues novos (4 warnings pré-existentes em `insights_carousel_loading_widget.dart`, nenhum da refatoração)
- [x] `flutter test test/src/infrastructure/clients/http/interceptors/authentication_interceptor_test.dart` — 6 testes verdes (5 existentes + 1 novo)
- [x] `flutter test` — suite completa verde (661 testes)
- [ ] Smoke: logout no app → forçar GET protegido → no Talker logs, **nenhuma** request `POST /auth/refresh` deve aparecer; user vai pro SignIn
- [ ] Smoke: sessão válida → forçar 401 sintético no backend → refresh dispara, retry, sucesso (cenário existente, valida não-regressão)
