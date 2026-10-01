## MODIFIED Requirements

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

## ADDED Requirements

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
