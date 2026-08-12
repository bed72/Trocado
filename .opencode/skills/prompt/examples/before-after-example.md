# Before and After Example

## Before

```text
Add an expense screen.
```

## After

```xml
<task>Implement the expense creation screen with validation and API integration.</task>

<goals>
    Allow the user to create an expense with clear validation and feedback.
</goals>

<role>
    You are a senior Flutter engineer working on Trocado with Dart, Riverpod, Dio,
    duck_router, and strict Clean Architecture.
</role>

<requirements>
    ### Business
    - The user can enter amount, category, date, and description.
    ### Technical
    - Follow domain -> data -> infrastructure and domain -> presentation.
    - Use Notifier -> Repository -> DataSource -> Client (Dio).
    ### UI/UX
    - Show loading, validation errors, success feedback, and an empty state where applicable.
</requirements>

<critical>
    ### Skills obrigatórias
    - `/sdd` is mandatory before implementation.
    ### Fora do Escopo
    - NÃO change unrelated features.
</critical>
```
