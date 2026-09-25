## Why

`ExpenseRepository` reúne operações de gestão de despesas e do ciclo de tentativas de categorização. Isso obriga consumidores de CRUD, fila e cache a depender de métodos que não utilizam e torna arriscado evoluir a classificação sem afetar a persistência comum. A divisão precisa preservar as garantias já existentes de concorrência, enfileiramento e invalidação das páginas.

## What Changes

- Separar o contrato de persistência de despesas do contrato que gerencia tentativas de categorização, sem introduzir um novo bounded context.
- Separar as implementações de persistência e os caminhos de cache correspondentes; a categorização bem-sucedida continuará invalidando as páginas apenas do proprietário afetado após confirmação da escrita.
- Atualizar os consumidores e bindings para que criação, edição, listagem e exclusão usem `ExpenseRepository`, enquanto o processamento assíncrono usa o contrato de categorização; a criação usa ambos quando inicia uma tentativa.
- Preservar o processamento assíncrono, o agente de IA, a API JSON:API e as regras atuais de tentativa, expiração, falha, edição concorrente e fallback `other`.
- **BREAKING (interno):** consumidores que chamam os métodos de tentativa pelo antigo `ExpenseRepository` deverão passar a depender do novo contrato; não há mudança no contrato HTTP. Não é exigida compatibilidade com jobs anteriores à mudança.

## Capabilities

### New Capabilities

- `expense-repository-boundaries`: responsabilidades dos contratos de persistência de Expense e continuidade das garantias da categorização assíncrona e do cache durante a separação.

### Modified Capabilities

Nenhuma: o comportamento externo definido para `expense` e seu cache permanece o mesmo.

## Impact

Contratos e UseCases de Expense Application, repositories de persistência/cache, adapter de despacho, bindings do `ExpenseServiceProvider` e verificações focadas nesses pontos. A mudança deverá ser conciliada com as mudanças ativas `classify-expenses-asynchronously` e `cache-owned-expense-pages`, cujos designs ainda mencionam o contrato único. Sem nova migration, package, endpoint, fila, worker ou configuração operacional.
