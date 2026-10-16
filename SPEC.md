# Testes de carga simples com Pest

Change: **`add-endpoint-load-testing`**.

## Decisão atual

O usuário confirmou: **“Só queria teste de carga”**. A versão de 51 tarefas foi substituída por uma entrega pequena usando a API PHP pública do Pest/Stressless. Não há adaptação k6, JS/Node próprio, manifesto/lease de campanha ou massa obrigatória de 200 mil despesas.

Fontes de verdade:

- [Proposta](openspec/changes/add-endpoint-load-testing/proposal.md)
- [Design e limites](openspec/changes/add-endpoint-load-testing/design.md)
- [Requisitos](openspec/changes/add-endpoint-load-testing/specs/endpoint-load-testing/spec.md)
- [Checklist e histórico](openspec/changes/add-endpoint-load-testing/tasks.md)

## Entrega

- Quatro leituras, uma URL e um token por execução.
- Comando `lerd composer test:load -- --scenario=<id>`.
- `--list`/`--list-tests` não enviam HTTP nem preparam recursos.
- JSON privado externo seleciona alvo local dedicado, token, concorrência/duração e p95 máximo opcional.
- Preflight HTTP 200/JSON:API antes da medição.
- Resultado: requests/RPS, fração de falhas, p50/p95; erros HTTP reprovam.
- Limiter de produto preservado; a ferramenta não cria/apaga bancos, dados ou tokens.

## Estado

O Stressless oficial executou uma sonda HTTPS de 1s/1 concorrente no `/up` do alvo dedicado: **14 requests, 100% de sucesso**. A extração inicial exigiu PHP com **512 MiB**. O binário AMD64 selecionado pelo plugin funcionou neste ambiente ARM64; não se alega gerador nativo.

As evidências e pendências da versão anterior permanecem históricas em `tasks.md`. O checklist atual é o do escopo simplificado; não se reutiliza o percentual 6/51 ou as provas do spike retirado como conclusão da nova entrega.

**Entrega simplificada: 5/5 tarefas concluídas.** As quatro leituras autenticadas executaram sondas de 1s/1 concorrente no alvo dedicado, com uma conta sem despesas. Uma sequência atingiu o limiter e reprovou corretamente; sugestões passou depois da renovação da janela. P95 sentinela também reprovou como esperado. Isso comprova execução e assertions, não desempenho com massa representativa. Ver comandos, métricas, limitações e recursos preparados em `tasks.md`.
