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
O sistema MUST preservar exatamente a senha informada, MUST aceitar somente senhas entre 6 e 32 caracteres, com até 72 bytes para evitar truncamento pelo bcrypt, ao menos uma letra maiúscula e um número, e MUST confirmar a senha no `SignUp` HTTP.

#### Scenario: Senha válida com espaços
- **WHEN** `SignUp` recebe senha confirmada dentro dos limites contendo espaços externos
- **THEN** o valor exato é entregue ao hasher sem trim ou normalização

#### Scenario: Senha fora dos limites
- **WHEN** a senha possui menos de 6 caracteres, mais de 32 caracteres, mais de 72 bytes, nenhuma letra maiúscula ou nenhum número
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
O sistema MUST delegar geração, hash SHA-256, lookup, autenticação e revogação de Bearer token ao Sanctum e MUST persistir expiração individual em `personal_access_tokens.expires_at` para todo token emitido por SignIn. A validade inicial e cada extensão efetiva MUST conceder no máximo 30 dias contados do respectivo momento e MUST NOT ultrapassar 90 dias desde a emissão. Atividade fora da janela de extensão MUST NOT deslocar o prazo. O limite global de expiração contado desde `created_at` MUST NOT antecipar essa validade. O sistema MUST conservar o mesmo segredo Bearer e o mesmo registro durante a extensão, sem refresh token nem novo Personal Access Token por atividade.

#### Scenario: Token persistido com segurança
- **WHEN** Sanctum emite um Personal Access Token no SignIn
- **THEN** `personal_access_tokens` armazena somente seu hash e um `expires_at` não nulo de 30 dias após a emissão
- **AND** o plain-text token não pode ser recuperado do banco

#### Scenario: Acesso quinzenal
- **WHEN** o usuário acessa com sucesso uma rota protegida a cada 15 dias com o mesmo Bearer, antes da expiração e do limite absoluto
- **THEN** a sessão permanece válida pela política de extensão
- **AND** o identificador, o hash do token, seu segredo Bearer e a quantidade de tokens da conta não mudam por causa desses acessos

#### Scenario: Expiração
- **WHEN** passam 30 dias desde a última emissão ou extensão efetiva, sem acesso elegível na janela final de 15 dias antes de `expires_at`
- **THEN** `auth:sanctum` recusa o token em `401` JSON:API
- **AND** a requisição recusada não reativa a sessão e exige novo SignIn

#### Scenario: Atividade precoce não reinicia a contagem
- **WHEN** a única atividade após SignIn acontece no primeiro dia, com mais de 15 dias restantes, e não há acessos posteriores
- **THEN** a validade ainda termina 30 dias após o SignIn
- **AND** a atividade precoce não cria a promessa de 30 dias adicionais

#### Scenario: Teto absoluto de 90 dias
- **WHEN** decorrem 90 dias desde `created_at`, mesmo havendo atividade anterior
- **THEN** o token é recusado em `401` JSON:API
- **AND** nenhum request posterior prolonga a sessão além desse limite

#### Scenario: Limpeza de expirados
- **WHEN** a rotina oficial `sanctum:prune-expired` executa após a margem configurada
- **THEN** tokens cujo `expires_at` venceu há mais que a margem são removidos fisicamente
- **AND** a validade não depende dessa remoção, mesmo com a expiração global do Sanctum desativada

### Requirement: Resposta de SignIn representa access token
A API MUST responder SignIn válido com recurso JSON:API `access-tokens`, token Bearer retornado uma única vez e headers contra cache. O atributo `expires_at` MUST indicar a validade inicial do token no momento do SignIn, sem ser tratado como promessa de prazo imutável depois de atividade elegível.

#### Scenario: Resposta válida
- **WHEN** um token Sanctum é emitido
- **THEN** responde `200` com identificador do token, `token`, `token_type` igual a `Bearer` e `expires_at` inicial em 30 dias
- **AND** relaciona o token ao recurso `users` autenticado

#### Scenario: Resposta não armazenável
- **WHEN** a API entrega o plain-text token
- **THEN** envia `Cache-Control: no-store` e `Pragma: no-cache`
- **AND** usa `application/vnd.api+json`

#### Scenario: Token não é relido
- **WHEN** qualquer resposta posterior usa o token
- **THEN** o plain-text token não é recuperado da persistência nem devolvido novamente

#### Scenario: Validade inicial não é expiração imutável
- **WHEN** o cliente recebe `expires_at` no SignIn e, posteriormente, realiza atividade elegível
- **THEN** o prazo efetivo pode ser maior que o inicialmente comunicado, até o teto absoluto
- **AND** o cliente deve considerar a recusa `401` do servidor como necessidade de novo SignIn

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

### Requirement: SignUp solicita verificação após confirmação da conta
O sistema MUST persistir novas contas com `status = pending` e `email_verified_at = null`, MUST solicitar verificação do endereço somente depois do commit de `UserRepository::create` e MUST NOT autenticar ou emitir token no SignUp. O sucesso HTTP MUST preservar `201`, tipo `sign-ups`, relacionamento `users` e header `Location` existentes; aceitação da solicitação MUST NOT afirmar que o e-mail foi entregue.

#### Scenario: Cadastro válido
- **WHEN** o SignUp recebe nome, e-mail canônico, senha e confirmação válidos
- **THEN** a conta é persistida com `pending` e e-mail não verificado
- **AND** responde `201` com o documento JSON:API `sign-ups` e `Location` atuais
- **AND** nenhum Personal Access Token é criado
- **AND** uma única verificação é solicitada após o commit

#### Scenario: Rollback ou conflito de unicidade
- **WHEN** o cadastro é rejeitado ou a transação de criação é revertida, inclusive numa tentativa repetida pelo banco
- **THEN** nenhum e-mail referente à tentativa abortada é enfileirado
- **AND** os contratos existentes de validação e conflito permanecem

### Requirement: E-mail de verificação é assíncrono e usa os mecanismos nativos
O sistema MUST enfileirar no Redis uma notification Laravel implementando `ShouldQueue`, com URL temporária assinada produzida pela infraestrutura nativa `VerifyEmail`, usando o mailer configurado no ambiente. MUST NOT executar transporte de e-mail na requisição HTTP, introduzir serviço externo em Domain/Application ou enviar mensagem síncrona como fallback. O processamento MUST usar o endereço ainda pertencente ao usuário para o qual a solicitação foi criada.

#### Scenario: Worker entrega a verificação
- **WHEN** um cadastro confirmado solicita verificação e o worker consome o job
- **THEN** a notification é enviada pelo mailer configurado, sem envio durante o request de SignUp
- **AND** o link contém rota `verification.verify`, ID, hash do endereço de destino, assinatura e prazo

#### Scenario: Worker parado ou envio falha
- **WHEN** o worker não está disponível ou o mailer configurado falha após o cadastro
- **THEN** a conta continua `pending` e não verificada
- **AND** o job aguarda processamento ou segue retries e registro de falhas da queue
- **AND** não há emissão de token nem fallback síncrono

#### Scenario: Endereço mudou ou conta foi excluída antes do processamento
- **WHEN** a notificação antiga é processada depois que o e-mail foi alterado ou a conta foi removida
- **THEN** não envia um link antigo para o novo endereço nem trata o endereço novo como já confirmado

### Requirement: Link público confirma somente a posse do e-mail
O sistema MUST aceitar confirmação sem login através de `GET` público `verification.verify` com assinatura temporária válida, identificador existente e hash do e-mail canônico atual. MUST marcar apenas `email_verified_at` em operação atômica e emitir `Verified` somente após commit; MUST NOT modificar `status`, conceder sessão ou emitir token. O tratamento de sucesso MUST ser idempotente e retornar `204` sem conteúdo; erros da API MUST seguir JSON:API.

#### Scenario: Conta pendente confirma o endereço
- **WHEN** a conta `pending` acessa seu link válido antes de expirar, sem Bearer token
- **THEN** `email_verified_at` recebe um timestamp e o evento Laravel `Verified` é emitido uma vez
- **AND** `status` continua `pending`, a resposta é `204` e nenhum token é criado

#### Scenario: Conta bloqueada confirma o endereço
- **WHEN** a conta `blocked` acessa um link válido
- **THEN** somente o e-mail é confirmado
- **AND** ela continua `blocked` e sem acesso à aplicação

#### Scenario: Link válido repetido
- **WHEN** um link já utilizado para o mesmo e-mail, ainda válido, é acessado novamente
- **THEN** responde `204` sem atualizar o timestamp nem emitir novamente `Verified`
- **AND** nenhuma ativação ocorre

#### Scenario: Confirmação revertida
- **WHEN** a transação que marcou o e-mail verificado sofre rollback
- **THEN** `email_verified_at` permanece nulo
- **AND** o evento `Verified` não é emitido

#### Scenario: Assinatura ou prazo inválido
- **WHEN** a URL foi adulterada ou seu prazo expirou
- **THEN** responde `403` em JSON:API
- **AND** não altera conta, verificação ou tokens

#### Scenario: Conta inexistente ou hash não corresponde ao endereço atual
- **WHEN** o link identifica conta inexistente ou foi emitido para e-mail diferente do atual
- **THEN** responde `403` uniforme em JSON:API
- **AND** não confirma nenhum endereço

### Requirement: SignIn e rotas protegidas exigem e-mail confirmado e conta ativa
O sistema MUST verificar e-mail e `status = active` após validar credenciais e antes de chamar Sanctum `createToken()`. MUST rejeitar token Bearer existente de usuário cujo e-mail não está verificado nas rotas protegidas de User e Expense, sem remover as verificações atuais de status e ownership. SignOut MUST continuar disponível ao titular de token anteriormente emitido independentemente da nova condição de e-mail verificado, sujeito aos demais requisitos atuais de SignOut.

#### Scenario: E-mail confirmado e conta ainda pendente
- **WHEN** o e-mail foi confirmado, mas `status = pending`
- **THEN** SignIn conserva o `403` de conta pendente
- **AND** não cria Personal Access Token nem autoriza recursos protegidos

#### Scenario: Conta ativa sem e-mail confirmado
- **WHEN** credenciais corretas pertencem a conta `active` com `email_verified_at = null`
- **THEN** SignIn responde `403` JSON:API de e-mail não confirmado
- **AND** nenhum Personal Access Token é criado

#### Scenario: Credenciais inválidas
- **WHEN** e-mail inexiste, é inválido ou a senha está incorreta
- **THEN** permanece o mesmo `401` genérico atual
- **AND** não informa se o e-mail foi verificado

#### Scenario: Conta apta
- **WHEN** credenciais corretas pertencem a conta `active` com e-mail confirmado
- **THEN** SignIn emite token opaco Sanctum com o contrato `access-tokens` atual

#### Scenario: Token previamente emitido com endereço não confirmado
- **WHEN** um token ainda persistido é usado nas rotas de User ou Expense por conta agora não verificada
- **THEN** a requisição é rejeitada em JSON:API sem ler nem alterar recursos protegidos
- **AND** Sanctum permanece responsável pela autenticação do Bearer token

### Requirement: Reenvio público não revela contas
O sistema SHOULD disponibilizar `POST /api/authentication/email-verification/resend` para e-mail informado em documento JSON:API, sem requerer token. Requisições admitidas MUST responder `202 Accepted` uniformemente para conta inexistente, já verificada e não verificada; somente conta existente não verificada pode gerar nova notificação, mantendo seu status. O endpoint MUST possuir limites separados dos de SignIn/SignUp, armazenados no limiter compartilhado Redis: inicialmente 5 por hora por IP e 2 por hora por combinação IP/e-mail canônico, com chave sem endereço em claro. Exceder um limite MUST responder `429` JSON:API com `Retry-After`.

#### Scenario: Recuperação de e-mail perdido
- **WHEN** endereço pertence a conta ainda não verificada e a cota permite
- **THEN** responde `202`, enfileira uma notificação e não altera status nem token

#### Scenario: Endereço desconhecido ou já confirmado
- **WHEN** o endereço não pertence a conta ou já está confirmado
- **THEN** responde o mesmo `202`, sem indicar existência ou status
- **AND** nenhuma notificação adicional é enfileirada

#### Scenario: Abuso e cotas independentes
- **WHEN** o mesmo IP excede 5 tentativas por hora ou a combinação IP/e-mail excede 2
- **THEN** responde `429` com `Retry-After` e não enfileira mensagem
- **AND** as cotas de SignUp e SignIn não são consumidas pelo reenvio

### Requirement: Atividade protegida estende somente o token autenticado elegível
O sistema MUST estender exclusivamente o `expires_at` do Personal Access Token atual quando uma requisição autenticada a uma rota protegida de User ou Expense terminar com status `2xx`, o token ainda estiver válido e faltarem 15 dias ou menos para seu vencimento. A nova expiração MUST ser o menor valor entre 30 dias a partir da extensão e 90 dias a partir da emissão; uma extensão MUST NOT encurtar o prazo já vigente, atualizar `created_at` ou emitir outro token.

#### Scenario: Extensão dentro da janela
- **WHEN** uma rota protegida de User ou Expense responde `2xx` para token com 14 dias restantes e menos de 90 dias de idade
- **THEN** `expires_at` do mesmo registro passa para no máximo 30 dias após a atividade e no máximo `created_at + 90 dias`
- **AND** o Bearer apresentado continua funcionando até o novo prazo sem resposta contendo outro segredo

#### Scenario: Uso antes da janela
- **WHEN** uma rota protegida responde `2xx` e faltam mais de 15 dias para `expires_at`
- **THEN** nenhuma extensão nem escrita adicional de expiração é realizada por essa política

#### Scenario: Extensão próxima do limite absoluto
- **WHEN** uma rota protegida responde `2xx` perto do 90º dia, com menos de 15 dias de validade restantes
- **THEN** qualquer extensão termina no máximo em `created_at + 90 dias`
- **AND** o limite absoluto não se desloca quando `expires_at` muda

#### Scenario: Conta não apta ou requisição recusada
- **WHEN** a conta está inativa, não verificada ou a requisição autenticada termina com erro, inclusive `403`, `404`, `422`, `429` ou `5xx`
- **THEN** essa requisição não estende `expires_at` nem altera a quantidade de tokens
- **AND** os status e as regras de autorização existentes continuam aplicáveis

#### Scenario: Sem credencial ou com credencial vencida
- **WHEN** uma rota protegida recebe Bearer ausente, inválido, vencido ou já revogado
- **THEN** responde `401` sem extensão, novo token ou reativação do token antigo

#### Scenario: Rotas não elegíveis
- **WHEN** uma rota pública, SignIn ou SignOut é requisitada
- **THEN** não ocorre extensão por atividade
- **AND** SignOut continua a revogar somente o token atual e seus pedidos subsequentes respondem `401`

### Requirement: Extensão de sessão é segura sob concorrência
O sistema MUST revalidar na escrita que o token atual ainda existe, não venceu, não atingiu 90 dias desde a emissão e continua na janela de extensão. Atualizações simultâneas MUST NOT encurtar `expires_at`, recriar token excluído nem estender validade além de `created_at + 90 dias`. A validação de expiração MUST continuar independente da remoção física pelo pruning.

#### Scenario: Requisições paralelas com o mesmo token
- **WHEN** duas requisições elegíveis e concorrentes tentam estender a mesma sessão
- **THEN** o prazo persistido não é menor que o prazo vigente antes de cada escrita
- **AND** há somente um registro e o prazo final respeita os 90 dias

#### Scenario: Logout concorrente
- **WHEN** o token é removido pelo SignOut antes de uma extensão concorrente ser persistida
- **THEN** a extensão não recria o registro removido
- **AND** o Bearer revogado não volta a autenticar

#### Scenario: Expiração entre autenticação e escrita
- **WHEN** o token vence depois da autenticação inicial da requisição mas antes da tentativa de extensão
- **THEN** a extensão é ignorada e não reativa o token vencido

#### Scenario: Token legado ainda válido na implantação
- **WHEN** um token emitido antes da mudança ainda possui `expires_at` futuro explícito e faz uma requisição elegível
- **THEN** pode receber a extensão segundo os mesmos limites de idade e validade
- **AND** um token legado já vencido não ganha nova validade quando o limite global é desligado
