## Why

As rotas de User exigem token Sanctum, mas GET, PATCH e DELETE usam o identificador da URL sem confirmar que ele pertence ao principal autenticado. Uma conta pode, portanto, ler, alterar ou excluir outra conta. O padrão existente de `SignOutPort`/`SignOutAdapter` já demonstra como acessar a autenticação sem acoplar Controllers e Application ao Request do Laravel.

## What Changes

- Restringir consulta, atualização e exclusão de `/api/users/{user}` ao próprio titular; responder `404` tanto para conta alheia quanto inexistente, sem consultar ou modificar a conta alheia.
- Obter o identificador do principal autenticado por capacidade de Identity Application implementada em Identity Infrastructure, como no SignOut; impor a regra nos UseCases e manter Controllers sem `$request->user()`.
- Preservar os contratos de sucesso de quem acessa a própria conta e os erros JSON:API; acrescentar cobertura para acesso cruzado e ausência de principal autenticado.
- **BREAKING:** clientes autenticados deixam de poder operar contas de terceiros pelas rotas existentes; não há rota administrativa nesta mudança.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `user`: GET, PATCH e DELETE exigem que o alvo seja o principal autenticado, inclusive quando os UseCases são chamados fora de HTTP.
- `identity-context`: acrescentar capacidade de obter o identificador autenticado sem expor Request, guard ou Model à Application.
- `authentication`: atualizar a distinção entre autenticação e autorização, pois as operações de User passam a verificar ownership.

## Impact

Identity Application (UseCases e Port), Identity Infrastructure (Adapter e binding), Identity Presentation (Controllers e erros existentes), testes focados e specs de `user`, `identity-context` e `authentication`. Sem migration, nova dependência, alteração no esquema do banco ou mudança no fluxo de Expense.
