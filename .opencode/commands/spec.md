---
description: Create an OpenSpec proposal for a Trocado change and wait for approval before implementation.
agent: build
---

# Spec

Create a spec for: $ARGUMENTS

## 1. Understand the scope

Read `CLAUDE.md` and the relevant existing code. If the request is unclear, ask:

- Which layer is affected: `domain`, `data`, `infrastructure`, `presentation`, or `main`?
- Is it a new feature, bug fix, or refactor?
- Does it depend on an API endpoint? If so, inspect the available API reference before proposing code.

## 2. Name the change

Derive a concise kebab-case change name from the request, for example `authentication-sign-in` or `expense-remote-datasource`.

## 3. Create the artifacts

Create `openspec/changes/<change-name>/` with:

```
proposal.md
design.md
tasks.md
specs/spec.md
```

Apply these constraints:

- `proposal.md`: state intent, affected layers, motivation, and explicit out-of-scope behavior.
- `design.md`: explain dependency direction (`domain <- data <- infrastructure`), datasource placement, new failures, and API operation mapping when applicable.
- `tasks.md`: order work as domain, infrastructure, data, presentation, main, then tests.
- `specs/spec.md`: use SHALL requirements and Given/When/Then scenarios.

## 4. Approval gate

After generating the artifacts, show the user what the proposal covers and ask whether `proposal.md`, `design.md`, and `tasks.md` are approved. Do not implement until approval.

## 5. Archive

After implementation is complete and verified, archive the change according to the repository's existing OpenSpec workflow. Do not archive an unapproved or partially implemented change.
