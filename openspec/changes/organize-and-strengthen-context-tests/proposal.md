## Why

A revisão dos testes de Core, Identity, Expense, Insights e Metrics revelou responsabilidades misturadas, doubles e fixtures sem organização comum, cenários críticos sem evidência apropriada e um teste de Insights que falha conforme o ID gerado pelo PostgreSQL. Uma execução padrão passou com 627 testes e 3.450 assertions, mas a execução aleatória com seed `20261009` e a execução isolada do cenário editorial falharam; o projeto precisa de uma suíte localizável, determinística e efetivamente isolada, inclusive em paralelo.

## What Changes

- Organizar testes por contexto, camada e responsabilidade, distinguindo unitários puros, integração de Infrastructure, contratos HTTP e jornadas deliberadamente integradas.
- Separar fixtures, builders e doubles reutilizáveis em `tests/Support/<Contexto>/`, com capacidades transversais em Core, sem catálogo global de mocks nem herança especulativa.
- Manter expectativas específicas de mocks próximas dos cenários e preservar fakes nativos de Laravel/AI SDK; padronizar PHPUnit como mecanismo de doubles de contratos próprios.
- Substituir preparação implícita de conta por fixtures com estados explícitos e helpers de jornadas HTTP claramente nomeados; remover mutações de negócio e fakes ocultos de `tests/Pest.php`.
- Corrigir a dependência editorial de Insights de IDs incidentais, preservar as quatro variantes válidas e consolidar builders e casos duplicados sem perder cenários úteis.
- Fortalecer provas de orquestração e efeitos após commit, mantendo rollback, constraints, locks e persistência no nível PostgreSQL real.
- Fechar lacunas de Expense em consulta individual, ownership, paginação real, validação, cache/TTL e invalidação, e de Identity em login, cadastro, exclusão atômica e rate limiting.
- Localizar em Core as verificações das capacidades transversais, incluindo status autenticado, correlação de requests e observabilidade, com assertions estruturais em vez de busca indiscriminada de números no JSON.
- Preservar e organizar os cenários existentes de Metrics Application; não implementar Adapter, endpoint ou outras tarefas de `add-expense-metrics` nesta mudança.
- Exigir preparação incremental do schema de teste, proteção contra bancos operacionais, limpeza de todos os recursos utilizados, testes isolados, ordem aleatória e execução paralela com recursos exclusivos por execução/processo.
- Exigir matriz de rastreabilidade de cenários antigos e novos, evidências de execução e ausência de skips inesperados nos cenários obrigatórios.

## Capabilities

### New Capabilities

- `test-suite-organization`: classificação e localização dos testes, suporte reutilizável por contexto, doubles, fixtures explícitas e preservação rastreável de cenários.
- `test-behavioral-evidence`: provas necessárias dos contratos já implementados de Core, Identity, Expense, Insights e Metrics, com nível de evidência e assertions apropriados.
- `test-execution-isolation`: determinismo, preparação/limpeza segura, isolamento de banco/Redis/filas/logs, execução avulsa, aleatória, concorrente e paralela, com critérios de conclusão reproduzíveis.

### Modified Capabilities

- `postgresql-persistence`: ampliar o requisito de testes isolados para bancos PostgreSQL exclusivos por processo e execução, preservando validação da conexão efetiva antes de operações de escrita, limpeza ou preparação de schema.

## Impact

- **Arquivos de testes:** `tests/Pest.php`, `tests/TestCase.php`, `tests/FeatureTestCase.php`, `tests/Unit/`, `tests/Feature/` e novo suporte necessário em `tests/Support/`.
- **Configuração/ferramentas:** configuração Pest/PHPUnit, hooks nativos de parallel testing, autoload de desenvolvimento já existente e scripts de execução/preparação estritamente necessários. Manter Pest 5/PHPUnit 13 e tooling instalado; não adicionar dependências por esta proposta.
- **Banco:** somente bancos exclusivos de teste; migrations existentes aplicadas incrementalmente. Nenhuma migration de produto, importação, mudança de schema operacional ou `migrate:fresh` é prevista.
- **Serviços:** PostgreSQL real para integração, Redis real somente nos cenários que comprovam integração distribuída e mailer de teste para notifications. Nenhum serviço externo de IA ou envio real de e-mail.
- **Arquitetura/API:** nenhum novo bounded context de produto, mudança funcional, endpoint, catálogo editorial ou autorização. Helpers de teste podem integrar contextos para preparação explícita, sem relaxar as fronteiras de `app/`.
- **Compatibilidade:** caminhos de testes e comandos focados poderão mudar e deverão ter documentação e rastreabilidade atualizadas; não há breaking change da API pública.
- **Documentação:** atualizar somente orientações existentes necessárias para rodar a suíte e referências afetadas por movimentação; não criar documentação paralela sem finalidade.
- **Coordenação:** preservar trabalho existente e evidências históricas de `add-expense-metrics`; seus testes atuais seguem as novas convenções, mas a implementação futura continua naquela mudança.
- **Autorização:** este pedido autoriza apenas criação e validação dos artefatos OpenSpec. Aplicação, refactor de testes, preparação de bancos e execução das verificações da aplicação exigem autorização posterior. Eventual bug de produção revelado pelos novos testes deve ser apresentado antes de alterar código de produto.
