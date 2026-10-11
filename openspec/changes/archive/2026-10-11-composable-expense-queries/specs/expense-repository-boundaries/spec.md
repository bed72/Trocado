## MODIFIED Requirements

### Requirement: Cache coerente com escritas de ambos os contratos
Cache de CRUD e categorização MUST compartilhar política de páginas por proprietário. Criação, edição, exclusão e categorização que alterem despesa MUST invalidar todas as páginas da conta somente após confirmação, incluindo períodos, categorias, valores, sorts, tamanhos e cursores distintos. Início, leitura, cancelamento ou aplicação recusada de tentativa MUST NOT invalidar páginas; transação revertida MUST NOT invalidá-las. Categorização bem-sucedida MUST usar o proprietário da despesa efetivamente atualizada, sem invalidar outras contas.

#### Scenario: Classificação confirmada com página previamente cacheada
- **WHEN** IA aplica categoria válida com páginas do proprietário previamente cacheadas
- **THEN** após commit todas as variantes, inclusive páginas filtradas pela categoria anterior e nova, são recarregadas
- **AND** páginas de outras contas não são invalidadas

#### Scenario: Operação sem alteração efetiva
- **WHEN** tentativa é iniciada, consultada, cancelada ou sua aplicação é recusada
- **THEN** páginas existentes não são invalidadas por essa operação

#### Scenario: Rollback de categorização
- **WHEN** aplicação de categoria reverte
- **THEN** categoria anterior permanece e nenhuma página é invalidada pela tentativa

#### Scenario: Escrita de CRUD confirmada
- **WHEN** despesa é criada, editada ou excluída com sucesso
- **THEN** todas as variantes de páginas do proprietário são invalidadas após confirmação
- **AND** separação dos contratos não elimina a invalidação existente
