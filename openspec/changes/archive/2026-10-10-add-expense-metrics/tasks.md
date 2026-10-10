## 1. Autorizar e preparar a implementação futura

- [x] 1.1 Obter autorização explícita para implementar/apply. Autorização recebida para Domain, normalização de VOs, Application, Adapter, Presentation e composição HTTP.
- [x] 1.2 Confirmar o escopo de verificação autorizado. Testes puros de Domain/Application, integração PostgreSQL do Adapter, HTTP e verificações existentes de fronteira.
- [x] 1.3 Reconsultar versões, documentação Laravel/JSON:API, schema de `expenses`, conexões, índices e grupo de proteções das rotas analíticas com os MCPs/Artisan apropriados; documentar qualquer divergência relevante antes de alterar o desenho.

## 2. Estabelecer Metrics e seus contratos puros

- [x] 2.1 Introduzir somente as camadas necessárias de `app/Metrics/`, preservando o ownership de fatos quantitativos e ausência de imports de Expense, Identity e Insights, conforme o requisito de contexto dedicado.
- [x] 2.2 Definir tipos puros mínimos para período civil inclusivo e modo de agrupamento, protegendo datas reais, ordem e dia único também fora de HTTP; manter relógio/timezone fora de Domain e Application.
- [x] 2.3 Definir `ExpenseMetricsPort` com proprietário, período e modo explícitos e projeção própria tipada; não expor Model, Builder, connection, collection Laravel ou Output HTTP no contrato.
- [x] 2.4 Definir Input/Outputs próprios em `Application/Data`, `final readonly`, constructor-only, distinguindo agrupamento ausente de agrupamento presente e vazio, sem carriers redundantes por conveniência.
- [x] 2.5 Definir aritmética exata de centavos e percentual com duas casas/half-up em tipos puros, sem overflow, float, arredondamento intermediário ou correção artificial da soma de percentuais; usar somente dependência pura já instalada e atualizar a permissão arquitetural pertinente.

## 3. Implementar a leitura analítica PostgreSQL

- [x] 3.1 Implementar `ExpenseMetricsAdapter` sobre o schema compartilhado, somente leitura de `user_id`, `occurred_on`, `amount` e `category`, com filtro obrigatório por proprietário antes de agregação e limites inclusivos.
- [x] 3.2 Implementar total simples por soma exata no banco, preservando string canônica inclusive acima de `PHP_INT_MAX` e retornando `"0"` somente na ausência legítima de despesas.
- [x] 3.3 Implementar leitura agrupada em lote, com todos os grupos presentes, `other` incluída, nenhuma categoria artificial com zero e soma geral reconciliada com os grupos no mesmo statement/snapshot.
- [x] 3.4 Garantir ordenação por total numérico exato decrescente e identificador alfabético no empate; verificar que a comparação não é lexical nem baseada no percentual arredondado.
- [x] 3.5 Garantir que a consulta não carrega despesas individuais, não percorre páginas de Expense, não consulta usuários, não faz uma query por categoria e não usa cache ou estado analítico persistido.
- [x] 3.6 Verificar o mecanismo de snapshot do statement e tratamento de escrita concorrente; statement único verificado e semântica READ COMMITTED conferida na documentação PostgreSQL 16. A prova experimental de escrita durante a leitura permanece aberta em 7.6.

## 4. Orquestrar o resumo na Application

- [x] 4.1 Implementar `GetExpenseMetricsUseCase` concreto, obtendo a conta exclusivamente por `Core\Application\Ports\UserPort` e passando o proprietário explicitamente ao Port, com DI nomeada por papel e ordem arquitetural.
- [x] 4.2 Receber o período efetivo validado no Input, preparado explicitamente pela borda com `fromDates()` ou `monthContaining()` para o mês inteiro; conservar o mesmo período na leitura, saída e ID, sem relógio ou config na Application. A resolução de relógio/timezone na borda continua na tarefa 5.7.
- [x] 4.3 Calcular percentuais finais com o total geral da mesma projeção do Port, mantendo categorias com participação arredondada `"0.00"` e evitando divisão por zero no conjunto vazio. A prova do snapshot PostgreSQL continua nas tarefas 3.6 e 7.6.
- [x] 4.4 Produzir ID opaco determinístico por conta, datas efetivas e modo, independente de valores e origem explícita/default do período; não persistir ID nem expor a conta bruta. Normalização e ordem de filtros HTTP permanecem na Presentation.
- [x] 4.5 Produzir Output final com período de datas canônicas, total exato e semântica de presença de categorias, sem serialização JSON:API ou configuração de gráficos na Application.

## 5. Implementar a borda de query e resposta HTTP

- [x] 5.1 Implementar inspeção da query original na Presentation para conservar presença, nomes decodificados e multiplicidade antes de normalizações destrutivas; não adicionar parser externo ou middleware global.
- [x] 5.2 Rejeitar nomes desconhecidos, aliases normalizados, bracket notation de arrays/mapas, mistura de estruturas e duplicatas, inclusive valores iguais e nomes encoded equivalentes; identificar o filtro em `source.parameter`.
- [x] 5.3 Implementar trim externo somente dos valores escalares; manter valores vazios, somente espaços ou convertidos em `null` por middleware como presentes e inválidos.
- [x] 5.4 Implementar par obrigatório de datas quando presentes, calendário/formato estritos, limites inclusivos e ordem; aceitar dia único, futuros e vários anos sem teto de duração, sem completar ou inverter filtros.
- [x] 5.5 Implementar `group_by` fechado em `category`, ausência como total simples e erro para vazio/demais valores; impedir que corpo de GET seja usado como fonte de filtros.
- [x] 5.6 Implementar erros `422` no padrão de query de Insights com `title: "Parâmetro inválido"`, `detail`, `status: "422"`, `source.parameter` e media type JSON:API, sem alterar o handler global de documentos.
- [x] 5.7 Implementar Controller fino, com referência civil resolvida uma única vez pelo timezone da aplicação na borda, sem consulta a banco ou regra monetária no Controller.
- [x] 5.8 Implementar `ExpenseMetricsResponse` com o recurso first-party JSON:API, `type: "expense-metrics"`, ID string, `data` singular e atributos aprovados; omitir `categories` sem agrupamento e `currency` em ambos os modos.
- [x] 5.9 Implementar `200` para período válido vazio com total `"0"`, lista `[]` somente no agrupado e período sempre exposto; preservar erro operacional explícito sem fallback para zero.

## 6. Conectar a feature à aplicação

- [x] 6.1 Registrar provider com o binding do Port para o Adapter, reutilizando o binding de identidade de Core e sem registrar concretos desnecessários.
- [x] 6.2 Registrar somente `GET /api/metrics/expenses` no contexto e composition root, com autenticação, metadados autenticados, conta ativa, e-mail verificado, throttle compartilhado e extensão de sessão existentes.
- [x] 6.3 Atualizar `ARCHITECTURE.md` para reconhecer o ownership de Metrics, sua integração somente de leitura e aritmética pura exata; não reintroduzir funcionalidades inferidas ou dependências cross-context.
- [x] 6.4 Atualizar o reconhecimento de Metrics nas verificações de fronteira já existentes, se autorizado, sem abrir allowlist para classes de Expense, Identity ou Insights.

## 7. Verificar os requisitos com evidências autorizadas

- [ ] 7.1 Verificar períodos explícitos e padrão, timezone/virada do mês, fevereiro bissexto/não bissexto, dia único, inclusividade, futuro e vários anos; mapear resultados aos cenários de período.
- [x] 7.2 Verificar a matriz inteira de filtros inválidos com e sem despesas, incluindo ausência parcial, vazio/trim, datas inexistentes/invertidas, valores não escalares, nomes desconhecidos e agrupamentos não suportados, sem leitura analítica em `422`.
- [x] 7.3 Verificar duplicatas com a query textual original: diferentes, iguais, encoded equivalentes e array seguido de escalar. Evidência construída somente com array parsed é insuficiente para comprovar esse requisito.
- [x] 7.4 Verificar isolamento entre contas, todos os grupos presentes, `other`, ordenação numérica/empates, soma acima de inteiro nativo e ausência de query por categoria; verificar integridade do schema consumido.
- [x] 7.5 Verificar percentuais de 60%, 16,665%, terços, 100% e participação mínima arredondada para zero, preservação de precisão e exemplos de soma exibida 99,99%/100,01%.
- [ ] 7.6 Verificar reconciliação monetária e garantia de snapshot, distinguindo prova de statement único de teste efetivo com escrita concorrente; não declarar cobertura de concorrência a partir de chamadas sequenciais.
- [x] 7.7 Verificar atualização após criação, edição de valor/data/categoria e exclusão confirmadas, sem cache; verificar falha operacional explícita sem total zero fabricado. Comprovado no Adapter PostgreSQL; tradução HTTP permanece em 5.9/7.8.
- [ ] 7.8 Verificar JSON:API singular, campos/tipos, datas efetivas, omissão versus lista vazia, moeda omitida, IDs equivalentes/ distintos, erro de query completo, autenticação e demais proteções herdadas.
- [x] 7.9 Verificar fronteiras de contexto e pureza de Domain/Application com os mecanismos existentes autorizados; confirmar que a query não altera despesas. Comprovado nas camadas implementadas; repetir ao introduzir Presentation/composição.
- [ ] 7.10 Medir a consulta afetada no Lerd, habilitando captura e examinando plano e `optimize_route` após chamadas representativas, sem prometer escala a partir de amostras pequenas nem adicionar cache/índices sem evidência.

## 8. Consolidar evidências e finalizar a implementação autorizada

- [ ] 8.1 Executar Laravel Pint com `--dirty --format agent` após mudanças PHP e as verificações estreitas apropriadas; ampliar somente se alterações compartilhadas ou achados justificarem.
- [ ] 8.2 Atualizar a matriz abaixo com caminhos/comandos, resultados e limitações reais para cada requisito/cenário; marcar tarefas somente após verificação correspondente.
- [ ] 8.3 Validar OpenSpec estritamente, revisar consistência entre proposal/design/spec/tasks e aplicar o quality gate pertinente à implementação antes de declarar entrega ou archive readiness.
- [x] 8.4 Apresentar evidências e eventuais pendências ao usuário; sincronizar/arquivar somente quando solicitado e autorizado, sem confundir artefatos completos com implementação concluída. Usuário confirmou funcionamento em teste manual e solicitou explicitamente o arquivamento, ciente das pendências apresentadas.

## Matriz de rastreabilidade planejada

### Decisão de encerramento

O usuário informou que testou a feature e confirmou seu funcionamento, autorizando explicitamente sincronizar e arquivar esta mudança. A última suíte executada passou com 725 testes e 4588 assertions, além de Pint e validação OpenSpec estrita. As evidências HTTP implementadas constam da seção Presentation abaixo; referências a HTTP pendente na matriz original representam o planejamento anterior e devem ser lidas junto dessa seção.

O arquivamento é uma decisão explícita de encerramento, não uma nova prova dos cenários ainda não executados: travessia de mês durante execução (7.1), escrita concorrente durante leitura (7.6), cota/extensão de sessão especificamente em Metrics (7.8) e observabilidade analítica autenticada representativa no Lerd (7.10). Essas tarefas permanecem desmarcadas para conservar a rastreabilidade das limitações aceitas; nenhuma cobertura adicional é inferida do teste manual informado.

Esta tabela identifica evidências esperadas para os requisitos e todos os cenários dentro de cada bloco. A etapa autorizada de Domain fornece as evidências parciais indicadas abaixo; as demais continuam planejadas. Testes são níveis preferidos de evidência quando sua criação/uso estiver autorizado; as tarefas não concedem essa autorização por si mesmas.

| Blocos de requisitos da spec | Tarefas | Evidência preferida futura | Estado atual |
| --- | --- | --- | --- |
| Contexto dedicado; dados para gráficos sem acoplamento | 2.1, 2.3–2.4, 6.3–6.4, 7.9 | Verificação arquitetural e revisão de fronteiras/contratos. | Domain e Application verificados por `ContextBoundariesTest.php`, incluindo Data imutáveis e dependência explícita de `UserPort`; demais camadas pendentes. |
| Rota GET com dois modos; JSON:API singular | 5.7–5.9, 6.2, 7.8 | Verificação HTTP com respostas completas de ambos os modos. | Não comprovado; somente especificado. |
| Acesso autenticado e proteções existentes | 6.2, 7.8 | Verificação HTTP de `401`, `403`, política de e-mail, cota e sessão. | Não comprovado; somente especificado. |
| Isolamento pela conta | 3.1, 4.1, 7.4, 7.8 | Integração do Adapter/HTTP com duas contas e mesmos período/categorias. | Application e SQL comprovados: duas contas com despesas coincidentes, conta vazia diante de terceiros e bindings de proprietário; HTTP pendente. |
| Mês inteiro; timezone; presença conjunta; formato; ordem; futuros/duração | 2.2, 4.2, 5.4, 5.7, 7.1–7.2 | Invariantes puras e verificações HTTP com relógio controlado e limites inclusivos. | Parcial: `tests/Unit/Core/Domain/ValueObjects/DatePeriodCalendarTest.php` e `DatePeriodValueObjectTest.php` provam calendário, extremos, ordem, inclusividade e mês inteiro por referência explícita; relógio da borda, presença e HTTP pendentes. |
| Normalização; vazios; group_by fechado; allowlist; estruturas; repetição | 5.1–5.6, 7.2–7.3 | Verificação HTTP preservando a query textual original e a presença após middleware. | Não comprovado; somente especificado. |
| Validação independente dos dados | 5.1–5.6, 7.2 | `422` para conta vazia e comprovação de ausência de leitura analítica. | Não comprovado; somente especificado. |
| occurred_on; estado atual; total exato | 3.1–3.2, 7.4, 7.7 | Integração PostgreSQL com registros nos limites, retroativos/futuros e soma acima do inteiro nativo. | Comprovado no Adapter em ambos os modos: limites inclusivos, timestamps distintos, soma geral/categoria acima de inteiro nativo, datas extremas e atualizações confirmadas. |
| Categorias presentes; ordenação | 3.3–3.4, 7.4 | Integração com todas as categorias, `other`, empate e valores de dígitos distintos. | Application e SQL comprovados: todas as categorias, `other`, ausência de grupos artificiais, empates e ordenação numérica de valores com dígitos distintos. |
| Percentuais exatos; arredondamento independente | 2.5, 4.3, 7.5 | Verificação pura de aritmética e reconciliação da representação HTTP. | Comprovado no Domain pelos testes de `AmountValueObject` e `RatioValueObject` em `tests/Unit/Core/Domain/ValueObjects/`, incluindo overflow e 99,99%/100,01%; integração/representação HTTP pendentes. |
| Mesmo snapshot | 3.3, 3.6, 7.6 | Evidência de um statement PostgreSQL; prova concorrente adicional se autorizada e executada. | Statement único e reconciliação exata comprovados; semântica de snapshot documentada pelo PostgreSQL 16. Não houve teste de escrita concorrente durante a execução. |
| Período vazio | 3.2–3.3, 4.3, 5.9, 7.8 | Verificação HTTP de zero, recurso singular e omissão/`[]`. | Application e SQL comprovados: zero e ausência de grupos artificiais, inclusive com despesas de terceiros; omissão HTTP pendente. |
| Identidade determinística | 4.4, 7.8 | Verificação por conta/período/modo, default equivalente, ordem/trim e alteração de valores. | Application comprovada por conta, ambos os limites, modo, período default equivalente e alteração de fatos; ordem/trim de filtros HTTP pendentes. |
| Erros de query existentes | 5.6, 7.8 | Comparação com padrão de Insights e verificação HTTP de campos/media type/status. | Não comprovado em Metrics; padrão existente conferido para a spec. |
| Sem cache/estado; agregação em lote | 3.5, 7.4, 7.7, 7.10 | Contagem de statements, leituras sucessivas após confirmação e observabilidade Lerd. | Adapter comprovado por query log e novas leituras após escritas autocommit. Plano medido em amostra pequena; observabilidade HTTP pendente. |
| Falhas operacionais explícitas | 5.9, 7.7 | Verificação de indisponibilidade/falha sem fallback de sucesso e sem dados internos no erro. | Application e Adapter comprovados: falhas propagam e erros SQL reais não retornam zero. Indisponibilidade de serviço e tratamento HTTP pendentes. |

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
- `AmountValueObject`, `DatePeriodValueObject` e `RatioValueObject` agora pertencem a `Core/Domain`, com exceções independentes dos consumidores. Os seis tipos locais anteriores foram substituídos por esses três tipos normalizados.
- `RatioValueObject::fromAmounts()` aceita variações acima de 100%; `fromShare()` valida parcela limitada ao total. `roundedPercent()` preserva zero casas para Insights; `roundedPercent(decimalPlaces: 2)` atende Metrics, sem arredondamento intermediário.
- Os testes puros de ambos os contextos foram migrados para `tests/Unit/Core/Domain/ValueObjects/`. Os consumidores de Insights foram atualizados, sem aliases para os nomes antigos.
- Verificação inicial de Core Domain e Insights Unit: **369 testes, 1668 assertions, passando**. Fronteiras arquiteturais: **23 testes, 247 assertions, passando**, incluindo a pureza de Core Domain e allowlist explícita de tipos compartilhados.
- Após Pint, suíte completa via `vendor_run pest --compact`: **587 testes, 586 passando, 3292 assertions**. Uma falha em `tests/Feature/Insights/ExpenseAnalysisAdapterTest.php:179`: o teste espera o trecho `dois meses anteriores`, enquanto o catálogo editorial modificado antes desta normalização usa `dois anteriores`. A normalização preserva o catálogo e a expectativa editorial existente; a suíte completa não está verde.
- `vendor_run pint --dirty --format agent`, validação OpenSpec estrita e `git diff --check` executados. Busca nos arquivos PHP do projeto não encontrou referências aos seis nomes antigos nem às exceções removidas. `migrate:status` confirmou ausência de migrations pendentes.

## Evidências da etapa Application

- Implementação em `app/Metrics/Application/`: `ExpenseMetricsPort`, `GetExpenseMetricsUseCase`, cinco Data próprios e `InvalidExpenseMetricsProjectionException`. Os Data são constructor-only; a validação da projeção é explícita no UseCase e usa as invariantes dos VOs de Core.
- `GetExpenseMetricsInput` recebe somente período efetivo e modo, sem proprietário ou relógio. `ExpenseMetricsOutput` conserva o período e representa categorias não solicitadas por `null`, distinguindo a lista agrupada vazia. A futura borda resolve defaults e serializa a omissão.
- O Port documenta leitura por conta/período inclusivo/modo, valores canônicos exatos e reconciliação no mesmo snapshot. O UseCase faz uma chamada por execução; isso não comprova contagem de statements nem isolamento no futuro Adapter.
- `vendor_run pest tests/Unit/Metrics --compact`: **39 testes, 92 assertions, passando**, incluindo identidade, períodos equivalentes, valores acima do inteiro nativo, categorias completas/ordenadas, percentuais independentes, ID determinístico e falhas explícitas.
- `vendor_run pint --dirty --format agent`: **passou**. Após Pint: `vendor_run pest tests/Unit/Metrics tests/Unit/Core/Domain tests/Unit/Architecture/ContextBoundariesTest.php --compact`: **240 testes, 858 assertions, passando**.
- `openspec validate add-expense-metrics --type change --strict --json --no-interactive`: **passou, sem issues**. `git diff --check`: **passou**. Quality gate desta etapa: contratos puros, Data imutáveis, fronteiras e comportamento de Application verificados no nível unitário.
- A etapa não altera Core ou os fluxos existentes de Insights. A suíte completa não foi repetida; a evidência histórica e sua divergência editorial continuam registradas acima, sem inferir o estado atual de testes não executados.
- Infrastructure, Presentation, bindings, SQL/snapshot, isolamento real, validação da query original, timezone da borda e observabilidade continuam pendentes; a mudança completa não está pronta para arquivamento.

## Extração autorizada do catálogo de categorias

- `ExpenseCategoryEnum` foi movido de Expense para `Core/Domain/Enums`, preservando todos os cases e valores persistidos. Os consumidores existentes, o seeder e seus testes usam o novo namespace.
- `GetExpenseMetricsUseCase` valida os identificadores com `ExpenseCategoryEnum::tryFrom()`, sem a lista local duplicada. A ordenação conserva a arrow function estática e os mesmos critérios.
- Arquitetura, design e spec reconhecem o catálogo compartilhado; as verificações de fronteira permitem somente o enum explícito, sem imports entre contextos de negócio.
- A expectativa existente de totais por categoria no teste de Metrics foi alinhada à propriedade `totalAmount` do Output.
- Após Pint, `vendor_run pest tests/Unit/Metrics tests/Unit/Expense tests/Unit/Architecture/ContextBoundariesTest.php tests/Feature/Expense/ExpenseClassificationTest.php tests/Feature/Expense/Infrastructure/Repositories/Cache/CachedExpenseCategorizationRepositoryTest.php --compact`: **116 testes, 712 assertions, passando**. A suíte completa não foi repetida.

## Evidências da etapa Infrastructure PostgreSQL

- Autorização recebida para o próximo step apresentado: Adapter Infrastructure e testes de integração PostgreSQL. Presentation, provider e rota permanecem nas próximas etapas.
- Preflight: Boost confirmou PHP 8.5/Laravel 13.34.0 e conexão padrão `pgsql`; PostgreSQL **16.10**, isolamento **READ COMMITTED**. Schema conferido: `amount bigint`, `occurred_on date`, `category varchar(32)` e `user_id bigint` não nulos, FK de proprietário e índices `(user_id, occurred_on)` e `(user_id, occurred_on, id)`. Não há constraints CHECK de valor/categoria no banco; as invariantes pertencem a Expense e a Application valida a projeção. Nenhuma divergência exige migration nesta etapa.
- `migrate:status --no-interaction`: nenhuma migration pendente. `route:list --path=api/insights -vv --json` confirmou Sanctum, metadados autenticados, throttle `api.authenticated`, bindings, conta ativa, e-mail verificado e extensão de sessão. Documentação Laravel 13 de Query Builder/JSON:API consultada via Boost.
- Implementação: `app/Metrics/Infrastructure/Adapters/ExpenseMetricsAdapter.php`, sem imports de Expense/Identity/Insights, modelos próprios, cache, escrita ou bindings antecipados. Uma agregação por execução; `SUM(SUM(amount)) OVER ()` obtém o total agrupado e `CAST(... AS text)` conserva precisão. A ordenação SQL usa a soma numérica antes da conversão textual.
- Testes: `tests/Feature/Metrics/Infrastructure/Adapters/ExpenseMetricsAdapterTest.php`. Executados no banco exclusivo `trocado_testing`, protegido pelo `Tests\TestCase`. **15 testes, 52 assertions, passando**: ambos os modos, terceiros/conta vazia, limites inclusivos, timestamps independentes, todas as categorias/`other`, empates/ordenação numérica, total de categoria `12000000000000000000`, total geral `12000000000000000001`, reconciliação exata, dia único, futuro, bissexto, vários anos e extremos `0001-01-01`/`9999-12-31`.
- Query log comprova statement único, bindings explícitos e ausência de query por categoria; comparação dos registros antes/depois comprova leitura sem alterações. Escritas autocommit entre consultas comprovam atualização após criação, valor/categoria/data e exclusão. Rename transacional de coluna, revertido em `finally`, produz erro SQL real e comprova propagação em ambos os modos, sem zero fabricado.
- Snapshot: mecanismo conferido na documentação oficial PostgreSQL 16, seção 13.2.1 (`https://www.postgresql.org/docs/16/transaction-iso.html`): SELECT sem `FOR UPDATE/SHARE` usa o snapshot do início do statement. Statement único mais janela elimina mistura de versões entre grupos/total. **Não foi executado teste de criação ou recategorização confirmada durante a consulta**; 7.6 continua aberta para distinguir essa limitação da reconciliação já comprovada.
- `vendor_run pint --dirty --format agent`: **passou**. Após Pint, `vendor_run pest tests/Feature/Metrics tests/Unit/Metrics tests/Unit/Architecture/ContextBoundariesTest.php --compact`: **79 testes, 454 assertions, passando**. A suíte completa não foi repetida, pois a mudança não altera contratos compartilhados.
- Plano medido por Boost `EXPLAIN (ANALYZE, BUFFERS)` das duas consultas em amostra local de **88 despesas/9 categorias**, período civil inteiro: total simples **0,071 ms**, agrupado **0,157 ms** de execução. Ambos usam Seq Scan na tabela pequena; o agrupado usa HashAggregate/WindowAgg/Sort, com filtro de proprietário e datas antes da agregação. Não representa prova de escala e não justifica índice novo.
- Captura Lerd já habilitada (`dumps_toggle` sem mudança). `optimize_route` retornou **zero amostras e zero rotas**; sem endpoint de Metrics nesta etapa, não há evidência de tráfego HTTP. 7.10 permanece aberta para medição da futura rota.
- Quality gate desta etapa: Adapter e fronteiras comprovados; contrato HTTP, proteções de acesso, parsing da query original, timezone da borda, binding, concorrência ativa e escala permanecem pendentes. A mudança completa não está pronta para arquivamento.
- `openspec validate add-expense-metrics --type change --strict --json --no-interactive`: **passou, sem issues**. `git diff --check`: **passou**. Tarefas globais 8.1–8.4 permanecem abertas para a consolidação da implementação completa; esta seção registra os checks efetivamente executados nesta etapa.

## Evidências da etapa Presentation e composição HTTP

- Autorizado o próximo step: Request, Controller, Response, provider/rota e testes HTTP. `GetExpenseMetricsRequest` valida o `QUERY_STRING` original: separa pares, decodifica uma vez, detecta nomes desconhecidos/brackets/repetição e preserva vazios. Usa os VOs de Core para calendário; erro `422` identifica `source.parameter`. Corpo de GET não participa dos filtros.
- `GetExpenseMetricsController` resolve uma referência civil com Carbon/Config no timezone da aplicação e entrega Input explícito ao UseCase. `ExpenseMetricsResponse` usa `JsonApiResource`, ID/type próprios e atributos singulares; omite `categories` sem agrupamento, mantém `[]` no vazio agrupado e não retorna moeda.
- `MetricsServiceProvider` registrado, binding real comprovado; rota `metrics.expenses` conectada em `bootstrap/app.php`. Artisan `route:list --path=api/metrics -vv --json` confirmou todas as proteções herdadas de Insights. Não há migrations pendentes.
- `tests/Feature/Metrics/Presentation/ExpenseMetricsHttpTest.php`: **80 testes, 1077 assertions, passando** antes do último ajuste arquitetural do Controller. Dataset de 34 queries inválidas em conta vazia e com despesas, mock exigindo nenhuma leitura: nomes desconhecidos/aliases, estruturas, duplicatas iguais/diferentes/encoded, array sobrescrito por escalar, datas/vazios/trim e agrupamento fechado. Outros cenários comprovam singularidade JSON:API, identidade equivalente após trim/ordem/default, timezone São Paulo na virada UTC, fevereiro bissexto/não bissexto, futuras no mês, ausência versus lista vazia, soma acima de inteiro nativo, parcela `0.00`, isolamento entre contas, ID estável após escrita, `401`/`403` sem leitura e erro operacional sanitizado `500`.
- Após último ajuste e Pint `--dirty --format agent`, `vendor_run pest tests/Feature/Metrics tests/Unit/Metrics tests/Unit/Architecture/ContextBoundariesTest.php --compact`: **160 testes, 1532 assertions, passando**. Fronteiras permanecem fechadas; Controller usa Carbon/Config permitidos, sem abrir allowlist de helpers.
- Suíte completa executada antes do ajuste final: **724 testes, 722 passando, 4577 assertions**. O achado arquitetural do helper `now` foi corrigido e retestado. Persiste a falha editorial preexistente `tests/Feature/Insights/ExpenseAnalysisAdapterTest.php:179`, já registrada historicamente; não foi alterada por esta etapa. Não declarar suíte completa verde.
- Smoke HTTP local retornou documento `401` correto com e sem Accept. O smoke inicial revelou redirecionamento para `login` inexistente quando Accept não é enviado. Ajuste mínimo em `bootstrap/app.php` via `redirectGuestsTo` retorna null para `api/*`, permitindo ao tratamento JSON existente produzir `401`; novo teste HTTP comprova ausência de exigência adicional de header. API Laravel 13 conferida via Boost.
- Captura Lerd habilitada; `optimize_route` sem amostras analíticas autenticadas. HTTP automatizado não comprova tráfego FPM representativo. Permanecem abertas 7.1 (travessia de mês durante execução), 7.6 (escrita durante leitura), 7.8 (cota compartilhada/extensão de sessão especificamente em Metrics), 7.10 e consolidação 8.x. A implementação HTTP está entregue; a mudança completa não está pronta para arquivamento.
- Após a correção transversal e novo Pint, suíte completa repetida: **725 testes, 724 passando, 4584 assertions**, com somente a falha editorial de Insights em `ExpenseAnalysisAdapterTest.php:179`. Metrics HTTP agora tem 81 casos; todas as verificações de Metrics/fronteiras passaram nesta execução. `optimize_route` após smoke tem uma amostra, sem rotas lentas; é autenticação recusada, não medição do SQL analítico.
- Validação OpenSpec estrita e `git diff --check` passaram nesta etapa. O UseCase já tinha alteração local na ordem dos componentes do hash antes deste trabalho; essa alteração foi preservada.
