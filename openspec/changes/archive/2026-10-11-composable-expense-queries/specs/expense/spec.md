## MODIFIED Requirements

### Requirement: Paginação por cursor de despesas
O sistema MUST ordenar despesas pelos critérios válidos de sort definidos em expense-querying, com id decrescente como desempate final; sem sort MUST preservar occurred_on decrescente e id decrescente. MUST paginar no PostgreSQL usando cursor, sem carregar todos os registros nem usar offset, preservando o índice existente e avaliando índices adicionais pelos planos das consultas suportadas. page[size] MUST ser opcional, padrão 20 e intervalo inclusivo de 1 a 100; page[cursor] MUST ser opcional e opaco. Cursor inválido, incompatível com os filtros/ordenação efetivos ou tamanho fora do intervalo MUST produzir 422 em JSON:API, sem retornar implicitamente a primeira página. Campos e tipos do cursor MUST corresponder aos critérios efetivos e nunca autorizar campos SQL arbitrários. Cursores legados de occurred_on/id MUST continuar aceitos para consultas do contrato anterior, inclusive filtros ano/mês/dia, mas MUST ser rejeitados para novos filtros ou ordenações. Cada página MUST conter no máximo o tamanho solicitado e preservar proprietário e critérios antes da seleção.

#### Scenario: Ordem determinística em datas iguais
- **WHEN** várias despesas da mesma conta têm a mesma ocorrência e a ordenação padrão é usada
- **THEN** aparecem em id decrescente, sem omissões ou repetições entre páginas sem alterações nos dados

#### Scenario: Navegação adiante e atrás
- **WHEN** uma conta tem mais despesas elegíveis do que o limite solicitado e segue next ou prev
- **THEN** recebe a página correspondente na mesma ordenação e somente com suas despesas que atendem aos filtros
- **AND** ausência de página seguinte/anterior é indicada pelo link nulo

#### Scenario: Cursor usado por outra conta
- **WHEN** uma conta usa um cursor de consulta com critérios compatíveis obtido por outra conta
- **THEN** a leitura continua restrita à conta autenticada e não revela despesas da outra conta

#### Scenario: Parâmetros de paginação inválidos
- **WHEN** page[size] não é inteiro entre 1 e 100 ou page[cursor] é malformado
- **THEN** a API responde 422 com erro JSON:API identificando o parâmetro inválido

#### Scenario: Ordenação composta com empates
- **WHEN** a consulta usa sort=-occurred_on,amount e há várias despesas na mesma data e valor
- **THEN** a seleção usa ocorrência, valor e ID para avançar/retornar sem repetir ou omitir registros estáveis

#### Scenario: Mudança de consulta com cursor novo
- **WHEN** um novo cursor é reutilizado com filtros, direção ou prioridade de ordenação diferentes
- **THEN** a API responde 422 mesmo se os nomes das colunas forem iguais

#### Scenario: Compatibilidade com cursor anterior
- **WHEN** um cursor legado válido de occurred_on/id é usado na listagem anterior, com ou sem ano/mês/dia
- **THEN** a navegação permanece disponível na ordem padrão e escopo atual
- **AND** o mesmo cursor não é aceito em consulta com novas categorias, valores, intervalos ou sort

### Requirement: Resposta JSON:API da listagem de despesas
GET /api/expenses MUST responder 200 com coleção data de recursos expenses, IDs em string e os mesmos atributos públicos da criação. MUST incluir links next e prev com page[cursor] opaco, preservando tamanho, filtros e ordenações da consulta; MUST NOT exigir contagem total nem oferecer páginas numeradas. Cursor MUST NOT ser autorização de acesso. Ausência de página MUST produzir link nulo, e filtros sem correspondência MUST produzir coleção vazia.

#### Scenario: Primeira página de despesas
- **WHEN** a conta solicita primeira página com mais registros elegíveis disponíveis
- **THEN** recebe no máximo page[size] recursos, next utilizável e prev nulo
- **AND** next preserva todos os critérios válidos da consulta

#### Scenario: Página final
- **WHEN** a conta alcança a última página
- **THEN** next é nulo e os recursos mantêm o documento JSON:API esperado
- **AND** prev conserva filtros, sort e tamanho

#### Scenario: Seis despesas mais recentes de setembro
- **WHEN** a conta envia from=2026-09-01, to=2026-09-30 e page[size]=6 sem sort
- **THEN** recebe até seis despesas mais recentes do período e pode consultar as próximas seis pelo link next

### Requirement: Cache de páginas de despesas isolado por proprietário
O sistema MUST reutilizar por até 60 segundos páginas para a mesma conta, critérios normalizados, ordenação efetiva, tamanho e cursor, incluindo itens e cursores. MUST distinguir proprietário, limites de data, categorias, valores, ordem/direção dos sorts, tamanho e cursor; MUST manter filtro de proprietário no PostgreSQL e MUST NOT usar cache/cursor como autorização. Categorias equivalentes MUST normalizar para a mesma identidade de consulta, mas prioridades de sort diferentes MUST permanecer distintas. Dados e ordem JSON:API MUST ser preservados sem armazenar documento HTTP ou links dependentes da requisição. O namespace de páginas MUST ser versionado para impedir reutilização de páginas do contrato anterior de consultas/cursores, preservando descrição nullable.

#### Scenario: Repetição da mesma página
- **WHEN** a conta repete os mesmos critérios normalizados, sort, tamanho e cursor antes do TTL sem invalidação
- **THEN** recebe mesmos itens e cursores sem nova consulta de despesas, com links reconstituídos

#### Scenario: Página ou proprietário diferente
- **WHEN** muda proprietário, filtros, sort, tamanho ou cursor
- **THEN** a página de outra combinação não é reutilizada e toda consulta permanece restrita à conta

#### Scenario: Expiração
- **WHEN** uma página ultrapassa 60 segundos sem renovação
- **THEN** a próxima solicitação recarrega dados restritos à conta e critérios e reconstitui links

#### Scenario: Normalização não perde prioridade
- **WHEN** food,transport e transport,food são enviados, ou as prioridades de sort são trocadas
- **THEN** categorias equivalentes compartilham identidade, mas listas de sort com prioridades diferentes não compartilham página

#### Scenario: Páginas do contrato anterior
- **WHEN** existem páginas no namespace antigo com o contrato anterior de consultas e cursores
- **THEN** a versão nova não reutiliza essas páginas

### Requirement: Invalidação das páginas após escrita confirmada
O sistema MUST invalidar todas as páginas do proprietário após criação, edição, exclusão ou classificação confirmada, incluindo filtros, sorts, tamanhos e cursores diferentes. Escrita rejeitada/revertida MUST NOT invalidar antecipadamente. Sob concorrência, eventual desatualização MUST ser limitada pelo TTL de 60 segundos, sem promessa de snapshot ou leitura imediatamente consistente.

#### Scenario: Criação confirmada
- **WHEN** a conta cria despesa após consultar várias páginas
- **THEN** suas páginas são recarregadas na próxima consulta e páginas de outras contas permanecem

#### Scenario: Criação revertida
- **WHEN** a transação de criação falha ou reverte
- **THEN** nada é persistido e as páginas existentes não são invalidadas antecipadamente

#### Scenario: Alteração ou exclusão individual futura
- **WHEN** uma edição ou exclusão individual é confirmada
- **THEN** todas as variantes da conta são invalidadas, inclusive quando ocorrência, categoria, valor ou descrição muda sua posição/elegibilidade

#### Scenario: Leitura simultânea à escrita
- **WHEN** leitura e escrita da mesma conta se sobrepõem
- **THEN** uma resposta pode conter dados anteriores, mas página antiga remanescente deixa de ser reutilizada ao término do TTL
