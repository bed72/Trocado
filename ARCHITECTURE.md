# Arquitetura da POC Trocado

**Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.** Laravel é uma escolha deliberada nas bordas; Domain e Application não recebem detalhes do framework.

## Bounded contexts e dependências

Cada contexto vive em `app/<Contexto>/` e organiza apenas as camadas necessárias entre `Domain/`, `Application/`, `Infrastructure/` e `Presentation/`. `Identity` e `Expense` são contextos de negócio: a conta pertence a uma pessoa e suas despesas pertencem a essa conta. `Core` abriga somente capacidades transversais usadas pelos contextos, como a coordenação transacional. Crie outros contextos somente quando houver uma feature real. Não distribua features primariamente entre pastas globais `Models`, `Services`, `Repositories` e `Http/Controllers`.

Geradores Artisan são permitidos, mas a localização padrão dos arquivos gerados não define a arquitetura do projeto. Coloque cada classe na camada e no contexto correspondentes; não crie factories, seeders ou testes por hábito.

Dependências de código: `Presentation → Application → Domain` e `Infrastructure → Application/Domain`. Domain não importa nenhuma camada externa. Application conhece Domain, seus próprios contratos e, quando precisa de transação, `Core\Application\Ports\TransactionPort`; não conhece implementações de Infrastructure ou Presentation. O container liga os contratos às implementações nas bordas.

`Identity` é o único owner da identidade local, registro, credencial, autenticação, Personal Access Tokens e encerramento da conta. `UserEntity` carrega `NameValueObject`, que normaliza whitespace externo e repetido, aceita somente letras Unicode separadas por espaços e exige de 2 a 12 letras sem contar espaços; a validação HTTP espelha essa regra. A Entity e os Value Objects permanecem puros em Identity Domain; `UserModel`, hashing, Auth, Eloquent e Sanctum permanecem em Identity Infrastructure. Não existe allowlist cross-context para acessar a tabela `users`.

`UserModel::expenses()` e `ExpenseModel::user()` representam a associação Eloquent pela FK `expenses.user_id`. A exceção cross-context limita-se a esses dois Models de Infrastructure; Domain e Application não importam o outro contexto. O lazy loading é bloqueado fora de produção para revelar N+1, e consultas que precisem das relações devem usar eager loading. Despesas excluídas logicamente não aparecem em `UserModel::expenses()` por padrão; a FK remove todas quando a conta é apagada.

`POST /api/authentication/sign-up` é o único caminho público de criação de conta. `POST /api/users` e a listagem global `GET /api/users` não existem e respondem `404`. `GET`, `PATCH` e `DELETE /api/users/{user}`, os resource types `users`, `sign-ups` e `access-tokens` e os endpoints de Authentication permanecem orientados ao consumidor.

O Sanctum usa o morph type padrão do `UserModel` atual para novos tokens. Como a aplicação ainda está em desenvolvimento e não há tokens legados, não há mapeamento de compatibilidade com namespaces anteriores.

## Responsabilidades

- **Domain:** PHP puro para Entities, Value Objects, Domain Services, exceções e invariantes. Sem Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure ou Presentation. Não decide persistência nem serialização.
- **Application:** UseCases concretos, contratos de Repository/Ports e exceções da aplicação. Depende de Domain. Sem Eloquent Models/Builders, Controllers, Requests, Responses, facades, HTTP, Infrastructure, SDKs concretos, `app()` ou `resolve()`. Injete dependências relevantes pelo construtor; não crie interfaces para UseCases.
- **Infrastructure:** implementa persistência, Ports, integrações e adaptadores de entrada que dependem do framework, como Commands. Use Laravel, Eloquent, Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e Service Providers diretamente quando forem idiomáticos. Registre bindings arquiteturalmente relevantes, como `UserRepository → EloquentUserRepository`; classes concretas resolvidas automaticamente não precisam de registro.
- **Presentation:** lida com HTTP usando Laravel, Controllers, Form Requests, Responses e middleware. Fluxo preferido: `HTTP → Form Request → Controller → UseCase → Response → HTTP`. Controllers são finos: não consultam Models/Eloquent nem contêm regra de negócio ou persistência. Form Request valida o transporte; Domain protege invariantes também para chamadas por CLI, Command ou outros meios.

## Fronteiras e escolhas práticas

Objetos que agrupam dados de contratos da Application ficam em `app/<Contexto>/Application/Data`, pertencem ao bounded context que define o contrato e não são compartilhados globalmente apenas por coincidência estrutural. Use `Input` para uma entrada coesa e `Output` para uma saída estruturada; `Result` não é usado como sufixo de saída da Application. Essas classes são `final readonly`, constructor-only, fortemente tipadas, sem setters, serialização, formatação HTTP, comportamento de domínio ou dependências de framework. Se o tipo passar a proteger invariantes, comparar valores semanticamente ou oferecer operações do conceito, reavalie-o como Value Object de Domain.

Mais de três parâmetros relevantes exigem avaliar a adoção de um `Input`, mas coesão, clareza e evolução conjunta prevalecem sobre a contagem. Contratos públicos da Application com três ou mais valores heterogêneos nomeados usam `Output` em vez de array shape; pares também podem usar `Output` quando os nomes forem essenciais ou os valores evoluírem juntos. Assinaturas pequenas e inequívocas permanecem explícitas. Entities, Value Objects, scalars e coleções homogêneas continuam sendo retornos naturais, e um Repository só usa Data próprio para uma projeção composta legítima, sem reutilizar Output de Use Case por conveniência.

Repositories representam persistência e consultas de agregados da Application; `UserRepository` e `ExpenseRepository` são implementados por Repositories Eloquent em Infrastructure. `UserRepository` cria, consulta, atualiza e exclui identidades; a criação recebe password transitório sensível apenas no SignUp e persiste o hash na Infrastructure. Seus contratos expõem apenas operações necessárias ao contexto e tipos independentes do ORM. Não exponha Model, Builder ou queries Eloquent. A interface torna a dependência explícita; ela não pressupõe trocar Eloquent. Mapping simples pode ficar no Repository. Não crie Mapper, `BaseRepository`, `GenericRepository` ou `CrudRepository` automaticamente.

Ports representam capacidades de Infrastructure que não são persistência ordinária de um agregado, como coordenação transacional, autenticação, locks ou integrações externas. O UseCase decide quando a capacidade faz parte da operação; o Adapter implementa como ela acontece. `Core` oferece `TransactionPort` com `DatabaseTransactionAdapter` para operações de qualquer contexto e `ScopePort` com `ScopeAdapter` para associar um principal à transação PostgreSQL de operações sujeitas a RLS; `SignInPort` e `SignOutPort` em Identity cuidam de emissão e revogação do token atual. A exclusão de conta remove todos os Personal Access Tokens e a identidade na mesma unidade definida pelo UseCase. Callbacks transacionais não devem executar efeitos externos não transacionais, pois podem ser repetidos em caso de retry.

`ExpenseEntity` representa domínio; `ExpenseModel` representa persistência. Avalie o ganho de uma Entity separada em CRUD simples e sinalize o custo antes de acrescentar boilerplate. Crie Value Objects para conceitos reais com invariantes; prefira imutabilidade e não embrulhe toda primitive. Não crie interfaces para Entity ou Value Object.

Facades são proibidas em Domain e Application, permitidas em Infrastructure e Presentation quando idiomáticas. Prefira injeção pelo construtor para dependências relevantes. Não crie wrappers de uma única chamada só para esconder Laravel nas bordas, nem DI externo.

Para JSON:API, consulte primeiro Boost/Search Docs e o código da versão instalada. As classes do projeto ficam em `Presentation/Http/Responses`, usam o sufixo `Response` e, quando aplicável, estendem `Illuminate\Http\Resources\JsonApi\JsonApiResource`, deixando o suporte oficial montar o envelope `data`. Não use `JsonResource` tradicional por hábito. Trate erros no limite HTTP conforme a API oficial.

## Injeção de dependências

Use constructor property promotion e nomeie dependências pelo papel arquitetural quando houver apenas uma: `$useCase`, `$repository` e `$port`. Quando duas dependências tiverem o mesmo papel, qualifique-as pelo contexto, como `$identityRepository` e `$expenseRepository`; não repita o nome completo do tipo sem necessidade.

Em UseCases, mantenha a ordem `Port → UseCase → Repository`. Essa ordem deixa primeiro a fronteira que delimita a operação, depois a colaboração de aplicação e por fim a persistência. Argumentos nomeados tornam os nomes dos parâmetros parte dos chamadores: ao alterar uma assinatura, atualize todos os pontos de construção e seus testes.

## Commands e concorrência

Commands Laravel ficam em `Infrastructure/Console/Commands` e funcionam como adaptadores finos. Eles resolvem preocupações de borda, como configuração, timezone, relógio e saída do terminal, e chamam um UseCase com valores explícitos e independentes do framework. Registre Commands no Service Provider do contexto e declare o agendamento no composition root do Laravel, atualmente `routes/console.php`.

`withoutOverlapping()` evita sobreposição operacional do Scheduler, mas não garante integridade contra execução manual, múltiplos processos ou escritas da API. Regras concorrentes devem ser protegidas no banco por transações, ordem consistente de locks, revalidação do estado dentro da transação e constraints como última barreira. O processamento recorrente é síncrono nesta POC; filas, jobs ou limites de lote só entram quando houver requisito ou medição que justifique a complexidade.

Arquivos globais do Laravel, como `bootstrap/app.php`, `bootstrap/providers.php`, `routes/console.php` e `database/migrations`, são composition roots permitidos. Eles podem conectar um bounded context ao framework, mas não devem receber regra de negócio.

## Nomes e evolução

Use sufixos explícitos: `ExpenseEntity`, `SignInOutput`, `ExpenseRepository`, `TransactionPort`, `DatabaseTransactionAdapter`, `EloquentExpenseRepository`, `ExpenseModel`, `CreateExpenseUseCase`, `CreateExpenseController`, `CreateExpenseRequest`, `ExpenseResponse`, `InvalidExpenseException` e `ExpenseServiceProvider`. Adapters recebem o nome da capacidade implementada; cite a tecnologia quando ela distinguir a implementação. Evite `Service`, `Manager`, `Handler` ou `Helper` sem papel claro. Não use `Result` para saídas da Application nem crie bases genéricas (`BaseEntity`, `BaseUseCase`, `BaseController`, `BaseMapper`, `BaseFactory`) por antecipação.

Controllers podem ser separados por ação, como `CreateExpenseController` e `GetUserController`; o sufixo `Controller` importa mais que unificá-los. Responses JSON:API seguem a mesma linguagem do contexto, como `ExpenseResponse` e `UserResponse`.

Antes de alterar estas regras para concluir uma feature, identifique o conflito, explique o trade-off e proponha a menor mudança. Laravel Boost serve ao desenvolvimento assistido; Laravel AI SDK só entra com uma feature de IA do produto.

Em caso de conflito com sugestões genéricas geradas pelo Boost ou com a estrutura padrão do Laravel, siga as decisões específicas deste documento e das guidelines do projeto. `AGENTS.md` orienta os agentes a consultar essas fontes e o Search Docs.
