# postgresql-persistence Specification

## Purpose
Define PostgreSQL como banco padrão da aplicação, as garantias do schema migrado e o isolamento do banco usado pelos testes de persistência.
## Requirements
### Requirement: PostgreSQL é o banco operacional padrão
O sistema MUST usar PostgreSQL como banco padrão para execução local e novas instalações documentadas. A configuração de exemplo MUST indicar a conexão PostgreSQL e os parâmetros necessários sem publicar credenciais. Se o serviço ou driver PostgreSQL estiver indisponível, a aplicação MUST falhar explicitamente em vez de usar SQLite como fallback silencioso. Dados SQLite locais anteriores MUST NOT ser importados como pré-requisito para inicializar PostgreSQL.

#### Scenario: Instalação local do zero
- **WHEN** o ambiente de desenvolvimento é configurado conforme o bootstrap documentado e PostgreSQL está disponível
- **THEN** a conexão efetiva usa o banco PostgreSQL da aplicação
- **AND** uma instalação limpa funciona sem copiar registros do arquivo SQLite

#### Scenario: PostgreSQL indisponível
- **WHEN** a aplicação tenta persistir dados com PostgreSQL configurado e o serviço ou driver não está disponível
- **THEN** a operação falha sem ler nem escrever em SQLite como substituto

### Requirement: Schema da aplicação nasce de migrations em PostgreSQL
As migrations versionadas MUST criar desde um banco PostgreSQL vazio `users`, `personal_access_tokens` e `expenses` com suas restrições de unicidade, FK, cascata e índices existentes. As operações atuais de registro, autenticação, atualização/exclusão da própria conta, criação e paginação de despesas MUST manter seus contratos após a troca de banco. Os ajustes de dialeto MUST permanecer em Infrastructure/migrations, sem introduzir dependência PostgreSQL em Domain ou Application.

#### Scenario: Banco PostgreSQL vazio
- **WHEN** as migrations são aplicadas a um banco PostgreSQL sem tabelas da aplicação
- **THEN** todas terminam sem erro e as três tabelas possuem as chaves, restrições e índices necessários

#### Scenario: Unicidade e integridade referencial
- **WHEN** há tentativas de e-mail canônico duplicado, token duplicado ou despesa vinculada a User inexistente
- **THEN** as respectivas constraints PostgreSQL impedem a persistência inválida
- **AND** os erros tratados pela aplicação preservam os contratos públicos existentes

#### Scenario: Exclusão da conta e seus dados
- **WHEN** o titular remove uma conta com tokens e despesas ativas ou excluídas logicamente
- **THEN** a operação mantém a atomicidade prevista e não restam tokens nem despesas dessa conta

#### Scenario: Paginação por cursor
- **WHEN** o titular pagina suas despesas em PostgreSQL com datas repetidas
- **THEN** a consulta preserva o filtro por proprietário, a ordenação `occurred_on DESC, id DESC` e a navegação esperada

### Requirement: Testes de persistência isolados em PostgreSQL
A suíte de testes que acessa o banco MUST usar um banco PostgreSQL exclusivo para testes, separado do banco de desenvolvimento, e MUST NOT usar SQLite em memória para comprovar compatibilidade com o runtime. Comandos de teste ou de preparação do schema MUST NOT recriar ou limpar o banco de desenvolvimento.

#### Scenario: Execução da suíte
- **WHEN** testes que executam migrations ou operações de Repository são iniciados
- **THEN** a conexão efetiva é PostgreSQL e aponta para o banco de testes
- **AND** dados do banco de desenvolvimento não são removidos ou alterados pela suíte

#### Scenario: Configuração de testes incorreta
- **WHEN** a conexão de testes aponta para o banco de desenvolvimento ou para SQLite
- **THEN** a execução de verificações de persistência é interrompida antes de qualquer limpeza ou recriação de schema
