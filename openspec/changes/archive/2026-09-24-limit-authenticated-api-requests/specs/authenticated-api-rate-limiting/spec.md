## ADDED Requirements

### Requirement: API autenticada compartilha cota por User
O sistema MUST limitar a 60 requisições por minuto por User autenticado as rotas protegidas atuais de Identity (`GET`, `PATCH` e `DELETE /api/users/{user}`) e Expense (`GET` e `POST /api/expenses`). A cota MUST ser compartilhada entre essas rotas e entre todos os tokens e IPs do mesmo User; Users distintos MUST ter contadores independentes. Requisições admitidas MUST consumir cota mesmo quando a operação resultar em erro após a autenticação.

#### Scenario: Cota acumulada entre contextos
- **WHEN** o mesmo User realiza 60 requisições admitidas em um minuto distribuídas entre rotas protegidas de Identity e Expense
- **THEN** a próxima requisição autenticada a qualquer uma dessas rotas recebe `429`
- **AND** o endpoint não executa a operação solicitada

#### Scenario: Tokens e IPs do mesmo User
- **WHEN** o mesmo User alterna Personal Access Tokens válidos ou IPs entre requisições
- **THEN** todas essas requisições consomem a mesma cota do User

#### Scenario: Identidades independentes
- **WHEN** um User esgota sua cota e outro User envia requisição autenticada dentro da própria cota, mesmo do mesmo IP
- **THEN** o segundo User não é bloqueado pela cota do primeiro

#### Scenario: Erro após autenticação consome cota
- **WHEN** uma requisição autenticada admitida resulta em erro de validação ou recurso inexistente no endpoint protegido
- **THEN** a tentativa ainda consome uma unidade da cota daquele User

### Requirement: Autenticação precede a cota de User
O sistema MUST resolver `auth:sanctum` antes de aplicar o limite da API autenticada, MUST preservar a resposta `401` de requisições sem Personal Access Token válido e MUST NOT atribuir a tentativa de visitante anônimo a uma cota de User. As rotas públicas de SignIn e SignUp MUST continuar usando exclusivamente seus limites públicos próprios. `DELETE /api/authentication/sign-out` MUST permanecer protegido por Sanctum, mas MUST NOT consumir nem ser bloqueado pela cota autenticada.

#### Scenario: Token ausente ou inválido
- **WHEN** uma requisição alcança uma rota protegida sem Bearer token válido
- **THEN** responde `401` em JSON:API sem consumir a cota de qualquer User
- **AND** não responde `429` pelo limite da API autenticada

#### Scenario: Rotas públicas independentes
- **WHEN** um cliente chama SignIn ou SignUp
- **THEN** a requisição não consome a cota autenticada de nenhum User
- **AND** os limites próprios dessas rotas continuam aplicáveis

#### Scenario: SignOut permanece disponível após esgotar a cota
- **WHEN** um User esgota a cota autenticada e solicita SignOut com token válido
- **THEN** o token atual é revogado e a API responde `204` sem consumir cota adicional
- **AND** uma nova tentativa com o token revogado responde `401`

### Requirement: Esgotamento da cota autenticada retorna resposta JSON:API
O sistema MUST responder ao excesso da cota de User com status `429`, `Content-Type: application/vnd.api+json`, erro JSON:API com título, detalhe e status textual `429`, e header `Retry-After`. A resposta MUST NOT expor token ou dados de outro User. Após expirar a janela, uma requisição autenticada do mesmo User MUST voltar a ser admitida.

#### Scenario: Resposta de cota excedida
- **WHEN** uma requisição autenticada excede a cota do User
- **THEN** a resposta contém `429`, erro JSON:API e `Retry-After` com tempo de espera
- **AND** não executa criação, alteração ou exclusão de recurso

#### Scenario: Janela renovada
- **WHEN** a janela do limite termina sem novas requisições admitidas
- **THEN** uma nova requisição autenticada do mesmo User volta a ser processada conforme o contrato existente do endpoint

### Requirement: Contadores autenticados usam o Redis do limiter
O sistema MUST armazenar a cota autenticada no mesmo store Redis compartilhado de rate limit já configurado para a API pública, com chave distinta das cotas de SignIn e SignUp. O sistema MUST NOT fazer fallback silencioso para cache local quando o Redis estiver indisponível e MUST manter a configuração de cache geral independente.

#### Scenario: Contagem distribuída
- **WHEN** duas instâncias conectadas ao mesmo Redis recebem requisições do mesmo User
- **THEN** ambas observam uma cota compartilhada de 60 requisições por minuto

#### Scenario: Redis indisponível
- **WHEN** Redis não está acessível durante a aplicação do limite autenticado
- **THEN** a requisição não prossegue sem limite por meio de um cache local alternativo
