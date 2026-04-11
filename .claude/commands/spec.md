# /spec

Cria uma spec OpenSpec para uma mudança no Trocado usando `/opsx:propose`.

## Instrução

O usuário quer criar uma spec para: $ARGUMENTS

Siga os passos abaixo antes de invocar `/opsx:propose`:

---

### 1. Entender o escopo

Leia `CLAUDE.md` para entender a arquitetura atual.
Se `$ARGUMENTS` não estiver claro, use `AskUserQuestion` para esclarecer:
- Qual camada será afetada? (domain / application / data / infrastructure / presentation)
- É uma feature nova, correção ou refatoração?
- Tem dependência de API? Se sim, verificar o endpoint em `openapi.json`

### 2. Nomear a mudança

Derivar um `change-name` em kebab-case a partir de `$ARGUMENTS`:
- `autenticacao-jwt` → auth flow completo
- `expense-remote-datasource` → datasource remoto de despesas
- `sign-in-notifier` → Notifier MVI de autenticação

### 3. Invocar `/opsx:propose`

```
/opsx:propose <change-name>
```

### 4. Guiar a geração dos artefatos

O `/opsx:propose` vai gerar em `openspec/changes/<change-name>/`:

```
openspec/changes/<change-name>/
├── proposal.md   ← intenção, escopo, motivação
├── design.md     ← abordagem técnica, decisões, trade-offs
├── tasks.md      ← checklist de implementação
└── specs/        ← requisitos SHALL + cenários Given/When/Then
    └── spec.md
```

Ao gerar cada artefato, aplique as constraints do projeto:

**`proposal.md`** — incluir:
- Camadas afetadas — **somente o que o usuário pediu**; se identificar dependências em outras camadas, listar em "Fora do escopo" e perguntar ao usuário antes de incluir
- O que NÃO está no escopo

**`design.md`** — incluir:
- Regra de dependência respeitada (`domain ← data ← infrastructure`)
- Se há datasource envolvido: interface em `infrastructure/datasources/`, remoto em `infrastructure/datasources/remote/`
- Se há erro novo: subtipo de `Failure` em `domain/failures/`
- Se há API: `operationId` do `openapi.json` mapeado para método do datasource

**`tasks.md`** — ordenar pela sequência da arquitetura:
1. `domain/` (models, interfaces, failures)
2. `infrastructure/` (entities em `infrastructure/entities/`, datasource interface, datasource remoto)
3. `data/` (mappers, repository)
4. `presentation/` (Intent, State, Notifier com `@riverpod`)
5. Testes (mocks, unit tests por camada)

**`specs/spec.md`** — requisitos em linguagem SHALL:
```markdown
## Requirements

### Requirement: <Nome>
The system SHALL <comportamento>.

#### Scenario: <Cenário>
Given <pré-condição>
When <ação>
Then <resultado esperado>
```

### 5. Verificar antes de implementar

Após o `/opsx:propose` gerar os artefatos, confirmar com o usuário:
- O `proposal.md` captura a intenção corretamente?
- O `design.md` respeita as regras de camada?
- O `tasks.md` está na ordem certa?

Só avançar para `/opsx:apply` após aprovação.

### 6. Arquivar após implementação

```
/opsx:archive <change-name>
```

Move `openspec/changes/<change-name>/` para `openspec/archive/<change-name>/`.
Executar após todos os itens do `tasks.md` estarem concluídos e commitados.

---

## Exemplo de uso

```
/spec datasource remoto de despesas
```

```
/spec sign-in com JWT
```
