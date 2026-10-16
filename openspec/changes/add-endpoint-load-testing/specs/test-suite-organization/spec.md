## MODIFIED Requirements

### Requirement: ORG-01 Localização pela responsabilidade principal

A suíte MUST localizar unitários em `tests/Unit/<Contexto>/<Camada>/` e testes com aplicação iniciada em `tests/Feature/<Contexto>/<Camada>/`, usando as camadas existentes do projeto e subpastas com papéis claros. HTTP MUST pertencer a Presentation; persistência, adapters, providers, notifications e workers MUST pertencer a Infrastructure. Jornadas deliberadamente integradas MUST ser identificadas em `tests/Feature/<Contexto>/Journeys/`, com contexto proprietário e finalidade explícitos. Carga HTTP contra servidor externo ao processo Pest MUST ficar em `tests/Load/<Contexto>/Presentation/Http/`, com configuração e comando opt-in próprios fora da descoberta funcional padrão; suporte reutilizado MUST permanecer em `tests/Support/<Contexto>/`, sendo Core proprietário da orquestração transversal. A organização MUST NOT criar bounded contexts de produto, pastas vazias, hierarquias genéricas de bases ou importar Laravel para preparar testes puros de Domain/Application. Carga HTTP real MUST NOT ser classificada como Unit por não iniciar Laravel no processo gerador.

#### Scenario: Localizar um teste de Repository
- **WHEN** o comportamento alvo é mapping, query, constraint ou escrita de um Repository Eloquent
- **THEN** o teste é encontrado em Feature do contexto proprietário, sob Infrastructure/Repositories/Persistence
- **AND** seu nome identifica o Repository ou a responsabilidade específica exercitada

#### Scenario: Localizar contrato HTTP
- **WHEN** o alvo é validação, middleware, status, headers ou documento JSON:API
- **THEN** o teste pertence a Presentation/Http do contexto proprietário
- **AND** o arquivo não reúne testes diretos de provider ou Repository sem objetivo HTTP

#### Scenario: Unidade de adapter sem bootstrap
- **WHEN** um adapter de Infrastructure é exercitado somente com dependências injetadas e sem container/banco
- **THEN** o teste pode permanecer em Unit/Infrastructure
- **AND** a classificação Unit não é determinada apenas por o código pertencer a Infrastructure

#### Scenario: Localizar carga de Insights
- **WHEN** o comportamento alvo é desempenho HTTP real de `GET /api/insights` no servidor dedicado
- **THEN** o cenário pertence a `tests/Load/Insights/Presentation/Http/` e é executado pelo comando manual de carga
- **AND** não é descoberto automaticamente como Unit/Feature nem exige bootstrap de Feature no gerador
