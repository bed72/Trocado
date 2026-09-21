---
name: trocado-batched-delivery
description: Use when planning, applying, reviewing, or approving OpenSpec implementation batches in Trocado. Enforces a maximum of 20 changed files, one independently integrable batch per execution, verification, and an explicit human approval gate before the next batch.
license: MIT
compatibility: Trocado with OpenSpec and git.
metadata:
  project: trocado
  workflow: review-batched-delivery
---

# Trocado Batched Delivery

Deliver a large OpenSpec change as small reviewable batches. This workflow optimizes for human review, not maximum autonomous throughput.

## Batch Contract

Represent every batch in `tasks.md` with this structure:

```markdown
## Lote N: Outcome-oriented name

**Objetivo:** Observable result or coherent prerequisite foundation.
**Dependências:** Earlier approved batches or `nenhuma`.
**Orçamento:** máximo de 20 arquivos únicos.
**Estado do lote:** PENDING
**Escopo previsto:** Concise list of affected areas and expected verification.

- [ ] N.1 Independently verifiable task
- [ ] N.2 Focused verification task
```

Allowed states are exact:

```text
PENDING -> IMPLEMENTING -> AWAITING_REVIEW -> APPROVED
```

- Move `PENDING` to `IMPLEMENTING` only when implementation starts.
- Move `IMPLEMENTING` to `AWAITING_REVIEW` only after the batch quality gate passes.
- Move `AWAITING_REVIEW` to `APPROVED` only after the user explicitly approves that numbered batch.
- Never infer approval from passing checks, silence, `continue`, or a request to proceed.
- Approving a batch ends the current execution. Never start the next batch in the same turn.
- Keep approval out of task checkboxes so OpenSpec progress measures implementation work only.

## Plan Batches

- Order batches by dependency and make each one independently integrable and testable.
- Prefer a vertical behavior slice. A foundation-only batch is acceptable when it is coherent, required by later slices, and leaves the application working.
- Include tests, migrations, configuration, formatting, and operational checks in the batch that needs them.
- Avoid horizontal batches such as all Domain work followed by all HTTP work when neither is independently useful.
- Estimate the concrete file manifest before implementation. Split the batch before editing when the estimate may exceed 20 files.
- Do not duplicate a requirement across batches. State which approved batch supplies a dependency.

## Count The File Budget

Count each unique file changed by the batch once, including:

- Application code and tests.
- Migrations, configuration, routes, providers, and environment examples.
- Dependency manifests and lockfiles.
- Documentation, API collections, generated source, and substantive OpenSpec artifact updates.

Exclude only mechanical task checkbox and `Estado do lote` updates in the active `tasks.md`. Do not exclude generated files merely because a tool created them.

Before editing, snapshot the pre-existing dirty paths. Never modify unrelated existing work. If the batch must touch an already-dirty file and attribution is ambiguous, pause for the user instead of claiming the file budget is reliable.

If the batch reaches 20 files and another file is required, stop. Do not silently exceed the budget, move work into an unrelated file, or weaken tests. Propose a split or request an explicit exception.

## Apply One Batch

1. Resolve the change with `openspec status --change "<change>" --json` and `openspec instructions apply --change "<change>" --json`.
2. Read all returned context files and validate the change strictly before implementation.
3. Select only the earliest batch whose state is not `APPROVED`.
4. Refuse to start it when any dependency batch is not `APPROVED`.
5. If its state is `AWAITING_REVIEW`, report that review is pending and make no implementation edits.
6. Build the predicted file manifest and confirm it fits the budget before changing the state to `IMPLEMENTING`.
7. Implement only that batch. Do not opportunistically complete later tasks.
8. Verify each task before checking it and update its checkbox immediately.
9. Load `trocado-architecture` for application changes and `trocado-quality-gate` for the batch gate.
10. Recount the actual files and move the state to `AWAITING_REVIEW` only when every batch task and required check passes.
11. Stop and present the review report. Do not commit unless the user explicitly requests it.

If implementation reveals a spec or design change, update and strictly validate the artifacts. Count substantive artifact edits in the batch budget.

## Approve One Batch

Approval must identify the change and batch number. Confirm that the batch is `AWAITING_REVIEW`, then change only its state to `APPROVED` and stop. Do not approve a batch with unchecked tasks, failed checks, unresolved blockers, or a file-budget violation.

## Review Report

Report:

1. Batch objective and resulting behavior.
2. Exact changed-file list and total count.
3. Tasks completed and evidence for each.
4. Verification commands and outcomes.
5. Residual risks and explicitly deferred work.
6. The exact statement that the batch is `AWAITING_REVIEW` and the next batch remains blocked.
