# structured-observability Specification

## Purpose
Definir a emissão de eventos estruturados pela Application, sua correlação com requisições HTTP e a observação da criação confirmada de despesas sem comprometer a operação quando o destino de logs falhar.
## Requirements
### Requirement: Eventos observáveis da Application independentes do framework
O sistema MUST permitir que UseCases emitam eventos nomeados por uma capacidade transversal independente de Laravel/Monolog, acompanhados apenas de atributos estruturados explicitamente selecionados. O contrato da Application MUST NOT expor níveis de log, canais, formatters, objetos HTTP ou detalhes do destino. Logs técnicos de Infrastructure e Presentation MUST poder continuar usando Laravel diretamente sem passar por essa capacidade.

#### Scenario: Evento emitido por um UseCase
- **WHEN** um UseCase declara um evento com nome e atributos explícitos
- **THEN** o Adapter entrega um registro com o nome e os atributos ao canal de observabilidade configurado
- **AND** o UseCase não depende de Laravel ou Monolog

#### Scenario: Diagnóstico técnico de Infrastructure
- **WHEN** um Adapter de Infrastructure precisa registrar uma falha operacional
- **THEN** pode usar o logger Laravel diretamente sem implementar novos métodos no Port de observabilidade

### Requirement: Registro estruturado e correlacionável
O sistema MUST emitir uma linha JSON por evento com timestamp/level/event/atributos. HTTP MUST gerar correlação UUIDv7 canônica server-owned, usar o mesmo UUID em trace_id e X-Request-Id, sem herdar ID entre requests ou confiar em header cliente. Atributos do request, contexto e logs MUST usar somente trace_id, sem duplicá-lo em request_id. IDs próprios de entidades nos campos permitidos MUST ser UUIDv7 strings, não números/casts. Identificadores de SDK/queue MUST conservar contratos nativos e papéis distinguíveis. Fora de HTTP evento não exige trace_id; logs MUST NOT expor tokens, chaves/fingerprints do registro de projeções, textos ou valores financeiros.

#### Scenario: Evento durante requisição HTTP
- **WHEN** request gera evento
- **THEN** trace_id é o mesmo UUIDv7 do header, sem campo request_id duplicado
- **AND** atributos mantêm campos estruturados, com IDs próprios canônicos

#### Scenario: Requisições consecutivas
- **WHEN** processo atende dois requests
- **THEN** cada um usa novo UUIDv7 sem herdar contexto

#### Scenario: Execução fora de HTTP
- **WHEN** operação sem request emite evento
- **THEN** JSON válido sem exigir correlação HTTP
- **AND** job_id nativo não é reclassificado como ID de entidade do projeto

### Requirement: Criação de despesa observada apenas após confirmação
O sistema MUST emitir o evento `expense.created` uma vez após a criação confirmada de uma despesa, com `expense_id` e `user_id`. MUST NOT emitir esse evento para criação rejeitada, revertida ou tentativa transacional repetida que não tenha sido confirmada. O evento MUST NOT incluir descrição, valor, credenciais, tokens nem payload HTTP completo. A indisponibilidade do destino de logs MUST NOT desfazer a despesa confirmada nem alterar a resposta de criação.

#### Scenario: Criação confirmada
- **WHEN** uma despesa é criada e a operação é confirmada
- **THEN** um registro `expense.created` contém os IDs da despesa e de seu proprietário
- **AND** a resposta de criação preserva seu contrato existente

#### Scenario: Criação revertida ou rejeitada
- **WHEN** a criação é rejeitada ou uma transação que a contém é revertida
- **THEN** não é emitido `expense.created` para essa tentativa

#### Scenario: Falha no destino de logs
- **WHEN** o destino de observabilidade falha depois de uma criação confirmada
- **THEN** a despesa permanece criada e a resposta ao cliente preserva o sucesso da operação
