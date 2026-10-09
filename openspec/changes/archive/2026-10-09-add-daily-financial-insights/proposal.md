## Why

O Trocado registra despesas, mas ainda não transforma esses registros em observações textuais úteis sobre concentração e mudanças de comportamento. Insights oferecerá uma pequena lista de mensagens honestas, curtas e com personalidade, sem exigir dashboards ou serviços externos de geração de texto.

## What Changes

- Introduzir o bounded context dedicado `Insights`, dono das análises, elegibilidade, seleção e composição de mensagens.
- Permitir leitura direta dos dados de despesas pela Infrastructure de Insights no banco compartilhado, sem consumir código, Models, Repositories, UseCases ou endpoints de Expense e sem escrever em suas tabelas.
- Disponibilizar `GET /api/insights` autenticado, com até seis recursos JSON:API, sem quantidade mínima ou paginação.
- Separar mensagens por `group` e `type`, para o Flutter definir ícones e cores sem conhecer as regras de análise.
- Calcular fatos sobre despesas registradas e aplicar regras determinísticas para observações, comparações e onboarding; evitar inferências de economia, orçamento ou completude dos registros.
- Usar um catálogo editorial com textos completos, título de até 32 caracteres e descrição de até 110 caracteres, com variantes estáveis durante o dia e rotação diária por conta e observação.
- Gerar sob demanda, sem IA em runtime, persistência de insights, histórico de visualização ou cache específico no MVP.
- Implementar o conjunto inicial de regras e critérios de evidência aprovado no design, com o catálogo editorial apresentado e adotado como base inicial após a reiteração do pedido de implementação.

## Capabilities

### New Capabilities

- `insights`: consulta de insights pessoais, análise determinística de despesas, seleção sem redundância, onboarding, catálogo curto com rotação diária e contrato JSON:API por grupo e tipo.

### Modified Capabilities

Nenhuma. Expense permanece dono das escritas e não ganha operações analíticas ou responsabilidades de integração com Insights.

## Impact

Novo contexto `app/Insights/{Domain,Application,Infrastructure,Presentation}`, composição de rota e provider, futura atualização de `ARCHITECTURE.md` e das verificações arquiteturais para reconhecer o contexto e sua dependência de leitura do schema de despesas. PostgreSQL fornece agregações por proprietário e período; não há migration, nova dependência Composer, integração externa ou alteração do CRUD de Expense prevista. O consumidor Flutter recebe `group`, `type`, título, descrição e período, sem cores ou ícones definidos pelo backend.

Fora de escopo: análises familiares, renda, orçamento, projeções, gráficos, dashboards, relatórios complexos, notificações, Open Finance, filas para Insights, administração de catálogo e mensagens genéricas de configurações da conta. O backend foi implementado e verificado; as evidências e a pendência externa de revisão visual no Flutter estão registradas em `tasks.md`. O usuário solicitou o arquivamento de todas as specs abertas após essa pendência ser informada.
