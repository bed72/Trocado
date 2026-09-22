## MODIFIED Requirements

### Requirement: Fluxo Authentication seguro para consumidores
Após a consolidação em Identity, a collection Bruno MUST fornecer um fluxo serial `SignUp` → `SignIn` → request Bearer autenticado → `SignOut` → rejeição do token revogado. Password e token MUST existir somente durante a execução. A collection MUST criar contas exclusivamente por SignUp, MUST enviar Bearer nos endpoints protegidos de User, Budget e recorrência e MUST NOT chamar `POST /api/users`.

#### Scenario: Captura e uso do token
- **WHEN** SignIn responde com um access token válido
- **THEN** o token retornado uma única vez é salvo como runtime variable
- **AND** o request autenticado seguinte o envia por `Authorization: Bearer`

#### Scenario: Revogação observável
- **WHEN** SignOut encerra a sessão corrente e o mesmo token é reutilizado
- **THEN** a API rejeita o token revogado com `401`

#### Scenario: Requests públicos não recebem Bearer implicitamente
- **WHEN** SignUp, SignIn ou health é executado
- **THEN** a collection não acrescenta token Bearer por herança global

#### Scenario: Requests protegidos recebem Bearer explicitamente
- **WHEN** um endpoint de User, Budget ou recorrência é executado
- **THEN** a collection envia o Personal Access Token da variável de runtime
- **AND** não persiste o token na collection ou no ambiente versionado

#### Scenario: User é criado somente por SignUp
- **WHEN** um cenário precisa de uma identidade temporária
- **THEN** o setup chama `POST /api/authentication/sign-up`
- **AND** nenhum request da collection chama o `POST /api/users` removido
