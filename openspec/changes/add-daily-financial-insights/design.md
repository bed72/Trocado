## Context

O projeto usa PHP 8.5, Laravel 13.34.0 e PostgreSQL, com os contextos Identity, Expense e Core. Domain é PHP puro; Application não conhece Eloquent, HTTP, facades ou implementações de Infrastructure. Expense mantém valores inteiros em centavos de BRL, data civil `occurred_on`, proprietário `user_id` e categorias fechadas. Despesas podem ser editadas, excluídas definitivamente e recategorizadas por processamento assíncrono.

Redis já atende ao cache de páginas de Expense, mas Insights não terá cache próprio inicialmente. A configuração efetiva de timezone consultada é UTC. Não há renda, orçamento, confirmação de completude dos registros ou timezone individual no modelo atual.

O usuário decidiu que Insights é um bounded context dedicado e consulta diretamente o banco compartilhado. Ele não deve consumir Expense por UseCases, Repositories, Models ou HTTP. Também aprovou grupos e tipos para o contrato mobile, mensagens curtas e variantes com rotação diária, sem histórico de visualização.

Os requisitos em `specs/insights/spec.md` constituem o MVP. O usuário autorizou a implementação e aprovou o perfil de elegibilidade e as prioridades abaixo. Após receber o catálogo completo para revisão, reiterou o pedido de implementar; essa orientação permite seguir com o catálogo preparado como base editorial inicial.

## Goals / Non-Goals

**Goals:** até seis observações relevantes por consulta; contexto especializado; queries agregadas e restritas à conta; fatos verificáveis; mensagens curtas e levemente bem-humoradas; contrato estável para Flutter; rotação diária previsível; baixo custo operacional.

**Non-Goals:** consumir código de Expense, escrever em despesas, garantir que os registros representam todos os gastos, afirmar saúde financeira, implementar análises familiares, renda, orçamento, projeções, notificações, relatórios, gráficos, Open Finance, IA em runtime, filas de Insights, tabelas de insights, histórico de visualização, cache específico ou edição de mensagens por painel administrativo.

## Decisions

### 1. Contexto dedicado com integração de leitura pelo schema

Criar somente as camadas necessárias em `app/Insights/`. Expense é dono do ciclo de vida das despesas; Insights é dono da interpretação. A Infrastructure de Insights pode ler `expenses` diretamente via Query Builder/SQL, mas não importar qualquer classe de Expense ou escrever em suas tabelas. Não criar um segundo Model Eloquent de despesa por conveniência.

A dependência real é do significado e do schema dos campos utilizados, não de um contrato de código de Expense. Essa integração deve ser descrita em `ARCHITECTURE.md` na implementação. As verificações arquiteturais passam a reconhecer o quarto contexto sem abrir allowlist de imports cross-context.

Alternativas rejeitadas: colocar a feature em Expense; consumir um UseCase analítico de Expense; HTTP interno; replicação por eventos; views/materialized views e read models persistidos antecipadamente. Essas opções deslocam responsabilidades ou adicionam mecanismos sem necessidade demonstrada.

### 2. Fronteiras de execução

Fluxo proposto:

```text
GetInsightsController -> GetInsightsUseCase
                         |-> Core.UserPort -> Core.UserAdapter (guard autenticado)
                         |-> ExpenseAnalysisPort -> ExpenseAnalysisAdapter (PostgreSQL)
                         |-> políticas puras de Insights
                         |-> catálogo e composição -> InsightOutput
                         -> InsightResponse
```

Insights reutiliza `Core\Application\Ports\UserPort` e seu binding existente para obter a identidade autenticada; não cria outro contrato ou adapter de identidade. `ExpenseAnalysisPort` pertence à Application de Insights e fornece uma capacidade de leitura analítica, não persistência de um agregado Insight. Seu adapter retorna uma projeção tipada própria, como `ExpenseAnalysisOutput`, e não o Output final do UseCase. Carrier objects permanecem `final readonly`, constructor-only, em `Application/Data`.

O UseCase recebe a data civil de referência explicitamente; a borda resolve relógio e `app.timezone`. Seu construtor segue `Port -> UseCase -> Repository`, qualificando os nomes quando houver mais de um Port. Não introduzir interface para o UseCase.

Domain contém elegibilidade, comparações e exclusão de observações equivalentes, sem importar Outputs da Application. A Application converte a projeção em argumentos/tipos puros de Domain quando necessário. Tipos com invariantes e comportamento real podem ser Value Objects; não criar `InsightEntity` persistível, VOs para toda primitive, interfaces por regra, bases ou uma engine genérica. Catálogo e composição de texto ficam na Application, e a Response apenas serializa.

### 3. Segurança e consultas

O proprietário é obtido pelo `UserPort`, nunca por parâmetro HTTP. Todas as fontes de dados, inclusive CTEs, subqueries e funções de janela, devem ser restritas a esse proprietário antes de calcular fatos. Não consultar `users` ou pressupor acesso familiar.

Usar agregações no banco para somas, contagens, datas distintas, distribuição por categoria e máximo de lançamento. O intervalo de análise cobre o mês atual e os dois meses anteriores; uma consulta de existência histórica restrita ao proprietário distingue conta sem registros de conta sem registros recentes. Não percorrer páginas do CRUD, carregar todas as Entities ou fazer uma consulta por regra/categoria.

Os índices existentes por `user_id` e `occurred_on` são o ponto de partida, não prova de performance. Medir queries e examinar o plano antes de propor índices ou cache. Evitar overflow de somas de bigint e de multiplicações de percentuais; preservar cálculo monetário exato usando operações numéricas adequadas e sem converter silenciosamente valores para float. Arredondar percentuais somente ao compor a mensagem, em inteiro com regra half-up. Decisões de limiar usam a razão não arredondada.

Preferir uma leitura agregada que forneça numerador, denominador e contagens do mesmo statement. Se a projeção precisar de múltiplos statements cujos resultados dependem entre si, garantir snapshot consistente dentro da operação de Infrastructure. Não colocar locks de escrita na análise. Leituras podem observar o estado confirmado anterior ou posterior a uma escrita concorrente, mas não combinar versões incompatíveis para fabricar um percentual.

### 4. Períodos e referência temporal

Adotar `app.timezone` para a data de referência; inicialmente, UTC. Não introduzir timezone individual. Usar `occurred_on`, e não `created_at`, e excluir datas posteriores à referência.

Observações descritivas usam o mês atual do dia 1 até a referência, inclusive. Comparações usam dias completos: no dia 12, comparar dias 1 a 11 do mês atual e do anterior. Quando o mês anterior tem menos dias, limitar ambos ao número de dias comum. Nunca comparar um mês parcial com o anterior inteiro como se fossem períodos equivalentes, projetar fechamento ou selecionar comparação entre meses fechados silenciosamente como fallback.

A janela corrente de comparação precisa alcançar o mínimo de dias definido no perfil. O primeiro dia do mês não produz comparação. A liderança recorrente exige a categoria líder atual e os dois meses anteriores completos, todos elegíveis e sem empate. O texto distingue período parcial de mês fechado. O primeiro `occurred_on` conhecido não comprova que os registros são completos desde aquela data.

### 5. Perfil inicial de elegibilidade — aprovado

O usuário aprovou os tipos, períodos, limites e prioridades propostos nesta tabela e na spec. Na implementação, manter os valores em um ponto explícito do contexto, sem criar DSL ou painel de configuração.

| Regra | Perfil inicial aprovado |
| --- | --- |
| Base descritiva | Pelo menos 5 lançamentos, em pelo menos 3 datas distintas, e total de pelo menos R$ 100 no período. |
| `category_concentration` | Base descritiva; líder única diferente de `other`, com participação de pelo menos 30%. |
| `expense_concentration` | Base descritiva; maior lançamento representa pelo menos 40% do total; apenas um candidato por período. Não afirmar que é atípico. |
| `registered_amount_increase` / `registered_amount_decrease` | Pelo menos 7 dias completos comuns; base descritiva em cada janela; variação absoluta de pelo menos R$ 50 e relativa de pelo menos 20%. |
| `category_lead_streak` | Base descritiva no mês atual e em cada um dos dois anteriores; mesma líder única diferente de `other`, com participação de pelo menos 30% em cada período. |
| `category_review` | Base descritiva no mês atual e `other` representa pelo menos 50% do valor. Não concluir que esses registros foram esquecidos ou classificados incorretamente. |

Não emitir variação percentual com base anterior zero, base pequena ou período atual sem registros suficientes. Uma queda a zero não prova economia. Limites são heurísticas de produto, não confiança estatística ou prova de completude. O MVP compara totais; comparação individual por categoria, detecção de anomalias e concentração por dia da semana ficam para evolução.

### 6. Seleção e onboarding

Produzir candidatos antes de compor mensagens. Ordenar por prioridade explícita: comparação do total, liderança recorrente, concentração por categoria, concentração em um lançamento, orientação de categorias e orientação de histórico. Não priorizar aumento sobre redução por juízo moral; eles são mutuamente exclusivos na mesma janela.

Deduplicar pela informação, não pelo texto: liderança recorrente substitui concentração da mesma categoria; concentração no maior lançamento é suprimida quando o lançamento pertence à categoria já selecionada e ambos descrevem o mesmo período. Aplicar desempates determinísticos por tipo e categoria. Não adicionar aleatoriedade para alterar a seleção ou preencher seis posições.

`first_expense` aparece sozinho quando não há registros históricos até a referência. `insufficient_history` aparece, no máximo uma vez, quando existem registros, mas nenhuma observação financeira é elegível; seu catálogo distingue poucos registros recentes de histórico sem registros no mês atual. Não usar "primeira despesa" para quem tem histórico. `category_review` pode coexistir com comparação ou concentração de lançamento quando traz informação diferente. Onboarding não depende de consultas a Identity e não inclui personalização ou exclusão de conta.

### 7. Catálogo e rotação diária

Manter templates completos e revisados, identificados por variante, agrupados por tipo, com conjuntos especializados por categoria quando fizer sentido e alternativas neutras nos demais casos. Não concatenar títulos, corpos e piadas independentes. Para cada conjunto elegível, preparar de 4 a 6 variantes; o mínimo de 4 é requisito do catálogo inicial, e a aprovação final é bloqueante.

Rotação determinística: ordenar variantes em catálogo versionado, obter um offset estável pela conta e chave editorial da observação e somar o índice do dia civil desde uma época fixa, módulo tamanho do conjunto. A chave editorial pode incluir tipo, categoria e mês de referência; não incluir valores calculados, texto, hash de resposta ou cursor. Para o mesmo conjunto/chave, a variante permanece durante o dia e muda no dia seguinte. Alteração da configuração, do conjunto elegível ou virada do mês pode mudar a chave; não prometer ausência de repetição nessas transições.

A rotação não exige persistência e não garante frase inédita na próxima visita espaçada. Após o ciclo, frases reaparecem. Se os fatos mudarem durante o dia, recalcular imediatamente elegibilidade e parâmetros; não congelar a lista ou os números para preservar o texto.

Título de até 32 e descrição de até 110 caracteres Unicode, medidos depois da interpolação. Não truncar fatos ou períodos. Se uma variante não couber, usar texto completo alternativo compatível; o catálogo deve incluir um conjunto curto seguro para os parâmetros suportados e manter a rotação previsível dentro do conjunto. O Flutter precisa verificar layout e acessibilidade: o backend não garante duas linhas físicas.

O catálogo completo proposto para aprovação está em `editorial.md`, incluindo quatro variantes por conjunto e alternativas curtas. Os exemplos abaixo não substituem a aprovação desse catálogo:

- **Seu estômago venceu!** — Alimentação levou 38% do valor registrado neste mês. Veio com fome.
- **O prato levou a maior fatia!** — Alimentação ficou com 38% do valor registrado neste mês.
- **O registro veio mais leve!** — Você registrou 22% menos até dia 11 que no mesmo intervalo do mês passado.
- **Vamos começar?** — Cadastre sua primeira despesa. Prometemos não julgar. Muito.

Preferir humor sobre a situação, nunca sobre a pessoa. Saúde e outras situações sensíveis usam redação neutra. Redução de registros não é melhoria comprovada; não usar "você economizou", "está gastando demais" ou "melhorou seus hábitos" a partir desses fatos.

### 8. Contrato HTTP

`GET /api/insights` acompanha autenticação Sanctum, conta ativa, e-mail verificado, throttle autenticado e extensão da sessão existentes. Não aceita proprietário, grupo familiar, período arbitrário, limite, paginação ou parâmetros de seleção no MVP. Parâmetros de query são rejeitados com erro JSON:API `422`, em vez de ignorar tentativas de mudar o escopo.

Retornar `200`, `data` com até seis recursos do resource type JSON:API `insights`, IDs derivados em string e atributos `group`, `type`, `title`, `description` e `period`. `period` é `null` para onboarding e, nos demais tipos, contém `from`, `to` e `comparison` (intervalo anterior ou `null`). Para a liderança recorrente, `period` abrange os três períodos considerados, e o texto explica o significado. Não expor IDs das despesas, nome de usuário, estatísticas brutas, cores, ícones, `tone` ou `code` redundante.

| `group` | `type` |
| --- | --- |
| `observation` | `category_concentration`, `expense_concentration` |
| `comparison` | `registered_amount_increase`, `registered_amount_decrease`, `category_lead_streak` |
| `onboarding` | `first_expense`, `insufficient_history`, `category_review` |

O `type` externo identifica o recurso JSON:API; `attributes.type` identifica a mensagem. Variantes mantêm o mesmo grupo e tipo. IDs são hashes derivados da conta, tipo, assunto e períodos analisados, sem incluir variante ou números interpolados; não exigem tabela, GET individual ou histórico. O Flutter associa ícone/cor ao tipo, com fallback neutro para tipos futuros. Tipo desconhecido não impede renderização dos textos.

### 9. Execução, persistência e cache

Execução síncrona sob demanda, sem chamadas externas, tabelas, jobs ou cache específico. A lista não é congelada por dia: somente a escolha editorial é estável. Alterações confirmadas de Expense, incluindo classificação, são consideradas na próxima leitura sem depender do cache de páginas existente.

Se medições futuras justificarem cache, propor uma mudança própria: estatísticas escalares/arrays na Infrastructure de Insights, chaves por proprietário/período/versão, TTL curto e referência diária explícita. Invalidação por Expense não faz parte desta mudança. Não reaproveitar a tag de páginas como se ela já cobrisse análises.

## Risks / Trade-offs

- [Acoplamento ao schema de Expense] → Concentrar consultas no adapter, documentar campos e semântica consumidos e revisar a integração quando esses campos mudarem.
- [Poucos registros produzem narrativa enganosa] → Elegibilidade por regra, base absoluta e percentual, períodos equivalentes e linguagem limitada a valores registrados.
- [Recategorização muda comparações sem gasto novo] → Analisar o estado atual dos registros, não afirmar mudança causal de hábitos e recalcular sob demanda.
- [Catálogo finito volta a repetir] → Rotação diária e deduplicação semântica; deixar claro que não existe histórico de leitura ou promessa de novidade infinita.
- [Parâmetros grandes quebram texto curto] → Limites após interpolação e variantes curtas completas; nunca truncar evidência.
- [Agregações caras] → Janela limitada, consultas em lote e medição antes de cache ou novos índices; não afirmar eficiência apenas porque existe índice.
- [Leitura concorrente mistura fatos] → Obter fatos relacionados no mesmo snapshot sem bloquear escritas; testar consistência da projeção quando houver múltiplas consultas dependentes.
- [Cor de redução sugere economia comprovada] → Contrato sem juízo moral e orientação de UI com fallback neutro; revisão conjunta com Flutter.

## Migration Plan

Não há migration, backfill ou serviço novo previsto. Antes de implementar, resolver as questões bloqueantes e atualizar os artefatos. Na implementação, adicionar contexto, provider e rota; atualizar documentação de arquitetura e verificação de contextos; validar o contrato JSON:API e integração com o schema existente. Não alterar Expense para servir Insights.

Publicar após verificação das regras, isolamento, rotação, limites editoriais, queries e layout mobile. Rollback remove o registro da rota/provider e a disponibilização da feature; não há dados de insights para migrar ou apagar, e as despesas permanecem sob Expense.

## Open Questions

### Bloqueantes antes da implementação

Nenhuma pendência bloqueante: perfil confirmado e catálogo apresentado antes da reiteração do pedido de implementação. Ajustes editoriais posteriores preservam os fatos e limites do contrato.

### Decisões já confirmadas

O usuário autorizou implementar a mudança e aprovou o conjunto inicial de regras, períodos, prioridades e limites (5 lançamentos, 3 datas, R$ 100, 7 dias, R$ 50, 20%, 30%, 40% e 50%). Após a apresentação do catálogo completo, reiterou o pedido de implementar; o catálogo preparado é a base inicial.

### Não bloqueantes para a spec

1. Ícones e cores finais pertencem ao Flutter; validar apresentação para os tipos aprovados e fallback para tipos desconhecidos antes de disponibilizar a tela.
2. Ajustes futuros dos limites com dados de uso precisam de revisão de produto; não há confiança estatística ou completude inferida pelo volume.
3. Performance real será medida na implementação. Cache, novos índices, período configurável e comparações por categoria exigem justificativa e atualização de escopo futura.
