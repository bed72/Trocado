---
description: Enforce the Trocado Spec-Driven Development workflow before implementation.
agent: build
---

# SDD — Spec-Driven Development

Use this workflow for the requested change: $ARGUMENTS

## Non-negotiable rule

Always create the specification before writing implementation code. Create the spec and stop for user approval. Do not implement without approval.

The sequence is:

1. Understand the requested feature.
2. Create a spec under `specs/` or an OpenSpec change under `openspec/changes/`, following the existing convention.
3. Ask the user to approve the scope.
4. Implement exactly the approved scope.
5. Ask before adding layers or behavior discovered during implementation but not covered by the spec.

## Contract mapping

Before implementation, record required and optional fields, types, nullable values, pagination (`next`/`previous`), read-only fields, and API operation identifiers.

## Implementation order after approval

1. `domain/`: models, repository interfaces, and failures.
2. `infrastructure/`: requests, responses, datasource interface, and remote datasource.
3. `data/`: response mapping extensions and repository implementation.
4. `presentation/`: Intent, State, Notifier, screen, widgets, and previews.
5. `main/`: Riverpod providers and location wiring.
6. Tests by layer.

## Trocado constraints

- Domain is pure Dart and has no Flutter or external-package imports.
- Responses implement `fromJson()` only. Mapping to domain belongs in `data/extensions/`.
- Datasource interfaces accept domain primitives; concrete datasources create request DTOs.
- Repositories return `Either<Failure, T>` and do not throw exceptions.
- The only `try-catch` belongs in the HTTP client.
- Use `@Riverpod()` only for Riverpod providers.
- Use `dart run build_runner build --delete-conflicting-outputs` after provider changes.
- Follow the complete architecture and naming rules in `CLAUDE.md`.
