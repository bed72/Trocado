import 'package:trocado/src/domain/validators/validation.dart';

import 'package:trocado/src/presentation/ui/couple/scan/data/couple_scan_state.dart';
import 'package:trocado/src/presentation/ui/couple/scan/validators/invite_code_validation.dart';

final class CoupleScanFormValidator {
  final InviteCodeValidation _codeValidation;

  const CoupleScanFormValidator({required InviteCodeValidation codeValidation})
    : _codeValidation = codeValidation;

  ({CoupleScanState state, String? code}) call(CoupleScanState state) {
    final code = _codeValidation(state.manualCode);

    final updated = state.copyWith(
      manualCodeFailure: switch (code) {
        Valid() => null,
        Invalid(:final message) => message,
      },
      clearManualCodeFailure: code is Valid,
    );

    return (
      state: updated,
      code: switch (code) {
        Valid(:final value) => value,
        Invalid() => null,
      },
    );
  }
}
