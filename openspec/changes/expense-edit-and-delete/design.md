# Design — expense-edit-and-delete

## Contexto técnico

A stack de despesas já está em pé: `IExpenseRepository` → `IRemoteExpenseDataSource` → `IHttpClient` (Dio). O `ExpenseRequest` existente serializa `{date → ISO yyyy-MM-dd, value → decimal string, description → string}` — exatamente o que o backend espera no `PATCH`. `ExpenseResponse` + `ExpenseResponseExtension.toModel()` já mapeiam o retorno do `PATCH` para `ExpenseModel`. Para o `DELETE` (204 sem body), basta mapear o `Right(_)` do client para `Right(null)`.

No lado de presentation, o `ExpenseNotifier` (tela de cadastro) é um `Notifier<ExpenseState>` síncrono, e o `ExpensesNotifier` (listagem) é um `AsyncNotifier<ExpensesState>` com métodos diretos (`applyFilter`, `searchChanged`, `removeFilter`, `loadMore`). A listagem **não usa MVI dispatch** — isso é deliberado e foi mantido ao longo das evoluções da feature. Respeitamos esse idioma.

## Regra de dependência (respeitada)

```
domain ← data ← infrastructure
domain ← presentation
main   → tudo
```

- `domain/` ganha assinaturas em `IExpenseRepository` (update, delete). Zero Flutter imports, zero Dio.
- `infrastructure/` ganha os métodos concretos no datasource remoto. Reusa `ExpenseRequest` existente (sem DTO novo).
- `data/` implementa update/delete no `ExpenseRepository`, reusando `FailureResponseExtension.toFailure()` e `ExpenseResponseExtension.toModel()`.
- `presentation/` ganha a family no `ExpenseNotifier`, parametrização dos textos em `ExpenseScreen` + `ExpenseSaveButtonWidget`, o método `delete` em `ExpensesNotifier`, o `onLongPress` no `ExpenseItemWidget`, e a nova feature `expense_actions/` (screen + location, sem notifier — é um sheet de callbacks puro).
- `main/` (via `lib/app_route.dart`) ganha a rota `expenseActions`.

## Decisões de design

### 1. Reusar `ExpenseRequest` para create e update (sem `UpdateExpenseRequest`)

**Decisão**: o `PATCH` envia sempre os 3 campos `{value, description, date}` — exatamente a shape do `ExpenseRequest` já usado no `POST`. Não introduzir um `UpdateExpenseRequest` idêntico.

**Rationale**: criar duas classes com o mesmo formato serializado só adiciona superfície pra manter em sincronia. Se no futuro o PATCH divergir (ex: suportar partial update, ganhar campos exclusivos), partimos o request em duas classes naquele momento. Por ora, um único DTO serve os dois verbos.

**Trade-off**: caso o backend passe a aceitar patch parcial, a mudança vai exigir uma divergência — mas isso é uma evolução local ao datasource, não dano estrutural.

### 2. `ExpenseNotifier` vira family `<ExpenseModel?>` (não `<int?>`)

**Decisão**: `@riverpod` family com parâmetro `ExpenseModel?`. `null` = modo create, não-null = modo edit (state pré-preenchido com `id`, `date`, `value`, `description` do model).

**Rationale**: o model inteiro já está em memória quando o usuário long-pressa um item (vem do `ExpenseItemData` via `state.items[i].expense`). Passar `ExpenseModel?` evita:

- Adicionar um `findById` no repositório só para edit.
- Um segundo request de rede que duplica dados que já temos.
- Um estado intermediário de "carregando dados para editar".

`ExpenseModel` é `Equatable`, então o Riverpod usa hashCode/igualdade dele como chave da family corretamente — duas instâncias com mesmos campos compartilham o mesmo provider.

**Trade-off**: se no futuro a tela de edit vier de deep link (recebe só `id` via URL), teremos que revisitar para aceitar `int?` e fazer um fetch no build. Para o uso atual (long-press na lista), `ExpenseModel?` é mais direto.

### 3. `ExpenseState` ganha `int? id` como discriminador de modo

**Decisão**: `null` = create, preenchido = edit. `_submit()` ramifica por `state.id == null` entre `repository.create(...)` e `repository.update(id: state.id!, ...)`.

**Rationale**: não criar um enum `ExpenseMode { create, edit }` redundante. A presença do `id` é a única coisa que distingue os modos em termos de comportamento — tornar isso explícito no state é mais barato que manter duas fontes de verdade (`mode` + `id`). O `id!` no branch de update é seguro porque `id != null` é a própria condição do branch.

**Consequência no `ExpenseIntent`**: o sealed não muda — os mesmos intents (`ValueChanged`, `DescriptionChanged`, `DateChanged`, `SubmitPressed`) cobrem os dois modos. **Não** adicionar `DeletePressed` aqui (delete é exclusivo do bottom sheet; colocar intent aqui implicaria um botão de delete na tela, o que foi explicitamente descartado).

### 4. `delete(int id)` é método direto em `ExpensesNotifier`, não intent — e retorna `Either`

**Decisão**: `ExpensesNotifier` expõe `Future<Either<Failure, void>> delete(int id)`. Em sucesso, invalida `expensesProvider`, `activeBudgetProvider`, `recentExpensesProvider` e retorna `Right(null)`. Em falha, **não mutua o state** — retorna `Left(failure)` para o chamador, que mostra um toast.

**Rationale (método vs intent)**: `ExpensesNotifier` não usa MVI dispatch — ele expõe `applyFilter`, `searchChanged`, `removeFilter`, `loadMore` como métodos. Adicionar um intent aqui quebraria o padrão deste notifier. O design do notifier de lista é intencionalmente diferente do `ExpenseNotifier` de formulário: não tem "intents de usuário" no sentido MVI clássico — tem operações de refresh/filtragem que o usuário aciona via botões/gestos, mas a superfície é método a método.

**Rationale (retornar Either e não emitir AsyncError)**: se o delete falhar, transicionar o `state` para `AsyncError` faria a screen inteira virar `ExpensesFailureWidget` (tela de erro com retry) — perda total de contexto por uma mutação que sequer afeta o estado visual atual. O padrão correto é o mesmo do `ExpenseScreen` em falha de submit: **toast**. Retornar `Either` do método permite que a `ExpensesLocation` (que compõe o callback) chame `showToastWidget` via o `context` já capturado; o state da lista permanece intacto.

**Alternativa considerada 1**: manter `Future<void>` e emitir falhas por um canal lateral (ex: um `StreamController` de erros no notifier). **Rejeitado**: adiciona infra sem ganho — o chamador já é quem sabe `context` e já está num `async` callback; o `Either` é a ferramenta natural.

**Alternativa considerada 2**: criar `ExpenseActionsNotifier` na nova feature para hospedar o delete. **Rejeitado**: quebra encapsulamento por-feature (já que o delete precisa invalidar providers de `expenses/`) e adiciona um notifier só para uma operação. Mais simples: a nova feature é pura UI de callbacks; a mutação é responsabilidade do dono do estado da lista.

### 5. `expense_actions/` é feature de **screen puro + location**, sem notifier

**Decisão**: `ExpenseActionsScreen` é `StatelessWidget` que recebe `VoidCallback onEdit` e `VoidCallback onDelete` via construtor. `ExpenseActionsLocation` injeta os callbacks via construtor.

**Rationale**: o sheet não tem estado próprio. Ele só renderiza dois botões e chama callbacks. Adicionar um notifier só para "quando o botão é tocado" seria cerimônia pura. Isso também respeita a regra de **feature autocontida**: `expense_actions/` não importa nada de `expenses/` ou `expense/` — toda a cola acontece em `ExpensesLocation`, que é o único ponto autorizado a compor callbacks entre features (via `Consumer` pra capturar `ref`).

### 6. Composição dos callbacks vive em `ExpensesLocation` (com `Consumer` no `pageBuilder`)

**Decisão**: `ExpensesLocation.pageBuilder` é envolvido em `Consumer` — dentro dele, o builder cria os callbacks `onEdit` (pop + navigate para `ExpenseLocation(expense: ...)`) e `onDelete` (pop + `ref.read(expensesProvider.notifier).delete(expense.id)`).

**Rationale**: Location é o ponto canônico de composição de navegação no projeto (padrão já usado em `ExitLocation`, `ExpenseLocation` com `navigateToDate`, etc.). Usar `Consumer` dentro do `pageBuilder` permite capturar `ref` para o `onDelete` sem vazar Riverpod pra dentro da `ExpenseActionsScreen`. A screen permanece `StatelessWidget` puro com `VoidCallback`s — testável sem container.

**Consequência**: é o **único** ponto que conhece simultaneamente `ExpenseLocation`, `ExpenseActionsLocation` e `expensesProvider`. Respeitando a regra do CLAUDE.md: "Locations compondo navegação podem importar outras Locations — mas apenas em outras Locations".

### 7. `long-press` via `GestureDetector`, não `InkWell`

**Decisão**: `ExpenseItemWidget` ganha `VoidCallback? onLongPress` e embrulha o `Padding` atual em `GestureDetector(onLongPress: ...)`.

**Rationale**: o item não tem `onTap` hoje (tap não abre nada). Usar `InkWell` adicionaria ripple visual para um gesto que ninguém está fazendo (tap). `GestureDetector` dispara long-press sem feedback visual extra — o usuário percebe a ação pelo sheet que aparece, não pelo item "brilhar". Se no futuro o item ganhar `onTap`, podemos migrar para `InkWell` — hoje é adição gratuita.

### 8. `DELETE` retorna `Right(void)` — mapeamento explícito no datasource

**Decisão**: o datasource faz `return response.either(FailureResponse.fromJson, (_) => null);` (ou equivalente), produzindo `Either<FailureResponse, void>`. No repositório, o mapeamento de sucesso é `(_) => null`.

**Rationale**: 204 No Content não tem body — o `HttpClient._execute` já retorna `Right({})` para respostas sem body (via `data ?? {}`). O datasource descarta esse `{}` e produz `void` (representado como `null`) para a camada superior. Tipar como `Either<Failure, void>` comunica explicitamente que "só importa o lado da falha".

**Alternativa considerada**: retornar `Either<Failure, bool>` com `Right(true)` em sucesso. **Rejeitado**: `true` não agrega informação além do "deu certo", e qualquer call site acabaria ignorando o `bool`. `void` é mais honesto.

### 9. `ExpenseSaveButtonWidget` ganha parâmetro `label`

**Decisão**: o widget atual tem `label: 'Salvar'` hardcoded. Adicionar `final String label;` e passar `'Cadastrar'` / `'Atualizar'` de acordo com o modo a partir da `ExpenseScreen`.

**Rationale**: o label mudar dinamicamente é requisito explícito do prompt. Parametrizar via construtor mantém o widget sem conhecer o modo — só recebe o texto pronto.

## Fluxos

### Long-press → editar

```
[ExpensesScreen] user long-presses item
  → ExpenseItemWidget.onLongPress(expense)
  → screen callback
  → context.navigate(ExpenseActionsLocation(onEdit: …, onDelete: …))
    (composto em ExpensesLocation.pageBuilder via Consumer)

[ExpenseActionsScreen] user taps "Editar"
  → onEdit()
    → context.pop()              [sheet fecha]
    → context.navigate(ExpenseLocation(expense: expense))

[ExpenseLocation → ExpenseScreen] build com expense != null
  → ExpenseNotifier.build(expense) retorna state pré-preenchido com id/date/value/description
  → screen renderiza com título "Editar despesa", subtítulo "Atualize…", botão "Atualizar"

[ExpenseScreen] user altera campos e tap "Atualizar"
  → dispatch(SubmitPressed)
  → _submit() ramifica por state.id != null
  → repository.update(id, date, value, description)
  → on Right(ExpenseModel):
      ref.invalidate(expensesProvider, activeBudgetProvider, recentExpensesProvider)
      state.status = success
      → screen listener faz context.pop()
```

### Long-press → excluir

```
[ExpensesScreen] user long-presses item
  → (mesmo fluxo até ExpenseActionsScreen)

[ExpenseActionsScreen] user taps "Excluir"
  → onDelete() [async, composta em ExpensesLocation]
    → context.pop()                                          [sheet fecha]
    → final data = await ref.read(expensesProvider.notifier).delete(expense.id)
    → data.fold(
        (failure) => showToastWidget(context: context, ...,  [toast na ExpensesScreen]
                       type: ToastConstant.failure,
                       description: failure.message),
        (_) {},                                              [sucesso: providers já invalidados]
      )

[ExpensesNotifier.delete] (Future<Either<Failure, void>>)
  → repository.delete(id: id)
  → on Right(null):
      ref.invalidate(activeBudgetProvider)
      ref.invalidate(recentExpensesProvider)
      ref.invalidate(expensesProvider)   [re-executa build(), refresca a lista]
      return Right(null)
  → on Left(failure):
      return Left(failure)               [state NÃO muda; lista permanece intacta]
```

## Trade-offs assumidos

- **Delete imediato sem confirmação**: é decisão UX do usuário. O risco de exclusão acidental existe; a mitigação atual é o long-press (gesto intencional) + dois taps para chegar no delete (long-press → botão "Excluir"). Se virar problema, adicionar snackbar "Desfazer" (5s) é a próxima evolução.
- **`ExpenseLocation` recebendo model em memória**: acopla a feature de edit ao estado da lista. Se alguém quiser editar via deep link, a Location precisa evoluir. OK como ponto de partida — deep link para edit não está no roadmap atual.
- **Reusar `ExpenseRequest`**: se o backend ganhar campos exclusivos de update (raro), precisaremos separar. Aceitável.

## O que este design **não** pretende resolver

- Otimistic update na lista após delete (remover item localmente antes da resposta).
- Multi-seleção de despesas para delete em lote.
- Histórico de edições / audit trail.
- Notificação ao parceiro quando uma despesa é editada/excluída (fora do escopo de CRUD local).
