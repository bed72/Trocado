# Testes de carga — âncora de implementação

Change: **`add-endpoint-load-testing`**.

**Estado inicial:** planejamento validado; **0/51 tarefas de implementação concluídas**. A criação deste arquivo não inicia implementação, instalação, provisionamento ou execução de carga.

**Apply local — 2026-10-16:** STEP 01 autorizado; **2/51 tarefas concluídas (1.1–1.2)**. Spike bloqueado pela seleção de arquitetura do plugin e pelas capacidades dinâmicas ausentes; decisão de adaptação pendente em 1.6. Evidências em `tasks.md`.

## Fontes de verdade

- [Proposta e escopo](openspec/changes/add-endpoint-load-testing/proposal.md)
- [Desenho técnico e decisões](openspec/changes/add-endpoint-load-testing/design.md)
- [Requisitos e cenários](openspec/changes/add-endpoint-load-testing/specs/)
- [Checklist oficial e evidências](openspec/changes/add-endpoint-load-testing/tasks.md)
- [Arquitetura do projeto](ARCHITECTURE.md)

Este arquivo é o mapa de execução por step. Os contratos normativos e detalhes completos permanecem nos artefatos OpenSpec. Os identificadores das tarefas abaixo correspondem aos do checklist oficial.

Ao executar uma etapa:

1. Ler o step, as tarefas oficiais e as decisões/requisitos relacionados.
2. Implementar uma tarefa pendente por vez dentro do escopo autorizado.
3. Verificar o resultado antes de concluir a tarefa.
4. Sincronizar os checkboxes deste arquivo e de `tasks.md`, registrando comandos, resultados e limitações no checklist oficial.
5. Preservar pendências e evidências históricas. Blocked, timeout, skip ou recurso não comprovado não equivalem a aprovação.

## Decisões consolidadas

| Tema | Definição |
| --- | --- |
| Objetivos | Regressão de desempenho e investigação de capacidade, em cenários separados |
| Endpoints iniciais | GET `/api/expenses`, `/api/metrics/expenses`, `/api/insights` e `/api/expenses/suggestions` |
| Ambiente inicial | Alvo HTTP dedicado no Lerd, com configuração, banco e recursos próprios |
| Massa | 20 contas ativas/verificadas × 10 mil despesas: 200 mil despesas, com PATs reais |
| Carga inicial | Aquecimento separado e níveis de concorrência total 1, 5, 10 e 20, por 30 segundos cada |
| Rate limiter | Perfil de capacidade com cota ampliada somente no alvo dedicado; cenário separado com os 60 requests/minuto por usuário originais |
| Critérios de desempenho | Calibrar primeiro, com repetições; aprovar thresholds depois |
| Execução | Manual e explícita, fora da suíte funcional e do CI automático |
| Ferramenta | Pest Stressless/k6, com dependência dev autorizada para implementação futura e compatibilidade a comprovar |
| VPS | URL configurável para homologação futura; gerador preferencialmente externo e referências próprias por ambiente |
| Produção | Fora da primeira entrega; não executar carga por inferência de autorização local |

## STEP 01 — Autorizar apply e comprovar o motor

**Entrega:** viabilidade técnica do Pest Stressless/k6 comprovada antes de construir a infraestrutura e os cenários dependentes.

- [x] **1.1** Obter autorização explícita de implementação e sondas/carga local; reconferir artefatos, versões e decisões.
- [x] **1.2** Resolver release estável compatível com Pest 5 e requisitos PHP/extensões; registrar versões e instalação dev/lockfile sem rebaixamentos ou alteração de requisito PHP não aprovada.
- [ ] **1.3** Definir topologia Lerd suportada para servidor dedicado com configuração, cache compilado, logs, banco e Redis separados.
- [ ] **1.4** Conferir runtime, download/tamanho/licença do k6, SO/arquitetura, DNS e CA/HTTPS com sonda mínima controlada.
- [ ] **1.5** Provar suporte a múltiplos tokens/URLs, cursores dinâmicos, concorrência total, status/checks, p50/p95/p99 e exportação/agregação.
- [ ] **1.6** Obter decisão explícita para limitações de versão/adaptação antes de implementar cenários dependentes; sem vendor patch ou cobertura reduzida apresentada como equivalente.

**Concluir quando:** versão/binário e capacidades necessárias estão comprovados, a topologia está definida e limitações bloqueantes receberam decisão explícita. A API upstream examinada usa URL e headers fixos por execução; isso não prova os cenários compostos pretendidos.

**Referências:** LOAD-01–04/06–10; design D1/D3.

## STEP 02 — Entrada manual e organização

**Entrega:** comando opt-in e estrutura própria de carga, separados da execução funcional comum.

- [ ] **2.1** Criar entrada proposta `test:load` e configuração dedicada, com seleção avulsa de cenário/endpoint/objetivo e descoberta sem carga.
- [ ] **2.2** Organizar Load por contexto/Presentation/Http e suporte tipado em Tests Support, mantendo tooling fora de `app/`.
- [ ] **2.3** Provar que `composer test`, listagem, Unit/Feature e CI padrão não iniciam/provisionam Load nem usam skips para escondê-lo.
- [ ] **2.4** Definir manifesto privado, fases, estados de resultado e configuração de URL/perfil/dataset/limites, sem segredos em argumentos ou relatórios.

**Concluir quando:** um cenário pode ser selecionado explicitamente e a suíte funcional permanece íntegra. A entrada `test:load` é proposta, não um comando já disponível.

**Referências:** LOAD-01/03–04/12; ORG-01; ISO-08; design D2.

## STEP 03 — Alvo dedicado e ownership

**Entrega:** servidor-alvo identificado e recursos de campanha isolados, com preflight e ownership exatos.

- [ ] **3.1** Provisionar somente o alvo Lerd autorizado, registrando recursos criados/preexistentes e prontidão efetiva.
- [ ] **3.2** Conferir URL, instância, configuração, revisão e PostgreSQL efetivo, com confirmação HTTP por credencial exclusiva; recusar produção/alvo desconhecido.
- [ ] **3.3** Implementar ownership e lease por campanha, namespaces/processos/temporários próprios e migrations incrementais no banco autorizado.
- [ ] **3.4** Provar recusa de URL/configuração/banco divergentes, nome parecido, manifesto ausente/alterado e banco operacional antes de escrita/cleanup/carga.
- [ ] **3.5** Provar duas invocações simultâneas com recursos distintos ou segunda lease recusada, sem interferência.

**Concluir quando:** o banco/configuração do servidor HTTP estão comprovados, não apenas os do processo Pest. Uma campanha não prepara, mede ou limpa recursos de outra.

**Referências:** LOAD-03–04/06; design D3/D4.

## STEP 04 — Massa e credenciais próprias

**Entrega:** dataset reproduzível de 20 proprietários e 200 mil despesas, preparado fora da medição.

- [ ] **4.1** Definir versão/seed, referência civil/timezone, distribuição de meses/categorias/descrições/empates e controles vazios por endpoint.
- [ ] **4.2** Preparar 20 contas aptas, PATs reais e 10 mil despesas UUIDv7 por owner em lotes, sem seeds pessoais ou efeitos externos reais.
- [ ] **4.3** Provar contagens, UUIDs, ownership, datas/distribuição, reuso consistente e recusa de massa/referência divergentes sem duplicação.
- [ ] **4.4** Provar token existente só no gerador rejeitado, PATs válidos no servidor e isolamento A/B, preservando middleware/autorização.
- [ ] **4.5** Proteger credenciais/temporários e provar ausência de segredos e fatos financeiros nos exports/diagnósticos.

**Concluir quando:** a massa pertence exclusivamente à campanha e os tokens autenticam no servidor correto. A seed demonstrativa de desenvolvimento não é a preparação de carga.

**Referências:** LOAD-05–07/12; design D5.

## STEP 05 — Perfis de cota e carga

**Entrega:** capacidade e proteção original medidos em perfis distintos, com concorrência e prazos limitados.

- [ ] **5.1** Implementar cota positiva ampliada apenas no alvo dedicado não produtivo, preservando default 60 e todos os middlewares.
- [ ] **5.2** Separar namespaces Redis por perfil e confirmar/restaurar a configuração efetiva no servidor.
- [ ] **5.3** Provar cota original entre rotas/dois tokens, 60 admitidas/61ª 429 JSON:API com Retry-After, outra conta independente e janela renovada.
- [ ] **5.4** Provar recusa de ampliação fora do alvo, default 60 em desenvolvimento/produção sem perfil e falha explícita se Redis indisponível.
- [ ] **5.5** Definir timeouts, aquecimento, recuperação, limite total e critérios de interrupção conforme recursos inventariados.
- [ ] **5.6** Implementar níveis totais 1/5/10/20 por 30s, distribuição entre contas e cenário de mesma conta, sem multiplicação por subprocessos.
- [ ] **5.7** Provar encerramento limitado, recuperação entre níveis e parada por timeout, limites de recursos ou alvo não recuperado.

**Concluir quando:** os perfis são confirmados no servidor e não compartilham contadores contaminados. Concorrência não é RPS; 429 em capacidade não deve ser interpretado como saturação da aplicação.

**Referências:** LOAD-08–09/13; deltas de cota/contadores; design D7.

## STEP 06 — Catálogo de cenários e correção

**Entrega:** quatro leituras com variações reais e estados de cache/registro identificados.

- [ ] **6.1** Implementar listagem com páginas 20/100, filtros, sort monetário/alfabético, empates e next/prev com cursores reais.
- [ ] **6.2** Implementar métricas total/agrupada, mês elegível/vazio e primeira resolução/hit Core.
- [ ] **6.3** Implementar insights vigente/encerrado, resultado elegível/onboarding e primeira resolução/hit sem fixar variante editorial incidental.
- [ ] **6.4** Implementar sugestões com termo frequente/raro/sem resultado e variações válidas, preservando agrupamento/limites.
- [ ] **6.5** Provar preparação de cache frio/quente e registro ausente/hit fora da janela medida, distinguindo primeira coorte e regime aquecido.
- [ ] **6.6** Provar classificação de 401/403/422, 429, 5xx, timeout e corpo inválido, sem tratá-los como operações bem-sucedidas por serem rápidos.

**Concluir quando:** os cenários exercitam os contratos reais, navegação e estados declarados. Repetir a primeira página não comprova paginação; cache de páginas e associações Core são dimensões diferentes.

**Referências:** LOAD-06–07/09–10; design D6.

## STEP 07 — Métricas, relatórios e cleanup

**Entrega:** resultados rastreáveis e sanitizados, com encerramento e limpeza por ownership.

- [ ] **7.1** Coletar p50/p95/p99, total/RPS, duração, concorrência, statuses e falhas com unidades/populações explícitas.
- [ ] **7.2** Provar agregação válida sem média de percentis; métrica ausente, amostragem insuficiente ou gerador saturado gera inconclusivo/Blocked.
- [ ] **7.3** Produzir relatório legível e JSON sanitizado com revisão, massa/perfil, alvo/gerador, recursos/configuração/versões, cota/cache/registro e instrumentação; definir retenção.
- [ ] **7.4** Provar sanitização por campos permitidos e segredos sentinela, incluindo falhas do motor, processos, URLs e temporários.
- [ ] **7.5** Implementar finally/teardown para filhos, tokens, banco/associações/Redis/temporários próprios e restauração de perfil/instrumentação.
- [ ] **7.6** Provar cleanup em falha/interrupção tratável, preservação de recursos preexistentes/relatórios e recuperação por manifesto após SIGKILL.

**Concluir quando:** relatórios não contêm segredos e cada recurso removido tem ownership validado. Rollback no Pest não reverte os efeitos dos GETs no servidor externo.

**Referências:** LOAD-02/04/10/12–13; design D8–D10.

## STEP 08 — Calibração e regressão

**Entrega:** referência local reproduzível e limites de regressão aprovados com base em evidências.

- [ ] **8.1** Validar sondas mínimas dos quatro endpoints antes de aumentar carga, registrando correção/prontidão.
- [ ] **8.2** Executar a campanha conservadora com pelo menos três repetições por combinação candidata à referência e registrar variabilidade/falhas/interrupções.
- [ ] **8.3** Diagnosticar gargalos por tráfego real/Lerd, correlacionando queries/CPU em rodadas separadas das referências sem instrumentação pesada.
- [ ] **8.4** Apresentar referência e proposta de thresholds por ambiente/endpoint/cenário/perfil/estado; obter aprovação explícita.
- [ ] **8.5** Ativar limites aprovados e provar reprovação controlada, preservação da referência e recusa de comparações não equivalentes.
- [ ] **8.6** Registrar achados de capacidade e restrições; obter decisão para correções de produto fora do escopo, sem relaxar esperados para ocultar gargalos.

**Concluir quando:** as referências são tecnicamente válidas e os thresholds foram aprovados e exercitados. Calibração sem limite aprovado não é aprovação de regressão; resultado local não comprova capacidade da VPS.

**Referências:** LOAD-01/06–12; design D7–D9.

## STEP 09 — Documentação e fechamento

**Entrega:** operação documentada, evidências completas e critérios de conclusão verificados.

- [ ] **9.1** Atualizar ARCHITECTURE/README para Load opt-in, comando, massa, ownership, relatórios e perfis, preservando Unit/Feature e launcher.
- [ ] **9.2** Documentar homologação VPS com URL configurável, gerador externo preferido, referências distintas e autorização própria antes de provisionar/executar remotamente.
- [ ] **9.3** Executar verificações isoladas do harness, suítes funcionais afetadas e arquitetura; mudanças de suporte compartilhado exigem gates padrão, duas seeds e paralelo com pelo menos dois processos.
- [ ] **9.4** Executar Pint e reverificações necessárias; validar OpenSpec e conferir diff, segredos e resíduos próprios.
- [ ] **9.5** Preencher matriz por requisito/cenário com comandos, versões, ambiente, resultados e estados de evidência, incluindo limitações e provas remotas não executadas.
- [ ] **9.6** Resolver bloqueios técnicos e aprovação dos thresholds antes de declarar conclusão/arquivo; archive, commit, push e operações VPS exigem autorização própria.

**Concluir quando:** todas as tarefas têm evidência e os gates aplicáveis passaram. A entrega inicial local documenta a reutilização remota, mas não declara homologação VPS executada.

**Referências:** LOAD-01–13; ORG-01; ISO-08; design e checklist oficial.

## Ordem e pontos de decisão

```text
STEP 01: viabilidade do motor e topologia
  → STEPs 02–05: entrada, isolamento, dados e perfis
    → STEPs 06–07: cenários, métricas, relatórios e cleanup
      → STEP 08: calibração → aprovação dos thresholds → regressão
        → STEP 09: documentação, gates e fechamento
```

- Limitações de Stressless/k6 exigem decisão antes de cenários dependentes, sem substituir a ferramenta silenciosamente.
- Aprovação dos thresholds ocorre depois da calibração, não por pressuposição na implementação.
- A massa e o servidor HTTP precisam estar isolados antes da carga; banco exclusivo do gerador não basta.
- Provisionamento/execução na VPS não são autorizados pelo apply local.

## Validação documental

```sh
openspec status --change add-endpoint-load-testing --json
openspec validate add-endpoint-load-testing --type change --strict --json --no-interactive
```

Esses comandos conferem os artefatos de planejamento. Verificações de implementação e campanhas pertencem aos steps autorizados; artefatos completos não significam produto implementado.
