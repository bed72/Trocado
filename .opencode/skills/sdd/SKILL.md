---
name: sdd
description: Use before implementing any non-trivial Trocado change to create and approve a specification before code is written. Trigger on feature requests, bug fixes, refactors, API integrations, or requests to implement code.
---

# Spec-Driven Development

Never implement a non-trivial change before an approved specification exists. Create the spec, show its scope to the user, and wait for approval.

## Workflow

1. Read `CLAUDE.md` and inspect the relevant code.
2. Identify affected layers, required and optional fields, types, nullability, pagination, read-only fields, and API operation identifiers.
3. Create the specification using `/spec` or the repository's OpenSpec convention under `openspec/changes/<change-name>/`.
4. Ask the user to approve `proposal.md`, `design.md`, and `tasks.md`.
5. After approval, implement exactly the approved scope.
6. If another layer or behavior becomes necessary, stop and ask before expanding the scope.
7. Run the relevant tests and archive the OpenSpec change only after implementation is complete and verified.

## Implementation order

1. `domain/`: models, repository interfaces, and failures.
2. `infrastructure/`: requests, responses, datasource interface, and remote datasource.
3. `data/`: response mapping extensions and repositories.
4. `presentation/`: intents, state, notifiers, screens, widgets, and previews.
5. `main/`: Riverpod providers and location wiring.
6. Tests by layer.

## Trocado constraints

- Domain is pure Dart and has no Flutter, `dart:ui`, or external-package imports.
- Responses have `fromJson()` only. Map responses to domain models through extensions in `data/extensions/`.
- Datasource interfaces accept domain primitives; concrete datasources create request DTOs.
- Repositories return `Either<Failure, T>` and do not throw exceptions.
- The only `try-catch` belongs in the HTTP client.
- Code generation is exclusively for `@Riverpod()` providers.
- Follow the current architecture, paths, naming, and test rules in `CLAUDE.md`.
