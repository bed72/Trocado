## Context

A revisão anterior é a baseline histórica de diagnóstico desta proposta; nenhum teste da aplicação é executado nesta primeira etapa de atualização da spec. Ela analisou 49 arquivos de testes/suporte, encontrou PHPUnit mocks em 16 arquivos e funções globais de preparação em 15. Esse inventário antecede a entrega de Infrastructure/Presentation de Metrics e deve ser atualizado antes da migração dos testes. PHP 8.5, Laravel 13.34.0, Pest 5.2.1, PHPUnit 13.3.4 e Mockery 1.6.15 foram reconfirmados pelo Boost em 2026-10-10; APIs e mecanismos de execução devem ser consultados na etapa de implementação correspondente.

Evidências históricas da revisão:

| Execução | Resultado | Interpretação |
| --- | --- | --- |
| Pest completo, padrão | 627 testes, 3.450 assertions, todos passando | Uma execução verde, não prova de independência de estado. |
| Pest completo, ordem aleatória, seed 20261009 | 626 passando, 1 falha | Falha em ExpenseAnalysisAdapterTest, descrição editorial. |
| Cenário editorial isolado | 1 falha na assertion de texto | Reproduz o problema sem depender da suíte completa. |
| Encerramento de add-expense-metrics, 2026-10-10 | 725 testes, 4.588 assertions, todos passando | Última execução completa documentada no arquivo histórico; não executada por esta mudança nem prova de ordem aleatória/paralelismo. |

A fonte da baseline posterior é `openspec/changes/archive/2026-10-10-add-expense-metrics/tasks.md`, seção **Decisão de encerramento**, lida junto das evidências de Infrastructure e Presentation. As tabelas intermediárias daquele arquivo descrevem etapas anteriores e não tornam Adapter/HTTP novamente pendentes. O encerramento registra aceite explícito das limitações: travessia de mês durante a execução, escrita concorrente durante a leitura, cota/extensão de sessão especificamente em Metrics e observabilidade analítica autenticada representativa no Lerd. A execução verde posterior não demonstra independência de IDs; a falha editorial precisa ser reconferida isoladamente antes de qualquer correção.

A sequência de users não é reiniciada pelos deletes atuais, e a escolha de variante editorial usa userId. Reiniciar a sequência esconderia uma assertion errada: somente uma das quatro mensagens contém a frase exigida. O catálogo de produção deve ser preservado.

Identity/Expense possuem suites Feature que misturam HTTP, Repository, configuração, transações e worker. Core tem invariantes fortes, mas parte de suas capacidades transversais é comprovada em Expense. Insights tem muitos builders semelhantes. Metrics já possui Domain/Application, Adapter PostgreSQL, Request/Controller/Response, provider e rota implementados, com testes unitários, integração e HTTP registrados na entrega arquivada.

O usuário confirmou que execução paralela real é obrigatória nesta mudança. As regras do projeto exigem PostgreSQL real nas provas de persistência, segurança antes de limpeza e nenhum migrate:fresh sem autorização. O banco de teste literal atual é trocado_testing; a proteção deve evoluir sem virar permissão ampla por sufixo.

## Goals / Non-Goals

**Goals:**

- Uma responsabilidade clara por arquivo e um destino previsível para cada prova.
- Doubles e fixtures reutilizáveis independentes da descoberta dos testes.
- Cobertura dos cenários faltantes indicados na revisão, preservando os cenários valiosos existentes.
- Determinismo editorial, temporal e de isolamento, com execução avulsa e reordenada.
- Bootstrap incremental seguro e bancos/Redis/filas/logs por execução/processo.
- Gate completo sequencial, aleatório, paralelo e concorrente entre invocações.
- Evidência rastreável por requisito/cenário, sem alegação de percentual de cobertura.

**Non-Goals:**

- Reescrever código de produto, mudar API, catálogo editorial, autorização ou migrations de produto.
- Reimplementar Adapter/endpoint já entregues de Metrics ou introduzir novas funcionalidades.
- Introduzir biblioteca, runner alternativo, camada genérica de factories/mocks ou infraestrutura de CI externa.
- Fazer testes de carga, estabelecer SLO, exigir coverage percentual ou mutation score.
- Atualizar em massa specs funcionais históricas com drift ou apagar evidências anteriores.

## Decisions

### D1. Manter Unit/Feature e explicitar camadas

Adotar a estrutura abaixo somente para responsabilidades existentes:

```text
tests/
  Pest.php
  TestCase.php
  FeatureTestCase.php
  Unit/
    Architecture/
    Core/Domain/ValueObjects/
    Core/Infrastructure/Adapters/
    Identity/Domain/{Entities,ValueObjects}/
    Identity/Application/UseCases/
    Expense/Domain/Entities/
    Expense/Application/UseCases/
    Insights/Domain/{Enums,ValueObjects}/
     Insights/Application/UseCases/
     Metrics/Domain/Enums/
     Metrics/Application/UseCases/
  Feature/
    Core/Infrastructure/{Adapters,Providers}/
    Core/Presentation/Http/Middleware/
    Identity/Infrastructure/{Adapters,Notifications,Repositories,Providers}/
    Identity/Presentation/Http/
    Identity/Journeys/
    Expense/Infrastructure/{Adapters,Providers,Queues,Repositories}/
    Expense/Presentation/Http/
    Expense/Journeys/
    Insights/Infrastructure/Adapters/
     Insights/Presentation/Http/
     Metrics/Infrastructure/{Adapters,Providers}/
     Metrics/Presentation/Http/
  Support/
    Core/{Fakes,Stubs,Spies,Helpers}/
    Identity/{Fixtures,Helpers}/
    Expense/{Fixtures,Spies,Stubs}/
    Insights/Fixtures/
    Metrics/Fixtures/
```

Não criar todas as pastas antecipadamente. Infrastructure pode ter teste Unit se todas as dependências forem explicitamente simuladas e não houver bootstrap. `Journeys` não será depósito de cenários difíceis de classificar: cada jornada declara uma integração necessária e proprietário.

Alternativa rejeitada: mover tudo para uma raiz por contexto e abandonar Unit/Feature. O padrão atual e a seleção do runner são úteis; o problema é coerência das responsabilidades dentro deles.

### D2. Extração seletiva de suporte

Manter autoload `Tests\\` existente. Classes de suporte usam nomes como `TransactionPortFake`, `UserPortStub`, `ObservabilityPortSpy`, `ExpenseRepositorySpy`, `IdentityFixture`, `InsightCandidateFixture` e `ExpenseMetricsProjectionFixture`, ajustados ao papel efetivo. Nomes são propostas, não obrigação de criar todas as classes.

- Mock simples: criado/configurado no cenário, com expectativas específicas visíveis.
- Stub simples: usar PHPUnit stub ou classe reutilizável quando compartilhado.
- Fake/spies com comportamento substancial ou repetido: em Support com API explícita.
- Fakes do framework: `Notification::fake`, `Queue::fake`, AI SDK e assertions nativas, sem wrappers inúteis.
- Classes de retorno de preparação somente quando evitarem agrupamentos opacos e tiverem dados coesos; não devolver mocks recebidos apenas para construir uma tupla.

Migrar Mockery de contratos próprios para PHPUnit/spy. Não remover Mockery de composer, pois Laravel usa essa integração. Não criar `BaseFake`, `MockFactory`, `GenericRepositoryFake` ou interfaces para auxiliares de teste.

Alternativa rejeitada: separar cada configuração de mock em uma classe. Isso esconderia o oráculo do teste e aumentaria navegação sem reutilização relevante.

### D3. Fake de transação observa a unidade e os callbacks

O fake registra quando está dentro de `commit`, resultado/falha e callbacks daquela tentativa. Executa a operação fornecida, confirma o estado simulado e libera callbacks no momento explícito adequado; descarta os callbacks da tentativa que falhou. A API deve permitir assertions da ordem, ID/evento e não execução antecipada.

Esse fake não implementa rollback de banco/in-memory Repository nem afirma repetir fielmente o transaction manager Laravel. Não testar savepoints reais com ele. Falha depois de commit em callback externo não deve ser confundida com rollback da operação já confirmada. Os testes de mecanismo ficam em Core Feature e jornadas reais necessárias.

Alternativa rejeitada: `willReturnCallback(fn ($operation) => $operation())` como única prova de atomicidade. Chamadas ao Repository fora da unidade ou callbacks nunca executados poderiam continuar verdes.

### D4. Fixtures de identidade sem ativação oculta

Separar preparação direta de estado e jornada HTTP. Fixtures de persistência podem criar UserModel e token Sanctum em testes Feature quando isso é apenas Arrange; isso não altera o fluxo de criação do produto. Estados e valores devem ser parâmetros nomeados ou métodos com nomes claros: pending/unverified, active/verified e blocked.

Não usar `Sanctum::actingAs` nos cenários que provam Bearer real, expiração, revogação ou resolução do principal. Nesses casos criar token real e enviar o segredo pela request. Pode-se usar autenticação simulada nos cenários cujo alvo não é esse mecanismo, documentando seu limite.

`tests/Pest.php` deixa de declarar signUpIdentityByApi/signInIdentityByApi. Helpers de jornada ficam autoloadáveis em Identity Support e não chamam fake nem alteram status silenciosamente. O teste/setup escolhe fakes visíveis. Guards são esquecidos/reavaliados ao alternar credenciais em requests no mesmo processo.

Etapa 4 implementada: `IdentityFixture::create` exige status e `verifiedAt` explícitos (null representa não verificado), retorna UserModel de preparação e não cria token. `IdentityFixture::token` recebe a expiração explicitamente e persiste um token real. `IdentityHttpJourney` executa somente ações HTTP nomeadas de cadastro, confirmação assinada e login; estado/fakes continuam escolhidos pelo chamador. Os sete arquivos antes dependentes de Pest.php mantêm seus cenários com essa preparação explícita, e a jornada integrada de observabilidade conserva cadastro/confirmação reais.

### D5. Migração dos arquivos amplos por responsabilidade

| Origem atual | Destinos/responsabilidades planejados |
| --- | --- |
| Identity/EmailVerificationTest | HTTP de SignUp/Verify/Resend/Profile; Notification/worker; EloquentUserRepository; jornada de confirmação quando necessária. |
| Identity/SlidingSanctumSessionTest | HTTP da política de sessão; SessionExtensionAdapter incluindo concorrência; pruning em teste focado de integração. |
| Identity/SignUpRateLimitTest | Presentation/Http/RateLimiting, junto de arquivos focados em SignIn/Reenvio e cota autenticada. |
| Expense/ExpenseClassificationTest | HTTP de classificação; configuração ExpenseServiceProvider; Queue/worker; integração de tentativa/categorização; jornada create/classify/read. |
| Expense/ExpenseOwnershipTest | HTTP por leitura/escrita; FK/cascade em persistência; novos contratos de GET individual/paginação. |
| Expense/ExpenseObservabilityTest | intenção de eventos nas unidades de Expense/Identity; formatter/adapter/correlação em Core; poucas jornadas de wiring. |
| Insights/ExpenseAnalysisAdapterTest | Infrastructure/Adapters e jornada analítica separada se necessário; corrigir assertion editorial. |
| Insights/InsightsApiTest | Presentation/Http com fixtures explícitas e query/read observation sem dependência de nome de CTE. |
| Metrics/GetExpenseMetricsUseCaseTest | mesma responsabilidade de Application, com fixtures externas e construção direta do UseCase. |
| Metrics/Infrastructure/Adapters/ExpenseMetricsAdapterTest | preservar integração PostgreSQL focada, observação de statements, precisão e atualização após escritas confirmadas; extrair somente suporte reutilizável. |
| Metrics/Presentation/ExpenseMetricsHttpTest | Presentation/Http, conservando query textual original, contratos/erros JSON:API e proteções; separar prova de provider quando a responsabilidade justificar. |
| Identity/Application/Ports e Repositories reflexivos | avaliar permanência ou destino Architecture para fronteiras reais; não exigir ordem incidental de Reflection. |

Cada cenário antigo recebe destino registrado antes da remoção de sua origem. Ordem: mover com comportamento preservado, extrair suporte e então fortalecer os cenários, verificando cada unidade alterada. A escolha exata de nomes dos novos arquivos cabe ao apply, dentro dos destinos e contratos especificados.

### D6. Builders de Insights e consolidação de Core

Separar fatos válidos por tipo de candidato e projeções próprias de Application, sem helpers globais. Evitar conversões Domain -> Application -> Domain quando elas só tornam Arrange mais difícil; a fixture deve construir o contrato recebido pelo objeto testado.

Não reparar projeções negativas. Defaults são valores explícitos e datas fixas, não `now` ou sorteio. Soma de fixture pode ser derivada para preparar dados coesos, mas valores esperados de aritmética/seleção devem ser independentes da rotina de produção sob teste.

Consolidar Core por comportamentos (parsing, aritmética, calendário, razão/participação, arredondamento). Preferir datasets nomeados com casos abaixo/no/acima de limite. A sobreposição de `AmountArithmeticTest` com Amount/Ratio e de calendários deve ser reduzida sem perder casos distintos de APIs ou precisão.

### D7. Assertions editoriais e estruturais

Integração de Insights verifica tipo, grupo, assunto, período, ratio, limites e correspondência a uma mensagem válida; não exige frase incidental de uma variante. Testes focados do catálogo percorrem todas as variantes com IDs/datas explícitos e validam o texto aprovado, inclusive Unicode, fallback completo e placeholders.

Observabilidade lê JSON decodificado. Verifica campos/valores permitidos e ausência de `amount`, `description`, credenciais/payload; não pesquisa o literal numérico 1500 em todo o documento. Para falha de log, injetar falha determinística ou usar recurso temporário controlado, sem depender de `/nonexistent/...` estar inacessível no sistema.

Testes de query count identificam a operação analítica pelo escopo observado/connection e ausência de outras ações dentro dele, ou por monitor específico, sem acoplar a finalidade do teste ao nome `WITH periods`. Não introduzir observador de produção só para isso.

### D8. Bootstrap de teste com recursos por execução/processo

Usar integração nativa Laravel/Pest para parallel testing, após consultar docs e ordem dos hooks na versão efetiva durante o apply. O bootstrap precisa distinguir validação de configuração inicial, provisionamento e validação do banco efetivo de processo; não validar apenas depois que o framework já executou operações destrutivas.

Modelo planejado:

1. O entrypoint de teste cria um runId único e o propaga antes de iniciar subprocessos.
2. Configura somente naquela execução uma base exclusiva de teste, por exemplo `trocado_testing_<runId>`, e mantém registro exato dos destinos permitidos.
3. O mecanismo nativo deriva os bancos de processo, por exemplo `<base>_test_<token>`. O formato efetivo deve ser confirmado no framework; esses exemplos não autorizam nomes por regex ampla.
4. O guard verifica driver, URL, nome configurado, registro de ownership e `current_database()` na conexão efetiva antes de escrever/migrar/limpar. Read-only de identificação não é escrita de fixture.
5. Provisiona apenas destinos autorizados e aplica migrations incrementalmente. Não usar migrate:fresh nem depender de `--recreate-databases` como gate.
6. Propaga runId/token aos prefixos Redis, queue names, arquivos de log, protocolos concorrentes e aos workers disparados pelo teste.
7. Cleanup descarta somente recursos criados/registrados pela execução; banco reusado explicitamente não é dropado por inferência. Resíduos após término abrupto precisam de identificação exata, não sweep por substring.

O entrypoint pode ser um script de teste estreito/command de Composer com helper de bootstrap em Tests Support, executando o runner nativo e encaminhando seus argumentos. Não criar Command de negócio em Core/Infrastructure para administrar testes. Comandos diretos devem chamar o preflight apropriado ou falhar antes de mudanças com instrução explícita. Credentials/services seguem os mecanismos Lerd; não commitar secretos nem hand-edit .env para configurar serviço.

Alternativas rejeitadas: liberar qualquer banco `_test*`; compartilhar trocado_testing e confiar em deletes; bloquear globalmente toda a suíte; usar SQLite; desativar testes Redis/concorrentes no gate paralelo.

Implementação incremental da etapa 2: `composer test` chama `tests/run.php`, gera runId/segredo e manifesto temporário privado, propagados ao runner Pest. O nome exato é derivado de `trocado_testing` e runId; um comentário PostgreSQL registra ownership e deve coincidir com o manifesto antes de migrations, fixtures/limpeza ou drop. Provisionamento usa conexão administrativa separada em `postgres`, cria somente o destino registrado e recusa reuso sem ownership coincidente. A preparação executa `migrate` incrementalmente uma vez antes do runner; chamadas diretas Feature sem manifesto falham antes de inicializar a aplicação.

Cleanup normal em `finally` remove somente banco criado pelo preparador, após confirmação efetiva e nova checagem de ownership; um preparador que apenas reusa não o remove. Unit puro e listagem não provisionam/migram. Configuração em cache é recusada em vez de limpar cache operacional como efeito colateral. `tests/CreatesApplication.php` bloqueia a resolução do app pelo runner paralelo antes dos hooks de banco; é uma fronteira temporária até 10.5, não prova de paralelismo. Isolamento externo, cleanup em interrupção abrupta e bancos por token continuam nas etapas 10.x.

Estado posterior, etapa de isolamento implementada: o launcher registra antecipadamente os tokens nativos, provisiona/migra cada destino exato e permite `CreatesApplication` somente com manifesto/guard. `TestCase` seleciona o destino autorizado por `TEST_TOKEN` e valida o banco efetivo antes das fixtures. Como Feature não usa os traits destrutivos de banco do Laravel, a preparação segura permanece no launcher e os hooks nativos não recriam schema. Opções de recriação/drop/desativação de tokens são recusadas. ParaTest continua sendo o runner instalado, sem substituto. Diretórios de views compiladas, cache PHPUnit e arquivos de protocolo do ParaTest também distinguem runId; hooks de views por token sozinhos não isolam invocações.

`TestDatabaseCleanup` classifica explicitamente failed_jobs/jobs/tokens/expenses/users, preserva migrations e sequências e recusa tabelas desconhecidas. `TestResources` atribui prefixos Redis, cache, filas e logs por runId/token/cenário; teardown limpa somente esse namespace nas conexões default/cache, inclusive após purges exigidos por fork. Clientes independentes que comprovam compartilhamento recebem o mesmo namespace intencional. Aplicações de teste restauram bindings/listeners/fakes/guards; teardown também reverte transações e restaura clocks/timezone/query logs/canais. O protocolo `ConcurrentDatabaseProcess` substitui o fork aberto da sessão, desconecta conexões antes do fork, valida o filho, transmite ready/go/done/erro, observa lock PostgreSQL e reverte/fecha/aguarda ou encerra com prazo limitado.

Provas sincronizadas mantêm duas invocações de dois processos na barreira com e-mail e ID 1500 coincidentes, cache/limiter, fila e log; liberam uma invocação e verificam remoção dos seus recursos e preservação da outra antes de liberá-la. Falha controlada e filho que não termina têm provas próprias. SIGKILL do launcher continua fora da recuperação automática: a seção de evidências distingue cleanup normal/falha controlada dos resíduos de tentativas encerradas externamente.

### D9. Limpeza preserva commits e remove todos os recursos usados

Uma transação externa global de rollback não pode envolver cenários que provam commit/afterCommit/workers. Adotar cleanup explícito com catálogo mantido das tabelas mutáveis do schema e recursos por cenário, validado antes da escrita. O catálogo deve incluir jobs/failed_jobs quando usados e ser atualizado ao adicionar recursos; não truncar indiscriminadamente tabelas de metadata/migrations ou bancos de outro processo.

Fixture e worker usando resources externos devem registrar ownership e cleanup em finally. Monitores de queries, channels, events, fake clocks e guards devem ser restaurados no teardown. Os listeners Eloquent que injetam falha precisam desaparecer junto do ciclo do app ou ser removidos explicitamente, com prova por reordenação.

### D10. Redis real somente para a prova necessária

Suites comuns usam array cache/limiter e fakes. Testes dedicados comprovam cache e limiter Redis com dois clientes/conexões/processos no mesmo namespace intencional. Não parar o Redis local para simular indisponibilidade: usar falha controlada no cliente/store restrito do cenário. Mail usa transport array; IA usa fake nativo.

Fila dedicada de teste deve sobrescrever o nome resolvido pelo job/notification na configuração local daquele app, e o worker deve consumi-la explicitamente. Nunca permitir que o worker local default ou expense-classification capture mensagens da suíte. Verificar o nome efetivo no payload/store, não apenas a intenção de config.

### D11. Concorrência determinística e processos limitados

Preservar o teste de lock de sessão, acrescentando disciplina de cleanup/timeout onde necessário. Criar provas sincronizadas de colisão de e-mail e atualização condicional de tentativa de Expense. Child desconecta conexão herdada, usa destino autorizado do processo pai, comunica ready/go/done ou erro e fecha recursos. O pai observa a barreira/lock antes de liberar escrita e sempre espera/encerra o filho com prazo limitado.

Esses filhos pertencem a um cenário e usam seu banco intencionalmente para a corrida; não são processos paralelos independentes da suíte. Separar esse compartilhamento necessário do isolamento entre partes da suíte. Não fabricar corrida com duas chamadas sequenciais nem waits arbitrários. Ambiente do gate precisa de pcntl ou mecanismo de subprocesso equivalente confirmado no apply; indisponibilidade bloqueia a prova, não remove o requisito.

### D12. Metrics e documentação histórica

Reorganizar os testes já implementados de Domain/Application, Infrastructure PostgreSQL e Presentation/composição e usar fixtures próprias de Metrics. Preservar `GetExpenseMetricsUseCaseTest`, `ExpenseMetricsAdapterTest` e `ExpenseMetricsHttpTest`, com mapa de cenários/destinos; invariantes monetárias/civis compartilhadas continuam em Core. O contrato vigente está em `openspec/specs/expense-metrics/spec.md`; o histórico está em `archive/2026-10-10-add-expense-metrics` e não deve ser reescrito por movimentação de arquivos.

A integração comprova proprietário/período, soma exata, grupos/ordenação, reconciliação por statement único, leitura sem escrita/cache e atualização entre consultas após commits. HTTP comprova parsing da query original, validação antes da análise, período/default/timezone, identidade, omissão versus lista vazia, JSON:API, bloqueios e falha operacional sanitizada. Preservar esse nível de evidência, sem substituir SQL/HTTP por mocks. Statement único mais semântica PostgreSQL é prova de mecanismo de snapshot, não experimento com escrita durante a leitura.

As pendências aceitas no arquivo histórico não são automaticamente tarefas novas desta mudança. Cota compartilhada pode incluir Metrics na prova transversal já prevista em BEH-07; travessia de mês, escrita durante leitura, extensão de sessão específica e medição autenticada continuam limitações explícitas até receberem escopo e evidência próprios. Atualizar referências correntes em orientações/documentos relevantes se caminhos mudarem, mantendo rastreabilidade até os caminhos históricos sem alterar checkboxes/evidências arquivados.

Specs antigas divergentes (relações Eloquent User/Expense; 405 versus 404 na criação pública de users; Port antigo de ownership) não são oráculo literal. Os testes devem seguir arquitetura/contratos atuais. Se uma divergência não tiver decisão posterior inequívoca, apresentar ao usuário uma pergunta por vez antes de fixar a expectativa; não alterar produto para satisfazer texto obsoleto.

## Plano de evidências por responsabilidade

| Área | Prova planejada | Limitação explícita |
| --- | --- | --- |
| Core Domain | Unit de parser/aritmética/calendário/razões e limites. | Não prova schema nem consultas SQL. |
| Core adapters | UserAdapter id/status, callbacks reais, formatter/context/correlação/falha. | Intenção de evento de negócio também precisa de cenário do emissor. |
| Identity Application | Ownership antes do Repository, unidade de commit, callbacks e argumentos. | Mock não prova constraint nem rollback de tokens. |
| Identity Infrastructure/HTTP | Login real, validação/canonicalização, unicidade concorrente, exclusão/cascade/rollback, ratelimits, links/worker/sessão. | Retry injetado não equivale a deadlock natural de carga; registrar a natureza da prova. |
| Expense Application | ID/proprietário explícitos, leitura/atualização/exclusão/classificação e efeitos. | Não prova cursor nem update condicional SQL. |
| Expense Infrastructure/HTTP | Cursor real, own/alheio/ausente, validação, defaults, FK, cache/TTL/invalidação e jobs. | Cache array não prova Redis entre processos; usar cenário dedicado. |
| Insights | Projeção real, threshold exato, seleção, catálogo completo, HTTP/proteções e independência editorial. | Statement único é prova de mecanismo de snapshot; não afirmar corrida ativa sem exercitá-la. |
| Metrics Domain/Application | Enum, encaminhamento, projeções inválidas, reconciliação, percentuais/IDs/null versus vazio. | Mock não comprova SQL, snapshot ou contrato HTTP. |
| Metrics Infrastructure/HTTP | Proprietário/occurred_on, precisão/grupos, statement único, leituras atuais sem cache, query original/default/timezone, JSON:API/proteções/erros e binding. | Preservar provas entregues; escrita durante leitura, travessia de mês, sessão específica e medição autenticada permanecem limitações históricas, não claims de cobertura. |
| Arquitetura | Restrições atuais de app e contratos Data/reflexivos pertinentes. | Não medir coverage de comportamento por Reflection. |

## Risks / Trade-offs

- [Fixtures escondem regras ou reparam negativos] → API explícita, expectativas locais e construção inválida permitida.
- [Extração vira framework de testes] → apenas doubles repetidos/substanciais; nenhuma base ou interface especulativa.
- [Paralelismo atinge banco operacional] → ownership exato, guard inicial e efetivo antes de cada fronteira de escrita/cleanup; testes negativos do próprio guard.
- [Framework troca conexão depois do guard] → confirmar ordem nativa e repetir verificação do destino resolvido antes de schema/fixtures; não confiar só em config.
- [Jobs roubados por workers locais] → nome exclusivo efetivo por cenário e cleanup próprio; IA/mail sem tráfego externo.
- [Cenários afterCommit ficam falsamente verdes] → não envolver commits reais em wrapper transacional que nunca confirma.
- [Corrida trava o runner] → protocolo, timeouts, erro filho, finally e espera limitada com encerramento controlado.
- [Specs históricas contraditórias] → seguir decisões atuais inequívocas; perguntar antes de alterar um contrato ambíguo.
- [Novos testes revelam bug de produção] → manter evidência reprovada e solicitar autorização para a menor correção, sem enfraquecer expectativa.
- [Duração maior com integração Redis/concorrência] → grupos selecionáveis para desenvolvimento; gate completo continua obrigatório, sem SLO artificial.
- [Contagem muda após consolidação] → exigir equivalência por cenário, não manter 627 ou 725 como meta fixa; ambas são contagens históricas de estados diferentes.

## Migration Plan

1. Após autorização de apply, reconsultar versões/docs e inventariar cenários/recursos do estado atual, preservando alterações do usuário.
2. Definir o launcher/preflight e testar o guard em destinos falsos sem tocar dados operacionais; preparar somente bancos de teste autorizados.
3. Corrigir a assertion editorial com prova isolada e IDs distintos; estabelecer suporte necessário e mover testes por blocos pequenos com mapa origem/destino.
4. Consolidar duplicações e fortalecer cenários de Core/Identity/Expense/Insights/Metrics conforme BEH, mantendo testes anteriores rastreados.
5. Isolar Redis/filas/logs/filhos e habilitar execução paralela nativa; provar execução/processo e limpeza em falha.
6. Atualizar orientações existentes e comandos focados, aplicar Pint e executar a escada de verificação prevista em tasks.
7. Preencher rastreabilidade com evidências reais, validar OpenSpec e solicitar decisão de sincronização/arquivamento somente após todos os gates.

Rollback: reverter somente alterações desta mudança em testes/config/scripts e recursos de teste registrados, preservando trabalho prévio. Não há migration de produto nem dado operacional a restaurar. O cleanup de banco criado pela execução só atua sobre destino exato registrado e confirmado; nunca usar git reset amplo ou apagar schemas por padrão de nome.

## Open Questions

- **Resolvida pelo usuário:** execução paralela com bancos/recursos exclusivos é requisito obrigatório.
- **Sem dúvida funcional bloqueante na fase de spec:** organização e mecanismos seguem as decisões acima.
- **Verificação técnica do apply:** formato/ordem dos hooks Laravel/Pest, criação segura de base/processos, capacidade de provisionamento PostgreSQL e mecanismo concorrente disponíveis devem ser confirmados com docs/código instalado naquele momento. Falta de capacidade é bloqueio operacional com diagnóstico, não autorização para reduzir os requisitos.
- **Condicional às próximas etapas:** divergência funcional nova ou correção em produção exige pergunta ao usuário, uma por vez. Migração/fortalecimento por contexto foi autorizado em rodadas Core, Identity, Expense, Insights e Metrics. A correção do hash não autenticável (BEH-04) foi autorizada e comprovada. Após o pedido de corrigir os testes quebrados, BEH-16 foi mantido: Core remove campos HTTP herdados no callback oficial Context::hydrated, conservando outros metadados e os IDs emitidos explicitamente pelo worker. A regressão com request autenticada e worker real passa. O isolamento/paralelismo foi entregue posteriormente em 10.x. No passo 7 solicitado, 37 arquivos avulsos, cinco contextos, arquitetura e quatro gates (padrão, seeds 20261009/20261010 e dois processos) foram reconfirmados; cada gate passou com 811 testes/5.096 assertions. Tasks distingue essa aprovação executável das lacunas de organização/inventário/comportamento ainda abertas. A mudança inteira não está concluída/arquivável.
