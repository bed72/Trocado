# JSON:API

- Antes de implementar, consulte Boost/Search Docs e o código Laravel instalado, especialmente em Laravel 13.
- Prefira o suporte first-party `Illuminate\Http\Resources\JsonApi\JsonApiResource` quando aplicável.
- Nomeie as classes do projeto como Responses, por exemplo `ExpenseResponse`; não use `JsonResource` tradicional por hábito.
- Deixe o suporte oficial serializar o envelope `data`; formate erros no limite HTTP segundo a API atual.
