## 1. Baseline e caracterização antes da extração

- [x] 1.1 Reconciliar o inventário do design com o bootstrap efetivo e a fatia implementada de Notifications; registrar por tradução status, textos, origens, ordem, guards e exclusões de reporte. Identificar evidência existente por arquivo/cenário, sem assumir que fixtures atuais provam todo o contrato. (ERR-01 a ERR-06)
- [x] 1.2 Acrescentar somente a caracterização HTTP faltante para os mapeamentos inventariados, os três ramos de conta e o conflito de e-mail com pointer; executar os arquivos afetados isoladamente pelo launcher e registrar o resultado anterior à extração. Não alterar produto para fazer a baseline passar. (ERR-01, ERR-02)
- [x] 1.3 Caracterizar validação com múltiplas mensagens, catálogo/defaults do fallback, 404 específico/genérico, documento JSON:API pronto, alcance fora da API e reporte. Usar rotas de teste temporárias e isolamento de bindings/listeners quando necessário, sem novos endpoints de produto. (ERR-03 a ERR-06)

Evidências de 1.1–1.3: seção **Baseline verificada — Step 1 (2026-10-19)** em `design.md`, com inventário por tradução, mapa requisito/cenário/arquivo, comandos, resultados e limites. Produção permanece intacta; os checkboxes seguintes não são satisfeitos pela baseline.

## 2. Construção compartilhada e fronteiras

- [x] 2.1 Implementar `JsonErrorResponse` (nome inicial: `JsonApiErrorResponse`) em Core Presentation com construção de um/vários erros e reaproveitamento do documento na normalização final; verificar envelope, status textual, membros opcionais e ausência de `data`. (ERR-01, ERR-03, ERR-04)
- [x] 2.2 Atualizar somente a permissão arquitetural exata de consumo dessa Response em Presentation e a documentação pertinente, caso ainda ausente; preservar proibições de imports entre contextos e de HTTP em Domain/Application. Executar a verificação focada de fronteiras. (ERR-02)

Evidências de 2.1–2.2: seção **Construção compartilhada verificada — Step 2 (2026-10-19)** em `design.md`. `tests/Unit/Core/Presentation/Http/Responses/JsonApiErrorResponseTest.php` (13 testes / 45 assertions), `tests/Unit/Architecture/ContextBoundariesTest.php` (30 testes / 504 assertions) e os quatro arquivos da baseline HTTP foram aprovados isoladamente pelo launcher após Pint: 113 testes / 885 assertions nesta etapa. O construtor e `document()` compartilham a montagem; sua integração no hook final pertence à tarefa 3.3, não executada neste step. Permissão restrita à classe exata em Presentation de Identity/Expense/Notifications, documentada em `ARCHITECTURE.md`.

## 3. Modularização dos registros Laravel

- [x] 3.1 Extrair os registros de Identity para sua Presentation usando a Response compartilhada; remover apenas o segundo registro de e-mail usado e preservar o primeiro, todos os textos, pointers, guards e exclusões de reporte. (ERR-01, ERR-02, ERR-06)
- [x] 3.2 Extrair os registros de Expense e Notifications para suas respectivas Presentations, incluindo o callback de 404 de DELETE pertencente a Notifications, com retorno null fora do caso específico. (ERR-02, ERR-05, ERR-06)
- [x] 3.3 Extrair validação, decisão de JSON, 404 genérico e fallback para Core Presentation, sem imports de contextos consumidores, preservando respostas prontas, status e headers originais. (ERR-03 a ERR-06)
- [x] 3.4 Reduzir `withExceptions` à composição explícita dos registros, garantindo a precedência do 404 específico; revisar o diff para confirmar que routing, middleware e demais políticas não mudaram. (ERR-02, ERR-05, ERR-06)

Evidências de 3.1–3.4: seção **Extração integrada verificada — Step 3 (2026-10-19)** em `design.md`. Cada extração foi testada antes da seguinte; após Pint, os 11 arquivos HTTP da baseline, Response Unit e fronteiras passaram isoladamente pelo launcher: 384 testes / 3340 assertions. Os blocos de routing/middleware foram comparados com HEAD e são idênticos. O Step 4 mantém seu gate de fechamento pendente; as provas focadas desta etapa não autorizam arquivar.

## 4. Evidências e fechamento após autorização de apply

- [x] 4.1 Executar isoladamente os arquivos alterados e as suítes HTTP focadas de Core, Identity, Expense, Notifications e os cenários de erro de query de Insights/Metrics via `lerd composer test -- <caminho/opções>`; verificar cada cenário ERR-01 a ERR-06 e registrar comandos, resultados e limitações. Não executar Feature diretamente por Pest/Artisan.
- [x] 4.2 Provar preservação de `Retry-After` em 429, `Allow` em 405, headers em resposta JSON:API pronta e remoção de Content-Length obsoleto; verificar falha interna sanitizada sem expor SQL/segredo. (ERR-04, ERR-05)
- [x] 4.3 Executar Pint `--dirty --format agent` para o PHP alterado, repetir verificações afetadas e revisar fronteiras/ownership. Se houver alteração de suporte de testes compartilhado, aplicar o gate ampliado exigido pelo projeto, com duas seeds e paralelo, registrando evidências sem tratar skips inesperados como aprovação.
- [x] 4.4 Revalidar a mudança OpenSpec estritamente e revisar rastreabilidade requisito → cenário → teste/evidência com `trocado-quality-gate` antes de propor conclusão ou arquivamento. Manter pendente qualquer tarefa sem prova; problemas de produto fora do escopo exigem decisão do usuário.

Evidências de 4.1–4.4: seção **Gate final — Step 4 (2026-10-19)** em `design.md`, com matriz ERR-01–ERR-06. Suíte completa: 2445 testes / 41741 assertions; suítes HTTP focadas: 549 / 4121; sete arquivos isolados da correção final: 160 / 1177. Todos aprovados pelo launcher, após Pint, sem skips/incomplete/risky. Validação estrita da change passou. Sem alteração de suporte compartilhado, sem gate ampliado de reorganização aplicável. Arquivamento autorizado explicitamente pelo usuário.
