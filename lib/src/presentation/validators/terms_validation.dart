import 'package:trocado/src/domain/validators/validation.dart';

final class TermsValidation implements Validation<bool> {
  const TermsValidation();

  @override
  ValidationBase<bool> call(bool value) {
    if (!value) return const Invalid('Você deve aceitar os termos para continuar.');
    return Valid(value);
  }
}
