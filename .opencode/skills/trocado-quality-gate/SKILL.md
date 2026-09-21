---
name: trocado-quality-gate
description: Use when reviewing, validating, or declaring a Trocado change complete or archive-ready. Maps OpenSpec requirements and scenarios to evidence, checks architecture boundaries and task truthfulness, runs layered verification, and reports unsupported quality claims.
license: MIT
compatibility: Trocado backend with OpenSpec, Laravel Boost, Lerd, Pest, and Pint.
metadata:
  project: trocado
  concern: verification
---

# Trocado Quality Gate

This is an evidence gate, not a summary exercise. Do not mark tasks complete or call a change archive-ready based on code inspection alone when executable verification is available.

## Load The Evidence

Read:

1. `AGENTS.md`, `ARCHITECTURE.md`, and relevant `.ai/guidelines/`.
2. The active change's proposal, design, delta specs, and tasks from `openspec instructions apply`.
3. Affected main specs under `openspec/specs/`.
4. Changed implementation and test files.
5. Relevant database schema, routes, configuration, and runtime state through MCP tools.

For an active change run:

```sh
openspec status --change "<change>" --json
openspec instructions apply --change "<change>" --json
openspec validate "<change>" --type change --strict --json --no-interactive
```

If no change is active, derive the behavioral contract from main specs and the user's requested scope. Do not invent missing requirements.

## Build A Traceability Matrix

Map every normative requirement and scenario to the lowest useful evidence level:

| Behavior | Preferred evidence |
| --- | --- |
| Pure invariant or calculation | Domain unit test |
| UseCase orchestration or failure | Application unit test |
| Mapping, query, constraint, transaction, or lock | Infrastructure feature test |
| Request, response, validation, or error contract | HTTP feature test |
| Provider binding, Command, or schedule registration | Focused feature test |
| Layer or context dependency | Architecture test |

For each scenario classify the evidence as:

- `Proven`: a relevant check passed.
- `Partially proven`: related checks passed but the exact scenario was not exercised.
- `Unproven`: no relevant executable evidence exists.
- `Blocked`: verification could not run; include the exact blocker.

Do not claim concurrency coverage from sequential idempotency tests. Do not claim rollback, uniqueness, locking, or HTTP contract coverage from unit tests that bypass the relevant boundary.

## Review Gates

### Specification

- Proposal scope, design decisions, specs, tasks, and implementation agree.
- Every listed capability has the expected delta spec.
- Every requirement has concrete scenarios.
- `MODIFIED` contains the complete requirement.
- Main spec purpose is meaningful rather than generated `TBD` text.
- Blocking open questions are resolved.

### Architecture

Apply the `trocado-architecture` skill and check:

- Domain purity and Application framework independence.
- No cross-context imports without an explicit decision.
- Repository versus Port responsibilities are correct.
- Controllers stay thin and JSON:API responses follow project conventions.
- Transaction and lock boundaries preserve the documented atomic operation.
- Composition roots contain wiring, not business rules.
- No speculative abstractions or broad unrelated refactors were introduced.

### Task Truthfulness

- Every checked task has corresponding code, documentation, or verification evidence.
- Every completed implementation task is checked immediately after verification.
- Unchecked work remains visible; never hide it to permit archive.
- Unsupported claims such as full coverage or proven races are called out explicitly.

## Verification Ladder

Use the available Lerd and Laravel Boost MCP tools. Discover commands and installed binaries rather than assuming host execution.

Run only checks relevant to the change, from narrow to broad:

1. Domain tests.
2. Application tests.
3. Infrastructure repository, adapter, provider, or command tests.
4. Presentation/API tests.
5. `tests/Unit/Architecture/ContextBoundariesTest.php` when application structure changed.
6. The affected context suite.
7. The full project suite when shared boundaries or archive readiness are involved.

If migrations changed, inspect the schema and apply pending migrations with Lerd before manual HTTP or command verification. Never use `migrate:fresh` without explicit authorization.

After PHP changes, run Laravel Pint with `--dirty --format agent`, then rerun affected tests. Do not add tests unless the user requested them or an approved SDD task explicitly includes them.

When the change affects live request/database behavior, use Lerd diagnostics and logs as appropriate rather than inferring success from tests alone.

## Archive Readiness

A change is ready to archive only when:

- Required artifacts are complete.
- All intended tasks are checked and backed by evidence.
- Strict OpenSpec validation passes.
- The traceability matrix has no unexplained `Unproven` or `Blocked` scenario.
- Relevant tests and architecture checks pass.
- Pint has run after the final PHP edit.
- Migrations and operational checks required by the change succeeded.
- Main specs will have meaningful purpose and durable requirements after archive.

If any item fails, do not archive automatically. Report the smallest concrete work needed to pass.

## Batch Review Gate

When `tasks.md` uses review batches, evaluate only the batch being delivered while preserving change-wide architectural and behavioral consistency.

- Confirm every task in the batch has evidence and later-batch tasks remain untouched.
- Count every unique file changed by the batch, including code, tests, migrations, configuration, dependency manifests, lockfiles, documentation, and API collections.
- Exclude only mechanical checkbox and `Estado do lote` updates in `tasks.md`; substantive OpenSpec artifact changes count.
- Fail the gate above 20 files unless the user explicitly approved an exception before implementation.
- Require focused tests, affected architecture checks, strict OpenSpec validation, and Pint when PHP changed.
- Report the exact changed-file list, commands run, failures, residual risks, and deferred work.
- A passing quality gate moves the batch only to `AWAITING_REVIEW`; it does not constitute human approval.
- Only an explicit approval naming the batch may move it to `APPROVED`, and approval never starts the next batch in the same turn.

## Report Format

Lead with findings, ordered by severity, and include file or artifact references.

1. `Blocker`: behavior is wrong, data integrity is at risk, validation fails, or a required artifact/task is incomplete.
2. `Gap`: a requirement lacks proof, documentation is inconsistent, or an operational check is missing.
3. `Pass`: concise list of checks that completed successfully.
4. `Residual risk`: anything not reproducible or not exercised, especially concurrency and external effects.

If no findings exist, say so explicitly and still state residual testing limitations. Never substitute a broad summary for concrete evidence.
