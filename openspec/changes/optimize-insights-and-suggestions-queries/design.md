## Context

Autorização: “vamos fazer esses ajustes”. Evidências anteriores em `investigate-read-endpoint-performance/design.md`. VPS informada: 2 vCPUs, 8 GB RAM, NVMe 100 GB; ambiente de medição local é diferente e compartilhado. Alterações próprias restritas aos dois Repositories; preservar edições preexistentes.

## Goals / Non-Goals

**Goals:** reduzir CPU/ordenação/temporários por leitura e provar resultados equivalentes com PostgreSQL e massa dedicada.

**Non-Goals:** deploy, tuning da VPS/pool/work_mem, SLA, capacidade sustentada, novo cache/schema/índice ou mudanças Domain/Application/HTTP.

## Decisions

1. **Insights:** pré-agregar fatos por data/categoria antes de expandir para os períodos. Contar datas distintas e somar contagens/somas sobre essa projeção compacta; preservar numeric/string exata. Consultar maior lançamento via LATERAL top-1 por período no mesmo statement/snapshot, com os desempates existentes. Assim descrições não atravessam materialização/ordenação global de dezenas de milhares de linhas. Alternativa rejeitada: aumentar memória ou indexar sem reduzir o trabalho observado.
2. **Sugestões:** materializar descrições normalizadas uma vez, agrupar/rankear todo o histórico e escolher cinco chaves antes de selecionar grafia e agregar valores dessas chaves. Seleção detalhada permanece em SQL num único statement, com ownership antes de normalização, sem query PHP por sugestão. Não limitar lançamentos antes do ranking histórico. Alternativa rejeitada: cortar histórico pela janela financeira ou mudar normalização para um trim não equivalente.
   - Antes de materializar, filtrar substring sobre texto original em caixa uniforme com o termo já sem whitespace externo: uma correspondência de termo assim normalizado não depende do whitespace externo removido da descrição. Prefixo/ranking/grafia continuam calculados sobre descrição normalizada. Isso evita materializar todo o histórico em buscas seletivas/sem matches. A primeira tentativa que materializava todas as descrições teve regressão medida e foi substituída.
3. **Verificação:** executar arquivos existentes dos dois Repositories isoladamente e suítes dos contextos pelo launcher, incluindo cenários de datas, empates, valores grandes e IDs. Comparar original/novo no mesmo banco dedicado, mesma referência, SELECT read-only com timeout 5s e saídas privadas comparadas em memória; registrar mediana/faixa por query sem fabricar percentis de carga. Medir HTTP após aplicar somente os dois arquivos ao clone, identificando essa revisão como base + patch. Não substituir .env/massa/vendor nem executar migrations sem pendências relacionadas.
4. **Instrumentação:** manter estados preexistentes. Comparações instrumentadas são equivalentes quanto ao estado declarado; sem desligar diagnóstico global de outro usuário. Até 30 sondas HTTP autenticadas, timeout 10s/connect 3s, sem bursts/k6 e sem limpar cotas. Encerrar em erro/timeout; `/up` final. Resultados locais não garantem a mesma latência na VPS.

## Risks / Trade-offs

- [Pré-agregação perde máximo/desempate] → máximo selecionado na fonte original com `amount DESC, category ASC, id ASC`.
- [Somar contagens distintas por categoria duplica datas] → COUNT DISTINCT da data na projeção diária de cada período.
- [Top cinco antecipa limite indevido] → ranking usa todos os grupos, frequência/recência históricas; grafia e valores usam todos os lançamentos das chaves escolhidas.
- [CTEs/planos mudam com cardinalidade] → comparar planos e tempos, não assumir melhoria só pela reescrita. Rollback da implementação se piorar.
- [Snapshot/ownership] → uma leitura financeira por Repository e filtros por proprietário antes de agregação.

## Migration Plan

Sem migration. Publicação futura segue deploy existente; rollback pelos dois arquivos. Clone de carga recebe cópia exata apenas desses arquivos após testes, com revisão/patch registrados. VPS não será acessada ou reconfigurada neste escopo.

## Open Questions

Sem bloqueantes para implementar. Capacidade sustentada, tamanho de pool e medições na VPS são posteriores.

## Resultado e rastreabilidade — 2026-10-16

Implementação entregue somente nos dois Repositories. Evidência detalhada de comandos, versões, rodadas intermediárias/final, falha de teste corrigida sem mudar assertions, hashes do clone e limitações em `tasks.md`.

| Requisito/cenário | Evidência | Estado |
| --- | --- | --- |
| EFF-01 períodos/categorias/data/máximo | Repository Insights: 22 testes/368 assertions; suíte Feature Insights 176/1960; comparação completa original/novo com 60 mil despesas | Proven nos cenários executados |
| EFF-01 vazio/valores grandes | Testes existentes de história vazia/futura, somas acima de PHP_INT_MAX, desempates e meses encerrados, sem alterações de esperados | Proven |
| EFF-02 mais de cinco grupos/grafia/valores | Repository sugestões 27/94; suíte Feature Expense final 381/2876, incluindo ranking, ownership, empates, representação e IDs estáveis | Proven |
| EFF-02 antigo/literal | Cenários existentes de histórico antigo, caracteres especiais, whitespace, acentos e valores divergentes; equivalência completa na massa para buscas ampla, seletiva e vazia | Proven |
| EFF-03 comparação | Três repetições intercaladas por query/versão, SELECT read-only/timeout 5s, planos e capturas HTTP finais confirmados | Proven local/instrumentado |

### Ganhos finais observados

- **Insights SQL:** mediana 157,44 → 13,53 ms (~91,4% menos); projeção por período 44.380 → 972 linhas, sem temporários no plano novo. HTTP mediano 237,68 → 83,62 ms (~64,8% menos).
- **Sugestões SQL:** busca ampla 175,72 → 125,75 ms (~28,4% menos); seletiva 60,55 → 31,71 ms (~47,6% menos); vazia 35,79 → 11,66 ms (~67,4% menos). Detalhe dos cinco grupos limitado a 340 linhas na massa ampla, preservando ranking histórico global. Normalização/materialização ampla continua com temporários (603/603 blocos): não é custo constante nem busca indexada.
- **Sugestões HTTP:** mediana 248,64 → 199,00 ms (~20% menos). Não usar o tempo mais favorável dos protótipos como resultado entregue.

A primeira tentativa de sugestões regrediu em buscas vazias; foi corrigida com filtro antes da materialização e revalidada. O pool de cinco workers não foi alterado. Menor custo por request deve reduzir ocupação, mas multiplicador de vazão/usuários e dimensionamento na VPS de 2 vCPUs/8 GB permanecem **Unproven**, pois não houve carga sustentada ou medição nessa máquina. Alguns testes/diagnósticos locais executaram enquanto outros processos da VM estavam ativos; não houve isolamento físico do host. Sem deploy, índices, cache, migração ou promessa de SLA.
