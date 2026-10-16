## ADDED Requirements

### Requirement: LOAD-01 Carga simples com Pest em PHP

O sistema MUST oferecer carga HTTP manual das leituras `GET /api/expenses`, `/api/metrics/expenses`, `/api/insights` e `/api/expenses/suggestions` usando a API PHP pública de Pest/Stressless. Cada execução MUST usar uma URL fixa, uma credencial e um processo de carga. MUST NOT exigir JS próprio, servidor Node, adaptação do motor, múltiplos tokens ou navegação dinâmica. Sugestões MUST usar uma query válida fixa nesta versão.

#### Scenario: Uma leitura selecionada
- **WHEN** o operador seleciona uma entrada e fornece configuração válida
- **THEN** somente o arquivo correspondente executa sua URL com o token fornecido
- **AND** não há login por request, rotação de conta ou seguimento de cursores durante a carga

### Requirement: LOAD-02 Execução opt-in e descoberta sem carga

`test:load` MUST permitir listar catálogo/testes sem ler configuração, fazer download do motor ou enviar HTTP. MUST exigir seleção explícita de cenário ou endpoint para executar e MUST NOT entrar na descoberta funcional/CI padrão nem ser ocultado por skips.

#### Scenario: Listar sem configuração
- **WHEN** o operador usa `--list` ou `--list-tests`
- **THEN** a seleção é exibida sem preflight, banco ou gerador de carga

#### Scenario: Seleção inválida
- **WHEN** não há seleção ou os filtros/opções são inválidos ou divergentes
- **THEN** o comando falha antes de iniciar HTTP

### Requirement: LOAD-03 Alvo local dedicado e segredo privado

O operador MUST preparar e confirmar explicitamente um alvo local dedicado com configuração/dados próprios e uma conta apta com PAT real. A ferramenta MUST aceitar URL/token somente por JSON privado regular externo ao repositório, com limite de tamanho e confirmação `dedicatedTarget`. MUST rejeitar URL externa, URL com credenciais/query/fragment e configuração pública/malformada. MUST NOT presumir que o banco do Pest configure o servidor nem provisionar, migrar ou limpar recursos automaticamente.

#### Scenario: Configuração secreta inválida
- **WHEN** o arquivo está ausente, é público, contém campos inválidos ou não confirma o alvo dedicado
- **THEN** a execução é recusada sem divulgar credencial/conteúdo

#### Scenario: Preparação manual
- **WHEN** a configuração aponta para um alvo já preparado e confirmado pelo operador
- **THEN** o runner executa apenas HTTP, sem migrations, seeder, drop ou limpeza de Redis/contas/tokens

### Requirement: LOAD-04 Preflight autenticado antes da carga

O runner MUST enviar uma requisição limitada à mesma URL/credencial antes da medição e exigir HTTP 200 e JSON:API válido com `data`, sem erros. MUST NOT medir um preflight 401/403/422/429/5xx ou corpo inválido como operação bem-sucedida. Ownership, cursores e correção por resposta sob carga MUST permanecer fora desta versão e continuar cobertos pela suíte funcional.

#### Scenario: Token não reconhecido pelo servidor
- **WHEN** o alvo rejeita o Bearer ou retorna documento inválido no preflight
- **THEN** a carga não começa e o teste falha sem expor token ou corpo financeiro

### Requirement: LOAD-05 Concorrência e duração limitadas

Cada execução MUST usar concorrência inteira de 1 a 20 e duração inteira de 1 a 30 segundos, com defaults 1/5. MUST executar um único cenário/processo por vez, com prazo finito do runner e sem escalada automática. MUST preservar a cota e todos os middlewares do produto; respostas limitadas MUST NOT ser apresentadas como capacidade da operação de negócio.

#### Scenario: Limite inválido
- **WHEN** concorrência/duração são zero, negativos, não inteiros ou ultrapassam os intervalos
- **THEN** a execução é recusada antes do gerador

#### Scenario: Limiter alcançado
- **WHEN** a rodada recebe erros HTTP, inclusive por atingir a cota
- **THEN** a fração de falhas reprova a execução sem alterar o limiter para obter verde

### Requirement: LOAD-06 Métricas suportadas e assertions explícitas

O teste MUST registrar requests, RPS, concorrência/duração configuradas, fração de falhas e p50/p95 em ms usando os resultados públicos do plugin. MUST reprovar zero requests ou falha HTTP; um limiar positivo de p95 MAY ser fornecido explicitamente. MUST NOT fabricar p99/distribuição por status, agregar percentis de processos, declarar capacidade VPS ou regressão aprovada sem limite informado. O relatório MUST omitir token, headers, corpo e fatos financeiros.

#### Scenario: Medição sem limiar de latência
- **WHEN** há requests sem falhas e nenhum p95 máximo foi fornecido
- **THEN** as métricas são apresentadas sem alegar aprovação de SLA ou calibração

#### Scenario: Limiar fornecido
- **WHEN** a rodada ultrapassa o p95 máximo explicitamente informado
- **THEN** a assertion reprova e as métricas observadas permanecem visíveis sem segredos
