# Proposal: http-client

## Intenção

Implementar o cliente HTTP da aplicação usando Dio, seguindo a arquitetura Clean Architecture do projeto.
O Client é o único ponto de entrada para comunicação HTTP e o único lugar onde ocorre `try-catch`.

## Motivação

Toda feature que consuma a API REST do backend depende de um Client HTTP bem definido.
Sem ele, nenhum datasource remoto pode ser implementado.

## Camadas afetadas

- `infrastructure/clients/http/` — interface `IHttpClient` e implementação `DioHttpClient`
- `infrastructure/clients/http/responses/` — `FailureResponse` e `ErrorItemResponse` (compartilhados)

## Fora do escopo

- Interceptors de autenticação (JWT) — serão adicionados em feature separada
- Refresh de token
- Cache de respostas
- Qualquer datasource concreto
- Modelos de domínio
- Camada `presentation/`
