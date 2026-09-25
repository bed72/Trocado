## 1. Contratos e persistência

- [x] 1.1 Conciliar os arquivos de Expense com as alterações locais em andamento e identificar todos os consumidores, bindings, mocks e chamadas por argumento nomeado antes de alterar as assinaturas.
- [x] 1.2 Criar `ExpenseCategorizationRepository` na Application com os quatro métodos atuais de tentativa e deixar `ExpenseRepository` restrito a `create`, `listByUser`, `updateByUser` e `deleteByUser`, sem tipos de ORM ou interfaces genéricas.
- [x] 1.3 Separar `EloquentExpenseCategorizationRepository` de `EloquentExpenseRepository` usando o mesmo `ExpenseModel`; preservar cancelamento por token, expiração, predicados condicionais atômicos e retorno do proprietário somente após escrita efetiva.
- [x] 1.4 Manter no CRUD a limpeza do token quando categoria ou descrição são explicitamente editadas e o filtro por proprietário em leitura, edição e exclusão.

## 2. Cache, injeção e fila

- [x] 2.1 Reduzir `CachedExpenseRepository` às operações de CRUD; manter cache da listagem e invalidação após commit das escritas confirmadas.
- [x] 2.2 Criar `CachedExpenseCategorizationRepository` com a mesma política de tag e store de páginas por proprietário; invalidar somente quando `applyClassificationAttempt` atualizar uma despesa e houver commit, sem invalidar em `begin`, `find`, `cancel`, tentativa recusada ou rollback.
- [x] 2.3 Atualizar `ExpenseServiceProvider` para ligar os dois contratos aos respectivos decorators e implementações Eloquent; conferir a resolução de ambos pelo container.
- [x] 2.4 Atualizar `CreateExpenseUseCase` para injetar ambos os repositories, preservando a transação de criação/tentativa, o despacho pós-commit e as alterações locais de observabilidade; atualizar `ClassifyExpenseUseCase` para usar somente o contrato de categorização e manter os demais UseCases de CRUD inalterados semanticamente.
- [x] 2.5 Atualizar `ExpenseClassificationDispatchAdapter` para cancelar pelo novo contrato na fila `sync` e nas falhas pós-commit; preservar o processamento de novos jobs por `ClassifyExpenseQueue` e o agente, inclusive o caminho `failed`.

## 3. Evidências de comportamento

- [x] 3.1 Ajustar mocks e fixtures de ambos os repositories, inclusive a referência antiga a `cancelClassificationAttempt` no teste do UseCase, e verificar que os casos de uso recebem apenas suas dependências necessárias.
- [x] 3.2 Verificar criação elegível com tentativa na mesma transação, rollback sem job, `201` com `other`, falha de despacho/sync sem tentativa órfã e nenhum acesso ao agente durante a requisição HTTP.
- [x] 3.3 Verificar categoria aplicada por novo job e worker de teste real, erro/resposta inválida/falha definitiva, expiração e reentrega; confirmar que a sugestão não vence edição explícita para `other`, alteração de descrição ou exclusão.
- [x] 3.4 Verificar invalidação do cache após CRUD e categorização confirmados para tamanhos/cursores da conta correta, e ausência de invalidação para outra conta, tentativa sem escrita ou rollback, incluindo um fluxo integrado com escrita Eloquent, commit e releitura da página.
- [x] 3.5 Executar verificações arquiteturais de fronteira, testes focados do contexto e Pint após mudanças PHP; revisar diff para evitar regressão nas alterações locais e nos contratos HTTP.

## 4. Coerência dos artefatos ativos

- [x] 4.1 Quando esta mudança for aplicada, conciliar as referências a repository único nos designs/tarefas ainda ativos de `cache-owned-expense-pages` e `classify-expenses-asynchronously`, preservando seus requisitos comportamentais e o estado real de suas tarefas.
- [x] 4.2 Validar esta mudança OpenSpec em modo strict novamente após quaisquer ajustes de escopo ou artefatos durante a implementação.

## 5. Entrada coesa da aplicação condicional

- [x] 5.1 Criar `ApplyExpenseClassificationInput` em Expense Application/Data e usá-lo no contrato, no UseCase e nas duas implementações de `applyClassificationAttempt`, preservando predicados e retorno.
- [x] 5.2 Atualizar os testes existentes para a nova assinatura e verificar categorização, invalidação pós-commit, testes arquiteturais, Pint e validação OpenSpec strict.
