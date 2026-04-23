import 'package:trocado/src/domain/validators/validation.dart';

final class ExpenseDateValidation implements Validation<int?> {
  const ExpenseDateValidation();

  @override
  ValidationBase<int?> call(int? value) {
    if (value == null) return const Invalid('Data é obrigatória');
    return Valid(value);
  }
}
