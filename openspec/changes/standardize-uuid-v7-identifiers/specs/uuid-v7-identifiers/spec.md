## ADDED Requirements

### Requirement: UID-01 Identificadores próprios UUIDv7 com escopo explícito

O sistema MUST usar UUIDv7 para IDs de User, Expense, registros Notifications, PATs/sessões, associações de recursos de Core e IDs públicos de Insights, Metrics e sugestões. MUST usar UUIDv7 na correlação HTTP própria e exigir UUIDv7 de instalação. MUST preservar os formatos internos controlados por Laravel/SDKs, incluindo jobs/failed_jobs/migrations e payload IDs de queue. Categorias/códigos, datas, valores, contagens, versões, segredos Bearer/FCM, hashes de senha/assinatura/fingerprint e tokens de fencing MUST NOT ser tratados como IDs de entidade a converter.

#### Scenario: Todos os recursos de API próprios
- **WHEN** a API cria ou retorna User, despesa, registro push, access token, insight, resumo Metrics ou sugestão
- **THEN** seu `data.id` é uma string UUIDv7 válida e canônica
- **AND** relacionamentos de recursos próprios usam IDs UUIDv7

#### Scenario: Identificadores internos preservados
- **WHEN** Laravel cria um job, registra migration ou emite ID interno de SDK
- **THEN** o contrato nativo permanece operacional
- **AND** o projeto não muda vendor ou gerador global para transformar esses valores

#### Scenario: Valores que não são identidades
- **WHEN** uma despesa contém amount inteiro, category food e destino FCM opaco
- **THEN** esses conceitos mantêm seus tipos/bytes
- **AND** somente campos de identidade própria seguem a política UUIDv7

### Requirement: UID-02 Forma canônica e validação independente do transporte

Identificadores presentes MUST usar representação UUID textual de 36 caracteres com hífens, versão 7, variante RFC 9562 e saída minúscula. O sistema MUST validar essa invariante em Domain/contratos antes da persistência/lookup, inclusive fora de HTTP. MUST normalizar somente caixa de UUID textual válido; MUST NOT aceitar inteiro, string numérica, hash, nil, versão diferente, whitespace, bytes sem hífens ou variante inválida como ID de recurso. Ausência pré-persistência MUST ser explícita e não pode virar ID vazio/zero ou ser aceita em owner/FK/saída obrigatória.

#### Scenario: Caixa equivalente
- **WHEN** um UUIDv7 textual válido é recebido em maiúsculas
- **THEN** sua identidade é equivalente à forma minúscula
- **AND** comparação de ownership e resposta usam a forma canônica

#### Scenario: ID legado ou malformado
- **WHEN** um chamador fornece 42, "42", UUIDv4, hash SHA-256, nil, variante inválida ou UUID com whitespace como identidade própria
- **THEN** o contrato rejeita o ID antes da query de negócio
- **AND** não há cast para int, truncamento ou transformação de bits para aparentar v7

#### Scenario: Entidade ainda não persistida
- **WHEN** um contrato existente admite entidade sem ID antes do create
- **THEN** a ausência permanece null até a geração legítima
- **AND** um recurso persistido/retornado nunca contém ID null

### Requirement: UID-03 Geração UUIDv7 padrão e identidade imutável

IDs novos MUST ser produzidos por gerador UUIDv7 suportado nas bordas, com unicidade protegida no banco. MUST NOT usar UUIDv4, hash público, conversão de inteiro ou montagem manual de hash/timestamp como substituto do gerador padrão. ID de entidade ou associação confirmada MUST ser imutável em updates, rotação, extensão de sessão e retry. O timestamp embutido MUST NOT determinar data financeira, validade de sessão ou autorização, nem provar ordem global de cadastro.

#### Scenario: Criação seguida de edição
- **WHEN** uma despesa recebe UUIDv7 e seu valor/categoria é atualizado
- **THEN** o ID permanece igual
- **AND** somente os campos editáveis mudam

#### Scenario: UUID de projeção histórica
- **WHEN** setembro histórico é consultado pela primeira vez em outubro
- **THEN** o UUIDv7 é emitido legitimamente na primeira associação
- **AND** a análise continua setembro, sem fabricar timestamp UUID a partir do período

#### Scenario: Tentativa de mudar ID
- **WHEN** um cliente tenta atribuir ID server-owned em create/update
- **THEN** a validação fechada preserva sua rejeição
- **AND** nenhum identificador confirmado é substituído

### Requirement: UID-04 Persistência PostgreSQL e referências UUID

PKs próprias em users, expenses, notifications, personal_access_tokens e resource_identities MUST usar tipo PostgreSQL uuid com geração v7 e proteção de versão/variante. Owner e sessão MUST usar colunas UUID compatíveis, sem sequence/autoincremento de identidade própria. FKs/uniqueness/cascades/indexes existentes MUST ser conservados; tokenable_id MUST suportar User UUID sem alterar seu morph type. O sistema MUST NOT manter coluna paralela de ID inteiro ou alias de compatibilidade.

#### Scenario: Schema novo completo
- **WHEN** o schema é construído no ambiente autorizado ou em banco exclusivo do launcher
- **THEN** PKs e referências próprias possuem tipos UUID e constraints coerentes
- **AND** rows com PK própria não v7 ou FK órfã são rejeitadas

#### Scenario: Encerramento de conta
- **WHEN** a exclusão autorizada da User UUID confirma
- **THEN** despesas, PATs, destinos associados e identidades auxiliares da conta são removidos conforme seus lifecycle/cascades
- **AND** dados de outra conta permanecem

#### Scenario: Schema técnico nativo
- **WHEN** migrations/jobs/failed_jobs são criados pelo framework
- **THEN** sua estratégia interna de chave continua nativa
- **AND** isso não autoriza ID inteiro em uma entidade/recurso próprio

### Requirement: UID-05 Contratos PHP sem pressuposto de inteiro

Ports, Repositories, UseCases, Entities, Data, controllers, caches e payloads próprios MUST transportar IDs presentes como strings UUIDv7 canônicas ou conceito puro validado equivalente, nunca int/float. UserPort MUST obter exclusivamente o owner UUID do guard Sanctum e falhar como autenticação se ausente/inválido. UUID de owner MUST atravessar todos os contextos sem imports de Models/Infrastructure de outro contexto. Validação/geração MUST preservar as fronteiras puras de Domain/Application.

#### Scenario: Owner atravessa a análise
- **WHEN** UserPort fornece um owner UUIDv7 para Expense, Notifications, Insights ou Metrics
- **THEN** a leitura/escrita recebe o mesmo owner canônico explicitamente
- **AND** não consulta outra conta nem transforma UUID em zero

#### Scenario: Principal inválido
- **WHEN** o guard não oferece ID de User UUIDv7 válido
- **THEN** a capacidade de identidade falha como não autenticado
- **AND** não usa Context, outro guard ou ID enviado pelo cliente como fallback

### Requirement: UID-06 HTTP UUIDv7 sem regressão de proteção

Rotas e relações de entidades próprias MUST aceitar UUIDv7 e conservar autenticação, atividade, verificação, throttle, ownership e statuses. Rotas de recurso com ID legado/malformado/versão errada MUST produzir 404 JSON:API sem lookup de negócio; UUIDv7 alheio/inexistente MUST preservar o mesmo contrato de não encontrado. Documentos inválidos MUST conservar 422/pointers e Bearer inválido MUST conservar 401. MUST NOT provocar erro SQL de cast UUID ou escolher owner pela rota sem checagem.

#### Scenario: Recurso da própria conta
- **WHEN** uma conta apta consulta o UUIDv7 de recurso próprio
- **THEN** recebe seu contrato de sucesso com IDs canônicos

#### Scenario: ID numérico antigo
- **WHEN** um cliente acessa rota própria com /42
- **THEN** recebe 404 JSON:API
- **AND** nenhum alias busca o registro por inteiro antigo

#### Scenario: UUIDv7 de outra conta
- **WHEN** a conta A tenta consultar/alterar/excluir o UUIDv7 de B
- **THEN** o owner permanece A e a operação é recusada pelo contrato de não encontrado

### Requirement: UID-07 Instalação UUIDv7 e cadastro push coerente

Notifications MUST gerar registro UUIDv7 e exigir installation_id UUIDv7 do cliente, conservando o destino FCM exato, sessão/owner, idempotência, geração, cifragem, fingerprints e conflitos. MUST NOT editar uma instalação v4 para v7 por alteração de bits ou confundi-la com ID do registro/FCM. Repetição/rotação MUST preservar ID de registro. IDs de mensagem/resource_id próprios futuros MUST seguir v7 sem ativar envio nesta mudança.

#### Scenario: Instalação v7 válida
- **WHEN** um cliente apto registra installation_id UUIDv7 e token FCM válido
- **THEN** recebe registro UUIDv7 e os atributos públicos existentes
- **AND** repetição retorna o mesmo ID sem duplicar row

#### Scenario: Instalação de outra versão
- **WHEN** installation_id é UUIDv4 ou outra versão
- **THEN** recebe 422 com pointer /data/attributes/installation_id
- **AND** não cria registro ou ecoa o destino

#### Scenario: Instalação não é registro
- **WHEN** o backend retorna installation_id e data.id
- **THEN** ambos são v7 mas mantêm seus papéis independentes
- **AND** conhecer qualquer um não concede ownership nem transfere destino

### Requirement: UID-08 Transição local sem legado e sem destruição fora do escopo

A implementação MUST executar o reset autorizado somente após identificar e conferir o banco local de desenvolvimento correto. MUST permitir recriação desse banco sem mapeamento/compatibilidade de IDs antigos e sem seed automático. MUST pausar/restaurar workers relevantes e tratar somente filas/chaves próprias incompatíveis. MUST NOT usar essa autorização em produção/banco compartilhado/de testes, apagar recursos de outros sites, usar FLUSHALL/FLUSHDB ou contornar manifesto/ownership do launcher. Não executar reset, migrations ou testes por motivo de criação desta spec.

#### Scenario: Reset de desenvolvimento consentido
- **WHEN** apply autorizado confirma o alvo local correto antes de migrate:fresh
- **THEN** o schema é recriado em UUIDv7 e IDs/tokens/cursors antigos deixam de valer
- **AND** somente recursos próprios incompatíveis são descartados

#### Scenario: Alvo divergente
- **WHEN** a configuração aponta produção, banco compartilhado ou DB de testes
- **THEN** o reset é interrompido antes de qualquer alteração

#### Scenario: Launcher de testes
- **WHEN** a futura suíte Feature é executada
- **THEN** usa banco exclusivo, ownership e migrations incrementais
- **AND** não usa migrate:fresh nem autorização por substring testing
