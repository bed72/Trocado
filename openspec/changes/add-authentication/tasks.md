## 1. Estrutura e persistência

- [ ] 1.1 Criar a estrutura mínima de `app/Authentication/{Domain,Application,Infrastructure,Presentation}` somente com os diretórios necessários aos arquivos desta mudança.
- [ ] 1.2 Criar a migration de `authentication_credentials` com `user_id` único, password hash, timestamps, foreign key para `users.id` e exclusão em cascata.
- [ ] 1.3 Criar a migration de `authentication_sessions` com identificador não secreto, `user_id`, `token_hash` único, `expires_at`, timestamp de criação, índices de consulta e exclusão em cascata.
- [ ] 1.4 Definir configuração explícita para duração padrão de 120 minutos, nome e atributos do cookie e demais valores operacionais sem armazenar segredos no código.
- [ ] 1.5 Executar as migrations pelo ambiente Lerd e confirmar schema, constraints, índices e rollback sem alterar as colunas de `users`.

## 2. Domain de Authentication

- [ ] 2.1 Implementar `PasswordValueObject` com preservação exata do valor, mínimo de 8 caracteres e máximo de 72 bytes, além de `InvalidPasswordException`.
- [ ] 2.2 Implementar `PasswordHashValueObject` e o Value Object do digest de sessão sem aceitar valores vazios ou expor segredos por conversão implícita.
- [ ] 2.3 Implementar `CredentialEntity` vinculada por `userId` e sem nome, e-mail, senha em claro ou dependência de User.
- [ ] 2.4 Implementar `AuthenticationSessionEntity` com identificador, `userId`, digest e expiração fixa, incluindo a decisão pura de expiração por instante explícito.
- [ ] 2.5 Adicionar testes unitários das invariantes de senha, hash, credencial e sessão, incluindo limites, preservação de espaços e expiração.

## 3. Contratos e casos de uso

- [ ] 3.1 Definir `CredentialRepository` com somente as operações exigidas por criação, busca por `userId` e atualização de hash.
- [ ] 3.2 Definir `AuthenticationSessionRepository` com operações explícitas para criar, localizar por digest e remover a sessão atual.
- [ ] 3.3 Definir `UserIdentityPort`, `PasswordHasherPort`, `SessionTokenPort`, `ClockPort` e `AuthenticationWritePort` com tipos independentes de Laravel, Eloquent e User.
- [ ] 3.4 Implementar `SignUpUseCase` com hash antes da transação, criação atômica de identidade e credencial e sem emissão implícita de sessão.
- [ ] 3.5 Implementar `SignInUseCase` com resolução por e-mail, verificação genérica de credenciais, hash fictício, rehash quando necessário e emissão de nova sessão.
- [ ] 3.6 Implementar `SignOutUseCase` para revogar somente a sessão identificada pelo principal atual.
- [ ] 3.7 Criar exceções de Application para credenciais inválidas, conflito de credencial/identidade e falhas traduzidas do Port sem reutilizar exceções de User na Presentation.
- [ ] 3.8 Adicionar testes unitários dos três UseCases cobrindo sucesso, rollback, User sem credencial, falhas indistinguíveis, rehash, múltiplas sessões e revogação seletiva.

## 4. Infrastructure e integração com User

- [ ] 4.1 Implementar `CredentialModel` e `AuthenticationSessionModel` como Models de persistência sem transformá-los em entidades de Domain.
- [ ] 4.2 Implementar `EloquentCredentialRepository` e `EloquentAuthenticationSessionRepository` com mapping, consultas indexadas e tradução das constraints relevantes.
- [ ] 4.3 Implementar `PasswordHasherAdapter` com o hasher Laravel, incluindo verificação, hash fictício e detecção de rehash.
- [ ] 4.4 Implementar `SessionTokenAdapter` com pelo menos 256 bits de entropia, codificação segura para header/cookie e digest SHA-256 determinístico para consulta.
- [ ] 4.5 Implementar `ClockAdapter` e `AuthenticationWriteAdapter`, mantendo geração de hash fora da transação e coordenação de User e Credential dentro dela.
- [ ] 4.6 Implementar `UserIdentityAdapter` sobre `CreateUserUseCase` e `GetUserByEmailUseCase`, traduzindo entidades e exceções de User para contratos de Authentication.
- [ ] 4.7 Implementar `AuthenticationServiceProvider` com somente os bindings arquiteturalmente relevantes e registrar o provider no composition root.
- [ ] 4.8 Atualizar o allowlist do teste arquitetural para permitir somente a dependência de Authentication Infrastructure em User Application/Domain.
- [ ] 4.9 Adicionar testes de integração dos Repositories, Adapters, transação entre contextos, cascatas, concorrência de `SignUp` e bindings do provider.

## 5. Guard e principal autenticado

- [ ] 5.1 Implementar o principal Laravel mínimo com `userId` e `sessionId`, sem expor `UserModel`, `UserEntity`, credencial ou hashes.
- [ ] 5.2 Implementar o resolvedor de request que extrai Bearer e cookie, recusa credenciais conflitantes, calcula o digest e aceita somente sessão não expirada.
- [ ] 5.3 Registrar um request guard próprio de Authentication e configurar o middleware Laravel para disponibilizar o principal em `$request->user()`.
- [ ] 5.4 Garantir que sessão expirada, ausente, revogada ou com token inválido produza `401` e que um registro expirado encontrado possa ser removido.
- [ ] 5.5 Adicionar testes do guard para Bearer, cookie, mesmo token nos dois transportes, conflito, expiração, revogação e principal mínimo.

## 6. API JSON:API

- [ ] 6.1 Implementar `SignUpRequest`, `SignUpController` e `SignUpResponse` para `POST /api/authentication/sign-up`, incluindo estrutura fechada, confirmação de senha, `201`, `Location` e relacionamento com User.
- [ ] 6.2 Implementar `SignInRequest`, `SignInController` e `AuthenticationSessionResponse` para `POST /api/authentication/sign-in`, incluindo resposta `200`, token Bearer retornado uma vez e headers `no-store`/`no-cache`.
- [ ] 6.3 Implementar `SignOutController` para `DELETE /api/authentication/sign-out` protegido pelo guard e com resposta `204`.
- [ ] 6.4 Registrar as rotas com nomes `authentication.api.sign-up`, `authentication.api.sign-in` e `authentication.api.sign-out` no arquivo de rotas do contexto e no composition root.
- [ ] 6.5 Mapear exceções e falhas HTTP de Authentication para erros JSON:API `401`, `409`, `422` e `429`, preservando pointers e mensagens sem enumeração.
- [ ] 6.6 Adicionar feature tests dos payloads, status, headers, envelopes, pointers, segredo retornado somente no `SignIn` e rejeição posterior do token revogado.

## 7. Transporte web por cookie

- [ ] 7.1 Implementar Controllers e Requests web de `SignUp`, `SignIn` e `SignOut` chamando os mesmos UseCases da API e retornando redirects convencionais.
- [ ] 7.2 Registrar as rotas mutáveis no grupo `web` com nomes `authentication.web.sign-up`, `authentication.web.sign-in` e `authentication.web.sign-out` e proteção CSRF.
- [ ] 7.3 Anexar o token de `SignIn` em cookie Laravel criptografado, assinado, `HttpOnly`, `SameSite=Lax`, path `/`, `Secure` em produção e com expiração alinhada à sessão.
- [ ] 7.4 Expirar o cookie em `SignOut` e evitar token em corpo, URL, HTML, flash data, logs e mensagens de erro.
- [ ] 7.5 Adicionar feature tests dos atributos do cookie, redirects, CSRF, ausência do token no conteúdo e autenticação de requests web seguintes.

## 8. Proteções operacionais

- [ ] 8.1 Configurar rate limiter de cinco tentativas de `SignIn` por minuto por IP e digest do e-mail operacionalmente normalizado, compartilhado pelos transportes API e web.
- [ ] 8.2 Testar limite excedido, independência entre chaves e ausência do e-mail em claro na chave persistida.
- [ ] 8.3 Verificar que logs, exceptions, dumps e responses não contêm password, password hash, token digest ou token puro fora da resposta inicial da API e do cookie.
- [ ] 8.4 Confirmar que nenhuma rota atual de User ou Budget recebeu autorização genérica e documentar a necessidade de specs próprias de ownership.

## 9. Verificação e documentação operacional

- [ ] 9.1 Adicionar a collection Bruno de `SignUp`, `SignIn`, `SignOut`, credenciais inválidas, validação, conflito, throttling e token revogado usando somente variáveis de runtime para segredos.
- [ ] 9.2 Executar os testes focados de Domain, Application, Infrastructure, API, web, provider e arquitetura após cada grupo implementado.
- [ ] 9.3 Executar a suíte completa, analisar falhas sem alterar testes não relacionados e confirmar que User continua independente de Authentication.
- [ ] 9.4 Executar Laravel Pint com `vendor/bin/pint --dirty --format agent` e revisar o diff final para segredos, dependências indevidas e escopo não solicitado.
- [ ] 9.5 Validar a mudança OpenSpec, confirmar todos os cenários implementados e somente então preparar o arquivamento da capability.
