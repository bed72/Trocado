## 1. Autorizar e preparar a implementação futura

- [x] 1.1 Obter autorização explícita para implementar/apply. Autorização recebida para começar pelo Domain e seus testes; as demais camadas ficam para etapas posteriores.
- [x] 1.2 Confirmar o escopo de verificação autorizado. Criar e executar testes puros de Metrics e ajustar/executar as verificações existentes de fronteira; HTTP, Application e PostgreSQL não são comprovados nesta etapa.
- [ ] 1.3 Reconsultar versões, documentação Laravel/JSON:API, schema de `expenses`, conexões, índices e grupo de proteções das rotas analíticas com os MCPs/Artisan apropriados; documentar qualquer divergência relevante antes de alterar o desenho.

## 2. Estabelecer Metrics e seus contratos puros

- [x] 2.1 Introduzir somente as camadas necessárias de `app/Metrics/`, preservando o ownership de fatos quantitativos e ausência de imports de Expense, Identity e Insights, conforme o requisito de contexto dedicado.
- [x] 2.2 Definir tipos puros mínimos para período civil inclusivo e modo de agrupamento, protegendo datas reais, ordem e dia único também fora de HTTP; manter relógio/timezone fora de Domain e Application.
- [ ] 2.3 Definir `ExpenseMetricsPort` com proprietário, período e modo explícitos e projeção própria tipada; não expor Model, Builder, connection, collection Laravel ou Output HTTP no contrato.
- [ ] 2.4 Definir Input/Outputs próprios em `Application/Data`, `final readonly`, constructor-only, distinguindo agrupamento ausente de agrupamento presente e vazio, sem carriers redundantes por conveniência.
- [x] 2.5 Definir aritmética exata de centavos e percentual com duas casas/half-up em tipos puros, sem overflow, float, arredondamento intermediário ou correção artificial da soma de percentuais; usar somente dependência pura já instalada e atualizar a permissão arquitetural pertinente.

## 3. Implementar a leitura analítica PostgreSQL

- [ ] 3.1 Implementar `ExpenseMetricsAdapter` sobre o schema compartilhado, somente leitura de `user_id`, `occurred_on`, `amount` e `category`, com filtro obrigatório por proprietário antes de agregação e limites inclusivos.
- [ ] 3.2 Implementar total simples por soma exata no banco, preservando string canônica inclusive acima de `PHP_INT_MAX` e retornando `"0"` somente na ausência legítima de despesas.
- [ ] 3.3 Implementar leitura agrupada em lote, com todos os grupos presentes, `other` incluída, nenhuma categoria artificial com zero e soma geral reconciliada com os grupos no mesmo statement/snapshot.
- [ ] 3.4 Garantir ordenação por total numérico exato decrescente e identificador alfabético no empate; verificar que a comparação não é lexical nem baseada no percentual arredondado.
- [ ] 3.5 Garantir que a consulta não carrega despesas individuais, não percorre páginas de Expense, não consulta usuários, não faz uma query por categoria e não usa cache ou estado analítico persistido.
- [ ] 3.6 Verificar o mecanismo de snapshot do statement e tratamento de escrita concorrente; se forem necessários múltiplos statements dependentes, revisar o desenho e garantir explicitamente o isolamento antes de prosseguir.

## 4. Orquestrar o resumo na Application

- [ ] 4.1 Implementar `GetExpenseMetricsUseCase` concreto, obtendo a conta exclusivamente por `Core\Application\Ports\UserPort` e passando o proprietário explicitamente ao Port, com DI nomeada por papel e ordem arquitetural.
- [ ] 4.2 Resolver o período efetivo a partir da entrada explícita preparada pela borda, usando mês inteiro quando as datas estão ausentes; usar a mesma referência para leitura, resposta e ID, sem relógio ou config na Application.
- [ ] 4.3 Calcular percentuais finais com o total geral do mesmo snapshot, mantendo categorias com participação arredondada `"0.00"` e evitando divisão por zero no conjunto vazio.
- [ ] 4.4 Produzir ID opaco determinístico por conta, datas efetivas e modo, independente de valores, ordem/espaços de filtros e origem explícita/default do período; não persistir ID nem expor a conta bruta.
- [ ] 4.5 Produzir Output final com datas canônicas, total exato e semântica de presença de categorias, sem serialização JSON:API ou configuração de gráficos na Application.

## 5. Implementar a borda de query e resposta HTTP

- [ ] 5.1 Implementar inspeção da query original na Presentation para conservar presença, nomes decodificados e multiplicidade antes de normalizações destrutivas; não adicionar parser externo ou middleware global.
- [ ] 5.2 Rejeitar nomes desconhecidos, aliases normalizados, bracket notation de arrays/mapas, mistura de estruturas e duplicatas, inclusive valores iguais e nomes encoded equivalentes; identificar o filtro em `source.parameter`.
- [ ] 5.3 Implementar trim externo somente dos valores escalares; manter valores vazios, somente espaços ou convertidos em `null` por middleware como presentes e inválidos.
- [ ] 5.4 Implementar par obrigatório de datas quando presentes, calendário/formato estritos, limites inclusivos e ordem; aceitar dia único, futuros e vários anos sem teto de duração, sem completar ou inverter filtros.
- [ ] 5.5 Implementar `group_by` fechado em `category`, ausência como total simples e erro para vazio/demais valores; impedir que corpo de GET seja usado como fonte de filtros.
- [ ] 5.6 Implementar erros `422` no padrão de query de Insights com `title: "Parâmetro inválido"`, `detail`, `status: "422"`, `source.parameter` e media type JSON:API, sem alterar o handler global de documentos.
- [ ] 5.7 Implementar Controller fino, com referência civil resolvida uma única vez pelo timezone da aplicação na borda, sem consulta a banco ou regra monetária no Controller.
- [ ] 5.8 Implementar `ExpenseMetricsResponse` com o recurso first-party JSON:API, `type: "expense-metrics"`, ID string, `data` singular e atributos aprovados; omitir `categories` sem agrupamento e `currency` em ambos os modos.
- [ ] 5.9 Implementar `200` para período válido vazio com total `"0"`, lista `[]` somente no agrupado e período sempre exposto; preservar erro operacional explícito sem fallback para zero.

## 6. Conectar a feature à aplicação

- [ ] 6.1 Registrar provider com o binding do Port para o Adapter, reutilizando o binding de identidade de Core e sem registrar concretos desnecessários.
- [ ] 6.2 Registrar somente `GET /api/metrics/expenses` no contexto e composition root, com autenticação, metadados autenticados, conta ativa, e-mail verificado, throttle compartilhado e extensão de sessão existentes.
- [ ] 6.3 Atualizar `ARCHITECTURE.md` para reconhecer o ownership de Metrics, sua integração somente de leitura e aritmética pura exata; não reintroduzir funcionalidades inferidas ou dependências cross-context.
- [x] 6.4 Atualizar o reconhecimento de Metrics nas verificações de fronteira já existentes, se autorizado, sem abrir allowlist para classes de Expense, Identity ou Insights.

## 7. Verificar os requisitos com evidências autorizadas

- [ ] 7.1 Verificar períodos explícitos e padrão, timezone/virada do mês, fevereiro bissexto/não bissexto, dia único, inclusividade, futuro e vários anos; mapear resultados aos cenários de período.
- [ ] 7.2 Verificar a matriz inteira de filtros inválidos com e sem despesas, incluindo ausência parcial, vazio/trim, datas inexistentes/invertidas, valores não escalares, nomes desconhecidos e agrupamentos não suportados, sem leitura analítica em `422`.
- [ ] 7.3 Verificar duplicatas com a query textual original: diferentes, iguais, encoded equivalentes e array seguido de escalar. Evidência construída somente com array parsed é insuficiente para comprovar esse requisito.
- [ ] 7.4 Verificar isolamento entre contas, todos os grupos presentes, `other`, ordenação numérica/empates, soma acima de inteiro nativo e ausência de query por categoria; verificar integridade do schema consumido.
- [x] 7.5 Verificar percentuais de 60%, 16,665%, terços, 100% e participação mínima arredondada para zero, preservação de precisão e exemplos de soma exibida 99,99%/100,01%.
- [ ] 7.6 Verificar reconciliação monetária e garantia de snapshot, distinguindo prova de statement único de teste efetivo com escrita concorrente; não declarar cobertura de concorrência a partir de chamadas sequenciais.
- [ ] 7.7 Verificar atualização após criação, edição de valor/data/categoria e exclusão confirmadas, sem cache; verificar falha operacional explícita sem total zero fabricado.
- [ ] 7.8 Verificar JSON:API singular, campos/tipos, datas efetivas, omissão versus lista vazia, moeda omitida, IDs equivalentes/ distintos, erro de query completo, autenticação e demais proteções herdadas.
- [ ] 7.9 Verificar fronteiras de contexto e pureza de Domain/Application com os mecanismos existentes autorizados; confirmar que a query não altera despesas.
- [ ] 7.10 Medir a consulta afetada no Lerd, habilitando captura e examinando plano e `optimize_route` após chamadas representativas, sem prometer escala a partir de amostras pequenas nem adicionar cache/índices sem evidência.

## 8. Consolidar evidências e finalizar a implementação autorizada

- [ ] 8.1 Executar Laravel Pint com `--dirty --format agent` após mudanças PHP e as verificações estreitas apropriadas; ampliar somente se alterações compartilhadas ou achados justificarem.
- [ ] 8.2 Atualizar a matriz abaixo com caminhos/comandos, resultados e limitações reais para cada requisito/cenário; marcar tarefas somente após verificação correspondente.
- [ ] 8.3 Validar OpenSpec estritamente, revisar consistência entre proposal/design/spec/tasks e aplicar o quality gate pertinente à implementação antes de declarar entrega ou archive readiness.
- [ ] 8.4 Apresentar evidências e eventuais pendências ao usuário; sincronizar/arquivar somente quando solicitado e autorizado, sem confundir artefatos completos com implementação concluída.

## Matriz de rastreabilidade planejada

Esta tabela identifica evidências esperadas para os requisitos e todos os cenários dentro de cada bloco. A etapa autorizada de Domain fornece as evidências parciais indicadas abaixo; as demais continuam planejadas. Testes são níveis preferidos de evidência quando sua criação/uso estiver autorizado; as tarefas não concedem essa autorização por si mesmas.

| Blocos de requisitos da spec | Tarefas | Evidência preferida futura | Estado atual |
| --- | --- | --- | --- |
| Contexto dedicado; dados para gráficos sem acoplamento | 2.1, 2.3–2.4, 6.3–6.4, 7.9 | Verificação arquitetural e revisão de fronteiras/contratos. | Parcial: Metrics Domain isolado em `ContextBoundariesTest.php`; contratos e demais camadas pendentes. |
| Rota GET com dois modos; JSON:API singular | 5.7–5.9, 6.2, 7.8 | Verificação HTTP com respostas completas de ambos os modos. | Não comprovado; somente especificado. |
| Acesso autenticado e proteções existentes | 6.2, 7.8 | Verificação HTTP de `401`, `403`, política de e-mail, cota e sessão. | Não comprovado; somente especificado. |
| Isolamento pela conta | 3.1, 4.1, 7.4, 7.8 | Integração do Adapter/HTTP com duas contas e mesmos período/categorias. | Não comprovado; somente especificado. |
| Mês inteiro; timezone; presença conjunta; formato; ordem; futuros/duração | 2.2, 4.2, 5.4, 5.7, 7.1–7.2 | Invariantes puras e verificações HTTP com relógio controlado e limites inclusivos. | Parcial: `tests/Unit/Core/Domain/ValueObjects/DatePeriodCalendarTest.php` e `DatePeriodValueObjectTest.php` provam calendário, extremos, ordem, inclusividade e mês inteiro por referência explícita; relógio da borda, presença e HTTP pendentes. |
| Normalização; vazios; group_by fechado; allowlist; estruturas; repetição | 5.1–5.6, 7.2–7.3 | Verificação HTTP preservando a query textual original e a presença após middleware. | Não comprovado; somente especificado. |
| Validação independente dos dados | 5.1–5.6, 7.2 | `422` para conta vazia e comprovação de ausência de leitura analítica. | Não comprovado; somente especificado. |
| occurred_on; estado atual; total exato | 3.1–3.2, 7.4, 7.7 | Integração PostgreSQL com registros nos limites, retroativos/futuros e soma acima do inteiro nativo. | Não comprovado; somente especificado. |
| Categorias presentes; ordenação | 3.3–3.4, 7.4 | Integração com todas as categorias, `other`, empate e valores de dígitos distintos. | Não comprovado; somente especificado. |
| Percentuais exatos; arredondamento independente | 2.5, 4.3, 7.5 | Verificação pura de aritmética e reconciliação da representação HTTP. | Comprovado no Domain pelos testes de `CentsValueObject` e `RatioValueObject` em `tests/Unit/Core/Domain/ValueObjects/`, incluindo overflow e 99,99%/100,01%; integração/representação HTTP pendentes. |
| Mesmo snapshot | 3.3, 3.6, 7.6 | Evidência de um statement PostgreSQL; prova concorrente adicional se autorizada e executada. | Não comprovado; somente especificado. |
| Período vazio | 3.2–3.3, 4.3, 5.9, 7.8 | Verificação HTTP de zero, recurso singular e omissão/`[]`. | Não comprovado; somente especificado. |
| Identidade determinística | 4.4, 7.8 | Verificação por conta/período/modo, default equivalente, ordem/trim e alteração de valores. | Não comprovado; somente especificado. |
| Erros de query existentes | 5.6, 7.8 | Comparação com padrão de Insights e verificação HTTP de campos/media type/status. | Não comprovado em Metrics; padrão existente conferido para a spec. |
| Sem cache/estado; agregação em lote | 3.5, 7.4, 7.7, 7.10 | Contagem de statements, leituras sucessivas após confirmação e observabilidade Lerd. | Não comprovado; somente especificado. |
| Falhas operacionais explícitas | 5.9, 7.7 | Verificação de indisponibilidade/falha sem fallback de sucesso e sem dados internos no erro. | Não comprovado; somente especificado. |

## Critérios para encerrar a fase de especificação

- Proposal declara a capacidade que tem delta spec correspondente.
- Todas as decisões confirmadas constam da tabela do design e de requisitos/cenários verificáveis.
- Exemplos de totais e percentuais reconciliam aritmeticamente, exceto a diferença de arredondamento explicitamente admitida.
- Erros de query incluem o título correto e `source.parameter`, conforme o padrão conferido de Insights.
- Nenhuma implementação, verificação da aplicação ou tarefa futura é declarada concluída.
- `openspec validate add-expense-metrics --type change --strict --json --no-interactive` passa.

## Critérios para encerrar a implementação futura

- O gate de autorização foi cumprido e o escopo de evidência foi respeitado.
- Tarefas aplicáveis estão verificadas e marcadas individualmente com evidências reais.
- Todos os cenários têm evidência ou limitação explícita; nenhuma limitação é escondida por checklist marcado.
- Soma monetária exata, isolamento e snapshot estão comprovados no nível apropriado.
- Duplicatas são verificadas na query original e não somente por arrays já normalizados.
- Contrato HTTP, campos omitidos, erros e políticas herdadas estão verificados.
- Pint, checks pertinentes, documentação arquitetural e validação OpenSpec estão concluídos.
- Ausência de prova de escala, concorrência ativa ou integração do front é declarada quando aplicável, sem afirmar cobertura inexistente.

## Evidências da primeira etapa: Domain e testes

- Escopo autorizado: Domain de Metrics e seus testes, com reconhecimento do novo contexto nas verificações arquiteturais. PHP 8.5, `brick/math` 1.0.0 e Pest 5.2.1 confirmados pelo Boost.
- Implementação inicial: tipos locais de período, centavos e percentual em Metrics, posteriormente consolidados em `app/Core/Domain/` por autorização explícita para normalizar os VOs repetidos. `app/Metrics/Domain/` conserva o enum de modos internos `total`/`category`. A validação HTTP de `group_by` permanece pendente: o modo interno `total` não é um novo valor permitido de query.
- `lerd` MCP `vendor_run pest tests/Unit/Metrics --compact`: **92 testes, 296 assertions, todos passando**.
- `lerd` MCP `vendor_run pint --dirty --format agent`: **passou**.
- Após Pint: `vendor_run pest tests/Unit/Metrics tests/Unit/Architecture/ContextBoundariesTest.php --compact`: **114 testes, 542 assertions, todos passando**.
- `openspec validate add-expense-metrics --type change --strict --json --no-interactive`: **passou, sem issues**. `git diff --check`: **passou**. Quality gate desta etapa: invariantes puras e isolamento arquitetural comprovados; evidências das demais camadas permanecem pendentes.
- Datas civis aceitas de `0001-01-01` a `9999-12-31`; ano zero, calendário inexistente e formatos não canônicos rejeitados. Isso comprova tipos puros, não o transporte do driver PostgreSQL.
- Tarefas 1.3, 6.3, 7.1 e 7.9 permanecem abertas por incluírem verificações ou implementação além desta etapa. A permissão de Brick Math e a introdução de Metrics Domain estão documentadas em `ARCHITECTURE.md`.
- Application, Adapter, snapshot, isolamento por conta, query original, contrato HTTP, autenticação, observabilidade e concorrência permanecem sem evidência nesta etapa. A mudança completa não está pronta para arquivamento.

## Normalização autorizada dos Value Objects compartilhados

- Inventário: 11 Value Objects em Identity, Insights e Metrics. Centavos e períodos tinham implementações repetidas; razões e percentuais repetiam a aritmética de participação, com diferenças de limite e precisão preservadas na API compartilhada.
- `CentsValueObject`, `DatePeriodValueObject` e `RatioValueObject` agora pertencem a `Core/Domain`, com exceções independentes dos consumidores. Os seis tipos locais anteriores foram substituídos por esses três tipos normalizados.
- `RatioValueObject::fromAmounts()` aceita variações acima de 100%; `fromShare()` valida parcela limitada ao total. `roundedPercent()` preserva zero casas para Insights; `roundedPercent(decimalPlaces: 2)` atende Metrics, sem arredondamento intermediário.
- Os testes puros de ambos os contextos foram migrados para `tests/Unit/Core/Domain/ValueObjects/`. Os consumidores de Insights foram atualizados, sem aliases para os nomes antigos.
- Verificação inicial de Core Domain e Insights Unit: **369 testes, 1668 assertions, passando**. Fronteiras arquiteturais: **23 testes, 247 assertions, passando**, incluindo a pureza de Core Domain e allowlist explícita de tipos compartilhados.
- Após Pint, suíte completa via `vendor_run pest --compact`: **587 testes, 586 passando, 3292 assertions**. Uma falha em `tests/Feature/Insights/ExpenseAnalysisAdapterTest.php:179`: o teste espera o trecho `dois meses anteriores`, enquanto o catálogo editorial modificado antes desta normalização usa `dois anteriores`. A normalização preserva o catálogo e a expectativa editorial existente; a suíte completa não está verde.
- `vendor_run pint --dirty --format agent`, validação OpenSpec estrita e `git diff --check` executados. Busca nos arquivos PHP do projeto não encontrou referências aos seis nomes antigos nem às exceções removidas. `migrate:status` confirmou ausência de migrations pendentes.
