import 'package:trocado/src/domain/validators/validation.dart';

final class PasswordValidation implements Validation<String> {
  const PasswordValidation();

  static const _minLength = 8;

  @override
  ValidationBase<String> call(String value) {
    if (value.isEmpty) return const Invalid('Senha obrigatória');
    if (value.length < _minLength) {
      return const Invalid('Senha deve ter ao menos 8 caracteres');
    }

    return Valid(value);
  }
}
