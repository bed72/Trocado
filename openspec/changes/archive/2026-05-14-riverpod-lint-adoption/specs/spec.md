# Spec: riverpod-lint-adoption

## Capability

Habilitar análise estática específica do Riverpod no projeto via o sistema `analysis_server_plugin` (Dart 3.10+), detectando em tempo de IDE/CLI bugs que o analyzer padrão não pega — em especial parâmetros de family não-Equatable, campos públicos mutáveis em notifiers e uso incorreto do par `Notifier`/`AsyncNotifier` no codegen.

## Comportamento

### Ativação

- `analysis_options.yaml` declara `riverpod_lint` em bloco `plugins:` de topo, com versão inline.
- Nenhuma dependência adicionada em `pubspec.yaml` — sistema `analysis_server_plugin` resolve plugin via workspace sintético interno.
- Versão pinada em `^3.1.3` (linha 3.1.x, compatível com `flutter_riverpod 3.x` e analyzer ^9.0.0).
- IDE com suporte (VSCode com extensão Dart, IntelliJ/Android Studio com plugin Dart) mostra os diagnostics inline após restart do Dart Analysis Server.

### Configuração

- `plugins.riverpod_lint.diagnostics` lista regras explicitamente habilitadas/desabilitadas.
- `only_use_keep_alive_inside_keep_alive: false` — única regra desabilitada na adoção inicial, com TODO inline documentando spec futura.
- Todas as outras regras seguem o default do plugin.

### CLI

- `dart analyze` e `flutter analyze` rodam o plugin automaticamente junto com a análise padrão.
- Não há comando separado (não há `dart run custom_lint` — projeto não usa `custom_lint`).
- Exit code reflete a presença de diagnostics (warnings ou errors do plugin contam).

### Estado pós-aplicação

- `flutter analyze` reporta apenas diagnostics pré-existentes:
  - `unused_import` em `test/src/presentation/providers/recent_expenses_notifier_test.dart:14` (aparece duplicado por echo do plugin — mesma issue subjacente)
- `flutter test` continua verde (618 testes).
- Nenhum arquivo em `lib/`, `test/`, `pubspec.yaml`, `build.yaml`, ou `.github/` é modificado.

### Documentação

- `CLAUDE.md` não muda. `flutter analyze` já estava documentado como comando de verificação e agora cobre também o plugin.

### Regras com cobertura efetiva no projeto

| Regra | Cenário coberto | Status |
|---|---|---|
| `provider_parameters` | Family providers (5 hoje) — parâmetro sem `==` por valor | ✅ Ativa |
| `avoid_public_notifier_properties` | Padrão MVI — campo público mutável fora do `state` | ✅ Ativa |
| `notifier_extends` | Codegen — `_$XxxNotifier` esperando `Notifier` ou `AsyncNotifier` | ✅ Ativa |
| `functional_ref` | Codegen — uso incorreto de `Ref` em providers funcionais | ✅ Ativa |
| `notifier_build` | Codegen — assinatura inválida do `build` | ✅ Ativa |
| `unsupported_provider_value` | Provider retorna tipo mutável sem `==` | ✅ Ativa |
| `scoped_providers_should_specify_dependencies` | Provider scoped sem declarar `dependencies` | ✅ Ativa |
| `missing_provider_scope` | `runApp` sem `ProviderScope` | ✅ Ativa |
| `avoid_build_context_in_providers` | `BuildContext` num provider | ✅ Ativa |
| `avoid_ref_inside_state_dispose` | `ref` em `State.dispose()` | ✅ Ativa |
| `async_value_nullable_pattern` | Pattern match incorreto em `AsyncValue` nullable | ✅ Ativa |
| `protected_notifier_properties` | Membros protegidos vazando do notifier | ✅ Ativa |
| `only_use_keep_alive_inside_keep_alive` | `keepAlive: true` provider observando provider auto-dispose | ❌ Desabilitada com TODO |

### Suprimir diagnostics individuais (referência)

| Granularidade | Sintaxe |
|---|---|
| Projeto | `plugins.riverpod_lint.diagnostics: { rule_name: false }` |
| Arquivo | `// ignore_for_file: riverpod_lint/rule_name` |
| Linha | `// ignore: riverpod_lint/rule_name` |

`analyzer.errors: { rule_name: ignore }` **não funciona** para diagnostics de plugin — analyzer trata como `unrecognized_error_code`.

## Não-comportamentos

- **Não** adiciona nada em `dev_dependencies`. Sistema `analysis_server_plugin` declara o plugin inline em `analysis_options.yaml`.
- **Não** introduz CI step novo. `.github/workflows/` só tem `android-release.yml` — workflow de checks é spec separada.
- **Não** instala pre-commit hook nem hook git. Uso é manual (`flutter analyze`) ou via IDE.
- **Não** toca em `lib/`, `test/`, `pubspec.yaml`, `build.yaml`, ou `CLAUDE.md`. Spec puramente de tooling em `analysis_options.yaml`.
- **Não** regenera `.g.dart`. Plugin é ortogonal ao `build_runner`.
- **Não** habilita lints customizados próprios (regras específicas do projeto como "sem `ConsumerWidget`", "`late` sem `final` em `build`"). Essas regras continuam vivendo no `CLAUDE.md` e em code review até existir um plugin custom próprio.
- **Não** desabilita regras de `flutter_lints` existentes. Os dois conjuntos coexistem.
- **Não** corrige os 3 sites flagrados por `only_use_keep_alive_inside_keep_alive`. Refactor não-trivial; deferido pra spec futura.
- **Não** limpa o `unused_import` duplicado em `recent_expenses_notifier_test.dart`. Pré-existente, cleanup independente.
