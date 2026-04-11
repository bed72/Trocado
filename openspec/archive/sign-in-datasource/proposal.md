# Proposal: sign-in-datasource

## Intenção

Implementar a camada de infraestrutura e dados para autenticação via sign-in (email + password),
retornando os tokens JWT de acesso e refresh.

## Motivação

É o pré-requisito para qualquer feature autenticada do app. Sem os tokens não há como
consumir endpoints protegidos da API.

## Camadas afetadas

- `domain/models/` — `AuthenticationModel` (access, refresh)
- `domain/contracts/repositories/` — `IAuthenticationRepository`
- `infrastructure/clients/http/requests/` — `SignInRequest`
- `infrastructure/clients/http/responses/` — `SignInResponse`
- `infrastructure/datasources/remote/` — `IRemoteAuthenticationDataSource` + `RemoteAuthenticationDataSource`
- `data/repositories/` — `AuthenticationRepository`
- `main/` — providers Riverpod para datasource e repositório

## Fora do escopo

- Persistência local dos tokens (secure storage)
- Interceptor de autenticação no Dio (Authorization header)
- Refresh automático de token
- Sign-out
- Tela de sign-in (presentation layer)
- Notifier MVI
