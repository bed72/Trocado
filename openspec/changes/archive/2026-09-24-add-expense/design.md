## Context

Identity já é o owner da conta. Expense precisa aceitar gastos da conta autenticada. A exclusão de conta em Identity já é transacional e definitiva.

## Goals / Non-Goals

**Goals:** Criar Expense pertencente à conta autenticada com data, centavos em BRL, descrição opcional e categoria fechada com padrão `other`; manter exclusão de conta consistente.

**Non-Goals:** Criar endpoints de listagem/edição/exclusão individual, adicionar `updated_at` ou criar novas contas.

## Decisions

1. **Contexto separado `Expense`.** Domain valida invariantes sem framework, Application orquestra a criação com um Repository próprio, Infrastructure implementa persistência e Presentation obtém o User autenticado e devolve JSON:API.
2. **Proprietário derivado da autenticação.** `user_id` vem do principal autenticado na Presentation, não do payload. A Application de Expense recebe apenas o identificador; não importa Models, Repositories nem UseCases de Identity. O banco impõe FK para `users` com `ON DELETE CASCADE`, pois a exclusão definitiva do User já ocorre numa transação e deve remover inclusive despesas com `deleted_at`. Infrastructure traduz a violação de FK por conta removida em falha explícita, sem deixar vazar exceção de banco. Alternativa rejeitada: permitir `user_id` arbitrário ou implementar deleção manual cross-context em Identity. A FK também protege concorrência entre criação de despesa e exclusão da conta. A navegação Eloquent entre os dois contextos fica restrita a `UserModel::expenses()` e `ExpenseModel::user()`; não afeta Domain ou Application.
3. **Valores e datas explícitos.** `amount` é inteiro positivo em centavos BRL, `occurred_on` é `DATE`, categoria é enum de string validada no Domain e descrição é nula ou tem até 64 caracteres. A data padrão é calculada na borda usando o fuso da aplicação e entregue explicitamente ao caso de uso; `created_at` guarda o instante da criação, `deleted_at` permite exclusão lógica futura. Não há `updated_at` nesta versão. Alternativa rejeitada: timestamp em `occurred_on` ou dinheiro decimal.
4. **Categoria opcional com padrão `other`.** O cliente pode escolher uma categoria dentre as opções permitidas; a ausência usa `other`, enquanto um valor desconhecido é rejeitado antes da persistência. Alternativa rejeitada: texto livre como categoria.
5. **Criação HTTP mínima.** `POST /api/expenses` aceita somente `amount`, `occurred_on`, `category` e `description`; `user_id` é controlado pelo servidor. Form Request valida transporte, Domain protege invariantes, Controller invoca UseCase e `ExpenseResponse` serializa JSON:API. Alternativa rejeitada: CRUD completo antes de validar o fluxo de lançamento.
6. **Proteção de leitura relacional.** O Eloquent bloqueia lazy loading fora de produção também ao inicializar Expense; as futuras consultas de coleções que precisem do User ou das despesas usam eager loading explícito. Testes de lote verificam número constante de queries e a violação de lazy loading. Não introduzir eager loading global enquanto a criação não lê relações.

## Risks / Trade-offs

- [Categoria escolhida incorretamente não pode ser corrigida nesta versão] → Edição será uma capability posterior, sem impedir o lançamento agora.
- [A nova FK altera a exclusão de conta] → Garantir cascade no banco e verificar rollback com a transação existente.

## Migration Plan

Criar `expenses` com FK e índice composto sem modificar dados atuais. Aplicar a migration antes de habilitar o endpoint. Se precisar reverter, desabilitar o endpoint antes de reverter a migration; a reversão da tabela apaga despesas já criadas e exige backup para preservar dados.
