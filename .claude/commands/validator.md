# Criar Validadores de Formulário

Cria os validadores para a feature: $ARGUMENTS

---

## Estrutura a gerar

### 1. Validações individuais — `lib/src/presentation/validators/`

Uma classe por campo. Implementam `Validation<T>` de `domain/validators/validation.dart`.

```dart
// presentation/validators/xxx_validation.dart
import 'package:trocado/src/domain/validators/validation.dart';

final class XxxValidation implements Validation<String> {
  const XxxValidation();

  @override
  ValidationBase<String> call(String value) {
    if (value.isEmpty) return const Invalid('Xxx obrigatório');
    // regras específicas...
    return Valid(value);
  }
}
```

### 2. Form validator — `lib/src/presentation/screens/xxx/validators/xxx_form_validator.dart`

Compõe as validações individuais e retorna o state atualizado com falhas + flag `isValid`.

```dart
// presentation/screens/xxx/validators/xxx_form_validator.dart
import 'package:trocado/src/domain/validators/validation.dart';
import 'package:trocado/src/presentation/validators/xxx_validation.dart';

import 'package:trocado/src/presentation/screens/xxx/notifiers/xxx_state.dart';

final class XxxFormValidator {
  final XxxValidation _xxxValidation;

  const XxxFormValidator({
    required XxxValidation xxxValidation,
  }) : _xxxValidation = xxxValidation;

  ({XxxState state, bool isValid}) call(XxxState state) {
    final xxxResult = _xxxValidation(state.xxx);

    final isValid = xxxResult is Valid;

    final validated = state.copyWith(
      xxxFailure: switch (xxxResult) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearXxxFailure: xxxResult is Valid,
    );

    return (state: validated, isValid: isValid);
  }
}
```

### 3. Provider — `lib/src/main/providers/validators_provider.dart`

Adicionar o provider do form validator (ou criar o arquivo se não existir).

```dart
// main/providers/validators_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/validators/xxx_validation.dart';
import 'package:trocado/src/presentation/screens/xxx/validators/xxx_form_validator.dart';

part 'validators_provider.g.dart';

@Riverpod()
XxxFormValidator xxxFormValidator(Ref _) => const XxxFormValidator(
  xxxValidation: XxxValidation(),
);
```

### 4. Notifier — receber validator via DI

No `build()` do notifier:

```dart
late XxxFormValidator _validator;

@override
XxxState build() {
  _validator = ref.watch(xxxFormValidatorProvider);
  _repository = ref.watch(xxxRepositoryProvider);
  return const XxxState();
}
```

### 5. State — campos de failure

Adicionar campos de failure no state para cada campo validado:

```dart
final class XxxState extends Equatable {
  final String xxx;
  final String? xxxFailure;
  // ...

  XxxState copyWith({
    String? xxx,
    String? xxxFailure,
    bool clearXxxFailure = false,
  }) => XxxState(
    xxx: xxx ?? this.xxx,
    xxxFailure: clearXxxFailure ? null : xxxFailure ?? this.xxxFailure,
  );
}
```

---

## Após criar os arquivos

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Regras

- `Validation<T>` é a interface de domínio — as implementações concretas ficam em `presentation/validators/`
- Form validator vive em `presentation/screens/xxx/validators/` (escopo da feature)
- Nunca instanciar validações diretamente no notifier — sempre via provider
- Campos `late`, nunca `late final`, para `_validator` no notifier
- `clearXxxFailure` no `copyWith()` do state para limpar falhas ao editar o campo
- Intents `XxxChanged` devem incluir `clearXxxFailure: true` no `copyWith`
