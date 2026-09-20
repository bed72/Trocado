# Application

- Use UseCases concretos e injeção pelo construtor; não crie interfaces para cada UseCase.
- Use contratos de Repository ou Ports para fronteiras reais de persistência e integrações externas.
- Não importe Eloquent, Models, Builders, Controllers, Requests, Resources, facades, HTTP, Infrastructure ou SDKs concretos.
- Não use `app()`, `resolve()` ou Service Locator.
- Contratos de Repository expõem apenas operações necessárias e tipos independentes do ORM.
