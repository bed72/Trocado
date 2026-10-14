## ADDED Requirements

### Requirement: Solicitação de push é capacidade interna explícita
O sistema MUST oferecer capacidade interna de solicitar push para `user_id` explícito, com `notification_id` estável, mensagem limitada e instantes explícitos. MUST NOT expor disparo público, aceitar destinatário decidido por payload livre ou introduzir gatilho de produto não aprovado. Outros contextos MUST depender de contrato transversal, sem importar Models/UseCases de Notifications.

#### Scenario: Solicitação interna válida
- **WHEN** um caller autorizado solicita mensagem válida para uma conta explícita
- **THEN** a capacidade prepara processamento somente para os registros elegíveis dessa conta
- **AND** o resultado distingue publicação de jobs de entrega/recepção pelo cliente

#### Scenario: Ausência de disparo público
- **WHEN** um cliente tenta enviar push por HTTP ou cadastrar trigger arbitrário
- **THEN** não existe endpoint de disparo que execute essa intenção

### Requirement: Mensagem é limitada e não concede acesso ao recurso
A mensagem MUST ter ID UUID, título genérico de até 80 caracteres, corpo genérico de até 240 e data com somente strings de catálogo fechado (`notification_id`, `action`, `resource_id` opcional). MUST NOT conter credenciais, tokens, valores/descrições financeiras ou URL arbitrária. O payload FCM final MUST respeitar 4 KiB em bytes incluindo serialização/overhead. Navigation MUST apontar a action aprovada; acesso ao recurso MUST depender da API autenticada, não do push.

#### Scenario: Payload fora do contrato
- **WHEN** a solicitação inclui campo não permitido, tamanho excedido, action desconhecida ou informação sensível
- **THEN** a solicitação é rejeitada antes de publicar qualquer job ou chamar FCM

#### Scenario: Deep link recebido por outra sessão
- **WHEN** o cliente abre uma action com `resource_id` depois de logout ou troca de conta
- **THEN** precisa autenticar e reconsultar o recurso sob ownership atual
- **AND** o push não fornece conteúdo protegido nem autorização alternativa

### Requirement: Publicação ocorre após commit e não usa fallback síncrono
Intenções originadas em operação transacional MUST ser publicadas somente depois do commit confirmado e MUST NOT executar Firebase dentro de callbacks sujeitos a retry. A queue MUST usar conexão Redis e fila push configuradas, sem fallback sync. Falha de publicação MUST ser explícita e observável sem reverter estado de negócio já confirmado; esta capacidade MUST NOT prometer recuperação durável de intenção sem outbox.

#### Scenario: Operação revertida
- **WHEN** uma operação produtora sofre rollback ou uma tentativa transacional é abortada
- **THEN** nenhum job ou envio correspondente à tentativa é publicado

#### Scenario: Redis indisponível após confirmação
- **WHEN** a operação de negócio confirma e a publicação falha por Redis indisponível
- **THEN** o estado de negócio permanece confirmado e a falha de publicação é informada à capacidade/observabilidade
- **AND** não há envio síncrono nem declaração de entrega eventual garantida

#### Scenario: Worker parado
- **WHEN** os jobs são publicados e o worker da fila push está parado
- **THEN** aguardam processamento sem chamada FCM no request produtor

### Requirement: Fanout é isolado por instalação
Uma solicitação MUST preparar no máximo um job por registro elegível no snapshot, com owner, registro, geração esperada, mensagem e prazo. MUST NOT colocar token/FID/credencial no job. Ausência de destinos MUST produzir `no_targets` sem jobs/FCM. Falha em publicação ou envio de um destino MUST NOT impedir os demais nem repetir automaticamente o lote inteiro.

#### Scenario: Múltiplas instalações
- **WHEN** a conta tem duas instalações elegíveis e ambas são publicadas
- **THEN** dois jobs independentes referenciam seus IDs/gerações e a mesma `notification_id`
- **AND** nenhum deles contém o identificador recuperável do destino

#### Scenario: Nenhum destino
- **WHEN** a conta não tem registro elegível
- **THEN** a solicitação retorna `no_targets`, com zero jobs e zero chamada Firebase

#### Scenario: Publicação parcialmente concluída
- **WHEN** o primeiro destino é enfileirado e a publicação do segundo falha
- **THEN** o resultado/diagnóstico registra publicação parcial e contagens efetivas
- **AND** o primeiro job não é republicado como compensação automática

#### Scenario: Um destino rejeitado
- **WHEN** uma instalação é rejeitada permanentemente pelo FCM e outra é válida
- **THEN** a instalação válida continua seu processamento independente

### Requirement: Worker revalida proprietário e geração antes de cada tentativa
Antes de cada chamada externa, o worker MUST reler registro por owner/ID e verificar geração, frescura, sessão/conta e prazo. Destino removido, alterado, transferido ou inelegível MUST resultar em `skipped` sem transporte. A tentativa MUST NOT ser redirecionada ao destino novo ou a outro proprietário. Revalidação MUST ocorrer também após backoff; não há garantia de recolher mensagem já aceita ou impedir chamada já em voo.

#### Scenario: Logout antes do consumo
- **WHEN** a sessão é revogada antes de o job ser consumido
- **THEN** o registro ausente resulta em `skipped` sem chamada FCM

#### Scenario: Rotação antes do consumo
- **WHEN** a instalação troca de destino/sessão e geração depois da publicação
- **THEN** o job antigo é descartado e não usa o destino novo

#### Scenario: Conta bloqueada ou sessão vencida
- **WHEN** a conta perde aptidão ou a sessão vence antes de qualquer tentativa, inclusive durante backoff
- **THEN** a tentativa é descartada sem depender de pruning

#### Scenario: Exclusão e novo cadastro
- **WHEN** o registro foi excluído e a instalação cadastrada novamente por outra conta
- **THEN** o job anterior não encontra vínculo elegível por owner/ID/geração e não envia à nova conta

### Requirement: Mensagem expira e TTL acompanha o prazo restante
Solicitações MUST ter `expires_at` futuro e no máximo uma hora após `requested_at`. O worker MUST descartar mensagem quando `now >= expires_at`, limitar TTL FCM ao prazo restante e MUST NOT programar retry que só execute após a expiração. O tempo em queue MUST contar para a validade.

#### Scenario: Fila demora além da validade
- **WHEN** o worker consome o job no instante de expiração ou depois dele
- **THEN** encerra como `skipped` sem transporte

#### Scenario: Tempo restante
- **WHEN** a mensagem de uma hora ficou 20 minutos na queue e o destino ainda é elegível
- **THEN** o TTL enviado não supera os 40 minutos restantes

### Requirement: Transporte FCM é autenticado server-side e compatível
O transporte MUST usar API atual e autenticação server-side suportada, projeto explicitamente configurado e identificador compatível com SDKs aprovados. MUST NOT usar API legacy, server key no cliente, JWT/OAuth próprio ou assumir suporte a FID a partir do nome do campo. Credencial ausente/incompatível MUST produzir falha operacional segura, sem simular aceitação.

#### Scenario: Configuração válida
- **WHEN** o Adapter envia destino compatível com projeto e perfil aprovados
- **THEN** usa autenticação server-side e método de envio suportados
- **AND** credenciais ficam fora do código fonte/payload cliente

#### Scenario: Configuração ausente ou incompatível
- **WHEN** faltam credenciais/projeto ou o transporte não suporta o tipo de registro
- **THEN** não declara sucesso e informa falha sanitizada sem expor segredo

### Requirement: Aceitação pelo provedor não é entrega ou leitura
Resposta de sucesso do FCM MUST ser classificada como `accepted` e pode carregar message ID técnico. MUST NOT produzir estado `delivered`, `read` ou afirmação de recepção sem evidência específica do cliente/provedor. O sistema MUST NOT criar inbox ou histórico permanente de mensagens como efeito implícito desse envio.

#### Scenario: FCM retorna sucesso
- **WHEN** o transporte recebe confirmação de aceitação com message ID
- **THEN** o job conclui como `accepted`, com observabilidade de aceitação
- **AND** não registra leitura, entrega confirmada ou linha de histórico de inbox

### Requirement: Erro de destino invalida somente a geração enviada
Resposta documentada de registro inexistente MUST remover apenas o registro proprietário na geração que originou a tentativa. `INVALID_ARGUMENT` MUST ser classificado pelos detalhes e MUST NOT apagar destino quando a causa puder ser payload inválido. Remoção MUST usar comparação atômica de owner/ID/geração e não afetar rotação recente ou outro dispositivo.

#### Scenario: Destino não registrado
- **WHEN** FCM informa `UNREGISTERED` para o destino enviado e a geração continua a mesma
- **THEN** esse registro é removido e outros destinos permanecem

#### Scenario: Erro antigo após rotação
- **WHEN** a instalação confirma geração nova enquanto a resposta de invalidez da anterior está em voo
- **THEN** a limpeza condicional da geração antiga não remove o destino novo

#### Scenario: Payload rejeitado
- **WHEN** FCM informa `INVALID_ARGUMENT` por payload inválido ou causa ambígua
- **THEN** a tentativa falha sem apagar o destino

### Requirement: Falhas temporárias usam retry limitado por destino
Quota, `429`, indisponibilidade `5xx` e erros temporários de rede MUST seguir backoff com jitter e `Retry-After`, respeitando recomendações do método FCM escolhido e expiração. Cada job MUST ter no máximo cinco tentativas totais; os quatro atrasos-base MUST ser de pelo menos 10, 30, 120 e 300 segundos, sem reduzir o mínimo de quota exigido pelo FCM. Falhas permanentes de payload/configuração MUST NOT receber retry cego. Esgotamento MUST ser observável e não remover destino por simples indisponibilidade.

#### Scenario: Indisponibilidade temporária
- **WHEN** o destino recebe falha `5xx` na primeira tentativa e ainda há prazo
- **THEN** somente seu job agenda tentativa posterior conforme backoff
- **AND** não apaga registro nem repete jobs de outros destinos já aceitos

#### Scenario: Quota informa espera
- **WHEN** FCM retorna `429` com `Retry-After` superior ao atraso-base
- **THEN** o job respeita o prazo maior e o mínimo de quota documentado

#### Scenario: Limite de tentativas
- **WHEN** cinco tentativas temporárias falham dentro da validade
- **THEN** o job encerra por esgotamento e registra falha sanitizada
- **AND** não faz sexta chamada nem invalida registro por indisponibilidade

#### Scenario: Falha permanente de projeto
- **WHEN** o destino é recusado por sender/projeto incompatível ou permissão inválida
- **THEN** a tentativa termina como falha operacional permanente sem apagar destinos ou repetir cegamente

### Requirement: Duplicação e lacunas de publicação são explícitas
O sistema MUST distinguir intenção, publicação e aceitação, e MUST NOT prometer exactly-once, deduplicação durável ou atomicidade entre PostgreSQL, Redis e FCM. Retries/redelivery MUST preservar `notification_id` para correlação/UX, sem tratá-la como prova de ausência de duplicatas. Push MUST NOT ser fonte única de estado de negócio.

#### Scenario: Timeout depois de possível aceitação
- **WHEN** FCM pode ter aceitado a mensagem antes de timeout e ocorre retry
- **THEN** a mesma `notification_id` é preservada e duplicação continua possível
- **AND** o servidor não classifica a primeira tentativa desconhecida como entrega comprovada

#### Scenario: Redelivery de job
- **WHEN** a queue entrega novamente um job já possivelmente aceito
- **THEN** são reaplicadas elegibilidade e expiração
- **AND** não existe alegação de deduplicação durável sem ledger implementado

### Requirement: Diagnóstico de push é estruturado e sanitizado
O sistema MUST observar cadastro, publicação, aceitação, descarte, retry, falha e invalidação por eventos estruturados correlacionáveis. Campos MUST ser allowlist de IDs técnicos, geração, plataforma, contagens, tentativa, motivo normalizado, latência e message ID. MUST NOT registrar token/FID/fingerprint, Bearer, credencial, mensagem, dados financeiros, documento HTTP ou resposta/exceção FCM bruta. Mutação de registro MUST ser observada somente após commit; falha de logger MUST NOT desfazer persistência confirmada. Payloads de queue/failed jobs MUST conter apenas o conteúdo mínimo aprovado e nunca segredos de transporte/destino.

#### Scenario: Falha do SDK inclui request sensível
- **WHEN** uma exceção do transporte contém header de autorização, destino e payload bruto
- **THEN** logs/failed jobs recebem somente erro normalizado sem esses dados

#### Scenario: Worker processa jobs consecutivos
- **WHEN** dois jobs de solicitações diferentes usam o mesmo processo
- **THEN** cada evento conserva sua correlação e não herda o contexto do job anterior

#### Scenario: Logger indisponível após cadastro
- **WHEN** a escrita do registro confirmou e o destino de logs falha
- **THEN** o cadastro permanece confirmado e sua resposta de sucesso é preservada

### Requirement: Queue e transporte permanecem nas bordas
Domain/Application MUST ser independentes de Laravel, Firebase, HTTP Client, Redis e Models. O UseCase MUST definir a intenção/unidade e depender de Repository/Ports tipados; job e Adapter MUST ser finos e executar envio fora de transação de banco. Configuração MUST definir timeout de rede menor que timeout do job e timeout do job menor que `retry_after`, sem locks de banco durante I/O FCM.

#### Scenario: Revisão de fronteiras e execução
- **WHEN** dependências, fluxo do worker e configuração são inspecionados
- **THEN** SDK/queue/rede aparecem somente em Infrastructure e os contratos de Application não os expõem
- **AND** chamadas FCM não ocorrem sob transação/lock PostgreSQL aberto

### Requirement: Validação externa não é simulada por testes internos
A evidência futura MUST separar orquestração com doubles, persistência PostgreSQL, consumo real de worker em fila exclusiva e smoke test FCM em ambiente consentido. Suíte comum MUST NOT enviar para Firebase real. Compatibilidade/recepção no cliente MUST permanecer não comprovada até validação específica da plataforma aprovada.

#### Scenario: Suíte automatizada
- **WHEN** verificações de Application, Adapter e worker executam no launcher do projeto
- **THEN** transporte FCM é simulado e recursos de queue pertencem exclusivamente à execução
- **AND** sucesso desses checks não é descrito como prova de recepção no dispositivo

#### Scenario: Homologação real
- **WHEN** projeto e instalação de teste consentidos recebem uma mensagem do transporte configurado
- **THEN** a evidência distingue aceitação server-side de recepção no cliente e informa plataforma/SDK
- **AND** não envolve contas reais sem autorização
