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
  — campos antes do construtor, `fromJson()` **apenas** — nunca `toModel()`
- [ ] Criar interface de datasource em `lib/src/infrastructure/datasources/`
  — retornar `Either<FailureResponse, XxxResponse>`
  — interface aceita parâmetros de domínio (String, int…), nunca `XxxRequest`
- [ ] Criar datasource remoto em `lib/src/infrastructure/datasources/remote/` usando Client
  — criar `XxxRequest` internamente na implementação, não na interface
  — mapear `Either<Map, Map>` do Client para `Either<FailureResponse, XxxResponse>` via `fromJson`

### 3. Data — repositório e extensions

- [ ] Criar `lib/src/data/extensions/xxx_response_extension.dart`
  — extension `toModel()` em `XxxResponse` retornando `XxxModel`
- [ ] Criar implementação de repositório em `lib/src/data/repositories/`
  — receber interface de datasource (nunca implementação concreta)
  — passar parâmetros de domínio direto ao datasource (sem criar `XxxRequest`)
  — converter `FailureResponse → Left(failure.toFailure())` e `XxxResponse → Right(response.toModel())`
  — usar `data.either(...)` quando não há async entre os dois lados; early return quando há

### 4. Presentation — MVI

- [ ] Criar `XxxIntent` (sealed class) com todos os intents da feature
- [ ] Criar `XxxState` com `copyWith()` — campos antes do construtor
- [ ] Criar `XxxNotifier` com `@riverpod` e método `dispatch(XxxIntent)`
- [ ] Se houver formatação/transformação por service (moneyService, etc.), criar view-model em `lib/src/presentation/screens/<feature>/data/` (ex: `XxxItemData`) — o notifier injeta o service em `build()` e emite dados prontos no state; screen **nunca** lê service direto via `ref.watch`
- [ ] Feature é autocontida: não importar widgets/notifiers/states/screens de outra feature. Se um widget ou view-model precisa ser compartilhado, mover para `lib/src/presentation/widgets/<família>/` ou `lib/src/presentation/data/<família>/` (sempre subpasta por família)
- [ ] Navegação entre features via `VoidCallback` injetado pela Location — screen nunca importa outra `XxxLocation`
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
