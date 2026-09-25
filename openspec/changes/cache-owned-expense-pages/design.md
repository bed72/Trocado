## Context

`ListExpensesUseCase` consulta `ExpenseRepository::listByUser` com o proprietário explícito recebido da borda HTTP. A página contém `ExpenseEntity` e os cursores de navegação, e a Presentation monta o documento JSON:API e seus links. Redis já está configurado como serviço local. A listagem paginada está definida na mudança ativa `list-owned-expenses-with-cursor-pagination`; esta proposta se aplica à listagem resultante sem mudar seus contratos.

## Goals / Non-Goals

**Goals:** Redis como padrão para usos atuais e futuros do cache da aplicação; reaproveitamento de páginas de Expense por usuário e parâmetros; invalidação por proprietário após escritas confirmadas, com consistência eventual limitada por TTL.

**Non-Goals:** garantia de snapshot entre páginas, cache HTTP público, fila de invalidação, cache de todas as consultas, implementação de edição/exclusão de Expense ou troca do driver de sessões/filas.

## Decisions

1. **Redis é o store padrão.** Alterar o padrão efetivo do ambiente e o fallback de configuração para `redis`, mantendo `CACHE_STORE=array` e `CACHE_LIMITER_STORE=array` nos testes; o limiter continua com escolha própria. Confirmar que todos os processos apontam para o mesmo Redis e que a extensão/conexão necessária está disponível. Não fazer fallback silencioso para `file`, pois isso eliminaria a invalidação compartilhada. A decisão anterior de não trocar `CACHE_STORE` na mudança de throttle tinha escopo restrito a ela; aqui Redis é escolhido deliberadamente para a aplicação como um todo. Alternativa descartada: store Redis explícito só para Expense, que fragmentaria a convenção futura.
2. **Cache pertence a Expense Infrastructure.** `CachedExpenseRepository` decora `EloquentExpenseRepository` e implementa o mesmo contrato `ExpenseRepository`, mantendo cache e serialização com Laravel fora da Application. A consulta no miss preserva filtro explícito por usuário no repository interno. No hit, a identidade confiável recebida pelo caso de uso determina a chave; cache não concede acesso por cursor ou por chave e a borda HTTP continua autenticando. Alternativas descartadas: facade na Application, invalidar no Controller, cachear JSON:API/links ou criar abstração genérica de cache.
3. **Chaves e conteúdo.** Namespace próprio de Expense e tag de proprietário, com chave que inclua `userId`, `size` e o cursor exato (inclusive ausência dele). Todos os dados da página e seus cursores são armazenados com TTL inicial de **60 segundos**, em representação escalar/array e reconstruídos para o contrato da Application, sem serializar objetos PHP arbitrários; o padrão `serializable_classes=false` do Laravel 13 permanece. O documento JSON:API e URLs são produzidos a cada requisição pela Presentation. A invalidação de uma conta descarrega a tag dela, abrangendo todas as páginas e tamanhos sem limpar o store global nem o rate limiter. Alternativa descartada: `forget` somente da primeira página, que deixa páginas seguintes antigas.
4. **Escrita e consistência.** `CachedExpenseRepository::create` invalida a conta depois de `EloquentExpenseRepository::create` retornar com sucesso. Edição e exclusão individual, quando forem criadas, adotarão a mesma regra para o proprietário afetado. Uma leitura concorrente pode observar dados anteriores por uma janela curta; a invalidação após escrita confirmada e o TTL de 60 segundos delimitam a inconsistência aceita, sem prometer consistência forte ou snapshot de cursores. Outros caminhos de escrita que contornem o repository decorado só convergem pela expiração, a menos que invalidem explicitamente. A exclusão da conta em Identity não ganha dependência cross-context para invalidar Expense: a autenticação deixa de conceder acesso e as entradas expiram.

## Risks / Trade-offs

- [Redis fora do ar afeta qualquer consumidor do cache padrão] → Validar disponibilidade e configuração do serviço antes da ativação; falhar explicitamente em vez de voltar para cache local não compartilhado.
- [Dados de outra conta ou cursor antigo reaproveitados] → Chaves/tag por ID confiável, autenticação obrigatória e filtro explícito por proprietário nas consultas de miss; validar hits, misses e isolamento entre contas.
- [Leitura concorrente e escrita se cruzam] → Aceitar consistência eventual com TTL de 60 segundos e testar invalidação após commit, rollback e expiração; não prometer leitura linearizável.
- [Tag ou versão de chave permanece depois da expiração dos valores] → Verificar comportamento e crescimento de metadados de tags no Redis; revisar estratégia se a quantidade de contas exigir, sem `flush` global.

## Migration Plan

Publicar a configuração Redis e confirmar conexão e prefixo compartilhados antes de habilitar o cache de Expense. Atualizar `.env.example`, fallback em `config/cache.php` e o `CACHE_STORE` do ambiente existente para `redis` (o arquivo local tem precedência); reconstruir config cache se estiver ativo. Entradas em `file` não são migradas e podem expirar; nenhuma migration de banco é necessária. Rollback: desabilitar o cache de páginas, restaurar o store anterior e deixar chaves Redis expirarem, preservando os contratos HTTP.

## Open Questions

Nenhuma bloqueante. TTL inicial de 60 segundos e a métrica de acerto poderão ser revistos com tráfego real.
