# Spec — standardize-domain-enums

## Context

O domínio tem hoje 5 enums vivendo em `lib/src/domain/models/`:

- `ExpenseCategory` (`expense/expense_category.dart`)
- `ExpenseOrdering` (`expense/expense_ordering.dart`)
- `ExpensePeriodPreset` (`expense/expense_period_preset.dart`) + typedef `ExpensePeriodRange`
- `InsightSeverity` (`insight/insight_severity.dart`)
- `InsightType` (`insight/insight_type.dart`)

Nenhum deles usa o sufixo `Model`, que no codebase denota classe de dados com `copyWith` + `Equatable`. Enums são *classifications* / domain primitives — uma abstração diferente (conjunto fechado de valores, possivelmente com campos e métodos), e conflatar ambas sob a mesma pasta e o mesmo sufixo viola a distinção semântica esperada em Clean Architecture / SOLID.

Esta spec move os 5 enums para uma nova raiz `lib/src/domain/enums/<feature>/`, renomeia classe e arquivo com sufixo `Enum`, e atualiza todos os ~35 arquivos consumidores (presentation, tests, previews). O typedef `ExpensePeriodRange` permanece no mesmo arquivo do `ExpensePeriodPresetEnum` porque é um detalhe de retorno do método `toRange()` e não tem vida independente.

Nenhuma lógica de enum é alterada — valores, campos, métodos (`fromString`, `toRange`, etc.) e assinaturas de `copyWith`/`Equatable` em models consumidores permanecem idênticos.

---

## Requirements

### Requirement: Nova raiz `domain/enums/`

The system SHALL criar a pasta `lib/src/domain/enums/` com subpastas por feature (`expense/`, `insight/`). A pasta SHALL ser irmã de `domain/models/`, `domain/repositories/`, `domain/services/`, `domain/validators/` e `domain/failures/`.

The system SHALL NOT mover nenhum outro conteúdo atualmente em `domain/models/` — apenas os 5 enums listados nesta spec.

#### Scenario: Estrutura resultante
Given a refatoração concluída
When `ls lib/src/domain/enums/` é executado
Then aparecem duas subpastas: `expense/` e `insight/`

When `ls lib/src/domain/models/expense/` é executado
Then os arquivos `expense_category.dart`, `expense_ordering.dart`, `expense_period_preset.dart` não existem mais

When `ls lib/src/domain/models/insight/` é executado
Then os arquivos `insight_severity.dart`, `insight_type.dart` não existem mais

---

### Requirement: Renomeação de `ExpenseCategory`

The system SHALL mover `lib/src/domain/models/expense/expense_category.dart` para `lib/src/domain/enums/expense/expense_category_enum.dart`.

The system SHALL renomear o enum `ExpenseCategory` para `ExpenseCategoryEnum`. Valores (`food`, `debt`, `health`, `unknown`, `housing`, `shopping`, `transport`, `entertainment`) e o método estático `fromString` SHALL permanecer idênticos em assinatura e comportamento. O tipo de retorno de `fromString` passa a ser `ExpenseCategoryEnum`.

The system SHALL atualizar todas as referências no codebase:
- Tipo da variável / parâmetro / campo: `ExpenseCategory` → `ExpenseCategoryEnum`
- Referência a valores: `ExpenseCategory.food` → `ExpenseCategoryEnum.food` (e análogos)
- Imports: `package:trocado/src/domain/models/expense/expense_category.dart` → `package:trocado/src/domain/enums/expense/expense_category_enum.dart`

Arquivos afetados:
- `lib/src/domain/models/expense/expense_model.dart` (campo `category`)
- `lib/src/domain/models/expense/expense_filter_model.dart` (campo `category`)
- `lib/src/presentation/widgets/expense/expense_category_visual_extension.dart` (extension target)
- `lib/src/presentation/screens/expense/widgets/expense_category_field_widget.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_state.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_category_section_widget.dart`
- `lib/src/presentation/preview/mocks/expense/expense_item_mock.dart`
- Testes listados no requirement **Testes atualizados**

#### Scenario: Nenhuma referência ao símbolo antigo
Given a refatoração concluída
When `grep -rn "\bExpenseCategory\b" lib test --include="*.dart"` é executado
Then zero resultados (apenas `ExpenseCategoryEnum` aparece)

---

### Requirement: Renomeação de `ExpenseOrdering`

The system SHALL mover `lib/src/domain/models/expense/expense_ordering.dart` para `lib/src/domain/enums/expense/expense_ordering_enum.dart`.

The system SHALL renomear o enum `ExpenseOrdering` para `ExpenseOrderingEnum`. Valores (`dateAsc`, `valueAsc`, `dateDesc`, `valueDesc`), campos (`query`, `label`) e construtor SHALL permanecer idênticos.

The system SHALL atualizar todas as referências:
- Tipo e valores: `ExpenseOrdering` → `ExpenseOrderingEnum`, `ExpenseOrdering.valueDesc` → `ExpenseOrderingEnum.valueDesc`
- Imports atualizados para o novo caminho

Arquivos afetados:
- `lib/src/domain/models/expense/expense_filter_model.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_state.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_ordering_section_widget.dart`
- Testes

#### Scenario: Nenhuma referência ao símbolo antigo
Given a refatoração concluída
When `grep -rn "\bExpenseOrdering\b" lib test --include="*.dart"` é executado
Then zero resultados

---

### Requirement: Renomeação de `ExpensePeriodPreset` e typedef junto

The system SHALL mover `lib/src/domain/models/expense/expense_period_preset.dart` para `lib/src/domain/enums/expense/expense_period_preset_enum.dart`.

The system SHALL renomear o enum `ExpensePeriodPreset` para `ExpensePeriodPresetEnum`. Valores (`custom`, `currentMonth`, `previousMonth`, `last30Days`), campo `label`, construtor e método `toRange({required DateTime now})` SHALL permanecer idênticos em assinatura e comportamento.

The system SHALL manter o typedef `ExpensePeriodRange` no **mesmo arquivo** do enum (`expense_period_preset_enum.dart`), no topo do arquivo, sem alterar sua definição (`({int startDate, int endDate})`).

The system SHALL NOT criar arquivo separado para o typedef.

The system SHALL atualizar todas as referências:
- Tipo e valores do enum: `ExpensePeriodPreset` → `ExpensePeriodPresetEnum`
- Typedef: `ExpensePeriodRange` permanece com o mesmo nome (sem sufixo `Enum`, não é enum)
- Imports atualizados para o novo caminho — arquivos que usam *apenas* o typedef também passam a importar de `domain/enums/expense/expense_period_preset_enum.dart`

Arquivos afetados:
- `lib/src/domain/models/expense/expense_filter_model.dart` (se usar o preset/range)
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_state.dart`
- `lib/src/presentation/screens/expenses/screens/expenses_filter_screen.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_period_section_widget.dart`
- Testes

#### Scenario: Nenhuma referência ao símbolo antigo
Given a refatoração concluída
When `grep -rn "\bExpensePeriodPreset\b" lib test --include="*.dart"` é executado
Then zero resultados

When `grep -rn "\bExpensePeriodRange\b" lib test --include="*.dart"` é executado
Then resultados existem (typedef preservado), todos importando de `domain/enums/expense/expense_period_preset_enum.dart`

---

### Requirement: Renomeação de `InsightSeverity`

The system SHALL mover `lib/src/domain/models/insight/insight_severity.dart` para `lib/src/domain/enums/insight/insight_severity_enum.dart`.

The system SHALL renomear o enum `InsightSeverity` para `InsightSeverityEnum`. Valores (`info`, `danger`, `warning`, `unknown`) e método `fromString` SHALL permanecer idênticos.

The system SHALL atualizar todas as referências:
- Tipo e valores: `InsightSeverity` → `InsightSeverityEnum`
- Imports atualizados

Arquivos afetados:
- `lib/src/domain/models/insight/insight_model.dart`
- `lib/src/presentation/screens/home/widgets/insights/insight_card_widget.dart`
- `lib/src/presentation/screens/home/widgets/insights/insight_icon_widget.dart`
- `lib/src/presentation/screens/home/widgets/insights/insights_carousel_loading_widget.dart` (se aplicável)
- Testes

#### Scenario: Nenhuma referência ao símbolo antigo
Given a refatoração concluída
When `grep -rn "\bInsightSeverity\b" lib test --include="*.dart"` é executado
Then zero resultados

---

### Requirement: Renomeação de `InsightType`

The system SHALL mover `lib/src/domain/models/insight/insight_type.dart` para `lib/src/domain/enums/insight/insight_type_enum.dart`.

The system SHALL renomear o enum `InsightType` para `InsightTypeEnum`. Valores (`unknown`, `topCategory`, `dailyAverage`, `willOverspend`, `budgetUtilization`) e método `fromString` SHALL permanecer idênticos.

The system SHALL atualizar todas as referências:
- Tipo e valores: `InsightType` → `InsightTypeEnum`
- Imports atualizados

Arquivos afetados:
- `lib/src/domain/models/insight/insight_model.dart`
- `lib/src/presentation/screens/home/widgets/insights/insight_card_widget.dart` (se aplicável)
- `lib/src/presentation/screens/home/widgets/insights/insight_icon_widget.dart`
- Testes

#### Scenario: Nenhuma referência ao símbolo antigo
Given a refatoração concluída
When `grep -rn "\bInsightType\b" lib test --include="*.dart"` é executado
Then zero resultados

---

### Requirement: Testes atualizados e renomeados

The system SHALL renomear os arquivos de teste para espelhar o novo nome do arquivo de produção, mantendo-os sob `test/src/domain/` mas na subárvore `enums/<feature>/`. Inclui a correção do caminho de `expense_category_test.dart`, hoje solto em `test/src/domain/models/` sem subpasta `expense/`:

| Arquivo atual | Novo arquivo |
|---|---|
| `test/src/domain/models/expense_category_test.dart` | `test/src/domain/enums/expense/expense_category_enum_test.dart` |
| `test/src/domain/models/expense/expense_ordering_test.dart` | `test/src/domain/enums/expense/expense_ordering_enum_test.dart` |
| `test/src/domain/models/expense/expense_period_preset_test.dart` | `test/src/domain/enums/expense/expense_period_preset_enum_test.dart` |

The system SHALL criar testes dedicados novos para `InsightSeverityEnum` e `InsightTypeEnum`, cobrindo o método `fromString` (valores válidos e fallback para `unknown`):

- `test/src/domain/enums/insight/insight_severity_enum_test.dart`
- `test/src/domain/enums/insight/insight_type_enum_test.dart`

The system SHALL atualizar imports, declarações de tipo e valores em todos os demais arquivos de teste que referenciam os símbolos renomeados:
- `test/src/data/repositories/expense_repository_test.dart`
- `test/src/data/repositories/insights_repository_test.dart`
- `test/src/domain/models/expense/expense_filter_model_test.dart`
- `test/src/infrastructure/clients/http/requests/expense_filter_rql_builder_test.dart`
- `test/src/infrastructure/responses/insights_response_test.dart`
- `test/src/presentation/providers/expense_notifier_test.dart`
- `test/src/presentation/providers/expenses_filters_notifier_test.dart`
- `test/src/presentation/providers/expenses_notifier_test.dart`
- `test/src/presentation/providers/insights_notifier_test.dart`
- `test/src/presentation/providers/recent_expenses_notifier_test.dart`
- `test/src/presentation/screens/expenses/data/expense_groups_builder_test.dart`

The system SHALL manter todas as descrições de `test()` e `group()` inalteradas. Apenas tipos e imports mudam.

#### Scenario: Suite passa sem regressão
Given a refatoração concluída
When `flutter test` é executado
Then zero falhas, zero erros de compilação

#### Scenario: Nomes de arquivo refletem símbolo
Given os três testes renomeados
When inspecionados
Then o nome do arquivo termina em `_enum_test.dart` e a subpasta é `enums/<feature>/`

---

### Requirement: Lógica preservada

The system SHALL NOT alterar:
- Valores dos enums, ordem de declaração, nem campos/construtores
- Corpo dos métodos `fromString` / `toRange`
- Definição do typedef `ExpensePeriodRange`
- Assinaturas de `copyWith`, `Equatable.props` ou qualquer outra API pública dos models consumidores (`ExpenseModel`, `ExpenseFilterModel`, `InsightModel`)

#### Scenario: Diff semântico mínimo
Given a refatoração concluída
When `git diff` é inspecionado
Then nenhuma mudança além de: nome da classe (`+Enum`), caminho do arquivo (`models/` → `enums/` e `+_enum`), e uso do novo símbolo/import nos consumidores

---

### Requirement: Compilação verde e analyzer limpo

The system SHALL garantir que `flutter analyze` não reporta erros novos ou warnings relacionados à renomeação.

The system SHALL rodar `dart run build_runner build --delete-conflicting-outputs` caso qualquer arquivo `.g.dart` dependa de imports modificados (ex: notifiers Riverpod).

#### Scenario: Analyze limpo
Given a refatoração concluída
When `flutter analyze` é executado
Then zero erros e zero novos warnings (baseline pré-refatoração mantido)

---

## Files

### Delete

- `lib/src/domain/models/expense/expense_category.dart`
- `lib/src/domain/models/expense/expense_ordering.dart`
- `lib/src/domain/models/expense/expense_period_preset.dart`
- `lib/src/domain/models/insight/insight_severity.dart`
- `lib/src/domain/models/insight/insight_type.dart`
- `test/src/domain/models/expense_category_test.dart` (movido)
- `test/src/domain/models/expense/expense_ordering_test.dart` (movido)
- `test/src/domain/models/expense/expense_period_preset_test.dart` (movido)

### Create

- `lib/src/domain/enums/expense/expense_category_enum.dart`
- `lib/src/domain/enums/expense/expense_ordering_enum.dart`
- `lib/src/domain/enums/expense/expense_period_preset_enum.dart` (inclui typedef `ExpensePeriodRange`)
- `lib/src/domain/enums/insight/insight_severity_enum.dart`
- `lib/src/domain/enums/insight/insight_type_enum.dart`
- `test/src/domain/enums/expense/expense_category_enum_test.dart`
- `test/src/domain/enums/expense/expense_ordering_enum_test.dart`
- `test/src/domain/enums/expense/expense_period_preset_enum_test.dart`
- `test/src/domain/enums/insight/insight_severity_enum_test.dart` (novo — cobre `fromString`)
- `test/src/domain/enums/insight/insight_type_enum_test.dart` (novo — cobre `fromString`)

### Modify (consumidores — imports + símbolos)

**Domain (models consumidores):**
- `lib/src/domain/models/expense/expense_model.dart`
- `lib/src/domain/models/expense/expense_filter_model.dart`
- `lib/src/domain/models/insight/insight_model.dart`

**Presentation:**
- `lib/src/presentation/widgets/expense/expense_category_visual_extension.dart`
- `lib/src/presentation/screens/expense/widgets/expense_category_field_widget.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_filters_state.dart`
- `lib/src/presentation/screens/expenses/notifiers/expenses_notifier.dart`
- `lib/src/presentation/screens/expenses/screens/expenses_filter_screen.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_category_section_widget.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_ordering_section_widget.dart`
- `lib/src/presentation/screens/expenses/widgets/filter/expenses_filter_period_section_widget.dart`
- `lib/src/presentation/screens/expenses/preview/screens/expenses_screen_preview.dart`
- `lib/src/presentation/screens/home/widgets/insights/insight_card_widget.dart`
- `lib/src/presentation/screens/home/widgets/insights/insight_icon_widget.dart`
- `lib/src/presentation/screens/home/widgets/insights/insights_carousel_loading_widget.dart`
- `lib/src/presentation/preview/mocks/expense/expense_item_mock.dart`

**Tests:**
- `test/src/data/repositories/expense_repository_test.dart`
- `test/src/data/repositories/insights_repository_test.dart`
- `test/src/domain/models/expense/expense_filter_model_test.dart`
- `test/src/infrastructure/clients/http/requests/expense_filter_rql_builder_test.dart`
- `test/src/infrastructure/responses/insights_response_test.dart`
- `test/src/presentation/providers/expense_notifier_test.dart`
- `test/src/presentation/providers/expenses_filters_notifier_test.dart`
- `test/src/presentation/providers/expenses_notifier_test.dart`
- `test/src/presentation/providers/insights_notifier_test.dart`
- `test/src/presentation/providers/recent_expenses_notifier_test.dart`
- `test/src/presentation/screens/expenses/data/expense_groups_builder_test.dart`

### Unchanged

- `lib/src/presentation/widgets/expense/expense_item_widget.dart` (apenas importa `expense_category_visual_extension.dart` — import transitivo, não precisa mudar)
- Qualquer enum fora de `domain/` (`FailureCodeResponse`, `StorageKey`, `EndpointKey`, `*Status`, `*Constant`, `*Kind`, `*Type` em presentation/infrastructure)
- Todos os models reais em `domain/models/` (`ExpenseModel`, `BudgetModel`, `InsightModel`, etc.) mantêm o sufixo `Model` e o caminho atual
- Repositórios, datasources, clients, services, validators — zero mudança
- API REST, wire format, endpoints — zero mudança

---

## Out of scope

- Renomear enums em outras camadas (presentation/infrastructure) — não sofrem a mesma confusão semântica (são `Status`, `Kind`, `Constant` — nomes já distintos de `Model`).
- Refatorar a lógica interna dos enums (método `fromString`, `toRange`, etc.).
- Promover o typedef `ExpensePeriodRange` a classe com `Equatable` — fora do escopo e overkill para um record de 2 campos.
- Padronização do sufixo `Model` em outros symbols de `domain/` fora dos 5 enums.
- Qualquer mudança em contratos de repositório, datasource ou API.
