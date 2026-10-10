# test-suite-organization Specification

## Purpose
TBD - created by archiving change organize-and-strengthen-context-tests. Update Purpose after archive.
## Requirements
### Requirement: ORG-01 Localização pela responsabilidade principal

A suíte MUST localizar unitários em `tests/Unit/<Contexto>/<Camada>/` e testes com aplicação iniciada em `tests/Feature/<Contexto>/<Camada>/`, usando as camadas existentes do projeto e subpastas com papéis claros. HTTP MUST pertencer a Presentation; persistência, adapters, providers, notifications e workers MUST pertencer a Infrastructure. Jornadas deliberadamente integradas MUST ser identificadas em `tests/Feature/<Contexto>/Journeys/`, com contexto proprietário e finalidade explícitos. A organização MUST NOT criar bounded contexts de produto, pastas vazias, hierarquias genéricas de bases ou importar Laravel para preparar testes puros de Domain/Application.

#### Scenario: Localizar um teste de Repository
- **WHEN** o comportamento alvo é mapping, query, constraint ou escrita de um Repository Eloquent
- **THEN** o teste é encontrado em Feature do contexto proprietário, sob Infrastructure/Repositories/Persistence
- **AND** seu nome identifica o Repository ou a responsabilidade específica exercitada

#### Scenario: Localizar contrato HTTP
- **WHEN** o alvo é validação, middleware, status, headers ou documento JSON:API
- **THEN** o teste pertence a Presentation/Http do contexto proprietário
- **AND** o arquivo não reúne testes diretos de provider ou Repository sem objetivo HTTP

#### Scenario: Unidade de adapter sem bootstrap
- **WHEN** um adapter de Infrastructure é exercitado somente com dependências injetadas e sem container/banco
- **THEN** o teste pode permanecer em Unit/Infrastructure
- **AND** a classificação Unit não é determinada apenas por o código pertencer a Infrastructure

### Requirement: ORG-02 Arquivos coesos e descoberta independente

Cada arquivo MUST possuir uma responsabilidade principal reconhecível pelo nome e localização. Helpers MUST NOT depender de outro arquivo de testes ser carregado antes; arquivos MUST ser executáveis individualmente. A suíte MUST separar configuração de provider, jornada de classificação, worker, contrato HTTP, cache e atualização de perfil atualmente reunidos em arquivos amplos, sem fragmentar artificialmente cada assertion em um arquivo.

#### Scenario: Dividir a verificação de e-mail
- **WHEN** os cenários de Identity são reorganizados
- **THEN** cadastro, link público, reenvio, notification/worker, perfil e persistência têm destinos coesos
- **AND** o cenário de Repository que preserva e-mail deixa de ficar escondido no arquivo de verificação de e-mail

#### Scenario: Dividir classificação de despesa
- **WHEN** os cenários de Expense são reorganizados
- **THEN** configuração de provider, classificação HTTP, processamento de fila e cache têm arquivos distintos por responsabilidade
- **AND** jornadas necessárias continuam exercitando o fluxo integrado sem depender de helpers declarados em outros testes

### Requirement: ORG-03 Suporte reutilizável separado dos cenários

Fixtures, builders, fakes, stubs e spies reutilizados ou com implementação substancial MUST ficar em classes autoloadáveis em `tests/Support/<Contexto>/`, com subpastas `Fixtures`, `Fakes`, `Stubs`, `Spies` ou `Helpers` apenas quando houver necessidade real. Capacidades transversais MUST pertencer a `tests/Support/Core/`. Classes MUST revelar seu papel no nome, usar tipos explícitos e não residir em `app/`. A extração MUST ser motivada por reutilização real ou legibilidade, sem criar uma classe para cada mock trivial.

#### Scenario: Repository double do cache
- **WHEN** o Repository simplificado com contadores é usado para testar páginas cacheadas
- **THEN** sua implementação fica fora do arquivo de cenários, com nome e API explícitos
- **AND** seus valores de resposta e chamadas registradas podem ser configurados/inspecionados sem depender de IDs mágicos fixos

#### Scenario: Capacidade autenticada compartilhada
- **WHEN** Identity, Expense, Insights ou Metrics precisa de um principal simulado em teste puro
- **THEN** pode reutilizar um stub de UserPort pertencente a Core
- **AND** o suporte de Core não importa Models ou classes de domínio dos contextos consumidores

#### Scenario: Double pontual pequeno
- **WHEN** um cenário exige somente uma expectativa simples de um contrato
- **THEN** a configuração do mock permanece próxima da ação e assertions do cenário
- **AND** não é criada uma classe compartilhada sem ganho demonstrável

### Requirement: ORG-04 Expectativas locais e mecanismo consistente de doubles

Mocks de contratos próprios MUST usar PHPUnit como mecanismo padrão, compatível com Pest instalado. Comportamentos sem verificação de interações MUST usar stub/fake explícito ou stub do PHPUnit em vez de mock sem finalidade. Expectativas `once`, `never`, argumentos e falhas específicas MUST permanecer no cenário; suporte compartilhado MUST NOT esconder quotas de chamadas ou decidir o resultado esperado. Fakes nativos de Laravel e AI SDK MUST ser preservados quando exercitam a integração do framework. Mockery MUST NOT ser usado para contratos próprios onde o padrão adotado já atende, sem remover dependência usada pelo framework.

#### Scenario: Cache de categorização
- **WHEN** os testes hoje configurados com Mockery para ExpenseRepository são migrados
- **THEN** as expectativas equivalentes ficam explícitas no cenário com PHPUnit ou um spy reutilizável
- **AND** a fixture não recebe um número de chamadas esperado para ocultar a assertion

#### Scenario: Falha de integração simulada
- **WHEN** um cenário precisa de provider de IA, queue ou notification simulados
- **THEN** usa a capacidade fake nativa apropriada e assertions nativas quando relevantes
- **AND** não cria wrappers de uma única chamada apenas para uniformizar sintaxe

### Requirement: ORG-05 Fixtures de identidade com estado explícito

Preparação de conta MUST distinguir `pending`, `active`, `blocked`, e-mail verificado/não verificado e presença de tokens. Helpers de cadastro real MUST NOT ativar ou verificar silenciosamente a conta; fakes de notification/queue MUST ser escolhidos pelo teste ou setup visível. Tests de outros contextos MUST poder preparar uma conta apta sem executar cadastro e login HTTP, salvo quando essa integração for o objetivo da jornada. Helpers MUST retornar dados tipados/coerentes, sem tuplas de mocks apenas para repassá-los ao chamador.

#### Scenario: Conta apta para testar Expense
- **WHEN** um contrato de Expense precisa apenas de usuário autenticado ativo e verificado
- **THEN** prepara explicitamente esses estados e a credencial necessária
- **AND** uma regressão na rota pública de cadastro não é pré-requisito para exercitar esse cenário de Expense

#### Scenario: Jornada de cadastro real
- **WHEN** o objetivo é provar cadastro, verificação e acesso posterior
- **THEN** o teste executa os limites reais definidos para a jornada
- **AND** não simula confirmação por atualização oculta da fixture

### Requirement: ORG-06 Builders de dados sem oráculos de produção

Builders de candidatos, resumos e projeções MUST pertencer ao contexto que define esses dados, ser determinísticos e permitir overrides nomeados de fatos relevantes. MUST distinguir construção válida de construção propositalmente inválida. MUST NOT calcular o valor esperado pela mesma rotina de produção sob teste ou copiar algoritmo de produção para fabricar um oráculo. Regras específicas de um cenário MUST continuar visíveis no dataset ou Arrange.

#### Scenario: Candidatos de Insights
- **WHEN** composição, seleção e invariantes precisam construir candidatos semelhantes
- **THEN** reutilizam construção coesa de fatos válidos sem listas duplicadas de tipos em cada arquivo
- **AND** os testes de invariantes ainda podem omitir ou contradizer fatos explicitamente para exercitar rejeições

#### Scenario: Projeção inválida de Metrics
- **WHEN** o teste precisa de categorias duplicadas, valor não canônico ou soma inconsistente
- **THEN** a fixture permite fornecer essa projeção sem reparação automática
- **AND** o esperado é independente da execução do UseCase avaliado

### Requirement: ORG-07 Consolidação sem perda silenciosa de cenários

Movimentação, renomeação, extração e consolidação MUST registrar a correspondência entre cada cenário antigo e seu destino. Um teste MUST NOT ser removido somente por parecer semelhante ou diminuir a quantidade de arquivos. Sobreposições de centavos, datas e razões em Core e invariantes de Domain em arquivos de Application de Insights MUST ser consolidadas por comportamento, mantendo limites, precisão, timezone e imutabilidade pertinentes. A contagem total de testes MUST NOT ser critério de equivalência funcional.

#### Scenario: Dois testes de formato monetário
- **WHEN** dois datasets exercitam o mesmo parser de centavos
- **THEN** podem ser consolidados em um dataset nomeado com a união dos casos relevantes
- **AND** precisão arbitrária, sinais, zeros à esquerda e caracteres de controle não são perdidos

#### Scenario: Redução legítima da contagem
- **WHEN** a consolidação reduz o número de testes gerados
- **THEN** a matriz demonstra quais cenários continuam comprovados e quais duplicações foram removidas
- **AND** a redução não é apresentada como perda nem como ganho de cobertura sem evidência

### Requirement: ORG-08 Bootstrap e fronteiras da suíte

`tests/Pest.php` MUST concentrar associação de TestCases, hooks e configuração geral, sem helpers globais de mutação de negócio. Unitários de Domain/Application MUST executar sem bootstrap Laravel e sem PostgreSQL/Redis. Architecture MUST continuar verificando `app/` com as permissões específicas existentes, independentemente da liberdade de integração do suporte de testes. Classes de Support MUST NOT ser descobertas como testes nem introduzir dependências de teste em produção.

#### Scenario: Executar unitários puros
- **WHEN** a suíte Unit de Domain/Application é executada sem serviços de integração disponíveis
- **THEN** seus cenários não exigem conexão nem inicialização Laravel
- **AND** nenhuma fixture global abre conexão durante a descoberta

#### Scenario: Helper integra contextos
- **WHEN** uma fixture Feature cria identidade para um cenário de Expense
- **THEN** essa integração permanece explícita e restrita ao código de testes
- **AND** não altera a matriz de dependências das camadas de produto
