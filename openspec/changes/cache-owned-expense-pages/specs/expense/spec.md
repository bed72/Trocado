## ADDED Requirements

### Requirement: Cache de páginas de despesas isolado por proprietário
O sistema MUST reutilizar por até 60 segundos uma página da listagem autenticada de despesas para a mesma conta, tamanho e cursor, incluindo os dados e cursores de navegação. MUST diferenciar contas e parâmetros, MUST manter o filtro de proprietário e a RLS nas consultas ao banco e MUST NOT usar o cache ou o cursor como autorização. O conteúdo devolvido MUST preservar o contrato e a ordem da listagem JSON:API, sem armazenar documento HTTP ou links dependentes da requisição.

#### Scenario: Repetição da mesma página
- **WHEN** a conta autenticada solicita novamente uma página com o mesmo tamanho e cursor antes do TTL e não houve invalidação
- **THEN** recebe os mesmos itens e links de navegação sem nova consulta de despesas

#### Scenario: Página ou proprietário diferente
- **WHEN** outra conta usa o mesmo cursor ou a mesma conta muda tamanho ou cursor
- **THEN** a página armazenada para a combinação anterior não é reutilizada
- **AND** cada consulta ao banco permanece restrita à conta autenticada

#### Scenario: Expiração
- **WHEN** uma página em cache ultrapassa 60 segundos sem ser renovada
- **THEN** a próxima solicitação recarrega a página a partir da consulta restrita à conta e reconstitui os links da resposta

### Requirement: Invalidação das páginas após escrita confirmada
O sistema MUST invalidar todas as páginas em cache do proprietário depois que a criação de uma despesa for confirmada, incluindo tamanhos e cursores diferentes. Uma escrita revertida ou rejeitada MUST NOT invalidar antecipadamente a página. Quando edição ou exclusão individual de despesas forem disponibilizadas, elas MUST aplicar a mesma invalidação após confirmação da escrita para o proprietário afetado. Sob leituras e escritas concorrentes, o sistema MUST limitar a duração de eventual desatualização pelo TTL, sem prometer snapshot ou leitura imediatamente consistente.

#### Scenario: Criação confirmada
- **WHEN** a conta cria uma despesa com sucesso após já consultar várias páginas
- **THEN** a próxima consulta às páginas anteriormente cacheadas dessa conta recarrega os dados e cursores da listagem atual
- **AND** as páginas de outras contas não são invalidadas

#### Scenario: Criação revertida
- **WHEN** a transação de criação falha ou é revertida
- **THEN** nenhuma despesa é persistida e as páginas já cacheadas não são invalidadas antes de uma escrita confirmada

#### Scenario: Alteração ou exclusão individual futura
- **WHEN** uma futura operação de edição ou exclusão individual é confirmada
- **THEN** todas as páginas em cache da conta afetada são invalidadas, inclusive quando a posição de uma despesa muda na ordenação

#### Scenario: Leitura simultânea à escrita
- **WHEN** uma leitura e uma escrita para a mesma conta se sobrepõem
- **THEN** uma resposta ainda pode conter a versão anterior dos dados
- **AND** qualquer página antiga remanescente deixa de ser reutilizada no máximo ao término do TTL de 60 segundos

### Requirement: Redis como store padrão compartilhado
O sistema MUST usar Redis como store padrão de cache da aplicação em operação normal, de modo que processos compartilhem páginas e invalidações. Os testes MUST poder substituir esse store por um isolado sem exigir Redis; o rate limiter MUST preservar sua configuração de store independente. O store padrão MUST NOT alterar por si só os drivers de sessão ou fila.

#### Scenario: Requisições atendidas por processos distintos
- **WHEN** uma página é cacheada por um processo e invalidada por outro após criação confirmada
- **THEN** a próxima consulta em qualquer processo não utiliza a página invalidada

#### Scenario: Testes isolados
- **WHEN** a suíte automatizada usa o store de cache `array`
- **THEN** exercita cache e invalidação sem exigir um servidor Redis
