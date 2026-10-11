## Context

Expense tem CRUD isolado por proprietário, valores inteiros em centavos, `occurred_on` civil e descrições opcionais de até 64 caracteres. Suas rotas usam Sanctum e as proteções de conta, verificação, throttling e extensão de sessão. O proprietário entra nos UseCases por `Core\Application\Ports\UserPort`.

`ExpenseRepository` é um contrato de CRUD entregue pelo decorator `CachedExpenseRepository`; `ExpenseCategorizationRepository` cuida exclusivamente das tentativas de classificação. A spec `expense-repository-boundaries` preserva essa segregação. As sugestões consultam projeções do histórico do próprio contexto, sem necessidade de modificar esses contratos.

O schema existente contém todos os dados necessários e índices por proprietário e ocorrência. Não há índice textual específico; a V1 restringe primeiro o proprietário e mede a consulta antes de propor qualquer alteração de schema.

## Goals / Non-Goals

**Goals:**
- Entregar até cinco descrições úteis ao autocomplete, com ordem estável e isolamento integral por conta.
- Oferecer valor opcional exato e conservador, sustentado pelos três meses civis anteriores completos.
- Manter um fluxo vertical pequeno, dados tipados e um único statement de despesas.
- Comprovar regra, query e contrato HTTP nos níveis de teste adequados.

**Non-Goals:**
- Alterar Flutter, CRUD, validação de criação, categorias ou categorização por IA.
- Criar lançamentos, recorrências, agendamentos, tabelas, entidades persistentes, dependências, cache, Redis, filas ou jobs para sugestões.
- Adicionar busca aproximada, remoção de acentos, score ponderado, paginação ou parâmetros configuráveis de limite e janela.

## Decisions

### 1. Repository de leitura próprio, sem Port de sugestões

Criar `ExpenseSuggestionsRepository` em `Expense/Application/Repositories` e `EloquentExpenseSuggestionsRepository` em `Expense/Infrastructure/Repositories/Persistence`, reutilizando `ExpenseModel`. Registrar somente esse binding no provider existente.

Repository é adequado porque se trata de consulta de agregados do próprio contexto. O retorno é uma projeção composta legítima, não um Model. Um Port seria apropriado para uma capacidade externa ou transversal, não justificado apenas pela agregação SQL. Acrescentar método ao CRUD exigiria ampliar sua fronteira documentada e tocar seu decorator; o contrato específico evita isso com uma única operação.

Não criar interface para o UseCase, Mapper, base genérica ou segundo Model de despesas.

### 2. Entrada temporal explícita e dados próprios

`GetExpenseSuggestionsController` recebe `GetExpenseSuggestionsRequest`, resolve a data civil atual no timezone da aplicação e entrega termo e referência a `GetExpenseSuggestionsUseCase`. O UseCase injeta `UserPort $port` antes de `ExpenseSuggestionsRepository $repository` e obtém o ID uma única vez.

Derivar a janela a partir do primeiro dia do mês de referência, evitando overflow de datas como 31 de janeiro, e reutilizar `DatePeriodValueObject` para representar o intervalo inclusivo. Não adicionar Port de relógio nem receber data controlada pelo cliente nesta V1.

O Repository recebe proprietário, termo e período explícitos e retorna uma lista de `ExpenseSuggestionHistoryOutput`, `final readonly` e constructor-only, com chave normalizada, descrição representativa, número de meses distintos representados e mínimo/máximo monetário da janela, anuláveis quando ela está vazia. Não retornar linhas individuais, Models, Builders ou metadados de ordenação desnecessários.

O UseCase transforma cada projeção em `ExpenseSuggestionOutput` próprio, com ID opaco, descrição e valor opcional. O Repository não reutiliza esse Output de UseCase. A consistência é uma política de consulta, não uma nova invariante do agregado: verificar três meses representados e igualdade exata de mínimo e máximo em PHP puro no UseCase, sem criar Entity persistente ou Domain Service. Os testes Unit comprovam essa decisão sem Laravel.

### 3. Normalização única e representação mais recente

Usar a mesma expressão PostgreSQL para busca, agrupamento e fatos monetários: remover whitespace nas extremidades e converter para minúsculas. Documentar e testar uma remoção consistente de whitespace externo, incluindo espaço, tabulação e quebra de linha, sem comprimir espaços internos. A descrição exibida preserva caixa, acentuação e espaços internos do registro com maior `(created_at, id)`, removendo apenas whitespace externo.

A remoção de espaços externos foi recomendada na análise e adotada como decisão desta proposta; não representa migração de dados. Não reutilizar a elegibilidade do classificador: ela tem outro propósito e poderia excluir texto válido no histórico.

A normalização textual de comparação fica na Infrastructure, onde o PostgreSQL define a igualdade e ordenação dos grupos; o UseCase não reimplementa `lower()` para juntar grupos. Para o desempate final, usar collation determinística explícita, como `C`, sobre a chave normalizada. A V1 não usa `unaccent`, extensão, fuzzy matching ou normalização de espaços internos.

### 4. Busca literal e ordenação lexicográfica

`query` é obrigatório com comprimento Unicode de 1 a 64 antes de trim; a validação verifica também texto não vazio após trim. O Request lê a query string, não um corpo GET, e rejeita presença de `user_id`, inclusive vazio. Preservar o padrão de erros JSON:API com associação ao parâmetro de query.

Usar bindings e escapar os caracteres de LIKE (`%`, `_` e o próprio caractere de escape) quando aplicável. Prefixo é prioridade binária, seguido de `MAX(created_at) DESC`, `COUNT(*) DESC` e chave normalizada crescente. Não escolher um score que torne difícil justificar a ordem. Frequência e recência abrangem todo o histórico correspondente da conta; o período limita somente os fatos monetários.

O limite é fixo em cinco no contrato de leitura, sem parâmetro de paginação, contagem total ou configuração adicional. A resposta não expõe score, frequência ou timestamp.

### 5. Um statement de despesas com agregação no banco

Implementar uma consulta parametrizada com subqueries ou CTEs legíveis:
1. Restringir `user_id`, excluir descrições inutilizáveis, normalizar e buscar correspondências literais.
2. Agrupar por chave, determinar grafia representativa e ordenar/limitar a cinco grupos no PostgreSQL.
3. Obter para os candidatos `COUNT(DISTINCT mês de occurred_on)`, `MIN(amount)` e `MAX(amount)` filtrados ao período explícito e ao mesmo proprietário.
4. Devolver uma linha agregada por candidato, na ordem final, em um único statement/snapshot.

Escolher a forma SQL mais legível que cumpra o contrato, sem framework de queries nem consultas executadas por candidato. Agregações podem ser incorporadas ao agrupamento inicial quando isso simplificar o statement; não é obrigatório materializar CTEs. Nunca limitar lançamentos antes de medir frequência ou consistência: isso poderia ocultar divergências.

Como os valores são individuais, mínimo/máximo mantêm a representação inteira de Expense, sem `SUM`, média ou float. Três meses distintos no intervalo de exatamente três meses provam presença mensal; igualdade de mínimo/máximo prova igualdade de todos os registros, inclusive duplicados. Meses fora da janela não influenciam esses fatos.

### 6. Response independente de despesa persistida

Adicionar a rota estática `suggestions` no grupo existente e `ExpenseSuggestionResponse` com `JsonApiResource` first-party. Não usar `ExpenseResponse`, pois a sugestão não representa um lançamento persistido e não possui seus atributos de lifecycle.

Gerar ID opaco determinístico na Application usando hash de composição não ambígua da versão da identidade de sugestão, proprietário e chave normalizada. Não usar ID do lançamento representativo: sua grafia pode mudar sem mudar a identidade do grupo. O ID não autoriza acesso a qualquer recurso nem contém o proprietário em claro.

Resposta típica:

```json
{
  "data": [
    {
      "type": "expense-suggestions",
      "id": "<identificador-opaco>",
      "attributes": {"description": "Internet", "amount": 14000}
    },
    {
      "type": "expense-suggestions",
      "id": "<outro-identificador-opaco>",
      "attributes": {"description": "Plano de Internet"}
    }
  ]
}
```

Usar a API instalada para omitir `amount` ausente e manter `data: []` em coleção vazia. Não acrescentar links de paginação ou identificar a sugestão como despesa. O consumidor pode alterar o valor antes de usar o POST existente.

### 7. Evidência por responsabilidade

- `tests/Unit/Expense/Application/UseCases/GetExpenseSuggestionsUseCaseTest.php`: proprietário, termo, janela, chamada única, ausência de dados, consistência e transformação para Output, usando mocks PHPUnit e o suporte existente quando apropriado.
- `tests/Feature/Expense/Infrastructure/Repositories/Persistence/EloquentExpenseSuggestionsRepositoryTest.php`: isolamento, variantes textuais, grafia, ranking, limite, limites de calendário, fatos monetários e um statement de despesas para zero/um/cinco resultados no PostgreSQL.
- `tests/Feature/Expense/Presentation/Http/GetExpenseSuggestionsHttpTest.php`: Bearer real para autenticação/expiração/revogação, conta ativa/verificação, validação da query, rota, JSON:API, omissão de valor, identidade estável e ausência de efeitos em despesas/classificação.
- Verificações existentes de fronteiras e suítes focadas de Expense após implementação. Não alterar allowlists para importar Identity em produto; fixtures de Identity ficam restritas ao Arrange dos testes.

Executar arquivos isolados e contexto pelo launcher `lerd composer test -- ...`; restaurar relógio/timezone e query logs e manter fakes de IA/filas explícitos. Usar Pint após edições PHP. No fluxo de implementação autorizado, verificar o plano PostgreSQL em dados representativos e capturar a rota afetada com diagnósticos Lerd; não alegar performance comprovada apenas pela ausência de N+1.

## Risks / Trade-offs

- [Busca contendo substring não usa diretamente índice textual] → Restringir pelo proprietário, limitar candidatos no banco e verificar `EXPLAIN`/tempo; propor índice somente se a medição justificar, sem adicioná-lo silenciosamente ao escopo.
- [Descrições iguais podem representar gastos diferentes] → Exigir presença nos três meses e igualdade de todos os valores; o valor continua opcional e editável, sem alegar recorrência real.
- [Normalização ou collation divergentes entre PHP e PostgreSQL] → Manter a chave canônica na query e testar Unicode, whitespace externo e desempates; não unir resultados novamente em PHP.
- [Cadastrar despesa retroativa promove sua descrição] → Decisão intencional: recência significa utilização no cadastro (`created_at`), enquanto evidência mensal usa `occurred_on`.
- [Mudança entre requisições altera ranking ou valor] → Não usar cache; cada execução lê um snapshot PostgreSQL próprio. Não prometer estabilidade do histórico entre requisições.
- [Middlewares têm escritas legítimas] → A ausência de efeitos refere-se a despesas, categorização e recursos desta feature; preservar extensão de sessão e rate limiting existentes.

## Migration Plan

Sem migration planejada. A implantação adiciona classes, binding e rota; contratos atuais continuam disponíveis. Antes de exercitar manualmente o fluxo na implementação, conferir migrations pendentes do checkout e aplicar incrementalmente se necessário, sem `migrate:fresh`.

Rollback consiste em retirar o novo fluxo, binding e rota; não existe dado novo a migrar ou limpar. Não arquivar esta mudança antes de implementação autorizada e evidências correspondentes.

## Open Questions

Nenhuma questão bloqueante. Consistência integral dos múltiplos registros e recência antes de frequência foram confirmadas pelo usuário. Trim externo é a recomendação adotada nesta proposta, descrita explicitamente na spec; espaços internos e acentos permanecem significativos. Medições e escolha da forma final do statement são tarefas de implementação, não justificam expandir o escopo antecipadamente.
