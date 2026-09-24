# Nomes

- Use sufixos que revelem o papel: `Entity`, `ValueObject`, `Input`, `Output`, `UseCase`, `Repository`, `Port`, `Adapter`, `Model`, `Request`, `Controller`, `Response`, `Command`, `Enum`, `Exception` e `ServiceProvider`.
- Exemplos: `ExpenseEntity`, `CreateExpenseInput`, `SignInOutput`, `ExpenseRepository`, `IdentityWritePort`, `IdentityWriteAdapter`, `EloquentExpenseRepository`, `ExpenseModel`, `CreateExpenseUseCase` e `ExpenseResponse`.
- Reserve `Input` e `Output` para contratos em `Application/Data`; não use `Result` como sufixo de saída da Application nem `Response` fora da Presentation.
- Controllers podem ser separados por ação, como `CreateExpenseController`. Classes de resposta JSON:API ficam em `Presentation/Http/Responses`, usam o sufixo `Response` e podem estender o recurso first-party do Laravel.
- Evite nomes genéricos como `Service`, `Manager`, `Handler` ou `Helper` quando o papel for claro.
- Não crie `BaseEntity`, `BaseUseCase`, `BaseRepository`, `BaseController`, `BaseService`, `BaseMapper` ou `BaseFactory` por antecipação.
