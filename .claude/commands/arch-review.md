# Arch Review — Clean Architecture & SOLID

Revisão de violações de Clean Architecture e SOLID para a feature: $ARGUMENTS

---

## Como executar

1. Ler todos os arquivos da feature de ponta a ponta (screen → notifier → repository → datasource → client)
2. Verificar cada item dos checklists abaixo
3. Listar apenas os pontos com problema — sem mencionar o que está correto

---

## Checklist — Clean Architecture

### `core/`
- [ ] `Either` importado de `core/either/either.dart`, não de `domain/`

### `infrastructure/` nunca conhece `domain/`
- [ ] Nenhuma response tem `toModel()` ou importa models de `domain/`
- [ ] Nenhum client ou datasource importa de `domain/`

### Interface de datasource aceita parâmetros de domínio
- [ ] Métodos da interface recebem tipos primitivos (`String`, `int`, etc.), não DTOs como `XxxRequest`
- [ ] O `XxxRequest` é criado dentro da implementação concreta, não passado pela interface

### `data/` mapeia via extensions
- [ ] Existe `data/extensions/xxx_response_extension.dart` com `toModel()`
- [ ] O repositório usa `response.toModel()` da extension, não acessa campos diretamente para construir o model
- [ ] O repositório usa `failure.toFailure()` de `FailureResponseExtension`

### `data/` não conhece `presentation/` nem `main/`
- [ ] Nenhum import de `presentation/` ou `main/` dentro de `data/`

### `presentation/` não conhece `data/` nem `infrastructure/`
- [ ] Notifier importa apenas interfaces de `domain/` e providers de `main/`
- [ ] Screen não importa nada de `data/` ou `infrastructure/`

---

## Checklist — SOLID

### SRP — Single Responsibility
- [ ] Repositório não mistura responsabilidades além de acesso a dados de uma entidade
- [ ] Notifier não instancia dependências — recebe tudo via `ref.watch`

### DIP — Dependency Inversion
- [ ] Notifier recebe repositório via `ref.watch(xxxRepositoryProvider)` em `build()`
- [ ] Notifier recebe validator via `ref.watch(xxxFormValidatorProvider)` em `build()`, se houver formulário
- [ ] Repositório recebe interfaces de datasource via construtor, nunca implementações concretas

### OCP / DRY
- [ ] `HttpClient` não tem lógica duplicada entre os métodos HTTP (usa `_execute`)

---

## Checklist — Riverpod

- [ ] Campos de dependência no Notifier são `late` (nunca `late final`)
- [ ] Dependências inicializadas em `build()`, nunca como `static const` ou inline
- [ ] Validators são providers em `main/providers/validators_provider.dart`

---

## Checklist — Segurança

- [ ] `_mapFailure` em `HttpClient` usa `is Map<String, dynamic>` antes de usar o dado da response (sem cast direto `as`)

---

## Checklist — Expressividade

- [ ] `hideKeyboard` chamado como método `hideKeyboard()`, não como getter `hideKeyboard`

---

## Formato de saída

Para cada violação encontrada, reportar:

| # | Tipo | Severidade | Arquivo | Descrição |
|---|------|-----------|---------|-----------|
| 1 | Clean Arch | Alta | `infrastructure/clients/http/responses/sign_in_response.dart` | `toModel()` em response importa domain |

Severidade: **Alta** (viola camadas), **Média** (DRY/OCP/DIP), **Baixa** (expressividade)

Se não houver violações, confirmar: "Nenhuma violação encontrada."
