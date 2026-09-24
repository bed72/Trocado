## ADDED Requirements

### Requirement: Listagem de despesas restrita ao proprietário
O sistema MUST disponibilizar `GET /api/expenses` somente a um User autenticado. A consulta MUST filtrar por `user_id` obtido da identidade autenticada antes de paginar, MUST omitir despesas com `deleted_at` preenchido e MUST NOT aceitar `user_id` fornecido pelo cliente para definir o proprietário. A Application MUST receber o identificador autenticado explicitamente e MUST NOT depender de HTTP, autenticação Laravel ou Eloquent; o contrato de Repository MUST expor somente tipos independentes do ORM.

#### Scenario: Despesas da própria conta
- **WHEN** uma conta autenticada possui despesas ativas e outras contas também possuem despesas
- **THEN** `GET /api/expenses` retorna somente as despesas ativas da conta autenticada
- **AND** os links de paginação não permitem acessar registros de outra conta

#### Scenario: Despesas excluídas logicamente
- **WHEN** a conta possui despesas ativas e despesas com `deleted_at` preenchido
- **THEN** somente as despesas ativas aparecem na listagem e nas páginas seguintes

#### Scenario: Conta sem despesas
- **WHEN** a conta autenticada não possui despesas ativas
- **THEN** a API responde `200` com `data` como coleção vazia e sem próximo cursor

#### Scenario: Consulta sem autenticação
- **WHEN** `GET /api/expenses` é chamado sem Bearer token válido
- **THEN** a API responde `401` em JSON:API sem revelar despesas

#### Scenario: Proprietário fornecido pelo cliente
- **WHEN** uma conta autenticada envia `user_id` de terceiro nos parâmetros da listagem
- **THEN** a API rejeita o parâmetro com `422` em JSON:API e não altera o escopo da consulta

### Requirement: Paginação por cursor de despesas
O sistema MUST ordenar as despesas por `occurred_on` decrescente e, em caso de empate, por `id` decrescente. MUST paginar no banco usando cursor e índice compatível com o filtro por `user_id` e a ordenação, sem carregar todos os registros ou usar offset. `page[size]` MUST ser opcional, com valor padrão `20` e limite inclusivo de `1` a `100`; `page[cursor]` MUST ser opcional e representar a posição opaca devolvida pela API. Um cursor inválido ou tamanho fora do intervalo MUST produzir `422` em JSON:API, sem retornar implicitamente a primeira página. Cada página MUST conter no máximo o tamanho solicitado e MUST preservar o escopo da conta autenticada, inclusive ao seguir um cursor.

#### Scenario: Ordem determinística em datas iguais
- **WHEN** várias despesas da mesma conta possuem a mesma data de ocorrência
- **THEN** aparecem em ordem decrescente de `id`, sem omissões nem repetições ao avançar entre páginas sem alterações nos dados

#### Scenario: Navegação adiante e atrás
- **WHEN** uma conta tem mais despesas ativas do que o limite solicitado e segue os links `next` ou `prev`
- **THEN** recebe a página correspondente, na mesma ordenação e somente com suas despesas
- **AND** a ausência de página seguinte ou anterior é indicada pelo respectivo link nulo

#### Scenario: Cursor usado por outra conta
- **WHEN** uma conta usa um cursor obtido em listagem de outra conta
- **THEN** a consulta continua restrita à conta autenticada e não revela despesas da outra conta

#### Scenario: Parâmetros de paginação inválidos
- **WHEN** `page[size]` não é inteiro entre `1` e `100` ou `page[cursor]` é malformado
- **THEN** a API responde `422` com erro JSON:API identificando o parâmetro inválido

### Requirement: Resposta JSON:API da listagem de despesas
`GET /api/expenses` MUST responder `200` com coleção `data` de recursos do tipo `expenses`, IDs em string e os mesmos atributos públicos da resposta de criação. MUST incluir links de paginação `next` e `prev` com `page[cursor]` opaco, preservando o tamanho da página; MUST NOT exigir contagem total de registros nem oferecer páginas numeradas. O cursor MUST NOT ser tratado como autorização para acessar registros.

#### Scenario: Primeira página de despesas
- **WHEN** a conta autenticada solicita uma primeira página com mais registros disponíveis
- **THEN** a resposta contém no máximo `page[size]` recursos e um link `next` utilizável
- **AND** o link `prev` é nulo

#### Scenario: Página final
- **WHEN** a conta autenticada alcança a última página
- **THEN** o link `next` é nulo
- **AND** os recursos mantêm o documento JSON:API esperado
