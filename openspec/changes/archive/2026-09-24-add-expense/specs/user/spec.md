## MODIFIED Requirements

### Requirement: Exclusão de User
O sistema MUST excluir uma conta existente dentro de `IdentityWritePort`, MUST remover todos os seus Personal Access Tokens antes de remover `users` por `IdentityRepository::delete` e MUST reverter ambos diante de falha. A exclusão definitiva do User MUST remover também todas as suas despesas, inclusive as que possuírem `deleted_at` preenchido, na mesma transação. Uma identidade inexistente MUST produzir a mesma falha explícita de User não encontrado.

#### Scenario: Exclusão bem-sucedida
- **WHEN** uma conta existente com múltiplos tokens é excluída
- **THEN** todos os tokens dessa identidade e seu registro `users` são removidos
- **AND** consultas e autenticação posteriores não a encontram

#### Scenario: Exclusão com despesas
- **WHEN** uma conta com despesas ativas e logicamente excluídas é removida
- **THEN** todas as despesas dessa conta são removidas definitivamente na mesma transação
- **AND** não restam despesas órfãs

#### Scenario: Falha durante exclusão
- **WHEN** a remoção da identidade falha depois da tentativa de remover tokens
- **THEN** a transação restaura os tokens e mantém o User
- **AND** mantém também todas as suas despesas

#### Scenario: Exclusão de User inexistente
- **WHEN** se tenta excluir um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio de `IdentityServiceProvider`, tornando visível em desenvolvimento a principal fonte de queries N+1 relacionais. `UserModel` MUST declarar `expenses()` como relação `HasMany` pelo campo `expenses.user_id`; a exclusão lógica de Expense MUST ser respeitada pela relação. Consultas de múltiplos Users que acessem despesas MUST carregar a relação antecipadamente.

#### Scenario: Lazy loading em desenvolvimento
- **WHEN** `IdentityServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

#### Scenario: Despesas de múltiplos Users carregadas em lote
- **WHEN** múltiplos Users são consultados com `expenses` carregado antecipadamente
- **THEN** cada User possui somente suas despesas ativas
- **AND** a quantidade de queries da leitura não aumenta por User

#### Scenario: Lazy loading de despesas bloqueado
- **WHEN** a relação `expenses` é acessada sem eager loading em uma coleção de Users fora de produção
- **THEN** a proteção do Eloquent sinaliza o acesso indevido
