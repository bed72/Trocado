import 'package:trocado/src/domain/validators/validation.dart';

final class BudgetValueValidation implements Validation<int> {
  const BudgetValueValidation();

  @override
  ValidationBase<int> call(int value) {
    if (value <= 0) return const Invalid('Valor é obrigatório');
    return Valid(value);
  }
}
