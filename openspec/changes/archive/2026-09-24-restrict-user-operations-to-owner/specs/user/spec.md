## MODIFIED Requirements

### Requirement: CRUD HTTP JSON:API
O sistema MUST expor consulta, atualização e exclusão de User em `/api/users/{user}` usando Form Requests, Controllers por ação e `UserResponse`, somente quando o alvo é a conta autenticada. O sistema MUST NOT expor listagem global de contas em `GET /api/users`. As respostas de recurso MUST usar o tipo `users`, identificador em string, atributos `name`, `email`, `created_at` e `updated_at`, e link `self`. A API MUST NOT expor criação por `POST /api/users`.

#### Scenario: Criação HTTP removida
- **WHEN** `POST /api/users` é executado
- **THEN** responde `404` em JSON:API
- **AND** orienta implicitamente o consumidor a usar o recurso de SignUp sem criar User

#### Scenario: Consulta HTTP
- **WHEN** `GET /api/users/{user}` referencia a conta autenticada existente
- **THEN** responde `200` com o recurso JSON:API correspondente

#### Scenario: Atualização HTTP
- **WHEN** `PATCH /api/users/{user}` recebe identificador correspondente à conta autenticada e ao menos um atributo válido
- **THEN** responde `200` com o recurso atualizado

#### Scenario: Exclusão HTTP
- **WHEN** `DELETE /api/users/{user}` referencia a conta autenticada existente
- **THEN** responde `204` sem conteúdo

#### Scenario: Erros HTTP
- **WHEN** a API recebe dados inválidos, e-mail duplicado ou identificador inexistente
- **THEN** responde em JSON:API respectivamente com `422`, `409` ou `404`

#### Scenario: Conta de outra pessoa
- **WHEN** um token válido da conta A solicita GET, PATCH ou DELETE `/api/users/{user}` com o ID da conta B
- **THEN** a API responde `404` em JSON:API com o mesmo contrato de conta inexistente
- **AND** não lê nem altera o registro B, suas credenciais, tokens ou despesas
- **AND** o token da conta A não concede acesso à conta B

#### Scenario: Requisição sem principal válido
- **WHEN** GET, PATCH ou DELETE `/api/users/{user}` é chamado sem autenticação válida
- **THEN** a API responde `401` em JSON:API
- **AND** não revela nem modifica qualquer conta

## ADDED Requirements

### Requirement: Ownership de User é aplicado nos UseCases
Os UseCases de consulta por ID, atualização e exclusão de User MUST obter o ID do principal autenticado por um contrato de Identity Application, MUST comparar esse ID ao identificador alvo antes de consultar ou modificar a identidade e MUST NOT aceitar um ID de principal fornecido pelo cliente ou inferir autorização apenas de um token válido. A ausência de principal MUST falhar como não autenticado; a divergência MUST produzir a mesma falha explícita de User não encontrado do alvo inexistente. A exclusão autorizada MUST preservar sua unidade transacional.

#### Scenario: Chamador fora de HTTP usa a própria conta
- **WHEN** um chamador invoca um dos três UseCases com alvo igual ao ID do principal autenticado
- **THEN** a operação segue as regras existentes de consulta, atualização ou exclusão

#### Scenario: Chamador fora de HTTP aponta outra conta
- **WHEN** um chamador invoca um dos três UseCases com alvo diferente do ID do principal autenticado
- **THEN** o UseCase falha como User não encontrado antes de ler ou escrever no Repository
- **AND** nenhuma alteração de User, token ou despesa é realizada

#### Scenario: Principal ausente
- **WHEN** um dos três UseCases é invocado sem principal autenticado válido
- **THEN** falha como não autenticado antes de consultar ou alterar o Repository
