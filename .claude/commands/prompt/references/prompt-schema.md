# Prompt Schema (Structured Format)

Prompts estruturados usam blocos XML para organizar o contexto. Cada bloco tem um propósito específico. Técnicas de prompt engineering aplicadas: contextual priming, delimitadores, XML tags, output format control.

## Blocos Obrigatórios

| Bloco | Propósito | Exemplo |
|-------|-----------|---------|
| `<task>` | Descrição concisa da tarefa em uma linha | `<task>Implementação da tela de criação de despesa</task>` |
| `<goals>` | Objetivo em uma frase (foco do modelo) | `<goals>Implementar a tela com validação de formulário e integração via Dio.</goals>` |
| `<role>` | Papel do agente e contexto da tarefa | `<role>Você é um engenheiro Flutter senior...</role>` |
| `<requirements>` | Requisitos organizados por categoria | Business, Technical, UI/UX |
| `<critical>` | Restrições e skills obrigatórias | Skills, fora do escopo |

## Blocos Opcionais (incluir quando aplicável)

| Bloco | Propósito | Quando usar |
|-------|-----------|-------------|
| `<context-tools>` | Skills e MCPs relevantes para a tarefa | Sempre que houver skills do projeto ou MCPs aplicáveis |
| `<workflow>` | Passos de raciocínio (Chain-of-Thought) | Tarefas complexas com múltiplas etapas |
| `<output>` | Formato esperado da saída | Estrutura de arquivos, código, paths Dart |
| `<profile>` | Autor, versão, idioma | Prompts reutilizáveis ou versionados |
| `<endpoints>` | APIs externas, payloads | Quando há integração com APIs HTTP (consumo, não criação) |
| `<tests>` | Casos de teste esperados | Quando há lógica testável: Notifier, validators, repository ou response fromJson |

## Delimitadores

Entre blocos longos (mais de 5 linhas), use `---` como separador visual. Delimitadores explícitos melhoram precisão e estabilidade do modelo.

## Estrutura de `<requirements>`

**Todas as três subcategorias são obrigatórias:**

```
### Business
- Requisitos de negócio (o que o usuário precisa em termos de valor/funcionalidade)

### Technical
- Requisitos técnicos (stack, arquitetura, camadas, fluxo de dados)
- Mencionar: Clean Architecture, Riverpod, Dio, duck_router, equatable, intl conforme relevante
- Fluxo padrão: Notifier → Repository → DataSource → Client (Dio)

### UI/UX
- Requisitos de interface e experiência
- Mencionar: estados da tela (loading, erro, vazio, sucesso), feedback visual, acessibilidade
```

## Estrutura de `<critical>`

**Ambas as subcategorias são obrigatórias:**

```
### Skills obrigatórias
- `sdd` — SEMPRE obrigatória: criar spec antes de implementar
- Lista de outras skills do projeto que devem ser invocadas

### Fora do Escopo
- O que NÃO deve ser implementado (explícito)
- Use *NÃO* ou *NUNCA* para ênfase
```

## Estrutura de `<goals>`

Uma frase que resume o objetivo principal. Deve ser específica o suficiente para direcionar a atenção do modelo sem descrever implementação.

Exemplo: "Implementar a tela de histórico consumindo o ExpenseRepository, com paginação e estado vazio ilustrado."

## Estrutura de `<workflow>`

Passos numerados para tarefas complexas (Chain-of-Thought). Exemplo:

```
1. [Criar spec com /sdd e aguardar aprovação]
2. [Implementar camada domain: model + interface de repositório]
3. [Implementar infrastructure: request/response + datasource]
4. [Implementar data: repositório + extension de mapping]
5. [Implementar presentation: state + intent + notifier + screen + widgets]
6. [Registrar providers em main/providers/]
7. [Rodar flutter analyze && flutter test]
```

## Estrutura de `<output>`

Especificar o que se espera como resultado: "Arquivos criados/modificados com caminhos", "Código Dart + providers em main/providers/", etc.

## Estrutura de `<context-tools>`

```
### Skills relevantes
- `<skill-name>` — <quando/por que usar nesta tarefa>

### MCPs disponíveis
- `context7` — documentação atualizada de libs (Riverpod, Dio, duck_router, intl, Flutter)
- `octocode` — exemplos reais em repositórios GitHub Flutter/Dart
```

## Estrutura de `<profile>`

```
- author: [nome]
- version: [semver]
- language: [pt-BR, en, etc.]
```
