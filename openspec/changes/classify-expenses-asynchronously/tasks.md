## 1. Infraestrutura e configuração

- [x] 1.1 Adicionar `laravel/ai` e configurar provider/modelo/timeout e `EXPENSE_CLASSIFICATION_API_KEY` genérica, aplicada ao provider selecionado sem armazenar segredos.
- [x] 1.2 Criar migrations de estado da tentativa e falhas; manter a tabela `jobs` para a conexão de testes `database` (Redis no ambiente operacional) e aplicar migrations pendentes no Lerd sem limpar dados.
- [x] 1.3 Configurar Redis no ambiente e no exemplo; worker padrão exclusivo para `default` e worker dedicado à `expense-classification`, sem execução de IA no HTTP ou driver `sync` no fluxo normal.

## 2. Regras de criação e classificação

- [x] 2.1 Definir em Expense a precedência de categoria explícita e a elegibilidade de descrição (`null`, vazia, whitespace-only, payload isolado), preservando textos legítimos com números e símbolos.
- [x] 2.2 Criar Port e Adapter de despacho após commit, integrar a criação com categoria inicial `other` e fallback no erro de enfileiramento; não enfileirar criação revertida.
- [x] 2.3 Implementar agente do Laravel AI SDK sem memória/ferramentas, com instruções que tratem a descrição como dado e schema limitado aos valores do enum; validar também a resposta no Adapter.
- [x] 2.4 Implementar `ClassifyExpenseQueue` fino em `Infrastructure/Queues/` e UseCase de classificação com timeout/tentativas limitadas e fallback `other` para erro, resposta inválida e falha definitiva.

## 3. Concorrência e cache

- [x] 3.1 Cancelar tentativa pendente quando a categoria (inclusive `other`) ou descrição for editada; atualização condicional atômica deve ignorar despesa alterada, excluída, tentativa repetida ou vencida.
- [x] 3.2 Invalidar páginas cacheadas apenas após classificação persistida para o proprietário correto, sem invalidar outras contas nem fazer chamada externa em transação.

## 4. Verificação

- [x] 4.1 Verificar por cenários de domínio/aplicação e HTTP: `201` imediato com `other`, categoria explícita, entrada elegível/ineligível, `422` existente e nenhuma chamada de IA na requisição.
- [x] 4.2 Verificar com fila de teste/worker e provider falso: processamento após commit, rollback sem trabalho, falhas de despacho/provider, categoria inválida, timeout/tentativas esgotadas, reentrega e concorrência com edição manual.
- [x] 4.3 Verificar invalidação do cache e limites arquiteturais; executar checks relevantes e Pint após a revisão e conferir Redis e ambos os workers efetivos no Lerd.
