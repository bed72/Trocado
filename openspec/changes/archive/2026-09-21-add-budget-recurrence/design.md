## Context

O bounded context `Budget` possui hoje uma entidade com `amount`, `startDate` e `endDate`, persistida por `BudgetRepository`. Os intervalos são fechados e ainda não existe proteção contra sobreposição. Expenses não referenciam um Budget diretamente; a associação é derivada pela data, portanto dois Budgets cobrindo o mesmo dia produziriam ambiguidade.

A recorrência deve gerar Budgets independentes, recuperar períodos perdidos e permanecer idempotente sob reexecução ou concorrência. A arquitetura do projeto exige Domain puro, Application sem Laravel, Infrastructure responsável por persistência e agendamento e Presentation responsável por HTTP.

## Goals / Non-Goals

**Goals:**

- Representar explicitamente a série recorrente e seu ciclo de vida.
- Repetir qualquer intervalo fechado por sua quantidade inclusiva de dias.
- Manter criação, atualização e geração livres de sobreposição.
- Tornar geração, catch-up e retomada idempotentes e atomicamente persistidas.
- Cobrir todos os comportamentos e falhas relevantes com testes automatizados.
- Manter o desenho extraível no futuro sem criar agora um domínio genérico.

**Non-Goals:**

- Criar um bounded context compartilhado de recorrência.
- Suportar frequências semanais, mensais ou regras de calendário.
- Implementar recorrência de Expense ou de qualquer outro contexto.
- Usar filas, gerar ocorrências futuras antecipadamente ou permitir reativar recorrências encerradas.
- Anexar, nesta primeira versão, uma nova recorrência a um Budget preexistente; a recorrência nasce atomicamente com seu primeiro Budget.
- Alterar automaticamente Budgets já criados quando o template da recorrência mudar.

## Decisions

### Recorrência é uma entidade de Budget

Será criada uma `BudgetRecurrenceEntity` dentro de `app/Budget`, em vez de adicionar um booleano persistido ao `BudgetEntity` ou criar uma entidade genérica compartilhada.

A entidade manterá:

- identidade opcional durante a criação;
- `RecurrenceStatus` com `Active`, `Blocked` e `Ended`;
- `MoneyValueObject` para o amount futuro;
- `durationInDays` positivo;
- `nextStartDate` como data de calendário;
- timestamps de persistência e, quando úteis para auditoria, `blockedAt` e `endedAt`.

O `BudgetEntity` receberá `recurrenceId` opcional. Todos os Budgets da série, inclusive o inicial, usarão o mesmo identificador.

Alternativa rejeitada: fazer cada Budget apontar apenas para o anterior e carregar um booleano `recurring`. Isso torna ambíguos o proprietário da série, o template vigente, o encerramento, o bloqueio e o cursor de catch-up.

### O template pertence à recorrência

O amount será armazenado tanto na recorrência quanto em cada Budget. O valor da recorrência representa o template futuro; o valor do Budget representa o fato histórico daquela ocorrência.

Não haverá clonagem genérica de Budget. Quando novos atributos surgirem, sua participação no template deverá ser decidida explicitamente.

### Intervalo fixo em dias de calendário

`durationInDays` será calculado como diferença entre as datas mais um. O próximo intervalo será calculado a partir de `nextStartDate`; seu término será `nextStartDate + durationInDays - 1`, e o novo cursor será o dia seguinte ao término.

Datas continuarão representadas como datas de calendário, sem hora. O domínio usará tipos PHP imutáveis apenas para cálculo e retornará o formato canônico `Y-m-d`, sem Carbon ou outras dependências do framework.

Alternativa rejeitada: detectar que um intervalo representa um mês. Essa heurística seria ambígua e contrariaria a decisão de usar exclusivamente o range original.

### Estados e transições

As transições válidas serão:

- `Active -> Blocked`, quando a ocorrência pendente conflitar;
- `Blocked -> Active`, por retomada explícita depois da resolução;
- `Active -> Ended` e `Blocked -> Ended`, por encerramento explícito.

`Ended` é terminal. Uma nova sequência exige uma nova criação de Budget recorrente. A retomada de `Blocked` preserva `nextStartDate`, para que o período pendente não seja silenciosamente ignorado.

### Alterações têm alvos explícitos

Os UseCases existentes de atualização e exclusão de Budget continuarão operando somente sobre a ocorrência. UseCases próprios alterarão o template, encerrarão ou retomarão a recorrência.

Mudar `durationInDays` não reposicionará `nextStartDate`. Isso mantém continuidade com tudo que já foi materializado e faz a nova duração valer apenas para o próximo intervalo ainda não criado.

### Persistência e integridade

Uma tabela `budget_recurrences` armazenará status, amount, duração, cursor e timestamps. `budgets` receberá uma chave estrangeira `recurrence_id` anulável. A combinação `(recurrence_id, start_date)` será única como última barreira contra duplicação; múltiplos Budgets não recorrentes continuam possíveis porque `recurrence_id` é nulo.

A regra de não sobreposição será centralizada na fronteira de persistência usada por todos os fluxos de escrita. A consulta de conflito usará:

```text
existing.start_date <= candidate.end_date
AND existing.end_date >= candidate.start_date
```

Atualizações excluirão o próprio Budget dessa consulta. A checagem e a gravação serão serializadas por uma coordenação de escrita implementada em Infrastructure e executadas em transação. Domain e Application não importarão facades, Eloquent, cache ou locks do Laravel.

A criação de uma ocorrência e o avanço da recorrência compartilharão a mesma transação. O processamento obterá exclusividade para a recorrência e repetirá a leitura do estado e do cursor dentro da unidade atômica. A restrição única será uma proteção adicional, não o mecanismo principal.

Alternativa rejeitada: depender apenas de `withoutOverlapping()` do Scheduler. Esse lock protege a tarefa agendada, mas não protege outros processos, reexecuções manuais nem gravações concorrentes da API.

### Processamento e catch-up

Um UseCase da Application receberá uma data explícita e buscará recorrências ativas com `nextStartDate <= processingDate`. Para cada uma, processará intervalos em ordem até o cursor ultrapassar a data informada ou a recorrência ficar bloqueada.

Um comando/adaptador agendado diariamente no Laravel chamará esse UseCase com a data no timezone configurado da aplicação. O processamento será síncrono nesta versão. Um limite operacional de lote só deverá ser introduzido se métricas reais demonstrarem necessidade; ele não pode quebrar a retomada pelo cursor.

### API

A criação de Budget aceitará o atributo opcional `recurring`, com padrão `false`. A resposta de Budget identificará sua recorrência por relacionamento JSON:API quando houver associação.

A recorrência será exposta como recurso próprio para consulta e alteração do template. Encerramento e retomada bloqueada serão ações explícitas, mapeadas para UseCases distintos. A definição final das rotas seguirá o padrão atual de controllers por ação e recursos JSON:API first-party.

Erros de intervalo, sobreposição, recorrência inexistente e transição inválida serão traduzidos no limite HTTP, preservando as exceções puras de Domain/Application.

### Estratégia de testes

Cada cenário da spec terá ao menos um teste automatizado no nível mais baixo que prove o comportamento sem duplicação desnecessária.

- Testes unitários de Domain cobrirão duração inclusiva, intervalo de um dia, transição de mês e ano bissexto, cálculo seguinte, invariantes e todas as transições de estado válidas e inválidas.
- Testes unitários de Application cobrirão criação atômica, geração não devida, uma ocorrência, catch-up múltiplo, falhas, bloqueio, retomada, encerramento, alteração futura e isolamento de edições de ocorrência.
- Testes de integração de persistência cobrirão mappings, consultas devidas, detecção de sobreposição, exclusão do próprio registro, restrição única, rollback e serialização/idempotência concorrente.
- Testes de Feature HTTP cobrirão payload opcional e inválido, respostas e relacionamento JSON:API, consulta/alteração/encerramento/retomada e mapeamento dos erros de domínio.
- Testes do adaptador agendado cobrirão registro diário, timezone/data encaminhada e invocação do UseCase sem fila.
- A suíte existente de Budget será executada integralmente para detectar regressões no CRUD.

## Risks / Trade-offs

- [Serializar todas as escritas de Budget pode reduzir throughput] -> O contexto atual é uma POC e privilegia correção; otimizações serão orientadas por medição.
- [Uma longa indisponibilidade pode gerar muitas ocorrências em uma execução] -> O cursor permite processamento incremental seguro; um lote limitado pode ser adicionado sem mudar o domínio.
- [Uma recorrência bloqueada exige ação humana] -> O estado e o intervalo pendente serão expostos pela API, evitando repetição silenciosa de falhas.
- [Excluir uma ocorrência cria uma lacuna histórica] -> A exclusão é uma ação explícita e não retrocede o cursor, impedindo recriação surpreendente.
- [A restrição única não impede sobreposições arbitrárias] -> Toda escrita passará pela mesma coordenação atômica e pela consulta de conflito.

## Migration Plan

1. Criar `budget_recurrences` e adicionar `budgets.recurrence_id` anulável com índice e chave estrangeira.
2. Adicionar a restrição única de ocorrência sem alterar os Budgets existentes, que permanecerão com associação nula.
3. Implantar Domain, Application e Infrastructure antes de habilitar as novas rotas e o agendamento.
4. Validar a suíte completa e executar a migração antes de ativar o Scheduler.
5. Em rollback, desativar primeiro o agendamento e as novas rotas; a reversão destrutiva das tabelas só poderá ocorrer depois de confirmar que os dados recorrentes não precisam ser preservados.

## Open Questions

Nenhuma decisão de domínio permanece aberta para esta primeira versão. Nomes exatos de rotas e códigos de erro serão definidos durante a implementação conforme as convenções JSON:API já adotadas, sem alterar os comportamentos desta spec.
