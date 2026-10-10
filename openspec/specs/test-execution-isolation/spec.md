# test-execution-isolation Specification

## Purpose
TBD - created by archiving change organize-and-strengthen-context-tests. Update Purpose after archive.
## Requirements
### Requirement: ISO-01 Guard de banco antes de qualquer alteração

Toda preparação de schema, escrita de fixture, limpeza e remoção de banco MUST ocorrer somente após validar conexão configurada e banco efetivo como PostgreSQL exclusivo de teste autorizado para a execução/processo. A autorização MUST usar nomes exatos derivados de uma base de teste explicitamente configurada e identidade confiável da execução, não substring testing ou sufixo genérico. DB_URL operacional, driver alternativo, banco de desenvolvimento e nome inesperado MUST interromper a execução antes de alteração. A consulta read-only de current_database() MUST confirmar o destino efetivo após resolução da conexão, inclusive após mudança pelo parallel testing.

#### Scenario: Configuração operacional acidental
- **WHEN** o ambiente de teste aponta por nome, URL ou conexão efetiva para o banco de desenvolvimento
- **THEN** a suíte falha com diagnóstico explícito antes de migrar, limpar ou criar fixtures
- **AND** nenhum dado operacional é alterado

#### Scenario: Nome parecido mas não autorizado
- **WHEN** o nome contém testing mas não coincide com a identidade exata de banco registrada para o processo
- **THEN** o guard rejeita o destino
- **AND** não existe fallback para SQLite nem liberação por regex ampla

#### Scenario: Banco resolvido pelo processo paralelo
- **WHEN** o framework seleciona o banco exclusivo do token paralelo
- **THEN** o guard confirma esse destino efetivo antes da limpeza ou escrita
- **AND** não rejeita um destino legítimo apenas por ser diferente do antigo literal trocado_testing

### Requirement: ISO-02 Bootstrap incremental e execução avulsa

A suíte Feature MUST possuir preparação documentada e executável de bancos/schema seguros, aplicando migrations existentes pendentes de forma incremental antes dos cenários. MUST funcionar a partir de banco de teste vazio e de banco atualizado, sem depender de uma execução prévia da suíte completa. Comandos canônicos e execução avulsa MUST possuir preflight ou falha explícita indicando preparação necessária; descoberta/listagem e testes puros MUST NOT executar migrations. MUST NOT usar migrate:fresh, recriação destrutiva ou schema operacional como pré-requisito padrão.

#### Scenario: Banco vazio de teste
- **WHEN** o comando canônico prepara um banco autorizado vazio
- **THEN** migrations existentes são aplicadas e a suíte pode executar
- **AND** o banco de desenvolvimento permanece intocado

#### Scenario: Migration pendente
- **WHEN** uma execução encontra migrations existentes ainda não aplicadas no destino autorizado
- **THEN** o bootstrap as aplica antes dos testes dependentes
- **AND** não executa migrations antes de cada request

#### Scenario: Arquivo isolado
- **WHEN** um arquivo Feature é selecionado diretamente pelo comando documentado
- **THEN** seu preflight resolve schema e destino válidos ou informa preparação faltante antes de dados parciais
- **AND** não depende de outro arquivo registrar helpers ou limpar resíduos

### Requirement: ISO-03 Limpeza completa sem apagar dados alheios

A infraestrutura de testes MUST limpar todos os recursos que cria/usa com estado persistente, inclusive tokens, despesas, contas, jobs, failed jobs e demais tabelas necessárias introduzidas por migrations já existentes. A lista/política MUST ter ownership e mecanismo de manutenção explícitos, não três deletes tratados como cobertura universal. A limpeza MUST respeitar FKs e testar cenários com commits reais sem transação externa que impeça afterCommit. Recursos externos e conexões/processos abertos MUST ser encerrados em finally/teardown também quando assertions falham.

#### Scenario: Worker falha antes de consumir job
- **WHEN** o cenário aborta após enfileirar um job ou criar registro de falha
- **THEN** cleanup remove somente seus resíduos no banco autorizado/fila exclusiva
- **AND** a próxima execução não observa jobs pendentes daquela execução

#### Scenario: Testes de afterCommit
- **WHEN** um cenário precisa provar commit externo e rollback/savepoint reais
- **THEN** pode controlar suas transações efetivamente sem wrapper global que nunca confirma
- **AND** o teardown garante zero transações abertas e desconexão apropriada

### Requirement: ISO-04 Execução paralela real com PostgreSQL por processo

A suíte Feature e o comando completo MUST executar com pelo menos dois processos paralelos, usando mecanismos nativos compatíveis com Laravel/Pest instalados e banco PostgreSQL exclusivo para cada processo. Bancos e recursos MUST também distinguir execuções concorrentes; duas invocações simultâneas MUST NOT compartilhar destinos de limpeza. Provisionamento MUST ser idempotente para a identidade autorizada e registrar criação/reuso com segurança. Nenhum processo MUST limpar ou escrever no banco de outro; serializar globalmente toda a suíte ou desabilitar cenários obrigatórios MUST NOT ser aceito como implementação de paralelismo.

#### Scenario: Dois processos executam Feature
- **WHEN** duas partes da suíte preparam contas/despesas simultaneamente
- **THEN** os destinos PostgreSQL efetivos são distintos e assertions não observam registros do outro processo
- **AND** ambos passam sem disputa de limpeza, e-mail fixo ou sequência compartilhada

#### Scenario: Duas invocações simultâneas
- **WHEN** duas execuções canônicas começam com os mesmos tokens locais de processo
- **THEN** a identidade de execução diferencia bancos, Redis, filas e arquivos
- **AND** limpeza de uma invocação não interfere na outra

#### Scenario: Recursos suficientes indisponíveis
- **WHEN** o ambiente não pode provisionar o banco/processo requerido
- **THEN** a verificação obrigatória é reportada como bloqueada com causa explícita
- **AND** não há fallback silencioso para o banco base compartilhado

### Requirement: ISO-05 Redis cache limiter e filas exclusivos

Cenários de Redis real MUST usar namespace exclusivo por execução/processo/cenário, explicitamente propagado aos clientes e workers de teste. Filas de teste MUST possuir nome exclusivo e não competir com workers locais default/expense-classification. Limpeza MUST remover somente chaves/filas registradas pela execução, sem FLUSHALL/FLUSHDB ou invalidar tags de desenvolvimento. Credenciais operacionais, provider externo e envio real de mail MUST NOT ser usados. Cenários comuns MUST manter cache/limiter array e fakes nativos quando integração real não é a prova alvo.

#### Scenario: Worker local ativo
- **WHEN** a suíte de integração enfileira uma notification ou classificação enquanto workers locais estão ativos
- **THEN** somente o worker de teste consome a fila exclusiva do cenário
- **AND** a fila de produto e suas mensagens não são limpas nem consumidas

#### Scenario: Cache e limiter em paralelo
- **WHEN** dois processos usam os mesmos IDs de fixture e nomes lógicos de chaves
- **THEN** os namespaces exclusivos impedem hits/contadores cruzados
- **AND** um cenário que prova compartilhamento usa dois clientes no mesmo namespace intencional, sem perder isolamento externo

#### Scenario: Interrupção de cenário Redis
- **WHEN** uma assertion falha após criar mensagens/chaves
- **THEN** finally/teardown remove seus recursos conhecidos
- **AND** não limpa o Redis inteiro para restaurar o ambiente

### Requirement: ISO-06 Estado global e tempo restaurados

Testes MUST controlar datas relevantes explicitamente e restaurar relógio/timezone, guards, bindings, events/listeners, fakes e canais de log alterados. MUST NOT depender de horário corrente, IDs previsíveis, ordem de descoberta, valores aleatórios não registrados ou execução prévia. Logs MUST usar caminhos temporários exclusivos e a simulação de falha MUST ser determinística. Requests sequenciais que usam credenciais distintas MUST reavaliar o guard sem reutilizar principal anterior.

#### Scenario: Troca de token no mesmo processo
- **WHEN** um teste alterna tokens de A/B ou token revogado/inválido
- **THEN** cada request resolve o principal correspondente naquele momento
- **AND** não herda autenticação cacheada pela request anterior

#### Scenario: Relógio e listener modificados
- **WHEN** um cenário altera testNow/timezone ou registra listener que lança falha
- **THEN** outro cenário isolado/reordenado não herda essa alteração
- **AND** restauração acontece mesmo quando o primeiro falha

### Requirement: ISO-07 Concorrência controlada sem esperas frágeis

Testes que comprovam corrida/lock MUST usar conexões/processos realmente independentes, barreiras/sinais explícitos e observação do estado relevante, com timeouts limitados e diagnóstico. MUST desconectar conexões herdadas antes de uso em fork, informar erros do filho, fechar sockets, reverter transações e aguardar/encerrar filhos de forma limitada. Espera longa arbitrária ou sleep como prova de que a corrida ocorreu MUST NOT ser aceita. Ambiente do gate MUST disponibilizar a capacidade necessária; skip local MUST aparecer como bloqueio da prova e não como conclusão.

#### Scenario: Processo aguarda lock
- **WHEN** o filho precisa aguardar uma escrita concorrente no PostgreSQL
- **THEN** o pai confirma bloqueio/sincronização antes de alterar e liberar o registro
- **AND** erro/timeout do filho reprova com informação suficiente sem deixar processo pendurado

#### Scenario: Processo falha antes da barreira
- **WHEN** o filho não conecta ou lança erro antes de completar o protocolo
- **THEN** o cenário termina com falha limitada no tempo e limpa recursos
- **AND** não declara concorrência comprovada por simplesmente chegar à assertion final

### Requirement: ISO-08 Seleção de suítes e dependências explícitas

A suíte MUST permitir selecionar Unit, arquitetura, Feature por contexto e integrações que exigem Redis/concorrência por caminhos/grupos documentados. A seleção MUST permitir desenvolvimento rápido sem reclassificar integração real como unitário. O comando completo de aceitação MUST incluir todas as integrações obrigatórias; indisponibilidade MUST ter falha/blocked claro em vez de omissão silenciosa. Helpers/Support MUST estar autoloadáveis mesmo em filtro de um único cenário.

#### Scenario: Desenvolvimento de regra pura
- **WHEN** somente Domain/Application é selecionado
- **THEN** a execução não inicializa banco/Redis/workers por causa de setup global
- **AND** o comando é distinto do gate completo obrigatório

#### Scenario: Gate completo
- **WHEN** a implementação é candidata a conclusão
- **THEN** o relatório inclui os grupos Redis, concorrência e parallel obrigatórios
- **AND** cenários skipped/incomplete/risky inesperados impedem declarar a suíte completa comprovada

### Requirement: ISO-09 Gate reproduzível com rastreabilidade

A implementação MUST concluir somente após arquivos afetados isolados, suítes dos cinco contextos, arquitetura e suíte completa passarem no ambiente autorizado. MUST executar ordem padrão, ao menos duas seeds aleatórias registradas e paralelismo com pelo menos dois processos, incluindo duas invocações concorrentes para verificar separação por execução. A mesma seed MUST ser reutilizável para diagnóstico, sem promessa de IDs incidentais reproduzíveis. MUST registrar comandos, seeds, processos, resultados, skips, duração, cenário/destino de evidência e limitações. Pint MUST executar após mudanças PHP; OpenSpec MUST validar estritamente. MUST NOT aumentar timeout, relaxar assertion, fixar sequência ou retirar cenário obrigatório para ocultar falha.

#### Scenario: Teste editorial selecionado sozinho
- **WHEN** o cenário de liderança recorrente é executado avulso e em ordens diferentes sobre bancos de teste com sequências diferentes
- **THEN** passa sem reiniciar sequências para escolher uma mensagem
- **AND** o relatório identifica a correção da dependência incidental

#### Scenario: Regressão descoberta no gate
- **WHEN** uma seed ou execução paralela falha enquanto a padrão passa
- **THEN** a mudança continua incompleta até diagnóstico/correção dentro do escopo ou decisão explícita do usuário
- **AND** somente uma execução verde não substitui a evidência faltante
