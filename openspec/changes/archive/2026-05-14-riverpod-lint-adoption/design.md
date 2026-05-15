# Design: riverpod-lint-adoption

## Arquivos tocados

| Arquivo | Tipo de mudança |
|---|---|
| `analysis_options.yaml` | adicionar bloco `plugins:` de topo |

Nenhum arquivo de `lib/`, `test/`, `pubspec.yaml`, `build.yaml`, ou `.github/` é modificado. **Notar**: spec anterior previa adição em `pubspec.yaml` via `dev_dependencies` — descartada após descobrir que `riverpod_lint 3.1.x` migrou para o novo sistema `analysis_server_plugin`, onde o plugin é declarado e versionado inline em `analysis_options.yaml`.

---

## `analysis_options.yaml`

Estado atual:

```yaml
analyzer:
  exclude:
    - lib/firebase_options.dart
  errors:
    library_private_types_in_public_api: ignore
    use_build_context_synchronously: ignore

include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: false
    prefer_single_quotes: true
```

Adicionar bloco `plugins:` no topo (fora de `analyzer:`):

```yaml
plugins:
  riverpod_lint:
    version: ^3.1.3
    diagnostics:
      # TODO: revisar wiring de keepAlive notifiers x repositories auto-dispose em spec separada.
      # Hoje notifiers keepAlive (ex: ExpensesNotifier) observam repos auto-dispose, o que mantém
      # os repos vivos transitivamente. Decisão: marcar repos/datasources como keepAlive: true
      # consistentemente, ou aceitar o padrão atual e manter este rule desabilitado.
      only_use_keep_alive_inside_keep_alive: false
```

Resto do arquivo permanece idêntico. `analyzer:`, `include:`, `linter:` ficam exatamente como estão.

---

## Como funciona o sistema `analysis_server_plugin`

Pra contexto futuro (referência da [doc oficial do Dart SDK](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md)):

- Plugin é declarado em **bloco `plugins:` de topo** no `analysis_options.yaml`, não dentro de `analyzer.plugins:` (legado).
- A versão é especificada **inline ali** — não vai em `pubspec.yaml`.
- O analyzer cria um workspace sintético, resolve via `dart pub upgrade` num isolate separado, e injeta os diagnósticos no `dart analyze` / `flutter analyze` / IDE.
- Disponível a partir de **Dart 3.10 (Flutter 3.38)**. Versão do projeto: `sdk: ^3.10.0` em `pubspec.yaml` — confirmado compatível.
- Plugin diagnostics emitem códigos próprios. `dart analyze` lista no formato `arquivo:linha:coluna • <rule_name>`.

### Suprimir regras

| Granularidade | Sintaxe |
|---|---|
| Projeto inteiro | `plugins.riverpod_lint.diagnostics: { rule_name: false }` |
| Arquivo | `// ignore_for_file: riverpod_lint/rule_name` no topo |
| Linha | `// ignore: riverpod_lint/rule_name` na linha anterior |

`analyzer.errors: { rule_name: ignore }` **não funciona** para diagnostics emitidos por plugins — o analyzer trata como `unrecognized_error_code` (validado em runtime durante implementação).

### Restart obrigatório após mudar `plugins:`

Conforme docs: "After any change is made to the `plugins` section of an `analysis_options.yaml` file, the Dart Analysis Server must be restarted to see the effects." Na IDE: comando "Reload Window" (VSCode) ou "Restart Dart Analysis Server".

---

## Comportamento esperado pós-aplicação

### Sucesso (estado final)

`flutter analyze` reporta apenas o `unused_import` pré-existente em `test/src/presentation/providers/recent_expenses_notifier_test.dart:14`, que agora aparece **duplicado** por efeito do plugin echo (mesmo arquivo:linha:coluna, mesmo `unused_import`). A issue subjacente é única e pré-spec.

```
warning • Unused import: ... • recent_expenses_notifier_test.dart:14:8 • unused_import
warning • Unused import: ... • recent_expenses_notifier_test.dart:14:8 • unused_import

2 issues found.
```

Aceito como noise cosmético. Limpeza do import pré-existente fica fora de escopo (cleanup independente).

### `flutter test`

Todos os testes verdes (618 testes). Plugin não interfere com runtime de testes.

### Regras com cobertura efetiva no projeto

| Regra | Cenário coberto | Status |
|---|---|---|
| `provider_parameters` | Family providers (5 hoje) — parâmetro sem `==` por valor | ✅ Ativa |
| `avoid_public_notifier_properties` | Campo público mutável no notifier (violaria MVI) | ✅ Ativa |
| `notifier_extends` | `Notifier` vs `AsyncNotifier` errado | ✅ Ativa |
| `functional_ref` | `Ref` mal-usado em providers funcionais | ✅ Ativa |
| `notifier_build` | Assinatura inválida do `build` | ✅ Ativa |
| `unsupported_provider_value` | Provider retorna tipo mutável sem `==` | ✅ Ativa |
| `scoped_providers_should_specify_dependencies` | Provider scoped sem declarar `dependencies` | ✅ Ativa |
| `missing_provider_scope` | `runApp` sem `ProviderScope` | ✅ Ativa |
| `avoid_build_context_in_providers` | `BuildContext` num provider | ✅ Ativa |
| `avoid_ref_inside_state_dispose` | `ref` em `State.dispose()` | ✅ Ativa |
| `async_value_nullable_pattern` | Pattern match incorreto em `AsyncValue` nullable | ✅ Ativa |
| `protected_notifier_properties` | Membros protegidos vazando | ✅ Ativa |
| `only_use_keep_alive_inside_keep_alive` | `keepAlive: true` observando auto-dispose | ❌ Desabilitada (TODO em `analysis_options.yaml`) |

---

## Decisões de design

1. **Mudança total de approach mid-implementation: `custom_lint` → `analysis_server_plugin`.**
   Spec inicial previa `dev_dependencies: custom_lint + riverpod_lint` + `analyzer.plugins: [custom_lint]` + comando `dart run custom_lint`. Ao rodar `flutter pub get`, descoberto que: (a) `custom_lint 0.8.1` é incompatível com `riverpod_generator 4.0.3` (analyzer ^8.0 vs ^9.0); (b) `riverpod_lint 3.1.x` não depende mais de `custom_lint_builder`, migrou pra `analysis_server_plugin` direto. README do `riverpod_lint` confirma o approach novo. Spec atualizada inline pra refletir realidade — sem `dev_dependencies`, sem comando novo.

2. **Não importar `package:riverpod_lint` em lugar nenhum do código.**
   `riverpod_lint` vive só como plugin do analyzer. Se aparecer `import 'package:riverpod_lint/...'` em `lib/` ou `test/`, é erro.

3. **`riverpod_lint` ^3.1.x alinha com `flutter_riverpod` ^3.x.**
   O versionamento segue o major do Riverpod core. Manter sincronizado em qualquer upgrade futuro.

4. **Não regenerar `.g.dart` como parte desta spec.**
   Plugin não toca em codegen. Os 30 arquivos `.g.dart` já gerados permanecem como estão.

5. **Sem mudança no `build.yaml`.**
   Builders e linters são domínios separados. A otimização anterior do `build.yaml` (`generate_for` escopado pro `riverpod_generator`) é ortogonal.

6. **Regra `only_use_keep_alive_inside_keep_alive` desabilitada — não corrigida.**
   3 sites flagrados: `clients_provider.dart:48` (dio watches localTokenDataSource), `notification_lifecycle_provider.dart:15`, `expenses_notifier.dart:40`. Todos seguem o padrão "notifier keepAlive observa repository auto-dispose", o que é onipresente no projeto (qualquer notifier keepAlive faz isso). Corrigir exigiria decisão arquitetural: tornar repos/datasources `keepAlive: true` universalmente, ou converter notifiers para auto-dispose (mudaria UX — listas reconstruiriam ao navegar). Decisão deferida pra spec separada; TODO inline em `analysis_options.yaml` documenta a pendência.

7. **`unused_import` duplicado não é tratado.**
   `test/src/presentation/providers/recent_expenses_notifier_test.dart:14` tem import não usado pré-existente. Após habilitar o plugin, aparece **duas vezes** no output de `flutter analyze` (mesma issue, echo). Causa: plugin re-emite diagnostics do analyzer base. Não é regressão funcional — só ruído visual. Cleanup do import em si fica fora do escopo (independente do plugin).
