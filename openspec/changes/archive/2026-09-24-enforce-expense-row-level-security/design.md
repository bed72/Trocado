## Context

PostgreSQL já é o banco efetivo. `POST /api/expenses` e `GET /api/expenses` recebem o ID autenticado na borda HTTP e os Repositories aplicam o filtro de proprietário na listagem. Não existe escopo de principal no banco. O `TransactionPort` de Core coordena transações genéricas; `ScopePort` em Core oferece uma capacidade distinta de associar o principal à transação para consultas protegidas por RLS, usada agora por Expense e reutilizável por User quando necessário. Os testes Feature atuais usam `RefreshDatabase`, que mantém uma transação externa: `SET LOCAL` dentro de uma transação aninhada não é garantia de limpeza ao fim da transação interna.

## Goals / Non-Goals

**Goals:** negar leitura/escrita cruzada diretamente em `expenses` sob a role da API, fazer a ausência do contexto negar acesso, preservar o comportamento HTTP e evitar vazamento entre requisições/conexões reutilizadas.

**Non-Goals:** RLS em `users`/`personal_access_tokens`, substituir as checagens da aplicação, atribuir um login PostgreSQL por usuário, oferecer acesso administrativo pela role da API, ou prometer proteção contra SQL arbitrário capaz de alterar o próprio contexto de sessão.

## Decisions

1. Uma migration, aplicada com uma role de manutenção distinta, ativa `ENABLE ROW LEVEL SECURITY` e `FORCE ROW LEVEL SECURITY` em `expenses` e cria política explícita para a role de runtime: linhas com `user_id` igual ao ID do contexto transacional passam por `USING` (SELECT/UPDATE/DELETE) e `WITH CHECK` (INSERT/UPDATE). A expressão trata configuração ausente/vazia como `NULL` e só aceita identificador válido; não há política ampla que combine permissivamente para liberar outras linhas. Alternativa descartada: confiar no `where('user_id', ...)` do Repository, que não protege uma consulta nova sem filtro.
2. O processo HTTP usa credencial de uma role PostgreSQL não superuser, sem `BYPASSRLS`, sem propriedade de `expenses` e sem privilégios de DDL/TRUNCATE; uma credencial separada para migrations/provisionamento fica fora do repositório e nunca é usada pela API. Mesmo com `FORCE`, testar a role efetiva para não depender de comportamento de owner. Prever grants de operações e sequence necessários à API; preparar a role antes da migration que a referencia. Alternativa descartada: mesma credencial de administração e runtime, que torna o teste de RLS enganoso. No ambiente de testes, criar o schema com a role de manutenção e executar fluxos protegidos com a role de runtime.
3. Criar `ScopePort` em Core Application, implementado por `ScopeAdapter` em Core Infrastructure: o UseCase envolve toda a consulta ou criação em uma transação e passa o ID autenticado já recebido da borda; o Adapter define o contexto com `set_config(..., true)` por parâmetro vinculado **dentro da transação e na mesma conexão** usada pelo Repository. Reestabelecer o contexto em cada tentativa de retry. A alteração de contexto não sai do escopo transacional e não deve acontecer em middleware que apenas execute antes da transação. O Port preserva retornos naturais da Application. Alternativa descartada: substituir o `TransactionPort` genérico de Core ou esconder o contexto em um global de Eloquent.
4. Não aceitar silenciosamente uma transação externa preexistente para o escopo RLS: nesse caso, recusar a operação até existir um contrato explícito de nesting/limpeza, pois o `SET LOCAL` pode sobreviver ao commit da transação interna. Para testes que exercitem múltiplas requisições na mesma conexão, não usar o `RefreshDatabase` transacional atual no escopo desses testes; preparar schema com a role adequada e garantir limpeza em um banco PostgreSQL exclusivo de testes. Também provar isolamento após commit, rollback e troca de conta. Alternativa descartada: supor que o fim da closure aninhada limpa a configuração.
5. A RLS é uma barreira contra consultas acidentais sem filtro: manter `auth:sanctum`, a origem confiável do ID no HTTP e o filtro do Repository. Uma role de runtime com permissão de executar SQL arbitrário também pode definir sua própria configuração customizada; portanto a política isoladamente não autentica o valor de `app.user_id` nem resolve injeção SQL. Nenhum usuário pode escolher esse valor via payload.

## Risks / Trade-offs

- [Role errada em runtime/testes contorna RLS] → Verificar `current_user`, `rolsuper`, `rolbypassrls`, owner e políticas reais sob a conexão usada pela API.
- [Contexto transacional persiste em outer transaction/pool] → Rejeitar escopo aninhado não suportado, testar commit/rollback e reutilização da mesma conexão; nunca usar configuração de sessão persistente.
- [Mudança na criação/consulta durante ativação] → Provisionar role, grants e política antes de trocar credenciais; exercer os fluxos existentes e manter rollback da migration. A integridade referencial/cascata na exclusão de User deve ser confirmada com RLS ativo.
- [Dados escondidos por RLS em tarefas administrativas] → Administração e backups exigem conexão de manutenção deliberada, não bypass pela API.

## Migration Plan

Provisionar role de manutenção e role limitada de runtime fora do repositório; instalar migration reversível de política/RLS e conferir grants; configurar separadamente conexão de migrations e runtime; verificar SELECT/INSERT/UPDATE/DELETE sob a role real sem e com contexto, seguido de fluxos HTTP, exclusão de User e testes de isolamento no banco `_testing`. Ativar a aplicação somente após essas verificações. Rollback explícito da migration desativa RLS e remove a política, reabrindo o risco de consultas sem filtro: usar apenas para recuperação controlada.

## Open Questions

Nenhuma decisão funcional bloqueante. Durante o apply, conferir os nomes reais de roles e a estratégia disponível no Lerd para provisionar grants e migrations com credencial distinta; se o ambiente não conseguir separar runtime e manutenção, interromper a ativação da política em vez de declará-la segura.
