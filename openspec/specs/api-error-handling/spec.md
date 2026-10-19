# api-error-handling Specification

## Purpose
Preservar o contrato de erros JSON:API na tradução de exceções da API, com ownership por contexto, precedência dos tratamentos específicos, mensagens públicas seguras e conservação de status, origens, headers e política de reporte.

## Requirements
### Requirement: ERR-01 Documento de erro JSON:API consistente

O tratamento de exceções da API MUST produzir documento com array `errors`, `Content-Type: application/vnd.api+json` e status textual coerente com o HTTP. MUST preservar título, detalhe, quantidade e ordem dos erros e membros opcionais existentes. MUST NOT acrescentar `data` a documentos de erro nem reclassificar origens existentes.

#### Scenario: Conflito de e-mail preserva a primeira tradução efetiva
- **WHEN** o fluxo HTTP lança `EmailAlreadyUsedException`
- **THEN** responde 409 com título `E-mail já utilizado`, detalhe da exceção e status textual `409`
- **AND** o erro inclui `source.pointer` igual a `/data/attributes/email`
- **AND** não existe um segundo registro concorrente para a mesma tradução

#### Scenario: Campos específicos conservam seus pointers
- **WHEN** os renderers existentes tratam senha inválida, avatar inválido ou cursor de despesa inválido
- **THEN** respondem 422 e preservam respectivamente `/data/attributes/password`, `/data/attributes/avatar` e `/page/cursor`
- **AND** não substituem esses pointers por `source.parameter`

### Requirement: ERR-02 Tradução específica preserva semântica e ownership

Cada contexto MUST manter na borda HTTP suas traduções de falhas, sem introduzir dependências HTTP em Domain/Application ou imports entre contextos de negócio. A composição global MUST apenas conectar os registros, sem definir mensagens ou particularidades de negócio. A construção transversal do documento MUST ser compartilhada sem conhecer os contextos consumidores. Status, títulos, detalhes e presença/ausência de origens da baseline efetiva MUST permanecer iguais.

#### Scenario: Falhas de cada contexto mantêm seus contratos
- **WHEN** são exercitadas as traduções existentes de Identity, Expense e Notifications
- **THEN** credenciais inválidas retornam 401, e-mail não confirmado/conta inativa retornam 403, ausências retornam 404, conflitos retornam 409 e dados inválidos retornam 422
- **AND** cada caso mantém seus textos e membros específicos, incluindo os ramos de status da conta e o pointer do campo inválido de Notifications
- **AND** nenhuma exceção de Domain/Application precisa renderizar HTTP

### Requirement: ERR-03 Validação mantém multiplicidade e origem

Para requests `api/*`, `ValidationException` MUST produzir um erro por mensagem na ordem original, com título `Erro de validação`, detalhe da mensagem, status textual `422` e `source.pointer` formado pelo campo com pontos substituídos por barras e prefixo `/`. MUST NOT reduzir múltiplas mensagens a uma só.

#### Scenario: Vários campos e várias mensagens
- **WHEN** a validação da API fornece duas mensagens para `data.attributes.password` e uma para `data.attributes.email`
- **THEN** responde 422 com três erros na ordem fornecida
- **AND** os dois primeiros apontam para `/data/attributes/password` e o último para `/data/attributes/email`

### Requirement: ERR-04 Fallback HTTP preserva segurança e headers

O fallback do exception handler em `api/*` MUST conservar o status original e as mensagens públicas atuais para os códigos conhecidos e os defaults de status não catalogados. MUST preservar headers funcionais e remover Content-Length obsoleto quando substituir o corpo. MUST NOT expor mensagem interna, stack trace, SQL, credenciais ou dados sensíveis de uma falha desconhecida.

#### Scenario: Limite excedido mantém tempo de espera
- **WHEN** o exception handler produz 429 com `Retry-After`
- **THEN** a normalização retorna erro JSON:API de status `429` com os textos públicos atuais
- **AND** conserva o valor de `Retry-After`

#### Scenario: Método não permitido mantém métodos aceitos
- **WHEN** o exception handler produz 405 com header `Allow`
- **THEN** a normalização mantém 405 e o valor de `Allow`
- **AND** o documento de erro usa status textual `405`

#### Scenario: Catálogo e defaults permanecem compatíveis
- **WHEN** são normalizadas respostas de exceção com os códigos conhecidos ou códigos 418 e 507 não catalogados
- **THEN** cada código conhecido mantém seus títulos e detalhes atuais, incluindo 419 como sessão expirada
- **AND** 418 usa o default público de erro na solicitação e 507 o default público de erro interno
- **AND** o status HTTP não é substituído por 400 ou 500

#### Scenario: Falha interna não vaza informação
- **WHEN** uma exceção inesperada com SQL ou segredo em sua mensagem resulta em 500
- **THEN** o cliente recebe `Erro interno do servidor` e `Não foi possível processar a solicitação.`
- **AND** não recebe mensagem original, trace ou segredo

### Requirement: ERR-05 Precedência conserva erros específicos e documentos prontos

Traduções específicas MUST ter oportunidade de responder antes dos fallbacks genéricos aplicáveis. O 404 de DELETE de push registrations MUST permanecer uniforme para ID inválido, registro inexistente ou de terceiro, sem afetar o 404 genérico de outras rotas. O fallback MUST NOT reescrever respostas cujo Content-Type já começa com `application/vnd.api+json`.

#### Scenario: Registro push indisponível mantém 404 uniforme
- **WHEN** DELETE de `/api/push-registrations/{registration}` recebe ID malformado, ausente ou de terceiro, inclusive quando a rejeição ocorre antes do controller
- **THEN** os casos retornam 404 JSON:API com título `Registro push não encontrado` e o mesmo detalhe público atual
- **AND** não são substituídos por `Recurso não encontrado`

#### Scenario: Outra rota ausente usa fallback genérico
- **WHEN** uma rota API inexistente fora do caso específico de DELETE de registro push gera `NotFoundHttpException`
- **THEN** responde 404 com título `Recurso não encontrado` e detalhe `O recurso solicitado não foi encontrado.`

#### Scenario: Erro JSON:API já construído permanece intacto
- **WHEN** uma resposta de erro já JSON:API, inclusive erro de query de Insights/Metrics com `source.parameter`, chega ao hook final
- **THEN** conserva corpo, status, origens e headers, sem novo envelope ou texto genérico

### Requirement: ERR-06 Escopo e política de reporte permanecem inalterados

A modularização MUST preservar a seleção atual de JSON por `api/* || expectsJson()`, os guards de API dos tratamentos de validação/404/fallback e o alcance atual dos renderers tipados de negócio. MUST preservar as exclusões explícitas de reporte e o comportamento padrão do Laravel para as demais exceções. MUST NOT converter indiscriminadamente respostas não API para JSON:API nem silenciar toda exceção de negócio.

#### Scenario: Erros de framework fora da API conservam tratamento Laravel
- **WHEN** uma requisição fora de `api/*` gera erro de validação ou rota ausente, com e sem expectativa de JSON
- **THEN** mantém a escolha atual de JSON/HTML/redirect do framework
- **AND** não passa a receber o fallback JSON:API exclusivo da API

#### Scenario: Renderer de negócio não ganha novo guard
- **WHEN** uma exceção de negócio com renderer tipado existente é lançada fora de `api/*`
- **THEN** a extração conserva o mesmo resultado do renderer atual, sem acrescentar restrição por caminho

#### Scenario: Exclusões explícitas não são ampliadas
- **WHEN** são comparadas as configurações de reporte antes e depois da extração
- **THEN** permanecem excluídas explicitamente as três exceções atuais de Notifications, cursor inválido, conta inativa, senha inválida, e-mail usado, credenciais inválidas e e-mail não confirmado
- **AND** as demais exceções mantêm a política padrão anterior, sem exclusão por classe base ou namespace
