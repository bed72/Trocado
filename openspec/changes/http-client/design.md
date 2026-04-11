# Design: http-client

## Fluxo de responsabilidades

```
IHttpClient (interface)
    Either<Map<String, dynamic>, Map<String, dynamic>>
         Left  = body do erro   (status >= 400)
         Right = body do sucesso (status 2xx)

DioHttpClient (implementação)
    — único try-catch do projeto
    — captura DioException e erros inesperados
    — nunca lança exceptions para fora

FailureResponse (compartilhado)
    — deserializa o Left do Client
    — usado por todos os datasources remotos
```

## Regra de dependência

```
infrastructure/ conhece apenas suas próprias interfaces
domain/         não é importado pelo Client
```

`IHttpClient` não conhece `Failure`, `Either` do domínio, nem nenhum model.
O `Either` usado aqui é o do domínio (`lib/src/domain/either/either.dart`), que é Dart puro.

## Interface IHttpClient

```dart
abstract interface class IHttpClient {
  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Either<Map<String, dynamic>, Map<String, dynamic>>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });
}
```

## Implementação DioHttpClient

- Recebe `Dio` via construtor (injeção de dependência)
- Cada método chama o verbo correspondente do Dio
- Sucesso (2xx): `Right(response.data as Map<String, dynamic>)`
- Erro HTTP (DioException com response): `Left(dioException.response!.data as Map<String, dynamic>)`
- Erro de rede / timeout / cancelamento: `Left({'errors': [{'field': 'non_field_errors', 'message': e.message, 'code': 'network_error'}]})`
- Erro inesperado: `Left({'errors': [{'field': 'non_field_errors', 'message': 'Unknown error', 'code': 'unknown'}]})`

## FailureResponse (compartilhado)

Estrutura da API:
```json
{
  "errors": [
    { "field": "email",            "message": "This field is required.", "code": "required" },
    { "field": "non_field_errors", "message": "Invalid credentials.",    "code": "invalid"  }
  ]
}
```

```dart
final class ErrorItemResponse {
  final String field;
  final String message;
  final String code;

  const ErrorItemResponse({
    required this.field,
    required this.message,
    required this.code,
  });

  factory ErrorItemResponse.fromJson(Map<String, dynamic> json) => ErrorItemResponse(
    field: json['field'] as String,
    message: json['message'] as String,
    code: json['code'] as String,
  );
}

final class FailureResponse {
  final List<ErrorItemResponse> errors;

  const FailureResponse({required this.errors});

  factory FailureResponse.fromJson(Map<String, dynamic> json) => FailureResponse(
    errors: (json['errors'] as List)
        .map((e) => ErrorItemResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
```

## Decisões e trade-offs

| Decisão | Alternativa descartada | Motivo |
|---|---|---|
| `Either<Map, Map>` no Client | `Either<Failure, Model>` | Client não conhece domínio; mapeamento é responsabilidade do datasource |
| Dio injetado via construtor | Dio criado internamente | Permite mock em testes e configuração externa (baseUrl, interceptors) |
| `FailureResponse` genérico compartilhado | Um por feature | A API tem estrutura de erro uniforme |
| `try-catch` apenas no Client | try-catch no datasource | Único ponto de controle; datasources mapeiam `Either` sem exceções |
