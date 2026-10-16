## MODIFIED Requirements

### Requirement: Contrato JSON:API por grupo e tipo
O sistema MUST responder 200/data coleção insights com ID string UUIDv7 canônico estável e attributes group/type/title/description/period. MUST manter observation(category_concentration/expense_concentration), comparison(registered_amount_increase/decrease/category_lead_streak) e onboarding(first_expense/insufficient_history/category_review). Variantes MUST manter grupo/tipo. IDs MUST distinguir owner/tipo/assunto/estado/períodos por associação mínima de Core, sem texto/números/versão editorial e sem expor fingerprint/hash alternativo. MUST NOT persistir cartão/resultado ou criar endpoint individual pelo UUID.

period MUST ser null em onboarding e from/to/comparison nos financeiros com Y-m-d; comparação anterior MUST ser explícita no total e null nos demais; liderança MUST cobrir três períodos. MUST NOT devolver cor/ícone/código redundante/julgamento/ID de despesa/perfil. Flutter MUST usar attributes.type e admitir fallback visual neutro para tipo desconhecido. Sem paginação; associação estável não altera texto/data recalculados.

#### Scenario: Cartão financeiro para Flutter
- **WHEN** seleciona concentração de categoria
- **THEN** recurso UUIDv7 tem observation/category_concentration/texto/período corretos
- **AND** cliente não calcula razão/limiares

#### Scenario: Comparação com intervalos explícitos
- **WHEN** referência é 12/10/2026 e o total corrente é comparado
- **THEN** from 2026-10-01/to 2026-10-11 e comparison 2026-09-01 a 2026-09-11, com UUIDv7

#### Scenario: Cartão de onboarding
- **WHEN** retorna first_expense
- **THEN** UUIDv7, group onboarding, period null e par completo

#### Scenario: Tipo futuro desconhecido pelo cliente
- **WHEN** cliente recebe tipo sem mapeamento visual
- **THEN** renderiza título/descrição com aparência neutra
- **AND** não rejeita coleção nem deriva regras do UUID

### Requirement: Geração sob demanda sem estado analítico persistido
Insights MUST recalcular fatos/candidatos/textos sob demanda, sem persistir cartão, visualização, resultado financeiro, cache próprio ou processamento assíncrono. MUST permitir somente associação técnica de identidade em Core, resolvida em lote após validar/selecionar/deduplicar/compor todos os recursos. Agregação financeira MUST permanecer limitada/em lote/snapshot consistente, sem query por regra/categoria ou reutilização de páginas Expense. Falha de leitura/precisão/composição/registro MUST produzir falha HTTP JSON:API explícita, sem lista parcial, onboarding fabricado, hash ou UUID transitório de fallback.

#### Scenario: Categoria alterada após o cadastro
- **WHEN** classificação confirmada muda categoria
- **THEN** a próxima consulta recalcula candidatos
- **AND** não depende de cache Expense; identidade é reutilizada só se a chave lógica continuar igual

#### Scenario: Exclusão ou edição confirmada
- **WHEN** despesa é removida ou valor/data muda
- **THEN** a resposta usa fatos confirmados atuais
- **AND** não recupera cartão/conteúdo congelado do registro

#### Scenario: Histórico extenso
- **WHEN** há vários anos de despesas
- **THEN** fonte financeira usa janela limitada/existência histórica
- **AND** não pagina CRUD ou instancia cada despesa

#### Scenario: Falha de acesso ao banco
- **WHEN** leitura financeira falha
- **THEN** responde erro JSON:API
- **AND** não aloca ID nem inventa ausência/percentual

#### Scenario: Falha de associação
- **WHEN** textos finais válidos não conseguem UUIDs confirmados no Core
- **THEN** resposta falha sem data parcial/ID aleatório

### Requirement: Identidade e períodos preservados na navegação mensal
O sistema MUST manter type/attributes/grupos/tipos/period/limite seis. UUIDv7 associado MUST distinguir owner/tipo/assunto/estado/from/to internos e comparação, incluindo onboarding com period null. MUST NOT depender de forma da URL/números/descrição/variante/dia de visita/versão editorial por si só; UUID MUST permanecer após reinício, sessão e desaparecimento temporário da mesma identidade. Comparações/liderança MUST manter períodos atuais. MUST NOT adicionar estado de navegação, ID de despesa, novos tipos/paginação. Fonte/eligibilidade continua autorizando seleção, nunca existência da associação.

#### Scenario: Período histórico público
- **WHEN** setembro selecionado compara agosto
- **THEN** from/to setembro 01–30 e comparison agosto 01–31, com UUIDv7 estável

#### Scenario: IDs não são texto ou dia de visita
- **WHEN** owner/tipo/assunto/estado/períodos históricos não mudam, mas números/variante mudam
- **THEN** UUIDv7 permanece, inclusive em outro processo
- **AND** outro mês distingue identidade

#### Scenario: Onboarding de meses distintos
- **WHEN** agosto/setembro retornam insufficient_history period null
- **THEN** cada período interno resolve UUIDv7 distinto e texto contextual

#### Scenario: Vigente avança limite efetivo
- **WHEN** a mesma conta consulta o vigente em outro dia e o período interno cresce
- **THEN** a chave/UUID da observação pode mudar pelo período, não apenas pela rotação

#### Scenario: Default e zeros normalizados
- **WHEN** default/seleção explícita/zeros à esquerda representam os mesmos períodos
- **THEN** mesmos UUIDv7 e fatos no mesmo dia
