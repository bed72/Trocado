## MODIFIED Requirements

### Requirement: Persistência e ciclo de vida inicial
O sistema MUST persistir expenses.id como PK UUIDv7 e user_id UUID obrigatório/FK users, mantendo amount inteiro em centavos, occurred_on data, category obrigatória, description nullable e created_at preenchido. MUST manter índice (user_id, occurred_on), hard delete individual e ausência de deleted_at. Geração MUST ocorrer na borda por mecanismo UUIDv7 suportado, sem autoincremento/cast numérico; editar/recategorizar MUST conservar ID.

#### Scenario: Despesa persistida
- **WHEN** despesa válida é criada
- **THEN** recebe UUIDv7 único/canônico e timestamp
- **AND** owner UUID e campos financeiros são persistidos

#### Scenario: Consulta eficiente por proprietário e período
- **WHEN** o schema Expense é criado
- **THEN** existe índice composto user_id UUID/occurred_on

### Requirement: Consulta individual de despesa restrita ao proprietário
GET /api/expenses/{expense} MUST manter auth/middlewares existentes, com ID de rota UUIDv7. UseCase MUST obter owner UUIDv7 por Core UserPort e consultar Repository explicitamente por ID/owner; filtro MUST ocorrer no banco. Resposta MUST ser 200 expenses com ID string v7 e atributos atuais. Inexistente/excluída/alheia MUST produzir 404 uniforme; ID numérico/hash/malformado/outra versão MUST ser rejeitado em 404 antes de query de negócio. MUST consultar persistência sem cache de páginas ou coerção numérica.

#### Scenario: Consulta da própria despesa
- **WHEN** conta apta consulta UUIDv7 de sua despesa
- **THEN** recebe 200 e recurso atual com mesmo UUID

#### Scenario: Despesa inexistente, excluída ou de outra conta
- **WHEN** UUIDv7 é inexistente, excluído ou alheio
- **THEN** recebe 404 JSON:API sem revelar despesa

#### Scenario: Consulta individual sem autenticação
- **WHEN** rota UUIDv7 válida é chamada sem Bearer válido
- **THEN** 401 sem revelar despesas

#### Scenario: Identificador não numérico
- **WHEN** a rota recebe texto que não é UUIDv7 válido, como not-an-id
- **THEN** 404 JSON:API antes de lookup

#### Scenario: Identificador inteiro legado
- **WHEN** a rota recebe 42
- **THEN** 404 sem alias/conversão de inteiro

### Requirement: Paginação por cursor de despesas
O sistema MUST preservar filtros/sorts válidos e id UUID decrescente como desempate final; default occurred_on DESC/id DESC. MUST paginar no PostgreSQL por cursor, sem offset/carregar todos, avaliando índices por planos. page[size] MUST continuar 20/1–100; cursor MUST ser opaco v2 com posição ID string UUIDv7, correspondência de campos/tipos/direção/consulta e comparação igual à ordenação UUID PostgreSQL. Cursores numéricos v1/shape legado MUST ser rejeitados em 422, inclusive nas consultas antigas, sem primeira página implícita. Amount continua inteiro, separado da validação UUID de id. Owner/filtros MUST ser aplicados antes da seleção; cursor não confere acesso.

#### Scenario: Ordem determinística em datas iguais
- **WHEN** despesas próprias têm mesma ocorrência e dados estáveis
- **THEN** UUID decrescente desempata sem omitir/repetir páginas
- **AND** não depende da ordem de inserts ou contador inteiro

#### Scenario: Navegação adiante e atrás
- **WHEN** a conta segue next/prev v2 em lista maior que page[size]
- **THEN** recebe página ordenada e somente despesas próprias elegíveis
- **AND** links inexistentes são null

#### Scenario: Cursor usado por outra conta
- **WHEN** A usa cursor com posição UUID conhecido de B e critérios compatíveis
- **THEN** a leitura continua restrita a A sem revelar B

#### Scenario: Parâmetros de paginação inválidos
- **WHEN** size é inválido ou cursor tem ID inteiro/outra versão/shape incompatível
- **THEN** 422 JSON:API aponta parâmetro e não retorna primeira página

#### Scenario: Ordenação composta com empates
- **WHEN** sort=-occurred_on,amount encontra empate de data/valor
- **THEN** seek usa data/valor/UUID com a mesma comparação e preserva ida/volta sem repetição

#### Scenario: Mudança de consulta com cursor novo
- **WHEN** v2 é reutilizado com filtros/direção/prioridade diferentes
- **THEN** 422 mesmo com nomes de colunas iguais

#### Scenario: Compatibilidade com cursor anterior
- **WHEN** o cliente apresenta cursor antigo numérico occurred_on/id ou v1
- **THEN** recebe 422, mesmo no default/ano/mês/dia
- **AND** precisa iniciar paginação UUIDv7 sem compatibilidade silenciosa

### Requirement: Resposta JSON:API da listagem de despesas
GET /api/expenses MUST responder 200/data coleção expenses com IDs string UUIDv7 e atributos atuais. next/prev MUST preservar size/filtros/sort com cursor v2 opaco; não oferecer contagem total/páginas numeradas ou tratar cursor como autorização. Link ausente MUST ser null e filtros sem match MUST retornar coleção vazia. MUST NOT expor ID inteiro alternativo ou transformar UUID para número no payload/cache.

#### Scenario: Primeira página de despesas
- **WHEN** há mais despesas elegíveis que o limite
- **THEN** recebe até size recursos UUIDv7, next v2 utilizável e prev null
- **AND** next conserva critérios

#### Scenario: Página final
- **WHEN** chega ao fim
- **THEN** next null e documento JSON:API UUID preservado
- **AND** prev conserva filtros/sort/size

#### Scenario: Seis despesas mais recentes de setembro
- **WHEN** a conta informa setembro/page[size]=6 sem sort
- **THEN** recebe até seis ocorrências mais recentes, com UUID DESC nos empates
- **AND** segue next v2 para as próximas sem inferir recência por UUID

## ADDED Requirements

### Requirement: EXP-UID Classificação e cache transportam UUID sem mudar seus conceitos
Payloads/contratos próprios de classificação e cache MUST usar Expense/owner UUIDv7, preservar token de fencing, valores, autorização, retry e invalidação após commit. Namespace de páginas MUST ser versionado para excluir payloads numéricos antigos, com limpeza/pausa de queues exclusivamente próprias na transição. MUST NOT converter token técnico em UUID, consumir jobs de IDs legados após reset ou reutilizar página de outro owner.

#### Scenario: Worker recebe despesa UUIDv7
- **WHEN** trabalho novo de classificação é consumido na fila exclusiva
- **THEN** usa UUID da despesa/fencing exato e conserva proteção contra edição posterior

#### Scenario: Cache de nova identidade
- **WHEN** consulta UUIDv7 repete critérios efetivos
- **THEN** namespace novo/owner/cursor distinguem a página
- **AND** payload numérico antigo não é servido
