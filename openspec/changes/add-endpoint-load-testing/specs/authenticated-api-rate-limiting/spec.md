## MODIFIED Requirements

### Requirement: API autenticada compartilha cota por User

O sistema MUST limitar a 60 requisições por minuto por User autenticado as rotas protegidas atuais de Identity (`GET`, `PATCH` e `DELETE /api/users/{user}`) e Expense (`GET` e `POST /api/expenses`). A cota MUST ser compartilhada entre essas rotas e entre todos os tokens e IPs do mesmo User; Users distintos MUST ter contadores independentes. Requisições admitidas MUST consumir cota mesmo quando a operação resultar em erro após a autenticação. Somente um alvo dedicado não produtivo, identificado e autorizado para testes de capacidade, MUST permitir perfil explícito de cota positiva ampliada, com configuração efetiva registrada e aplicada às rotas que compartilham esse limiter. Na ausência desse perfil, inclusive em produção e desenvolvimento comum, MUST prevalecer 60. O perfil de capacidade MUST NOT desativar autenticação, autorização ou o middleware de rate limit; o cenário da proteção original MUST usar 60 e namespace independente/restaurado.

#### Scenario: Cota acumulada entre contextos
- **WHEN** o mesmo User realiza 60 requisições admitidas em um minuto distribuídas entre rotas protegidas de Identity e Expense
- **THEN** a próxima requisição autenticada a qualquer uma dessas rotas recebe `429`
- **AND** o endpoint não executa a operação solicitada

#### Scenario: Tokens e IPs do mesmo User
- **WHEN** o mesmo User alterna Personal Access Tokens válidos ou IPs entre requisições
- **THEN** todas essas requisições consomem a mesma cota do User

#### Scenario: Identidades independentes
- **WHEN** um User esgota sua cota e outro User envia requisição autenticada dentro da própria cota, mesmo do mesmo IP
- **THEN** o segundo User não é bloqueado pela cota do primeiro

#### Scenario: Erro após autenticação consome cota
- **WHEN** uma requisição autenticada admitida resulta em erro de validação ou recurso inexistente no endpoint protegido
- **THEN** a tentativa ainda consome uma unidade da cota daquele User

#### Scenario: Capacidade no alvo dedicado
- **WHEN** o perfil ampliado é explicitamente ativado e confirmado em uma instância dedicada não produtiva de carga
- **THEN** ela aplica a cota positiva registrada, preservando compartilhamento por User e isolamento entre Users
- **AND** outras instâncias sem o perfil continuam aplicando 60 requisições por minuto

#### Scenario: Tentativa de ampliar produção ou desenvolvimento comum
- **WHEN** a configuração tenta ativar o perfil de capacidade sem identificar um alvo dedicado não produtivo autorizado
- **THEN** o perfil é rejeitado sem ampliar a cota e a campanha não é iniciada

### Requirement: Contadores autenticados usam o Redis do limiter

O sistema MUST armazenar a cota autenticada no mesmo store Redis compartilhado de rate limit já configurado para a API pública, com chave distinta das cotas de SignIn e SignUp. O sistema MUST NOT fazer fallback silencioso para cache local quando o Redis estiver indisponível e MUST manter a configuração de cache geral independente. Instâncias de carga MUST usar namespace próprio da campanha e perfil; a cota ampliada e a cota original MUST NOT reutilizar contadores contaminados de outro perfil ou de desenvolvimento/produção.

#### Scenario: Contagem distribuída
- **WHEN** duas instâncias conectadas ao mesmo Redis recebem requisições do mesmo User no perfil original
- **THEN** ambas observam uma cota compartilhada de 60 requisições por minuto

#### Scenario: Redis indisponível
- **WHEN** Redis não está acessível durante a aplicação do limite autenticado
- **THEN** a requisição não prossegue sem limite por meio de um cache local alternativo

#### Scenario: Perfis de carga independentes
- **WHEN** a campanha alterna entre capacidade e validação dos 60 requests/minuto
- **THEN** cada perfil usa seus contadores próprios e o estado efetivo é confirmado antes dos requests medidos
- **AND** a limpeza não altera contadores da aplicação comum ou de outra campanha
