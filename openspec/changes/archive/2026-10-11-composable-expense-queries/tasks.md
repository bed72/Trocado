## 1. Decisões e baseline

- [x] 1.1 Obter a decisão sobre maiúsculas/acentos, documentar collation/normalização e cenários explícitos; resolver antes de implementar ordenação alfabética.
- [x] 1.2 Após autorização explícita de apply, revisar os diffs locais do baseline, preservar arquivos Bruno preexistentes e mapear cenários/testes históricos sem atribuir aprovação ao novo escopo.
- [x] 1.3 Conferir APIs do Query Builder/Eloquent e cursor na versão Laravel instalada com Boost/docs e código quando necessário, sem adicionar dependências ou alterar Composer.

Evidência da etapa 1 (2026-10-11): decisão do usuário de ignorar ambos, cenários normativos em `specs/expense-querying/spec.md`, revisão por arquivo e mapa de cenários do baseline em `design.md` (HEAD + diffs locais), APIs Laravel 13.34.0 confirmadas por Boost/docs e código instalado, capacidade ICU local confirmada por consulta read-only. As provas executáveis da implementação permanecem nas tarefas 5 e 6.

Verificações da etapa: `openspec validate composable-expense-queries --type change --strict --json --no-interactive` passou sem issues; `git diff --check` passou. Critério de saída atendido: contrato sem decisão bloqueante e baseline identificado. Nenhum teste da aplicação foi executado nesta etapa e nenhum resultado histórico foi promovido a prova do novo escopo.

## 2. Consulta explícita e validação

- [x] 2.1 Criar GetAllExpenseInput imutável e atualizar UseCase, contrato, decorators, doubles e chamadores com proprietário explícito.
- [x] 2.2 Validar filtros opcionais, formatos/limites, categorias por OU, critérios por E, conflitos temporais, intervalos abertos e valores em centavos incluindo zero.
- [x] 2.3 Normalizar componentes civis para limites sem inferir datas atuais; deduplicar/ordenar categorias e preservar prioridade dos sorts.
- [x] 2.4 Compor a query no EloquentExpenseRepository com Query Builder nativo: proprietário explícito, where inclusivo para limites independentes, whereIn para categorias, verificações !== null para preservar zero e allowlist de colunas; sem Request interna ou parser genérico.
- [x] 2.5 Implementar ordenações nas duas direções com até três campos distintos e ID decrescente; criar por migration incremental a collation ICU expense_description_ci_ai (und-u-ks-level1, deterministic=false), selecionar expressão COALESCE de descrição nullable com alias interno e conservar a collation nos comparadores do cursor, sem alterar a persistência de description.

## 3. Cursor links e cache

- [x] 3.1 Implementar/validar cursor tipado de consulta efetiva, detectar mudança de critérios/direção/prioridade e rejeitar campos arbitrários antes de cache/leitura.
- [x] 3.2 Preservar cursores legados no contrato anterior e rejeitá-los nas novas combinações, documentando a compatibilidade limitada.
- [x] 3.3 Preservar todos os filtros/sorts/tamanho nos links next/prev e manter resposta JSON:API e links nulos.
- [x] 3.4 Versionar chaves e distinguir proprietário, critérios normalizados, prioridade/direção de sort, tamanho e cursor, mantendo TTL 60 e invalidação afterCommit.

## 4. Escopo de descrição cancelado

Em 2026-10-11, o usuário determinou restaurar `description` como nullable e não alterar esse contrato. As tarefas originais 4.1 (obrigatoriedade), 4.2 (consumidores/fixtures), 4.3 (cleanup/NOT NULL/CHECK), 4.4 (invalidação repetível do cleanup) e 4.5 (aplicação local) foram canceladas e retiradas da lista ativa, sem marcar implementação revertida como concluída. Classes, migration e testes específicos foram removidos; consumidores e fixtures foram restaurados ao baseline. Nenhuma migration/limpeza dessa etapa foi aplicada ao banco local.

Evidência histórica da implementação posteriormente revertida: provas focadas de migration (37), HTTP (68), persistência (29), Unit de Expense (85 mais 4 de criação), arquitetura (26) e suíte completa (1132) passaram nos bancos exclusivos de teste. Execuções adicionais com seeds/paralelo foram abortadas. Esses resultados não aprovam código revertido nem provam as consultas combináveis ainda pendentes.

## 5. Evidência automatizada

- [x] 5.1 Provar proprietário/propagação dos critérios em Application Unit sem bootstrap; descrição permanece opcional/nullable.
- [x] 5.2 Provar em Feature PostgreSQL filtros isolados/combinados, limites inclusivos, intervalos abertos, bissextos, zero, categorias duplicadas e isolamento entre contas.
- [x] 5.3 Provar HTTP negativo de filtros/sorts/tipos/cursores e regressão sem parâmetros/ano-mês-dia, incluindo page[size]=6 e padrão 20.
- [x] 5.4 Provar ordenações simples/compostas, política alfabética aprovada, empates, ida/volta sem duplicação em dados estáveis, incompatibilidade e cursores legados.
- [x] 5.5 Provar identidade/cache hit de critérios equivalentes, isolamento de consultas distintas e invalidação após CRUD/classificação; incluir Redis real isolado e rollback.

As tarefas originais 5.6 (provas de cleanup/constraints) e 5.7 (obrigatoriedade e trabalhos antigos após cleanup) foram canceladas com a seção 4. As provas de ordenação 5.4 devem incluir descrições nullable sem exigir mudanças em sua persistência.

## 6. Gate de aplicação e fechamento

- [x] 6.1 Executar arquivos afetados isoladamente pelo launcher, depois suítes afetadas e arquitetura; registrar comandos, resultados/skips/bloqueios e rastreabilidade por cenário.
- [x] 6.2 Executar gate completo e paralelo com pelo menos dois processos para impactos compartilhados de cursor; se suporte compartilhado for alterado, incluir duas seeds registradas e duas invocações simultâneas conforme regras do projeto.
- [x] 6.3 Executar Pint --dirty --format agent após mudanças PHP e repetir verificações afetadas pelo formatter.
- [x] 6.4 Medir consultas reais/planos PostgreSQL pelo launcher no Lerd e justificar índices com evidência, sem promessa de performance por inspeção. Por decisão explícita do usuário, o diagnóstico HTTP local originalmente previsto foi transferido para 7.2, após a migration local.
- [x] 6.5 Revisar docs/coleções afetadas pelo contrato e só alterar arquivos com changes preexistentes após inspeção; não sobrescrever trabalho local.
- [x] 6.6 Validar OpenSpec estritamente, revisar evidências e pendências antes de considerar archive; nenhuma aprovação histórica substitui prova do novo escopo e nenhum commit/archive é automático.

Evidência da implementação ativa: matriz por requisito/cenário e comandos/resultados no `design.md`. Gate padrão e as seeds 20261011/20261012 (duas invocações simultâneas) passaram com 1090 testes/7033 assertions; paralelo com dois processos passou. A limitação de instrumentação do Lerd e os timeouts MCP foram registrados, sem enfraquecer testes. A captura de dumps foi restaurada para enabled=true após o gate.

Fechamento do escopo autorizado: OpenSpec estrito passou sem issues e `git diff --check` passou. `migrate:status` confirmou a migration de collation como Pending no banco local; Domain, criação/edição nullable, Model e Composer não têm alterações desta implementação. Pendências operacionais 7.1–7.2 permanecem explícitas; nenhuma declaração de archive-ready, commit ou archive foi feita.

## 7. Validação operacional local adiada

Em 2026-10-11, o usuário escolheu explicitamente **Manter para etapa 7** a aplicação local da migration de collation. Os itens abaixo permanecem pendentes e impedem declarar a mudança integralmente archive-ready.

- [x] 7.1 Quando autorizado para esta etapa, aplicar somente a migration de collation no banco local pelo Lerd, confirmando que description continua nullable e nenhum dado é limpo.
- [x] 7.2 Após 7.1, conferir os fluxos HTTP locais afetados com captura/diagnóstico do Lerd, revisar queries/tempos e registrar evidência antes de considerar archive.

Aplicação local autorizada e executada em 2026-10-11: `lerd artisan migrate --no-interaction` aplicou `2026_10_11_204139_create_expense_description_sort_collation` em 15.20 ms, batch 3. `migrate:status` confirmou todas as migrations aplicadas. Consultas read-only confirmaram ICU/und-u-ks-level1/deterministic=false, description nullable e 88 despesas antes/depois. O usuário informou já ter validado os fluxos; essa validação manual é evidência relatada pelo usuário, sem atribuir a ela captura ou revisão de queries/tempos ainda não registrada para 7.2.

Fechamento posterior de 7.2: revisada a captura FPM real da consulta Bruno com from/to de setembro, categorias food/transport, valores 1000–30000, sort=-occurred_on,amount e tamanho 6. O SQL restringiu user_id e todos os critérios, usou occurred_on DESC/amount ASC/id DESC e limit 7, com uma leitura de despesas em 2.53 ms. Foram observadas cinco queries desse request, incluindo autenticação/extensão de sessão; não há uma query de despesas por item nessa captura. route_timing/optimize_route reportaram duas amostras, mediana 236.5 ms e nenhuma rota lenta, sem atribuir a essa janela pequena garantia de performance. analyze_queries continha tráfego CLI de testes e não foi usado como prova de N+1 HTTP. A validação funcional manual informada pelo usuário e as provas PostgreSQL/HTTP automatizadas complementam essa evidência. Todos os itens ativos estão concluídos; arquivamento autorizado pelo usuário.
