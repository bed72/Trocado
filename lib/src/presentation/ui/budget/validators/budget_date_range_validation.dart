import 'package:trocado/src/domain/validators/validation.dart';

final class BudgetDateRangeValidation implements Validation<(int?, int?)> {
  const BudgetDateRangeValidation();

  @override
  ValidationBase<(int?, int?)> call((int?, int?) value) {
    final (startDate, endDate) = value;

    if (startDate == null || endDate == null) {
      return const Invalid('Data de início e fim são obrigatórias');
    }

    if (endDate < startDate) {
      return const Invalid('Data de fim deve ser posterior à data de início');
    }

    return Valid(value);
  }
}
