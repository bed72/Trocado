## MODIFIED Requirements

### Requirement: Categorias somente com despesas e identificadores estáveis

No modo agrupado, o sistema MUST retornar um item por categoria que tenha pelo menos uma despesa considerada no período. MUST NOT adicionar categorias sem registros, duplicar categorias ou retornar rótulos traduzidos. Cada item MUST conter `category`, `total_amount` e `percentage`. `category` MUST usar o identificador persistido do catálogo compartilhado `Core\Domain\Enums\ExpenseCategoryEnum`: `food`, `health`, `housing`, `leisure`, `shopping`, `services`, `transport`, `education`, `subscriptions`, `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations`, `travel` ou `other`. Todas as categorias MUST participar normalmente do total geral e do denominador dos percentuais, incluindo investimentos, financiamentos e `other`, sem serem ocultadas, renomeadas ou tratadas como registros inválidos. O total de cada categoria MUST seguir a mesma representação monetária exata do total geral.

#### Scenario: Categoria presente e categoria sem despesas
- **WHEN** o período contém duas despesas `food` e nenhuma `health`
- **THEN** `categories` contém um único item `food` com a soma das duas despesas
- **AND** não contém um item `health` com zero

#### Scenario: Other participa normalmente
- **WHEN** as únicas despesas consideradas pertencem a `other`
- **THEN** o total geral inclui todos esses valores
- **AND** o agrupamento contém `category: "other"` com participação `"100.00"`

#### Scenario: Identificador sem tradução
- **WHEN** a categoria considerada é `food`
- **THEN** o item usa `category: "food"`
- **AND** não inclui campo adicional de nome traduzido, cor ou ícone

#### Scenario: Cada nova categoria integra as métricas
- **WHEN** para cada um dos oito novos identificadores, o período contém um único lançamento de `"10000"` centavos naquela categoria
- **THEN** o total geral é `"10000"` e o único item agrupado usa o identificador persistido com `total_amount: "10000"` e `percentage: "100.00"`
- **AND** nenhuma categoria ausente é fabricada com zero

#### Scenario: Investimentos e financiamentos no mesmo denominador
- **WHEN** a conta tem `investments` de `60000`, `financing` de `30000` e `food` de `10000` centavos considerados no período
- **THEN** o total geral é `"100000"` e as participações são respectivamente `"60.00"`, `"30.00"` e `"10.00"`
- **AND** o modo sem agrupamento também retorna total `"100000"`
- **AND** as mesmas categorias de outra conta ou fora do período não entram nos totais

#### Scenario: Empate entre categorias novas
- **WHEN** `travel`, `investments` e `financing` têm o mesmo total considerado
- **THEN** os itens mantêm os identificadores originais e aparecem em ordem `financing`, `investments`, `travel`, conforme o desempate por identificador
