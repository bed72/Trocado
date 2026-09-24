## ADDED Requirements

### Requirement: Contadores de Authentication usam cache compartilhado
O sistema MUST manter os contadores de rate limit de SignIn e SignUp em um store Redis compartilhado entre instâncias da API, configurado independentemente do store de cache geral. O sistema MUST NOT cair silenciosamente para um store local quando o Redis estiver indisponível.

#### Scenario: Cache geral local
- **WHEN** o cache geral da aplicação usa `file` e o store do limiter usa Redis
- **THEN** tentativas de SignIn e SignUp consomem contadores no Redis
- **AND** a configuração do cache geral permanece `file`

#### Scenario: Instâncias compartilham contadores
- **WHEN** duas instâncias da API conectadas ao mesmo Redis recebem requisições para a mesma chave de limite
- **THEN** ambas observam o mesmo contador e aplicam o limite combinado

#### Scenario: Redis indisponível
- **WHEN** o store Redis do limiter não pode ser acessado
- **THEN** a API não substitui o contador pelo store local de cache

### Requirement: SignIn público limita tentativas por origem e identificador
O sistema MUST limitar `POST /api/authentication/sign-in` a 5 requisições por minuto por combinação de IP e e-mail informado e a 30 requisições por minuto por IP, independentemente do e-mail informado. Os limites MUST ser independentes dos de SignUp e MUST contar requisições admitidas mesmo quando credenciais ou documento forem inválidos ou quando o login for bem-sucedido.

#### Scenario: Tentativas repetidas para a mesma combinação
- **WHEN** um IP envia 5 requisições de SignIn para o mesmo e-mail dentro de um minuto
- **THEN** a sexta requisição para essa combinação recebe `429` antes de validar credenciais ou emitir token

#### Scenario: Variação do e-mail não contorna o limite por IP
- **WHEN** um IP envia 30 requisições de SignIn com e-mails diferentes dentro de um minuto
- **THEN** a próxima requisição desse IP recebe `429`, mesmo usando outro e-mail

#### Scenario: Identificador equivalente
- **WHEN** o mesmo IP envia e-mails que diferem apenas em caixa ou espaços externos
- **THEN** essas requisições compartilham o mesmo limite por combinação de IP e e-mail

#### Scenario: Contadores independentes
- **WHEN** uma requisição de SignIn de outro IP ainda está dentro dos seus limites
- **THEN** tentativas de um IP limitado não bloqueiam esse outro IP
- **AND** tentativas de SignUp não consomem a cota de SignIn

### Requirement: SignUp público limita cadastros por origem
O sistema MUST limitar `POST /api/authentication/sign-up` a 3 requisições por hora por IP, contando requisições admitidas independentemente de resultarem em cadastro, erro de validação ou conflito de e-mail. O limite MUST ser independente dos limites de SignIn.

#### Scenario: Cadastros sucessivos pela mesma origem
- **WHEN** um IP envia 3 requisições de SignUp dentro de uma hora
- **THEN** a quarta requisição desse IP recebe `429` antes de validar ou criar User

#### Scenario: Origem distinta
- **WHEN** outro IP envia SignUp dentro de sua própria cota
- **THEN** o esgotamento da cota do primeiro IP não impede essa requisição

### Requirement: Esgotamento de limite de Authentication responde com erro seguro
O sistema MUST responder ao esgotamento de qualquer limite público de Authentication com `429`, `Content-Type: application/vnd.api+json`, um erro JSON:API com título, detalhe e status textual `429`, e header `Retry-After`. A resposta MUST NOT revelar a existência de User, a senha, o token ou o e-mail informado. Requisições dentro da cota MUST preservar os contratos existentes de SignIn e SignUp.

#### Scenario: Limite esgotado
- **WHEN** uma requisição excede qualquer limite de SignIn ou SignUp
- **THEN** a resposta contém erro JSON:API `429` e `Retry-After` com tempo de espera
- **AND** nenhum User ou token é criado por essa requisição

#### Scenario: Requisição admitida
- **WHEN** uma requisição de SignIn ou SignUp está dentro de todos os seus limites
- **THEN** a API processa normalmente a requisição e conserva os status, envelopes e regras de autenticação já especificados

#### Scenario: Reabertura após a janela
- **WHEN** o tempo de espera indicado para o limite esgotado termina e não há novo consumo da cota
- **THEN** uma nova requisição da mesma origem pode ser processada novamente
