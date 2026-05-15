# Proposal: riverpod-lint-adoption

## Intenção

Habilitar `riverpod_lint` no projeto via o novo sistema de plugins (`analysis_server_plugin`) introduzido em Dart 3.10 (Flutter 3.38). Registrar o plugin em `analysis_options.yaml` como bloco `plugins:` de topo. Nenhuma mudança em código de produção.

## Motivação

O app já usa **5 family providers** (parâmetros no `build` do notifier):

| Notifier | Parâmetro |
|---|---|
| `ExpenseByIdNotifier` | `int id` |
| `ExpenseNotifier` (form) | `int? id` |
| `BudgetByIdNotifier` | `int id` |
| `BudgetFormNotifier` | `int? id` |
| `ExpensesFiltersNotifier` | `ExpenseFilterModel seed` |

`ExpenseFilterModel` é `Equatable` hoje, então o cache do Riverpod identifica filtros iguais corretamente. Mas:

- Se alguém remover `extends Equatable` num refactor inocente, o cache passa a tratar cada instância como provider diferente → memory leak + state perdido. Bug silencioso, sem stacktrace.
- Toda nova family que entrar precisa garantir que o parâmetro override `==`. Code review humano não pega de forma confiável.
- A regra `provider_parameters` do `riverpod_lint` flagra exatamente esse cenário em tempo de análise.

Outras regras que agregam pro padrão MVI do projeto:

- `avoid_public_notifier_properties` — pega campo público mutável no notifier (state deve fluir sempre via `state.copyWith`).
- `notifier_extends` — pega `Notifier` vs `AsyncNotifier` errado (fácil de errar com codegen quando o `build` muda de síncrono pra async).
- `functional_ref` / `notifier_build` — pegadinhas de assinatura de `build` em codegen.
- `only_use_keep_alive_inside_keep_alive` — pega `keepAlive: true` provider observando provider auto-dispose (mantém o auto-dispose vivo transitivamente). **Desabilitada nesta spec — ver "Decisões de design" #6.**

## Camadas afetadas

- `analysis_options.yaml` — adicionar bloco `plugins:` de topo com `riverpod_lint` e o `diagnostics:` desabilitando regra que conflita com padrão atual.

Sem mudança em `pubspec.yaml`, `lib/`, `test/`, ou `build.yaml`. Sem CI — `.github/workflows/` hoje só tem `android-release.yml`.

## Fora do escopo

- **CI**: adicionar step de `flutter analyze` num workflow novo — não há workflow de checks hoje; é spec separada.
- **Lints customizados próprios** (sem `ConsumerWidget`, `late` sem `final` em `build`, services só via notifier, encapsulamento de feature). Escrever lint plugin próprio é projeto autônomo — se virar dor recorrente, abrimos spec depois.
- **Revisar wiring de `keepAlive` notifiers × repositories auto-dispose** — flagrado pela regra `only_use_keep_alive_inside_keep_alive`, mas refactor não-trivial. Spec separada futura. Regra desabilitada com TODO referenciando essa decisão.
- **Limpar `unused_import` pré-existente** em `test/src/presentation/providers/recent_expenses_notifier_test.dart` — aparece duplicado quando o plugin está ativo (efeito colateral do echo de diagnostics). Pré-existe à spec; cleanup separado.

## Decisões de design

1. **Usar o sistema novo (`analysis_server_plugin`), não `custom_lint`.**
   Descoberto durante implementação: `riverpod_lint ^3.1.x` migrou para `analysis_server_plugin` direto e não depende mais de `custom_lint`. O bloco `plugins:` é top-level (não `analyzer.plugins`), e a versão do plugin é declarada inline ali — não vai em `dev_dependencies`. O analyzer baixa o plugin transparentemente via `dart pub upgrade` num workspace sintético. `dart analyze` e `flutter analyze` rodam o plugin junto com a análise padrão — não há CLI separada como `dart run custom_lint`.

2. **Versão pinada em `^3.1.3`.**
   Linha 3.1.x alinha com `flutter_riverpod ^3.3.1` e `riverpod_generator ^4.0.3` (analyzer ^9.0.0). Versões 3.1.4-dev exigem analyzer ^12.0.0, fora do Dart SDK atual.

3. **`plugins:` é top-level, fora de `analyzer:`.**
   Conforme [docs do Dart SDK](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md): "Analyzer plugins are specified in the top-level `plugins` section". A documentação enfatiza que o legado sob `analyzer.plugins` é diferente.

4. **Nenhuma regra é desabilitada upfront, exceto a flagrada na auditoria.**
   `only_use_keep_alive_inside_keep_alive` apareceu em 3 sites (clients_provider.dart, notification_lifecycle_provider.dart, expenses_notifier.dart). Os 3 são padrões correntes do projeto onde notifiers `keepAlive: true` observam repositories `@Riverpod()` (auto-dispose). Refactor para tornar consistente exigiria propagar `keepAlive: true` por toda a camada de repos/datasources, ou converter notifiers para auto-dispose — decisão de design não-trivial. Desabilitar com TODO inline no `analysis_options.yaml`.

5. **Suprimir regra via `plugins.<name>.diagnostics: { <rule>: false }`.**
   Sintaxe oficial do novo sistema. `analyzer.errors: { rule: ignore }` **não funciona** para diagnostics de plugin — o analyzer reporta `unrecognized_error_code` (validado durante implementação).

6. **CLAUDE.md sem mudança.**
   `flutter analyze` já é o comando documentado. O plugin roda junto automaticamente — não há comando adicional pra documentar.

7. **Sem hook git, sem pre-commit.**
   O projeto não tem hooks hoje. Adicionar pre-commit pra rodar `flutter analyze` é decisão separada (mexe em fluxo de outros devs / Codex).

8. **Sem mudança no `build.yaml`.**
   `analysis_server_plugin` roda em isolate separado do analyzer, ortogonal ao `build_runner`. A spec anterior (`build.yaml` scoped) continua valendo.

9. **Critério de "pronto" é `flutter analyze` rodando com apenas warnings pré-existentes.**
   A auditoria do código existente sugeria conformidade — após habilitar, 3 warnings novos apareceram e foram suprimidos via `diagnostics: false` com TODO. Estado final: `flutter analyze` reporta o mesmo `unused_import` pré-spec (agora duplicado por causa do plugin echo, mas a issue subjacente é a mesma).
