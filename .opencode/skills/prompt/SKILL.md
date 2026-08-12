---
name: prompt
description: Use when a user gives a vague or poorly structured Flutter/Dart implementation request that needs to become an executable XML-and-Markdown prompt. Do not use for already structured prompts or general documentation.
---

# Prompt Enhancement

Transform vague or poorly structured requests into structured prompts with XML and Markdown. Tailor the result to this project: Flutter, Dart, Riverpod, Dio, duck_router, equatable, intl, and strict Clean Architecture.

## Procedure

### 1. Analyze the input

1. Read the user's request in full.
2. Identify the main task, explicit and implicit requirements, affected layers, and constraints.
3. Read `references/prompt-schema.md` for required output blocks.
4. Read `examples/before-after-example.md` for the expected transformation style.
5. If the task matches a known pattern, read `examples/few-shot-examples.md`.

### 2. Extract and categorize

Build these blocks:

- `<task>`: one concise line.
- `<goals>`: one sentence describing the primary outcome.
- `<role>`: a senior Flutter engineer using Flutter, Dart, Riverpod, and Clean Architecture, with the feature context.
- `<requirements>` with all three subsections: `Business`, `Technical`, and `UI/UX`.
- `<context-tools>` when project skills or MCPs apply.
- `<workflow>` when steps have dependencies.
- `<output>` when file structure or code format matters.
- `<endpoints>` when an external HTTP API is involved.
- `<tests>` whenever any logic is testable.
- `<critical>` with `Skills obrigatórias` and `Fora do Escopo`.

The `<critical>` block must always say that `/sdd` is mandatory before implementation and must explicitly state what is not in scope.

### 3. Assemble

Read `assets/structured-prompt-template.md` and fill every applicable block. Remove optional empty blocks. Add `---` between blocks longer than five lines. Make vague requirements explicit, including loading, error, empty, success, feedback, and accessibility states when applicable.

### 4. Validate

Read `references/checklist.md` and validate the generated prompt:

```bash
python3 scripts/validate-structure.py < generated-prompt.md
```

Fix every `MISSING` error before delivering. Evaluate warnings and add `<tests>` whenever the task contains testable logic.

### 5. Next step

End the response with:

> **Próximo passo:** cole o prompt acima e execute `/sdd` para criar a spec antes de qualquer implementação.

## Error handling

- If the input already contains XML blocks such as `<task>` or `<requirements>`, say it is already structured and offer refinement instead of rebuilding it.
- If context is insufficient, ask for the feature name, affected layers, and API details when relevant.
- If no specific project skill applies, use `arch-review` as the minimum workflow for cross-layer changes.
