## 1. Ambiente PostgreSQL

- [x] 1.1 Conferir driver PDO PostgreSQL e provisionar pelo Lerd o serviço, o banco da aplicação e o banco `_testing`, sem migrar dados do SQLite.
- [x] 1.2 Configurar o ambiente local e `.env.example` com `pgsql` como conexão padrão, sem credenciais no repositório; confirmar conexão efetiva e falha sem fallback se o serviço estiver indisponível.

## 2. Schema e testes isolados

- [x] 2.1 Configurar PHPUnit para usar somente o banco PostgreSQL de testes e impedir que configuração errada aponte para SQLite ou para o banco de desenvolvimento antes de recriar schema.
- [x] 2.2 Aplicar as migrations existentes em PostgreSQL vazio; corrigir incompatibilidades reais preservando índices, unicidade, FK e cascata, sem introduzir SQL paralelo ou migration de importação.
- [x] 2.3 Verificar em PostgreSQL as constraints e os contratos existentes de Identity, Sanctum e Expense, incluindo exclusão atômica, tradução de erros e paginação por cursor.

## 3. Documentação e validação

- [x] 3.1 Atualizar README com bootstrap PostgreSQL e separação dos bancos de desenvolvimento e testes; remover instruções que dependem de SQLite como padrão.
- [x] 3.2 Executar suíte pertinente e verificações arquiteturais sobre PostgreSQL, Laravel Pint para PHP alterado, revisar diff e validar esta mudança OpenSpec em modo strict.
