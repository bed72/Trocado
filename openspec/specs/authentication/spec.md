# authentication Specification

## Purpose
Definir cadastro, autenticação e encerramento de acesso à API com Laravel Sanctum, preservando as fronteiras arquiteturais, a segurança de credenciais e a revogação seletiva de tokens.
## Requirements
### Requirement: Authentication usa Laravel Sanctum
O sistema MUST usar Laravel Sanctum como mecanismo de autenticação da API e MUST NOT implementar guard, principal, formato de token, geração de token, digest, tabela de token ou resolução Bearer próprios.

#### Scenario: Dependência suportada
- **WHEN** a implementação de Authentication é inspecionada
- **THEN** `laravel/sanctum` é uma dependência de produção compatível com a versão instalada do Laravel
- **AND** rotas protegidas usam o guard `sanctum`

#### Scenario: Ausência de infraestrutura paralela
- **WHEN** os componentes de token são inspecionados
- **THEN** tokens de API usam `personal_access_tokens` e o guard do Sanctum
- **AND** não existe tabela de token própria, token generator, token digest, request guard ou principal equivalente mantido pela aplicação

### Requirement: Authentication respeita as fronteiras do projeto
O sistema MUST manter regras de password e orquestração nas camadas adequadas de Identity, MUST manter Domain e Application livres de Laravel e MUST limitar integrações com Auth, Eloquent e Sanctum a Identity Infrastructure ou Presentation.

#### Scenario: Fronteiras arquiteturais
- **WHEN** as dependências de Identity são verificadas
- **THEN** Domain utiliza somente tipos próprios e PHP
- **AND** Application utiliza somente seu Domain e contratos próprios
- **AND** Auth, Eloquent e Sanctum aparecem somente nas bordas permitidas

#### Scenario: Sem abstração do pacote
- **WHEN** a integração Sanctum é inspecionada
- **THEN** não existe wrapper que apenas renomeia uma única chamada de `createToken`, `currentAccessToken` ou `auth:sanctum`
- **AND** `SignInPort` e `SignOutPort` existem para preservar fronteiras reais de Application

### Requirement: UserModel é o principal autenticável
O sistema MUST usar `UserModel` de Identity Infrastructure como principal autenticável resolvido pelo Sanctum, MUST habilitá-lo com `HasApiTokens` e MUST manter `UserEntity` sem framework, password ou token.

#### Scenario: Principal resolvido pelo Sanctum
- **WHEN** uma requisição protegida é autenticada por Bearer token
- **THEN** `$request->user()` retorna o `UserModel` correspondente
- **AND** Sanctum disponibiliza o token atual

#### Scenario: Domain permanece puro
- **WHEN** `UserEntity` é inspecionada
- **THEN** ela não implementa `Authenticatable` nem usa `HasApiTokens`
- **AND** contém somente o estado de identidade definido por Identity

### Requirement: Password hash usa o provider Laravel
O sistema MUST armazenar somente password hash adaptativo na coluna `users.password`, MUST ocultá-lo da serialização e MUST usar o provider e hasher configurados do Laravel para autenticação.

#### Scenario: Persistência de nova conta
- **WHEN** `SignUp` cria uma conta
- **THEN** `users.password` contém um hash adaptativo verificável pelo hasher Laravel
- **AND** a senha em texto puro não é persistida nem serializada

#### Scenario: User preexistente
- **WHEN** a migration encontra User criado antes de Authentication
- **THEN** atribui um hash aleatório irrecuperável necessário ao provider
- **AND** esse User não consegue autenticar com uma senha conhecida

#### Scenario: Infraestrutura própria não é criada
- **WHEN** o schema é inspecionado
- **THEN** não existe tabela `authentication_credentials` nem tabela de token mantida pela aplicação
- **AND** tokens ficam na tabela oficial `personal_access_tokens`

### Requirement: Senha válida e preservada
O sistema MUST preservar exatamente a senha informada, MUST aceitar somente senhas entre 6 e 12 caracteres com ao menos uma letra maiúscula e um número e MUST confirmar a senha no `SignUp` HTTP.

#### Scenario: Senha válida com espaços
- **WHEN** `SignUp` recebe senha confirmada dentro dos limites contendo espaços externos
- **THEN** o valor exato é entregue ao hasher sem trim ou normalização

#### Scenario: Senha fora dos limites
- **WHEN** a senha possui menos de 6 caracteres, mais de 12 caracteres, nenhuma letra maiúscula ou nenhum número
- **THEN** responde `422`
- **AND** nenhum User ou token é criado

#### Scenario: Confirmação divergente
- **WHEN** `password_confirmation` difere de `password`
- **THEN** responde `422` com pointer para `/data/attributes/password_confirmation`

### Requirement: SignUp cria conta atomicamente
O sistema MUST criar nome, e-mail canônico e password hash na unidade definida por `Core` `TransactionPort`, MUST persistir o principal por `UserRepository::create`, MUST preservar a unicidade de e-mail e MUST NOT autenticar ou emitir token implicitamente.

#### Scenario: SignUp bem-sucedido
- **WHEN** nome, e-mail disponível e password confirmado são válidos
- **THEN** `SignUpUseCase` executa `UserRepository::create` dentro de `TransactionPort`
- **AND** um único registro `users` é persistido com password hash
- **AND** nenhum Personal Access Token é criado

#### Scenario: E-mail já utilizado
- **WHEN** o e-mail canônico já pertence a um User
- **THEN** responde `409` sem alterar aquele User
- **AND** não cria password ou token adicional

#### Scenario: Concorrência no mesmo e-mail
- **WHEN** dois `SignUp` concorrentes usam o mesmo e-mail canônico
- **THEN** a constraint única permite somente uma conta
- **AND** `UserRepository` traduz a tentativa conflitante para o mesmo `409`

### Requirement: API de SignUp segue JSON:API
A API MUST expor `POST /api/authentication/sign-up` com nome `authentication.api.sign-up`, aceitar documento `sign-ups` fechado e responder sem password ou token.

#### Scenario: SignUp válido
- **WHEN** o documento contém `name`, `email`, `password` e `password_confirmation` válidos
- **THEN** responde `201` com recurso `sign-ups` identificado pelo `userId`
- **AND** relaciona `user` ao recurso `users` e envia `Location` para `/api/users/{id}`

#### Scenario: Estrutura inválida
- **WHEN** faltam membros, `data.type` difere ou existem atributos não permitidos
- **THEN** responde `422` em JSON:API
- **AND** os erros contêm `source.pointer`

### Requirement: SignIn de API emite Personal Access Token
A API MUST expor `POST /api/authentication/sign-in` com nome `authentication.api.sign-in`, validar e-mail e senha pelo provider Laravel e emitir um novo Personal Access Token Sanctum somente após sucesso.

#### Scenario: Credenciais válidas
- **WHEN** o provider confirma as credenciais
- **THEN** Sanctum cria um registro em `personal_access_tokens`
- **AND** o resultado contém o plain-text token somente para entrega imediata

#### Scenario: Novo SignIn
- **WHEN** o mesmo User conclui dois `SignIn` válidos
- **THEN** Sanctum cria dois Personal Access Tokens distintos
- **AND** ambos permanecem válidos até expiração ou revogação individual

#### Scenario: E-mail canônico
- **WHEN** `SignIn` recebe diferença de caixa ou espaços externos em e-mail válido
- **THEN** aplica a canonicalização de User antes de consultar o provider
- **AND** encontra a mesma identidade

### Requirement: Falha de SignIn não enumera Users
O sistema MUST responder com o mesmo status, título e detalhe público quando o e-mail for inválido, o User não existir, o password hash for irrecuperável ou a senha estiver incorreta.

#### Scenario: Credenciais inválidas
- **WHEN** qualquer condição de credencial inválida ocorre
- **THEN** a API responde `401` com erro genérico idêntico
- **AND** não informa qual parte falhou

#### Scenario: Falha não emite autenticação
- **WHEN** as credenciais não são confirmadas
- **THEN** nenhum Personal Access Token é criado

### Requirement: Token de API é gerenciado pelo Sanctum
O sistema MUST delegar geração, hash SHA-256, lookup, autenticação e revogação de Bearer token ao Sanctum, MUST configurar expiração fixa padrão de 120 minutos e MUST NOT renovar o token a cada request.

#### Scenario: Token persistido com segurança
- **WHEN** Sanctum emite um Personal Access Token
- **THEN** `personal_access_tokens` armazena somente seu hash
- **AND** o plain-text token não pode ser recuperado do banco

#### Scenario: Expiração
- **WHEN** decorrem 120 minutos desde a emissão sem override
- **THEN** `auth:sanctum` recusa o token
- **AND** requests anteriores não prolongam a expiração

#### Scenario: Limpeza de expirados
- **WHEN** a rotina oficial `sanctum:prune-expired` executa após a margem configurada
- **THEN** tokens expirados elegíveis são removidos fisicamente
- **AND** a validade não depende dessa remoção

### Requirement: Resposta de SignIn representa access token
A API MUST responder `SignIn` válido com recurso JSON:API `access-tokens`, token Bearer retornado uma única vez e headers contra cache.

#### Scenario: Resposta válida
- **WHEN** um token Sanctum é emitido
- **THEN** responde `200` com identificador do token, `token`, `token_type` igual a `Bearer` e `expires_at`
- **AND** relaciona o token ao recurso `users` autenticado

#### Scenario: Resposta não armazenável
- **WHEN** a API entrega o plain-text token
- **THEN** envia `Cache-Control: no-store` e `Pragma: no-cache`
- **AND** usa `application/vnd.api+json`

#### Scenario: Token não é relido
- **WHEN** qualquer resposta posterior usa o token
- **THEN** o plain-text token não é recuperado da persistência nem devolvido novamente

### Requirement: Sanctum reconhece Bearer token
Rotas protegidas MUST usar `auth:sanctum` e MUST aceitar Personal Access Token válido enviado por `Authorization: Bearer` conforme a resolução oficial do pacote.

#### Scenario: Bearer válido
- **WHEN** uma requisição envia Personal Access Token válido em `Authorization: Bearer`
- **THEN** Sanctum resolve o `UserModel` correspondente
- **AND** disponibiliza `currentAccessToken()`

#### Scenario: Credencial ausente ou inválida
- **WHEN** não existe Bearer token válido
- **THEN** a API responde `401` em JSON:API

### Requirement: SignOut revoga somente o token atual
O sistema MUST revogar somente o Personal Access Token usado na requisição, sem apagar password ou outros tokens do User. O Controller MUST delegar a operação a `SignOutUseCase`, a Application MUST depender de `SignOutPort` e somente o Adapter de Infrastructure MUST resolver `currentAccessToken()` e excluir o Model do Sanctum.

#### Scenario: SignOut de API
- **WHEN** `DELETE /api/authentication/sign-out` recebe Bearer válido
- **THEN** remove `currentAccessToken()` e responde `204`
- **AND** reapresentar o token removido resulta em `401`

#### Scenario: Outros tokens preservados
- **WHEN** um User possui dois Personal Access Tokens e encerra um deles
- **THEN** somente o token atual é removido
- **AND** o outro continua válido

#### Scenario: Revogação respeita as camadas
- **WHEN** `SignOutController` processa uma requisição autenticada
- **THEN** chama `SignOutUseCase` sem acessar o User ou o token da Request
- **AND** `SignOutAdapter` concentra a resolução e a exclusão do token Sanctum atual

### Requirement: Erros seguem JSON:API
A API MUST responder erros de Authentication com `application/vnd.api+json`, array `errors`, status textual, título e detalhe seguros, e MUST fornecer `source.pointer` para validação.

#### Scenario: Mapeamento de falhas
- **WHEN** ocorre credencial inválida, conflito ou validação
- **THEN** responde respectivamente `401`, `409` ou `422`
- **AND** não inclui stack trace, password, hash ou token

### Requirement: Authentication não concede autorização
O sistema MUST limitar Authentication à comprovação do principal e MUST NOT interpretar token válido como autorização de negócio ou ownership sobre recursos de User ou Expense. As rotas atuais desses contextos MUST exigir `auth:sanctum`; as operações de User por ID MUST verificar ownership em seus UseCases por meio de um Port de Identity, independentemente da autenticação da rota. Outras regras de autorização e ownership MUST permanecer sob responsabilidade de specs próprias.

#### Scenario: Rotas autenticadas sem autorização de negócio
- **WHEN** um endpoint de User ou Expense recebe uma requisição sem Personal Access Token válido
- **THEN** responde `401`
- **AND** um token válido somente identifica o principal, sem provar ownership ou privilégio administrativo
- **AND** regras de autorização e ownership permanecem responsabilidade das operações de cada contexto

#### Scenario: Token válido de outra conta
- **WHEN** uma conta autenticada tenta consultar, alterar ou excluir outra conta pela rota de User
- **THEN** a autenticação é insuficiente para autorizar a operação
- **AND** a regra de ownership de User impede o acesso

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio de `IdentityServiceProvider`, sem depender da inicialização de outro bounded context.

#### Scenario: Provider de Identity em desenvolvimento
- **WHEN** `IdentityServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

### Requirement: Naming e cobertura
O sistema MUST usar `UserRepository` para persistência de User, `SignInPort` e `SignOutPort` para autenticação e `Core` `TransactionPort` para coordenação transacional, MUST usar a terminologia `AccessToken` para o recurso emitido pelo Sanctum e MUST cobrir os fluxos críticos automatizados.

#### Scenario: Cobertura automatizada
- **WHEN** a suíte focada é executada
- **THEN** cobre registro atômico pelo Repository, falhas genéricas, token Sanctum, expiração, SignOut seletivo e ausência de outro caminho público de criação

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
O sistema MUST limitar `POST /api/authentication/sign-up` por IP e por hora usando o rate limiter nativo configurado pelo ambiente, com padrão de 3 requisições por hora quando não houver override. O ambiente local MAY definir uma cota maior em `IDENTITY_SIGN_UP_PER_HOUR`, sem desabilitar o limiter ou modificar a cota padrão de produção. Requisições admitidas MUST ser contabilizadas independentemente de resultarem em cadastro, erro de validação ou conflito de e-mail. O limite MUST ser independente dos limites de SignIn.

#### Scenario: Cadastros sucessivos pela mesma origem
- **WHEN** um IP envia 3 requisições de SignUp dentro de uma hora sem override da cota padrão
- **THEN** a quarta requisição desse IP recebe `429` antes de validar ou criar User

#### Scenario: Origem distinta
- **WHEN** outro IP envia SignUp dentro de sua própria cota
- **THEN** o esgotamento da cota do primeiro IP não impede essa requisição

#### Scenario: Cota configurada no ambiente local
- **WHEN** o ambiente local configura `IDENTITY_SIGN_UP_PER_HOUR=100`
- **THEN** a centésima requisição do mesmo IP dentro de uma hora é admitida
- **AND** a seguinte recebe `429` sem afetar o padrão de 3/h de ambientes sem override

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
