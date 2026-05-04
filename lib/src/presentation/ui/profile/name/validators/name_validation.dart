import 'package:trocado/src/domain/validators/validation.dart';

final class NameValidation implements Validation<String> {
  const NameValidation();

  static const _maxLength = 128;

  @override
  ValidationBase<String> call(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) return const Invalid('Nome obrigatório');
    if (normalized.length > _maxLength) {
      return const Invalid('Nome deve ter no máximo 128 caracteres');
    }

    return Valid(normalized);
  }
}
