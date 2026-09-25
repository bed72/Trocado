## 1. Contrato e canal

- [x] 1.1 Definir `ObservabilityPort` em Core Application e `ObservabilityAdapter` em Core Infrastructure, com binding no provider; manter detalhes do logger fora da Application.
- [x] 1.2 Configurar canal Laravel para emitir eventos em JSON de linha única com timestamp, level, event e atributos nomeados, usando apenas dependências já instaladas.

## 2. Correlação e primeiro evento

- [x] 2.1 Gerar e propagar `request_id` por requisição HTTP até os canais de log, devolver `X-Request-Id` e impedir vazamento de contexto entre requisições do mesmo processo.
- [x] 2.2 Emitir `expense.created` após commit efetivo, uma vez por criação confirmada, com somente `expense_id` e `user_id`; não emitir em rollback ou rejeição.
- [x] 2.3 Tratar falhas do destino no Adapter sem afetar a criação, sem recursão no logging e sem esconder falhas da operação de negócio.

## 3. Verificação

- [x] 3.1 Verificar formato JSON e campos consultáveis, correlação HTTP e isolamento entre requisições, além de execução sem HTTP.
- [x] 3.2 Verificar evento único após confirmação, ausência de evento em rollback/rejeição, exclusão de dados sensíveis e sucesso da criação quando o destino de logs falha.
- [x] 3.3 Verificar limites arquiteturais, configuração/binding, logs técnicos existentes e executar as checagens adequadas e Pint após a implementação.
