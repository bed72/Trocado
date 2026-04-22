<task>Implementar seção "Despesas recentes" na HomeScreen — lista com até 4 itens mais recentes consumindo GET /api/v1/expenses</task>

<goals>
    Criar a feature de exibição das 4 despesas mais recentes no Home — domain, data, infrastructure, presentation e wiring em main — consumindo o endpoint paginado `GET /api/v1/expenses` e seguindo o padrão já estabelecido por `InsightCarousel` e `BudgetCard`.
</goals>

<role>
    Você é um engenheiro Flutter senior trabalhando no app Trocado (controle financeiro para casais).
    Stack: Flutter, Dart 3.10+, Riverpod (riverpod_generator, MVI com sealed Intent + dispatch ou AsyncNotifier para carregamento inicial), Dio via `IHttpClient`, duck_router, equatable, intl (`pt_BR`), Clean Architecture estrita (core/domain/application/data/infrastructure/presentation/main).
    Sua tarefa é integrar a exibição das despesas recentes na HomeScreen como uma seção adicional (análoga ao `InsightCarousel` e `BudgetCard`), implementando todas as camadas necessárias do zero para o recurso de `Expense` (o app ainda não possui esse domínio implementado).
</role>

---

<requirements>
    ### Business

    - Exibir no Home uma seção **"Despesas recentes"** com no máximo **4 itens**.
    - Título da seção à esquerda, ação **"Ver tudo"** à direita usando `ButtonWidget.text` com accent color.
    - Cada item exibe: ícone da categoria, descrição (bold), linha secundária "Categoria · data relativa · hora" (ex: `Mercado · hoje · 18:42`), valor formatado em `R$ 0,00` (bold) à direita e um badge/avatar circular com inicial/cor do usuário que registrou (quando a API passar a expor o usuário; se não existir no payload atual, usar placeholder neutro e **confirmar antes de estender o schema**).
    - A API retorna paginada, ordenada por `created_at desc` — basta consumir a primeira página e fatiar os 4 primeiros `results`.
    - Ação "Ver tudo" deve existir visualmente e estar pronta para navegação; **a tela de lista completa ainda não existe** — deixar o callback preparado e **perguntar antes de criar `ExpensesLocation`/`ExpensesScreen` inteira** (escopo restrito).

    ### Technical

    - **domain**
        - `ExpenseModel` (Equatable, `copyWith`, campos: `id: int`, `amount: int` (centavos), `description: String`, `date: DateTime`, `createdAt: DateTime`, `category: ExpenseCategory`).
        - `enum ExpenseCategory { food, transport, shopping, health, housing, debt, entertainment, unknown }` (com `fromString`).
        - `IExpenseRepository` com método `findRecent({int limit = 4})` retornando `Future<Either<Failure, List<ExpenseModel>>>`.
    - **infrastructure**
        - `EndpointKey.expenses` → `/api/v1/expenses`.
        - `ExpenseResponse` com `fromJson()` apenas (campos do payload da API: `id`, `value`, `description`, `date`, `created_at`, `category`). **NUNCA** `toModel()` aqui.
        - `PaginatedResponse<T>` genérica se ainda não existir (`next`, `previous`, `results`); caso já exista um padrão no projeto, reutilizar — **verificar antes de criar**.
        - `IRemoteExpenseDataSource.findRecent({required int limit})` retornando `Either<FailureResponse, List<ExpenseResponse>>`.
        - `RemoteExpenseDataSource` chamando `_client.get(...)` e deserializando ambos os lados do `Either` via `fromJson`.
        - Interface aceita **tipos primitivos de domínio** (ex: `int limit`), nunca DTO de infraestrutura.
    - **data**
        - `ExpenseRepository` implementando `IExpenseRepository` — converte `FailureResponse → Failure` via `FailureResponseExtension.toFailure()` e `ExpenseResponse → ExpenseModel` via extension `ExpenseResponseExtension.toModel()` em `data/extensions/`.
        - Conversão monetária: `String "85.50"` → `int 8550` centavos (na extension, não na response).
        - Conversão de datas: `date` (`YYYY-MM-DD`) e `created_at` (ISO-8601 com timezone) → `DateTime`.
        - Conversão de `category: String` → `ExpenseCategory` via `ExpenseCategory.fromString`.
    - **presentation**
        - `RecentExpensesNotifier` como `AsyncNotifier<List<ExpenseModel>>` — `build()` async chama `_repository.findRecent(limit: 4)` (estado é carregado ao montar; sem interação do usuário, não precisa de sealed Intent).
        - Campos via `ref.watch` no `build()`, marcados `late` (não `late final`).
        - `RecentExpensesSectionWidget` — `StatelessWidget` + `Consumer` interno que escuta o provider via `AsyncValue.when` / switch expression em pattern `AsyncData/AsyncError/AsyncLoading`.
        - `ExpenseItemWidget` — `StatelessWidget` puro, recebe `ExpenseModel` + `MoneyService` via construtor (named required params).
        - Integração na `HomeScreen`: inserir `RecentExpensesSectionWidget` entre `BudgetCard` e/ou `InsightCarousel` (ou abaixo, conforme ordem visual decidida na spec).
    - **application**
        - Usar `IMoneyService.format(amount / 100)` para exibição de valores.
        - Formatação de data relativa (`hoje`, `ontem`, data completa) e hora (`HH:mm`) via `intl` no `pt_BR` — se não houver helper utilitário existente, **criar helper simples em `application/services/` ou inline no widget e confirmar preferência na spec**.
    - **main/providers**
        - `expense_providers.dart` com providers para datasource, repository e notifier (gerados via `@riverpod`).
    - Fluxo de dados: `RecentExpensesNotifier` → `IExpenseRepository` → `IRemoteExpenseDataSource` → `IHttpClient` (Dio).
    - `Either<Failure, T>` em todo o fluxo. Repositório **nunca** lança exceptions.

    ### UI/UX

    - **Loading** (`AsyncLoading`): skeleton/placeholder dos 4 itens (ou shimmer) — seguir padrão já usado em `InsightCarousel`/`BudgetCard`.
    - **Vazio** (sucesso com `results.isEmpty`): estado vazio discreto com mensagem curta (ex: "Sem despesas por aqui ainda") — confirmar copy na spec.
    - **Erro** (`AsyncError`): mensagem curta de falha seguindo o padrão dos outros cards do Home; sem toast invasivo (é seção passiva no Home).
    - **Sucesso** (`AsyncData`): lista com no máximo 4 itens renderizados.
    - Ícones e cores de categoria devem reutilizar qualquer mapa/enum visual já existente; se não existir, definir mapa `ExpenseCategory → IconData` + `ExpenseCategory → Color` no `presentation/` da feature e mantê-lo isolado.
    - Tipografia e cores via `context.typography` e `context.colors` (Material 3, flex_color_scheme).
    - Espaçamento e padding consistentes com os outros cards do Home.

</requirements>

---

<context-tools>
    ### Skills relevantes

    - `sdd` — **OBRIGATÓRIA**: criar spec antes de qualquer implementação.
    - `new-feature` — checklist de criação de feature end-to-end com todas as camadas.
    - `notifier` — padrão do Notifier (aqui usar a variante `AsyncNotifier` com `build()` async documentada no CLAUDE.md).
    - `arch-review` — validar dependências entre camadas ao final.
    - `new-test` — padrões de teste para response `fromJson`, Repository e Notifier.

    ### MCPs disponíveis

    - `context7` — verificar API atualizada de `flutter_riverpod` / `riverpod_annotation` (`AsyncNotifier`, `@riverpod`) e `intl` (formatação relativa).
    - `octocode` — referência de padrões de lista paginada Flutter + Riverpod se necessário.

</context-tools>

---

<workflow>
    1. Criar spec com `/sdd` cobrindo: novo domínio `Expense`, novas camadas, integração na `HomeScreen`, estados de UI (loading/vazio/erro/sucesso), e **aguardar aprovação**.
    2. Confirmar com o usuário pontos em aberto (badge de usuário no item, copy do estado vazio, formato de data relativa, tela "Ver tudo").
    3. Implementar **domain**: `ExpenseCategory`, `ExpenseModel`, `IExpenseRepository`.
    4. Implementar **infrastructure**: `EndpointKey.expenses`, `ExpenseResponse`, `PaginatedResponse<T>` (se não existir), `IRemoteExpenseDataSource` + `RemoteExpenseDataSource`.
    5. Implementar **data**: `ExpenseRepository` + `ExpenseResponseExtension.toModel()` (conversão de valor decimal → centavos, datas ISO → `DateTime`, `category` → `ExpenseCategory`).
    6. Implementar **presentation**: `RecentExpensesNotifier` (`AsyncNotifier`), `RecentExpensesSectionWidget`, `ExpenseItemWidget`.
    7. Registrar providers em `main/providers/expense_providers.dart` e injetar a seção na `HomeScreen`.
    8. Escrever testes (ver `<tests>`) em `test/src/`.
    9. Rodar `dart run build_runner build --delete-conflicting-outputs` → `flutter analyze` → `flutter test`.

</workflow>

<output>
    Arquivos criados/modificados (paths sujeitos à estrutura real do projeto — validar na spec):

    - `lib/src/domain/models/expense_model.dart`
    - `lib/src/domain/models/expense_category.dart`
    - `lib/src/domain/repositories/interface_expense_repository.dart`
    - `lib/src/infrastructure/clients/http/endpoints/endpoint_key.dart` (adicionar `expenses`)
    - `lib/src/infrastructure/clients/http/responses/expense/expense_response.dart`
    - `lib/src/infrastructure/clients/http/responses/paginated_response.dart` (se não existir)
    - `lib/src/infrastructure/datasources/remote_expense_data_source.dart`
    - `lib/src/data/repositories/expense_repository.dart`
    - `lib/src/data/extensions/expense_response_extension.dart`
    - `lib/src/presentation/screens/home/notifiers/recent_expenses_notifier.dart`
    - `lib/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_section_widget.dart`
    - `lib/src/presentation/screens/home/widgets/recent_expenses/expense_item_widget.dart`
    - `lib/src/presentation/screens/home/screens/home_screen.dart` (integração da seção)
    - `lib/src/main/providers/expense_providers.dart`
    - `test/src/infrastructure/responses/expense/expense_response_test.dart`
    - `test/src/data/extensions/expense_response_extension_test.dart`
    - `test/src/data/repositories/expense_repository_test.dart`
    - `test/src/presentation/screens/home/notifiers/recent_expenses_notifier_test.dart`
    - `test/mocks/mocks.dart` (adicionar `MockExpenseRepository`, `MockRemoteExpenseDataSource`)

</output>

<endpoints>
    ### Listar despesas

    - **URL:** `/api/v1/expenses`
    - **Método:** GET
    - **Auth:** Bearer token (já injetado pelo `IHttpClient`).
    - **Query params (opcionais, RQL):** filtros por `date` (lookups `eq, ge, le, gt, lt`) — ex: `ge(date,2026-03-01)`. **Não necessário na primeira versão** (usar primeira página + slice `take(4)`).
    - **Status codes:** 200 OK, 400 Bad Request, 401 Unauthorized, 500.
    - **Response 200 (resumido):**
      ```json
      {
        "next": "http://.../expenses?cursor=...",
        "previous": null,
        "results": [
          {
            "id": 129,
            "value": "85.50",
            "description": "Cafezinho com o meu amor",
            "date": "2026-04-15",
            "created_at": "2026-04-22T11:45:03.220605-03:00",
            "category": "food"
          }
        ]
      }
      ```
    - **Response erro (padrão backend):**
      ```json
      { "errors": [ { "field": "string", "message": "string", "code": "string" } ] }
      ```

</endpoints>

<tests>
    ### ExpenseResponse.fromJson (Dart puro)

    - JSON válido → todos os campos mapeados corretamente (strings preservadas; datas e centavos **não** convertidos aqui — isso é na extension).
    - Campo `category` desconhecido → preserva string (conversão para enum é responsabilidade da extension).

    ### ExpenseResponseExtension.toModel (Dart puro)

    - `"85.50"` → `8550` centavos; `"1200.00"` → `120000`; `"19.24"` → `1924`.
    - `date: "2026-04-15"` → `DateTime(2026, 04, 15)`.
    - `created_at: "2026-04-22T11:45:03.220605-03:00"` → `DateTime` equivalente em UTC/local conforme decidido na spec.
    - `category: "food"` → `ExpenseCategory.food`; categoria desconhecida → `ExpenseCategory.unknown`.

    ### ExpenseRepository (mock em `IHttpClient`)

    - Sucesso (200 com `results`) → `Right(List<ExpenseModel>)` com itens mapeados e `length <= 4` quando `limit: 4`.
    - Sucesso com `results: []` → `Right([])`.
    - Erro 401 → `Left(NetworkFailure)` (conforme mapeamento padrão).
    - Erro 400 com body de `FailureResponse` → `Left(ValidationFailure)`.
    - Erro 500 → `Left(ServerFailure)`.
    - Exception inesperada (único try/catch no Client) → `Left(UnknownFailure)`.

    ### RecentExpensesNotifier (mock em `IExpenseRepository`, `ProviderContainer`)

    - `build()` com sucesso → `AsyncData(List<ExpenseModel>)` com tamanho `<= 4`.
    - `build()` com repositório retornando `Left(NetworkFailure)` → `AsyncError`.
    - `build()` com lista vazia → `AsyncData([])`.
    - Descrições de teste **em inglês**; `group` por método/cenário; sem mock de `IHttpClient` neste nível.

</tests>

---

<critical>
    ### Skills obrigatórias

    - `sdd` — **OBRIGATÓRIA**: criar a spec antes de qualquer linha de código.
    - `new-feature` — checklist de nova feature (todas as camadas).
    - `notifier` — padrão do `AsyncNotifier` (build async, `late` sem `final`, dependências via `ref.watch`).
    - `new-test` — padrões de teste (estratégia de mock por camada, descrições em inglês).
    - `arch-review` — validar dependências entre camadas antes de considerar pronto.

    ### Fora do Escopo

    - *NÃO* implementar a tela de lista completa de despesas ("Ver tudo") — apenas deixar o botão preparado. Confirmar com o usuário antes de criar `ExpensesLocation`/`ExpensesScreen`.
    - *NÃO* implementar criação, edição ou exclusão de despesa — apenas leitura das mais recentes.
    - *NÃO* implementar filtros RQL por data na primeira versão — usar primeira página + `take(4)`.
    - *NÃO* alterar o backend Django nem propor novos endpoints.
    - *NUNCA* usar `ConsumerWidget` — apenas `StatelessWidget` + `Consumer` interno.
    - *NUNCA* usar `var` — sempre `final` com tipo inferível, ou tipo explícito quando agrega legibilidade.
    - *NUNCA* usar switch statement — apenas switch expression (dispatch, `ref.listen`, mapeamento de failure, `AsyncValue`).
    - *NUNCA* declarar campos como `late final` no Notifier — apenas `late` (re-execução de `build()` pelo Riverpod).
    - *NUNCA* instanciar dependências (validators, repositories) diretamente no Notifier — tudo via `ref.watch` em `main/providers/`.
    - *NÃO* criar widgets privados (`class _FooWidget`) dentro de arquivos de widget — extrair para arquivo próprio, ou método privado para widget trivial.
    - *NÃO* adicionar método `toModel()` em `ExpenseResponse` — mapping **apenas** em `data/extensions/expense_response_extension.dart`.
    - *NÃO* usar DTOs de infraestrutura (`XxxRequest`) em interfaces de datasource — aceitar primitivos de domínio.
    - *NÃO* adicionar `try-catch` fora do `IHttpClient` (Datasource só deserializa; Repository só mapeia `Failure`).
    - *NÃO* adicionar comentários explicativos — código autoexplicativo por nome.
    - *NÃO* nomear variáveis de `result` ou `either` — usar `data`, `failure`, `state`, ou o conceito que representa.
    - *NÃO* expandir escopo além do descrito sem perguntar antes.

</critical>
