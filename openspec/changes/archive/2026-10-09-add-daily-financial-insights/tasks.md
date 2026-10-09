## 1. Fechar as decisões de produto antes de implementar

- [x] 1.1 Confirmar com o usuário o conjunto inicial de tipos, prioridades, períodos e limites numéricos propostos no design; atualizar spec e design com os valores aprovados.
- [x] 1.2 Preparar e aprovar o catálogo editorial completo, com pelo menos quatro variantes por conjunto, alternativas curtas e linguagem neutra para categorias sensíveis; cobrir os estados de onboarding.
- [x] 1.3 Revalidar a mudança estritamente após resolver as pendências e obter autorização explícita para implementar. A criação desta spec não autoriza apply, código ou testes da aplicação.

## 2. Estabelecer o contexto e seus contratos

- [x] 2.1 Introduzir Insights com as camadas necessárias, reutilizando `Core\Application\Ports\UserPort`, com `ExpenseAnalysisPort`, projeção analítica e Outputs tipados próprios, respeitando Domain puro e Application independente de framework.
- [x] 2.2 Reutilizar o adapter de identidade autenticada e o binding existentes em Core; registrar somente bindings próprios de fronteira no provider de Insights, sem importar Identity ou Expense.
- [x] 2.3 Atualizar `ARCHITECTURE.md` e as verificações arquiteturais para reconhecer Insights e seu acesso somente de leitura ao schema de despesas, sem allowlist de imports de Expense.

## 3. Consultar e interpretar os registros

- [x] 3.1 Implementar consultas agregadas por proprietário para o mês corrente e dois anteriores, mais existência histórica, sem Eloquent Models de Expense, paginação do CRUD ou uma query por regra/categoria.
- [x] 3.2 Garantir datas por ocorrência, exclusão de datas futuras, inclusão de `other`, períodos equivalentes, cálculo exato, arredondamento editorial e snapshot consistente de fatos relacionados.
- [x] 3.3 Implementar concentração por categoria e lançamento, variação do total e liderança recorrente com o perfil de elegibilidade aprovado, sem inferências de completude, economia ou excesso financeiro.
- [x] 3.4 Implementar onboarding por existência histórica e evidência recente, incluindo revisão de `other`, sem consultas a perfil ou configurações de Identity.
- [x] 3.5 Implementar priorização, desempates determinísticos, deduplicação semântica e máximo de seis candidatos, sem quantidade mínima ou preenchimento artificial.

## 4. Compor mensagens e disponibilizar a API

- [x] 4.1 Implementar o catálogo aprovado e sua interpolação de fatos; validar título de até 32 e descrição de até 110 caracteres Unicode com alternativas completas, sem truncamento de evidência.
- [x] 4.2 Implementar rotação determinística por conta, chave editorial e dia, preservando variante no mesmo dia e mudando no dia seguinte para o mesmo conjunto; não persistir histórico nem congelar valores.
- [x] 4.3 Implementar `GetInsightsUseCase` com referência civil explícita e IDs derivados, retornando Outputs próprios sem persistência, cache específico, IA, jobs ou efeitos de escrita nas despesas.
- [x] 4.4 Consultar Boost/Search Docs e o código instalado para wiring e JSON:API; disponibilizar `GET /api/insights` com as proteções HTTP existentes, rejeição de query params e `InsightResponse` com `group`, `type` e período.

## 5. Verificar o comportamento e preparar entrega

- [x] 5.1 Verificar as regras e seleção com cenários de base pequena/zero, limiares, empate, liderança incompleta, `other`, redundância e ausência de registros, conforme os requisitos da spec.
- [x] 5.2 Verificar rotação no mesmo dia, em dias consecutivos e após um ciclo; mudanças de números sem troca de variante, transições de conjunto e limites Unicode após interpolação.
- [x] 5.3 Verificar queries e projeções com contas distintas, registros retroativos/futuros, meses de durações diferentes, somas grandes e consistência de fatos relacionados; verificar leitura após edição, exclusão e recategorização confirmadas.
- [x] 5.4 Verificar contrato HTTP, autenticação e demais proteções, parâmetros rejeitados, IDs, grupos/tipos, períodos, onboarding e falha explícita de leitura, sem expor dados de outras contas.
- [x] 5.5 Executar verificações arquiteturais e medir as queries do fluxo em Lerd, examinando plano e ausência de consultas por regra/categoria; propor cache ou índices somente se houver evidência de necessidade.
- [ ] 5.6 Revisar o contrato com Flutter, incluindo mapeamento visual, fallback de tipo desconhecido e layout com fontes ampliadas; manter decisões visuais no cliente.
- [x] 5.7 Executar Pint após alterações PHP, verificações relevantes e validação OpenSpec estrita; mapear evidências aos cenários e atualizar cada tarefa somente após sua verificação.

## Evidências de encerramento do backend — 2026-10-09

| Requisitos e cenários | Evidência | Resultado |
| --- | --- | --- |
| Fronteiras de contexto, pureza e integração somente de leitura | `tests/Unit/Architecture/ContextBoundariesTest.php`; teste do adapter compara despesas antes/depois | Comprovado |
| Proprietário, ocorrência, datas futuras, `other`, meses distintos, somas acima de inteiro nativo e alterações confirmadas | `tests/Feature/Insights/ExpenseAnalysisAdapterTest.php` | Comprovado |
| Fatos relacionados no mesmo snapshot | Teste do adapter comprova um único statement PostgreSQL para todos os fatos; garantia de snapshot por statement do banco | Comprovado pelo mecanismo; não foi executado teste com escrita concorrente |
| Elegibilidade, concentração, comparações, liderança, onboarding e seleção sem redundância | `tests/Unit/Insights/Application/UseCases/GenerateInsightCandidates*Test.php` e `SelectInsightCandidatesUseCaseTest.php` | Comprovado |
| Aritmética exata, limiares, períodos e arredondamento | `tests/Unit/Insights/Domain/ValueObjects/` | Comprovado |
| Catálogo, limites Unicode, alternativas curtas, rotação diária e IDs | Testes de composição, seleção de variantes e `GetInsightsUseCaseTest.php` | Comprovado |
| JSON:API, autenticação, proteções, query params e falha explícita | `tests/Feature/Insights/InsightsApiTest.php` | Comprovado |
| Cenários reais com histórico e sem despesas | Login e `GET /api/insights` no Lerd: Gabriel recebeu aumento e liderança recorrente; Kelly recebeu `first_expense` | Comprovado |
| Quantidade de queries e plano | Teste do adapter comprova uma leitura analítica; `EXPLAIN (ANALYZE, BUFFERS)` da consulta no banco local: 0,639 ms, sem escrita ou uso de disco temporário | Comprovado no conjunto local de 88 despesas; não é benchmark de escala |
| Observabilidade HTTP | Lerd `optimize_route`: 14 amostras, mediana de 141,5 ms, nenhuma rota lenta reportada | Comprovado no tráfego local |
| Verificações finais | Suíte completa: 491 testes, 2.594 assertions; Pint aprovado; OpenSpec estrito aprovado | Comprovado |

## Pendência externa de apresentação

A tarefa 5.6 permanece aberta: o repositório Flutter não está disponível aqui, portanto ícones, cores, fallback e layout com fontes ampliadas não foram verificados. O usuário solicitou o arquivamento de todas as specs abertas após essa limitação ser informada. O arquivamento encerra a entrega do backend e não declara a revisão visual concluída; ela continua necessária antes de disponibilizar a tela Flutter.
