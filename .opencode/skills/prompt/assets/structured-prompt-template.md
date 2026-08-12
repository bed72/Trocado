<task>[Descrição concisa da tarefa em uma linha]</task>

<goals>
    [Objetivo em uma frase — foco do modelo]
</goals>

<role>
    [Papel do agente: engenheiro Flutter senior, stack Dart + Riverpod + Clean Architecture.
    Contexto: [descrever o domínio/feature da tarefa]]
</role>

---

<requirements>
    ### Business

    - [Requisitos de negócio: o que o usuário precisa em termos de valor e funcionalidade]

    ### Technical

    - [Stack e camadas envolvidas: domain, data, infrastructure, presentation, main]
    - [Tecnologias relevantes: Riverpod, Dio, duck_router, equatable, intl]
    - [Fluxo de dados: Notifier → Repository → DataSource → API]

    ### UI/UX

    - [Estados da tela: loading, erro, vazio, sucesso]
    - [Feedback visual, acessibilidade, animações se aplicável]
</requirements>

---

<context-tools>
    ### Skills relevantes

    - `[skill-name]` — [quando/por que usar nesta tarefa]

    ### MCPs disponíveis

    - `context7` — documentação atualizada de libs (Riverpod, Dio, duck_router, intl, Flutter)
    - `octocode` — exemplos reais em repositórios GitHub Flutter/Dart
</context-tools>

---

<workflow>
    1. [Primeiro passo lógico]
    2. [Segundo passo]
    3. [Terceiro passo]
</workflow>

<output>
    [Formato esperado: arquivos criados/modificados com caminhos, código Dart, providers em main/providers/]
</output>

<endpoints>
    ### [Nome da API]

    - **URL:** [endpoint]
    - **Método:** [GET/POST/PUT/DELETE]
    - **Status codes:** [200, 400, 401, etc.]
    - **Payload:** [campos relevantes]
</endpoints>

<tests>
    ### [Categoria: Notifier / Validators / Repository / Response fromJson]

    - [Cenário de teste esperado]
</tests>

---

<critical>
    ### Skills obrigatórias

    - `sdd` — **OBRIGATÓRIA**: criar a spec antes de qualquer implementação
    - `[skill-name]` — [por que é obrigatória aqui]

    ### Fora do Escopo

    - *NÃO* [restrição explícita]
    - *NUNCA* [restrição absoluta]
</critical>
