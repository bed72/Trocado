# Exemplo: Prompt Base vs Prompt Estruturado

## Prompt Base (entrada típica)

```
Cria a tela de criação de despesa. O usuário preenche descrição, valor, categoria e data.
Tem que validar os campos antes de salvar. Quando salvar com sucesso, volta pra tela anterior.
Temos uma API REST pra criar a despesa — POST /expenses.
```

## Problemas do prompt base

- Não define papel do agente nem a stack
- Requisitos misturados (business, técnico, UI)
- Sem especificação de endpoint (payload, status codes)
- Sem menção a skills do projeto
- Sem definição de fora do escopo
- UI/UX vago: sem loading, sem erros, sem feedback
- Não menciona camadas (Notifier, Repository, DataSource)
- Não menciona `/sdd` como pré-requisito

---

## Prompt Estruturado (saída esperada)

<task>Implementar tela de criação de despesa com validação de formulário e integração com API REST</task>

<goals>
    Criar a feature de expense creation completa — validação de formulário, chamada ao endpoint POST /expenses via Dio, e navegação de volta ao Home após sucesso.
</goals>

<role>
    Você é um engenheiro Flutter senior trabalhando no app Trocado (controle financeiro para casais).
    Stack: Flutter, Dart, Riverpod (MVI com sealed Intent + dispatch), Dio, duck_router, Clean Architecture (domain/data/infrastructure/presentation/main).
    Sua tarefa é implementar a feature de criação de despesa do zero, respeitando todas as convenções do projeto.
</role>

---

<requirements>
    ### Business

    - Usuário preenche: descrição, valor (monetário em centavos), categoria e data da despesa
    - Campos são validados antes do envio — erros exibidos inline nos campos
    - Ao salvar com sucesso, o usuário retorna à tela anterior
    - Ao falhar, exibir toast de erro sem limpar o formulário

    ### Technical

    - **domain**: `ExpenseModel` com `copyWith`; `IExpenseRepository` com `create`
    - **infrastructure**: `CreateExpenseRequest` com `toJson()`; `ExpenseResponse` com `fromJson()`; `IRemoteExpenseDataSource` retornando `Either<FailureResponse, ExpenseResponse>`
    - **data**: `ExpenseRepository` implementando `IExpenseRepository`; extension `ExpenseResponseExtension.toModel()`
    - **presentation**: `ExpenseState` + `ExpenseIntent` (sealed) + `ExpenseNotifier` (MVI com `dispatch`) + `ExpenseScreen` + widgets
    - **main**: providers em `main/providers/`; `ExpenseLocation` em `main/locations/`
    - Fluxo: `ExpenseNotifier` → `IExpenseRepository` → `IRemoteExpenseDataSource` → `IHttpClient` (Dio)
    - Valor monetário: `int` em centavos no app; `String` decimal na API (ex: `"85.50"`)

    ### UI/UX

    - Loading: botão de salvar exibe indicador e fica desabilitado durante a requisição
    - Erro de validação: exibido inline abaixo de cada campo via `failure` nos widgets
    - Erro de rede/servidor: toast com tipo `ToastConstant.failure`
    - Sucesso: `context.pop()` imediato
    - Teclado: descartar ao submeter via `hideKeyboard()`

</requirements>

---

<context-tools>
    ### Skills relevantes

    - `sdd` — criar spec antes de qualquer implementação
    - `notifier` — estrutura do Notifier MVI com sealed Intent + dispatch
    - `validator` — criação dos validators de formulário
    - `new-feature` — checklist de nova feature
    - `new-test` — padrões de teste para Notifier e Repository

    ### MCPs disponíveis

    - `context7` — verificar API do Riverpod ou Dio antes de implementar
    - `octocode` — exemplos de formulários Flutter com validação

</context-tools>

---

<workflow>
    1. Criar spec com `/sdd` e aguardar aprovação
    2. Implementar camada domain: `ExpenseModel` e `IExpenseRepository`
    3. Implementar camada infrastructure: request, response, datasource
    4. Implementar camada data: repositório e extension de mapping
    5. Implementar camada presentation: state, intent, notifier, screen, widgets
    6. Registrar providers em `main/providers/` e location em `main/locations/`
    7. Rodar `flutter analyze && flutter test`
</workflow>

<output>
    Arquivos criados/modificados:
    - `domain/models/expense_model.dart`
    - `domain/repositories/interface_expense_repository.dart`
    - `infrastructure/clients/http/requests/expense/create_expense_request.dart`
    - `infrastructure/clients/http/responses/expense/expense_response.dart`
    - `infrastructure/datasources/remote_expense_data_source.dart`
    - `data/repositories/expense_repository.dart`
    - `data/extensions/expense_response_extension.dart`
    - `presentation/screens/expense/notifiers/expense_state.dart`
    - `presentation/screens/expense/notifiers/expense_intent.dart`
    - `presentation/screens/expense/notifiers/expense_notifier.dart`
    - `presentation/screens/expense/screens/expense_screen.dart`
    - `presentation/screens/expense/widgets/` (widgets de campo)
    - `main/providers/expense_providers.dart`
    - `main/locations/expense_location.dart`
</output>

<endpoints>
    ### Criar despesa

    - **URL:** `/expenses`
    - **Método:** POST
    - **Status codes:** 201 Created, 400 Bad Request, 401 Unauthorized
    - **Payload:** `{ "description": string, "amount": string (decimal), "category": int, "date": string (ISO 8601) }`

</endpoints>

<tests>
    ### ExpenseNotifier

    - Submeter formulário válido → estado muda para loading → sucesso → status success
    - Submeter formulário com campos inválidos → erros inline, sem chamada ao repositório
    - Falha de rede → estado failure com mensagem, formulário mantido

    ### ExpenseRepository

    - Sucesso na criação → retorna `Right(ExpenseModel)`
    - Erro 400 → retorna `Left(ValidationFailure)`
    - Erro 401 → retorna `Left(NetworkFailure)`

    ### ExpenseResponse fromJson

    - JSON válido → todos os campos mapeados corretamente
    - Valor decimal `"85.50"` → `8550` centavos após `toModel()`

</tests>

---

<critical>
    ### Skills obrigatórias

    - `sdd` — **OBRIGATÓRIA**: criar spec antes de qualquer linha de código
    - `notifier` — para estrutura do Notifier MVI
    - `validator` — para validators de formulário

    ### Fora do Escopo

    - *NÃO* implementar edição de despesa — apenas criação
    - *NUNCA* usar `ConsumerWidget` — apenas `StatelessWidget` + `Consumer` interno
    - *NUNCA* usar `var` — tipos explícitos ou inferência clara com `final`
    - *NÃO* criar widgets privados dentro de arquivos de widget — extrair para arquivo próprio
    - *NÃO* criar endpoints no backend — apenas consumir a API existente

</critical>
