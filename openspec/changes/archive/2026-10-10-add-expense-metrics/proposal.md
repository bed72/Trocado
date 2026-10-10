## Why

O front precisa de dados quantitativos confiáveis para construir cards e gráficos customizáveis de despesas por período, sem carregar e somar páginas do CRUD nem depender das mensagens interpretativas de Insights. Um contexto `Metrics` separa a consulta de fatos financeiros da interpretação desses fatos e oferece um contrato único para o total geral e sua distribuição por categoria.

## What Changes

- Introduzir o bounded context `Metrics`, dono das métricas quantitativas, com leitura agregada de despesas e sem dependência de código de Expense, Identity ou Insights.
- Disponibilizar uma rota `GET /api/metrics/expenses` com dois modos: total geral sem `group_by`; total geral e distribuição por categoria com `group_by=category`.
- Filtrar exclusivamente por `occurred_on` e pela conta autenticada, com limites inclusivos. Sem datas, consultar o mês corrente inteiro no timezone configurado da aplicação, incluindo datas futuras já registradas.
- Exigir `start_date` e `end_date` juntas quando informadas, em formato civil estrito `YYYY-MM-DD`; aceitar dia único, intervalos futuros e intervalos sem limite arbitrário de duração.
- Rejeitar com `422` filtros vazios, datas inválidas ou invertidas, agrupamentos não suportados, parâmetros desconhecidos, estruturas não escalares e parâmetros repetidos, mesmo com valores iguais. Remover somente espaços externos dos valores antes da validação.
- Retornar valores monetários exatos em strings inteiras de centavos; BRL é implícito e não existe campo `currency`.
- Na consulta agrupada, incluir somente categorias com despesas, com identificadores atuais de Expense, total e percentual em string com duas casas decimais e half-up; ordenar por total decrescente e identificador alfabético no desempate.
- Garantir que total e categorias representam o mesmo snapshot, sem cache de métricas nem reutilização do cache de páginas de Expense.
- Responder em JSON:API com um único recurso `expense-metrics`, ID opaco determinístico por conta/período/agrupamento, período efetivo e total; omitir `categories` quando o agrupamento não for solicitado.
- Retornar `200` com total `"0"` para um período válido sem despesas; retornar `categories: []` somente no modo agrupado.
- Seguir as proteções existentes das rotas analíticas autenticadas e o padrão de erros de query de Insights: `title: "Parâmetro inválido"`, `detail`, `status: "422"`, `source.parameter` e media type JSON:API.

## Capabilities

### New Capabilities

- `expense-metrics`: consulta pessoal de métricas de despesas por intervalo civil, total geral, distribuição por categoria, percentuais exatos, validação estrita, consistência de snapshot e contrato JSON:API para o front.

### Modified Capabilities

Nenhuma. Os contratos existentes de Expense e Insights permanecem com suas responsabilidades próprias. Metrics herda as políticas transversais existentes sem modificar suas regras, cotas ou mecanismos.

## Impact

- **API:** adição de `GET /api/metrics/expenses`; as duas URLs discutidas são variações da mesma rota, não endpoints implementados separadamente. Não há breaking change de endpoints existentes.
- **Arquitetura:** novo contexto em `app/Metrics/`, com Port de leitura analítica, Adapter PostgreSQL, UseCase concreto, Data próprios e borda HTTP. Core continua sendo dono do acesso à identidade autenticada via `UserPort`.
- **Integração de dados:** leitura somente de `expenses.user_id`, `expenses.occurred_on`, `expenses.amount` e `expenses.category`; Expense permanece dono das escritas e das invariantes dos registros.
- **Precisão:** nenhum cast de totais para inteiro nativo ou float; calcular percentuais com aritmética exata e arredondar apenas a representação final.
- **Composition roots:** registro futuro de provider, rota e reconhecimento de Metrics nas verificações arquiteturais e documentação. Nenhuma alteração dessas implementações é autorizada pela criação dos artefatos.
- **Persistência e operação:** não são previstos tabela, migration, backfill, serviço, fila, job, chamada externa, cache específico ou dependência nova.
- **Front:** escolhe biblioteca, tipo de gráfico, cores, ícones, rótulos traduzidos e formatação em reais; recebe valores e percentuais prontos sem requisito de implementação de UI nesta mudança.
- **Escopo:** esta solicitação autoriza somente os artefatos OpenSpec e sua validação. Apply, código da aplicação e criação de testes exigem autorização posterior.
