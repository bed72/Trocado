# Criar Riverpod Notifier (MVI)

Cria um Notifier com padrão MVI para a feature: $ARGUMENTS

---

## Estrutura a gerar

### 1. State — `lib/src/presentation/providers/xxx/xxx_state.dart`

```dart
enum XxxStatus { initial, loading, success, failure }

class XxxState extends Equatable {
  final XxxStatus status;
  final String message;

  const XxxState({
    this.status = XxxStatus.initial,
    this.message = '',
  });

  XxxState copyWith({XxxStatus? status, String? message}) => XxxState(
    status: status ?? this.status,
    message: message ?? this.message,
  );

  @override
  List<Object> get props => [status, message];
}
```

### 2. Intent — `lib/src/presentation/providers/xxx/xxx_intent.dart`

```dart
sealed class XxxIntent {}

final class XxxActionA extends XxxIntent {
  final String value;
  const XxxActionA(this.value);
}

final class XxxSubmit extends XxxIntent {}
```

### 3. Notifier — `lib/src/presentation/providers/xxx/xxx_notifier.dart`

```dart
part 'xxx_notifier.g.dart';

@riverpod
final class XxxNotifier extends _$XxxNotifier {
  late IXxxRepository _repository;

  @override
  XxxState build() {
    _repository = ref.watch(xxxRepositoryProvider);
    return const XxxState();
  }

  void dispatch(XxxIntent intent) => switch (intent) {
    XxxActionA(:final value) => state = state.copyWith(...),
    XxxSubmit()              => _submit(),
  };

  Future<void> _submit() async {
    state = state.copyWith(status: XxxStatus.loading);

    final data = await _repository.action();

    data.fold(
      (failure) => state = state.copyWith(status: XxxStatus.failure, message: failure.message),
      (_)       => state = state.copyWith(status: XxxStatus.success),
    );
  }
}
```

### 4. Consumer na Screen

```dart
class XxxScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(xxxProvider, (_, XxxState state) => switch (state.status) {
          XxxStatus.success  => context.navigate(NextLocation()),
          XxxStatus.failure  => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message))),
          XxxStatus.loading ||
          XxxStatus.initial  => null,
        });

        final status = ref.watch(
          xxxNotifierProvider.select((s) => s.status),
        );

        return XxxWidget(
          isLoading: status == XxxStatus.loading,
          onIntent: ref.read(xxxNotifierProvider.notifier).dispatch,
        );
      },
    );
  }
}
```

### Variante: AsyncNotifier (inicialização automática)

Quando não há interação do usuário e o estado é carregado ao montar (ex: splash, carregamento inicial de dados), usar `AsyncNotifier`. A lógica async fica em método privado:

```dart
@riverpod
final class XxxNotifier extends _$XxxNotifier {
  late IXxxRepository _repository;

  @override
  Future<XxxStatus> build() async {
    _repository = ref.watch(xxxRepositoryProvider);
    return await _load();
  }

  Future<XxxStatus> _load() async {
    final data = await _repository.action();
    return data.fold((_) => XxxStatus.failure, (_) => XxxStatus.success);
  }
}
```

Na screen, o provider retorna `AsyncValue<XxxStatus>`:

```dart
ref.listen(xxxProvider, (_, AsyncValue<XxxStatus> state) => switch (state) {
  AsyncData(:final value) => switch (value) {
    XxxStatus.success => navigateToHome(),
    XxxStatus.failure => navigateToSignIn(),
  },
  _ => null,
});
```

---

## Após criar os arquivos

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Regras

- Campos antes do construtor em `XxxState`
- Zero comentários no código
- `@riverpod` apenas no Notifier — não usar code gen em State ou Intent
- **`switch` expression sempre** — nunca switch statement. Vale para `dispatch`, `ref.listen`, mapeamentos de failure e qualquer outro switch no projeto
- `switch` no `dispatch` deve ser exhaustivo (cobrir todos os intents)
- Widget filho (`XxxWidget`) não conhece Riverpod — recebe `onIntent` como callback
- **Nunca usar `ConsumerWidget`** — sempre `StatelessWidget` + `Consumer` interno na screen
- **Nunca criar widget privado dentro de outro arquivo** (`class _XxxWidget extends StatelessWidget`) — extrair para arquivo próprio se não-trivial, ou usar método privado se trivial (ex: `Widget _placeholder() => const SizedBox(...)`)
- **Dependências via `ref.watch` em `build()`** — repositórios, validators e demais dependências nunca instanciadas diretamente no notifier
- **Campos de dependência são `late`, nunca `late final`** — `build()` pode ser re-executado na mesma instância quando um `ref.watch` muda; `late final` lançaria erro na segunda execução
- Se o notifier usa um validator, ele é provido por um provider em `main/providers/validators_provider.dart`
