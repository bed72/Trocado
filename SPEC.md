# Melhorias de desempenho — execução por partes

Change ativa: **`optimize-insights-and-suggestions-queries`**.

Este arquivo é o roteiro de retomada. O checklist canônico, os requisitos e as evidências ficam nos artefatos OpenSpec; consulte-os antes de executar cada parte.

## Fontes de verdade

- [Proposta e escopo](openspec/changes/optimize-insights-and-suggestions-queries/proposal.md)
- [Design, investigação ampliada e critérios por step](openspec/changes/optimize-insights-and-suggestions-queries/design.md)
- [Requisitos EFF-01–08](openspec/changes/optimize-insights-and-suggestions-queries/specs/read-query-efficiency/spec.md)
- [Checklist e evidências](openspec/changes/optimize-insights-and-suggestions-queries/tasks.md)

## Estado de partida — 2026-10-16

**15/25 tarefas concluídas; 10 tarefas pendentes. STEP 6 implementado e verificado localmente; próxima melhoria de código: STEP 7. STEP 4 adiado/Blocked por indisponibilidade de acesso à instância publicada.** Nenhuma alteração operacional aplicada. Reconfira esse estado pelo OpenSpec ao retomar, pois este resumo não substitui `tasks.md`.

| Step | Parte | Estado |
| --- | --- | --- |
| 1–2 | Otimização inicial de Insights/sugestões e verificação | Concluído |
| 3 | Investigação aprofundada e planejamento das próximas melhorias | Concluído |
| 4 | Referência representativa e runtime efetivo | Iniciado/Blocked — desbloquear acesso e baseline |
| 5 | Busca indexável de sugestões | Concluído — índice dispensado; compactação adaptativa implementada |
| 6 | Sessão e tracking de Identity | Concluído — tracking mantido; renovação com transação/lock condicional |
| 7 | Índices seletivos da listagem | Pendente |
| 8 | Coordenação condicional de cache | Pendente |
| 9 | Aceitação integrada e decisão operacional | Pendente |

As correções já entregues preservaram os resultados e reduziram a mediana SQL de Insights de **157,44 para 13,53 ms** e a busca ampla de sugestões de **175,72 para 125,75 ms** na massa local de 60 mil despesas. Os testes e comparações dessa entrega são evidência histórica; não aprovam antecipadamente os próximos steps.

Na retomada do STEP 5, a ampla recorrente caiu **124,641 → 30,010 ms SQL** e **194,973 → 98,501 ms HTTP**, com resultados/IDs iguais. Índices experimentais foram descartados; a compactação adaptativa não exige extensão/migration. Há overhead de aproximadamente **1–3 ms** em buscas seletivas/ausentes e na alta cardinalidade; não é ganho uniforme nem evidência de capacidade da VPS. Rodadas completas, protótipos rejeitados e verificações estão em `tasks.md`.

No STEP 6, sem possibilidade de renovar, SessionAdapter mantém uma leitura fresca pelo writer e elimina a transação/FOR UPDATE; antes de estender, continua revalidando sob lock. Tracking oficial mantido, inclusive sua contenção no mesmo PAT. Política 30/15/90, rejeições e Notifications preservadas por provas concorrentes. Gate completo padrão e paralelo (dois processos): **2354 testes/41277 assertions**, ambos passaram. Microbenchmark isolado mostrou menos trabalho transacional; as seis sondas FPM não demonstraram ganho HTTP.

## Como executar por partes

1. Executar **somente o step solicitado**, usando as tarefas correspondentes em `tasks.md`. Um pedido de revisar esta spec não inicia implementação.
2. Antes de começar, ler `AGENTS.md`, as skills/regras aplicáveis e os artefatos da change. Reconsultar `openspec instructions apply --change optimize-insights-and-suggestions-queries --json` para o estado atual.
3. Respeitar dependências e decisões do step. Quando faltar acesso, baseline ou decisão técnica necessária, registrar o bloqueio e o menor próximo passo; não substituir o alvo silenciosamente.
4. Implementar a menor alteração aprovada, medir o efeito e executar as verificações adequadas àquela alteração. Marcar tarefas somente depois da evidência correspondente.
5. Atualizar `tasks.md` com comandos, resultados, limitações e decisões; manter tentativas que falharam e tarefas ainda pendentes visíveis. Atualizar este resumo ao concluir uma parte.
6. **Parar ao terminar o step** e entregar o resultado. Não iniciar o seguinte, fazer deploy ou arquivar a change automaticamente.

## STEP 4 — Referência representativa e runtime efetivo

**Tarefas:** 4.1–4.3. **Requisitos:** EFF-03/08.

- Confirmar a instância realmente publicada: revisão/imagem, SAPI/servidor, configuração efetiva, OPcache, caches Laravel, hooks de deploy e recursos compartilhados.
- Distinguir o FPM local do Apache definido no Dockerfile. A VPS informada tem **2 vCPUs/8 GB RAM**, mas sua SAPI/configuração efetiva ainda não foi inspecionada.
- Estabelecer uma referência production-like coordenada, com revisão/massa e instrumentação declaradas. Medir CPU, memória real por processo, conexões e serviços concorrentes.
- Propor a menor configuração justificada. A tarefa 4.3 só aplica mudanças operacionais após aprovação desse escopo, com smoke checks e rollback.

**Saída esperada:** inventário, baseline e proposta operacional rastreáveis, ou bloqueios explícitos. Não calcular workers dividindo RAM por `memory_limit`, transportar os cinco workers locais para a VPS ou presumir migração para FPM.

## STEP 5 — Busca indexável de sugestões

**Tarefas:** 5.1–5.3. **Requisitos:** EFF-02–04.

- Comparar estratégias de predicado/expressão/coluna em banco isolado, com termos amplos, seletivos, curtos, especiais e sem resultados.
- Verificar equivalência completa de chaves, ranking, grafia, valores e IDs. Um índice de trigramas não acelera automaticamente o `strpos()` atual.
- Escolher a estratégia pelo ganho líquido, incluindo escrita/tamanho do índice. Decidir extensão/DDL e migration incremental/rollback antes de aplicar; aceitar não criar índice quando não compensar.

**Saída esperada:** estratégia medida e implementada quando aprovada, ou dispensa justificada. Não mudar busca literal, acentos, histórico, comprimento mínimo ou janela monetária para obter ganho.

## STEP 6 — Sessão e tracking de Identity

**Tarefas:** 6.1–6.3. **Requisitos:** EFF-03/05.

- Decidir a política de `last_used_at` após inventariar seus consumidores; separar tracking de autenticação e renovação.
- Reduzir trabalho de renovação somente com algoritmo que trate estado Eloquent antigo e revalide persistência atomicamente antes de estender.
- Provar extensão, encurtamento, expiração e revogação concorrentes com PostgreSQL e processos sincronizados; comparar mesmo PAT e sessões distintas sem confundir limiter por conta com contenção.

**Saída esperada:** redução comprovada de trabalho/espera, preservando validade de 30 dias, janela inclusiva de 15, teto de 90 e rejeições sem renovação. Não remover locks ou desabilitar tracking apenas porque existem no caminho.

## STEP 7 — Índices seletivos da listagem

**Tarefas:** 7.1–7.3. **Requisitos:** EFF-03/06.

- Priorizar sorts pela frequência real e medir primeira página, avanço, retorno, página profunda e cache miss/hit.
- Avaliar índices mínimos para valor/descrição, com direções, UUID DESC, expressão nullable e collation ICU corretos.
- Decidir/aplicar somente DDL justificado e verificar plano, cursor v2, Unicode, empates, ownership, escrita e rollback.

**Saída esperada:** benefício medido nas consultas prioritárias, sem regressão do default, que já é eficiente. Não criar todas as permutações nem remover índices por aparência de redundância.

## STEP 8 — Coordenação de cache somente se compensar

**Tarefas:** 8.1–8.2. **Requisito:** EFF-07.

- Primeiro reproduzir misses simultâneos e corrida com invalidação em fixtures/keys Redis exclusivas. Comparar recomputação duplicada com overhead de coordenação.
- Se houver benefício, implementar coordenação por página, double-check e espera/validade limitadas, mantendo hits livres e isolamento de owner/critérios/cursor.
- Preservar TTL de 60s, invalidação após commit e limite de staleness; provar também rollback, classificação, falhas e expiração de lock.

**Saída esperada:** coordenação comprovadamente útil ou decisão documentada de dispensá-la. O cache atual já apresentou hits de aproximadamente 0,5 ms; lock em todo miss não é uma solução presumida.

## STEP 9 — Aceitação integrada e decisão operacional

**Tarefas:** 9.1–9.2. **Requisitos:** EFF-01–08.

- Verificar os steps efetivamente aplicados com testes pertinentes, Pint e workload representativo em condições comparáveis.
- Registrar equivalência, planos, tempos, status, vazão útil, recursos, decisões, limitações e rollback. Separar 429 de respostas úteis e não fazer média de percentis como percentil global.
- Validar a change e entregar o plano operacional; deploy/tuning/carga na VPS dependem de decisão própria.

**Saída esperada:** matriz requisito/cenário → evidência e resumo honesto do ganho obtido. Não converter sondas locais ou ganho de SQL em número de usuários/SLA da VPS.

## Pedido sugerido para a próxima parte

> Execute somente o STEP 7 da change `optimize-insights-and-suggestions-queries`, seguindo `SPEC.md` e as tarefas 7.1–7.3. Preserve o STEP 4 adiado/Blocked; priorize sorts por uso real e compare planos, páginas profundas, escrita e tamanho antes de decidir qualquer índice/migration. Atualize as evidências, registre limitações e pare antes do STEP 8.

## Histórico relacionado

- [Testes de carga simples com Pest/Stressless](openspec/changes/add-endpoint-load-testing/tasks.md): entrega simplificada de 5/5 tarefas, uma URL/token por execução e limiter preservado. As limitações do gerador, bursts e rodadas com erros continuam válidas; não criar outro harness por inferência deste roteiro.
- [Investigação inicial de desempenho](openspec/changes/investigate-read-endpoint-performance/design.md): origem dos achados e limitações históricas. Suas tarefas são independentes do checklist desta change.
