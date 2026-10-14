## Why

O Trocado precisa enviar notificações push individuais via Firebase Cloud Messaging (FCM), mantendo o vínculo correto entre conta, sessão e instalação do aplicativo. Um campo em `users` não representa múltiplos dispositivos nem permite tratar rotação, logout e invalidação dos destinos com segurança.

## What Changes

- Introduzir o contexto `Notifications`, proprietário do cadastro e ciclo de vida dos destinos push e da integração de envio com FCM.
- Persistir destinos na tabela `notifications` do PostgreSQL, renomeada incrementalmente de `push_registrations`: uma conta pode ter várias instalações; cada instalação tem no máximo um vínculo ativo e um destino vigente. Não é histórico de mensagens nem o canal database Laravel.
- Expor cadastro/atualização idempotente e remoção de registro pela API autenticada, com documentos JSON:API, ownership e limites existentes.
- Vincular o registro à sessão que o cadastrou: revogação remove seus registros, expiração impede novos envios e encerramento da conta remove todos os destinos.
- Oferecer uma capacidade interna de solicitar push para uma conta, com transporte assíncrono, validação do destino no processamento, falhas por instalação e retries limitados.
- Manter credenciais Firebase exclusivamente na Infrastructure e identificar aceitação pelo FCM sem prometer entrega ou leitura.
- Prever observabilidade sanitizada e evidência futura de HTTP, persistência PostgreSQL, worker, concorrência e fronteiras.
- Atender somente Android e iOS, com cliente Flutter e pacotes oficiais Firebase; vínculo ao PAT e suspensão após expiração aprovados pelo usuário. O usuário autorizou a fatia de cadastro POST/DELETE e confirmou exclusivamente token FCM (`registration_kind = token`). Versões/payload real ainda dependem de homologação; projeto Firebase, transporte e primeiro evento de produto permanecem futuros. A criação da spec, isoladamente, não autoriza implementar, adicionar dependências, testes ou operar filas.

Não haverá histórico de mensagens, central de lidas/não lidas, outbox, ledger de entregas, campanhas, tópicos, Firebase Authentication, Firestore ou disparo público nesta etapa. A tabela `notifications` contém **destinos**, não mensagens. Nenhum contrato HTTP existente terá quebra deliberada; efeitos adicionais do logout atingem apenas os novos registros push associados à sessão revogada.

## Capabilities

### New Capabilities

- `push-registration`: cadastro autenticado, múltiplas instalações, rotação, ownership, concorrência e ciclo de vida dos destinos push.
- `firebase-push-delivery`: solicitação interna, processamento assíncrono por instalação, integração FCM, classificação de falhas, limites de retry e observabilidade.

### Modified Capabilities

Nenhuma alteração dos requisitos atuais: SignOut continua revogando somente o token atual, e a política de sessão permanece a de Identity. As novas specs definem o efeito desse ciclo de vida sobre os novos destinos. As rotas push usarão a cota autenticada existente, sem mudar suas regras ou valores para os endpoints atuais.

## Impact

- **Persistência:** migrations incrementais de criação e renomeação para `notifications`, constraints de unicidade, foreign keys e classificação no cleanup de testes. Sem backfill, alteração de migrations históricas ou limpeza de dados existentes.
- **Backend:** novas camadas em `app/Notifications/`; contratos transversais de Core para colaboração explícita; Adapter de Identity para comprovação de sessão/aptidão, sem imports de Identity em Notifications.
- **HTTP:** `POST /api/push-registrations` e `DELETE /api/push-registrations/{registration}`. Sem rota pública de envio ou listagem global de destinos.
- **Operação:** projeto FCM, credencial server-side, APIs habilitadas, fila Redis e worker na fila configurada. Timeouts, expiração, backoff e logs devem ser definidos antes da liberação.
- **Dependências:** escolher HTTP v1 com autenticação suportada ou pacote compatível somente após confirmar os SDKs. Nenhum pacote Firebase consta no inventário consultado; sua instalação exige aprovação explícita.
- **Clientes:** obter permissão push, cadastrar a instalação após login, sincronizar alterações do destino e limpar estado local no logout/troca de conta.
- **Escopo de produto:** esta mudança entrega a infraestrutura de push. O primeiro evento, texto e deep link precisam ser escolhidos; não se presume notificação de Expense, Insights ou Metrics.
