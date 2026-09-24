## 1. Contratos e persistência

- [ ] 1.1 Definir em Expense Application a consulta por proprietário e um retorno de página independente de Laravel, com UseCase que recebe ID autenticado, tamanho e cursor.
- [ ] 1.2 Implementar a consulta Eloquent com filtro por `user_id`, exclusão lógica, ordenação `occurred_on DESC, id DESC` e `cursorPaginate`, sem materializar a tabela inteira.
- [ ] 1.3 Criar migration reversível para o índice composto da consulta e verificar seu efeito sem eliminar índices necessários a outros fluxos.

## 2. API JSON:API

- [ ] 2.1 Disponibilizar `GET /api/expenses` com autenticação Sanctum e encaminhar o ID do principal ao UseCase, sem aceitar `user_id` externo.
- [ ] 2.2 Validar `page[size]` e `page[cursor]`, incluindo rejeição explícita de cursor malformado com erro JSON:API `422`.
- [ ] 2.3 Serializar a coleção de `ExpenseEntity` pela resposta JSON:API, preservando `page[size]` e oferecendo links `next`/`prev` sem contagem total.

## 3. Verificação

- [ ] 3.1 Verificar isolamento entre duas contas, exclusão lógica, ordem em datas iguais e navegação nas duas direções com diferentes tamanhos de página.
- [ ] 3.2 Verificar respostas `401`, `422` e `200` com coleção vazia, inclusive cursor de outra conta e ausência de vazamento.
- [ ] 3.3 Aplicar migrations pendentes no ambiente Lerd antes dos fluxos dependentes do índice; conferir rota, limites arquiteturais e executar Pint e verificações adequadas à implementação.
