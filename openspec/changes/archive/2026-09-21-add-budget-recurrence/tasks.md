## 1. Domínio da recorrência

- [ ] 1.1 Criar testes unitários para duração inclusiva, intervalo de um dia, travessia de mês, ano bissexto, próximo intervalo e datas inválidas.
- [ ] 1.2 Implementar `BudgetRecurrenceEntity`, `RecurrenceStatus` e exceções de domínio sem dependências de Laravel.
- [ ] 1.3 Criar testes unitários para as transições `Active -> Blocked`, `Blocked -> Active`, `Active|Blocked -> Ended` e para transições inválidas a partir de `Ended`.
- [ ] 1.4 Adicionar `recurrenceId` opcional ao `BudgetEntity` e ajustar seus testes sem alterar as invariantes existentes.

## 2. Persistência e atomicidade

- [ ] 2.1 Criar migrations para `budget_recurrences`, para `budgets.recurrence_id`, para a chave estrangeira e para a unicidade de `(recurrence_id, start_date)`.
- [ ] 2.2 Definir os contratos mínimos de recorrência, consulta de conflitos e transação/coordenação de escrita na Application, sem expor Eloquent, Builder, facades ou Models.
- [ ] 2.3 Implementar `BudgetRecurrenceModel` e os mappings de recorrência e associação de Budget nos repositories de Infrastructure.
- [ ] 2.4 Implementar busca de recorrências ativas devidas e bloqueio exclusivo da recorrência durante o processamento.
- [ ] 2.5 Centralizar a detecção atômica de sobreposição em todas as gravações de Budget, excluindo o próprio registro em atualizações.
- [ ] 2.6 Implementar a unidade atômica que cria uma ocorrência e avança `nextStartDate`, com rollback conjunto em falhas.
- [ ] 2.7 Criar testes de integração para migrations, mappings, consultas devidas, intervalo adjacente, todas as formas de sobreposição e atualização que exclui o próprio Budget.
- [ ] 2.8 Criar testes de integração para unicidade, rollback, reexecução e duas tentativas concorrentes sobre a mesma ocorrência.

## 3. Casos de uso

- [ ] 3.1 Estender `CreateBudgetUseCase` para aceitar `recurring`, criar Budget simples por padrão e criar atomicamente o primeiro Budget e sua recorrência quando habilitado.
- [ ] 3.2 Atualizar `CreateBudgetUseCase` e `UpdateBudgetUseCase` para rejeitar sobreposição e criar testes unitários para sucesso, conflito e ausência de persistência parcial.
- [ ] 3.3 Implementar o caso de uso de geração com data explícita, cobrindo nenhuma ocorrência devida, uma ocorrência, limite no dia anterior e uso do template vigente.
- [ ] 3.4 Implementar o loop de catch-up em ordem cronológica e criar testes para múltiplos períodos, falha intermediária e continuação posterior.
- [ ] 3.5 Implementar bloqueio por conflito sem avanço do cursor e testar que recorrências `Blocked` e `Ended` são ignoradas pelo processamento.
- [ ] 3.6 Implementar consulta e alteração do template futuro, com testes que provem que amount, datas e duração de Budgets existentes não mudam.
- [ ] 3.7 Implementar encerramento irreversível de recorrências ativas e bloqueadas, com testes de preservação dos Budgets e rejeição de retomada.
- [ ] 3.8 Implementar retomada explícita de recorrência bloqueada, validando novamente o intervalo pendente e testando conflito persistente e retomada bem-sucedida.
- [ ] 3.9 Ajustar atualização e exclusão de ocorrências e testar que essas operações não alteram template, cursor ou estado da recorrência e não recriam uma ocorrência excluída.

## 4. API JSON:API

- [ ] 4.1 Consultar a documentação Laravel 13 do `JsonApiResource` first-party e definir rotas e códigos de erro consistentes com a API existente.
- [ ] 4.2 Estender o request de criação para validar `recurring` como booleano opcional estrito e rejeitar atributos desconhecidos.
- [ ] 4.3 Expor o relacionamento opcional de recorrência na resposta de Budget e criar o `BudgetRecurrenceResponse` para estado, amount, duração e próxima data inicial.
- [ ] 4.4 Criar Form Requests e controllers finos para consultar, alterar, encerrar e retomar recorrências, cada um delegando a um UseCase.
- [ ] 4.5 Mapear recorrência inexistente, sobreposição e transição inválida para erros HTTP/JSON:API sem vazamento de detalhes de Infrastructure.
- [ ] 4.6 Criar testes Feature para criação com `recurring` omitido, falso, verdadeiro e inválido, incluindo atomicidade e relacionamento na resposta.
- [ ] 4.7 Criar testes Feature para consulta, alteração futura, encerramento e retomada de recorrência.
- [ ] 4.8 Criar testes Feature para sobreposição na criação e atualização, conflito ao retomar e respostas de transições inválidas.

## 5. Processamento agendado

- [ ] 5.1 Criar um comando/adaptador que obtenha a data no timezone da aplicação e invoque sincronamente o caso de uso de geração.
- [ ] 5.2 Registrar o comando no Laravel Scheduler com execução diária e proteção operacional contra sobreposição, sem usar filas como garantia de correção.
- [ ] 5.3 Criar testes para registro da frequência diária, encaminhamento da data correta, ausência de dispatch para fila e reexecução segura do comando.

## 6. Verificação completa

- [ ] 6.1 Manter uma matriz de rastreabilidade durante a implementação e confirmar que cada cenário de `specs/budget-recurrence/spec.md` possui ao menos um teste automatizado correspondente.
- [ ] 6.2 Executar separadamente os testes de Domain, Application, persistência, HTTP e scheduler e corrigir todas as falhas.
- [ ] 6.3 Executar a suíte completa existente de Budget para confirmar ausência de regressões no CRUD.
- [ ] 6.4 Executar a suíte completa do projeto com relatório de cobertura e confirmar cobertura integral das novas regras, ramificações e tratamentos de erro do mecanismo.
- [ ] 6.5 Executar `vendor/bin/pint --dirty --format agent` e repetir os testes afetados após a formatação.
