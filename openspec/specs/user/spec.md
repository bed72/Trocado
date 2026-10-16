# user Specification

## Purpose
Definir o recurso User dentro do bounded context Identity, suas invariantes, persistência e operações JSON:API preservadas, mantendo Domain e Application independentes dos detalhes de framework e autenticação.
## Requirements
### Requirement: Identidade local independente de autenticação
O sistema MUST representar UserEntity em Identity Domain com ID presente UUIDv7 canônico, NameValueObject e e-mail, sem password/hash/token. Ausência de ID antes da persistência MUST ser explícita, nunca inteiro/zero. Domain/Application MUST permanecer independentes de Laravel, Eloquent, HTTP, Sanctum e Infrastructure, podendo consumir o conceito puro UUID de Core. UserModel MUST integrar os contratos Laravel/Sanctum somente na borda. A transição local autorizada MUST NOT inventar credenciais, converter IDs antigos ou criar compatibilidade com usuários legados descartados.

#### Scenario: Entidade criada com credencial fora do Domain
- **WHEN** SignUp registra nome, e-mail e password válidos
- **THEN** UserEntity representa somente a identidade criada com UUIDv7
- **AND** password hash e tokens permanecem fora da Entity

#### Scenario: Usuário preexistente permanece sem credencial conhecida
- **WHEN** o ambiente legado é substituído pelo reset local autorizado, sem dados a conservar
- **THEN** nenhuma credencial antiga é recuperada ou sintetizada
- **AND** novas contas só recebem credenciais pelo fluxo explícito de SignUp

#### Scenario: Entidade permanece pura
- **WHEN** as dependências de UserEntity são verificadas
- **THEN** a entidade valida seu ID por conceito PHP puro e não depende de Laravel, Illuminate, Eloquent, HTTP, Infrastructure, Sanctum ou contratos de autenticação

#### Scenario: Model integra com o framework
- **WHEN** UserModel de Identity Infrastructure é inspecionado
- **THEN** implementa Authenticatable, HasApiTokens e geração UUIDv7 suportada
- **AND** essa integração não é exposta pela Entity ou contratos de Application

### Requirement: Nome válido
O sistema MUST representar o nome por `NameValueObject`, MUST remover whitespace externo, MUST reduzir whitespace repetido a um único espaço e MUST aceitar somente letras Unicode separadas por espaços. O nome canônico MUST conter entre 2 e 32 letras, inclusive, sem contar os espaços. `UserEntity` MUST carregar o `NameValueObject`, e a validação HTTP de SignUp e atualização MUST aplicar as mesmas regras do Domain.

#### Scenario: Whitespace é normalizado
- **WHEN** SignUp ou atualização recebe o nome `  Maria   Silva  `
- **THEN** o nome canônico é `Maria Silva`
- **AND** `UserEntity` carrega esse valor como `NameValueObject`

#### Scenario: Somente letras Unicode separadas por espaços
- **WHEN** o nome canônico contém dígito, pontuação, símbolo ou separador diferente de espaço
- **THEN** o Domain rejeita o nome
- **AND** nenhuma identidade é criada ou alterada

#### Scenario: Limites inclusivos contam somente letras
- **WHEN** o nome canônico contém 2 ou 32 letras, inclusive com espaços internos
- **THEN** o nome é aceito
- **AND** os espaços não são incluídos na contagem

#### Scenario: Nome fora do limite de letras
- **WHEN** o nome canônico contém menos de 2 ou mais de 32 letras
- **THEN** o Domain rejeita o nome
- **AND** nenhuma identidade é criada ou alterada

#### Scenario: Validação HTTP espelha o Domain
- **WHEN** SignUp ou atualização recebe um nome que o `NameValueObject` rejeitaria
- **THEN** a API responde `422` com pointer para `/data/attributes/name`
- **AND** o UseCase não persiste a entrada inválida

### Requirement: E-mail válido e canônico
O sistema MUST representar o e-mail por `EmailValueObject`, MUST remover espaços externos, MUST convertê-lo para minúsculas e MUST rejeitar valores que não sejam endereços de e-mail válidos. A mesma forma canônica MUST ser usada na criação, consulta e persistência.

#### Scenario: Normalização de e-mail
- **WHEN** um User é criado com o e-mail `  Maria.Silva@Example.COM  `
- **THEN** seu e-mail canônico é `maria.silva@example.com`

#### Scenario: E-mail inválido
- **WHEN** se tenta criar um User com um valor que não representa um endereço de e-mail válido
- **THEN** a criação é rejeitada por uma exceção de Domain
- **AND** nenhum User é persistido

### Requirement: Unicidade de e-mail
O sistema MUST impedir que dois Users possuam o mesmo e-mail canônico. A Application MUST apresentar uma falha explícita de e-mail já utilizado, e a persistência MUST manter uma restrição única como garantia definitiva inclusive para tentativas concorrentes.

#### Scenario: E-mail canônico duplicado
- **WHEN** existe um User com `maria@example.com` e se tenta criar outro com ` MARIA@EXAMPLE.COM `
- **THEN** a criação é rejeitada como e-mail já utilizado
- **AND** nenhum User adicional é persistido

#### Scenario: Criações concorrentes com o mesmo e-mail
- **WHEN** duas criações concorrentes tentam persistir o mesmo e-mail canônico
- **THEN** no máximo um User é persistido com esse e-mail
- **AND** a tentativa conflitante produz a mesma falha explícita de e-mail já utilizado, sem vazar uma exceção do banco

### Requirement: Consulta de User
O sistema MUST permitir consultar User por identificador e por e-mail canônico por meio de UseCases concretos. Uma identidade inexistente MUST produzir uma falha explícita da Application e MUST NOT expor Model, Builder ou consulta Eloquent.

#### Scenario: Consulta por identificador existente
- **WHEN** um User é consultado por seu identificador persistido
- **THEN** o sistema retorna o `UserEntity` correspondente

#### Scenario: Consulta por e-mail normalizado
- **WHEN** um User com `maria@example.com` é consultado usando ` Maria@Example.COM `
- **THEN** o sistema retorna o mesmo `UserEntity` por meio da forma canônica do e-mail

#### Scenario: Usuário inexistente
- **WHEN** a consulta por identificador ou e-mail não encontra um User
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Atualização parcial de User
O sistema MUST permitir atualizar somente o nome de um User existente pelo `UserRepository::update`, MUST preservar e-mail, status, verificação e tokens, MUST reaplicar normalização e invariantes do nome e MUST retornar a entidade persistida atualizada. O e-mail não é editável por este endpoint nesta etapa.

#### Scenario: Atualização de nome
- **WHEN** um novo nome válido é informado
- **THEN** o nome canônico é atualizado
- **AND** o e-mail existente, a verificação e os tokens são preservados

#### Scenario: E-mail enviado
- **WHEN** a requisição tenta atualizar ou reenviar o e-mail existente
- **THEN** responde `422` JSON:API e nenhuma atualização ou revogação é executada

#### Scenario: Nome inválido
- **WHEN** o nome informado viola as regras de `NameValueObject`
- **THEN** a atualização é rejeitada sem alterar a conta

#### Scenario: Atualização de User inexistente
- **WHEN** se tenta atualizar um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Exclusão de User
O sistema MUST excluir uma conta existente dentro de `Core` `TransactionPort`, MUST remover todos os seus Personal Access Tokens antes de remover `users` por `UserRepository::delete` e MUST reverter ambos diante de falha. A exclusão definitiva do User MUST remover também todas as suas despesas na mesma transação. Uma identidade inexistente MUST produzir a mesma falha explícita de User não encontrado.

#### Scenario: Exclusão bem-sucedida
- **WHEN** uma conta existente com múltiplos tokens é excluída
- **THEN** todos os tokens dessa identidade e seu registro `users` são removidos
- **AND** consultas e autenticação posteriores não a encontram

#### Scenario: Exclusão com despesas
- **WHEN** uma conta com despesas é removida
- **THEN** todas as despesas dessa conta são removidas definitivamente na mesma transação
- **AND** não restam despesas órfãs

#### Scenario: Falha durante exclusão
- **WHEN** a remoção da identidade falha depois da tentativa de remover tokens
- **THEN** a transação restaura os tokens e mantém o User
- **AND** mantém também todas as suas despesas

#### Scenario: Exclusão de User inexistente
- **WHEN** se tenta excluir um identificador inexistente
- **THEN** o caso de uso produz uma exceção explícita de User não encontrado

### Requirement: Contrato explícito de Repository
O sistema MUST declarar `UserRepository` na camada Application com `create(UserEntity, string password): UserEntity`, `update(UserEntity): ?UserEntity`, `delete(int): bool`, `getById(int): ?UserEntity` e `getByEmail(EmailValueObject): ?UserEntity`. A senha de criação MUST ser tratada como sensível e transitória; o contrato MUST usar apenas tipos independentes do ORM e sua implementação Eloquent MUST permanecer em Infrastructure. Apenas SignUp MUST criar contas no fluxo atual.

#### Scenario: Fronteira independente do ORM
- **WHEN** o contrato `UserRepository` é verificado
- **THEN** seus parâmetros e retornos não incluem Model, Builder, query, facade ou outro tipo de Infrastructure
- **AND** a criação não expõe password hash ou `save` genérico

#### Scenario: Criação com credencial válida
- **WHEN** `SignUpUseCase` entrega uma `UserEntity` ainda não persistida e password válido
- **THEN** `UserRepository::create` retorna `UserEntity` com ID e timestamps
- **AND** o password hash é persistido sem inserir password em texto puro ou emitir token

#### Scenario: Conflito na criação
- **WHEN** o e-mail canônico já existe ou conflita sob concorrência
- **THEN** a constraint única permite no máximo uma identidade
- **AND** `EloquentUserRepository` traduz o conflito para a exceção de Application esperada

#### Scenario: Binding da implementação
- **WHEN** o container resolve `UserRepository`
- **THEN** `IdentityServiceProvider` fornece `EloquentUserRepository`
- **AND** nenhum Repository base ou genérico é introduzido

### Requirement: CRUD HTTP JSON:API
O sistema MUST expor consulta/atualização/exclusão em /api/users/{user} somente para a conta autenticada, com alvo UUIDv7 validado/canônico antes do lookup. MUST NOT expor GET global ou POST /api/users. Recursos MUST manter type users, ID string UUIDv7, name/email/created_at/updated_at e self. Rota com ID numérico, hash, malformado ou outra versão MUST retornar 404 JSON:API, sem coerção/query inválida; owner UUID desconhecido/alheio MUST preservar não encontrado uniforme. Normalização de caixa MUST ocorrer antes da comparação de owner, sem alterar políticas de acesso.

#### Scenario: Criação HTTP removida
- **WHEN** POST /api/users é executado
- **THEN** responde 404 JSON:API
- **AND** nenhuma User é criada fora de SignUp

#### Scenario: Consulta HTTP
- **WHEN** GET /api/users/{user} referencia o UUIDv7 da conta autenticada existente
- **THEN** responde 200 com o recurso JSON:API canônico

#### Scenario: Atualização HTTP
- **WHEN** PATCH recebe UUIDv7 correspondente à conta e atributo válido
- **THEN** responde 200 com recurso atualizado e mesmo UUID

#### Scenario: Exclusão HTTP
- **WHEN** DELETE referencia UUIDv7 da conta autenticada existente
- **THEN** responde 204 sem conteúdo e conclui seu lifecycle de exclusão

#### Scenario: Erros HTTP
- **WHEN** há documento inválido, ID inexistente ou rota com ID de formato/versão inválido
- **THEN** responde JSON:API respectivamente com 422 ou 404, sem erro SQL de cast

#### Scenario: Conta de outra pessoa
- **WHEN** token de A solicita GET/PATCH/DELETE com UUIDv7 de B
- **THEN** responde 404 igual ao contrato de conta inexistente
- **AND** não lê/altera B, credenciais, tokens, despesas ou associações de recursos
- **AND** possuir UUID válido não concede acesso

#### Scenario: Requisição sem principal válido
- **WHEN** rota UUIDv7 válida é chamada sem autenticação válida
- **THEN** responde 401 JSON:API
- **AND** não revela/modifica contas

### Requirement: Persistência mínima de User
O sistema MUST persistir users.id UUIDv7 nativo, nome, e-mail canônico, password hash e timestamps, com ID imutável. UserModel MUST representar persistência/principal sem ser Entity. Tokens MUST permanecer na tabela oficial Sanctum com seus IDs/owner UUIDv7. MUST NOT inventar password aleatório, manter ID inteiro paralelo ou inferir uma entidade de apresentação. FKs/cascades MUST conservar isolamento e remover associações estáveis próprias ao excluir a conta.

#### Scenario: Registro persistido
- **WHEN** SignUp e UserRepository criam User
- **THEN** users contém UUIDv7, nome, e-mail canônico, password hash e timestamps
- **AND** não contém segredo de token, remember token ou password em texto

#### Scenario: Ausência de fallback
- **WHEN** código cria UserModel sem password fora do registro
- **THEN** a persistência rejeita
- **AND** nenhum callback inventa credencial

#### Scenario: Mapping para o domínio
- **WHEN** Repository cria/recupera registro
- **THEN** retorna Entity com ID UUIDv7 string validado, sem hash/Model
- **AND** não expõe relações/tipos Sanctum nem cast numérico do UUID

#### Scenario: Serialização segura
- **WHEN** UserModel é serializado em borda Laravel
- **THEN** password permanece oculto
- **AND** nenhum PAT ou registro auxiliar é incluído automaticamente

### Requirement: Proteção de desenvolvimento contra N+1
O sistema MUST impedir lazy loading do Eloquent fora de produção por meio de `IdentityServiceProvider`, tornando visível em desenvolvimento a principal fonte de queries N+1 relacionais. `UserModel` MUST declarar `expenses()` como relação `HasMany` pelo campo `expenses.user_id`. Consultas de múltiplos Users que acessem despesas MUST carregar a relação antecipadamente.

#### Scenario: Lazy loading em desenvolvimento
- **WHEN** `IdentityServiceProvider` inicializa fora de produção
- **THEN** `Model::preventsLazyLoading()` fica habilitado

#### Scenario: Despesas de múltiplos Users carregadas em lote
- **WHEN** múltiplos Users são consultados com `expenses` carregado antecipadamente
- **THEN** cada User possui somente suas despesas ativas
- **AND** a quantidade de queries da leitura não aumenta por User

#### Scenario: Lazy loading de despesas bloqueado
- **WHEN** a relação `expenses` é acessada sem eager loading em uma coleção de Users fora de produção
- **THEN** a proteção do Eloquent sinaliza o acesso indevido

### Requirement: Ownership de User é aplicado nos UseCases
UseCases MUST obter owner UUIDv7 de Core UserPort, validar/canonicalizar o alvo e comparar por identidade antes de Repository. MUST NOT aceitar principal do cliente, consultar Context como autoridade ou converter IDs em números. Principal ausente/inválido MUST falhar como autenticação; alvo divergente MUST produzir User não encontrado igual ao inexistente. Exclusão MUST manter unidade transacional e lifecycle de tokens/despesas/destinos/associações de identidade, sem acessar Models de outros contextos.

#### Scenario: Chamador fora de HTTP usa a própria conta
- **WHEN** alvo UUIDv7 válido equivale ao owner, inclusive somente por diferença de caixa
- **THEN** a operação segue as regras existentes com UUID canônico

#### Scenario: Chamador fora de HTTP aponta outra conta
- **WHEN** o alvo UUIDv7 diverge do owner
- **THEN** o UseCase falha antes do Repository
- **AND** não altera conta/token/despesa/associação

#### Scenario: Principal ausente
- **WHEN** não há owner UUIDv7 autenticado válido
- **THEN** falha como não autenticado antes de persistência

### Requirement: Verificação de e-mail persiste separada do status de User
O sistema MUST manter `users.email_verified_at` nullable e independente de `status` (`pending`, `active`, `blocked`). `UserModel` MUST implementar `Illuminate\Contracts\Auth\MustVerifyEmail` e usar os recursos nativos do Laravel nas bordas. O timestamp MUST NOT entrar em `UserEntity` apenas por existir no schema; Repository e UseCases de User MUST manter tipos sem Eloquent nem detalhes do framework. A migration MUST ser incremental e não apagar ou verificar implicitamente contas existentes.

#### Scenario: Estados ortogonais
- **WHEN** um endereço de uma conta `pending` é confirmado
- **THEN** a conta pode estar simultaneamente `pending` e com `email_verified_at` preenchido
- **AND** GET/PATCH/DELETE preservam suas regras atuais de autenticação e ownership

#### Scenario: Migração com conta preexistente
- **WHEN** a migration é aplicada sobre tabela `users` com registros existentes
- **THEN** ela adiciona o campo nullable sem excluir registros nem mudar seus status ou tokens
- **AND** uma conta com valor nulo continua sujeita às regras novas de acesso

### Requirement: E-mail de User é imutável pela API nesta etapa
O sistema MUST aceitar somente `name` como atributo de `PATCH /api/users/{user}`. Uma tentativa de incluir `email`, mesmo igual ao atual ou canonicamente equivalente, MUST responder `422` em JSON:API antes do UseCase, sem alterar e-mail, verificação, tokens ou outros atributos. `UpdateUserUseCase` MUST aceitar somente ID e nome e `UserRepository::update` MUST persistir somente o nome; não deve haver operação exposta de alteração de e-mail e revogação de tokens nessa interface. Atualizar nome MUST conservar o timestamp de verificação e todos os tokens. A checagem de ownership permanece obrigatória.

#### Scenario: E-mail diferente é enviado no PATCH
- **WHEN** o titular autenticado tenta enviar `email` novo no PATCH
- **THEN** responde `422` JSON:API com erro de validação e não altera User
- **AND** preserva todos os tokens, o e-mail e `email_verified_at` anteriores
- **AND** não solicita novo envio de verificação

#### Scenario: Mesmo e-mail canônico é enviado no PATCH
- **WHEN** o titular envia seu próprio e-mail com ou sem diferenças de caixa/espaços
- **THEN** responde `422` JSON:API sem alterar os dados ou tokens

#### Scenario: Atualização só de nome
- **WHEN** o titular altera o nome válido sem incluir e-mail
- **THEN** responde `200` com recurso `users` contendo nome atualizado e o mesmo e-mail
- **AND** verificação e todos os tokens são preservados, sem enfileirar nova mensagem

#### Scenario: Tentativa de alterar conta de terceiro
- **WHEN** um token da conta A tenta editar o nome da conta B
- **THEN** recebe o mesmo `404` de ownership atual antes de ler ou alterar B
- **AND** nenhum token é revogado

#### Scenario: Entrada inválida ou usuário removido
- **WHEN** o nome é inválido ou o alvo não existe
- **THEN** preserva a conta e os tokens, sem notificação de verificação
