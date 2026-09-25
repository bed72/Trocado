## Why

Hoje uma despesa sem categoria recebe sempre `other`, mesmo quando a descrição permite sugerir uma categoria mais útil. A classificação por IA deve melhorar esse padrão sem atrasar a criação nem tornar o provedor externo uma condição para registrar o gasto.

## What Changes

- Quando a categoria for omitida e houver descrição elegível, criar a despesa inicialmente com `other`, responder imediatamente e classificá-la em segundo plano por meio de uma fila.
- Preservar categorias fornecidas pelo cliente; descrições ausentes, vazias, só com espaços ou compostas claramente apenas por payload de injeção mantêm `other` sem consultar a IA.
- Restringir sugestões às dez categorias existentes; falhas, timeouts e respostas inválidas mantêm `other`.
- Evitar que uma classificação atrasada sobrescreva edição do usuário ou classifique uma descrição que já mudou.
- **BREAKING (comportamento eventual):** quando a categoria é omitida e há descrição elegível, a categoria final pode mudar de `other` após o `201` inicial; clientes que assumem `other` como valor definitivo precisarão reler a despesa.

## Capabilities

### New Capabilities

Nenhuma: a classificação integra a capacidade existente de despesas.

### Modified Capabilities

- `expense`: alterar a regra de categoria padrão e a criação JSON:API para permitir classificação assíncrona, com fallback, limites de entrada e proteção contra edições concorrentes.

## Impact

Fluxos de criação e edição, persistência e cache de Expense; Laravel AI SDK como nova dependência, credencial genérica configurável por provider, fila Redis dedicada e worker separado do processamento padrão. A resposta de criação continua `201` com a categoria inicial `other` e o mesmo formato JSON:API. Nenhuma nova categoria ou mudança na autenticação é necessária.
