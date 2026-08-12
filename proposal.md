# Arquitetura: UseCase ate Client

## Regra principal

O `UseCase` coordena a acao do usuario e chama diretamente o contrato do
`Repository`:

```text
UseCase
   |
   v
Repository
   |
   v
DataSource
   |
   v
Client
```

O fluxo remoto completo e:

```text

<Feature>UseCase
   |
   v
I<Feature>Repository
   |
   v
<Feature>Repository
   |
   v
IRemote<Feature>DataSource
   |
   v
Remote<Feature>DataSource
   |
   v
IHttpClient
   |
   v
HttpClient
   |
   v
REST API
```

## Padrao de arquivos

Para uma feature chamada `budget`, a estrutura e:

```text
lib/src/
├── domain/use-cases/
│   └── budget-use-case.ts
├── domain/repositories/
│   └── interface_budget_repository.ts
├── domain/models/budget/
│   └── budget_model.ts
├── data/repositories/
│   └── budget_repository.ts
├── data/extensions/budget/
│   └── budget_response_extension.ts
├── infrastructure/datasources/remote/
│   └── remote_budget_data_source.ts
└── infrastructure/clients/http/
    ├── http_client.ts
    ├── endpoint_key.ts
    ├── requests/
    │   ├── requests.ts
    │   └── budget_request.ts
    └── responses/
        ├── reponses.ts
        ├── data_model.ts
        ├── budget/budget_response.ts
        └── failure/failure_response.ts
```

O arquivo `reponses.ts` e o arquivo compartilhado existente no projeto.
As classes de response especificas ficam organizadas por feature dentro de
`responses/`.

## Padrao de nomes

| Tipo | Nome do arquivo | Nome da classe |
|---|---|---|
| Notifier | `<feature>_notifier.ts` | `<Feature>Notifier` |
| Contrato de repository | `interface_<feature>_repository.ts` | `I<Feature>Repository` |
| Repository | `<feature>_repository.ts` | `<Feature>Repository` |
| Contrato de datasource remoto | `remote_<feature>_data_source.ts` | `IRemote<Feature>DataSource` |
| Datasource remoto | `remote_<feature>_data_source.ts` | `Remote<Feature>DataSource` |
| Contrato de datasource local | `local_<feature>_data_source.ts` | `ILocal<Feature>DataSource` |
| Datasource local | `local_<feature>_data_source.ts` | `Local<Feature>DataSource` |
| Contrato de client HTTP | `http_client.ts` | `IHttpClient` |
| Client HTTP | `http_client.ts` | `HttpClient` |
| Contrato de storage | `storage_client.ts` | `IStorageClient` |
| Client de storage | `storage_client.ts` | `StorageClient` |
| Request | `<feature>_request.ts` | `<Feature>Request` |
| Response | `<feature>_response.ts` | `<Feature>Response` |
| Model de dominio | `<feature>_model.ts` | `<Feature>Model` |
| Mapping de response | `<feature>_response_extension.ts` | `<Feature>ResponseExtension` |

Interfaces e implementacoes ficam no mesmo arquivo para clients e datasources:

```ts
abstract interface class IHttpClient {
  // contrato
}

final class HttpClient implements IHttpClient {
  // implementacao
}
```

Dependencias sao recebidas pelo construtor com parametro nomeado obrigatorio:

```ts
final class HttpClient implements IHttpClient {
  final Dio _dio;

  HttpClient({required this._dio});
}
```

## Exemplo remoto: Budget

### 1. Notifier

Arquivo:

```text
lib/src/presentation/ui/budget/notifiers/budget_by_id_notifier.ts
```

Classe:

```ts
BudgetByIdNotifier
```

O notifier depende apenas do contrato de dominio:

```ts
late IBudgetRepository _repository;

@override
Future<BudgetModel> build(int id) async {
  _repository = ref.watch(budgetRepositoryProvider);
  return await _findById(id);
}

Future<BudgetModel> _findById(int id) async {
  final data = await _repository.findById(id: id);
  return data.fold((failure) => throw failure, (model) => model);
}
```

O notifier nao conhece `Dio`, `HttpClient`, request, response ou datasource.

### 2. Contrato do Repository

Arquivo:

```text
lib/src/domain/repositories/interface_budget_repository.ts
```

Classe:

```ts
IBudgetRepository
```

O contrato usa tipos de dominio:

```ts
abstract interface class IBudgetRepository {
  Future<Either<Failure, BudgetModel>> findById({required int id});
}
```

O dominio conhece `Failure`, `BudgetModel` e `Either`, mas nao conhece HTTP,
Dio, requests ou responses.

### 3. Implementacao do Repository

Arquivo:

```text
lib/src/data/repositories/budget_repository.ts
```

Classe:

```ts
BudgetRepository
```

O repository depende da interface do datasource:

```ts
final class BudgetRepository implements IBudgetRepository {
  final IRemoteBudgetDataSource _dataSource;

  BudgetRepository({required this._dataSource});
}
```

Ele chama o datasource e converte os tipos de infraestrutura para tipos de
dominio:

```ts
@override
Future<Either<Failure, BudgetModel>> findById({required int id}) async {
  final data = await _dataSource.findById(id: id);

  return data.either(
    (failure) => failure.toFailure(),
    (response) => response.data.toModel(),
  );
}
```

Mappings ficam em `lib/src/data/extensions/`, nunca dentro da response:

```text
FailureResponse -> Failure
BudgetResponse  -> BudgetModel
```

### 4. Contrato do DataSource remoto

Arquivo:

```text
lib/src/infrastructure/datasources/remote/remote_budget_data_source.ts
```

Classes:

```ts
IRemoteBudgetDataSource
RemoteBudgetDataSource
```

O contrato aceita parametros simples de dominio e retorna DTOs de
infraestrutura:

```ts
abstract interface class IRemoteBudgetDataSource {
  Future<Either<FailureResponse, DataModel<BudgetResponse>>> findById({
    required int id,
  });
}
```

A interface nao recebe `BudgetRequest`. A implementacao cria o request:

```ts
final class RemoteBudgetDataSource implements IRemoteBudgetDataSource {
  final IHttpClient _client;

  RemoteBudgetDataSource({required this._client});
}
```

Exemplo de chamada:

```ts
final response = await _client.get(
  parameter: Requests('${EndpointKey.budgets.path}/$id'),
);

return response.toDataModel(
  (data) => BudgetResponse.fromJson(
    Map<String, dynamic>.from(data as Map),
  ),
);
```

O datasource e responsavel por:

- Escolher o endpoint.
- Criar `Requests`.
- Criar requests especificos, como `BudgetRequest`.
- Desserializar `BudgetResponse`.
- Desserializar `FailureResponse` por meio de `toDataModel` ou `either`.

### 5. Request

Arquivos:

```text
lib/src/infrastructure/clients/http/requests/requests.ts
lib/src/infrastructure/clients/http/requests/budget_request.ts
```

Classes:

```ts
Requests
BudgetRequest
```

`Requests` representa a requisicao generica:

```ts
Requests(
  EndpointKey.budgets.path,
  body: BudgetRequest(
    value: value,
    startDate: startDate,
    endDate: endDate,
    description: description,
  ).toJson(),
)
```

`BudgetRequest` representa o body especifico da feature e possui `toJson()`.
Ele converte o formato do dominio para o formato esperado pela API, como
centavos para string decimal e timestamp para data ISO.

### 6. Response

Arquivos:

```text
lib/src/infrastructure/clients/http/responses/budget/budget_response.ts
lib/src/infrastructure/clients/http/responses/data_model.ts
lib/src/infrastructure/clients/http/responses/failure/failure_response.ts
lib/src/infrastructure/clients/http/responses/reponses.ts
```

Classes e typedefs:

```text
BudgetResponse
DataModel<T>
FailureResponse
Responses
```

Responses possuem apenas `fromJson()` e nao possuem `toModel()`.

O `Responses` compartilhado representa o retorno bruto do client:

```ts
typedef Responses = Either<
  Map<String, dynamic>,
  Map<String, dynamic>
>;
```

Depois da desserializacao, o datasource retorna:

```text
Left  -> FailureResponse
Right -> DataModel<BudgetResponse>
```

### 7. Contrato do HTTP Client

Arquivo:

```text
lib/src/infrastructure/clients/http/http_client.ts
```

Classe e implementacao:

```ts
IHttpClient
HttpClient
```

O client recebe `Requests` e devolve dados JSON brutos:

```ts
abstract interface class IHttpClient {
  Future<Responses> get({required Requests parameter});
  Future<Responses> post({required Requests parameter});
  Future<Responses> put({required Requests parameter});
  Future<Responses> patch({required Requests parameter});
  Future<Responses> delete({required Requests parameter});
}
```

`HttpClient` implementa o contrato usando `Dio`:

```ts
final class HttpClient implements IHttpClient {
  final Dio _dio;

  HttpClient({required this._dio});
}
```

Responsabilidades do `HttpClient`:

- Executar os verbos HTTP.
- Enviar path, body, query e headers.
- Retornar `Right` com o JSON de sucesso.
- Retornar `Left` com o JSON de erro.
- Capturar `DioException`.
- Capturar erros inesperados.
- Nao deixar exceptions escaparem para o datasource.

O client nao conhece `Failure`, `BudgetModel` ou qualquer model de dominio.
O `try-catch` fica somente nessa camada.

## Fluxo de retorno remoto

```text
REST API
   |
   v
HttpClient
   | Responses
   | Left:  Map<String, dynamic> com erro
   | Right: Map<String, dynamic> com sucesso
   v
RemoteBudgetDataSource
   | Left:  FailureResponse
   | Right: DataModel<BudgetResponse>
   v
BudgetRepository
   | Left:  Failure
   | Right: BudgetModel
   v
BudgetByIdNotifier
   |
   v
AsyncValue<BudgetModel>
```

## Fluxo local: Storage Client

O storage e um client de infraestrutura separado do HTTP. Ele nao usa
`Either`, porque e um wrapper simples de persistencia local.

### Estrutura

```text
lib/src/
├── infrastructure/clients/storage/
│   ├── storage_client.ts
│   └── storage_key.ts
└── infrastructure/datasources/local/
    └── local_token_data_source.ts
```

### Interface e implementacao

Arquivo:

```text
lib/src/infrastructure/clients/storage/storage_client.ts
```

Classes:

```ts
IStorageClient
StorageClient
```

Contrato:

```ts
abstract interface class IStorageClient {
  Future<void> clear();
  Future<void> delete({required String key});
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}
```

Implementacao:

```ts
final class StorageClient implements IStorageClient {
  final FlutterSecureStorage _storage;

  StorageClient({required this._storage});
}
```

O detalhe `FlutterSecureStorage` fica escondido atras de `IStorageClient`.
Consumidores dependem da interface, nao da biblioteca externa.

### DataSource local

Arquivo:

```text
lib/src/infrastructure/datasources/local/local_token_data_source.ts
```

Classes:

```ts
ILocalTokenDataSource
LocalTokenDataSource
```

O datasource local depende de `IStorageClient`:

```ts
final class LocalTokenDataSource implements ILocalTokenDataSource {
  final IStorageClient _client;

  LocalTokenDataSource({required this._client});
}
```

Ele transforma operacoes genericas de chave e valor em operacoes de dominio
da persistencia de token:

```text
LocalTokenDataSource
   |
   v
IStorageClient
   |
   v
StorageClient
   |
   v
FlutterSecureStorage
```

O `LocalTokenDataSource` conhece `StorageKey`, mas o `StorageClient` nao
conhece tokens, autenticacao ou qualquer regra de negocio.

## Exemplo de autenticacao com remoto e local

O `AuthenticationRepository` combina os dois tipos de datasource:

```text
AuthenticationRepository
   ├── IRemoteAuthenticationDataSource
   │      └── IHttpClient
   └── ILocalTokenDataSource
          └── IStorageClient
```

No login:

```text
Notifier
   |
   v
IAuthenticationRepository
   |
   v
AuthenticationRepository
   ├── chama IRemoteAuthenticationDataSource.signIn()
   │      └── chama IHttpClient.post()
   └── salva tokens via ILocalTokenDataSource.save()
          └── grava via IStorageClient.write()
```

No logout ou verificacao de sessao, o repository pode ler e limpar os tokens
locais e, quando necessario, chamar a API remota.

## Regras de dependencia

```text
domain          nao conhece data, infrastructure ou presentation
data            conhece domain e interfaces de infrastructure
infrastructure  nao conhece presentation
presentation    conhece domain, mas nao conhece data nem infrastructure
main            faz o wiring de todas as implementacoes
```

Dependencias concretas sao registradas nos providers de `main/`. Features da
presentation recebem contratos via `ref.watch`, nunca instanciam `Dio`,
`FlutterSecureStorage`, `HttpClient` ou `StorageClient` diretamente.
