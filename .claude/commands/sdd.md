# SDD — Spec-Driven Development

Fluxo para implementar um endpoint do backend no app Flutter Trocado.

## ⚠️ REGRA MAIS IMPORTANTE — NUNCA IGNORE

**SEMPRE crie a spec ANTES de qualquer implementação.**
Sem spec aprovada pelo usuário = sem código. Zero exceções.

O fluxo correto é:
1. Usuário pede uma feature
2. Você cria a spec (`/sdd`) e aguarda aprovação
3. Usuário aprova
4. Você implementa

Implementar sem spec é um erro grave — a spec é o contrato que guia toda a implementação.

## Pré-requisito

Antes de implementar qualquer coisa, criar uma spec com `/sdd`.
**Implementar exatamente o escopo definido na spec.** Se durante a implementação for identificado que outras camadas são necessárias, perguntar ao usuário antes de incluir.
Mapear campos do contrato:
- Campos obrigatórios vs opcionais
- Tipos de dados (String decimal, ISO date, nullable)
- Paginação (cursor: `next`/`previous`)
- ReadOnly fields (não enviar no POST/PATCH)

---

## Fluxo completo

### 1. Model (domain)

Criar/atualizar em `lib/src/domain/models/`:
- `amount: double` (converter de `String` decimal do backend)
- `date: int` (converter de `String` ISO 8601 para milliseconds)
- Campos antes do construtor
- `copyWith()` obrigatório

### 2. Request e Response (infrastructure/http)

Criar em `lib/src/infrastructure/clients/http/`:
- `requests/xxx_request.dart` — campos antes do construtor, `toJson()`
- `responses/xxx_response.dart` — campos antes do construtor, `fromJson()`
  - `value: String` (decimal do backend) → converter para `double` ao mapear para Model
  - `date: String` (ISO 8601) → converter para `int` (milliseconds) ao mapear para Model

### 3. Datasource interface (infrastructure)

Criar em `lib/src/infrastructure/datasources/remote/`:
- Retornar `Either<FailureResponse, XxxResponse>`
- Receber `IHttpClient` via construtor
- Deserializar ambos os lados do `Either<Map, Map>` retornado pelo client
- Path do endpoint via `Endpoints` enum em `lib/src/infrastructure/clients/http/endpoints.dart`

**Convenções de nomenclatura no datasource:**
- Parâmetro do método: sempre `parameter` (não `request`)
- Variável do retorno do client: `response` (nunca `either` — reservado para `Either` explícito no repositório)

```dart
abstract interface class IXxxDataSource {
  Future<Either<FailureResponse, XxxResponse>> action({required XxxRequest parameter});
}

final class RemoteXxxDataSource implements IXxxDataSource {
  final IHttpClient _client;
  RemoteXxxDataSource({required IHttpClient client}) : _client = client;

  @override
  Future<Either<FailureResponse, XxxResponse>> action({required XxxRequest parameter}) async {
    final response = await _client.post(
      parameter: Requests(Endpoints.xxx.path, body: parameter.toJson()),
    );
    return response.either(FailureResponse.fromJson, XxxResponse.fromJson);
  }
}
```

**Interface e implementação no mesmo arquivo** — sem arquivo `interface_` separado. A regra `interface_` se aplica apenas a repositórios (que ficam em camadas diferentes).

**Nomenclatura da interface:**
- Datasource remoto: `IRemoteXxxDataSource` — ex: `IRemoteAuthenticationDataSource`
- Datasource local: `ILocalXxxDataSource` — ex: `ILocalTokenDataSource`

### 4. Repositório (data)

Implementar em `lib/src/data/repositories/`:
- Receber interface de datasource (nunca implementação concreta)
- Converter `FailureResponse → Failure` e `XxxResponse → Model`
- **Sem try-catch** — o único try-catch fica no Client

```dart
@override
Future<Either<Failure, XxxModel>> action({required param}) async {
  final data = await _dataSource.action(
    parameter: XxxRequest(param: param),
  );
  return data.either((failure) => failure.toFailure(), (success) => success.toModel());
}
```

Sem `_toFailure` local. A conversão `FailureResponse → Failure` é feita via `FailureResponseExtension.toFailure()` definida em `lib/src/data/extensions/failure_response_extension.dart`, que usa o enum `FailureCodeResponse` (em `infrastructure/clients/http/responses/failure/failure_code.dart`) no pattern match:

```dart
return switch (FailureCodeResponse.fromString(item.code)) {
  .networkError => const NetworkFailure(),
  .serverError  => const ServerFailure(),
  .notFound     => const NotFoundFailure(),
  _             => ValidationFailure(item.message),
};
```

Mapeamento HTTP status → Failure (feito no repositório via `FailureResponse`):

| Código (`FailureItemResponse.code`) | Failure |
|---|---|
| `connection_error` / `timeout` | `NetworkFailure` |
| `not_found` | `NotFoundFailure` |
| `server_error` | `ServerFailure` |
| outros | `ValidationFailure(message)` |
| desconhecido | `UnknownFailure` |

### 5. Provider (main)

Criar providers Riverpod com `@riverpod` para:
- Datasource remoto
- Repositório (via interface)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Testes

**Não há testes de datasource separados.** A lógica de deserialização é coberta por:

- `test/src/infrastructure/responses/xxx_response_test.dart` — testa `fromJson` isolado
- `test/src/data/repositories/xxx_repository_test.dart` — mock em `IHttpClient`, testa repositório + datasource juntos
- `test/src/presentation/providers/` — Notifier com mock do repositório

---

## Referências

- CLAUDE.md: camadas e regras de dependência
