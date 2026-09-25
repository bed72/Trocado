## ADDED Requirements

### Requirement: Contratos de persistência de Expense segregados por responsabilidade
O contexto Expense MUST expor `ExpenseRepository` somente para criar, listar por proprietário, atualizar por proprietário e excluir por proprietário; MUST expor `ExpenseCategorizationRepository` somente para iniciar, localizar, aplicar e cancelar tentativas de categorização. Os contratos MUST usar tipos independentes do ORM, permanecer na Application e ter implementações de persistência distintas na Infrastructure. Casos de uso MUST depender apenas dos contratos necessários à sua operação: a criação pode usar ambos, o processamento assíncrono MUST usar apenas o de categorização e listagem/edição/exclusão MUST usar apenas o de despesas.

#### Scenario: Consumidores de CRUD
- **WHEN** os casos de uso de listagem, edição e exclusão de despesas são resolvidos
- **THEN** suas dependências de persistência expõem as operações de `ExpenseRepository`
- **AND** eles não dependem das operações de tentativa de categorização

#### Scenario: Criação e processamento assíncrono
- **WHEN** uma despesa elegível é criada e posteriormente processada pelo classificador
- **THEN** a criação persiste a despesa pelo contrato de CRUD e registra a tentativa pelo contrato de categorização
- **AND** o processamento consulta, aplica ou cancela a tentativa sem depender do contrato de CRUD

### Requirement: Estado da tentativa preservado após a separação
O registro de tentativa de categorização MUST ocorrer na mesma unidade transacional da criação elegível. A consulta MUST retornar apenas uma tentativa correspondente ao ID/token vigente e elegível; uma tentativa vencida MUST deixar de ser pendente. A confirmação MUST alterar a categoria e consumir a tentativa apenas quando ID, token, prazo, categoria inicial `other` e descrição ainda coincidirem no momento da escrita. Edição explícita da categoria, inclusive para `other`, ou da descrição MUST cancelar a tentativa anterior; cancelamento MUST afetar apenas o token correspondente. Excluir a despesa ou reprocessar uma tentativa concluída MUST NOT ressuscitar nem aplicar a classificação antiga.

#### Scenario: Criação revertida
- **WHEN** a transação que cria a despesa elegível é revertida
- **THEN** nem a despesa nem uma tentativa utilizável por um trabalho posterior são persistidas

#### Scenario: Edição antes da conclusão da inferência
- **WHEN** a categoria é explicitamente editada para `other` ou a descrição muda antes de uma resposta de IA atrasada
- **THEN** a tentativa antiga não substitui a edição do proprietário

#### Scenario: Tentativa vencida, cancelada, repetida ou despesa excluída
- **WHEN** um trabalho usa um token vencido/cancelado, já aplicado ou referente a uma despesa excluída
- **THEN** nenhuma categoria é atualizada por esse trabalho

#### Scenario: Resultado concorrente à edição
- **WHEN** a categoria, a descrição ou o token da despesa muda entre a leitura da tentativa e a aplicação da sugestão
- **THEN** a atualização condicional não aplica a sugestão e não informa uma categorização bem-sucedida

### Requirement: Cache coerente com escritas de ambos os contratos
Os caminhos de cache de CRUD e de categorização MUST compartilhar a política de páginas por proprietário. Criação, edição, exclusão e categorização que alterem uma despesa MUST invalidar as páginas da conta afetada somente após a confirmação da respectiva escrita. O início, a leitura, o cancelamento ou a aplicação recusada de uma tentativa MUST NOT invalidar páginas; uma transação revertida MUST NOT invalidá-las. Uma categorização bem-sucedida MUST usar o proprietário da despesa efetivamente atualizada, sem invalidar páginas de outros proprietários.

#### Scenario: Classificação confirmada com página previamente cacheada
- **WHEN** a IA aplica uma categoria válida a uma despesa com páginas cacheadas de seu proprietário
- **THEN** após o commit as páginas desse proprietário, inclusive tamanhos e cursores diferentes, são recarregadas na próxima consulta
- **AND** as páginas de outras contas não são invalidadas

#### Scenario: Operação sem alteração efetiva
- **WHEN** uma tentativa é iniciada, consultada ou cancelada, ou sua aplicação condicional é recusada
- **THEN** as páginas já cacheadas não são invalidadas por essa operação

#### Scenario: Rollback de categorização
- **WHEN** a aplicação da categoria ocorre em uma transação que depois é revertida
- **THEN** a categoria anterior permanece e nenhuma invalidação dessa tentativa é aplicada antes do commit

#### Scenario: Escrita de CRUD confirmada
- **WHEN** uma despesa é criada, editada ou excluída com sucesso para um proprietário
- **THEN** as páginas desse proprietário são invalidadas após a confirmação
- **AND** a separação dos contratos não elimina a invalidação já existente

### Requirement: Despacho e consumo da fila com os contratos separados
A separação MUST enfileirar novos jobs de categorização com os dados necessários à tentativa e à execução, resolvendo o caso de uso e seus bindings no momento do processamento, sem serializar repositories ou serviços. O despacho MUST ocorrer após commit da criação; falha de despacho, uso de fila síncrona desabilitada para esse fluxo, sugestão inválida ou falha definitiva MUST cancelar apenas a tentativa correspondente, sem sobrescrever eventual edição do usuário, e manter `other` quando a despesa não tiver sido editada. O agente de IA MUST continuar isolado da persistência e MUST NOT ser chamado durante a criação HTTP.

#### Scenario: Novo job processado com os contratos separados
- **WHEN** um job criado após a separação é consumido pelo worker de classificação
- **THEN** ele resolve o caso de uso com o contrato de categorização e aplica a sugestão apenas à tentativa ainda válida

#### Scenario: Enfileiramento após commit ou rollback
- **WHEN** uma criação elegível é confirmada ou revertida
- **THEN** somente a criação confirmada disponibiliza um job para classificação
- **AND** nenhuma chamada ao agente ocorre no processamento da requisição HTTP

#### Scenario: Falha de envio ou de processamento
- **WHEN** o job não pode ser enviado, a fila síncrona está ativa, a sugestão é inválida ou todas as tentativas do job falham sem edição manual da despesa
- **THEN** apenas a tentativa de mesmo ID e token é cancelada
- **AND** a despesa permanece disponível com categoria `other`, sem impedir o sucesso da criação
