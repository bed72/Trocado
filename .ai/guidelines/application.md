# Application

- Use UseCases concretos e injeção pelo construtor; não crie interfaces para cada UseCase.
- Em construtores de UseCases, ordene dependências como `Port → UseCase → Repository`. Use `$port`, `$useCase` e `$repository` quando houver uma única dependência do papel; qualifique pelo contexto quando houver mais de uma.
- Use Repository para persistência e consultas de agregados. Use Port para capacidades de Infrastructure, como transações, locks e integrações externas.
- Quando uma operação precisar ser atômica, o UseCase delimita a unidade pelo Port; checagens e escritas relacionadas permanecem na mesma execução.
- Não importe Eloquent, Models, Builders, Controllers, Requests, Responses, facades, HTTP, Infrastructure ou SDKs concretos.
- Não use `app()`, `resolve()` ou Service Locator.
- Contratos de Repository expõem apenas operações necessárias e tipos independentes do ORM.
- Coloque agrupamentos de dados da Application em `app/<Contexto>/Application/Data`, sem compartilhá-los entre contextos apenas por coincidência estrutural.
- Use objetos `final readonly`, constructor-only e sem dependências de framework: `Input` para entradas coesas e `Output` para saídas estruturadas; não use `Result` como sufixo de saída da Application.
- Mais de três parâmetros relevantes exigem avaliar um `Input`, sem esconder dados sem coesão. Três ou mais valores heterogêneos nomeados exigem um `Output`; pares seguem o mesmo critério quando os nomes ou a evolução conjunta forem essenciais.
- Preserve Entities, Value Objects, scalars e coleções homogêneas como retornos naturais. Repositories só usam Data próprio para projeções compostas legítimas e não reutilizam Outputs de Use Case por conveniência.
