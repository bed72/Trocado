## Why

Budgets precisam poder continuar por períodos consecutivos sem criação manual, preservando a associação determinística de despesas por data. A recorrência também precisa permanecer correta diante de reexecuções, concorrência, indisponibilidade temporária e conflitos com outros Budgets.

## What Changes

- Introduzir uma regra de recorrência própria do bounded context `Budget`, separada das ocorrências de Budget que ela gera.
- Repetir a quantidade inclusiva de dias do intervalo original, sem frequências predefinidas ou semântica implícita de mês calendário.
- Gerar somente ocorrências devidas até a data corrente e recuperar automaticamente períodos não processados durante indisponibilidades.
- Permitir alterar o template de ocorrências futuras sem modificar Budgets já criados.
- Permitir encerrar definitivamente uma recorrência, preservando as ocorrências existentes e sem backfill posterior.
- Bloquear a recorrência quando a próxima ocorrência se sobrepuser a outro Budget, exigindo resolução explícita antes da retomada.
- Impedir sobreposição de datas em todas as formas de criação e atualização de Budget, recorrentes ou manuais.
- Garantir idempotência por transação, serialização do processamento e restrição única da ocorrência.
- Adicionar cobertura automatizada completa das regras de domínio, casos de uso, persistência, processamento agendado e API afetada.

## Capabilities

### New Capabilities

- `budget-recurrence`: Define criação, cálculo, geração, alteração, encerramento, bloqueio, recuperação e idempotência de recorrências de Budget, incluindo a regra global de não sobreposição.

### Modified Capabilities

Nenhuma capability existente.

## Impact

- O bounded context `Budget` receberá novos elementos em Domain, Application, Infrastructure e Presentation, preservando as dependências definidas em `ARCHITECTURE.md`.
- A persistência receberá a regra de recorrência, a associação opcional das ocorrências e restrições de integridade e idempotência.
- Os fluxos existentes de criação e atualização de Budget passarão a rejeitar intervalos sobrepostos.
- A API de Budget será ampliada para iniciar, consultar, alterar, encerrar e retomar recorrências bloqueadas.
- O Laravel Scheduler executará um adaptador que invoca o caso de uso de geração; filas não fazem parte deste escopo inicial.
- Não haverá novo bounded context compartilhado nem abstração genérica para outros domínios.
