## 1. Preparação da implementação

- [x] 1.1 Conferir as APIs Laravel aplicáveis no Boost e a estrutura vigente de Identity antes de implementar a nova capability.

## 2. Domínio e persistência de Expense

- [x] 2.1 Implementar invariantes de valor, data, descrição e categorias fechadas no Domain, incluindo `other` quando categoria é omitida; verificar entradas inválidas fora de HTTP.
- [x] 2.2 Criar migration de `expenses` com PK, FK `user_id` com cascade, `DATE` para `occurred_on`, campos e defaults acordados, `deleted_at` e índice (`user_id`, `occurred_on`); verificar schema e exclusão de User com despesas ativas e logicamente excluídas.
- [x] 2.3 Implementar Repository e binding no contexto Expense sem expor Eloquent à Application; verificar criação e persistência dos valores corretos.

## 3. Criação

- [x] 3.1 Implementar UseCase de criação com identificador do User autenticado, sem dependência de Identity na Application, data padrão recebida da borda e persistência única; verificar que uma conta removida não cria Expense e resulta em falha explícita.
- [x] 3.2 Implementar `POST /api/expenses` autenticado com Form Request, Controller e `ExpenseResponse` JSON:API; verificar `201`, `401`, `422`, tentativa de `user_id` arbitrário, categoria permitida, categoria desconhecida e padrão `other`.

## 4. Verificação operacional

- [x] 4.1 No Lerd, executar migrations pendentes e verificar o fluxo de criação e a exclusão transacional de User com e sem despesas, incluindo rollback diante de falha.
- [x] 4.2 Executar Laravel Pint nos PHP alterados e as verificações apropriadas; validar a mudança OpenSpec estritamente antes de considerar a implementação concluída.

## 5. Relacionamentos e N+1

- [x] 5.1 Declarar `UserModel::expenses()` e `ExpenseModel::user()` preservando SoftDeletes e restringir imports cross-context aos Models de Infrastructure.
- [x] 5.2 Proteger contra lazy loading no contexto Expense e verificar com múltiplos registros que ambas as relações carregadas antecipadamente usam número constante de queries.
- [x] 5.3 Executar os testes de arquitetura e regressão, Pint e validação estrita da mudança atualizada.
