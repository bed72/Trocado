## MODIFIED Requirements

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

## ADDED Requirements

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
