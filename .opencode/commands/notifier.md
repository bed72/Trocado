---
description: Create or update a Riverpod MVI notifier for a Trocado feature.
agent: build
---

# Criar Riverpod Notifier (MVI)

Crie o Notifier para a feature: $ARGUMENTS

## Estrutura

### State

Create `lib/src/presentation/ui/<feature>/data/<feature>_state.dart` or the feature's established state location:

```dart
enum XxxStatus { initial, loading, success, failure }

final class XxxState extends Equatable {
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

### Intent

Create a sealed intent hierarchy with one class per user interaction:

```dart
sealed class XxxIntent {}

final class XxxActionA extends XxxIntent {
  final String value;
  const XxxActionA(this.value);
}

final class XxxSubmit extends XxxIntent {}
```

### Notifier

Use `@Riverpod()` and generated provider wiring:

```dart
part 'xxx_notifier.g.dart';

@Riverpod()
final class XxxNotifier extends _$XxxNotifier {
  late IXxxRepository _repository;

  @override
  XxxState build() {
    _repository = ref.watch(xxxRepositoryProvider);
    return const XxxState();
  }

  void dispatch(XxxIntent intent) => switch (intent) {
    XxxActionA(:final value) => state = state.copyWith(message: value),
    XxxSubmit() => _submit(),
  };

  Future<void> _submit() async {
    state = state.copyWith(status: XxxStatus.loading);
    final data = await _repository.action();
    data.fold(
      (failure) => state = state.copyWith(
        status: XxxStatus.failure,
        message: failure.message,
      ),
      (_) => state = state.copyWith(status: XxxStatus.success),
    );
  }
}
```

### Screen

Screens are `StatelessWidget` plus an internal `Consumer`; child widgets receive callbacks and do not know Riverpod:

```dart
class XxxScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      ref.listen(xxxNotifierProvider, (_, XxxState state) => switch (state.status) {
        XxxStatus.success => context.navigate(NextLocation()),
        XxxStatus.failure => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        ),
        XxxStatus.loading || XxxStatus.initial => null,
      });

      final status = ref.watch(xxxNotifierProvider.select((state) => state.status));
      return XxxWidget(
        isLoading: status == XxxStatus.loading,
        onIntent: ref.read(xxxNotifierProvider.notifier).dispatch,
      );
    },
  );
}
```

### AsyncNotifier

For automatic initial loading with no user interaction, use `Future<XxxStatus> build() async` and keep async work in a private method. Screens consume `AsyncValue<XxxStatus>` and use `AsyncData(:final value)` with a switch expression.

## Rules

- Use `@Riverpod()` only for Riverpod providers; do not generate State or Intent.
- Use switch expressions everywhere, including exhaustive `dispatch` and `ref.listen` mappings.
- Never use `ConsumerWidget`.
- Services are injected into the notifier and formatted values are emitted through presentation data; screens never read service providers directly.
- Features are self-contained. Cross-feature imports are limited to locations and `ref.invalidate(...)` after successful mutations.
- Never define a non-trivial private widget class in another widget file; extract it to its own public file.
- Dependencies are obtained with `ref.watch` in `build()` and fields are `late`, never `late final`.
- Validators are provided by `main/providers/validators_provider.dart`.

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
```
