## 1. Preparação e revisão editorial

- [x] 1.1 Obter autorização explícita para apply, reler as instruções da change e conferir o escopo com a otimização de consultas ativa, sem alterar Repository/SQL por conveniência. Evidência: autorização e inventário focado registrados; design D1/D6.
- [x] 1.2 Preparar e revisar o catálogo completo futuro com pelo menos quatro variantes por conjunto e todas as alternativas, modos e estados. Vincular cada texto ao fato que o autoriza, incluindo reconhecimento positivo demonstrável, alertas sem tarefa obrigatória e exceções acolhedoras. Registrar aprovação editorial sem confundir exemplos com catálogo aprovado. Rastreio: “Catálogo curto com personalidade e fidelidade aos fatos”, “Reconhecimento positivo e sarcasmo sem ofensa”, design D3.
- [x] 1.3 Conferir previamente que todos os conjuntos comportam título até 24 e card completo até 70 grafemas, contando separador, contexto temporal, rótulos longos e emojis opcionais; registrar alternativas completas para anos distintos e intervalos parciais. Rastreio: cenários “Limite exato e excesso”, “Emojis e caracteres compostos”, “Comparação parcial compacta” e “Rótulos longos e alternativas compactas”; design D2.

## 2. Catálogo, composição e segurança

- [x] 2.1 Versionar e substituir os templates/alternativas numéricos pelo catálogo revisado, preservando tipos, grupos, contexto mensal, mecanismo de rotação e identidade lógica. Rastreio: concentração, comparações, onboarding, categorias expandidas e rotação; design D1/D3/D6.
- [x] 2.2 Implementar a contagem do par completo por grafemas e a validação das alternativas no limite de 70 com título até 24, sem truncamento, sem troca incidental de variante e com falha explícita quando nenhuma alternativa for válida. Verificar APIs Unicode disponíveis sem adicionar dependência. Rastreio: “Catálogo curto com personalidade e fidelidade aos fatos”; design D2.
- [x] 2.3 Retirar interpolação editorial de valores/porcentagens, preservar números simples factuais e proteger descrições de usuário, usando categoria/data quando o texto não for seguro ou não couber. Preservar precisão, thresholds e seleção do mesmo lançamento no snapshot, sem query extra ou logs de descrição. Rastreio: “Fatos derivados de registros com cálculo exato” e “Maior lançamento identificado por fatos do registro”; design D1/D4.
- [x] 2.4 Ajustar onboarding e variantes sensíveis para acolhimento/motivação, sem elogiar ausência ou redução nem inferir renda, saldo, hábitos, dificuldade ou economia. Confirmar que não foi criada cota de positividade ou regra analítica nova. Rastreio: “Onboarding contextual e tratamento de other” e “Reconhecimento positivo e sarcasmo sem ofensa”; design D3.

## 3. Seleção sem redundância

- [x] 3.1 Revisar equivalência semântica e sobreposição entre candidatos, conservando prioridades/desempates e cobrindo mesmo fato com tipos ou paráfrases diferentes sem apagar informações realmente distintas. Rastreio: “Seleção relevante sem preenchimento artificial”, cenários de alimentação, maior lançamento e mesmo significado; design D5.
- [x] 3.2 Validar unicidade textual do conjunto composto, incluindo diferenças cosméticas de caixa/espaços/pontuação/emojis; em colisão conservar maior prioridade, sem reposição artificial, e só depois resolver o lote final de UUIDs. Rastreio: “Colisão textual após composição” e “Poucos fatos relevantes”; design D5/D6.
- [x] 3.3 Preservar repetição permitida entre consultas, rotação diária, recálculo imediato e estabilidade de UUID/variante quando só mudam números internos. Não persistir visualização ou congelar respostas. Rastreio: “Reaparecimento em outra consulta” e todos os cenários de “Rotação diária estável sem histórico de visualização”; design D5/D6.

## 4. Evidência focada e suporte ao consumidor

- [x] 4.1 Atualizar testes Unit focados do catálogo/compositor para todas as variantes/fallbacks: 70/71 grafemas, teto do título, espaço separador, acento combinante, emojis compostos/opcionais, rótulos longos, anos diferentes e períodos parciais/fechados. Rastreio: BEH-13, catálogo e categorias expandidas.
- [x] 4.2 Atualizar provas editoriais de dinheiro/porcentagem proibidos, proporções por extenso, números simples permitidos, descrição insegura, elogio fundamentado e ausência que não prova economia; incluir os contraexemplos “3 dias sem delivery” e “Você guardou dinheiro”. Complementar testes com revisão humana de todas as variantes. Rastreio: BEH-13, segurança, fatos e maior lançamento.
- [x] 4.3 Atualizar testes Unit de seleção/orquestração para redundância semântica entre tipos, colisão textual, preservação de fatos distintos, resultado menor que seis, ordem estável e alocação de UUIDs somente do lote final. Rastreio: BEH-13 e seleção; design D5.
- [x] 4.4 Ajustar as expectativas editoriais de Feature/HTTP existentes e executar regressões focadas de owner, elegibilidade exata, limites civis, tipos/grupos/períodos, onboarding, recálculo, UUIDv7, rotação e falha explícita sem parcial. Não exigir número na descrição nem literal incidental. Rastreio: BEH-13 e requisitos modificados; contratos HTTP/temporais preservados.
- [x] 4.5 Atualizar somente as assertions/documentação pertinentes em `bruno/Insights/` para o orçamento combinado e proibição editorial de dinheiro/porcentagem, sem dependência de variante literal ou quantidade mínima. Preservar filtros e credenciais por ambiente. Rastreio: requisito existente de Bruno e novo catálogo.
- [x] 4.6 Atualizar a documentação existente que descreve 24/80, magnitude e neutralidade obrigatórias, sem reescrever catálogos/evidências arquivados; registrar a ruptura editorial e preservação do envelope. Rastreio: proposal e design D6.

## 5. Verificação e fechamento do apply

- [x] 5.1 Executar os arquivos afetados isoladamente e a suíte focada pelo launcher `lerd composer test -- ...`, registrando comandos, resultados e limitações; executar Pint `--dirty --format agent` pelo tooling Lerd quando PHP mudar. Não executar Feature diretamente nem testes durante a etapa exclusiva de spec.
- [x] 5.2 Revisar rastreabilidade de cada requisito/cenário ao catálogo aprovado e evidências, fronteiras arquiteturais e tarefas efetivamente verificadas, usando o quality gate no escopo do apply autorizado. Não declarar testes automáticos como aprovação humana de tom, de ausência de redundância semântica ou de layout Flutter.
- [x] 5.3 Revalidar esta change estritamente, registrar plano de publicação/rollback e limitações de consumidor; não sincronizar main specs, arquivar ou publicar sem a autorização correspondente.

## Evidências do apply — 2026-10-19

> Histórico da revisão 1/v5 abaixo. O feedback posterior do usuário superou a proibição de dinheiro e a direção de humor. As tarefas 1–5 e seus resultados continuam históricos; o grupo 6 registra a revisão atual e tem verificações próprias.

- Autorização explícita: pedido “Implementa a spec /reformulate-insights-editorial”. Supera a restrição histórica de autorização somente documental em proposal/design; não autoriza publicação, sync ou archive.
- OpenSpec 1.6.0: doctor saudável, status e instructions apply lidos; validação estrita passou sem issues antes de editar.
- Inventário: catálogo/compositor/seleção/orquestração em Insights Application; equivalência em `InsightCandidateValueObject`; Data de templates, testes focados e Bruno. A seleção já suprime liderança/concentração/maior lançamento sobrepostos; falta a verificação textual final antes do lote Core.
- A otimização ativa já modificou o Repository de Insights e mantém três tarefas operacionais bloqueadas. Nenhuma alteração desse Repository, SQL, Metrics, Identity, schema ou runtime faz parte deste apply.
- Estado inicial: somente a pasta desta change estava untracked. Lerd/Boost confirmaram site principal `trocado`, PHP 8.5, Laravel 13.34.0 e PostgreSQL. Nenhum teste da aplicação executado nesta preparação editorial.
- Catálogo proposto em `editorial-catalog.md`: 11 famílias, quatro variantes por conjunto/modo/direção, 92 pares completos considerando a alternativa categoria/data. Conferência documental com rótulo máximo “Presentes e doações”, dia 31, identificação de 26 caracteres e meses/anos distintos: todos os títulos até 24 e pares até 70; máximo observado 68. Os textos propostos não contêm emojis nem acentos combinantes, portanto pontos de código coincidem com grafemas nessa conferência; os cenários Unicode de runtime continuam pendentes em 2.2/4.1. Descrições arbitrárias nunca são prometidas como cabendo: a alternativa factual está prevista por variante. Revisão humana/aprovação de 1.2 continua pendente.
- Atualização: aprovação humana explícita “Aprovar revisão 1” recebida após apresentar o arquivo completo. Substituição por `v5-short-editorial`, quatro variantes por conjunto, sem interpolação de razão/BRL. Sem alteração de geração de candidatos, precisão, SQL ou identidade lógica.
- `InsightMessageValueObject` protege o par normalizado; `grapheme_strlen` e `Normalizer` funcionaram no runtime instalado, sem nova dependência. Seleção semântica existente foi revisada e preservada: liderança substitui concentração/maior lançamento sobrepostos; assunto/período distintos e revisão de Outros versus lançamento individual permanecem. `SelectInsightMessagesUseCase` deduplica textos já priorizados e devolve os índices finais antes de Core.
- Primeira execução isolada de Compose: 26 testes/9138 assertions, passou. Unit Insights inicial: 586/24949, passou. Após ajustes, Unit Insights + fronteiras: 622/25272, passou com fail-on-skipped/incomplete/risky. Feature Insights inicial: 172/176, quatro falhas de expectations antigas que exigiam mês no título em vez do par; corrigidas mantendo prova de contexto temporal. Rerun: 176/1991, passou com os mesmos flags; banco exclusivo do launcher e migrations incrementais. `migrate:status` local confirmou todas executadas, sem migration nova/pendente.
- Pint `--dirty --format agent` executado após mudanças PHP; corrigiu alinhamento PHPDoc/ordem de imports/espaçamento. Reruns finais isolados e focados serão registrados em 5.1.

### Verificação final e rastreabilidade

Todos os testes abaixo usam `exec` Lerd com `action: composer`, `args: ["test", "--", <arquivo/opções>, "--compact", "--fail-on-skipped", "--fail-on-incomplete", "--fail-on-risky"]`, equivalente a `lerd composer test -- ...`. Sem execução direta por Pest/Artisan, SQLite, migrate:fresh ou remoção de dados operacionais. Cada Feature recebeu seu próprio banco por invocação do launcher.

| Arquivo isolado (caminho relativo a tests) | Testes / assertions | Resultado |
| --- | --- | --- |
| Unit/Insights/Domain/ValueObjects/InsightMessageValueObjectTest.php | 9 / 22 | passou |
| Unit/Insights/Application/UseCases/SelectInsightMessagesUseCaseTest.php | 1 / 3 | passou |
| Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php | 33 / 8967 | passou, incluindo rerun após o último cenário de alternativa por tamanho |
| Unit/Insights/Application/UseCases/ExpandedCategoryMessageTest.php | 306 / 14892 | passou |
| Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php | 25 / 184 | passou |
| Unit/Insights/Application/UseCases/SelectInsightCandidatesUseCaseTest.php | 18 / 27 | passou, mantido sem refactor |
| Feature/Insights/InsightsApiTest.php | 54 / 363 | passou |
| Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php | 22 / 368 | passou |
| Feature/Insights/Presentation/Http/ExpandedCategoriesInsightsHttpTest.php | 20 / 248 | passou |
| Feature/Insights/Presentation/Http/MonthlyCompositionFailureHttpTest.php | 2 / 32 | passou |
| Feature/Insights/Presentation/Http/MonthlyContractHttpTest.php | 2 / 89 | passou |
| Feature/Insights/Presentation/Http/MonthlyIdentityHttpTest.php | 6 / 169 | passou |
| Feature/Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php | 41 / 256 | passou |
| Feature/Insights/Presentation/Http/MonthlyOnboardingHttpTest.php | 22 / 218 | passou |
| Feature/Insights/Presentation/Http/MonthlyRotationHttpTest.php | 5 / 224 | passou |

- Gate completo final, depois do último PHP e Pint: `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` → **2417 testes / 36159 assertions**, passou em **81,002s**, banco exclusivo `trocado_testing_f9136b4410cffef65b8ec94b`. Inclui Insights, fronteiras, Redis e concorrência preexistente. Não somar isolados/focados como testes adicionais. Não houve skips/incomplete/risky inesperados. Seeds e paralelo completo não foram executados: não há reorganização de suíte nem alteração de suporte compartilhado.
- Pint final `exec vendor_run pint --dirty --format agent`: passou. `git diff --check`: passou. OpenSpec strict da change: válido/sem issues.
- Bruno 01–03: assertions compilaram em Node do host; `Intl.Segmenter` contou 70/71 corretamente para acento combinante, tom de pele e emoji ZWJ. Sem alterar filtros, URLs, credenciais ou outros requests. **Não executado no aplicativo/CLI Bruno contra uma conta real**; runtime Bruno precisa oferecer Intl.Segmenter. Assertions e documentação são o escopo da task 4.5, não homologação externa.
- README/ARCHITECTURE atualizados; main specs e evidências/catálogos arquivados intocados. A matriz abaixo usa a delta autorizada como contrato novo, não a magnitude obrigatória antiga.

| Requisito/cenários da delta | Evidência e classificação |
| --- | --- |
| Fatos exatos: retroativo/futuro, valor diminuto, ausência, overflow | **Proven** pelas regras Unit existentes, Repository PostgreSQL e HTTP de recálculo/limites; compositor agora ignora magnitude interna, com prova de razão de 100 dígitos. SQL/thresholds preservados. |
| Snapshot/alteração concorrente | Um único statement e projeções reconciliadas preservados, Repository passou; **Partially proven** para a intercalação específica de escrita concorrente de despesas: não foi criada corrida nova nesta mudança editorial. Testes concorrentes gerais do gate não são apresentados como essa prova. |
| Concentrações: líder, empate, volume insuficiente e lançamento não atípico | **Proven** em GenerateInsightCandidatesRules/GenerateInsightCandidates e Repository; ciclos de Compose e ExpandedCategoryMessage verificam textos qualitativos em todas as categorias/modos, sem inferir excesso. Catálogo 1–4 aprovado. |
| Comparações: redução, diferenças absoluta/relativa, anterior vazio, meses inteiros | **Proven** nas regras Unit e MonthlyInsightsFilters/Rotation; Compose verifica direção, ambos os anos e os dois intervalos parciais, incluindo virada dezembro/janeiro. Catálogo 5 aprovado; não há elogio por queda. |
| Onboarding: primeira despesa, história antiga, Outros, mês anterior ao primeiro registro e poucos registros | **Proven** em geração Unit, MonthlyOnboarding/Identity/Filters e ciclos de Compose; Outros mantém threshold exato, público null e contexto interno. Catálogo 8–11 aprovado. |
| Seleção: alimentação equivalente, maior lançamento sobreposto, poucos fatos e mesmo significado | **Proven** nas 18 provas existentes de SelectInsightCandidates, Domain Candidate e HTTP de liderança/novas categorias; revisão confirmou que não é necessário reescrever equivalência já implementada. Fatos distintos de Outros e comparação do total foram conservados. |
| Colisão textual e reaparecimento | **Proven** em SelectInsightMessages e Message VO: primeiro índice priorizado, caixa/espaços/pontuação/emojis, diferenças factuais preservadas, repetição permitida por invocação. GetInsights e MonthlyContract comprovam lote canônico final e falha antes de associação; inspeção confirma uso exclusivo dos índices filtrados na identidade. Não se afirma que o catálogo atual produziu uma colisão natural via HTTP. |
| Catálogo: alimentação, 70/71, emojis, parcial/histórico, extremos, números permitidos e falha editorial | **Proven** em Compose, Message VO, ExpandedCategoryMessage (306 combinações), MonthlyContract e MonthlyCompositionFailure. Alternativa por comprimento de identificação segura exercitada sem troca da variante. Grafemas e normalização executados no PHP instalado, sem dependência nova. Aprovação de tom é a resposta humana explícita, não regex. |
| Rotação: mesmo dia, seguinte, mudança numérica, ciclo, histórico e retroativo | **Proven** em SelectInsightMessageVariant, Compose, GetInsights, MonthlyRotation e MonthlyIdentity, com identidade/variante estáveis e próxima consulta reavaliando elegibilidade. Sem persistência de visualização ou congelamento. |
| Categorias expandidas: oito rótulos, investimentos, financiamentos, longos e viagens | **Proven** nas 306 combinações de ExpandedCategoryMessage e ExpandedCategoriesInsightsHttp; rótulos integrais, datas-limite 0001/9999, modos e virada de ano. Catálogo 1–7 aprovado. |
| Maior lançamento: identificação utilizável, ausente/longa, marcação literal, conteúdo proibido e empate | **Proven** em Compose/InsightsApi/MonthlyContract e Repository: fallback mesmo registro, owner e desempate inalterados; dados/SQL não modificados. Segurança conservadora aceita somente identificações neutras conhecidas integralmente, nunca texto livre por blacklist. |
| Reconhecimento/sarcasmo: registro de investimentos, inatividade, categoria sensível e alerta sem tarefa | **Proven** por revisão humana do catálogo completo, provas objetivas de ciclos/identificação adversa e expectativas específicas de reconhecimento de registro nas sete categorias acolhedoras. Os contraexemplos “3 dias sem delivery” e “Você guardou dinheiro” têm datasets de fallback. Não se declara um classificador semântico geral nem validação Flutter. |
| BEH-13 e fronteiras | **Proven** por Unit/Feature/arquitetura e gate completo, sem dependência do caminho de uma change ativa ou de literal único na integração. Nenhuma nova dependência cross-context, binding, contrato HTTP, Repository ou migration. |

#### Mapa dos cenários editoriais substituídos

O arquivo Compose foi reescrito porque o contrato editorial mudou, não para reduzir a suíte. Catálogo regular/curto/monetário → ciclo completo de todos os tipos/categorias/modos + catálogo humano; 24/80 → VO 70/71 e título 24/25; interpolação/refresh de percentual e BRL exato → estabilidade qualitativa com montantes extremos (cálculos exatos permanecem nas provas de Core/geração); erro por número longo → composição válida sem número; onboarding e liderança por literais → ciclos e contexto, com reconhecimento explícito das categorias sensíveis; identificação/markup/whitespace e fallback → identificação segura, conteúdo adverso e alternativa por tamanho sem trocar variante; rotação/mês/ciclo/anos → ciclo de cinco visitas e pares temporais explícitos, complementados por SelectInsightMessageVariant e HTTP. As garantias que ainda valem foram mantidas; não usar contagem como equivalência nem recalcular expected financeiro com produção. SelectInsightCandidates e suporte compartilhado não foram movidos/consolidados.

#### Operação, consumidor e rollback

- Dumps estavam e permaneceram habilitados/listening, sem clear global. HTTP foi exercitado pelo kernel real nos testes isolados. `optimize_route(site=trocado)` retornou **zero amostras**, portanto não há prova nova de desempenho/N+1 em tráfego FPM autenticado. A prova determinística HTTP/Repository preserva uma leitura financeira; nenhuma promessa de latência/SLA ou extrapolação da otimização anterior.
- Sem bloqueio de implementação encontrado no quality gate; limitações de observação concorrente específica, Bruno real e layout estão explicitadas, não escondidas em testes verdes. Não há homologação Flutter.
- Publicação futura, somente mediante autorização: publicar release backend com `v5-short-editorial`; consumidor conserva os mesmos atributos e não extrai números de texto. Smoke de conta controlada confirma envelope, 70/24, datas e UUID estável; não requer migration/backfill, limpar dados ou reiniciar identidades.
- Rollback por release restaura catálogo/compositor/seleção anterior e assertions correspondentes, sem apagar dados ou identidades. Reintroduz dinheiro/porcentagens e o limite antigo: exige aceitar explicitamente que o contrato editorial novo deixa de ser atendido.
- Nenhum deploy, archive, sync, commit ou push executado. Change permanece ativa; conclusão das tarefas de apply não substitui eventual decisão de sincronização/arquivamento.

## 6. Redesenho monetário direto após feedback real — revisão atual

- [x] 6.1 Atualizar proposal/design/deltas e apresentar catálogo completo v6 no padrão monetário aprovado, com alternativas, sem humor/datawall, preservando as evidências anteriores; validar estritamente antes de implementar.
- [x] 6.2 Transportar valor positivo da categoria selecionada na liderança sem mudar elegibilidade, SQL, snapshot, identidade ou sumarizar os três meses; provar invariantes e origem do montante.
- [x] 6.3 Implementar todos os conjuntos v6 e alternativas completas, BRL exato por strings sem float/arredondamento, referência natural com detalhes em period e onboarding histórico contextual; aplicar orçamento 80/24 explicitamente aprovado, mantendo rotação, segurança e deduplicação.
- [x] 6.4 Atualizar provas Unit/Feature e Bruno/docs para dinheiro real, centavos, extremos, valores corretos por tipo, recálculo sem troca de UUID/variante, Unicode, alternativas e falha explícita; não enfraquecer contratos de owner/períodos/thresholds.
- [x] 6.5 Executar isolados afetados, contexto/arquitetura e Pint pelo launcher/tooling Lerd; registrar comandos/resultados/limitações, revisão quality gate/rastreabilidade e validação OpenSpec final, sem deploy/sync/archive.

### Evidências da revisão atual

- Aprovações explícitas após apresentação do catálogo completo v6: “80 no total (Recomendado)” e “Aprovar e aplicar”. Exemplo de comparação aprovado tem 72 grafemas; a revisão não promete mais caber em 70. Delta/design/proposal atualizados e validação estrita passou antes do código.
- `selectedCategoryAmount` é exclusivo/positivo para liderança e vem de `$current->categoryAmount($leader)` do mesmo resumo reconciliado. Teste com R$ 1.800, R$ 2.300 e R$ 2.700 nos três meses confirma R$ 1.800 no selecionado, não soma. Invariantes rejeitam ausência, zero ou fato em outro tipo; nenhuma query/threshold alterado.
- Durante regressão, os testes de identidade detectaram ordem de componentes divergente em GetInsightsUseCase. Após explicar o efeito de novos IDs para o mesmo card, o usuário autorizou explicitamente “Sim, preservar os IDs”. Restaurada somente a ordem contratual preexistente (type, subject, history_state, analysis_from, analysis_to, comparison_from, comparison_to), sem limpar/escrever associações operacionais. O montante novo não participa dessa chave.
- Unit Insights atual: **603 testes / 28201 assertions**, passou pelo launcher com flags fail-on-skipped/incomplete/risky. Inclui os dois exemplos monetários aprovados, centavos e valores acima de inteiro nativo, falha de montante integral impossível, 80/81 grafemas e origem da liderança. Ajustes pendentes de expectations Feature ainda não contam como aprovação da revisão atual.
- Catálogo/composição v6 implementados, com alternativas de par inteiro e formatação BRL por string. Feature atual após adaptar as expectativas ao contrato autorizado: **176 / 2060**, passou, preservando owner, períodos, uma leitura, dados financeiros e UUIDs. A primeira execução de Feature teve 130/176: 46 expectativas antigas sobre dinheiro proibido/mês numérico/título antigo, corrigidas sem alterar arranjo financeiro ou critérios de seleção. Unit inicial também detectou expectations antigas e a divergência de ordem de chave já autorizada/corrigida; regressões de identidade voltaram a passar sem modificar o expected contratual.
- Provas adicionais de todos os seis tipos monetários × dois modos × quatro variantes com `9223372036854775808` centavos passaram preservando valor integral e limite de 80. Liderança tem prova de recálculo completo com valor/UUID/variante/period, além da origem no selecionado. Segurança de descrições continua testada com dinheiro de usuário, porcentagem, ofensa e os dois contraexemplos de inferência proibida.
- Bruno 01–03 atualizado para 80/24, exigir BRL nos seis tipos monetários e continuar vedando percentuais/proporções/decoração. Node do host compilou as assertions e confirmou Intl.Segmenter em 80/81 com acento combinante, emoji ZWJ e tom de pele. Não executado contra conta real no aplicativo/CLI Bruno; não equivale a homologação Flutter. README/ARCHITECTURE refletem a direção monetária e os intervalos em period; arquivos arquivados e main specs intocados.

### Gate final da revisão v6 — evidência atual, distinta de v5

Comandos canônicos via MCP Lerd: `exec action=composer args=["test", "--", <arquivo/opções>, "--compact", "--fail-on-skipped", "--fail-on-incomplete", "--fail-on-risky"]`. Sem testes Feature diretos, migrate:fresh, SQLite, limpeza de cache/dados do usuário ou alteração de configurações. Cada invocação Feature recebeu banco exclusivo e preflight/migrations incrementais do launcher. Nenhum suporte compartilhado ou migration foi alterado.

| Isolado atual, relativo a tests/ | Testes / assertions | Resultado |
| --- | --- | --- |
| Unit/Insights/Domain/ValueObjects/InsightCandidateValueObjectTest.php | 47 / 155 | passou |
| Unit/Insights/Domain/ValueObjects/InsightMessageValueObjectTest.php | 9 / 22 | passou |
| Unit/Insights/Application/UseCases/GenerateInsightCandidatesRulesTest.php | 56 / 117 | passou |
| Unit/Insights/Application/UseCases/SelectInsightCandidatesUseCaseTest.php | 18 / 27 | passou |
| Unit/Insights/Application/UseCases/ComposeInsightMessageUseCaseTest.php | 51 / 8496 | passou |
| Unit/Insights/Application/UseCases/ExpandedCategoryMessageTest.php | 306 / 18972 | passou |
| Unit/Insights/Application/UseCases/GetInsightsUseCaseTest.php | 26 / 202 | passou |
| Feature/Insights/InsightsApiTest.php | 54 / 366 | passou |
| Feature/Insights/Infrastructure/Repositories/Persistence/EloquentExpenseAnalysisRepositoryTest.php | 22 / 377 | passou |
| Feature/Insights/Presentation/Http/ExpandedCategoriesInsightsHttpTest.php | 20 / 266 | passou |
| Feature/Insights/Presentation/Http/MonthlyCompositionFailureHttpTest.php | 2 / 32 | passou |
| Feature/Insights/Presentation/Http/MonthlyContractHttpTest.php | 2 / 93 | passou |
| Feature/Insights/Presentation/Http/MonthlyIdentityHttpTest.php | 6 / 175 | passou |
| Feature/Insights/Presentation/Http/MonthlyInsightsFiltersHttpTest.php | 41 / 257 | passou |
| Feature/Insights/Presentation/Http/MonthlyOnboardingHttpTest.php | 22 / 222 | passou |
| Feature/Insights/Presentation/Http/MonthlyRotationHttpTest.php | 5 / 248 | passou |

- Todos os isolados acima passaram **depois do Pint** atual. Focado final `tests/Unit/Insights tests/Feature/Insights tests/Unit/Architecture/ContextBoundariesTest.php` com os mesmos flags: **822 testes / 30975 assertions**, **12,079s**, passou, banco `trocado_testing_cf47923b1678794fbdbc87f7`.
- Gate completo padrão final `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky`: **2440 testes / 39865 assertions**, **84,962s**, passou, banco `trocado_testing_af815688487ed337dab7d9e5`. Inclui arquitetura, Redis e concorrência existentes. Não houve skips/incomplete/risky inesperados. Não somar reruns/isolados como testes adicionais; nenhum benchmark ou capacidade operacional foi derivado desses tempos.
- Pint `exec vendor_run pint --dirty --format agent` executado após o último PHP, corrigiu imports/espaçamento; isolados, focado e gate completo posteriores passaram. `git diff --check` e OpenSpec strict atuais passaram.

| Contrato atual / cenários | Rastreabilidade e classificação |
| --- | --- |
| Valor real/data/owner/exatidão | **Proven** por Repository PostgreSQL e InsightsApi/MonthlyContract, preservando uma leitura e dados financeiros; Compose formata 35000/35001/1/180000/9223372036854775808 por expected literais independentes. Não publica razão ou dinheiro de descrição. |
| Categoria líder, empate e base mínima | **Proven** pelas regras Unit preservadas e ExpandedCategories HTTP. Categoria mostra seu total (R$ 400/R$ 600 nos arranjos), não valor do máximo ou total geral. |
| Aumento/redução/parcial/encerrado e base material | **Proven** pelas regras de geração e ciclos Compose, InsightsApi e MonthlyInsightsFilters: direção/tipo/thresholds e períodos preservados, dinheiro da diferença absoluta. Os dois exemplos aprovados são exercitados literalmente dentro dos conjuntos; comparações correntes não incluem dia em andamento. |
| Liderança do terceiro mês | **Proven** por novo cenário de geração com montantes distintos nos três meses, invariantes exclusivas/positivas de selectedCategoryAmount, prova completa GetInsights de R$ 300 → R$ 330 com UUID/variante/period estáveis e Repository/HTTP de liderança. Nenhum SQL novo, soma de três meses ou mudança de prioridade. |
| Maior lançamento/identificação/segurança/desempate | **Proven** por Compose, InsightsApi, Repository e MonthlyContract. Título identifica descrição reconhecida ou categoria/data; compacta conserva data/categoria/valor/condição. O montante publicado vem do máximo selecionado; conteúdo ofensivo/instrução/percentual/dinheiro do usuário usa fallback, sem truncar ou logar texto. |
| Outros e onboarding | **Proven** em MonthlyOnboarding/Identity/Filters e ciclos de catálogo. Revisão publica R$ 50/R$ 60 conforme os limiares exatos do arranjo; insuficiência e vazio não inventam valor/conquista. Primeiro registro não exige datas decorativas; histórico sem period público mantém mês/ano. |
| Catálogo completo/80–81/centavos/extremos/alternativas/falhas | **Proven** pelos 51 cenários de Compose, 306 combinações de ExpandedCategoryMessage e VO Unicode. Seis tipos monetários em dois modos percorrem quatro variantes com valor acima de inteiro nativo; montante de 100 dígitos falha sem remover dinheiro. Alternativas testadas como pares completos válidos, inclusive título de categoria longo e descrição segura que excede o teto de título. |
| Deduplicação/prioridades/UUID/rotação | **Proven** por SelectInsightCandidates, SelectInsightMessages, GetInsights, MonthlyIdentity/Rotation/Contract e fronteiras. A ordem original da chave de identidade foi restaurada com autorização, sem mudar o expected contratual nem adicionar valor à chave. Apenas o lote final é associado; não houve mudança de mecanismo de rotação ou persistência de visualização. |
| Respeito e utilidade editorial | Catálogo completo v6 **aprovado pelo usuário** (“Aprovar e aplicar”) após direção e orçamento explícitos. Assertions vedam percentuais/proporções e frases de enfeite, mas não são declaradas prova semântica universal. Dinheiro não implica renda/economia/retorno; onboarding sem dado não fabrica vitória. |
| BEH-13 e arquitetura | **Proven** pelo gate atual e fronteiras: variantes aceitas sem literal incidental na integração, catálogo focado independente de caminho da change, Domain/Application sem framework e sem import cross-context novo. Contratos HTTP, Infrastructure financeira, composição Core e esquema preservados. |

#### Limitações e operação atual

- Dumps estavam habilitados/listening e foram preservados, sem clear/toggle. Kernel HTTP real exercitado nos testes; `optimize_route(site=trocado)` continua com **zero amostras** FPM. Portanto não há prova nova de latência/N+1 em tráfego autenticado operacional; a prova de uma leitura é determinística no HTTP/Repository. Não foram criadas credenciais/contas operacionais para medição.
- Consistência continua baseada no mesmo statement/snapshot; não se reivindica uma nova corrida sincronizada de escrita de despesas. Testes concorrentes gerais do gate não substituem essa prova específica. SQL não foi alterado pelo redesenho.
- Bruno real e Flutter/layout não homologados. Os limites são grafemas, não garantia de linhas físicas. Esta revisão permite 80 combinados por escolha explícita, não 80 por campo.
- Associações emitidas com uma eventual ordem divergente não foram migradas/apagadas. Restaurou-se o contrato canônico de código e testou-se sua estabilidade; não se afirma ter reconciliado dados históricos por inspeção ou backfill.
- Publicação futura somente com autorização: release v6 mantendo os mesmos atributos; smoke controlado de valores, períodos e IDs. Sem migration/backfill/limpeza de dados. Rollback técnico por release para v5 restaura os textos rejeitados/proibição de dinheiro e exige aceitar essa regressão editorial.
- Nenhum deploy, sync, archive, commit ou push executado. Tarefas anteriores preservam evidência histórica; o grupo 6 documenta a aceitação atual, sem usar o gate antigo para aprovar o novo contrato.

### Fechamento autorizado — 2026-10-19

- Pedido explícito: “Arquiva, commita tudo e da push”. Autoriza arquivar esta change pelo CLI nativo com sync de suas main specs, incluir todas as alterações pendentes revisadas no commit e enviar para `origin/main`; não é autorização de deploy. As declarações anteriores de ausência de archive/commit/push registram as etapas históricas.
- Duas concatenações de `InsightMessageValueObject` foram convertidas para interpolação por solicitação posterior do usuário. Após cada ajuste, Pint e o arquivo isolado passaram (**9 testes / 22 assertions**).
- Gate de fechamento novo após o último PHP e Pint: `lerd composer test -- --compact --fail-on-skipped --fail-on-incomplete --fail-on-risky` → **2440 testes / 39865 assertions**, **79,652s**, passou, banco exclusivo `trocado_testing_c32e5d523d296387c490a206`; sem skips/incomplete/risky inesperados. Não reutiliza o resultado anterior como se fosse execução nova.
- `openspec instructions apply` confirmou **24/24** tarefas concluídas; validação strict da change, `git diff --check`, Pint e doctor OpenSpec passaram. Quality gate conferiu a rastreabilidade v6 acima, aprovação humana, contrato canônico de IDs e fronteiras. Limitações não bloqueantes de Bruno real, Flutter e tráfego FPM permanecem explícitas, sem alegação de novas provas de corrida/snapshot ou performance.
- Antes do commit, `git fetch origin` concluiu sem erro; branch atual `main` acompanha `origin/main`. Diff pendente revisado: contexto Insights, suas provas, Bruno/Insights, README/ARCHITECTURE e artefatos desta change, sem credenciais, .env, migrations ou arquivos de outras changes.
- A primeira tentativa nativa de archive recusou sincronizar porque a delta v6 havia substituído nomes de cenários existentes. O CLI confirmou ausência de escrita/movimentação. Reconciliados todos os cenários anteriores dos requisitos modificados (Insights e BEH-13), conservando os nomes e atualizando somente as expectativas editoriais superadas para dinheiro/80 grafemas/contexto em period. Mantidos os cenários novos; nenhum requisito de outra capacidade removido. A reconciliação é exclusivamente documental, sem alteração PHP ou nova regra de produto; preservação de nomes conferida contra main com conjunto faltante vazio, strict e diff-check passaram novamente antes de repetir archive.
- Archive nativo concluído em `2026-10-19-reformulate-insights-editorial`, com specs sincronizadas: **1 requisito adicionado, 11 modificados, zero removidos/renomeados**. Pós-archive: doctor saudável, change ausente da lista ativa, inventário de specs atualizado e validação global strict **23/23 válidos**; somente observações INFO sobre tamanho de requisitos. Removidas duas linhas vazias extras de EOF emitidas pelo sync para atender `git diff --check`, sem mudança de conteúdo normativo.
