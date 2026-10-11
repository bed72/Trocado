## ADDED Requirements

### Requirement: Rótulos e análise das categorias expandidas
Insights MUST reconhecer os identificadores `financing`, `investments`, `taxes`, `insurance`, `personal_care`, `pets`, `gifts_and_donations` e `travel` com os rótulos editoriais integrais “Financiamentos”, “Investimentos”, “Impostos e taxas”, “Seguros”, “Cuidados pessoais”, “Pets”, “Presentes e doações” e “Viagens”, respectivamente. MUST preservar os rótulos existentes e tratar as novas categorias como elegíveis nas mesmas regras de concentração, liderança e comparação de valores registrados. Investimentos e financiamentos MUST participar dos totais e denominadores conforme o período e proprietário selecionados; MUST NOT inferir consumo, prejuízo, retorno, patrimônio ou capacidade financeira com base nesses registros. Os textos interpolados MUST respeitar os limites editoriais vigentes com alternativas completas, sem truncar rótulo, fatos ou período e sem falhar por ausência de rótulo para categoria válida. As novas categorias MUST NOT alterar os grupos, tipos e envelope JSON:API existentes.

#### Scenario: Concentração de cada nova categoria
- **WHEN** cada uma das oito novas categorias é líder única, tem 40% do total registrado e a base descritiva mínima está atendida
- **THEN** um candidato de concentração pode produzir mensagem com o rótulo integral correspondente e participação factual
- **AND** não ocorre exceção por categoria sem rótulo nem afirmação sobre excesso ou renda

#### Scenario: Investimentos no total e na interpretação
- **WHEN** cinco lançamentos em pelo menos três datas somam `100000` centavos no período, dos quais `60000` são `investments`
- **THEN** a concentração pode informar “Investimentos” com participação de 60% do valor registrado
- **AND** os aportes não são excluídos do denominador nem apresentados como consumo, prejuízo ou rendimento

#### Scenario: Liderança recorrente de nova categoria
- **WHEN** `financing` lidera isoladamente os três períodos analisados com base e participação mínimas atendidas
- **THEN** a liderança recorrente usa o rótulo “Financiamentos” e os períodos corretos conforme o modo de análise
- **AND** preserva a prioridade e deduplicação existentes

#### Scenario: Rótulos longos e alternativas compactas
- **WHEN** “Presentes e doações”, “Cuidados pessoais” ou “Impostos e taxas” são interpolados nas variantes aplicáveis de concentração, liderança ou identificação de lançamento
- **THEN** todos os pares entregues respeitam os limites editoriais vigentes, inclusive 24 caracteres de título e 80 de descrição quando esse contrato estiver vigente
- **AND** alternativas preservam o rótulo integral, magnitude exigida e referência temporal, sem corte ou ampliação dos limites

#### Scenario: Viagem não implica narrativa sobre o usuário
- **WHEN** os lançamentos de `travel` tornam elegível uma observação
- **THEN** a mensagem usa “Viagens” e somente fatos registrados
- **AND** não inventa destino, finalidade pessoal ou capacidade de viajar
