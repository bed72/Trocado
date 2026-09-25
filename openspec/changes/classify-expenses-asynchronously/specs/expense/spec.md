## MODIFIED Requirements

### Requirement: Categorias fechadas e categoria padrão
O sistema MUST aceitar somente `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions` e `other` como categorias de Expense. MUST rejeitar valores fora da lista e MUST preservar a categoria válida informada pelo cliente, inclusive `other`. Quando o cliente omitir `category`, MUST usar `other` na criação; se houver descrição elegível, MUST permitir substituí-la posteriormente apenas por uma categoria válida sugerida em segundo plano. Se não houver descrição elegível ou a classificação não tiver sucesso, MUST manter `other`.

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

### Requirement: Criação HTTP JSON:API
O sistema MUST disponibilizar `POST /api/expenses` autenticado com documento JSON:API do tipo `expenses` e atributos de entrada `amount`, `occurred_on` opcional, `category` opcional e `description` opcional. MUST responder `201` com o recurso criado, identificador em string e atributos `amount`, `occurred_on`, `category`, `description` e `created_at`. Na ausência de `category`, a resposta de criação MUST apresentar `other` mesmo quando uma classificação futura estiver pendente; a chamada ao provedor de IA MUST NOT bloquear essa resposta. Dados inválidos MUST produzir erro JSON:API `422` sem criar uma despesa.

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

## ADDED Requirements

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
