## Context

O projeto organiza cada capability em um bounded context com `Domain`, `Application`, `Infrastructure` e `Presentation`. `User` já representa uma identidade local composta por identificador, nome e e-mail canônico, enquanto sua spec exige que `UserEntity`, `UserModel` e a tabela `users` permaneçam sem senha, token, sessão, verificação de e-mail ou contratos de autenticação.

A aplicação não possui `config/auth.php` próprio, migration de sessões ou pacote de autenticação adicional. As rotas atuais são JSON:API, os erros são formatados no composition root e `UserModel` estende o Model Eloquent comum. O projeto também valida por teste que Application dependa somente de seu próprio Domain e contratos, enquanto dependências entre contextos precisam ser declaradas explicitamente.

Authentication atenderá dois consumidores. Clientes de API usarão um segredo opaco como Bearer token; a aplicação web Blade usará o mesmo tipo de sessão por cookie protegido. Ambos precisam compartilhar credenciais, emissão, persistência, expiração, revogação e resolução do usuário autenticado sem forçar o navegador a armazenar um Bearer token em JavaScript.

## Goals / Non-Goals

**Goals:**

- Criar `Authentication` como bounded context independente e consistente com a arquitetura atual.
- Implementar `SignUp`, `SignIn` e `SignOut` com a mesma linguagem em UseCases, Controllers, Requests, rotas e testes.
- Preservar User como dono do e-mail e da identidade, sem dependência reversa para Authentication.
- Persistir credenciais e sessões em estruturas próprias vinculadas somente por `userId`.
- Usar uma sessão server-side revogável e um token opaco de alta entropia, armazenando apenas um digest irreversível.
- Permitir que a mesma sessão seja transportada por Bearer na API ou por cookie no fluxo Blade.
- Integrar o principal autenticado ao middleware e às APIs de autenticação do Laravel sem transformar `UserModel` em `Authenticatable`.
- Manter entradas, respostas e erros da API compatíveis com JSON:API.
- Garantir atomicidade no `SignUp`, falhas sem enumeração de usuários e rate limiting no `SignIn`.
- Deixar a estrutura preparada para mover conceitos realmente compartilhados para Core sem acoplar Authentication ao namespace atual de `EmailValueObject`.

**Non-Goals:**

- Implementar password reset, alteração de senha, verificação de e-mail, MFA, login social ou provedores OIDC/OAuth.
- Implementar refresh token, JWT, token auto-contido ou rotação automática a cada request.
- Listar sessões, nomear dispositivos, revogar outras sessões ou oferecer "lembrar-me".
- Criar credenciais para Users preexistentes ou permitir que um e-mail existente seja reivindicado por `SignUp`.
- Proteger genericamente os CRUDs de User e Budget sem suas respectivas regras de autorização.
- Criar roles, permissions, policies de negócio ou um bounded context de Authorization.
- Criar eventos sem consumidores, abstrações base ou um `AuthenticationService` agregador.
- Criar Core nesta mudança ou mover antecipadamente `EmailValueObject` para ele.

## Decisions

### Authentication será um bounded context próprio

As classes serão organizadas sob `app/Authentication/{Domain,Application,Infrastructure,Presentation}`. Domain permanecerá PHP puro; Application conterá UseCases concretos, Repositories e Ports; Infrastructure conterá Eloquent, hashing, geração de tokens, integração com User e com o guard Laravel; Presentation conterá os adaptadores HTTP de API e web.

As dependências relevantes serão registradas por `AuthenticationServiceProvider`. Classes concretas resolvidas automaticamente não receberão bindings artificiais.

Alternativa rejeitada: colocar senha e métodos de login em User. Isso contrariaria a spec existente, misturaria identidade com prova de acesso e faria outros contextos herdarem detalhes de autenticação.

### User continuará dono do e-mail

`SignInUseCase` receberá e-mail e senha como strings. Authentication não criará outro Email VO nem importará `App\User\Domain\ValueObjects\EmailValueObject`. A Application dependerá de `UserIdentityPort`, com operações mínimas para criar uma identidade e resolver um `userId` por e-mail.

`UserIdentityAdapter`, em Authentication Infrastructure, chamará os UseCases públicos de User e traduzirá seus retornos e exceções para os contratos de Authentication. A única dependência entre contextos ficará nesse Adapter e será declarada no allowlist do teste arquitetural. `CredentialRepository` nunca fará join com `users` nem buscará credenciais por e-mail.

No `SignIn`, e-mail sintaticamente inválido, identidade ausente e credencial ausente convergirão para a mesma falha. No `SignUp`, dados inválidos e e-mail já utilizado continuarão distinguíveis como `422` e `409`.

Quando Core existir, `EmailValueObject` poderá ser movido para ele se sua semântica for realmente compartilhada. O Port de Authentication permanecerá estável, limitando a mudança a User e aos consumidores que decidirem usar diretamente o tipo compartilhado.

Alternativa rejeitada: importar o Email VO de User em Authentication Application. Isso criaria dependência direta entre contextos, espalharia a localização atual do tipo e aumentaria o retrabalho de uma futura extração para Core.

### Credencial será um agregado separado e individual por User

`CredentialEntity` representará uma credencial local por `userId`, contendo apenas o hash de senha e metadados de persistência. `PasswordValueObject` representará transitoriamente a senha em texto puro e protegerá sua política mínima; `PasswordHashValueObject` representará o valor persistível. Nenhum desses conceitos entrará em `UserEntity`.

A tabela `authentication_credentials` usará `user_id` como chave única e referência para `users.id`, além de `password_hash` e timestamps. A referência terá exclusão em cascata para impedir credenciais órfãs quando a identidade for excluída. Senha em texto puro nunca será persistida, serializada em resposta ou escrita em logs.

A política inicial aceitará senhas entre 8 caracteres e 72 bytes, preservando espaços e caracteres exatamente como informados, sem impor composição arbitrária de maiúsculas, números ou símbolos. A confirmação de senha será uma preocupação do Request de `SignUp`; Application receberá apenas a senha confirmada.

`PasswordHasherPort` separará Application do hasher Laravel. O Adapter usará hash adaptativo configurado pelo framework, verificação segura e `needsRehash`; um `SignIn` bem-sucedido atualizará o hash quando seus parâmetros estiverem defasados.

Alternativa rejeitada: armazenar o e-mail junto à credencial para usar o provider Eloquent padrão. Isso duplicaria o estado de User e exigiria sincronização em toda alteração de e-mail.

### SignUp coordenará User e Credential atomicamente

`SignUpUseCase` validará a senha e produzirá seu hash antes de abrir a transação. Dentro de `AuthenticationWritePort`, ele criará a identidade por `UserIdentityPort` e a credencial por `CredentialRepository`. O Adapter transacional usará a mesma conexão em que User e Authentication persistem hoje.

Falha na criação da credencial reverterá também a identidade. Unicidade de `users.email` e de `authentication_credentials.user_id` permanecerá a barreira final contra concorrência. `SignUp` nunca anexará uma credencial a User preexistente e não iniciará sessão implicitamente.

Alternativa rejeitada: chamar `CreateUserUseCase` e depois persistir a credencial sem transação. Uma falha intermediária produziria identidades incompletas que não poderiam autenticar.

### Uma AuthenticationSession atenderá Bearer e cookie

`AuthenticationSessionEntity` representará uma sessão persistida com identificador não secreto, `userId`, digest do token, data de criação e expiração fixa. Cada `SignIn` bem-sucedido criará uma sessão nova; múltiplas sessões simultâneas por User serão permitidas.

`SessionTokenPort` gerará pelo menos 256 bits de entropia usando um gerador criptograficamente seguro e produzirá uma codificação adequada para header e cookie. Somente um digest SHA-256 do token será persistido, com índice único. SHA-256 é apropriado aqui porque o segredo é aleatório e de alta entropia, diferentemente de senha humana. O token puro existirá apenas no resultado imediato de `SignIn` e no transporte escolhido.

A duração será fixa e configurável, com padrão inicial de 120 minutos. Não haverá renovação deslizante nem refresh token. Sessões expiradas serão recusadas mesmo se o registro ainda existir; um registro expirado encontrado poderá ser removido durante a consulta. `SignOut` revogará imediatamente a sessão atual removendo seu registro.

Alternativa rejeitada: JWT. A aplicação exige revogação imediata e já aceita estado server-side; um token auto-contido adicionaria rotação de chaves, invalidation lists e claims sem benefício atual.

Alternativa rejeitada: mecanismos independentes para web e API. Eles duplicariam persistência, regras de expiração e revogação e poderiam produzir comportamentos de segurança divergentes.

### O transporte será decidido na Presentation

`SignInUseCase` sempre produzirá o mesmo resultado: identificador da sessão, `userId`, token puro e expiração. Ele não conhecerá cookie, header, JSON, redirect ou Request Laravel.

No endpoint JSON:API, `AuthenticationSessionResponse` devolverá o token uma única vez, junto de `token_type: Bearer` e `expires_at`, e adicionará `Cache-Control: no-store` e `Pragma: no-cache`. Requests autenticados seguintes enviarão `Authorization: Bearer <token>`.

No fluxo web, o Controller anexará o token a um cookie Laravel criptografado e assinado, `HttpOnly`, `SameSite=Lax`, limitado ao path `/` e `Secure` em produção. O token não aparecerá no HTML, flash data, URL ou corpo da resposta. Toda operação web mutável, incluindo `SignIn`, `SignUp` e `SignOut`, permanecerá no grupo `web` e exigirá proteção CSRF.

Se uma requisição apresentar simultaneamente Bearer e cookie com valores diferentes, o resolvedor recusará a autenticação com `401`; ele não escolherá silenciosamente um dos segredos. Se ambos transportarem o mesmo valor, a sessão será tratada como uma única credencial.

### O Laravel receberá um principal próprio de Authentication

Authentication Infrastructure registrará um request guard capaz de extrair Bearer ou cookie, aplicar o digest, carregar uma sessão válida e retornar um principal mínimo com `userId` e `sessionId`. Esse principal poderá implementar o contrato Laravel necessário dentro da Infrastructure, mas não será `UserEntity` nem `UserModel`.

Controllers de outros contextos obterão o identificador autenticado na borda e o passarão explicitamente aos seus UseCases quando suas specs de autorização forem implementadas. Entidades e UseCases de negócio não receberão Request, guard, Model ou principal Laravel.

Alternativa rejeitada: fazer `UserModel` estender a classe autenticável do framework. Isso quebraria uma decisão explícita da capability User e tornaria identidade e persistência dependentes do mecanismo de autenticação.

### SignIn evitará enumeração e abuso básico

`SignInUseCase` responderá com `InvalidCredentialsException` para e-mail inválido, User ausente, credencial ausente ou senha incorreta. O detalhe público será idêntico em todos os casos. Quando não houver hash real, o Adapter de hashing verificará a senha contra um hash fictício válido para reduzir diferenças observáveis de tempo.

As rotas de `SignIn` receberão rate limiting de cinco tentativas por minuto por combinação de IP e digest de uma forma normalizada do e-mail usada apenas na chave operacional. O limitador não bloqueará globalmente uma identidade em todos os IPs. Excesso responderá `429` na API e seguirá o tratamento equivalente no fluxo web.

Não haverá eventos próprios de `SignUp`, `SignIn` ou `SignOut` nesta mudança porque não existe consumidor. Eventos Laravel não serão usados como substitutos da regra principal dos UseCases.

### A API seguirá JSON:API e a web seguirá redirects convencionais

As rotas de API serão:

- `POST /api/authentication/sign-up`, nome `authentication.api.sign-up`.
- `POST /api/authentication/sign-in`, nome `authentication.api.sign-in`.
- `DELETE /api/authentication/sign-out`, nome `authentication.api.sign-out`.

`SignUpRequest` exigirá `data.type = sign-ups` e atributos `name`, `email`, `password` e `password_confirmation`. A resposta `201` representará o resultado `sign-ups`, identificará o User criado, oferecerá relacionamento para `users` e enviará `Location` para `/api/users/{id}`, sem expor a credencial.

`SignInRequest` exigirá `data.type = sign-ins` e atributos `email` e `password`. A resposta `200` representará `authentication-sessions`; ela não declara um novo recurso HTTP consultável porque não existe endpoint público para recuperar a sessão ou seu token. `SignOut` responderá `204` sem documento.

As rotas web mutáveis usarão os mesmos termos sob `/authentication/sign-up`, `/authentication/sign-in` e `/authentication/sign-out`, com nomes `authentication.web.sign-up`, `authentication.web.sign-in` e `authentication.web.sign-out`. Controllers web chamarão os mesmos UseCases, transportarão a sessão por cookie e redirecionarão sem retornar JSON:API.

Validation errors da API preservarão `source.pointer`. E-mail já utilizado responderá `409`, entrada inválida `422`, credenciais inválidas ou sessão ausente/inválida `401` e throttling `429`, todos com `application/vnd.api+json`. Nenhuma resposta incluirá password hash ou token digest.

### Authentication e Authorization permanecerão separadas

Esta mudança disponibilizará um guard e middleware capazes de autenticar futuras rotas, mas não aplicará regras genéricas aos endpoints atuais de User e Budget. Cada contexto deverá especificar quais operações um `userId` pode executar e manter invariantes críticas de ownership em Application, usando Policies ou middleware apenas como adaptação HTTP.

Alternativa rejeitada: proteger todos os endpoints apenas com `auth`. Isso impediria acesso anônimo, mas ainda permitiria que qualquer usuário autenticado manipulasse recursos de outros usuários.

## Risks / Trade-offs

- [Uma sessão opaca exige consulta ao banco em toda autenticação] -> Indexar `token_hash`, selecionar somente os campos necessários e medir antes de introduzir cache; revogação imediata é priorizada nesta fase.
- [O mesmo segredo pode ser aceito por cookie e Bearer] -> Manter transportes na Presentation, proteger cookie com CSRF e recusar credenciais conflitantes na mesma requisição.
- [Um token roubado concede acesso até expirar ou ser revogado] -> Usar alta entropia, HTTPS, cookie protegido, resposta `no-store`, expiração fixa curta e persistência somente do digest.
- [Rate limiting por IP e e-mail não impede ataques distribuídos] -> Cobrir abuso básico agora e evoluir observabilidade ou limitação adicional somente com evidência.
- [A transação de SignUp pressupõe User e Authentication no mesmo banco] -> Aceitar essa restrição explícita no monólito atual; eventual separação de persistência exigirá um fluxo assíncrono ou compensatório próprio.
- [Users existentes continuarão sem credenciais] -> Tratar como identidades não autenticáveis e rejeitar `SignUp` com e-mail já ocupado; convite ou credential setup terá spec separada.
- [Exclusão em cascata remove sessões e credenciais sem passar por UseCases de Authentication] -> Aceitar a constraint como garantia de integridade e revogação imediata enquanto não existem efeitos externos ou auditoria obrigatória.
- [Registros expirados podem permanecer sem serem apresentados novamente] -> Remover quando encontrados e adicionar limpeza agendada apenas quando volume ou requisito operacional justificar.
- [A futura criação de Core pode mover EmailValueObject] -> Preservar o `UserIdentityPort` com primitivas e resultados próprios de Authentication para impedir propagação do namespace atual.

## Migration Plan

1. Criar as migrations de credenciais e sessões com constraints, índices e cascata para `users.id`.
2. Implementar Domain e Application de Authentication sem dependências Laravel ou User.
3. Implementar Repositories, Ports, Adapters e o Adapter de integração com os UseCases de User.
4. Registrar bindings, configuração, request guard e allowlist arquitetural no composition root.
5. Expor e testar primeiro os endpoints JSON:API; em seguida conectar o transporte web com cookie, CSRF e redirects aos mesmos UseCases.
6. Adicionar testes de segurança, atomicidade, concorrência relevante, expiração, revogação, transportes, JSON:API e fronteiras.
7. Executar migrations antes dos testes de fluxo, a suíte focada, a suíte arquitetural e Pint.

Em rollback, remover primeiro as rotas e o guard, depois as tabelas de sessões e credenciais. A tabela `users` e seus registros permanecem, pois User não depende de Authentication. Nenhum password hash ou token será migrado para `users`.

## Open Questions

Nenhuma decisão bloqueadora permanece para esta capability. Password reset, verificação de e-mail, criação de credencial para User existente, duração diferenciada por dispositivo e aplicação das regras de autorização serão decididos em mudanças próprias.
