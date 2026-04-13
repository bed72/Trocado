import 'package:trocado/src/domain/validators/validation.dart';

final class EmailValidation implements Validation<String> {
  const EmailValidation();

  static final _regex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  ValidationBase<String> call(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) return const Invalid('E-mail obrigatório');
    if (!_regex.hasMatch(normalized)) return const Invalid('E-mail inválido');

    return Valid(normalized);
  }
}
