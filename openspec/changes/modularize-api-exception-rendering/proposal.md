## Why

`bootstrap/app.php` concentra mais de 220 linhas de tradução de exceções, montagem repetida de erros JSON:API e políticas de reporte. O acoplamento entre contextos e a duplicação de `EmailAlreadyUsedException`, com dois documentos diferentes, tornam mudanças pequenas difíceis de revisar e arriscam regressões no contrato HTTP.

## What Changes

- Manter os pontos de extensão nativos do Laravel, separando registros específicos de Identity, Expense e Notifications do tratamento transversal de Core.
- Centralizar a construção de documentos de erro JSON:API, sem duplicar envelope, media type e status textual.
- Preservar o comportamento efetivo: status, títulos, detalhes, origens, headers, precedência, política de reporte e escopo API/não API.
- Remover o registro redundante de `EmailAlreadyUsedException`, conservando a primeira resposta efetiva, inclusive `/data/attributes/email`.
- Retirar do bootstrap e do fallback transversal a particularidade de DELETE de registros push, mantendo a resposta uniforme atual.
- Definir caracterização e verificações focadas para uma implementação futura. Esta proposta não implementa nem executa testes da aplicação.

## Capabilities

### New Capabilities

- `api-error-handling`: contrato transversal de tradução de falhas e preservação de erros JSON:API durante a modularização, complementar aos contratos específicos já existentes.

### Modified Capabilities

Nenhuma. Os requisitos públicos de authentication, user, expense, métricas, consultas e push registration permanecem inalterados; esta mudança formaliza garantias compartilhadas sem reescrever essas capacidades.

## Impact

- Implementação futura: `bootstrap/app.php`, Presentation HTTP de Core/Identity/Expense/Notifications e verificações focadas de arquitetura e HTTP.
- Insights e Metrics são consumidores indiretos do fallback: suas respostas próprias, inclusive `source.parameter`, devem permanecer intactas.
- Compatibilidade com a mudança ativa `add-firebase-push-notifications`: preservar apenas a fatia de registro já implementada; não assumir tarefas de envio, FCM, filas ou produtores.
- Sem novos packages, migrations, alterações de dados, rotas, middlewares, autenticação, limites ou integrações. Nenhuma mudança breaking prevista.
- Alterações preexistentes em arquivos do projeto permanecem fora do escopo.
