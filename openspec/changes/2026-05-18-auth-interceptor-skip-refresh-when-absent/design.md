# Design: auth-interceptor-skip-refresh-when-absent

## Estado atual

`lib/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart:38-68`:

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode != HttpStatus.unauthorized) {
    return handler.next(err);
  }

  if (EndpointKey.isPublicPath(err.requestOptions.path)) {
    return handler.next(err);
  }

  try {
    final tokens = await _dataSource.get();
    final Response(data: data) = await _dio.post<Map<String, dynamic>>(
      EndpointKey.refreshToken.path,
      data: {'refresh': tokens.refresh},   // ❌ pode mandar null
    );

    final access = data!['access'] as String;
    final refresh = data['refresh'] as String;
    await _dataSource.save(access: access, refresh: refresh);

    err.requestOptions.headers[HttpHeaders.authorizationHeader] =
        'Bearer $access';

    handler.resolve(await _dio.fetch(err.requestOptions));
  } catch (_) {
    await _dataSource.clear();
    _onUnauthenticated();
    handler.next(err);
  }
}
```

`_dataSource.get()` retorna `Future<({String? access, String? refresh})>` (ver `local_token_data_source.dart:6`) — ambos os campos são nulláveis. Quando o storage está vazio (primeiro install, pós-logout, OS limpou), o record vem `(access: null, refresh: null)`.

---

## Mudança

`lib/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart`:

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode != HttpStatus.unauthorized) {
    return handler.next(err);
  }

  if (EndpointKey.isPublicPath(err.requestOptions.path)) {
    return handler.next(err);
  }

  final tokens = await _dataSource.get();

  if (tokens.refresh == null) {
    await _dataSource.clear();
    _onUnauthenticated();
    return handler.next(err);
  }

  try {
    final Response(data: data) = await _dio.post<Map<String, dynamic>>(
      EndpointKey.refreshToken.path,
      data: {'refresh': tokens.refresh},
    );

    final access = data!['access'] as String;
    final refresh = data['refresh'] as String;
    await _dataSource.save(access: access, refresh: refresh);

    err.requestOptions.headers[HttpHeaders.authorizationHeader] =
        'Bearer $access';

    handler.resolve(await _dio.fetch(err.requestOptions));
  } catch (_) {
    await _dataSource.clear();
    _onUnauthenticated();
    handler.next(err);
  }
}
```

**Diffs concretos:**
- `final tokens = await _dataSource.get();` sai de dentro do `try` pra ficar antes dele. Não precisa estar dentro do try — `_dataSource.get()` é safe (não lança em produção; se o storage corromper e lançar, ainda há a defesa do early return + a expectativa de que o catch original cubra cenários extremos).
- Inserido `if (tokens.refresh == null) { ... return handler.next(err); }` antes do `try`.
- O `try` agora começa direto no POST.

**Observação sobre o `_dataSource.get()` fora do try:**
Se `_dataSource.get()` lançar (cenário 4 do diagnóstico), agora o erro propaga em vez de cair no `catch`. Em produção esse cenário não acontece (storage local é sync + write-through). Se quiser defesa-em-profundidade absoluta, manter dentro do try é trivial (mover o `if` pra dentro também):

```dart
try {
  final tokens = await _dataSource.get();

  if (tokens.refresh == null) {
    await _dataSource.clear();
    _onUnauthenticated();
    return handler.next(err);
  }

  // ... resto igual
} catch (_) { ... }
```

**Decisão**: ficar com a versão "fora do try". A leitura é mais limpa (o early return é visualmente independente do refresh path), e o caso de `_dataSource.get()` lançar é fictício. Se virar real, abrimos spec separada.

---

## Testes

### `test/src/infrastructure/clients/http/interceptors/authentication_interceptor_test.dart`

Adicionar um adapter que **conta** quantas requests passaram por ele:

```dart
final class _CountingAdapter implements HttpClientAdapter {
  int callCount = 0;
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    paths.add(options.path);

    return ResponseBody.fromString(
      '',
      401,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
```

Novo teste dentro do `group('onError — 401')`:

```dart
test(
  'skips refresh and short-circuits when refresh token is absent',
  () async {
    when(() => dataSource.get())
        .thenAnswer((_) async => (access: null, refresh: null));
    when(() => dataSource.clear()).thenAnswer((_) async {});

    final adapter = _CountingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.interceptors.add(buildInterceptor(dio));
    dio.httpClientAdapter = adapter;

    try {
      await dio.get('/api/v1/expenses');
    } on DioException catch (_) {}

    expect(adapter.callCount, 1);
    expect(adapter.paths, ['/api/v1/expenses']);
    expect(adapter.paths.any((p) => p.contains('token/refresh')), isFalse);
    verify(() => dataSource.clear()).called(1);
    verifyNever(() => dataSource.save(
      access: any(named: 'access'),
      refresh: any(named: 'refresh'),
    ));
    expect(onUnauthenticatedCalled, isTrue);
  },
);
```

**Por que `_CountingAdapter` retorna 401 sempre:**
- Primeira call: a request original (`GET /api/v1/expenses`) — adapter retorna 401 → cai no `onError`.
- O early return dispara antes de qualquer call pro `/auth/refresh`.
- Resultado esperado: adapter foi chamado **1 vez** total (a request original), nunca pro `/auth/refresh`.

**Por que não reusar `_RefreshFailureAdapter`:**
O `_RefreshFailureAdapter` existente responde 401 sempre. Se reusado, o teste passaria mesmo com o código antigo (a chamada pro `/auth/refresh` voltaria 401 → cai no catch → mesma saída). Precisamos do **assert de count == 1** pra provar que o refresh **não foi tentado**.

### Cenários existentes — sem mudanças

- `onRequest — public endpoint`
- `onRequest — protected endpoint`
- `onError — non-401`
- `onError — 401 refreshes tokens and retries request on success`
- `onError — 401 clears tokens and calls onUnauthenticated on refresh failure` (esse usa `refresh: 'expired_refresh'` — passa pelo early return porque `refresh != null` → entra no try → backend rejeita → catch dispara)

---

## Considerações

### Risco

Mínimo. O comportamento end-to-end é preservado nos 5 cenários existentes. O único delta observável é o cenário novo:

| Cenário | Antes | Depois |
|---|---|---|
| 401 + refresh existe (válido) | refresh → 200 → retry | (sem mudança) |
| 401 + refresh existe (expirado) | refresh → 401 → catch → signin | (sem mudança) |
| 401 + refresh ausente | refresh → 400/401 → catch → signin | early return → signin (sem POST) |

### Smoke manual

- Logout no app → tentar fazer um GET protegido (ex: navegar manualmente pra `/expenses` sem sessão) → não deve haver request `POST /auth/refresh` no Network inspector / talker logs. User vai pra signin igual.
- Sessão válida → 401 sintético (revogar token no backend) → refresh dispara, retry, sucesso. (Cenário existente, valida que não regredimos.)

### Performance

Economiza 1 request por 401-sem-refresh. Em telas que disparam várias requests paralelas pós-logout (cenário raro mas possível em deep links), economia escala linear.
