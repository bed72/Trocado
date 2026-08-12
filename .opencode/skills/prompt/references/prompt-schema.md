# Prompt Schema

Structured prompts use XML blocks to organize context.

## Required blocks

| Block | Purpose |
|---|---|
| `<task>` | One-line task description |
| `<goals>` | One-sentence focus |
| `<role>` | Agent role, stack, and task context |
| `<requirements>` | Business, Technical, and UI/UX requirements |
| `<critical>` | Mandatory skills and out-of-scope constraints |

## Optional blocks

Use `<context-tools>` for applicable skills or MCPs, `<workflow>` for dependent steps, `<output>` for expected files, `<endpoints>` for HTTP integrations, and `<tests>` for testable logic.

## Requirements subsections

`<requirements>` must contain `### Business`, `### Technical`, and `### UI/UX`.

`Technical` should mention affected layers, relevant stack, Clean Architecture, and the flow `Notifier → Repository → DataSource → Client (Dio)`.

`UI/UX` should mention loading, error, empty, and success states when applicable, plus visual feedback and accessibility.

## Critical subsections

`<critical>` must contain `### Skills obrigatórias` with `/sdd` as mandatory and `### Fora do Escopo` using `NÃO` or `NUNCA` for explicit constraints.

## Delimiters

Place `---` between blocks longer than five lines.
