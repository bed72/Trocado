## MODIFIED Requirements

### Requirement: Múltiplas ordenações explícitas e determinísticas
sort MUST aceitar um a três campos distintos occurred_on/amount/description, na prioridade informada; prefixo - decrescente, sem prefixo crescente, id UUIDv7 DESC sempre como desempate final. Default MUST ser occurred_on DESC/id DESC. Critério desconhecido/duplicado/vazio/estrutura inválida MUST produzir 422. Comparação UUID do sort e seek MUST ser a mesma PostgreSQL; não presumir ordem de criação/inteiro a partir do UUID. Description MUST manter nullable/texto original e equivalência de caixa/acentos/canonical Unicode por ICU und-u-ks-level1 não determinística. COALESCE vazio MUST valer somente na chave interna, precedendo texto ASC e sucedendo DESC. Próximos critérios/UUID MUST resolver empates sem critério intermediário por bytes/grafia. Cursor MUST usar a mesma collation.

Nos cenários abaixo U11...U43 são rótulos de fixtures UUIDv7 canônicas distintas, não IDs numéricos enviados à API; dentro de cada grupo, a ordem PostgreSQL de UUID é a ordem crescente dos sufixos indicados. Isso mantém exemplos legíveis sem vincular ordenação a uma sequence.

#### Scenario: Data e valor com prioridade
- **WHEN** sort=-occurred_on,amount
- **THEN** ordena ocorrência mais recente, menor valor e UUID DESC

#### Scenario: Ordenações simples nos dois sentidos
- **WHEN** data/valor é ordenado ASC ou DESC
- **THEN** mantém direção e UUID DESC nos empates

#### Scenario: Descrição alfabética e desempate
- **WHEN** descrições são Aluguel e Mercado com description/-description
- **THEN** ordena respectivamente Aluguel/Mercado ou Mercado/Aluguel
- **AND** política equivalente usa próximos critérios/UUID

#### Scenario: Maiúsculas e acentos equivalentes nas duas direções
- **WHEN** Água U11, agua U12, ÁGUA U13, Aluguel U14 e Mercado U15 são ordenadas por description
- **THEN** a ordem é U13,U12,U11,U14,U15
- **AND** -description produz U15,U14,U13,U12,U11
- **AND** os textos originais são preservados

#### Scenario: Cedilha e acentos não criam grupos distintos
- **WHEN** Açaí U21, acai U22, ACAI U23 e Banana U24 são ordenados
- **THEN** description produz U23,U22,U21,U24 e -description U24,U23,U22,U21

#### Scenario: Próximo critério precede ID no empate alfabético
- **WHEN** Água amount 2000/U31, agua 1000/U32 e ÁGUA 1000/U33 usam description,amount ou -description,amount
- **THEN** a ordem é U33,U32,U31
- **AND** description,-amount produz U31,U33,U32

#### Scenario: Representações Unicode equivalentes
- **WHEN** texto difere somente por Á pré-composto ou A+acento combinante
- **THEN** description empata e próximos critérios/UUID DESC resolvem
- **AND** texto não é reescrito

#### Scenario: Cursor atravessa empate alfabético
- **WHEN** o cenário de equivalência usa size 2 e next/prev v2 nas duas direções
- **THEN** percorre a ordem UUID esperada sem omissão/repetição
- **AND** volta à primeira página com os mesmos UUIDs/textos

#### Scenario: Descrições nullable conservam dados e paginação
- **WHEN** há null U41, vazio U42 e Água U43
- **THEN** description produz U42,U41,U43 e -description U43,U42,U41
- **AND** size 1/next/prev conserva ordem sem perdas
- **AND** dados permanecem null/vazio/Água

#### Scenario: Ordenação inválida
- **WHEN** a consulta envia `sort=amount,-amount`, `sort=user_id`, `sort=amount,` ou array
- **THEN** 422 sem ordenação parcial
