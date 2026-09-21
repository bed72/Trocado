## ADDED Requirements

### Requirement: Headers JSON:API compartilhados sem excesso
A collection Bruno MUST definir uma única vez `Accept: application/vnd.api+json` para os requests da API e MUST enviar `Content-Type: application/vnd.api+json` somente nos requests que transportam documento JSON:API. A configuração compartilhada MUST preservar a possibilidade de override explícito por request.

#### Scenario: Request de leitura herda negociação de resposta
- **WHEN** um request `GET` da collection é executado sem body
- **THEN** ele envia `Accept: application/vnd.api+json` herdado da collection
- **AND** ele não envia `Content-Type` apenas por pertencer à collection

#### Scenario: Request de escrita declara o tipo do documento
- **WHEN** um request envia um documento JSON:API no body
- **THEN** ele envia `Content-Type: application/vnd.api+json`
- **AND** continua enviando o `Accept` compartilhado

### Requirement: Escopos de variáveis e segredos
A collection Bruno MUST manter no ambiente apenas valores públicos que variam entre destinos, MUST manter fixtures estáveis e não sensíveis como collection variables e MUST manter identificadores, credenciais e tokens gerados durante um fluxo como runtime variables. A collection, seus ambientes, sua documentação e seus relatórios versionados MUST NOT conter password real, token de sessão real ou outro segredo reutilizável.

#### Scenario: Seleção de ambiente
- **WHEN** o consumidor seleciona um ambiente Bruno
- **THEN** `baseUrl` resolve o destino correspondente
- **AND** IDs reservados para not-found não dependem daquele ambiente

#### Scenario: Encadeamento efêmero
- **WHEN** um request de setup cria um recurso usado pelos requests seguintes
- **THEN** seu identificador é salvo como runtime variable
- **AND** nenhum identificador dinâmico precisa ser gravado no arquivo de ambiente

#### Scenario: Segredo fornecido externamente
- **WHEN** uma execução precisa receber um segredo que não pode ser gerado pelo próprio fluxo
- **THEN** o valor entra por secret variable ou variável de processo suportada pelo runner
- **AND** o valor não é escrito em arquivo versionado nem exposto em relatório

### Requirement: Fluxo Authentication seguro para consumidores
Após a capability Authentication estar disponível, a collection Bruno MUST fornecer um fluxo serial `SignUp` → `SignIn` → request Bearer autenticado → `SignOut` → rejeição do token revogado. Password e token MUST existir somente durante a execução, e a collection MUST NOT aplicar Bearer por padrão aos endpoints públicos atuais de User e Budget.

#### Scenario: Captura e uso do token
- **WHEN** `SignIn` responde com uma AuthenticationSession válida
- **THEN** o token retornado uma única vez é salvo como runtime variable
- **AND** o request autenticado seguinte o envia por `Authorization: Bearer`

#### Scenario: Revogação observável
- **WHEN** `SignOut` encerra a sessão corrente e o mesmo token é reutilizado
- **THEN** a API rejeita o token revogado com `401`

#### Scenario: Requests públicos não recebem Bearer implicitamente
- **WHEN** `SignUp`, `SignIn`, health ou um endpoint atual não protegido de User ou Budget é executado
- **THEN** a collection não acrescenta token Bearer por herança global

### Requirement: Documentação operacional junto da collection
A collection Bruno MUST documentar as convenções transversais de consumo da API e cada pasta funcional MUST documentar objetivo, ordem, setup, efeitos destrutivos e cleanup quando aplicáveis. Documentação por request MUST ser usada para comportamento relevante que não esteja evidente em método, URL, payload e testes, sem duplicar integralmente as requirements OpenSpec.

#### Scenario: Onboarding do app consumidor
- **WHEN** um desenvolvedor abre a documentação da collection
- **THEN** encontra os pré-requisitos, uso de JSON:API, amount em centavos, ambientes, autenticação e instruções de execução
- **AND** consegue identificar OpenSpec como fonte normativa dos comportamentos

#### Scenario: Execução de uma pasta mutável
- **WHEN** um consumidor abre uma pasta com cenário serial ou destrutivo
- **THEN** a documentação informa a ordem esperada e os passos de setup e cleanup

#### Scenario: Comportamento sensível documentado no request
- **WHEN** um request retorna um token somente uma vez ou demonstra uma transição inválida
- **THEN** sua documentação explica a restrição sem registrar valores secretos

### Requirement: Smoke tests Bruno em CI
O sistema MUST executar por Bruno CLI um subconjunto identificado por tag `smoke` contra uma instância isolada da API e banco descartável. A execução MUST ser serial, MUST falhar diante de erro de request, assertion ou test e MUST NOT apontar para produção ou banco compartilhado.

#### Scenario: Smoke bem-sucedido
- **WHEN** a pipeline prepara a aplicação, executa migrations, confirma health e roda a tag `smoke`
- **THEN** os requests são executados serialmente com o ambiente de CI
- **AND** a etapa termina com sucesso somente quando todos os requests, assertions e tests passam

#### Scenario: Regressão de contrato
- **WHEN** um endpoint smoke retorna status, header ou documento incompatível com seu teste Bruno
- **THEN** a etapa de CI falha e identifica o request responsável

#### Scenario: Destino inseguro
- **WHEN** a configuração da execução resolve `baseUrl` para produção ou outro destino fora da allowlist de CI
- **THEN** a suíte é interrompida antes de executar requests mutáveis

#### Scenario: Relatório de execução autenticada
- **WHEN** a pipeline publica um relatório que inclui cenários Authentication
- **THEN** headers e bodies capazes de conter password ou token são mascarados ou omitidos

### Requirement: Referência HTML derivada para consumidores
O sistema MUST permitir gerar uma referência HTML compartilhável a partir da collection Bruno e de sua documentação, usando somente ambiente não produtivo e sem incorporar valores secretos. O HTML MUST ser tratado como artefato regenerável e MUST NOT substituir OpenSpec como fonte normativa.

#### Scenario: Geração da referência
- **WHEN** a documentação HTML é gerada para o app consumidor
- **THEN** ela apresenta a navegação por pastas, requests, payloads, headers e orientação de autenticação da collection vigente
- **AND** identifica a versão ou revisão da collection usada na geração

#### Scenario: Inspeção de segurança do HTML
- **WHEN** o artefato gerado é revisado antes do compartilhamento
- **THEN** ele não contém password, token, cookie, header de autorização real nem URL de produção não aprovada

#### Scenario: Mudança da collection
- **WHEN** requests ou documentação da collection mudam
- **THEN** a referência pode ser regenerada sem edição manual do HTML
