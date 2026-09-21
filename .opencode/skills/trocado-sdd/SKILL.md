---
name: trocado-sdd
description: Use for SDD or OpenSpec work in Trocado: exploring a non-trivial change, creating or updating proposal.md, design.md, delta specs, and tasks.md, applying an active change, synchronizing specs, or archiving a completed change. Do not force SDD onto trivial isolated edits unless the user requests it.
license: MIT
compatibility: Requires the OpenSpec CLI and the project-local openspec directory.
metadata:
  project: trocado
  workflow: spec-driven
---

# Trocado SDD

Use OpenSpec as the executable workflow and the project documentation as the quality standard. Do not replace current CLI instructions with memorized templates.

## Sources Of Truth

Read before creating or applying a change:

1. `AGENTS.md`.
2. `ARCHITECTURE.md`.
3. Relevant files in `.ai/guidelines/`.
4. `openspec/config.yaml`.
5. Existing main specs and the closest archived change when they cover the same capability.

For Laravel behavior, consult Laravel Boost/Search Docs before relying on framework APIs. For runtime, database, routes, or schema state, prefer the available MCP tools over assumptions.

## Discover The Workflow

Start with:

```sh
openspec --version
openspec doctor --json
openspec list --json
openspec list --specs --json
```

If the user names an external OpenSpec store, discover it with `openspec store list --json` and preserve `--store <id>` on supported follow-up commands. Otherwise use the nearest project-local `openspec/` root.

Never assume artifact paths. Resolve them from:

```sh
openspec status --change "<change>" --json
openspec instructions <artifact> --change "<change>" --json
```

Treat the returned `context` and `rules` as constraints for the agent, not text to copy into artifacts.

## Choose The Mode

### Explore

Use when requirements, ownership, or trade-offs are unclear.

- Read code, specs, and documentation without implementing application code.
- Identify the owning bounded context, invariants, affected layers, risks, alternatives, and open questions.
- Do not silently create or update artifacts. Offer the appropriate artifact update when a decision is reached.

Route discoveries deliberately:

| Discovery | Artifact |
| --- | --- |
| Motivation or scope changed | `proposal.md` |
| Observable behavior changed | Delta spec |
| Technical decision or trade-off changed | `design.md` |
| New implementation work identified | `tasks.md` |

### Propose Or Update

Create a kebab-case change name and initialize it through the CLI:

```sh
openspec new change "<change>"
```

Build artifacts in dependency order reported by `openspec status`:

```text
proposal -> specs and design -> tasks
```

For every ready artifact:

1. Run `openspec instructions <artifact> --change "<change>" --json`.
2. Read completed dependencies.
3. Follow the returned template and instructions.
4. Write to `resolvedOutputPath`.
5. Re-run status before moving to the next artifact.

Before implementation, validate strictly:

```sh
openspec validate "<change>" --type change --strict --json --no-interactive
```

Material scope expansion requires updating proposal, specs, and design before implementing the expanded scope.

### Apply

Load implementation context dynamically:

```sh
openspec status --change "<change>" --json
openspec instructions apply --change "<change>" --json
```

Read every path in `contextFiles`. Implement one pending task at a time and keep changes focused.

- Follow the `trocado-architecture` skill for application changes.
- When `tasks.md` contains review batches, load and follow the `trocado-batched-delivery` skill. Apply exactly one batch and stop at its human review gate.
- Never start a later batch in the same turn that completes or approves the current batch.
- Verify a task before changing `- [ ]` to `- [x]`.
- Update the checkbox immediately after verification; never bulk-check tasks later.
- If implementation reveals a behavioral or design change, update the artifacts and revalidate before continuing.
- Pause only for a real ambiguity, blocker, failed verification, or user decision.

### Synchronize Or Archive

For an explicit sync without archiving, compare each delta spec with its main spec and preserve unrelated requirements. A `MODIFIED` operation must contain the complete updated requirement, not a partial patch.

Before archiving, use the `trocado-quality-gate` skill. Archive only when required artifacts are complete, tasks reflect verified work, strict validation passes, and blocking questions are resolved.

Use the native CLI so spec updates and validation stay atomic with the archive operation:

```sh
openspec archive "<change>" --yes --json
```

Do not manually move a normal active change into `archive/`. Do not use `--skip-specs` or `--no-validate` unless the user explicitly accepts the consequence.

After archiving:

```sh
openspec validate --all --strict --json --no-interactive
openspec doctor --json
openspec list --json
openspec list --specs --json
```

## Artifact Quality Gates

### Proposal

- Explain why the change is needed now.
- Define scope, non-goals, new capabilities, modified capabilities, and impact.
- Mark breaking changes explicitly.
- Keep implementation details in design unless they are part of the durable contract.

### Delta Specs

- Use normative `MUST` or `MUST NOT` language.
- Give every requirement at least one `#### Scenario` with concrete `WHEN`, `THEN`, and relevant `AND` clauses.
- Cover failure, conflict, and concurrency behavior where relevant.
- Keep permanent capability specs focused on durable behavior, not class names or file paths.
- Include the full requirement in `MODIFIED`; include reason and migration for removals.

### Design

- Align decisions with `ARCHITECTURE.md` and name affected boundaries.
- Record rationale and rejected alternatives.
- Address atomicity, concurrency, security, migration, rollback, and operations when relevant.
- Classify open questions as blocking or non-blocking.

### Tasks

- Use numbered groups and parseable `- [ ]` checkboxes.
- Order tasks by dependency and make each independently verifiable.
- For non-trivial work, organize tasks into dependency-ordered review batches with an objective, expected scope, a maximum budget of 20 unique changed files, and an `Estado do lote` marker.
- Make each batch independently integrable and include its focused verification. Split a batch before implementation when the predicted scope may exceed the budget.
- Keep human approval outside task checkboxes so OpenSpec progress reflects implementation work only.
- Include migrations, documentation, formatting, and operational checks when applicable.
- Trace implementation and verification work back to requirements and scenarios.
- Never mark work complete based only on intent.
