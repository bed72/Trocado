# Proposal: auth-interceptor-skip-refresh-when-absent

## Intenção

No `AuthenticationInterceptor.onError` (`lib/src/infrastructure/clients/http/interceptors/authentication_interceptor.dart:39`), quando um 401 chega e o `_dataSource.get()` retorna `refresh == null` (sem refresh token armazenado), o código **ainda** envia um POST pra `/auth/refresh` com `{"refresh": null}` — sabendo que vai falhar. A spec elimina esse round-trip inútil via early return.

## Motivação

O `_dataSource.get()` retorna `({String? access, String? refresh})` (record com ambos campos nulos quando o storage está limpo — primeiro install, pós-logout, storage corrompido pelo OS). Hoje o fluxo é:

```
401 chega
↓
tokens = (access: null, refresh: null)
↓
POST /auth/refresh com body {"refresh": null}
↓
Django responde 400 ("refresh is required") ou 401 ("token invalid")
↓
catch (_) pega → clear + _onUnauthenticated() + handler.next(err)
```

A malha de segurança do `catch (_)` salva — o user sai pro SignIn, nada quebra. Mas:

1. **Round-trip desperdiçado**: 1 POST inútil por 401 quando o user já está deslogado. Em cenários onde o app dispara várias requests paralelas (ex: home + budgets + insights), cada uma gera um POST de refresh redundante antes de cair no signin. Em produção isso polui o log do backend com `400 refresh required` que não é bug — é sinal de cliente mal-comportado.
2. **Intent não-óbvia**: o leitor do código precisa rastrear até o `catch (_)` pra entender que "ok, vai falhar mesmo". Early return explícito sobre `refresh == null` deixa a intenção clara: "sem refresh, não tem como renovar, ir direto pro signin".
3. **Latência percebida**: o POST `/auth/refresh` pode levar 200-500ms num link ruim. Multiplica pelas requests paralelas → user percebe lag antes do redirect.

## Camadas afetadas

- `infrastructure/clients/http/interceptors/authentication_interceptor.dart` — `onError` ganha early return quando `tokens.refresh == null`.
- `test/src/infrastructure/clients/http/interceptors/authentication_interceptor_test.dart` — novo cenário no `group('onError — 401')` cobrindo o early return (assert que **nenhuma** request foi pro `/auth/refresh`, `clear` foi chamado, `onUnauthenticated` foi chamado, erro original propaga).

Nada novo em `domain/`, `data/`, `presentation/`, `main/`.

## Fora do escopo

- **Curto-circuito em `onRequest`** (rejeitar protected requests sem header quando `tokens.access == null`). Bigger change, afeta fluxos transientes (sign-in em andamento, splash). Spec separada se virar prioritário.
- **Mudar `data!['access'] as String` pra check explícito** no caminho de sucesso do refresh. O `catch (_)` já cobre `TypeError` por null check ou cast errado. Refactor cosmético não muda comportamento. Não vale ruído.
- **Adicionar logging estruturado** no early return (ex: "skipped refresh because no token"). Talker já loga 401 via `dio_talker_logger`; adicionar log próprio aqui mistura responsabilidade. Se quiser observability, é spec separada.
- **Dedupe de refresh concorrente** (várias requests paralelas → 1 único POST `/auth/refresh`). Issue conhecido mas ortogonal — afeta o cenário "tem refresh válido", não o "refresh ausente". Não tocar agora.
- **Validar `access == null` mas `refresh != null`** como cenário separado. Combinação não acontece em produção (sempre saem juntos via `_dataSource.save(access:, refresh:)`), mas se acontecer, o early return de `refresh == null` não dispara → POST sai → backend valida refresh → fluxo normal. OK por inércia.

## Decisões de design

1. **Checar apenas `tokens.refresh == null`, não `tokens.access == null`.**
   `access == null` é irrelevante pro fluxo de refresh (só o `refresh` é body do POST). Combinação `access:null, refresh:'algo'` é teoricamente possível se o storage corromper só uma das chaves — o early return ignora esse caso e segue pro POST, que é o comportamento certo (tentamos renovar com o refresh que temos).

2. **Early return faz o mesmo trabalho do `catch`: `clear()` + `_onUnauthenticated()` + `handler.next(err)`.**
   Não tentar simplificar pra um `throw` que cai no catch. Razões: (a) o `catch (_)` é uma trap silenciosa que esconde a intenção; queremos o caminho de "sem refresh" ser explícito; (b) `throw` numa função `async` que retorna `void` cria fluxo de exceção em vez de return — mais difícil de ler. Duplicar 3 linhas vale a clareza.

3. **Sem refactor do `try-catch` existente.**
   O catch continua sendo a malha de segurança pros cenários 2-4 (`data == null` no 200, `data['access']` ausente, storage lança). Mantemos a defesa em profundidade.

4. **Teste valida que **nenhuma** request foi pro `/auth/refresh`.**
   O adapter de teste precisa capturar todas as requests que passaram por ele. Hoje há `_CapturingAdapter` que captura a última — pra esse cenário criamos um adapter que lista todas, ou simplesmente assertamos que o adapter foi chamado 1 vez (a request original que recebeu 401) e nunca 2. Ver design.md.

5. **Comportamento end-to-end observável é zero-delta no cenário "user deslogado clica em algo protegido".**
   User sai pro signin igual hoje, só sem o POST inútil no meio. UX idêntica; diferença é só servidor + latência.

6. **Não muda os outros 4 testes existentes do interceptor.**
   `onRequest — public/protected`, `onError — non-401`, `onError — 401 success`, `onError — 401 refresh failure` continuam passando byte-a-byte.
