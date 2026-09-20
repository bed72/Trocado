# Arquitetura da POC Trocado

**Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.** Laravel é uma escolha deliberada nas bordas; Domain e Application não recebem detalhes do framework.

## Bounded contexts e dependências

Cada contexto vive em `app/<Contexto>/` e organiza seus próprios `Domain/`, `Application/`, `Infrastructure/` e `Presentation/`. O contexto existente é `Budget`; crie outros somente quando houver uma feature real. Não distribua features primariamente entre pastas globais `Models`, `Services`, `Repositories` e `Http/Controllers`.

Geradores Artisan são permitidos, mas a localização padrão dos arquivos gerados não define a arquitetura do projeto. Coloque cada classe na camada e no contexto correspondentes; não crie factories, seeders ou testes por hábito.

Dependências de código: `Presentation → Application → Domain` e `Infrastructure → Application/Domain`. Domain não importa nenhuma camada externa. Application conhece Domain e seus próprios contratos, mas não conhece implementações de Infrastructure ou Presentation. O container liga os contratos às implementações nas bordas.

## Responsabilidades

- **Domain:** PHP puro para Entities, Value Objects, Domain Services, exceções e invariantes. Sem Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure ou Presentation. Não decide persistência nem serialização.
- **Application:** UseCases concretos, contratos de Repository/Ports e exceções da aplicação. Depende de Domain. Sem Eloquent Models/Builders, Controllers, Requests, Resources, facades, HTTP, Infrastructure, SDKs concretos, `app()` ou `resolve()`. Injete dependências relevantes pelo construtor; não crie interfaces para UseCases.
- **Infrastructure:** implementa persistência e integrações. Use Laravel, Eloquent, Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e Service Providers diretamente quando forem idiomáticos. Registre bindings arquiteturalmente relevantes, como `BudgetRepository → EloquentBudgetRepository`; classes concretas resolvidas automaticamente não precisam de registro.
- **Presentation:** lida com HTTP usando Laravel, Controllers, Form Requests, JsonApiResources e middleware. Fluxo preferido: `HTTP → Form Request → Controller → UseCase → JsonApiResource → HTTP`. Controllers são finos: não consultam Models/Eloquent nem contêm regra de negócio ou persistência. Form Request valida o transporte; Domain protege invariantes também para chamadas por CLI, Job ou outros meios.

## Fronteiras e escolhas práticas

`BudgetRepository` representa a fronteira de persistência da Application; `EloquentBudgetRepository` a implementa em Infrastructure. O contrato expõe apenas operações necessárias ao contexto e tipos independentes do ORM. Não exponha Model, Builder ou queries Eloquent. A interface torna a dependência explícita; ela não pressupõe trocar Eloquent. Mapping simples pode ficar no Repository. Não crie Mapper, `BaseRepository`, `GenericRepository` ou `CrudRepository` automaticamente.

`BudgetEntity` representa domínio; `BudgetModel` representa persistência. Avalie o ganho de uma Entity separada em CRUD simples e sinalize o custo antes de acrescentar boilerplate. Crie Value Objects para conceitos reais com invariantes, como `MoneyValueObject`; prefira imutabilidade e não embrulhe toda primitive. Não crie interfaces para Entity ou Value Object.

Facades são proibidas em Domain e Application, permitidas em Infrastructure e Presentation quando idiomáticas. Prefira injeção pelo construtor para dependências relevantes. Não crie wrappers de uma única chamada só para esconder Laravel nas bordas, nem DI externo.

Para JSON:API, consulte primeiro Boost/Search Docs e o código da versão instalada. Quando aplicável, prefira `Illuminate\Http\Resources\JsonApi\JsonApiResource` e deixe o suporte oficial montar o envelope `data`. Não use `JsonResource` tradicional por hábito. Trate erros no limite HTTP conforme a API oficial.

## Nomes e evolução

Use sufixos explícitos: `BudgetEntity`, `MoneyValueObject`, `BudgetRepository`, `EloquentBudgetRepository`, `BudgetModel`, `CreateBudgetUseCase`, `GetBudgetUseCase`, `GetAllBudgetsUseCase`, `UpdateBudgetUseCase`, `DeleteBudgetUseCase`, `BudgetController`, `CreateBudgetRequest`, `BudgetJsonApiResource`, `BudgetServiceProvider`, `ResendEmailAdapter` e `ExpoPushAdapter`. Evite `Service`, `Manager`, `Handler` ou `Helper` sem papel claro. Não crie bases genéricas (`BaseEntity`, `BaseUseCase`, `BaseController`, `BaseMapper`, `BaseFactory`) por antecipação.

Controllers podem ser separados por ação, como os atuais `CreateBudgetController` e `GetBudgetController`; o sufixo `Controller` importa mais que unificá-los. O `BudgetResponse` existente estende o `JsonApiResource` oficial, mas antecede a convenção de nome `BudgetJsonApiResource`: trate-o como exceção preexistente, sem copiá-la nem renomeá-la durante trabalho não relacionado.

Antes de alterar estas regras para concluir uma feature, identifique o conflito, explique o trade-off e proponha a menor mudança. Preserve o contexto Budget existente sem refactor amplo. Laravel Boost serve ao desenvolvimento assistido; Laravel AI SDK só entra com uma feature de IA do produto.

Em caso de conflito com sugestões genéricas geradas pelo Boost ou com a estrutura padrão do Laravel, siga as decisões específicas deste documento e das guidelines do projeto. `AGENTS.md` orienta os agentes a consultar essas fontes e o Search Docs.
