# New Feature Checklist

Guia para adicionar uma nova feature seguindo a arquitetura do projeto.

## Fluxo padrão

```
Notifier → Repository → DataSource → Client
```

---

## Checklist por camada

### 1. Domain — contratos (Dart puro, zero Flutter)

- [ ] Criar model em `lib/src/domain/models/`
  — campos antes do construtor
  — `copyWith()` obrigatório
- [ ] Criar interface em `lib/src/domain/contracts/repositories/`
  — retornar `Either<Failure, T>`, nunca lançar exceptions

### 2. Infrastructure — request, response e datasource

- [ ] Criar `XxxRequest` em `lib/src/infrastructure/clients/http/requests/`
  — campos antes do construtor, `toJson()` obrigatório
- [ ] Criar `XxxResponse` em `lib/src/infrastructure/clients/http/responses/`
  — campos antes do construtor, `fromJson()` obrigatório
- [ ] Criar interface de datasource em `lib/src/infrastructure/datasources/`
  — retornar `Either<FailureResponse, XxxResponse>`
- [ ] Criar datasource remoto em `lib/src/infrastructure/datasources/remote/` usando Client
  — mapear `Either<Map, Map>` do Client para `Either<FailureResponse, XxxResponse>` via `fromJson`
- [ ] Criar uma interface de Client em `lib/src/infrastructure/clients/http/` com os 5 principais metodos GET, POST, PUT PATCH e DELETE,
  — deve retornar `Either<Map<String, dynamic>, Map<String, dynamic>>`, único try-catch do projeto

### 3. Data — repositório

- [ ] Criar implementação de repositório em `lib/src/data/repositories/`
  — receber interface de datasource (nunca implementação concreta)
  — converter `FailureResponse → Left(Failure)` e `XxxResponse → Right(Model)`

### 4. Presentation — MVI

- [ ] Criar `XxxIntent` (sealed class) com todos os intents da feature
- [ ] Criar `XxxState` com `copyWith()` — campos antes do construtor
- [ ] Criar `XxxNotifier` com `@riverpod` e método `dispatch(XxxIntent)`
- [ ] Rodar `dart run build_runner build --delete-conflicting-outputs`

### 5. Testes

- [ ] `test/src/domain/failures/` — se houver novo subtipo de Failure
- [ ] `test/src/data/repositories/` — testes do repositório com mock do datasource
- [ ] `test/src/presentation/providers/` — dispatch de intents com ProviderContainer
- [ ] `flutter test` e `flutter analyze` passando

---

## Regras obrigatórias

- Campos antes do construtor em toda classe
- Zero comentários explicativos no código
- Code gen (`@riverpod`) apenas para providers Riverpod
- Sem use_cases — lógica fica no Notifier

---

## Referências
- Fluxo SDD: skill `/sdd`
