## MODIFIED Requirements

### Requirement: ISO-08 Seleção de suítes e dependências explícitas

A suíte MUST permitir selecionar Unit, arquitetura, Feature por contexto e integrações que exigem Redis/concorrência por caminhos/grupos documentados. A seleção MUST permitir desenvolvimento rápido sem reclassificar integração real como unitário. O comando completo de aceitação funcional MUST incluir todas as integrações funcionais obrigatórias; indisponibilidade MUST ter falha/blocked claro em vez de omissão silenciosa. Carga HTTP externa MUST ter comando e configuração opt-in próprios, separados do gate funcional e do CI automático; essa separação MUST NOT retirar integrações funcionais existentes do gate completo nem usar skips para esconder carga na descoberta comum. A carga simples MUST usar alvo dedicado preparado/confirmado pelo operador e preflight HTTP, sem presumir que o banco do processo Pest configure o servidor e sem executar lifecycle de banco/Redis/contas. O launcher e os guards existentes de Unit/Feature MUST ser preservados. Helpers/Support MUST estar autoloadáveis mesmo em filtro de um único cenário.

#### Scenario: Desenvolvimento de regra pura
- **WHEN** somente Domain/Application é selecionado
- **THEN** a execução não inicializa banco/Redis/workers por causa de setup global
- **AND** o comando é distinto do gate completo obrigatório

#### Scenario: Gate completo
- **WHEN** a implementação é candidata a conclusão
- **THEN** o relatório inclui os grupos Redis, concorrência e parallel funcionais obrigatórios
- **AND** cenários skipped/incomplete/risky inesperados impedem declarar a suíte completa comprovada

#### Scenario: Descoberta padrão após adicionar carga
- **WHEN** o comando funcional completo descobre Unit e Feature
- **THEN** as integrações obrigatórias anteriores continuam selecionadas e nenhuma campanha de carga é iniciada ou marcada skipped

#### Scenario: Execução manual de carga
- **WHEN** o operador seleciona um cenário Load pelo comando dedicado
- **THEN** a medição ocorre somente após configuração privada de alvo dedicado confirmado pelo operador e preflight HTTP bem-sucedido
- **AND** o guard do banco do processo Pest não é apresentado como prova de isolamento do servidor externo
