# Proposal: fcm-token-on-logout

## Intenção

Revogar o token FCM no backend quando o usuário faz logout. `DELETE /api/v1/me/fcm-token` com body `{"token": "..."}` apaga o registro deste device, mantendo intactos os tokens de outros devices do mesmo user (cenário multi-device — casal usando app em vários celulares).

## Motivação

Sem revogação explícita, após logout o backend continua tratando o device como "ativo" até:
- (a) Próximo envio de push retornar `UNREGISTERED` — pode demorar dias, e o backend cleanup é reativo apenas;
- (b) Cleanup periódico de 90 dias passar.

Pior cenário: user A loga no device X, depois loga no device Y, depois faz logout no device Y. Sem DELETE, o backend continua acreditando que o device Y receberia push de user A — confusão potencial em handoff de devices entre usuários do mesmo casal.

Contrato confirmado via curl ground truth (backend já implementou na rodada anterior):

```http
DELETE /api/v1/me/fcm-token
Authorization: Bearer <jwt>
Content-Type: application/json

{ "token": "<fcm-token>" }
```

Sempre retorna `204` — idempotente em todos os cenários (token desconhecido, já revogado, pertence a outro user).

## Camadas afetadas

- `domain/repositories/` — `INotificationRepository` ganha `revokeToken()` (sem params, mesma assinatura de `registerToken`).
- `infrastructure/clients/http/requests/` — novo `FcmTokenDeleteRequest({token})` com `toJson()` retornando só `{token}`.
- `infrastructure/datasources/remote/` — `IRemoteNotificationDataSource.revokeToken()` + impl que pega token via `IMessagingClient`, posta DELETE com body.
- `data/repositories/notification_repository.dart` — `revokeToken()` faz forward + mapping de failure.
- `data/repositories/authentication_repository.dart` — injeta `INotificationRepository`, dispara `unawaited(_notificationRepository.revokeToken())` como primeira linha do `logout()`.
- `main/providers/repositories_provider.dart` — passa `notificationRepository` ao `authenticationRepository`.

Nada em `presentation/`.

## Fora do escopo

- Bulk DELETE ("sign-out-everywhere") — backend não implementou; spec futura se aparecer demanda.
- Cleanup ao deletar conta — responsabilidade do backend via cascade.
- Persistência local de "último token deletado" — backend dedupe.
- Retry em caso de falha — fire-and-forget cobre via 90d periodic do backend.

## Decisões de design

1. **`revokeToken()` sem params, simétrico a `registerToken()`.**
   DataSource orquestra o fetch via `IMessagingClient.getToken()`, exatamente como `registerToken()` faz (Spec 1). Quem chama (`AuthenticationRepository`) não precisa importar `IMessagingClient` — fronteira de camada preservada.

2. **`FcmTokenDeleteRequest` separado de `FcmTokenRequest`.**
   Body do DELETE é `{token}` apenas — sem `platform`. Criar DTO próprio mantém serialização precisa e evita sobrecarregar `FcmTokenRequest` com flags opcionais.

3. **Plug em `AuthenticationRepository.logout()`, primeira linha.**
   - Encapsula "logout = limpar tudo (server + local)" coeso. Presentation não muda.
   - Primeira linha garante que o Bearer ainda está válido no interceptor quando o DELETE sair (a `signOut` do backend invalida o token, então ordem importa).
   - `unawaited(...)` — DELETE roda em paralelo ao resto do logout; falha não bloqueia o fluxo.

4. **Token `null` do `IMessagingClient` → `Right(null)` no DataSource.**
   Mesmo tratamento de `registerToken()`: `null` é estado esperado (Firebase não disponível, iOS sem APNs). Não é falha. Backend 90d periodic cobre.

5. **Backend sempre retorna 204 → cliente trata 4xx/5xx só como erro de rede.**
   `FailureResponse` path existe pra cobrir erro de rede genuíno (timeout, 5xx, sem conexão). Backend não retorna 400 com erro de validação aqui.

6. **Sem alteração no `IHttpClient`.**
   `delete({required Requests parameter})` já existe e passa `parameter.body` como `data` pro Dio. Suporte a DELETE com body é nativo.

7. **`AuthenticationRepository` ganha dependência em `INotificationRepository`.**
   Domain interface, OK pela camada. Adiciona uma linha no provider wiring.
