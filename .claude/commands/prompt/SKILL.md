---
name: prompt
description: Transforms vague or poorly structured prompts into structured prompts using XML and Markdown. Applies techniques: goals, workflow (Chain-of-Thought), output format, few-shot patterns, delimiters. Produces prompts with task, goals, role, requirements (business, technical, UI/UX), workflow, output, endpoints, tests, context-tools, and critical constraints. Tailored for Flutter/Dart projects with Clean Architecture. Do not use for prompts that are already well-structured or for general documentation.
---

# Prompt Enhancement

Transforma prompts vagos ou mal estruturados em prompts estruturados com XML e Markdown, seguindo boas práticas e trazendo mais contexto para o agente executor.

Contexto do projeto: Flutter, Dart, Riverpod, Dio, duck_router, equatable, intl, Clean Architecture.

## Procedimento

**Step 1: Analisar o prompt de entrada**

1. Leia o prompt fornecido pelo usuário na íntegra.
2. Identifique a tarefa principal, requisitos implícitos e explícitos, camadas afetadas e restrições.
3. Leia `references/prompt-schema.md` para entender a estrutura de saída e quais blocos são obrigatórios.
4. Leia `examples/before-after-example.md` para ver o padrão de transformação esperado.
5. Se a tarefa se encaixar em um padrão conhecido, leia `examples/few-shot-examples.md` para referência.

**Step 2: Extrair e categorizar**

1. Extraia a tarefa em uma linha concisa para `<task>`.
2. Defina `<goals>`: uma frase que resume o objetivo principal — **obrigatório sempre**.
3. Defina `<role>` com: engenheiro Flutter senior, stack (Flutter, Dart, Riverpod, Clean Architecture), contexto da feature.
4. Separe requisitos em três subcategorias obrigatórias dentro de `<requirements>`:
   - **Business:** o que o usuário precisa em termos de valor e funcionalidade.
   - **Technical:** camadas afetadas (domain/data/infrastructure/presentation/main), stack, fluxo de dados.
   - **UI/UX:** estados da tela (loading, erro, vazio, sucesso), feedback visual, acessibilidade.
5. Defina `<context-tools>` quando houver skills do projeto ou MCPs aplicáveis:
   - **Skills relevantes:** das skills disponíveis no projeto (`sdd`, `notifier`, `validator`, `new-feature`, `new-test`, `arch-review`, `deep-link`).
   - **MCPs disponíveis:** `context7` (documentação de libs Flutter/Dart) e/ou `octocode` (exemplos GitHub) quando pertinentes.
6. Se a tarefa tiver múltiplas etapas com dependências, extraia `<workflow>` com passos numerados (Chain-of-Thought).
7. Se o formato ou estrutura de saída for relevante, defina `<output>` (arquivos criados, estrutura de código).
8. Se a tarefa envolver integração com APIs HTTP externas, documente em `<endpoints>` com URL, método, status codes e payload.
9. Inclua `<tests>` quando houver **qualquer** lógica testável — não apenas endpoints:
   - Notifier (ProviderContainer + mock de IXxxRepository)
   - Validators (Dart puro)
   - Repository (mock em IHttpClient)
   - Response `fromJson` (Dart puro)
10. Em `<critical>`, inclua as duas subcategorias obrigatórias:
    - **Skills obrigatórias:** skills que o agente executor deve invocar — `/sdd` é **sempre** obrigatória.
    - **Fora do Escopo:** o que *NÃO* deve ser implementado, usando *NÃO* ou *NUNCA* para ênfase.

**Step 3: Montar o prompt estruturado**

1. Leia `assets/structured-prompt-template.md` para o esqueleto.
2. Preencha cada bloco com o conteúdo extraído e categorizado.
3. Remova blocos opcionais vazios (`<endpoints>`, `<workflow>`, `<output>`, `<tests>`, `<context-tools>` se não aplicável).
4. Entre blocos longos (mais de 5 linhas), insira `---` como delimitador visual.
5. Garanta que requisitos vagos sejam tornados explícitos (ex.: "exiba os dados" → "lista com loading, estado vazio e tratamento de erro").

**Step 4: Validar**

1. Leia `references/checklist.md` e verifique cada item.
2. Execute `python3 scripts/validate-structure.py` passando o prompt gerado via stdin para confirmar blocos e subcategorias obrigatórias.
3. Corrija qualquer `MISSING` reportado antes de entregar ao usuário.
4. `WARNING` (como `<tests>` ausente com `<endpoints>` presente) deve ser avaliado — se houver lógica testável, adicione `<tests>`.

**Step 5: Instruir o próximo passo**

Após entregar o prompt estruturado, adicione sempre esta instrução ao final da resposta:

> **Próximo passo:** cole o prompt acima e execute `/sdd` para criar a spec antes de qualquer implementação.

## Error Handling

- **Prompt já estruturado:** Se o prompt de entrada já contiver blocos XML (`<task>`, `<role>`, etc.), informe o usuário e ofereça refinamento em vez de reestruturação completa.
- **Contexto insuficiente:** Se o prompt for muito vago (ex.: "faz uma tela"), solicite ao usuário: feature name, camadas envolvidas, APIs se houver.
- **Skills não identificadas:** Se a tarefa não mapear claramente para skills conhecidas, prefira `arch-review` como padrão mínimo para qualquer tarefa cross-layer.
- **Validação falhou:** Se `scripts/validate-structure.py` retornar erros `MISSING`, adicione os blocos ou subcategorias faltantes antes de entregar.
