import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/validators/invite_code_validation.dart';
import 'package:trocado/src/presentation/ui/couple/scan/validators/couple_scan_form_validator.dart';

void main() {
  const validator = CoupleScanFormValidator(
    codeValidation: InviteCodeValidation(),
  );

  group('CoupleScanFormValidator', () {
    test('sets manualCodeFailure when code is empty', () {
      const input = CoupleScanState();

      final (:state, :code) = validator(input);

      expect(code, isNull);
      expect(state.manualCodeFailure, 'Código obrigatório');
    });

    test('sets manualCodeFailure when code is shorter than 6', () {
      const input = CoupleScanState(manualCode: 'AB3');

      final (:state, :code) = validator(input);

      expect(code, isNull);
      expect(state.manualCodeFailure, 'Código deve ter 6 caracteres');
    });

    test('sets manualCodeFailure when code contains ambiguous chars', () {
      const input = CoupleScanState(manualCode: 'AB0K7N');

      final (:state, :code) = validator(input);

      expect(code, isNull);
      expect(state.manualCodeFailure, 'Código inválido');
    });

    test('returns normalized code and clears failure when valid', () {
      const input = CoupleScanState(
        manualCode: '  ab3k7n  ',
        manualCodeFailure: 'Código obrigatório',
      );

      final (:state, :code) = validator(input);

      expect(code, 'AB3K7N');
      expect(state.manualCodeFailure, isNull);
    });
  });
}
