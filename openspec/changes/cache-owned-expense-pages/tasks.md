## 1. Configuração compartilhada

- [ ] 1.1 Configurar Redis como store padrão em `config/cache.php` e `.env.example`; conferir o `CACHE_STORE` efetivo do ambiente e a conectividade dos processos, preservando `CACHE_LIMITER_STORE` independente e `CACHE_STORE=array` nos testes.

## 2. Cache de Expense

- [ ] 2.1 Manter `ExpenseRepository` como contrato de CRUD da Application para cache e persistência e `ExpenseCategorizationRepository` para tentativas de classificação, sem dependências Laravel ou acesso à identidade global.
- [ ] 2.2 Implementar em Expense Infrastructure um `CachedExpenseRepository` decorando `EloquentExpenseRepository`, com tag da conta, chave por usuário/tamanho/cursor e TTL de 60 segundos, mantendo os dados armazenados em formato seguro sem serializar objetos PHP arbitrários.
- [ ] 2.3 Integrar a leitura ao binding de `ExpenseRepository`: hit sem consulta ao banco, miss com `ExpenseRepository::listByUser` no repository interno e apresentação JSON:API inalterada.
- [ ] 2.4 Integrar a invalidação após commit das escritas confirmadas nos respectivos decorators de CRUD e categorização; manter a mesma regra para edição e exclusão individual.
- [ ] 2.5 Registrar o binding arquitetural de Expense e confirmar que o cache não cria dependências entre contextos ou muda o driver das sessões/filas.

## 3. Verificação

- [ ] 3.1 Verificar hit/miss, TTL, diferença entre contas, tamanhos e cursores, isolamento por proprietário no miss, links JSON:API e serialização compatível com Laravel 13.
- [ ] 3.2 Verificar invalidação de todas as páginas apenas após criação confirmada, rollback sem invalidação, não invalidação de outra conta e comportamento de leitura concorrente limitado pelo TTL.
- [ ] 3.3 Verificar que processos compartilham o cache Redis em ambiente de integração e que a suíte usa `array`; conferir configuração efetiva, limites arquiteturais e executar Pint e verificações adequadas à implementação.
