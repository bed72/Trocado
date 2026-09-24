## ADDED Requirements

### Requirement: Despesas isoladas por RLS no PostgreSQL
O sistema MUST aplicar RLS à tabela `expenses` de modo que a role de runtime da API só possa visualizar ou alterar linhas cujo `user_id` corresponda ao principal associado à transação. INSERT e UPDATE MUST rejeitar uma nova linha cujo `user_id` seja diferente do principal. Sem identificador válido na transação, SELECT/UPDATE/DELETE MUST NOT alcançar linhas e INSERT MUST ser negado. A política MUST continuar efetiva mesmo quando uma consulta SQL omitir o filtro por proprietário; a aplicação MUST manter suas verificações de autenticação e ownership existentes.

#### Scenario: Consulta sem filtro por proprietário
- **WHEN** a role de runtime consulta `expenses` sem cláusula `user_id` durante uma transação da conta A, havendo despesas das contas A e B
- **THEN** somente as despesas de A são visíveis, inclusive as ativas e as com `deleted_at` preenchido na consulta direta

#### Scenario: Tentativa de escrita para outra conta
- **WHEN** a role de runtime tenta inserir ou atualizar despesa para o `user_id` de B durante uma transação da conta A
- **THEN** a escrita é rejeitada pela política e nenhuma linha alheia é modificada

#### Scenario: Modificação de linhas alheias
- **WHEN** a role de runtime tenta UPDATE ou DELETE de uma despesa existente de B durante uma transação da conta A
- **THEN** nenhuma linha de B é alterada ou removida

#### Scenario: Ausência de contexto
- **WHEN** a role de runtime acessa `expenses` sem identificador de principal definido na transação
- **THEN** não vê nem modifica despesas e não consegue inserir uma nova despesa

### Requirement: Contexto do principal limitado à operação
Os UseCases de criação e listagem de Expense MUST definir toda a operação de Repository dentro de um escopo transacional que associa à conexão PostgreSQL o identificador autenticado obtido pela borda confiável. Esse contexto MUST valer só para a transação, inclusive quando a conexão é reutilizada; cada tentativa de retry MUST configurá-lo novamente. Uma transação externa sem suporte explícito de limpeza MUST NOT ser aceita silenciosamente. O identificador MUST NOT ser escolhido pelo payload do cliente, e os contratos da Application MUST permanecer livres de tipos PostgreSQL/Laravel.

#### Scenario: Criação e paginação normais
- **WHEN** a conta A autenticada cria ou pagina suas despesas
- **THEN** a operação do Repository ocorre sob o contexto transacional de A e preserva as respostas HTTP existentes
- **AND** a consulta continua com escopo explícito por proprietário no Repository

#### Scenario: Mesma conexão, contas diferentes
- **WHEN** duas operações sequenciais usam a mesma conexão, primeiro para A e depois para B
- **THEN** a segunda só acessa despesas de B e não herda o contexto de A
- **AND** fora das operações não há contexto utilizável para consultar despesas

#### Scenario: Falha e nova tentativa
- **WHEN** uma operação falha e é revertida ou a transação é tentada novamente
- **THEN** o contexto anterior não autoriza consultas subsequentes fora do escopo
- **AND** cada tentativa válida configura o ID do próprio principal antes de acessar o Repository

#### Scenario: Transação externa não suportada
- **WHEN** uma operação de Expense é invocada sob uma transação externa cujo contexto não pode ser limpo com segurança
- **THEN** a execução é recusada antes de qualquer acesso a `expenses`, sem manter contexto de outra conta

### Requirement: Role da aplicação não contorna a política
A conexão normal da API MUST usar uma role distinta da role de manutenção de schema, sem propriedade de `expenses`, sem atributo `BYPASSRLS`, sem superuser e sem privilégios que desativem RLS ou façam TRUNCATE. A criação/manutenção da política MUST usar credenciais administrativas fora da aplicação e do repositório. As verificações de RLS MUST executar como a role efetiva da API sobre PostgreSQL real, e o provisionamento MUST ser reproduzível nos ambientes de desenvolvimento e de testes.

#### Scenario: Role de runtime efetiva
- **WHEN** a aplicação consulta o banco em execução normal ou nos testes de integração
- **THEN** a role efetiva não possui bypass, propriedade da tabela ou privilégios administrativos
- **AND** a tabela tem RLS ativo e obrigatório para o owner

#### Scenario: Credenciais administrativas indisponíveis na API
- **WHEN** o processo da API usa suas credenciais normais
- **THEN** não consegue desligar a política nem acessar todas as despesas como role de manutenção

#### Scenario: Bootstrap com role inadequada
- **WHEN** a conexão configurada para runtime tem superuser, `BYPASSRLS` ou é a conexão de manutenção
- **THEN** a ativação é considerada inválida e a segurança não é declarada verificada

### Requirement: Fluxos de Identity permanecem funcionais
A RLS de `expenses` MUST NOT bloquear SignUp, SignIn, SignOut, operações autorizadas de User ou a exclusão da conta com remoção das despesas ativas e logicamente excluídas; `users` e `personal_access_tokens` MUST permanecer fora desta política.

#### Scenario: Autenticação sem contexto de despesa
- **WHEN** SignUp, SignIn ou SignOut é executado sem um escopo de Expense
- **THEN** continua funcionando sem expor ou exigir um contexto de RLS para `users` ou tokens

#### Scenario: Exclusão da conta
- **WHEN** o titular exclui a própria conta com despesas ativas e logicamente excluídas
- **THEN** a transação existente remove os tokens, a conta e todas as suas despesas sem deixar órfãos
