## ADDED Requirements

### Requirement: Registros push pertencem a uma conta e uma instalação
O sistema MUST persistir destinos push separadamente da identidade da conta, permitindo múltiplas instalações por conta e no máximo um vínculo vigente por instalação. ID do registro, proprietário, sessão/PAT e instalação MUST usar UUIDv7 canônico conforme a change coordenada `standardize-uuid-v7-identifiers`. Cada registro MUST identificar proprietário, sessão de cadastro, plataforma, provedor, tipo de destino, destino recuperável, geração e última sincronização. UUID local da instalação MUST NOT ser interpretado como prova de ownership, FID ou token de autenticação nem confundido com a PK do registro.

#### Scenario: Dois dispositivos da mesma conta
- **WHEN** uma conta apta cadastra duas instalações distintas com destinos distintos
- **THEN** existem dois registros independentes associados à mesma conta
- **AND** o segundo cadastro não sobrescreve o primeiro

#### Scenario: Identidade local não autentica
- **WHEN** um cliente informa apenas UUID de instalação ou destino push sem Bearer válido
- **THEN** a API responde `401` sem cadastrar ou alterar registro

### Requirement: Cadastro é autenticado e não amplia a sessão
`POST /api/push-registrations` MUST exigir Personal Access Token Sanctum válido, conta ativa e e-mail confirmado. O proprietário e a sessão MUST ser resolvidos server-side, e a API MUST usar a cota autenticada compartilhada existente. Sincronização de registro push MUST NOT estender a sessão por atividade ou emitir um novo token.

#### Scenario: Conta apta
- **WHEN** uma conta ativa/verificada apresenta Bearer válido e documento válido dentro da cota
- **THEN** o registro é associado ao proprietário e à sessão autenticados
- **AND** nenhum token é emitido e `expires_at` da sessão não é estendido por esse request

#### Scenario: Conta não apta
- **WHEN** um Bearer ainda persistido pertence a conta bloqueada, pendente ou sem e-mail confirmado
- **THEN** responde `403` JSON:API sem persistir o registro

#### Scenario: Cota compartilhada
- **WHEN** a conta esgotou sua cota autenticada em outros endpoints e tenta cadastrar destino
- **THEN** responde `429` JSON:API com `Retry-After`, sem escrita nem envio FCM
- **AND** alternar token ou IP não concede outra cota à mesma conta

### Requirement: Documento de cadastro é fechado e preserva destino exato
A API MUST aceitar documento JSON:API `push-registrations` com somente `installation_id`, `platform`, `registration_kind` e `registration_identifier` em `data.attributes`. MUST validar installation_id textual UUIDv7/variante RFC 9562, normalizando somente caixa válida, inclusive fora de HTTP; outras versões, números ou whitespace MUST produzir `422` em `/data/attributes/installation_id`, sem converter o ID ou ecoar destino. MUST validar plataforma exclusivamente `android` ou `ios` e `registration_kind` exclusivamente `token`, para token de registro FCM do cliente Flutter oficial. FID e token APNs direto MUST NOT ser usados como perfil alternativo; compatibilidade do transporte será comprovada na fatia de envio. O destino MUST ter de 1 a 4096 bytes ASCII sem whitespace/controle e MUST ser preservado exatamente, sem trim ou mudança de caixa. Entradas inválidas ou membros editáveis desconhecidos MUST produzir `422` com `source.pointer` sem eco do destino.

#### Scenario: Tentativa de definir proprietário
- **WHEN** o documento inclui `user_id`, `session_id`, `provider`, geração, timestamps, `data.id` ou `relationships`
- **THEN** responde `422` apontando o membro não permitido
- **AND** não ignora silenciosamente o campo nem altera outro proprietário

#### Scenario: Destino inválido
- **WHEN** o destino é vazio, não string, possui whitespace/controle, não é ASCII ou excede 4096 bytes
- **THEN** responde `422` com pointer `/data/attributes/registration_identifier`
- **AND** não inclui o valor sensível no detalhe

#### Scenario: Tipo sem suporte
- **WHEN** o cliente envia tipo ou plataforma fora do perfil aprovado, mesmo que exista na documentação Firebase
- **THEN** responde `422` sem converter o identificador ou alegar suporte ao SDK

#### Scenario: Plataforma web fora desta entrega
- **WHEN** o cliente envia `platform` igual a `web`
- **THEN** responde `422` com pointer `/data/attributes/platform`, sem cadastrar destino

#### Scenario: Instalação não UUIDv7
- **WHEN** installation_id é UUIDv4, outra versão, número ou texto com whitespace
- **THEN** responde `422` com pointer `/data/attributes/installation_id`, sem cadastrar ou converter a instalação
- **AND** não ecoa o destino FCM

#### Scenario: Caixa equivalente da instalação UUIDv7
- **WHEN** o proprietário sincroniza a mesma instalação UUIDv7 com caixa textual diferente
- **THEN** a forma minúscula canônica identifica a mesma instalação e o ID do registro é preservado

### Requirement: Sincronização de instalação é idempotente
O primeiro cadastro MUST responder `201`; sincronização da mesma instalação pelo mesmo proprietário MUST responder `200` e preservar o ID do registro. Repetição com mesmo destino, plataforma e sessão MUST atualizar somente a frescura/auditoria necessária sem aumentar a geração ou a quantidade de registros. A data de sincronização MUST vir do relógio server-side explicitamente resolvido na borda.

#### Scenario: Primeiro cadastro
- **WHEN** instalação e destino disponíveis são cadastrados por conta apta
- **THEN** responde `201` com ID UUIDv7 canônico gerado pelo servidor, distinto da identidade de instalação, e geração inicial positiva

#### Scenario: Cadastro repetido
- **WHEN** o mesmo proprietário repete a sincronização com os mesmos dados e sessão
- **THEN** responde `200` com o mesmo ID e uma única linha persistida
- **AND** `last_registered_at` é atualizado e a geração é preservada

### Requirement: Rotação troca destino sem acumular destinatários antigos
Alteração de destino, plataforma ou sessão da mesma instalação pelo mesmo proprietário MUST preservar ID, substituir o vínculo vigente e incrementar a geração atomicamente. O destino anterior MUST deixar de ser selecionado para novos envios; a troca MUST NOT alterar registros de outras instalações. Requests de rotação independentes MUST ser serializados, sem promessa de inferir a ordem temporal dos callbacks no cliente.

#### Scenario: Token renovado
- **WHEN** o proprietário sincroniza novo destino para a mesma instalação
- **THEN** existe uma linha com o novo destino, mesmo ID e geração superior
- **AND** o destino antigo não permanece como destinatário adicional

#### Scenario: Novo login na mesma conta
- **WHEN** a instalação ainda vinculada à mesma conta é cadastrada com outra sessão válida dessa conta
- **THEN** a sessão vigente é substituída e a geração aumenta
- **AND** revogar a sessão anterior não remove o vínculo já transferido à sessão nova

### Requirement: Conflitos não transferem ownership silenciosamente
Instalação ou destino vigente pertencente a outra conta MUST causar `409` uniforme, sem mutação do vínculo original e sem revelar o proprietário. Destino vinculado a outra instalação, inclusive da mesma conta, MUST causar conflito em vez de duplicação ou fusão silenciosa. Conhecer UUID/destino MUST NOT autorizar transferência entre contas.

#### Scenario: Troca de conta sem revogar vínculo anterior
- **WHEN** uma segunda conta tenta cadastrar instalação ou destino ainda vigente da primeira
- **THEN** responde `409` sem identificar a primeira conta nem substituir seu registro

#### Scenario: Destino duplicado na mesma conta
- **WHEN** a mesma conta tenta associar um destino existente a outro UUID de instalação
- **THEN** responde `409` e conserva uma única associação do destino

#### Scenario: Troca de conta após logout confirmado
- **WHEN** a sessão anterior foi revogada, seu registro foi removido e outra conta apta cadastra a instalação
- **THEN** um novo vínculo pode ser criado sem carregar o proprietário, ID ou geração anteriores

### Requirement: Cadastro é atômico sob concorrência e revogação
O UseCase MUST delimitar checagem bloqueante da sessão, ownership e escrita na mesma unidade por `TransactionPort`. O banco MUST impor unicidade da instalação e do fingerprint do destino. Corridas previstas MUST produzir sincronização idempotente ou conflito seguro, sem duplicação, estado parcial ou recriação de sessão revogada. Rollback MUST preservar o estado anterior e MUST NOT produzir efeito Firebase.

#### Scenario: Duas primeiras sincronizações iguais
- **WHEN** duas requisições concorrentes válidas cadastram a mesma instalação/destino para a mesma conta/sessão
- **THEN** uma responde `201` e a outra `200`, com o mesmo ID
- **AND** apenas um registro existe após os commits

#### Scenario: Duas contas disputam destino disponível
- **WHEN** duas contas distintas cadastram simultaneamente o mesmo destino ou instalação
- **THEN** no máximo um vínculo é confirmado e a tentativa conflitante recebe `409`

#### Scenario: Rotação concorrente
- **WHEN** duas rotações distintas para a mesma instalação e proprietário são confirmadas
- **THEN** o estado final corresponde ao último commit aceito, com geração monotônica
- **AND** não existe mistura parcial de destino, sessão, plataforma e fingerprint

#### Scenario: Cadastro disputa com SignOut
- **WHEN** logout e cadastro da mesma sessão executam concorrentemente
- **THEN** cadastro confirmado antes da revogação é removido pelo encerramento da sessão
- **AND** cadastro que encontra sessão já revogada é recusado sem recriar registro

#### Scenario: Falha após escrita dentro da unidade
- **WHEN** falha sentinela aborta a unidade de rotação após uma escrita
- **THEN** destino, sessão, geração e fingerprint anteriores permanecem integralmente
- **AND** nenhuma chamada FCM ou publicação push ocorre por esse cadastro

### Requirement: Remoção respeita ownership e não revoga autenticação
`DELETE /api/push-registrations/{registration}` MUST remover somente registro UUIDv7 do proprietário autenticado e responder `204`. Registro inexistente, ID malformado/de outra versão ou pertencente a outra conta MUST responder `404` uniforme em JSON:API, sem lookup UUID inválido. A remoção MUST NOT revogar sessão, apagar conta ou atingir outras instalações. MUST herdar autenticação, aptidão e cota do cadastro.

#### Scenario: Remoção de instalação própria
- **WHEN** a conta apta remove um de seus registros
- **THEN** responde `204` e esse registro deixa de ser selecionado para envio
- **AND** seus demais registros e sessões permanecem

#### Scenario: Registro alheio ou ausente
- **WHEN** a conta tenta remover registro alheio, desconhecido, malformado ou já removido
- **THEN** responde o mesmo `404` sem revelar outra conta ou modificar qualquer registro

### Requirement: Logout e encerramento da conta eliminam vínculos correspondentes
Revogação física de uma sessão MUST remover seus registros push por integridade do banco, sem depender de DELETE executado pelo cliente. Exclusão de conta MUST remover todos os seus destinos na unidade de encerramento existente. Outras sessões/contas MUST permanecer intactas. Expiração lógica MUST impedir novos envios mesmo antes de pruning.

#### Scenario: SignOut seletivo
- **WHEN** uma conta com instalações em duas sessões revoga a sessão atual pelo SignOut existente
- **THEN** registros ainda associados à sessão revogada são removidos e o SignOut conserva `204`
- **AND** registros ligados à outra sessão permanecem

#### Scenario: Conta removida
- **WHEN** o encerramento da conta é confirmado
- **THEN** todos os seus destinos são removidos sem chamada FCM dentro da transação

#### Scenario: Sessão expirada ainda no banco
- **WHEN** a sessão atingiu sua validade efetiva e ainda não foi removida pelo pruning
- **THEN** o vínculo não é elegível para envio
- **AND** sincronização com esse Bearer responde `401` sem reativar a sessão

### Requirement: Frescura do destino é independente da sessão
Um registro MUST ser elegível por frescura somente se a última sincronização aceita ocorreu há menos de 60 dias. Essa frescura MUST NOT substituir validade de sessão, estado da conta ou autorização. Sincronização válida MUST renovar frescura; staleness MUST NOT exigir exclusão automática, Scheduler ou reinício de sessão nesta etapa.

#### Scenario: Limite de frescura
- **WHEN** decorrem exatamente 60 dias desde a última sincronização aceita
- **THEN** o registro é descartado da seleção/envio por staleness

#### Scenario: Ressincronização válida
- **WHEN** instalação stale é sincronizada pelo proprietário com sessão válida e dados compatíveis
- **THEN** sua frescura é renovada e volta a ser elegível, sujeita às demais regras

### Requirement: Destinos são sensíveis e respostas são mínimas
O destino MUST ser armazenado de forma cifrada e recuperável apenas pelo backend; unicidade MUST usar fingerprint SHA-256 separado, calculado sobre provedor/tipo/identificador exatos com separadores NUL, sem chave auxiliar. Registros anteriores MUST ter fingerprints recalculados atomicamente a partir do destino cifrado, sem alterar ciphertext, owner, sessão, ID, geração ou timestamps; falha de decifragem/constraint MUST preservar todos os valores anteriores. A API MUST retornar apenas ID, instalação, plataforma, provedor e última sincronização em recurso JSON:API, com `Cache-Control: no-store`. MUST NOT expor destino, fingerprint, sessão, geração, credencial Firebase ou conteúdo sensível em sucesso, erro ou observabilidade.

#### Scenario: Conversão de fingerprints existentes
- **WHEN** a migration converte um registro cifrado persistido com fingerprint anterior
- **THEN** somente o fingerprint passa ao SHA-256 do destino exato e o cadastro repetido preserva a mesma linha/ID

#### Scenario: Falha durante conversão
- **WHEN** a conversão já escreveu um fingerprint e encontra um destino posterior impossível de decifrar
- **THEN** a unidade reverte também a escrita anterior, sem revelar destino/ciphertext/fingerprint no erro normalizado

#### Scenario: Cadastro responde sem segredo
- **WHEN** cadastro ou sincronização é aceito
- **THEN** a resposta usa tipo `push-registrations`, atributos públicos previstos e `no-store`
- **AND** não devolve identificador sensível nem header Location para rota inexistente

#### Scenario: Inspeção de persistência e diagnóstico
- **WHEN** a linha persistida e logs de cadastro/conflito são inspecionados
- **THEN** o campo recuperável não está em texto claro no banco
- **AND** os logs não contêm destino, fingerprint, credencial ou documento completo

### Requirement: Fronteiras de registro preservam autoridade de Identity
Notifications MUST obter identidade autenticada por `UserPort` de Core, definir a capacidade de sessão requerida em seu próprio `Application/Ports/NotificationPort`, persistir apenas seus registros por Repository e manter Controllers finos. Domain/Application MUST NOT importar Laravel, SDK, Eloquent ou Identity. A política de aptidão/sessão MUST ser comprovada por Adapter de Identity que implementa esse contrato do consumidor, com binding em Identity, sem duplicação de política temporal ou relação Eloquent entre contextos. Identity Infrastructure MUST importar somente essa interface de Notifications, sem permissão ampla para suas camadas/classes concretas. Core MUST NOT possuir esse contrato específico de cadastro.

#### Scenario: Inspeção de dependências
- **WHEN** os componentes de cadastro e bindings são revisados
- **THEN** UseCases usam Ports/Repository e tipos puros próprios/Core
- **AND** sessão/estado de conta são resolvidos na borda de Identity implementando o Port de Notifications, enquanto persistência pertence a Notifications
