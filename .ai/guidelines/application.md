# Application

- Use UseCases concretos e injeção pelo construtor; não crie interfaces para cada UseCase.
- Em construtores de UseCases, ordene dependências como `Port → UseCase → Repository`. Use `$port`, `$useCase` e `$repository` quando houver uma única dependência do papel; qualifique pelo contexto quando houver mais de uma.
- Use Repository para persistência e consultas de agregados. Use Port para capacidades de Infrastructure, como transações, locks e integrações externas.
- Quando uma operação precisar ser atômica, o UseCase delimita a unidade pelo Port; checagens e escritas relacionadas permanecem na mesma execução.
- Não importe Eloquent, Models, Builders, Controllers, Requests, Responses, facades, HTTP, Infrastructure ou SDKs concretos.
- Não use `app()`, `resolve()` ou Service Locator.
- Contratos de Repository expõem apenas operações necessárias e tipos independentes do ORM.
