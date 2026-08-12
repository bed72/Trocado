---
description: Create form field validators and dependency-injected form validation for a Trocado feature.
agent: build
---

# Criar Validadores de Formulário

Crie os validadores para a feature: $ARGUMENTS

## 1. Individual validations

Create one class per field in `lib/src/presentation/ui/<feature>/validators/` or the feature's established validator location. Implement `Validation<T>` from `domain/validators/validation.dart`:

```dart
import 'package:trocado/src/domain/validators/validation.dart';

final class XxxValidation implements Validation<String> {
  const XxxValidation();

  @override
  ValidationBase<String> call(String value) {
    if (value.isEmpty) return const Invalid('Xxx obrigatório');
    return Valid(value);
  }
}
```

## 2. Form validator

Create the feature-scoped form validator beside the feature state. It composes individual validations and returns `({XxxState state, bool isValid})`. Use a switch expression over `Valid` and `Invalid`, and expose clear-failure flags through `copyWith()`.

```dart
final class XxxFormValidator {
  final XxxValidation _xxxValidation;

  const XxxFormValidator({required XxxValidation xxxValidation})
      : _xxxValidation = xxxValidation;

  ({XxxState state, bool isValid}) call(XxxState state) {
    final xxxValidation = _xxxValidation(state.xxx);
    final isValid = xxxValidation is Valid;
    final validated = state.copyWith(
      xxxFailure: switch (xxxValidation) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearXxxFailure: xxxValidation is Valid,
    );
    return (state: validated, isValid: isValid);
  }
}
```

## 3. Provider

Register the form validator in `lib/src/main/providers/validators_provider.dart`:

```dart
@Riverpod()
XxxFormValidator xxxFormValidator(Ref _) => const XxxFormValidator(
  xxxValidation: XxxValidation(),
);
```

The notifier must receive it through `ref.watch(xxxFormValidatorProvider)` in `build()`. Never instantiate validators directly in the notifier.

## 4. State and intents

Add a nullable failure field for every validated field. Its `copyWith()` must support `clearXxxFailure`, and each `XxxChanged` intent must clear that field.

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

## Rules

- Concrete validations live in presentation; `Validation<T>` remains a domain interface.
- Dependency fields are `late`, never `late final`.
- Form validators stay scoped to their feature.
