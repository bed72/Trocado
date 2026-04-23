import 'package:trocado/src/domain/validators/validation.dart';

final class BudgetDescriptionValidation implements Validation<String> {
  const BudgetDescriptionValidation();

  static const _maxLength = 256;

  @override
  ValidationBase<String> call(String value) {
    if (value.trim().isEmpty) return const Invalid('Descrição é obrigatória');
    if (value.length > _maxLength) {
      return const Invalid('Descrição deve ter no máximo 256 caracteres');
    }
    return Valid(value.trim());
  }
}
