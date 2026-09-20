# Orientações para agentes

- Leia `ARCHITECTURE.md` antes de mudanças estruturais e siga as regras em `.ai/guidelines/`. As decisões específicas do projeto prevalecem sobre sugestões genéricas do Boost.
- Para Laravel e packages Laravel instalados, consulte primeiro Laravel Boost/Search Docs antes de assumir APIs por memória; confira o código instalado quando necessário. Isso vale especialmente para Laravel 13, JSON:API Resources, Eloquent, migrations, validation, DI, Service Providers, Queue, Cache, rate limiting, Boost, AI SDK e Artisan.
- Consulte o MCP disponível para versões, packages, schema, conexões, queries, logs, último erro e documentação antes de inferir o estado da aplicação. Para config, rotas e comandos, use o MCP quando houver ferramenta; caso contrário, consulte Artisan. Se o MCP não estiver acessível, indique a limitação.
- Preserve os bounded contexts em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`. Domain é PHP puro; Application não usa Eloquent, facades, HTTP, Infrastructure ou Service Locator.
- Use os sufixos arquiteturais de `ARCHITECTURE.md`; crie interfaces somente para fronteiras reais, como persistência e integrações externas. Não faça refactors amplos ou crie dependências sem solicitação.
- Se uma mudança conflitar com a arquitetura, explique o trade-off e proponha a menor alteração antes de mudar as regras.
- Execute verificações adequadas e Laravel Pint, quando disponível, antes de concluir. Nesta POC, não adicione usuários, autenticação, Expense, Couple, filas, jobs, IA ou testes sem nova solicitação.
- O ambiente local usa Lerd. Antes de operá-lo, leia [as instruções existentes](.ai/lerd.md).

===

<laravel-boost-guidelines>
=== .ai/application rules ===

# Application

- Use UseCases concretos e injeção pelo construtor; não crie interfaces para cada UseCase.
- Use contratos de Repository ou Ports para fronteiras reais de persistência e integrações externas.
- Não importe Eloquent, Models, Builders, Controllers, Requests, Resources, facades, HTTP, Infrastructure ou SDKs concretos.
- Não use `app()`, `resolve()` ou Service Locator.
- Contratos de Repository expõem apenas operações necessárias e tipos independentes do ORM.

=== .ai/architecture rules ===

# Arquitetura

- Leia `ARCHITECTURE.md` antes de mudanças estruturais.
- Organize features em `app/<Contexto>/{Domain,Application,Infrastructure,Presentation}`; não crie contextos vazios.
- Respeite `Presentation → Application → Domain` e `Infrastructure → Application/Domain`.
- Domain puro, Application explícita, Infrastructure Laravel, Presentation Laravel.
- A convenção do projeto prevalece sobre orientações genéricas do Boost para pastas globais, acesso direto a Eloquent na Presentation e geração automática de factories, seeders ou testes.
- Use geradores Artisan quando úteis, colocando as classes geradas na camada e no contexto corretos.
- Para Laravel e packages Laravel instalados, consulte primeiro Laravel Boost/Search Docs antes de assumir APIs por memória; confira o código instalado quando necessário.
- Se houver conflito com a arquitetura, explique o trade-off e proponha a menor mudança antes de alterar as regras. Evite refactors amplos não solicitados.

=== .ai/domain rules ===

# Domain

- Mantenha Domain em PHP puro: Entities, Value Objects, Domain Services, exceções e invariantes.
- Proíba dependências de Laravel, Illuminate, Eloquent, facades, HTTP, container, banco, migrations, Infrastructure e Presentation.
- Domain não conhece persistência nem serialização. Proteja invariantes também fora do Form Request.
- Crie Value Objects só para conceitos reais; prefira imutabilidade e não crie interfaces para Entities ou Value Objects.

=== .ai/infrastructure rules ===

# Infrastructure

- Use Laravel e Eloquent diretamente quando forem idiomáticos: Query Builder, Cache, Queue, Filesystem, HTTP Client, facades, SDKs e migrations são permitidos.
- Implemente contratos da Application sem expor Model, Builder ou query do ORM neles.
- Registre bindings de fronteira em Service Providers; não registre classes concretas resolvidas automaticamente.
- Deixe mapping simples no Repository; só extraia Mapper com complexidade real. Não crie wrappers de uma única chamada nem DI externo.

=== .ai/json-api rules ===

# JSON:API

- Antes de implementar, consulte Boost/Search Docs e o código Laravel instalado, especialmente em Laravel 13.
- Prefira o suporte first-party `Illuminate\Http\Resources\JsonApi\JsonApiResource` quando aplicável.
- Nomeie Resources como `BudgetJsonApiResource`; não use `JsonResource` tradicional por hábito.
- Deixe o suporte oficial serializar o envelope `data`; formate erros no limite HTTP segundo a API atual.

=== .ai/naming rules ===

# Nomes

- Use sufixos que revelem o papel: `Entity`, `ValueObject`, `UseCase`, `Repository`, `Model`, `Request`, `Controller`, `JsonApiResource`, `ServiceProvider` e `Adapter`.
- Exemplos: `BudgetEntity`, `MoneyValueObject`, `BudgetRepository`, `EloquentBudgetRepository`, `BudgetModel`, `CreateBudgetUseCase`, `BudgetJsonApiResource`.
- Controllers podem ser separados por ação, como `CreateBudgetController`. O `BudgetResponse` existente é uma exceção anterior ao padrão; não copie o nome nem o renomeie em refactors não solicitados.
- Evite nomes genéricos como `Service`, `Manager`, `Handler` ou `Helper` quando o papel for claro.
- Não crie `BaseEntity`, `BaseUseCase`, `BaseRepository`, `BaseController`, `BaseService`, `BaseMapper` ou `BaseFactory` por antecipação.

=== .ai/presentation rules ===

# Presentation

- Use Laravel para Controllers, Form Requests, Resources e middleware.
- Prefira `HTTP → Form Request → Controller → UseCase → JsonApiResource → HTTP`.
- Controllers devem ser finos: sem consultas a Eloquent/Models, persistência ou regra de negócio.
- Form Request valida entrada HTTP; mantenha invariantes no Domain para outros chamadores.
- Facades são permitidas quando idiomáticas; prefira injeção para dependências relevantes.

=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to ensure the best experience when building Laravel applications.

## Foundational Context

This application is a Laravel application running on PHP 8.5. You are an expert with the Laravel ecosystem. Always use the APIs that match the installed major version of each package — do not assume a version.

Before relying on a package's API, confirm its installed version:
- PHP packages: run `composer show --direct` to list direct dependencies with versions, or `composer show <vendor/package>` for a single package.
- JS packages: check `package.json` for the installed versions.

## Conventions

- You must follow all existing code conventions used in this application. When creating or editing a file, check sibling files for the correct structure, approach, and naming.
- Use descriptive names for variables and methods. For example, `isRegisteredForDiscounts`, not `discount()`.
- Check for existing components to reuse before writing a new one.

## Verification Scripts

- Do not create verification scripts or tinker when tests cover that functionality and prove they work. Unit and feature tests are more important.

## Application Structure & Architecture

- Stick to existing directory structure; don't create new base folders without approval.
- Do not change the application's dependencies without approval.

## Frontend Bundling

- If the user doesn't see a frontend change reflected in the UI, it could mean they need to run `npm run build`, `npm run dev`, or `composer run dev`. Ask them.

## Documentation Files

- You must only create documentation files if explicitly requested by the user.

## Replies

- Be concise in your explanations - focus on what's important rather than explaining obvious details.

=== boost rules ===

# Laravel Boost

## Tools

- Laravel Boost is an MCP server with tools designed specifically for this application. Prefer Boost tools over manual alternatives like shell commands or file reads.
- Use `database-query` to run read-only queries against the database instead of writing raw SQL in tinker.
- Use `database-schema` to inspect table structure before writing migrations or models.
- Use `get-absolute-url` to resolve the correct scheme, domain, and port for project URLs. Always use this before sharing a URL with the user.
- Use `browser-logs` to read browser logs, errors, and exceptions. Only recent logs are useful, ignore old entries.

## Searching Documentation (IMPORTANT)

- Use `search-docs` before changes that depend on Laravel ecosystem APIs, behavior, configuration, or version-specific syntax. Skip it for copy-only edits and other changes where package documentation is irrelevant. Reuse sufficient results already in context instead of searching again.
- Pass a `packages` array to scope results when you know which packages are relevant.
- Use multiple broad, topic-based queries: `['rate limiting', 'routing rate limiting', 'routing']`. Expect the most relevant results first.
- Do not add package names to queries because package info is already shared. Use `test resource table`, not `filament 4 test resource table`.

### Search Syntax

1. Use words for auto-stemmed AND logic: `rate limit` matches both "rate" AND "limit".
2. Use `"quoted phrases"` for exact position matching: `"infinite scroll"` requires adjacent words in order.
3. Combine words and phrases for mixed queries: `middleware "rate limit"`.
4. Use multiple queries for OR logic: `queries=["authentication", "middleware"]`.

## Project Rules

- This project contains committed, area-grouped rules in `.ai/rules` when that directory exists (settled decisions, non-obvious traps, standing constraints). Framework and package guidelines that only apply to specific paths (testing, frontend, components) also live there, under `.ai/rules/boost` — this is not just recorded decisions, it is load-bearing guidance you have not seen inline. Before you enter plan mode or create/edit any file, you MUST first: open @.ai/rules/index.md (it maps file globs to rule files), read every rule file whose globs cover the path(s) in scope, and run `grep -rin 'keyword' .ai/rules` to catch what a path match alone misses. Do not write code until you have read and are following every matching rule. If `.ai/rules` does not exist, continue without it.
- Record a rule with `record-rule` only when the user explicitly asks for one. Instructions for the work at hand are not rules, no matter how emphatic: "remove this typo", "use X here" are work to do, not rules to record. Never record a rule on your own initiative, as a byproduct of a change, or to summarize what you just did. When the user does ask, pass a `glob` (e.g. `app/Http/Controllers/**`), a short `title`, and a few-line `note`. Use `record-rule` rather than your native memory or notes tool, because native memory is personal and session-scoped, while only `.ai/rules` is shared with the team and persists in the repo.

## Artisan

- Run Artisan commands directly via the command line (e.g., `php artisan route:list`). Use `php artisan list` to discover available commands and `php artisan [command] --help` to check parameters.
- Inspect routes with `php artisan route:list`. Filter with: `--method=GET`, `--name=users`, `--path=api`, `--except-vendor`, `--only-vendor`.
- Read configuration values using dot notation: `php artisan config:show app.name`, `php artisan config:show database.default`. Or read config files directly from the `config/` directory.

## Tinker

- Execute PHP in app context for debugging and testing code. Do not create models without user approval, prefer tests with factories instead. Prefer existing Artisan commands over custom tinker code.
- Always use single quotes to prevent shell expansion: `php artisan tinker --execute 'Your::code();'`
  - Double quotes for PHP strings inside: `php artisan tinker --execute 'User::where("active", true)->count();'`

=== php rules ===

# PHP

- Always use curly braces for control structures, even for single-line bodies.
- Use PHP 8 constructor property promotion: `public function __construct(public GitHub $github) { }`. Do not leave empty zero-parameter `__construct()` methods unless the constructor is private.
- Use explicit return type declarations and type hints for all method parameters: `function isAccessible(User $user, ?string $path = null): bool`
- Use TitleCase for Enum keys: `FavoritePerson`, `BestLake`, `Monthly`.
- Prefer PHPDoc blocks over inline comments. Only add inline comments for exceptionally complex logic.
- Use array shape type definitions in PHPDoc blocks.

=== deployments rules ===

# Deployment

- Laravel can be deployed using [Laravel Cloud](https://cloud.laravel.com/), which is the fastest way to deploy and scale production Laravel applications.
- Activate the `deploying-to-cloud` skill whenever deploying to Laravel Cloud, configuring Cloud environments or resources, using the Cloud CLI, or troubleshooting Cloud deployments.

=== laravel/core rules ===

# Do Things the Laravel Way

- Use `php artisan make:` commands to create new files (i.e. migrations, controllers, models, etc.). You can list available Artisan commands using `php artisan list` and check their parameters with `php artisan [command] --help`.
- If you're creating a generic PHP class, use `php artisan make:class`.
- Pass `--no-interaction` to all Artisan commands to ensure they work without user input. You should also pass the correct `--options` to ensure correct behavior.

### Model Creation

- When creating new models, create useful factories and seeders for them too. Ask the user if they need any other things, using `php artisan make:model --help` to check the available options.

## APIs & Eloquent Resources

- For APIs, default to using Eloquent API Resources and API versioning unless existing API routes do not, then you should follow existing application convention.

## URL Generation

- When generating links to other pages, prefer named routes and the `route()` function.

## Testing

- When creating models for tests, use the factories for the models. Check if the factory has custom states that can be used before manually setting up the model.
- Faker: Use methods such as `$this->faker->word()` or `fake()->randomDigit()`. Follow existing conventions whether to use `$this->faker` or `fake()`.
- When creating tests, make use of `php artisan make:test [options] {name}` to create a feature test, and pass `--unit` to create a unit test. Most tests should be feature tests.

## Vite Error

- If you receive an "Illuminate\Foundation\ViteException: Unable to locate file in Vite manifest" error, you can run `npm run build` or ask the user to run `npm run dev` or `composer run dev`.

=== pint/core rules ===

# Laravel Pint Code Formatter

- If you have modified any PHP files, you must run `vendor/bin/pint --dirty --format agent` before finalizing changes to ensure your code matches the project's expected style.
- Do not run `vendor/bin/pint --test --format agent`, simply run `vendor/bin/pint --format agent` to fix any formatting issues.

=== phpunit/core rules ===

# PHPUnit

- This project uses PHPUnit. Create tests with `php artisan make:test --phpunit {name}`.
- Do not include the test suite directory in `{name}`. Use `SomeFeatureTest`, not `Feature/SomeFeatureTest`.
- Read the `testing-best-practices` skill for guidance on coverage, naming, structure, dependency isolation, and review.

## Running Tests

- Run the narrowest set of tests that covers the change. Pass a file path or `--filter=testName` to `php artisan test --compact`.
- Rerun a test after each change to it.
- Run `vendor/bin/phpunit` to call the test runner directly. It accepts the same file path and `--filter=testName` arguments.

</laravel-boost-guidelines>
