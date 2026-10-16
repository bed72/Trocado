## MODIFIED Requirements

### Requirement: Contexto Metrics dedicado a fatos quantitativos
Metrics MUST ser dono de totais/agrupamentos/percentuais, mantendo interpretação/mensagens em Insights. MUST NOT importar classes de negócio/Models/Repositories/UseCases/Responses de Expense, Identity ou Insights. A integração financeira MUST permanecer na Infrastructure por schema compartilhado, sem Model duplicado/escrita de despesas. Domain MUST ser puro e Application independente de Laravel/HTTP/ORM/Infrastructure. MUST permitir consumo específico da capacidade Core de UUIDv7 estável, que guarda somente identidade técnica, não fatos/resumos.

#### Scenario: Consulta quantitativa independente de Insights
- **WHEN** consulta totais próprios
- **THEN** entrega fatos de Metrics sem chamar geração/elegibilidade/seleção/composição de Insights
- **AND** não exige mínimo de lançamentos

#### Scenario: Integração somente de leitura
- **WHEN** calcula valores de despesas
- **THEN** lê schema somente na Infrastructure
- **AND** não modifica despesa/conta/configuração; somente associação técnica de identidade pode ser criada em Core

#### Scenario: Repository de leitura do contexto consumidor
- **WHEN** pede totais por owner/período/modo
- **THEN** usa seu Repository e projeções independentes do ORM
- **AND** não amplia CRUD Expense nem chama agregação de Port

#### Scenario: Conceitos puros compartilhados sem duplicação
- **WHEN** contextos usam centavos/períodos/razões/UUID
- **THEN** reutilizam os conceitos puros específicos de Core
- **AND** Core não importa consumidores/regras editoriais/financeiras

#### Scenario: Catálogo de categorias compartilhado
- **WHEN** Expense/Metrics reconhecem categoria
- **THEN** usam o enum compartilhado, sem duplicar/importar outro contexto
- **AND** cases/valores permanecem iguais
- **AND** Expense continua dono da categorização
- **AND** participações Metrics continuam até 100% e variações Insights podem exceder

### Requirement: Resumo singular em JSON:API com período efetivo
O sistema MUST responder 200/application/vnd.api+json com data singular expense-metrics, id string UUIDv7 canônico estável e start_date/end_date/total_amount atuais. Datas MUST ser efetivas/canônicas/não nulas inclusive default. Grouped MUST incluir categories como parcelas, não recursos/relationships; total simples MUST omitir categories, sem null/array substituto. MUST NOT publicar fingerprint ou ID numérico/hash alternativo.

#### Scenario: Total explícito em JSON:API
- **WHEN** outubro explícito soma 123456 centavos sem grouped
- **THEN** data tem type expense-metrics, UUIDv7, start_date 2026-10-01, end_date 2026-10-31 e total_amount "123456"
- **AND** sem categories/currency

#### Scenario: Resumo agrupado não é coleção de recursos
- **WHEN** group_by=category
- **THEN** data continua um objeto com UUIDv7
- **AND** categories ficam nos attributes, com category/total_amount/percentage
- **AND** sem included/outra coleção/paginação

#### Scenario: Default exposto ao consumidor
- **WHEN** período default é outubro/2026
- **THEN** expõe os limites 01–31/10
- **AND** não exige relógio do cliente

### Requirement: Identidade opaca e determinística do resumo
O sistema MUST obter UUIDv7 estável pela associação de Core para owner UUID, período efetivo e modo de agrupamento. A escolha da chave MUST ser determinística, mas o UUID MUST ser gerado legitimamente uma vez e persistido, nunca obtido por conversão de hash. MUST distinguir owners/períodos/modos; não depender de URL/trim/valores/visita nem expor owner/fingerprint na composição do ID. Default e limites explícitos equivalentes MUST identificar o mesmo resumo, inclusive zero total e após reinício/troca de PAT. O ID MUST NOT ser credencial ou exigir endpoint individual.

#### Scenario: Mesma consulta repetida
- **WHEN** owner consulta período/modo repetido em processo igual ou novo
- **THEN** id é o mesmo UUIDv7 confirmado

#### Scenario: Valores alterados mantendo o período
- **WHEN** escrita confirmada altera totais
- **THEN** valores mudam e UUID permanece

#### Scenario: Default e intervalo explícito equivalente
- **WHEN** default e datas explícitas resolvem o mesmo intervalo/modo
- **THEN** mesmo UUIDv7

#### Scenario: Ordem e espaços equivalentes
- **WHEN** muda somente ordem/trim aceito de filtros
- **THEN** UUID não muda

#### Scenario: Conta ou modo diferente
- **WHEN** owners diferem ou grouped alterna
- **THEN** os UUIDs distinguem os resumos
- **AND** não publicam owner/fingerprint

### Requirement: Leitura sob demanda sem cache ou estado analítico persistido
Métricas MUST consultar fatos a cada request válido sem cache próprio/páginas Expense/tabela de resumos/materialização/queue/job/chamada externa. MUST considerar alterações confirmadas no snapshot da nova leitura e não congelar conteúdo por UUID/dia/mês. MUST permitir somente associação auxiliar de Core para identidade estável, resolvida após reconciliação da projeção. UUID estável não torna valores imutáveis. Erros de fonte/projeção não alocam ID; falha Core responde erro, não resumo parcial/zero fabricado.

#### Scenario: Criação entre duas consultas
- **WHEN** 10000 centavos viram 12500 por nova despesa confirmada
- **THEN** novo total "12500", com mesmo UUID
- **AND** sem aguardar TTL/invalidação

#### Scenario: Edição de valor ou ocorrência
- **WHEN** valor/data muda antes da leitura
- **THEN** resumo reflete fatos atuais, não row de resultado no registro

#### Scenario: Categoria atualizada
- **WHEN** other vira food
- **THEN** distribuição reflete categoria atual
- **AND** total e UUID não mudam somente pela recategorização

#### Scenario: Exclusão confirmada
- **WHEN** despesa é removida
- **THEN** total/distribuição atualizam, preservando UUID da consulta
- **AND** não resta valor em tabela de resumos

#### Scenario: Resumo zero também tem identidade
- **WHEN** período válido não tem fatos
- **THEN** total "0" usa UUIDv7 associado à mesma consulta
- **AND** futuras despesas mudam o conteúdo sem regenerar ID
