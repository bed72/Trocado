# Tasks: http-client

## 1. Infrastructure — Client

- [ ] Criar `lib/src/infrastructure/clients/http/i_http_client.dart`
  — interface `IHttpClient` com métodos `get`, `post`, `put`, `patch`, `delete`
  — cada método retorna `Future<Either<Map<String, dynamic>, Map<String, dynamic>>>`

- [ ] Criar `lib/src/infrastructure/clients/http/dio_http_client.dart`
  — `DioHttpClient implements IHttpClient`
  — `Dio` recebido via construtor
  — único `try-catch` do projeto: captura `DioException` e `Object`
  — sucesso → `Right(response.data)`
  — erro HTTP → `Left(dioException.response!.data)`
  — erro de rede / timeout → `Left` com estrutura `{ errors: [...] }` normalizada

## 2. Infrastructure — Responses compartilhados

- [ ] Criar `lib/src/infrastructure/clients/http/responses/error_item_response.dart`
  — campos: `field`, `message`, `code` (todos `String`)
  — `fromJson` obrigatório

- [ ] Criar `lib/src/infrastructure/clients/http/responses/failure_response.dart`
  — campo: `errors` (`List<ErrorItemResponse>`)
  — `fromJson` obrigatório

## 3. Testes

- [ ] Criar `test/mocks/mocks.dart` (ou atualizar) com `MockHttpClient`
  — `class MockHttpClient extends Mock implements IHttpClient`

- [ ] Criar `test/src/infrastructure/clients/http/dio_http_client_test.dart`
  — sucesso 200: retorna `Right` com body
  — erro 400: retorna `Left` com body da resposta
  — erro 401: retorna `Left` com body da resposta
  — erro de rede (DioException sem response): retorna `Left` normalizado
  — erro inesperado: retorna `Left` normalizado

- [ ] Criar `test/src/infrastructure/clients/http/responses/failure_response_test.dart`
  — `fromJson` com lista de erros
  — `fromJson` com lista vazia

- [ ] `flutter test` e `flutter analyze` passando
