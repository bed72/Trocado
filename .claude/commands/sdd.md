# SDD — Spec-Driven Development

Fluxo para implementar um endpoint do backend no app Flutter Trocado.

## Pré-requisito

Verificar o contrato do endpoint em `openapi.json` antes de qualquer implementação.

---

## Fluxo completo

### 1. Verificar openapi.json

Mapear campos relevantes:
- Campos obrigatórios vs opcionais
- Tipos de dados (String decimal, ISO date, nullable)
- Paginação (cursor: `next`/`previous`)
- ReadOnly fields (não enviar no POST/PATCH)

### 2. Model (domain)

Criar/atualizar em `lib/src/domain/models/`:
- `amount: double` (converter de `String` decimal do backend)
- `date: int` (converter de `String` ISO 8601 para milliseconds)
- Campos antes do construtor
- `copyWith()` obrigatório

### 3. Datasource interface (infrastructure)

Criar em `lib/src/infrastructure/datasources/`:
- Retornar `Future<Model>` puro
- **Sem** `Either`, **sem** `Failure`

### 4. Request e Response (infrastructure/http)

Criar em `lib/src/infrastructure/clients/http/`:
- `requests/xxx_request.dart` — campos antes do construtor, `toJson()`
- `responses/xxx_response.dart` — campos antes do construtor, `fromJson()`
  - `value: String` (decimal do backend) → converter para `double` ao mapear para Model
  - `date: String` (ISO 8601) → converter para `int` (milliseconds) ao mapear para Model

### 5. Datasource remoto (infrastructure/remote)

Criar em `lib/src/infrastructure/datasources/remote/` usando Dio:
- Usar `XxxRequest` para montar o body do request
- Deserializar resposta com `XxxResponse.fromJson()`
- Converter `XxxResponse` → `Model`

Mapeamento HTTP status → Failure (feito no repositório):

| HTTP Status | Failure |
|---|---|
| timeout / sem conexão | `NetworkFailure` |
| 404 | `NotFoundFailure` |
| 5xx | `ServerFailure` |
| 422 / 400 | `ValidationFailure(message)` |
| outros | `UnknownFailure` |

### 6. Repositório (data)

Implementar em `lib/src/data/repositories/`:
- Receber interface de datasource (nunca implementação concreta)
- Wrap em try/catch → `Left(Failure)` / `Right(model)`

```dart
try {
  final model = await _dataSource.findById(id);
  return Right(model);
} on DioException catch (e) {
  return Left(_mapDioException(e));
} catch (e) {
  return Left(UnknownFailure(e.toString()));
}
```

### 7. Provider (main)

Criar providers Riverpod com `@riverpod` para:
- Datasource remoto
- Repositório (via interface)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 8. Testes

- `test/src/data/repositories/` — unit tests com mock do datasource
- `test/src/presentation/providers/` — Notifier com mock do repositório

---

## Referências

- API contract: `openapi.json`
- CLAUDE.md: camadas e regras de dependência
