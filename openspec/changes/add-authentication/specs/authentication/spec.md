## ADDED Requirements

### Requirement: Authentication usa Laravel Sanctum
O sistema MUST usar Laravel Sanctum como mecanismo de autenticação HTTP e MUST NOT implementar guard, principal, formato de token, geração de token, digest, tabela de token ou resolução Bearer próprios.

#### Scenario: Dependência suportada
- **WHEN** a implementação de Authentication é inspecionada
- **THEN** `laravel/sanctum` é uma dependência de produção compatível com a versão instalada do Laravel
- **AND** rotas protegidas usam o guard `sanctum`

#### Scenario: Ausência de infraestrutura paralela
- **WHEN** os componentes de sessão e token são inspecionados
- **THEN** tokens de API usam `personal_access_tokens` e o guard do Sanctum
- **AND** não existem `authentication_sessions`, token generator, token digest, request guard ou principal equivalentes mantidos pela aplicação

### Requirement: Authentication respeita as fronteiras do projeto
O sistema MUST manter regras de senha e orquestração próprias nas camadas adequadas, MUST manter Domain e Application livres de Laravel e MUST limitar integrações com Auth, Eloquent e Sanctum a Infrastructure ou Presentation.

#### Scenario: Fronteiras arquiteturais
- **WHEN** as dependências de Authentication são verificadas
- **THEN** Domain utiliza somente tipos próprios e PHP
- **AND** Application utiliza somente seu Domain e contratos próprios
- **AND** Auth, Eloquent, Sanctum e tipos de User aparecem somente nas bordas permitidas

#### Scenario: Sem abstração do pacote
- **WHEN** a integração Sanctum é inspecionada
- **THEN** não existe wrapper que apenas renomeia uma única chamada de `createToken`, `currentAccessToken` ou `auth:sanctum`
- **AND** contratos próprios existem somente quando preservam uma fronteira real de Application

### Requirement: UserModel é o principal autenticável
O sistema MUST usar `UserModel` como principal Eloquent dos guards Laravel, MUST habilitá-lo com `HasApiTokens` e MUST manter `UserEntity` sem framework, password, token ou sessão.

#### Scenario: Principal resolvido pelo Sanctum
- **WHEN** uma requisição protegida é autenticada por sessão first-party ou Bearer token
- **THEN** `$request->user()` retorna o `UserModel` correspondente
- **AND** Sanctum disponibiliza o token atual quando o transporte for Bearer

#### Scenario: Domain permanece puro
- **WHEN** `UserEntity` é inspecionada
- **THEN** ela não implementa `Authenticatable` nem usa `HasApiTokens`
- **AND** contém somente o estado de identidade definido pela capability User

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
- **THEN** não existem tabelas `authentication_credentials` ou `authentication_sessions`
- **AND** tokens ficam na tabela oficial `personal_access_tokens`

### Requirement: Senha válida e preservada
O sistema MUST preservar exatamente a senha informada, MUST aceitar somente senhas com ao menos 8 caracteres e no máximo 72 bytes e MUST confirmar a senha no `SignUp` HTTP.

#### Scenario: Senha válida com espaços
- **WHEN** `SignUp` recebe senha confirmada dentro dos limites contendo espaços externos
- **THEN** o valor exato é entregue ao hasher sem trim ou normalização

#### Scenario: Senha fora dos limites
- **WHEN** a senha possui menos de 8 caracteres ou mais de 72 bytes
- **THEN** responde `422`
- **AND** nenhum User, token ou sessão é criado

#### Scenario: Confirmação divergente
- **WHEN** `password_confirmation` difere de `password`
- **THEN** responde `422` com pointer para `/data/attributes/password_confirmation`

### Requirement: SignUp cria conta atomicamente
O sistema MUST criar nome, e-mail canônico e password hash em uma única transação, MUST preservar a unicidade de e-mail e MUST NOT autenticar ou emitir token implicitamente.

#### Scenario: SignUp bem-sucedido
- **WHEN** nome, e-mail disponível e senha confirmada são válidos
- **THEN** um único registro `users` é persistido com password hash
- **AND** nenhum Personal Access Token ou sessão web é criado

#### Scenario: E-mail já utilizado
- **WHEN** o e-mail canônico já pertence a um User
- **THEN** responde `409` sem alterar aquele User
- **AND** não cria password, token ou sessão adicional

#### Scenario: Concorrência no mesmo e-mail
- **WHEN** dois `SignUp` concorrentes usam o mesmo e-mail canônico
- **THEN** a constraint única permite somente uma conta
- **AND** a tentativa conflitante é traduzida para o mesmo `409`

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
- **THEN** nenhum Personal Access Token ou sessão web é criado

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

### Requirement: Web usa sessão Laravel first-party
O fluxo web MUST usar guard `web`, sessão e cookie nativos do Laravel, MUST regenerar a sessão após `SignIn`, MUST proteger operações mutáveis por CSRF e MUST NOT colocar Personal Access Token em cookie próprio.

#### Scenario: SignIn web
- **WHEN** credenciais válidas e CSRF válido são enviados ao endpoint web
- **THEN** o guard `web` autentica o User e regenera o session ID
- **AND** redireciona sem token no corpo, URL ou flash data

#### Scenario: Cookie protegido
- **WHEN** a sessão web é emitida
- **THEN** o cookie é criptografado e assinado, `HttpOnly`, `SameSite=Lax` e `Secure` em produção
- **AND** sua configuração vem do mecanismo de sessão Laravel

#### Scenario: Ausência de CSRF
- **WHEN** uma operação web mutável não possui prova CSRF válida
- **THEN** o middleware web rejeita a operação
- **AND** nenhuma conta ou autenticação é alterada

### Requirement: Sanctum reconhece sessão ou Bearer
Rotas protegidas MUST usar `auth:sanctum` e MUST aceitar sessão first-party válida ou Personal Access Token Bearer válido conforme a resolução oficial do pacote.

#### Scenario: Bearer válido
- **WHEN** uma requisição envia Personal Access Token válido em `Authorization: Bearer`
- **THEN** Sanctum resolve o `UserModel` correspondente
- **AND** disponibiliza `currentAccessToken()`

#### Scenario: Sessão web válida
- **WHEN** uma requisição first-party envia sessão Laravel válida
- **THEN** Sanctum resolve o mesmo `UserModel` pelo guard web
- **AND** não cria Personal Access Token

#### Scenario: Credencial ausente ou inválida
- **WHEN** não existe sessão first-party nem Bearer token válido
- **THEN** a API responde `401` em JSON:API

### Requirement: SignOut encerra somente o mecanismo atual
O sistema MUST revogar somente o Personal Access Token atual no fluxo API e MUST encerrar somente a sessão atual no fluxo web, sem apagar password ou outras autenticações do User.

#### Scenario: SignOut de API
- **WHEN** `DELETE /api/authentication/sign-out` recebe Bearer válido
- **THEN** remove `currentAccessToken()` e responde `204`
- **AND** reapresentar o token removido resulta em `401`

#### Scenario: Outros tokens preservados
- **WHEN** um User possui dois Personal Access Tokens e encerra um deles
- **THEN** somente o token atual é removido
- **AND** o outro continua válido

#### Scenario: SignOut web
- **WHEN** o endpoint web recebe sessão e CSRF válidos
- **THEN** executa logout, invalida a sessão e regenera o token CSRF
- **AND** redireciona como visitante sem revogar Personal Access Tokens

### Requirement: Rate limiting de SignIn
O sistema MUST limitar `SignIn` a cinco tentativas por minuto por combinação de IP e digest da forma normalizada do e-mail, MUST compartilhar a regra entre API e web e MUST NOT persistir e-mail em claro na chave.

#### Scenario: Limite excedido
- **WHEN** ocorre a sexta tentativa na mesma janela e chave
- **THEN** a API responde `429` antes de verificar credenciais ou emitir token

#### Scenario: Chaves independentes
- **WHEN** muda o IP ou o e-mail normalizado
- **THEN** a tentativa usa outra chave de rate limiting

#### Scenario: Chave opaca
- **WHEN** a chave é persistida pelo backend
- **THEN** contém digest do e-mail e não o e-mail em claro

### Requirement: Erros seguem JSON:API
A API MUST responder erros de Authentication com `application/vnd.api+json`, array `errors`, status textual, título e detalhe seguros, e MUST fornecer `source.pointer` para validação.

#### Scenario: Mapeamento de falhas
- **WHEN** ocorre credencial inválida, conflito, validação ou throttling
- **THEN** responde respectivamente `401`, `409`, `422` ou `429`
- **AND** não inclui stack trace, password, hash ou token

### Requirement: Authentication não concede autorização
O sistema MUST limitar Authentication à comprovação do principal e MUST NOT interpretar sessão ou token válido como autorização sobre recursos de User ou Budget.

#### Scenario: Rotas existentes
- **WHEN** esta mudança é aplicada
- **THEN** nenhuma autorização genérica é adicionada aos endpoints atuais de User ou Budget
- **AND** regras de ownership permanecem responsabilidade de specs próprias

### Requirement: Naming e cobertura
O sistema MUST usar `SignUp`, `SignIn` e `SignOut` nos adaptadores próprios, MUST usar a terminologia `AccessToken` para o recurso emitido pelo Sanctum e MUST cobrir os fluxos críticos automatizados e por Bruno.

#### Scenario: Cobertura automatizada
- **WHEN** a suíte focada é executada
- **THEN** cobre SignUp atômico, falhas genéricas, token Sanctum, expiração, sessão web, CSRF, rate limiting e SignOut seletivo

#### Scenario: Collection Bruno segura
- **WHEN** o fluxo manual da API é executado
- **THEN** mantém o Bearer token apenas em variável de runtime
- **AND** confirma `SignUp`, `SignIn`, `SignOut` e rejeição do token revogado sem versionar segredo real
