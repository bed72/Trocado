# Evidências comportamentais da suíte

## Purpose

Definir cenários de regressão dos contratos já implementados, no menor nível capaz de provar cada garantia, sem confundir mocks com integridade PostgreSQL nem quantidade de assertions com qualidade.

## Regra de leitura

Os requisitos BEH definem a evidência que a suíte deve produzir, não novos comportamentos de produto. Uma divergência revelada durante o apply deve ser apresentada antes de alterar produção. As specs históricas de `user`, `expense` e `identity-context` contêm referências de relacionamento/ownership/status de rota incompatíveis com decisões posteriores; a arquitetura atual, os contratos posteriores consolidados e a decisão explícita do usuário prevalecem. Esta mudança não deve reintroduzir relações Eloquent entre contextos nem atualizar silenciosamente specs funcionais antigas.

## ADDED Requirements

### Requirement: BEH-01 Nível de prova adequado e expectativas causais

A suíte MUST comprovar invariantes por unitários puros, orquestração por Application com contratos injetados, mapping/query/constraints/transações por integração PostgreSQL e transporte por HTTP. Nomes que afirmam transação, rollback ou concorrência MUST possuir prova correspondente. Assertions MUST identificar o efeito relevante e falhas esperadas; catches genéricos MUST NOT aceitar uma falha diferente da provocada para rollback. Um único teste pode provar vários campos de um contrato coeso, mas cenários independentes MUST ter diagnóstico identificável.

#### Scenario: Criação dentro da unidade transacional
- **WHEN** SignUp é testado com um double de TransactionPort
- **THEN** o teste observa que a chamada de criação ocorre enquanto o callback transacional está ativo
- **AND** apenas constatar uma chamada a commit e outra ao Repository não é prova suficiente da ordem/escopo

#### Scenario: Rollback provocado
- **WHEN** um teste força rollback com uma exceção sentinela após a escrita
- **THEN** comprova que a exceção capturada é a sentinela e que a escrita anterior aconteceu
- **AND** uma falha operacional anterior à sentinela reprova o teste em vez de ser absorvida

### Requirement: BEH-02 Efeitos após commit observados na Application

Testes dos UseCases que agendam efeitos MUST observar callbacks registrados, argumentos e execução somente após confirmação simulada apropriada. MUST cobrir sucesso, escrita rejeitada e falha transacional aplicável, sem usar mocks no-op de TransactionPort/ObservabilityPort para declarar cobertura desses efeitos. O double MUST registrar ordem e permitir descartar callbacks de tentativa abortada; a prova de mecanismo real MUST permanecer em Feature.

#### Scenario: Registro confirmado
- **WHEN** SignUp cria uma conta pelo Repository
- **THEN** a suíte observa solicitação de verificação e evento user.registered com o ID correto após confirmação
- **AND** esses efeitos não são executados antes da conclusão do callback de escrita

#### Scenario: Tentativa abortada
- **WHEN** a unidade simulada falha antes do commit
- **THEN** callbacks daquela tentativa não produzem notification nem evento
- **AND** a falha permanece observável ao chamador

#### Scenario: Mutações e classificação
- **WHEN** alteração/exclusão de Expense ou exclusão de User confirma a escrita, ou classificação informa proprietário efetivamente atualizado
- **THEN** os testes verificam o evento correspondente e IDs/atributos permitidos
- **AND** resultado ausente/recusado não agenda evento de sucesso

### Requirement: BEH-03 Cadastro Identity valida e preserva credenciais

A suíte MUST provar cadastro JSON:API de conta pending e não verificada, password hash sem token implícito, canonicalização, preservação exata de senha e rejeição de documentos inválidos sem escrita. MUST cobrir confirmação divergente, política de senha, nome inválido, e-mail inválido, atributos extras e resource type incorreto no limite HTTP. MUST verificar status, media type, source.pointer pertinente, Location e ausência de senha/hash/token no documento.

#### Scenario: Confirmação divergente
- **WHEN** password é Correct1 e password_confirmation é Other123
- **THEN** responde 422 com pointer /data/attributes/password_confirmation
- **AND** não cria conta, token ou solicitação de verificação

#### Scenario: Senha preservada
- **WHEN** o cadastro recebe uma senha válida com espaços externos e confirmação idêntica
- **THEN** o hash confirma exatamente a senha com espaços
- **AND** o login com uma versão alterada não é considerado equivalente

#### Scenario: Limites e transporte inválidos
- **WHEN** são enviados senha de 5/33 caracteres, mais de 72 bytes, sem maiúscula/número, nome fora dos limites, e-mail inválido, atributos extras ou type diferente
- **THEN** cada caso nomeado falha no contrato HTTP esperado sem persistência
- **AND** os casos válidos nos limites inclusivos permanecem aceitos

### Requirement: BEH-04 Login Identity comprova autenticação real e erros uniformes

A suíte MUST exercitar provider/hasher/Sanctum reais em testes de integração/HTTP para sucesso, múltiplos tokens, canonicalização e falha. Credenciais inválidas MUST ter status, título e detalhe equivalentes sem enumeração; nenhuma falha MUST criar token. Testes de delegação ao SignInPort MUST NOT ser usados como prova desse contrato real. Conta pending/blocked ou active não verificada MUST ser testada após credenciais corretas; SignOut MUST permanecer possível ao titular de token válido não verificado conforme a política atual.

#### Scenario: E-mail equivalente no login
- **WHEN** uma conta apta cadastrada com e-mail canônico recebe login com diferenças de caixa/espaços externos
- **THEN** o mesmo principal é autenticado e recebe novo token Sanctum
- **AND** não cria uma nova identidade

#### Scenario: Falhas genéricas
- **WHEN** são tentados e-mail inválido, conta inexistente, senha incorreta e hash não autenticável de fixture
- **THEN** o contrato público de 401 tem os mesmos título e detalhe seguros
- **AND** a quantidade de tokens não aumenta

#### Scenario: Dois logins e resposta segura
- **WHEN** a mesma conta conclui dois logins válidos
- **THEN** são criados tokens distintos com hash, expiração e relações corretos
- **AND** a resposta entrega o segredo com no-store e Pragma no-cache sem expor hash ou senha

#### Scenario: E-mail deixa de estar verificado
- **WHEN** uma conta com token válido perde a verificação de e-mail
- **THEN** o acesso protegido é recusado e SignOut revoga o token conforme o contrato existente
- **AND** não há concessão de acesso por simples presença do token

### Requirement: BEH-05 Ownership e encerramento atômico de Identity

A suíte MUST provar GET/PATCH/DELETE da própria conta, recusa uniforme de alvo alheio/inexistente e ausência de principal, além de rejeitar criação/listagem públicas de users com 404 JSON:API. MUST comprovar exclusão com múltiplos tokens e despesas no PostgreSQL e rollback após a remoção de tokens antes da exclusão de users. Conta, tokens e despesas de terceiros MUST permanecer inalterados.

#### Scenario: Exclusão completa
- **WHEN** A tem dois tokens e duas despesas e B possui seus próprios dados
- **THEN** DELETE autorizado de A responde 204 e remove todos os dados de A
- **AND** B permanece intacta e tokens de A deixam de autenticar

#### Scenario: Falha após remover tokens
- **WHEN** uma falha sentinela ocorre na exclusão da identidade depois da tentativa real de remover seus tokens
- **THEN** a transação restaura conta, tokens e despesas de A
- **AND** a suíte verifica persistência real, não somente retorno do Repository mockado

#### Scenario: Conta alheia e ausente
- **WHEN** A chama GET, PATCH ou DELETE para B ou um ID inexistente
- **THEN** recebe o mesmo contrato 404 sem alteração dos dados de B
- **AND** os unitários também provam interrupção antes de consulta/escrita do Repository quando os IDs divergem

#### Scenario: Caminhos públicos inexistentes
- **WHEN** GET /api/users ou POST /api/users é solicitado
- **THEN** responde 404 JSON:API sem listar/criar contas
- **AND** cadastro continua pertencendo exclusivamente a SignUp

### Requirement: BEH-06 Unicidade e mapping de Identity

A suíte MUST exercitar EloquentUserRepository para mapping de ID, nome, e-mail, status e timestamps, leitura ausente, atualização somente de nome e tradução de conflito de unicidade. MUST distinguir conflito sequencial encontrado por precheck de colisão que alcança a constraint. A corrida de criação no mesmo e-mail MUST usar conexões/processos distintos e sincronização, permitindo exatamente uma conta sem token/e-mail da tentativa abortada.

#### Scenario: Colisão após precheck
- **WHEN** duas tentativas ultrapassam a checagem de disponibilidade para o mesmo e-mail canônico
- **THEN** a constraint permite uma conta e a perdedora recebe a exceção/409 equivalente
- **AND** uma duplicação sequencial isolada não é apresentada como prova desse ramo concorrente

#### Scenario: Perfil preservado
- **WHEN** o nome é atualizado com normalização de whitespace
- **THEN** o retorno é Entity com o nome persistido e os demais campos preservados
- **AND** e-mail, status, verificação e todos os tokens não mudam

### Requirement: BEH-07 Rate limiting público e autenticado

A suíte MUST provar SignIn em 5/minuto por combinação IP/e-mail canônico e 30/minuto por IP, SignUp em 3/hora no padrão e override configurável, reenvio em 2/hora por combinação e 5/hora por IP, e cota autenticada 60/minuto por User. MUST comprovar compartilhamento entre tokens/IPs/rotas aplicáveis, independência entre usuários/políticas, consumo por erros admitidos, Retry-After e reabertura de janela com relógio controlado. MUST provar que SignOut não é bloqueado pela cota autenticada e que acesso recusado não executa a operação.

#### Scenario: Login repetido canônico
- **WHEN** um IP envia cinco logins com caixa/espaços equivalentes no e-mail
- **THEN** o sexto recebe 429 JSON:API com Retry-After e sem token
- **AND** outro IP dentro da cota continua sendo admitido

#### Scenario: Troca de e-mail não contorna IP
- **WHEN** um IP envia trinta logins admitidos com identificadores distintos
- **THEN** a próxima tentativa recebe 429 mesmo com outro identificador
- **AND** SignUp/reenvio mantêm contadores próprios

#### Scenario: Cota autenticada compartilhada
- **WHEN** o mesmo User alterna dois tokens, IPs e rotas protegidas de Identity/Expense, incluindo erros admitidos
- **THEN** a sexagésima primeira requisição é bloqueada sem executar mutação
- **AND** outro User não é bloqueado e o titular ainda consegue SignOut

#### Scenario: Janela expira
- **WHEN** o relógio controlado ultrapassa a janela após o esgotamento
- **THEN** uma nova tentativa é admitida
- **AND** a suíte não usa sleep real para aguardar minutos ou horas

#### Scenario: Redis compartilhado e indisponibilidade
- **WHEN** conexões/processos independentes usam o store Redis do limiter em namespace exclusivo de teste
- **THEN** observam o consumo combinado sem depender do cache geral array/file
- **AND** uma falha injetada nesse acesso não é convertida em contador local ou sucesso sem limite

### Requirement: BEH-08 Expense prova ownership da consulta individual

A suíte MUST exercitar GET individual no HTTP e a delegação do UseCase ao Repository com ID e proprietário explícitos. MUST comprovar recurso próprio atualizado, equivalência de 404 para alheio/ausente/excluído, 401 sem credencial, 404 para ID não numérico e leitura da persistência sem reutilizar páginas cacheadas. MUST verificar type expenses, ID string e atributos públicos sem campos de classificação interna.

#### Scenario: Consulta própria e atual
- **WHEN** A lê uma despesa própria após uma edição confirmada
- **THEN** recebe 200 com os atributos atuais e contrato JSON:API completo
- **AND** uma página previamente cacheada não determina o retorno individual

#### Scenario: Alvo inacessível
- **WHEN** A lê despesa de B, ausente ou definitivamente removida
- **THEN** os três casos recebem 404 equivalente sem dados de B
- **AND** credencial ausente/inválida e ID não numérico têm os status próprios esperados

### Requirement: BEH-09 Expense prova paginação real e validação de cursor

A suíte MUST paginar dados reais PostgreSQL com diferentes datas e empates por ID, tamanho padrão 20 e limites 1/100, navegando next/prev até os limites. MUST comprovar sequência ordenada exata, ausência de duplicações/omissões com dados estáveis, links nulos nas bordas e preservação de tamanho/escopo. MUST validar cursores produzidos pela API e rejeitar estruturas inválidas sem fallback para a primeira página. Cursores artificiais em testes de cache MUST NOT ser considerados prova de paginação.

#### Scenario: Datas iguais em várias páginas
- **WHEN** A tem sete despesas com datas repetidas e solicita tamanho 2
- **THEN** a navegação completa produz exatamente os sete IDs em occurred_on DESC e id DESC
- **AND** voltar por prev entrega a página anterior na mesma ordem sem repetição/omissão

#### Scenario: Cursor de outra conta
- **WHEN** B usa um cursor emitido para A com despesas em posições coincidentes
- **THEN** todas as despesas retornadas continuam pertencendo a B
- **AND** A não participa do conteúdo nem dos links de autorização

#### Scenario: Conta vazia e limites
- **WHEN** a conta está vazia ou solicita tamanhos 1, 20 e 100 válidos
- **THEN** o contrato e links respeitam quantidade/ausência de páginas
- **AND** o default 20 é comprovado com mais de vinte registros

#### Scenario: Cursor ou tamanho inválido
- **WHEN** são enviados tamanho 0/101/fracionário/textual, cursor vazio/oversized/malformado, campos ausentes/extras, ID não positivo, data impossível ou direção de tipo incorreto
- **THEN** cada caso recebe 422 JSON:API com identificação do parâmetro pertinente
- **AND** não executa leitura de página nem retorna implicitamente a primeira

#### Scenario: Proprietário fornecido pelo cliente
- **WHEN** user_id é enviado na listagem
- **THEN** a requisição é rejeitada com 422 sem mudar o escopo
- **AND** um cursor válido não torna esse parâmetro aceitável

### Requirement: BEH-10 Expense prova criação atualização e integridade

A suíte MUST preservar os cenários atuais de escrita por proprietário e ampliar validação HTTP/persistência para amount positivo inteiro, data civil, categoria fechada e descrição de até 64 caracteres. MUST provar defaults de data no timezone da aplicação e descrição nula, PATCH distinguindo omissão e null explícito, preservação de campos não informados, cancelamento da classificação por edição pertinente e tradução de FK ausente na criação. MUST NOT introduzir relações Eloquent entre Identity e Expense para obter essas evidências.

#### Scenario: Default na virada civil
- **WHEN** a criação omite occurred_on em instante cujo dia difere entre UTC e timezone configurado
- **THEN** a despesa usa o dia da aplicação e description null quando omitida
- **AND** a referência é controlada no teste

#### Scenario: Atualização parcial
- **WHEN** PATCH omite description em um cenário e envia description null em outro
- **THEN** o primeiro preserva o valor e o segundo o limpa
- **AND** edição de categoria/descrição cancela tentativa antiga sem alterar dados de terceiros

#### Scenario: Invariantes no transporte e Repository
- **WHEN** entradas inválidas de valor/data/categoria/descrição são enviadas ou o proprietário desaparece antes da persistência
- **THEN** a suíte prova rejeição sem escrita/job indevido e a tradução da falha de identidade pertinente
- **AND** os limites válidos de descrição/catálogo permanecem aceitos

### Requirement: BEH-11 Cache de Expense prova conteúdo TTL e invalidação

A suíte MUST comprovar cache miss/hit, round-trip de todos os campos públicos e cursores, isolamento por proprietário/tamanho/cursor, TTL 60 segundos e passagem direta de getById. MUST observar invalidação de todas as páginas do proprietário após create/update/delete/classificação confirmados, preservação de outros proprietários e ausência de invalidação em escrita recusada, rollback total/nested e tentativa de categorização sem mudança. O cenário de integração Redis MUST comprovar compartilhamento real entre clientes independentes; os cenários comuns MUST poder usar array.

#### Scenario: TTL antes e depois do limite
- **WHEN** a mesma página é lida em t0, antes de t0+60s e depois de t0+60s com relógio controlado
- **THEN** a leitura intermediária reutiliza o cache e a posterior consulta o Repository novamente
- **AND** campos, timestamps e ambos os cursores são reconstruídos sem perda

#### Scenario: Escrita confirmada em múltiplas páginas
- **WHEN** um proprietário tem páginas cacheadas em tamanhos/cursores distintos e confirma create, update, delete ou classificação
- **THEN** cada página daquele proprietário é recarregada na próxima leitura
- **AND** as páginas de outro proprietário continuam sendo hits

#### Scenario: Rollback e savepoint
- **WHEN** uma escrita real é revertida no escopo externo ou em savepoint com commit externo
- **THEN** os dados permanecem anteriores e callbacks daquela escrita não invalidam páginas
- **AND** a exceção sentinela e o estado da transação são verificados

#### Scenario: Leitura individual e categoria recusada
- **WHEN** getById é chamado duas vezes ou uma tentativa de categoria é apenas iniciada/lida/cancelada/recusada
- **THEN** getById consulta o inner Repository a cada chamada
- **AND** as operações sem categoria aplicada não invalidam páginas

#### Scenario: Invalidação entre clientes Redis
- **WHEN** um cliente preenche páginas e outro confirma escrita/invalidação no mesmo namespace exclusivo
- **THEN** uma leitura subsequente no primeiro cliente não usa a página invalidada
- **AND** nenhum cache de desenvolvimento é lido, invalidado ou limpo

### Requirement: BEH-12 Classificação assíncrona preserva provas e suas limitações

A suíte MUST preservar despacho pós-commit, ausência de inferência no HTTP, fila dedicada, falha de despacho, sync desabilitado, provider inválido/exceção, expiração, repetição, edição de categoria/descrição e exclusão. MUST distinguir invocação manual de handle/failed de consumo real do worker, e interleaving determinístico de concorrência entre processos. MUST acrescentar prova PostgreSQL sincronizada de atualização condicional frente a alteração de categoria/descrição/token após leitura; cancelamento de token antigo MUST NOT cancelar uma nova tentativa.

#### Scenario: Resposta tardia diante de edição
- **WHEN** uma conexão leu uma tentativa e outra confirma categoria, descrição ou token diferente antes da aplicação
- **THEN** a atualização antiga afeta zero registros e não emite sucesso
- **AND** o estado novo permanece intacto

#### Scenario: Falha de tentativa antiga
- **WHEN** cancelamento/falha usa token antigo após existir uma tentativa nova
- **THEN** a nova tentativa não é apagada
- **AND** o cenário comprova a condição real de ID/token na persistência

#### Scenario: Worker real
- **WHEN** um job serializado é colocado em fila exclusiva e consumido pelo worker real
- **THEN** resolve bindings atuais e aplica apenas a tentativa válida
- **AND** o provider continua fake e retries não são declarados comprovados somente por chamar failed manualmente

### Requirement: BEH-13 Insights independente de variante incidental

Testes de integração de Insights MUST aceitar todas as variantes editoriais válidas para o mesmo significado e MUST NOT depender de ID gerado, ordem anterior, reinício de sequência ou um fragmento presente em somente uma variante. Catálogo/composição MUST ter testes focados de todas as variantes, Unicode, orçamento, labels, fallback completo, ciclos e estabilidade diária. IDs determinísticos MUST ser testados com dimensões explícitas de conta, assunto e período sem copiar o algoritmo de hashing.

#### Scenario: Liderança recorrente com contas diferentes
- **WHEN** dados equivalentes de liderança são analisados com diferentes IDs positivos
- **THEN** todos os resultados válidos de composição passam o contrato de significado/limites
- **AND** ausência da frase literal dois meses anteriores em uma variante não reprova a integração

#### Scenario: Catálogo completo
- **WHEN** cada conjunto editorial percorre um ciclo completo com IDs/datas explícitos
- **THEN** todas as variantes são exercitadas, os placeholders são preenchidos e limites Unicode respeitados
- **AND** percentuais muito longos usam alternativa completa ou falha explícita, sem truncamento

#### Scenario: Números mudam no mesmo dia
- **WHEN** somente os valores de uma projeção mudam mantendo conta, fatos identificadores e períodos
- **THEN** ID/título permanecem estáveis enquanto o percentual/descrição pertinente muda
- **AND** a expectativa usa valores independentes conhecidos

### Requirement: BEH-14 Insights mantém análise regras e contrato HTTP

A suíte MUST preservar isolamento por proprietário, occurred_on, limites civis, referências explícitas, meses curtos/bissextos, histórico antigo/futuro, soma acima de inteiro nativo, desempate do maior lançamento e ausência de escrita. MUST manter thresholds exatos, comparações materiais, seleção sem redundância e limite seis, onboarding e falhas de projeção. O HTTP MUST continuar rejeitando todo parâmetro de query antes da análise, provar proteções/session e falha sem onboarding fabricado. Contagem de leitura MUST observar statements analíticos efetivos, sem exigir um nome de CTE específico como contrato público.

#### Scenario: Uma leitura analítica íntegra
- **WHEN** a conta tem fatos atuais/históricos e terceiros têm fatos coincidentes
- **THEN** todos os campos analíticos são coerentes e obtidos por uma leitura sem escrita
- **AND** o teste identifica a leitura pelo limite/capacidade observada sem depender de WITH periods como única identificação

#### Scenario: Thresholds e seleção
- **WHEN** os fatos estão imediatamente abaixo, no limite e acima de uma regra material
- **THEN** elegibilidade usa a razão exata antes do arredondamento
- **AND** seleção mantém períodos/assuntos distintos e remove somente redundâncias previstas

#### Scenario: Query recusada e falha operacional
- **WHEN** há query não permitida, proteção de acesso recusada ou falha analítica
- **THEN** a suíte prova 422/401/403/429/5xx pertinentes e ausência de leitura quando bloqueada
- **AND** falha operacional não é convertida em first_expense ou resposta de sucesso

### Requirement: BEH-15 Core mantém invariantes compartilhadas e identidade autenticada

A suíte MUST preservar centavos canônicos, precisão arbitrária, soma/diferença/comparação/imutabilidade, datas canônicas de 0001 a 9999, inclusividade/calendário/timezone e razões com percentuais exatos. MUST distinguir razão de variação acima de 100% de participação limitada ao total. UserAdapter MUST ter provas diretas de id inteiro e status string/BackedEnum, além de falha para principal/status ausente ou de tipo inválido e uso exclusivo do guard Sanctum.

#### Scenario: Status do principal
- **WHEN** o guard Sanctum entrega status como string ou enum respaldado em string
- **THEN** status retorna o valor textual correto
- **AND** principal ausente, status null ou de tipo inválido falha como autenticação sem consultar outro guard

#### Scenario: Razão versus participação
- **WHEN** numerador excede denominador em razão de variação e em participação
- **THEN** a primeira é aceita e a segunda é rejeitada
- **AND** zero no denominador continua inválido mesmo com numerador zero

#### Scenario: Aritmética e calendário extremos
- **WHEN** há valores acima de PHP_INT_MAX, half-up, datas extremas, dia único e mudança de timezone
- **THEN** a suíte conserva valores exatos, datas civis e operandos originais
- **AND** a consolidação não remove esses casos por repetirem fixtures

### Requirement: BEH-16 Observabilidade transversal possui assertions estruturais

Provas diretas de observabilidade/correlação MUST pertencer a Core, enquanto intenção de evento específico permanece no contexto emissor. A suíte MUST verificar JSON válido, campos permitidos, timestamp/level/event, request_id e user_id apropriados, isolamento entre requests, ausência de contexto fora de HTTP e falha do destino sem desfazer escrita. MUST provar ausência de descrição/amount/credenciais/payload por campos e valores sensíveis específicos, sem rejeitar números que apareçam legitimamente em ID/timestamp.

#### Scenario: IDs coincidem com valor sensível numérico
- **WHEN** um ID legítimo é 1500 ou um timestamp contém os mesmos dígitos de um amount
- **THEN** o evento passa se o campo amount não existir e os campos permitidos estiverem corretos
- **AND** inserir amount, password, token ou payload proibido reprova a assertion estrutural

#### Scenario: Requests e execução fora de HTTP
- **WHEN** dois requests e um evento de worker/CLI são processados no mesmo processo
- **THEN** request_id é distinto e igual ao header de cada request, e não vaza para o evento externo
- **AND** os eventos de queue expõem apenas metadados autorizados e classe do erro, não sua mensagem sensível

#### Scenario: Destino de log indisponível
- **WHEN** uma escrita confirmada tenta emitir evento para um destino que falha
- **THEN** o recurso permanece persistido e o HTTP conserva sucesso
- **AND** o teste não depende de uma pasta absoluta específica ser inexistente na máquina

### Requirement: BEH-17 Metrics preserva o estágio implementado

A suíte MUST organizar e preservar os testes atuais de GetExpenseMetricsUseCase e seu enum, usando Core para invariantes monetárias/civis. MUST comprovar uma chamada com proprietário/período/modo explícitos, null versus lista vazia, reconciliação, catálogo completo, ordenação exata, percentuais independentes, ID por dimensões e falhas/projeções inválidas. Esta mudança MUST NOT implementar Infrastructure/Presentation de Metrics, exigir cenários HTTP de capacidade ainda inexistente nem declarar SQL/snapshot/isolamento real comprovados por mocks.

#### Scenario: Totais e percentuais exatos
- **WHEN** projeções incluem totais acima de inteiro nativo, empate e participações de terços/16,665%/mínima positiva
- **THEN** a ordenação e representação são exatas, inclusive somas exibidas 99,99% e 100,01%
- **AND** a soma monetária reconcilia sem corrigir percentuais artificialmente

#### Scenario: Projeção inconsistente
- **WHEN** faltam grupos, há duplicação, categoria desconhecida, item não tipado, valor não canônico ou soma divergente
- **THEN** o UseCase falha explicitamente sem fabricar total zero ou reparar os dados
- **AND** o builder não impede construir essas entradas negativas

#### Scenario: Coordenação com mudança de Metrics
- **WHEN** os testes existentes são movidos ou suas fixtures são extraídas
- **THEN** as referências correntes relevantes são atualizadas sem apagar evidências históricas de add-expense-metrics
- **AND** as tarefas futuras de Adapter/HTTP continuam pertencendo àquela mudança

### Requirement: BEH-18 Arquitetura preservada e prova sem claims excessivos

A suíte MUST continuar verificando contextos/camadas, pureza, imports permitidos, Data final readonly constructor-only, naming e ausência de referências retiradas. Testes reflexivos MUST proteger decisões arquiteturais reais e não apenas repetir declarações por hábito. O relatório MUST distinguir código executado, contrato comportamental, evidência parcial e risco residual; MUST NOT afirmar cobertura percentual, corrida, rollback ou escala sem medição/prova correspondente.

#### Scenario: Nova organização de suporte
- **WHEN** Support integra dados de diferentes contextos para Feature
- **THEN** os testes de arquitetura de app continuam com as mesmas restrições específicas
- **AND** o enum compartilhado de Core não libera imports adicionais entre contextos

#### Scenario: Prova sequencial de idempotência
- **WHEN** handle é executado duas vezes sequencialmente
- **THEN** o relatório classifica o resultado como repetição/idempotência
- **AND** não o registra como prova de uma corrida entre processos
