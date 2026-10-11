## 1. Contratos e caso de uso de Expense

- [x] 1.1 Criar `ExpenseSuggestionsRepository` e `ExpenseSuggestionHistoryOutput` tipado para chave, descrição representativa e fatos mensais agregados, sem ORM e sem alterar contratos de CRUD/categorização (requisito: Leitura limitada sem efeitos no ciclo de vida de despesas).
- [x] 1.2 Criar `ExpenseSuggestionOutput` e `GetExpenseSuggestionsUseCase`, com `UserPort` antes do Repository, proprietário explícito e janela dos três meses civis anteriores derivada da referência usando o período de Core (requisitos: Consulta autenticada e isolada por proprietário; Janela de três meses civis anteriores).
- [x] 1.3 Implementar a política pura de três meses representados e igualdade integral de mínimo/máximo, mantendo centavos inteiros, e gerar identidade opaca estável por conta/chave sem acrescentar Entity persistente ou Domain Service (requisitos: Valor sugerido somente com consistência integral; Resposta JSON:API de sugestões transitórias).
- [x] 1.4 Criar e executar isoladamente `tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php`, cobrindo argumentos/chamada única, coleção vazia, janela em outubro/virada de ano, valores iguais/diferentes, mês ausente, múltiplos registros consistentes/divergentes, exatidão monetária e identidade estável; registrar evidência pelo launcher.

### Evidências da etapa 1 — 2026-10-11

- `lerd composer test -- tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php --compact`: 25 testes aprovados, 134 assertions.
- Pint pelo MCP Lerd (`vendor_run`, `bin: pint`, `args: ["--dirty", "--format", "agent"]`): aprovado.
- Após Pint, `lerd composer test -- tests/Unit/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 74 testes aprovados, 540 assertions.
- `openspec validate add-expense-suggestions --type change --strict --json --no-interactive`: aprovado, sem issues.
- Orquestração: proprietário lido uma vez, termo preservado, período explícito e uma chamada ao Repository; coleção vazia e falha de identidade sem leitura.
- Calendário: outubro, virada de ano em 31 de janeiro, fim de mês e fevereiro bissexto; referência civil inválida não consulta histórico.
- Política monetária: três meses e extremos iguais positivos, mês ausente, registros concentrados no mesmo mês, extremos divergentes, histórico fora da janela e extremos ausentes. Exatidão comprovada para `14001`, `9007199254740993`, divergência de um centavo acima da precisão de double e `PHP_INT_MAX`.
- Identidade: estabilidade com alteração de termo, referência, grafia e valor; distinção por proprietário e chave. Ordem e grafia da projeção preservadas.
- Limite da evidência: Unit usa fatos agregados tipados; a inclusão de todos os lançamentos, inclusive múltiplos registros consistentes/divergentes no mesmo mês, depende da prova PostgreSQL nas tarefas 2.4–2.5. Autenticação HTTP, isolamento real no banco, normalização, ranking SQL, statement único e transporte JSON:API permanecem pendentes nas etapas 2–3. Não há fluxo manual novo ou migration nesta etapa.

## 2. Leitura PostgreSQL de sugestões

- [x] 2.1 Implementar `EloquentExpenseSuggestionsRepository` reutilizando `ExpenseModel`, com filtro por conta em todas as leituras, normalização única, exclusão de descrições inutilizáveis e busca literal com bindings (requisitos: Consulta autenticada e isolada por proprietário; Entrada textual limitada e busca parcial literal; Descrições normalizadas e únicas).
- [x] 2.2 Completar o statement único com grafia por `(created_at, id)`, ranking prefixo/recência/frequência/chave, limite de cinco após agrupamento e fatos monetários da janela sem descartar divergências (requisitos: Ordenação determinística e limite fixo; Janela de três meses civis anteriores; Valor sugerido somente com consistência integral; Leitura limitada sem efeitos no ciclo de vida de despesas).
- [x] 2.3 Registrar o binding do novo Repository no `ExpenseServiceProvider`, sem alterar os decorators atuais ou acrescentar cache, e comprovar sua resolução pelo fluxo de consulta.
- [x] 2.4 Criar e executar isoladamente `tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php`, cobrindo isolamento de ranking/valor, substring/prefixo, caixa, whitespace externo, acentos/espaços internos preservados, caracteres LIKE literais e grafia com empate de timestamp.
- [x] 2.5 Completar e executar o mesmo arquivo com recência antes de frequência, desempate determinístico, cadastro retroativo, cinco resultados, vazio, limites inclusivos da janela, histórico antigo, mesmo mês sem recorrência, mês ausente e todos os casos de consistência; comprovar um statement de despesas para zero/um/cinco sugestões e restaurar query logs.

### Evidências da etapa 2 — 2026-10-11

- `lerd composer test -- tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php --compact`: primeira execução com 24 testes/84 assertions; após completar cenários de frequência histórica e isolamento, 26 testes aprovados/91 assertions. Ambas pelo launcher com migrations incrementais nos bancos exclusivos de execução.
- Pint pelo MCP Lerd (`vendor_run`, `bin: pint`, `args: ["--dirty", "--format", "agent"]`): aprovado.
- Após Pint, `lerd composer test -- tests/Unit/Expense tests/Feature/Expense tests/Unit/Architecture/ContextBoundariesTest.php --compact`: 151 testes aprovados, 919 assertions.
- Normalização PostgreSQL: `regexp_replace` com `^[[:space:]]+|[[:space:]]+$` e flag `g` remove whitespace externo (espaço, tabulação e quebras de linha comprovados); `lower()` unifica caixa. A chave é compartilhada por busca, agrupamento e fatos monetários; acentos e espaços internos permanecem significativos. Chave usa collation `C` para agrupamento/desempate determinísticos, após conversão de caixa.
- Busca literal usa `strpos` com bindings, sem LIKE: `%`, `_`, barra invertida, aspas e texto com formato de SQL comprovados como literais.
- Provas de isolamento: descrição/grafia/recência/frequência de terceiros não alteram resultados; meses de outra conta não preenchem lacunas; valores de terceiros não invalidam padrão completo do proprietário.
- Ranking/limite: prefixo antes de substring; cadastro antes de frequência; frequência histórica inclusive fora da janela; desempate pela chave; cadastro retroativo e `updated_at` irrelevante; cinco grupos únicos após agregação, sem limitar registros monetários nem esconder divergência anterior.
- Fatos monetários e UseCase: limites inclusivos, exclusão de junho/outubro, histórico antigo sem valor, mês ausente, três registros no mesmo mês, múltiplos registros consistentes e divergências em ambas as ordens. `14001`, `9007199254740993` e `PHP_INT_MAX` preservados exatamente.
- Quantidade constante: zero/um/cinco grupos executam exatamente um statement, com bindings explícitos; estado de despesas preservado e query log vazio/estado de logging restaurados em finally. Binding comprovado por resolução do Repository e execução do UseCase pelo container.
- Limites: não há rota de sugestões nesta etapa; contrato HTTP e captura `optimize_route` dependem da etapa 3. `EXPLAIN`/tempo com histórico representativo continuam pendentes em 4.3; statement único não é alegação de performance medida. Nenhuma migration nova.

## 3. Contrato HTTP JSON:API

- [ ] 3.1 Criar `GetExpenseSuggestionsRequest` com `query` obrigatório escalar textual de até 64 caracteres, trim externo, rejeição de vazio/array e de presença de `user_id`, lendo query string e preservando erros JSON:API associados aos parâmetros (requisitos: Entrada textual limitada e busca parcial literal; Consulta autenticada e isolada por proprietário).
- [ ] 3.2 Criar `GetExpenseSuggestionsController`, resolvendo referência civil no timezone configurado, e `ExpenseSuggestionResponse` com recurso `expense-suggestions`, ID string, descrição e omissão real de `amount` ausente; confirmar a API first-party instalada pelo Boost antes de implementar (requisitos: Janela de três meses civis anteriores; Resposta JSON:API de sugestões transitórias).
- [ ] 3.3 Adicionar a rota estática nomeada `expenses.suggestions` no grupo protegido existente e verificar sua resolução e middlewares sem alterar endpoints atuais.
- [ ] 3.4 Criar e executar isoladamente `tests/Feature/Expense/Presentation/Http/GetExpenseSuggestionsHttpTest.php`, cobrindo Bearer válido/ausente/inválido/expirado/revogado, conta inativa/não verificada, isolamento, query inválida e `user_id` presente inclusive vazio; usar fixtures explícitas e tokens reais nos cenários de autenticação.
- [ ] 3.5 Completar e executar o mesmo arquivo com coleção vazia, tipo/IDs/atributos JSON:API, omissão de valor/categoria/data, IDs estáveis entre buscas/variantes e distintos entre contas, referência no timezone configurado e ausência de mudanças em despesas/tentativas, chamadas de IA ou jobs; restaurar relógio/timezone e manter fakes explícitos.

## 4. Verificação e rastreabilidade da implementação

- [ ] 4.1 Executar arquivos novos pelo launcher `lerd composer test -- <caminho> --compact`, suítes Unit/Feature focadas de Expense e `tests/Unit/Architecture/ContextBoundariesTest.php`; registrar comandos, resultados e bloqueios sem tratar skips inesperados como aprovação.
- [ ] 4.2 Executar Pint `--dirty --format agent` pela ferramenta Lerd após as últimas edições PHP e repetir as verificações afetadas pelo formatter, preservando mudanças externas à feature.
- [ ] 4.3 No ambiente de implementação, conferir migrations pendentes antes do fluxo manual e aplicar incrementalmente se necessário; inspecionar `EXPLAIN` e tempo da consulta com histórico representativo e registrar observações sem acrescentar índices ou dependências sem decisão.
- [ ] 4.4 Capturar a rota afetada pelos diagnósticos Lerd e consultar `optimize_route` para verificar N+1/slow queries, preservando autenticação e recursos de captura; registrar limites da medição e restaurar configurações de diagnóstico alteradas.
- [ ] 4.5 Mapear todos os cenários da spec para evidências, revisar fronteiras e preservação de criação/categorização, validar `add-expense-suggestions` estritamente e atualizar checkboxes somente com trabalho comprovado; manter a mudança não arquivada até autorização e gate aplicável.
