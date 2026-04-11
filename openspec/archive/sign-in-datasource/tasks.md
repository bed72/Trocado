# Tasks: sign-in-datasource

## domain/

- [x] `lib/src/domain/models/authentication_model.dart` — `AuthenticationModel` (access, refresh, copyWith, Equatable)
- [x] `lib/src/domain/contracts/repositories/i_authentication_repository.dart` — `IAuthenticationRepository` com método `signIn`

## infrastructure/

- [x] `lib/src/infrastructure/clients/http/requests/sign_in_request.dart` — `SignInRequest` (email, password, toJson)
- [x] `lib/src/infrastructure/clients/http/responses/sign_in_response.dart` — `SignInResponse` (access, refresh, fromJson, toModel)
- [x] `lib/src/infrastructure/datasources/remote/remote_authentication_data_source.dart` — `IRemoteAuthenticationDataSource` + `RemoteAuthenticationDataSource`

## data/

- [x] `lib/src/data/repositories/authentication_repository.dart` — `AuthenticationRepository` implements `IAuthenticationRepository`

## main/

- [x] Providers `@riverpod` para `RemoteAuthenticationDataSource` e `AuthenticationRepository`
- [x] `dart run build_runner build --delete-conflicting-outputs`

## Testes

- [x] `test/mocks/mocks.dart` — adicionar `MockHttpClient` (se ainda não existir)
- [x] `test/src/infrastructure/responses/sign_in_response_test.dart` — `fromJson` e `toModel`
- [x] `test/src/data/repositories/authentication_repository_test.dart` — mock em `IHttpClient`
