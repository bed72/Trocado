# Checklist de Validação do Prompt Estruturado

Use este checklist para validar o prompt gerado antes de entregar ao usuário.

## Blocos obrigatórios

- [ ] `<task>` presente e conciso (uma linha)
- [ ] `<goals>` presente (uma frase de foco)
- [ ] `<role>` define o agente (Flutter senior), stack (Flutter, Dart, Riverpod, Clean Architecture) e contexto da tarefa
- [ ] `<requirements>` separados em **Business**, **Technical** e **UI/UX** (todas as três subcategorias)
- [ ] `<critical>` inclui **Skills obrigatórias** e **Fora do Escopo** (ambas as subcategorias)
- [ ] `<critical> ### Skills obrigatórias` contém `/sdd` como obrigatória

## Blocos opcionais (verificar se foram incluídos quando necessário)

- [ ] `<context-tools>` incluído quando há skills do projeto ou MCPs aplicáveis à tarefa
- [ ] `<workflow>` incluído quando a tarefa tem múltiplas etapas com dependências
- [ ] `<output>` incluído quando o formato ou estrutura de saída for relevante
- [ ] `<endpoints>` incluído quando há integração com APIs HTTP externas
- [ ] `<tests>` incluído quando há lógica testável (Notifier, validators, repository ou response fromJson)

## Qualidade

- [ ] Requisitos explícitos — nada implícito ou vago (ex.: "exiba os dados" → "lista com loading, estado vazio e tratamento de erro")
- [ ] `<requirements> ### Technical` menciona as camadas afetadas (domain, data, infrastructure, presentation, main)
- [ ] `<requirements> ### Technical` menciona o fluxo: Notifier → Repository → DataSource → Client (Dio)
- [ ] `<requirements> ### UI/UX` inclui estados da tela: loading, erro, vazio e sucesso quando aplicável
- [ ] `<critical> ### Fora do Escopo` usa *NÃO* ou *NUNCA* para ênfase
- [ ] `<context-tools>` lista skills específicas para a tarefa (não skills genéricas não aplicáveis)
- [ ] Delimitador `---` entre blocos longos (5+ linhas)
- [ ] `<endpoints>` inclui método HTTP, URL e status codes esperados quando presente
- [ ] `<tests>` referencia as estratégias de mock do projeto (mock em IHttpClient para repositório, mock em IXxxRepository para Notifier) quando pertinente

## Pós-entrega

- [ ] Instrução ao usuário para executar `/sdd` adicionada ao final da resposta
