# Arquitetura da POC Trocado

**Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.** Laravel é uma escolha deliberada nas bordas; Domain e Application não recebem detalhes do framework.

## Bounded contexts e dependências

Cada contexto vive em `app/<Contexto>/` e organiza apenas as camadas necessárias entre `Domain/`, `Application/`, `Infrastructure/` e `Presentation/`. `Identity` e `Expense` são contextos de negócio: a conta pertence a uma pessoa e suas despesas pertencem a essa conta. `Core` abriga capacidades transversais usadas pelos contextos, como a coordenação transacional, e conceitos puros compartilhados com invariantes equivalentes: centavos, períodos civis e razões exatas. Crie outros contextos somente quando houver uma feature real. Não distribua features primariamente entre pastas globais `Models`, `Services`, `Repositories` e `Http/Controllers`.

Geradores Artisan são permitidos, mas a localização padrão dos arquivos gerados não define a arquitetura do projeto. Coloque cada classe na camada e no contexto correspondentes; não crie factories, seeders ou testes por hábito.

Dependências de código: `Presentation → Application → Domain` e `Infrastructure → Application/Domain`. Domain não importa nenhuma camada externa. Application conhece Domain, seus próprios contratos e as capacidades transversais necessárias de Core, como `TransactionPort`, `ObservabilityPort` e `UserPort`; não conhece implementações de Infrastructure ou Presentation. Os UseCases de Identity, Expense, Insights e Metrics obtêm o ID autenticado por `Core\Application\Ports\UserPort` e o passam explicitamente aos contratos de persistência e leitura, sem importar outro contexto de negócio. Insights e Metrics reutilizam esse contrato e o binding do `CoreServiceProvider`, sem duplicar a capacidade de identidade autenticada. O container liga os contratos às implementações nas bordas.

`Identity` é o único owner da identidade local, registro, credencial, autenticação, Personal Access Tokens e encerramento da conta. `UserEntity` carrega `NameValueObject`, que normaliza whitespace externo e repetido, aceita somente letras Unicode separadas por espaços e exige de 2 a 32 letras sem contar espaços; a validação HTTP espelha essa regra. A Entity e os Value Objects permanecem puros em Identity Domain; `UserModel`, hashing, Eloquent, emissão e revogação de tokens permanecem em Identity Infrastructure. Core apenas lê o identificador do principal pelo guard Sanctum, sem importar Identity ou acessar diretamente a tabela `users`.

`UserModel` não conhece `ExpenseModel`, e `ExpenseModel` não conhece `UserModel`. A associação entre conta e despesa existe no banco por `expenses.user_id` e sua foreign key para `users.id`, com cascade configurado no schema. Expense trabalha com `user_id` explicitamente; uma foreign key entre tabelas não cria relação Eloquent entre bounded contexts.

`POST /api/authentication/sign-up` é o único caminho público de criação de conta. `POST /api/users` e a listagem global `GET /api/users` não existem e respondem `404`. `GET`, `PATCH` e `DELETE /api/users/{user}`, os resource types `users`, `sign-ups` e `access-tokens` e os endpoints de Authentication permanecem orientados ao consumidor.

O Sanctum usa o morph type padrão do `UserModel` atual para novos tokens. Como a aplicação ainda está em desenvolvimento e não há tokens legados, não há mapeamento de compatibilidade com namespaces anteriores.

## Responsabilidades

`Insights` é dono da interpretação analítica das despesas. Sua Infrastructure lê diretamente o schema compartilhado (`expenses.user_id`, `amount` em centavos de BRL, `occurred_on` como data civil e `category`, incluindo `other`), sem importar classes de Expense ou Identity, criar outro Model de despesa ou escrever nessas tabelas. `ExpenseAnalysisPort` fornece essa capacidade à Application, e `ExpenseAnalysisAdapter` entrega projeções próprias por uma única leitura PostgreSQL, com fatos relacionados no mesmo snapshot. A janela financeira cobre o mês corrente até a referência explícita e os dois meses anteriores; existência histórica é consultada separadamente dentro do mesmo statement. Somas monetárias são strings inteiras exatas para preservar valores acima de `PHP_INT_MAX`. Essa integração depende do significado dos campos e deve ser revista quando o schema mudar.

`Core\Domain` fornece `AmountValueObject`, `DatePeriodValueObject` e `RatioValueObject`, com suas exceções de invariantes, para uso explícito pelas camadas dos contextos. Esses tipos não importam contextos consumidores nem carregam regras editoriais, persistência ou relógio. `Brick\Math\BigInteger` e `Brick\Math\RoundingMode`, da biblioteca PHP pura já instalada, são permitidos somente no Domain de Core para aritmética exata. O compartilhamento não libera imports entre contextos de negócio nem dependências de framework no Domain. Nome, e-mail e senha continuam em Identity; candidatos e resumos interpretativos continuam em Insights.

`Core\Domain\Enums\ExpenseCategoryEnum` define o catálogo fechado de identificadores de categoria compartilhado por Expense e Metrics. Expense continua dono do ciclo de vida e da categorização das despesas; Metrics apenas valida os identificadores recebidos na projeção com `tryFrom()`, sem manter uma lista duplicada. Os cases e valores persistidos são preservados. A permissão nas verificações de fronteira é explícita para esse enum, sem liberar outros imports de Domain ou entre contextos de negócio.

`AmountValueObject` preserva centavos inteiros não negativos, soma, diferença absoluta e comparação sem limite de inteiro nativo. `DatePeriodValueObject` valida datas civis canônicas de `0001-01-01` a `9999-12-31`, ordem e limites inclusivos, além de operações de calendário. `RatioValueObject::fromAmounts()` aceita razões não negativas inclusive acima de 100%, necessárias às variações de Insights; `fromShare()` exige parcela menor ou igual ao total para Metrics. O denominador é sempre positivo. Percentuais usam half-up final com precisão explícita: zero casas em Insights e duas em Metrics. Elegibilidade compara razões sem arredondamento. `GenerateInsightCandidatesUseCase` converte projeções da Application em resumos de Domain; candidatos preservam os fatos e períodos de análise, inclusive em onboarding, cuja exposição de período é `null`.

`Metrics` é dono dos fatos quantitativos para totais e distribuição de despesas, independente da interpretação de Insights e sem imports de Expense, Identity ou Insights. Seu Domain define o modo total ou categoria e reutiliza os conceitos puros de Core para período, centavos e participação. O mês inteiro é derivado de uma referência civil explícita; relógio e timezone são resolvidos na borda. `ExpenseMetricsAdapter` lê somente o schema de `expenses`, restringindo proprietário e período inclusivo antes de agregar. O modo simples usa `SUM(amount)`; o agrupado usa `GROUP BY category` e `SUM(SUM(amount)) OVER ()`, em um único statement PostgreSQL e snapshot, sem locks de escrita ou cache. Os agregados numéricos são transportados como texto exato e ordenados pelo valor numérico antes da conversão.

`GetExpenseMetricsUseCase` recebe `GetExpenseMetricsInput` com período efetivo validado e agrupamento, obtém a conta por `UserPort` e chama `ExpenseMetricsPort::summarize()` uma vez por execução, com proprietário, período e modo explícitos. O Port devolve total canônico e totais de categoria tipados, provenientes do mesmo snapshot. A Application valida a representação exata, os identificadores do catálogo integrado, unicidade, valores positivos e reconciliação monetária; inconsistências falham sem fabricar zero ou resultado parcial. Ordena categorias por total exato decrescente e identificador crescente, calcula percentuais independentes com duas casas e produz ID opaco por conta, período e modo. `ExpenseMetricsOutput` conserva o mesmo período e distingue categorias não solicitadas (`null`) de conjunto agrupado vazio (`[]`); a omissão HTTP cabe à futura Response. Não há cache, relógio, configuração ou serialização HTTP na Application.

- **Domain:** PHP puro para Entities, Value Objects, exceções e invariantes. Sem Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure ou Presentation. Não decide persistência nem serialização.
- **Application:** UseCases concretos, contratos de Repository/Ports e exceções da aplicação. Depende de Domain. Sem Eloquent Models/Builders, Controllers, Requests, Responses, facades, HTTP, Infrastructure, SDKs concretos, `app()` ou `resolve()`. Injete dependências relevantes pelo construtor; não crie interfaces para UseCases.
- **Infrastructure:** implementa persistência, Ports, integrações e adaptadores de entrada que dependem do framework, como Commands. Use Laravel, Eloquent, Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e Service Providers diretamente quando forem idiomáticos. Repositories de persistência ficam em `Infrastructure/Repositories/Persistence/`, com seus Models em `Infrastructure/Repositories/Persistence/Models/` (por exemplo, `EloquentUserRepository.php` e `Models/UserModel.php`). Aplique essa organização em Identity, Expense e novos Repositories de persistência; Adapters e Providers continuam em suas pastas próprias. Registre bindings arquiteturalmente relevantes, como `UserRepository → EloquentUserRepository`; classes concretas resolvidas automaticamente não precisam de registro.
- **Presentation:** lida com HTTP usando Laravel, Controllers, Form Requests, Responses e middleware. Fluxo preferido: `HTTP → Form Request → Controller → UseCase → Response → HTTP`. Controllers são finos: não consultam Models/Eloquent nem contêm regra de negócio ou persistência. Form Request valida o transporte; Domain protege invariantes também para chamadas por CLI, Command ou outros meios.

## Fronteiras e escolhas práticas

`GET /api/metrics/expenses` conecta Request, Controller, UseCase e `ExpenseMetricsResponse` singular JSON:API. O Request inspeciona `QUERY_STRING` original com decodificação única, conserva presença e duplicidade e rejeita nomes desconhecidos/estruturas antes da execução. Datas civis são validadas pelos VOs de Core; o Controller resolve uma referência civil no timezone da aplicação e prepara o período efetivo. A Response omite categorias no modo simples e conserva lista vazia no agrupado. `MetricsServiceProvider` liga somente `ExpenseMetricsPort` ao Adapter; a rota herda as mesmas proteções de Insights.

Objetos que agrupam dados de contratos da Application ficam em `app/<Contexto>/Application/Data`, pertencem ao bounded context que define o contrato e não são compartilhados globalmente apenas por coincidência estrutural. Use `Input` para uma entrada coesa e `Output` para uma saída estruturada; `Result` não é usado como sufixo de saída da Application. Essas classes são `final readonly`, constructor-only, fortemente tipadas, sem setters, serialização, formatação HTTP, comportamento de domínio ou dependências de framework. Se o tipo passar a proteger invariantes, comparar valores semanticamente ou oferecer operações do conceito, reavalie-o como Value Object de Domain.

Mais de três parâmetros relevantes exigem avaliar a adoção de um `Input`, mas coesão, clareza e evolução conjunta prevalecem sobre a contagem. Contratos públicos da Application com três ou mais valores heterogêneos nomeados usam `Output` em vez de array shape; pares também podem usar `Output` quando os nomes forem essenciais ou os valores evoluírem juntos. Assinaturas pequenas e inequívocas permanecem explícitas. Entities, Value Objects, scalars e coleções homogêneas continuam sendo retornos naturais, e um Repository só usa Data próprio para uma projeção composta legítima, sem reutilizar Output de Use Case por conveniência.

Repositories representam persistência e consultas de agregados da Application; `UserRepository` e `ExpenseRepository` são implementados por Repositories Eloquent em Infrastructure. `UserRepository` cria, consulta, atualiza e exclui identidades; a criação recebe password transitório sensível apenas no SignUp e persiste o hash na Infrastructure. Seus contratos expõem apenas operações necessárias ao contexto e tipos independentes do ORM. Não exponha Model, Builder ou queries Eloquent. A interface torna a dependência explícita; ela não pressupõe trocar Eloquent. Mapping simples pode ficar no Repository. Não crie Mapper, `BaseRepository`, `GenericRepository` ou `CrudRepository` automaticamente.

Ports representam capacidades de Infrastructure que não são persistência ordinária de um agregado, como coordenação transacional, autenticação, locks ou integrações externas. O UseCase decide quando a capacidade faz parte da operação; o Adapter implementa como ela acontece. `Core` oferece `TransactionPort` com `TransactionAdapter` e `UserPort` com `UserAdapter`; seus bindings pertencem ao `CoreServiceProvider`. Identity, Expense e `AuthenticatedRequestMiddleware` usam o mesmo contrato de identidade autenticada. `UserPort::id()` exige um identificador inteiro e falha como autenticação quando ausente. O middleware registra `user_id` no Context somente nas rotas protegidas, depois de `auth:sanctum`; rotas públicas continuam recebendo os metadados iniciais de rastreamento. O Adapter consulta o guard Sanctum, nunca o Context, sem expor Models ou tipos de Identity. `UserPort::status()` retorna o status do principal como string e falha como autenticação quando ausente; o `EnsureActiveUserMiddleware` de Identity converte esse valor para seu `UserStatusEnum` e aplica a restrição de conta ativa. `SignInPort` e `SignOutPort` em Identity cuidam de emissão e revogação do token atual. A exclusão de conta remove todos os Personal Access Tokens e a identidade na mesma unidade definida pelo UseCase. Callbacks transacionais não devem executar efeitos externos não transacionais, pois podem ser repetidos em caso de retry.

`ExpenseEntity` representa domínio; `ExpenseModel` representa persistência. Avalie o ganho de uma Entity separada em CRUD simples e sinalize o custo antes de acrescentar boilerplate. Crie Value Objects para conceitos reais com invariantes; prefira imutabilidade e não embrulhe toda primitive. Não crie interfaces para Entity ou Value Object.

Facades são proibidas em Domain e Application, permitidas em Infrastructure e Presentation quando idiomáticas. Prefira injeção pelo construtor para dependências relevantes. Não crie wrappers de uma única chamada só para esconder Laravel nas bordas, nem DI externo.

Para JSON:API, consulte primeiro Boost/Search Docs e o código da versão instalada. As classes do projeto ficam em `Presentation/Http/Responses`, usam o sufixo `Response` e, quando aplicável, estendem `Illuminate\Http\Resources\JsonApi\JsonApiResource`, deixando o suporte oficial montar o envelope `data`. Não use `JsonResource` tradicional por hábito. Trate erros no limite HTTP conforme a API oficial.

## Cache e consistência

Para os usos de cache da aplicação, a decisão é adotar Redis como store padrão compartilhado entre processos; o rate limiter conserva sua configuração independente e os testes podem usar um store isolado. Sessões e filas não mudam por causa do store de cache. **Esta é uma decisão de arquitetura para a mudança proposta em [`cache-owned-expense-pages`](openspec/changes/cache-owned-expense-pages/); até sua implementação, a configuração efetiva do ambiente continua prevalecendo.**

Na listagem de Expense, o cache é uma otimização de Infrastructure transparente para os UseCases. `CachedExpenseRepository` decora `EloquentExpenseRepository` e implementa o mesmo contrato `ExpenseRepository`; o container entrega o decorator para a Application. Chaves distinguem proprietário autenticado, tamanho e cursor; o TTL inicial é de 60 segundos. O cache armazena dados da página, não respostas HTTP. Após criação confirmada pelo repository interno, a invalidação abrange todas as páginas da conta; futuros casos de edição e exclusão individual seguem a mesma regra. Leituras concorrentes podem observar dados anteriores até o TTL, sem promessa de snapshot ou consistência imediata. Cache e cursor nunca substituem autenticação, autorização ou filtro explícito por `user_id`.

## Injeção de dependências

Use constructor property promotion e nomeie dependências pelo papel arquitetural quando houver apenas uma: `$useCase`, `$repository` e `$port`. Quando duas dependências tiverem o mesmo papel, qualifique-as pelo contexto, como `$identityRepository` e `$expenseRepository`; não repita o nome completo do tipo sem necessidade.

Em UseCases, mantenha a ordem `Port → UseCase → Repository`. Essa ordem deixa primeiro a fronteira que delimita a operação, depois a colaboração de aplicação e por fim a persistência. Argumentos nomeados tornam os nomes dos parâmetros parte dos chamadores: ao alterar uma assinatura, atualize todos os pontos de construção e seus testes.

## Commands e concorrência

Commands Laravel ficam em `Infrastructure/Console/Commands` e funcionam como adaptadores finos. Eles resolvem preocupações de borda, como configuração, timezone, relógio e saída do terminal, e chamam um UseCase com valores explícitos e independentes do framework. Registre Commands no Service Provider do contexto e declare o agendamento no composition root do Laravel, atualmente `routes/console.php`.

`withoutOverlapping()` evita sobreposição operacional do Scheduler, mas não garante integridade contra execução manual, múltiplos processos ou escritas da API. Regras concorrentes devem ser protegidas no banco por transações, ordem consistente de locks, revalidação do estado dentro da transação e constraints como última barreira. Filas, jobs ou limites de lote só entram quando houver requisito ou medição que justifique a complexidade.

Arquivos globais do Laravel, como `bootstrap/app.php`, `bootstrap/providers.php`, `routes/console.php` e `database/migrations`, são composition roots permitidos. Eles podem conectar um bounded context ao framework, mas não devem receber regra de negócio.

## Arquitetura dos testes

A suíte usa Pest 5 sobre PHPUnit 13 e acompanha os contextos Core, Identity, Expense, Insights e Metrics. Classifique cada teste pela responsabilidade que ele comprova e pelas dependências efetivamente usadas, não apenas pela camada da classe de produção.

```text
tests/
  Pest.php
  TestCase.php
  FeatureTestCase.php
  run.php
  Unit/
    Architecture/
    <Contexto>/<Camada>/<Responsabilidade>/
  Feature/
    <Contexto>/Infrastructure/{Adapters,Providers,Repositories,...}/
    <Contexto>/Presentation/Http/
    <Contexto>/Journeys/
  Support/
    <Contexto>/{Fixtures,Fakes,Stubs,Spies,Helpers,...}/
```

Crie somente pastas necessárias. Unit de Domain/Application executa sem bootstrap Laravel, PostgreSQL ou Redis; um adapter pode ter teste Unit quando suas dependências são explicitamente simuladas e não há bootstrap. Feature inicia a aplicação: mapping, queries, constraints, providers, notifications e workers pertencem a Infrastructure; requests, responses, validação e middleware pertencem a Presentation. `Journeys` identifica integrações deliberadas com objetivo e contexto proprietário explícitos. Cada arquivo tem uma responsabilidade principal e executa individualmente.

### Suporte e preparação explícita

Fixtures, builders e doubles substanciais ou reutilizados ficam em classes tipadas e autoloadáveis por `Tests\`, sob `tests/Support/<Contexto>/`. Capacidades transversais pertencem a Core. Use nomes que expressem o papel, como `IdentityFixture`, `TransactionPortFake`, `UserPortStub` e `ObservabilityPortSpy`. Não crie bases genéricas, catálogos de mocks ou wrappers de uma única chamada.

Mocks de contratos próprios usam PHPUnit; configure expectativas de chamadas, argumentos e falhas no cenário. Use stub quando só precisar fornecer respostas, fake para comportamento simplificado e spy para registrar efeitos. Preserve fakes e assertions nativos de Laravel/AI SDK; Mockery permanece como integração do framework, sem ser o padrão para contratos próprios.

Fixtures de identidade recebem status, verificação e credenciais explicitamente. Preparação direta de persistência não executa cadastro/login HTTP quando esses fluxos não são o alvo. Helpers de jornada executam ações HTTP nomeadas, sem ativação, verificação ou fakes ocultos. Cenários de Bearer, expiração ou revogação usam tokens reais; simulação de autenticação só serve quando esse mecanismo não é o alvo. `tests/Pest.php` concentra associação de TestCases, hooks e configuração geral, sem mutações de negócio ou conexão durante descoberta de Unit.

Builders permitem entradas propositalmente inválidas sem repará-las; datas e fatos relevantes são explícitos, e valores esperados não são calculados pela rotina de produção sob teste. Integração entre contextos no Arrange de Feature permanece restrita aos testes e não amplia as permissões de imports em `app/`.

### Nível de evidência e determinismo

Invariantes são comprovadas em Domain Unit; orquestração e argumentos em Application Unit; persistência, rollback, constraints, locks e callbacks reais em Feature PostgreSQL; contratos de transporte em HTTP Feature. O fake de transação observa escopo, ordem e liberação/descarte de callbacks, mas não prova rollback de banco. Cenários de commit/afterCommit não usam wrapper transacional global que impeça a confirmação. Falhas provocadas verificam a exceção sentinela e a escrita anterior; chamar `handle`/`failed` manualmente não prova consumo pelo worker, e repetição sequencial não prova concorrência.

Controle relógio/timezone e restaure guards, bindings, listeners, fakes, canais e query logs. Assertions editoriais de integração aceitam todas as variantes válidas; testes focados verificam o catálogo com dimensões explícitas, sem depender de sequência PostgreSQL. Observabilidade é verificada por JSON decodificado e campos permitidos/sensíveis, não por busca indiscriminada de números. Consolidações e movimentações preservam mapa de cenário antigo, destino e evidência; contagem de testes não é critério de equivalência.

### Execução segura e isolamento

O entrypoint canônico é `composer test -- <caminho/opções Pest>` (`lerd composer test -- ...` no Lerd), que chama `tests/run.php`. Feature exige manifesto privado, runId e ownership exato de banco; o guard valida configuração e `current_database()` antes de migrations, fixtures, cleanup e remoção. O launcher prepara migrations incrementalmente em bancos exclusivos por execução/processo. Não use SQLite para prova de persistência, liberação por substring `testing`, `migrate:fresh` ou opções de recriação/drop que contornem o preflight. Unit puro e listagem não provisionam banco.

Recursos Redis, filas, logs e arquivos temporários distinguem execução, processo e cenário. Testes comuns usam cache/limiter array; integração Redis é explícita, mail usa transport array e IA usa fake. Workers de teste consomem somente filas exclusivas. Cleanup em finally/teardown atua sobre recursos registrados, sem FLUSHALL/FLUSHDB, e novas tabelas mutáveis devem ser classificadas em `TestDatabaseCleanup`. Preserve migrations e sequências. Provas concorrentes usam conexão nova, barreiras, erros observáveis e timeouts limitados, sem sleeps como evidência de corrida.

Execute primeiro arquivos afetados e suítes focadas; mudanças de suporte compartilhado e fechamento da reorganização exigem gate completo padrão, duas seeds registradas e paralelo nativo com pelo menos dois processos, incluindo Redis, concorrência e duas invocações simultâneas. Registre comandos, resultados, skips e limitações; ausência de pré-requisito e skips/incomplete/risky inesperados não contam como aprovação. A suíte verde não substitui rastreabilidade de cenários. Os comandos e pré-requisitos operacionais ficam no [README](README.md#testes-e-preflight-postgresql).

## Nomes e evolução

Use sufixos explícitos: `ExpenseEntity`, `SignInOutput`, `ExpenseRepository`, `TransactionPort`, `DatabaseTransactionAdapter`, `EloquentExpenseRepository`, `ExpenseModel`, `CreateExpenseUseCase`, `CreateExpenseController`, `CreateExpenseRequest`, `ExpenseResponse`, `InvalidExpenseException` e `ExpenseServiceProvider`. Adapters recebem o nome da capacidade implementada; cite a tecnologia quando ela distinguir a implementação. Não usamos classes `Service` ou Domain Services; a orquestração pertence aos UseCases e as invariantes às Entities e Value Objects. Evite nomes genéricos como `Manager`, `Handler` ou `Helper`. Não use `Result` para saídas da Application nem crie bases genéricas (`BaseEntity`, `BaseUseCase`, `BaseController`, `BaseMapper`, `BaseFactory`) por antecipação.

Controllers podem ser separados por ação, como `CreateExpenseController` e `GetUserController`; o sufixo `Controller` importa mais que unificá-los. Responses JSON:API seguem a mesma linguagem do contexto, como `ExpenseResponse` e `UserResponse`.

Antes de alterar estas regras para concluir uma feature, identifique o conflito, explique o trade-off e proponha a menor mudança. Laravel Boost serve ao desenvolvimento assistido; Laravel AI SDK só entra com uma feature de IA do produto.

Em caso de conflito com sugestões genéricas geradas pelo Boost ou com a estrutura padrão do Laravel, siga as decisões específicas deste documento e das guidelines do projeto. `AGENTS.md` orienta os agentes a consultar essas fontes e o Search Docs.
