## MODIFIED Requirements

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
