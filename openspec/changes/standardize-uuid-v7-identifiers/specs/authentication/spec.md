## MODIFIED Requirements

### Requirement: UserModel é o principal autenticável
O sistema MUST usar UserModel de Identity Infrastructure com PK UUIDv7 como principal resolvido por Sanctum, habilitar HasApiTokens e conservar Entity pura sem password/token/framework. MUST usar Model próprio de PAT UUIDv7 registrado pela API suportada do Sanctum, com tokenable_id UUID e morph type atual de UserModel. MUST NOT modificar vendor, gerar credencial própria ou reconstruir owner por coerção numérica.

#### Scenario: Principal resolvido pelo Sanctum
- **WHEN** um Bearer válido referencia PAT UUIDv7
- **THEN** request->user retorna UserModel de owner UUIDv7 correto
- **AND** currentAccessToken oferece o mesmo PAT do vínculo

#### Scenario: Domain permanece puro
- **WHEN** UserEntity é inspecionada
- **THEN** não implementa Authenticatable/HasApiTokens
- **AND** contém somente identidade definida por Identity, com validação UUIDv7 pura

### Requirement: Token de API é gerenciado pelo Sanctum
O sistema MUST delegar geração do segredo, hash SHA-256, lookup, autenticação/revogação ao Sanctum. PAT.id MUST ser UUIDv7, tokenable_id MUST representar User UUIDv7 e todos os IDs de sessão MUST permanecer strings canônicas nos contratos. Todo token emitido MUST ter expires_at; emissão/extensão MUST conceder até 30 dias e nunca ultrapassar 90 desde emissão. Atividade fora da janela MUST NOT deslocar prazo; expiração global MUST NOT antecipar validade. Extensão MUST conservar o mesmo UUID, hash e segredo sem refresh token/novo PAT. UUID do registro e segredo completo Bearer são conceitos distintos; o segredo não passa a ser UUID.

#### Scenario: Token persistido com segurança
- **WHEN** SignIn emite PAT
- **THEN** persiste UUIDv7, owner UUID, somente hash do segredo e expires_at em 30 dias
- **AND** plain-text token não é recuperável

#### Scenario: Acesso quinzenal
- **WHEN** a conta acessa a cada 15 dias com o mesmo Bearer dentro da validade/teto
- **THEN** sessão segue política de extensão
- **AND** UUID, hash, segredo e quantidade de tokens não mudam

#### Scenario: Expiração
- **WHEN** passam 30 dias da emissão/extensão sem atividade elegível nos últimos 15
- **THEN** auth:sanctum recusa com 401 JSON:API
- **AND** não reativa a sessão

#### Scenario: Atividade precoce não reinicia a contagem
- **WHEN** há somente acesso no primeiro dia com mais de 15 dias restantes
- **THEN** prazo inicial não muda
- **AND** não concede 30 dias adicionais

#### Scenario: Teto absoluto de 90 dias
- **WHEN** decorrem 90 dias de created_at
- **THEN** o token é recusado com 401
- **AND** requests posteriores não estendem além do teto

#### Scenario: Limpeza de expirados
- **WHEN** sanctum:prune-expired executa após a margem
- **THEN** remove PATs expirados, inclusive por UUIDv7, e conserva lifecycle de seus destinos
- **AND** validade não depende de pruning nem de expiração global ativada

### Requirement: Resposta de SignIn representa access token
SignIn válido MUST responder recurso access-tokens com data.id UUIDv7 canônico, relacionamento users com User UUIDv7 e segredo Bearer uma única vez. MUST conservar token_type Bearer, expires_at inicial, headers no-store/no-cache e media type JSON:API. expires_at MUST NOT prometer prazo imutável após atividade elegível; hashes/Model/detalhes de persistência MUST NOT aparecer.

#### Scenario: Resposta válida
- **WHEN** Sanctum emite PAT UUIDv7
- **THEN** responde 200 com seu UUID, token, token_type Bearer e expires_at em 30 dias
- **AND** relaciona a User autenticada pelo UUIDv7 correto

#### Scenario: Resposta não armazenável
- **WHEN** plain-text token é entregue
- **THEN** envia Cache-Control no-store, Pragma no-cache
- **AND** usa application/vnd.api+json

#### Scenario: Token não é relido
- **WHEN** respostas posteriores usam o PAT
- **THEN** o segredo não é relido/devolvido

#### Scenario: Validade inicial não é expiração imutável
- **WHEN** o cliente realiza atividade elegível depois do SignIn
- **THEN** a validade pode crescer até o teto, sem trocar UUID/segredo
- **AND** 401 continua exigindo novo SignIn

### Requirement: Sanctum reconhece Bearer token
Rotas protegidas MUST usar auth:sanctum e resolução oficial com o Model PAT UUIDv7 suportado. Bearer emitido com parte de ID UUIDv7 MUST autenticar sem casts numéricos. Prefixo de ID legado/malformado, credencial ausente/inválida, token expirado/revogado MUST resultar em 401 JSON:API, sem comparar literal UUID inválido no PostgreSQL nem gerar 500. MUST NOT criar JWT/protocolo próprio ou tratar UUID do PAT sozinho como segredo.

#### Scenario: Bearer válido
- **WHEN** Authorization contém PAT válido com parte ID UUIDv7
- **THEN** Sanctum resolve UserModel/owner correto
- **AND** disponibiliza currentAccessToken

#### Scenario: Credencial ausente ou inválida
- **WHEN** falta Bearer válido ou sua parte ID é numérica, outra versão UUID ou malformada
- **THEN** responde 401 JSON:API sem erro SQL/enumeração

#### Scenario: UUID sem segredo
- **WHEN** um cliente envia apenas o UUIDv7 de um PAT
- **THEN** não ganha sessão ou acesso à conta

### Requirement: Link público confirma somente a posse do e-mail
O sistema MUST confirmar sem login por GET público verification.verify com assinatura temporária válida, User UUIDv7 existente e hash do e-mail atual. MUST validar assinatura sobre a URL original antes de canonicalizar ID para lookup. MUST marcar somente email_verified_at atomicamente e emitir Verified depois do commit, sem alterar status/sessão/emitir PAT. Sucesso MUST ser 204 idempotente; falhas MUST seguir JSON:API. Links numéricos antigos não ganham tradução/alias.

#### Scenario: Conta pendente confirma o endereço
- **WHEN** pending usa link UUIDv7 válido e não expirado sem Bearer
- **THEN** marca verificação e emite Verified uma vez
- **AND** conserva pending, retorna 204 e não cria token

#### Scenario: Conta bloqueada confirma o endereço
- **WHEN** blocked usa link válido
- **THEN** confirma somente e-mail
- **AND** permanece blocked/sem acesso

#### Scenario: Link válido repetido
- **WHEN** o mesmo link ainda válido é repetido
- **THEN** 204 sem novo timestamp/evento
- **AND** não ativa conta

#### Scenario: Confirmação revertida
- **WHEN** a confirmação sofre rollback
- **THEN** email_verified_at permanece nulo
- **AND** Verified não é emitido

#### Scenario: Assinatura ou prazo inválido
- **WHEN** URL/UUID foi adulterado ou expirou
- **THEN** 403 JSON:API
- **AND** não altera conta/verificação/tokens

#### Scenario: Conta inexistente ou hash não corresponde ao endereço atual
- **WHEN** o link identifica UUID inexistente ou e-mail diferente
- **THEN** responde 403 uniforme
- **AND** não confirma nenhum endereço
