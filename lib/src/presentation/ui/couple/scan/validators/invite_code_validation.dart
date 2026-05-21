import 'package:trocado/src/domain/validators/validation.dart';

final class InviteCodeValidation implements Validation<String> {
  static const length = 6;
  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final _pattern = RegExp('^[$alphabet]+\$');

  const InviteCodeValidation();

  @override
  ValidationBase<String> call(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.isEmpty) return const Invalid('Código obrigatório');
    if (normalized.length != length) {
      return Invalid('Código deve ter $length caracteres');
    }
    if (!_pattern.hasMatch(normalized)) {
      return const Invalid('Código inválido');
    }

    return Valid(normalized);
  }
}
