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
O sistema MUST emitir cada evento em uma única linha JSON válida com timestamp, level, event e atributos nomeados. Em uma requisição HTTP, MUST associar um identificador de correlação gerado pelo servidor, incluí-lo nos registros do fluxo e devolver o mesmo valor em `X-Request-Id`. O identificador de uma requisição MUST NOT vazar para outra. A ausência de requisição HTTP MUST NOT impedir a emissão do evento.

#### Scenario: Evento durante requisição HTTP
- **WHEN** uma requisição produz um evento observável
- **THEN** o registro JSON contém `request_id` igual ao cabeçalho `X-Request-Id` da resposta
- **AND** cada atributo permanece pesquisável como campo estruturado

#### Scenario: Requisições consecutivas
- **WHEN** duas requisições consecutivas são processadas pelo mesmo processo
- **THEN** cada uma usa seu próprio `request_id` sem herdar o contexto da anterior

#### Scenario: Execução fora de HTTP
- **WHEN** uma operação executada sem requisição HTTP emite um evento
- **THEN** o registro JSON continua válido e não exige `request_id`

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
