## Context

Expense já registra despesas ligadas a `user_id` e usa exclusão lógica; ainda não há listagem. A consulta deve impedir vazamento entre contas em todas as páginas. Laravel 13 oferece `cursorPaginate`, que exige ordenação única e indexável. O índice atual (`user_id`, `occurred_on`) não explicita o critério de desempate por `id`.

## Goals / Non-Goals

**Goals:** listagem autenticada, limitada ao proprietário, paginada com cursor e apresentada em JSON:API; ordenação determinística e índice compatível.

**Non-Goals:** UUID, listagem administrativa, filtros por período/categoria, total de registros, páginas numeradas, edição ou exclusão de despesas.

## Decisions

1. O endpoint será `GET /api/expenses`, protegido por Sanctum. O UseCase obtém o ID do principal por `Expense\Application\Ports\UserPort`, implementado em Expense Infrastructure sem depender de Identity, e o entrega explicitamente ao Repository; filtros de proprietário e `deleted_at IS NULL` são aplicados na consulta **antes** da paginação. Um cursor não concede acesso por si só. Parâmetros `user_id` informados pelo cliente são rejeitados. Alternativa descartada: buscar despesas globais e filtrar a página em memória, pois isso vaza informação e produz páginas incompletas.
2. O contrato público de paginação usa `page[size]` (padrão `20`, máximo `100`) e `page[cursor]`; os links `next` e `prev` devem conservar o tamanho. A camada Presentation valida entrada, rejeita cursor malformado em vez de deixá-lo virar primeira página e adapta a resposta ao JSON:API. A Application recebe tamanho e cursor explícitos e devolve itens e informações de navegação sem `CursorPaginator`, Model ou facades. O Repository expõe uma operação de consulta por proprietário (por exemplo, `listByUser`), em vez de `all()` global. Alternativa descartada: expor o paginator Laravel através de Application.
3. Ordenar por `occurred_on DESC, id DESC`: data representa a cronologia do gasto; `id` desempata datas iguais de maneira estável. Acrescentar índice (`user_id`, `occurred_on`, `id`) para a consulta e preservar o índice existente conforme a necessidade observada na migration. Alternativa: `id DESC` sozinho, simples e eficiente, mas não ordena por data de ocorrência quando o registro é lançado retroativamente.
4. Usar `cursorPaginate` na Infrastructure, com mapeamento para `ExpenseEntity` e apresentação dos recursos pela `ExpenseResponse` existente. Cursor é posição opaca, não token de acesso nem promessa de snapshot; navegação oferece próximo/anterior sem `total` ou número de páginas. A implementação deve verificar a serialização da coleção paginada pelo recurso JSON:API first-party do Laravel 13, sem depender da forma de `JsonResource` tradicional.

## Risks / Trade-offs

- [Criação ou exclusão entre requisições muda o conjunto percorrido] → Documentar semântica de cursor sem promessa de snapshot; testar estabilidade para dados inalterados.
- [Cursor de outra conta ou adulterado] → Validar sintaxe e aplicar o escopo de `user_id` em toda requisição, inclusive nas páginas seguintes; não usar o cursor como autorização.
- [Índice adicional aumenta custo e espaço de escrita] → Medir a consulta e evitar duplicação de índices se o índice anterior puder ser substituído sem prejudicar outras consultas.

## Migration Plan

Adicionar o índice em migration reversível; disponibilizar a nova rota GET sem modificar os dados existentes. Rollback remove a rota e o índice novo.

## Open Questions

Nenhuma decisão funcional bloqueante para esta proposta.
