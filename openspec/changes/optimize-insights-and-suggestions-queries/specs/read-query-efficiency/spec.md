## ADDED Requirements

### Requirement: EFF-01 Projeção analítica compacta e equivalente

Insights MUST preservar um statement PostgreSQL por análise, ownership, snapshot, períodos vigentes/encerrados e históricos, somas exatas acima de inteiro nativo, contagem de datas distintas e maior lançamento com seus desempates. MUST reduzir o trabalho intermediário de fatos repetidos antes das agregações por período, sem cachear fatos ou escrever despesas.

#### Scenario: Períodos sobrepostos e categorias na mesma data
- **WHEN** uma análise vigente inclui períodos sobrepostos e despesas de várias categorias na mesma data
- **THEN** totais, categorias, contagens e datas distintas permanecem equivalentes ao contrato atual
- **AND** máximo, descrição, data e categoria pertencem ao mesmo lançamento selecionado

#### Scenario: Histórico vazio e valores grandes
- **WHEN** períodos estão vazios ou somas de valores válidos excedem o inteiro nativo
- **THEN** mantém ausência contextual correta e valores exatos, sem overflow nem fatos inventados

### Requirement: EFF-02 Ranking histórico antes do detalhe das sugestões

Sugestões MUST preservar normalização POSIX de espaços externos, caixa, acentos/espaços internos, busca literal, ranking histórico global e desempates. MUST selecionar até cinco grupos no banco antes de calcular seus detalhes, considerando todos os registros relevantes das chaves finais para grafia e consistência monetária. MUST manter uma leitura financeira e IDs estáveis, sem limitar histórico pela janela monetária ou buscar cada sugestão pela Application.

#### Scenario: Mais de cinco grupos e grafias empatadas
- **WHEN** há mais de cinco grupos elegíveis, com empates de recência/frequência e variantes de grafia
- **THEN** conserva as mesmas cinco chaves ordenadas e a grafia do maior created_at/id de cada chave
- **AND** o limite não descarta registros divergentes da análise monetária

#### Scenario: Descrições antigas e busca literal
- **WHEN** existem descrições antigas fora da janela financeira ou termos com caracteres especiais
- **THEN** a elegibilidade/ranking histórico e busca literal são preservados
- **AND** somente os registros da janela financeira influenciam os valores

### Requirement: EFF-03 Melhoria medida com contratos preservados

A otimização MUST ser acompanhada de testes PostgreSQL existentes relevantes e comparação original/novo com mesma massa/referência e instrumentação declarada. MUST registrar plano, tempos individuais, equivalência e limitações. MUST NOT extrapolar medições locais para SLA/capacidade da VPS nem alterar recursos/cota para aparentar ganho.

#### Scenario: Comparação reproduzível
- **WHEN** as queries otimizadas são verificadas com a massa dedicada
- **THEN** resultados são confrontados com a implementação original no mesmo banco e contexto
- **AND** ganhos são informados somente onde medidos, com desvios/falhas preservados
