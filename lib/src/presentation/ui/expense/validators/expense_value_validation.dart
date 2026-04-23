import 'package:trocado/src/domain/validators/validation.dart';

final class ExpenseValueValidation implements Validation<int> {
  const ExpenseValueValidation();

  @override
  ValidationBase<int> call(int value) {
    if (value <= 0) return const Invalid('Valor é obrigatório');
    return Valid(value);
  }
}
