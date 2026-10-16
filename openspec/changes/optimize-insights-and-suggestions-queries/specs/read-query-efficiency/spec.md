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

### Requirement: EFF-04 Busca indexável com equivalência literal e custo demonstrado

Uma próxima otimização de sugestões MUST preservar substring literal, normalização POSIX/caixa, diferenças de acentos/espaços internos, ranking histórico, grafia, janela monetária, ownership e IDs. MUST avaliar seletividade e compatibilidade entre predicado, expressão/collation e operador do índice antes de aprovar DDL. MUST medir termos amplos, seletivos, curtos, especiais e sem resultados, incluindo custo de escrita/armazenamento. MUST NOT presumir que um índice de trigramas acelera strpos, aplicar fuzzy search ou criar projeção financeira persistida como parte dessa alteração.

#### Scenario: Candidato indexável contém caracteres especiais
- **WHEN** um experimento substitui o filtro atual por operador compatível com índice e o termo contém porcentagem, underscore, barra invertida ou aspas
- **THEN** o termo continua literal, com bindings e escaping apropriado
- **AND** chaves, ordem, grafias e valores finais são equivalentes ao contrato atual

#### Scenario: Termo curto ou busca pouco seletiva
- **WHEN** o termo não fornece trigramas úteis ou corresponde a quase todo o histórico
- **THEN** o experimento registra plano/tempo e limitações dessa dimensão
- **AND** não força índice nem altera elegibilidade/comprimento mínimo para aparentar melhoria

#### Scenario: Benefício de índice não demonstrado
- **WHEN** a estratégia candidata não melhora o workload relevante ou seu custo de manutenção não é justificado
- **THEN** o step registra a decisão de não aplicar DDL ou propõe outro experimento
- **AND** não declara índice implementado/melhoria comprovada

#### Scenario: Amostragem escolhe uma estratégia de execução
- **WHEN** a consulta usa uma amostra para escolher entre caminhos SQL equivalentes
- **THEN** a amostra não limita os registros que participam do ranking histórico, grafia ou análise monetária
- **AND** ambos os caminhos preservam chaves, ownership, ordem e IDs, mesmo quando os registros relevantes estão fora da amostra

### Requirement: EFF-05 Redução de trabalho de sessão preserva validade e revalidação

Uma otimização de Identity MUST separar autenticação, tracking last_used_at e renovação. MUST preservar validade inicial 30 dias, janela inclusiva de 15, teto absoluto 90, revogação/expiração, token/issued_at imutáveis e ausência de extensão em requests rejeitados. Fast path MUST ter prova explícita sobre estado Eloquent possivelmente antigo e MUST revalidar persistência atomicamente antes de qualquer extensão. Mudança de tracking MUST depender de decisão sobre consumidores/auditoria e usar API suportada da versão instalada, sem vendor patch/cache de autenticação. Ganhos de concorrência MUST exigir medição de espera/roundtrips, sem confundir competição pelo mesmo PAT com limiter por conta.

#### Scenario: Request sem necessidade de renovação
- **WHEN** a sessão não é elegível para extensão segundo o estado validado pelo algoritmo aprovado
- **THEN** não estende expires_at nem emite token novo
- **AND** uma redução de locks/roundtrips é medida e não tratada como permissão para ignorar a autenticação

#### Scenario: Persistência muda após autenticação
- **WHEN** outro processo estende, encurta, expira ou revoga o PAT depois de sua leitura inicial
- **THEN** o algoritmo preserva o contrato documentado de renovação sem ressuscitar token nem sobrescrever extensão válida
- **AND** a prova usa conexões independentes e corrida sincronizada, além dos casos sequenciais

#### Scenario: Política de último uso ainda não decidida
- **WHEN** o custo de last_used_at é candidato mas seus consumidores ou sua política não foram decididos
- **THEN** o tracking existente permanece e a decisão pendente fica explícita
- **AND** uma tentativa de save não é relatada como UPDATE em toda chamada sem observar dirty state/cadência

### Requirement: EFF-06 Índices de listagem preservam todas as dimensões do cursor

Novos índices de Expense MUST ser escolhidos por workload/plano e benefício líquido, preservando filtros inclusivos, owner, prioridades/direções de sort, UUID DESC, expressão nullable e collation ICU não determinística existentes. MUST verificar primeira página, avanço/retorno e página profunda, hits/misses de cache e custo de escrita. MUST NOT trocar a collation da listagem pela chave binária de sugestões, criar todas as permutações ou remover índices com prefixo comum sem evidência.

#### Scenario: Ordenação alfabética com empates e página seguinte
- **WHEN** a listagem atravessa descrições equivalentes por caixa/acento/Unicode e valores null/vazio
- **THEN** conserva IDs/textos/ordem e navegação v2 sem omissão ou repetição
- **AND** o plano é avaliado separadamente do hit do cache

#### Scenario: Índice com direção mista
- **WHEN** uma definição candidata atende uma direção do sort com UUID DESC
- **THEN** seu scan reverso não é presumido equivalente à direção oposta com o mesmo desempate
- **AND** cada combinação priorizada tem prova de plano/resultados e justificativa de manutenção

### Requirement: EFF-07 Coordenação de cache condicionada ao custo e isolada por página

Single-flight de páginas MUST depender de reprodução de recomputação simultânea custosa e benefício superior ao overhead de coordenação. Se adotado, MUST preservar hit sem lock, isolamento por owner/critérios/cursor, TTL 60s e invalidação após commit de CRUD/classificação, sem ampliar a staleness acordada. MUST usar espera e validade de lock limitadas e double-check do cache, com política de falha/timeout explícita. MUST NOT usar lock global de proprietário para todas as páginas, limpar cache operacional no experimento ou alterar TTL/stale-while-revalidate implicitamente.

#### Scenario: Dois misses simultâneos para a mesma página
- **WHEN** a prova isolada mostra recomputações duplicadas e a coordenação é aprovada
- **THEN** a implementação reduz recomputação com espera limitada sem bloquear hits ou páginas de outros owners
- **AND** a evidência identifica consultas, espera e recuperação em vez de inferir corrida de duas chamadas sequenciais

#### Scenario: Invalidação ou falha durante preenchimento
- **WHEN** CRUD/classificação confirma, há rollback ou o lock expira/falha enquanto uma página é preenchida
- **THEN** são preservados a invalidação após commit, o isolamento e o limite de staleness
- **AND** a política não produz espera ilimitada nem reintroduz cache invalidado por decisão silenciosa

### Requirement: EFF-08 Runtime comprovado antes de dimensionar concorrência

O step operacional MUST confirmar revisão/imagem, SAPI/servidor, configuração efetiva, hooks de deploy, instrumentação e orçamento de recursos da instância alvo antes de tuning. MUST distinguir Apache/MPM de FPM/pool e ambiente local dev de produção; caches Laravel MUST ser preparados após ambiente efetivo estar disponível. MUST medir memória real por processo, CPU e recursos compartilhados, não derivar workers apenas do memory_limit ou dos 8 GB totais. Ausência de acesso/staging MUST ser reportada Blocked. MUST NOT expor debug/status público, desligar captura preexistente sem coordenação ou extrapolar capacidade VPS a partir das sondas locais.

#### Scenario: Entrega define Apache e diagnóstico usa FPM
- **WHEN** os arquivos de deploy e a medição local usam servidores diferentes
- **THEN** o inventário da instância realmente publicada precede qualquer ajuste de limite
- **AND** max_children local não é usado como MaxRequestWorkers de produção

#### Scenario: Referência equivalente indisponível
- **WHEN** faltam acesso, recursos representativos ou janela coordenada sem instrumentação pesada
- **THEN** a comparação operacional dependente permanece Blocked com dados ausentes identificados
- **AND** a spec não substitui o alvo por localhost nem declara tuning/capacidade comprovados
