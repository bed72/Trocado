## MODIFIED Requirements

### Requirement: Testes de persistência isolados em PostgreSQL

A suíte de testes que acessa o banco MUST usar bancos PostgreSQL exclusivos para testes, separados do banco de desenvolvimento, e MUST NOT usar SQLite em memória para comprovar compatibilidade com o runtime. Comandos de teste ou de preparação do schema MUST NOT recriar ou limpar o banco de desenvolvimento. A execução paralela MUST destinar um banco exclusivo a cada processo e diferenciar execuções concorrentes, usando nomes exatos autorizados para a execução/processo. A conexão configurada e o destino efetivo MUST ser verificados antes de preparar migrations, escrever fixtures, limpar tabelas ou remover bancos. A validação MUST NOT aceitar destinos apenas por conterem testing no nome; DB_URL que seleciona destino operacional MUST ser recusada. Preparação MUST usar migrations existentes incrementalmente em bancos autorizados, sem migrate:fresh como bootstrap padrão.

#### Scenario: Execução da suíte
- **WHEN** testes que executam migrations ou operações de Repository são iniciados
- **THEN** a conexão efetiva é PostgreSQL e aponta para o banco de testes autorizado para aquela execução
- **AND** dados do banco de desenvolvimento não são removidos ou alterados pela suíte

#### Scenario: Configuração de testes incorreta
- **WHEN** a conexão de testes aponta para o banco de desenvolvimento ou para SQLite
- **THEN** a execução de verificações de persistência é interrompida antes de qualquer limpeza ou recriação de schema
- **AND** a resolução por URL ou nome semelhante não contorna essa proteção

#### Scenario: Processos paralelos
- **WHEN** a suíte executa com dois ou mais processos
- **THEN** cada processo verifica e usa seu próprio banco PostgreSQL autorizado
- **AND** não limpa nem consulta fixtures criadas por outro processo

#### Scenario: Execuções simultâneas
- **WHEN** duas invocações da suíte usam os mesmos tokens locais de processo
- **THEN** uma identidade de execução distingue seus bancos
- **AND** o teardown de uma não remove nem altera o destino da outra

#### Scenario: Bootstrap incremental seguro
- **WHEN** um banco autorizado está vazio ou tem migrations existentes pendentes
- **THEN** a preparação aplica as migrations antes dos testes dependentes do schema
- **AND** não apaga schema/dados operacionais nem depende de uma execução anterior da suíte completa
