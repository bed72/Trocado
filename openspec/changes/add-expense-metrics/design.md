## Context

O Trocado usa PHP 8.5, Laravel 13.34.0 e PostgreSQL. A arquitetura distribui os contextos entre Domain puro, Application explícita, Infrastructure Laravel e Presentation Laravel. Expense é dono do ciclo de vida das despesas; Insights interpreta registros e produz mensagens; Core oferece capacidades transversais como `UserPort`.

A feature solicitada é a primeira consulta quantitativa para gráficos customizáveis no front. Ela tem uma única rota GET e dois modos, escolhidos pela presença de `group_by=category`. O cliente precisa receber o período efetivo, o total e, opcionalmente, a distribuição com percentuais, sem depender de inferência editorial, regras de elegibilidade de Insights ou paginação do CRUD.

As decisões de produto foram fechadas individualmente na conversa. A origem financeira é `occurred_on`; o default cobre o mês inteiro; totais são strings de centavos sem moeda explícita; percentuais são strings com duas casas e half-up; o resultado é um recurso JSON:API singular. O erro de query foi conferido no padrão existente de `GetInsightsRequest`: `title: "Parâmetro inválido"`, `detail`, `status` textual e `source.parameter`.

Fontes consultadas para estes artefatos: `ARCHITECTURE.md`, `.ai/guidelines/`, specs de Expense, Insights e rate limiting autenticado, mudança arquivada de Insights, sua rota e seu Request, e documentação Laravel 13 via Boost. A leitura das fontes não equivale a validação de runtime ou prova da implementação futura. Artefatos antigos com temas fora deste escopo não autorizam inferir funcionalidades existentes.

## Goals / Non-Goals

**Goals:**

1. Fornecer totais pessoais por intervalo civil inclusivo e, opcionalmente, por categoria.
2. Permitir cards, pizza, barras e outras apresentações com os mesmos fatos de backend.
3. Preservar valores acima do inteiro nativo e a precisão do cálculo percentual.
4. Manter total geral, categorias e denominadores reconciliados no mesmo snapshot.
5. Tornar ausência de filtro, filtro vazio, filtro inválido e período vazio semanticamente diferentes.
6. Detectar repetição e estruturas de query antes que o parser elimine a evidência do erro.
7. Reutilizar autenticação, status, verificação de e-mail, throttle e extensão de sessão existentes.
8. Tornar contrato HTTP, casos-limite e evidências esperadas explícitos antes de implementar.

**Non-Goals:**

- Construir componentes ou configurações de gráficos no front.
- Alterar Expense ou Insights para fornecer a consulta de Metrics.
- Consultar gastos de terceiros, casal, família ou qualquer escopo selecionável por query.
- Fornecer filtro por categoria individual, agrupamento por dia/mês, múltiplos agrupamentos ou séries temporais nesta entrega.
- Oferecer comparações, tendências, interpretação de hábitos, previsão, orçamento ou agregação de dados externos.
- Usar o verbo HTTP `QUERY`, corpo de GET, filtros JSON complexos ou DSL genérica de métricas.
- Retornar nomes traduzidos, cores, ícones, moeda, contagem de despesas ou campos extras não aprovados.
- Criar tabelas, projections persistidas, materialized views, filas, jobs, chamadas externas ou cache específico.
- Alterar limites da API autenticada, configuração de timezone ou política de acesso.
- Implementar código da aplicação, executar sua suíte ou criar testes como parte da presente solicitação de spec.

## Decisions

### 1. Ownership de Metrics e integração pelo schema

Criar as camadas necessárias de `app/Metrics/` quando apply for autorizado. A responsabilidade é fornecer fatos quantitativos próprios, sem interpretar ou selecionar mensagens. Metrics não deve importar modelos, enums de categoria, repositories, use cases ou Data de Expense ou Insights. Também não deve consultar o contexto Identity para obter o dono: reutiliza `Core\Application\Ports\UserPort` e o binding já existente.

Após autorização explícita para compartilhar o catálogo, `ExpenseCategoryEnum` pertence a `Core\Domain\Enums` e é reutilizado por Expense e Metrics. Essa dependência pura e explícita não permite imports entre os contextos consumidores.

A leitura direta de `expenses` pertence exclusivamente à Infrastructure de Metrics. Seu contrato semântico é:

| Campo | Uso | Regra |
| --- | --- | --- |
| `user_id` | Isolar a conta | Recebido explicitamente do UseCase; filtrado antes de agregação. |
| `occurred_on` | Definir o período | Data civil, limites inclusivos, sem filtros por timestamp. |
| `amount` | Somar centavos | Inteiro positivo de Expense; agregado pode superar inteiro nativo. |
| `category` | Agrupar | Identificador persistido do catálogo existente, incluindo `other`. |

Não consultar `users`, descrições, histórico editorial ou timestamps para montar o resumo. Não criar outro Model Eloquent de despesa. Mudança futura no significado desses campos exige revisão do Adapter e do contrato, porque o acoplamento é ao schema e sua semântica.

Alternativas rejeitadas: novo método no Repository de agregados de Expense para alimentar outro contexto; reutilização de `ExpenseAnalysisPort` de Insights; HTTP interno; replicação por eventos; engine genérica de métricas. Elas criam dependência de código ou complexidade sem necessidade desta consulta.

### 2. Fluxo de execução e contratos próprios

Fluxo proposto, com nomes arquiteturais orientativos:

```text
GET /api/metrics/expenses
  -> middlewares autenticados existentes
  -> GetExpenseMetricsRequest
       -> inspeção da query original: nomes, estruturas, duplicidade e presença
       -> normalização de valores textuais e validação de datas/agrupamento
  -> GetExpenseMetricsController
       -> resolve referência civil pelo relógio e app.timezone quando necessário
       -> converte filtros validados em entrada explícita da Application
  -> GetExpenseMetricsUseCase
       -> Core.UserPort: identidade autenticada
       -> período e modo válidos
       -> ExpenseMetricsPort: leitura analítica explícita por conta/período/modo
            -> ExpenseMetricsAdapter: PostgreSQL, uma projeção consistente
       -> aritmética exata de percentuais e reconciliação
       -> identidade determinística e ExpenseMetricsOutput
  -> ExpenseMetricsResponse
       -> recurso JSON:API singular
```

O Port pertence a Metrics Application e representa capacidade de leitura analítica, não persistência de um agregado Metrics. O Adapter fornece projeção própria e não recebe/retorna o Output HTTP nem Builder, Model, conexão ou collection Laravel.

Agrupamentos de dados ficam em `Application/Data`, com `final readonly`, constructor-only e tipos explícitos. Nomes propostos:

- `GetExpenseMetricsInput`: período efetivo e modo; não aceita proprietário fornecido pelo cliente.
- `ExpenseMetricsProjectionOutput`: total bruto exato e projeções de categoria produzidos pelo Port.
- `ExpenseCategoryTotalOutput`: identificador e soma exata de categoria, quando necessário para a projeção tipada.
- `ExpenseMetricsOutput`: identidade, período, total e presença semântica do agrupamento.
- `ExpenseCategoryMetricsOutput`: categoria, total e percentual finais.

Evitar Data redundante apenas para repetir a estrutura; os contratos do Port e do UseCase têm papéis distintos, mesmo se alguns campos coincidirem. Os nomes são orientação técnica, não justificativa para criar todos os objetos antecipadamente.

Período civil válido e valores monetários/razões exatas possuem invariantes reais. Após a revisão autorizada dos conceitos repetidos, Metrics e Insights reutilizam `Core\Domain\ValueObjects\DatePeriodValueObject`, `CentsValueObject` e `RatioValueObject`, com exceções puras de Core. O enum de agrupamento continua pertencendo a Metrics. `RatioValueObject::fromShare()` exige parcela menor ou igual ao total; `fromCents()` conserva razões acima de 100% usadas por Insights. Não criar Entity persistível, Domain Service genérico, interface por UseCase ou VO para toda string. A Application não importa Infrastructure, facades ou HTTP; Domain não importa Application Data nem outro contexto de negócio.

O construtor do UseCase deve seguir `Port → UseCase → Repository`, com `$userPort` e `$metricsPort` quando existirem dois Ports. O container resolve UseCases concretos e registra somente os bindings de fronteira necessários.

Na etapa de Application, `GetExpenseMetricsInput` recebe o `DatePeriodValueObject` efetivo e o enum de agrupamento. Para datas ausentes, a futura borda constrói o período com `monthContaining()` sobre a referência civil resolvida uma vez; para datas explícitas, usa `fromDates()`. O UseCase não recebe dados de transporte nem precisa de uma segunda referência. `ExpenseMetricsOutput` conserva esse período, o ID, o total e categorias nullable (`null` sem agrupamento; lista inclusive vazia no agrupado). A projeção do Port tem total e lista de `ExpenseCategoryTotalOutput`; no modo simples essa lista é vazia. A Application rejeita projeções inconsistentes, sem corrigir totais, fundir duplicatas ou descartar parcelas, e garante ordenação exata na saída mesmo se a projeção vier em outra ordem.

### 3. Período efetivo e responsabilidade do relógio

O transporte aceita zero ou duas datas. Não existe intervalo aberto. A referência do default vem de `app.timezone`; sua resolução ocorre uma vez na borda e é entregue explicitamente à operação, sem `now()`, Carbon, config ou Service Locator na Application/Domain.

O período default é primeiro a último dia do mês da referência, não dia 1 até hoje. Em outubro, uma ocorrência registrada para o dia 31 já entra na consulta feita no dia 9. Esta diferença em relação à janela financeira de Insights é intencional e não exige alterar Insights.

Uma vez resolvido, o período é usado na query, no ID e nos atributos da resposta. A execução não pode recalcular o mês para serializar a resposta e atravessar a virada do mês com outro intervalo.

`occurred_on` e os filtros explícitos são datas civis sem horário. A comparação é equivalente a `occurred_on >= start_date AND occurred_on <= end_date`, com bindings. Não usar horários `00:00:00`/`23:59:59`, conversão UTC ou funções de timezone sobre a coluna.

Não impor teto arbitrário ao intervalo; preservar todo o período solicitado. O domínio de datas continua sendo o formato civil real canônico de quatro dígitos de ano, não texto relativo ou calendário corrigido automaticamente. Datas extremas precisam de verificação na implementação para evitar limite acidental de bibliotecas, sem introduzir um máximo de duração novo.

### 4. Validação de presença, forma e nomes antes de defaults

Pipeline semântico obrigatório:

1. Conservar a query original recebida pelo servidor, antes de perder multiplicidade ou nomes pelo parsing.
2. Identificar nomes decodificados, valores, bracket notation e ocorrências de cada parâmetro.
3. Rejeitar nomes fora da allowlist exata e detectar duplicatas, inclusive nomes URL-encoded equivalentes.
4. Rejeitar qualquer estrutura de array/mapa ou mistura de escalar e array.
5. Conservar quais filtros foram efetivamente enviados, mesmo que middleware transforme vazio em `null`.
6. Remover espaços externos somente de valores escalares textuais.
7. Validar presença conjunta das datas, valores não vazios, formato/calendário, ordem e `group_by` fechado.
8. Aplicar default somente se ambas as datas estavam ausentes, nunca como recuperação de erro.
9. Executar o UseCase somente após validação completa e proteções de acesso.

O corpo da requisição não é fonte de filtros. Não usar inadvertidamente a união de body e query para resolver os campos desta consulta.

É insuficiente usar apenas o array final de query para detectar repetição: parsers PHP/Symfony podem conservar somente uma ocorrência. Da mesma forma, a representação normalizada da query pode já ter eliminado informação. A implementação deve validar a string original disponível no servidor, sem confiar em reserialização do array parsed.

A inspeção adicional deve ficar na Presentation e ser específica dos requisitos desta rota. Não adicionar biblioteca externa, parser genérico ou middleware global que mude o comportamento de todos os endpoints. Decodificação deve respeitar URL encoding uma vez e a semântica de query; `start_date` e `start%5Fdate` representam o mesmo nome. Nomes com pontos/espaços não podem ser convertidos silenciosamente em underscores para entrar na allowlist.

Para bracket notation de um filtro conhecido, `source.parameter` aponta ao nome raiz (`group_by`, `start_date`, `end_date`). Para um nome desconhecido, identifica o nome de query não suportado. Repetições de nomes desconhecidos permanecem inválidas pela allowlist, independentemente do erro específico de duplicidade.

Não fixar precedência ou quantidade exata de mensagens de validadores para combinações inválidas além dos parâmetros relevantes e do envelope. Regras dependentes, como comparar datas, só devem ser avaliadas depois que as datas sejam individualmente válidas, evitando mensagens contraditórias ou exceções de parsing.

### 5. Matriz de entrada para o contrato HTTP

| Query representativa | Resultado semântico |
| --- | --- |
| Sem parâmetros | Mês corrente inteiro, total simples. |
| `group_by=category` | Mês corrente inteiro, total e categorias. |
| Duas datas válidas | Intervalo explícito, total simples. |
| Duas datas válidas e `group_by=category` | Intervalo explícito, total e categorias. |
| Datas iguais | Dia único inclusivo. |
| Período de vários anos | Válido; sem truncamento ou teto de duração. |
| Período futuro | Válido; somente registros existentes. |
| Apenas `start_date` | `422`, falta `end_date`. |
| Apenas `end_date` | `422`, falta `start_date`. |
| Data vazia, somente espaços ou sem `=` | `422`, campo enviado é inválido. |
| Duas datas vazias | `422`, não ativa default. |
| `group_by=` ou somente espaços | `422`, não vira total simples. |
| `2026-02-30` / `2027-02-29` | `422`, data inexistente. |
| Data brasileira, relativa, timestamp, timezone ou sem zero canônico | `422`, formato inválido. |
| Inicial posterior à final | `422`, `end_date`; sem troca automática. |
| `group_by=month`, `Category`, `none` ou lista textual | `422`, agrupamento inválido. |
| `foo=bar`, `user_id`, `timezone`, `currency`, `page[size]` | `422`, nome não suportado. |
| Array/mapa em filtro permitido | `422`, filtro raiz inválido. |
| Filtro repetido com valores distintos | `422`, não escolhe uma ocorrência. |
| Filtro repetido com valores iguais | `422`, repetição continua inválida. |
| Nome duplicado com encoding equivalente | `422`, decodificação não contorna unicidade. |
| Array seguido de escalar para o mesmo filtro | `422`, último valor não apaga erro estrutural. |
| Espaços externos com valor válido | Aceito após trim; resposta canônica. |
| Espaços internos | Rejeitado pela regra do valor, sem correção. |
| Filtros inválidos e conta sem despesas | `422`, validação independe dos dados. |
| Filtros válidos e conta sem despesas | `200`, total `"0"`; lista vazia só no modo agrupado. |

### 6. Aggregation PostgreSQL e precisão monetária

O Adapter recebe proprietário e limites válidos explícitos. Deve usar agregações PostgreSQL com bindings, sem concatenar valores ou permitir seleção de coluna a partir de input livre. `group_by` tem domínio fechado; somente o caminho implementado para categoria é possível.

No modo simples, uma soma agregada resolve o total. No agrupado, usar uma única leitura que produza totais por categoria e total geral a partir dos mesmos registros, por exemplo uma CTE restrita por proprietário/período com agrupamento e total por janela. Também é possível derivar o total geral da soma exata dos grupos obtidos por um único statement. A escolha final deve evitar escanear o histórico desnecessariamente e manter a reconciliação verificável.

`SUM` de valores potencialmente grandes deve manter representação numérica exata do PostgreSQL. Não fazer cast do agregado para `bigint`, inteiro PHP ou float. Normalizar o transporte do driver para string decimal canônica e preservar `"0"` na ausência legítima de linhas. A ausência de linhas é um caso explícito de resultado, não `catch` para qualquer falha.

Três registros de `4000000000000000000` centavos, cada um dentro de 64 bits, já produzem `12000000000000000000`, acima do limite nativo. Esse cenário verifica a soma, não autoriza ampliar o limite individual de Expense nem alterar suas invariantes.

O índice composto documentado por `user_id` e `occurred_on` é um ponto de partida. Na implementação, confirmar o schema e medir o plano do statement. Não criar migration ou índice por hipótese, nem declarar escala comprovada com poucos registros locais.

### 7. Snapshot e concorrência de leitura

Preferir uma única consulta agregada por requisição válida de métricas. Em PostgreSQL, fatos de um único statement compartilham o snapshot de leitura, permitindo total e categorias consistentes sem locks de escrita ou transação de múltiplas leituras.

Se a implementação precisar de mais de um statement dependente, documentar e garantir isolamento que preserve o mesmo snapshot; uma transação comum em `READ COMMITTED` não garante que dois statements vejam a mesma versão. Não introduzir `TransactionPort` apenas para uma leitura de statement único. Uma mudança desse desenho exige revisar tarefas e evidências de concorrência.

Garantias:

- Todos os valores relacionados de uma resposta agrupada reconciliam monetariamente.
- Escrita confirmada antes de iniciar o novo snapshot é considerada na nova consulta.
- Escrita concorrente pode aparecer ou não na resposta, conforme o snapshot.
- Não existe promessa de atualização contínua durante o envio HTTP ou de igualdade entre duas requisições distintas.
- Recategorização concorrente mantém cada despesa em somente um grupo no snapshot.

### 8. Percentuais exatos com duas casas e half-up

Para total de categoria `C` e total geral positivo `T`:

```text
percentual exato = C * 100 / T
centésimos de percentual = round_half_up(C * 10000 / T)
percentage = centésimos formatados com ponto e exatamente duas casas
```

A multiplicação por `10000` é exata e pode superar inteiro nativo; não deve ocorrer antes da conversão para aritmética de precisão arbitrária. Realizar uma única etapa final de arredondamento. Não arredondar primeiro a razão para duas casas e depois multiplicar por cem.

Exemplos verificáveis:

| C | T | Percentual exato | String final |
| --- | --- | --- | --- |
| `60000` | `100000` | 60% | `"60.00"` |
| `16665` | `100000` | 16,665% | `"16.67"` |
| `1` | `3` | 33,333…% | `"33.33"` |
| `1` | `1000000` | 0,0001% | `"0.00"` |
| `2500` | `2500` | 100% | `"100.00"` |

Se não existem despesas, o total é zero e a lista é vazia; não existe categoria para dividir por zero. As invariantes atuais de Expense exigem valores individuais positivos. Uma categoria com valor positivo e percentual exibido `"0.00"` deve continuar na lista.

Arredondamento independente não reconcilia percentuais: três grupos iguais mostram 99,99% somados. Para total `100000` e grupos `16665`, `16665`, `16670`, `50000`, a soma exibida é 100,01%. Ambos são válidos. Não implementar largest remainder ou outro rateio para corrigir a exibição.

A biblioteca PHP pura `brick/math` já está instalada. A aritmética exata com `BigInteger` e `RoundingMode` fica nos Value Objects compartilhados de Core Domain, conforme a normalização autorizada. Metrics usa `CentsValueObject` e `RatioValueObject::fromShare(...)->roundedPercent(decimalPlaces: 2)`; Insights preserva comparação de elegibilidade sem arredondamento e representação editorial com zero casas. A permissão em `ARCHITECTURE.md` e nas verificações de fronteira é limitada ao Domain de Core para Brick Math e aos tipos compartilhados explícitos para os consumidores. Isso não libera Laravel, ORM ou SDK em Domain nem imports entre contextos de negócio.

### 9. Categorias presentes, completas e ordenadas

Retornar todos os grupos com despesas elegíveis; não preencher grupos vazios. Não oferecer paginação ou top-N: omitir uma categoria impediria reconciliar a soma com o total geral.

Os identificadores são os persistidos no catálogo compartilhado `Core\Domain\Enums\ExpenseCategoryEnum`, incluindo `other`. O enum foi extraído de Expense sem mudar cases ou valores, por autorização explícita. `GetExpenseMetricsUseCase` valida os identificadores com `tryFrom()`, sem lista local duplicada. Expense continua dono da categorização das despesas; Metrics apenas valida e transporta os identificadores. Uma mudança no catálogo deve motivar revisão dessa integração.

Ordenar por soma numérica exata decrescente e por identificador crescente no empate. O banco pode produzir essa ordenação sobre o agregado numérico antes de converter em texto; se houver ordenação na aplicação, usar comparação de inteiros exatos. Não ordenar strings como `"900"` e `"10000"` lexicograficamente, nem pelo percentual já arredondado.

### 10. JSON:API singular e presença semântica do agrupamento

Usar a classe first-party `Illuminate\Http\Resources\JsonApi\JsonApiResource` quando aplicável, nomeada `ExpenseMetricsResponse` em `Presentation/Http/Responses`. A documentação Laravel 13 permite customizar `toType` e `toId`; a Response recebe Output próprio e não necessita de Model persistido.

O suporte oficial deve serializar o envelope. Não montar manualmente um segundo `data`, criar `JsonResource` tradicional por hábito ou serializar o resumo como collection.

Contrato de atributos:

| Atributo | Tipo JSON | Presença | Semântica |
| --- | --- | --- | --- |
| `start_date` | string | Sempre | Limite inicial efetivo canônico. |
| `end_date` | string | Sempre | Limite final efetivo canônico. |
| `total_amount` | string | Sempre | Inteiro decimal exato em centavos, inclusive `"0"`. |
| `categories` | array | Somente com `group_by=category` | Lista completa e ordenada, podendo ser `[]`. |
| `categories[].category` | string | Em cada item | Identificador estável do catálogo persistido. |
| `categories[].total_amount` | string | Em cada item | Centavos exatos da categoria. |
| `categories[].percentage` | string | Em cada item | Porcentagem com ponto e duas casas. |

Não retornar `currency`, nomes traduzidos, cor, ícone, contagem, IDs de despesas ou configurações de gráfico. Categorias são objetos de atributos do resumo, sem `id` próprio, `type` próprio, `relationships` ou `included`.

A Application precisa distinguir agrupamento não solicitado de agrupamento solicitado e vazio. Uma lista vazia sozinha não expressa ambos. Representar o modo explicitamente e/ou a ausência do conjunto no Output, de forma que a Response não tente inferir presença pela quantidade de itens.

Media type e status: `application/vnd.api+json`, `200` em sucesso; `422` para filtros inválidos; demais erros seguem o tratamento existente. Não criar exigência adicional de headers de entrada além da política atual da aplicação.

### 11. Identidade determinística do resumo

Derivar ID opaco de uma composição canônica da conta autenticada, `start_date`, `end_date` e modo (`total` ou `category` internamente). Uma implementação de hash determinístico deve usar delimitação ou estrutura canônica sem colisões de concatenação e retornar string opaca. O algoritmo concreto é detalhe técnico, não contrato para o cliente calcular ou decodificar.

Não incluir valores, lista atual de categorias, percentual, ordem original dos filtros, texto da URL, instante da requisição ou indicação de que o período foi explícito/default. Isso mantém o mesmo resumo reconhecível quando os dados mudam ou o cliente explicita o mês antes usado como default.

Não armazenar resumo ou ID em tabela. Não criar rota `/api/metrics/expenses/{id}`. O ID não é uma autorização; a conta sempre vem de autenticação e participa da nova consulta. Não expor seu identificador bruto em prefixo ou atributo do recurso.

### 12. Erros de query iguais ao padrão existente de Insights

O handler global de `ValidationException` em `bootstrap/app.php` usa `source.pointer`, apropriado aos campos de documentos de entrada que ele já atende. `GetInsightsRequest::failedValidation` usa formato específico de query com `source.parameter` e título `Parâmetro inválido`.

Metrics deve adotar o formato de query em sua borda HTTP, sem alterar o handler global ou refatorar os Requests existentes para um framework compartilhado de erro. Preservar:

```json
{
  "errors": [
    {
      "title": "Parâmetro inválido",
      "detail": "A data final deve ser igual ou posterior à data inicial.",
      "status": "422",
      "source": { "parameter": "end_date" }
    }
  ]
}
```

O título e os nomes dos campos fazem parte do padrão. A mensagem de detalhe deve explicar a regra em linguagem compatível com as mensagens existentes; o exemplo não exige um novo catálogo global nem códigos de erro adicionais. Cada erro reportado identifica seu parâmetro, inclusive o complementar ausente quando as datas não vierem juntas.

Erro não contém resultado parcial. Falha operacional não é erro de filtro e deve usar o tratamento existente apropriado; não converter toda exceção em `422` ou em total zero.

### 13. Proteções e composição da rota

Seguir o grupo atual de Insights: autenticação Sanctum, metadados autenticados, conta ativa, e-mail verificado, throttle autenticado e extensão de sessão. Essas políticas são herdadas, não decisões novas de Metrics. Não criar um limiter de gráficos ou ajustar a cota existente.

Registrar a rota no arquivo do contexto e conectá-la em `bootstrap/app.php`; registrar o provider em `bootstrap/providers.php`. O provider fornece o binding de `ExpenseMetricsPort` para `ExpenseMetricsAdapter`. Não duplicar o binding de `UserPort` nem registrar concretos que o container já resolve.

Auth/acesso seguem a precedência existente. Dentro de uma requisição admitida, validar filtros antes de consultar despesas. Chamadas `422` podem consumir a cota conforme a política autenticada atual; Metrics não tenta reembolsar a contagem.

### 14. Leitura atualizada sem cache

Cada consulta válida executa nova leitura. Não reutilizar o cache de páginas de Expense, salvar resumos, memorizar por dia/mês ou introduzir TTL. ID estável não significa conteúdo congelado.

Criação, mudança de valor/data/categoria e exclusão já confirmadas antes do novo snapshot devem ser refletidas. Isso vale para qualquer mecanismo existente que confirme uma escrita, sem pressupor ou criar funcionalidades de edição adicionais.

O limite da promessa é a nova leitura no banco: uma escrita concorrente pode ficar de fora se confirmada depois do snapshot. Não prometer sincronização em tempo real entre clientes, atualização durante a resposta ou eliminar caches externos que a infraestrutura não controla. A implementação deve evitar adicionar uma política que contradiga a atualização aprovada.

### 15. Registro das decisões confirmadas na conversa

| Decisão | Contrato consolidado | Requisitos relacionados |
| --- | --- | --- |
| Base financeira | `occurred_on`, nunca data de cadastro/pagamento/vencimento. | Cálculo por occurred_on. |
| 1 | Mês corrente inteiro, incluindo futuras já registradas. | Período padrão. |
| 2 | Datas juntas; apenas uma causa `422`. | Par completo. |
| 3 | Datas reais em `YYYY-MM-DD`, sem horário ou timezone. | Formato civil estrito. |
| 4 | Intervalo invertido causa `422`, sem troca automática. | Limites e ordem. |
| 5 | Limites inclusivos; dia único válido. | Limites e ordem. |
| 6 | Datas vazias não ativam defaults. | Valores vazios. |
| 7 | Intervalos futuros aceitos. | Intervalos explícitos. |
| 8 | Sem teto arbitrário de duração. | Intervalos explícitos. |
| 9 | Mês atual resolvido pelo timezone da aplicação. | Referência civil. |
| 10 | `group_by` ausente ou exatamente `category`; demais valores inválidos. | Agrupamento fechado. |
| 11 | Consulta agrupada também retorna total geral. | Dois modos e snapshot. |
| 12 | Somente categorias com despesas. | Categorias presentes. |
| 13 | Período sem despesas: `200`, zero, lista vazia quando agrupado, período informado. | Período vazio. |
| 14 | Centavos em strings inteiras, sem `currency`. | Total exato. |
| 15 | Total decrescente, categoria alfabética no empate. | Ordenação. |
| 16 | Identificador de categoria existente, sem nome traduzido; `other` normal. | Categorias presentes. |
| 17 | Conta autenticada somente; sem `user_id`. | Isolamento e acesso. |
| 18 | Parâmetros desconhecidos causam `422`. | Allowlist de nomes. |
| 19 | Arrays e objetos de filtros causam `422`. | Valores escalares. |
| 20 | Total e categorias no mesmo snapshot e reconciliados. | Snapshot. |
| 21 | Backend retorna percentual de cada categoria. | Percentual exato. |
| 22 | Duas casas, half-up e sem ajustar para somar cem. | Percentual e arredondamento independente. |
| 23 | JSON:API singular, categorias dentro do resumo. | Resumo JSON:API. |
| 24 | `categories` omitido sem agrupamento. | Resumo JSON:API. |
| 25 | Banco a cada consulta, sem cache de métricas. | Leitura sob demanda. |
| 26 | Filtros inválidos causam erro mesmo sem despesas. | Validação independente. |
| 27 | Conta ativa conforme restrição existente. | Acesso. |
| 28 | Contexto `Metrics`, separado de Insights. | Ownership. |
| 29 | Duplicatas causam `422`, mesmo iguais. | Repetição de filtros. |
| 30 | `expense-metrics`, ID opaco por conta/período/modo. | Identidade e JSON:API. |
| 31 | Trim externo somente; somente espaços é vazio inválido. | Normalização. |
| 32, corrigida após conferir o projeto | Query errors com título `Parâmetro inválido` e `source.parameter`. | Erros JSON:API de query. |

A pergunta subsequente baseada em uma inferência indevida foi descartada. Não existe requisito derivado dela e não há dependência de funcionalidades não confirmadas pelo usuário.

## Risks / Trade-offs

- **[Acoplamento ao schema] →** Isolar `user_id`, `occurred_on`, `amount` e `category` no Adapter e documentar a integração; não disfarçar acesso direto como import de outro contexto.
- **[Repetições perdidas pelo parser] →** Inspecionar query original e verificar casos com duplicatas iguais, diferentes, encoded e misturas de array/escalar. Testes construídos somente com arrays não demonstram esse comportamento.
- **[Middleware confunde vazio com ausência] →** Conservar presença original e não usar `null` como critério único para defaults.
- **[Alias normalizado em nome permitido] →** Verificar allowlist nos nomes recebidos e decodificados, não apenas no array com nomes transformados por PHP.
- **[Intervalos grandes custam mais] →** Agregar no banco, restringir conta/data, medir plano e tráfego representativo; não esconder custo com truncamento não aprovado. Não há promessa de SLA ou escala sem medição.
- **[Somas ou multiplicações excedem inteiro nativo] →** PostgreSQL numérico exato e aritmética pura de precisão arbitrária, sem float ou cast destrutivo.
- **[Percentual aparentemente não fecha cem] →** Contrato explícito de arredondamento independente, exemplos de 99,99% e 100,01%; totais monetários sempre reconciliam.
- **[Resultados diferentes de Insights] →** Documentar que Metrics usa mês inteiro e intervalos arbitrários; Insights tem janela e elegibilidade próprias. Não copiar regras interpretativas para Metrics.
- **[ID confundido com cache ou autorização] →** Separar identidade estável, conteúdo recalculado e escopo autenticado.
- **[Categorias vazias confundidas com agrupamento ausente] →** Representar modo explicitamente na Application e serializar ausência versus `[]` de forma intencional.
- **[Front converte string grande para Number] →** Manter contrato de centavos em string e orientar formatação sem perda de precisão; o backend não reduz valores para atender ao limite de JavaScript.
- **[Spec confundida com implementação concluída] →** Manter tarefas futuras abertas e evidências classificadas como planejadas; validação OpenSpec prova formato dos artefatos, não comportamento HTTP.

## Migration Plan

Não há migration, backfill, tabela de métricas ou serviço novo previsto. O trabalho futuro começa somente após autorização explícita de implementação:

1. Reconsultar versões e documentação relevantes, schema e índices pelo MCP, rotas e configuração efetiva; não assumir o runtime a partir deste documento.
2. Introduzir os tipos necessários de Domain/Application, contratos de leitura e UseCase concreto de Metrics.
3. Implementar Adapter com soma exata, filtros e snapshot consistente.
4. Implementar Request com inspeção da query original, Controller e Response JSON:API.
5. Registrar provider e rota com o mesmo grupo de proteções analíticas.
6. Atualizar a documentação arquitetural para reconhecer Metrics, leitura pelo schema e uso puro de aritmética exata; reconhecer o contexto nas verificações de fronteira.
7. Executar as verificações autorizadas, mapear evidências aos cenários e medir a consulta real no Lerd.
8. Publicar a rota após validação do contrato; front consome os fatos sem alteração obrigatória nos endpoints existentes.

Se surgir necessidade comprovada de migration, dependência ou índice, registrar o motivo e revisar o escopo antes de introduzir. Se migrations pendentes existirem na implementação, aplicar pelo Lerd antes de fluxos que dependam do schema, sem `migrate:fresh`.

Rollback da disponibilização remove registro da rota/provider e código da feature conforme o processo de deploy. Como a operação é somente de leitura e não cria estado analítico, não há dados de Metrics para migrar ou apagar.

## Open Questions

### Bloqueantes de produto

Nenhuma decisão de produto discutida permanece pendente. Todos os comportamentos aprovados estão mapeados acima e em cenários normativos.

### Gate antes de apply

O usuário solicitou escrever a spec, não implementar. É necessária autorização explícita para apply. A criação de testes também deve respeitar a restrição do projeto e ser autorizada no escopo futuro; as verificações abaixo e em `tasks.md` descrevem evidências esperadas, não execução ou criação de testes agora.

### Detalhes técnicos a verificar durante implementação

- API instalada para inspeção da query original sem normalização destrutiva.
- Formato concreto do hash de ID, permanecendo opaco e determinístico.
- Plano e custo de intervalos amplos sobre dados representativos; sem alterar o contrato por hipótese.
- Representação de datas extremas e valores agregados pelo driver PostgreSQL.
- Estrutura mínima de tipos puros para período e razão exata, sem boilerplate.

São escolhas e verificações de implementação, não filtros ou campos extras a inventar na primeira versão.
