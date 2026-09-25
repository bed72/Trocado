# expense Specification

## Purpose
Definir a criação de despesas pertencentes ao User autenticado, com invariantes de valor, data e categoria, persistência com exclusão lógica e relacionamento Eloquent protegido contra N+1.
## Requirements
### Requirement: Despesa pertence a uma identidade existente
O sistema MUST permitir criar Expense somente para o User autenticado e existente em Identity. `user_id` MUST ser definido pela identidade autenticada e MUST NOT ser escolhido pelo cliente.

#### Scenario: Criação de despesa
- **WHEN** um User autenticado cria uma despesa válida
- **THEN** a despesa é vinculada ao seu identificador e persistida

#### Scenario: Tentativa de atribuição a terceiro
- **WHEN** um cliente autenticado envia `user_id` de outra pessoa na criação
- **THEN** a requisição é rejeitada como inválida
- **AND** nenhuma despesa é criada para qualquer User

#### Scenario: Identidade não autenticada ou inexistente
- **WHEN** uma criação é solicitada sem autenticação ou o User vinculado não existe mais
- **THEN** nenhuma despesa é criada
- **AND** a API responde respectivamente `401` ou uma falha explícita de identidade inexistente

### Requirement: Dados e invariantes da despesa
O sistema MUST representar `amount` como inteiro positivo em centavos de BRL, `occurred_on` como data civil sem horário, `description` como texto opcional de até 64 caracteres e `category` como um dos valores permitidos. O limite de 32 caracteres da categoria e o limite de descrição MUST ser protegidos em código, inclusive fora do transporte HTTP. Ao omitir `occurred_on`, o sistema MUST usar a data corrente no fuso configurado para a aplicação; ao omitir `description`, MUST persistir `null`.

#### Scenario: Campos mínimos
- **WHEN** um User cria uma despesa com `amount` igual a `1250` e sem data nem descrição
- **THEN** ela representa R$ 12,50, recebe a data corrente e mantém descrição nula

#### Scenario: Data informada
- **WHEN** uma despesa é criada com `occurred_on` igual a `2026-09-20`
- **THEN** o valor persistido é essa data, sem componente de horário

#### Scenario: Valor inválido
- **WHEN** `amount` é zero, negativo, fracionário ou não é um inteiro
- **THEN** a criação é rejeitada sem persistência

#### Scenario: Descrição longa
- **WHEN** a descrição excede 64 caracteres
- **THEN** a criação é rejeitada sem persistência

### Requirement: Categorias fechadas e categoria padrão
O sistema MUST aceitar somente `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions` e `other` como categorias de Expense. MUST rejeitar valores fora da lista e MUST preservar a categoria válida informada pelo cliente, inclusive `other`. Quando o cliente omitir `category`, MUST usar `other` na criação; se houver descrição elegível, MUST permitir substituí-la posteriormente apenas por uma categoria válida sugerida em segundo plano. Se não houver descrição elegível ou a classificação não tiver sucesso, MUST manter `other`.

#### Scenario: Categoria omitida
- **WHEN** uma despesa é criada sem categoria informada
- **THEN** a categoria inicial persistida é `other`, mesmo quando uma classificação futura estiver pendente

#### Scenario: Categoria omitida sem descrição elegível
- **WHEN** uma despesa é criada sem categoria e sem descrição elegível
- **THEN** a categoria persistida é `other`
- **AND** nenhuma classificação por IA é solicitada

#### Scenario: Categoria omitida com descrição elegível
- **WHEN** uma despesa é criada sem categoria e com descrição elegível
- **THEN** a categoria inicial persistida é `other`
- **AND** uma sugestão válida pode substituí-la após o processamento assíncrono

#### Scenario: Categoria válida informada
- **WHEN** uma despesa é criada com `category` igual a `transport` ou `other`, independentemente da descrição
- **THEN** a categoria informada é persistida e não é substituída pela IA

#### Scenario: Categoria desconhecida
- **WHEN** uma despesa é criada com `category` fora da lista permitida
- **THEN** a criação é rejeitada sem persistência

### Requirement: Persistência e ciclo de vida inicial
O sistema MUST persistir despesas em `expenses` com `id` como chave primária, `user_id` obrigatório como chave estrangeira para `users`, `amount` inteiro em centavos, `occurred_on` como data, `category` obrigatória, `description` anulável, `created_at` preenchido na criação e `deleted_at` inicialmente nulo. MUST manter um índice composto em (`user_id`, `occurred_on`) e preparar exclusão lógica individual por `deleted_at`, sem exigir edição ou exclusão individual nesta mudança.

#### Scenario: Despesa persistida
- **WHEN** uma despesa válida é criada
- **THEN** recebe identificador único, timestamp de criação e `deleted_at` nulo
- **AND** a referência ao User e os campos do gasto são persistidos

#### Scenario: Consulta eficiente por proprietário e período
- **WHEN** a estrutura de persistência de Expense é criada
- **THEN** existe índice composto por `user_id` e `occurred_on`

### Requirement: Relacionamento Eloquent e prevenção de N+1
`ExpenseModel` MUST declarar `user()` como relação `BelongsTo` pelo campo `user_id`. A proteção contra lazy loading MUST permanecer ativa fora de produção. Consultas de múltiplas despesas que acessem seus Users MUST carregar a relação antecipadamente, sem uma query por despesa. O relacionamento entre Models MUST NOT introduzir dependências cross-context em Domain ou Application.

#### Scenario: Users de múltiplas despesas carregados em lote
- **WHEN** várias despesas são consultadas com a relação `user` antecipadamente carregada
- **THEN** cada despesa referencia o User correto
- **AND** a quantidade de queries da leitura não aumenta por despesa

#### Scenario: Lazy loading de User bloqueado
- **WHEN** a relação `user` é acessada sem eager loading em uma coleção de despesas fora de produção
- **THEN** a proteção do Eloquent sinaliza o acesso indevido

### Requirement: Criação HTTP JSON:API
O sistema MUST disponibilizar `POST /api/expenses` autenticado com documento JSON:API do tipo `expenses` e atributos de entrada `amount`, `occurred_on` opcional, `category` opcional e `description` opcional. MUST responder `201` com o recurso criado, identificador em string e atributos `amount`, `occurred_on`, `category`, `description` e `created_at`. Na ausência de `category`, a resposta de criação MUST apresentar `other` mesmo quando uma classificação futura estiver pendente; a chamada ao provedor de IA MUST NOT bloquear essa resposta. Dados inválidos MUST produzir erro JSON:API `422` sem criar uma despesa.

#### Scenario: Criação autenticada
- **WHEN** `POST /api/expenses` recebe um documento válido e autenticação de User existente
- **THEN** responde `201` com a despesa pertencente a esse User
- **AND** a resposta contém a categoria informada ou `other` quando omitida, sem aguardar a IA

#### Scenario: Criação autenticada com categoria explícita
- **WHEN** `POST /api/expenses` recebe um documento válido, categoria informada e autenticação de User existente
- **THEN** responde `201` com a despesa pertencente a esse User e a categoria informada

#### Scenario: Criação autenticada sem categoria e com descrição elegível
- **WHEN** `POST /api/expenses` recebe um documento válido sem categoria, mas com descrição elegível
- **THEN** responde `201` com categoria inicial `other` e identificador em string, sem aguardar a IA
- **AND** uma leitura posterior pode apresentar uma categoria válida distinta de `other` após o processamento da fila

#### Scenario: Validação HTTP
- **WHEN** a requisição contém valor não positivo, data inválida, categoria desconhecida, descrição de tipo incorreto ou descrição longa
- **THEN** responde `422` em JSON:API
- **AND** nenhuma despesa é criada ou enviada à classificação

### Requirement: Listagem de despesas restrita ao proprietário
O sistema MUST disponibilizar `GET /api/expenses` somente a um User autenticado. A consulta MUST filtrar por `user_id` obtido da identidade autenticada antes de paginar, MUST omitir despesas com `deleted_at` preenchido e MUST NOT aceitar `user_id` fornecido pelo cliente para definir o proprietário. O UseCase MUST obter o identificador autenticado por `Expense\Application\Ports\UserPort` e entregá-lo explicitamente ao Repository; a Application MUST NOT depender de HTTP, autenticação Laravel ou Eloquent; o contrato de Repository MUST expor somente tipos independentes do ORM.

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

### Requirement: Elegibilidade da descrição para classificação
O sistema MUST decidir a elegibilidade antes de enfileirar o trabalho e MUST NOT enviar à IA descrições `null`, vazias, compostas apenas por espaços ou compostas claramente apenas por payload de SQL injection ou XSS. Descrições válidas com números, pontuação ou símbolos usuais de gastos MUST NOT ser descartadas apenas por conter esses caracteres. A descrição MUST ser tratada como dado não confiável, nunca como instrução do cliente para o classificador.

#### Scenario: Descrição apenas com espaços
- **WHEN** o cliente omite a categoria e envia `description` igual a `"   "`
- **THEN** a despesa é criada com `other` e nenhum trabalho de IA é enfileirado

#### Scenario: Payload isolado
- **WHEN** o cliente omite a categoria e envia uma descrição composta apenas por `"' OR '1'='1"` ou `"<script>alert('hack')</script>"`
- **THEN** a despesa é criada com `other` e nenhum trabalho de IA é enfileirado

#### Scenario: Descrição legítima com números ou símbolos
- **WHEN** o cliente omite a categoria e envia `"Uber 123"` ou `"Mercado - 2 itens"`
- **THEN** a descrição continua elegível para classificação, respeitado o limite de 64 caracteres

### Requirement: Classificação assíncrona e fallback
Para cada criação elegível sem categoria explícita, o sistema MUST disponibilizar um trabalho na fila Redis dedicada de classificação, processada separadamente da fila `default`, após a criação confirmada; MUST NOT executar a consulta ao provedor de IA na requisição nem processar trabalhos de uma criação revertida. A classificação MUST restringir a sugestão às dez categorias permitidas e MUST validar a resposta antes de persistir. Se o provedor falhar, expirar, devolver resultado inválido ou as tentativas se esgotarem, o sistema MUST manter `other` sem impedir a criação. Falhas de enfileiramento MUST NOT impedir a criação nem deixar uma classificação pendente indefinidamente.

#### Scenario: Processamento após confirmação
- **WHEN** a criação elegível é confirmada e o worker processa uma sugestão válida `food`
- **THEN** a categoria passa de `other` para `food` sem nova requisição de criação

#### Scenario: Fila dedicada
- **WHEN** uma criação elegível despacha a classificação
- **THEN** o trabalho é destinado à fila Redis de classificação
- **AND** o worker da fila `default` não precisa processar trabalhos de IA para continuar atendendo suas próprias tarefas

#### Scenario: Criação revertida
- **WHEN** uma criação elegível é revertida antes de ser confirmada
- **THEN** nenhuma despesa é criada e nenhum trabalho de IA para ela é processado

#### Scenario: Falha ou resposta inválida
- **WHEN** o provedor falha, expira, devolve categoria fora do enum ou as tentativas se esgotam
- **THEN** a categoria final permanece `other` e a despesa continua disponível

#### Scenario: Fila indisponível
- **WHEN** o trabalho de classificação não pode ser enfileirado
- **THEN** a criação continua respondendo `201` com categoria `other`
- **AND** a despesa não permanece marcada como pendente sem trabalho correspondente

### Requirement: Atualização assíncrona sem sobrescrever alterações posteriores
O sistema MUST aplicar a sugestão de IA apenas enquanto a despesa ainda corresponder à mesma classificação pendente, descrição e categoria inicial da criação. Uma edição explícita da categoria, inclusive para `other`, uma mudança ou remoção da descrição, ou a exclusão da despesa MUST impedir a aplicação de trabalhos antigos. Atualizações de categoria confirmadas pelo processamento assíncrono MUST respeitar o isolamento por proprietário e a invalidação das páginas de despesas em cache.

#### Scenario: Categoria alterada manualmente antes do worker
- **WHEN** o usuário altera a categoria para `other` ou `health` enquanto a classificação original ainda está pendente
- **THEN** o trabalho antigo não sobrescreve a categoria escolhida

#### Scenario: Descrição alterada ou despesa excluída antes do worker
- **WHEN** a descrição é alterada/removida ou a despesa é excluída antes de um trabalho antigo terminar
- **THEN** esse trabalho não modifica a categoria da despesa

#### Scenario: Trabalho repetido ou atrasado
- **WHEN** o mesmo trabalho é entregue novamente depois de uma classificação concluída ou cancelada
- **THEN** não aplica uma segunda alteração à despesa

#### Scenario: Leitura após classificação bem-sucedida
- **WHEN** uma classificação atualiza a categoria e o proprietário consulta suas páginas de despesas previamente cacheadas
- **THEN** a atualização segue a política de invalidação por proprietário e não altera páginas de outras contas
