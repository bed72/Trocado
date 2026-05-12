# Trocado

App de controle financeiro para casais. "Trocado" é o nome coloquial brasileiro para dinheiro.

Consome uma API REST Django para sincronizar despesas, orçamentos e dados de autenticação entre os parceiros.

---

## Stack

- **Flutter** (Dart SDK `^3.10.0`) — iOS e Android
- **Riverpod** (`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`) — state management e DI
- **Dio** — HTTP client com interceptors de autenticação JWT e App Check
- **duck_router** — navegação declarativa por `Location`
- **flex_color_scheme** — tema Material 3, suporte a dark mode
- **equatable** — igualdade em modelos de domínio
- **intl** — formatação de moeda e datas em `pt_BR`
- **Firebase** — Core, Crashlytics, Cloud Messaging, App Check

State management segue padrão MVI: cada feature tem um `XxxNotifier` com `dispatch(intent)` e estado imutável via `copyWith()`. Widgets são `StatelessWidget` puros; apenas screens consomem providers via `Consumer`.

---

## Arquitetura

Clean Architecture estrita em 5 camadas:

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

- `domain/` — Dart puro, zero Flutter. Models, failures, repository interfaces, validators.
- `data/` — implementa contratos de `domain`; extensions de mapping `XxxResponse → XxxModel`.
- `infrastructure/` — clients externos (Dio, Firebase, storage), datasources, request/response DTOs.
- `presentation/` — UI (screens + widgets) e state (Notifiers Riverpod MVI).
- `main/` — composition root: locations do `duck_router`, providers de wiring.

Repositórios retornam `Either<Failure, T>` — nunca lançam exceptions. O único `try-catch` fica no HTTP client.

Convenções completas, regras de dependência, padrões de teste e nomenclatura: ver [CLAUDE.md](./CLAUDE.md).

---

## Features

### Autenticação
- Sign-in com email + senha
- Sign-up com confirmação de senha
- Forgot password / password reset por email
- Refresh token automático em 401

### Despesas
- Cadastro com validação (valor em centavos, categoria, data, descrição)
- Edição e exclusão (swipe-to-delete)
- Listagem paginada com filtros (todas / receitas / despesas)
- Cards de resumo financeiro (total, entradas, saídas, saldo)

### Orçamentos
- Criação por período (mês/ano)
- Listagem, edição e exclusão
- Vínculo com despesas para acompanhamento

### Outros
- Home com despesas recentes + carrossel de insights
- Splash com checagem de sessão (autenticado vs. não autenticado)
- Settings: perfil, logout, exclusão de conta
- Calculadora de despesas
- Seletor de período com `date_range`

---

## Setup local

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` é usado **exclusivamente** para gerar providers Riverpod (`@riverpod`).

### Rodar em debug

A app consome um backend Django. Passa a URL via `--dart-define`:

```bash
flutter run --dart-define=BASE_URL=http://192.168.1.x:8080
```

Há uma config pronta em `.vscode/launch.json` (`Trocado (debug)`) que já injeta o `BASE_URL` local.

---

## Builds

### Debug local

```bash
flutter run --dart-define=BASE_URL=<url-do-backend>
```

### Release Android — automatizado via GitHub Action

Workflow `.github/workflows/android-release.yml` é disparado manualmente, lê a versão de `pubspec.yaml`, builda AAB assinado, faz upload dos símbolos Dart pro Crashlytics e sobe pro Play Console em track `internal` com status `draft`.

Fluxo:

1. **Bump em `pubspec.yaml`** linha `version: X.Y.Z+N` (PR + merge na `main`).
2. **Dispatch**:
   ```bash
   gh workflow run android-release.yml
   ```
3. **Aguardar** ~10-15min. Output: AAB em draft no Play Console + tag `vX.Y.Z+N` no commit.
4. **Rollout manual**: Play Console → Trocado → Testing → Internal testing → Review release → Start rollout.

Detalhes (secrets necessários, pré-requisitos, signing): ver `## Releases` em [CLAUDE.md](./CLAUDE.md).

### Release iOS

Ainda manual via Xcode. Automação virá em change futura.

---

## Testes

```bash
flutter test
flutter analyze
```

Estratégia por camada:

| Camada | O que mocka | Onde fica |
|---|---|---|
| Response `fromJson` | nada (puro) | `test/src/infrastructure/responses/` |
| Repositório + Datasource | `IHttpClient` | `test/src/data/repositories/` |
| Notifier | `IXxxRepository` | `test/src/presentation/providers/` |

Não há testes separados de datasource — eles só deserializam JSON e são cobertos pelos testes de `fromJson` + repositório.

---

## Spec-Driven Development

Toda mudança não-trivial começa por uma spec em `openspec/changes/<data>-<change>/` com `proposal.md`, `design.md` e `tasks.md`. Após implementação, a change vai pra `openspec/changes/archive/`.

Specs ativas e arquivadas: `openspec/`.

---

## Atribuições

Ilustrações: [Money illustrations by Storyset](https://storyset.com/money).
