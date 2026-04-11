# Spec: http-client

## Requirements

---

### Requirement: Interface IHttpClient

The system SHALL define an abstract interface `IHttpClient` com os verbos `get`, `post`, `put`, `patch` e `delete`.
The system SHALL retornar `Future<Either<Map<String, dynamic>, Map<String, dynamic>>>` em todos os métodos.

#### Scenario: Contrato de sucesso
Given um endpoint que responde 2xx
When o Client executa qualquer verbo
Then retorna `Right` contendo o body da resposta como `Map<String, dynamic>`

#### Scenario: Contrato de erro HTTP
Given um endpoint que responde 4xx ou 5xx
When o Client executa qualquer verbo
Then retorna `Left` contendo o body do erro como `Map<String, dynamic>`

---

### Requirement: Implementação DioHttpClient

The system SHALL implementar `IHttpClient` usando `Dio` injetado via construtor.
The system SHALL conter o único `try-catch` do projeto dentro de `DioHttpClient`.

#### Scenario: Resposta 2xx
Given uma requisição bem-sucedida
When o Dio retorna status 200/201/204
Then `DioHttpClient` retorna `Right(response.data)`

#### Scenario: Erro HTTP com body
Given uma requisição que falha com `DioException` e `response != null`
When o Dio lança `DioException`
Then `DioHttpClient` retorna `Left(dioException.response!.data)`

#### Scenario: Erro de rede sem response
Given uma falha de conexão, timeout ou cancelamento
When o Dio lança `DioException` com `response == null`
Then `DioHttpClient` retorna `Left` com estrutura normalizada `{ "errors": [{ "field": "non_field_errors", "message": <mensagem>, "code": "network_error" }] }`

#### Scenario: Erro inesperado
Given uma exceção não prevista
When ocorre qualquer `Object` fora de `DioException`
Then `DioHttpClient` retorna `Left` com estrutura normalizada `{ "errors": [{ "field": "non_field_errors", "message": "Unknown error", "code": "unknown" }] }`

---

### Requirement: FailureResponse

The system SHALL definir `FailureResponse` como objeto compartilhado em `infrastructure/clients/http/responses/`.
The system SHALL deserializar o campo `errors` como `List<ErrorItemResponse>`.

#### Scenario: Desserialização de erros de validação
Given o body `{ "errors": [{ "field": "email", "message": "This field is required.", "code": "required" }] }`
When `FailureResponse.fromJson` é chamado
Then retorna `FailureResponse` com `errors` contendo 1 item com `field = "email"`, `message = "This field is required."`, `code = "required"`

#### Scenario: Desserialização de erro geral
Given o body `{ "errors": [{ "field": "non_field_errors", "message": "Invalid credentials.", "code": "invalid" }] }`
When `FailureResponse.fromJson` é chamado
Then retorna `FailureResponse` com `errors` contendo 1 item com `field = "non_field_errors"`

#### Scenario: Lista de erros vazia
Given o body `{ "errors": [] }`
When `FailureResponse.fromJson` é chamado
Then retorna `FailureResponse` com `errors` como lista vazia

---

### Requirement: Injeção de dependência

The system SHALL receber `Dio` via construtor em `DioHttpClient`.
The system SHALL permitir substituição do `Dio` por mock em testes sem alterar o código de produção.

#### Scenario: Mock em testes
Given um `MockDio` configurado
When `DioHttpClient` é instanciado com o mock
Then todos os métodos usam o `Dio` injetado, nunca um singleton interno
