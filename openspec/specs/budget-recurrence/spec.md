# budget-recurrence Specification

## Purpose
TBD - created by archiving change add-budget-recurrence. Update Purpose after archive.
## Requirements
### Requirement: Criação opcional de recorrência
O sistema MUST permitir criar um Budget com recorrência opcional por meio do atributo booleano `recurring`, que MUST assumir `false` quando omitido. Quando `recurring` for `true`, o Budget inicial e sua regra de recorrência MUST ser persistidos atomicamente, e o Budget inicial MUST pertencer à recorrência criada.

#### Scenario: Criação sem recorrência
- **WHEN** um Budget é criado sem `recurring` ou com `recurring` igual a `false`
- **THEN** somente o Budget é criado e ele não possui associação com uma recorrência

#### Scenario: Criação com recorrência
- **WHEN** um Budget de 1 a 7 de janeiro, com amount de R$ 1.000, é criado com `recurring` igual a `true`
- **THEN** o Budget inicial e uma recorrência ativa são criados na mesma operação
- **AND** a recorrência registra amount de R$ 1.000, duração de 7 dias e próxima data inicial em 8 de janeiro

#### Scenario: Falha atômica na criação
- **WHEN** a recorrência não puder ser persistida durante a criação de um Budget recorrente
- **THEN** nem o Budget nem a recorrência são persistidos

### Requirement: Regra de recorrência pertencente ao contexto Budget
O sistema MUST representar a recorrência como uma entidade própria do bounded context `Budget`, separada dos Budgets gerados. A recorrência MUST manter seu estado, o template das próximas ocorrências, a duração em dias e a próxima data inicial. O sistema MUST NOT introduzir uma recorrência genérica compartilhada com contextos inexistentes.

#### Scenario: Ocorrências independentes da regra
- **WHEN** uma recorrência gera um novo Budget
- **THEN** o novo Budget possui identidade e timestamps próprios
- **AND** permanece associado à recorrência que o gerou

### Requirement: Duração inclusiva e fixa em dias
O sistema MUST calcular `durationInDays` como a diferença entre `endDate` e `startDate`, acrescida de um dia. Cada próximo intervalo MUST iniciar no dia seguinte ao término anterior e MUST possuir a mesma quantidade inclusiva de dias, sem inferir semanas, quinzenas ou meses calendário.

#### Scenario: Intervalo de sete dias
- **WHEN** o intervalo original é de 1 a 7 de janeiro
- **THEN** os próximos intervalos são de 8 a 14 de janeiro e de 15 a 21 de janeiro

#### Scenario: Intervalo de um único dia
- **WHEN** o intervalo original possui a mesma data inicial e final
- **THEN** a duração é de um dia e a próxima ocorrência ocupa o dia seguinte

#### Scenario: Intervalo que aparenta ser um mês
- **WHEN** o intervalo original é de 1 a 31 de janeiro
- **THEN** a duração é de 31 dias e o próximo intervalo é de 1 de fevereiro a 3 de março em um ano não bissexto

#### Scenario: Travessia de ano bissexto
- **WHEN** um próximo intervalo atravessa 29 de fevereiro de um ano bissexto
- **THEN** o dia bissexto é contado como um dia normal do intervalo

### Requirement: Geração de ocorrências devidas
O sistema MUST gerar uma ocorrência quando a `nextStartDate` de uma recorrência ativa for anterior ou igual à data corrente. A ocorrência MUST usar o amount vigente no template, o intervalo calculado e a associação com a recorrência. O sistema MUST NOT copiar identificadores, timestamps ou outros metadados técnicos de Budgets anteriores.

#### Scenario: Próxima ocorrência devida
- **WHEN** a data corrente é 8 de janeiro e uma recorrência ativa de sete dias possui `nextStartDate` em 8 de janeiro
- **THEN** um Budget de 8 a 14 de janeiro é criado com o amount vigente da recorrência
- **AND** a `nextStartDate` avança para 15 de janeiro

#### Scenario: Ocorrência ainda não devida
- **WHEN** a `nextStartDate` de uma recorrência ativa é posterior à data corrente
- **THEN** nenhum Budget é criado e a recorrência não é alterada

#### Scenario: Data corrente no fim do período anterior
- **WHEN** a data corrente ainda é igual à `endDate` da última ocorrência
- **THEN** a próxima ocorrência não é criada antecipadamente

### Requirement: Recuperação após indisponibilidade
O sistema MUST recuperar todas as ocorrências vencidas de uma recorrência ativa, em ordem cronológica, até que sua `nextStartDate` fique posterior à data corrente.

#### Scenario: Recuperação de múltiplos períodos
- **WHEN** uma recorrência de sete dias possui `nextStartDate` em 8 de janeiro e o processamento volta a executar em 22 de janeiro
- **THEN** são criados os Budgets de 8 a 14, 15 a 21 e 22 a 28 de janeiro
- **AND** a `nextStartDate` avança para 29 de janeiro

#### Scenario: Falha durante recuperação
- **WHEN** uma ocorrência falha durante a recuperação de múltiplos períodos
- **THEN** nenhum avanço de cursor é confirmado sem a ocorrência correspondente
- **AND** uma execução posterior pode continuar a partir da primeira ocorrência não confirmada

### Requirement: Processamento idempotente
O sistema MUST garantir que cada recorrência produza no máximo um Budget para uma mesma `startDate`, mesmo quando o processamento for repetido ou executado concorrentemente. A criação da ocorrência e o avanço de `nextStartDate` MUST ser atômicos.

#### Scenario: Reexecução do processamento
- **WHEN** o processamento é executado novamente para uma data já processada
- **THEN** nenhum Budget duplicado é criado

#### Scenario: Processamento concorrente da mesma recorrência
- **WHEN** dois processadores tentam gerar simultaneamente a mesma ocorrência
- **THEN** somente um Budget é persistido para a combinação de recorrência e `startDate`
- **AND** o cursor termina apontando para o intervalo imediatamente seguinte

#### Scenario: Falha antes do commit
- **WHEN** ocorre uma falha entre a tentativa de criar uma ocorrência e confirmar a transação
- **THEN** a ocorrência e o avanço do cursor são ambos revertidos

### Requirement: Proibição global de sobreposição
O sistema MUST rejeitar qualquer criação ou atualização que faça dois Budgets cobrirem a mesma data. Para intervalos fechados, existe sobreposição quando o início existente é anterior ou igual ao fim candidato e o fim existente é posterior ou igual ao início candidato. A verificação MUST ser aplicada atomicamente a todas as formas de escrita de Budget.

#### Scenario: Criação manual sobreposta
- **WHEN** existe um Budget de 1 a 7 de janeiro e se tenta criar outro de 7 a 10 de janeiro
- **THEN** a criação é rejeitada porque 7 de janeiro pertence aos dois intervalos

#### Scenario: Intervalos adjacentes
- **WHEN** existe um Budget de 1 a 7 de janeiro e se cria outro de 8 a 14 de janeiro
- **THEN** a criação é aceita porque os intervalos não se sobrepõem

#### Scenario: Atualização para intervalo sobreposto
- **WHEN** a atualização de um Budget faria seu intervalo intersectar outro Budget
- **THEN** a atualização é rejeitada e o Budget permanece inalterado

#### Scenario: Atualização preservando o próprio intervalo
- **WHEN** um Budget é atualizado sem colidir com qualquer outro Budget, desconsiderando a si próprio na verificação
- **THEN** a atualização é aceita

### Requirement: Bloqueio por conflito de datas
O sistema MUST bloquear uma recorrência ativa quando seu próximo intervalo se sobrepuser a outro Budget. O conflito MUST NOT criar uma ocorrência nem avançar `nextStartDate`. Recorrências bloqueadas MUST NOT ser processadas até uma retomada explícita.

#### Scenario: Próxima ocorrência conflitante
- **WHEN** uma recorrência tenta gerar um intervalo que se sobrepõe a outro Budget
- **THEN** nenhum novo Budget é criado
- **AND** a recorrência passa para o estado `Blocked`
- **AND** sua `nextStartDate` permanece inalterada

#### Scenario: Execuções enquanto bloqueada
- **WHEN** o processamento periódico encontra uma recorrência bloqueada
- **THEN** ele não tenta criar ocorrências para essa recorrência

#### Scenario: Retomada com conflito ainda existente
- **WHEN** se solicita a retomada de uma recorrência bloqueada e o intervalo pendente ainda se sobrepõe a outro Budget
- **THEN** a retomada é rejeitada e a recorrência permanece bloqueada

#### Scenario: Retomada após resolução
- **WHEN** o conflito do intervalo pendente foi removido e se solicita a retomada
- **THEN** a recorrência volta ao estado `Active` preservando sua `nextStartDate`
- **AND** o próximo processamento recupera as ocorrências devidas

### Requirement: Alterações explícitas e não retroativas
O sistema MUST tratar a edição de um Budget e a edição de sua recorrência como operações distintas. Alterar ou excluir uma ocorrência MUST afetar somente aquele Budget. Alterar uma recorrência MUST afetar somente ocorrências ainda não criadas e MUST preservar sua `nextStartDate`.

#### Scenario: Alteração do amount de uma ocorrência
- **WHEN** o amount de um Budget recorrente já criado é alterado
- **THEN** somente esse Budget é alterado
- **AND** o amount do template da recorrência permanece inalterado

#### Scenario: Alteração das datas de uma ocorrência
- **WHEN** as datas de uma ocorrência são alteradas para um intervalo sem sobreposição
- **THEN** somente essa ocorrência é alterada
- **AND** a duração e a `nextStartDate` da recorrência permanecem inalteradas

#### Scenario: Exclusão de uma ocorrência
- **WHEN** um Budget pertencente a uma recorrência é excluído
- **THEN** somente esse Budget é excluído
- **AND** a recorrência não recria automaticamente a ocorrência excluída nem altera seu estado

#### Scenario: Alteração do template da recorrência
- **WHEN** o amount da recorrência é alterado
- **THEN** Budgets existentes permanecem inalterados
- **AND** as próximas ocorrências usam o novo amount

#### Scenario: Alteração da duração futura
- **WHEN** a duração de uma recorrência é alterada
- **THEN** Budgets existentes permanecem inalterados
- **AND** o próximo intervalo começa na `nextStartDate` já registrada e usa a nova duração

### Requirement: Encerramento definitivo
O sistema MUST permitir encerrar uma recorrência ativa ou bloqueada. O encerramento MUST preservar os Budgets existentes, MUST impedir novas ocorrências e MUST ser irreversível. Retomar a repetição depois do encerramento MUST exigir uma nova recorrência e não pode recuperar a lacuna da recorrência encerrada.

#### Scenario: Encerramento de recorrência ativa
- **WHEN** uma recorrência ativa é encerrada
- **THEN** ela passa para o estado `Ended` e nenhuma nova ocorrência é gerada

#### Scenario: Encerramento de recorrência bloqueada
- **WHEN** uma recorrência bloqueada é encerrada
- **THEN** ela passa para o estado `Ended` sem criar a ocorrência pendente

#### Scenario: Tentativa de retomada após encerramento
- **WHEN** se tenta retomar uma recorrência encerrada
- **THEN** a operação é rejeitada e a recorrência permanece encerrada

#### Scenario: Budgets existentes após encerramento
- **WHEN** uma recorrência é encerrada
- **THEN** todos os Budgets já gerados permanecem disponíveis e inalterados

### Requirement: Processamento periódico orientado pela data
O sistema MUST disponibilizar um caso de uso de geração que receba explicitamente a data de processamento. Um adaptador agendado MUST invocá-lo diariamente usando a data corrente no fuso horário da aplicação. O processamento inicial MUST ser síncrono e MUST NOT depender de filas.

#### Scenario: Execução diária
- **WHEN** o Laravel Scheduler executa a tarefa diária de recorrência
- **THEN** o adaptador invoca o caso de uso com a data corrente da aplicação

#### Scenario: Data controlada em teste
- **WHEN** o caso de uso é executado com uma data informada explicitamente
- **THEN** todas as decisões de vencimento usam essa data, sem consultar implicitamente o relógio do sistema

### Requirement: Exposição do vínculo e estado da recorrência
O sistema MUST expor pela API a associação opcional de um Budget com sua recorrência e MUST oferecer operações distintas para consultar, alterar, encerrar e retomar uma recorrência bloqueada. Erros de sobreposição e transições de estado inválidas MUST ser retornados como erros de domínio da API, sem persistência parcial.

#### Scenario: Resposta de Budget recorrente
- **WHEN** um Budget associado a uma recorrência é retornado pela API
- **THEN** a resposta identifica a recorrência associada

#### Scenario: Consulta da recorrência
- **WHEN** uma recorrência existente é consultada
- **THEN** a API retorna seu estado, amount, duração e próxima data inicial

#### Scenario: Erro de sobreposição pela API
- **WHEN** uma criação ou atualização solicitada pela API causaria sobreposição
- **THEN** a API retorna um erro de domínio apropriado
- **AND** nenhum recurso é alterado parcialmente
