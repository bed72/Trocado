## Why

Expense já restringe criação e listagem pelo proprietário na aplicação, mas uma consulta futura que esqueça o filtro poderia ler despesas de outra conta. Com PostgreSQL agora em uso, RLS pode impor o mesmo isolamento na própria tabela como segunda barreira.

## What Changes

- Ativar RLS em `expenses`, restringindo leitura e escrita ao `user_id` do principal autenticado e negando acesso sem contexto.
- Associar o principal a cada operação de Expense em uma transação de banco, sem deixar estado entre requisições ou em conexões reutilizadas.
- Separar permissões de operação e de administração do schema para que a conexão normal da API não contorne RLS; verificar a política sob a mesma role usada pela aplicação.
- Preservar o escopo existente nos UseCases/Repositories e os contratos HTTP de Expense, Identity e Sanctum. Users e tokens não recebem RLS nesta mudança.
- **BREAKING:** acesso direto a `expenses` sem contexto de proprietário deixa de devolver ou gravar linhas; ferramentas administrativas deverão usar uma conexão administrativa separada e explícita.

## Capabilities

### New Capabilities

- `expense-row-level-security`: política PostgreSQL de isolamento por conta, contexto transacional do principal e garantia de que a role da API não faz bypass.

### Modified Capabilities

Nenhuma. Os comportamentos de domínio e os contratos HTTP existentes de Expense permanecem iguais para o titular autenticado.

## Impact

Migration de Infrastructure para RLS, configuração/provisionamento das roles PostgreSQL, capacidade de escopo transacional em Core Application/Infrastructure, casos de uso de criação e listagem de Expense e verificações de integração em PostgreSQL. Sem mudança em Domain ou em tabelas de Identity; não há nova dependência PHP.
