## Why

A listagem paginada de despesas pode repetir consultas para a mesma conta e página. Como outros fluxos também usarão cache no futuro, é preciso definir um store compartilhado e uma política de invalidação que preserve o isolamento por proprietário sem acoplar a Application ao Laravel.

## What Changes

- Adotar Redis como store padrão de cache da aplicação, mantendo os stores de testes e do rate limiter configuráveis separadamente.
- Cachear por tempo curto as páginas da listagem de despesas da conta autenticada, incluindo dados e cursores de navegação, sem alterar o contrato JSON:API.
- Invalidar todas as páginas da conta após a criação de uma despesa confirmada; aplicar a mesma regra à edição e à exclusão individual quando esses fluxos existirem.
- Delimitar a consistência eventual aceitável para leituras concorrentes e assegurar que cache não substitui autenticação nem isolamento por proprietário.

## Capabilities

### New Capabilities

Nenhuma.

### Modified Capabilities

- `expense`: acrescentar cache e invalidação por proprietário à listagem de despesas, sem alterar o formato ou o escopo das respostas.

## Impact

Configuração do cache padrão e ambiente, Expense Application/Infrastructure e seu binding; verificação dos fluxos de criação e listagem. Redis passa a ser dependência operacional do cache padrão; sessões, filas e contratos HTTP não mudam. Não há migration, dependência Composer ou implementação de edição/exclusão nesta proposta.
