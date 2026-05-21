import 'package:flutter/services.dart';

import 'package:trocado/src/presentation/ui/couple/scan/validators/invite_code_validation.dart';

final class UppercaseAlphabetFormatter extends TextInputFormatter {
  static final _allowed = RegExp('[${InviteCodeValidation.alphabet}]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    final filtered = upper.split('').where(_allowed.hasMatch).join();

    if (filtered == newValue.text) return newValue;

    return TextEditingValue(
      text: filtered,
      selection: .collapsed(offset: filtered.length),
    );
  }
}
