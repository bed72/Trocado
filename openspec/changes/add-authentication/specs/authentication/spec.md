## ADDED Requirements

### Requirement: Authentication como bounded context independente
O sistema MUST organizar Authentication em `app/Authentication/{Domain,Application,Infrastructure,Presentation}`, MUST manter Domain livre de framework e MUST manter Application livre de Eloquent, HTTP, facades, Infrastructure, Presentation e tipos pertencentes a outros bounded contexts.

#### Scenario: Fronteiras arquiteturais de Authentication
- **WHEN** as dependências do novo contexto são verificadas
- **THEN** Domain utiliza somente seus próprios tipos e PHP
- **AND** Application utiliza somente seu Domain e seus próprios contratos
- **AND** integrações Laravel e entre contextos permanecem em Infrastructure ou Presentation conforme seus papéis

#### Scenario: Ausência de serviço agregador
- **WHEN** os casos de uso de Authentication são inspecionados
- **THEN** `SignUp`, `SignIn` e `SignOut` são UseCases concretos e separados
- **AND** não existe `AuthenticationService`, UseCase base ou interface por UseCase

### Requirement: User permanece independente de Authentication
O sistema MUST manter nome, e-mail e identidade no bounded context User, MUST persistir credenciais e sessões fora da tabela `users` e MUST NOT fazer `UserEntity` ou `UserModel` implementar contratos de autenticação do Laravel.

#### Scenario: Estrutura de User inalterada
- **WHEN** Authentication é instalado
- **THEN** a tabela `users` continua contendo somente os dados definidos pela capability User
- **AND** nenhuma coluna de password, password hash, token, sessão ou remember token é adicionada a ela

#### Scenario: Model de User permanece comum
- **WHEN** `UserModel` é inspecionado
- **THEN** ele continua sendo um Model Eloquent comum
- **AND** não implementa `Illuminate\Contracts\Auth\Authenticatable`

### Requirement: Integração com User por Port
Authentication Application MUST depender de `UserIdentityPort` para criar e localizar identidades, MUST usar `userId` como vínculo persistente e MUST NOT importar `UserEntity`, `EmailValueObject`, `UserRepository` ou UseCases de User.

#### Scenario: Resolução de e-mail no contexto proprietário
- **WHEN** `SignInUseCase` procura uma identidade pelo e-mail recebido
- **THEN** ele chama `UserIdentityPort` com o valor de entrada
- **AND** `UserIdentityAdapter` delega a resolução ao contexto User
- **AND** a canonicalização do e-mail é aplicada pelo contexto User

#### Scenario: Dependência entre contextos isolada
- **WHEN** as dependências entre namespaces são verificadas
- **THEN** somente Authentication Infrastructure referencia Application ou Domain de User
- **AND** essa exceção está declarada no allowlist arquitetural

#### Scenario: Localização futura do EmailValueObject
- **WHEN** a implementação do Email VO mudar dentro de User ou para um Core compartilhado
- **THEN** os contratos e UseCases de Authentication permanecem independentes daquele namespace

### Requirement: Credencial local separada
O sistema MUST representar no máximo uma credencial local por User, MUST persistir somente `userId`, password hash e timestamps em `authentication_credentials` e MUST garantir a unicidade de `userId` no banco.

#### Scenario: Persistência de credencial
- **WHEN** uma credencial local é criada para um User
- **THEN** `authentication_credentials` contém uma referência única a `users.id`
- **AND** contém um password hash adaptativo
- **AND** não contém nome ou e-mail duplicado

#### Scenario: User sem credencial
- **WHEN** uma identidade User não possui registro em `authentication_credentials`
- **THEN** ela continua sendo uma identidade válida para o contexto User
- **AND** não pode concluir `SignIn` por senha

#### Scenario: Exclusão da identidade
- **WHEN** um User é excluído
- **THEN** sua credencial e todas as suas sessões são removidas por integridade referencial
- **AND** nenhuma credencial ou sessão órfã permanece

### Requirement: Senha válida e confidencial
O sistema MUST preservar exatamente a senha informada, MUST aceitar somente senhas com ao menos 8 caracteres e no máximo 72 bytes e MUST manter a senha em texto puro apenas durante o processamento necessário para criar ou verificar seu hash.

#### Scenario: Senha dentro da política
- **WHEN** `SignUp` recebe uma senha confirmada dentro dos limites
- **THEN** o Domain aceita o valor sem remover espaços ou modificar caracteres

#### Scenario: Senha muito curta
- **WHEN** `SignUp` recebe uma senha com menos de 8 caracteres
- **THEN** a operação é rejeitada com erro de entrada `422`
- **AND** nenhuma identidade ou credencial é persistida

#### Scenario: Senha acima do limite
- **WHEN** `SignUp` recebe uma senha acima de 72 bytes
- **THEN** a operação é rejeitada com erro de entrada `422`
- **AND** nenhuma identidade ou credencial é persistida

#### Scenario: Senha não confirmada
- **WHEN** `password_confirmation` não corresponde exatamente a `password`
- **THEN** o Request rejeita o documento com `422`
- **AND** aponta o atributo inválido no erro JSON:API

#### Scenario: Segredo ausente de saídas
- **WHEN** qualquer operação de Authentication responde, falha ou registra diagnóstico
- **THEN** password, password hash e token digest não aparecem em resposta, URL, log ou mensagem pública

### Requirement: Hash adaptativo de senha
Authentication Application MUST usar `PasswordHasherPort` para criar, verificar e detectar hashes defasados, e Infrastructure MUST implementar essa capacidade com o hasher configurado pelo Laravel sem expor facades ou algoritmos concretos à Application.

#### Scenario: Criação do hash
- **WHEN** `SignUp` aceita uma senha válida
- **THEN** a senha é transformada em hash adaptativo antes da persistência
- **AND** somente o hash é entregue ao `CredentialRepository`

#### Scenario: Verificação de senha
- **WHEN** `SignIn` encontra uma credencial
- **THEN** a comparação é executada pelo `PasswordHasherPort`
- **AND** não por comparação direta de strings ou hash determinístico rápido

#### Scenario: Rehash após autenticação
- **WHEN** a senha está correta e o hash persistido usa parâmetros defasados
- **THEN** o sistema produz e persiste um hash atualizado
- **AND** conclui o mesmo `SignIn` sem exigir alteração da senha

### Requirement: SignUp cria identidade e credencial atomicamente
`SignUpUseCase` MUST criar uma nova identidade em User e sua credencial local dentro de uma única unidade transacional, MUST produzir o password hash antes da transação e MUST NOT criar sessão implicitamente.

#### Scenario: SignUp bem-sucedido
- **WHEN** `SignUp` recebe nome, e-mail disponível, senha válida e confirmação correspondente
- **THEN** User persiste uma identidade com o e-mail canônico
- **AND** Authentication persiste uma credencial vinculada ao novo `userId`
- **AND** nenhuma sessão é criada

#### Scenario: Falha ao persistir a credencial
- **WHEN** a identidade é inserida mas a persistência da credencial falha dentro da operação
- **THEN** a transação reverte a identidade e a credencial
- **AND** nenhum User incompleto permanece

#### Scenario: E-mail já utilizado
- **WHEN** `SignUp` recebe um e-mail canônico pertencente a User existente
- **THEN** a operação responde `409`
- **AND** não anexa credencial ao User existente
- **AND** não cria outra identidade ou sessão

#### Scenario: Concorrência no mesmo e-mail
- **WHEN** dois `SignUp` concorrentes usam o mesmo e-mail canônico
- **THEN** a constraint única permite somente uma identidade e uma credencial
- **AND** a tentativa conflitante é traduzida para a mesma falha de e-mail utilizado

### Requirement: Contrato JSON:API de SignUp
A API MUST expor `POST /api/authentication/sign-up` com nome `authentication.api.sign-up`, MUST aceitar um documento JSON:API `sign-ups` e MUST responder em JSON:API sem representar password ou credencial secreta.

#### Scenario: Request válido de SignUp
- **WHEN** a API recebe `data.type` igual a `sign-ups` e os atributos `name`, `email`, `password` e `password_confirmation` válidos
- **THEN** responde `201` com um recurso `sign-ups`
- **AND** o identificador corresponde ao `userId` criado
- **AND** o relacionamento `user` referencia o recurso `users` criado
- **AND** o header `Location` referencia `/api/users/{id}` para o User criado

#### Scenario: Estrutura inesperada no SignUp
- **WHEN** o documento omite membros obrigatórios, usa outro `data.type` ou inclui atributo não permitido
- **THEN** responde `422` com `application/vnd.api+json`
- **AND** cada erro contém `source.pointer` para o membro inválido

#### Scenario: SignUp não autentica
- **WHEN** a API conclui `SignUp`
- **THEN** a resposta não contém token
- **AND** o novo User precisa executar `SignIn` separadamente

### Requirement: SignIn usa e-mail e senha
`SignInUseCase` MUST receber e-mail e senha, MUST resolver o `userId` por `UserIdentityPort`, MUST verificar a credencial associada e MUST criar uma nova sessão somente quando a senha corresponder.

#### Scenario: SignIn válido
- **WHEN** e-mail canônico identifica um User com credencial e a senha corresponde ao hash
- **THEN** uma nova AuthenticationSession é persistida para aquele `userId`
- **AND** o resultado contém o token puro somente para entrega imediata

#### Scenario: E-mail com forma não canônica
- **WHEN** `SignIn` recebe espaços externos ou diferença de caixa em um e-mail válido
- **THEN** User aplica sua canonicalização existente
- **AND** a mesma identidade e credencial são encontradas

#### Scenario: User sem credencial
- **WHEN** o e-mail identifica User existente sem credencial local
- **THEN** `SignIn` falha como credenciais inválidas
- **AND** nenhuma sessão é criada

### Requirement: Falha de SignIn não enumera usuários
O sistema MUST produzir a mesma `InvalidCredentialsException`, o mesmo status `401`, o mesmo título e o mesmo detalhe público quando o e-mail for inválido, o User não existir, a credencial não existir ou a senha estiver incorreta.

#### Scenario: E-mail sintaticamente inválido
- **WHEN** `SignIn` recebe e-mail que User considera inválido
- **THEN** responde com o erro público genérico de credenciais inválidas
- **AND** não informa que o formato, o User ou a credencial falhou

#### Scenario: User inexistente
- **WHEN** `SignIn` recebe e-mail válido sem identidade correspondente
- **THEN** responde com o mesmo erro público de credenciais inválidas
- **AND** nenhuma sessão é criada

#### Scenario: Senha incorreta
- **WHEN** `SignIn` encontra User e credencial mas a senha não corresponde
- **THEN** responde com o mesmo erro público de credenciais inválidas
- **AND** nenhuma sessão é criada

#### Scenario: Caminho sem hash real
- **WHEN** User ou credencial não existe
- **THEN** o sistema ainda executa uma verificação contra hash fictício válido
- **AND** não condiciona a mensagem pública à existência do registro

### Requirement: Sessão opaca server-side
O sistema MUST criar AuthenticationSession server-side com identificador não secreto, `userId`, digest único do token, criação e expiração fixa, MUST gerar token com ao menos 256 bits de entropia criptográfica e MUST persistir somente seu digest SHA-256.

#### Scenario: Emissão da sessão
- **WHEN** `SignIn` é concluído
- **THEN** um token opaco novo é gerado pelo `SessionTokenPort`
- **AND** somente seu digest é persistido em `authentication_sessions`
- **AND** o token puro não pode ser reconstruído a partir do registro

#### Scenario: Tokens distintos
- **WHEN** o mesmo User conclui dois `SignIn`
- **THEN** duas sessões independentes com tokens e identificadores distintos são criadas
- **AND** ambas podem permanecer válidas simultaneamente

#### Scenario: Expiração configurada
- **WHEN** uma sessão é emitida sem override de configuração
- **THEN** sua expiração é fixada em 120 minutos após a emissão
- **AND** requisições não prolongam automaticamente essa expiração

#### Scenario: Colisão de digest
- **WHEN** a persistência encontra um digest já existente
- **THEN** a constraint única impede duas sessões com o mesmo digest
- **AND** o segredo colidente não é retornado como sessão válida

### Requirement: Contrato JSON:API de SignIn por Bearer
A API MUST expor `POST /api/authentication/sign-in` com nome `authentication.api.sign-in`, MUST aceitar um documento JSON:API `sign-ins` com e-mail e senha e MUST responder com a nova AuthenticationSession e o token Bearer somente uma vez.

#### Scenario: SignIn de API bem-sucedido
- **WHEN** a API recebe `data.type` igual a `sign-ins` e credenciais válidas
- **THEN** responde `200` com `data.type` igual a `authentication-sessions`
- **AND** inclui o identificador não secreto da sessão, `token`, `token_type` igual a `Bearer` e `expires_at`
- **AND** relaciona a sessão ao recurso `users` autenticado

#### Scenario: Resposta com token não armazenável em cache
- **WHEN** a API devolve o token após `SignIn`
- **THEN** a resposta contém `Cache-Control: no-store`
- **AND** contém `Pragma: no-cache`
- **AND** usa `application/vnd.api+json`

#### Scenario: Token não é relido
- **WHEN** a sessão já foi emitida e outra resposta consulta ou utiliza a sessão
- **THEN** o token puro não é recuperado da persistência nem devolvido novamente

### Requirement: Transporte web por cookie protegido
O fluxo web MUST transportar o mesmo token opaco em cookie Laravel criptografado e assinado, `HttpOnly`, `SameSite=Lax`, path `/` e `Secure` em produção, MUST NOT incluir o token no corpo, URL, HTML ou flash data e MUST proteger operações mutáveis por CSRF.

#### Scenario: SignIn web bem-sucedido
- **WHEN** o endpoint web de `SignIn` recebe credenciais válidas e CSRF válido
- **THEN** chama o mesmo `SignInUseCase` usado pela API
- **AND** anexa o token a um cookie protegido com expiração correspondente à sessão
- **AND** redireciona sem expor o token

#### Scenario: Requisição web sem CSRF
- **WHEN** uma requisição mutável de Authentication usa transporte web sem prova CSRF válida
- **THEN** o middleware web rejeita a operação
- **AND** nenhuma identidade, credencial ou sessão é alterada

#### Scenario: Cookie acessível ao servidor
- **WHEN** uma requisição web seguinte inclui o cookie válido
- **THEN** o request guard resolve a mesma AuthenticationSession server-side
- **AND** scripts do navegador não conseguem ler o cookie por ele ser `HttpOnly`

#### Scenario: Ambiente de produção
- **WHEN** a aplicação opera em produção
- **THEN** o cookie de Authentication é emitido somente com a flag `Secure`

### Requirement: Resolução inequívoca do token
O request guard MUST aceitar o token pelo header Bearer ou pelo cookie configurado, MUST autenticar somente sessões existentes e não expiradas e MUST rejeitar uma requisição que apresente credenciais conflitantes nos dois transportes.

#### Scenario: Bearer válido
- **WHEN** uma requisição envia `Authorization: Bearer` com token pertencente a sessão válida
- **THEN** o guard resolve o `userId` e o identificador daquela sessão

#### Scenario: Cookie válido
- **WHEN** uma requisição envia somente o cookie com token pertencente a sessão válida
- **THEN** o guard resolve o mesmo principal que seria resolvido por Bearer

#### Scenario: Credenciais conflitantes
- **WHEN** a mesma requisição apresenta Bearer e cookie com tokens diferentes
- **THEN** a autenticação é recusada com `401`
- **AND** nenhum dos dois tokens é escolhido implicitamente

#### Scenario: Mesmo token nos dois transportes
- **WHEN** Bearer e cookie contêm exatamente o mesmo token válido
- **THEN** o guard trata ambos como referência à mesma sessão
- **AND** não cria sessão adicional

### Requirement: Principal autenticado mínimo
Infrastructure MUST fornecer ao Laravel um principal autenticado contendo pelo menos `userId` e `sessionId`, MUST obter esse principal da AuthenticationSession e MUST NOT expor CredentialEntity, password hash, token digest, UserEntity ou UserModel como principal.

#### Scenario: Request autenticado
- **WHEN** o guard reconhece uma AuthenticationSession válida
- **THEN** `$request->user()` disponibiliza um principal compatível com o middleware Laravel
- **AND** seu identificador de negócio é o `userId`
- **AND** sua sessão atual é identificável para `SignOut`

#### Scenario: Dependências dos casos de uso protegidos
- **WHEN** outro contexto futuramente protege uma operação
- **THEN** a Presentation extrai o `userId` do principal
- **AND** passa um valor explícito ao UseCase de negócio
- **AND** não passa Request, guard ou principal Laravel para Application

### Requirement: Sessão expirada ou revogada não autentica
O sistema MUST considerar inválida uma sessão revogada, ausente ou cuja expiração não seja posterior ao instante atual, independentemente do transporte usado.

#### Scenario: Sessão expirada por Bearer
- **WHEN** uma requisição apresenta token cujo registro alcançou `expires_at`
- **THEN** responde `401` no formato JSON:API
- **AND** não disponibiliza principal autenticado

#### Scenario: Sessão expirada por cookie
- **WHEN** uma requisição web apresenta cookie de sessão expirada
- **THEN** a autenticação é recusada
- **AND** o cookie pode ser expirado na resposta

#### Scenario: Sessão revogada
- **WHEN** o token de uma sessão removida é reapresentado
- **THEN** responde como não autenticado
- **AND** a sessão não pode ser recriada a partir do token antigo

### Requirement: SignOut revoga somente a sessão atual
`SignOutUseCase` MUST remover a AuthenticationSession identificada pelo principal atual, MUST preserve outras sessões do mesmo User e MUST NOT apagar a credencial local.

#### Scenario: SignOut de API
- **WHEN** `DELETE /api/authentication/sign-out` recebe Bearer válido
- **THEN** a sessão correspondente é removida
- **AND** responde `204` sem conteúdo
- **AND** reapresentar o mesmo token resulta em `401`

#### Scenario: SignOut web
- **WHEN** o endpoint web `authentication.web.sign-out` recebe cookie e CSRF válidos
- **THEN** a sessão correspondente é removida
- **AND** o cookie é expirado na resposta
- **AND** o usuário é redirecionado como visitante

#### Scenario: Outras sessões preservadas
- **WHEN** um User possui duas sessões e executa `SignOut` em uma delas
- **THEN** somente a sessão atual é revogada
- **AND** a outra sessão continua válida até sua própria expiração ou revogação

#### Scenario: SignOut sem sessão válida
- **WHEN** o endpoint de `SignOut` não recebe uma sessão reconhecida
- **THEN** responde `401`
- **AND** nenhuma credencial ou outra sessão é alterada

### Requirement: Rate limiting de SignIn
O sistema MUST limitar `SignIn` a cinco tentativas por minuto por combinação de endereço IP e digest de uma forma operacionalmente normalizada do e-mail, MUST aplicar a regra nos transportes API e web e MUST NOT bloquear globalmente o e-mail em todos os IPs.

#### Scenario: Limite excedido na API
- **WHEN** a sexta tentativa de `SignIn` ocorre dentro da mesma janela para a mesma chave
- **THEN** a API responde `429` em JSON:API
- **AND** não verifica credencial nem cria sessão

#### Scenario: Chaves independentes
- **WHEN** outro IP tenta autenticar o mesmo e-mail ou o mesmo IP tenta outro e-mail
- **THEN** a tentativa usa uma chave de rate limiting distinta

#### Scenario: Chave não revela e-mail
- **WHEN** a chave é persistida pelo backend de rate limiting
- **THEN** ela contém um digest do e-mail operacionalmente normalizado
- **AND** não contém o e-mail em claro

### Requirement: Erros de Authentication seguem JSON:API
A API MUST responder erros de Authentication com `application/vnd.api+json`, array `errors`, status textual, título e detalhe seguros, MUST fornecer `source.pointer` para validação de entrada e MUST NOT incluir stack trace, segredo ou informação que enumere Users.

#### Scenario: Credenciais inválidas
- **WHEN** `SignIn` falha por qualquer credencial inválida
- **THEN** responde `401` com título e detalhe genéricos idênticos

#### Scenario: Conflito de SignUp
- **WHEN** o e-mail de `SignUp` já pertence a User
- **THEN** responde `409` com erro JSON:API
- **AND** não informa dados adicionais daquele User

#### Scenario: Validação de atributo
- **WHEN** um atributo de `SignUp` ou `SignIn` falha na validação HTTP
- **THEN** responde `422`
- **AND** `source.pointer` referencia `/data/attributes/<atributo>` ou o membro estrutural correspondente

#### Scenario: Acesso sem autenticação
- **WHEN** uma rota protegida recebe token ausente, inválido, expirado ou revogado
- **THEN** responde `401` no envelope JSON:API já padronizado pela aplicação

### Requirement: Authentication não concede autorização de negócio
O sistema MUST limitar Authentication à comprovação do principal e MUST NOT interpretar uma sessão válida como permissão para listar, consultar, atualizar ou excluir recursos pertencentes a qualquer contexto.

#### Scenario: Sessão válida sem regra de acesso
- **WHEN** um User autenticado tenta operar recurso de outro contexto
- **THEN** Authentication fornece somente seu `userId`
- **AND** a decisão de acesso pertence à capability proprietária do recurso

#### Scenario: Rotas existentes
- **WHEN** esta mudança é aplicada
- **THEN** ela não adiciona autorização genérica aos endpoints atuais de User e Budget
- **AND** sua proteção será definida por specs próprias com regras de ownership ou papel

### Requirement: Naming consistente de Authentication
O sistema MUST usar `SignUp`, `SignIn` e `SignOut` em classes, arquivos, rotas, testes e documentação e MUST NOT alternar esses conceitos com `Register`, `Registration`, `Login`, `Logout` ou `Authenticate`.

#### Scenario: Classes por ação
- **WHEN** os adaptadores HTTP e UseCases são inspecionados
- **THEN** usam nomes como `SignUpUseCase`, `SignInController`, `SignOutController` e `SignInApiTest`
- **AND** Responses recebem o nome do recurso representado quando aplicável, como `AuthenticationSessionResponse`

#### Scenario: Rotas nomeadas
- **WHEN** as rotas de Authentication são listadas
- **THEN** seus nomes contêm `sign-up`, `sign-in` ou `sign-out` sob o prefixo `authentication.api` ou `authentication.web`

### Requirement: Cobertura operacional e automatizada
O sistema MUST fornecer testes automatizados para Domain, Application, Infrastructure, Presentation e fronteiras arquiteturais de Authentication e MUST fornecer requests Bruno para os fluxos de API que não exponham segredos persistidos no repositório.

#### Scenario: Cobertura dos fluxos críticos
- **WHEN** a suíte focada de Authentication é executada
- **THEN** ela cobre SignUp atômico, falhas de credencial, rehash, emissão, Bearer, cookie, CSRF, expiração, conflito de transportes, rate limiting e SignOut

#### Scenario: Collection Bruno segura
- **WHEN** o fluxo manual de Authentication é executado
- **THEN** o token retornado é mantido apenas em variável de runtime
- **AND** a collection executa `SignUp`, `SignIn`, `SignOut` autenticado e a rejeição posterior do token revogado
- **AND** nenhum token real ou senha sensível é versionado
