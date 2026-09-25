## Context

O projeto mantém Domain e Application independentes do Laravel, enquanto Infrastructure e Presentation podem usar suas APIs. Hoje o logging usa canais Laravel/Monolog e há diagnóstico técnico direto em Expense Infrastructure. Laravel 13 e Monolog já estão instalados; a configuração de canais oferece formatter, e o Laravel permite compartilhar contexto entre canais. A observabilidade deve complementar, e não substituir, os logs técnicos.

## Goals / Non-Goals

**Goals:** emitir eventos úteis de UseCases com contrato independente do framework; produzir uma linha JSON por registro em um canal configurável; correlacionar registros de uma mesma requisição; evitar dados sensíveis; manter a operação de negócio independente da disponibilidade do destino de logs.

**Non-Goals:** obrigar todo log a passar pelo Port; implementar trilha de auditoria durável, métricas, traces distribuídos ou infraestrutura externa de coleta; registrar payloads HTTP completos ou descrições de despesas; instrumentar todos os UseCases nesta mudança.

## Decisions

1. **Capacidade transversal, não espelho de PSR-3.** `Core\Application\Ports\ObservabilityPort` oferece emissão de evento nomeado com atributos escalares explícitos. `Core\Infrastructure\Adapters\Observability\ObservabilityAdapter` implementa o contrato via canal Laravel configurado, com binding no provider de Core. O Port não expõe níveis, handlers, canais, exceções ou objetos de Laravel; esses detalhes pertencem ao Adapter e à configuração. A Application de Expense depende do Port de Core, como já faz com a capacidade de transações. Alternativa descartada: interface genérica com `debug/info/warning/error` obrigatória em todas as camadas, que apenas duplicaria o logger.
2. **Primeiro produtor e semântica de confirmação.** `CreateExpenseUseCase` emite `expense.created` com `expense_id` e `user_id` após confirmação da persistência, uma vez por criação bem-sucedida. Se a operação reverter ou for rejeitada, não emite o evento. Não executar envio não transacional dentro de callback que possa sofrer retry; caso haja transação externa, deferir até seu commit efetivo e descartar no rollback. O registro é best-effort: falha do destino não altera a criação nem a resposta HTTP. Alternativas descartadas: emitir antes do commit ou tornar o sucesso do log pré-condição da criação.
3. **Estrutura e privacidade.** O canal produz JSON em linha única com timestamp, level, event, atributos explicitamente passados e `request_id` quando a execução vier de HTTP. O primeiro evento usa IDs e não inclui descrição, valor, token, credenciais ou o corpo da requisição. Dados de correlação vêm da borda HTTP, não são passados pelo UseCase. Os eventos usam nomes estáveis; não montar mensagem com interpolação de atributos para que campos continuem pesquisáveis. Alternativa descartada: texto livre como único registro ou serialização automática de entidades/payloads inteiros.
4. **Correlação na borda.** Um identificador gerado pelo servidor é atribuído por requisição e incluído no contexto do logger e no cabeçalho de resposta `X-Request-Id`. Atribuição/limpeza do contexto respeita o ciclo de vida da requisição, inclusive em workers persistentes, para não correlacionar requisições diferentes. Execuções sem contexto HTTP continuam emitindo registros válidos sem `request_id`. Alternativa descartada: tornar `request_id` argumento obrigatório de cada UseCase.
5. **Logs técnicos continuam nas bordas.** Infrastructure e Presentation podem registrar falhas operacionais diretamente com Laravel no canal apropriado; o Port serve para eventos que o UseCase deliberadamente declara. A correlação da requisição pode ser compartilhada com os canais técnicos. Alternativa descartada: reescrever logs existentes sem necessidade funcional.

## Risks / Trade-offs

- [Evento duplicado ou correspondente a transação revertida] → emissão vinculada ao commit efetivo, fora de callbacks sujeitos a retry; verificar rollback e caminho de sucesso.
- [Falha de logging afeta resposta ou cria recursão ao relatar a própria falha] → captura delimitada no Adapter, sem relogar a mesma falha pelo próprio Port; verificar que o fluxo de criação permanece bem-sucedido.
- [Vazamento de dados e contexto entre requisições] → atributos explícitos sem payloads brutos; correlação gerada/limpa por execução e verificação com requisições consecutivas.
- [Logs não são armazenamento transacional nem entrega garantida] → documentar best-effort; se futuramente houver auditoria obrigatória, especificar persistência própria.

## Migration Plan

Adicionar canal e binding antes de instrumentar o UseCase. Ajustar a configuração efetiva de logs para o novo canal sem perder a coleta dos logs técnicos; validar JSON e correlação no destino configurado. Rollback: desabilitar o emissor de eventos e retornar à configuração anterior, sem migração de dados.

## Open Questions

Nenhuma bloqueante. O destino operacional final (arquivo ou stderr/coletor) permanece configurável sem mudar o contrato do Port.
