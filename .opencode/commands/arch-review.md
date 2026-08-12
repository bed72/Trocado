---
description: Review a Trocado feature for Clean Architecture, SOLID, Riverpod, security, and expressiveness violations.
agent: plan
---

# Arch Review — Clean Architecture & SOLID

Review the feature requested by the user: $ARGUMENTS

## Procedure

1. Read every file in the feature end to end (`screen` -> `notifier` -> `repository` -> `datasource` -> `client`), plus shared files touched by the flow.
2. Check every item in the checklists below.
3. Report only problems. Do not mention what is correct.

## Clean Architecture

### `domain/`

- [ ] `Either` is imported from `domain/either/either.dart`.
- [ ] Domain code has no Flutter, `dart:ui`, or external-package imports.

### `infrastructure/` never knows `domain/`

- [ ] No response has `toModel()` or imports a domain model.
- [ ] No client or datasource imports from `domain/`.

### Datasource interfaces accept domain parameters

- [ ] Interface methods receive primitives (`String`, `int`, etc.), never DTOs such as `XxxRequest`.
- [ ] `XxxRequest` is created inside the concrete datasource implementation.

### `data/` maps through extensions

- [ ] `data/extensions/xxx_response_extension.dart` contains `toModel()`.
- [ ] The repository uses `response.toModel()` instead of constructing the model from response fields directly.
- [ ] The repository uses `failure.toFailure()` from `FailureResponseExtension`.

### Layer boundaries

- [ ] `data/` imports neither `presentation/` nor `main/`.
- [ ] Notifiers import domain interfaces and main providers, not data or infrastructure implementations.
- [ ] Screens do not import `data/` or `infrastructure/`.

### Services only through the notifier

- [ ] Screens do not call `ref.watch`/`ref.read` on service providers (`moneyServiceProvider`, `dateFormatterProvider`, etc.).
- [ ] Notifiers inject services with `ref.watch(...)` in `build()` and expose ready-to-render formatted values in state view-models.
- [ ] Feature-specific presentation data lives in `presentation/ui/<feature>/data/`; shared data lives in `presentation/data/<family>/`.
- [ ] Generic folders such as `helpers/` are not used for presentation data.

### Feature encapsulation

- [ ] No file in `presentation/ui/<A>/` imports UI internals from `presentation/ui/<B>/`.
- [ ] The only exceptions are a location importing another location for navigation composition and a mutation notifier importing another feature's read provider solely for `ref.invalidate(...)` after success.
- [ ] Shared widgets live in `presentation/widgets/<family>/`.
- [ ] Shared presentation data lives in `presentation/data/<family>/`.
- [ ] Screens receive navigation callbacks from their location and do not import locations.

## SOLID and Riverpod

- [ ] Repository has only the data-access responsibility for its entity.
- [ ] Notifiers do not instantiate dependencies; all dependencies come from `ref.watch` in `build()`.
- [ ] Repositories receive datasource interfaces through named constructor parameters.
- [ ] `HttpClient` does not duplicate HTTP execution logic.
- [ ] Notifier dependency fields are `late`, never `late final`.
- [ ] Validators are providers in `main/providers/validators_provider.dart`.

## Security and expressiveness

- [ ] `HttpClient._mapFailure` checks `is Map<String, dynamic>` before reading response data.
- [ ] `hideKeyboard` is called as `hideKeyboard()`, not accessed as a getter.

## Output

Report each violation using this table:

| # | Type | Severity | File | Description |
|---|---|---|---|---|
| 1 | Clean Architecture | High | `infrastructure/...` | A response imports a domain model |

Use **High** for layer violations, **Medium** for DRY/OCP/DIP issues, and **Low** for expressiveness issues.

If there are no violations, report exactly: `Nenhuma violação encontrada.`
