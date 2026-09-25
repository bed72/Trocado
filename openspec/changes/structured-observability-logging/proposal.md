## Why

Os logs técnicos existentes não oferecem um contrato uniforme para acompanhar operações importantes da aplicação em formato estruturado e correlacionável. Precisamos permitir que UseCases emitam sinais de observabilidade sem importar Laravel/Monolog nem transformar todos os diagnósticos técnicos em uma abstração genérica.

## What Changes

- Introduzir uma capacidade transversal de observabilidade para eventos nomeados emitidos pela Application, com atributos estruturados e um Adapter em Infrastructure.
- Configurar saída JSON estruturada com nível, timestamp, nome do evento e identificador de correlação quando houver requisição.
- Instrumentar a criação confirmada de Expense como primeiro evento (`expense.created`), sem alterar o resultado da operação quando a emissão falhar.
- Preservar logs técnicos diretamente nas bordas Laravel; impedir que dados sensíveis ou descrição da despesa sejam incluídos no novo evento.

## Capabilities

### New Capabilities

- `structured-observability`: emissão e formatação de eventos estruturados, correlação por requisição, limites de responsabilidade e tratamento de falhas.

### Modified Capabilities

Nenhuma. A criação de Expense mantém seu contrato funcional e HTTP; a observabilidade é uma capacidade transversal adicional.

## Impact

`Core` Application/Infrastructure para Port, Adapter e binding; `Expense` Application para a emissão inicial; configuração de logging e borda HTTP para JSON e correlação. Sem mudança no contrato HTTP de Expense, migration ou nova dependência Composer.
