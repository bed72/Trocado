# Nomes

- Use sufixos que revelem o papel: `Entity`, `ValueObject`, `UseCase`, `Repository`, `Model`, `Request`, `Controller`, `JsonApiResource`, `ServiceProvider` e `Adapter`.
- Exemplos: `BudgetEntity`, `MoneyValueObject`, `BudgetRepository`, `EloquentBudgetRepository`, `BudgetModel`, `CreateBudgetUseCase`, `BudgetJsonApiResource`.
- Controllers podem ser separados por ação, como `CreateBudgetController`. O `BudgetResponse` existente é uma exceção anterior ao padrão; não copie o nome nem o renomeie em refactors não solicitados.
- Evite nomes genéricos como `Service`, `Manager`, `Handler` ou `Helper` quando o papel for claro.
- Não crie `BaseEntity`, `BaseUseCase`, `BaseRepository`, `BaseController`, `BaseService`, `BaseMapper` ou `BaseFactory` por antecipação.
