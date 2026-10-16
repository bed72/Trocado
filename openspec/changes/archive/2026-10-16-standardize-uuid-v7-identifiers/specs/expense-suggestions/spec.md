## MODIFIED Requirements

### Requirement: Resposta JSON:API de sugestões transitórias
O endpoint MUST responder 200/data coleção expense-suggestions com ID UUIDv7 canônico estável para o mesmo owner UUID e chave normalizada, obtido pelo registro de Core. MUST distinguir owners/chaves sem identificar despesa específica ou publicar o fingerprint. description MUST manter apresentação atual; amount MUST existir somente pela consistência financeira, sem zero/média/null substituto. MUST NOT adicionar categoria/data/owner/frequência/timestamps. Histórico/busca sem matches MUST produzir data vazio e não resolver associações. Rota estática MUST continuar não sendo ID de despesa.

#### Scenario: Sugestão com valor
- **WHEN** descrição satisfaz busca e consistência
- **THEN** retorna type expense-suggestions, UUIDv7, description e amount exato

#### Scenario: Sugestão somente de descrição
- **WHEN** descrição corresponde sem base de valor
- **THEN** retorna UUIDv7/description e omite amount
- **AND** não preenche categoria/data

#### Scenario: Histórico ou busca vazios
- **WHEN** não há histórico/matches
- **THEN** 200/data vazio, sem alocação de identidade

#### Scenario: Identidade estável de sugestão
- **WHEN** owner pesquisa a mesma chave com termos diferentes ou cria variante de caixa
- **THEN** conserva UUIDv7 enquanto a chave normalizada não muda, inclusive após reinício
- **AND** outro owner recebe outro UUID

### Requirement: Leitura limitada sem efeitos no ciclo de vida de despesas
A funcionalidade MUST permanecer em Expense, com Repository financeiro próprio e uma leitura PostgreSQL de busca/fatos monetários por execução válida, sem ORM nas camadas internas, N+1, query por sugestão ou transferência de lançamentos individuais. UserPort MUST fornecer owner UUIDv7 explícito. MUST permitir somente associação auxiliar de identidade em Core por lote final, além dos efeitos atuais dos middlewares; não persistir sugestões/descriptions/valores, escrever despesas, chamar IA, despachar jobs ou cachear resultados. CRUD/default other/classificação MUST permanecer preservados. O registro MUST ser invocado depois de validar projeção e preparar a resposta, sem alias para o hash antigo.

#### Scenario: Quantidade constante de statements de despesas
- **WHEN** consulta válida retorna zero, uma ou cinco sugestões
- **THEN** usa um statement financeiro
- **AND** auth e resolução batch de IDs Core são classificados separadamente, não por sugestão

#### Scenario: Consulta sem efeitos em despesas ou categorização
- **WHEN** há/ausenta padrão de valor
- **THEN** despesas/tentativas ficam intactas
- **AND** não chama classificador, queue ou cache de sugestões
- **AND** somente middleware e associação mínima de identidade final são efeitos permitidos

#### Scenario: Cadastro após seleção da sugestão
- **WHEN** cliente usa sugestão e escolhe outro valor no create
- **THEN** Expense valida/persiste o documento atual com novo ID de despesa UUIDv7
- **AND** o UUID de sugestão não é ID de despesa nem obriga valor/categoria/periodicidade

#### Scenario: Associação existente sem candidatos
- **WHEN** há associação antiga mas a descrição não corresponde mais à busca/histórico
- **THEN** ela não faz uma sugestão reaparecer na resposta

#### Scenario: Falha do registro
- **WHEN** fonte financeira é válida mas Core não resolve os IDs
- **THEN** há falha JSON:API explícita sem dados parciais ou UUID transitório
