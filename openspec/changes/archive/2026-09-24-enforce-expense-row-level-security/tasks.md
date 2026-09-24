## 1. Permissões e política PostgreSQL

- [x] 1.1 Provisionar de modo reproduzível e documentado roles separadas de manutenção e runtime (inclusive no banco `_testing`), sem credenciais no repositório; verificar grants mínimos e ausência de superuser, `BYPASSRLS`, ownership e TRUNCATE na role da API.
- [x] 1.2 Criar migration reversível para habilitar/forçar RLS em `expenses` e instituir política de leitura/escrita por `user_id` com negação sem contexto; aplicar no PostgreSQL com a role de manutenção, sem habilitar bypass na API.
- [x] 1.3 Verificar diretamente como a role real de runtime, sobre PostgreSQL, ausência de contexto, SELECT sem filtro, INSERT/UPDATE de outra conta e UPDATE/DELETE de linha alheia; confirmar RLS ativo/forçado e rejeição de DDL/bypass.

## 2. Escopo da operação de Expense

- [x] 2.1 Implementar `ScopePort` e `ScopeAdapter` de escopo transacional em Core, com contexto local parametrizado na mesma conexão a cada tentativa, sem aceitar silenciosamente transação externa insegura; registrar binding no provider.
- [x] 2.2 Envolver criação e listagem inteiras dos UseCases no escopo por ID autenticado da borda, preservando o filtro existente no Repository e os contratos HTTP; confirmar ausência de acesso ao Repository quando o escopo não é seguro.
- [x] 2.3 Adaptar os testes Feature pertinentes ao escopo não aninhado (hoje usam `RefreshDatabase` com transação externa) e ao provisionamento separado do schema de testes, sem tocar o banco de desenvolvimento.

## 3. Evidência de isolamento e regressão

- [x] 3.1 Verificar commit, rollback, retry e operações A/B sequenciais na mesma conexão: nunca herdar o contexto anterior ou permitir acesso fora do escopo.
- [x] 3.2 Verificar em PostgreSQL real criação e paginação de despesas, autenticação sem contexto de Expense e exclusão de User com tokens, despesas ativas e logicamente excluídas; executar testes de arquitetura relevantes.
- [x] 3.3 Executar suíte pertinente, Laravel Pint para PHP alterado, revisar diff/roles/migration e validar a mudança OpenSpec em modo strict antes de declarar o comportamento seguro.
