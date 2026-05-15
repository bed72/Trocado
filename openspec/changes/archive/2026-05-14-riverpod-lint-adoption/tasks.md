# Tasks: riverpod-lint-adoption

> Mudança de approach no meio da implementação: spec inicial previa `custom_lint` + `dev_dependencies`, mas `riverpod_lint 3.1.x` migrou para `analysis_server_plugin` direto. Tasks reflitem o approach final.

## analysis_options.yaml

- [x] `analysis_options.yaml` — adicionar bloco `plugins:` de topo (fora de `analyzer:`):
  ```yaml
  plugins:
    riverpod_lint:
      version: ^3.1.3
      diagnostics:
        only_use_keep_alive_inside_keep_alive: false
  ```
- [x] Adicionar comentário TODO acima da regra desabilitada, referenciando spec futura

## pubspec.yaml

- [x] (nenhuma mudança — sistema `analysis_server_plugin` declara o plugin inline em `analysis_options.yaml`, não em `dev_dependencies`)

## CLAUDE.md

- [x] (nenhuma mudança — `flutter analyze` já é o comando documentado; plugin roda junto automaticamente)

## Verificação

- [x] `flutter pub get` — completa sem erro
- [x] `flutter analyze` — exit code reflete apenas issues pré-existentes (`unused_import` em `recent_expenses_notifier_test.dart:14`, agora duplicado por echo do plugin)
- [x] `flutter test` — 618 testes verdes, sem regressão
- [x] Restart Dart Analysis Server na IDE — necessário pra plugin carregar (validação manual: abrir um notifier com `@riverpod` e confirmar que IDE mostra warnings inline)

## Tratamento de warnings inesperados (executado)

Ao habilitar o plugin, 3 warnings novos apareceram (`only_use_keep_alive_inside_keep_alive`):

- `lib/src/main/providers/clients_provider.dart:48` — `dio` (keepAlive) observa `localTokenDataSourceProvider` (auto-dispose)
- `lib/src/main/providers/notification_lifecycle_provider.dart:15` — keepAlive observa auto-dispose
- `lib/src/presentation/ui/expenses/notifiers/expenses_notifier.dart:40` — `ExpensesNotifier` (keepAlive) observa `expenseRepositoryProvider` (auto-dispose)

Categorização: **fix não-trivial** (>2 arquivos + decisão arquitetural sobre marcar repos/datasources como `keepAlive: true`).

Ação aplicada: regra desabilitada via `plugins.riverpod_lint.diagnostics.only_use_keep_alive_inside_keep_alive: false` com TODO inline referenciando spec futura.

## Pré-condições (validadas)

- `flutter_riverpod ^3.3.1`, `riverpod_annotation ^4.0.2`, `riverpod_generator ^4.0.3` — todos linha 3.x/4.x compatível com `riverpod_lint 3.1.x`
- `analysis_options.yaml` existe — confirmado
- Dart SDK `^3.10.0` em `pubspec.yaml` — `analysis_server_plugin` exige Dart 3.10+ (Flutter 3.38+), confirmado
- Não há outro plugin em `analysis_options.yaml` — `plugins:` é seção nova, sem conflito
