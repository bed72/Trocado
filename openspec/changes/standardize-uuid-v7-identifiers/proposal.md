## Why

O projeto mistura IDs inteiros de entidades, UUIDv4 de registros/requests e hashes públicos de projeções. A decisão é adotar UUIDv7 em todos os identificadores controlados pelo projeto e expostos pela API, incluindo Insights, Metrics e sugestões, preservando sua identidade entre consultas equivalentes.

Ainda não há usuários/dados a preservar segundo o usuário; este é o momento de substituir o contrato antes de consolidar consumidores, sem carregar compatibilidade de IDs antigos.

## What Changes

- **BREAKING:** User, Expense, registros Notifications e sessões/PATs usam UUIDv7 em PKs, FKs, contratos PHP, rotas, relacionamentos e JSON:API. Inteiros, UUIDs de outras versões e hashes antigos deixam de ser IDs de recursos aceitos.
- **BREAKING:** `installation_id` recebido do aplicativo passa a exigir UUIDv7; cliente deve atualizar seu gerador. Tokens FCM continuam destinos opacos e não são convertidos em UUID.
- Core fornece validação pura de UUIDv7 e identidade autenticada canônica; IDs próprios de correlação HTTP passam a UUIDv7. Laravel/SDKs conservam seus identificadores internos nativos.
- Core mantém um registro transversal mínimo de associações `(owner, namespace, identidade lógica) → UUIDv7`, sem resultados financeiros, descrições ou conteúdo editorial. UUIDs são emitidos pelo gerador padrão, não por transformação de hash.
- Insights, Metrics e sugestões usam o registro em lote, preservando IDs após alterações de valores/textos, visitas e reinícios. Leituras financeiras permanecem sob demanda; somente a associação de identidade pode ser persistida.
- **BREAKING:** cursores de despesas passam a uma versão UUIDv7, com desempate UUID consistente com PostgreSQL; cursores numéricos antigos são rejeitados. Cache/filas de aplicação incompatíveis são invalidados de forma exclusiva, sem limpeza global de serviços.
- Schema local poderá ser recriado com `lerd artisan migrate:fresh`, exclusivamente no banco local de desenvolvimento confirmado no apply. Bancos de teste continuam pelo launcher, com preflight/ownership e migrations incrementais, sem `migrate:fresh`.
- Specs, arquitetura, API, Bruno, fixtures e provas passam a representar UUIDv7 e a nova exceção de persistência de identidade das projeções.

## Capabilities

### New Capabilities

- `uuid-v7-identifiers`: política transversal, escopo/exclusões, geração, validação, schema, contratos/rotas, instalação, correlação e transição local sem legado.
- `stable-resource-identities`: registro de Core, associação mínima e estável, isolamento, resolução em lote, concorrência, retenção e falhas explícitas.

### Modified Capabilities

- `user`: identidade local, persistência e CRUD com UUIDv7 e ownership canônico.
- `identity-context`: conceitos puros de Core e fronteiras dos contratos de identificação UUIDv7.
- `authentication`: User/PAT UUIDv7, associação polimórfica, Bearer, respostas e verificação de e-mail sem regressão de sessão.
- `expense`: PK/owner UUIDv7, rotas, paginação e contratos de classificação/cache.
- `expense-querying`: desempate UUID e paginação que não depende de ID inteiro.
- `expense-suggestions`: UUIDv7 estável por owner/chave normalizada, com somente associação auxiliar persistida.
- `expense-metrics`: UUIDv7 estável por owner/período/modo, sem congelar fatos.
- `insights`: UUIDv7 estável por owner/tipo/assunto/estado/períodos, preservando rotação e onboarding.
- `structured-observability`: correlação própria UUIDv7 e IDs de negócio canônicos, sem expor segredos ou chaves internas do registro.

Notifications é coberto pela política transversal e pela coordenação com a change ativa `add-firebase-push-notifications`; esta proposta não duplica nem implementa a fatia pendente de envio Firebase.

## Impact

- Todos os contextos existentes: Core, Identity, Expense, Notifications, Insights e Metrics; composição raiz e migrations.
- Novo estado técnico mínimo em Core e permissão arquitetural específica para consumir sua capacidade de identidade; sem imports de Infrastructure/Models entre contextos.
- Customização suportada do Model de PAT do Sanctum, tipos UUID de owner/sessão, URLs assinadas, jobs próprios que referenciam entidades e chaves/cursors/cache.
- Clientes precisam tratar todos os IDs de recurso como strings UUIDv7, atualizar instalação e descartar tokens, links e cursores antigos. Enum de categorias, moeda, datas, contagens e formatos de segredos permanecem próprios de seus conceitos.
- Nenhuma nova dependência prevista: PHP 8.5, Laravel 13.34.0, Sanctum 4.3.3 e PostgreSQL; `HasUuids` já gera UUIDv7 e Sanctum permite Model de PAT próprio. APIs instaladas serão reconferidas no apply.
- Aplicação futura exige autorização específica. Este pedido autoriza **somente escrever/validar a spec**, sem implementar, executar testes da aplicação, recriar banco, emitir tokens, alterar workers ou publicar código.

## Decisões confirmadas

1. A resposta final à pergunta repetida foi **“Manter IDs estáveis”**; substitui a escolha anterior de UUID novo por resposta.
2. Escopo **“Projeto e API”**, preservando contratos internos de dependências, inclusive PKs técnicas de jobs/failed_jobs/migrations.
3. Instalação: **“Exigir UUIDv7”**.
4. Banco local: **“Recriar banco local”**, autorizado para a implementação futura; não autoriza destruição fora desse ambiente nem muda o lifecycle seguro de testes.
5. Associação estável: **“Registro transversal no Core”**.
