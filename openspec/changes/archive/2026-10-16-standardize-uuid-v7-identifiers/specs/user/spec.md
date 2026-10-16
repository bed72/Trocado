## MODIFIED Requirements

### Requirement: Identidade local independente de autenticação
O sistema MUST representar UserEntity em Identity Domain com ID presente UUIDv7 canônico, NameValueObject e e-mail, sem password/hash/token. Ausência de ID antes da persistência MUST ser explícita, nunca inteiro/zero. Domain/Application MUST permanecer independentes de Laravel, Eloquent, HTTP, Sanctum e Infrastructure, podendo consumir o conceito puro UUID de Core. UserModel MUST integrar os contratos Laravel/Sanctum somente na borda. A transição local autorizada MUST NOT inventar credenciais, converter IDs antigos ou criar compatibilidade com usuários legados descartados.

#### Scenario: Entidade criada com credencial fora do Domain
- **WHEN** SignUp registra nome, e-mail e password válidos
- **THEN** UserEntity representa somente a identidade criada com UUIDv7
- **AND** password hash e tokens permanecem fora da Entity

#### Scenario: Usuário preexistente permanece sem credencial conhecida
- **WHEN** o ambiente legado é substituído pelo reset local autorizado, sem dados a conservar
- **THEN** nenhuma credencial antiga é recuperada ou sintetizada
- **AND** novas contas só recebem credenciais pelo fluxo explícito de SignUp

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de UserEntity são verificadas
- **THEN** a entidade valida seu ID por conceito PHP puro e não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure, Sanctum ou contratos de autenticação

#### Scenario: Model integra com o framework
- **WHEN** UserModel de Identity Infrastructure é inspecionado
- **THEN** implementa Authenticatable, HasApiTokens e geração UUIDv7 suportada
- **AND** essa integração não é exposta pela Entity ou contratos de Application

### Requirement: CRUD HTTP JSON:API
O sistema MUST expor consulta/atualização/exclusão em /api/users/{user} somente para a conta autenticada, com alvo UUIDv7 validado/canônico antes do lookup. MUST NOT expor GET global ou POST /api/users. Recursos MUST manter type users, ID string UUIDv7, name/email/created_at/updated_at e self. Rota com ID numérico, hash, malformado ou outra versão MUST retornar 404 JSON:API, sem coerção/query inválida; owner UUID desconhecido/alheio MUST preservar não encontrado uniforme. Normalização de caixa MUST ocorrer antes da comparação de owner, sem alterar políticas de acesso.

#### Scenario: Criação HTTP removida
- **WHEN** POST /api/users é executado
- **THEN** responde 404 JSON:API
- **AND** nenhuma User é criada fora de SignUp

#### Scenario: Consulta HTTP
- **WHEN** GET /api/users/{user} referencia o UUIDv7 da conta autenticada existente
- **THEN** responde 200 com o recurso JSON:API canônico

#### Scenario: Atualização HTTP
- **WHEN** PATCH recebe UUIDv7 correspondente à conta e atributo válido
- **THEN** responde 200 com recurso atualizado e mesmo UUID

#### Scenario: Exclusão HTTP
- **WHEN** DELETE referencia UUIDv7 da conta autenticada existente
- **THEN** responde 204 sem conteúdo e conclui seu lifecycle de exclusão

#### Scenario: Erros HTTP
- **WHEN** há documento inválido, ID inexistente ou rota com ID de formato/versão inválido
- **THEN** responde JSON:API respectivamente com 422 ou 404, sem erro SQL de cast

#### Scenario: Conta de outra pessoa
- **WHEN** token de A solicita GET/PATCH/DELETE com UUIDv7 de B
- **THEN** responde 404 igual ao contrato de conta inexistente
- **AND** não lê/altera B, credenciais, tokens, despesas ou associações de recursos
- **AND** possuir UUID válido não concede acesso

#### Scenario: Requisição sem principal válido
- **WHEN** rota UUIDv7 válida é chamada sem autenticação válida
- **THEN** responde 401 JSON:API
- **AND** não revela/modifica contas

### Requirement: Persistência mínima de User
O sistema MUST persistir users.id UUIDv7 nativo, nome, e-mail canônico, password hash e timestamps, com ID imutável. UserModel MUST representar persistência/principal sem ser Entity. Tokens MUST permanecer na tabela oficial Sanctum com seus IDs/owner UUIDv7. MUST NOT inventar password aleatório, manter ID inteiro paralelo ou inferir uma entidade de apresentação. FKs/cascades MUST conservar isolamento e remover associações estáveis próprias ao excluir a conta.

#### Scenario: Registro persistido
- **WHEN** SignUp e UserRepository criam User
- **THEN** users contém UUIDv7, nome, e-mail canônico, password hash e timestamps
- **AND** não contém segredo de token, remember token ou password em texto

#### Scenario: Ausência de fallback
- **WHEN** código cria UserModel sem password fora do registro
- **THEN** a persistência rejeita
- **AND** nenhum callback inventa credencial

#### Scenario: Mapping para o domínio
- **WHEN** Repository cria/recupera registro
- **THEN** retorna Entity com ID UUIDv7 string validado, sem hash/Model
- **AND** não expõe relações/tipos Sanctum nem cast numérico do UUID

#### Scenario: Serialização segura
- **WHEN** UserModel é serializado em borda Laravel
- **THEN** password permanece oculto
- **AND** nenhum PAT ou registro auxiliar é incluído automaticamente

### Requirement: Ownership de User é aplicado nos UseCases
UseCases MUST obter owner UUIDv7 de Core UserPort, validar/canonicalizar o alvo e comparar por identidade antes de Repository. MUST NOT aceitar principal do cliente, consultar Context como autoridade ou converter IDs em números. Principal ausente/inválido MUST falhar como autenticação; alvo divergente MUST produzir User não encontrado igual ao inexistente. Exclusão MUST manter unidade transacional e lifecycle de tokens/despesas/destinos/associações de identidade, sem acessar Models de outros contextos.

#### Scenario: Chamador fora de HTTP usa a própria conta
- **WHEN** alvo UUIDv7 válido equivale ao owner, inclusive somente por diferença de caixa
- **THEN** a operação segue as regras existentes com UUID canônico

#### Scenario: Chamador fora de HTTP aponta outra conta
- **WHEN** o alvo UUIDv7 diverge do owner
- **THEN** o UseCase falha antes do Repository
- **AND** não altera conta/token/despesa/associação

#### Scenario: Principal ausente
- **WHEN** não há owner UUIDv7 autenticado válido
- **THEN** falha como não autenticado antes de persistência
