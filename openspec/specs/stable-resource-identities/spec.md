# stable-resource-identities Specification

## Purpose
Definir o registro mínimo de Core que associa identidades lógicas de recursos a UUIDv7 duráveis por proprietário, preservando estabilidade, isolamento e resolução em lote sem armazenar fatos financeiros, resultados ou conteúdo editorial.

## Requirements
### Requirement: RID-01 Registro de Core guarda somente associação de identidade

Core MUST oferecer um registro transversal mínimo de `(owner UUIDv7, namespace, versão de identidade, chave lógica) → UUIDv7`, sem conhecer regras financeiras dos consumidores. MUST guardar somente UUID, owner, namespace, versão positiva, fingerprint lógico interno e instante de criação. MUST NOT guardar valor, percentual, contagem financeira, descrição, título/corpo, token, snapshot, resultado, visualização ou último acesso. Consumers MUST acessar contratos/UseCase/Data puros específicos de Core, sem Models/Infrastructure ou Service Locator.

#### Scenario: Primeira associação
- **WHEN** um consumidor fornece identidade lógica válida e ainda inexistente para owner autenticado
- **THEN** Core associa um UUIDv7 novo à chave
- **AND** a row não contém o resultado financeiro ou o texto do recurso

#### Scenario: Separação de conceitos
- **WHEN** Core recebe namespace e fingerprint opacos de Insights, Metrics ou sugestões
- **THEN** persiste/consulta a associação sem interpretar categoria, período, magnitude ou descrição
- **AND** o consumidor continua dono da composição de sua chave

### Requirement: RID-02 Identidade lógica canônica e sem ambiguidade

Consumers MUST construir chaves por componentes tipados e representação canônica não ambígua, com namespace e versão semântica explícitos. Owner/namespace/versão/chave distintos MUST distinguir associações. Fingerprint interno MUST NOT ser exposto como id ou usado como credencial. MUST NOT incluir números calculados, texto de apresentação, variante, ordem da URL ou versão editorial quando não mudam a identidade lógica. Descrição normalizada que define uma sugestão MUST continuar sendo parte de seu assunto, diferente da descrição editorial de uma despesa em Insights.

#### Scenario: Mesma chave com payload diferente
- **WHEN** owner/namespace/versão/componentes lógicos permanecem e valores/textos do recurso mudam
- **THEN** o UUIDv7 permanece igual

#### Scenario: Concatenação ambígua
- **WHEN** dois conjuntos de componentes distintos produziram a mesma concatenação simples sem delimitadores/tipos
- **THEN** a representação canônica os distingue
- **AND** não reutiliza identidade por ambiguidade de serialização

#### Scenario: Namespaces ou owners diferentes
- **WHEN** a mesma chave aparece para dois owners ou namespaces
- **THEN** cada associação tem seu próprio UUIDv7
- **AND** lookup não atravessa o escopo do owner

### Requirement: RID-03 Associação única e resolução concorrente

Persistência MUST proteger unicidade da chave composta e do UUID por constraints PostgreSQL. Duas criações simultâneas da mesma identidade MUST retornar o UUID do único vencedor confirmado, sem duplicatas, IDs perdedores ou update do UUID existente. Resolve MUST usar transação curta/retry limitado, ordem determinística e releitura com snapshot adequado após conflito. MUST NOT fabricar UUID de fallback ou supor que row concorrente esteja visível no snapshot de uma CTE anterior.

#### Scenario: Corrida da mesma identidade
- **WHEN** duas conexões novas resolvem simultaneamente a primeira associação da mesma chave/owner
- **THEN** ambas obtêm o mesmo UUIDv7 confirmado e somente uma row existe

#### Scenario: UUID candidato perdedor
- **WHEN** uma tentativa gera UUID candidato e perde para insert concorrente da mesma chave
- **THEN** devolve o ID persistido pelo vencedor
- **AND** não publica o candidato descartado

#### Scenario: Falha durante lote
- **WHEN** uma transação de associação falha após uma escrita anterior da tentativa
- **THEN** as escritas daquela tentativa sofrem rollback
- **AND** não há resposta parcial nem retry externo não transacional

### Requirement: RID-04 Resolução em lote com quantidade limitada de statements

Resolve MUST aceitar chaves finais em lote por owner, deduplicar chaves iguais e preservar correspondência/ordem da saída. Lote vazio MUST executar zero statements do registro. Hit completo MUST usar uma leitura em lote sem update de timestamp/row. Misses/conflitos MUST usar no máximo três statements do registro por tentativa, até três tentativas limitadas, independentemente do número de recursos; MUST NOT fazer query por cartão, sugestão ou categoria. Statements financeiros, auth e controle transacional MUST ser classificados separadamente.

#### Scenario: Zero recursos selecionados
- **WHEN** Insights ou sugestões não têm recursos finais
- **THEN** não cria/consulta associações nem placeholders

#### Scenario: Seis associações existentes
- **WHEN** seis Insights já possuem IDs
- **THEN** a resolução usa uma leitura em lote, sem writes de hits
- **AND** devolve IDs correspondentes na ordem dos recursos finais

#### Scenario: Lote misto
- **WHEN** cinco sugestões contêm chaves existentes e novas
- **THEN** cria somente ausentes em lote e reutiliza existentes
- **AND** statements por tentativa respeitam o teto e não crescem por sugestão

### Requirement: RID-05 Retenção durável e encerramento de conta

Associações MUST sobreviver a reinício, troca de processo, dia, token, SignOut e pruning, sem TTL ou regeneração periódica enquanto a conta existir. Remoção de conta MUST remover suas associações por cascade. Um recurso ausente temporariamente MUST reutilizar sua associação se a mesma identidade voltar a ser elegível. A existência de associação MUST NOT tornar o recurso elegível, servir dados financeiros antigos ou recriar owner apagado.

#### Scenario: Reinício e nova sessão
- **WHEN** o servidor reinicia e a mesma conta consulta a mesma identidade com outro PAT válido
- **THEN** recebe o mesmo UUIDv7 e fatos recalculados

#### Scenario: Sugestão desaparece e retorna
- **WHEN** a chave deixa de ter correspondências e depois volta para a mesma conta
- **THEN** a resposta vazia intermediária não é preenchida pelo registro
- **AND** o retorno reutiliza o UUID da identidade lógica original

#### Scenario: Encerramento concorrente
- **WHEN** a conta é excluída durante a primeira associação
- **THEN** constraints/transações não permitem identidade órfã nem recriação da conta
- **AND** recursos de outro owner permanecem

### Requirement: RID-06 Alocação posterior à validação e falha explícita

Consumers MUST validar entrada/owner, calcular/reconciliar fatos e compor seus recursos finais antes de criar associações. Falha de fonte, precisão, validação ou composição MUST NOT alocar IDs de recursos que não serão retornados. Falha do registro MUST produzir erro HTTP JSON:API existente sem coleção/resumo parcial, UUID aleatório/hash substituto ou resultado financeiro inventado. Erros/logs MUST NOT expor SQL/bindings, fingerprints/chaves lógicas, descrições, tokens ou dados de terceiros.

#### Scenario: Query rejeitada
- **WHEN** filtro/cursor inválido resulta em 422
- **THEN** o registro não é invocado nem recebe writes

#### Scenario: Composição falha no segundo cartão
- **WHEN** há candidato componível seguido de falha editorial
- **THEN** a resposta falha e nenhum lote de associações daqueles cartões é criado

#### Scenario: Fonte válida e registro indisponível
- **WHEN** a consulta financeira é válida mas a associação não pode ser resolvida
- **THEN** a API retorna falha explícita sem data parcial
- **AND** não devolve novo ID transitório para esconder o problema

### Requirement: RID-07 UUID estável não confere acesso ou endpoint individual

Os endpoints de projeção MUST continuar obtendo owner por autenticação e validando seus filtros, sem aceitar owner/namespace/fingerprint arbitrários do cliente. MUST NOT expor endpoint público de lookup/listagem do registro ou usar UUID como credencial. Associação de outro owner MUST NOT ser retornada mesmo se seu UUID/chave for conhecido. O registro MUST ser incluído no cleanup/lifecycle seguro de testes.

#### Scenario: UUID conhecido de outra conta
- **WHEN** uma conta conhece UUID de resumo/insight/sugestão de outra
- **THEN** isso não abre consulta individual ou muda o owner dos endpoints existentes

#### Scenario: Limpeza de testes
- **WHEN** uma execução registrada termina
- **THEN** associações do banco exclusivo são limpas sob guard de ownership
- **AND** nenhuma base/chave de outra execução é apagada
