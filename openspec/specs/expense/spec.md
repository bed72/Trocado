# expense Specification

## Purpose
Definir o ciclo de vida de despesas pertencentes ao User autenticado, suas invariantes de valor, data e categoria, descrição opcional, consultas e paginação JSON:API e cache isolado por proprietário.
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
O sistema MUST aceitar somente `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions`, `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations`, `travel` e `other` como categorias de Expense. MUST rejeitar valores fora da lista e MUST preservar a categoria válida informada pelo cliente, inclusive `other`. Quando o cliente omitir `category`, MUST usar `other` na criação; se houver descrição elegível, MUST permitir substituí-la posteriormente apenas por uma categoria válida sugerida em segundo plano. Se não houver descrição elegível ou a classificação não tiver sucesso, MUST manter `other`. MUST aceitar os oito novos identificadores na criação, edição e filtro por categoria, mantendo o mesmo identificador na persistência e nas respostas.

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

#### Scenario: Criação com cada nova categoria
- **WHEN** a conta cria uma despesa válida com cada um dos valores `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations` e `travel`
- **THEN** cada criação responde `201` e persiste/devolve exatamente a categoria informada
- **AND** a descrição não provoca substituição de categoria pela IA

#### Scenario: Edição para cada nova categoria
- **WHEN** a conta edita uma despesa própria para cada um dos oito novos identificadores válidos
- **THEN** a edição persiste e devolve o identificador escolhido
- **AND** uma classificação pendente anterior não sobrescreve a escolha manual

#### Scenario: Filtro com categorias novas e existentes
- **WHEN** a conta consulta `filter[category]=travel,investments,food,travel`
- **THEN** somente suas despesas dessas três categorias são elegíveis antes da paginação
- **AND** a repetição de `travel` não altera o conjunto nem dispensa os demais filtros

#### Scenario: Cada nova categoria pode ser filtrada
- **WHEN** a conta filtra individualmente por cada um dos oito novos identificadores
- **THEN** o filtro é aceito e seleciona somente seus lançamentos naquela categoria

#### Scenario: Valores semelhantes mas não pertencentes ao catálogo
- **WHEN** o cliente cria ou edita com `investment`, ou filtra por `travel,unknown`
- **THEN** a operação responde `422` JSON:API identificando a categoria inválida
- **AND** a escrita inválida não persiste e o filtro não ignora silenciosamente o token desconhecido

### Requirement: Persistência e ciclo de vida inicial
O sistema MUST persistir expenses.id como PK UUIDv7 e user_id UUID obrigatório/FK users, mantendo amount inteiro em centavos, occurred_on data, category obrigatória, description nullable e created_at preenchido. MUST manter índice (user_id, occurred_on), hard delete individual e ausência de deleted_at. Geração MUST ocorrer na borda por mecanismo UUIDv7 suportado, sem autoincremento/cast numérico; editar/recategorizar MUST conservar ID.

#### Scenario: Despesa persistida
- **WHEN** despesa válida é criada
- **THEN** recebe UUIDv7 único/canônico e timestamp
- **AND** owner UUID e campos financeiros são persistidos

#### Scenario: Consulta eficiente por proprietário e período
- **WHEN** o schema Expense é criado
- **THEN** existe índice composto user_id UUID/occurred_on

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
O sistema MUST disponibilizar `GET /api/expenses` somente a um User autenticado. A consulta MUST filtrar por `user_id` obtido da identidade autenticada antes de paginar e MUST NOT aceitar `user_id` fornecido pelo cliente para definir o proprietário. Despesas excluídas definitivamente MUST NOT aparecer na listagem. O UseCase MUST obter o identificador autenticado por `Core\Application\Ports\UserPort` e entregá-lo explicitamente ao Repository; a Application MUST NOT depender de HTTP, autenticação Laravel ou Eloquent; o contrato de Repository MUST expor somente tipos independentes do ORM.

#### Scenario: Despesas da própria conta
- **WHEN** uma conta autenticada possui despesas ativas e outras contas também possuem despesas
- **THEN** `GET /api/expenses` retorna somente as despesas ativas da conta autenticada
- **AND** os links de paginação não permitem acessar registros de outra conta

#### Scenario: Despesas excluídas
- **WHEN** uma conta exclui uma despesa individualmente
- **THEN** o registro é removido definitivamente e não aparece na listagem nem nas páginas seguintes

#### Scenario: Conta sem despesas
- **WHEN** a conta autenticada não possui despesas ativas
- **THEN** a API responde `200` com `data` como coleção vazia e sem próximo cursor

#### Scenario: Consulta sem autenticação
- **WHEN** `GET /api/expenses` é chamado sem Bearer token válido
- **THEN** a API responde `401` em JSON:API sem revelar despesas

#### Scenario: Proprietário fornecido pelo cliente
- **WHEN** uma conta autenticada envia `user_id` de terceiro nos parâmetros da listagem
- **THEN** a API rejeita o parâmetro com `422` em JSON:API e não altera o escopo da consulta

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
Para cada criação elegível sem categoria explícita, o sistema MUST disponibilizar um trabalho na fila Redis dedicada de classificação, processada separadamente da fila `default`, após a criação confirmada; MUST NOT executar a consulta ao provedor de IA na requisição nem processar trabalhos de uma criação revertida. A classificação MUST restringir a sugestão às dezoito categorias permitidas e MUST validar a resposta antes de persistir. Se o provedor falhar, expirar, devolver resultado inválido ou as tentativas se esgotarem, o sistema MUST manter `other` sem impedir a criação. Falhas de enfileiramento MUST NOT impedir a criação nem deixar uma classificação pendente indefinidamente.

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

### Requirement: Redis como store padrão compartilhado
O sistema MUST usar Redis como store padrão de cache da aplicação em operação normal, de modo que processos compartilhem páginas e invalidações. Os testes MUST poder substituir esse store por um isolado sem exigir Redis; o rate limiter MUST preservar sua configuração de store independente. O store padrão MUST NOT alterar por si só os drivers de sessão ou fila.

#### Scenario: Requisições atendidas por processos distintos
- **WHEN** uma página é cacheada por um processo e invalidada por outro após criação confirmada
- **THEN** a próxima consulta em qualquer processo não utiliza a página invalidada

#### Scenario: Testes isolados
- **WHEN** a suíte automatizada usa o store de cache `array`
- **THEN** exercita cache e invalidação sem exigir um servidor Redis

### Requirement: Semântica das categorias expandidas na classificação
O classificador MUST disponibilizar os dezoito identificadores do catálogo e instruções para os oito novos: `financing` para prestações de financiamento/empréstimo; `investments` para aportes financeiros/previdência privada; `taxes` para tributos e taxas administrativas/documentais; `insurance` para prêmios de seguro; `personal_care` para cuidados pessoais/cosméticos; `pets` para produtos e atendimento de animais; `gifts_and_donations` para presentes/doações/ajuda sem restituição; `travel` para passagens, hospedagem e pacotes com finalidade explícita de viagem. MUST distinguir finalidade e forma de pagamento, sem classificar qualquer compra parcelada como financiamento, qualquer taxa como tributo ou qualquer deslocamento como viagem. MUST preservar categorias explícitas, tratar a descrição como dado não confiável e manter fallback e proteção contra classificação atrasada existentes.

#### Scenario: Prestação e compra parcelada
- **WHEN** as descrições elegíveis são “Prestação do financiamento do carro” e “Compra de roupas parcelada”
- **THEN** as instruções orientam respectivamente `financing` e `shopping`, sem usar parcelamento como critério único

#### Scenario: Aporte e imposto
- **WHEN** as descrições elegíveis são “Aporte em renda fixa” e “Pagamento de IPVA”
- **THEN** as instruções orientam respectivamente `investments` e `taxes`
- **AND** não tratam tarifa bancária ou prestação de empréstimo como aporte

#### Scenario: Seguro e saúde
- **WHEN** as descrições elegíveis são “Seguro de vida” e “Mensalidade do plano de saúde”
- **THEN** as instruções orientam respectivamente `insurance` e `health`

#### Scenario: Finalidade específica de produtos e atendimento
- **WHEN** as descrições elegíveis são “Manicure”, “Consulta veterinária”, “Presente de aniversário” e “Doação beneficente”
- **THEN** as instruções orientam respectivamente `personal_care`, `pets`, `gifts_and_donations` e `gifts_and_donations`

#### Scenario: Viagem e deslocamento cotidiano
- **WHEN** as descrições elegíveis são “Passagem aérea para as férias”, “Hospedagem de viagem”, “Ônibus para o trabalho” e “Combustível”
- **THEN** as instruções orientam respectivamente `travel`, `travel`, `transport` e `transport`
- **AND** não movem refeições ou compras para `travel` sem uma finalidade específica que justifique essa categoria

#### Scenario: Sugestão nova aplicada em segundo plano
- **WHEN** uma criação sem categoria tem descrição elegível e a tentativa vigente recebe uma sugestão válida de cada uma das oito novas categorias
- **THEN** a categoria inicial `other` pode ser substituída pelo identificador válido sugerido
- **AND** sugestão inválida, falha ou descrição insuficiente conserva `other` conforme a política existente

### Requirement: Preservação do catálogo e dos registros existentes
A expansão MUST preservar os dez identificadores anteriores e MUST NOT recategorizar registros históricos, reprocessar classificação antiga ou converter categorias existentes automaticamente. Novas regras de classificação MUST aplicar-se somente a tentativas elegíveis do fluxo existente.

#### Scenario: Registro histórico em categoria genérica
- **WHEN** já existe uma despesa em `transport` cuja descrição menciona uma viagem, ou em `other` cujo texto menciona um aporte
- **THEN** a expansão do catálogo mantém a categoria persistida e o registro continua legível
- **AND** eventual recategorização exige edição explícita pelo cliente

### Requirement: EXP-UID Classificação e cache transportam UUID sem mudar seus conceitos
Payloads/contratos próprios de classificação e cache MUST usar Expense/owner UUIDv7, preservar token de fencing, valores, autorização, retry e invalidação após commit. Namespace de páginas MUST ser versionado para excluir payloads numéricos antigos, com limpeza/pausa de queues exclusivamente próprias na transição. MUST NOT converter token técnico em UUID, consumir jobs de IDs legados após reset ou reutilizar página de outro owner.

#### Scenario: Worker recebe despesa UUIDv7
- **WHEN** trabalho novo de classificação é consumido na fila exclusiva
- **THEN** usa UUID da despesa/fencing exato e conserva proteção contra edição posterior

#### Scenario: Cache de nova identidade
- **WHEN** consulta UUIDv7 repete critérios efetivos
- **THEN** namespace novo/owner/cursor distinguem a página
- **AND** payload numérico antigo não é servido
