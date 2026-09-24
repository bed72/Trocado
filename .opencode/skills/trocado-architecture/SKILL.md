---
name: trocado-architecture
description: Use when implementing or reviewing Trocado PHP/Laravel code, migrations, routes, controllers, use cases, repositories, ports, adapters, or bounded-context changes. Preserves the project's Domain/Application/Infrastructure/Presentation boundaries, naming, dependency injection, atomicity, and local coding style.
license: MIT
compatibility: Trocado backend architecture on Laravel 13 and PHP 8.3 or newer.
metadata:
  project: trocado
  concern: architecture
---

# Trocado Architecture

Use this skill as a decision procedure. `AGENTS.md`, `ARCHITECTURE.md`, and `.ai/guidelines/` remain authoritative.

## Preflight

Before editing:

1. Read `AGENTS.md` and `ARCHITECTURE.md`.
2. Read every relevant file in `.ai/guidelines/`.
3. Check `.ai/rules/index.md` when `.ai/rules/` exists and load all matching rules.
4. Inspect sibling classes and tests in the target context.
5. Read relevant OpenSpec main specs and active change artifacts.
6. Use Laravel Boost/Search Docs for version-sensitive Laravel APIs.
7. Use MCP tools for package versions, schema, routes, configuration, logs, and runtime state.
8. Read `.ai/lerd.md` before operating Lerd.

Do not copy existing drift when it conflicts with the documented target. Do not opportunistically refactor unrelated drift.

## Classify The Change

Identify the owning bounded context and place each responsibility deliberately:

| Concern | Layer |
| --- | --- |
| Invariants, entities, value objects, domain transitions | Domain |
| Orchestration, use cases, repository contracts, capability ports | Application |
| Eloquent, transactions, locks, SDKs, providers, commands | Infrastructure |
| HTTP requests, controllers, responses, middleware, context routes | Presentation |
| Framework wiring only | Global composition root |

Contexts live under `app/<Context>/{Domain,Application,Infrastructure,Presentation}`. Do not create an empty context or layer. Do not import another bounded context unless the architecture explicitly introduces that dependency.

## Enforce Boundaries

### Domain

- Keep it pure PHP: no Laravel, Illuminate, Eloquent, HTTP, container, database, migrations, Infrastructure, or Presentation.
- Protect invariants here even when Form Requests also reject invalid transport input.
- Prefer immutable entities and value objects for real concepts only.
- Keep money as integer cents and calendar dates at Application boundaries as canonical `Y-m-d` strings.

### Application

- Use concrete UseCases with constructor injection; do not create UseCase interfaces.
- Do not import Eloquent, Models, Builders, facades, HTTP, Presentation, Infrastructure, or concrete SDKs.
- Do not call `app()` or `resolve()`.
- Repository contracts persist and query aggregates without exposing ORM types.
- Ports represent real Infrastructure capabilities such as transaction and lock coordination.
- When atomicity matters, the UseCase defines the whole atomic scope and keeps checks, locks, and writes inside it; the Adapter implements the mechanism.

Constructor dependency order in UseCases is `Port -> UseCase -> Repository`. Name a single dependency by role (`$port`, `$useCase`, `$repository`) and qualify it only when there is more than one dependency with the same role.

### Infrastructure

- Use Laravel and Eloquent directly when idiomatic.
- Keep simple model/entity mapping inside the Repository; extract no Mapper without demonstrated complexity.
- Register boundary bindings in the context Service Provider, not concrete autowirable UseCases.
- Put Laravel Commands in `Infrastructure/Console/Commands` and keep them as thin adapters.
- Avoid external non-transactional effects inside retryable transaction callbacks.

### Presentation

Prefer:

```text
Route -> Form Request -> invokable Controller -> UseCase -> Response
```

- Controllers do not query Eloquent or contain business rules.
- Requests validate transport shape; Domain still protects invariants.
- JSON:API responses are `*Response` classes using Laravel's first-party `JsonApiResource` when applicable.
- Preserve strict JSON:API members, string resource IDs, named routes, JSON pointers for validation errors, `201` plus `Location` on creation, and `204` on deletion.
- Translate Domain and Application exceptions at the HTTP boundary.

### Composition Roots

`bootstrap/app.php`, `bootstrap/providers.php`, `routes/console.php`, and `database/migrations/` may connect contexts to Laravel. They must not absorb business rules.

## Naming And Style

- Use role suffixes: `Entity`, `ValueObject`, `UseCase`, `Repository`, `Port`, `Adapter`, `Model`, `Request`, `Controller`, `Response`, `Command`, `Enum`, `Exception`, `ServiceProvider`.
- Avoid speculative `Base*` classes and generic `Service`, `Manager`, `Handler`, or `Helper` names.
- Add `declare(strict_types=1);` to PHP files.
- Use explicit parameter and return types, constructor property promotion, curly braces, and TitleCase enum cases.
- Prefer `final`; use `readonly` when the object is genuinely immutable.
- Use PHPDoc only for information native types cannot express, such as list or array shapes.
- Add comments only for non-obvious decisions.
- Follow the repository's existing Pest style when tests are explicitly in scope.

## Implementation And Verification

Make the smallest vertical change that satisfies the behavior. Introduce an interface only for a real Repository or capability boundary.

When a migration is added or pending, run it in Lerd before exercising schema-dependent flows. Never run `migrate:fresh` without explicit authorization.

When tests are requested or required by an active SDD task, run the narrowest affected test first, then the affected context and architecture checks. After modifying PHP, run Laravel Pint through the available Lerd tooling and rerun affected tests.

Before finishing, confirm:

- Imports respect the layer and context dependency matrix.
- The behavior matches active specs and design.
- Named-argument call sites still match constructor and method parameter names.
- New bindings, routes, error translations, schedules, and migrations are wired only where required.
- No unrelated abstraction, dependency, context, or refactor was introduced.
