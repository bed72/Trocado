# Spec: Health Check & Connectivity Guard no Splash

## Contexto

Hoje o `SplashNotifier` vai direto para `checkSession()`. Se o servidor estiver fora ou o device sem internet, o usuário fica preso na splash sem feedback. Precisamos de um guard que verifica conectividade e saúde do servidor **antes** do fluxo de autenticação.

## Fluxo

```
SplashNotifier.build()
  │
  ├─ 1. Verificar conectividade de rede (local, sem request)
  │     ├─ sem internet → emitir SplashStatus.noConnection
  │     └─ com internet ↓
  │
  ├─ 2. GET /health/
  │     ├─ 200 + status "ok" → continua ↓
  │     └─ qualquer outro resultado → emitir SplashStatus.maintenance
  │
  └─ 3. checkSession() (fluxo atual)
        ├─ autenticado → SplashStatus.authenticated
        └─ não autenticado → SplashStatus.unauthenticated
```

## Contrato da API

**GET /health/** — endpoint público (sem auth)

Response 200:
```json
{
  "status": "ok",
  "version": 1,
  "components": {
    "db": "ok",
    "cache": "ok",
    "worker": {
      "status": "ok",
      "heartbeat_age_seconds": 5.94
    },
    "queue": {
      "depth": 0,
      "warning": false
    }
  }
}
```

O app só valida `status == "ok"`. Os `components` são informacionais.

## Camadas impactadas

### 1. Domain

- `SplashStatus` — +`noConnection`, +`maintenance`
- `IConnectivityService` — interface de serviço (`Future<bool> hasConnection()`)
- `IHealthRepository` — interface de repositório (`Future<Either<Failure, bool>> check()`)

### 2. Infrastructure

- `HealthResponse` — response com `status` e `version`
- `EndpointKey.health` — `/health/`, marcado como público
- `RemoteHealthDataSource` — GET no endpoint, retorna `Either<FailureResponse, HealthResponse>`
- `ConnectivityService` — `connectivity_plus` + DNS lookup

### 3. Data

- `HealthRepository` — decide `status == 'ok'`, retorna `Either<Failure, bool>`

### 4. Presentation

- `SplashNotifier` — guard: rede → health → session, método `retry()`
- `SplashScreen` — switch no body: logo (loading/navegação) ou erro inline
- `SplashErrorWidget` — ícone, título, mensagem e botão retry (noConnection vs maintenance)

### 5. Testes

- `HealthResponse.fromJson` — parse de campos
- `HealthRepository` — 4 cenários (ok, degraded, server error, network error)
- `SplashNotifier` — 5 cenários (noConnection, maintenance×2, authenticated, unauthenticated)

## Fora de escopo

- Model de domínio para HealthResponse
- Tela separada de erro
- Cache do health check
- Polling/auto-retry com timer
- Verificação dos components individuais
