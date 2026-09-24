## Why

SQLite é o banco atual, mas PostgreSQL foi escolhido como base da aplicação para a evolução futura do isolamento de dados. Como ainda não há usuários reais, não há necessidade de transportar registros locais de desenvolvimento: o importante é que instalação, testes e fluxos existentes funcionem desde um banco PostgreSQL vazio.

## What Changes

- Tornar PostgreSQL o banco padrão da aplicação e do ambiente local Lerd, com banco de testes separado.
- Garantir que todas as migrations atuais rodem do zero em PostgreSQL e que Identity, Sanctum e Expense preservem seus comportamentos, constraints, paginação e transações.
- Atualizar configuração de exemplo e instruções de bootstrap, sem guardar credenciais no repositório.
- **BREAKING:** SQLite deixa de ser o banco padrão; os dados locais existentes não serão migrados para PostgreSQL.
- Não implementar RLS nesta mudança; ele será especificado depois que o banco PostgreSQL estiver operacional.

## Capabilities

### New Capabilities

- `postgresql-persistence`: instalação, configuração, schema e execução dos fluxos persistidos em PostgreSQL, com isolamento do banco de testes.

### Modified Capabilities

Nenhuma. Os contratos HTTP e as regras de Identity/Expense permanecem os mesmos; muda o mecanismo de persistência.

## Impact

Configuração de banco e testes, `.env.example`, README, ambiente Lerd, migrations e eventuais ajustes de compatibilidade PostgreSQL em Infrastructure. Sem mudança nos contratos de Domain/Application/Presentation nem dependência nova, salvo requisito de driver PostgreSQL no runtime PHP caso ainda não esteja disponível.
