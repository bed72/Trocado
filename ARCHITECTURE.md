# Arquitetura da POC Trocado

**Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.** Laravel é uma escolha deliberada nas bordas; Domain e Application não recebem detalhes do framework.

## Bounded contexts e dependências

Cada contexto vive em `app/<Contexto>/` e organiza seus próprios `Domain/`, `Application/`, `Infrastructure/` e `Presentation/`. O contexto existente é `Budget`; crie outros somente quando houver uma feature real. Não distribua features primariamente entre pastas globais `Models`, `Services`, `Repositories` e `Http/Controllers`.

Geradores Artisan são permitidos, mas a localização padrão dos arquivos gerados não define a arquitetura do projeto. Coloque cada classe na camada e no contexto correspondentes; não crie factories, seeders ou testes por hábito.

Dependências de código: `Presentation → Application → Domain` e `Infrastructure → Application/Domain`. Domain não importa nenhuma camada externa. Application conhece Domain e seus próprios contratos, mas não conhece implementações de Infrastructure ou Presentation. O container liga os contratos às implementações nas bordas.

## Responsabilidades

- **Domain:** PHP puro para Entities, Value Objects, Domain Services, exceções e invariantes. Sem Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure ou Presentation. Não decide persistência nem serialização.
- **Application:** UseCases concretos, contratos de Repository/Ports e exceções da aplicação. Depende de Domain. Sem Eloquent Models/Builders, Controllers, Requests, Responses, facades, HTTP, Infrastructure, SDKs concretos, `app()` ou `resolve()`. Injete dependências relevantes pelo construtor; não crie interfaces para UseCases.
- **Infrastructure:** implementa persistência, Ports, integrações e adaptadores de entrada que dependem do framework, como Commands. Use Laravel, Eloquent, Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e Service Providers diretamente quando forem idiomáticos. Registre bindings arquiteturalmente relevantes, como `BudgetRepository → EloquentBudgetRepository` e `BudgetWritePort → BudgetWriteAdapter`; classes concretas resolvidas automaticamente não precisam de registro.
- **Presentation:** lida com HTTP usando Laravel, Controllers, Form Requests, Responses e middleware. Fluxo preferido: `HTTP → Form Request → Controller → UseCase → Response → HTTP`. Controllers são finos: não consultam Models/Eloquent nem contêm regra de negócio ou persistência. Form Request valida o transporte; Domain protege invariantes também para chamadas por CLI, Command ou outros meios.

## Fronteiras e escolhas práticas

Repositories representam persistência e consultas de agregados da Application; `BudgetRepository` e `BudgetRecurrenceRepository` são implementados por Repositories Eloquent em Infrastructure. Seus contratos expõem apenas operações necessárias ao contexto e tipos independentes do ORM. Não exponha Model, Builder ou queries Eloquent. A interface torna a dependência explícita; ela não pressupõe trocar Eloquent. Mapping simples pode ficar no Repository. Não crie Mapper, `BaseRepository`, `GenericRepository` ou `CrudRepository` automaticamente.

Ports representam capacidades de Infrastructure que não são persistência de um agregado, como coordenação transacional, locks ou integrações externas. O UseCase decide quando a capacidade faz parte da operação; o Adapter implementa como ela acontece. No fluxo de escrita de Budget, `BudgetWritePort` delimita a unidade atômica e `BudgetWriteAdapter` aplica transação e lock no banco. Checagens de sobreposição, leituras com `FOR UPDATE`, gravações e avanço de cursor que compõem uma mesma regra devem permanecer dentro dessa unidade. Callbacks transacionais não devem executar efeitos externos não transacionais, pois podem ser repetidos em caso de retry.

`BudgetEntity` representa domínio; `BudgetModel` representa persistência. Avalie o ganho de uma Entity separada em CRUD simples e sinalize o custo antes de acrescentar boilerplate. Crie Value Objects para conceitos reais com invariantes, como `MoneyValueObject`; prefira imutabilidade e não embrulhe toda primitive. Não crie interfaces para Entity ou Value Object.

Facades são proibidas em Domain e Application, permitidas em Infrastructure e Presentation quando idiomáticas. Prefira injeção pelo construtor para dependências relevantes. Não crie wrappers de uma única chamada só para esconder Laravel nas bordas, nem DI externo.

Para JSON:API, consulte primeiro Boost/Search Docs e o código da versão instalada. As classes do projeto ficam em `Presentation/Http/Responses`, usam o sufixo `Response` e, quando aplicável, estendem `Illuminate\Http\Resources\JsonApi\JsonApiResource`, deixando o suporte oficial montar o envelope `data`. Não use `JsonResource` tradicional por hábito. Trate erros no limite HTTP conforme a API oficial.

## Injeção de dependências

Use constructor property promotion e nomeie dependências pelo papel arquitetural quando houver apenas uma: `$useCase`, `$repository` e `$port`. Quando duas dependências tiverem o mesmo papel, qualifique-as pelo contexto, como `$budgetRepository` e `$recurrenceRepository`; não repita o nome completo do tipo sem necessidade.

Em UseCases, mantenha a ordem `Port → UseCase → Repository`. Essa ordem deixa primeiro a fronteira que delimita a operação, depois a colaboração de aplicação e por fim a persistência. Argumentos nomeados tornam os nomes dos parâmetros parte dos chamadores: ao alterar uma assinatura, atualize todos os pontos de construção e seus testes.

## Commands e concorrência

Commands Laravel ficam em `Infrastructure/Console/Commands` e funcionam como adaptadores finos. Eles resolvem preocupações de borda, como configuração, timezone, relógio e saída do terminal, e chamam um UseCase com valores explícitos e independentes do framework. Registre Commands no Service Provider do contexto e declare o agendamento no composition root do Laravel, atualmente `routes/console.php`.

`withoutOverlapping()` evita sobreposição operacional do Scheduler, mas não garante integridade contra execução manual, múltiplos processos ou escritas da API. Regras concorrentes devem ser protegidas no banco por transações, ordem consistente de locks, revalidação do estado dentro da transação e constraints como última barreira. O processamento recorrente é síncrono nesta POC; filas, jobs ou limites de lote só entram quando houver requisito ou medição que justifique a complexidade.

Arquivos globais do Laravel, como `bootstrap/app.php`, `bootstrap/providers.php`, `routes/console.php` e `database/migrations`, são composition roots permitidos. Eles podem conectar um bounded context ao framework, mas não devem receber regra de negócio.

## Nomes e evolução

Use sufixos explícitos: `BudgetEntity`, `MoneyValueObject`, `BudgetRepository`, `BudgetWritePort`, `BudgetWriteAdapter`, `EloquentBudgetRepository`, `BudgetModel`, `CreateBudgetUseCase`, `GetBudgetUseCase`, `CreateBudgetController`, `CreateBudgetRequest`, `BudgetResponse`, `ProcessDueBudgetRecurrencesCommand`, `RecurrenceStatusEnum`, `OverlappingBudgetException` e `BudgetServiceProvider`. Adapters recebem o nome da capacidade implementada; não acrescente a tecnologia ao nome quando ela não distinguir implementações reais. Evite `Service`, `Manager`, `Handler` ou `Helper` sem papel claro. Não crie bases genéricas (`BaseEntity`, `BaseUseCase`, `BaseController`, `BaseMapper`, `BaseFactory`) por antecipação.

Controllers podem ser separados por ação, como os atuais `CreateBudgetController` e `GetBudgetController`; o sufixo `Controller` importa mais que unificá-los. Responses JSON:API seguem a mesma linguagem do contexto, como `BudgetResponse` e `BudgetRecurrenceResponse`.

Antes de alterar estas regras para concluir uma feature, identifique o conflito, explique o trade-off e proponha a menor mudança. Preserve o contexto Budget existente sem refactor amplo. Laravel Boost serve ao desenvolvimento assistido; Laravel AI SDK só entra com uma feature de IA do produto.

Em caso de conflito com sugestões genéricas geradas pelo Boost ou com a estrutura padrão do Laravel, siga as decisões específicas deste documento e das guidelines do projeto. `AGENTS.md` orienta os agentes a consultar essas fontes e o Search Docs.
